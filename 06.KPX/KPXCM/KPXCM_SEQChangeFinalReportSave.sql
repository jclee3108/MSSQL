  
IF OBJECT_ID('KPXCM_SEQChangeFinalReportSave') IS NOT NULL   
    DROP PROC KPXCM_SEQChangeFinalReportSave  
GO  
  
-- v2015.06.12  
  
-- 변경실행결과등록-저장 by 이재천   
CREATE PROC KPXCM_SEQChangeFinalReportSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TEQChangeFinalReport (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQChangeFinalReport'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQChangeFinalReport')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQChangeFinalReport'    , -- 테이블명        
                  '#KPXCM_TEQChangeFinalReport'    , -- 임시 테이블명        
                  'FinalReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQChangeFinalReport WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQChangeFinalReport AS A   
          JOIN KPXCM_TEQChangeFinalReport AS B ON ( B.CompanySeq = @CompanySeq AND B.FinalReportSeq = A.FinalReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQChangeFinalReport WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.FinalReportDate    = A.FinalReportDate      ,  
               B.ResultDateFr       = A.ResultDateFr        ,  
               B.ResultDateTo       = A.ResultDateTo        ,  
               B.FinalReportDeptSeq = A.FinalReportDeptSeq  ,  
               B.FinalReportEmpSeq  = A.FinalReportEmpSeq   ,  
               B.ResultRemark       = A.ResultRemark        ,  
               B.IsPID              = A.IsFinalPID          , 
               B.IsPFD              = A.IsFinalPFD          ,  
               B.IsLayOut           = A.IsFinalLayOut       ,  
               B.IsProposal         = A.IsFinalProposal     ,  
               B.IsReport           = A.IsFinalReport       ,  
               B.IsMinutes          = A.IsFinalMinutes      ,  
               B.IsReview           = A.IsFinalReview       ,  
               B.IsOpinion          = A.IsFinalOpinion      ,  
               B.IsDange            = A.IsFinalDange        ,  
               B.IsMSDS             = A.IsFinalMSDS         ,  
               B.IsCheckList        = A.IsCheckList         ,  
               B.IsResultCheck      = A.IsResultCheck       ,  
               B.IsEduJoin          = A.IsEduJoin           ,  
               B.IsSkillReport      = A.IsSkillReport       ,  
               B.Etc                = A.FinalEtc            ,  
               B.FileSeq            = A.FileSeq             ,  
               B.LastUserSeq        = @UserSeq              ,  
               B.LastDateTime       = GETDATE() 
      FROM #KPXCM_TEQChangeFinalReport AS A   
          JOIN KPXCM_TEQChangeFinalReport AS B ON ( B.CompanySeq = @CompanySeq AND B.FinalReportSeq = A.FinalReportSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQChangeFinalReport WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQChangeFinalReport  
        (   
            CompanySeq,FinalReportSeq,FinalReportDate,ResultDateFr,ResultDateTo,  
            FinalReportDeptSeq,FinalReportEmpSeq,ResultRemark,IsPID,IsPFD,  
            IsLayOut,IsProposal,IsReport,IsMinutes,IsReview,  
            IsOpinion,IsDange,IsMSDS,IsCheckList,IsResultCheck,  
            IsEduJoin,IsSkillReport,Etc,FileSeq,ChangeRequestSeq,  
            LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.FinalReportSeq,A.FinalReportDate,A.ResultDateFr,A.ResultDateTo,  
               A.FinalReportDeptSeq,A.FinalReportEmpSeq,A.ResultRemark,A.IsFinalPID,A.IsFinalPFD,  
               A.IsFinalLayOut,A.IsFinalProposal,A.IsFinalReport,A.IsFinalMinutes,A.IsFinalReview,  
               A.IsFinalOpinion,A.IsFinalDange,A.IsFinalMSDS,A.IsCheckList,A.IsResultCheck,  
               A.IsEduJoin,A.IsSkillReport,A.FinalEtc,A.FileSeq,A.ChangeRequestSeq,  
               @UserSeq,GETDATE()   
          FROM #KPXCM_TEQChangeFinalReport AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXCM_TEQChangeFinalReport   
      
    RETURN  
--Go
--begin tran 
--exec KPXCM_SEQChangeFinalReportSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <Status>0</Status>
--    <ChangeRequestSeq>4</ChangeRequestSeq>
--    <FileSeq>48918</FileSeq>
--    <FinalEtc>asdg</FinalEtc>
--    <FinalReportDate>20150612</FinalReportDate>
--    <FinalReportDeptSeq>1300</FinalReportDeptSeq>
--    <FinalReportEmpSeq>2028</FinalReportEmpSeq>
--    <IsCheckList>1</IsCheckList>
--    <IsEduJoin>1</IsEduJoin>
--    <IsFinalDange>1</IsFinalDange>
--    <IsFinalLayOut>0</IsFinalLayOut>
--    <IsFinalMinutes>1</IsFinalMinutes>
--    <IsFinalMSDS>0</IsFinalMSDS>
--    <IsFinalOpinion>0</IsFinalOpinion>
--    <IsFinalPFD>0</IsFinalPFD>
--    <IsFinalPID>1</IsFinalPID>
--    <IsFinalProposal>0</IsFinalProposal>
--    <IsFinalReport>0</IsFinalReport>
--    <IsFinalReview>1</IsFinalReview>
--    <IsResultCheck>1</IsResultCheck>
--    <IsSkillReport>0</IsSkillReport>
--    <ResultDateFr>20150612</ResultDateFr>
--    <ResultDateTo>20150630</ResultDateTo>
--    <ResultRemark>sdgasdg</ResultRemark>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030259,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025248
--rollback 