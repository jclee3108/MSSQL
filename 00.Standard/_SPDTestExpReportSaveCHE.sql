
IF OBJECT_ID('_SPDTestExpReportSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportSaveCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서등록(영업) : 저장  
 작성일 - 20110922  
 작성자 - 박헌기  
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
           
  
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestExpReport', -- 원테이블명  
          '#TPDTestExpReport', -- 템프테이블명  
          'TestReportSeq,UMSpec  ' , -- 키가 여러개일 경우는 , 로 연결한다.   
          'CompanySeq   ,TestReportSeq,UMSpec       ,UMSpecValue  ,  
                    AnalysisDate ,RgstDate     ,RgstEmpSeq   ,LastUserSeq  ,  
                    LastDateTime'  
                      
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestExpReportList', -- 원테이블명  
          '#TPDTestExpReportList', -- 템프테이블명  
          'TestReportSeq  ,TestReportSerl ' , -- 키가 여러개일 경우는 , 로 연결한다.   
          'CompanySeq     ,TestReportSeq  ,TestReportSerl ,FactUnit       ,  
                    SectionSeq     ,SampleLocSeq   ,AnalysisItemSeq,ItemCodeName   ,  
                    UnitName       ,Spec           ,ResultVal      ,Method         ,  
                    LastUserSeq    ,LastDateTime'            
  
  
 -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
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