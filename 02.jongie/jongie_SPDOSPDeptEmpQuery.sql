  
IF OBJECT_ID('jongie_SPDOSPDeptEmpQuery') IS NOT NULL   
    DROP PROC jongie_SPDOSPDeptEmpQuery  
GO  
  
-- v2013.10.29  
  
-- 외주비이체조회_jongie(부서담당자조회) by이재천
CREATE PROC jongie_SPDOSPDeptEmpQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    SET NOCOUNT ON          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED          
       
    DECLARE @docHandle INT  
    
    -- 최종조회   
    SELECT A.EmpSeq, 
           C.EmpName, 
           A.DeptSeq, 
           B.DeptName
           
      FROM _TCAUser AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
     WHERE A.UserSeq = @UserSeq
    
    RETURN  