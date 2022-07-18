  
IF OBJECT_ID('KPX_SPUDrumDelvListQuery') IS NOT NULL   
    DROP PROC KPX_SPUDrumDelvListQuery  
GO  
  
-- v2014.12.17  
  
-- 운반용기업체별구입실적-조회 by 이재천   
CREATE PROC KPX_SPUDrumDelvListQuery  
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
            @StdYear    NCHAR(4), 
            @BizUnit    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear = ISNULL( StdYear, '' ),  
           @BizUnit = ISNULL( BizUnit, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYear    NCHAR(4),
            BizUnit    INT  
           )    
    
    ---------------------------------------------------------------------
    -- 기초데이터 
    ---------------------------------------------------------------------
    CREATE TABLE #BaseData 
    (
        DelvInYM    NCHAR(6), 
        CustSeq     INT, 
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5)
    )
    
    INSERT INTO #BaseData ( DelvInYM, CustSeq, ItemSeq, Qty, Amt ) 
    SELECT LEFT(A.DelvInDate,6), A.CustSeq, B.ItemSeq, SUM(B.Qty), SUM(B.CurAmt) 
      FROM _TPUDelvIn                       AS A 
      LEFT OUTER JOIN _TPUDelvInItem        AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
                 JOIN _TDAItemUserDefine    AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq AND D.MngSerl = 1000003 AND D.MngValText IN ('True','1') ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.DelvInDate,4) = @StdYear 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
     GROUP BY LEFT(A.DelvInDate,6), A.CustSeq, B.ItemSeq 
     ORDER BY A.CustSeq, B.ItemSeq
    
    
    ---------------------------------------------------------------------
    -- Title
    ---------------------------------------------------------------------
    
    CREATE TABLE #Title_Sub 
    (
        Title       NVARCHAR(100), 
        TitleSeq    INT, 
        Title2      NVARCHAR(100), 
        TitleSeq2   INT, 
        Sort        INT 
    )
    
    CREATE TABLE #Title 
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(100),
        TitleSeq    INT, 
        Title2      NVARCHAR(100),
        TitleSeq2   INT, 
        Title3      NVARCHAR(100),
        TitleSeq3   INT, 
        Sort        INT 
    )
    
    INSERT INTO #Title_Sub ( Title, TitleSeq, Title2, TitleSeq2, Sort ) 
    SELECT DISTINCT 
           B.CustName, 
           A.CustSeq, 
           '소계' AS Title2, 
           100 AS TitleSeq2, 
           1 AS Sort
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDACust AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
    
    UNION ALL 
    
    SELECT DISTINCT 
           B.CustName, 
           A.CustSeq, 
           C.ItemName AS Title2, 
           A.ItemSeq AS TitleSeq2, 
           2 AS Sort 
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDACust AS B ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     ORDER BY CustSeq, Sort

    
    
    INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2, Title3, TitleSeq3, Sort )
    SELECT A.Title, A.TitleSeq, A.Title2, A.TitleSeq2, B.Title3, B.TitleSeq3, A.Sort 
      FROM #Title_Sub AS A 
      JOIN ( SELECT '수량' AS Title3, 1000 AS TitleSeq3
             UNION ALL 
             SELECT '금액' AS Title3, 2000 AS TitleSeq3
           ) AS B ON ( 1 = 1 ) 
     ORDER BY A.TitleSeq, A.Sort            
    
    SELECT * FROM #Title 
    
    
    
    ---------------------------------------------------------------------
    -- 고정행
    ---------------------------------------------------------------------
    
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        KindName    NVARCHAR(100), 
        KindSeq     INT
    )
    
    INSERT INTO #FixCol ( KindName, KindSeq ) 
    SELECT '총계' AS KindName, 1 AS KindSeq 
    UNION ALL                      
    SELECT '년평균' AS KindName, 2 AS KindSeq 
    UNION ALL 
    SELECT '1월' AS KindName, CONVERT(INT,@StdYear + '01') AS KindSeq 
    UNION ALL                      
    SELECT '2월' AS KindName, CONVERT(INT,@StdYear + '02') AS KindSeq 
    UNION ALL                      
    SELECT '3월' AS KindName, CONVERT(INT,@StdYear + '03') AS KindSeq 
    UNION ALL                      
    SELECT '4월' AS KindName, CONVERT(INT,@StdYear + '04') AS KindSeq 
    UNION ALL                      
    SELECT '5월' AS KindName, CONVERT(INT,@StdYear + '05') AS KindSeq 
    UNION ALL                      
    SELECT '6월' AS KindName, CONVERT(INT,@StdYear + '06') AS KindSeq 
    UNION ALL                      
    SELECT '7월' AS KindName, CONVERT(INT,@StdYear + '07') AS KindSeq 
    UNION ALL                      
    SELECT '8월' AS KindName, CONVERT(INT,@StdYear + '08') AS KindSeq 
    UNION ALL                      
    SELECT '9월' AS KindName, CONVERT(INT,@StdYear + '09') AS KindSeq 
    UNION ALL                      
    SELECT '10월' AS KindName, CONVERT(INT,@StdYear + '10') AS KindSeq 
    UNION ALL                      
    SELECT '11월' AS KindName, CONVERT(INT,@StdYear + '11') AS KindSeq 
    UNION ALL                      
    SELECT '12월' AS KindName, CONVERT(INT,@StdYear + '12') AS KindSeq 
    
    -- 조회 
    SELECT * FROM #FixCol 

    
    ---------------------------------------------------------------------
    -- 가변행 
    ---------------------------------------------------------------------
    
    CREATE TABLE #Value_Sub
    (
        DelvInYM    INT, 
        CustSeq     INT, 
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5) 
    )
    
    CREATE TABLE #Value
    (
        DelvInYM    INT, 
        CustSeq     INT, 
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5) 
    )
    
    INSERT INTO #Value_Sub ( DelvInYM, CustSeq, ItemSeq, Qty, Amt ) 
    SELECT DelvInYM, A.CustSeq, A.ItemSeq, SUM(A.Qty), SUM(A.Amt)
      FROM #BaseData AS A 
     GROUP BY DelvInYM, A.CustSeq, ItemSeq  
     
    
    UNION ALL 
    
    SELECT DelvInYM, A.CustSeq, 100 AS ItemSeq, SUM(A.Qty), SUM(A.Amt)
      FROM #BaseData AS A 
     GROUP BY DelvInYM, A.CustSeq 
     ORDER BY DelvInYM, CustSeq 
    
    
    INSERT INTO #Value ( DelvInYM, CustSeq, ItemSeq, Qty, Amt ) 
    SELECT DelvInYM, CustSeq, ItemSeq, Qty, Amt  
      FROM #Value_Sub 
    
    
    INSERT INTO #Value ( DelvInYM, CustSeq, ItemSeq, Qty, Amt ) 
    SELECT 1, A.CustSeq, A.ItemSeq, SUM(Qty), SUM(Amt) 
      FROM #Value_Sub AS A  
     GROUP BY A.CustSeq, A.ItemSeq
    
    UNION ALL 
    
    SELECT 2, A.CustSeq, A.ItemSeq, SUM(Qty) / 12, SUM(Amt) / 12 
      FROM #Value_Sub AS A  
     GROUP BY A.CustSeq, A.ItemSeq
     
    -- 조회 
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN A.TitleSeq3 = 1000 THEN C.Qty ELSE C.Amt END AS Value 
    
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.CustSeq AND A.TitleSeq2 = C.ItemSeq ) 
      JOIN #FixCol AS B ON ( B.KindSeq = C.DelvInYM ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
GO 

exec KPX_SPUDrumDelvListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYear>2014</StdYear>
    <BizUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026854,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022463


--select * From _TCApgm where caption like '%품목자산%'