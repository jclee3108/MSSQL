  
IF OBJECT_ID('KPXCM_SARBizTripCostQuery') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostQuery  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-조회 by 이재천   
CREATE PROC KPXCM_SARBizTripCostQuery  
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
           A.BizTripNo, 
           A.RegDate, 
           A.RegEmpSeq, 
           B.EmpName AS RegEmpName, 
           A.TripEmpSeq, 
           C.EmpName AS TripEmpName, 
           A.TripDeptSeq, 
           D.DeptName AS TripDeptName, 
           A.TripCCtrSeq, 
           E.CCtrName AS TripCCtrName, 
           A.CostSeq, 
           G.MinorName AS CostName, 
           A.TripPlace,
           A.TripCust,
           A.TripFrDate, 
           A.TripToDate, 
           A.Purpose, 
           A.Contents, 
           A.TripPerson, 
           A.PayReqDate, 
           A.AccUnit, 
           F.AccUnitName, 
           A.WkItemSeq, 
           H.WkItemName 
           
           
      FROM KPXCM_TARBizTripCost     AS A 
      LEFT OUTER JOIN _TDAEmp       AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.RegEmpSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.TripEmpSeq ) 
      LEFT OUTER JOIN _TDADept      AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.TripDeptSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS E ON ( E.CompanySeq = @CompanySeq AND E.CCtrSeq = A.TripCCtrSeq ) 
      LEFT OUTER JOIN _TDAAccUnit   AS F ON ( F.CompanySeq = @CompanySeq AND F.AccUnit = A.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinor    AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.CostSeq ) 
      LEFT OUTER JOIN _TPRWkItem    AS H ON ( H.CompanySeq = @CompanySeq AND H.WkItemSeq = A.WkItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.BizTripSeq = @BizTripSeq ) 
      
    RETURN  
GO
exec KPXCM_SARBizTripCostQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizTripSeq>5</BizTripSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397