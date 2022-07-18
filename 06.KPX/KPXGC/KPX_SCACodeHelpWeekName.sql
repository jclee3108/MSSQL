
IF OBJECT_ID('KPX_SCACodeHelpWeekName') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpWeekName
GO 

-- v2014.11.14   
    
-- 주간판매계획-주차코드도움 by 이재천   
CREATE PROC KPX_SCACodeHelpWeekName    
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
      
    SELECT ProdWeekName AS WeekName, 
           Serl AS WeekSeq, 
           DateFr AS FromDate, 
           DateTo AS ToDate 
      FROM _TPDBaseProdWeek   
     WHERE CompanySeq = @CompanySeq   
       AND ProdWeekName LIKE @Keyword + '%'    
      
    SET ROWCOUNT 0    
      
    RETURN    