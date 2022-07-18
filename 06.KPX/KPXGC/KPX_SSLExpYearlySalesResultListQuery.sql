  
IF OBJECT_ID('KPX_SSLExpYearlySalesResultListQuery') IS NOT NULL   
    DROP PROC KPX_SSLExpYearlySalesResultListQuery  
GO  
  
-- v2014.12.24  
  
-- 년도별 판매실적-조회 by 이재천   
CREATE PROC KPX_SSLExpYearlySalesResultListQuery  
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
            @StdYear    NCHAR(8)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear   = ISNULL( StdYear, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYear   NCHAR(8))    
    
    CREATE TABLE #BaseData_Sub
    (
        BizUnit         INT, 
        SalesYM         NCHAR(6), 
        ItemClassLSeq   INT, 
        ItemClassLName  NVARCHAr(100), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5) 
    )
    
    CREATE TABLE #BaseData
    (
        BizUnit         INT, 
        SalesYM         NCHAR(6), 
        ItemClassLSeq   INT, 
        ItemClassLName  NVARCHAr(100), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5) 
    )
    INSERT INTO #BaseData_Sub ( BizUnit, SalesYM, ItemClassLSeq, ItemClassLName, Qty, Amt )
    SELECT E.ValueSeq AS BizUnit, LEFT(A.SalesDate,6) AS SalesYM, C.ItemClassLSeq, C.ItemClasLName, 
           SUM(B.Qty) / 1000 AS Qty, SUM(B.DomAmt) AS Amt
      FROM _TSLSales                    AS A 
      JOIN _TSLSalesItem                AS B ON ( B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS C ON ( C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.ItemClassLSeq AND E.Serl = 1000001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.SalesDate,4) = @StdYear 
       AND LEFT(C.ItemClassLSeq,4) = 2003
     GROUP BY E.ValueSeq, LEFT(A.SalesDate,6), C.ItemClassLSeq, C.ItemClasLName
     ORDER BY BizUnit, SalesYM, ItemClassLSeq
    
    INSERT INTO #BaseData -- 기초 데이터 
    SELECT * FROM #BaseData_Sub 
    
    INSERT INTO #BaseData -- 다이나믹 소계 
    SELECT BizUnit, SalesYM, 999999998, '소계', SUM(Qty), SUM(Amt) 
      FROM #BaseData_Sub 
     GROUP BY BizUnit, SalesYM
     ORDER BY BizUnit, SalesYM
    
    INSERT INTO #BaseData -- 다이나믹 합계 
    SELECT 999999999, SalesYM, 999999999, '합계', SUM(Qty), SUM(Amt) 
      FROM #BaseData_Sub 
     GROUP BY SalesYM
     ORDER BY SalesYM 
     
    INSERT INTO #BaseData  -- 고정행 계 구하기 
    SELECT BizUnit, 999999, ItemClassLSeq, ItemClassLName, SUM(Qty), SUM(Amt) 
      FROM #BaseData 
     GROUP BY BizUnit, ItemClassLSeq, ItemClassLName
     ORDER BY BizUnit 
    
    
    ----------------------------------------------------------------------
    -- Title
    ----------------------------------------------------------------------
    CREATE TABLE #Title
    (
         ColIdx     INT IDENTITY(0, 1), 
         BizUnit    INT, 
         Title      NVARCHAR(100), 
         TitleSeq   INT, 
         Title2     NVARCHAR(100), 
         TitleSeq2  INT 
    )
    
    INSERT INTO #Title (BizUnit, Title, TitleSeq, Title2, TitleSeq2) 
    SELECT DISTINCT A.BizUnit, A.ItemClassLName, A.ItemClassLSeq, B.Title2, B.TitleSeq2 
      FROM #BaseData AS A 
      JOIN (
            SELECT '수량' AS Title2, 100 AS TitleSeq2 
            UNION ALL 
            SELECT '금액', 200 
           ) AS B ON ( 1 = 1 ) 
     ORDER BY A.BizUnit, A.ItemClassLSeq, B.TitleSeq2 
    
    SELECT * FROM #Title 
    --return 
    
    ----------------------------------------------------------------------
    -- 고정행 
    ----------------------------------------------------------------------
    
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        KindName    NVARCHAR(100), 
        KindSeq     INT 
    )
    
    INSERT INTO #FixCol ( KindName, KindSeq ) 
    SELECT DISTINCT CASE WHEN SalesYM = 999999 THEN '계' ELSE CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(SalesYM,2))) + '월' END AS KindName, SalesYM AS KindSeq 
      FROM #BaseData 
     ORDER BY KindSeq 
    
    SELECT * FROM #FixCol 
    --return 
    
    ----------------------------------------------------------------------
    -- 가변행 
    ---------------------------------------------------------------------- 
    
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN A.TitleSeq2 = 100 THEN C.Qty 
                WHEN A.TitleSeq2 = 200 THEN C.Amt 
                ELSE 0 
                END AS Value
      FROM #BaseData AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.ItemClassLSeq AND A.BizUnit = C.BizUnit ) 
      JOIN #FixCol AS B ON ( B.KindSeq = C.SalesYM ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    
    RETURN  
    go 
exec KPX_SSLExpYearlySalesResultListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYear>2014</StdYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027072,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020693
 