  
IF OBJECT_ID('DTI_SESMDEmpCCtrRatioPayQuery') IS NOT NULL   
    DROP PROC DTI_SESMDEmpCCtrRatioPayQuery
GO  
    
-- v2013.06.26  
  
-- 사원별 활동센터 배부율 등록(급여조회)_DTI by 이재천
CREATE PROC DTI_SESMDEmpCCtrRatioPayQuery 
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
		    @EmpSeq     INT ,
            @CostYM     NCHAR(6)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpSeq = EmpSeq,
           @CostYM = CostYM      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (EmpSeq      INT ,
            CostYM      NCHAR(6) )
    
    SELECT E.EmpID, 
           A.EmpSeq, 
           A.DeptSeq AS DeptSeq,
           B.EmpName, 
           G.CCtrSeq AS CCtrSeq, 
           G.CCtrName AS CCtrName, 
           A.TotPayAmt AS PayAmt,
           (SELECT TOP 1 DeptName FROM _TDADeptHist WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq AND BegDate <= H.EndDate AND EndDate >= H.EndDate) AS DeptName, 
           A.EmpSeq AS EmpSeqOld,
           G.CCtrSeq AS CCtrSeqOld,
           A.TotPayAmt AS TotPayAmt  -- 계산하기위한 총 급여액
           
      FROM _TPRPayResult AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp         AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmpIn       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq )
      LEFT OUTER JOIN _THROrgDeptCCtr AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq AND @CostYM BETWEEN BegYM AND EndYM ) 
      LEFT OUTER JOIN _TDACCtr        AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CCtrSeq = D.CCtrSeq ) 
      LEFT OUTER JOIN _TPRBasPb       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.PbSeq = A.PbSeq ) -- 급상여구분
      LEFT OUTER JOIN _TPRPayDateDtl  AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.PuSeq = A.PuSeq AND H.PbYM = A.PbYM AND H.SerialNo = A.SerialNo ) 
     WHERE A.CompanySeq = @CompanySeq
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND A.PbYm = @CostYM     
       AND F.SMPbType = (SELECT EnvValue FROM DTI_TCOMEnv WITH(NOLOCK) where CompanySeq = @CompanySeq AND EnvSeq = 4 AND EnvSerl = 1 ) -- 급상여종류 
    
    RETURN
GO
