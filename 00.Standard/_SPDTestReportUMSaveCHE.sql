
IF OBJECT_ID('_SPDTestReportUMSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportUMSaveCHE
GO 

/*********************************************************************************************************************    
    ȭ��� : ���뼺������� - UM����  
    �ۼ��� : 2011.04.28 ���游  
********************************************************************************************************************/   
  
CREATE PROCEDURE _SPDTestReportUMSaveCHE   
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
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#PDTestReport'   
   
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TPDTestReportUMSpec', -- �����̺��                    
                   '#PDTestReport', -- �������̺��                    
                   'TestReportSeq, UMSpec' , -- Ű�� �������� ���� , �� �����Ѵ�.   
                   'CompanySeq, TestReportSeq,UMSpec,UMSpecValue,LastUserSeq,LastDateTime'  
  
--select * from _TPDTestReportUMSpec  
 --DEL  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'D' AND Status = 0)  
 BEGIN  
  DELETE _TPDTestReportUMSpec  
    FROM _TPDTestReportUMSpec AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
           AND A.UMSpec = B.UMSpec  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'D'  
     AND B.Status = 0  
 END  
   
 --UPDATE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'U' AND Status = 0)  
 BEGIN  
  UPDATE A  
     SET UMSpecValue = B.UMSpecValue,      
      --ItemSeq  = B.ItemSeq,   
      LastUserSeq = @UserSeq,  
      LastDateTime = GETDATE()  
    FROM _TPDTestReportUMSpec AS A  
      JOIN #PDTestReport AS B ON A.TestReportSeq = B.TestReportSeq  
           AND A.UMSpec = B.UMSpec  
   WHERE A.CompanySeq = @CompanySeq  
     AND B.WorkingTag = 'U'  
     AND B.Status = 0  
 END  
 --SAVE  
 IF EXISTS (SELECT 1 FROM #PDTestReport WHERE WorkingTag = 'A' AND Status = 0)  
 BEGIN  
  INSERT INTO _TPDTestReportUMSpec  
    SELECT @CompanySeq, TestReportSeq,UMSpec,UMSpecValue, @UserSeq, GETDATE()  
      FROM #PDTestReport AS A  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0  
 END  
   
 SELECT * FROM #PDTestReport  
  
  RETURN