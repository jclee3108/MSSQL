
IF OBJECT_ID('_SPDTestReportMCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportMCheckCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - Müũ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportMCheckCHE 
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
            @MaxSeq   INT,  
            @BegDate  NCHAR(8),  
            @EndDate  NCHAR(8)  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#PDTestReport'       
  
 SELECT @Count = COUNT(1) FROM #PDTestReport WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)          
    IF @count > 0    
    BEGIN     
        EXEC @Seq = _SCOMCreateSeq @CompanySeq, '_TPDTestReport', 'TestReportSeq', @Count   
    END    
  
    UPDATE #PDTestReport    
       SET TestReportSeq = @Seq + DataSeq  
     WHERE WorkingTag = 'A'    
       AND Status = 0    
  
         
    SELECT * FROM #PDTestReport  
    
    RETURN