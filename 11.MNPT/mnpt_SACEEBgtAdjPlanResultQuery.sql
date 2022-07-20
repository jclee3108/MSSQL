     
IF OBJECT_ID('mnpt_SACEEBgtAdjPlanResultQuery') IS NOT NULL       
    DROP PROC mnpt_SACEEBgtAdjPlanResultQuery      
GO      
      
-- v2018.01.08
      
-- 경비예산실적현황-조회 by 이재천  
CREATE PROC mnpt_SACEEBgtAdjPlanResultQuery      
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
            @DeptSeq        INT, 
            @CCtrSeq        INT, 
            @EnvValue       INT -- 환경설정  
      
    SELECT @StdYM       = ISNULL( StdYM, '' ),   
           @BgtSeq      = ISNULL( BgtSeq , 0 ), 
           @AccUnit     = ISNULL( AccUnit, 0 ), 
           @DeptCCtrSeq = ISNULL( DeptCCtrSeq, 0 ), 
           @AmtUnit     = ISNULL( AmtUnit, 0 )
      FROM #BIZ_IN_DataBlock1    
    

    SELECT @EnvValue = EnvValue  
      FROM _TCOMEnv WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 4008  

    SELECT @DeptSeq = CASE WHEN @EnvValue = 4013001 THEN @DeptCCtrSeq ELSE 0 END,  
           @CCtrSeq = CASE WHEN @EnvValue = 4013002 THEN @DeptCCtrSeq ELSE 0 END
    
    --select RIGHT(@StdYM,2)
    --return 
    ------------------------------------------------------------------
    -- 예산 계획 
    ------------------------------------------------------------------
    SELECT A.AccSeq, 
           C.BgtSeq, 
           A.DeptSeq, 
           A.CCtrSeq, 
           CASE WHEN RIGHT(@StdYM,2) >= '01' THEN A.Month01 ELSE 0 END AS Month01, 
           CASE WHEN RIGHT(@StdYM,2) >= '02' THEN A.Month02 ELSE 0 END AS Month02, 
           CASE WHEN RIGHT(@StdYM,2) >= '03' THEN A.Month03 ELSE 0 END AS Month03, 
           CASE WHEN RIGHT(@StdYM,2) >= '04' THEN A.Month04 ELSE 0 END AS Month04, 
           CASE WHEN RIGHT(@StdYM,2) >= '05' THEN A.Month05 ELSE 0 END AS Month05, 
           CASE WHEN RIGHT(@StdYM,2) >= '06' THEN A.Month06 ELSE 0 END AS Month06, 
           CASE WHEN RIGHT(@StdYM,2) >= '07' THEN A.Month07 ELSE 0 END AS Month07, 
           CASE WHEN RIGHT(@StdYM,2) >= '08' THEN A.Month08 ELSE 0 END AS Month08, 
           CASE WHEN RIGHT(@StdYM,2) >= '09' THEN A.Month09 ELSE 0 END AS Month09, 
           CASE WHEN RIGHT(@StdYM,2) >= '10' THEN A.Month10 ELSE 0 END AS Month10, 
           CASE WHEN RIGHT(@StdYM,2) >= '11' THEN A.Month11 ELSE 0 END AS Month11, 
           CASE WHEN RIGHT(@StdYM,2) >= '12' THEN A.Month12 ELSE 0 END AS Month12
      INTO #AccBgtPlanAmt 
      FROM mnpt_TACEEBgtAdj AS A 
      JOIN _TACBgtClosing   AS B ON ( B.CompanySeq = @CompanySeq AND A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit ) 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
      
     WHERE A.StdYear = LEFT(@StdYM,4)  
       AND B.IsCfm = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq ) 
     --GROUP BY A.AccSeq, C.BgtSeq 
    
    --select * from #AccBgtPlanAmt 
    --return 
    
    
    -- 예산과목 집계
    SELECT BgtSeq, 
           0 AS AccSeq, 
           A.DeptSeq, 
           A.CCtrSeq, 
           SUM(A.Month01) AS Month01, SUM(A.Month02) AS Month02, SUM(A.Month03) AS Month03, SUM(A.Month04) AS Month04, SUM(A.Month05) AS Month05, 
           SUM(A.Month06) AS Month06, SUM(A.Month07) AS Month07, SUM(A.Month08) AS Month08, SUM(A.Month09) AS Month09, SUM(A.Month10) AS Month10, 
           SUM(A.Month11) AS Month11, SUM(A.Month12) AS Month12, 
           1 AS Sort 
      INTO #PlanAmt 
      FROM #AccBgtPlanAmt AS A 
     GROUP BY BgtSeq, DeptSeq, CCtrSeq 
    UNION ALL -- 계정과목 집계 
    SELECT BgtSeq, 
           AccSeq, 
           DeptSeq, 
           CCtrSeq, 
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
           Month12,
           2 AS Sort 
      FROM #AccBgtPlanAmt AS A 
    UNION ALL -- 합계
    SELECT 99999999, 
           99999999 AS AccSeq, 
           DeptSeq, 
           CCtrSeq , 
           SUM(A.Month01) AS Month01, SUM(A.Month02) AS Month02, SUM(A.Month03) AS Month03, SUM(A.Month04) AS Month04, SUM(A.Month05) AS Month05, 
           SUM(A.Month06) AS Month06, SUM(A.Month07) AS Month07, SUM(A.Month08) AS Month08, SUM(A.Month09) AS Month09, SUM(A.Month10) AS Month10, 
           SUM(A.Month11) AS Month11, SUM(A.Month12) AS Month12, 
           3 AS Sort 
      FROM #AccBgtPlanAmt AS A 
     GROUP BY DeptSeq, CCtrSeq 

    ------------------------------------------------------------------
    -- 예산 계획, End 
    ------------------------------------------------------------------
    --select * From #PlanAmt 
    --return 
    ------------------------------------------------------------------
    -- 예산 실적 
    ------------------------------------------------------------------
    SELECT LEFT(A.AccDate,6) AccYM, 
           A.AccSeq, 
           C.BgtSeq, 
           A.BgtDeptSeq, 
           A.BgtCCtrSeq, 
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
       AND LEFT(A.AccDate,6) BETWEEN LEFT(@StdYM,4) + '01' AND @StdYM

       AND (BgtDeptSeq <> 0 OR BgtCCtrSeq <> 0 )
       AND A.IsSet = '1' 

       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.BgtDeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.BgtCCtrSeq = @CCtrSeq ) 
     GROUP BY LEFT(A.AccDate,6), A.AccSeq, C.BgtSeq, A.BgtDeptSeq, A.BgtCCtrSeq


    -- 예산과목 집계
    SELECT AccYM,
           BgtSeq, 
           0 AS AccSeq, 
           BgtDeptSeq AS DeptSeq, 
           BgtCCtrSeq AS CCtrSeq, 
           SUM(ResultAmt) AS ResultAmt,
           1 AS Sort 
      INTO #ResultAmt 
      FROM #AccBgtResultAmt AS A 
     GROUP BY AccYM, BgtSeq, BgtDeptSeq, BgtCCtrSeq
    UNION ALL -- 계정과목 집계 
    SELECT AccYM, 
           BgtSeq, 
           AccSeq, 
           BgtDeptSeq AS DeptSeq, 
           BgtCCtrSeq AS CCtrSeq, 
           ResultAmt, 
           2 AS Sort 
      FROM #AccBgtResultAmt AS A 
    UNION ALL -- 합계
    SELECT AccYM,
           99999999, 
           99999999 AS AccSeq, 
           BgtDeptSeq AS DeptSeq, 
           BgtCCtrSeq AS CCtrSeq, 
           SUM(ResultAmt) AS ResultAmt,
           3 AS Sort 
      FROM #AccBgtResultAmt AS A 
     GROUP BY AccYM, BgtDeptSeq, BgtCCtrSeq
    ------------------------------------------------------------------
    -- 예산 실적, End 
    ------------------------------------------------------------------
    --select * from #PlanAmt
    --select * from #ResultAmt
    --return 
    
    CREATE TABLE #Result 
    (
        StdYM       NCHAR(6), 
        AccSeq      INT, 
        BgtSeq      INT, 
        PlanAmt     DECIMAL(19,5), 
        ResultAmt   DECIMAL(19,5), 
        AccBgtSeq   INT, 
        DeptSeq     INT, 
        CCtrSeq     INT, 
        Sort        INT 
    ) 

    INSERT INTO #Result ( StdYM, AccSeq, BgtSeq, Sort, DeptSeq, CCtrSeq, ResultAmt, PlanAmt ) 
    SELECT StdYM, AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 0, PlanAmt 
      FROM ( 
            SELECT LEFT(@StdYM,4) + '01' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month01 AS PlanAmt
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '02' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month02
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '03' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month03
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '04' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month04
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '05' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month05
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '06' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month06
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '07' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month07
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '08' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month08
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '09' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month09
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '10' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month10
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '11' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month11
              FROM #PlanAmt 
            UNION ALL 
            SELECT LEFT(@StdYM,4) + '12' AS StdYM, 
                   AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, 
                   Month12
              FROM #PlanAmt 
           ) AS A 

    UNION ALL 
    SELECT AccYM, AccSeq , BgtSeq, Sort, DeptSeq, CCtrSeq, ResultAmt, 0
      FROM #ResultAmt 
     ORDER BY BgtSeq, Sort, AccSeq, DeptSeq, CCtrSeq 
    
    --select @StdYM

    SELECT AccSeq, 
           BgtSeq, 
           CASE WHEN AccSeq = 0 THEN BgtSeq ELSE AccSeq END AS BgtAccSeq, 
           DeptSeq, 
           CCtrSeq, 
           Sort, 
           SUM(PlanAmt) / NULLIF(@AmtUnit,0) AS PlanAmt, 
           SUM(ResultAmt) / NULLIF(@AmtUnit,0) AS ResultAmt
      INTO #BaseData
      FROM #Result 
     GROUP BY AccSeq, BgtSeq, AccBgtSeq, DeptSeq, CCtrSeq, Sort
    
    --select * from #BaseData 
    
    
    ------------------------------------------------------------------
    -- Title 
    ------------------------------------------------------------------
    CREATE TABLE #Title	
    (	
        ColIdx      INT IDENTITY(0, 1), 	
        TitleName   NVARCHAR(100), 	
        TitleSeq    INT, 
        TitleName2  NVARCHAR(100), 	
        TitleSeq2   INT
    )	
    INSERT INTO #Title (TitleName, TitleSeq, TitleName2, TitleSeq2) 
    SELECT A.TitleName, A.TitleSeq, B.TitleName2, B.TitleSeq2
      FROM ( SELECT CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(@StdYM,2))) + '월 계획' AS TitleName, 1 AS TitleSeq
             UNION ALL 
             SELECT CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(@StdYM,2))) + '월 실적' AS TitleName, 2 AS TitleSeq
             UNION ALL 
             SELECT '증감' AS TitleName, 3 AS TitleSeq
            ) AS A 
      JOIN ( 
            SELECT DISTINCT 
                   CASE WHEN A.DeptSeq <> 0 THEN B.DeptName ELSE C.CCtrName END TitleName2, 
                   CASE WHEN A.DeptSeq <> 0 THEN A.DeptSeq ELSE A.CCtrSeq END TitleSeq2, 
                   1 AS Sort
              FROM #BaseData AS A 
              LEFT OUTER JOIN _TDADept AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
              LEFT OUTER JOIN _TDACCtr AS C ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.CCtrSeq ) 
            UNION ALL 
            SELECT '합계' AS TitleName2, 99999999 AS TitleSeq2, 2 AS Sort
           ) AS B ON ( 1 = 1 ) 
     ORDER BY TitleSeq, Sort, TitleName2
    
    SELECT * FROM #Title 
    ------------------------------------------------------------------
    -- Fix
    ------------------------------------------------------------------
    CREATE TABLE #FixCol	
    (	
        RowIdx     INT IDENTITY(0, 1), 	
        AccBgtName NVARCHAR(100), 	
        BgtAccSeq  INT, 
        BgtSeq     INT, 
        Sort       INT 
    )	
    INSERT INTO #FixCol ( AccBgtName, BgtAccSeq, BgtSeq, Sort ) 
    SELECT DISTINCT 
           --CASE WHEN A.AccSeq = 0 THEN C.BgtName ELSE B.AccName END AS AccBgtName, 
           CASE WHEN A.AccSeq = 0 THEN C.BgtName 
                WHEN A.AccSeq = 99999999 THEN '합계'
                ELSE B.AccName END AS AccBgtName, 
           A.BgtAccSeq, 
           A.BgtSeq, 
           A.Sort 
      FROM #BaseData                AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACBgtItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.BgtSeq = A.BgtSeq ) 
     ORDER BY BgtSeq, Sort
    
    SELECT * FROM #FixCol 
    ------------------------------------------------------------------
    -- Value 
    ------------------------------------------------------------------
    CREATE TABLE #Value	
    (	
        Amt         DECIMAL(19, 5), 	
        BgtAccSeq   INT, 	
        TitleSeq    INT, 
        TitleSeq2   INT
    )	
    INSERT INTO #Value ( Amt, BgtAccSeq, TitleSeq, TitleSeq2 ) 
    SELECT PlanAmt, BgtAccSeq, 1 AS TitleSeq, CASE WHEN DeptSeq <> 0 THEN DeptSeq ELSE CCtrSeq END AS TitleSeq2
      FROM #BaseData
    UNION ALL 
    SELECT SUM(PlanAmt), BgtAccSeq, 1 AS TitleSeq, 99999999 AS TitleSeq2
      FROM #BaseData
     GROUP BY BgtAccSeq
    UNION ALL 
    SELECT ResultAmt, BgtAccSeq, 2 AS TitleSeq, CASE WHEN DeptSeq <> 0 THEN DeptSeq ELSE CCtrSeq END AS TitleSeq2
      FROM #BaseData
    UNION ALL 
    SELECT SUM(ResultAmt), BgtAccSeq, 2 AS TitleSeq, 99999999 AS TitleSeq2
      FROM #BaseData
     GROUP BY BgtAccSeq
    UNION ALL 
    SELECT ResultAmt - PlanAmt, BgtAccSeq, 3 AS TitleSeq, CASE WHEN DeptSeq <> 0 THEN DeptSeq ELSE CCtrSeq END AS TitleSeq2
      FROM #BaseData
    UNION ALL 
    SELECT SUM(ResultAmt) - SUM(PlanAmt), BgtAccSeq, 3 AS TitleSeq, 99999999 AS TitleSeq2
      FROM #BaseData
     GROUP BY BgtAccSeq



    SELECT B.RowIdx, A.ColIdx, C.Amt AS Value		
      FROM #Value AS C		
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq AND A.TitleSeq2 = C.TitleSeq2 ) 		
      JOIN #FixCol AS B ON ( B.BgtAccSeq = C.BgtAccSeq ) 		
     ORDER BY A.ColIdx, B.RowIdx		


    --return 

    RETURN     
