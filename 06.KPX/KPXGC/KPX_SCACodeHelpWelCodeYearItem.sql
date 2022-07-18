
IF OBJECT_ID('m') IS NOT NULL 
    DROP PROC KPX_SCACodeHelpWelCodeYearItem
GO 

-- v2014.12.02   
        
-- 신청기간코드도움_KPX by이재천   
CREATE PROC KPX_SCACodeHelpWelCodeYearItem        
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
          
    SELECT A.RegName, 
           A.RegSeq, 
           A.DateFr, 
           A.DateTo, 
           A.EmpAmt, 
           B.YearLimite, 
           B.SMRegType, 
           C.MinorName AS SMRegTypeName 
      FROM KPX_THRWelCodeYearItem AS A 
      LEFT OUTER JOIN KPX_THRWelCode AS B ON ( B.CompanySeq = @CompanySeq AND B.WelCodeSeq = A.WelCodeSeq )
      LEFT OUTER JOIN _TDASMinor     AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.SMRegType ) 
     WHERE A.CompanySeq = @CompanySeq       
       AND A.RegName LIKE @Keyword + '%'        
      
    SET ROWCOUNT 0        
      
      RETURN      