
IF OBJECT_ID('KPX_SCACodeHelpItemWorkCenter') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpItemWorkCenter
GO 

-- v2014.09.26 
  
-- 제품별워크센터코드도움_KPX by 이재천
CREATE PROCEDURE KPX_SCACodeHelpItemWorkCenter
    @WorkingTag     NVARCHAR(1),                          
    @LanguageSeq    INT,                          
    @CodeHelpSeq    INT,                          
    @DefQueryOption INT,        
    @CodeHelpType   TINYINT,                          
    @PageCount      INT = 20,               
    @CompanySeq     INT = 1,                         
    @Keyword        NVARCHAR(200) = '',                          
    @Param1         NVARCHAR(50) = '',      --활동센터분류(구분자로 받는다.)        
    @Param2         NVARCHAR(50) = '',      --제조/판관/프로젝트        
    @Param3         NVARCHAR(50) = '',      --원가단위        
    @Param4         NVARCHAR(50) = '',         
    @SubConditionSql   nvarchar(200)=''      
  
    WITH RECOMPILE        
AS  
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
  
    SET ROWCOUNT @PageCount   
    
    DECLARE @BOMRev NCHAR(2)
    SELECT @BOMRev = '00' 
    
    SELECT DISTINCT 
           B.WorkCenterName, 
           A.WorkCenterSeq, 
           D.FactUnitName, 
           A.FactUnit, 
           E.MinorName AS SMWorkCenterTypeName, 
           B.SMWorkCenterType
       FROM _TPDROUItemProcWC               AS A WITH(NOLOCK) 
       LEFT OUTER JOIN _TPDBaseWorkCenter   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq ) 
       LEFT OUTER JOIN _TDACust             AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND B.CustSeq = C.CustSeq ) 
       LEFT OUTER JOIN _TDAFactUnit         AS D WITH(NOLOCK) ON ( D.CompanySeq = A.CompanySeq AND D.FactUnit = A.FactUnit ) 
       LEFT OUTER JOIN _TDASMinor           AS E WITH(NOLOCK) ON ( E.CompanySeq = B.CompanySeq AND E.MinorSeq = B.SMWorkCenterType ) 
   WHERE A.CompanySeq = @CompanySeq
        AND (@KeyWord = '' OR B.WorkCenterName LIKE @KeyWord + '%')
        AND A.BOMRev = @BOMRev           
        AND A.ItemSeq = @Param1          
        AND (@Param2 = 0 OR A.ProcSeq = @Param2)
    GO 
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1020044',@Keyword=N'%%',@Param1=N'0',@Param2=N'0',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=2,@FactUnit=0,@DeptSeq=1300,@WkDeptSeq=147,@EmpSeq=2028,@UserSeq=50322