go


begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_IN_DataBlock4 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock4 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_IN_DataBlock4 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock4 = 0
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

        , StdYM CHAR(6), BgtName NVARCHAR(200), AccUnitName NVARCHAR(200), DeptCCtrName NVARCHAR(200), AmtUnit DECIMAL(19, 5), BgtSeq INT, AccUnit INT, DeptCCtrSeq INT
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

        , StdYM CHAR(6), BgtName NVARCHAR(200), AccUnitName NVARCHAR(200), DeptCCtrName NVARCHAR(200), AmtUnit DECIMAL(19, 5), BgtSeq INT, AccUnit INT, DeptCCtrSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END

IF @CONST_#BIZ_IN_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock2
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

        , TitleName NVARCHAR(200), TitleSeq INT, TitleName2 NVARCHAR(200), TitleSeq2 INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock2 = 1

END

IF @CONST_#BIZ_OUT_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock2
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

        , TitleName NVARCHAR(200), TitleSeq INT, TitleName2 NVARCHAR(200), TitleSeq2 INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END

IF @CONST_#BIZ_IN_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock3
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

        , AccBgtName NVARCHAR(200), AccBgtSeq INT, Sort INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock3 = 1

END

IF @CONST_#BIZ_OUT_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock3
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

        , AccBgtName NVARCHAR(200), AccBgtSeq INT, Sort INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END

IF @CONST_#BIZ_IN_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_IN_DataBlock4 = 1

END

IF @CONST_#BIZ_OUT_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock4 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYM, BgtName, AccUnitName, DeptCCtrName, AmtUnit, BgtSeq, AccUnit, DeptCCtrSeq) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'201902', N'', N'', N'', N'1000', N'', N'', N''
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

SET @ServiceSeq     = 13820093
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820097
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjPlanResultQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4rollback 