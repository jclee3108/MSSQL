     
IF OBJECT_ID('mnpt_SACEEBgtAccPlanResultListQuery') IS NOT NULL       
    DROP PROC mnpt_SACEEBgtAccPlanResultListQuery      
GO      
      
-- v2018.03.26
      
-- 계정과목별예실조회-조회 by 이재천  
CREATE PROC mnpt_SACEEBgtAccPlanResultListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @StdYM          NCHAR(6), 
            @BgtSeq         INT, 
            @AccUnit        INT, 
            @DeptCCtrSeq    INT, 
            @AmtUnit        DECIMAL(19,5), 
            @AccSeq         INT, 
            @DeptSeq        INT, 
            @CCtrSeq        INT, 
            @EnvValue       INT -- 환경설정  
      
    SELECT @StdYM       = ISNULL( StdYM, '' ),   
           @BgtSeq      = ISNULL( BgtSeq , 0 ), 
           @AccUnit     = ISNULL( AccUnit, 0 ), 
           @DeptCCtrSeq = ISNULL( DeptCCtrSeq, 0 ), 
           @AmtUnit     = ISNULL( AmtUnit, 0 ), 
           @AccSeq      = ISNULL( AccSeq, 0 ) 
      FROM #BIZ_IN_DataBlock1    
    
    SELECT @EnvValue = EnvValue  
      FROM _TCOMEnv WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 4008  
    SELECT @DeptSeq = CASE WHEN @EnvValue = 4013001 THEN @DeptCCtrSeq ELSE 0 END,  
           @CCtrSeq = CASE WHEN @EnvValue = 4013002 THEN @DeptCCtrSeq ELSE 0 END
    
    ------------------------------------------------------------------
    -- 예산 계획 
    ------------------------------------------------------------------

    SELECT D.AccSeq, 
           C.BgtSeq, 
           D.UMCostType, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '01' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month01, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '02' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month02, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '03' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month03, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '04' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month04, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '05' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month05, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '06' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month06, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '07' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month07, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '08' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month08, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '09' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month09, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '10' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month10, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '11' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month11, 
           SUM(CASE WHEN RIGHT(D.BgtYM,2) = '12' THEN (CASE WHEN D.SMBgtChangeKind = 4137001 THEN ISNULL(D.BgtAmt,0) ELSE (-1) * ISNULL(D.BgtAmt,0) END) ELSE 0 END) AS Month12
      INTO #Changed
      FROM mnpt_TACBgt                  AS D 
      JOIN _TACBgtClosing   AS B ON ( B.CompanySeq = @CompanySeq AND LEFT(D.BgtYM,4) = B.BgtYear AND D.AccUnit = B.AccUnit ) 
      JOIN (
          SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
              WHERE CompanySeq = @CompanySeq
              GROUP BY AccSeq 
          ) AS C ON ( D.AccSeq = C.AccSeq )  
     WHERE D.CompanySeq = @CompanySeq
       AND LEFT(D.BgtYM,4) = LEFT(@StdYM,4)
       AND B.IsCfm = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR D.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR D.DeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR D.CCtrSeq = @CCtrSeq ) 
       AND ( @AccSeq = 0 OR D.AccSeq = @AccSeq ) 
     GROUP BY D.AccSeq, C.BgtSeq, D.UMCostType 
    

    SELECT A.AccSeq, 
           C.BgtSeq, 
           A.UMCostType, 
           MAX(A.Month01) AS StdMonth01, 
           MAX(A.Month02) AS StdMonth02, 
           MAX(A.Month03) AS StdMonth03, 
           MAX(A.Month04) AS StdMonth04, 
           MAX(A.Month05) AS StdMonth05, 
           MAX(A.Month06) AS StdMonth06, 
           MAX(A.Month07) AS StdMonth07, 
           MAX(A.Month08) AS StdMonth08, 
           MAX(A.Month09) AS StdMonth09, 
           MAX(A.Month10) AS StdMonth10, 
           MAX(A.Month11) AS StdMonth11, 
           MAX(A.Month12) AS StdMonth12, 
           MAX(A.Month01) AS Month01, 
           MAX(A.Month02) AS Month02, 
           MAX(A.Month03) AS Month03, 
           MAX(A.Month04) AS Month04, 
           MAX(A.Month05) AS Month05, 
           MAX(A.Month06) AS Month06, 
           MAX(A.Month07) AS Month07, 
           MAX(A.Month08) AS Month08, 
           MAX(A.Month09) AS Month09, 
           MAX(A.Month10) AS Month10, 
           MAX(A.Month11) AS Month11, 
           MAX(A.Month12) AS Month12

      INTO #AccBgtPlanAmt_Sub
      FROM mnpt_TACEEBgtAdj AS A 
      JOIN _TACBgtClosing   AS B ON ( B.CompanySeq = @CompanySeq AND A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit ) 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
      --LEFT OUTER JOIN mnpt_TACBgt   AS D ON ( D.CompanySeq = @CompanySeq 
      --                                    AND LEFT(D.BgtYM,4) = A.StdYear
      --                                    AND D.AccUnit = A.AccUnit 
      --                                    AND D.DeptSeq = A.DeptSeq 
      --                                    AND D.CCtrSeq = A.CCtrSeq 
      --                                    AND D.AccSeq = A.AccSeq 
      --                                    AND D.UMCostType = A.UMCostType 
      --                                      ) 
     WHERE A.StdYear = LEFT(@StdYM,4)  
       AND B.IsCfm = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq ) 
       AND ( @AccSeq = 0 OR A.AccSeq = @AccSeq ) 
     GROUP BY A.AccSeq, C.BgtSeq, A.UMCostType 
    
    UNION ALL 

    SELECT A.AccSeq, 
           A.BgtSeq, 
           A.UMCostType, 
           0 AS StdMonth01, 
           0 AS StdMonth02, 
           0 AS StdMonth03, 
           0 AS StdMonth04, 
           0 AS StdMonth05, 
           0 AS StdMonth06, 
           0 AS StdMonth07, 
           0 AS StdMonth08, 
           0 AS StdMonth09, 
           0 AS StdMonth10, 
           0 AS StdMonth11, 
           0 AS StdMonth12, 
           Month01,
           Month02,
           Month03,
           Month04,
           Month05,
           Month06,
           Month07,
           Month08,
           Month09,
           Month10,
           Month11,
           Month12
      FROM #Changed AS A 
    
    select A.AccSeq, 
           A.BgtSeq, 
           A.UMCostType, 
           SUM(A.StdMonth01) AS StdMonth01, 
           SUM(A.StdMonth02) AS StdMonth02, 
           SUM(A.StdMonth03) AS StdMonth03, 
           SUM(A.StdMonth04) AS StdMonth04, 
           SUM(A.StdMonth05) AS StdMonth05, 
           SUM(A.StdMonth06) AS StdMonth06, 
           SUM(A.StdMonth07) AS StdMonth07, 
           SUM(A.StdMonth08) AS StdMonth08, 
           SUM(A.StdMonth09) AS StdMonth09, 
           SUM(A.StdMonth10) AS StdMonth10, 
           SUM(A.StdMonth11) AS StdMonth11, 
           SUM(A.StdMonth12) AS StdMonth12, 
           SUM(A.Month01) AS Month01,
           SUM(A.Month02) AS Month02,
           SUM(A.Month03) AS Month03,
           SUM(A.Month04) AS Month04,
           SUM(A.Month05) AS Month05,
           SUM(A.Month06) AS Month06,
           SUM(A.Month07) AS Month07,
           SUM(A.Month08) AS Month08,
           SUM(A.Month09) AS Month09,
           SUM(A.Month10) AS Month10,
           SUM(A.Month11) AS Month11,
           SUM(A.Month12) AS Month12
      INTO #AccBgtPlanAmt
      from #AccBgtPlanAmt_Sub AS A 
     GROUP BY A.AccSeq, A.BgtSeq, A.UMCostType
    
    SELECT A.AccSeq, 
           A.BgtSeq, 
           A.UMCostType, 
           SUM( 
               CASE WHEN RIGHT(@StdYM,2) = '01' THEN ISNULL(A.StdMonth01,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '02' THEN ISNULL(A.StdMonth02,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '03' THEN ISNULL(A.StdMonth03,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '04' THEN ISNULL(A.StdMonth04,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '05' THEN ISNULL(A.StdMonth05,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '06' THEN ISNULL(A.StdMonth06,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '07' THEN ISNULL(A.StdMonth07,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '08' THEN ISNULL(A.StdMonth08,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '09' THEN ISNULL(A.StdMonth09,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '10' THEN ISNULL(A.StdMonth10,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '11' THEN ISNULL(A.StdMonth11,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '12' THEN ISNULL(A.StdMonth12,0) ELSE 0 END 
               ) AS StdMonthPlan, 
           SUM( 
               CASE WHEN RIGHT(@StdYM,2) = '01' THEN ISNULL(A.Month01,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '02' THEN ISNULL(A.Month02,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '03' THEN ISNULL(A.Month03,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '04' THEN ISNULL(A.Month04,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '05' THEN ISNULL(A.Month05,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '06' THEN ISNULL(A.Month06,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '07' THEN ISNULL(A.Month07,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '08' THEN ISNULL(A.Month08,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '09' THEN ISNULL(A.Month09,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '10' THEN ISNULL(A.Month10,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '11' THEN ISNULL(A.Month11,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) = '12' THEN ISNULL(A.Month12,0) ELSE 0 END 
               ) AS MonthPlan, 
          SUM ( 
               CASE WHEN RIGHT(@StdYM,2) >= '01' THEN ISNULL(A.Month01,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '02' THEN ISNULL(A.Month02,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '03' THEN ISNULL(A.Month03,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '04' THEN ISNULL(A.Month04,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '05' THEN ISNULL(A.Month05,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '06' THEN ISNULL(A.Month06,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '07' THEN ISNULL(A.Month07,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '08' THEN ISNULL(A.Month08,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '09' THEN ISNULL(A.Month09,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '10' THEN ISNULL(A.Month10,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '11' THEN ISNULL(A.Month11,0) ELSE 0 END +  
               CASE WHEN RIGHT(@StdYM,2) >= '12' THEN ISNULL(A.Month12,0) ELSE 0 END 
              ) AS SumPlan, 
           SUM( 
               ISNULL(A.Month01,0) + ISNULL(A.Month02,0) + ISNULL(A.Month03,0) + ISNULL(A.Month04,0) + 
               ISNULL(A.Month05,0) + ISNULL(A.Month06,0) + ISNULL(A.Month07,0) + ISNULL(A.Month08,0) + 
               ISNULL(A.Month09,0) + ISNULL(A.Month10,0) + ISNULL(A.Month11,0) + ISNULL(A.Month12,0) 
              ) AS YearPlan 
      INTO #Plan_Query
      FROM #AccBgtPlanAmt AS A 
     GROUP BY A.AccSeq, A.BgtSeq, A.UMCostType
    ------------------------------------------------------------------
    -- 예산 계획, End 
    ------------------------------------------------------------------
    
    ------------------------------------------------------------------
    -- 예산 실적 
    ------------------------------------------------------------------
    SELECT LEFT(A.AccDate,6) AccYM, 
           A.AccSeq, 
           C.BgtSeq, 
           A.UMCostType, 
           SUM(A.DrAmt + A.CrAmt) AS ResultAmt
      INTO #AccBgtResultAmt 
      FROM _TACSlipRow AS A 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
     WHERE CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,4) = LEFT(@StdYM,4) 
       AND (BgtDeptSeq <> 0 OR BgtCCtrSeq <> 0 )
       AND A.IsSet = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.BgtDeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.BgtCCtrSeq = @CCtrSeq ) 
       AND ( @AccSeq = 0 OR A.AccSeq = @AccSeq ) 
     GROUP BY LEFT(A.AccDate,6), A.AccSeq, C.BgtSeq, A.UMCostType
    
    
    SELECT A.AccSeq, 
           A.BgtSeq, 
           A.UMCostType, 
           SUM(CASE WHEN RIGHT(A.AccYM,2) = RIGHT(@StdYM,2) THEN ISNULL(A.ResultAmt,0) ELSE 0 END) AS MonthResult, 
           SUM(CASE WHEN RIGHT(A.AccYM,2) <= RIGHT(@StdYM,2) THEN ISNULL(A.ResultAmt,0) ELSE 0 END) AS SumResult, 
           SUM(ISNULL(A.ResultAmt,0)) AS YearResult
      INTO #Result_Query
      FROM #AccBgtResultAmt AS A 
     GROUP BY A.AccSeq, A.BgtSeq, A.UMCostType 
    ------------------------------------------------------------------
    -- 예산 실적, End 
    ------------------------------------------------------------------
    
    ------------------------------------------------------------------
    -- 예산 계획 & 실적 
    ------------------------------------------------------------------
    SELECT A.AccSeq, A.BgtSeq, A.UMCostType, 
           B.StdMonthPlan, B.MonthPlan, C.MonthResult, B.SumPlan, C.SumResult, B.YearPlan, C.YearResult 
      INTO #PlanResultAmt
      FROM ( 
            SELECT AccSeq, BgtSeq, UMCostType
              FROM #Plan_Query
            UNION 
            SELECT AccSeq, BgtSeq, UMCostType
              FROM #Result_Query 
           ) AS A 
      LEFT OUTER JOIN #Plan_Query   AS B ON ( B.AccSeq = A.AccSeq 
                                          AND B.BgtSeq = A.BgtSeq 
                                          AND B.UMCostType = A.UMCostType
                                            )  
      LEFT OUTER JOIN #Result_Query AS C ON ( C.AccSeq = A.AccSeq 
                                          AND C.BgtSeq = A.BgtSeq 
                                          AND C.UMCostType = A.UMCostType
                                            ) 
    ------------------------------------------------------------------
    -- 예산 계획 & 실적, End 
    ------------------------------------------------------------------
    
    ------------------------------------------------------------------
    -- 예산 계획 & 실적 합계추가
    ------------------------------------------------------------------
    -- 예산과목 집계
    SELECT BgtSeq, 
           0 AS AccSeq, 
           0 AS UMCostType, 
           SUM(ISNULL(A.StdMonthPlan,0)) AS StdMonthPlan,
           SUM(ISNULL(A.MonthPlan,0)) AS MonthPlan, 
           SUM(ISNULL(A.MonthResult,0)) AS MonthResult, 
           SUM(ISNULL(A.SumPlan,0)) AS SumPlan, 
           SUM(ISNULL(A.SumResult,0)) AS SumResult, 
           SUM(ISNULL(A.YearPlan,0)) AS YearPlan, 
           SUM(ISNULL(A.YearResult,0)) AS YearResult, 
           1 AS Sort
      INTO #Result   
      FROM #PlanResultAmt AS A 
     GROUP BY BgtSeq
    UNION ALL -- 계정과목 집계 
    SELECT BgtSeq, 
           AccSeq, 
           UMCostType, 
           ISNULL(A.StdMonthPlan,0) AS StdMonthPlan,
           ISNULL(A.MonthPlan,0) AS MonthPlan, 
           ISNULL(A.MonthResult,0) AS MonthResult, 
           ISNULL(A.SumPlan,0) AS SumPlan, 
           ISNULL(A.SumResult,0) AS SumResult, 
           ISNULL(A.YearPlan,0) AS YearPlan, 
           ISNULL(A.YearResult,0) AS YearResult, 
           2 AS Sort 
      FROM #PlanResultAmt AS A 
    --UNION ALL -- 합계
    
    IF EXISTS (SELECT 1 FROM #PlanResultAmt) 
    BEGIN 
        -- 합계 
        INSERT INTO #Result 
        SELECT 
               99999999 AS BgtSeq, 
               99999999 AS AccSeq, 
               99999999 AS UMCostType, 
               SUM(ISNULL(A.StdMonthPlan,0)) AS StdMonthPlan,
               SUM(ISNULL(A.MonthPlan,0)) AS MonthPlan, 
               SUM(ISNULL(A.MonthResult,0)) AS MonthResult, 
               SUM(ISNULL(A.SumPlan,0)) AS SumPlan, 
               SUM(ISNULL(A.SumResult,0)) AS SumResult, 
               SUM(ISNULL(A.YearPlan,0)) AS YearPlan, 
               SUM(ISNULL(A.YearResult,0)) AS YearResult, 
               3 AS Sort 
          FROM #PlanResultAmt AS A 
    END 
    ------------------------------------------------------------------
    -- 예산 계획 & 실적 합계추가, End 
    ------------------------------------------------------------------
    
    SELECT CASE WHEN A.AccSeq = 0 THEN C.BgtName 
                WHEN A.AccSeq = 99999999 THEN '합계'
                ELSE B.AccName END AS AccBgtName, 
           CASE WHEN A.Sort = 2 THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMCostType) 
                ELSE '' END AS UMCostTypeName, 
           NULLIF(A.StdMonthPlan,0) AS StdMonthPlan, 
           NULLIF(A.MonthPlan,0) AS MonthPlan, 
           NULLIF(A.MonthResult,0) AS MonthResult, 
           NULLIF(A.SumPlan,0) AS SumPlan, 
           NULLIF(A.SumResult,0) AS SumResult, 
           NULLIF(A.YearPlan,0) AS YearPlan, 
           NULLIF(A.YearResult,0) AS YearResult, 
           A.Sort, 
           A.BgtSeq 
      FROM #Result AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACBgtItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.BgtSeq = A.BgtSeq ) 
     ORDER BY BgtSeq, Sort
    RETURN
    go


    begin tran 


    DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
IF @CONST_#BIZ_IN_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , StdYM CHAR(6), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrSeq INT, BgtSeq INT, AccSeq INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock1 = 1

END

IF @CONST_#BIZ_OUT_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , StdYM CHAR(6), AccUnitName NVARCHAR(200), DeptCCtrName NVARCHAR(200), AmtUnit DECIMAL(19, 5), BgtName NVARCHAR(200), AccName NVARCHAR(200), AccUnit INT, DeptCCtrSeq INT, BgtSeq INT, AccSeq INT, AccBgtName NVARCHAR(200), AccBgtSeq INT, MonthPlan DECIMAL(19, 5), MonthResult DECIMAL(19, 5), SumPlan DECIMAL(19, 5), SumResult DECIMAL(19, 5), YearPlan DECIMAL(19, 5), YearResult DECIMAL(19, 5), Sort INT, UMCostTypeName NVARCHAR(200), StdMonthPlan DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYM, AmtUnit, AccUnit, DeptCCtrSeq, BgtSeq, AccSeq) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'201802', N'1', N'3', N'742', N'', N'1296'
IF @@ERROR <> 0 RETURN


DECLARE @HasError           NCHAR(1)
        , @UseTransaction   NCHAR(1)
        -- 내부 SP용 파라메터
        , @ServiceSeq       INT
        , @MethodSeq        INT
        , @WorkingTag       NVARCHAR(10)
        , @CompanySeq       INT
        , @LanguageSeq      INT
        , @UserSeq          INT
        , @PgmSeq           INT
        , @IsTransaction    BIT

SET @HasError = N'0'
SET @UseTransaction = N'0'

BEGIN TRY

SET @ServiceSeq     = 13820134
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820121
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAccPlanResultListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:
END TRY
BEGIN CATCH
-- SQL 오류인 경우는 여기서 처리가 된다
    IF @UseTransaction = N'1'
        ROLLBACK TRAN
    
    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
            , @ERROR_SEVERITY   INT
            , @ERROR_STATE      INT
            , @ERROR_PROCEDURE  NVARCHAR(128)

    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
            , @ERROR_STATE      = ERROR_STATE() 
            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

    RETURN
END CATCH

-- SQL 오류를 제외한 체크로직으로 발생된 오류는 여기서 처리
IF @HasError = N'1' AND @UseTransaction = N'1'
    ROLLBACK TRAN
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 