  
IF OBJECT_ID('hencom_SHRCompleteDateCheck') IS NOT NULL   
    DROP PROC hencom_SHRCompleteDateCheck  
GO  
    
-- v2017.07.26
  
-- 완료일관리-체크 by 이재천   
CREATE PROC hencom_SHRCompleteDateCheck  
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
      
    CREATE TABLE #hencom_THRCompleteDate( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_THRCompleteDate'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_THRCompleteDate WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_THRCompleteDate', 'CompleteSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #hencom_THRCompleteDate  
           SET CompleteSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_THRCompleteDate   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_THRCompleteDate  
     WHERE Status = 0  
       AND ( CompleteSeq = 0 OR CompleteSeq IS NULL )  
      
    SELECT * FROM #hencom_THRCompleteDate   
      
    RETURN  
    GO
begin tran 

exec hencom_SHRCompleteDateCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMCompleteType>1015529001</UMCompleteType>
    <UMCompleteTypeName>숙소(전체)</UMCompleteTypeName>
    <DpetSeq>66</DpetSeq>
    <DpetName>경영지원담당 재경팀</DpetName>
    <SrtDate>20170701</SrtDate>
    <EndDate>20170703</EndDate>
    <ManagementAmt>0</ManagementAmt>
    <AlarmDay>0</AlarmDay>
    <Remark>dfdf</Remark>
    <CompleteSeq>0</CompleteSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512703,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033993

rollback 