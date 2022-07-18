
IF OBJECT_ID('DTI_SPNPayPlanCCtrQuery') IS NOT NULL
    DROP PROC DTI_SPNPayPlanCCtrQuery

GO
    
-- v2013.07.08

-- [경영계획]급여계획등록_DTI(사원으로 활동센터가저오기) by 이재천
CREATE PROC DTI_SPNPayPlanCCtrQuery 
    @xmlDocument    NVARCHAR(MAX),            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0         
AS 
    
    DECLARE @docHandle  INT,
            @EmpSeq     INT,
            @PlanYear   NCHAR(4)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpSeq = EmpSeq,
           @PlanYear = PlanYear
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            EmpSeq INT,
            PlanYear NCHAR(4)
           )
    
    SELECT A.EmpName,
           ISNULL(E.CCtrName, '') AS CCtrName, 
           ISNULL(E.CCtrSeq, 0) AS CCtrSeq, 
           A.DeptSeq,
           A.EmpSeq
           
      FROM _fnAdmEmpOrd( @CompanySeq, @PlanYear +'0101' ) AS A
      LEFT OUTER JOIN _TDADept        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _THROrgDeptCCtr AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq AND @PlanYear+'01' BETWEEN BegYM AND EndYM )
      LEFT OUTER JOIN _TDACCtr        AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CCtrSeq = D.CCtrSeq ) 

     WHERE @PlanYear +'0101' BETWEEN A.EntDate AND A.RetireDate
       AND @EmpSeq = A.EmpSeq
    
    RETURN
GO

exec DTI_SPNPayPlanCCtrQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpSeq>47</EmpSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PlanYear>2013</PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016294,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013969