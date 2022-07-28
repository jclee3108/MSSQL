
IF OBJECT_ID('_SPDTestReportCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportCheckCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - 체크  
    작성일 : 2011.04.28 전경만  
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
  
    -- 사용할 변수를 선언한다.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @MaxSerl  INT  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#PDTestReport'       
  
 SELECT @Seq = TestReportSeq FROM #PDTestReport  
 -- 순번update---------------------------------------------------------------------------------------------------------------    
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