  
IF OBJECT_ID('KPX_SPDWorkOrderCfmSave') IS NOT NULL   
    DROP PROC KPX_SPDWorkOrderCfmSave  
GO  
  
-- v2014.10.21 
  
-- 작업지시서생성-저장 by 이재천 (_SPDMPSProdPlanWorkOrderSaveNotCapa 사용)
CREATE PROC KPX_SPDWorkOrderCfmSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHANDle      INT, 
            @FactUnit       INT, 
            @ProdDateFr     NCHAR(8), 
            @ProdDateTo     NCHAR(8), 
            @WorkcenterSeq  INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100), 
            @Spec           NVARCHAR(100), 
            @ProdWeekSeq    INT, 
            @EnvValue       NVARCHAR(100), 
            @Dec            INT, 
            @Count          INT, 
            @MessageType    INT, 
            @Status         INT, 
            @Results        NVARCHAR(250), 
            @ExsistCnt      INT, 
            @QtyPoint       INT 
    
    CREATE TABLE #TPDSFCWorkOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkOrder'   
    IF @@ERROR <> 0 RETURN    
    
    
    CREATE TABLE #TPDMPSDailyProdPlan 
    (
        ProdPlanSeq     INT, 
        FactUnit        INT, 
        SrtDate         NCHAR(12), 
        EndDate         NCHAR(12) 
    )
    INSERT INTO #TPDMPSDailyProdPlan (ProdPlanSeq, FactUnit, SrtDate, EndDate)
    SELECT A.ProdPlanSeq, A.FactUnit, A.SrtDate + A.WorkCond1, A.EndDate + A.WorkCond2 
      FROM #TPDSFCWorkOrder         AS B 
      JOIN _TPDMPSDailyProdPlan     AS A ON ( (A.SrtDate + WorkCond1 BETWEEN B.FrStdDate + FrTime AND B.ToStdDate + ToTime) AND B.WorkCenterSeq = A.WorkCenterSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ProdPlanSeq NOT IN (SELECT ProdPlanSeq 
                                 FROM _TPDSFCWorkOrder 
                                WHERE CompanySeq = @CompanySeq 
                                  AND WorkCenterSeq = B.WorkCenterSeq 
                                  AND (WorkDate + WorkStartTime BETWEEN B.FrStdDate + FrTime AND WorkCond1 + WorkEndTime) 
                              )
    
    ------------------------------------------------------------------------------------------
    -- 체크1, 작업일이 중복되는 데이터가 존재하여 작업지시를 생성할 수 없습니다. 
    ------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 
                 FROM #TPDMPSDailyProdPlan AS A 
                 LEFT OUTER JOIN #TPDMPSDailyProdPlan AS B ON ( 1 = 1 )
                WHERE (B.SrtDate BETWEEN A.SrtDate AND A.EndDate  
                  OR B.EndDate BETWEEN A.SrtDate AND A.EndDate ) 
                 AND A.SrtDate <> B.EndDate 
                 AND A.EndDate <> B.SrtDate 
                 AND A.ProdPlanSeq <> B.ProdPlanSeq 
                ) 
    BEGIN 
        UPDATE #TPDSFCWorkOrder
           SET Result = '작업일이 중복되는 데이터가 존재하여 작업지시를 생성할 수 없습니다.', 
               MessageType = 1234, 
               Status = 1234 
        
        SELECT * FROM #TPDSFCWorkOrder 
        RETURN 
    END 
    
    
    ------------------------------------------------------------------------------------------
    -- 체크2, 처리할 데이터가 없습니다. 
    ------------------------------------------------------------------------------------------
    
    IF NOT EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlan) 
    BEGIN
        UPDATE #TPDSFCWorkOrder
           SET Result = '처리할 데이터가 없습니다.', 
               MessageType = 1234, 
               Status = 1234 
          FROM #TPDSFCWorkOrder 
         WHERE Status = 0 
         
        SELECT * FROM #TPDSFCWorkOrder 
        RETURN 
    END 
    
    -- 생산계획 확정하기 
    UPDATE A
       SET CfmCode = '1', 
           CfmDate = CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112), 
           CfmEmpSeq = (SELECT EmpSeq FROM _TCAUSer WHERE CompanySeq = @CompanySeq AND USerseq = @UserSeq), 
           LastDateTime = GETDATE()
      FROM _TPDMPSDailyProdPlan_Confirm AS A 
      JOIN #TPDMPSDailyProdPlan         AS B ON ( A.CfmSeq = B.ProdPlanSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    
    -- 판매/제품 수량 소숫점 자릿수     --  12.04.25 BY 김세호 
    EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@QtyPoint OUTPUT
    
    -- 환경설정값 가져오기 (소수점 자리수 5)
    EXEC dbo._SCOMEnv @CompanySeq,5,0,@@PROCID,@EnvValue OUTPUT
    SELECT @Dec = ISNULL(@EnvValue, 0)
    
    DECLARE @WeekDay    NVARCHAR(10), 
            @WeekSeq    INT, 
            @Cnt        INT, 
            @CheckDate  NCHAR(8),
            @SrtDate    NCHAR(8), 
            @EndDate    NCHAR(8) 
    
    DECLARE @DailyProdPlan TABLE
    (
        FactUnit    INT,
        ProdPlanSeq INT,
        ProdPlanNo  NVARCHAR(30),
        WorkDate    NCHAR(8),
        ItemSeq     INT,
        BOMRev      NCHAR(2),
        ProcRev     NCHAR(2),
        ProdQty     DECIMAL(19,5),
        UnitSeq     INT,
        SMSource    INT,
        EndDate     NCHAR(8),
        DeptSeq     INT,
        BOMUnitSeq  INT,                -- BOM단위
        BOMUnitQty  DECIMAL(19, 5),      -- BOM단위 수량(계획수량를 BOM단위로 환산)        11.11.11 김세호 추가  
        WorkCond1   NVARCHAR(500),        -- 작업조건 2012. 1. 13 hkim 추가  
        SrtTime     NCHAR(4), 
        EndTime     NCHAR(4)
    ) 
    INSERT INTO @DailyProdPlan (
                                FactUnit, ProdPlanSeq, ProdPlanNo, WorkDate, ItemSeq, 
                                BOMRev, ProcRev, ProdQty, UnitSeq, SMSource, 
                                EndDate,DeptSeq, WorkCond1, SrtTime, EndTime 
                               ) 
    SELECT B.FactUnit, A.ProdPlanSeq, A.ProdPlanNo, A.SrtDate, A.ItemSeq, 
           A.BOMRev, A.ProcRev, A.ProdQty, A.UnitSeq, A.SMSource, 
           A.EndDate, A.DeptSeq, A.EndDate, WorkCond1, WorkCond2 
      FROM _TPDMPSDailyProdPlan As A 
      JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit
     WHERE A.CompanySeq = @CompanySeq
    
    -- 계획수량(생산단위)을 BOM단위수량으로 환산            11.11.11 김세호 추가 
    UPDATE A  
       SET A.BOMUnitSeq = B.STDUnitSeq,  
           A.BOMUnitQty = CASE WHEN UP.ConvDen * US.ConvNum * US.ConvDen <> 0 
                               THEN A.ProdQty * (UP.ConvNum / UP.ConvDen) / (US.ConvNum / US.ConvDen)    
                               ELSE A.ProdQty    
                               END 
      FROM @DailyProdPlan  AS A 
      JOIN _TDAItemDefUnit AS B WITH(NOLOCK)  ON A.ItemSeq   = B.ItemSeq  
                                              AND @CompanySeq = B.CompanySeq
                                              AND B.UMModuleSeq = 1003004
      JOIN _TDAItemUnit    AS US WITH(NOLOCK)  ON B.ItemSeq = US.ItemSeq  
                                                AND B.CompanySeq = US.CompanySeq  
                                                AND B.STDUnitSeq = US.UnitSeq  
      JOIN _TDAItemUnit    AS UP WITH(NOLOCK)  ON A.ItemSeq = UP.ItemSeq  
                                                AND @CompanySeq = UP.CompanySeq  
                                                AND A.UnitSeq = UP.UnitSeq   
    
    /*****************************************************************************************************************************/
    -- 배합품목 배치Seq 담기
    DECLARE @TempBatchItem TABLE
    (
        FactUnit    INT,
        ProdPlanSeq INT,
        ItemSeq     INT,
        BatchSeq    INT
    )
    INSERT INTO @TempBatchItem
    SELECT A.FactUnit, A.ProdPlanSeq, A.ItemSeq, B.BatchSeq
      FROM @DailyProdPlan AS A 
      JOIN _TPDBOMBatch AS B With(NOLOCK) ON A.FactUnit = B.FactUnit 
                                         AND A.ItemSeq = B.ItemSeq 
                                         AND B.CompanySeq = @CompanySeq
                                         AND A.EndDate >= B.DateFr 
                                         AND A.EndDate <= B.DateTo
    -- select * from _TPDBOMBatch where ItemSEq = 14768
    /****************************************************************************************************************************/
    
    
    SELECT @EndDate = MAX(WorkDate) FROM @DailyProdPlan
    SELECT @SrtDate = CONVERT(NCHAR(8),DATEADD(M,-12, CONVERT(DATETIME, @EndDate)),112)
    
    
    -- 기존 작업계획 삭제
    DELETE _TPDMPSWorkOrder
      FROM _TPDMPSWorkOrder AS A 
      JOIN @DailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit 
      JOIN #TPDMPSDailyProdPlan AS C ON A.ProdPlanSeq = C.ProdPlanSeq AND A.FactUnit = C.FactUnit
     WHERE A.CompanySeq = @CompanySeq 
    
    
    DECLARE @ItemProcInfo TABLE
    (
        FactUnit        INT,
        ItemSeq         INT,
        BOMRev          NCHAR(2),
        ProcRev         NCHAR(2),
        ProcSeq         INT,
        WorkCenterSeq   INT,
        ProcNo          INT,
        IsProcQC        NCHAR(1),
        IsLastProc      NCHAR(1),
        TimeUnit        INT,
        StdWorkTime     DECIMAL(19,5),
        ToProcNo        INT,
        SMToProcMovType INT,
        ISBatch         NCHAR(1),
        BatchSize       Decimal(19,5)
    )
    -- 제품별공정별워크센터에서 MIN(우선순위)중 MIN(Serl) 워크센터를 작업지시 대상 워크센터로 한다.     -- 11.11.08 김세호 추가   
    SELECT A.FactUnit, X.ItemSeq, X.BOMRev, X.ProcRev, B.ProcSeq, MIN(C.Serl) AS Serl  
      INTO #TMP_ItemProcWC  
      FROM @DailyProdPlan             AS X       
      JOIN _TPDROUItemProcRevFactUnit AS A WITH(NOLOCK) ON X.ItemSeq = A.ItemSeq       
                                                       AND X.BomRev = A.BomRev       
                                                       AND X.ProcRev = A.ProcRev       
                                                       AND X.FactUnit = A.FactUnit      
      JOIN _TPDROUItemProcRev         AS D WITH(NOLOCK) ON A.ItemSeq = D.ItemSeq       
                                                       AND a.ProcRev = D.ProcRev        
                                                       AND D.isProcType = '1'       
                                                       AND D.CompanySeq = @ComPanySeq      
      JOIN _TPDProcTypeItem           AS B WITH(NOLOCK) ON D.ProcTypeSeq = B.ProcTypeSeq       
                                                         AND A.ComPanySeq = B.ComPanySeq      
      JOIN _TPDROUItemProcWC          AS C WITH(NOLOCK) ON A.ItemSeq = C.ItemSeq       
                                                       AND A.ProcRev = C.ProcRev       
                                                       AND B.ProcSeq = C.ProcSeq       
                                                       AND B.ComPanySeq = C.ComPanySeq       
                                                       AND C.FactUnit = A.FactUnit      
     WHERE A.ComPanySeq = @ComPanySeq      
       AND B.ProcSeq <> 0      
       AND C.Ranking = (SELECT MIN(Ranking) FROM _TPDROUItemProcWC   
                          WHERE CompanySeq = @CompanySeq AND ItemSeq = C.ItemSeq AND ProcRev = C.ProcRev AND ProcSeq = C.ProcSeq AND FactUnit = C.FactUnit)     
     GROUP BY A.FactUnit, X.ItemSeq, X.BOMRev, X.ProcRev, B.ProcSeq   
    
    
    /*
    품목별공정테이블(_TPDROUItemProc)은 초기ER 로 사용 안되다가, 제품별공정소요자재에서 사용되게 되었으므로,
    공정이 중복으로 잡히지않도록 해당 구문은 주석처리              -- 13.08.14 BY 김세호 
    */
    INSERT INTO @ItemProcInfo(FactUnit,ItemSeq,    BOMRev,   ProcRev,     ProcSeq,  WorkCenterSeq,   ProcNo,    
                               IsProcQC,IsLastProc, TimeUnit, StdWorkTime, ToProcNo, SMToProcMovType, ISBatch, BatchSize )      
    SELECT DISTINCT A.FactUnit, X.ItemSeq,    X.BOMRev,   X.ProcRev,     B.ProcSeq,  C.WorkCenterSeq, B.ProcNo,    
            B.IsProcQC, B.IsLastProc, C.TimeUnit, C.StdWorkTime, B.ToProcNo, B.SMToProcMovQty,     C.ISBatch, 0  
      FROM @DailyProdPlan             AS X       
      JOIN _TPDROUItemProcRevFactUnit AS A WITH(NOLOCK) ON X.ItemSeq = A.ItemSeq       
                                                       AND X.BomRev = A.BomRev       
                                                       AND X.ProcRev = A.ProcRev       
                                                       AND X.FactUnit = A.FactUnit      
      JOIN _TPDROUItemProcRev         AS D WITH(NOLOCK) ON A.ItemSeq = D.ItemSeq       
                                                       AND a.ProcRev = D.ProcRev       
                                                       AND D.isProcType = '1'       
                                                     AND D.CompanySeq = @ComPanySeq      
      JOIN _TPDProcTypeItem           AS B WITH(NOLOCK) ON D.ProcTypeSeq = B.ProcTypeSeq       
                                                       AND A.ComPanySeq = B.ComPanySeq      
      JOIN _TPDROUItemProcWC          AS C WITH(NOLOCK) ON A.ItemSeq = C.ItemSeq       
                                                       AND A.ProcRev = C.ProcRev       
                                                       AND B.ProcSeq = C.ProcSeq       
                                                       AND B.ComPanySeq = C.ComPanySeq       
                                                       AND C.FactUnit = A.FactUnit   
      JOIN #TMP_ItemProcWC            AS E WITH(NOLOCK)  ON C.ItemSeq = E.ItemSeq       
                                                       AND C.ProcRev = E.ProcRev       
                                                       AND C.ProcSeq = E.ProcSeq         
                                                       AND C.FactUnit = E.FactUnit    
                                                       AND C.Serl     = E.Serl   
     WHERE A.ComPanySeq = @ComPanySeq      
       AND B.ProcSeq <> 0     
    
    
    
    UPDATE @ItemProcInfo
       SET ISBatch = B.ISBatch,  
           BatchSize = B.BatchSize
      FROM @ItemProcInfo AS A 
      JOIN _TPDROUItemProcWC AS B ON A.FactUnit = B.FactUnit AND A.ItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev AND A.ProcSeq = B.ProcSeq AND A.Workcenterseq = B.Workcenterseq
    
    
    DELETE FROM @ItemProcInfo WHERE TimeUnit = 0
    
    DECLARE @ItemProcAssy TABLE
    (
        ItemSeq INT,
        BOMRev  NCHAR(2),
        ProcRev NCHAR(2),
        ProcSeq INT,
        AssyItemSeq INT,
        AssyQtyNumerator DECIMAL(19,5),
        AssyQtyDenominator DECIMAL(19,5)
    )
    INSERT INTO @ItemProcAssy
    SELECT B.ItemSeq, B.BOMRev, B.ProcRev,B.ProcSeq,B.AssyItemSeq,B.AssyQtyNumerator,B.AssyQtyDenominator    
      FROM @DailyProdPlan AS A 
      JOIN _TPDROUItemProcMat AS B ON A.ItemSeq = B.ItemSeq 
                                   AND A.BOMRev = B.BOMRev 
                                   AND A.ProcRev = B.ProcRev 
                                   AND B.ProcSeq <> 0 
                                   AND AssyItemSeq <> 0 
                                   AND B.CompanySeq = @CompanySeq
     GROUP BY B.ItemSeq, B.BOMRev, B.ProcRev,B.ProcSeq,B.AssyItemSeq,B.AssyQtyNumerator,B.AssyQtyDenominator 
    
    CREATE TABLE #TPDMPSWorkOrder
    (
        Seq                     INT IDENTITY,
        CompanySeq    INT,-- 0 법인내부코드
        FactUnit    INT ,--0 생산사업장
        ProdPlanSeq    INT ,--0 생산계획내부코드
        WorkOrderSeq   INT,-- 0 작업지시내부코드
        WorkOrderNo    NCHAR(20),-- 20 작업지시번호
        WorkOrderSerl   INT ,--0 작업지시순번
        WorkOrderDate   NCHAR(8),-- 8 작업지시일
        WorkPlanSerl   INT,-- 0 작업계획순번
        DailyWorkPlanSerl     INT,-- 0 일자별작업계획순번
        WorkCenterSeq   INT,-- 0 워크센터내부코드
        GoodItemSeq    INT,-- 0 제품코드
        ProcSeq     INT,-- 0 공정내부코드
        AssyItemSeq    INT,-- 0 공정품코드
        ProdUnitSeq    INT,-- 0 생산단위
        OrderQty    DECIMAL(19,5),-- 19 지시수량
        StdUnitQty    DECIMAL(19,5),-- 19 기준단위수량
        WorkDate    NCHAR(8),-- 8 작업일
        WorkStartTime   NCHAR(4),-- 4 작업시작시간
        WorkENDTime    NCHAR(4),-- 4 작업종료시간
        ChainGoodsSeq   INT,-- 0 연산품내부코드
        WorkType    INT,-- 0 작업구분
        DeptSeq     INT,-- 0 생산부서코드
        ItemUnitSeq    INT,-- 0 제품단위코드
        ProcRev     NCHAR(2),-- 2 공정흐름차수
        Remark     NVARCHAR(200),-- 200 비고
        IsProcQC    NCHAR(1),-- 1 공정검사여부
        IsLastProc    NCHAR(1),-- 1 최종공정여부
        IsPjt     NCHAR(1),-- 1 프로젝트여부
        PjtSeq     INT,-- 0 프로젝트내부코드
        WBSSeq     INT,-- 0 WBS내부코드
        ItemBomRev    NCHAR(2),
        ProcNo     INT,
        ToProcNo    INT,
        SMToProcMovType   INT,
        LastUserSeq    INT,-- 0 작업자
        LastDateTime   DATETIME, -- 0 작업일
        SMSource                INT,
        WorkTime                DECIMAL(19,5),
        StdWorkTime             DECIMAL(19,5),
        TimeUnit                INT,
        ISBatch                 NCHAR(1),
        BatchSizeQty            DECIMAL(19,5),
        WorkCond1       NVARCHAR(500) 
    )
    
    -- 생산계획 건별 작업일의 작업시작/종료시간 가져오기 (Default : 09:00 ~ 18:00)     -- 13.01.08 BY 김세호
    SELECT A.ProdPlanSeq, 
          SrtTime AS SrtTime, 
          EndTime AS EndTime
      INTO #TMP_TPDBaseProdWorkHour
      FROM @DailyProdPlan                                AS A 
    
    INSERT INTO #TPDMPSWorkOrder
    (
        CompanySeq    ,--INT 0 법인내부코드
        FactUnit     ,--INT 0 생산사업장
        ProdPlanSeq    ,--INT 0 생산계획내부코드
        WorkOrderSeq   ,--INT 0 작업지시내부코드
        WorkOrderNo    ,--NCHAR 20 작업지시번호
        WorkOrderSerl   ,--INT 0 작업지시순번
        WorkOrderDate   ,--NCHAR 8 작업지시일
        WorkPlanSerl   ,--INT 0 작업계획순번
        DailyWorkPlanSerl     ,--INT 0 일자별작업계획순번
        WorkCenterSeq   ,--INT 0 워크센터내부코드
        GoodItemSeq    ,--INT 0 제품코드
        ProcSeq      ,--INT 0 공정내부코드
        AssyItemSeq    ,--INT 0 공정품코드
        ProdUnitSeq    ,--INT 0 생산단위
        OrderQty     ,--DECIMAL 19 지시수량
        StdUnitQty    ,--DECIMAL 19 기준단위수량
        WorkDate     ,--NCHAR 8 작업일
        WorkStartTime   ,--NCHAR 4 작업시작시간
        WorkENDTime    ,--NCHAR 4 작업종료시간
        ChainGoodsSeq   ,--INT 0 연산품내부코드
        WorkType     ,--INT 0 작업구분
        DeptSeq      ,--INT 0 생산부서코드
        ItemUnitSeq    ,--INT 0 제품단위코드
        ProcRev      ,--NCHAR 2 공정흐름차수
        Remark      ,--NVARCHAR 200 비고
        IsProcQC     ,--NCHAR 1 공정검사여부
        IsLastProc    ,--NCHAR 1 최종공정여부
        IsPjt       ,--NCHAR 1 프로젝트여부
        PjtSeq      ,--INT 0 프로젝트내부코드
        WBSSeq      ,--INT 0 WBS내부코드
        ItemBomRev,
        ProcNo,
        ToProcNo,
        SMToProcMovType,
        LastUserSeq    ,--INT 0 작업자
        LastDateTime   , --DATETIME 0 작업일
        SMSource,
        WorkTime,
        StdWorkTime,
        TimeUnit,
        ISBatch,
        BatchSizeQty,
        WorkCond1        
    )
    SELECT  
            @CompanySeq,
            A.FactUnit,
            a.ProdPlanSeq,
            0,
            '',
            0,
            A.WorkDate,
            0,
            0,
            F.WorkCenterSeq,

            a.ItemSeq,
            B.ProcSeq,
            c.AssyItemSeq,
            ISNULL((SELECT STDUnitSeq FROM _TDAItemDefUnit WHERE ItemSeq = c.AssyItemSeq AND UMModuleSeq = 1003003 AND ComPanySeq = @ComPanySeq),A.UnitSeq),    
            CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN a.BOMUnitQty ELSE a.BOMUnitQty * C.AssyQtyNumerator / C.AssyQtyDenominator END,    

            CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN a.BOMUnitQty ELSE a.BOMUnitQty * C.AssyQtyNumerator / C.AssyQtyDenominator END,   
            A.WorkDate,
            T.SrtTime,
            T.EndTime,
            0,

            6041001,
            F.DeptSeq,
            A.UnitSeq,
            A.ProcRev,
            '',
            B.IsProcQC,
            B.IsLastProc,
            '0',
            0,
            0,
            A.BOMRev,
            ISNULL(B.ProcNo,0),
            B.ToProcNo,
            B.SMToProcMovType,
            @UserSeq,
            GETDATE(),
            A.SMSource,
            -- CEILING((CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN 0 ELSE a.ProdQty * C.AssyQtyNumerator / C.AssyQtyDenominator END) * B.StdWorkTime),
            CEILING((CASE WHEN ISNULL(C.AssyQtyDenominator,0) = 0 THEN 0 ELSE a.ProdQty * C.AssyQtyNumerator / C.AssyQtyDenominator * ISNULL(D.WorkRate,0) /100 END) / B.StdWorkTime),  
            B.StdWorkTime,
            B.TimeUnit,
            B.ISBatch,
            B.BatchSize,
            A.WorkCond1 -- 종료시간 
    
      FROM @DailyProdPlan AS A 
      JOIN @ItemProcInfo AS B ON A.ItemSeq = B.ItemSeq AND A.BomRev = B.BomRev AND A.ProcRev = B.ProcRev  
      JOIN #TMP_TPDBaseProdWorkHour AS T ON A.ProdPlanSeq = T.ProdPlanSeq   
      LEFT OUTER JOIN @ItemProcAssy AS C ON B.ItemSeq = C.ItemSeq 
                                        AND B.ProcRev = C.ProcRev 
                                        AND B.Bomrev = C.Bomrev 
                                        AND B.ProcSeq = C.ProcSeq
      LEFT OUTER JOIN _TPDROUItemProcWC  AS D ON B.ItemSeq = D.ItemSeq 
                                             AND B.ProcRev = D.ProcRev 
                                             AND B.ProcSeq = D.ProcSeq 
                                             AND B.WorkCenterSeq = D.WorkCenterSeq
                                             AND B.FactUnit = D.FactUnit 
                                             AND D.Ranking = 1
                                             AND D.CompanySeq = @CompanySeq 
      LEFT OUTER JOIN _TPDBaseWorkcenter AS F ON B.WorkcenterSeq = F.WorkcenterSeq 
                   AND F.Companyseq = @Companyseq                                                              
     Order by a.ProdPlanSeq, B.ProcNo
    
    UPDATE #TPDMPSWorkOrder
       SET AssyItemSeq = GoodItemSeq
     WHERE ISNULL(AssyItemSeq,0) = 0
       and IsLastProc = '1'
    -- 공정품 로스율 반영      
           
    UPDATE #TPDMPSWorkOrder      
       SET OrderQty = A.OrderQty + (A.OrderQty * B.InLossRate / 100)      
      FROM #TPDMPSWorkOrder AS A JOIN _TPDROUItemProcMat AS B ON A.CompanySeq = B.CompanySeq       
                                                             AND A.GoodItemSeq = B.ItemSeq       
                                                             AND A.ItemBomRev = B.BomRev      
                                                             AND A.ProcRev = B.ProcRev      
                                                             AND A.AssyItemSeq = B.MatItemSeq      
     WHERE ISNULL(A.AssyItemSeq,0) <> 0    
    
    /****************************************************************************************************************/    
    
    -- 작업지시수량(BOM단위) 생산단위로 환산            -- 11.11.11 김세호 
    UPDATE A
       SET A.OrderQty = A.OrderQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)  ,
           A.StdUnitQty = A.StdUnitQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)  
      FROM #TPDMPSWorkOrder AS A  
      JOIN _TDAItemDefUnit    AS B WITH(NOLOCK)  ON A.AssyItemSeq = B.ItemSeq 
                                                AND @CompanySeq   = B.CompanySeq 
                                                AND UMModuleSeq   = 1003004
      JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON B.ItemSeq = US.ItemSeq  
                                                 AND B.CompanySeq = US.CompanySeq  
                                                 AND B.STDUnitSeq = US.UnitSeq  
      JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.AssyItemSeq = UP.ItemSeq  
                                                 AND @CompanySeq = UP.CompanySeq  
                                                 AND A.ProdUnitSeq = UP.UnitSeq 
    
    -- 환산한 작업지시수량(생산단위)로 작업시간 구함           -- 11.11.11 김세호 
    UPDATE A
       SET A.WorkTime = CEILING(A.OrderQty * ISNULL(D.WorkRate,0) /100 / A.StdWorkTime)
      FROM #TPDMPSWorkOrder AS A  
      LEFT OUTER JOIN _TPDROUItemProcWC AS D ON A.GoodItemSeq = D.ItemSeq     
                                            AND A.ProcRev = D.ProcRev     
                                            AND A.ProcSeq = D.ProcSeq     
                                            AND A.WorkCenterSeq = D.WorkCenterSeq    
                                            AND A.FactUnit = D.FactUnit     
                                            AND A.CompanySeq = D.CompanySeq
    
    -- 기준단위 환산되도록      -- 12.04.25 BY 김세호
    UPDATE A
       SET StdUnitQty = CASE WHEN A.ProdUnitSeq <> B.UnitSeq THEN A.OrderQty * (C.ConvNum / C.ConvDen) ELSE A.OrderQty END
      FROM #TPDMPSWorkOrder        AS A
      JOIN _TDAItem                AS B ON @CompanySeq = B.CompanySeq
                                       AND A.AssyItemSeq = B.ItemSeq
      JOIN _TDAItemUnit            AS C ON @CompanySeq = C.CompanySeq
                                       AND A.AssyItemSeq = C.ItemSeq
                                       AND A.ProdUnitSeq = C.UnitSeq
    /****************************************************************************************************************/    
    
    
    -- 작업지시 번호, 순번 생성하기    
    DECLARE @Seq                INT, 
             @ProdPlanSeq       INT, 
             @WorkDate          NCHAR(8), 
             @chkProdPlanSeq    INT, 
             @WorkOrderNo       NVARCHAR(20),
             @WorkOrderSeq      INT, 
             @WorkOrderSerl     INT, 
             @DeptSeq           INT,
             @NoLen             INT,
             @CountNo           INT,            -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 추가    
             @WorkOrderNoOld    NVARCHAR(20)    -- 2011. 5. 6 생산계획번호가 같고, 작업지시 코드는 다를 경우 중복해서 채번 될 수 있음    
    
    SELECT @Seq = 0, @chkProdPlanSeq = 0
    
    ---------------------------------------------------------------------------------------------------------------------------------------------------  
    
    -- 환경설정 (6214 생산계획번호를 작업지시번호로 사용) --12.02.23 김세호 추가
    DECLARE @IsUseProdPlanNo    NCHAR(1)                
    EXEC dbo._SCOMEnv @CompanySeq,6214,@UserSeq,@@PROCID,@IsUseProdPlanNo OUTPUT     
    WHILE(1=1)      
    BEGIN      
    
        SET ROWCOUNT 1      
    
        SELECT @Seq = Seq, 
               @ProdPlanSeq = ProdPlanSeq, 
               @WorkDate =  WorkOrderDate , 
               @WorkCenterSeq = WorkCenterSeq,    
               @FactUnit = FactUnit     
          FROM #TPDMPSWorkOrder      
         WHERE Seq > @Seq      
        ORDER BY Seq      
        
        IF @@ROWCOUNT = 0  BREAK      
        
        SET ROWCOUNT 0      
        
        
        -- 워크센터 구분자를 사용하는 경우    
        IF EXISTS (select * from _TCOMCreateNoDefine  WHERE TableName = '_TPDSFCWorkOrder' and Composition like '%E%')    
        BEGIN    
            
            IF @ProdPlanSeq <> @chkProdPlanSeq      
            
            BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
               
                -- 생산계획 번호 가져오기 2011. 3. 11 hkim    
                SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim    
                SELECT @NoLen = LEN(@WOrkOrderNo)    
                
                -- 반제품 생산계획을 풀기 전에 이미 생성된 작업지시 건수가 얼마인지 가져옮 2011. 4. 20 hkim    
                IF EXISTS (SELECT 1 FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                 --SELECT @ExsistCnt = COUNT(1) FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                 -- 2011. 5. 17 hkim 중간에 삭제가 된 경우 Row Count로는 중복 채번이 될 수 있어서 아래와 같이 Max 값 가져오도록 수정
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN  
                        SELECT @ExsistCnt =  CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4))  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE
                        SELECT @ExsistCnt = 0   
                END                    
                ELSE     
                BEGIN    
                    SELECT @ExsistCnt = 0    
                END      
                -- 임시테이블에 해당 작업지시 건수가 얼마인지 가져옮 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                -- 2011. 5. 17 row count 가 아닌 Max 값으로     
                               --SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END       
                   
                
                EXEC @WorkOrderSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                --EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                
                -- 생산계획에서 생성, 작업지시입력화면에서 생성. 이 두개를 같이 쓸 경우 중복키가 발생할 수 있어서 아래 로직 추가 2010. 12. 15 hkim    
                SELECT @WorkOrderSeq = @WorkOrderSeq + 1    
                  
                IF  @IsUseProdPlanNo <> '1'  -- 생산계획번호 작업지시번호로 사용안할경우 0001, 0002 로 채번 되도록  --12.02.23 김세호 추가
                BEGIN  
                    -- 2011. 4. 20 hkim Seq가 10을 넘어갈 수 있어서 아래와 같이 수정  -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 @Seq에사 @CountNo로 변경    
                    IF @CountNo + @ExsistCnt < 9      
                        SELECT @WorkOrderNo = @WorkOrderNo + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = @WorkOrderNo + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                        SELECT @WorkOrderNo = @WorkOrderNo + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE                           
                        SELECT @WorkOrderNo = @WorkOrderNo +  CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)                        
                            -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim 끝    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                               
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                    
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 추가 -- 2011. 5. 12 중복 채번 될 수 있어서 주석처리 hkim     
     
             END   
    
             ELSE      
             BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- 생산계획 번호 가져오기 2011. 3. 11 hkim    
                --SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
               EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
               
               -- 임시테이블에 해당 작업지시 건수가 얼마인지 가져옮 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                --SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                -- 2011. 5. 17 row count 가 아닌 Max 값으로 
                   IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkOrderNo), @NoLen + 1, 4) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1    
                   BEGIN
                       SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkOrderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'          
                   END
                   ELSE   
                       SELECT @CountNo = 0    
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                  
                IF  @IsUseProdPlanNo <> '1'  -- 생산계획번호 작업지시번호로 사용안할경우 0001, 0002 로 채번 되도록  --12.02.23 김세호 추가
                BEGIN             
                    -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim  -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 @Seq에사 @CountNo로 변경    
                    IF @CountNo + @ExsistCnt < 9     
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE                           
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim 끝    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 추가 -- 2011. 5. 12 중복 채번 될 수 있어서 주석처리 hkim     
     
            END              
     
        END  
    
        ELSE    
        BEGIN    
            IF @ProdPlanSeq <> @chkProdPlanSeq      
            BEGIN      
                
                SELECT @DeptSeq = DeptSeq FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- 생산계획 번호 가져오기 2011. 3. 11 hkim    
                SELECT @WorkOrderNo = ProdPlanNo FROM @DailyProdPlan WHERE ProdPlanSeq = @ProdPlanSeq    
                
                -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim    

                SELECT @NoLen = LEN(@WOrkOrderNo)      

                -- 반제품 생산계획을 풀기 전에 이미 생성된 작업지시 건수가 얼마인지 가져옮 2011. 4. 20 hkim    
                IF EXISTS (SELECT 1 FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                    -- 2011. 5. 17 hkim 중간에 삭제가 된 경우 Row Count로는 중복 채번이 될 수 있어서 아래와 같이 Max 값 가져오도록 수정  
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN  
                        SELECT @ExsistCnt =  CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4))  FROM _TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE  
                        SELECT @ExsistCnt = 0                            
                END                    
                ELSE     
                BEGIN    
                    SELECT @ExsistCnt = 0    
                END            
                -- 임시테이블에 해당 작업지시 건수가 얼마인지 가져옮 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                    SELECT @CountNo = COUNT(1) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                
                EXEC @WorkOrderSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1 
                --EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                
                
                -- 생산계획에서 생성, 작업지시입력화면에서 생성. 이 두개를 같이 쓸 경우 중복키가 발생할 수 있어서 아래 로직 추가 2010. 12. 15 hkim    
                SELECT @WorkOrderSeq = @WorkOrderSeq + 1    
                
                IF  @IsUseProdPlanNo <> '1'  -- 생산계획번호 작업지시번호로 사용안할경우 0001, 0002 로 채번 되도록  --12.02.23 김세호 추가
                BEGIN
                    IF @CountNo + @ExsistCnt < 9       -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 @Seq에사 @CountNo로 변경    
                        SELECT @WorkOrderNo = @WorkOrderNo + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = @WorkOrderNo + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 998      
                         SELECT @WorkOrderNo = @WorkOrderNo + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)        
                    ELSE                           
                        SELECT @WorkOrderNo = @WorkOrderNo +  CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)   
                     -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim 끝    
                END
                
                UPDATE #TPDMPSWorkOrder      
                   SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl      
                 WHERE Seq = @Seq      
                
                SELECT @chkProdPlanSeq = @ProdPlanSeq      
                
                --SELECT @CountNo = @CountNo + 1      -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 추가 -- 2011. 5. 12 중복 채번 될 수 있어서 주석처리 hkim     
     
            END  
            
            ELSE      
            BEGIN      
                
                EXEC @WorkOrderSerl = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkOrder', 'WorkOrderSerl', 1      
                    
                -- 임시테이블에 해당 작업지시 건수가 얼마인지 가져옮 2011. 5. 12 hkim    
                IF EXISTS (SELECT 1 FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND  WorkOrderNo LIKE @WorkOrderNo + '%')    
                BEGIN    
                -- 2011. 5. 17 Row count가 아닌 max 값으로     
                    IF ISNUMERIC((SELECT SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%')) = 1
                    BEGIN
                        SELECT @CountNo = CONVERT(INT, SUBSTRING(MAX(WorkORderNo), @NoLen + 1, 4)) FROM #TPDMPSWorkOrder WHERE CompanySeq = @CompanySeq AND WorkOrderNo LIKE @WorkOrderNo + '%'     
                    END
                    ELSE
                        SELECT @CountNo = 0 
                END                    
                ELSE     
                BEGIN    
                    SELECT @CountNo = 0    
                END      
                
                IF  @IsUseProdPlanNo <> '1'  -- 생산계획번호 작업지시번호로 사용안할경우 0001, 0002 로 채번 되도록  --12.02.23 김세호 추가
                BEGIN
                    -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim  -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 @Seq에사 @CountNo로 변경    
                    IF @CountNo + @ExsistCnt < 9      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '000' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 9 AND 98      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '00' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE IF @CountNo + @ExsistCnt BETWEEN 99 AND 9998      
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + '0' + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    ELSE                           
                        SELECT @WorkOrderNo = LEFT(@WorkOrderNo, @NoLen) + CONVERT(NVARCHAR, @CountNo + @ExsistCnt + 1)      
                    -- 생산계획에서 작업지시 생성시, 기존 작업지시 번호 + '0001', '0002' 등으로 순번 적용 2011. 3. 4 hkim 끝    
                    END
                    
                    UPDATE #TPDMPSWorkOrder      
                       SET WorkOrderNo = @WorkOrderNo, WorkOrderSeq = @WorkOrderSeq, WorkOrderSerl = @WorkOrderSerl     
                     WHERE Seq = @Seq      
     
                    SELECT @chkProdPlanSeq = @ProdPlanSeq      
                     
                 --SELECT @CountNo = @CountNo + 1  -- 2011. 4. 29 생산계획별로 작업지시를 생성할때 1번부터 순차적으로 생성되도록 추가 -- 2011. 5. 12 중복 채번 될 수 있어서 주석처리 hkim     
                
                END      
            END    
        END   
    

    
    SET ROWCOUNT 0      
    
    ALTER TABLE #TPDMPSWorkOrder ADD BatchSeq INT
    UPDATE #TPDMPSWorkOrder
       SET BatchSeq = ISNULL(B.BatchSeq,0)
      FROM #TPDMPSWorkOrder AS A JOIN @TempBatchItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq
    
    -- 제품별 공정검사 등록된 부분 반영하기 송기연 20100421------------------------------------------------------------------------------------------------------------------------
    UPDATE #TPDMPSWorkOrder
       SET IsProcQC = B.IsProcQC
      FROM #TPDMPSWorkOrder AS A 
      JOIN _TPDROUItemProcQC AS B ON A.GoodItemSeq = B.ItemSeq AND A.ProcRev = B.ProcRev 
                                 AND A.ProcSeq = B.ProcSeq AND B.CompanySeq = @CompanySeq
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------  
    
    UPDATE A 
       SET WorkOrderSerl = WorkOrderSeq 
      FROM #TPDMPSWorkOrder AS A 
    
    
    -- 생산계획, 작업지시 중간테이블 
    INSERT INTO _TPDMPSWorkOrder       
    (      
        CompanySeq,   FactUnit,      ProdPlanSeq,   WorkOrderSeq,      WorkOrderSerl,      
        WorkOrderNo,  WorkOrderDate, WorkPlanSerl,  DailyWorkPlanSerl, WorkCenterSeq,      
        GoodItemSeq,  ProcSeq,       AssyItemSeq,   ProdUnitSeq,       OrderQty,      
        StdUnitQty,   WorkDate,      WorkStartTime, WorkEndTime,       ChainGoodsSeq,      
        WorkType,     DeptSeq,       ItemUnitSeq,   ProcRev,           Remark,      
        IsProcQC,     IsLastProc,    IsPjt,         PjtSeq,            WBSSeq,      
        ItemBomRev,   ProcNo,        ToProcNo,      SMToProcMovType,   LastUserSeq,      
        LastDateTime, BatchSeq,      WorkCond1     
    )      
    SELECT           
            A.CompanySeq,   FactUnit,         ProdPlanSeq,           WorkOrderSeq,      WorkOrderSerl,        
            WorkOrderNo,  WorkOrderDate,    WorkPlanSerl,          DailyWorkPlanSerl, ISNULL(WorkCenterSeq,0),        
            GoodItemSeq,  ProcSeq,          ISNULL(AssyItemSeq,0), ProdUnitSeq,       CASE WHEN B.SMDecPointSeq = 1003001 THEN ROUND(OrderQty, @QtyPoint, 0)   -- 2011. 4. 19 hkim 소수점 자리수 통제하기 위해서 수정--CONVERT(DECIMAL(19,5),OrderQty),        
                                                                                           WHEN B.SMDecPointSeq = 1003002 THEN ROUND(OrderQty, @QtyPoint, -1)             
                                                                                           WHEN B.SMDecPointSeq = 1003003 THEN ROUND(OrderQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)     
                                                                                           ELSE ROUND(OrderQty  , @QtyPoint, 0) END,     
            CASE WHEN D.SMDecPointSeq = 1003001 THEN ROUND(StdUnitQty, @QtyPoint, 0)  -- 기준단위수량도 소수점처리 되도록   12.04.25 BY 김세호
                 WHEN D.SMDecPointSeq = 1003002 THEN ROUND(StdUnitQty, @QtyPoint, -1)             
                 WHEN D.SMDecPointSeq = 1003003 THEN ROUND(StdUnitQty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@QtyPoint + 1)), @QtyPoint)     
                 ELSE ROUND(OrderQty  , @QtyPoint, 0) END,   WorkDate,         WorkStartTime,         WorkENDTime,       ChainGoodsSeq,        
            WorkType,     ISNULL(A.DeptSeq,0) ,ItemUnitSeq,          ProcRev,           A.Remark,        
            IsProcQC,     IsLastProc,       IsPjt,                 PjtSeq,            WBSSeq,        
            ItemBomRev,   ProcNo,           ToProcNo,              SMToProcMovType,   A.LastUserSeq,        
            A.LastDateTime, A.BatchSeq,     WorkCond1  -- 종료시간     
      FROM #TPDMPSWorkOrder AS A    
      JOIN _TDAUnit          AS B ON A.ProdUnitSeq = B.UnitSeq    -- 2011. 4. 19 hkim 단위 등록의 소수점 계산방식을 가져오기 위해  
      JOIN _TDAItem          AS C ON B.CompanySeq = C.CompanySeq AND A.AssyItemSeq = C.ItemSeq  
      JOIN _TDAUnit          AS D ON C.CompanySeq = D.CompanySeq AND C.UnitSeq = D.UnitSeq
     WHERE ISNULL(WorkOrderNo ,'') <> ''         
       AND B.CompanySeq = @CompanySeq  
       AND A.OrderQty <> 0   --2013.02.05 BY 허승남  :: 작업시간 구할 때 제품 단위당 작업시간을 구하고 총 작업시간을 구하는 부분에서 환산처리하면서 단수차이가 발생하게 되어 총작업시간이 올림처리되면서 작업수량이 0 인 데이터가 생성될 수 있어서 수정 
    
    
    -- 작업지시 테이블 
    INSERT INTO _TPDSFCWorkOrder
    (
        CompanySeq,WorkOrderSeq,FactUnit,WorkOrderNo,WorkOrderSerl,
        WorkOrderDate,ProdPlanSeq,WorkPlanSerl,DailyWorkPlanSerl,WorkCenterSeq,
        GoodItemSeq,ProcSeq,AssyItemSeq,ProdUnitSeq,OrderQty,
        StdUnitQty,WorkDate,WorkStartTime,WorkEndTime,ChainGoodsSeq,
        WorkType,DeptSeq,ItemUnitSeq,ProcRev,Remark,
        IsProcQC,IsLastProc,IsPjt,PjtSeq,WBSSeq,
        ItemBomRev,ProcNo,ToProcNo,SMToProcMovType, ProdOrderSeq, 
        IsCancel, LastUserSeq, LastDateTime, BatchSeq, WorkCond1 -- 종료시간 
    ) 
    SELECT A.CompanySeq,
           A.WorkOrderSeq,
           A.FactUnit,
           A.WorkOrderNo,
           A.WorkOrderSerl,
           CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112), -- 작업지시일을 기존 생산계획완료일이 아닌 생산계획 확정일자로 변경 2012.06.18 by 허승남
           A.ProdPlanSeq,
           A.WorkPlanSerl,
           A.DailyWorkPlanSerl,
           A.WorkCenterSeq,
           A.GoodItemSeq,
           A.ProcSeq,
           A.AssyItemSeq,
           A.ProdUnitSeq,
           A.OrderQty,
           A.StdUnitQty,
           A.WorkDate,
           A.WorkStartTime,
           A.WorkEndTime,
           A.ChainGoodsSeq,
           6041001,
           A.DeptSeq,
           A.ItemUnitSeq,
           A.ProcRev,
           A.Remark,
           A.IsProcQC,--IsProcQC,
           A.IsLastProc,--IsLastProc,
           A.IsPjt,
           A.PjtSeq,
           A.WBSSeq,
           A.ItemBomRev,
           A.ProcNo,
           A.ToProcNo,
           A.SMToProcMovType,
           0,
           '0',
           A.LastUserSeq,
           A.LastDateTime,
           A.BatchSeq,
           A.WorkCond1 -- 종료시간 
        FROM _TPDMPSWorkOrder AS A 
        JOIN #TPDMPSDailyProdPlan AS B ON ( A.ProdPlanSeq = B.ProdPlanSeq ) 
       WHERE A.CompanySeq = @CompanySeq
    
    
    
    -- 작업지시 확정데이터 만들기
    INSERT INTO _TPDSFCWorkOrder_Confirm
    (
        CompanySeq,     CfmSeq,         CfmSerl,        CfmSubSerl,     CfmSecuSeq,
        IsAuto,         CfmCode,        CfmDate,        CfmEmpSeq,      UMCfmReason,
        CfmReason,      LastDateTime
    )
    SELECT @CompanySeq,
           A.WorkOrderSeq,
           A.WorkOrderSerl,
           0,
           1009,
           '0',
           0,
           '',
           (SELECT EmpSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq),
           0,
           '',
           GETDATE()
      FROM _TPDMPSWorkOrder                     AS A 
      JOIN #TPDMPSDailyProdPlan                 AS C ON A.ProdPlanSeq = C.ProdPlanSeq 
      LEFT OUTER JOIN _TPDSFCWorkOrder_Confirm  AS B ON A.WorkOrderSeq = B.CfmSeq 
                                                    AND A.WorkOrderSerl = B.CfmSerl
                                                    AND B.CompanySeq = @CompanySeq
     WHERE A.CompanySeq = @CompanySeq
       AND B.CfmSeq IS NULL
    
    IF ISNULL((SELECT IsNotUsed FROM _TCOMConfirmDef WHERE CompanySeq = @CompanySeq AND ConfirmSeq = 6320),'0') = '1'  
    BEGIN
        UPDATE _TPDSFCWorkOrder_Confirm
           SET CfmCode = 1,
               CfmDate = CONVERT(nCHAR(8), CONVERT(DATETIME, GETDATE()),112) --작업지시확정일자가 Convert가 제대로 되지 않은 상태로 들어가서 변경 12.11.22 by snheo
          FROM _TPDMPSWorkOrder                     AS A 
          JOIN #TPDMPSDailyProdPlan                 AS C ON A.ProdPlanSeq = C.ProdPlanSeq 
          LEFT OUter JOIN _TPDSFCWorkOrder_Confirm  AS B ON A.WorkOrderSeq = B.CfmSeq 
                                                       AND A.WorkOrderSerl = B.CfmSerl
                                                       AND B.CompanySeq = @CompanySeq
         WHERE A.CompanySeq = @CompanySeq
    END
    
    -- 생산계획 -> 작업지시 진행관리-------------------------------------------------------------------------------------------
    CREATE TABLE #SComSourceDailyBatch    
    (  
        ToTableName   NVARCHAR(100),  
        ToSeq         INT,  
        ToSerl        INT,  
        ToSubSerl     INT,  
        FromTableName NVARCHAR(100),  
        FromSeq       INT,  
        FromSerl      INT,  
        FromSubSerl   INT,  
        ToQty         DECIMAL(19,5),  
        ToStdQty      DECIMAL(19,5),  
        ToAmt         DECIMAL(19,5),  
        ToVAT         DECIMAL(19,5),  
        FromQty       DECIMAL(19,5),  
        FromSTDQty    DECIMAL(19,5),  
        FromAmt       DECIMAL(19,5),  
        FromVAT       DECIMAL(19,5)  
    )  
    -- 진행연결(생산계획 => 작업지시)  
    INSERT INTO #SComSourceDailyBatch  
    SELECT '_TPDSFCWorkOrder', A.WorkOrderSeq, A.WorkOrderSerl, 0,   
           '_TPDMPSDailyProdPlan', B.ProdPlanSeq, 0, 0,  
           0, 0, 0,   0,  
           0, 0, 0,   0 
      FROM _TPDMPSWorkOrder AS A JOIN #TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq 
     WHERE A.CompanySeq = @CompanySeq
    
    IF @@ERROR <> 0      
    BEGIN      
        RETURN      
    END    
    
     -- 진행연결  
     EXEC _SComSourceDailyBatch 'A', @CompanySeq, @UserSeq  
    
    SELECT * FROM #TPDSFCWorkOrder   
    
    RETURN  
go 
begin tran 
exec KPX_SPDWorkOrderCfmSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <FrStdDate>20141020</FrStdDate>
    <FrTime>1200</FrTime>
    <ToStdDate>20141031</ToStdDate>
    <ToTime>1200</ToTime>
    <WorkCenterName>조립2</WorkCenterName>
    <WorkCenterSeq>34</WorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021101
rollback  