  
IF OBJECT_ID('DTI_SESMDEmpCCtrRatioQuery') IS NOT NULL   
    DROP PROC DTI_SESMDEmpCCtrRatioQuery  
GO  
    
-- v2013.06.26  
  
-- 사원별 활동센터 배부율 등록(조회)_DTI by 이재천  
CREATE PROC DTI_SESMDEmpCCtrRatioQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT 	= 0,            
    @ServiceSeq     INT 	= 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT 	= 1,            
    @LanguageSeq    INT 	= 1,            
    @UserSeq        INT 	= 0,            
    @PgmSeq         INT 	= 0         
AS        
    
    DECLARE @docHandle  INT,
            @CostYM     NCHAR(6) ,
            @EmpSeq     INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CostYM = CostYM,
           @EmpSeq = EmpSeq
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (CostYM  NCHAR(6) ,
            EmpSeq  INT )
    
    SELECT A.CCtrSeq, 
           A.PayAmt, 
           A.DeptSeq, 
           A.CostYM, 
           A.EmpCnt, 
           B.EmpName, 
           E.EmpID,
           A.EmpSeq, 
           D.CCtrName, 
           F.DeptName,
           A.Remark,
           B.EmpSeq AS EmpSeqOld,
           A.CCtrSeq AS CCtrSeqOld,
           A.TotPayAmt
           
      FROM DTI_TESMDEmpCCtrRatio AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmpIn  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDACCtr   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDADept   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.CostYM = @CostYM   
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
    
    RETURN
GO
