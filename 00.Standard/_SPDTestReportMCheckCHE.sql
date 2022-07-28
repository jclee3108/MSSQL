
IF OBJECT_ID('_SPDTestReportMCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportMCheckCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - M체크  
    작성일 : 2011.04.28 전경만  
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
  
    -- 사용할 변수를 선언한다.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @MaxSeq   INT,  
            @BegDate  NCHAR(8),  
            @EndDate  NCHAR(8)  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#PDTestReport'       
  
 SELECT @Count = COUNT(1) FROM #PDTestReport WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)          
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