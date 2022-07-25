  
IF OBJECT_ID('amoerp_SPRWkRequestEmpDeptQuery') IS NOT NULL   
    DROP PROC amoerp_SPRWkRequestEmpDeptQuery  
GO  
  
-- v2013.10.31 
  
-- ����û����(��û��,��û�μ� ��ȸ) by����õ
CREATE PROC amoerp_SPRWkRequestEmpDeptQuery  
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
    
    -- ������ȸ   
    SELECT A.EmpSeq AS EmpSeqS, 
           C.EmpName AS EmpNameS, 
           A.DeptSeq AS DeptSeqS, 
           B.DeptName AS DeptNameS,
           A.EmpSeq AS EmpSeqQ, 
           C.EmpName AS EmpNameQ, 
           A.DeptSeq AS DeptSeqQ, 
           B.DeptName AS DeptNameQ
           
      FROM _TCAUser AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
     WHERE A.UserSeq = @UserSeq
    
    RETURN  