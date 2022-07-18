  
IF OBJECT_ID('KPX_SPDSFCProdUseCalQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdUseCalQuery  
GO  
  
-- v2015.01.23  
  
-- 자가소비량계산-조회 by 이재천   
CREATE PROC KPX_SPDSFCProdUseCalQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @AssetSeq   INT, 
            @FactUnit   INT, 
            @StdDateFr  NCHAR(8), 
            @StdDateTo  NCHAR(8), 
            @UMProcType INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @AssetSeq    = ISNULL( AssetSeq  , 0 ),  
           @FactUnit    = ISNULL( FactUnit  , 0 ),  
           @StdDateFr   = ISNULL( StdDateFr , '' ),  
           @StdDateTo   = ISNULL( StdDateTo , '' ),  
           @UMProcType  = ISNULL( UMProcType, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AssetSeq   INT, 
            FactUnit   INT, 
            StdDateFr  NCHAR(8), 
            StdDateTo  NCHAR(8), 
            UMProcType INT 
           )    
    
    IF @StdDateTo = '' SELECT @StdDateTo = '99991231'
    
    CREATE TABLE #TPDMPSDailyProdPlan
    (
        ItemSeq     INT, 
        SrtDate     NCHAR(8), 
        ProdQty     DECIMAL(19,5) 
    )
    
    INSERT INTO #TPDMPSDailyProdPlan ( ItemSeq, SrtDate, ProdQty ) 
    SELECT A.ItemSeq, 
           A.SrtDate, 
           SUM(A.ProdQty) 
      FROM _TPDMPSDailyProdPlan             AS A 
      LEFT OUTER JOIN KPX_TPDWorkCenterRate AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @UMProcType = 0 OR B.UMProcType = @UMProcType ) 
       AND ( @FactUnit = A.FactUnit ) 
       AND ( A.SrtDate BETWEEN @StdDateFr AND @StdDateTo ) 
       AND ( @AssetSeq = 0 OR C.AssetSeq = @AssetSeq ) 
     GROUP BY A.ItemSeq, SrtDate 
    
    --SELECT * 
    --  FROM #TPDMPSDailyProdPlan 
    
    -- 전일재고 가져오기 
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
    
    INSERT INTO #GetInOutItem (ItemSeq) 
    SELECT ItemSeq 
      FROM #TPDMPSDailyProdPlan 
    
    DECLARE @Date NCHAR(8) 
    
    SELECT @Date = CONVERT(NCHAR(8),DATEADD(DAY,-1,@StdDateFr),112)
    
    EXEC _SLGGetInOutStock  
         @CompanySeq    = @CompanySeq,       -- 법인코드  
         @BizUnit       = 0,       -- 사업부문  
         @FactUnit      = 0,       -- 생산사업장  
         @DateFr        = @Date, -- 조회기간Fr  
         @DateTo        = @Date, -- 조회기간To  
         @WHSeq         = 0,       -- 창고지정  
         @SMWHKind      = 0,       -- 창고구분별 조회  
         @CustSeq       = 0,       -- 수탁거래처  
         @IsSubDisplay  = '', -- 기능창고 조회  
         @IsUnitQry     = '', -- 단위별 조회  
         @QryType       = 'S'  -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고  
    
    --SELECT * FROM #GetInOutStock 
    
    
    
    -- Title 
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT
    ) 
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT SUBSTRING(A.Solar,1,4) + '-' + SUBSTRING(A.Solar,5,2) + '-' + SUBSTRING(A.Solar,7,2) AS TitleName, A.Solar AS Title
      FROM _TCOMCalendar AS A 
     WHERE A.Solar BETWEEN @StdDateFr AND @StdDateTo 
    
    SELECT * FROM #Title 
    
    -- Fix 
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        ItemSeq     INT, 
        ItemName    NVARCHAR(100), 
        StockQty    DECIMAL(19,5), 
        SumQty      DECIMAL(19,5) 
    )
    INSERT INTO #FixCol ( ItemSeq, ItemName, StockQty, SumQty ) 
    SELECT D.MatItemSeq, C.ItemName, SUM(ISNULL(B.StockQty,0)), SUM(CASE WHEN ISNULL(D.NeedQtyDenominator,0) = 0 THEN 0 ELSE A.ProdQty * ( D.NeedQtyNumerator / D.NeedQtyDenominator ) END)
      FROM #TPDMPSDailyProdPlan             AS A 
      LEFT OUTER JOIN #GetInOutStock        AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TPDROUItemProcMat    AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = D.MatItemSeq ) 
     GROUP BY D.MatItemSeq, C.ItemName
    
    SELECT * FROM #FixCol
    
    -- Value
    CREATE TABLE #Value
    (
        ItemSeq        INT, 
        SrtDate        NCHAR(8), 
        Qty            DECIMAL(19, 5)
    )
    INSERT INTO #Value ( Qty, SrtDate, ItemSeq ) 
    SELECT SUM(CASE WHEN ISNULL(D.NeedQtyDenominator,0) = 0 THEN 0 ELSE A.ProdQty * ( D.NeedQtyNumerator / D.NeedQtyDenominator ) END), 
           A.SrtDate, 
           D.MatItemSeq 
      FROM #TPDMPSDailyProdPlan             AS A 
      LEFT OUTER JOIN #GetInOutStock        AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TPDROUItemProcMat    AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
     GROUP BY D.MatItemSeq, A.SrtDate
    
    --select * From #Value 
    
    SELECT B.RowIdx, A.ColIdx, C.Qty AS Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.SrtDate ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq ) 
     ORDER BY A.ColIdx, B.RowIdx

    
    
    
    --return 
    
    RETURN  
GO 

exec KPX_SPDSFCProdUseCalQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>1</FactUnit>
    <StdDateFr>20150101</StdDateFr>
    <StdDateTo>20150123</StdDateTo>
    <UMProcType />
    <AssetSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027617,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1023101