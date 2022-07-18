  
IF OBJECT_ID('KPXCM_SPDShutDownCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDShutDownCheck  
GO  
  
-- v2016.04.21  
  
-- SHUT-DOWN일정등록(우레탄)-체크 by 이재천   
CREATE PROC KPXCM_SPDShutDownCheck  
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
      
    CREATE TABLE #KPXCM_TPDShutDown( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDShutDown'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 종료일이 시작일보다 빠르거나 같습니다.
    UPDATE A
       SET Result = '종료일이 시작일보다 빠르거나 같습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TPDShutDown AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND EndDate + REPLACE(EndTime,':','') <= SrtDate + REPLACE(SrtTime,':','')
    -- 체크1, END 
    
    -- 번호+코드 따기 :            
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TPDShutDown WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDShutDown', 'SDSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TPDShutDown  
           SET SDSeq = @Seq + DataSeq--,  
               --SampleNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TPDShutDown   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TPDShutDown  
     WHERE Status = 0  
       AND ( SDSeq = 0 OR SDSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TPDShutDown   
      
    RETURN  
    GO 
begin tran 
exec KPXCM_SPDShutDownCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SrtDate>20160413</SrtDate>
    <SrtTime>07:00</SrtTime>
    <SrtTimeSeq>1012820001</SrtTimeSeq>
    <EndDate>20160412</EndDate>
    <EndTime>15:00</EndTime>
    <EndTimeSeq>1012820002</EndTimeSeq>
    <Remark />
    <SDSeq>0</SDSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <FactUnit>1</FactUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036643,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030021        
rollback 