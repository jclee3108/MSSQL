IF OBJECT_ID('mnpt_SCACodeHelpWorkTypeMinorNameQuery') IS NOT NULL 
    DROP PROC mnpt_SCACodeHelpWorkTypeMinorNameQuery
GO 

-- v2017.12.18 

-- 작업항목(사용자정의코드) 코드도움 by이재천
CREATE PROCEDURE mnpt_SCACodeHelpWorkTypeMinorNameQuery
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
    
    SELECT A.MinorSeq AS UMWorkType, 
           A.MinorName AS UMWorkTypeName, 
           A.MinorSort 
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND (@Keyword = '' OR A.MinorName LIKE @Keyword)
       AND A.Majorseq = 1015816
     ORDER BY A.MinorSort
  
    SET ROWCOUNT 0 
    
    RETURN
