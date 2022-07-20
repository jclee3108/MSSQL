     
IF OBJECT_ID('mnpt_SPJTEEWorkReportWeightChgDlgQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEEWorkReportWeightChgDlgQuery      
GO      
      
-- v2018.02.12
      
-- 작업물량변경-조회 by 이재천  
CREATE PROC mnpt_SPJTEEWorkReportWeightChgDlgQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @WorkReportSeq  INT   
      
    SELECT @WorkReportSeq = ISNULL(WorkReportSeq,0)
      FROM #BIZ_IN_DataBlock1    
    
    SELECT A.WorkReportSeq, 
           A.PJTSeq,
           B.PJTName, 
           F.PJTTypeName, 
           A.ShipSeq,
           A.ShipSerl, 
           C.IFShipCode + '-' + LEFT(C.ShipSerlNo,4) + '-' + RIGHT(C.ShipSerlNo,3) AS ShipSerlNo,
           A.UMLoadType, 
           D.MinorName AS UMLoadTypeName, 
           A.UMWorkType, 
           E.MinorName AS UMWorkTypeName, 
           A.TodayMTWeight AS BFMTWeight, 
           A.TodayCBMWeight AS BFCBMWeight, 
           A.TodayMTWeight AS MTWeight, 
           A.TodayCBMWeight AS CBMWeight 
      FROM mnpt_TPJTWorkReport              AS A 
      LEFT OUTER JOIN _TPJTProject          AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLoadType ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMWorkType ) 
      LEFT OUTER JOIN _TPJTType             AS F ON ( F.CompanySeq = @CompanySeq AND F.PJTTypeSeq = B.PJTTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkReportSeq = @WorkReportSeq
    
    RETURN     

go
begin tran DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
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

        , WorkReportSeq INT
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

        , BFMTWeight DECIMAL(19, 5), BFCBMWeight DECIMAL(19, 5), MTWeight DECIMAL(19, 5), CBMWeight DECIMAL(19, 5), WorkReportSeq INT, PJTName NVARCHAR(200), PJTTypeName NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMLoadTypeName NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkReportSeq) 
SELECT N'U', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'493'



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

SET @ServiceSeq     = 13820157
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820137
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEWorkReportWeightChgDlgQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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