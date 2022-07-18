
IF OBJECT_ID('jongie_SPDItemMRPDailyList') IS NOT NULL 
    DROP PROC jongie_SPDItemMRPDailyList
GO

-- v2013.09.27 

-- 일자별제품별자재소요계획_jongie(조회) by이재천
CREATE PROC jongie_SPDItemMRPDailyList 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
	DECLARE @docHandle      INT,
            @FactUnit       INT, 
            @ProdPlanYM     NVARCHAR(6), 
            @ItemAseet      NVARCHAR(100), 
            @ItemName       NVARCHAR(200), 
            @ItemNo         NVARCHAR(100), 
		    @Spec           NVARCHAR(100), 
            @MatClassSSeq   INT, 
            @MatName        NVARCHAR(100), 
            @MatNo          NVARCHAR(100), 
            @MatSpec        NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
	SELECT @FactUnit        = FactUnit, 
           @ProdPlanYM      = ProdPlanYM, 
           @ItemAseet       = ItemAseet, 
           @ItemName        = ItemName, 
           @ItemNo          = ItemNo, 
           @Spec            = Spec, 
           @MatClassSSeq    = MatClassSSeq, 
           @MatName         = MatName, 
           @MatNo           = MatNo, 
           @MatSpec         = MatSpec 

      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
	  WITH (
            FactUnit        INT, 
	        ProdPlanYM     NVARCHAR(6), 
	        ItemAseet      NVARCHAR(100),
	        ItemName       NVARCHAR(200),
	        ItemNo         NVARCHAR(100),
	        Spec           NVARCHAR(100),
	        MatClassSSeq   INT, 
	        MatName        NVARCHAR(100),
	        MatNo          NVARCHAR(100),
	        MatSpec        NVARCHAR(100) 
           )

    
    DECLARE @EnvValue   INT, 
            @nItemPoint INT, 
            @ItemSeq    INT, 
            @ItemBomRev NCHAR(2), 
            @SrtDate    NVARCHAR(8), 
            @EndDate    NVARCHAR(8),
            @IDX_NO     INT
    
    SELECT @EnvValue = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 1 AND EnvSerl = 1 
    SELECT @SrtDate = @ProdPlanYM+'01'  
    SELECT @EndDate = CONVERT(NCHAR(8),DATEADD(Day,-1,DATEADD(Month,1,@SrtDate)),112)     
     
    -- 헤더부 
    CREATE TABLE #Title 
    (
     ColIdx     INT IDENTITY(0,1), 
     Title      NVARCHAR(100), 
     TitleSeq   INT
    )
    
    
    WHILE ( @SrtDate <= @EndDate )  
    BEGIN  
        INSERT INTO #Title ( Title, TitleSeq)
        SELECT CAST(CAST(RIGHT(@SrtDate,2) AS INT) AS NVARCHAR(2))+'일', CAST(RIGHT(@SrtDate,2) AS INT)
        
        SELECT @SrtDate = CONVERT(NCHAR(8), DATEADD(Day, 1, @SrtDate), 112)   
    END
    
    SELECT * FROM #Title ORDER BY ColIdx
      
    -- 고정부
    SELECT MAX(C.ItemName) AS ItemName, 
           A.EndDate AS EndDate,  
           MAX(C.ItemNo) AS ItemNo, 
           MAX(C.Spec) AS Spec, 
           MAX(D.UnitName) AS UnitName, 
           A.ItemSeq, 
           SUM(A.ProdQty) AS PlanQty, 
           A.BOMRev AS BOMRev
      INTO #TPDMPSDailyProdPlan
      FROM _TPDMPSDailyProdPlan    AS A 
      LEFT OUTER JOIN _TDAItem     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = A.UnitSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.FactUnit = @FactUnit 
       AND LEFT(A.EndDate,6) = @ProdPlanYM 
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (@Spec = '' OR C.Spec LIKE @Spec + '%') 
       AND (@ItemAseet = 0 OR C.AssetSeq = @ItemAseet) 
     GROUP BY A.EndDate, A.ItemSeq, A.BOMRev
     ORDER BY A.ItemSeq 



    SELECT IDENTITY(INT, 1, 1) AS IDX_NO,
           A.ItemSeq AS ItemSeq, 
           A.BOMRev AS BOMRev
      INTO #TPDMPSDailyProdPlansub
      FROM #TPDMPSDailyProdPlan    AS A 
     GROUP BY A.ItemSeq, A.BOMRev

    SELECT @IDX_NO = 0 
    
    CREATE TABLE #BOMSpread     
    (    
        ItemSeq             INT,    
        ItemBOMRev          NCHAR(2),    
        UnitSeq             INT,    
        BOMLevelText        NVARCHAR(50),    
        Location            NVARCHAR(1000),    
        Remark              NVARCHAR(500),    
        Serl                INT,    
        NeedQtyNumerator    DECIMAL(19,5),    
        NeedQtyDenominator  DECIMAL(19,5),    
        NeedQty             DECIMAL(19,10),    
        Seq                 INT IDENTITY(1,1),    
        ParentSeq           INT,    
        Sort                INT,    
        BOMLevel            INT,    
        BOMLevelTree        NVARCHAR(100)      
    )

    CREATE TABLE #BOMSpread_Result
    (    
        ItemSeq             INT,    
        ItemBOMRev          NCHAR(2),    
        SubItemSeq          INT,    
        SubItemBOMRev       NCHAR(2),    
        UnitSeq             INT,    
        BOMLevelText        NVARCHAR(50),    
        Location            NVARCHAR(1000),    
        Remark              NVARCHAR(500),    
        Serl                INT,    
        NeedQtyNumerator    DECIMAL(19,5),    
        NeedQtyDenominator  DECIMAL(19,5),    
        NeedQty             DECIMAL(19,10),    
        Seq                 INT,    
        ParentSeq           INT,    
        Sort                INT,    
        BOMLevel            INT,    
        BOMLevelTree        NVARCHAR(100)      
    )      

    WHILE (1=1)
    BEGIN
        IF EXISTS (SELECT 1 FROM #TPDMPSDailyProdPlansub WHERE IDX_NO > @IDX_NO)
        BEGIN
            SELECT TOP 1 @IDX_NO = IDX_NO,
                         @ItemSeq = ItemSeq, 
                         @ItemBOMRev = BOMRev 
              FROM #TPDMPSDailyProdPlansub 
             WHERE IDX_NO > @IDX_NO
             ORDER BY IDX_NO
        
            TRUNCATE TABLE #BOMSpread
        
            -- BOM전개    
            EXEC dbo._SPDBOMSpread     
                 @CompanySeq = @CompanySeq, 
                 @ItemSeq = @ItemSeq, 
                 @ItemBomRev = @ItemBOMRev    
                 
                INSERT #BOMSpread_Result
                SELECT @ItemSeq, @ItemBOMRev, * 
                  FROM #BOMSpread
        END
        ELSE BREAK
    END
    
    CREATE TABLE #MatNeedQty
    (
     ItemName       NVARCHAR(200), 
     ItemNo         NVARCHAR(200), 
     Spec           NVARCHAR(200), 
     ItemSeq        INT, 
     UnitName       NVARCHAR(100), 
     PlanQty        DECIMAL(19,5), 
     ItemAseetName  NVARCHAR(200), 
     ItemAssetSeq   INT, 
     MatName        NVARCHAR(200), 
     MatNo          NVARCHAR(200), 
     MatSpec        NVARCHAR(200), 
     TotNeedQty     DECIMAL(19,5), 
     SubItemSeq     INT,
     EndDate        NCHAR(8),
     BOMRev         NCHAR(2)
    )


    CREATE TABLE #FixCol
    (
     RowIdx         INT IDENTITY(0,1), 
     ItemName       NVARCHAR(200), 
     ItemNo         NVARCHAR(200), 
     Spec           NVARCHAR(200), 
     ItemSeq        INT, 
     UnitName       NVARCHAR(100), 
     ItemUnit       DECIMAL(19,5), 
     PlanQty        DECIMAL(19,5), 
     PlanBoxQty     DECIMAL(19,5), 
     ItemAseetName  NVARCHAR(200), 
     ItemAssetSeq   INT, 
     MatName        NVARCHAR(200), 
     MatNo          NVARCHAR(200), 
     MatSpec        NVARCHAR(200), 
     TotNeedQty     DECIMAL(19,5), 
     SubItemSeq     INT 
    )
    
    INSERT INTO #MatNeedQty(
                        ItemName, ItemNo, Spec, ItemSeq, UnitName, 
                        PlanQty, ItemAseetName, ItemAssetSeq,
                        MatName, MatNo, MatSpec, TotNeedQty, SubItemSeq, EndDate, BOMRev
                       )
    SELECT MAX(A.ItemName) AS ItemName, MAX(A.ItemNo), MAX(A.Spec), A.ItemSeq, MAX(A.UnitName), 
           MAX(A.PlanQty), MAX(D.ItemClasSName), MAX(D.ItemClassSSeq), 
           MAX(C.ItemName) AS SubItemName, MAX(C.ItemNo), MAX(C.Spec), SUM(B.NeedQty) * A.PlanQty, B.SubItemSeq, A.EndDate, A.BOMRev
      FROM #TPDMPSDailyProdPlan AS A 
      JOIN #BOMSpread_Result AS B ON ( B.ItemSeq = A.ItemSeq AND B.ItemBOMRev = A.BOMRev AND B.ParentSeq <> 0 )  
      LEFT OUTER JOIN _TDAItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.SubItemSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS D ON ( B.SubItemSeq = D.ItemSeq ) 
     WHERE (@MatClassSSeq = 0 OR D.ItemClassSSeq = @MatClassSSeq)
       AND (@MatName = '' OR C.ItemName LIKE @MatName + '%')
       AND (@MatNo = '' OR C.ItemNo LIKE @MatNo + '%') 
       AND (@MatSpec = '' OR C.Spec LIKE @MatSpec + '%')
     GROUP BY A.EndDate, A.ItemSeq, A.BOMRev, B.SubItemSeq, A.PlanQty

    INSERT INTO #FixCol(
                        ItemName, ItemNo, Spec, ItemSeq, UnitName, 
                        ItemUnit, PlanQty, PlanBoxQty, ItemAseetName, ItemAssetSeq,
                        MatName, MatNo, MatSpec, TotNeedQty, SubItemSeq
                       )
    SELECT ItemName, ItemNo, Spec, A.ItemSeq, UnitName, 
           CASE WHEN B.ConvDen = 0 THEN 0 ELSE B.ConvNum / B.ConvDen END AS ItemUnit, SUM(PlanQty), SUM(A.PlanQty) / (CASE WHEN B.ConvDen = 0 THEN 0 ELSE B.ConvNum / B.ConvDen END), ItemAseetName, ItemAssetSeq,
           MatName, MatNo, MatSpec, SUM(TotNeedQty), SubItemSeq
      FROM #MatNeedQty AS A
      LEFT OUTER JOIN _TDAItemUnit AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.UnitSeq = @EnvValue AND B.ItemSeq = A.ItemSeq ) 
     GROUP BY ItemName, ItemNo, Spec, A.ItemSeq, UnitName, 
           ItemAseetName, ItemAssetSeq,
           MatName, MatNo, MatSpec, SubItemSeq, B.ConvNum, B.ConvDen
     ORDER BY ItemName, MatName


    SELECT * FROM #FixCol ORDER BY RowIdx

    -- 가변행 
    CREATE TABLE #Value
    (
     TitleSeq       INT, 
     ItemSeq        INT, 
     TotNeedQty     DECIMAL(19,5)
    )
    INSERT INTO #Value(TitleSeq, ItemSeq, TotNeedQty)
    SELECT CONVERT(INT,RIGHT(A.EndDate,2)), 
           A.SubItemSeq AS ItemSeq,
           SUM(A.TotNeedQty)
      FROM #MatNeedQty AS A 
     GROUP BY CONVERT(INT,RIGHT(A.EndDate,2)), A.SubItemSeq
     ORDER BY ItemSeq 
    
    --select * from #Value
    --select * from #fixcol
    --select * from #MatNeedQty
    SELECT B.RowIdx, A.ColIdx, C.TotNeedQty AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 
      JOIN #FixCol AS B ON ( B.SubItemSeq = C.ItemSeq ) 
     ORDER BY B.RowIdx, A.ColIdx 

    RETURN
GO
exec jongie_SPDItemMRPDailyList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <ItemAseet />
    <MatClassSSeq />
    <ProdPlanYM>201308</ProdPlanYM>
    <ItemName />
    <MatName />
    <ItemNo>AFN00077</ItemNo>
    <MatNo />
    <Spec />
    <MatSpec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018053,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015421