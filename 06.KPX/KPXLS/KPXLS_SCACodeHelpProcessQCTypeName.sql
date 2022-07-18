IF OBJECT_ID('KPXLS_SCACodeHelpProcessQCTypeName') IS NOT NULL 
    DROP PROC KPXLS_SCACodeHelpProcessQCTypeName
GO 

-- v2016.01.04 

-- 검사공정_KPX by이재천   

CREATE PROC KPXLS_SCACodeHelpProcessQCTypeName 
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
       
    SELECT DISTINCT A.QCType, B.QCTypeName 
      FROM KPX_TQCQAQualityAssuranceSpec    AS A 
      JOIN KPX_TQCQAProcessQCType           AS B ON ( B.CompanySeq = A.CompanySeq AND B.QCType = A.QCType ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CustSeq = @Param1
       AND A.ItemSeq = @Param2 
      
    SET ROWCOUNT 0       
       
    RETURN

GO



