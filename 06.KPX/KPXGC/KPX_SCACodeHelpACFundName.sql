 
IF OBJECT_ID('KPX_SCACodeHelpACFundName') IS NOT NULL
    DROP PROC KPX_SCACodeHelpACFundName
GO 

-- v2014.12.11
  
-- 상품명 코드도움_KPX by이재천   
  
-- SP파라미터들    
CREATE PROCEDURE [dbo].[KPX_SCACodeHelpACFundName]    
    @WorkingTag     NVARCHAR(1)      ,    
    @LanguageSeq    INT              ,    
    @CodeHelpSeq    INT              ,    
    @DefQueryOption INT              ,    -- 2: direct search    
    @CodeHelpType   TINYINT          ,    
    @PageCount      INT = 20         ,    
    @CompanySeq     INT = 1          ,    
    @Keyword        NVARCHAR(50) = '',    
    @Param1         NVARCHAR(50) = '',    
    @Param2         NVARCHAR(50) = '',    
    @Param3         NVARCHAR(50) = '',    
    @Param4         NVARCHAR(50) = ''    
    
AS    
      
    SET ROWCOUNT @PageCount    
    
    SELECT A.FundName, 
           A.FundSeq, 
           A.FundCode 
      FROM KPX_TACFundMaster          AS A   
     WHERE A.CompanySeq = @CompanySeq   
       AND (@KeyWord = '' OR A.FundName LIKE @KeyWord + '%') 
       AND (@Param1 = 0 OR @Param1 <> A.FundSeq)
    
    SET ROWCOUNT 0    
    
    RETURN   