  
IF OBJECT_ID('KPX_SQCCOAPrintCheck') IS NOT NULL   
    DROP PROC KPX_SQCCOAPrintCheck  
GO  
  
-- v2014.12.18  
  
-- 시험성적서발행(COA)-체크 by 이재천   
CREATE PROC KPX_SQCCOAPrintCheck  
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
    
    CREATE TABLE #KPX_TQCCOAPrint( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCCOAPrint'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
        @Seq    INT   
    
    SELECT @Count = COUNT(1) FROM #KPX_TQCCOAPrint WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = CONVERT( NVARCHAR(8), GETDATE(), 112 )   
          FROM #KPX_TQCCOAPrint   
         WHERE WorkingTag = 'A'   
           AND Status = 0     

        EXEC dbo._SCOMCreateNo 'SITE', 'KPX_TQCCOAPrint', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT     
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCCOAPrint', 'COASeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TQCCOAPrint  
           SET COASeq = @Seq + DataSeq,  
               COANo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TQCCOAPrint   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCCOAPrint  
     WHERE Status = 0  
       AND ( COASeq = 0 OR COASeq IS NULL )  
      
    SELECT * FROM #KPX_TQCCOAPrint   
      
    RETURN  