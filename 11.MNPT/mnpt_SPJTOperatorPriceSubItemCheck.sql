  
IF OBJECT_ID('mnpt_SPJTOperatorPriceSubItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTOperatorPriceSubItemCheck  
GO  
    
-- v2017.09.19
  
-- 운전원노임단가입력-SS3체크 by 이재천
CREATE PROC mnpt_SPJTOperatorPriceSubItemCheck      
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
            @MaxSubSerl     INT 
        
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
      
    UPDATE #BIZ_OUT_DataBlock3  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #BIZ_OUT_DataBlock3 AS A   
      JOIN (SELECT S.PJTTypeSeq, S.StdSeq, S.StdSerl    
              FROM (SELECT A1.PJTTypeSeq, A1.StdSeq, A1.StdSerl  
                      FROM #BIZ_OUT_DataBlock3 AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTTypeSeq, A1.StdSeq, A1.StdSerl
                      FROM mnpt_TPJTOperatorPriceSubItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock3   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND StdSeq = A1.StdSeq  
                                                 AND StdSerl = A1.StdSerl 
                                                 AND StdSubSerl = A1.StdSubSerl
                                      )  
                   ) AS S  
             GROUP BY S.PJTTypeSeq, S.StdSeq, S.StdSerl     
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTTypeSeq = B.PJTTypeSeq AND A.StdSeq = B.StdSeq AND A.StdSerl = B.StdSerl )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  


    -- Serl 채번 
    SELECT @MaxSubSerl = MAX(A.StdSubSerl) 
      FROM mnpt_TPJTOperatorPriceSubItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock3 WHERE StdSeq = A.StdSeq AND StdSerl = A.StdSerl) 
    
    UPDATE A 
       SET StdSubSerl = ISNULL(@MaxSubSerl,0) + A.DataSeq
      FROM #BIZ_OUT_DataBlock3 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    




    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #BIZ_OUT_DataBlock3   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #BIZ_OUT_DataBlock3  
     WHERE Status = 0  
       AND (( StdSeq = 0 OR StdSeq IS NULL ) 
            OR ( StdSerl = 0 OR StdSerl IS NULL )
            OR ( StdSubSerl = 0 OR StdSubSerl IS NULL )
            )
    
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

        , UMToolTypeName NVARCHAR(200), UMToolType INT, PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UnDayPrice DECIMAL(19, 5), UnHalfPrice DECIMAL(19, 5), UnMonthPrice DECIMAL(19, 5), DailyDayPrice DECIMAL(19, 5), DailyHalfPrice DECIMAL(19, 5), DailyMonthPrice DECIMAL(19, 5), OSDayPrice DECIMAL(19, 5), OSHalfPrice DECIMAL(19, 5), OSMonthPrice DECIMAL(19, 5), EtcDayPrice DECIMAL(19, 5)
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
INSERT INTO #BIZ_IN_DataBlock3 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice) 
SELECT N'A', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock3', NULL, NULL, N'서비스', N'2', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, N'임희연소분류2테스트', N'3', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0' UNION ALL 
SELECT N'A', 3, 3, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0', N'0'
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
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, Remark, StdSeq      FROM  #BIZ_IN_DataBlock1INSERT INTO #BIZ_OUT_DataBlock2(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl      FROM  #BIZ_IN_DataBlock2INSERT INTO #BIZ_OUT_DataBlock3(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice      FROM  #BIZ_IN_DataBlock3-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTOperatorPriceCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
-- ExecuteOrder : 2 : End-- ExecuteOrder : 3 : StartEXEC    mnpt_SPJTOperatorPriceSubItemCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 3 : End-- ExecuteOrder : 4 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTOperatorPriceSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
-- ExecuteOrder : 5 : End-- ExecuteOrder : 6 : StartEXEC    mnpt_SPJTOperatorPriceSubItemSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock2 WHERE Status != 0) OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, StdDate, UMToolTypeName, UMEnToolTypeName, UMToolType, PJTTypeCnt, StdSeq, StdSerl  FROM #BIZ_OUT_DataBlock2 ORDER BY IDX_NO, ROW_IDXSELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
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
        , Result, ROW_IDX, IsChangedMst, UMToolTypeName, UMToolType, PJTTypeName, PJTTypeSeq, UnDayPrice, UnHalfPrice, UnMonthPrice, DailyDayPrice, DailyHalfPrice, DailyMonthPrice, OSDayPrice, OSHalfPrice, OSMonthPrice, EtcDayPrice  FROM #BIZ_OUT_DataBlock3 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3

rollback 
 