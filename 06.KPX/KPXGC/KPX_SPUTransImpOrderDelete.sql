  
IF OBJECT_ID('KPX_SPUTransImpOrderDelete') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderDelete  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시-저장 by 이재천   
CREATE PROC KPX_SPUTransImpOrderDelete  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPUTransImpOrder (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUTransImpOrder'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrder')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrder'    , -- 테이블명        
                  '#KPX_TPUTransImpOrder'    , -- 임시 테이블명        
                  'TransImpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
    DELETE B 
      FROM #KPX_TPUTransImpOrder AS A 
      JOIN KPX_TPUTransImpOrder  AS B ON ( B.CompanySeq = @CompanySeq AND B.TransImpSeq = A.TransImpSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    -- 시트 로그 
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrderItem'    , -- 테이블명        
                  '#KPX_TPUTransImpOrder'    , -- 임시 테이블명        
                  'TransImpSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    
    DELETE B 
      FROM #KPX_TPUTransImpOrder    AS A 
      JOIN KPX_TPUTransImpOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.TransImpSeq = A.TransImpSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    SELECT * FROM #KPX_TPUTransImpOrder
    
    RETURN 