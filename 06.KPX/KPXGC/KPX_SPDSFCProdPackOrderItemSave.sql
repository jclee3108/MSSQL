  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemSave') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemSave  
GO  
    
-- v2014.11.25  
    
-- 포장작업지시입력-품목 저장 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItem'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrderItem'    , -- 임시 테이블명        
                  'PackOrderSeq,PackOrderSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemCust')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPDSFCProdPackOrderItemCust'    , -- 테이블명        
                      '#KPX_TPDSFCProdPackOrderItem'    , -- 임시 테이블명        
                      'PackOrderSeq,PackOrderSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        DELETE B
          FROM #KPX_TPDSFCProdPackOrderItem AS A 
          JOIN KPX_TPDSFCProdPackOrderItemCust AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemSub')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TPDSFCProdPackOrderItemSub'    , -- 테이블명        
                      '#KPX_TPDSFCProdPackOrderItem'    , -- 임시 테이블명        
                      'PackOrderSeq,PackOrderSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
        DELETE B 
          FROM #KPX_TPDSFCProdPackOrderItem AS A 
          JOIN KPX_TPDSFCProdPackOrderItemSub AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ItemSeq = A.ItemSeq,  
               B.UnitSeq = A.UnitSeq, 
               B.OrderQty = A.OrderQty, 
               B.LotNo = A.LotNo, 
               B.UMDMMarking = A.UMDMMarking, 
               B.PackOnDate = A.PackOnDate, 
               B.PackReOnDate = A.PackReOnDate, 
               B.Remark = A.Remark, 
               B.SubItemSeq = A.SubItemSeq, 
               B.SubUnitSeq = A.SubUnitSeq, 
               B.SubQty = A.SubQty, 
               B.NonMarking = A.NonMarking, 
               B.PopInfo = A.PopInfo, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    
    DECLARE @WorkCenterSeq  INT 
    SELECT @WorkCenterSeq = (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 12 AND EnvSerl = 1) 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDSFCProdPackOrderItem  
        (   
            CompanySeq,PackOrderSeq,PackOrderSerl,ItemSeq,UnitSeq,
            OrderQty,LotNo,UMDMMarking,OutLotNo,PackOnDate,
            PackReOnDate,Remark,SubItemSeq,SubUnitSeq,SubQty,
            NonMarking,PopInfo,IsStop,WorkCenterSeq,LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.PackOrderSeq, A.PackOrderSerl, A.ItemSeq, A.UnitSeq, 
                A.OrderQty, A.LotNo, A.UMDMMarking, A.OutLotNo, A.PackOnDate, 
                A.PackReOnDate, A.Remark, A.SubItemSeq, A.SubUnitSeq, A.SubQty, 
                A.NonMarking, A.PopInfo, A.IsStop, ISNULL(@WorkCenterSeq,0), @UserSeq, GETDATE()
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem   
      
    RETURN  
GO 

BEGIN TRAN 
exec KPX_SPDSFCProdPackOrderItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <BrandName />
    <IsStop>0</IsStop>
    <ItemSeq>27261</ItemSeq>
    <LotNo />
    <NonMarking>3</NonMarking>
    <OrderQty>3.00000</OrderQty>
    <OutLotNo>test</OutLotNo>
    <PackOnDate xml:space="preserve">        </PackOnDate>
    <PackOrderSeq>11</PackOrderSeq>
    <PackOrderSerl>3</PackOrderSerl>
    <PackReOnDate>20141115</PackReOnDate>
    <PopInfo>4</PopInfo>
    <Remark />
    <SubItemSeq>27262</SubItemSeq>
    <SubQty>0.00000</SubQty>
    <SubUnitSeq>2</SubUnitSeq>
    <UMDMMarking>1010344001</UMDMMarking>
    <UnitSeq>2</UnitSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
rollback 