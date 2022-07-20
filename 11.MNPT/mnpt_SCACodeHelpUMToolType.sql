IF OBJECT_ID('mnpt_SCACodeHelpUMToolType') IS NOT NULL
    DROP PROC mnpt_SCACodeHelpUMToolType
GO 

-- v2017.09.19

-- 장비구분 코드도움 by이재천
CREATE PROCEDURE mnpt_SCACodeHelpUMToolType
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
    
    SELECT A.MinorName AS UMToolTypeName, -- 장비구분
           C.ValueText AS UMEnToolTypeName, -- 장비구분명(영문)
           B.ValueText AS UMKrToolTypeName, -- 장비구분명(한글) 
           A.MinorSeq AS UMToolType
      FROM _TDAUMinor                   AS A   
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
	 WHERE A.CompanySeq	= @CompanySeq 
       AND A.MajorSeq = 1015887
       AND (@Keyword = '' OR A.MinorName LIKE @Keyword + '%')
    
    SET ROWCOUNT 0 
    
    RETURN 