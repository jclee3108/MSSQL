  
IF OBJECT_ID('costel_SSLDelvContractItemSave') IS NOT NULL   
    DROP PROC costel_SSLDelvContractItemSave  
GO  
  
-- v2013.09.06 
  
-- 납품계약등록_costel(품목저장) by이재천   
CREATE PROC costel_SSLDelvContractItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #costel_TSLDelvContractItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItem'   
    IF @@ERROR <> 0 RETURN    
      --select * from #costel_TSLDelvContractItem
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Item 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('costel_TSLDelvContractItem')    
    
    EXEC _SCOMDeleteLog @CompanySeq     ,      
                        @UserSeq        ,      
                        'costel_TSLDelvContractItem'  ,     
                        '#costel_TSLDelvContractItem'      ,     
                        'ContractSeq,ContractSerl'     , -- CompanySeq제외 한 키     
                        @TableColumns   , '', @PgmSeq     
      
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF @WorkingTag = 'Delete' 
    BEGIN
        IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContractItem WHERE WorkingTag = 'D' AND Status = 0 )    
        BEGIN 
            DELETE B   
              FROM #costel_TSLDelvContractItem AS A   
              JOIN costel_TSLDelvContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq ) --AND A.ContractSerl = B.ContractSerl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN  
        END    
    END
    
    ELSE
    BEGIN
        IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContractItem WHERE WorkingTag = 'D' AND Status = 0 )    
        BEGIN 
            DELETE B   
              FROM #costel_TSLDelvContractItem AS A   
              JOIN costel_TSLDelvContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq AND A.ContractSerl = B.ContractSerl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0 
        
            IF @@ERROR <> 0  RETURN  
        END    
    
    END
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContractItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.DelvExpectDate      = A.DelvExpectDate    ,
               B.ChgDelvExpectDate   = A.ChangeDeliveyDate ,
               B.ItemSeq             = A.ItemSeq           ,
               B.UnitSeq             = A.UnitSeq           ,
               B.DelvQty             = A.DelvQty           ,
               B.DelvPrice           = A.DelvPrice         ,
               B.DelvCurAmt          = A.DelvAmt        ,
               B.DelvCurVAT          = A.DelvVATAmt        ,
               B.SalesExpectDate     = A.SalesExpectDate   ,
               B.Remark              = A.Remark            ,
               B.ChangeReason        = A.ChangeReason      ,
               B.CollectExpectDate   = A.ExpReceiptDate ,
               B.LastUserSeq         = @UserSeq            ,
               B.LastDateTime        = GETDATE()        
          FROM #costel_TSLDelvContractItem AS A   
          JOIN costel_TSLDelvContractItem AS B ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq AND A.ContractSerl = B.ContractSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #costel_TSLDelvContractItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO costel_TSLDelvContractItem  
        (   
            CompanySeq, ContractSeq, ContractSerl, DelvExpectDate, ChgDelvExpectDate,
            ItemSeq, UnitSeq, DelvQty, DelvPrice, DelvCurAmt,
            DelvCurVAT,SalesExpectDate, Remark, ChangeReason, CollectExpectDate, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.ContractSeq, A.ContractSerl, A.DelvExpectDate, A.ChangeDeliveyDate,
               A.ItemSeq, A.UnitSeq, A.DelvQty, A.DelvPrice, A.DelvAmt,
               A.DelvVatAmt, A.SalesExpectDate, A.Remark, A.ChangeReason, A.ExpReceiptDate, 
               @UserSeq, GETDATE()
          FROM #costel_TSLDelvContractItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #costel_TSLDelvContractItem   
      
    RETURN  
GO
BEGIN TRAN
exec costel_SSLDelvContractItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ChangeDeliveyDate>20130913</ChangeDeliveyDate>
    <ChangeReason />
    <DelvAmt>0.00000</DelvAmt>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <DelvExpectDate>20130912</DelvExpectDate>
    <DelvPrice>0.00000</DelvPrice>
    <DelvQty>0.00000</DelvQty>
    <DelvVatAmt>0.00000</DelvVatAmt>
    <ItemName>@공장건축공사</ItemName>
    <ItemNo>200901010001</ItemNo>
    <ItemSeq>14033</ItemSeq>
    <Remark />
    <SalesExpectDate />
    <Sel>0</Sel>
    <Spec />
    <SumDelvAmt>0.00000</SumDelvAmt>
    <UnitName>EA</UnitName>
    <UnitSeq>2</UnitSeq>
    <ContractSeq>17</ContractSeq>
    <ContractSerl>4</ContractSerl>
    <ExpReceiptDate />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985
ROLLBACK TRAN
