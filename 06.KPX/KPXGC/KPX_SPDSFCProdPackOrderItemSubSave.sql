  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemSubSave') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemSubSave  
GO  
  
-- v2014.11.25  
  
-- 포장작업지시입력-품목Sub 저장 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderItemSubSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDSFCProdPackOrderItemSub (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock4', '#KPX_TPDSFCProdPackOrderItemSub'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemSub')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItemSub'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrderItemSub'    , -- 임시 테이블명        
                  'PackOrderSeq,PackOrderSerl,PackOrderSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItemSub WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TPDSFCProdPackOrderItemSub AS A   
          JOIN KPX_TPDSFCProdPackOrderItemSub AS B ON ( B.CompanySeq = @CompanySeq 
                                                    AND A.PackOrderSeq = B.PackOrderSeq 
                                                    AND A.PackOrderSerl = B.PackOrderSerl 
                                                    AND A.PackOrderSubSerl = B.PackOrderSubSerl 
                                                      )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
          
    END   
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItemSub WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.InDate = A.InDate,  
               B.InQty = A.InQty, 
               B.Remark = A.Remark, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TPDSFCProdPackOrderItemSub AS A   
          JOIN KPX_TPDSFCProdPackOrderItemSub AS B ON ( B.CompanySeq = @CompanySeq 
                                                    AND A.PackOrderSeq = B.PackOrderSeq 
                                                    AND A.PackOrderSerl = B.PackOrderSerl 
                                                    AND A.PackOrderSubSerl = B.PackOrderSubSerl 
                                                      )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItemSub WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDSFCProdPackOrderItemSub  
        (   
            CompanySeq,PackOrderSeq,PackOrderSerl,PackOrderSubSerl,InDate,
            InQty,Remark,LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.PackOrderSeq, A.PackOrderSerl, A.PackOrderSubSerl, A.InDate,
               A.InQty, A.Remark, @UserSeq, GETDATE() 
          FROM #KPX_TPDSFCProdPackOrderItemSub AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPDSFCProdPackOrderItemSub   
    
    RETURN  
GO 
begin tran 
exec KPX_SPDSFCProdPackOrderItemSubSave @xmlDocument=N'<ROOT>
  <DataBlock4>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InDate>20140123</InDate>
    <InQty>13.00000</InQty>
    <PackOrderSubSerl>2</PackOrderSubSerl>
    <Remark />
    <PackOrderSeq>11</PackOrderSeq>
    <PackOrderSerl>3</PackOrderSerl>
  </DataBlock4>
  <DataBlock4>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <InDate>20141116</InDate>
    <InQty>123.00000</InQty>
    <PackOrderSubSerl>3</PackOrderSubSerl>
    <Remark />
    <PackOrderSeq>11</PackOrderSeq>
    <PackOrderSerl>3</PackOrderSerl>
  </DataBlock4>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
rollback 