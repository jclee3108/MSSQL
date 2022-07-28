
IF OBJECT_ID('_SPDTestReportUMCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportUMCheckCHE
GO 
/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - UMüũ  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
CREATE PROCEDURE _SPDTestReportUMCheckCHE  
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
            @MaxSeq   INT  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#PDTestReport'       
  
 SELECT * FROM #PDTestReport  
  
RETURN  