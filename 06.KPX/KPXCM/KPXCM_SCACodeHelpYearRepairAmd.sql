
IF OBJECT_ID('KPXCM_SCACodeHelpYearRepairAmd') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpYearRepairAmd
GO 

-- v2015.07.13 

-- 연차보수년도차수_KPXCM 코드도움 by이재천 
CREATE PROC KPXCM_SCACodeHelpYearRepairAmd    
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
                
    SELECT A.Amd, 
           A.Amd AS AmdSeq 
      FROM KPXCM_TEQYearRepairPeriodCHE AS A    
     WHERE A.CompanySeq = @CompanySeq    
       AND (@Param1 = A.FactUnit) 
       AND (@Param2 = A.RepairYear)
     ORDER BY A.Amd 
    
    SET ROWCOUNT 0              
    
    RETURN          