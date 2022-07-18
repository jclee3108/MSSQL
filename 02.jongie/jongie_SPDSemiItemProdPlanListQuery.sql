  
IF OBJECT_ID('jongie_SPDSemiItemProdPlanListQuery') IS NOT NULL   
    DROP PROC jongie_SPDSemiItemProdPlanListQuery  
GO  
  
-- v2013.10.08  
  
-- 하위반제품생산계획대상조회_jongie(조회) by이재천   
CREATE PROC jongie_SPDSemiItemProdPlanListQuery  
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
            -- 조회조건   
            @FactUnit       INT,  
            @ProdPlanYM     NVARCHAR(6), 
            @DeptSeq        INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100), 
            @Spec           NVARCHAR(100), 
            @SemiItemName   NVARCHAR(100), 
            @SemiItemNo     NVARCHAR(100), 
            @SemiSpec       NVARCHAR(100) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit     = ISNULL(FactUnit,0), 
           @ProdPlanYM   = ISNULL(ProdPlanYM,''), 
           @DeptSeq      = ISNULL(DeptSeq,0), 
           @ItemName     = ISNULL(ItemName,''), 
           @ItemNo       = ISNULL(ItemNo,''), 
           @Spec         = ISNULL(Spec,''), 
           @SemiItemName = ISNULL(SemiItemName,''), 
           @SemiItemNo   = ISNULL(SemiItemNo,''), 
           @SemiSpec     = ISNULL(SemiSpec,'') 
           
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
      
      WITH (
            FactUnit        INT,  
            ProdPlanYM      NVARCHAR(6), 
            DeptSeq         INT, 
            ItemName        NVARCHAR(100),
            ItemNo          NVARCHAR(100),
            Spec            NVARCHAR(100), 
            SemiItemName    NVARCHAR(100), 
            SemiItemNo      NVARCHAR(100), 
            SemiSpec        NVARCHAR(100) 
           )    
    
    -- 최종조회   
    SELECT ROW_NUMBER() OVER (Order BY ProdPlanSeq) AS IDX_NO, 0 AS Status, CONVERT(NVARCHAR(1000),NULL) AS Result, NULL AS MessageType,  
           A.CompanySeq, A.ProdPlanSeq, A.FactUnit, A.ProdPlanNo, A.SrtDate, 
           A.EndDate AS ProdPlanEndDate, A.DeptSeq AS ProdDeptSeq, A.WorkcenterSeq, A.ItemSeq, A.BOMRev, A.ProcRev, 
           A.UnitSeq, A.BaseStkQty, A.PreSalesQty, A.SOQty, A.StkQty, 
           A.PreInQty, A.ProdQty AS ProdPlanQty, A.StdProdQty, A.SMSource, A.SourceSeq, 
           A.SourceSerl, A.Remark, IsCfm, CfmEmpSeq, BatchSeq, StdUnitSeq
    
      INTO #TPDMPProdPlan
      FROM _TPDMPSDailyProdPlan AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND (@FactUnit = 0 OR A.FactUnit = FactUnit) 
       AND @ProdPlanYM = LEFT(A.EndDate,6) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@ItemName = '' OR B.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR B.ItemNo LIKE @ItemNo + '%') 
       AND (@Spec = '' OR B.Spec LIKE @Spec + '%') 
     
     --select * from #TPDMPProdPlan
     --return
