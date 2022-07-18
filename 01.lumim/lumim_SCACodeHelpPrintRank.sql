  
IF OBJECT_ID('lumim_SCACodeHelpPrintRank') IS NOT NULL
    DROP PROC lumim_SCACodeHelpPrintRank
GO

-- v2013.08.06  

-- 랭크(출력용)_lumim by이재천
CREATE PROC lumim_SCACodeHelpPrintRank        
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
    SET ROWCOUNT @PageCount                              
      
    SELECT A.MinorSeq AS PrintRankSeq,
           B.ValueText AS PrintRank
      FROM _TDAUMinor AS A WITH(NOLOCK)
      JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000006 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1008247 
       AND B.Serl = 1000006
      
    SET ROWCOUNT 0             
                 
    RETURN  
