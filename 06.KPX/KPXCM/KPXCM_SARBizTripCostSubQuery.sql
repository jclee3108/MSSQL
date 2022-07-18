  
IF OBJECT_ID('KPXCM_SARBizTripCostSubQuery') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostSubQuery  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-List조회 by 이재천   
CREATE PROC KPXCM_SARBizTripCostSubQuery  
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
            @RegDateFr      NCHAR(8), 
            @RegDateTo      NCHAR(8), 
            @RegEmpSeq      INT, 
            @TripEmpSeq     INT, 
            @TripDeptSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @RegDateFr   = ISNULL( RegDateFr   , '' ), 
           @RegDateTo   = ISNULL( RegDateTo   , '' ), 
           @RegEmpSeq   = ISNULL( RegEmpSeq   , 0 ), 
           @TripEmpSeq  = ISNULL( TripEmpSeq  , 0 ), 
           @TripDeptSeq = ISNULL( TripDeptSeq , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock3', @xmlFlags )       
      WITH (
            RegDateFr      NCHAR(8), 
            RegDateTo      NCHAR(8),       
            RegEmpSeq      INT,       
            TripEmpSeq     INT,       
            TripDeptSeq    INT      
           )    
    
    IF @RegDateTo = '' SELECT @RegDateTo = '99991231'
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
       AND (A.RegDate BETWEEN @RegDateFr AND @RegDateTo) 
       AND (@RegEmpSeq = 0 OR A.RegEmpSeq = @RegEmpSeq) 
       AND (@TripEmpSeq = 0 OR A.TripEmpSeq = @TripEmpSeq) 
       AND (@TripDeptSeq = 0 OR A.TripDeptSeq = @TripDeptSeq) 
      
    RETURN  
GO
exec KPXCM_SARBizTripCostSubQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegDateFr />
    <RegDateTo />
    <RegEmpSeq />
    <TripEmpSeq />
    <TripDeptSeq />
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397