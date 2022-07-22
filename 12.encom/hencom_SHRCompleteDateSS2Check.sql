  
IF OBJECT_ID('hencom_SHRCompleteDateSS2Check') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateSS2Check  
GO  
    
-- v2017.07.26
    
-- 완료일관리-SS2체크 by 이재천 
CREATE PROC hencom_SHRCompleteDateSS2Check  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #hencom_THRCompleteDateShare( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#hencom_THRCompleteDateShare'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @MaxSerl        INT
    
    SELECT @MaxSerl = MAX(ShareSerl)
      FROM hencom_THRCompleteDateShare AS A 
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_THRCompleteDateShare WHERE CompleteSeq = A.CompleteSeq)
    
    SELECT @MaxSerl = ISNULL(@MaxSerl,0) 
    


    UPDATE A
       SET ShareSerl = ISNULL(MaxShareSerl,@MaxSerl) + A.DataSeq
      FROM #hencom_THRCompleteDateShare AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SELECT * FROM #hencom_THRCompleteDateShare   
    
    RETURN 
    GO

begin tran 
exec hencom_SHRCompleteDateSS2Check @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ShareEmpName>김재철</ShareEmpName>
    <ShareEmpSeq>127</ShareEmpSeq>
    <ShareSerl>0</ShareSerl>
    <CompleteSeq>9</CompleteSeq>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512703,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033993

rollback 