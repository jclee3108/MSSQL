  
IF OBJECT_ID('KPXCM_SEQRegInspectChgSave') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectChgSave  
GO  
  
-- v2015.07.01  
  
-- 정기검사계획조정등록-저장 by 이재천   
CREATE PROC KPXCM_SEQRegInspectChgSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPXCM_TEQRegInspectChg (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspectChg'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQRegInspectChg')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQRegInspectChg'    , -- 테이블명        
                  '#KPXCM_TEQRegInspectChg'    , -- 임시 테이블명        
                  'RegInspectSeq,QCPlanDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TEQRegInspectChg AS A   
          JOIN KPXCM_TEQRegInspectChg AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCPlanDate = A.QCPlanDate )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ReplaceDate = A.ReplaceDate,  
               B.Remark = A.Remark,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQRegInspectChg AS A   
          JOIN KPXCM_TEQRegInspectChg AS B ON ( B.CompanySeq = @CompanySeq AND B.RegInspectSeq = A.RegInspectSeq AND B.QCPlanDate = A.QCPlanDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQRegInspectChg WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TEQRegInspectChg  
        (   
            CompanySeq,RegInspectSeq,QCPlanDate,ReplaceDate,Remark,
            LastUserSeq,LastDateTime,PgmSeq   
        )   
        SELECT @CompanySeq,A.RegInspectSeq,A.QCPlanDate,A.ReplaceDate,A.Remark,
               @UserSeq,GETDATE(),@PgmSeq   
          FROM #KPXCM_TEQRegInspectChg AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    UPDATE A 
       SET A.ReplaceDateOld = A.ReplaceDate
      FROM #KPXCM_TEQRegInspectChg AS A 
    
    SELECT * FROM #KPXCM_TEQRegInspectChg   
      
    RETURN  
--    go
--    begin tran 
    
--    exec KPXCM_SEQRegInspectChgSave @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Selected>0</Selected>
--    <Status>0</Status>
--    <QCPlanDate>20150719</QCPlanDate>
--    <RegInspectSeq>6</RegInspectSeq>
--    <Remark />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1030624,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025548

--rollback 