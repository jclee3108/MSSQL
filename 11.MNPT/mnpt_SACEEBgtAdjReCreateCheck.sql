  
IF OBJECT_ID('mnpt_SACEEBgtAdjReCreateCheck') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjReCreateCheck  
GO  
    
-- v2017.12.18
  
-- 경비예산입력-재생성 체크 by 이재천   
CREATE PROC mnpt_SACEEBgtAdjReCreateCheck  
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
            @EnvValue       INT 
        
    --------------------------------------------------------------------------------------
    -- 체크1, 년예산마감체크
    --------------------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          5                  , -- 이미 @1가(이) 완료된 @2입니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)  
                          @LanguageSeq       ,   
                          0,'년예산마감 ',   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
                          0,'자료'  
    UPDATE #BIZ_OUT_DataBlock1  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BIZ_OUT_DataBlock1 AS A   
                JOIN _TACBgtClosing AS B WITH(NOLOCK) ON A.StdYear = B.BgtYear AND A.AccUnit = B.AccUnit   
      WHERE B.CompanySeq = @CompanySeq   
        AND B.IsCfm = '1'  
        AND Status = 0  
    --------------------------------------------------------------------------------------
    -- 체크1, END
    --------------------------------------------------------------------------------------  
    --------------------------------------------------------------------------------------
    -- 체크2, 법인관리 결산연도에 예산을 편성하려는 연도가 등록되어 있지 않았을 때 
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND FiscalYear IN (SELECT StdYear FROM #BIZ_OUT_DataBlock1))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1170                  , -- @1에 @2이(가) 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%등록%')    
                              @LanguageSeq       ,     
                              27121,'법인관리 ',   -- SELECT * FROM _TCADictionary WHERE Word like '%법인%'    
                              1749,'예산연도' -- SELECT * FROM _TCADictionary WHERE Word like '%예산연도%'    
  
        UPDATE #BIZ_OUT_DataBlock1    
           SET Result        = @Results,    
               MessageType   = @MessageType,    
               Status        = @Status  
    END  
    --------------------------------------------------------------------------------------
    -- 체크2, END 
    --------------------------------------------------------------------------------------
    
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

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
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
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq) 
SELECT N'A', 3, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'2019', NULL, N'1000', N'1', N'영훈부서', N'복리후생비', N'판관', N'4', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'26', N'2', N'212', N'4001002', N'0', NULL, NULL
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
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820092
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SACEEBgtAdjSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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