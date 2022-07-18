  
IF OBJECT_ID('KPX_SPRBasWelFareCodeCheck') IS NOT NULL   
    DROP PROC KPX_SPRBasWelFareCodeCheck  
GO  
  
-- v2014.12.01  
  
-- 복리후생코드등록-체크 by 이재천   
CREATE PROC KPX_SPRBasWelFareCodeCheck  
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
      
    CREATE TABLE #KPX_THRWelCode( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWelCode'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPX_THRWelCodeYearItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelCodeYearItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count      INT,  
            @Seq        INT, 
            @MaxSerl    INT, 
            @MaxRegSeq  INT
    
    SELECT @Count = COUNT(1) FROM #KPX_THRWelCode WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THRWelCode', 'WelCodeSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_THRWelCode  
           SET WelCodeSeq = @Seq + DataSeq 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    SELECT @MaxSerl = (SELECT MAX(WelCodeSerl) FROM KPX_THRWelCodeYearItem WHERE CompanySeq = @CompanySeq AND WelCodeSeq  = (SELECT TOP 1 WelCodeSerl FROM #KPX_THRWelCodeYearItem WHERE WorkingTag = 'A'))
    
    UPDATE A
       SET WelCodeSerl = ISNULL(@MaxSerl,0) + A.DataSeq
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A'
    
    -- 기간명칭 코드 
    SELECT @MaxRegSeq = (SELECT MAX(RegSeq) FROM KPX_THRWelCodeYearItem WHERE CompanySeq = @CompanySeq) 
    
    UPDATE A
       SET RegSeq = ISNULL(@MaxRegSeq,0) + A.DataSeq 
      FROM #KPX_THRWelCodeYearItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A'
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_THRWelCode   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_THRWelCode  
     WHERE Status = 0  
       AND ( WelCodeSeq = 0 OR WelCodeSeq IS NULL )  
    
    SELECT * FROM #KPX_THRWelCode   
    
    SELECT * FROM #KPX_THRWelCodeYearItem 
    
    RETURN  
GO 
begin tran 
exec KPX_SPRBasWelFareCodeCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <YY>2014</YY>
    <RegName>2014 1분기 복리후생명</RegName>
    <DateFr>20140101</DateFr>
    <DateTo>20140331</DateTo>
    <EmpAmt>0</EmpAmt>
    <WelCodeSeq>10</WelCodeSeq>
    <WelCodeSerl>0</WelCodeSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <YY>2014</YY>
    <RegName>2014 2분기 복리후생명</RegName>
    <DateFr>20140401</DateFr>
    <DateTo>20140630</DateTo>
    <EmpAmt>0</EmpAmt>
    <WelCodeSeq>10</WelCodeSeq>
    <WelCodeSerl>0</WelCodeSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <YY>2014</YY>
    <RegName>2014 3분기 복리후생명</RegName>
    <DateFr>20140701</DateFr>
    <DateTo>20140930</DateTo>
    <EmpAmt>0</EmpAmt>
    <WelCodeSeq>10</WelCodeSeq>
    <WelCodeSerl>0</WelCodeSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <YY>2014</YY>
    <RegName>2014 4분기 복리후생명</RegName>
    <DateFr>20141001</DateFr>
    <DateTo>20141231</DateTo>
    <EmpAmt>0</EmpAmt>
    <WelCodeSeq>10</WelCodeSeq>
    <WelCodeSerl>0</WelCodeSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026356,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021406
rollback 