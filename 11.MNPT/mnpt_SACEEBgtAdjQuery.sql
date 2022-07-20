  
IF OBJECT_ID('mnpt_SACEEBgtAdjQuery') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjQuery  
GO  
    
-- v2017.12.18
  
-- 경비예산입력-조회 by 이재천   
CREATE PROC mnpt_SACEEBgtAdjQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StdYear    NCHAR(4), 
            @AccUnit    INT, 
            @AmtUnit    DECIMAL(19,5) 
      
    SELECT @StdYear = ISNULL( StdYear , '' ),   
           @AccUnit = ISNULL( AccUnit , 0 ), 
           @AmtUnit = ISNULL( AmtUnit, 0 ) 
      FROM #BIZ_IN_DataBlock1    
    
    
    SELECT A.AdjSeq, 
           A.StdYear, 
           A.AccUnit, 
           F.AccUnitName, 
           CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN ISNULL(C.CCtrName, '')   
                ELSE ISNULL(B.DeptName, 0) END DeptCCtrName, 
           CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN ISNULL(A.CCtrSeq, '')   
                ELSE ISNULL(A.DeptSeq, 0) END DeptCCtrSeq, 
           A.AccSeq, 
           D.AccName, 
           A.UMCostType, 
           E.MinorName AS UMCostTypeName, 
           A.Month01 / NULLIF(@AmtUnit,0) AS Month01, 
           A.Month02 / NULLIF(@AmtUnit,0) AS Month02, 
           A.Month03 / NULLIF(@AmtUnit,0) AS Month03, 
           A.Month04 / NULLIF(@AmtUnit,0) AS Month04, 
           A.Month05 / NULLIF(@AmtUnit,0) AS Month05, 
           A.Month06 / NULLIF(@AmtUnit,0) AS Month06, 
           A.Month07 / NULLIF(@AmtUnit,0) AS Month07, 
           A.Month08 / NULLIF(@AmtUnit,0) AS Month08, 
           A.Month09 / NULLIF(@AmtUnit,0) AS Month09, 
           A.Month10 / NULLIF(@AmtUnit,0) AS Month10, 
           A.Month11 / NULLIF(@AmtUnit,0) AS Month11, 
           A.Month12 / NULLIF(@AmtUnit,0) AS Month12, 
           (A.Month01 + A.Month02 + A.Month03 + A.Month04 + A.Month05 + A.Month06 + 
           A.Month07 + A.Month08 + A.Month09 + A.Month10 + A.Month11 + A.Month12) / NULLIF(@AmtUnit,0) AS MonthSum
      
      FROM mnpt_TACEEBgtAdj         AS A 
      LEFT OUTER JOIN _TDADept      AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS C ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS D ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMCostType ) 
      LEFT OUTER JOIN _TDAAccUnit   AS F ON ( F.CompanySeq = @CompanySeq AND F.AccUnit = A.AccUnit ) 

     WHERE A.CompanySeq = @CompanySeq   
       AND A.StdYear = @StdYear 
       AND A.AccUnit = @AccUnit 
     ORDER BY StdYear, AccUnitName, DeptCCtrName, AccName, UMCostTypeName
    
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

        , StdYear CHAR(4), AmtUnit DECIMAL(19, 5), AccUnit INT
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

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYear, AmtUnit, AccUnit) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'2017', N'0', N'1'
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

SET @ServiceSeq     = 13820089
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820092
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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