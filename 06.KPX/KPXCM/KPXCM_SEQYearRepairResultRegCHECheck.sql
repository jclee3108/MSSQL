  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHECheck  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-체크 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHECheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairResultRegCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairResultRegCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairResultRegCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN    
    
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairResultRegCHE', 'ResultSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TEQYearRepairResultRegCHE  
           SET ResultSeq = @Seq + DataSeq 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairResultRegCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairResultRegCHE  
     WHERE Status = 0  
       AND ( ResultSeq = 0 OR ResultSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQYearRepairResultRegCHE   
    
    RETURN  