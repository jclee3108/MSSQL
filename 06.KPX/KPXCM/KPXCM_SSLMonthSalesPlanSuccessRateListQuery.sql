  
IF OBJECT_ID('KPXCM_SSLMonthSalesPlanSuccessRateListQuery') IS NOT NULL   
    DROP PROC KPXCM_SSLMonthSalesPlanSuccessRateListQuery  
GO  
  
-- v2015.11.06  
  
-- 월간판매계획 대비 실적 적중률-조회 by 이재천   
CREATE PROC KPXCM_SSLMonthSalesPlanSuccessRateListQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @BizUnit        INT, 
            @MultiUMUseType NVARCHAR(MAX), 
            @StdYMFr        NCHAR(6), 
            @StdYMTo        NCHAR(6), 
            @UMUseType      INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit   = ISNULL( BizUnit, 0 ),  
           @MultiUMUseType = ISNULL( MultiUMUseType, '' ), 
           @StdYMFr  = ISNULL( StdYMFr, '' ), 
           @StdYMTo  = ISNULL( StdYMTo, '' ), 
           @UMUseType = ISNULL( UMUseType, 0 ), 
           @ItemName  = ISNULL( ItemName, ''), 
           @ItemNo    = ISNULL( ItemNo, '') 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit         INT, 
            MultiUMUseType  NVARCHAR(MAX), 
            StdYMFr         NCHAR(6),      
            StdYMTo         NCHAR(6), 
            UMUseType       INT, 
            ItemName        NVARCHAR(100), 
            ItemNo          NVARCHAR(100)
           )    
    
    IF @StdYMTo = '' SELECT @StdYMTo = '999912'
    
    --------------------------------------------------------------------------------------------------
    -- 기초데이터 
    --------------------------------------------------------------------------------------------------
    CREATE TABLE #BaseData 
    (
        IDX_NO      INT IDENTITY, 
        SalesSeq    INT, 
        SalesSerl   INT, 
        ItemSeq     INT, 
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5), 
        DeptSeq     INT, 
        UMUseType   INT
    )
    INSERT INTO #BaseData
    (
        SalesSeq, SalesSerl, ItemSeq, Qty, Amt, DeptSeq, 
        UMUseType
    )    
    SELECT A.SalesSeq, B.SalesSerl, B.ItemSeq, B.STDQty, B.DomAmt, D.SLDeptSeq, 
           0
      FROM _TSLSales                        AS A 
      LEFT OUTER JOIN _TSLSalesItem         AS B ON ( B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq ) 
      LEFT OUTER JOIN _TSLSalesBillRelation AS C ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.SalesSeq AND C.SalesSerl = B.SalesSerl ) 
      LEFT OUTER JOIN KPX_TSLBillAdd        AS D ON ( D.Companyseq = @CompanySeq AND D.BillSeq = C.BillSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.SalesDate,6) BETWEEN @StdYMFr AND @StdYMTo 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       --AND B.ItemSeq <> 1689 -- 매출할인 제외 
    --------------------------------------------------------------------------------------------------
    -- 기초데이터, END 
    --------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------
    -- 품목용도 구하기 위함 거래명세서 원천 조회 
    --------------------------------------------------------------------------------------------------
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TSLInvoiceItem'   -- 찾을 데이터의 테이블

    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
          
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TSLSalesItem',  -- 기준 테이블
                             @TempTableName = '#BaseData',  -- 기준템프테이블
                             @TempSeqColumnName = 'SalesSeq',  -- 템프테이블 Seq
                             @TempSerlColumnName = 'SalesSerl',  -- 템프테이블 Serl
                             @TempSubSerlColumnName = '' 

    UPDATE A 
       SET UMUseType = C.UMUseType
      FROM #BaseData                AS A 
      JOIN #TCOMSourceTracking      AS B ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN KPX_TSLInvoiceItemAdd    AS C ON ( C.CompanySeq = @CompanySeq AND C.InvoiceSeq = B.Seq AND C.InvoiceSerl = B.Serl ) 
    --------------------------------------------------------------------------------------------------
    -- 품목용도 구하기 위함 거래명세서 원천 조회, END 
    --------------------------------------------------------------------------------------------------
    --(SELECT Code FROM _FCOMXmlToSeq(@UMUseType, @MultiUMUseType))
    --return 
    

    
    ----------------------------------------------------------------------------------------
    -- 판매실적, 판매계획 품목 담기 
    ----------------------------------------------------------------------------------------
    SELECT DISTINCT A.DeptSeq, A.UMUseType, A.ItemSeq
      INTO #Item
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE ( @ItemName = '' OR B.ItemName LIKE @ItemName +'%' ) 
       AND ( @ItemNo = '' OR B.ItemNo LIKE @ItemNo +'%' ) 
    
    UNION 
    
    SELECT DISTINCT Z.DeptSeq, Z.UMUseType, Z.ItemSeq
      FROM KPXCM_TSLMonthSalesPlan AS Z 
      JOIN ( 
            SELECT Y.BizUnit, Y.DeptSeq, Y.PlanYM, MAX(PlanRev) MaxPlanRev
              FROM KPXCM_TSLMonthSalesPlan AS Y
             WHERE Y.CompanySeq = @CompanySeq 
             GROUP BY Y.BizUnit, Y.DeptSeq, Y.PlanYM 
           ) AS Q ON ( Q.BizUnit = Z.BizUnit AND Q.DeptSeq = Z.DeptSeq AND Q.PlanYM = Z.PlanYM AND Q.MaxPlanRev = Z.PlanRev ) 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = Z.ItemSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND Z.PlanYM BETWEEN @StdYMFr AND @StdYMTo 
       AND Z.BizUnit = @BizUnit 
       AND ( @ItemName = '' OR B.ItemName LIKE @ItemName +'%' ) 
       AND ( @ItemNo = '' OR B.ItemNo LIKE @ItemNo +'%' ) 
    ----------------------------------------------------------------------------------------
    -- 판매실적, 판매계획 품목 담기, END  
    ----------------------------------------------------------------------------------------
    --select * from #Item 
    --return     
    ---------------------------
    -- 품목용도 조회조건 
    ---------------------------
    DELETE A
      FROM #Item AS A 
     WHERE (SELECT TOP 1 Code FROM _FCOMXmlToSeq(@UMUseType, @MultiUMUseType)) <> 0 
       AND A.UMUseType NOT IN (SELECT Code FROM _FCOMXmlToSeq(@UMUseType, @MultiUMUseType))
    ---------------------------
    -- 품목용도 조회조건, END 
    ---------------------------
    
    --------------------------------------------------------------------------------------------
    -- 판매계획, 매출을 품목, 용도, 부서로 집계 and 내수 수출 구분 넣기 
    --------------------------------------------------------------------------------------------
    SELECT A.ItemSeq, A.UMUseType, A.DeptSeq, MAX(C.ExpKind) AS ExpKind, SUM(ISNULL(D.Amt,0)) AS Amt, SUM(ISNULL(D.Qty,0)) AS Qty, 
           MAX(ISNULL(B.PlanQty,0)) AS PlanQty, MAX(ISNULL(B.PlanAmt,0)) AS PlanAmt, 2 AS Sort
      INTO #Temp 
      FROM #Item AS A 
      LEFT OUTER JOIN #BaseData AS D ON ( D.ItemSeq = A.ItemSeq AND D.UMUseType = A.UMUseType AND D.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.DeptSeq, Z.UMUseType, Z.ItemSeq, SUM(Z.PlanQty) AS PlanQty, SUM(Z.PlanKorAmt) AS PlanAmt
                          FROM KPXCM_TSLMonthSalesPlan AS Z 
                          JOIN ( 
                                SELECT Y.BizUnit, Y.DeptSeq, Y.PlanYM, MAX(PlanRev) MaxPlanRev
                                  FROM KPXCM_TSLMonthSalesPlan AS Y
                                 WHERE Y.CompanySeq = @CompanySeq 
                                 GROUP BY Y.BizUnit, Y.DeptSeq, Y.PlanYM 
                               ) AS Q ON ( Q.BizUnit = Z.BizUnit AND Q.DeptSeq = Z.DeptSeq AND Q.PlanYM = Z.PlanYM AND Q.MaxPlanRev = Z.PlanRev ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.PlanYM BETWEEN @StdYMFr AND @StdYMTo 
                           AND Z.BizUnit = @BizUnit 
                         GROUP BY Z.DeptSeq, Z.UMUseType, Z.ItemSeq 
                      ) AS B ON ( B.DeptSeq = A.DeptSeq AND B.UMUseType = A.UMUseType AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN (
                        SELECT X.DeptSeq, Q.ExpKind
                          FROM _TDAUMinorValue AS Z 
                          OUTER APPLY( SELECT Y.ValueSeq AS DeptSeq 
                                         FROM _TDAUMinorValue AS Y 
                                        WHERE Y.CompanySeq = @CompanySeq 
                                          AND Y.MinorSeq = Z.MinorSeq 
                                          AND Y.Serl = 1000002 
                                     ) AS X 
                          OUTER APPLY( SELECT Y.ValueSeq AS ExpKind
                                         FROM _TDAUMinorValue AS Y 
                                        WHERE Y.CompanySeq = @CompanySeq 
                                          AND Y.MinorSeq = Z.MinorSeq 
                                          AND Y.Serl = 1000003 
                                     ) AS Q 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.MajorSeq = 1011807 
                           AND Z.Serl = 1000001 
                           AND Z.ValueSeq = @BizUnit 
                      ) AS C ON ( C.DeptSeq = A.DeptSeq ) 
                          
     GROUP BY A.ItemSeq, A.UMUseType, A.DeptSeq
    --------------------------------------------------------------------------------------------
    -- 판매계획, 매출을 품목, 용도, 부서로 집계, END  
    --------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------
    -- 내수 합계 
    --------------------------------------------------------------------------------------------
    INSERT INTO #Temp 
    SELECT A.ItemSeq, A.UMUseType, 888888888, 1010843001, SUM(Amt), SUM(Qty), SUM(PlanQty), SUM(PlanAmt), 3
      FROM #Temp AS A 
     WHERE A.ExpKind = 1010843001
     GROUP BY A.ItemSeq, A.UMUseType
    
    --select * from #Temp 
    --  return 
    --------------------------------------------------------------------------------------------
    -- 내수 합계, END  
    --------------------------------------------------------------------------------------------
    
    ----------------------------------
    -- Title 
    ----------------------------------
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT, 
        Title2     NVARCHAR(100), 
        TitleSeq2  INT, 
        Title3     NVARCHAR(100), 
        TitleSeq3  INT, 
        SortSub    INT, 
    )
    INSERT INTO #Title (Title, TitleSeq, Title2, TitleSeq2, Title3, TitleSeq3, SortSub)
    SELECT DISTINCT B.MinorName AS Title, A.ExpKind AS TitleSeq, 
                    CASE WHEN A.DeptSeq = 888888888 THEN '내수합계' ELSE C.DeptName END AS Title2,  A.DeptSeq AS TitleSeq2, 
                    D.Title3, D.TitleSeq3, A.Sort
      FROM #Temp AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ExpKind ) 
      LEFT OUTER JOIN _TDADept      AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN (
                        SELECT '수량' AS Title3, 1 AS TitleSeq3 
                        UNION ALL 
                        SELECT '금액' AS Title3, 2 AS TitleSeq3 
                      ) D ON ( 1 = 1 ) 
     ORDER BY A.ExpKind, A.Sort, Title2, D.TitleSeq3
    --return 

    ----------------------------------
    -- Title, END 
    ----------------------------------
    
    ----------------------------------
    -- Fix
    ----------------------------------
    CREATE TABLE #FixCol
    (
        RowIdx          INT IDENTITY(0, 1), 
        ItemName        NVARCHAR(200), 
        ItemNo          NVARCHAR(200), 
        ItemSeq         INT, 
        UMUseTypeName   NVARCHAR(200),  
        UMUseType       INT, 
        KindName        NVARCHAR(200),  
        Kind            INT, 
        SumQty          DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5), 
        Sort            INT
    )
    
    -- 합계행 
    INSERT INTO #Temp ( ItemSeq, UMUseType, DeptSeq, ExpKind, Amt, Qty, PlanQty, PlanAmt, Sort ) 
    SELECT 999999999, 0, DeptSeq, ExpKind, SUM(Amt), SUM(Qty), SUM(PlanQty), SUM(PlanAmt), 1
      FROM #Temp 
     GROUP BY DeptSeq, ExpKind
     
    INSERT INTO #FixCol ( ItemName, ItemNo, ItemSeq, UMUseTypeName, UMUseType, KindName, Kind, SumQty, SumAmt, Sort )
    SELECT CASE WHEN A.ItemSeq <> 999999999 THEN MAX(B.ItemName) ELSE '합계' END AS ItemName, 
           MAX(B.ItemNo),
           A.ItemSeq, 
           CASE WHEN A.UMUseType = 0 THEN ' ' ELSE MAX(C.MinorName) END AS UMUseTypeName, 
           A.UMUseType, 
           '계획' AS KindName, 
           100 AS Kind,
           SUM(A.PlanQty) AS PlanQty, 
           SUM(A.PlanAmt) AS PlanAmt, 
           A.Sort
      FROM #Temp AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMUseType ) 
     WHERE A.DeptSeq <> 888888888 -- 내수 합계 제외 
     GROUP BY A.ItemSeq, A.UMUseType, A.Sort
    
    UNION ALL 
    
    SELECT CASE WHEN A.ItemSeq <> 999999999 THEN MAX(B.ItemName) ELSE '합계' END AS ItemName, 
           MAX(B.ItemNo),
           A.ItemSeq, 
           CASE WHEN A.UMUseType = 0 THEN ' ' ELSE MAX(C.MinorName) END AS UMUseTypeName,  
           A.UMUseType, 
           '실적' AS KindName, 
           200 AS Kind,
           SUM(A.Qty) AS Qty, 
           SUM(A.Amt) AS Amt, 
           A.Sort
      FROM #Temp AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMUseType ) 
     WHERE A.DeptSeq <> 888888888 -- 내수 합계 제외 
     GROUP BY A.ItemSeq, A.UMUseType, A.Sort
    
    UNION ALL 
    
    SELECT CASE WHEN A.ItemSeq <> 999999999 THEN MAX(B.ItemName) ELSE '합계' END AS ItemName, 
           MAX(B.ItemNo),
           A.ItemSeq, 
           CASE WHEN A.UMUseType = 0 THEN ' ' ELSE MAX(C.MinorName) END AS UMUseTypeName, 
           A.UMUseType, 
           '적중률' AS KindName, 
           300 AS Kind,
           ISNULL(SUM(A.Qty) / NULLIF(SUM(A.PlanQty),0),0) * 100 AS Qty, 
           ISNULL(SUM(A.Amt) / NULLIF(SUM(A.PlanAmt),0),0) * 100 AS Amt, 
           A.Sort
      FROM #Temp AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMUseType ) 
     WHERE A.DeptSeq <> 888888888 -- 내수 합계 제외 
     GROUP BY A.ItemSeq, A.UMUseType, A.Sort
     
     ORDER BY Sort, ItemName, UMUseTypeName, Kind
    

    ----------------------------------
    -- Fix, END 
    ----------------------------------
        
    --select * from #Temp 
    
    ----------------------------------
    -- Value 
    ----------------------------------
    CREATE TABLE #Value
    (
        ItemSeq     INT, 
        UMUseType   INT, 
        ExpKind     INT, 
        DeptSeq     INT, 
        --TitleSeq3   INT, 
        Kind        INT, 
        --Value       NVARCHAR(200)
        Qty         DECIMAL(19,5), 
        Amt         DECIMAL(19,5) 
        
    ) 
    
    INSERT INTO #Value ( ItemSeq, UMUseType, ExpKind, DeptSeq, Kind, Qty, Amt )
    SELECT ItemSeq, UMUseType, ExpKind, DeptSeq, 100, PlanQty, PlanAmt
      FROM #Temp 
    
    UNION ALL 
    
    SELECT ItemSeq, UMUseType, ExpKind, DeptSeq, 200, Qty, Amt
      FROM #Temp 
    
    UNION ALL 
    
    SELECT ItemSeq, UMUseType, ExpKind, DeptSeq, 300, ISNULL(Qty / NULLIF(PlanQty,0),0) * 100, ISNULL(Amt / NULLIF(PlanAmt,0),0) * 100 
      FROM #Temp 
    ----------------------------------
    -- Value, END 
    ----------------------------------
    
    
    --select * from #Value 
    
    --return
    
    ----------------------------------
    -- Result 
    ----------------------------------
    SELECT * FROM #Title 
    SELECT RowIdx, ItemName, ItemNo, ItemSeq, UMUseTypeName, UMUseType, KindName, Kind, Sort, 
           CASE WHEN RowIdx % 3 <> 2 
                THEN dbo._FCOMNumberToStr(LEFT(SumQty, CHARINDEX('.', SumQty) -1) , 0) 
                ELSE dbo._FCOMNumberToStr(LEFT(SumQty, CHARINDEX('.',SumQty) + 2), 2)  
                END AS SumQty, 
           CASE WHEN RowIdx % 3 <> 2 
                THEN dbo._FCOMNumberToStr(LEFT(SumAmt, CHARINDEX('.', SumAmt) -1) , 0)
                ELSE dbo._FCOMNumberToStr(LEFT(SumAmt, CHARINDEX('.',SumAmt) + 2), 2)
                END AS SumAmt
      FROM #FixCol 
     ORDER BY Sort
     
    SELECT B.RowIdx, A.ColIdx, 
           CASE WHEN B.RowIdx % 3 <> 2 
                THEN dbo._FCOMNumberToStr(LEFT(CONVERT(NVARCHAR(100),CASE WHEN A.TitleSeq3 = 1 THEN C.Qty ELSE C.Amt END), CHARINDEX('.',CONVERT(NVARCHAR(100),CASE WHEN A.TitleSeq3 = 1 THEN C.Qty ELSE C.Amt END)) - 1) , 0)
                ELSE dbo._FCOMNumberToStr(LEFT(CONVERT(NVARCHAR(100),CASE WHEN A.TitleSeq3 = 1 THEN C.Qty ELSE C.Amt END),CHARINDEX('.',CONVERT(NVARCHAR(100),CASE WHEN A.TitleSeq3 = 1 THEN C.Qty ELSE C.Amt END)) + 2 ) , 2)
                END AS Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.ExpKind AND A.TitleSeq2 = C.DeptSeq ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq AND B.UMUseType = C.UMUseType AND B.Kind = C.Kind ) 
     ORDER BY A.ColIdx, B.RowIdx
    ----------------------------------
    -- Result, END 
    ----------------------------------

    
    
    
    RETURN  
    go
exec KPXCM_SSLMonthSalesPlanSuccessRateListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemName />
    <ItemNo />
    <BizUnit>1</BizUnit>
    <UMUseType />
    <MultiUMUseType>&amp;lt;XmlString&amp;gt;&amp;lt;/XmlString&amp;gt;</MultiUMUseType>
    <StdYMFr>201511</StdYMFr>
    <StdYMTo>201511</StdYMTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033030,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027322