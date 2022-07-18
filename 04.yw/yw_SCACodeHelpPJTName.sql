
IF OBJECT_ID('yw_SCACodeHelpPJTName') IS NOT NULL 
    DROP PROC yw_SCACodeHelpPJTName
GO 
-- v2014.07.15 
    
-- 코드도움-프로젝트명_yw by이재천
CREATE PROCEDURE dbo.yw_SCACodeHelpPJTName  
    @WorkingTag     NVARCHAR(1)      ,    -- WorkingTag        
    @LanguageSeq    INT              ,    -- 언어        
    @CodeHelpSeq    INT              ,    -- 코드도움(코드)        
    @DefQueryOption INT              ,    -- 2: direct search        
    @CodeHelpType   TINYINT          ,        
    @PageCount      INT = 20         ,        
    @CompanySeq     INT = 1          ,        
    @Keyword        NVARCHAR(50) = '',        
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = '',        
    @PageSize       INT = 50        
AS        
    
    SET ROWCOUNT @PageCount      
    
    SELECT A.PJTName, 
           A.PJTNo, 
           A.PJTSeq, 
           A.RegDate, 
           A.BegDate, 
           A.EndDate, 
           B.DeptName AS RegDeptName, 
           C.CustName AS RegCustName, 
           D.EmpName AS RegEmpName, 
           E.EmpName, 
           F.WBSLevelName, 
           G.MinorName AS UMPJTKindName, 
           H.MinorName AS UMStepName, 
           A.UMStep AS UMStepSeq, 
           A.WBSLevelSeq 
           
      FROM YW_TPJTProject           AS A    
      LEFT OUTER JOIN _TDADept      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.RegDeptSeq ) 
      LEFT OUTER JOIN _TDACust      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RegCustSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.RegEmpSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      OUTER APPLY (SELECT TOP 1 WBSLevelName 
                     FROM yw_TPJTWBS 
                    WHERE CompanySeq = @CompanySeq 
                      AND WBSLevelSeq = A.WBSLevelSeq
                  ) AS F 
      LEFT OUTER JOIN _TDAUMinor    AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMPJTKind ) 
      LEFT OUTER JOIN _TDAUMinor    AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = UMStep ) 
    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.PJTName LIKE @Keyword + '%' 
     ORDER BY A.PJTSeq
    
    SET ROWCOUNT 0      
    
    RETURN       
GO
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1002174',@Keyword=N'%%',@Param1=N'',@Param2=N'',@Param3=N'',@Param4=N'',@ConditionSeq=N'0',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=1,@FactUnit=1,@DeptSeq=147,@WkDeptSeq=59,@EmpSeq=2028,@UserSeq=50322