  
IF OBJECT_ID('mnpt_SPJTOperatorPriceDataCopy') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceDataCopy  
GO  
    
-- v2017.09.20
  
-- 운전원노임단가입력-최근자료복사 by 이재천
CREATE PROC mnpt_SPJTOperatorPriceDataCopy
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       

    -----------------------------------------------------------
    -- 기존 데이터 Delete, Srt
    -----------------------------------------------------------
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)  

    -- Item Log 
    SELECT 'D' AS WorkingTag, 
           A.Status, 
           B.StdSeq, 
           B.StdSerl 
      INTO #ItemLog
      FROM #BIZ_OUT_DataBlock2          AS A 
      JOIN mnpt_TPJTOperatorPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq ) 
     WHERE A.Status = 0 
     
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTOperatorPriceItem'    , -- 테이블명        
                  '#ItemLog'    , -- 임시 테이블명        
                  'StdSeq,StdSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- Item Delete 
    DELETE B
      FROM #BIZ_OUT_DataBlock2        AS A 
      JOIN mnpt_TPJTOperatorPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq ) 
     WHERE A.Status = 0 

    -- SubItem Log 
    SELECT 'D' AS WorkingTag, 
           A.Status, 
           B.StdSeq, 
           B.StdSerl, 
           B.StdSubSerl
      INTO #SubItemLog
      FROM #BIZ_OUT_DataBlock2              AS A 
      JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq ) 
     WHERE A.Status = 0 
     
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceSubItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTOperatorPriceSubItem'    , -- 테이블명        
                  '#SubItemLog'    , -- 임시 테이블명        
                  'StdSeq,StdSerl,StdSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- SubItem Delete 
    DELETE B
      FROM #BIZ_OUT_DataBlock2              AS A 
      JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq ) 
     WHERE A.Status = 0 

    -----------------------------------------------------------
    -- 기존 데이터 Delete, End
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- 최근자료복사, Srt
    -----------------------------------------------------------
    DECLARE @MaxStdDate NCHAR(8), 
            @MaxStdSeq  INT 

    SELECT @MaxStdDate = MAX(B.StdDate) 
      FROM #BIZ_OUT_DataBlock2          AS A 
      JOIN mnpt_TPJTOperatorPriceMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate < A.StdDate ) 
     WHERE A.Status = 0 
     
    SELECT @MaxStdSeq = A.StdSeq 
      FROM mnpt_TPJTOperatorPriceMaster AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdDate = @MaxStdDate 
    
    -- Item Insert
    INSERT INTO mnpt_TPJTOperatorPriceItem
    (
        Companyseq, StdSeq, StdSerl, UMToolType, FirstUserSeq, 
        FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
    )
    SELECT @Companyseq, B.StdSeq, A.StdSerl, A.UMToolType, @UserSeq, 
           GETDATE(), @UserSeq, GETDATE(), @PgmSeq
      FROM mnpt_TPJTOperatorPriceItem       AS A 
      LEFT OUTER JOIN #BIZ_OUT_DataBlock2   AS B ON ( 1 = 1 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @MaxStdSeq
    
    -- SubItem Insert 
    INSERT INTO mnpt_TPJTOperatorPriceSubItem
    (
        Companyseq, StdSeq, StdSerl, StdSubSerl, PJTTypeSeq, 
        UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, 
        DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice, 
        EtcHalfPrice, EtcMonthPrice, FirstUserSeq, FirstDateTime, LastUserSeq, 
        LastDateTime, PgmSeq
    )
    SELECT @Companyseq, B.StdSeq, A.StdSerl, A.StdSubSerl, A.PJTTypeSeq, 
           A.UnDayPrice, A.UnHalfPrice, A.UnMonthPrice, A.DailyDayPrice, A.DailyHalfPrice, 
           A.DailyMonthPrice, A.OSDayPrice, A.OSHalfPrice, A.OSMonthPrice, A.EtcDayPrice, 
           A.EtcHalfPrice, A.EtcMonthPrice, @UserSeq, GETDATE(), @UserSeq, 
           GETDATE(), @PgmSeq
      FROM mnpt_TPJTOperatorPriceSubItem        AS A 
      LEFT OUTER JOIN #BIZ_OUT_DataBlock2       AS B ON ( 1 = 1 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @MaxStdSeq
    -----------------------------------------------------------
    -- 최근자료복사, End 
    -----------------------------------------------------------
    
    RETURN  
 

 
 GO 


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

        , StdDate CHAR(8), StdSeq INT
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

        , StdDate CHAR(8), UMToolTypeName NVARCHAR(200), UMEnToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeCnt INT, StdSeq INT, StdSerl INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
INSERT INTO #BIZ_IN_DataBlock2 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdDate, StdSeq) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20170903', N'20'
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

SET @ServiceSeq     = 13820020
--SET @MethodSeq      = 5
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820017
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, StdSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, StdSeq      FROM  #BIZ_IN_DataBlock2-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTOperatorPriceDataCopyCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTOperatorPriceDataCopy            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, StdDate, StdSeq  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 