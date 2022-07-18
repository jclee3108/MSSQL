
IF OBJECT_ID('DTI_SPNSalesPurchasePlanListQuery') IS NOT NULL 
    DROP PROC DTI_SPNSalesPurchasePlanListQuery
GO 

-- v2014.03.31 

-- [경영계획]판매구매계획조회_DTI(조회) by이재천
CREATE PROC DTI_SPNSalesPurchasePlanListQuery 
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
            @DeptSeq    INT, 
            @PlanYear   NCHAR(4), 
            @AmtKind    INT, 
            @BizUnit    INT, 
            @PlanKeySeq INT, 
            @SMCostMng  INT, 
            @EmpSeq     INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @DeptSeq    = ISNULL(DeptSeq     ,0), 
           @PlanYear   = ISNULL(PlanYear    ,''), 
           @AmtKind    = ISNULL(AmtKind     ,0), 
           @BizUnit    = ISNULL(BizUnit     ,0), 
           @PlanKeySeq = ISNULL(PlanKeySeq  ,0), 
           @SMCostMng  = ISNULL(SMCostMng   ,0), 
           @EmpSeq     = ISNULL(EmpSeq      ,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (DeptSeq    INT, 
            PlanYear   NCHAR(4), 
            AmtKind    INT, 
            BizUnit    INT, 
            PlanKeySeq INT, 
            SMCostMng  INT, 
            EmpSeq     INT 
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
    
    CREATE TABLE #TEMP 
    (
        BizUnit     INT, 
        DeptSeq     INT, 
        EmpSeq      INT, 
        ItemSeq     INT, 
        AmtKind     INT, 
        PlanYM      NCHAR(6), 
        PlanAmt     DECIMAL(19,5), 
        Sort        INT 
    )
    INSERT INTO #TEMP(BizUnit, DeptSeq, EmpSeq, ItemSeq, AmtKind, PlanYM, PlanAmt, Sort)
    -- 매출액 
    SELECT A.BizUnit, A.DeptSeq, A.EmpSeq, A.ItemSeq, CASE WHEN PlanType = 1 THEN 1 ELSE 2 END, B.CostYM, A.PlanAmt, 1
      FROM DTI_TPNSalesPurchasePlan AS A 
      LEFT OUTER JOIN _TESMDCostKey  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
       AND (B.PlanYear = @PlanYear) 
       AND (B.SMCostMng = @SMCostMng) 
       AND (B.CostMngAmdSeq = @PlanKeySeq) 
    UNION ALL 
    -- GP 
    SELECT A.BizUnit, A.DeptSeq, A.EmpSeq, A.ItemSeq, 3, B.CostYM, SUM((CASE WHEN A.PlanType = 1 THEN A.PlanAmt ELSE 0 END) - (CASE WHEN A.PlanType = 2 THEN A.PlanAmt ELSE 0 END)), 1 
      FROM DTI_TPNSalesPurchasePlan AS A 
      LEFT OUTER JOIN _TESMDCostKey  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
       AND (B.PlanYear = @PlanYear) 
       AND (B.SMCostMng = @SMCostMng) 
       AND (B.CostMngAmdSeq = @PlanKeySeq) 
      GROUP BY A.BizUnit, A.DeptSeq, A.EmpSeq, A.ItemSeq, B.CostYM 
    -- 사내대체 
    UNION ALL 
    SELECT 0, A.DeptSeq, 0, 0, 4, A.PlanYM, A.Amt, 2
      FROM DTI_TPNSalesInterbilling AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND LEFT(A.PlanYM,4) = @PlanYear 
    
    CREATE TABLE #FixCol
    (
         RowIdx         INT IDENTITY(0, 1), 
         BizUnit        INT, 
         BizUnitName    NVARCHAR(100), 
         DeptName       NVARCHAR(100), 
         DeptSeq        INT, 
         EmpName        NVARCHAR(100), 
         EmpSeq         INT, 
         ItemName       NVARCHAR(100), 
         ItemNo         NVARCHAR(100), 
         Spec           NVARCHAR(100), 
         ItemSeq        INT, 
         AssetName      NVARCHAR(100), 
         AssetSeq       INT, 
         AmtKindName    NVARCHAR(100), 
         SumPlanAmt     DECIMAL(19,5), 
         Sort           INT, 
         AmtKind        INT 
    )
    
    INSERT INTO #FixCol (
                            BizUnit     ,BizUnitName ,DeptName    ,DeptSeq     ,EmpName     ,
                            EmpSeq      ,ItemName    ,ItemNo      ,Spec        ,ItemSeq     ,
                            AssetName   ,AssetSeq    ,AmtKindName ,SumPlanAmt  ,Sort        ,
                            AmtKind
                        ) 
    SELECT B.BizUnit, F.BizUnitName, B.DeptName, A.DeptSeq, C.EmpName, 
    
           A.EmpSeq, D.ItemName, D.ItemNo, CASE WHEN ISNULL(D.Spec,'') = '' THEN' 　'ELSE D.Spec END, A.ItemSeq, 
           
           E.AssetName, D.AssetSeq, 
           CASE WHEN A.AmtKind = 1 THEN '매출액' 
                WHEN A.AmtKind = 2 THEN '매출원가' 
                WHEN A.AmtKind = 3 THEN 'GP' 
                WHEN A.AmtKind = 4 THEN '사내대체' 
                ELSE '' 
                END, 
           SUM(PlanAmt), A.Sort, 
           
           A.AmtKind 
      FROM #TEMP                    AS A 
      LEFT OUTER JOIN _TDADept      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAItem      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.AssetSeq = D.AssetSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = A.BizUnit ) 
     WHERE (@AmtKind = 0 OR A.AmtKind = @AmtKind) 
     GROUP BY B.BizUnit, F.BizUnitName, B.DeptName, A.DeptSeq, C.EmpName, A.EmpSeq, D.ItemName,     
              D.ItemNo, D.Spec, A.ItemSeq, E.AssetName, D.AssetSeq, A.AmtKind, A.Sort
     ORDER BY F.BizUnitName, B.DeptName, A.Sort, C.EmpName, D.ItemName, D.ItemNo, D.Spec, E.AssetName, A.AmtKind 
      
    SELECT * FROM #FixCol
    
    CREATE TABLE #Value
    (
        TitleSeq    INT, 
        DeptSeq     INT, 
        AmtKind     INT, 
        ItemSeq     INT, 
        EmpSeq      INT, 
        PlanAmt     DECIMAL(19,5)
    )
    INSERT INTO #Value (TitleSeq, DeptSeq, AmtKind, ItemSeq, EmpSeq, PlanAmt)
    SELECT CONVERT(INT,RIGHT(A.PlanYM,2)), A.DeptSeq, A.AmtKind, A.ItemSeq, A.EmpSeq, A.PlanAmt
      FROM #TEMP AS A 
     WHERE (@AmtKind = 0 OR A.AmtKind = @AmtKind) 
    
    SELECT B.RowIdx, A.ColIdx, C.PlanAmt AS Results 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 
      JOIN #FixCol AS B ON ( B.DeptSeq = C.DeptSeq AND B.EmpSeq = C.EmpSeq AND B.AmtKind = C.AmtKind AND B.ItemSeq = C.ItemSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN
GO
exec DTI_SPNSalesPurchasePlanListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <AmtKind>1</AmtKind>
    <SMCostMng>5512002</SMCostMng>
    <PlanKeySeq>547</PlanKeySeq>
    <BizUnit>1</BizUnit>
    <PlanYear>2014</PlanYear>
    <EmpSeq />
    <DeptSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021959,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018444