
IF OBJECT_ID('_SPDTestReportSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportSaveCHE
GO 

/*********************************************************************************************************************    
    화면명 : 시헝성적서등록 - 시트저장  
    작성일 : 2011.04.28 전경만  
********************************************************************************************************************/   
  
CREATE PROCEDURE _SPDTestReportSaveCHE 
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',   
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE @docHandle  INT  
      
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#PDTestReport'   
   
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TPDTestReportD', -- 원테이블명                    
                   '#PDTestReport', -- 템프테이블명                    
                   'TestReportSeq, TestReportSerl' , -- 키가 여러개일 경우는 , 로 연결한다.   
                   'CompanySeq    ,TestReportSeq ,TestReportSerl,FactUnit      ,  
                    SectionSeq    ,SampleLocSeq  ,ItemCode      ,Unit          ,  
                    ResultVal     ,LastUserSeq   ,LastDateTime'  
  
--select * from _TPDTestReportD  
 --DEL  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'D' AND Status = 0)  
 BEGIN  
  DELETE _TPDTestReportD  
    FROM _TPDTestReportD AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
           AND A.TestReportSerl = B.TestReportSerl  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0  
 END  
   
 --UPDATE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'U' AND Status = 0)  
 BEGIN  
  UPDATE A  
     SET FactUnit      = B.FactUnit,  
      SectionSeq  = B.SectionSeq,  
      SampleLocSeq  = B.SampleLocSeq,  
      ItemCode   = B.ItemCode,  
      Unit     = B.Unit,  
      ResultVal  = B.ResultVal,  
      LastUserSeq  = @UserSeq,  
      LastDateTime  = GETDATE()  
    FROM _TPDTestReportD AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
           AND A.TestReportSerl = B.TestReportSerl  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'U'  
     AND B.Status = 0  
 END  
 --SAVE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'A' AND Status = 0)  
 BEGIN  
  INSERT INTO _TPDTestReportD  
    SELECT @CompanySeq, TestReportSeq,TestReportSerl,FactUnit,SectionSeq,  
     SampleLocSeq,ItemCode,Unit,  
     ResultVal, @UserSeq, GETDATE()  
      FROM #PDTestReport AS A  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0  
 END  
  
 SELECT * FROM #PDTestReport  
  
RETURN  