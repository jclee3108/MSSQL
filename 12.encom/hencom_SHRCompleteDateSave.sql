  
IF OBJECT_ID('hencom_SHRCompleteDateSave') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateSave  
GO  
    
-- v2017.07.27
  
-- 완료일관리-저장 by 이재천   
CREATE PROC hencom_SHRCompleteDateSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_THRCompleteDate (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_THRCompleteDate'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_THRCompleteDate')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_THRCompleteDate'    , -- 테이블명        
                  '#hencom_THRCompleteDate'    , -- 임시 테이블명        
                  'CompleteSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDate WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #hencom_THRCompleteDate AS A   
          JOIN hencom_THRCompleteDate AS B ON ( B.CompanySeq = @CompanySeq AND A.CompleteSeq = B.CompleteSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

        DELETE B   
          FROM #hencom_THRCompleteDate AS A   
          JOIN hencom_THRCompleteDateShare AS B ON ( B.CompanySeq = @CompanySeq AND A.CompleteSeq = B.CompleteSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  

    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDate WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMCompleteType    = A.UMCompleteType ,  
               B.DeptSeq           = A.DeptSeq        ,  
               B.ManagementAmt     = A.ManagementAmt  ,  
               B.AlarmDay          = A.AlarmDay       ,  
               B.SrtDate           = A.SrtDate        ,  
               B.EndDate           = A.EndDate        ,  
               B.Remark            = A.Remark         ,   
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #hencom_THRCompleteDate AS A   
          JOIN hencom_THRCompleteDate AS B ON ( B.CompanySeq = @CompanySeq AND A.CompleteSeq = B.CompleteSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #hencom_THRCompleteDate WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO hencom_THRCompleteDate  
        (   
            CompanySeq, CompleteSeq, UMCompleteType, DeptSeq, ManagementAmt, 
            AlarmDay, SrtDate, EndDate, Remark, LastUserSeq, 
            LastDateTime, PgmSeq 
        )   
        SELECT @CompanySeq, CompleteSeq, UMCompleteType, DeptSeq, ManagementAmt, 
               AlarmDay, SrtDate, EndDate, Remark, @UserSeq, 
               GETDATE(), @PgmSeq 
          FROM #hencom_THRCompleteDate AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #hencom_THRCompleteDate   
      
    RETURN  
