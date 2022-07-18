  
IF OBJECT_ID('KPXLS_SQCInQCIResultCheck') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultCheck  
GO  
  
-- v2015.12.15  
  
-- (검사품)수입검사등록-체크 by 이재천   
CREATE PROC KPXLS_SQCInQCIResultCheck  
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
      
    CREATE TABLE #KPX_TQCTestResult( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------
    -- 체크1, 검사승인 된 데이터는 수정, 삭제 할 수 없습니다. 
    ------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '검사승인 된 데이터는 수정, 삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TQCTestResult AS A 
      JOIN KPXLS_TQCTestResultAdd AS B ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = A.QCSeq ) 
     WHERE B.IsCfm = '1' 
       AND A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    
    ------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TQCTestResult WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN    
    
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCTestResult', 'QCSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TQCTestResult  
           SET QCSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
    
    UPDATE #KPX_TQCTestResult   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCTestResult  
     WHERE Status = 0  
       AND ( QCSeq = 0 OR QCSeq IS NULL )  
    
    SELECT * FROM #KPX_TQCTestResult   
    
    RETURN 
    GO 
    begin tran
    exec KPXLS_SQCInQCIResultCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QCNo>A003</QCNo>
    <QCNoSub>A004</QCNoSub>
    <QCDate>20151216</QCDate>
    <UseItemName>123</UseItemName>
    <UMQcType>1010418001</UMQcType>
    <UMQcTypeName>합격</UMQcTypeName>
    <SCDate>20151213</SCDate>
    <SCRocate>123</SCRocate>
    <SCAmount>test</SCAmount>
    <SCEmpName>asdfasdf</SCEmpName>
    <SCPackage>asdfasdf</SCPackage>
    <OKQty>0</OKQty>
    <BadQty>0</BadQty>
    <IsCfm>1</IsCfm>
    <CfmEmpName>이재천</CfmEmpName>
    <CfmDate>2015-12-17 오후 1:22:45</CfmDate>
    <QCSeq>182</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027993
rollback 