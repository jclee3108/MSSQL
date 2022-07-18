 
IF OBJECT_ID('KPX_SCACodeHelpACEvalProfitItemFundCode') IS NOT NULL
    DROP PROC KPX_SCACodeHelpACEvalProfitItemFundCode
GO 

-- v2014.12.11
  
-- 평가손익상품코드 코드도움_KPX by이재천   
  
-- SP파라미터들    
CREATE PROCEDURE KPX_SCACodeHelpACEvalProfitItemFundCode
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
    
    SELECT B.FundName, 
           B.FundSeq, 
           B.FundCode, 
           A.FundNo
      FROM KPX_TACEvalProfitItemMaster  AS A  
      LEFT OUTER JOIN KPX_TACFundMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.FundSeq = A.FundSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND (@KeyWord = '' OR B.FundName LIKE @KeyWord + '%') 
    
    SET ROWCOUNT 0    
    
    RETURN   