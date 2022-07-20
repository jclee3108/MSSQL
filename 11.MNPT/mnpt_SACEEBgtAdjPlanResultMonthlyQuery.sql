     
IF OBJECT_ID('mnpt_SACEEBgtAdjPlanResultMonthlyQuery') IS NOT NULL       
    DROP PROC mnpt_SACEEBgtAdjPlanResultMonthlyQuery      
GO      
      
-- v2018.01.08 
      
-- 경비예산실적현황(월별)-조회 by 이재천  
CREATE PROC mnpt_SACEEBgtAdjPlanResultMonthlyQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @StdYear        NCHAR(4), 
            @BgtSeq         INT, 
            @AccUnit        INT, 
            @DeptCCtrSeq    INT, 
            @AmtUnit        DECIMAL(19,5), 
            @DeptSeq        INT, 
            @CCtrSeq        INT, 
            @EnvValue       INT -- 환경설정  
      
    SELECT @StdYear     = ISNULL( StdYear, '' ),   
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
    
    ------------------------------------------------------------------
    -- 예산 계획 
    ------------------------------------------------------------------
    SELECT A.AccSeq, 
           C.BgtSeq, 
           SUM(A.Month01 + A.Month02 + A.Month03 + A.Month04 + A.Month05 + 
               A.Month06 + A.Month07 + A.Month08 + A.Month09 + A.Month10 + 
               A.Month11 + A.Month12
              ) AS PlanAmt
      INTO #AccBgtPlanAmt 
      FROM mnpt_TACEEBgtAdj AS A 
      JOIN _TACBgtClosing   AS B ON ( B.CompanySeq = @CompanySeq AND A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit ) 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
      
     WHERE A.StdYear = @StdYear 
       AND B.IsCfm = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq ) 
     GROUP BY A.AccSeq, C.BgtSeq 
    

    -- 예산과목 집계
    SELECT BgtSeq, 
           0 AS AccSeq, 
           SUM(PlanAmt) AS PlanAmt, 
           1 AS Sort 
      INTO #PlanAmt 
      FROM #AccBgtPlanAmt AS A 
     GROUP BY BgtSeq
    UNION ALL -- 계정과목 집계 
    SELECT BgtSeq, 
           AccSeq, 
           PlanAmt, 
           2 AS Sort 
      FROM #AccBgtPlanAmt AS A 
    UNION ALL -- 합계
    SELECT 99999999, 
           99999999, 
           SUM(PlanAmt) AS PlanAmt, 
           3 AS Sort 
      FROM #AccBgtPlanAmt AS A 
      
    ------------------------------------------------------------------
    -- 예산 계획, End 
    ------------------------------------------------------------------
    
    --SELECT * From #PlanAmt 
    --return 
    ------------------------------------------------------------------
    -- 예산 실적 
    ------------------------------------------------------------------
    SELECT LEFT(A.AccDate,6) AccYM, 
           A.AccSeq, 
           C.BgtSeq, 
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
       AND LEFT(A.AccDate,4) = @StdYear 

       AND (BgtDeptSeq <> 0 OR BgtCCtrSeq <> 0 )
       AND A.IsSet = '1' 

       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.BgtDeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.BgtCCtrSeq = @CCtrSeq ) 
     GROUP BY LEFT(A.AccDate,6), A.AccSeq, C.BgtSeq 


    -- 예산과목 집계
    SELECT AccYM,
           BgtSeq, 
           0 AS AccSeq, 
           SUM(ResultAmt) AS ResultAmt,
           1 AS Sort 
      INTO #ResultAmt 
      FROM #AccBgtResultAmt AS A 
     GROUP BY AccYM, BgtSeq
    UNION ALL -- 계정과목 집계 
    SELECT AccYM, 
           BgtSeq, 
           AccSeq, 
           ResultAmt, 
           2 AS Sort 
      FROM #AccBgtResultAmt AS A 
    UNION ALL -- 합계 
    SELECT AccYM,
           99999999, 
           99999999 AS AccSeq, 
           SUM(ResultAmt) AS ResultAmt,
           3 AS Sort 
      FROM #AccBgtResultAmt AS A 
     GROUP BY AccYM
    ------------------------------------------------------------------
    -- 예산 실적, End 
    ------------------------------------------------------------------
    --select * from #AccBgtPlanAmt
    --select * from #AccBgtResultAmt


    CREATE TABLE #Result 
    (
        AccSeq      INT, 
        BgtSeq      INT, 
        PlanAmt     DECIMAL(19,5), 
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
        AccBgtSeq   INT, 
        Sort        INT 
    ) 

    INSERT INTO #Result ( AccSeq, BgtSeq, Sort) 
    SELECT AccSeq , BgtSeq, Sort 
      FROM #PlanAmt 
    UNION 
    SELECT AccSeq , BgtSeq, Sort
      FROM #ResultAmt 
     ORDER BY BgtSeq, Sort, AccSeq
    


    -- 계획 Update 
    UPDATE A
       SET PlanAmt = B.PlanAmt / NULLIF(@AmtUnit,0)
      FROM #Result  AS A 
      JOIN #PlanAmt AS B ON ( B.AccSeq = A.AccSeq AND B.BgtSeq = A.BgtSeq ) 
    
    -- 실적 Update 
    UPDATE A
       SET Month01 = B.Month01 / NULLIF(@AmtUnit,0), 
           Month02 = B.Month02 / NULLIF(@AmtUnit,0), 
           Month03 = B.Month03 / NULLIF(@AmtUnit,0), 
           Month04 = B.Month04 / NULLIF(@AmtUnit,0), 
           Month05 = B.Month05 / NULLIF(@AmtUnit,0), 
           Month06 = B.Month06 / NULLIF(@AmtUnit,0), 
           Month07 = B.Month07 / NULLIF(@AmtUnit,0), 
           Month08 = B.Month08 / NULLIF(@AmtUnit,0), 
           Month09 = B.Month09 / NULLIF(@AmtUnit,0), 
           Month10 = B.Month10 / NULLIF(@AmtUnit,0), 
           Month11 = B.Month11 / NULLIF(@AmtUnit,0), 
           Month12 = B.Month12 / NULLIF(@AmtUnit,0), 
           MonthSum = (B.Month01 + B.Month02 + B.Month03 + B.Month04 + B.Month05 + B.Month06 + B.Month07 + B.Month08 + B.Month09 + B.Month10 + B.Month11 + B.Month12) / NULLIF(@AmtUnit,0), 
           AccBgtSeq = CASE WHEN A.AccSeq = 0 THEN A.BgtSeq ELSE A.AccSeq END  
      FROM #Result  AS A 
      LEFT OUTER JOIN ( 
                        SELECT BgtSeq, 
                               AccSeq, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '01' THEN ResultAmt ELSE 0 END) AS Month01, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '02' THEN ResultAmt ELSE 0 END) AS Month02, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '03' THEN ResultAmt ELSE 0 END) AS Month03, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '04' THEN ResultAmt ELSE 0 END) AS Month04, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '05' THEN ResultAmt ELSE 0 END) AS Month05, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '06' THEN ResultAmt ELSE 0 END) AS Month06, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '07' THEN ResultAmt ELSE 0 END) AS Month07, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '08' THEN ResultAmt ELSE 0 END) AS Month08, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '09' THEN ResultAmt ELSE 0 END) AS Month09, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '10' THEN ResultAmt ELSE 0 END) AS Month10, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '11' THEN ResultAmt ELSE 0 END) AS Month11, 
                               SUM(CASE WHEN RIGHT(AccYM,2) = '12' THEN ResultAmt ELSE 0 END) AS Month12
                          FROM #ResultAmt 
                         GROUP BY BgtSeq, AccSeq
                      ) AS B ON ( B.BgtSeq = A.BgtSeq AND B.AccSeq = A.AccSeq ) 
    
    -- 최종조회 
    SELECT A.AccSeq, 
           A.BgtSeq, 
           A.AccBgtSeq, 
           CASE WHEN A.AccSeq = 0 THEN C.BgtName 
                WHEN A.AccSeq = 99999999 THEN '합계'
                ELSE B.AccName END AS AccBgtName, 
           A.PlanAmt AS PlanAmt, 
           A.Month01 AS Month01,
           A.Month02 AS Month02,
           A.Month03 AS Month03,
           A.Month04 AS Month04,
           A.Month05 AS Month05,
           A.Month06 AS Month06,
           A.Month07 AS Month07,
           A.Month08 AS Month08,
           A.Month09 AS Month09,
           A.Month10 AS Month10,
           A.Month11 AS Month11,
           A.Month12 AS Month12,
           A.MonthSum AS MonthSum, 
           A.Sort 
      FROM #Result                  AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACBgtItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.BgtSeq = A.BgtSeq ) 
      ORDER BY BgtSeq, Sort, AccSeq
    
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

        , BgtSeq INT, StdYear CHAR(4), DeptCCtrSeq INT, AccUnit INT, AmtUnit DECIMAL(19, 5)
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

        , BgtSeq INT, StdYear CHAR(4), AccBgtName NVARCHAR(200), PlanAmt DECIMAL(19, 5), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), AccBgtSeq INT, Sort INT, DeptCCtrSeq INT, AccUnit INT, AmtUnit DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, BgtSeq, StdYear, DeptCCtrSeq, AccUnit, AmtUnit) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'', N'2018', N'', N'', N'1'
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

SET @ServiceSeq     = 13820092
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820095
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjPlanResultMonthlyQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 