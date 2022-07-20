  
IF OBJECT_ID('mnpt_SPJTShipIFListSave') IS NOT NULL   
    DROP PROC mnpt_SPJTShipIFListSave  
GO  
    
-- v2017.09.06
  
-- 모선조회-저장 by 이재천
CREATE PROC mnpt_SPJTShipIFListSave  
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipMaster')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTShipMaster'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'ShipSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.IsImagine    = A.IsImagine, 
               B.Remark       = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTShipMaster AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
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

        , IFShipCode NVARCHAR(200), IsImagine CHAR(1), Remark NVARCHAR(2000), FirstUserName NVARCHAR(100), FirstDateTime NVARCHAR(100), ShipSeq INT
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

        , IFShipCode NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), LINECode NVARCHAR(200), EnLINEName NVARCHAR(200), LINEName NVARCHAR(200), NationCode NVARCHAR(200), NationName NVARCHAR(200), CodeLetters NVARCHAR(200), TotalTON DECIMAL(19, 5), LoadTON DECIMAL(19, 5), LOA DECIMAL(19, 5), Breadth DECIMAL(19, 5), DRAFT DECIMAL(19, 5), BULKCNTR NVARCHAR(100), IsImagine CHAR(1), Remark NVARCHAR(2000), FirstUserName NVARCHAR(100), FirstDateTime NVARCHAR(100), ShipSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, IFShipCode, IsImagine, Remark, FirstUserName, FirstDateTime, ShipSeq) 
SELECT N'U', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'DOYA', N'1', N'', N'', N'', N'1' UNION ALL 
SELECT N'U', 2, 2, 0, 0, NULL, NULL, NULL, NULL, N'ZZZZ', N'1', N'', N'', N'', N'2' UNION ALL 
SELECT N'U', 3, 3, 0, 0, NULL, NULL, NULL, NULL, N'GRCH', N'1', N'', N'', N'', N'3'
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

SET @ServiceSeq     = 13820002
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820002
SET @IsTransaction  = 0
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, IFShipCode, IsImagine, Remark, FirstUserName, FirstDateTime, ShipSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, IFShipCode, IsImagine, Remark, FirstUserName, FirstDateTime, ShipSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipIFListSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
        , Result, ROW_IDX, IsChangedMst, IFShipCode, IsImagine, Remark, FirstUserName, FirstDateTime, ShipSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 