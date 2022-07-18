  
IF OBJECT_ID('KPX_SPDToolCHEUpLoadCheck') IS NOT NULL   
    DROP PROC KPX_SPDToolCHEUpLoadCheck  
GO  
  
-- v2015.02.04  
  
-- 설비등록(UpLoad)-체크 by 이재천   
CREATE PROC KPX_SPDToolCHEUpLoadCheck  
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
      
    CREATE TABLE #TPDTool( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTool'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #TPDTool 
    
    RETURN  