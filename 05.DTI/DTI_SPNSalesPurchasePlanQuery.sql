
IF OBJECT_ID('DTI_SPNSalesPurchasePlanQuery') IS NOT NULL 
    DROP PROC DTI_SPNSalesPurchasePlanQuery
GO 

-- v2014.03.31 

-- [경영계획]판매구매계획입력_DTI(조회) by이재천
CREATE PROC DTI_SPNSalesPurchasePlanQuery
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS  
    
    DECLARE @docHandle      INT,
            @EmpSeq         INT ,
            @DeptSeq        INT ,
            @PlanType       INT ,
            @PlanKeySeq     INT ,
            @SMCostMng      INT ,
            @BizUnit        INT, 
            @PlanYear       NCHAR(4) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpSeq          = ISNULL(EmpSeq        ,0), 
           @DeptSeq        = ISNULL(DeptSeq       ,0), 
           @PlanType       = ISNULL(PlanType      ,0), 
           @PlanKeySeq     = ISNULL(PlanKeySeq    ,0), 
           @SMCostMng      = ISNULL(SMCostMng     ,0), 
           @BizUnit        = ISNULL(BizUnit       ,0), 
           @PlanYear       = ISNULL(PlanYear      ,'') 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
          
      WITH (
            EmpSeq        INT , 
            DeptSeq       INT , 
            PlanType      INT , 
            PlanKeySeq    INT , 
            SMCostMng     INT , 
            BizUnit       INT , 
            PlanYear      NCHAR(4) 
           ) 
    
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY (0,1), 
        Title       NVARCHAR(100), 
        TitleSeq    INT, 
        Title2      NVARCHAR(100), 
        TitleSeq2   INT
    
    )
    
    INSERT INTO #Title (Title, TitleSeq, Title2, TitleSeq2) 
    SELECT A.Title, A.TitleSeq, B.Title2, B.TitleSeq2 + A.TitleSeq
      FROM (SELECT @PlanYear + '-01' AS Title, 1 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-02' AS Title, 2 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-03' AS Title, 3 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-04' AS Title, 4 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-05' AS Title, 5 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-06' AS Title, 6 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-07' AS Title, 7 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-08' AS Title, 8 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-09' AS Title, 9 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-10' AS Title, 10 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-11' AS Title, 11 AS TitleSeq
            UNION ALL 
            SELECT @PlanYear + '-12' AS Title, 12 AS TitleSeq
          ) AS A 
      JOIN (SELECT '금액' AS Title2, 100 AS TitleSeq2) AS B ON ( 1 = 1 ) 
    
    SELECT * FROM #Title 
    
    CREATE TABLE #FixCol
    (
         RowIdx     INT IDENTITY(0, 1), 
         Serl       INT, 
         ItemName   NVARCHAR(100), 
         ItemNo     NVARCHAR(100), 
         Spec       NVARCHAR(100), 
         ItemSeq    INT, 
         AssetName  NVARCHAR(100), 
         AssetSeq   INT, 
         SumPlanAmt DECIMAL(19,5) 
    )
    INSERT INTO #FixCol (Serl, ItemName, ItemNo, Spec, ItemSeq, AssetName, AssetSeq, SumPlanAmt) 
    SELECT A.Serl, 
           MAX(B.ItemName) AS ItemName, 
           MAX(B.ItemNo) AS ItemNo, 
           MAX(B.Spec) AS Spec, 
           A.ItemSeq, 
           MAX(C.AssetName) AS AssetName, 
           MAX(B.AssetSeq) AS AssetSeq, 
           SUM(PlanAmt) AS SumPlanAmt
           
      FROM DTI_TPNSalesPurchasePlan     AS A 
      LEFT OUTER JOIN _TDAItem          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
      LEFT OUTER JOIN _TESMDCostKey     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CostKeySeq = A.CostKeySeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND D.PlanYear = @PlanYear 
       AND D.CostMngAmdSeq = @PlanKeySeq 
       AND A.EmpSeq = @EmpSeq 
       AND A.DeptSeq = @DeptSeq 
       AND D.SMCostMng = @SMCostMng 
       AND A.PlanType = @PlanType
     GROUP BY A.Serl, A.ItemSeq 
     ORDER BY Serl 
    
    SELECT * FROM #FixCol 
    
    CREATE TABLE #Value
    (
         Serl       INT, 
         TitleSeq   INT, 
         Value      DECIMAL(19,5) 
    )
    INSERT INTO #Value (Serl, TitleSeq, Value) 
    SELECT A.Serl, CONVERT(INT,RIGHT(B.CostYM,2)), A.PlanAmt
      FROM DTI_TPNSalesPurchasePlan AS A 
      JOIN _TESMDCostKey            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND B.PlanYear = @PlanYear 
       AND B.CostMngAmdSeq = @PlanKeySeq 
       AND A.EmpSeq = @EmpSeq 
       AND A.DeptSeq = @DeptSeq 
       AND B.SMCostMng = @SMCostMng 
       AND A.PlanType = @PlanType
    
    -- 가변최종조회
    SELECT B.RowIdx, A.ColIdx, C.Value AS Results
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 
      JOIN #FixCol AS B ON ( B.Serl = C.Serl ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN
GO
exec DTI_SPNSalesPurchasePlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanType>1</PlanType>
    <SMCostMng>5512002</SMCostMng>
    <PlanKeySeq>602</PlanKeySeq>
    <BizUnit>1</BizUnit>
    <PlanYear>2014</PlanYear>
    <EmpSeq>1000066</EmpSeq>
    <DeptSeq>1261</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021944,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018429