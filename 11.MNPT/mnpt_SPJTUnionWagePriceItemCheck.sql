  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceItemCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceItemCheck  
GO  
    
-- v2017.09.28
  
-- 노조노임단가입력-SS2체크 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceItemCheck      
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
    
 
    
    CREATE TABLE #DISTINCTData
    (
        DataSeq         INT IDENTITY, 
        WorkingTag      NCHAR(1), 
        Status          INT, 
        ROW_IDX         INT, 
        PJTTypeSeq      INT, 
        UMLoadWaySeq    INT, 
        StdSeq          INT, 
        StdSerl         INT, 
        Result          NVARCHAR(500), 
        MessageType     INT

    )
    INSERT INTO #DISTINCTData ( WorkingTag, Status, ROW_IDX, PJTTypeSeq, UMLoadWaySeq, StdSeq, StdSerl, Result, MessageType )
    SELECT DISTINCT WorkingTag, Status, ROW_IDX, PJTTypeSeq, UMLoadWaySeq, StdSeq, StdSerl, Result, MessageType  
      FROM #BIZ_OUT_DataBlock3 
     ORDER BY ROW_IDX
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2' 
    UPDATE #DISTINCTData  
       SET Result       = @Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #DISTINCTData AS A   
      JOIN (SELECT S.PJTTypeSeq, S.UMLoadWaySeq, S.StdSeq
              FROM (SELECT A1.PJTTypeSeq, A1.UMLoadWaySeq, A1.StdSeq
                      FROM #DISTINCTData AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PJTTypeSeq, A1.UMLoadWaySeq, A1.StdSeq
                      FROM mnpt_TPJTUnionWagePriceItem AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #DISTINCTData   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND StdSeq = A1.StdSeq  
                                                 AND StdSerl = A1.StdSerl
                                      )  
                   ) AS S  
             GROUP BY S.PJTTypeSeq, S.UMLoadWaySeq, S.StdSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PJTTypeSeq = B.PJTTypeSeq AND A.UMLoadWaySeq = B.UMLoadWaySeq AND A.StdSeq = B.StdSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    

    UPDATE A  
       SET Result       = B.Result, 
           MessageType  = B.MessageType,  
           Status       = B.Status  
      FROM #BIZ_OUT_DataBlock3  AS A 
      JOIN #DISTINCTData        AS B ON ( B.ROW_IDX = A.ROW_IDX ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    




    -- Serl 채번 
    SELECT @MaxSerl = MAX(A.StdSerl) 
      FROM mnpt_TPJTUnionWagePriceItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #DISTINCTData WHERE StdSeq = A.StdSeq) 
    
    UPDATE A 
       SET StdSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #DISTINCTData AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    UPDATE A  
       SET StdSerl  = B.StdSerl 
      FROM #BIZ_OUT_DataBlock3  AS A 
      JOIN #DISTINCTData        AS B ON ( B.ROW_IDX = A.ROW_IDX ) 
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  

    
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
           )
    
    RETURN  
  

  go


  begin tran 

  DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_IN_DataBlock4 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock4 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_IN_DataBlock4 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock4 = 0
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
INSERT INTO #BIZ_IN_DataBlock3 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, PJTTypeName, PJTTypeSeq, UMLoadWayName, UMLoadWaySeq, StdSeq, StdSerl, TITLE_IDX1_SEQ, Value) 
SELECT N'A', 1, 1, 0, 0, NULL, 0, NULL, N'DataBlock3', N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942001', N'1' UNION ALL 
SELECT N'A', 2, 2, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942002', N'3' UNION ALL 
SELECT N'A', 3, 3, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942003', N'6' UNION ALL 
SELECT N'A', 4, 4, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942004', N'7' UNION ALL 
SELECT N'A', 5, 5, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942005', N'0' UNION ALL 
SELECT N'A', 6, 6, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942006', N'565' UNION ALL 
SELECT N'A', 7, 7, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942007', N'5656' UNION ALL 
SELECT N'A', 8, 8, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942008', N'545' UNION ALL 
SELECT N'A', 9, 9, 0, 0, NULL, 0, NULL, NULL, N'임희연소분류2테스트', N'3', N'일반', N'1015935001', N'8', N'0', N'1015942009', N'464' UNION ALL 
SELECT N'A', 10, 10, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942001', N'2' UNION ALL 
SELECT N'A', 11, 11, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942002', N'4' UNION ALL 
SELECT N'A', 12, 12, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942003', N'5' UNION ALL 
SELECT N'A', 13, 13, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942004', N'8' UNION ALL 
SELECT N'A', 14, 14, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942005', N'9' UNION ALL 
SELECT N'A', 15, 15, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942006', N'656' UNION ALL 
SELECT N'A', 16, 16, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942007', N'5656' UNION ALL 
SELECT N'A', 17, 17, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942008', N'45' UNION ALL 
SELECT N'A', 18, 18, 0, 0, NULL, 1, NULL, NULL, N'프로젝트별 품목생성 프로젝트', N'1', N'RORO', N'1015935002', N'8', N'0', N'1015942009', N'4646'
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
-- ExecuteOrder : 2 : End-- ExecuteOrder : 4 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTUnionWagePriceSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4Rollback 