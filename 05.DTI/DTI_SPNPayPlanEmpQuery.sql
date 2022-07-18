
IF OBJECT_ID('DTI_SPNPayPlanEmpQuery') IS NOT NULL
    DROP PROC DTI_SPNPayPlanEmpQuery

GO
    
-- v2013.07.01

-- [경영계획]급여계획등록(사원가져오기)_DTI by 이재천
CREATE PROC DTI_SPNPayPlanEmpQuery 
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
            @PlanYear   NCHAR(4),
            @AccUnit    INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @PlanYear    = PlanYear,
           @AccUnit     = AccUnit      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (PlanYear     NCHAR(4),
            AccUnit      INT
           )
    
    SELECT A.EmpID,
           A.EmpName,
           E.CCtrName, 
           E.CCtrSeq,
           A.DeptSeq,
           B.DeptName,
           A.EmpSeq,
           C.AccUnit
           
      FROM _fnAdmEmpOrd( @CompanySeq, @PlanYear +'0101' ) AS A
      LEFT OUTER JOIN _TDADept        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _THROrgDeptCCtr AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq AND @PlanYear+'01' BETWEEN BegYM AND EndYM )
      LEFT OUTER JOIN _TDAAccUnit     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDACCtr        AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CCtrSeq = D.CCtrSeq ) 

     WHERE @PlanYear +'0101' BETWEEN A.EntDate AND A.RetireDate
       AND C.AccUnit = @AccUnit 
       AND NOT EXISTS (SELECT EmpSeq 
                         FROM DTI_TPNPayPlan 
                        WHERE CompanySeq = @CompanySeq 
                          AND AccUnit = @AccUnit 
                          AND PlanYear = @PlanYear 
                          AND EmpSeq = A.EmpSeq 
                      )
    
    RETURN
GO

exec DTI_SPNPayPlanEmpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccUnit>1</AccUnit>
    <PlanYear>2013</PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016294,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013969