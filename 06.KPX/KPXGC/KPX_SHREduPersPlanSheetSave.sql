  
IF OBJECT_ID('KPX_SHREduPersPlanSheetSave') IS NOT NULL   
    DROP PROC KPX_SHREduPersPlanSheetSave  
GO  
  
-- v2015.04.14  
  
-- 교육계획등록(1sheet)-저장 by 이재천   
CREATE PROC KPX_SHREduPersPlanSheetSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_THREduPersPlanSheet (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THREduPersPlanSheet'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THREduPersPlanSheet')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THREduPersPlanSheet'    , -- 테이블명        
                  '#KPX_THREduPersPlanSheet'    , -- 임시 테이블명        
                  'PlanSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THREduPersPlanSheet WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_THREduPersPlanSheet AS A   
          JOIN KPX_THREduPersPlanSheet AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THREduPersPlanSheet WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PlanKindSeq = A.PlanKindSeq,  
               B.ExpectBegDate = A.ExpectBegDate,  
               B.ExpectEndDate = A.ExpectEndDate,  
               B.EmpSeq = A.EmpSeq,  
               B.EduCourseSeq = A.EduCourseSeq,  
               B.EduCenterSeq = A.EduCenterSeq,  
               B.EtcCourseName = A.EtcCourseName,  
               B.ExpectDd = A.ExpectDd,  
               B.ExpectTm = A.ExpectTm,  
               B.EduPoint = A.EduPoint,  
               B.ExpectCost = A.ExpectCost,  
               B.EduEffect = A.EduEffect,  
               B.EduObject = A.EduObject,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
                 
          FROM #KPX_THREduPersPlanSheet AS A   
          JOIN KPX_THREduPersPlanSheet AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THREduPersPlanSheet WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THREduPersPlanSheet  
        (   
            CompanySeq,PlanSeq,PlanKindSeq,ExpectBegDate,ExpectEndDate,  
            EmpSeq,EduCourseSeq,EduCenterSeq,EtcCourseName,ExpectDd,  
            ExpectTm,EduPoint,ExpectCost,EduEffect,EduObject,  
            LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.PlanSeq,A.PlanKindSeq,A.ExpectBegDate,A.ExpectEndDate,  
               A.EmpSeq,A.EduCourseSeq,A.EduCenterSeq,A.EtcCourseName,A.ExpectDd,  
               A.ExpectTm,A.EduPoint,A.ExpectCost,A.EduEffect,A.EduObject,  
               @UserSeq,GETDATE()   
          FROM #KPX_THREduPersPlanSheet AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_THREduPersPlanSheet   
      
    RETURN  