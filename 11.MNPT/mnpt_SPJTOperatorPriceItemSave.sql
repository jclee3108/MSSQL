  
IF OBJECT_ID('mnpt_SPJTOperatorPriceItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceItemSave  
GO  
    
-- v2017.09.19
  
-- 운전원노임단가입력-SS2저장 by 이재천
CREATE PROC mnpt_SPJTOperatorPriceItemSave
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTOperatorPriceItem'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock2'    , -- 임시 테이블명        
                  'StdSeq,StdSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock2          AS A   
          JOIN mnpt_TPJTOperatorPriceItem   AS B ON ( B.CompanySeq = @CompanySeq AND A.StdSeq = B.StdSeq AND A.StdSerl = B.StdSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- 디테일 삭제시 Sub디테일 로그남기기, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.StdSeq, 
               B.StdSerl, 
               B.StdSubSerl
          INTO #SubItemLog 
          FROM #BIZ_OUT_DataBlock2      AS A 
          JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq AND B.StdSerl = A.StdSerl )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTOperatorPriceSubItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTOperatorPriceSubItem'    , -- 테이블명        
                      '#SubItemLog'    , -- 임시 테이블명        
                      'StdSeq,StdSerl,StdSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock2      AS A   
          JOIN mnpt_TPJTOperatorPriceSubItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq AND B.StdSerl = A.StdSerl )
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMToolType   = A.UMToolType,  
               B.LastUserSeq  = @UserSeq    ,  
               B.LastDateTime = GETDATE()   ,
               B.PgmSeq       = @PgmSeq   
          FROM #BIZ_OUT_DataBlock2              AS A   
          JOIN mnpt_TPJTOperatorPriceItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq AND B.StdSerl = A.StdSerl )
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTOperatorPriceItem  
        (   
            Companyseq, StdSeq, StdSerl, UMToolType, FirstUserSeq, 
            FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @Companyseq, StdSeq, StdSerl, UMToolType, @UserSeq, 
               GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock2 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
 


 go

  begin tran 

  DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0
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

        , StdDate CHAR(8), Remark NVARCHAR(2000), StdSeq INT
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

        , FrStdDate CHAR(8), ToStdDate CHAR(8), StdDate CHAR(8), Remark NVARCHAR(2000), StdSeq INT
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

        , StdDate CHAR(8), UMToolTypeName NVARCHAR(200), UMEnToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeCnt INT, StdSeq INT, StdSerl INT
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5), EtcHalfPrice DECIMAL(19, 5), EtcMonthPrice DECIMAL(19, 5), StdSeq INT, StdSerl INT, StdSubSerl INT
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5), EtcHalfPrice DECIMAL(19, 5), EtcMonthPrice DECIMAL(19, 5), StdSeq INT, StdSerl INT, StdSubSerl INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END
INSERT INTO #BIZ_IN_DataBlock2 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl) 
SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock2', NULL, N'RS', N'', N'1015887004', N'0', N'3', N'0' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, NULL, NULL, NULL, NULL, N'GC', N'', N'1015887001', N'0', N'3', N'0' UNION ALL 
SELECT N'A', 3, 3, 0, 0, NULL, NULL, NULL, NULL, NULL, N'RS', N'', N'1015887004', N'0', N'3', N'0' UNION ALL 
SELECT N'A', 4, 4, 0, 0, NULL, NULL, NULL, NULL, NULL, N'FL', N'', N'1015887005', N'0', N'3', N'0'
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
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820017
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq      FROM  #BIZ_IN_DataBlock1INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl      FROM  #BIZ_IN_DataBlock2-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTOperatorPriceCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartEXEC    mnpt_SPJTOperatorPriceItemCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : End-- ExecuteOrder : 4 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTOperatorPriceSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 4 : End-- ExecuteOrder : 5 : StartEXEC    mnpt_SPJTOperatorPriceItemSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 5 : EndCOMMIT TRANSET @UseTransaction = N'0'GOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDXSELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3rollback 