  
IF OBJECT_ID('KPXCM_SPDProdPlanScenarioRevCheck') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanScenarioRevCheck  
GO  
  
-- v2016.05.20  
  
-- 생산계획시나리오 차수관리-체크 by 이재천   
CREATE PROC KPXCM_SPDProdPlanScenarioRevCheck  
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
      
    CREATE TABLE #KPXCM_TPDMonthProdPlanRev( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDMonthProdPlanRev'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPXCM_TPDMonthProdPlanRev   
      
    RETURN  