  
IF OBJECT_ID('KPXCM_SARBizTripCostGWQuery') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostGWQuery  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-조회 by 이재천   
CREATE PROC KPXCM_SARBizTripCostGWQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @BizTripSeq     INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizTripSeq = ISNULL( BizTripSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (BizTripSeq   INT)    
    
    -- 최종조회   
    SELECT A.BizTripSeq, 
           C.EmpName AS TripEmpName, 
           D.DeptName AS TripDeptName, 
           G.UMJpName, 
           A.TripPlace,
           A.TripCust,
           A.TripFrDate, 
           A.TripToDate, 
           A.Purpose, 
           F.MinorName AS UMTripKindName, 
           E.Remark, 
           E.Amt 
        
      FROM KPXCM_TARBizTripCost                 AS A 
      LEFT OUTER JOIN _TDAEmp                   AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.TripEmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.TripDeptSeq ) 
      LEFT OUTER JOIN KPXCM_TARBizTripCostItem  AS E ON ( E.CompanySeq = @CompanySeq AND E.BizTripSeq = A.BizTripSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.UMTripKind ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS G ON ( G.EmpSeq = A.TripEmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizTripSeq = 0 OR A.BizTripSeq = @BizTripSeq ) 
      
    RETURN  
GO
EXEC _SCOMGroupWarePrint 2, 1, 1, 1026397, 'BizTrip_CM', '1', ''