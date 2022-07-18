  
IF OBJECT_ID('KPX_SPDMPSProdPlanAutoSortCheck') IS NOT NULL   
    DROP PROC KPX_SPDMPSProdPlanAutoSortCheck  
GO  
  
-- v2014.10.14  
  
-- 자동정렬-체크 by 이재천   
CREATE PROC KPX_SPDMPSProdPlanAutoSortCheck  
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
      
    CREATE TABLE #TPDMPSDailyProdPlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDMPSDailyProdPlan'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #TPDMPSDailyProdPlan 
    
    RETURN  