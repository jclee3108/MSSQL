
IF OBJECT_ID('_SCACodeHelpYearRepairCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpYearRepairCHE
GO 


/************************************************************      
 ��  �� - �ڵ嵵��SP : capro_����������������      
 �ۼ��� - 20120223    
 �ۼ��� - ������      
************************************************************/      
 CREATE PROCEDURE _SCACodeHelpYearRepairCHE      
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
      
      
 SELECT RepairYear, Amd     
   FROM _TEQYearRepairPeriodCHE  
  WHERE CompanySeq = @CompanySeq    
    AND (@Param1 = '' OR RepairYear = @Param1)    
  --GROUP BY RepairYear, Amd    
  ORDER BY RepairYear, Amd    
    
    
    SET ROWCOUNT 0      
      
  RETURN  
    
    
    