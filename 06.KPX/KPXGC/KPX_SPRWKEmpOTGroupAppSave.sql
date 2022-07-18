  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppSave') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppSave  
GO  
  
-- v2014.12.17  
  
-- OT일괄신청-저장 by 이재천   
CREATE PROC KPX_SPRWKEmpOTGroupAppSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TPRWKEmpOTGroupApp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPRWKEmpOTGroupApp'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPRWKEmpOTGroupApp')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPRWKEmpOTGroupApp'    , -- 테이블명        
                  '#KPX_TPRWKEmpOTGroupApp'    , -- 임시 테이블명        
                  'GroupAppSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
          JOIN KPX_TPRWKEmpOTGroupApp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE       
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN    
        UPDATE B
           SET BaseDate = A.BaseDate, 
               LastUserSeq = @UserSeq, 
               LastDateTime = GETDATE()
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
          JOIN KPX_TPRWKEmpOTGroupApp AS B ON ( B.CompanySeq = @CompanySeq AND B.GroupAppSeq = A.GroupAppSeq )   
    END 
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPRWKEmpOTGroupApp WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TPRWKEmpOTGroupApp  
        (   
            CompanySeq,GroupAppSeq,BaseDate,GroupAppNo,LastUserSeq,  
            LastDateTime   
        )   
        SELECT @CompanySeq,A.GroupAppSeq,A.BaseDate,A.GroupAppNo,@UserSeq,  
               GETDATE()   
          FROM #KPX_TPRWKEmpOTGroupApp AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TPRWKEmpOTGroupApp   
      
    RETURN  