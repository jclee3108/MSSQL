
IF OBJECT_ID('KPXCM_SCACodeHelpYearRepair') IS NOT NULL 
    DROP PROC KPXCM_SCACodeHelpYearRepair
GO 

-- v2015.07.13 

-- 연차보수년도_KPXCM 코드도움 by이재천 
CREATE PROC KPXCM_SCACodeHelpYearRepair    
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
                
    SELECT DISTINCT 
           A.RepairYear, 
           A.RepairYear AS RepairYearSeq 
      FROM KPXCM_TEQYearRepairPeriodCHE AS A    
     WHERE A.CompanySeq = @CompanySeq    
       AND (@Param1 = A.FactUnit)
    
    SET ROWCOUNT 0              
    
    RETURN          