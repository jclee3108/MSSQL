  
IF OBJECT_ID('mnpt_SPJTEEWorkReportWeightChgDlgSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEEWorkReportWeightChgDlgSave  
GO  
      
-- v2018.02.13
      
-- 작업물량변경-저장 by 이재천 
CREATE PROC mnpt_SPJTEEWorkReportWeightChgDlgSave  
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

    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        --------------------------------------------------------------------------------------------------
        --작업 - 물량수정하기, Srt
        --------------------------------------------------------------------------------------------------
        -- 계약-청구항목
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkReport')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTWorkReport'    , -- 테이블명        
                      '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                      'WorkReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE A
           SET BFMTWeight = B.TodayMTWeight, 
               BFCBMWeight = B.TodayCBMWeight
          FROM #BIZ_OUT_DataBlock1              AS A 
          LEFT OUTER JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
        
        UPDATE B   
           SET B.TodayMTWeight  = A.MTWeight,  
               B.TodayCBMWeight = A.CBMWeight, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq 
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkReport  AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq )  
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        --------------------------------------------------------------------------------------------------
        --작업 - 물량수정하기, End 
        --------------------------------------------------------------------------------------------------

        --------------------------------------------------------------------------------------------------
        --청구 - 물량수정하기, Srt
        --------------------------------------------------------------------------------------------------
        -- <영업>RT 계산용 CBM 곱하기 값
        DECLARE @RTCalc DECIMAL(19,5) 

        SELECT @RTCalc = EnvValue FROM mnpt_TComEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 17 

        SELECT B.IDX_NO, 
               B.Status, 
               B.DataSeq, 
               B.WorkingTag, 
               A.PJTSeq, 
               A.ShipSeq, 
               A.ShipSerl, 
               C.ItemSeq, 
               A.TodayMTWeight AS MTWeight, 
               A.TodayCBMWeight AS CBMWeight, 
               B.BFMTWeight, 
               B.BFCBMWeight
          INTO #mnpt_TPJTWorkReport 
          FROM mnpt_TPJTWorkReport      AS A 
          JOIN #BIZ_OUT_DataBlock1      AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
          JOIN mnpt_TPJTProjectMapping  AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq AND C.UMWorkType = A.UMWorkType ) 
         WHERE A.CompanySeq = @CompanySeq 
        


        SELECT A.IDX_NO, 
               A.Status, 
               A.DataSeq, 
               A.WorkingTag, 
               C.InvoiceSeq, 
               C.InvoiceSerl, 
               C.Qty1 - CASE WHEN E.UnitName = 'MT' THEN A.BFMTWeight - A.MTWeight
                            WHEN E.UnitName = 'CBM' THEN A.BFCBMWeight - A.CBMWeight
                            WHEN E.UnitName = 'RT' THEN (A.BFCBMWeight - A.CBMWeight) * @RTCalc 
                            ELSE 0 
                            END AS AddQty1
          INTO #TSLInvoiceItem
          FROM #mnpt_TPJTWorkReport             AS A 
          JOIN mnpt_TPJTLinkInvoiceItem         AS B ON ( B.CompanySeq = @CompanySeq 
                                                      AND B.PJTSeq = A.PJTSeq 
                                                      AND B.ShipSeq = A.ShipSeq 
                                                      AND B.ShipSerl = A.ShipSerl 
                                                      AND B.ItemSeq = A.ItemSeq 
                                                    )  
          
          LEFT OUTER JOIN mnpt_TSLInvoiceItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.InvoiceSeq = B.InvoiceSeq AND C.InvoiceSerl = B.InvoiceSerl ) 
          LEFT OUTER JOIN _TSLInvoiceItem       AS D ON ( D.CompanySeq = @CompanySeq AND D.InvoiceSeq = C.InvoiceSeq AND D.InvoiceSerl = C.InvoiceSerl ) 
          LEFT OUTER JOIN _TDAUnit              AS E ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = D.UnitSeq ) 
         WHERE C.UMExtraSeq = 0 -- 할증이 없는 물량만 변경
        
        -- 청구-물량변경
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TSLInvoiceItem')    
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TSLInvoiceItem'    , -- 테이블명        
                      '#TSLInvoiceItem'    , -- 임시 테이블명        
                      'InvoiceSeq, InvoiceSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE A
           SET Qty1 = AddQty1 
          FROM mnpt_TSLInvoiceItem  AS A 
          JOIN #TSLInvoiceItem      AS B ON ( B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag = 'U'   
           AND B.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        --------------------------------------------------------------------------------------------------
        --청구 - 물량수정하기, End 
        --------------------------------------------------------------------------------------------------
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

        , BFMTWeight DECIMAL(19, 5), BFCBMWeight DECIMAL(19, 5), MTWeight DECIMAL(19, 5), CBMWeight DECIMAL(19, 5), WorkReportSeq INT, PJTName NVARCHAR(200), PJTTypeName NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMLoadTypeName NVARCHAR(200)
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
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, BFMTWeight, BFCBMWeight, MTWeight, CBMWeight, WorkReportSeq, PJTName, PJTTypeName, UMWorkTypeName, UMLoadTypeName) 
SELECT N'U', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'700', N'700', N'600', N'600', N'493', NULL, NULL, NULL, NULL



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
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820137
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, BFMTWeight, BFCBMWeight, MTWeight, CBMWeight, WorkReportSeq, PJTName, PJTTypeName, UMWorkTypeName, UMLoadTypeName)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, BFMTWeight, BFCBMWeight, MTWeight, CBMWeight, WorkReportSeq, PJTName, PJTTypeName, UMWorkTypeName, UMLoadTypeName      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEWorkReportWeightChgDlgCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTEEWorkReportWeightChgDlgSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
        , Result, ROW_IDX, IsChangedMst, BFMTWeight, BFCBMWeight, MTWeight, CBMWeight, WorkReportSeq, PJTName, PJTTypeName, UMWorkTypeName, UMLoadTypeName  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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