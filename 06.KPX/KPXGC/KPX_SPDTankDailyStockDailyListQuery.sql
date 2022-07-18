  
IF OBJECT_ID('KPX_SPDTankDailyStockDailyListQuery') IS NOT NULL   
    DROP PROC KPX_SPDTankDailyStockDailyListQuery  
GO  
  
-- v2016.01.20  
  
-- 탱크재고조회-조회 by 이재천   
CREATE PROC KPX_SPDTankDailyStockDailyListQuery  
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
            @FactUnit   INT, 
            @StdDateFr  NCHAR(8), 
            @StdDateTo  NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit   , 0 ),
           @StdDateFr  = ISNULL( StdDateFr  , '' ),
           @StdDateTo  = ISNULL( StdDateTo  , '' )
           
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT, 
            StdDateFr  NCHAR(8),       
            StdDateTo  NCHAR(8)       
           )    
    
    IF @StdDateTo = '' SELECT @StdDateTo = '99991231' 
    
    -- Title 
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(200), 
        TitleSeq    INT 
    )
    INSERT INTO #Title ( TitleSeq, Title ) 
    SELECT Solar AS TitleSeq, LEFT(Solar,4) + '-' + SUBSTRING(Solar,5,2) + '-' + RIGHT(Solar,2) AS Title
      FROM _TCOMCalendar 
     WHERE Solar BETWEEN @StdDateFr AND @StdDateTo 
    
    SELECT * FROM #Title 
    
    -- Title, END 
    

    -- 기본 데이터 
    SELECT A.StdDate, B.TankName, B.TankSeq, B.ItemSeq, C.ItemName, B.Qty, A.StockQty
      INTO #BaseData  
      FROM KPX_TPDTankDailyStock    AS A 
                 JOIN KPX_TPDTank   AS B ON ( B.CompanySeq = @CompanySeq AND B.TankSeq = A.TankSeq ) 
      LEFT OUTER JOIN _TDAItem      AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.StdDate BETWEEN @StdDateFr AND @StdDateTo ) 
       AND ( @FactUnit = 0 OR B.FactUnit = @FactUnit ) 
    
    -- Fix 
    CREATE TABLE #FixCol
    (
     RowIdx     INT IDENTITY(0, 1), 
     TankName   NVARCHAR(200), 
     TankSeq    INT, 
     ItemSeq    INT, 
     ItemName   NVARCHAR(200), 
     Qty        DECIMAL(19,5) 
    )
    
    
    INSERT INTO #FixCol (TankName, TankSeq, ItemSeq, ItemName, Qty) 
    SELECT MAX(TankName), TankSeq, ItemSeq, MAX(ItemName), MAX(Qty)
      FROM #BaseData 
     GROUP BY TankSeq, ItemSeq 
     ORDER BY TankSeq 
    
    SELECT *FROM #FixCol  
    -- Fix, END 
    
    -- Value 
    CREATE TABLE #Value 
    (
        StdDate     INT, 
        TankSeq     INT, 
        ItemSeq     INT, 
        StockQty    DECIMAL(19,5) 
    )
    
    INSERT INTO #Value (StdDate, TankSeq, ItemSeq, StockQty)
    SELECT CONVERT(INT,StdDate), TankSeq, ItemSeq, SUM(StockQty)
      FROM #BaseData
     GROUP BY CONVERT(INT,StdDate), TankSeq, ItemSeq 
    
    
    SELECT B.RowIdx, A.ColIdx, C.StockQty AS Value
      FROM #Value   AS C
      JOIN #Title   AS A ON ( A.TitleSeq = C.StdDate ) 
      JOIN #FixCol  AS B ON ( B.ItemSeq = C.ItemSeq AND B.TankSeq = C.TankSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
    go
EXEC KPX_SPDTankDailyStockDailyListQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit />
    <StdDateFr>20160101</StdDateFr>
    <StdDateTo>20160120</StdDateTo>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1034437, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1028521
