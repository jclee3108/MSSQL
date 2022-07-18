
IF OBJECT_ID('KPXCM_SLGWHAssyStockListAdjustApply') IS NOT NULL
    DROP PROC KPXCM_SLGWHAssyStockListAdjustApply
GO 

-- v2015.12.01 

-- 재공재고조정(월) by이재천 
CREATE PROCEDURE KPXCM_SLGWHAssyStockListAdjustApply
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHandle  INT,  
            @BizUnit    INT,  
            @StdYM      NCHAR(6), 
            @AccUnit    INT,  
            @EnvMatQty  INT, -- 자재수량소수점자리수  
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8), 
            @Status     INT, 
            @Result     NVARCHAR(500)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
  
    SELECT  @BizUnit    = ISNULL(BizUnit,0),  
            @StdYM      = ISNULL(StdYM,'')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  
            BizUnit INT,  
            StdYM   NCHAR(6)
         )     
    
    --/*
    DECLARE @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT               
              
    SELECT @ItemPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --자재단가계산단위                         
    SELECT @GoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --상품단가계산단위                         
    SELECT @FGoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --제품단가계산단위                         
              
  
    -- 구매/자재수량소수점자리수구하기  
    SELECT @EnvMatQty = EnvValue  
      FROM _TCOMEnv  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 5  
  
    SELECT @AccUnit = ISNULL(AccUnit, 0)  
      FROM _TDABizUnit WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND BizUnit    = @BizUnit  
    
    CREATE TABLE #BaseData
    (
        IDX_NO          INT IDENTITY, 
        MatItemSeq      INT, 
        WorkReportSeq   INT, 
        StockQty        DECIMAL(19,5), 
        MaxItemSerl     INT 
    )
    

    
    IF @WorkingTag = 'A' 
    BEGIN 
    
        CREATE TABLE #GetInOutItem  
        (  
            ItemSeq    INT  
        )  
      
        CREATE TABLE #GetInOutStock  
      
        (  
            WHSeq           INT,  
            FunctionWHSeq   INT,  
            ItemSeq         INT,  
            UnitSeq         INT,  
            PrevQty         DECIMAL(19,5),  
            InQty           DECIMAL(19,5),  
            OutQty          DECIMAL(19,5),  
            StockQty        DECIMAL(19,5),  
            STDPrevQty      DECIMAL(19,5),  
            STDInQty        DECIMAL(19,5),  
            STDOutQty       DECIMAL(19,5),  
            STDStockQty     DECIMAL(19,5)  
        )  
      
        INSERT INTO #GetInOutItem  
        SELECT DISTINCT A.ItemSeq  
          FROM _TDAItem AS A WITH (NOLOCK)  
               JOIN _TDAItemSales AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                    AND A.ItemSeq    = B.ItemSeq  
               JOIN _TDAItemAsset AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                    AND A.AssetSeq   = C.AssetSeq  
               LEFT OUTER JOIN _TDAItemClass AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                               AND A.ItemSeq    = D.ItemSeq  
                                                               AND D.UMajorItemClass IN (2001,2004)  
         WHERE A.CompanySeq = @CompanySeq  
           AND C.SMAssetGrp = 6008005
            
        
        
        SELECT @DateFr = @StdYM + '01', 
               @DateTo = CONVERT(NCHAR(8),DATEADD(DAY, -1, CONVERT(NCHAR(8),DATEADD(MONTH, 1, @StdYM + '01'),112)),112)
        
        
        -- 창고재고 가져오기  
        EXEC _SLGGetInOutStockAssy  @CompanySeq   = @CompanySeq,   -- 법인코드  
                                    @BizUnit      = @BizUnit,      -- 사업부문  
                                    @FactUnit     = 0,     -- 생산사업장  
                                    @DateFr       = @DateFr,       -- 조회기간Fr  
                                    @DateTo       = @DateTo,       -- 조회기간To  
                                    @WHSeq        = 0,        -- 창고지정  
                                    @SMWHKind     = 0,     -- 창고구분별 조회  
                                    @CustSeq      = 0,      -- 수탁거래처  
                                    @IsTrustCust  = '0',  -- 수탁여부  
                                    @IsSubDisplay = '0', -- 기능창고 조회  
                                    @IsUnitQry    = '0',    -- 단위별 조회  
                                    @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고  
                                    @MngDeptSeq   = 0  

        SELECT ISNULL(A.ItemSeq, 0) AS ItemSeq, 
               SUM(ROUND(ISNULL(A.STDStockQty, 0), @EnvMatQty)) - SUM(ROUND(ISNULL(A.STDPrevQty, 0), @EnvMatQty)) AS StockQty
          INTO #TMP_Table 
          FROM #GetInOutStock AS A  
         WHERE (A.STDPrevQty <> 0 OR A.STDInQty <> 0 OR A.STDOutQty <> 0 OR A.STDStockQty <> 0)  
         GROUP BY ISNULL(A.ItemSeq, 0) 
         HAVING SUM(ROUND(ISNULL(A.STDStockQty, 0), @EnvMatQty)) - SUM(ROUND(ISNULL(A.STDPrevQty, 0), @EnvMatQty)) <> 0 
        
        
        INSERT INTO #BaseData ( MatItemSeq, WorkReportSeq, StockQty )
        SELECT Z.MatItemSeq, MAX(Z.WorkReportSeq) AS WorkReportSeq, MAX(Q.StockQty) AS StockQty
          FROM _TPDSFCMatInPut AS Z 
          JOIN ( 
                SELECT A.ItemSeq, MAX(ISNULL(B.InputDate,'')) AS InputDate 
                  FROM #TMP_Table                   AS A 
                  JOIN _TPDSFCMatInPut   AS B ON ( B.CompanySeq = @CompanySeq AND B.MatItemSeq = A.ItemSeq AND LEFT(B.InputDate,6) = @StdYM ) 
                 GROUP BY A.ItemSeq 
               ) AS Y ON ( Y.ItemSeq = Z.MatItemSeq AND Y.InputDate = Z.InputDate ) 
          JOIN #TMP_Table AS Q ON ( Q.ItemSeq = Z.MatItemSeq ) 
         GROUP BY Z.MatItemSeq
    END 
    ELSE IF @WorkingTag = 'D' 
    BEGIN
    
        --SELECT 1 
        INSERT INTO #BaseData ( MatItemSeq, WorkReportSeq, StockQty, MaxItemSerl )
        SELECT A.MatItemSeq, A.WorkReportSeq, A.Qty, A.ItemSerl 
          FROM _TPDSFCMatinput      AS A 
          JOIN _TPDSFCWorkReport    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.PgmSeq = @PgmSeq 
           AND LEFT(A.InputDate,6) = @StdYM 
           AND B.FactUnit = ( SELECT TOP 1 FactUnit FROM _TDAFactUnit WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit )
    END 
    
    --select * from #BaseData 
    --return 
    
    IF NOT EXISTS (SELECT 1 FROM #BaseData)
    BEGIN
        SELECT ISNULL(@Status,0) AS Status,  
               ISNULL(@Result,'') AS Result 
    
        RETURN 
    END 
    
    DECLARE @Cnt        INT, 
            @MaxIDX_No  INT, 
            @XmlData    NVARCHAR(MAX)
    
    CREATE TABLE #TCOMCloseItemSubCheck (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2639, 'DataBlock3', '#TCOMCloseItemSubCheck'    
    
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                SELECT @WorkingTag AS WorkingTag, 
                                                       1 AS IDX_NO, 
                                                       1 AS DataSeq, 
                                                       0 AS Status, 
                                                       0 AS Selected, 
                                                       'DataBlock3' AS TABLE_NAME, 
                                                       @StdYM + '01' AS Date, 
                                                       @StdYM + '01' AS DateOld, 
                                                       2894 AS ServiceSeq, 
                                                       13 AS MethodSeq, 
                                                       0 AS RptUnit, 
                                                       (SELECT TOP 1 ItemSeq
                                                          FROM _TDAItem AS A 
                                                          JOIN _TDAItemAsset AS B ON ( B.CompanySeq = A.CompanySeq AND B.AssetSeq = A.AssetSeq ) 
                                                         WHERE A.CompanySeq = @CompanySeq 
                                                           AND B.SMAssetGrp = 6008005
                                                       ) AS ItemSeq, 
                                                       (SELECT DeptSeq FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq) AS DeptSeq, 
                                                       3 AS FactUnit, 
                                                       3 AS FactUnitOld
                                                 FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS   
                                             )
                             ) 

    
    --select @XmlData 
    --return 

    
    -- 업무 마감 체크 
    INSERT INTO #TCOMCloseItemSubCheck 
    EXEC _SCOMCloseItemSubCheck @xmlDocument = @XmlData, 
                                @xmlFlags = 2, 
                                @ServiceSeq = 2639,
                                @WorkingTag = N'', 
                                @CompanySeq = @CompanySeq, 
                                @LanguageSeq = 1, 
                                @UserSeq = @UserSeq, 
                                @PgmSeq = @PgmSeq 
    
    SELECT @Status = ( SELECT MAX(Status) FROM #TCOMCloseItemSubCheck ) 
    SELECT @Result = ( SELECT MAX(Result) FROM #TCOMCloseItemSubCheck ) 
    
    IF @Status <> 0 
    BEGIN
        SELECT ISNULL(@Status,0) AS Status,  
               ISNULL(@Result,'') AS Result 
        RETURN 
    END 
    
    SELECT @Cnt = 1 
    SELECT @MaxIDX_No = MAX(IDX_NO) FROM #BaseData 
    

    --select @Cnt, @MaxIDX_No 
    
    CREATE TABLE #TPDSFCMatinput (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2909, 'DataBlock2', '#TPDSFCMatinput'           
    
    CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2619, 'DataBlock3', '#TLGInOutDailyItemSub'  

    ALTER TABLE #TLGInOutDailyItemSub ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsLot        NCHAR(1) ---- Lot관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsSerial     NCHAR(1) ---- 시리얼관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크
    ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD CustSeq    INT ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD LastUserSeq    INT ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD LastDateTime   DATETIME ----  체크

--select * from _TPDSFCMatInputLog where WorkReportSeq = 13843 
    
    -- 투입 처리하기전 자재투입 스케쥴링을 중지 상태로 변경 
    UPDATE A
       SET enabled = '0'
      FROM msdb.dbo.sysjobs AS A  
    WHERE job_id = 'DBBA9E16-54B7-4FFA-AE71-11DDE4ACC052' -- 생산투입 POP연동_KPXCM 
        
    
    WHILE ( 1 = 1 ) 
    BEGIN
        
        IF @WorkingTag = 'A' 
        BEGIN 
            UPDATE Z
               SET MaxItemSerl = W.ItemSerl + 1 
              FROM #BaseData AS Z 
              CROSS APPLY ( 
                            SELECT A.WorkReportSeq, MAX(ItemSerl) AS ItemSerl 
                              FROM (
                                    SELECT WorkReportSeq, ItemSerl 
                                      FROM _TPDSFCMatInput 
                                     WHERE CompanySeq = @CompanySeq
                                       AND Z.WorkReportSeq = WorkReportSeq
                                    UNION  
                                    SELECT WorkReportSeq, ItemSerl 
                                      FROM _TPDSFCMatInputLog
                                     WHERE CompanySeq = @CompanySeq
                                       AND Z.WorkReportSeq = WorkReportSeq
                                    ) AS A 
                             GROUP BY A.WorkReportSeq
                          ) AS W 
             WHERE Z.IDX_NO = @Cnt 
        END 
        
        -- 자재투입 TR 데이터 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                    SELECT @WorkingTag AS WorkingTag, 
                                                           MaxItemSerl AS IDX_NO, 
                                                           1 AS DataSeq, 
                                                           0 AS Status, 
                                                           0 AS Selected, 
                                                           'DataBlock2' AS TABLE_NAME, 
                                                           '0' AS IsPjt, 
                                                           0 AS WBSSeq, 
                                                           A.WorkReportSeq, 
                                                           A.MaxItemSerl AS ItemSerl, 
                                                           B.WorkDate AS InputDate,
                                                           A.MatItemSeq, 
                                                           C.MatUnitSeq, 
                                                           0 AS StdUnitSeq, 
                                                           A.StockQty AS Qty, 
                                                           0 AS StdUnitQty, 
                                                           '' AS RealLotNo, 
                                                           '' SerialNoFrom, 
                                                           B.ProcSeq AS ProcSeq, 
                                                           '0' AS AssyYn, 
                                                           '0' AS IsConsign, 
                                                           B.GoodItemSeq, 
                                                           6042004 AS InputType, 
                                                           '0' AS IsPaid, 
                                                           '월말 재공재고조정' AS Remark, 
                                                           0 AS WHSeq, 
                                                           0 AS ProdWRSeq 
                                                      FROM #BaseData AS A 
                                                      LEFT OUTER JOIN _TPDSFCWorkReport AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
                                                      OUTER APPLY (
                                                                    SELECT TOP 1 MatUnitSeq
                                                                      FROM _TPDSFCMatInput 
                                                                     WHERE CompanySeq = @CompanySeq 
                                                                       AND WorkReportSeq = A.WorkReportSeq 
                                                                       AND MatItemSeq = A.MatItemSeq 
                                                                  ) AS C 
                                                     WHERE A.IDX_NO = @Cnt 
                                                     FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS   
                                                 )
                                 ) 
    
        TRUNCATE TABLE #TPDSFCMatinput 
        
        INSERT INTO #TPDSFCMatinput 
        EXEC _SPDSFCWorkReportMatSave @xmlDocument = @XmlData,
                                      @xmlFlags = 2,
                                      @ServiceSeq = 2909, 
                                      @WorkingTag = N'', 
                                      @CompanySeq = @CompanySeq, 
                                      @LanguageSeq = 1,
                                      @UserSeq = @UserSeq, 
                                      @PgmSeq = @PgmSeq 
        
        SELECT @Status = ( SELECT MAX(Status) FROM #TPDSFCMatinput ) 
        SELECT @Result = ( SELECT MAX(Result) FROM #TPDSFCMatinput ) 
        
        
        -- 자재투입 수불 데이터 
        SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                    SELECT @WorkingTag AS WorkingTag, 
                                                           MaxItemSerl AS IDX_NO, 
                                                           1 AS DataSeq, 
                                                           0 AS Status, 
                                                           0 AS Selected, 
                                                           'DataBlock3' AS TABLE_NAME, 
                                                           130 AS InOutType, 
                                                           8023015 AS InOutKind, 
                                                           MaxItemSerl AS InOutSerl, 
                                                           0 AS DataKind, 
                                                           0 AS InWHSeq, 
                                                           A.WorkReportSeq AS InOutSeq, 
                                                           A.MaxItemSerl AS InOutDataSerl, 
                                                           A.MatItemSeq AS ItemSeq, 
                                                           C.MatUnitSeq AS UnitSeq, 
                                                           0 AS StdUnitSeq, 
                                                           A.StockQty AS Qty, 
                                                           A.StockQty AS STDQty, 
                                                           '' AS LotNo, 
                                                           6042004 AS InOutDetailKind, 
                                                           '월말 재공재고조정' AS Remark, 
                                                           13 AS OutWHSeq -- 우레탄 현장창고 
                                                      FROM #BaseData AS A 
                                                      LEFT OUTER JOIN _TPDSFCWorkReport AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
                                                      OUTER APPLY (
                                                                    SELECT TOP 1 MatUnitSeq
                                                                      FROM _TPDSFCMatInput 
                                                                     WHERE CompanySeq = @CompanySeq 
                                                                       AND WorkReportSeq = A.WorkReportSeq 
                                                                       AND MatItemSeq = A.MatItemSeq 
                                                                  ) AS C 
                                                     WHERE A.IDX_NO = @Cnt 
                                                     FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS   
                                                 )
                                 ) 
        
        
        
        TRUNCATE TABLE #TLGInOutDailyItemSub 
        
        INSERT INTO #TLGInOutDailyItemSub 
        EXEC _SLGInOutDailyItemSubSave @xmlDocument = @XmlData, 
                                       @xmlFlags = 2,
                                       @ServiceSeq = 2619,
                                       @WorkingTag = N'', 
                                       @CompanySeq = @CompanySeq, 
                                       @LanguageSeq = 1, 
                                       @UserSeq = @UserSeq, 
                                       @PgmSeq = @PgmSeq 
        
        SELECT @Status = ( SELECT MAX(Status) FROM #TLGInOutDailyItemSub ) 
        SELECT @Result = ( SELECT MAX(Result) FROM #TLGInOutDailyItemSub ) 
        
        IF @Cnt >= ISNULL(@MaxIDX_No,0)
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
        
        
    END 
    
    -- 자재투입 스케쥴링을 시작으로 변경
    UPDATE A
       SET enabled = '1'
      FROM msdb.dbo.sysjobs AS A  
    WHERE job_id = 'DBBA9E16-54B7-4FFA-AE71-11DDE4ACC052' -- 생산투입 POP연동_KPXCM 
    
    
    SELECT ISNULL(@Status,0) AS Status,  
           ISNULL(@Result,'') AS Result 
    
    RETURN
    --*/
--GO
--begin tran 
--exec KPXCM_SLGWHAssyStockListAdjustApply @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>1</IsChangedMst>
--    <BizUnit>1</BizUnit>
--    <StdYM>201510</StdYM>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1032828,@WorkingTag=N'A',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027704


--select * from _TPDSFCMatinput where PgmSeq = 1027704
--select * from _TLGInOutDailyItemSub where PgmSeq = 1027704
----select * from _TPDSFCMatInPut where companyseq = 2 and WorkReportSeq = 9597 and matitemseq = 1352
----select * from _TLGInOutDailyItemSub where companyseq = 2 and inouttype = 130 and itemseq = 1352 and InOutSeq = 9597 
----select * from _TLGInOutDailyItem where companyseq = 2 and inouttype = 130 and InOutSeq = 9597 

----select * from _TLGInOutDaily where companyseq = 2 and inouttype = 130 and InOutSeq = 9597 
----select * from _TLGInOutDailyItem where companyseq = 2 and inouttype = 130 and InOutSeq = 9597
----select * from _TLGInOutDailyItemSub where companyseq = 2 and inouttype = 130 and InOutSeq = 9597 

--rollback 

