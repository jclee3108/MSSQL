  
IF OBJECT_ID('mnpt_SPJTWorkReportItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportItemCheck  
GO  
    
-- v2017.09.25
  
-- 작업실적입력-SS2체크 by 이재천
CREATE PROC mnpt_SPJTWorkReportItemCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @MaxSerl        INT 
    

    ------------------------------------------------------------------
    -- Serl 채번 
    ------------------------------------------------------------------
    SELECT @MaxSerl = MAX(A.WorkReportSerl) 
      FROM mnpt_TPJTWorkReportItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkReportSeq = A.WorkReportSeq) 
    
    UPDATE A 
       SET WorkReportSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    ------------------------------------------------------------------
    -- 체크1, 승인처리가 되어 신규/수정/삭제를 할 수 없습니다. 
    ------------------------------------------------------------------
    UPDATE A
       SET Result = '승인처리가 되어 신규/수정/삭제를 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #BIZ_OUT_DataBlock2      AS A 
      JOIN mnpt_TPJTWorkReport      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.Status = 0
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTWorkReportItem AS Z 
                     JOIN mnpt_TPJTWorkReport     AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WorkReportSeq = Z.WorkReportSeq ) 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Y.WorkDate = B.WorkDate 
                      AND Z.IsCfm = '1'
                  ) 
    ------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크2, 자가장비와 임차장비는 구분하여 저장하시기 바랍니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '자가장비와 임차장비는 구분하여 저장하시기 바랍니다.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND A.SelfToolSeq <> 0 AND A.RentToolSeq <> 0 
    ------------------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크3, 일용직이 존재 하는 경우에는 인원을 입력해야 합니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '일용직이 존재 하는 경우에는 인원을 입력해야 합니다.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND ( ( A.DDailyEmpSeq <> 0 AND A.DDailyDay = 0 AND A.DDailyHalf = 0 AND A.DDailyMonth = 0 )
          OR ( A.NDDailyEmpSeq <> 0 AND A.NDDailyDay = 0 AND A.NDDailyHalf = 0 AND A.NDDailyMonth = 0 )
           ) 
    ------------------------------------------------------------------
    -- 체크3, END 
    ------------------------------------------------------------------

    ------------------------------------------------------------------
    -- 체크4, 일용직 인원을 중복으로 입력 할 수 없습니다.
    ------------------------------------------------------------------
    UPDATE A
       SET Result        = '일용직 인원을 중복으로 입력 할 수 없습니다.',  
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock2 AS A 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
       AND ( ( (A.DDailyDay <> 0 AND A.DDailyHalf <> 0) OR ( A.DDailyDay <> 0 AND A.DDailyMonth <> 0) OR (A.DDailyHalf <> 0 AND A.DDailyMonth <> 0) )
          OR ( (A.NDDailyDay <> 0 AND A.NDDailyHalf <> 0) OR ( A.NDDailyDay <> 0 AND A.NDDailyMonth <> 0) OR (A.NDDailyHalf <> 0 AND A.NDDailyMonth <> 0) )
           ) 
    ------------------------------------------------------------------
    -- 체크4, END 
    ------------------------------------------------------------------




    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock2   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock2  
     WHERE Status = 0  
       AND ( WorkReportSeq = 0 OR WorkReportSeq IS NULL )  
        OR ( WorkReportSerl = 0 OR WorkReportSerl IS NULL ) 
    
    RETURN  
  

go
begin tran 

DECLARE   @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock2 INTSELECT    @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), DDailyEmpSeq INT, NDDailyEmpSeq INT, DDailyEmpName NVARCHAR(100), NDDailyEmpName NVARCHAR(100)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), SubWorkPlanSeq INT, IsCfmDetail CHAR(1), WorkDate CHAR(8), DDailyEmpSeq INT, NDDailyEmpSeq INT, DDailyEmpName NVARCHAR(100), NDDailyEmpName NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock2 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkReportSeq, WorkReportSerl, WorkPlanSeq, WorkPlanSerl, DDailyEmpSeq, NDDailyEmpSeq, DDailyEmpName, NDDailyEmpName) 
SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock2', N'송장발행', N'1015818010', N'', N'0', N'', N'0', N'0', N'', N'0', N'', N'0', N'', N'0', N'2', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'0', N'0', N'0', N'1', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'375', N'0', N'349', N'1', N'0', N'0', N'', N'' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, NULL, NULL, NULL, N'반입하차', N'1015818012', N'', N'0', N'', N'0', N'0', N'', N'0', N'', N'0', N'', N'0', N'3', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'0', N'0', N'0', N'32', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'375', N'0', N'349', N'2', N'0', N'0', N'', N'' UNION ALL 
SELECT N'A', 3, 3, 0, 0, NULL, NULL, NULL, NULL, N'장비임대', N'1015818013', N'', N'0', N'', N'0', N'0', N'', N'0', N'', N'0', N'', N'0', N'1', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'0', N'0', N'0', N'3', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'', N'375', N'0', N'349', N'3', N'0', N'0', N'', N''
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

SET @ServiceSeq     = 13820024
--SET @MethodSeq      = 4
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820019
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkReportSeq, WorkReportSerl, WorkPlanSeq, WorkPlanSerl, DDailyEmpSeq, NDDailyEmpSeq, DDailyEmpName, NDDailyEmpName)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkReportSeq, WorkReportSerl, WorkPlanSeq, WorkPlanSerl, DDailyEmpSeq, NDDailyEmpSeq, DDailyEmpName, NDDailyEmpName      FROM  #BIZ_IN_DataBlock2-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportItemCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTWorkReportItemSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : EndCOMMIT TRANSET @UseTransaction = N'0'GOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, UMBisWorkTypeName, UMBisWorkType, SelfToolName, SelfToolSeq, RentToolName, RentToolSeq, ToolWorkTime, DriverEmpName1, DriverEmpSeq1, DriverEmpName2, DriverEmpSeq2, DriverEmpName3, DriverEmpSeq3, DUnionDay, DUnionHalf, DUnionMonth, DDailyDay, DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, DEtcDay, DEtcHalf, DEtcMonth, NDEmpName, NDEmpSeq, NDUnionUnloadGang, NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, DRemark, WorkReportSeq, WorkReportSerl, WorkPlanSeq, WorkPlanSerl, DDailyEmpSeq, NDDailyEmpSeq, DDailyEmpName, NDDailyEmpName  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 