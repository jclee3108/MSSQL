  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceValueSave') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceValueSave  
GO  
    
-- v2017.09.28
  
-- 노조노임단가입력-Value저장 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceValueSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTUnionWagePriceValue')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTUnionWagePriceValue'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock3'    , -- 임시 테이블명        
                  'StdSeq,StdSerl,TitleSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , 'StdSeq,StdSerl,TITLE_IDX1_SEQ', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock3          AS A   
          JOIN mnpt_TPJTUnionWagePriceValue AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND A.StdSeq = B.StdSeq 
                                                  AND A.StdSerl = B.StdSerl 
                                                  AND A.TITLE_IDX1_SEQ = B.TitleSeq 
                                                    )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.Value          = A.Value, 
               B.LastUserSeq    = @UserSeq    ,  
               B.LastDateTime   = GETDATE()   ,
               B.PgmSeq         = @PgmSeq   
          FROM #BIZ_OUT_DataBlock3          AS A   
          JOIN mnpt_TPJTUnionWagePriceValue AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND A.StdSeq = B.StdSeq 
                                                  AND A.StdSerl = B.StdSerl 
                                                  AND A.TITLE_IDX1_SEQ = B.TitleSeq 
                                                    )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTUnionWagePriceValue  
        (   
            CompanySeq, StdSeq, StdSerl, TitleSeq, Value, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, StdSeq, StdSerl, TITLE_IDX1_SEQ, Value, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock3 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
 


go


begin tran DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_IN_DataBlock4 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock4 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_IN_DataBlock4 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock4 = 0
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

        , StdDate CHAR(8), Remark NVARCHAR(200), StdSeq INT
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

        , StdDate CHAR(8), Remark NVARCHAR(200), StdSeq INT, FrStdDate CHAR(8), ToStdDate CHAR(8)
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

        , TitleName1 NVARCHAR(200), TitleSeq1 INT, TitleName2 NVARCHAR(200), TitleSeq2 INT, TitleName3 NVARCHAR(200), TitleSeq3 INT
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

        , TitleName1 NVARCHAR(200), TitleSeq1 INT, TitleName2 NVARCHAR(200), TitleSeq2 INT, TitleName3 NVARCHAR(200), TitleSeq3 INT
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

        , PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UMLoadWayName NVARCHAR(200), UMLoadWaySeq INT, StdSeq INT, StdSerl INT, TITLE_IDX1_SEQ INT, Value DECIMAL(19, 5)
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

        , PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UMLoadWayName NVARCHAR(200), UMLoadWaySeq INT, StdSeq INT, StdSerl INT, TITLE_IDX1_SEQ INT, Value DECIMAL(19, 5)
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
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdDate, Remark, StdSeq) 
SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'20170901', N'', N'0' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, NULL, NULL, NULL, N'20170905', N'', N'0'
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

SET @ServiceSeq     = 13820028
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820023
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq      FROM  #BIZ_IN_DataBlock1INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, TitleName1, TitleSeq1, TitleName2, TitleSeq2, TitleName3, TitleSeq3)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, TitleName1, TitleSeq1, TitleName2, TitleSeq2, TitleName3, TitleSeq3      FROM  #BIZ_IN_DataBlock2INSERT INTO #BIZ_OUT_DataBlock3(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTTypeName, PJTTypeSeq, UMLoadWayName, UMLoadWaySeq, StdSeq, StdSerl, TITLE_IDX1_SEQ, Value)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, PJTTypeName, PJTTypeSeq, UMLoadWayName, UMLoadWaySeq, StdSeq, StdSerl, TITLE_IDX1_SEQ, Value      FROM  #BIZ_IN_DataBlock3-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTUnionWagePriceCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartEXEC    mnpt_SPJTUnionWagePriceItemCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : End-- ExecuteOrder : 3 : StartEXEC    mnpt_SPJTUnionWagePriceValueCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 3 : End-- ExecuteOrder : 4 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTUnionWagePriceSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 4 : End-- ExecuteOrder : 5 : StartEXEC    mnpt_SPJTUnionWagePriceItemSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 5 : End-- ExecuteOrder : 6 : StartEXEC    mnpt_SPJTUnionWagePriceValueSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock4 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
COMMIT TRANSET @UseTransaction = N'0'-- ExecuteOrder : 6 : EndGOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq, ToStdDate  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDXSELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, TitleName1, TitleSeq1, TitleName2, TitleSeq2, TitleName3, TitleSeq3  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDXSELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, PJTTypeName, PJTTypeSeq, UMLoadWayName, UMLoadWaySeq, StdSeq, StdSerl, TITLE_IDX1_SEQ, Value  FROM #BIZ_OUT_DataBlock3 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4rollback 