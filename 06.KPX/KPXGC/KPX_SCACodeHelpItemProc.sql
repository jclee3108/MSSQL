
IF OBJECT_ID('KPX_SCACodeHelpItemProc') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpItemProc
GO 

-- v2014.09.26 
  
-- 제품별공정코드도움_KPX by 이재천
CREATE PROCEDURE KPX_SCACodeHelpItemProc
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
           H.FactUnitName, 
           F.FactUnit, 
           A.ProcNo,  
           B.ProcSeq,  
           B.ProcName, 
           A.ToProcNo, 
           A.IsProcQC, 
           A.IsLastProc     
      FROM _TPDProcTypeItem                 AS A 
      JOIN _TPDROUItemProcRevFactUnit       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = @Param1 ) 
      LEFT OUTER JOIN _TPDROUItemProcMat    AS E WITH(NOLOCK) ON ( E.CompanySeq = A.CompanySeq AND E.ItemSeq = @Param1 AND E.ProcSeq = A.ProcSeq and E.BOMRev = F.BOMRev )  
      LEFT OUTER JOIN _TPDBaseProcess       AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ProcSeq = B.ProcSeq ) 
      LEFT OUTER JOIN _TDAItem              AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND E.AssyItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TPDROUItemProcWC     AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ProcSeq = B.ProcSeq AND G.BOMRev = @BOMRev AND G.ItemSeq = @Param1 AND G.FactUnit = F.FactUnit ) 
      LEFT OUTER JOIN _TDAFactUnit          AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.FactUnit = F.FactUnit ) 
    WHERE A.CompanySeq = @CompanySeq
      AND (@Param2 = 0 OR G.WorkCenterSeq = @Param2) 
      AND (@KeyWord = '' OR B.ProcName LIKE @KeyWord + '%')
      AND A.ProcTypeSeq IN (SELECT ProcTypeSeq   
                              FROM _TPDROUItemProcRev   
                             WHERE ItemSeq = @Param1
                               AND CompanySeq = @CompanySeq 
                           )
    GO 
exec _SCACodeHelpQuery @WorkingTag=N'Q',@CompanySeq=1,@LanguageSeq=1,@CodeHelpSeq=N'1020043',@Keyword=N'%%',@Param1=N'1001148',@Param2=N'0',@Param3=N'',@Param4=N'',@ConditionSeq=N'1',@PageCount=N'1',@PageSize=N'50',@SubConditionSql=N'',@AccUnit=N'1',@BizUnit=2,@FactUnit=0,@DeptSeq=1300,@WkDeptSeq=147,@EmpSeq=2028,@UserSeq=50322