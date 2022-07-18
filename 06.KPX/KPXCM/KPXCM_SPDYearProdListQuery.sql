  
IF OBJECT_ID('KPXCM_SPDYearProdListQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDYearProdListQuery  
GO  
  
-- v2016.05.18  
  
-- [年]연간생산현황-조회 by 이재천   
CREATE PROC KPXCM_SPDYearProdListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT, 
            @StdYear    NCHAR(4), 
            @QueryYM    NCHAR(6), 
            @UMUnitSeq  INT, 
            @ItemName   NVARCHAR(200), 
            @ItemNo     NVARCHAR(200), 
            @ItemKind   INT, 
            @BizUnit    INT, -- 생산사업장의 사업부문 
            @UnitQty    DECIMAL(19,5) 

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit  , 0 ),  
           @StdYear    = ISNULL( StdYear   , '' ),  
           @QueryYM    = ISNULL( QueryYM   , '' ),  
           @UMUnitSeq  = ISNULL( UMUnitSeq , 0 ),  
           @ItemName   = ISNULL( ItemName  , '' ),  
           @ItemNo     = ISNULL( ItemNo    , '' ),  
           @ItemKind   = ISNULL( ItemKind  , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT, 
            StdYear    NCHAR(4),       
            QueryYM    NCHAR(6),       
            UMUnitSeq  INT,       
            ItemName   NVARCHAR(200),      
            ItemNo     NVARCHAR(200),      
            ItemKind   INT       
           )    
    
    SELECT @BizUnit = BizUnit 
      FROM _TDAFactUnit  
     WHERE CompanySeq = @CompanySeq 
       AND FactUnit = @FactUnit 
    
    SELECT @UnitQty = CASE WHEN @UMUnitSeq = 1 THEN 1000 ELSE 1 END 
    --return 
    
    
    -- 결과테이블 만들기 
    CREATE TABLE #Result 
    (
        ItemSeq     INT, 
        ItemName    NVARCHAR(100),
        ItemNo      NVARCHAR(100), 
        KindName    NVARCHAR(100), 
        KindSeq     INT, 
        Month01     DECIMAL(19,5), 
        Month02     DECIMAL(19,5), 
        Month03     DECIMAL(19,5), 
        Month04     DECIMAL(19,5), 
        Month05     DECIMAL(19,5), 
        Month06     DECIMAL(19,5), 
        Month07     DECIMAL(19,5), 
        Month08     DECIMAL(19,5), 
        Month09     DECIMAL(19,5), 
        Month10     DECIMAL(19,5), 
        Month11     DECIMAL(19,5), 
        Month12     DECIMAL(19,5), 
        MonthSum    DECIMAL(19,5), 
        MonthAvg    DECIMAL(19,5), 
        Sort        INT, 
        IsColor     NCHAR(1) 
    )
    
    -- 제품,반제품 전체 담기 
    INSERT INTO #Result ( ItemSeq, ItemName, ItemNo, KindName, KindSeq, Sort ) 
    SELECT A.ItemSeq, 
           CASE WHEN (CASE WHEN A.ItemEngSName = '' THEN A.ItemSName ELSE A.ItemEngSName END) <> '' 
                THEN (CASE WHEN A.ItemEngSName = '' THEN A.ItemSName ELSE A.ItemEngSName END) 
                ELSE A.ItemName 
           END AS ItemName, 
           A.ItemNo, 
           B.KindName, 
           B.KindSeq, 
           1
      FROM _TDAItem         AS A 
      JOIN ( 
            SELECT '생산' KindName, 1 AS KindSeq 
            UNION ALL 
            SELECT '판매' KindName, 2 AS KindSeq 
            UNION ALL 
            SELECT '자가소비' KindName, 3 AS KindSeq 
           ) AS B ON ( 1 = 1 ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.MngSerl = 1000003 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AssetSeq IN ( 18, 20 ) 
       AND ( @ItemName = '' OR A.ItemName LIKE '%' + @ItemName + '%' ) 
       AND ( @ItemNo = '' OR A.ItemNo LIKE '%' + @ItemNo + '%' ) 
       AND ( @ItemKind = 0 OR C.MngValSeq = @ItemKind ) 
     ORDER BY ItemName, KindSeq 
    -- 생산량 구하기 
    SELECT Z.GoodItemSeq, 
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '01' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month01, 
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '02' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month02,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '03' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month03,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '04' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month04,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '05' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month05,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '06' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month06,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '07' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month07,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '08' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month08,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '09' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month09,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '10' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month10,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '11' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month11,
           SUM(CASE WHEN LEFT(Z.WorkDate,6) = @StdYear + '12' THEN ISNULL(Z.StdUnitProdQty,0) / @UnitQty ELSE 0 END) AS Month12, 
           SUM(ISNULL(Z.StdUnitProdQty,0) / @UnitQty ) AS MonthSum, 
           SUM(ISNULL(Z.StdUnitProdQty,0) / @UnitQty ) / CONVERT(INT,RIGHT(@QueryYM,2)) AS MonthAvg 
      INTO #TPDSFCWorkReport 
      FROM _TPDSFCWorkReport AS Z 
      JOIN #Result           AS Y ON ( Y.ItemSeq = Z.GoodItemSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND Z.GoodItemSeq = Z.GoodItemSeq 
       AND LEFT(Z.WorkDate,4) = @StdYear 
       AND LEFT(Z.WorkDate,6) <= @QueryYM 
       AND Z.FactUnit = @FactUnit 
     GROUP BY Z.GoodItemSeq
    
    UPDATE A 
       SET Month01  = B.Month01 , 
           Month02  = B.Month02 , 
           Month03  = B.Month03 , 
           Month04  = B.Month04 , 
           Month05  = B.Month05 , 
           Month06  = B.Month06 , 
           Month07  = B.Month07 , 
           Month08  = B.Month08 , 
           Month09  = B.Month09 , 
           Month10  = B.Month10 , 
           Month11  = B.Month11 , 
           Month12  = B.Month12 , 
           MonthSum = B.MonthSum, 
           MonthAvg = B.MonthAvg
      FROM #Result              AS A 
      JOIN #TPDSFCWorkReport    AS B ON ( B.GoodItemSeq = A.ItemSeq )
     WHERE A.KindSeq = 1 
    
    -- 판매량 구하기 
    SELECT Y.ItemSeq, 
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '01' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month01, 
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '02' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month02,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '03' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month03,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '04' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month04,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '05' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month05,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '06' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month06,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '07' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month07,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '08' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month08,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '09' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month09,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '10' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month10,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '11' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month11,
           SUM(CASE WHEN LEFT(Z.InvoiceDate,6) = @StdYear + '12' THEN ISNULL(Y.STDQty,0) / @UnitQty ELSE 0 END) AS Month12, 
           SUM(ISNULL(Y.STDQty,0) / @UnitQty) AS MonthSum, 
           SUM(ISNULL(Y.STDQty,0) / @UnitQty) / CONVERT(INT,RIGHT(@QueryYM,2)) AS MonthAvg 
      INTO #TSLInvoice 
      FROM _TSLInvoice      AS Z 
      JOIN _TSLInvoiceItem  AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.InvoiceSeq = Z.InvoiceSeq ) 
      JOIN #Result          AS Q ON ( Q.ItemSeq = Y.ItemSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND LEFT(Z.InvoiceDate,4) = @StdYear 
       AND LEFT(Z.InvoiceDate,6) <= @QueryYM 
       AND Z.BizUnit = @BizUnit 
       AND Z.IsDelvCfm = '1' 
     GROUP BY Y.ItemSeq 
    
    UPDATE A 
       SET Month01  = B.Month01 , 
           Month02  = B.Month02 , 
           Month03  = B.Month03 , 
           Month04  = B.Month04 , 
           Month05  = B.Month05 , 
           Month06  = B.Month06 , 
           Month07  = B.Month07 , 
           Month08  = B.Month08 , 
           Month09  = B.Month09 , 
           Month10  = B.Month10 , 
           Month11  = B.Month11 , 
           Month12  = B.Month12 , 
           MonthSum = B.MonthSum, 
           MonthAvg = B.MonthAvg
      FROM #Result      AS A 
      JOIN #TSLInvoice  AS B ON ( B.ItemSeq = A.ItemSeq )
     WHERE A.KindSeq = 2  
    
    -- 자가소비량 구하기 
    SELECT Z.MatItemSeq, 
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '01' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month01, 
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '02' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month02,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '03' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month03,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '04' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month04,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '05' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month05,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '06' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month06,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '07' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month07,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '08' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month08,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '09' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month09,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '10' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month10,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '11' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month11,
           SUM(CASE WHEN LEFT(Z.InputDate,6) = @StdYear + '12' THEN ISNULL(Z.StdUnitQty,0) / @UnitQty ELSE 0 END) AS Month12, 
           SUM(ISNULL(Z.StdUnitQty,0) / @UnitQty) AS MonthSum, 
           SUM(ISNULL(Z.StdUnitQty,0) / @UnitQty) / CONVERT(INT,RIGHT(@QueryYM,2)) AS MonthAvg 
      INTO #TPDSFCMatinput
      FROM _TPDSFCMatinput      AS Z 
      JOIN #Result              AS S ON ( S.ItemSeq = Z.MatItemSeq ) 
      JOIN _TPDSFCWorkReport    AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WorkReportSeq = Z.WorkReportSeq ) 
      JOIN _TDAItem             AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.ItemSeq = Z.MatItemSeq ) 
      JOIN _TDAItemAsset        AS W ON ( W.CompanySeq = @CompanySeq AND W.AssetSeq = Q.AssetSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND LEFT(Z.InputDate,4) = @StdYear 
       AND LEFT(Z.InputDate,6) <= @QueryYM 
       AND Y.FactUnit = @FactUnit 
       AND W.SMAssetGrp <> 6008005  
     GROUP BY Z.MatItemSeq  
    
    UPDATE A 
       SET Month01  = B.Month01 , 
           Month02  = B.Month02 , 
           Month03  = B.Month03 , 
           Month04  = B.Month04 , 
           Month05  = B.Month05 , 
           Month06  = B.Month06 , 
           Month07  = B.Month07 , 
           Month08  = B.Month08 , 
           Month09  = B.Month09 , 
           Month10  = B.Month10 , 
           Month11  = B.Month11 , 
           Month12  = B.Month12 , 
           MonthSum = B.MonthSum, 
           MonthAvg = B.MonthAvg
      FROM #Result          AS A 
      JOIN #TPDSFCMatinput  AS B ON ( B.MatItemSeq = A.ItemSeq )
     WHERE A.KindSeq = 3 
     
    
    -- 생산, 판매, 자가소비 없는 품목은 삭제 
    SELECT ItemSeq-- , COUNT(1) AS Cnt 
      INTO #DeleteItem 
      FROM #Result 
     WHERE Month01 IS NULL 
       AND Month02 IS NULL 
       AND Month03 IS NULL 
       AND Month04 IS NULL 
       AND Month05 IS NULL 
       AND Month06 IS NULL 
       AND Month07 IS NULL 
       AND Month08 IS NULL 
       AND Month09 IS NULL 
       AND Month10 IS NULL 
       AND Month11 IS NULL 
       AND Month12 IS NULL 
     GROUP BY ItemSeq 
     HAVING COUNT(1) = 3 
    
    DELETE A 
      FROM #Result      AS A 
      JOIN #DeleteItem  AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    --select * from #Result 
    --return 
    
    INSERT INTO #Result 
    ( 
        ItemSeq     ,        ItemName    ,        ItemNo      ,        KindName    ,        KindSeq     ,        
        Month01     ,        Month02     ,        Month03     ,        Month04     ,        Month05     ,        
        Month06     ,        Month07     ,        Month08     ,        Month09     ,        Month10     ,        
        Month11     ,        Month12     ,        MonthSum    ,        MonthAvg    ,        Sort        
    ) 
    SELECT 999999999, 
           '총 계', 
           ' ', 
           KindName, 
           KindSeq, 
           SUM(Month01) AS Month01, 
           SUM(Month02) AS Month02,
           SUM(Month03) AS Month03,
           SUM(Month04) AS Month04,
           SUM(Month05) AS Month05,
           SUM(Month06) AS Month06,
           SUM(Month07) AS Month07,
           SUM(Month08) AS Month08,
           SUM(Month09) AS Month09,
           SUM(Month10) AS Month10,
           SUM(Month11) AS Month11,
           SUM(Month12) AS Month12,
           SUM(Month01) + SUM(Month02) + SUM(Month03) + SUM(Month04) + SUM(Month05) + 
           SUM(Month06) + SUM(Month07) + SUM(Month08) + SUM(Month09) + SUM(Month10) + 
           SUM(Month11) + SUM(Month12) AS MonthSum, 
           (SUM(Month01) + SUM(Month02) + SUM(Month03) + SUM(Month04) + SUM(Month05) + 
            SUM(Month06) + SUM(Month07) + SUM(Month08) + SUM(Month09) + SUM(Month10) + 
            SUM(Month11) + SUM(Month12)) / CONVERT(INT,RIGHT(@QueryYM,2)) AS MonthAvg, 
           3 AS Sort 
      FROM #Result 
     GROUP BY KindName, KindSeq 
    
    
    -- 색상여부 
    CREATE TABLE #IsColor 
    (
        RowCnt      INT IDENTITY, 
        ItemSeq     INT 
    )
    INSERT INTO #IsColor ( ItemSeq ) 
    SELECT ItemSeq
      FROM #Result 
     WHERE KindSeq = 1 
     ORDER BY Sort, ItemName, KindSeq 
    
    UPDATE A
       SET A.IsColor = CASE WHEN B.RowCnt % 2 = 1 THEN '0' ELSE '1' END 
      FROM #Result  AS A 
      JOIN #IsColor AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    -- 최종 조회 
    SELECT *, 
           CASE WHEN Sort = 1 AND IsColor = '1' THEN '-1379875' 
                WHEN Sort = 1 AND IsColor = '0' THEN '-1' 
                ELSE '-860708' 
           END AS Color 
      FROM #Result 
     ORDER BY Sort, ItemName, KindSeq  
    
    RETURN  
    GO 
    
exec KPXCM_SPDYearProdListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>3</FactUnit>
    <StdYear>2016</StdYear>
    <QueryYM>201604</QueryYM>
    <UMUnitSeq>1</UMUnitSeq>
    <ItemName />
    <ItemNo />
    <ItemKind />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037068,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030383