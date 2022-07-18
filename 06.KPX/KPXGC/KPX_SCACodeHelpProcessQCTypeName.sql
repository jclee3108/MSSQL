
IF OBJECT_ID('KPX_SCACodeHelpProcessQCTypeName') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpProcessQCTypeName
GO 

-- v2014.11.20 
      
-- 검사공정_KPX by이재천 
CREATE PROC KPX_SCACodeHelpProcessQCTypeName      
    @WorkingTag     NVARCHAR(1),                              
    @LanguageSeq    INT,                              
    @CodeHelpSeq    INT,                              
    @DefQueryOption INT,            
    @CodeHelpType   TINYINT,                              
    @PageCount      INT = 20,                   
    @CompanySeq     INT = 1,                             
    @Keyword        NVARCHAR(200) = '',                              
    @Param1         NVARCHAR(50) = '',   
    @Param2         NVARCHAR(50) = '',   
    @Param3         NVARCHAR(50) = '',                  
    @Param4         NVARCHAR(50) = ''     
      
    WITH RECOMPILE            
AS      
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED          
        
    SET ROWCOUNT @PageCount            
        
    SELECT QCTypeName, 
           QCType
      FROM KPX_TQCQAProcessQCType     
     WHERE CompanySeq = @CompanySeq     
       AND QCTypeName LIKE @Keyword + '%'      
    
    SET ROWCOUNT 0      
    
    RETURN     