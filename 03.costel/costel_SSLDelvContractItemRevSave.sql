  
IF OBJECT_ID('costel_SSLDelvContractItemRevSave') IS NOT NULL   
    DROP PROC costel_SSLDelvContractItemRevSave  
GO  

-- v2013.09.06    
    
-- 납품계약등록_costel(차수품목등록) by이재천     
CREATE PROC costel_SSLDelvContractItemRevSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    CREATE TABLE #costel_TSLDelvContractItemRev (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItemRev'     
    IF @@ERROR <> 0 RETURN      
  
    -- INSERT    
    
        INSERT INTO costel_TSLDelvContractItemRev    
        (     
            CompanySeq, ContractSeq, ContractSerl, ContractRev, DelvExpectDate,   
            ChgDelvExpectDate, ItemSeq, UnitSeq, DelvQty, DelvPrice,   
            DelvCurAmt, DelvCurVAT, DelvCustSeq, SalesExpectDate, Remark,   
            ChangeReason, CollectExpectDate, LastUserSeq, LastDateTime   
        )     
          
        SELECT @CompanySeq, 30, A.ContractSerl, C.ContractRev - 1 , A.DelvExpectDate,   
               A.ChangeDeliveyDate, A.ItemSeq, A.UnitSeq, A.DelvQty, A.DelvPrice,   
               A.DelvAmt, A.DelvVatAmt, A.DelvCustSeq, A.SalesExpectDate, A.Remark,   
               A.ChangeReason, A.ExpReceiptDate, @UserSeq, GETDATE()  
          FROM #costel_TSLDelvContractItemRev AS A    
          JOIN costel_TSLDelvContractItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
          JOIN costel_TSLDelvContract     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = B.ContractSeq )   
          
        IF @@ERROR <> 0 RETURN    
      
        --DELETE   
        DELETE B  
          FROM #costel_TSLDelvContractItemRev AS A  
          JOIN costel_TSLDelvContractItem     AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
            
        UPDATE A  
           SET ContractRev = B.ContractRev  
          FROM #costel_TSLDelvContractItemRev AS A   
          JOIN costel_TSLDelvContract         AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
  
        DECLARE @MaxRev INT  
        SELECT @MaxRev = (  
                         SELECT MAX(B.ContractRev)   
                           FROM #costel_TSLDelvContractItemRev AS A   
                           JOIN costel_TSLDelvContractItemRev  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )   
                         )  
      
        INSERT INTO costel_TSLDelvContractItem    
        (     
            CompanySeq, ContractSeq, ContractSerl, DelvExpectDate, ChgDelvExpectDate,  
            ItemSeq, UnitSeq, DelvQty, DelvPrice, DelvCurAmt,  
            DelvCurVAT, DelvCustSeq, SalesExpectDate, Remark, ChangeReason,  
            CollectExpectDate, LastUserSeq, LastDateTime  
        )     
        SELECT @CompanySeq, A.ContractSeq, A.ContractSerl, A.DelvExpectDate, A.ChangeDeliveyDate,  
               A.ItemSeq, A.UnitSeq, A.DelvQty, A.DelvPrice, A.DelvAmt,  
               A.DelvVatAmt, A.DelvCustSeq, A.SalesExpectDate, A.Remark, A.ChangeReason,  
               A.ExpReceiptDate, @UserSeq, GETDATE()  
          FROM #costel_TSLDelvContractItemRev AS A     
          
        IF @@ERROR <> 0 RETURN    
      
    SELECT * FROM #costel_TSLDelvContractItemRev     
        
    RETURN    