  
IF OBJECT_ID('KPX_SPUDrumPirceChgListQuery') IS NOT NULL   
    DROP PROC KPX_SPUDrumPirceChgListQuery  
GO  
  
-- v2014.12.17  
  
-- 연간드럼구입실적가변동-조회 by 이재천   
CREATE PROC KPX_SPUDrumPirceChgListQuery  
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
            @YearFr     NCHAR(4), 
            @YearTo     NCHAR(4)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @YearFr = ISNULL( YearFr, '' ),  
           @YearTo = ISNULL( YearTo, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            YearFr     NCHAR(4), 
            YearTo     NCHAR(4) 
           )    
    
    CREATE TABLE #BaseData 
    (
        StdYear     NCHAR(4), 
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        Price       DECIMAL(19,5) 
    )
    
    INSERT INTO #BaseData ( StdYear, ItemSeq, Qty, Amt, Price ) 
    SELECT LEFT(A.DelvInDate,4), B.ItemSeq, SUM(B.Qty), SUM(B.CurAmt), AVG(B.Price) 
      FROM _TPUDelvIn                       AS A  
      LEFT OUTER JOIN _TPUDelvInItem        AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
                 JOIN _TDAItemUserDefine    AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq AND D.MngSerl = 1000003 AND D.MngValText IN ('True','1') ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND LEFT(A.DelvInDate,4) BETWEEN @YearFr AND @YearTo 
     GROUP BY LEFT(A.DelvInDate,4), B.ItemSeq 
     ORDER BY LEFT(A.DelvInDate,4), B.ItemSeq 
    
    --SELECT * FROM #BaseData 
    --return 
    ------------------------------------------------------------
    -- Title
    ------------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT, 
        Title2     NVARCHAR(100), 
        TitleSeq2  INT 
    )
    
    INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
    SELECT DISTINCT 
           B.ItemName AS Title, 
           A.ItemSeq AS TitleSeq, 
           C.Title2, 
           C.TitleSeq2
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      OUTER APPLY (SELECT '수량' AS Title2, 100 AS TitleSeq2
                   UNION ALL 
                   SELECT '금액' AS Title2, 200 AS TitleSeq2
                   UNION ALL 
                   SELECT '평균단가' AS Title2, 300 AS TitleSeq2
                  ) AS C 
     ORDER BY TitleSeq
    
    SELECT * FROM #Title 
    --return 
    
    ------------------------------------------------------------
    -- FixCol
    --------------------------------------------------------------
    
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        KindName    NVARCHAR(100), 
        KindSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        Price       DECIMAL(19,5) 
    )
    INSERT INTO #FixCol ( KindName, KindSeq, Qty, Amt, Price ) 
    SELECT '총계' AS KindName, 1 AS KindSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt, AVG(Price) AS Price 
      FROM #BaseData 
    
    UNION ALL 
    
    SELECT '연평균' AS KindName, 
           2 AS KindSeq, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE SUM(Qty) / MAX(ISNULL(B.Cnt,0)) END AS Qty, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE SUM(Amt) / MAX(ISNULL(B.Cnt,0)) END AS Amt, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE AVG(Price) / MAX(ISNULL(B.Cnt,0)) END AS Price 
      FROM #BaseData AS A 
      LEFT OUTER JOIN (
                        SELECT StdYear, ROW_NUMBER() OVER (ORDER BY StdYear) AS Cnt 
                          FROM #BaseData 
                        GROUP BY StdYear   
                     ) AS B ON ( B.StdYear = A.StdYear ) 
    UNION ALL 
    
    SELECT StdYear + '년' AS KindName, StdYear ASKindSeq  , SUM(Qty) AS Qty, SUM(Amt) AS Amt, AVG(Price) AS Price 
      FROM #BaseData 
     GROUP BY StdYear, StdYear + '년' 
    
    SELECT * FROM #FixCol
    --return 
    
    ------------------------------------------------------------
    -- Value
    ------------------------------------------------------------
    
    CREATE TABLE #Value
    (
        StdYear         NCHAR(4), 
        ItemSeq         INT, 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5), 
        Price           DECIMAL(19,5)
    )
    
    INSERT INTO #Value ( StdYear, ItemSeq, Qty, Amt, Price ) 
    SELECT 1 AS KindSeq, ItemSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt, AVG(Price) AS Price 
      FROM #BaseData 
     GROUP BY ItemSeq 
    
    UNION ALL 
    
    SELECT 2 AS KindSeq, 
           A.ItemSeq, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE SUM(Qty) / MAX(ISNULL(B.Cnt,0)) END AS Qty, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE SUM(Amt) / MAX(ISNULL(B.Cnt,0)) END AS Amt, 
           CASE WHEN MAX(ISNULL(B.Cnt,0)) = 0 THEN 0 ELSE AVG(Price) / MAX(ISNULL(B.Cnt,0)) END AS Price 
      FROM #BaseData AS A 
      LEFT OUTER JOIN (
                        SELECT StdYear, ItemSeq, ROW_NUMBER() OVER (PARTITION BY ItemSeq ORDER BY StdYear) AS Cnt 
                          FROM #BaseData 
                        GROUP BY StdYear, ItemSeq  
                      ) AS B ON ( B.StdYear = A.StdYear AND B.ItemSeq = A.ItemSeq ) 
     GROUP BY A.ItemSeq 
    
    
    UNION ALL 
    
    SELECT StdYear AS KindSeq, ItemSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt, AVG(Price) AS Price 
      FROM #BaseData 
     GROUP BY StdYear, ItemSeq 

    --select * from #Value 
    --return 
    
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN A.TitleSeq2 = 100 THEN C.Qty 
                WHEN A.TitleSeq2 = 200 THEN C.Amt 
                WHEN A.TitleSeq2 = 300 THEN C.Price 
                END AS Value 
           
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.ItemSeq ) 
      JOIN #FixCol AS B ON ( B.KindSeq = C.StdYear ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
GO 

exec KPX_SPUDrumPirceChgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <YearFr>2013</YearFr>
    <YearTo>2014</YearTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026884,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022481