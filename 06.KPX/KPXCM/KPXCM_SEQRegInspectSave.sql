  
IF OBJECT_ID('KPXCM_SEQRegInspectSave') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectSave  
GO  
  
-- v2015.07.01  
  
-- 정기검사설비등록-저장 by 이재천   
CREATE PROC KPXCM_SEQRegInspectSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TEQRegInspect (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspect'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQRegInspect')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQRegInspect'    , -- 테이블명        
                  '#KPXCM_TEQRegInspect'    , -- 임시 테이블명        
                  'RegInspectSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspect WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQRegInspect AS A   
          JOIN KPXCM_TEQRegInspect AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspect WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ToolSeq = A.ToolSeq,  
               B.UMQCSeq = A.UMQCSeq,  
               B.UMQCCompany = A.UMQCCompany,  
               B.UMLicense = A.UMLicense,  
               B.EmpSeq = A.EmpSeq,  
               B.UMQCCycle = A.UMQCCycle,  
               B.LastQCDate = A.LastQCDate,  
               B.Spec = A.Spec,  
               B.QCNo = A.QCNo,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQRegInspect AS A   
          JOIN KPXCM_TEQRegInspect AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspect WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQRegInspect  
        (   
            CompanySeq,RegInspectSeq,ToolSeq,UMQCSeq,UMQCCompany,  
            UMLicense,EmpSeq,UMQCCycle,LastQCDate,Spec,  
            QCNo,LastUserSeq,LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.RegInspectSeq,A.ToolSeq,A.UMQCSeq,A.UMQCCompany,  
                 A.UMLicense,A.EmpSeq,A.UMQCCycle,A.LastQCDate,A.Spec,  
               A.QCNo,@UserSeq,GETDATE(),@PgmSeq   
          FROM #KPXCM_TEQRegInspect AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_TEQRegInspect   
      
    RETURN  