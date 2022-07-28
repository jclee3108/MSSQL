
IF OBJECT_ID('_SCACodeHelpLactamSampleLocCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpLactamSampleLocCHE 
GO 

/************************************************************    
 ��  �� - �ڵ嵵��SP : ��ŽƮ������ȸ�� �÷���ġ    
 �ۼ��� - 20110329    
 �ۼ��� - �����  
************************************************************/    
 CREATE PROCEDURE dbo._SCACodeHelpLactamSampleLocCHE
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
    
    SELECT A.SampleLocSeq,   
           A.SampleLoc  
      FROM _TPDSampleLoc AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.SampleLocSeq IN (SELECT SampleLocSeq  
                                FROM _TPDAnalysisItem AS L1  
                               WHERE A.CompanySeq = L1.CompanySeq  
                                 AND L1.LactamTrend = '1')  
       AND A.SampleLoc LIKE '%'+@Keyword+'%'  
                               
    SET ROWCOUNT 0    
    
  RETURN