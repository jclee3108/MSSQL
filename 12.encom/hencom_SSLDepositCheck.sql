  
IF OBJECT_ID('hencom_SSLDepositCheck') IS NOT NULL   
    DROP PROC hencom_SSLDepositCheck  
GO  
    
-- v2017.07.24
  
-- 공탁관리-체크 by 이재천
CREATE PROC hencom_SSLDepositCheck  
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
      
    CREATE TABLE #hencom_TSLDeposit( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLDeposit'   
    IF @@ERROR <> 0 RETURN     
      
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #hencom_TSLDeposit WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'hencom_TSLDeposit', 'DepositSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #hencom_TSLDeposit  
           SET DepositSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #hencom_TSLDeposit   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #hencom_TSLDeposit  
     WHERE Status = 0  
       AND ( DepositSeq = 0 OR DepositSeq IS NULL )  
      
    SELECT * FROM #hencom_TSLDeposit   
      
    RETURN  
    GO