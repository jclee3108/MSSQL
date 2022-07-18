  
IF OBJECT_ID('KPX_SHRWelMediEmpCheck') IS NOT NULL   
    DROP PROC KPX_SHRWelMediEmpCheck  
GO  
  
-- v2014.12.03  
  
-- 의료비내역등록-체크 by 이재천   
CREATE PROC KPX_SHRWelMediEmpCheck  
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
      
    CREATE TABLE #KPX_THRWelMediEmp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelMediEmp'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A
       SET Result = '의료비신청으로 생성 된 데이터는 삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #KPX_THRWelMediEmp AS A 
      JOIN KPX_THRWelMediEmp  AS B ON ( B.CompanySeq = @CompanySeq AND B.WelMediEmpSeq = A.WelMediEmpSeq ) 
     WHERE WorkingTag = 'D'
       AND Status = 0 
       AND B.WelMediSeq <> 0 
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_THRWelMediEmp WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = 'KPX_THRWelMediEmp'
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THRWelMediEmp', 'WelMediEmpSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_THRWelMediEmp  
           SET WelMediEmpSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_THRWelMediEmp   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_THRWelMediEmp  
     WHERE Status = 0  
       AND ( WelMediEmpSeq = 0 OR WelMediEmpSeq IS NULL )  
      
    SELECT * FROM #KPX_THRWelMediEmp   
      
    RETURN  
GO 
begin tran 
exec KPX_SHRWelMediEmpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpSeq>2028</EmpSeq>
    <YY>2014</YY>
    <BaseDate>20141210</BaseDate>
    <CompanyAmt>4900</CompanyAmt>
    <ItemSeq>1</ItemSeq>
    <PbYM />
    <PbSeq>0</PbSeq>
    <WelMediEmpSeq>3</WelMediEmpSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026443,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022141
rollback 