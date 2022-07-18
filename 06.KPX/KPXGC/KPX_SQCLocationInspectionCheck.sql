  
IF OBJECT_ID('KPX_SQCLocationInspectionCheck') IS NOT NULL   
    DROP PROC KPX_SQCLocationInspectionCheck  
GO  
  
-- v2014.12.04  
  
-- 공정검사위치등록-체크 by 이재천   
CREATE PROC KPX_SQCLocationInspectionCheck  
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
    
    CREATE TABLE #KPX_TQCPlant( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCPlant'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPX_TQCPlantLocation( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCPlantLocation'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count      INT,  
            @Seq        INT, 
            @MaxSerl    INT 
      
    SELECT @Count = COUNT(1) FROM #KPX_TQCPlant WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCPlant', 'PlantSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TQCPlant  
           SET PlantSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    
    SELECT @MaxSerl = (SELECT MAX(LocationSeq) FROM KPX_TQCPlantLocation WHERE CompanySeq = @CompanySeq)
    
    UPDATE A  
       SET LocationSeq = ISNULL(@MaxSerl,0) + A.DataSeq  
      FROM #KPX_TQCPlantLocation AS A   
     WHERE A.Status = 0   
       AND A.WorkingTag = 'A' 
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TQCPlant   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCPlant  
     WHERE Status = 0  
       AND ( PlantSeq = 0 OR PlantSeq IS NULL )  
      
    SELECT * FROM #KPX_TQCPlant   
    
    SELECT * FROM #KPX_TQCPlantLocation 
    
    RETURN  
    