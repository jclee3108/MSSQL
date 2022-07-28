
IF OBJECT_ID('_SPDTestReportMSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportMSaveCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - M����  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
  
CREATE PROCEDURE _SPDTestReportMSaveCHE
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
      
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#PDTestReport'   
   
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TPDTestReport', -- �����̺��                    
                   '#PDTestReport', -- �������̺��                    
                   'TestReportSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq, TestReportSeq,NoticDate,AnalysisDate,ItemTakeDate,CustSeq,ItemSeq,LastUserSeq,LastDateTime'  
  
  
 --DEL  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'D' AND Status = 0)  
 BEGIN  
  DELETE _TPDTestReportUMSpec  
    FROM _TPDTestReportUMSpec AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0  
       
  DELETE _TPDTestReport  
    FROM _TPDTestReport AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0  
       
  DELETE _TPDTestReportD  
    FROM _TPDTestReportD AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0            
       
       
 END  
   
 --UPDATE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'U' AND Status = 0)  
 BEGIN  
  UPDATE A  
     SET NoticDate = B.NoticDate,  
      AnalysisDate = B.AnalysisDate,  
      ItemTakeDate = B.ItemTakeDate,  
      CustSeq  = B.CustSeq,  
      ItemSeq  = B.ItemSeq,   
      LastUserSeq = @UserSeq,  
      LastDateTime = GETDATE()  
    FROM _TPDTestReport AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'U'  
     AND B.Status = 0  
 END  
 --SAVE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'A' AND Status = 0)  
 BEGIN  
      INSERT INTO _TPDTestReport  
   SELECT @CompanySeq, TestReportSeq,NoticDate,AnalysisDate,ItemTakeDate,  
    CustSeq,ItemSeq, @UserSeq, GETDATE()  
     FROM #PDTestReport AS A  
    WHERE A.WorkingTag = 'A'  
      AND A.Status = 0  
 END  
   
 SELECT * FROM #PDTestReport  
  
  RETURN