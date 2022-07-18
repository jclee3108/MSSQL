  
IF OBJECT_ID('KPXCM_SPDProdPlanScenarioRevQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanScenarioRevQuery  
GO  
  
-- v2016.05.20  
  
-- 생산계획시나리오 차수관리-조회 by 이재천   
CREATE PROC KPXCM_SPDProdPlanScenarioRevQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT,  
            @PlanYear   NCHAR(4) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit, 0 ),  
           @PlanYear   = ISNULL( PlanYear, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT,  
            PlanYear   NCHAR(4)       
           )    
    
    SELECT @PlanYear + '01' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '02' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '03' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '04' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '05' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '06' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '07' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '08' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '09' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '10' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '11' AS PlanYM, @FactUnit AS FactUnit 
    UNION ALL 
    SELECT @PlanYear + '12' AS PlanYM, @FactUnit AS FactUnit
    
    RETURN  