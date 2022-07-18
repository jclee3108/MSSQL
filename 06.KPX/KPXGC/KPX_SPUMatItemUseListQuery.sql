  
IF OBJECT_ID('KPX_SPUMatItemUseListQuery') IS NOT NULL   
    DROP PROC KPX_SPUMatItemUseListQuery  
GO  
  
-- v2014.12.18  
  
-- 개별품목월(년)간원료사용량-조회 by 이재천   
CREATE PROC KPX_SPUMatItemUseListQuery  
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
            @StdYear    NCHAR(4)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYear = ISNULL( StdYear, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYear NCHAR(4))    
    
    CREATE TABLE #BaseData 
    (
        StdYM           NCHAR(6), 
        BizUnit         INT, 
        ItemClassSSeq   INT, 
        ItemClassSName  NVARCHAR(100), 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5), 
        Sort            INT 
    )
    
    INSERT INTO #BaseData ( StdYM, BizUnit, ItemClassSSeq, ItemClassSName, Qty, Amt , Sort ) 
    SELECT LEFT(A.WorkDate,6), D.BizUnit, C.ItemClassSSeq, MAX(C.ItemClasSName), SUM(ISNULL(A.ProdQty,0)), 0, 2 AS Sort
      FROM _TPDSFCWorkReport            AS A 
      LEFT OUTER JOIN _TPDSFCMatinput   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS C ON ( C.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = A.FactUnit ) 
                 JOIN _TDAItem          AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.MatItemSeq AND E.AssetSeq = 4 ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND LEFT(A.WorkDate,4) = @StdYear 
    
     GROUP BY LEFT(A.WorkDate,6), D.BizUnit, C.ItemClassSSeq 
    
    UNION ALL 
    
    SELECT LEFT(A.WorkDate,6), D.BizUnit, 1,  '소계', SUM(ISNULL(A.ProdQty,0)), 0, 1 
      FROM _TPDSFCWorkReport            AS A 
      LEFT OUTER JOIN _TPDSFCMatinput   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS C ON ( C.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = A.FactUnit ) 
                 JOIN _TDAItem          AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.MatItemSeq AND E.AssetSeq = 4 ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND LEFT(A.WorkDate,4) = @StdYear 
     GROUP BY LEFT(A.WorkDate,6), D.BizUnit
     ORDER BY Sort 
    
    
    --select * from #BaseData 
    --return 
    
    --------------------------------------------------------------------------------
    -- Title
    --------------------------------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx          INT IDENTITY(0, 1), 
        Title           NVARCHAR(100), 
        TitleSeq        INT, 
        Title2          NVARCHAR(100), 
        TitleSeq2       INT,
        Title3          NVARCHAR(100), 
        TitleSeq3       INT
    ) 
    INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2,Title3, TitleSeq3 ) 
    SELECT A.Title, 
           A.TitleSeq, 
           A.Title2, 
           A.TitleSeq2, 
           C.Title3, 
           C.TitleSeq3
      FROM ( 
                SELECT DISTINCT B.BizUnitName AS Title, A.BizUnit AS TitleSeq, A.ItemClassSName AS Title2, A.ItemClassSSeq AS TitleSeq2, A.Sort
                  From #BaseData  AS A 
                  LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
           ) AS A 
      OUTER APPLY ( SELECT '수량(TON)' AS Title3, 100 AS TitleSeq3 
                    UNION ALL 
                    SELECT '금액(백만원)' AS Title3, 200 AS TitleSeq3 
                  ) AS C 
     ORDER BY A.TitleSeq, A.Sort, TitleSeq2 
    
    SELECT * FROM #Title  
    --return 
    
    --------------------------------------------------------------------------------
    -- 고정행
    --------------------------------------------------------------------------------
    
    CREATE TABLE #FixCol
    (
     RowIdx     INT IDENTITY(0, 1), 
     KindName   NVARCHAR(100), 
     KindSeq    INT, 
     Qty        DECIMAL(19,5), 
     Amt        DECIMAL(19,5), 
     Rate       DECIMAL(19,5) 
    )
    
    INSERT INTO #FixCol ( KindName, KindSeq, Qty, Amt, Rate ) 
    SELECT '총계', 1, SUM(Qty) AS Qty, SUM(Amt) AS Amt, 0 
      FROM #BaseData 
     WHERE ItemClassSSeq <> 1 
    
    UNION ALL 
    
    SELECT '평균', 
           2, 
           CASE WHEN MAX(B.Cnt) = 0 THEN 0 ELSE SUM(A.Qty) / MAX(B.Cnt) END AS Qty, 
           CASE WHEN MAX(B.Cnt) = 0 THEN 0 ELSE SUM(A.Amt) / MAX(B.Cnt) END AS Amt, 
           0 
      FROM #BaseData AS A 
      LEFT OUTER JOIN ( SELECT StdYM, ROW_NUMBER() OVER(ORDER BY StdYM) AS Cnt 
                          FROM #BaseData AS Z 
                         GROUP BY StdYM 
                      ) AS B ON ( B.StdYM = A.StdYM ) 
     WHERE A.ItemClassSSeq <> 1 
    
    UNION ALL 
    
    SELECT CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(StdYM,2))) + '월', StdYM, SUM(Qty) AS Qty, SUM(Amt) AS Amt, 0 
      FROM #BaseData 
     WHERE ItemClassSSeq <> 1 
     GROUP BY CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(StdYM,2))) + '월', StdYM
    
    SELECT * FROM #FixCol 
    --return 
    
    --------------------------------------------------------------------------------
    -- Value
    --------------------------------------------------------------------------------
    
    CREATE TABLE #Value
    (
        StdYM           NCHAR(6), 
        BizUnit         INT, 
        ItemClassSSeq   INT, 
        Qty             DECIMAL(19,5), 
        Amt             DECIMAL(19,5)
    )
    
    INSERT INTO #Value ( StdYM, BizUnit, ItemClassSSeq, Qty, Amt ) 
    SELECT 1 AS StdYM, BizUnit, ItemClassSSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt
      FROM #BaseData 
     GROUP BY BizUnit, ItemClassSSeq
    
    UNION ALL 
    
    SELECT 2, A.BizUnit, A.ItemClassSSeq, 
           CASE WHEN MAX(B.Cnt) = 0 THEN 0 ELSE SUM(Qty) / MAX(B.Cnt) END, 
           CASE WHEN MAX(B.Cnt) = 0 THEN 0 ELSE SUM(Amt) / MAX(B.Cnt) END
    FROM #BaseData AS A 
    LEFT OUTER JOIN (SELECT StdYM, BizUnit, ROW_NUMBER() OVER (PARTITION BY BizUnit ORDER BY StdYM) AS Cnt 
                      FROM #BaseData  
                     GROUP BY StdYM, BizUnit
                    ) AS B ON ( B.StdYM = A.StdYM AND B.BizUnit = A.BizUnit ) 
     GROUP BY A.BizUnit, A.ItemClassSSeq
    
    UNION ALL 
    
    SELECT StdYM, BizUnit, ItemClassSSeq, Qty, Amt
      FROM #BaseData 
    
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN A.TitleSeq3 = 100 THEN C.Qty 
                WHEN A.TitleSeq3 = 200 THEN C.Amt
                END AS Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.BizUnit AND A.TitleSeq2 = ItemClassSSeq ) 
      JOIN #FixCol AS B ON ( B.KindSeq = C.StdYM ) 
     ORDER BY A.ColIdx, B.RowIdx

    
    RETURN  
GO 
exec KPX_SPUMatItemUseListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYear>2012</StdYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026918,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022504