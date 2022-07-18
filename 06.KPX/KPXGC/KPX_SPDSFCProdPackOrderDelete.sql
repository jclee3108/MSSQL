  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderDelete') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderDelete  
GO  
  
-- v2014.11.25
  
-- 포장작업지시입력-삭제 by이재천   
CREATE PROC KPX_SPDSFCProdPackOrderDelete  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TPDSFCProdPackOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrder'   
    IF @@ERROR <> 0 RETURN        
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrder')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrder'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrder'    , -- 임시 테이블명        
                  'PackOrderSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    DELETE B
      FROM #KPX_TPDSFCProdPackOrder AS A 
      JOIN KPX_TPDSFCProdPackOrder  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
       
    
    -- KPX_TPDSFCProdPackOrderItem 삭제 
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItem'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrder'    , -- 임시 테이블명        
                  'PackOrderSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    DELETE B
      FROM #KPX_TPDSFCProdPackOrder AS A 
      JOIN KPX_TPDSFCProdPackOrderItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
    
    
    
    -- KPX_TPDSFCProdPackOrderItemCust 삭제 
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemCust')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItemCust'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrder'    , -- 임시 테이블명        
                  'PackOrderSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    DELETE B
      FROM #KPX_TPDSFCProdPackOrder AS A 
      JOIN KPX_TPDSFCProdPackOrderItemCust  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
    
    -- KPX_TPDSFCProdPackOrderItemSub 삭제 
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItemSub')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItemSub'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrder'    , -- 임시 테이블명        
                  'PackOrderSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    DELETE B
      FROM #KPX_TPDSFCProdPackOrder AS A 
      JOIN KPX_TPDSFCProdPackOrderItemSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
    
    SELECT * FROM #KPX_TPDSFCProdPackOrder   
      
    RETURN  
GO 
begin tran 
exec KPX_SPDSFCProdPackOrderDelete @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <IsCfm>0</IsCfm>
    <PackOrderSeq>11</PackOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349
rollback 