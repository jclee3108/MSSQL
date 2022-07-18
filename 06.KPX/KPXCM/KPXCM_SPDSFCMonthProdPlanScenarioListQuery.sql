  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanScenarioListQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanScenarioListQuery  
GO  
  
-- v2016.05.26 
  
-- 생산계획시나리오조회-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanScenarioListQuery  
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
            @FactUnit   INT,  
            @PlanYear   NCHAR(4)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit, 0 ),  
           @PlanYear   = ISNULL( PlanYear, '')
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit    INT, 
            PlanYear    NCHAR(4)
           )    
    
    -- 최종조회   
    SELECT A.PlanSeq, 
           A.FactUnit, 
           B.FactUnitName, 
           A.PlanYM, 
           A.PlanNo, 
           A.EmpSeq, 
           C.EmpName, 
           A.DeptSeq, 
           D.DeptName, 
           A.IsStockCfm, 
           A.PlanRev, 
           E.PlanRevName
      FROM KPXCM_TPDSFCMonthProdPlanScenario    AS A 
      LEFT OUTER JOIN _TDAFactUnit              AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAEmp                   AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN KPXCM_TPDMonthProdPlanRev AS E ON ( E.CompanySeq = @CompanySeq 
                                                      AND E.FactUnit = A.FactUnit 
                                                      AND E.PlanYM = A.PlanYM 
                                                      AND E.PlanRev = A.PlanRev 
                                                        ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND LEFT(A.PlanYM,4) = @PlanYear 
       AND A.PlanYM = A.PlanYMSub 
       --AND CONVERT(INT,A.PlanRev) = @PlanRevSeq 
    
    RETURN 
    go
    exec KPXCM_SPDSFCMonthProdPlanScenarioListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <PlanYear>2016</PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037176,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030458