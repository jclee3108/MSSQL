  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanScenarioQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanScenarioQuery  
GO  
  
-- v2016.05.24 
  
-- 생산계획시나리오-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanScenarioQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PlanSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanSeq   = ISNULL( PlanSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlanSeq   INT)    
    
    -- 최종조회   
    SELECT A.PlanSeq, 
           A.FactUnit, 
           B.FactUnitName, 
           A.PlanNo, 
           A.PlanYM, 
           A.EmpSeq, 
           C.EmpName, 
           A.DeptSeq, 
           D.DeptName, 
           A.IsStockCfm, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptProdSalesQty1 / 1000 ELSE A.RptProdSalesQty1 END AS RptProdSalesQty1, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptProdSalesQty2 / 1000 ELSE A.RptProdSalesQty2 END AS RptProdSalesQty2, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptSelfQty1 / 1000 ELSE A.RptSelfQty1 END AS RptSelfQty1, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptSelfQty2 / 1000 ELSE A.RptSelfQty2 END AS RptSelfQty2, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptSalesQty1 / 1000 ELSE A.RptSalesQty1 END AS RptSalesQty1, 
           CASE WHEN @WorkingTag = 'P' THEN A.RptSalesQty2 / 1000 ELSE A.RptSalesQty2 END AS RptSalesQty2, 
           A.IsCfm, 
           CONVERT(INT,A.PlanRev) AS PlanRevSeq 
      FROM KPXCM_TPDSFCMonthProdPlanScenario    AS A 
      LEFT OUTER JOIN _TDAFactUnit              AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAEmp                   AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq       
       AND A.PlanSeq = @PlanSeq 
       AND A.PlanYM = A.PlanYMSub 
    
    RETURN  
go
exec KPXCM_SPDSFCMonthProdPlanScenarioQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanSeq>6</PlanSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037148,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030445