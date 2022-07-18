
IF OBJECT_ID('yw_SCACodeHelpToolNo') IS NOT NULL 
    DROP PROC yw_SCACodeHelpToolNo
GO 

-- v2014.08.26 
  
-- 금형번호_yw 코드헬프 by이재천 
CREATE PROCEDURE yw_SCACodeHelpToolNo
   
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
    
    SELECT B.ToolNo, 
           A.ToolSeq, 
           B.ToolName, 
           A.PJTSeq, 
           C.PJTName, 
           C.PJTNo, 
           
           D.MinorName AS UMPJTKindName, 
           C.UMPJTKind, 
           
           E.EmpName, 
           C.EmpSeq, 
           
           C.WBSLevelSeq, 
           F.WBSLevelName 
           
           
      FROM YW_TPJTProjectTool           AS A 
      LEFT OUTER JOIN _TPDTool          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN yw_TPJTProject    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMPJTKind ) 
      LEFT OUTER JOIN _TDAEmp           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = C.EmpSeq ) 
      OUTER APPLY (SELECT TOP 1 WBSLevelName 
                         FROM yw_TPJTWBS AS Z 
                        WHERE Z.CompanySeq = @CompanySeq
                          AND Z.WBSLevelSeq = C.WBSLevelSeq
                  ) AS F 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.ToolNo LIKE @Keyword + '%'
    SET ROWCOUNT 0    
    
    RETURN  