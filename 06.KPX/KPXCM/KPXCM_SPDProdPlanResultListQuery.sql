  
IF OBJECT_ID('KPXCM_SPDProdPlanResultListQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanResultListQuery  
GO  
  
-- v2016.05.18  
  
-- [年]연생산계획및실적-조회 by 이재천   
CREATE PROC KPXCM_SPDProdPlanResultListQuery  
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
            @UnitQty    DECIMAL(19,5) 

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit  , 0 ),  
           @StdYear    = ISNULL( StdYear   , '' ),  
           @QueryYM    = ISNULL( QueryYM   , '' ),  
           @UMUnitSeq  = ISNULL( UMUnitSeq , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT, 
            StdYear    NCHAR(4),       
            QueryYM    NCHAR(6),       
            UMUnitSeq  INT
           )     
    
    SELECT @UnitQty = CASE WHEN @UMUnitSeq = 1 THEN 1000 ELSE 1 END 
    
    CREATE TABLE #Result 
    (
        StdMonth        NVARCHAR(100), 
        StdMonthSub     NCHAR(6), 
        PlanSalesQty    DECIMAL(19,5), 
        PlanSelfQty     DECIMAL(19,5), 
        PlanSumQty      DECIMAL(19,5), 
        SalesQty        DECIMAL(19,5), 
        SelfQty         DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumRate         DECIMAL(19,5) 
    ) 
    
    INSERT INTO #Result ( StdMonth, StdMonthSub ) 
    SELECT '1월', @StdYear + '01'
    UNION ALL 
    SELECT '2월', @StdYear + '02'
    UNION ALL 
    SELECT '3월', @StdYear + '03'
    UNION ALL 
    SELECT '4월', @StdYear + '04'
    UNION ALL 
    SELECT '5월', @StdYear + '05'
    UNION ALL 
    SELECT '6월', @StdYear + '06'
    UNION ALL 
    SELECT '7월', @StdYear + '07'
    UNION ALL 
    SELECT '8월', @StdYear + '08'
    UNION ALL 
    SELECT '9월', @StdYear + '09'
    UNION ALL 
    SELECT '10월', @StdYear + '10'
    UNION ALL 
    SELECT '11월', @StdYear + '11'
    UNION ALL 
    SELECT '12월', @StdYear + '12'
    
    -- 제품,반제품 전체 담기 
    SELECT A.ItemSeq 
      INTO #TDAItem 
      FROM _TDAItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AssetSeq IN ( 18, 20 ) 
    
    ----------------------------------------------------------------------------------------------------
    -- 생산 계획 (월생산계획)
    ----------------------------------------------------------------------------------------------------    
    SELECT A.PlanYM, SUM(ISNULL(SalesPlanQty,0) / @UnitQty) AS PlanSalesQty, SUM(ISNULL(SelfQty,0) / @UnitQty) AS PlanSelfQty 
      INTO #KPXCM_TPDSFCMonthProdPlanStock
      FROM KPXCM_TPDSFCMonthProdPlanStock      AS A 
      JOIN KPXCM_TPDSFCMonthProdPlanStockItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq ) 
      JOIN #TDAItem                            AS C ON ( C.ItemSeq = B.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND LEFT(A.PlanYM,4) = @StdYear 
       AND A.PlanYM = A.PlanYMSub 
     GROUP BY A.PlanYM
    
    UPDATE A
       SET PlanSalesQty = B.PlanSalesQty, 
           PlanSelfQty = B.PlanSelfQty, 
           PlanSumQty = B.PlanSalesQty + B.PlanSelfQty
      FROM #Result                          AS A 
      JOIN #KPXCM_TPDSFCMonthProdPlanStock  AS B ON ( B.PlanYM = A.StdMonthSub ) 
    ----------------------------------------------------------------------------------------------------
    -- 생산 계획 (월생산계획), END 
    ----------------------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------------------
    -- 생산 실적 
    ----------------------------------------------------------------------------------------------------
    -- 생산수량 
    SELECT LEFT(A.WorkDate,6) AS WorkYM, SUM(ISNULL(A.StdUnitProdQty,0) / @UnitQty) AS ProdQty 
      INTO #TPDSFCWorkReport
      FROM _TPDSFCWorkReport    AS A 
      JOIN #TDAItem             AS B ON ( B.ItemSeq = A.GoodItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.GoodItemSeq = A.AssyItemSeq 
       AND LEFT(A.WorkDate,4) = @StdYear 
       AND LEFT(A.WorkDate,6) <= @QueryYM 
     GROUP BY LEFT(A.WorkDate,6) 
    
    UPDATE A
       SET SumQty = B.ProdQty 
      FROM #Result              AS A 
      JOIN #TPDSFCWorkReport    AS B ON ( B.WorkYM = A.StdMonthSub ) 
    
    -- 자소용 
    SELECT LEFT(A.InPutDate,6) AS InPutYM, SUM(ISNULL(A.StdUnitQty,0) / @UnitQty) AS MatQty 
      INTO #TPDSFCMatInput
      FROM _TPDSFCMatInput  AS A 
      JOIN #TDAItem         AS B ON ( B.ItemSeq = A.MatItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.InPutDate,4) = @StdYear 
       AND LEFT(A.InPutDate,6) <= @QueryYM 
     GROUP BY LEFT(A.InPutDate,6)
    
    UPDATE A
       SET SelfQty = B.MatQty, 
           SalesQty = A.SumQty - B.MatQty 
      FROM #Result          AS A 
      JOIN #TPDSFCMatInput  AS B ON ( B.InPutYM = A.StdMonthSub ) 
    ----------------------------------------------------------------------------------------------------
    -- 생산 실적, END 
    ----------------------------------------------------------------------------------------------------
    
    -- 판매용 계획대비 
    UPDATE A
       SET SumRate = CASE WHEN PlanSumQty = 0 THEN NULL ELSE (SumQty / PlanSumQty) * 100 END 
      FROM #Result AS A 
     WHERE PlanSumQty IS NOT NULL 
       AND SumQty IS NOT NULL 
    
    -- 합계 
    INSERT INTO #Result 
    (
        StdMonth     , StdMonthSub  , PlanSalesQty , PlanSelfQty  , PlanSumQty   , 
        SalesQty     , SelfQty      , SumQty       , SumRate      
    )
    SELECT '합계', 
           '999999', 
           SUM(PlanSalesQty) AS PlanSalesQty, 
           SUM(PlanSelfQty) AS PlanSelfQty, 
           SUM(PlanSumQty) AS PlanSumQty, 
           SUM(SalesQty) AS SalesQty, 
           SUM(SelfQty) AS SelfQty, 
           SUM(SumQty) AS SumQty, 
           CASE WHEN SUM(PlanSumQty) = 0 THEN NULL ELSE (SUM(SumQty) / SUM(PlanSumQty)) * 100 END AS SumRate 
      FROM #Result 
    
    -- 최종조회 
    SELECT *, 
           CASE WHEN @UMUnitSeq = 1 THEN 'M/T' ELSE 'M/KG' END AS UMUnitName, 
           @StdYear AS StdYear, 
           CASE WHEN RIGHT(StdMonthSub,2) <> '99' THEN '-1' 
                ELSE '-860708' 
           END AS Color
      FROM #Result 
     ORDER BY StdMonthSub 
    
    RETURN  
    GO
    begin tran 
    exec KPXCM_SPDProdPlanResultListQuery @xmlDocument=N'<ROOT>
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
    <UMUnitSeq>2</UMUnitSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037075,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030397
rollback 