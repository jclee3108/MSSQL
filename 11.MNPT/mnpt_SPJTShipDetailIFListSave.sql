     
IF OBJECT_ID('mnpt_SPJTShipDetailIFListSave') IS NOT NULL       
    DROP PROC mnpt_SPJTShipDetailIFListSave
GO      
      
-- v2017.09.15
      
-- 모선항차조회-체크 by 이재천  
CREATE PROC mnpt_SPJTShipDetailIFListSave      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- Value INSert,Update 하기위해 담기 
    SELECT CASE WHEN B.CompanySeq IS NULL THEN 'A' ELSE 'U' END AS WorkingTag, 
           A.IDX_NO, 
           A.DataSeq, 
           A.Status, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.TITLE_IDX0_SEQ AS TitleSeq, 
           A.Value
     INTO #Value
     FROM #BIZ_OUT_DataBlock3                  AS A 
     LEFT OUTER JOIN mnpt_TPJTShipDetailValue  AS B ON ( B.CompanySeq = @CompanySeq 
                                                     AND B.ShipSeq = A.ShipSeq 
                                                     AND B.ShipSerl = A.ShipSerl 
                                                     AND B.TitleSeq = A.TITLE_IDX0_SEQ 
                                                       ) 
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
       
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetail')    
         
    EXEC _SCOMDeleteLog @CompanySeq     ,      
                        @UserSeq        ,      
                        'ShipSeq,Ser'  ,     
                        '#BIZ_OUT_DataBlock3'      ,     
                        'ShipSeq,ShipSerl'     , -- CompanySeq제외 한 키     
                        @TableColumns   , '', @PgmSeq     
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetailValue')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTShipDetailValue'    , -- 테이블명        
                  '#Value'    , -- 임시 테이블명        
                  'ShipSeq,ShipSerl,TitleSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock3 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMApplyTon   = A.UMApplyTon,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #BIZ_OUT_DataBlock3 AS A   
          JOIN mnpt_TPJTShipDetail AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
    END 
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #Value WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN 

        UPDATE B   
           SET B.Value          = A.Value,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #Value                   AS A   
          JOIN mnpt_TPJTShipDetailValue AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND A.ShipSeq = B.ShipSeq 
                                              AND A.ShipSerl = B.ShipSerl 
                                              AND A.TitleSeq = B.TitleSeq 
                                                )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #Value WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTShipDetailValue  
        (   
            CompanySeq, ShipSeq, ShipSerl, TitleSeq, Value, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ShipSeq, ShipSerl, TitleSeq, Value, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq   
          FROM #Value AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     


    RETURN     

go
begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock3 INTSELECT    @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0
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

        , ShipSeq INT, ShipSerl INT, TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100)
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

        , IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), TotalTON DECIMAL(19, 5), LOA DECIMAL(19, 5), DRAFT DECIMAL(19, 5), LINECode NVARCHAR(200), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), InDateTime NVARCHAR(200), ApproachDateTime NVARCHAR(200), WorkSrtDateTime NVARCHAR(200), WorkEndDateTime NVARCHAR(200), OutDateTime NVARCHAR(200), DiffApproachTime INT, BERTH NVARCHAR(200), BRIDGE NVARCHAR(200), BIT NVARCHAR(200), PORT NVARCHAR(200), TRADECode NVARCHAR(200), TRADETypeName NVARCHAR(200), BULKCNTR NVARCHAR(200), BizUnitName NVARCHAR(200), FirstUserName NVARCHAR(200), FirstDateTime NVARCHAR(200), ShipSeq INT, ShipSerl INT, AgentName NVARCHAR(200), TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100), UMApplyTonName NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END
INSERT INTO #BIZ_IN_DataBlock3 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, ShipSeq, ShipSerl, TITLE_IDX0_SEQ, Value, UMApplyTon) 
SELECT N'U', 1, 1, 0, 0, NULL, 0, NULL, N'DataBlock3', N'685', N'1', N'1015782005', N'22', N'1015780001' UNION ALL 
SELECT N'U', 2, 2, 0, 0, NULL, 0, NULL, NULL, N'685', N'1', N'1015782006', N'222', N'1015780001' UNION ALL 
SELECT N'U', 3, 3, 0, 0, NULL, 0, NULL, NULL, N'685', N'1', N'1015782007', N'222', N'1015780001'
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

SET @ServiceSeq     = 13820003
--SET @MethodSeq      = 3
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820004
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock3(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ShipSeq, ShipSerl, TITLE_IDX0_SEQ, Value, UMApplyTon)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ShipSeq, ShipSerl, TITLE_IDX0_SEQ, Value, UMApplyTon      FROM  #BIZ_IN_DataBlock3-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipDetailIFListCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTShipDetailIFListSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock3 WHERE Status != 0)
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
        , Result, ROW_IDX, IsChangedMst, ShipSeq, ShipSerl, TITLE_IDX0_SEQ, Value, UMApplyTon  FROM #BIZ_OUT_DataBlock3 ORDER BY IDX_NO, ROW_IDX
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
DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3rollback 