-------------------------------------------------------------------------------------------------------------- 
    DECLARE @EnvValue INT
    SELECT @EnvValue =  CONVERT(INT,EnvValue) FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq like '6219%'           
    
    -- 품목별 공정정보      
    DECLARE @ItemProcInfo TABLE      
    (      
        FactUnit        INT,      
        ItemSeq         INT,      
        BOMRev          NCHAR(2),      
        ProcRev         NCHAR(2),      
        ProcSeq         INT,      
        WorkCenterSeq   INT      
    )      
      
    DECLARE @ProdItem TABLE      
    (      
        SrtDate     NCHAR(8),      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        BOMRev      NCHAR(2),      
        ProcRev     NCHAR(2),      
        ProdQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        FactUnit    INT      
       
    )      
      
    INSERT INTO @ProdItem      
    SELECT B.SrtDate, A.ProdPlanEndDate, A.ItemSeq, A.BOMRev,A.ProcRev,A.ProdPlanQty, A.ProdPlanSeq, A.FactUnit      
      FROM #TPDMPProdPlan AS A JOIN _TPDMPSDailyProdPlan AS B ON B.CompanySeq = @CompanySeq and A.ProdPlanSeq = B.ProdPlanSeq AND A.FactUnit = B.FactUnit      
     WHERE B.SMSource < 6054003      
     ORDER BY EndDate      
         
    UPDATE @ProdItem      
       SET BOMRev = B.BOMRev      
      FROM @ProdItem AS A JOIN @ItemProcInfo AS B ON A.FactUnit = B.FactUnit AND a.ItemSeq = B.ItemSeq      
      
    CREATE TABLE #MatNeed_GoodItem        
    (        
        IDX_NO          INT IDENTITY(1,1),        
        ItemSeq         INT,        -- 제품코드        
        ProcRev         NCHAR(2),   -- 공정흐름차수        
        BOMRev          NCHAR(2),   -- BOM차수        
        ProcSeq         INT,        -- 공정코드        
        AssyItemSeq     INT,        -- 공정품코드        
        UnitSeq         INT,        -- 단위코드     (공정품코드가 있으면 공정품단위코드, 없으면 제품단위코드)        
        Qty             DECIMAL(19, 5),    -- 제품수량     (공정품코드가 있으면 공정품수량)        
        ProdPlanSeq     INT,        -- 생산계획내부번호 (생산의뢰에서 추가된 옵션자재를 가져오기위해)        
        WorkOrderSeq    INT,        -- 작업지시내부번호 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)      
        WorkOrderSerl   INT,        -- 작업지시내부번호 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)         
        IsOut           NCHAR(1),    -- 로스율 적용에 사용 '1'이면 OutLossRate 적용        
        WorkDAte        NCHAR(8),  
        SemiGoodSeq     INT NULL,  
        SemiBOMRev      NCHAR(2) NULL  
    )        
             
    CREATE TABLE #MatNeed_MatItem_Result        
    (        
        IDX_NO          INT,            -- 제품코드        
        MatItemSeq      INT,            -- 자재코드        
        UnitSeq         INT,            -- 자재단위        
        NeedQty         DECIMAL(19,5),  -- 소요량        
        InputType       INT        
    )        
        
    CREATE TABLE #NeedQtySum        
    (        
        WorkOrderSeq        INT,        
        ProcSeq             INT,        
        MatItemSeq          INT,        
        UnitSeq             INT,        
        Qty                 NUMERIC(19,5),        
        NeedQty             NUMERIC(19,5),        
        TimeStep            NUMERIC(19,5)        
    )        
      
    DECLARE @SemiGoodQty TABLE      
    (      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        FactUnit    INT,      
        SMAssetGrp  INT      
    )      
          
    -- 소요량계산 을 위한 품목담기.        
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)        
    SELECT W.ItemSeq, W.ProcRev, W.BomRev, 0, 0, B.STDUnitSeq, W.ProdQty, W.ProdPlanSeq, 0,0,'0',W.SrtDate         
      FROM @ProdItem    AS W        
       JOIN _TDAItemDefUnit AS B ON W.ItemSeq = B.ItemSeq AND @CompanySeq = B.CompanySeq   
                                AND B.UMModuleSeq = 1003003    -- 소요자재 가져오기전에 생산단위를 담도록 수정 (_SPDMMGetItemNeedQty상에서 BOM단위로 환산하여 소요량 구하기위해)  
                                                               -- 11.10.07 김세호 추가  
   
    -- 소요자재 가져오기        
    EXEC dbo._SPDMMGetItemNeedQty @CompanySeq        
    
    INSERT INTO @SemiGoodQty      
    SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
           A.ItemSeq, A.Qty, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, F.SubItemBomRev,'00',1,0, D.SMAssetGrp      
      FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
                                  JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq AND C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                  JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq AND D.CompanySeq = @CompanySeq      
                                  JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008002,6008004,6008005)       
                                                      AND E.CompanySeq = @CompanySeq      
                                  JOIN _TPDBOM    AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
      
    DECLARE @MaxCheckDate NCHAR(8), @CheckDate NCHAR(8)      
    
    SELECT @CheckDate = Min(WorkDAte) from @ProdItem       
    SELECT @MaxCheckDate = MAX(WorkDAte) from @ProdItem       
    
    UPDATE @SemiGoodQty      
       SET FactUnit = B.FactUnit      
      FROM @SemiGoodQty AS A JOIN @ProdItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
    
    DELETE @SemiGoodQty      
      FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit      
    
    UPDATE @SemiGoodQty      
       SET SemiProcRev = B.ProcRev      
      FROM @SemiGoodQty  AS A JOIN       
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev      
       FROM @SemiGoodQty AS A        
        JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit       
                                            AND A.SemiGoodSeq = B.ItemSeq        
                                            AND A.SemiBomrev = B.BOMrev      
                                            AND B.CompanySeq = @CompanySeq      
                                            AND B.FrDate <= A.WorkDate      
                                            AND B.ToDate >= A.WorkDate      
      GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev
    ) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev      
       
  
      
    SELECT @CheckDate = Min(WorkDAte) FROM @ProdItem       
    SELECT @MaxCheckDate = MAX(WorkDAte) FROM @ProdItem       
    
    DECLARE @levCnt INT      
    
    SELECT @levCnt = 1      
    
    --## 옵션 구성품 가져오기(옵션 추가로 반제품이 달린 경우 무한 루프 돌게 됨. 그래서 해당 로직 추가 2011. 1. 12 hkim ##  
    CREATE TABLE #Option_Item  
    (  
        ItemSeq INT  
    )  
    INSERT INTO #Option_Item  
    SELECT DISTINCT C.MatItemSeq  
      FROM _TCOMSourceDaily AS A  
           JOIN @SemiGoodQty AS B ON A.ToSeq = B.ProdPlanSeq   
           JOIN _TPDROUItemProcMatAdd AS C ON A.FromSeq = C.ProdReqSeq AND A.FromSerl = C.ProdReqSerl  
     WHERE A.ToTableSeq = 32 AND A.FromTableSeq =  1        
    --## 옵션 구성품 가져오기 끝 (옵션 추가로 반제품이 달린 경우 무한 루프 돌게 됨. 그래서 해당 로직 추가 2011. 1. 12 hkim ##  
      
     
    WHILE(1=1)  
    BEGIN      
    
    IF (SELECT Count(*) FROM @SemiGoodQty WHERE LevCnt = @levCnt) = 0 BREAK      
    
    DELETE FROM #MatNeed_GoodItem      
    DELETE FROM #MatNeed_MatItem_Result        
    
    -- 소요량계산 을 위한 품목담기.        
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate, SemiGoodSeq, SemiBOMRev)          
    SELECT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomRev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate, W.SemiGoodSeq, W.SemiBOMRev        
      FROM @SemiGoodQty    AS W    
      JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                               AND @CompanySeq = D.CompanySeq   
                               AND D.UMModuleSeq = 1003003      -- 소요자재 가져오기전에 생산단위를 담도록 수정 (_SPDMMGetItemNeedQty상에서 BOM단위로 환산하여 소요량 구하기위해)  
                                                                -- 11.10.07 김세호 추가  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008004  
   -- 2012. 5. 22 hkim 아래부분 다시 주석처리 ;; 옵션을 사용할 경우 1레벨 이하의 반제품 풀어지지 않음      
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim 옵션 구성품은 자재소요에서 제외(반제품인 경우 무한루프 돈다)  
  
   --제품도 생산계획을 생성할 수 있도록 추가 12.05.14 snheo  
   INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)          
   SELECT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomRev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate         
     FROM @SemiGoodQty    AS W    
    JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                         AND @CompanySeq = D.CompanySeq   
                         AND D.UMModuleSeq = 1003003      -- 소요자재 가져오기전에 생산단위를 담도록 수정 (_SPDMMGetItemNeedQty상에서 BOM단위로 환산하여 소요량 구하기위해)  
                                                            -- 11.10.07 김세호 추가  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008002     
   -- 2012. 5. 22 hkim 아래부분 다시 주석처리 ;; 옵션을 사용할 경우 1레벨 이하의 반제품 풀어지지 않음         
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim 옵션 구성품은 자재소요에서 제외(반제품인 경우 무한루프 돈다)  
      
   INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate, SemiGoodSeq, SemiBOMRev)          
   SELECT DISTINCT B.ItemSeq, B.ProcRev, B.BOMRev, C.ProcSeq, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate, W.SemiGoodSeq, W.SemiBomRev  
     FROM @SemiGoodQty    AS W JOIN _TPDMPSDailyProdPlan AS B On W.ProdPlanSeq = B.ProdPlanSeq AND B.CompanySeq = @CompanySeq      
                               JOIN _TPDROUItemProcMat   AS C ON B.ItemSeq = C.ItemSeq AND B.BomRev = C.BOMRev AND B.ProcRev = C.ProcRev AND W.SemiGoodSeq = C.AssyItemSeq AND C.CompanySeq = @CompanySeq       
  
                                JOIN _TDAItemDefUnit AS D ON W.SemiGoodSeq = D.ItemSeq  
                                                     AND @CompanySeq = D.CompanySeq   
                                                     AND D.UMModuleSeq = 1003003      -- 소요자재 가져오기전에 생산단위를 담도록 수정 11.10.07 김세호 추가  
                                                                                        -- (_SPDMMGetItemNeedQty상에서 BOM단위로 환산하여 소요량 구하기위해)  
    WHERE W.levCnt = @levCnt      
      AND W.SMAssetGrp = 6008005  
   -- 2012. 5. 22 hkim 아래부분 다시 주석처리 ;; 옵션을 사용할 경우 1레벨 이하의 반제품 풀어지지 않음            
      --AND ( NOT EXISTS (SELECT 1 FROM #Option_Item) OR (W.SemiGoodSeq NOT IN (SELECT ISNULL(ItemSeq, 0) FROM #Option_Item) AND LevCnt <> 1) )      -- 2011. 1. 12 hkim 옵션 구성품은 자재소요에서 제외(반제품인 경우 무한루프 돈다)  
  
   -- 소요자재 가져오기        
   EXEC dbo._SPDMMGetItemNeedQty @CompanySeq        
     
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, F.SubItemBomRev,'00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                            JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN ( 6008004)       
                                                              and E.CompanySeq = @CompanySeq      
            LEFT OUTER JOIN _TPDBOM    AS F ON A.SemiGoodSeq = F.ItemSeq AND A.SemiBOMRev = F.ItemBOMRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
  
  
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, ISNULL(F.SubItemBomRev,'00'),'00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                          JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN ( 6008002)       
                                                              and E.CompanySeq = @CompanySeq      
                                          LEFT OUTER JOIN _TPDBOM    AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq      
     
  
   INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)      
   SELECT DISTINCT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),      
                   0, A.Qty, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, '00','00',@levCnt+1,0,D.SMAssetGrp      
     FROM #MatNeed_GoodItem AS A JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
            JOIN _TDAItem AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                                          JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                                          JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008005)       
                                                              and E.CompanySeq = @CompanySeq      
  
  
   -- BOM 차수 NULL 인건 사업장별생산품목의 MAX차수로 UPDATE  
   --(제품A - 반제품A - 재공품A - 반제품B 의 경우 반제품의 B의 BOM 차수를 못가져온다   
   -- 반제품 A의 공정별로 풀어서 재공품 A - 반제품 B의 BOM관계를 담아야돼는데, 반제품 A의 공정흐름차수를 명확히 알수가 없기 때문에)     -- 12.11.28 BY 김세호  
  
    UPDATE @SemiGoodQty  
       SET SemiBomrev = (SELECT  ISNULL(MAX(BOMRev), '00') FROM _TPDROUItemProcRevFactUnit WHERE CompanySeq = @CompanySeq AND ItemSeq = A.SemiGoodSeq)  
      FROM @SemiGoodQty     AS A  
     WHERE SemiBomrev IS NULL  
  
  
    UPDATE @SemiGoodQty      
       SET FactUnit = B.FactUnit      
      FROM @SemiGoodQty AS A JOIN @ProdItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
  
  
    DELETE @SemiGoodQty      
     FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit      
  
  
    UPDATE @SemiGoodQty      
       SET SemiProcRev = B.ProcRev      
     FROM @SemiGoodQty  AS A JOIN       
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev      
      FROM @SemiGoodQty AS A        
      JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit AND A.SemiGoodSeq = B.ItemSeq AND A.SemiBomrev = B.BOMrev      
                                          AND B.CompanySeq = @CompanySeq AND B.FrDate <= A.WorkDate AND B.ToDate >= A.WorkDate      
     WHERE A.levCnt = @levCnt+1      
     GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev
    ) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev      
     WHERE levCnt = @levCnt+1      
  
    SELECT @levCnt = @levCnt + 1      
    
    END      
    
    -- 공정품 삭제      
    DELETE @SemiGoodQty      
      FROM @SemiGoodQty AS A JOIN _TDAItem AS C ON A.SemiGoodSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4      
                             JOIN _TDAItemAsset AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq      
                             JOIN _TDASMinor AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq = 6008005 and E.CompanySeq = @CompanySeq      
    
    UPDATE @SemiGoodQty      
       SET ItemSeq = B.ItemSeq      
      FROM @SemiGoodQty AS A JOIN _TPDMPSDailyProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq and CompanySeq = @CompanySeq      
     WHERE A.ItemSeq = 0      
      
    DECLARE @SemiGoodQtySeq TABLE      
    (      
        Seq         INT IDENTITY ,      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        SemiProdPlanSeq INT,      
        ProdPlanNo  NVARCHAR(30),      
        FactUnit    INT      
    )      
  
    --동일한 반제품의 경우 하나의 계획으로 생성되도록   
    INSERT INTO @SemiGoodQtySeq      
    SELECT DISTINCT A.WorkDate,      
           A.ItemSeq,      
           A.ProdQty,      
           A.SemiGoodSeq,      
           A.NeedQty,      
           A.ProdPlanSeq, 
           A.SemiBomrev, 
           A.SemiProcRev, 
           A.levCnt, 
           0, 
           B.ProdPlanNo, 
           B.FactUnit 
      FROM @SemiGoodQty   AS A 
      JOIN #TPDMPProdPlan AS B ON A.ProdPlanSeq = B.ProdPlanSeq      
                
    -- 원천테이블            
    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))                    

    -- 원천 데이터 테이블            
    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,                    
                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))                          
            

    INSERT #TMP_SOURCETABLE              
             
    SELECT 1, '_TPDMPSProdReqItem'       -- 생산의뢰        
    
    EXEC _SCOMSourceTracking  @CompanySeq, '_TPDMPSDailyProdPlan', '#TPDMPProdPlan','ProdPlanSeq', '',''         
    
    DECLARE @SemiGoodQtySeqADD TABLE      
    (      
        WorkDate    NCHAR(8),      
        ItemSeq     INT,      
        ProdQty     DECIMAL(19,5),      
        SemiGoodSeq INT,      
        NeedQty     DECIMAL(19,5),      
        ProdPlanSeq INT,      
        SemiBomrev  NCHAR(2),      
        SemiProcRev NCHAR(2),      
        levCnt      INT,      
        SemiProdPlanSeq INT,      
        ProdPlanNo  NVARCHAR(30),      
        FactUnit    INT,      
        SMAddType   INT      
    )      
    
      INSERT INTO @SemiGoodQtySeqADD      
      SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.ProdPlanEndDate)),112) AS WorkDate,      
             A.ItemSeq      AS ItemSeq,      
             A.ProdplanQty  AS ProdQty,      
             C.MatItemSeq   As SemiGoodSeq,      
             CEILING(A.ProdplanQty * C.NeedQtyDenominator / C.NeedQtyNumerator) AS NeedQty,   -- 올림처리 100831 이재혁      
             A.ProdPlanSeq  AS ProdPlanSeq,      
             MAX(F.BomRev),      
             MAX(F.ProcRev),      
             1,  -- 9999에서 1로 변경    
             0,      
             A.ProdPlanNo,      
             A.FactUnit,      
             C.SMAddType      
    
        FROM #TPDMPProdPlan AS A JOIN #TCOMSourceTracking           AS B ON A.IDX_NO = B.IDX_NO      
                                 JOIN _TPDROUItemProcMatAdd         AS C ON B.Seq = C.ProdReqSeq AND B.Serl = C.ProdReqSerl AND C.CompanySeq = @CompanySeq      
                                 JOIN _TDAItem                      AS D ON C.MatItemSeq = D.ItemSeq AND D.CompanySeq = @CompanySeq      
                                 JOIN _TDAItemAsset                 AS E ON D.AssetSeq = E.AssetSeq AND E.CompanySeq = @CompanySeq AND E.SMAssetGrp IN (6008002, 6008004)       
                                 JOIN _TPDROUItemProcRevFactUnit    AS F ON A.FactUnit = F.FactUnit AND C.MatItemSeq = F.ItemSeq AND F.CompanySeq = @CompanySEq      
      GROUP BY A.ProdPlanEndDate, A.ItemSeq, A.ProdplanQty, C.MatItemSeq ,A.ProdplanQty, 
               C.NeedQtyDenominator, C.NeedQtyNumerator ,A.ProdPlanSeq, A.ProdPlanNo, A.FactUnit, C.SMAddType       
    
    -- 삭제 반제품       
          
    DELETE @SemiGoodQtySeqADD      
      FROM @SemiGoodQtySeqADD AS A JOIN @SemiGoodQtySeq AS B ON A.ProdPlanSeq = B.ProdPlanSeq And A.SemiGoodSeq = B.SemiGoodSeq      
     WHERE A.SMAddType = 6048001 -- 삭제      
  
  
    -- ######################### 2012. 5. 23 hkim While문으로 모든 레벨을 풀도록  
    -- 옵션품 하위의 반제품 풀기  
    DELETE @SemiGoodQty   

    INSERT INTO @SemiGoodQty (WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit)      
    SELECT WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit  
      FROM @SemiGoodQtySeqADD  
    
    SELECT @levCnt = 1  
    
    WHILE(1=1)      
    BEGIN      
    TRUNCATE TABLE #MatNeed_GoodItem     
    TRUNCATE TABLE #MatNeed_MatItem_Result  

     
    IF (SELECT Count(*) FROM @SemiGoodQty WHERE LevCnt = @levCnt) = 0 BREAK      
    
    INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkDate)            
    SELECT DISTINCT W.SemiGoodSeq, W.SemiProcRev, W.SemiBomrev, 0, 0, D.STDUnitSeq, W.NeedQty, W.ProdPlanSeq, 0,0,'0', W.WorkDate         
      FROM @SemiGoodQty     AS W --JOIN _TPDMPSDailyProdPlan AS B On W.ProdPlanSeq = B.ProdPlanSeq AND B.CompanySeq = @CompanySeq  
      JOIN _TDAItem         AS I ON W.SemiGoodSeq = I.ItemSeq AND I.CompanySeq = @CompanySeq        
      JOIN _TDAItemAsset    AS A ON I.AssetSeq = A.AssetSeq AND A.CompanySeq = @CompanySeq        
      JOIN _TDAItemDefUnit  AS D ON W.SemiGoodSeq = D.ItemSeq AND @CompanySeq = D.CompanySeq     
                                AND D.UMModuleSeq = 1003003      -- 소요자재 가져오기전에 생산단위를 담도록 수정 11.10.07 김세호 추가    
                                                                 -- (_SPDMMGetItemNeedQty상에서 BOM단위로 환산하여 소요량 구하기위해)    
     WHERE W.levCnt = @levCnt      
       AND A.SMAssetGrp = 6008004        
    
    -- 소요자재 가져오기          
    EXEC dbo._SPDMMGetItemNeedQty @CompanySeq          
    
    INSERT INTO @SemiGoodQty(WorkDate,ItemSeq,ProdQty,SemiGoodSeq ,NeedQty ,ProdPlanSeq ,SemiBomrev,SemiProcRev ,levCnt,FactUnit,SMAssetGrp)        
    SELECT CONVERT(NCHAR(8),(DATEADD(DD,@EnvValue *(-1),A.WorkDate)),112),        
                   0, 0, B.MatItemSeq, B.NeedQty, A.ProdPlanSeq, ISNULL(F.SubItemBomRev,'00'),'00',@levCnt+1,0,D.SMAssetGrp        
      FROM #MatNeed_GoodItem        AS A 
      JOIN #MatNeed_MatItem_Result  AS B ON A.IDX_NO = B.IDX_NO        
      JOIN _TDAItem                 AS C ON B.MatItemSeq = C.ItemSeq and C.CompanySeq = @CompanySeq --and AssetSeq = 4        
      JOIN _TDAItemAsset            AS D ON C.AssetSeq = D.AssetSeq and D.CompanySeq = @CompanySeq        
      JOIN _TDASMinor               AS E ON D.SMAssetGrp = E.MinorSeq AND E.MinorSeq IN (6008004) AND E.CompanySeq = @CompanySeq        
      LEFT OUTER JOIN _TPDBOM       AS F ON A.ItemSeq = F.ItemSeq AND A.BOMRev = F.ItemBomRev  AND B.MatItemSeq = F.SubItemSeq AND F.CompanySeq = @CompanySeq        
      --LEFT OUTER JOIN (SELECT PB.ItemSeq, MAX(PB.ItemBOMRev) AS BOMRev   
      --                   FROM _TPDBOM AS PB  
      --                            JOIN _TDAItem AS IC ON PB.ItemSeq = IC.ItemSeq and IC.CompanySeq = @CompanySeq --and AssetSeq = 4      
      --                            JOIN _TDAItemAsset AS IA ON IC.AssetSeq = IA.AssetSeq   
      --                                                    and IA.CompanySeq = @CompanySeq     
      --                            JOIN _TDASMinor    AS SM ON IA.SMAssetGrp = SM.MinorSeq   
      --                                                    AND SM.MinorSeq IN ( 6008004)       
      --                                                    AND SM.CompanySeq = @CompanySeq      
      --                  WHERE PB.CompanySeq = @CompanySeq   
      --                  GROUP BY PB.ItemSeq)  AS SF ON B.MatItemSeq = SF.ItemSeq       --2012.07.13 BY 허승남 :: 2레벨 이상의 반제품 경우 BOM차수가 '00'으로 세팅되는 것을 방지하기 위해 최종 BOM차수로 세팅해줌  
    UPDATE @SemiGoodQty        
       SET FactUnit = B.FactUnit        
      FROM @SemiGoodQty AS A JOIN @SemiGoodQtySeqADD AS B ON A.ProdPlanSeq = B.ProdPlanSeq        
    
    
    
    DELETE @SemiGoodQty        
     FROM @SemiGoodQty AS A JOIN _TPDBaseAheadItem AS B ON A.SemiGoodSeq = B.ItemSeq and A.FactUnit = B.FactUnit        
    
    
    UPDATE @SemiGoodQty        
       SET SemiProcRev = B.ProcRev        
     FROM @SemiGoodQty  AS A JOIN         
    (SELECT A.WorkDate, A.SemiGoodSeq, A.SemiBomRev, MAX(B.ProcRev) AS ProcRev        
      FROM @SemiGoodQty AS A          
      JOIN _TPDROUItemProcRevFactUnit AS B ON A.FactUnit = B.FactUnit         
                                          and A.SemiGoodSeq = B.ItemSeq          
                                          and A.SemiBomrev = B.BOMrev        
                                          and B.CompanySeq = @CompanySeq        
                                          and B.FrDate <= A.WorkDate        
                                          and B.ToDate >= A.WorkDate       
    GROUP BY A.WorkDate, A.SemiGoodSeq, A.SemiBomRev) AS B ON A.WorkDate = B.WorkDate AND A.SemiGoodSeq = B.SemiGoodSeq AND A.SemiBomRev = B.SemiBomRev        
    WHERE levCnt = @levCnt+1      
   
    SELECT @levCnt = @levCnt + 1  
    END        
    
   -- --동일한 반제품이 두개 이상일 경우 계획수량이 중복으로 잡히게 됨으로 동일한 반제품 수만큼 계획수량에서 나눠서 계획을 생성해 줌. 2012.07.05 By 허승남  
   -- ----------------------------------------------------------------------------------------------------------------------------------------------------  
   -- SELECT SemiGoodSeq, COUNT(*) AS Cnt  INTO #TempGoodCnt FROM @SemiGoodQtySeq GROUP BY SemiGoodSeq  
  
   -- UPDATE @SemiGoodQtySeq  
   --    SET NeedQty = CASE WHEN Cnt > 1 THEN NeedQty/Cnt ELSE NeedQty END   
   --   FROM @SemiGoodQtySeq AS A   
   --             JOIN #TempGoodCnt AS B ON A.SemiGoodSeq =  B.SemiGoodSeq  
      
   --------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  
   -- --동일한 반제품중 서로 레벨이 다른경우, 합산처리를 위해 기존 데이터를 삭제후 grouping 2012.07.16 BY 허승남  
  
    SELECT *  
      INTO #tempSemiGoodQtySeq  
      FROM @SemiGoodQtySeq  
  
    DELETE @SemiGoodQtySeq  
  
    INSERT INTO @SemiGoodQtySeq  
    SELECT WorkDate    ,        
           ItemSeq     ,        
           ProdQty     ,        
           SemiGoodSeq ,        
           SUM(NeedQty),        
           ProdPlanSeq ,        
           MAX(SemiBomrev)  ,        
           MAX(SemiProcRev) ,        
           MAX(levCnt)      ,        
           0             ,        
           ProdPlanNo  ,        
           FactUnit        
      FROM #tempSemiGoodQtySeq  
     GROUP BY WorkDate,ItemSeq,ProdQty,SemiGoodSeq,ProdPlanSeq, ProdPlanNo,FactUnit  
    
    -- 최종조회
    SELECT MAX(X.FactUnit) AS FactUnit,   --생산사업장코드 
           MAX(B.FactUnitName) AS FactUnitName, --생산사업장 
           MAX(C.ItemName) AS ItemName, --품명 
           MAX(C.ItemNo) AS ItemNo, --품번 
           MAX(C.Spec) AS Spec, --규격 
           MAX(X.ProdPlanNo) AS ProdPlanNo, --생산계획번호 
           X.SemiGoodSeq AS ItemSeq, --품목코드 
           MAX(D.UnitName) AS UnitName, --단위 
           MAX(Z.UnitSeq) AS UnitSeq, --단위코드 
           X.SemiBOMRev AS BOMRev, --BOM차수 
           X.SemiBOMRev AS BOMRevName , --CASE WHEN E.BomRevName > '' THEN E.BomRevName ELSE A.BOMRev END AS BOMRevName,    --BOM차수 BOMRevName 
           MAX(X.SemiProcRev) AS ProcRev, --공정흐름차수 
           MAX(F.ProcRevName) AS ProcRevName      ,   --공정흐름차수명 ProcRevName 
           SUM(X.NeedQty) AS ProdQty      , --생산계획수량 
           MAX(Z.ProdPlanEndDate) AS EndDate  , --생산계획완료일 
           MAX(Q.AssetName) AS AssetName, 
           MAX(Q.AssetSeq) AS AssetSeq  
    
      FROM @SemiGoodQtySeq                AS X 
      LEFT OUTER JOIN #TPDMPProdPlan      AS Z WITH(NOLOCK) ON ( Z.ProdPlanSeq = X.ProdPlanSeq ) 
      JOIN _TPDMPSDailyProdPlan_Confirm   AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.CfmSeq = Z.ProdPlanSeq AND Y.CfmCode = 1)
      LEFT OUTER JOIN _TDAFactUnit        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = X.FactUnit ) 
      LEFT OUTER JOIN _TDAItem            AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq  = X.SemiGoodSeq ) 
      LEFT OUTER JOIN _TDAUnit            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq  = Z.UnitSeq ) 
      LEFT OUTER JOIN _TPDBOMECOApply     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq  = X.SemiGoodSeq AND E.ChgBomRev = X.SemiBOMRev AND E.chgBOMRev = '1' ) 
      LEFT OUTER JOIN _TPDROUItemProcRev  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq  = X.SemiGoodSeq AND F.ProcRev = X.SemiProcRev ) 
      LEFT OUTER JOIN _TDAItemAsset       AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND C.AssetSeq = Q.AssetSeq ) 
     
     WHERE (@SemiItemName = '' OR C.ItemName LIKE @SemiItemName + '%') 
       AND (@SemiItemNo = '' OR C.ItemNo LIKE @SemiItemNo + '%') 
       AND (@SemiSpec = '' OR C.Spec LIKE @SemiSpec + '%') 
     GROUP BY X.SemiGoodSeq, X.SemiBomRev
        
    RETURN 
GO
exec jongie_SPDSemiItemProdPlanListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>1</FactUnit>
    <ProdPlanYM>201310</ProdPlanYM>
    <DeptSeq />
    <ItemName />
    <ItemNo />
    <Spec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018427,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015669