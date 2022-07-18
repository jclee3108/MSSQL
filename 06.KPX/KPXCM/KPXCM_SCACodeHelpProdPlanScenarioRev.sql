IF OBJECT_ID('KPXCM_SCACodeHelpProdPlanScenarioRev') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpProdPlanScenarioRev
GO 
  
-- v2016.05.23 
  
-- 생산계획시나리오차수_KPXCM 코드도움 by이재천   
CREATE PROC KPXCM_SCACodeHelpProdPlanScenarioRev      
    @WorkingTag     NVARCHAR(1),                                        
    @LanguageSeq    INT,                                        
    @CodeHelpSeq    INT,                                        
    @DefQueryOption INT,                      
    @CodeHelpType   TINYINT,                                        
    @PageCount      INT = 20,                             
    @CompanySeq     INT = 1,                                       
    @Keyword        NVARCHAR(200) = '',                                        
    @Param1         NVARCHAR(50) = '',             
    @Param2         NVARCHAR(50) = '',             
    @Param3         NVARCHAR(50) = '',                            
    @Param4         NVARCHAR(50) = ''               
      
    WITH RECOMPILE                      
AS                
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED                    
                  
    SET ROWCOUNT @PageCount                      
                  
    SELECT A.PlanRev + ' : ' + PlanRevName AS PlanRevName, 
           CONVERT(INT,PlanRev) AS PlanRevSeq 
      FROM KPXCM_TPDMonthProdPlanRev AS A      
     WHERE A.CompanySeq = @CompanySeq      
       AND (@Param1 = A.FactUnit)   
       AND (@Param2 = A.PlanYM)  
     ORDER BY A.PlanRev 
    
    SET ROWCOUNT 0                
      
    RETURN           