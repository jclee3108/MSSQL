  
IF OBJECT_ID('KPXCM_SPDProdPlanScenarioRevAdd') IS NOT NULL   
    DROP PROC KPXCM_SPDProdPlanScenarioRevAdd  
GO  
  
-- v2016.05.20  
  
-- 생산계획시나리오 차수관리-Sub조회 by 이재천 
CREATE PROC KPXCM_SPDProdPlanScenarioRevAdd  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPXCM_TPDMonthProdPlanRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDMonthProdPlanRev'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @MaxPlanRev NCHAR(2) 
    
    SELECT @MaxPlanRev = RIGHT('00' + CONVERT(NVARCHAR(10),ISNULL(CONVERT(INT,MAX(B.PlanRev)),0) + 1),2)
      FROM #KPXCM_TPDMonthProdPlanRev AS A 
      LEFT OUTER JOIN KPXCM_TPDMonthProdPlanRev AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit AND B.PlanYM = A.PlanYM ) 
    
    INSERT INTO KPXCM_TPDMonthProdPlanRev  
    (   
        CompanySeq, FactUnit, PlanYM, PlanRev, PlanRevName, 
        Remark, LastUserSeq, LastDateTime, PgmSeq
    )   
    SELECT DISTINCT 
           @CompanySeq, A.FactUnit, A.PlanYM, @MaxPlanRev, '', 
           '', @UserSeq, GETDATE(), @PgmSeq  
      FROM #KPXCM_TPDMonthProdPlanRev AS A   
     WHERE A.Status = 0      
    
    SELECT * FROM #KPXCM_TPDMonthProdPlanRev   
      
    RETURN  
GO 
exec KPXCM_SPDProdPlanScenarioRevAdd @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <PlanYear>2016</PlanYear>
    <PlanYM>201601</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037130,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030436



