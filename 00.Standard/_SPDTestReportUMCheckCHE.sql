
IF OBJECT_ID('_SPDTestReportUMCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportUMCheckCHE
GO 
/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - UM체크  
    작성일 : 2011.04.28 전경만  
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
  
    -- 사용할 변수를 선언한다.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @MaxSeq   INT  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#PDTestReport'       
  
 SELECT * FROM #PDTestReport  
  
RETURN  