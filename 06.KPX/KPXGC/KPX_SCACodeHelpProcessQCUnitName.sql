
IF OBJECT_ID('KPX_SCACodeHelpProcessQCUnitName') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpProcessQCUnitName
GO 

-- v2014.11.20 
      
-- 검사단위_KPX by이재천 
CREATE PROC KPX_SCACodeHelpProcessQCUnitName      
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
        
    SELECT QCUnit, 
           QCUnitName
      FROM KPX_TQCQAProcessQCUnit     
     WHERE CompanySeq = @CompanySeq     
       AND QCUnitName LIKE @Keyword + '%'      
    
    SET ROWCOUNT 0      
    
    RETURN     