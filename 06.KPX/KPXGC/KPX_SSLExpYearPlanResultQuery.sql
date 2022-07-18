  
IF OBJECT_ID('KPX_SSLExpYearPlanResultQuery') IS NOT NULL   
    DROP PROC KPX_SSLExpYearPlanResultQuery  
GO  
  
-- v2014.12.24  
  
-- 연간계획대비실적(구분)-조회 by 이재천   
CREATE PROC KPX_SSLExpYearPlanResultQuery  
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
      
    SELECT @StdYear   = ISNULL( StdYear, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYear   NCHAR(4))    
    
    -- 연간판매계획, 매출 데이터 담기 
    CREATE TABLE #TEMP 
    (
        BizUnit     INT,
        ItemSeq     INT, 
        CustSeq     INT, 
        PlanYM      NCHAR(6), 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        KindSeq     INT 
    )
    INSERT INTO #TEMP ( BizUnit, ItemSeq, CustSeq, PlanYM, Qty, Amt, KindSeq ) 
    SELECT A.BizUnit, A.ItemSeq, A.CustSeq, A.PlanYM, SUM(PlanQty) / 1000 AS Qty, SUM(PlanAmt) AS Amt, 1 AS KindSeq 
      FROM _TSLPlanYearSales AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.PlanYM,4) = @StdYear 
     GROUP BY A.BizUnit, A.PlanYM, A.ItemSeq, A.CustSeq 

    UNION ALL 
    
    SELECT A.BizUnit, B.ItemSeq, A.CustSeq, LEFT(A.SalesDate,6), SUM(Qty) / 1000, SUM(DomAmt), 2 
      FROM _TSLSales AS A 
      JOIN _TSLSalesItem AS B ON ( B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND LEFT(A.SalesDate,4) = @StdYear 
     GROUP BY A.BizUnit, LEFT(A.SalesDate,6), B.ItemSeq, A.CustSeq 
    ORDER BY BizUnit, ItemSeq, CustSeq, KindSeq 
    
    
    -- 구분값 기준으로 넣기 
    CREATE TABLE #Kind
    (
        BizUnit     INT, 
        ItemSeq     INT, 
        CustSeq     INT, 
        KindName    NVARCHAR(100), 
        KindSeq     INT 
    )
    INSERT INTO #Kind ( BizUnit, ItemSeq, CustSeq, KindName, KindSeq ) 
    SELECT A.BizUnit, A.ItemSeq, A.CustSeq, B.KindName, B.KindSeq 
      FROM (SELECT DISTINCT BizUnit, ItemSeq, CustSeq FROM #TEMP) AS A 
      JOIN (
            SELECT '사업계획' AS KindName, 1 AS KindSeq 
            UNION ALL 
            SELECT '실적', 2 
            UNION ALL 
            SELECT '계획 대비 실적', 3 
           ) AS B ON ( 1 = 1 ) 
    
    -- 기초데이터 
    CREATE TABLE #BaseData 
    (
        BizUnit     INT, 
        ItemSeq     INT, 
        CustSeq     INT, 
        KindName    NVARCHAR(100), 
        KindSeq     INT, 
        PlanYM      NCHAR(6), 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5) 
        
    )
    INSERT INTO #BaseData ( BizUnit, ItemSeq, CustSeq, KindName, KindSeq, PlanYM, Qty, Amt ) 
    SELECT A.BizUnit, A.ItemSeq, A.CustSeq, A.KindName, A.KindSeq, B.PlanYm, ISNULL(B.Qty,0) AS Qty, ISNULL(B.Amt,0) AS Amt 
      FROM #Kind AS A 
      LEFT OUTER JOIN  #TEMP AS B ON ( B.BizUnit = A.BizUnit AND B.ItemSeq = A.ItemSeq AND B.CustSeq = A.CustSeq AND B.KindSeq = A.KindSeq ) -- AND B.PlanYM = '201401' ) 
     ORDER BY A.BizUnit, A.ItemSeq, A.CustSeq, A.KindSeq 
    
    SELECT A.BizUnit, 
           B.BizUnitName, 
           A.ItemSeq, 
           C.ItemName, 
           A.CustSeq, 
           D.CustName, 
           A.KindName, 
           A.KindSeq, 
           ISNULL(E.Qty,0) AS Qty1, 
           ISNULL(E.Amt,0) AS Amt1,
           ISNULL(F.Qty,0) AS Qty2, 
           ISNULL(F.Amt,0) AS Amt2, 
           ISNULL(G.Qty,0) AS Qty3, 
           ISNULL(G.Amt,0) AS Amt3,
           ISNULL(H.Qty,0) AS Qty4, 
           ISNULL(H.Amt,0) AS Amt4,
           ISNULL(I.Qty,0) AS Qty5, 
           ISNULL(I.Amt,0) AS Amt5,
           ISNULL(J.Qty,0) AS Qty6, 
           ISNULL(J.Amt,0) AS Amt6,
           ISNULL(K.Qty,0) AS Qty7, 
           ISNULL(K.Amt,0) AS Amt7,
           ISNULL(L.Qty,0) AS Qty8 , 
           ISNULL(L.Amt,0) AS Amt8,
           ISNULL(M.Qty,0) AS Qty9, 
           ISNULL(M.Amt,0) AS Amt9,
           ISNULL(N.Qty,0) AS Qty10, 
           ISNULL(N.Amt,0) AS Amt10,
           ISNULL(O.Qty,0) AS Qty11, 
           ISNULL(O.Amt,0) AS Amt11,
           ISNULL(P.Qty,0) AS Qty12, 
           ISNULL(P.Amt,0) AS Amt12, 
           ISNULL(Q.SumQty,0) AS SumQty, 
           ISNULL(Q.SumAmt,0) AS SumAmt 
      INTO #Result 
      FROM (SELECT DISTINCT BizUnit, ItemSeq, CustSeq, KindName, KindSeq FROM #BaseData) AS A 
      LEFT OUTER JOIN _TDABizUnit AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDAItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACust    AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '01'
                  ) AS E 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '02'
                  ) AS F 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '03'
                  ) AS G
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '04'
                  ) AS H
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '05'
                  ) AS I 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '06'
                  ) AS J 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '07'
                  ) AS K 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '08'
                  ) AS L 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '09'
                  ) AS M 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '10'
                  ) AS N 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt 
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '11'
                  ) AS O 
      OUTER APPLY ( SELECT Z.Qty, Z.Amt
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                       AND Z.PlanYM = @StdYear + '12'
                  ) AS P 
      OUTER APPLY ( SELECT SUM(Qty) AS SumQty, SUM(Amt) AS SumAmt 
                      FROM #BaseData AS Z 
                     WHERE Z.BizUnit = A.BizUnit 
                       AND Z.ItemSeq = A.ItemSeq 
                       AND Z.CustSeq = A.CustSeq 
                       AND Z.KindSeq = A.KindSeq 
                  ) AS Q 
     ORDER BY A.BizUnit, A.ItemSeq, A.CustSeq, A.KindSeq
    
    
    
    
    CREATE TABLE #Result_Sub
    (
        BizUnit         INT, 
        BizUnitName     NVARCHAR(100), 
        ItemSeq         INT, 
        ItemName        NVARCHAR(100), 
        CustSeq         INT, 
        CustName        NVARCHAR(100), 
        KindName        NVARCHAR(100), 
        KindSeq         INT, 
        Qty1            DECIMAL(19,5), 
        Amt1            DECIMAL(19,5),
        Qty2            DECIMAL(19,5),
        Amt2            DECIMAL(19,5),
        Qty3            DECIMAL(19,5),
        Amt3            DECIMAL(19,5),
        Qty4            DECIMAL(19,5),
        Amt4            DECIMAL(19,5),
        Qty5            DECIMAL(19,5),
        Amt5            DECIMAL(19,5),
        Qty6            DECIMAL(19,5),
        Amt6            DECIMAL(19,5),
        Qty7            DECIMAL(19,5),
        Amt7            DECIMAL(19,5),
        Qty8            DECIMAL(19,5),
        Amt8            DECIMAL(19,5),
        Qty9            DECIMAL(19,5),
        Amt9            DECIMAL(19,5),
        Qty10           DECIMAL(19,5),
        Amt10           DECIMAL(19,5),
        Qty11           DECIMAL(19,5),
        Amt11           DECIMAL(19,5),
        Qty12           DECIMAL(19,5),
        Amt12           DECIMAL(19,5),
        SumQty          DECIMAL(19,5),
        SumAmt          DECIMAL(19,5)
    ) 
    
    INSERT INTO #Result_Sub 
    SELECT BizUnit     ,
           BizUnitName ,
           ItemSeq     ,
           ItemName    ,
           CustSeq     ,
           CustName    ,
           KindName    ,
           KindSeq     ,
           Qty1        ,
           Amt1        ,
           Qty2        ,
           Amt2        ,
           Qty3        ,
           Amt3        ,
           Qty4        ,
           Amt4        ,
           Qty5        ,
           Amt5        ,
           Qty6        ,
           Amt6        ,
           Qty7        ,
           Amt7        ,
           Qty8        ,
           Amt8        ,
           Qty9        ,
           Amt9        ,
           Qty10       ,
           Amt10       ,
           Qty11       ,
           Amt11       ,
           Qty12       ,
           Amt12       ,
           SumQty      ,
           SumAmt      
      FROM #Result 
    
    UNION ALL 
    
    SELECT BizUnit, BizUnitName, 99999999, '소계', 99999999, '', KindName, KindSeq,
           SUM(Qty1) AS Qty1, 
           SUM(Amt1) AS Amt1, 
           SUM(Qty2) AS Qty2, 
           SUM(Amt2) AS Amt2, 
           SUM(Qty3) AS Qty3, 
           SUM(Amt3) AS Amt3, 
           SUM(Qty4) AS Qty4, 
           SUM(Amt4) AS Amt4, 
           SUM(Qty5) AS Qty5, 
           SUM(Amt5) AS Amt5, 
           SUM(Qty6) AS Qty6, 
           SUM(Amt6) AS Amt6, 
           SUM(Qty7) AS Qty7, 
           SUM(Amt7) AS Amt7, 
           SUM(Qty8) AS Qty8, 
           SUM(Amt8) AS Amt8, 
           SUM(Qty9) AS Qty9, 
           SUM(Amt9) AS Amt9, 
           SUM(Qty10) AS Qty10, 
           SUM(Amt10) AS Amt10, 
           SUM(Qty11) AS Qty11, 
           SUM(Amt11) AS Amt11, 
           SUM(Qty12) AS Qty12, 
           SUM(Amt12) AS Amt12, 
           SUM(SumQty) AS SumQty, 
           SUM(SumAmt) AS SumAmt 
      FROM #Result 
     GROUP BY BizUnit, BizUnitName, KindName, KindSeq 
     
    UNION ALL 
    
    SELECT 99999999, '합계', 99999999, '', 99999999, '', KindName, KindSeq,
           SUM(Qty1) AS Qty1, 
           SUM(Amt1) AS Amt1, 
           SUM(Qty2) AS Qty2, 
           SUM(Amt2) AS Amt2, 
           SUM(Qty3) AS Qty3, 
           SUM(Amt3) AS Amt3, 
           SUM(Qty4) AS Qty4, 
           SUM(Amt4) AS Amt4, 
           SUM(Qty5) AS Qty5, 
           SUM(Amt5) AS Amt5, 
           SUM(Qty6) AS Qty6, 
           SUM(Amt6) AS Amt6, 
           SUM(Qty7) AS Qty7, 
           SUM(Amt7) AS Amt7, 
           SUM(Qty8) AS Qty8, 
           SUM(Amt8) AS Amt8, 
           SUM(Qty9) AS Qty9, 
           SUM(Amt9) AS Amt9, 
           SUM(Qty10) AS Qty10, 
           SUM(Amt10) AS Amt10, 
           SUM(Qty11) AS Qty11, 
           SUM(Amt11) AS Amt11, 
           SUM(Qty12) AS Qty12, 
           SUM(Amt12) AS Amt12, 
           SUM(SumQty) AS SumQty, 
           SUM(SumAmt) AS SumAmt 
      FROM #Result 
     GROUP BY KindName, KindSeq
     ORDER BY BizUnit, ItemSeq, CustSeq, KindSeq
    
    
    
    -- 구분3 (계획대비실적) 계산해서 업데이트하기 
    UPDATE #Result_Sub
       SET Qty1 = B.Qty1 - C.Qty1, 
           Amt1 = B.Amt1 - C.Amt1, 
           Qty2 = B.Qty2 - C.Qty2, 
           Amt2 = B.Amt2 - C.Amt2, 
           Qty3 = B.Qty3 - C.Qty3, 
           Amt3 = B.Amt3 - C.Amt3, 
           Qty4 = B.Qty4 - C.Qty4, 
           Amt4 = B.Amt4 - C.Amt4, 
           Qty5 = B.Qty5 - C.Qty5, 
           Amt5 = B.Amt5 - C.Amt5, 
           Qty6 = B.Qty6 - C.Qty6, 
           Amt6 = B.Amt6 - C.Amt6, 
           Qty7 = B.Qty7 - C.Qty7, 
           Amt7 = B.Amt7 - C.Amt7, 
           Qty8 = B.Qty8 - C.Qty8, 
           Amt8 = B.Amt8 - C.Amt8, 
           Qty9 = B.Qty9 - C.Qty9, 
           Amt9 = B.Amt9 - C.Amt9, 
           Qty10 = B.Qty10 - C.Qty10,
           Amt10 = B.Amt10 - C.Amt10,
           Qty11 = B.Qty11 - C.Qty11,
           Amt11 = B.Amt11 - C.Amt11,
           Qty12 = B.Qty12 - C.Qty12,
           Amt12 = B.Amt12 - C.Amt12, 
           SumQty = B.SumQty - C.SumQty, 
           SumAmt = B.SumQty - C.SumQty
      FROM #Result_Sub AS A 
      OUTER APPLY (SELECT Z.Qty1 ,
                          Z.Amt1 ,
                          Z.Qty2 ,
                          Z.Amt2 ,
                          Z.Qty3 ,
                          Z.Amt3 ,
                          Z.Qty4 ,
                          Z.Amt4 ,
                          Z.Qty5 ,
                          Z.Amt5 ,
                          Z.Qty6 ,
                          Z.Amt6 ,
                          Z.Qty7 ,
                          Z.Amt7 ,
                          Z.Qty8 ,
                          Z.Amt8 ,
                          Z.Qty9 ,
                          Z.Amt9 ,
                          Z.Qty10,
                          Z.Amt10,
                          Z.Qty11,
                          Z.Amt11,
                          Z.Qty12,
                          Z.Amt12,
                          Z.SumQty, 
                          Z.SumAmt
                     FROM #Result_Sub AS Z 
                    WHERE Z.KindSeq = 1 
                      AND Z.BizUnit = A.BizUnit 
                      AND Z.ItemSeq = A.ItemSeq 
                      AND Z.CustSeq = A.CustSeq 
                  ) AS B 
      OUTER APPLY (SELECT Z.Qty1 ,
                          Z.Amt1 ,
                          Z.Qty2 ,
                          Z.Amt2 ,
                          Z.Qty3 ,
                          Z.Amt3 ,
                          Z.Qty4 ,
                          Z.Amt4 ,
                          Z.Qty5 ,
                          Z.Amt5 ,
                          Z.Qty6 ,
                          Z.Amt6 ,
                          Z.Qty7 ,
                          Z.Amt7 ,
                          Z.Qty8 ,
                          Z.Amt8 ,
                          Z.Qty9 ,
                          Z.Amt9 ,
                          Z.Qty10,
                          Z.Amt10,
                          Z.Qty11,
                          Z.Amt11,
                          Z.Qty12,
                          Z.Amt12,
                          Z.SumQty, 
                          Z.SumAmt
                     FROM #Result_Sub AS Z 
                    WHERE Z.KindSeq = 2 
                      AND Z.BizUnit = A.BizUnit 
                      AND Z.ItemSeq = A.ItemSeq 
                      AND Z.CustSeq = A.CustSeq 
                  ) AS C 
     WHERE KindSeq = 3
    
    SELECT * FROM #Result_Sub ORDER BY BizUnit, ItemSeq, CustSeq, KindSeq 
    
    RETURN  
GO 
exec KPX_SSLExpYearPlanResultQuery @xmlDocument=N'<ROOT>
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
 