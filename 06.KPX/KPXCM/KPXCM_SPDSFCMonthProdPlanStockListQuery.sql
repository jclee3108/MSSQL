  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockListQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockListQuery  
GO  
  
-- v2015.10.22  
  
-- 월생산계획조회-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockListQuery  
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
           A.IsStockCfm 
      FROM KPXCM_TPDSFCMonthProdPlanStock   AS A 
      LEFT OUTER JOIN _TDAFactUnit          AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAEmp               AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept              AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FactUnit = @FactUnit 
       AND LEFT(A.PlanYM,4) = @PlanYear 
       AND A.PlanYM = A.PlanYMSub
    
    RETURN 