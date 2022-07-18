
IF OBJECT_ID('KPX_SCACodeHelpPRBasWelFareAmt') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpPRBasWelFareAmt
GO 

-- v2014.12.09 

-- 복리후생종류 코드도움_KPX by이재천 

-- SP파라미터들  
CREATE PROCEDURE KPX_SCACodeHelpPRBasWelFareAmt  
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
    
    SELECT A.EnvValue AS SMWelFareSort, 
           B.MinorName AS SMWelFareSortName
      FROM KPX_TCOMEnvItem          AS A 
      LEFT OUTER JOIN _TDASMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.EnvValue ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 11 
       AND (@KeyWord = '' OR B.MinorName LIKE @KeyWord + '%')
    
    SET ROWCOUNT 0  
    
    RETURN  