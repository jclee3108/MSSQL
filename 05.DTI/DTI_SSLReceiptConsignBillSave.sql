
IF OBJECT_ID('DTI_SSLReceiptConsignBillSave') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignBillSave
GO

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁세금계산서연결저장) by이재천
CREATE PROCEDURE DTI_SSLReceiptConsignBillSave  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    DECLARE @docHandle  INT  
    
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #DTI_TSLReceiptConsignBill (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TSLReceiptConsignBill'    
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   'DTI_TSLReceiptConsignBill', -- 원테이블명    
                   '#DTI_TSLReceiptConsignBill', -- 템프테이블명    
                   'ReceiptSeq,BillSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,ReceiptSeq,BillSeq,CurAmt,DomAmt,LastUserSeq,LastDateTime,PgmSeq','',@PgmSeq  
    
    -- DELETE      
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignBill WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
        -- 계산서입금관계  
        DELETE _TSLReceiptBill    
          FROM #DTI_TSLReceiptConsignBill   AS A    
          JOIN DTI_TSLReceiptConsignBill    AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq AND B.BillSeq = A.BillSeq ) 
         WHERE A.WorkingTag = 'D' AND A.Status = 0     
        
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END     
    END    
    
    -- Update      
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignBill WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        UPDATE B    
           SET DomAmt = A.DomAmt,  
               CurAmt = A.CurAmt,  
               LastUserSeq  = @UserSeq,     
               LastDateTime = GETDATE(),  
               PgmSeq       = @PgmSeq  
          FROM #DTI_TSLReceiptConsignBill AS A    
          JOIN DTI_TSLReceiptConsignBill  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptSeq = A.ReceiptSeq AND B.BillSeq = A.BillSeq ) 
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
        
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    
    END    
    
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignBill WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO DTI_TSLReceiptConsignBill(
                                                CompanySeq, ReceiptSeq, BillSeq, CurAmt, DomAmt, 
                                                LastUserSeq, LastDateTime, PgmSeq    
                                             )
        SELECT @CompanySeq, ReceiptSeq, BillSeq, CurAmt, DomAmt,  
               @UserSeq, GETDATE(), @PgmSeq  
          FROM #DTI_TSLReceiptConsignBill A    
         WHERE WorkingTag = 'A' AND Status = 0  
        
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END       
    END        
    
    SELECT * FROM #DTI_TSLReceiptConsignBill    
    
    RETURN 