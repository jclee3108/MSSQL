  
IF OBJECT_ID('KPX_SQCCycleInspectionCheck') IS NOT NULL   
    DROP PROC KPX_SQCCycleInspectionCheck  
GO  
  
-- v2014.12.04  
  
-- 공정검사주기등록-체크 by 이재천   
CREATE PROC KPX_SQCCycleInspectionCheck  
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
      
    CREATE TABLE #KPX_TQCPlantCycle( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCPlantCycle'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------
    -- 체크1, 중복여부 체크
    ------------------------------------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
    
    UPDATE #KPX_TQCPlantCycle  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_TQCPlantCycle AS A   
      JOIN (SELECT S.PlantSeq, S.CycleTime  
              FROM (SELECT A1.PlantSeq, A1.CycleTime  
                      FROM #KPX_TQCPlantCycle AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.PlantSeq, A1.CycleTime  
                      FROM KPX_TQCPlantCycle AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_TQCPlantCycle   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND PlantSeq = A1.PlantSeq 
                                                 AND CycleTime = A1.CycleTime
                                                 AND CycleSerl = A1.CycleSerl 
                                      )  
                   ) AS S  
             GROUP BY S.PlantSeq, S.CycleTime  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.PlantSeq = B.PlantSeq AND A.CycleTime = B.CycleTime )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    ------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------
    
    ------------------------------------------------------------------------
    -- 번호+코드 따기 
    ------------------------------------------------------------------------
    DECLARE @MaxSerl    INT   
    
    SELECT @MaxSerl = (SELECT MAX(CycleSerl) FROM KPX_TQCPlantCycle WHERE CompanySeq = @CompanySeq) 
    
    UPDATE #KPX_TQCPlantCycle  
       SET CycleSerl = ISNULL(@MaxSerl,0) + DataSeq
     WHERE WorkingTag = 'A'  
       AND Status = 0  
    
    SELECT * FROM #KPX_TQCPlantCycle   
      
    RETURN  
GO 
exec KPX_SQCCycleInspectionCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CycleTime>1114</CycleTime>
    <IsUse>1</IsUse>
    <Remark>test1</Remark>
    <CycleSerl>2</CycleSerl>
    <PlantSeq>11</PlantSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026478,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022176