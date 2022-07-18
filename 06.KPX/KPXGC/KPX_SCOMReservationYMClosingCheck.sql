  
IF OBJECT_ID('KPX_SCOMReservationYMClosingCheck') IS NOT NULL   
    DROP PROC KPX_SCOMReservationYMClosingCheck  
GO  
  
-- v2015.07.28  
  
-- 예약마감관리-체크 by 이재천   
CREATE PROC KPX_SCOMReservationYMClosingCheck  
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
      
    CREATE TABLE #KPX_TCOMReservationYMClosing( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TCOMReservationYMClosing'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET WorkingTag = 'A' 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE NOT EXISTS (SELECT 1 FROM KPX_TCOMReservationYMClosing WHERE CompanySeq = @CompanySeq AND ClosingYM = A.ClosingYM AND AccUnit = A.AccUnit) 
    
    UPDATE A 
       SET ReservationTime = ReservationTime + '00'
      FROM #KPX_TCOMReservationYMClosing AS A 
    
    ------------------------------------------------------------    
    -- 체크1, 현재시간보다 예약시간가 빠릅니다. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '현재시간보다 예약시간가 빠릅니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND A.ReservationDate + A.ReservationTime <= CONVERT(NCHAR(8),GETDATE(),112) + CONVERT(NCHAR(2),GETDATE(),108) + '00' 
    ------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------
    
    ------------------------------------------------------------    
    -- 체크2, 시간형태가 옳바르지 않습니다. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '시간형태가 옳바르지 않습니다. ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TCOMReservationYMClosing AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND ( LEFT(A.ReservationTime,2) >= 24 OR LEN(A.ReservationTime) <> 4 ) 
    ------------------------------------------------------------    
    -- 체크2, END 
    ------------------------------------------------------------
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TCOMReservationYMClosing WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TCOMReservationYMClosing', 'ClosingSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TCOMReservationYMClosing  
           SET ClosingSeq = @Seq + DataSeq--,  
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
      
    UPDATE #KPX_TCOMReservationYMClosing   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TCOMReservationYMClosing  
     WHERE Status = 0  
       AND ( ClosingSeq = 0 OR ClosingSeq IS NULL )  
      
    SELECT * FROM #KPX_TCOMReservationYMClosing   
      
    RETURN  
GO 
begin tran 
exec KPX_SCOMReservationYMClosingCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <IsCancel>0</IsCancel>
    <ClosingYM>201501</ClosingYM>
    <AccUnitName>상정-본사</AccUnitName>
    <AccUnit>3</AccUnit>
    <ReservationDate>20150801</ReservationDate>
    <ReservationTime>13</ReservationTime>
    <ProcDate />
    <ProcResult />
    <ClosingSeq />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <ClosingYear>2015</ClosingYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031128,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025935
rollback 

