IF OBJECT_ID('KPXCM_SCACodeHelpChmcNameCHE') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpChmcNameCHE
GO 

-- v2015.09.09 

-- KPX용으로 만듬
/************************************************************        
 설  명 - 코드도움SP : capro_화학물질품목      
 작성일 - 20110602        
 작성자 - 박헌기       
************************************************************/        
 CREATE PROCEDURE KPXCM_SCACodeHelpChmcNameCHE      
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
        
    SELECT  A.PrintName   AS PrintName  ,      
            A.ChmcSeq     AS ChmcSeq    ,      
            A.ItemSeq     AS ItemSeq    ,       
            B.ItemName    AS ItemName   ,       
            B.ItemNo      AS ItemNo     ,       
            B.UnitSeq     AS UnitSeq    ,      
            C.UnitName    AS UnitName   ,       
            B.Spec        AS Spec       ,       
            A.ToxicName   AS ToxicName  ,       
            A.MainPurpose AS MainPurpose,       
            A.Content     AS Content          
      FROM  KPXCM_TSEChemicalsListCHE   AS A WITH (NOLOCK)      
            JOIN _TDAItem            AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq      
                                                       AND A.ItemSeq    = B.ItemSeq      
            LEFT OUTER JOIN _TDAUnit AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq      
                                                       AND B.UnitSeq    = C.UnitSeq      
     WHERE  A.CompanySeq = @CompanySeq      
       AND  A.PrintName LIKE '%'+@Keyword+'%'      
       AND (@Param1 = '' OR @Param1 = '0' OR A.ChmcSeq = CONVERT(INT, @Param1))        
       --AND (@Param2 = '' OR @Param2 = '0' OR A.SectionSeq = CONVERT(INT, @Param2))        
       --AND (@Param3 = '' OR @Param3 = '0' OR A.SampleLocSeq = CONVERT(INT, @Param3))        
     ORDER BY PrintName      
        
    SET ROWCOUNT 0        
        
RETURN        
        