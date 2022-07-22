  
IF OBJECT_ID('hencom_SHRCompleteDateSS1Check') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateSS1Check  
GO  
    
-- v2017.07.26
    
-- 완료일관리-SS1체크 by 이재천 
CREATE PROC hencom_SHRCompleteDateSS1Check  
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
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hencom_THRCompleteDateShare'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @MaxSerl        INT, 
            @MaxShareSerl   INT 
    
    SELECT @MaxSerl = MAX(ShareSerl)
      FROM hencom_THRCompleteDateShare AS A 
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_THRCompleteDateShare WHERE CompleteSeq = A.CompleteSeq)
    
    SELECT @MaxSerl = ISNULL(@MaxSerl,0) 
    
    UPDATE A
       SET ShareSerl = @MaxSerl + A.DataSeq
      FROM #hencom_THRCompleteDateShare AS A 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    SET ROWCOUNT 1

    SELECT ShareSerl 
      INTO #MaxShareSerl 
      FROM #hencom_THRCompleteDateShare 
     ORDER BY DataSeq DESC

    SET ROWCOUNT 0 
    
    SELECT @MaxShareSerl = ShareSerl
      FROM #MaxShareSerl 
    
    UPDATE A
       SET MaxShareSerl = ISNULL(@MaxShareSerl,0)
      FROM #hencom_THRCompleteDateShare AS A 

    SELECT * FROM #hencom_THRCompleteDateShare   
    
    RETURN 

go
begin tran 

exec hencom_SHRCompleteDateSS1Check @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ShareDeptName>경영지원담당 재경팀</ShareDeptName>
    <ShareDeptSeq>66</ShareDeptSeq>
    <ShareSerl>0</ShareSerl>
    <CompleteSeq>2</CompleteSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
    <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ShareDeptName>경영지원담당 재경팀</ShareDeptName>
    <ShareDeptSeq>55</ShareDeptSeq>
    <ShareSerl>0</ShareSerl>
    <CompleteSeq>2</CompleteSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512703,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033993
rollback 