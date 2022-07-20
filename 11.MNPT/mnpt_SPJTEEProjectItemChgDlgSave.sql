  
IF OBJECT_ID('mnpt_SPJTEEProjectItemChgDlgSave') IS NOT NULL   
    DROP PROC mnpt_SPJTEEProjectItemChgDlgSave  
GO  
      
-- v2018.02.12
      
-- 청구항목변경-저장 by 이재천 
CREATE PROC mnpt_SPJTEEProjectItemChgDlgSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS    
    
    --select '_TPJTProjectDelivery', 1, ItemSeq from _TPJTProjectDelivery where pjtseq = 424 and delvserl = 2 
    --select 'mnpt_TPJTProjectMapping', 1, ItemSeq from mnpt_TPJTProjectMapping where pjtseq = 424 
    --select 'mnpt_TPJTLinkInvoiceItem', 1, ItemSeq from mnpt_TPJTLinkInvoiceItem where pjtseq = 424 and invoiceserl = 2 
    --select '_TSLInvoiceItem', 1, ItemSeq from _TSLInvoiceItem where invoiceseq = 630 and invoiceserl = 2 
    --select '_TSLSalesItem', 1, ItemSeq from _TSLSalesItem where SalesSeq = 135 and SalesSErl = 2 

    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        -- 로그 남기기    
        DECLARE @TableColumns NVARCHAR(4000)    

        -- 계약 Mapping
        SELECT A.PJTSeq, A.MappingSerl, B.ItemSeqOld, B.ItemSeq, B.WorkingTag, B.IDX_NO, B.DataSeq, B.Status
          INTO #MappingLog 
          FROM mnpt_TPJTProjectMapping  AS A 
          JOIN ( 
                SELECT Z.PJTSeq, Z.ItemSeq AS ItemSeqOld, Y.ItemSeq, Y.WorkingTag, Y.IDX_NO, Y.DataSeq, Y.Status
                  FROM _TPJTProjectDelivery AS Z 
                  JOIN #BIZ_OUT_DataBlock1  AS Y ON ( Y.PJTSeq = Z.PJTSeq AND Y.DelvSerl = Z.DelvSerl )
                 WHERE Z.CompanySeq = @CompanySeq 
               ) AS B ON ( B.PJTSeq = A.PJTSeq AND B.ItemSeqOld = A.ItemSeq ) 
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTProjectMapping')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTProjectMapping'    , -- 테이블명        
                      '#MappingLog'    , -- 임시 테이블명        
                      'PJTSeq,MappingSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM mnpt_TPJTProjectMapping  AS A 
          JOIN #MappingLog              AS B ON ( B.PJTSeq = A.PJTSeq AND B.MappingSerl = A.MappingSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag = 'U' 
           AND B.Status = 0 

        -- 계약-청구항목
        SELECT @TableColumns = dbo._FGetColumnsForLog('_TPJTProjectDelivery')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      '_TPJTProjectDelivery'    , -- 테이블명        
                      '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                      'PJTSeq,DelvSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

        UPDATE B   
           SET B.ItemSeq        = A.ItemSeq,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE() 
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN _TPJTProjectDelivery AS B ON ( B.CompanySeq = @CompanySeq AND A.PJTseq = B.PJTseq AND A.DelvSerl = B.DelvSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          

        -- 청구-청구항목
        SELECT B.InvoiceSeq, B.InvoiceSerl, A.ItemSeqOld, A.ItemSeq, A.WorkingTag, A.IDX_NO, A.DataSeq, A.Status
          INTO #InvoiceItemLog 
          FROM #MappingLog              AS A 
          JOIN mnpt_TPJTLinkInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ItemSeq = A.ItemSeqOld ) 
                
        -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
        EXEC _SCOMLog  @CompanySeq   ,
                       @UserSeq      ,
                       '_TSLInvoiceItem', -- 원테이블명
                       '#InvoiceItemLog', -- 템프테이블명
                       'InvoiceSeq, InvoiceSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                       'CompanySeq, InvoiceSeq, InvoiceSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT,
                        STDUnitSeq, STDQty, WHSeq, Remark, UMEtcOutKind, TrustCustSeq, LotNo, SerialNo, PJTSeq, WBSSeq, CCtrSeq, LastUserSeq, LastDateTime,Price,PgmSeq,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy7,Dummy8,Dummy9,Dummy10',
                       '', @PgmSeq 
        --return 
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM _TSLInvoiceItem  AS A 
          JOIN #InvoiceItemLog  AS B ON ( B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 

        -- 청구-Link
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTLinkInvoiceItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTLinkInvoiceItem'    , -- 테이블명        
                      '#InvoiceItemLog'    , -- 임시 테이블명        
                      'InvoiceSeq,InvoiceSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE A
           SET ItemSeq = B.ItemSeq 
          FROM mnpt_TPJTLinkInvoiceItem AS A 
          JOIN #InvoiceItemLog          AS B ON ( B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
         WHERE A.CompanySeq = @CompanySeq 

        -- 매출-청구항목
        CREATE TABLE #InvoiceProg 
        ( 
            IDX_NO      INT IDENTITY, 
            InvoiceSeq  INT, 
            InvoiceSerl INT, 
            ItemSeq     INT, 
            WorkingTag  NCHAR(1), 
            DataSeq     INT, 
            Status      INT 
        )   
        INSERT INTO #InvoiceProg ( InvoiceSeq, InvoiceSerl, ItemSeq, WorkingTag, DataSeq, Status ) 
        SELECT InvoiceSeq, InvoiceSerl, ItemSeq, WorkingTag, DataSeq, Status 
          FROM #InvoiceItemLog 

        CREATE TABLE #TMP_ProgressTable 
        (
            IDOrder   INT, 
            TableName NVARCHAR(100)
        ) 

        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
        SELECT 1, '_TSLSalesItem'   -- 데이터 찾을 테이블
        
        CREATE TABLE #TCOMProgressTracking
        (
            IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)
        ) 
 
        EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TSLInvoiceItem',    -- 기준이 되는 테이블
            @TempTableName = '#InvoiceProg',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'InvoiceSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'InvoiceSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
        

        SELECT A.*, C.SalesSeq, C.SalesSerl 
          INTO #SalesItemLog 
          FROM #InvoiceProg             AS A 
          JOIN #TCOMProgressTracking    AS B ON ( B.IDX_NO = A.IDX_NO ) 
          JOIN _TSLSalesItem            AS C ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.Seq AND C.SalesSerl = B.Serl ) 
        
        -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
        EXEC _SCOMLog  @CompanySeq   ,
                       @UserSeq      ,
                       '_TSLSalesItem', -- 원테이블명
                       '#SalesItemLog', -- 템프테이블명
                       'SalesSeq, SalesSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                       'CompanySeq, SalesSeq, SalesSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT, STDUnitSeq, STDQty, WHSeq, 
                        Remark, AccSeq, VATSeq, OppAccSeq, LotNo, SerialNo, MngSalesSerl, IsSetItem, PJTSeq, WBSSeq, CustSeq, DeptSeq, EmpSeq, LastUserSeq, LastDateTime, Price, PgmSeq', 
                       '', @PgmSeq 
        
        UPDATE A 
           SET ItemSeq = B.ItemSeq, 
               AccSeq = D.AccSeq 
          FROM _TSLSalesItem                AS A 
                     JOIN #SalesItemLog     AS B ON ( B.SalesSeq = A.SalesSeq AND B.SalesSerl = A.SalesSerl ) 
          LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
          LEFT OUTER JOIN _TDAItemAssetAcc  AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq AND D.AssetAccKindSeq = 2 ) 
         WHERE A.CompanySeq = @CompanySeq 
    END    

    --select '_TPJTProjectDelivery', 2, ItemSeq from _TPJTProjectDelivery where pjtseq = 424 and delvserl = 2 
    --select 'mnpt_TPJTProjectMapping', 2, ItemSeq from mnpt_TPJTProjectMapping where pjtseq = 424 
    --select 'mnpt_TPJTLinkInvoiceItem', 2, ItemSeq from mnpt_TPJTLinkInvoiceItem where pjtseq = 424 and invoiceserl = 2 
    --select '_TSLInvoiceItem', 2, ItemSeq from _TSLInvoiceItem where invoiceseq = 630 and invoiceserl = 2 
    --select '_TSLSalesItem', 2, ItemSeq from _TSLSalesItem where SalesSeq = 135 and SalesSErl = 2 

    
    --select * from _TPJTProjectDeliveryLog where pjtseq = 424 and delvserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from mnpt_TPJTProjectMappingLog where pjtseq = 424 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from mnpt_TPJTLinkInvoiceItemLog where pjtseq = 424 and invoiceserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from _TSLInvoiceItemLog where invoiceseq = 630 and invoiceserl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'
    --select * from _TSLSalesItemLog where SalesSeq = 135 and SalesSErl = 2 and LogUserSeq = 167 and LogDateTime > '20180212'


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

        , ItemName NVARCHAR(200), ItemSeq INT, PJTSeq INT, DelvSerl INT, PJTName NVARCHAR(200), ItemNameOld NVARCHAR(200), ItemSeqOld INT
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

        , ItemName NVARCHAR(200), ItemSeq INT, PJTSeq INT, DelvSerl INT, PJTName NVARCHAR(200), ItemNameOld NVARCHAR(200), ItemSeqOld INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld) 
SELECT N'U', 2, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'보관료월분할', N'533', N'424', N'2', NULL, N'보관료테스트.', N'517'



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

SET @ServiceSeq     = 13820156
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820136
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEProjectItemChgDlgCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTEEProjectItemChgDlgSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
        , Result, ROW_IDX, IsChangedMst, ItemName, ItemSeq, PJTSeq, DelvSerl, PJTName, ItemNameOld, ItemSeqOld  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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