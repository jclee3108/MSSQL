     
IF OBJECT_ID('mnpt_SPJTEEWorkReportAnalysisLabel') IS NOT NULL       
    DROP PROC mnpt_SPJTEEWorkReportAnalysisLabel      
GO      
      
-- v2017.12.18
      
-- 하역생산성분석-라벨 by 이재천  
CREATE PROC mnpt_SPJTEEWorkReportAnalysisLabel      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @StdYear            NCHAR(6), 
            @UMWorkReportKind   INT
    
    SELECT @StdYear           = ISNULL( StdYear , '' ), 
           @UMWorkReportKind  = ISNULL( UMWorkReportKind , 0 )
      FROM #BIZ_IN_DataBlock1  
    
    SELECT '※ ' + A.MinorName + '년 ' + D.MinorName + ' 관리지표 : ' + C.ValueText AS Label
      FROM _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor      AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016553
       AND A.MinorName = @StdYear 
       AND B.ValueSeq = @UMWorkReportKind
    
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

        , StdYear CHAR(4), UMWorkReportKind INT
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

        , StdYear CHAR(4), UMWorkReportKindName NVARCHAR(200), IsNotRORO CHAR(1), IsCrane CHAR(1), BizUnitName NVARCHAR(200), UMAnalysisKindName NVARCHAR(200), UMWorkReportKind INT, BizUnit INT, UMAnalysisKind INT, AnalysisSeq INT, Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthTot DECIMAL(19, 5), MonthAvg DECIMAL(19, 5), AnalysisSerl INT, Sort INT, AnalysisName NVARCHAR(200), Label NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYear, UMWorkReportKind) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'2017', N'1016550001'
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

SET @ServiceSeq     = 13820087
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820090
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEWorkReportAnalysisLabel            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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