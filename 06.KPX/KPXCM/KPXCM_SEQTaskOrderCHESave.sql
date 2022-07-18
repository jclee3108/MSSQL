
IF OBJECT_ID('KPXCM_SEQTaskOrderCHESave') IS NOT NULL 
    DROP PROC KPXCM_SEQTaskOrderCHESave
GO 
    
-- v2015.06.11    
    
-- 변경기술검토등록-저장 by 이재천     
CREATE PROC KPXCM_SEQTaskOrderCHESave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS      
        
    CREATE TABLE #KPXCM_TEQTaskOrderCHE (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQTaskOrderCHE'     
    IF @@ERROR <> 0 RETURN      
    
    -- 로그 남기기      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQTaskOrderCHE')      
        
    EXEC _SCOMLog @CompanySeq   ,          
                  @UserSeq      ,          
                  'KPXCM_TEQTaskOrderCHE'    , -- 테이블명          
                  '#KPXCM_TEQTaskOrderCHE'    , -- 임시 테이블명          
                  'TaskOrderSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
      
    -- DELETE        
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQTaskOrderCHE WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN      
            
        DELETE B     
          FROM #KPXCM_TEQTaskOrderCHE AS A     
          JOIN KPXCM_TEQTaskOrderCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.TaskOrderSeq = A.TaskOrderSeq )     
         WHERE A.WorkingTag = 'D'     
           AND A.Status = 0     
          
        IF @@ERROR <> 0  RETURN    
          
    END      
    
    -- UPDATE        
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQTaskOrderCHE WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
            
        UPDATE B     
           SET B.IsPID      = A.IsPID      ,   
               B.IsPFD      = A.IsPFD      ,   
               B.IsLayOut   = A.IsLayOut   ,   
               B.IsProposal = A.IsProposal ,   
               B.IsReport   = A.IsReport   ,   
               B.IsMinutes  = A.IsMinutes  ,   
               B.IsReview   = A.IsReview   ,   
               B.IsOpinion  = A.IsOpinion  ,   
               B.IsDange    = A.IsDange    ,   
               B.IsMSDS     = A.IsMSDS     ,   
               B.Etc        = A.Etc        ,  
               B.ChangePlan = A.ChangePlan,    
               B.TaskOrder = A.TaskOrder,    
               B.FileSeq = A.FileSeq,   
               B.LastUserSeq  = @UserSeq,    
               B.LastDateTime = GETDATE()  
          FROM #KPXCM_TEQTaskOrderCHE AS A     
          JOIN KPXCM_TEQTaskOrderCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.TaskOrderSeq = A.TaskOrderSeq )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0  RETURN    
            
    END      
    
    -- INSERT    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
            
        INSERT INTO KPXCM_TEQTaskOrderCHE    
        (     
            CompanySeq, TaskOrderSeq, TaskOrderDate, TaskOrderDeptSeq, TaskOrderEmpSeq, 
            IsPID, IsPFD, IsLayOut, IsProposal, IsReport, 
            IsMinutes, IsReview, IsOpinion, IsDange, IsMSDS, 
            Etc, ChangePlan, TaskOrder, FileSeq, ChangeRequestSeq, 
            LastUserSeq, LastDateTime  
        )     
        SELECT @CompanySeq, A.TaskOrderSeq, A.TaskOrderDate, A.TaskOrderDeptSeq, A.TaskOrderEmpSeq, 
               A.IsPID, A.IsPFD, A.IsLayOut, A.IsProposal, A.IsReport,
               A.IsMinutes, A.IsReview, A.IsOpinion, A.IsDange, A.IsMSDS,
               A.Etc, A.ChangePlan, A.TaskOrder, A.FileSeq, A.ChangeRequestSeq, 
               @UserSeq, GETDATE()
          FROM #KPXCM_TEQTaskOrderCHE AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0 RETURN    
      
    END       
      
    SELECT * FROM #KPXCM_TEQTaskOrderCHE     
    
    RETURN   
go
begin tran
exec KPXCM_SEQTaskOrderCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <ChangePlan>ㅁㄴㅇㅎ</ChangePlan>
    <ChangeRequestSeq>4</ChangeRequestSeq>
    <Etc>0</Etc>
    <FileSeq>0</FileSeq>
    <IsDange>1</IsDange>
    <IsLayOut>1</IsLayOut>
    <IsMinutes>0</IsMinutes>
    <IsOpinion>1</IsOpinion>
    <IsPFD>1</IsPFD>
    <IsPID>0</IsPID>
    <IsProposal>0</IsProposal>
    <IsReport>1</IsReport>
    <IsReview>1</IsReview>
    <TaskOrder>ㅁㄴㅇㅎ</TaskOrder>
    <TaskOrderDate>20150615</TaskOrderDate>
    <TaskOrderDeptName>사업개발팀2</TaskOrderDeptName>
    <TaskOrderDeptSeq>1300</TaskOrderDeptSeq>
    <TaskOrderEmpName>이재천</TaskOrderEmpName>
    <TaskOrderEmpSeq>2028</TaskOrderEmpSeq>
    <TaskOrderProgType>1010655001</TaskOrderProgType>
    <TaskOrderProgTypeName>작성</TaskOrderProgTypeName>
    <TaskOrderSeq>8</TaskOrderSeq>
    <IsMSDS>0</IsMSDS>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030226,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025227
select * from KPXCM_TEQTaskOrderCHE 

rollback 
