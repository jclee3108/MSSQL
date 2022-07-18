  
IF OBJECT_ID('KPX_SPDMRPMonthCheck') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthCheck  
GO  
  
-- v2014.12.16  
  
-- 월별자재소요계산-체크 by 이재천   
CREATE PROC KPX_SPDMRPMonthCheck  
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
    
    CREATE TABLE #KPX_TPDMRPMonth( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDMRPMonth'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
      DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPDMRPMonth WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = CONVERT( NVARCHAR(8), GETDATE(), 112 ) 
          FROM #KPX_TPDMRPMonth   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TPDMRPMonth', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDMRPMonth', 'MRPMonthSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TPDMRPMonth  
           SET MRPMonthSeq = @Seq + DataSeq,  
               MRPNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
        
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TPDMRPMonth   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPDMRPMonth  
     WHERE Status = 0  
       AND ( MRPMonthSeq = 0 OR MRPMonthSeq IS NULL )  
      
    SELECT * FROM #KPX_TPDMRPMonth   
      
    RETURN  