
IF OBJECT_ID('DTI_SPNPayPlanQuery') IS NOT NULL
    DROP PROC DTI_SPNPayPlanQuery
    
GO 

-- v2013.07.01

-- [경영계획]급여계획등록(조회)_DTI by 이재천
CREATE PROC DTI_SPNPayPlanQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
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
    
    SELECT @PlanYear = PlanYear,
           @AccUnit = AccUnit 
	  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (PlanYear     NCHAR(4),
            AccUnit      INT
           )
	
    SELECT A.AccUnit, 
           A.PlanYear, 
           A.Serl, 
           A.CCtrSeq, 
           A.EmpSeq , 
           A.DeptSeq,
           A.PayAmt1, 
           A.PayAmt2, 
           A.PayAmt3, 
           A.PayAmt4, 
           A.PayAmt5, 
           A.PayAmt6, 
           A.PayAmt7, 
           A.PayAmt8, 
           A.PayAmt9, 
           A.PayAmt10, 
           A.PayAmt11, 
           A.PayAmt12, 
           C.EmpID, 
           B.EmpName, 
           D.AccUnitName, 
           A.Remark, 
           (A.PayAmt1+A.PayAmt2+A.PayAmt3+A.PayAmt4+A.PayAmt5+A.PayAmt6+A.PayAmt7+A.PayAmt8+A.PayAmt9+A.PayAmt10+A.PayAmt11+A.PayAmt12) AS TotPayAmt,
           E.CCtrName     
      FROM DTI_TPNPayPlan         AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmpIn   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAAccUnit AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.AccUnit = A.AccUnit ) 
      LEFT OUTER JOIN _TDACCtr    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CCtrSeq = A.CCtrSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PlanYear = @PlanYear    
       AND A.AccUnit = @AccUnit     
    
    RETURN
