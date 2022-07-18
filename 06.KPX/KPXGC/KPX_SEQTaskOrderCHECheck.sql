  
IF OBJECT_ID('KPX_SEQTaskOrderCHECheck') IS NOT NULL   
    DROP PROC KPX_SEQTaskOrderCHECheck  
GO  
  
-- v2014.12.08  
  
-- 변경기술검토등록-체크 by 이재천   
CREATE PROC KPX_SEQTaskOrderCHECheck  
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
    
    CREATE TABLE #KPX_TEQTaskOrderCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQTaskOrderCHE'   
    IF @@ERROR <> 0 RETURN     
    
    
    ------------------------------------------------------------------------
    -- 번호+코드 따기 :           
    ------------------------------------------------------------------------
    DECLARE @Count  INT,  
            @Seq    INT   
    
    SELECT @Count = COUNT(1) FROM #KPX_TEQTaskOrderCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TEQTaskOrderCHE', 'TaskOrderSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TEQTaskOrderCHE  
           SET TaskOrderSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TEQTaskOrderCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TEQTaskOrderCHE  
     WHERE Status = 0  
       AND ( TaskOrderSeq = 0 OR TaskOrderSeq IS NULL )  
      
    SELECT * FROM #KPX_TEQTaskOrderCHE   
      
    RETURN  