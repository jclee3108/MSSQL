     
IF OBJECT_ID('mnpt_SPJTWorkReportJumpCheck') IS NOT NULL       
    DROP PROC mnpt_SPJTWorkReportJumpCheck      
GO      
      
-- v2018.02.13
      
-- 작업실적입력-점프체크 by 이재천  
CREATE PROC mnpt_SPJTWorkReportJumpCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS 
    
    ------------------------------------------------------------------------------
    -- 체크1, 모선항차가 존재하지 않은 작업은 변경 할 수 없습니다. 
    ------------------------------------------------------------------------------
    UPDATE A
       SET Result = '모선항차가 존재하지 않은 작업은 변경 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
           
      FROM #BIZ_OUT_DataBlock1   AS A 
      JOIN mnpt_TPJTWorkReport  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.Status = 0 
       AND (ISNULL(B.ShipSeq,0) = 0 
        OR ISNULL(B.ShipSerl,0) = 0)
   
    ------------------------------------------------------------------------------
    -- 체크1, End 
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- 체크2, 본선작업만 변경 할 수 있습니다.
    ------------------------------------------------------------------------------
    UPDATE A
       SET Result = '본선작업만 변경 할 수 있습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #BIZ_OUT_DataBlock1               AS A 
                 JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMWorkType AND C.Serl = 1000001 ) 
     WHERE C.ValueText <> '1' 
       AND A.Status = 0 
    ------------------------------------------------------------------------------
    -- 체크2, End 
    ------------------------------------------------------------------------------


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
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkReportSeq) 
SELECT N'', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'1778'
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

SET @ServiceSeq     = 13820157
--SET @MethodSeq      = 3
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820019
SET @IsTransaction  = 0
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkReportSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkReportSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportJumpCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
        , CASE
            WHEN Status = 0 OR Status IS NULL THEN
                -- 정상인건 중에
                CASE
                    WHEN @HasError = N'1' THEN
                        -- 오류가 발생된 건이면
                        CASE
                            WHEN @UseTransaction = N'1' THEN
                                999999  -- 트랜잭션인 경우
                            ELSE
                                999998  -- 트랜잭션이 아닌 경우
                        END
                    ELSE
                        -- 오류가 발생되지 않은 건이면
                        0
                END
            ELSE
                Status
        END AS Status
        , Result, ROW_IDX, IsChangedMst, WorkReportSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 