  
IF OBJECT_ID('KPXCM_SHREduRstWithCostSave') IS NOT NULL   
    DROP PROC KPXCM_SHREduRstWithCostSave
GO  
  
-- v2016.06.13  
  
-- 교육결과등록-저장 by 이재천   
CREATE PROC KPXCM_SHREduRstWithCostSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_THREduPersRst (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_THREduPersRst'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_THREduPersRst')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_THREduPersRst'    , -- 테이블명        
                  '#KPXCM_THREduPersRst'    , -- 임시 테이블명        
                  'RstSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_THREduPersRst WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_THREduPersRst AS A   
          JOIN KPXCM_THREduPersRst AS B ON ( B.CompanySeq = @CompanySeq AND B.RstSeq = A.RstSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_THREduPersRst WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.RegDate = A.RegDate,  
               B.RstNo = A.RstNo,  
               B.EmpSeq = A.EmpSeq,  
               B.UMEduGrpType = A.UMEduGrpType,  
               B.EduClassSeq = A.EduClassSeq,  
               B.EduCourseName = A.EduCourseName,  
               B.EduTypeSeq = A.EduTypeSeq,  
               B.EtcCourseName = A.EtcCourseName,  
               B.SMInOutType = A.SMInOutType,  
               B.EduBegDate = A.EduBegDate,  
               B.EduEndDate = A.EduEndDate,  
               B.EduDd = A.EduDd,  
               B.EduTm = A.EduTm,  
               B.EduPoint = A.EduPoint,  
               B.IsEI = A.IsEI,  
               B.SMComplate = A.SMComplate,  
               B.RstCost = A.RstCost,  
               B.ReturnAmt = A.ReturnAmt,  
               B.RstSummary = A.RstSummary,  
               B.RstRem = A.RstRem,  
               B.UMEduCost = A.UMEduCost,  
               B.UMEduReport = A.UMEduReport,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_THREduPersRst AS A   
          JOIN KPXCM_THREduPersRst AS B ON ( B.CompanySeq = @CompanySeq AND B.RstSeq = A.RstSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
  END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_THREduPersRst WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_THREduPersRst  
        (   
            CompanySeq,RstSeq,RegDate,RstNo,EmpSeq,  
            UMEduGrpType,EduClassSeq,EduCourseName,EduTypeSeq,EtcCourseName,  
            SMInOutType,EduBegDate,EduEndDate,EduDd,EduTm,  
            EduPoint,IsEI,SMComplate,RstCost,ReturnAmt,  
            RstSummary,RstRem,UMEduCost,UMEduReport,LastUserSeq,  
            LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.RstSeq,A.RegDate,A.RstNo,A.EmpSeq,  
               A.UMEduGrpType,A.EduClassSeq,A.EduCourseName,A.EduTypeSeq,A.EtcCourseName,  
               A.SMInOutType,A.EduBegDate,A.EduEndDate,A.EduDd,A.EduTm,  
               A.EduPoint,A.IsEI,A.SMComplate,A.RstCost,A.ReturnAmt,  
               A.RstSummary,A.RstRem,A.UMEduCost,A.UMEduReport,@UserSeq,  
               GETDATE(),@PgmSeq   
          FROM #KPXCM_THREduPersRst AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_THREduPersRst   
      
    RETURN  