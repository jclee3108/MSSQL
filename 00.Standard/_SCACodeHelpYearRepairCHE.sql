
IF OBJECT_ID('_SCACodeHelpYearRepairCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpYearRepairCHE
GO 


/************************************************************      
 설  명 - 코드도움SP : capro_연차보수접수차수      
 작성일 - 20120223    
 작성자 - 이재현      
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
    
    
    