  
IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanStockCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanStockCheck  
GO  
  
-- v2015.11.03  
  
-- 원부원료 사용계획서-체크 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanStockCheck  
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
      
    CREATE TABLE #KPXCM_TPDSFCMonthMatUsePlanStock( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthMatUsePlanStock'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPXCM_TPDSFCMonthMatUsePlanStock   
      
    RETURN  