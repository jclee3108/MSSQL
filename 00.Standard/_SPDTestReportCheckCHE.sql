
IF OBJECT_ID('_SPDTestReportCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportCheckCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - üũ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportCheckCHE  
    @xmlDocument NVARCHAR(MAX)   ,  
    @xmlFlags    INT = 0         ,  
    @ServiceSeq  INT = 0         ,  
    @WorkingTag  NVARCHAR(10)= '',    
    @CompanySeq  INT = 1         ,  
    @LanguageSeq INT = 1         ,  
    @UserSeq     INT = 0         ,  
    @PgmSeq      INT = 0  
  
AS  
  
    -- ����� ������ �����Ѵ�.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @MaxSerl  INT  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#PDTestReport'       
  
 SELECT @Seq = TestReportSeq FROM #PDTestReport  
 -- ����update---------------------------------------------------------------------------------------------------------------    
    SELECT @MaxSerl = ISNULL(MAX(TestReportSerl), 0)    
      FROM _TPDTestReportD     
     WHERE CompanySeq = @CompanySeq  
       AND TestReportSeq = @Seq    
    
    UPDATE #PDTestReport    
       SET TestReportSerl = @MaxSerl + DataSeq    
      FROM #PDTestReport    
     WHERE WorkingTag = 'A'     
       AND Status = 0    
         
    SELECT * FROM #PDTestReport  
    
    RETURN