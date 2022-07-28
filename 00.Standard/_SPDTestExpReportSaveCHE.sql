
IF OBJECT_ID('_SPDTestExpReportSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportSaveCHE
GO 

/************************************************************  
 ��  �� - ������-���輺�������(����) : ����  
 �ۼ��� - 20110922  
 �ۼ��� - �����  
************************************************************/  
CREATE PROC dbo._SPDTestExpReportSaveCHE
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #TPDTestExpReport (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestExpReport'       
 IF @@ERROR <> 0 RETURN    
   
 CREATE TABLE #TPDTestExpReportList (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPDTestExpReportList'       
 IF @@ERROR <> 0 RETURN    
           
  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestExpReport', -- �����̺��  
          '#TPDTestExpReport', -- �������̺��  
          'TestReportSeq,UMSpec  ' , -- Ű�� �������� ���� , �� �����Ѵ�.   
          'CompanySeq   ,TestReportSeq,UMSpec       ,UMSpecValue  ,  
                    AnalysisDate ,RgstDate     ,RgstEmpSeq   ,LastUserSeq  ,  
                    LastDateTime'  
                      
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestExpReportList', -- �����̺��  
          '#TPDTestExpReportList', -- �������̺��  
          'TestReportSeq  ,TestReportSerl ' , -- Ű�� �������� ���� , �� �����Ѵ�.   
          'CompanySeq     ,TestReportSeq  ,TestReportSerl ,FactUnit       ,  
                    SectionSeq     ,SampleLocSeq   ,AnalysisItemSeq,ItemCodeName   ,  
                    UnitName       ,Spec           ,ResultVal      ,Method         ,  
                    LastUserSeq    ,LastDateTime'            
  
  
 -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #TPDTestExpReport WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDTestExpReport  
     FROM #TPDTestExpReport A   
       JOIN _TPDTestExpReport B ON ( A.TestReportSeq  = B.TestReportSeq )   
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
      
   DELETE _TPDTestExpReportList  
     FROM #TPDTestExpReport A   
       JOIN _TPDTestExpReportList B ON ( A.TestReportSeq  = B.TestReportSeq )   
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN      
      
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDTestExpReport WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE _TPDTestExpReport  
      SET AnalysisDate   = A.AnalysisDate   ,  
                   UMSpec         = A.UMSpec         ,  
                   UMSpecValue    = A.UMSpecValue    ,  
                   LastUserSeq    = @UserSeq         ,  
                   LastDateTime   = GETDATE()  
     FROM #TPDTestExpReport AS A   
          JOIN _TPDTestExpReport AS B ON A.TestReportSeq  = B.TestReportSeq  
                                          AND A.UMSpec         = B.UMSpec  
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #TPDTestExpReport WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO _TPDTestExpReport ( CompanySeq   ,TestReportSeq,UMSpec       ,UMSpecValue  ,  
                                                 AnalysisDate ,RgstDate     ,RgstEmpSeq   ,LastUserSeq  ,  
                                                 LastDateTime)   
                                   SELECT @CompanySeq  ,TestReportSeq,UMSpec            ,UMSpecValue  ,  
                                                 AnalysisDate ,CONVERT(NCHAR(8),GETDATE(),112) ,(SELECT H1.EmpSeq  
                                                                                                   FROM _TCAUser AS H1   
                                                                                                  WHERE H1.CompanySeq = @CompanySeq  
                                                                                                    AND H1.UserSeq    = @UserSeq ) ,@UserSeq     ,  
                                                 GETDATE()  
                                   FROM #TPDTestExpReport AS A     
                                  WHERE A.WorkingTag = 'A'   
                                    AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
  
    ------------------------------------------------------------------------------------------------  
    ------------------------------------------------------------------------------------------------  
 IF EXISTS (SELECT TOP 1 1 FROM #TPDTestExpReportList WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDTestExpReportList  
     FROM #TPDTestExpReportList A   
       JOIN _TPDTestExpReportList B ON A.TestReportSeq  = B.TestReportSeq  
                                        AND A.TestReportSerl = B.TestReportSerl  
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN   
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDTestExpReportList WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE _TPDTestExpReportList  
      SET FactUnit        = A.FactUnit       ,  
                   SectionSeq      = A.SectionSeq     ,  
                   SampleLocSeq    = A.SampleLocSeq   ,  
                   AnalysisItemSeq = A.AnalysisItemSeq,  
                   ItemCodeName    = A.ItemCodeName   ,  
                   UnitName        = A.UnitName       ,  
                   Spec            = A.Spec           ,  
                   ResultVal       = A.ResultVal      ,  
                   Method          = A.Method         ,  
                   LastUserSeq     = @UserSeq         ,  
                   LastDateTime    = GETDATE()  
     FROM #TPDTestExpReportList AS A   
          JOIN _TPDTestExpReportList AS B ON A.TestReportSeq  = B.TestReportSeq  
                                           AND A.TestReportSerl = B.TestReportSerl  
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #TPDTestExpReportList WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO _TPDTestExpReportList(  CompanySeq     ,TestReportSeq  ,TestReportSerl ,FactUnit       ,  
                                                     SectionSeq     ,SampleLocSeq   ,AnalysisItemSeq,ItemCodeName   ,  
                                                     UnitName       ,Spec           ,ResultVal      ,Method         ,  
                                                     LastUserSeq    ,LastDateTime)   
                                     SELECT @CompanySeq    ,TestReportSeq  ,TestReportSerl ,FactUnit       ,  
                                                     SectionSeq     ,SampleLocSeq   ,AnalysisItemSeq,ItemCodeName   ,  
                                                     UnitName       ,Spec           ,ResultVal      ,Method         ,  
                                                     @UserSeq       ,GETDATE()  
                                       FROM #TPDTestExpReportList AS A     
                                      WHERE A.WorkingTag = 'A'   
                                        AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
  
  
  
 SELECT * FROM #TPDTestExpReport   
 SELECT * FROM #TPDTestExpReportList  
  RETURN      