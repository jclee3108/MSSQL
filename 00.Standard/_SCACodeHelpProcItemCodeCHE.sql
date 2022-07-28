IF OBJECT_ID('_SCACodeHelpProcItemCodeCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpProcItemCodeCHE
GO 
    
/************************************************************  
 설  명 - 코드도움SP : 공정분석항목  
 작성일 - 20110602  
 작성자 - 천경민  
************************************************************/  
 CREATE PROCEDURE _SCACodeHelpProcItemCodeCHE  
     @WorkingTag     NVARCHAR(1),                                
     @LanguageSeq    INT,                                
     @CodeHelpSeq    INT,                                
     @DefQueryOption INT,     -- 2: direct search                                
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
  
    SELECT C.MinorName AS ItemCodeName,  
           A.ItemCode,  
           D.FactUnitName,  
           S.FactUnit,  
           B.SectionCode,  
           B.SectionName,  
           B.SectionSeq,  
           S.SampleLoc,  
           S.SampleLocSeq  
      FROM _TPDAnalysisItem AS A WITH(NOLOCK)  
           JOIN _TPDSampleLoc      AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq  
                                                         AND A.SampleLocSeq = S.SampleLocSeq  
           JOIN _TPDSectionCode    AS B WITH(NOLOCK) ON S.CompanySeq = B.CompanySeq  
                                                         AND S.SectionSeq = B.SectionSeq  
           LEFT OUTER JOIN _TDAUMinor   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                         AND A.ItemCode   = C.MinorSeq  
           LEFT OUTER JOIN _TDAFactUnit AS D WITH(NOLOCK) ON S.CompanySeq = D.CompanySeq  
                                                         AND S.FactUnit   = D.FactUnit  
     WHERE A.CompanySeq = @CompanySeq  
       AND C.MinorName LIKE @Keyword  
       AND (@Param1 = '' OR @Param1 = '0' OR S.FactUnit = CONVERT(INT, @Param1))  
       AND (@Param2 = '' OR @Param2 = '0' OR B.SectionSeq = CONVERT(INT, @Param2))  
       AND (@Param3 = '' OR @Param3 = '0' OR S.SampleLocSeq = CONVERT(INT, @Param3))  
     ORDER BY A.Serl  
  
    SET ROWCOUNT 0  
  
RETURN  
  