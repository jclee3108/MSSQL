IF OBJECT_ID('mnpt_SCACodeHelpBgtAcc') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpBgtAcc
GO 

-- v2018.02.06

-- 계정과목-예산과목 코드도움 by이재천
CREATE PROCEDURE mnpt_SCACodeHelpBgtAcc
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    SET ROWCOUNT @PageCount      
    
    SELECT DISTINCT 
           A.AccSeq, 
           A.BgtSeq, 
           B.AccName, 
           C.BgtName
      FROM _TACBgtAcc               AS A 
      LEFT OUTER JOIN _TDAAccount   AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACBgtItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.BgtSeq = A.BgtSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@Keyword = '' OR B.AccName LIKE @Keyword + '%')
    
    SET ROWCOUNT 0 
    
    RETURN 
