
IF OBJECT_ID('_SPDTestReportSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportSaveCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - ��Ʈ����  
    �ۼ��� : 2011.04.28 ���游  
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
      
    -- ���� ����Ÿ ��� ����    
    CREATE TABLE #PDTestReport (WorkingTag NCHAR(1) NULL)    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#PDTestReport'   
   
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TPDTestReportD', -- �����̺��                    
                   '#PDTestReport', -- �������̺��                    
                   'TestReportSeq, TestReportSerl' , -- Ű�� �������� ���� , �� �����Ѵ�.   
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