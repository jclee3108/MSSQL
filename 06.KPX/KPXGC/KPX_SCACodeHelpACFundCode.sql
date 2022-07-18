 
IF OBJECT_ID('KPX_SCACodeHelpACFundCode') IS NOT NULL
    DROP PROC KPX_SCACodeHelpACFundCode
GO 

-- v2014.12.11
  
-- 상품코드 코드도움_KPX by이재천   
  
-- SP파라미터들    
CREATE PROCEDURE [dbo].[KPX_SCACodeHelpACFundCode]    
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
    
    SELECT A.FundCode, 
           A.FundSeq, 
           A.FundName 
      FROM KPX_TACFundMaster          AS A   
     WHERE A.CompanySeq = @CompanySeq   
       AND (@KeyWord = '' OR A.FundCode LIKE @KeyWord + '%')
    
    SET ROWCOUNT 0    
    
    RETURN   