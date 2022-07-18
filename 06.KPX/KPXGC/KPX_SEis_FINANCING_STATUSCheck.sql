  
IF OBJECT_ID('KPX_SEis_FINANCING_STATUSCheck') IS NOT NULL   
    DROP PROC KPX_SEis_FINANCING_STATUSCheck  
GO  
  
-- v2014.11.26  
  
-- (경영정보)자금 조달 현황-체크 by 이재천   
CREATE PROC KPX_SEis_FINANCING_STATUSCheck  
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
    
    CREATE TABLE #KPX_TEIS_FINANCING_STATUS( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEIS_FINANCING_STATUS'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TEIS_FINANCING_STATUS   
    
    RETURN  