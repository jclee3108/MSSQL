
IF OBJECT_ID('DTI_SCACodeHelpTPJTSalesRev') IS NOT NULL 
    DROP PROC DTI_SCACodeHelpTPJTSalesRev
GO 

-- v2014.03.20 
    
-- 프로젝트별매출이익현황_DTI(차수코드도움) By이재천      
CREATE PROC DTI_SCACodeHelpTPJTSalesRev          
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
    
    SELECT DISTINCT A.Rev AS PlanRev, A.Rev + 1 AS PlanRevSeq
      FROM DTI_TPJTSalesProfitPlan AS A 
     WHERE A.PJTSeq = @Param1 
       AND @KeyWord = '' OR A.Rev LIKE @Keyword
    UNION ALL 
    SELECT 0, 1 
     WHERE NOT EXISTS (SELECT 1 FROM DTI_TPJTSalesProfitPlan WHERE PJTSeq = @Param1)
    
    SET ROWCOUNT 0          
     
     RETURN
GO