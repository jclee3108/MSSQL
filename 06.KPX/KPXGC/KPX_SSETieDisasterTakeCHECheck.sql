  
IF OBJECT_ID('KPX_SSETieDisasterTakeCHECheck') IS NOT NULL   
    DROP PROC KPX_SSETieDisasterTakeCHECheck  
GO  
  
-- v2014.12.26  
  
-- 무재해운동-체크 by 이재천   
CREATE PROC KPX_SSETieDisasterTakeCHECheck  
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
      
    CREATE TABLE #KPX_TSETieDisasterTake( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSETieDisasterTake'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TSETieDisasterTake   

    RETURN  