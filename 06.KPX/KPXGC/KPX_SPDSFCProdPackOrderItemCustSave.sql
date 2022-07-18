  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemCustSave') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemCustSave  
GO  
  
-- v2014.11.25  
  
-- 포장작업지시입력-거래처 저장 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderItemCustSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDSFCProdPackOrderItemCust (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDSFCProdPackOrderItemCust'   
    IF @@ERROR <> 0 RETURN    
    
    
    IF EXISTS (SELECT 1 FROM #KPX_TPDSFCProdPackOrderItemCust WHERE ISNULL(PackOrderSeq,0) <> 0) 
    BEGIN 
        
        -- 로그 남기기    
        DECLARE @TableColumns NVARCHAR(4000)    
          
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemCust')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPDSFCProdPackOrderItemCust'    , -- 테이블명        
                      '#KPX_TPDSFCProdPackOrderItemCust'    , -- 임시 테이블명        
                      'PackOrderSeq,PackOrderSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        -- UPDATE      
        IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItemCust WHERE WorkingTag = 'U' AND Status = 0 )    
        BEGIN  
            UPDATE B   
               SET B.CustSeq = A.CustSeq,  
                   B.OutDate = A.OutDate, 
                   B.ReOutDate = A.ReOutDate, 
                   B.LastUserSeq  = @UserSeq,  
                   B.LastDateTime = GETDATE()
            
              FROM #KPX_TPDSFCProdPackOrderItemCust AS A   
              JOIN KPX_TPDSFCProdPackOrderItemCust AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
             WHERE A.WorkingTag = 'U'   
               AND A.Status = 0      
            
            IF @@ERROR <> 0  RETURN  
              
        END    
        
        -- INSERT  
        IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItemCust WHERE WorkingTag = 'A' AND Status = 0 )    
        BEGIN    
            INSERT INTO KPX_TPDSFCProdPackOrderItemCust  
            (   
                CompanySeq,PackOrderSeq,PackOrderSerl,CustSeq,OutDate,
                ReOutDate,LastUserSeq,LastDateTime
            )   
            SELECT @CompanySeq, A.PackOrderSeq, A.PackOrderSerl, A.CustSeq, A.OutDate,
                   A.ReOutDate, @UserSeq, GETDATE()
              FROM #KPX_TPDSFCProdPackOrderItemCust AS A   
             WHERE A.WorkingTag = 'A'   
               AND A.Status = 0      
              
            IF @@ERROR <> 0 RETURN  
              
        END     
        
    END 
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItemCust   
      
    RETURN  
GO 
begin tran 
exec KPX_SPDSFCProdPackOrderItemCustSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <CustSeq>0</CustSeq>
    <OutDate xml:space="preserve">        </OutDate>
    <ReOutDate xml:space="preserve">        </ReOutDate>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
rollback 