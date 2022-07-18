  
IF OBJECT_ID('KPXCM_SEQChangeFinalReportCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQChangeFinalReportCheck  
GO  
  
-- v2015.06.12  
  
-- 변경실행결과등록-체크 by 이재천   
CREATE PROC KPXCM_SEQChangeFinalReportCheck  
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
    
    CREATE TABLE #KPXCM_TEQChangeFinalReport( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQChangeFinalReport'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQChangeFinalReport WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQChangeFinalReport', 'FinalReportSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TEQChangeFinalReport  
           SET FinalReportSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A    
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQChangeFinalReport AS A 
     WHERE Status = 0  
       AND ( FinalReportSeq = 0 OR FinalReportSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQChangeFinalReport   
      
    RETURN  
go
begin tran

exec KPXCM_SEQChangeFinalReportCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ChangeRequestSeq>4</ChangeRequestSeq>
    <FileSeq>48918</FileSeq>
    <FinalReportDate>20150612</FinalReportDate>
    <ResultRemark>sdgasdg</ResultRemark>
    <FinalReportDeptSeq>1300</FinalReportDeptSeq>
    <FinalReportEmpSeq>2028</FinalReportEmpSeq>
    <ResultDateFr>20150612</ResultDateFr>
    <ResultDateTo>20150630</ResultDateTo>
    <IsFinalMSDS>0</IsFinalMSDS>
    <IsCheckList>1</IsCheckList>
    <IsResultCheck>1</IsResultCheck>
    <IsEduJoin>1</IsEduJoin>
    <IsSkillReport>0</IsSkillReport>
    <FinalEtc>asdg</FinalEtc>
    <IsFinalPID>1</IsFinalPID>
    <IsFinalPFD>0</IsFinalPFD>
    <IsFinalLayOut>0</IsFinalLayOut>
    <IsFinalProposal>0</IsFinalProposal>
    <IsFinalReport>0</IsFinalReport>
    <IsFinalMinutes>1</IsFinalMinutes>
    <IsFinalReview>1</IsFinalReview>
    <IsFinalOpinion>0</IsFinalOpinion>
    <IsFinalDange>1</IsFinalDange>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030259,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025248

rollback 