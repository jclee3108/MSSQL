  
IF OBJECT_ID('hencom_SPNPLMatItemConvfactorSave') IS NOT NULL   
    DROP PROC hencom_SPNPLMatItemConvfactorSave  
GO  
  
-- v2017.06.01
  
-- 사업계획자재단중등록-저장 by 이재천
CREATE PROC hencom_SPNPLMatItemConvfactorSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TPNPLMatItemConvfactor (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNPLMatItemConvfactor'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TPNPLMatItemConvfactor')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TPNPLMatItemConvfactor'    , -- 테이블명        
                  '#hencom_TPNPLMatItemConvfactor'    , -- 임시 테이블명        
                  'CFSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLMatItemConvfactor WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_TPNPLMatItemConvfactor AS A   
          JOIN hencom_TPNPLMatItemConvfactor AS B ON ( B.CompanySeq = @CompanySeq AND A.CFSeq = B.CFSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLMatItemConvfactor WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ItemSeq        = A.ItemSeq, 
               B.ConvFactor     = A.ConvFactor, 
               B.ConvFactor     = A.Remark, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
                 
          FROM #hencom_TPNPLMatItemConvfactor AS A   
          JOIN hencom_TPNPLMatItemConvfactor AS B ON ( B.CompanySeq = @CompanySeq AND A.CFSeq = B.CFSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_TPNPLMatItemConvfactor WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_TPNPLMatItemConvfactor  
        (   
            CompanySeq, CFSeq, StdYear, DeptSeq, ItemSeq, 
            ConvFactor, Remark, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.CFSeq, A.StdYear, A.DeptSeq, A.ItemSeq, 
               A.ConvFactor, A.Remark, @UserSeq, GETDATE(), @PgmSeq
          FROM #hencom_TPNPLMatItemConvfactor AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #hencom_TPNPLMatItemConvfactor   
      
    RETURN  
