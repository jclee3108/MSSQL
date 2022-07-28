
IF OBJECT_ID('_SPDTestReportItemSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemSaveCHE 
GO 

/************************************************************  
 설  명 - 데이터-시험성적서분석항목Method마스터 : 저장  
 작성일 - 20120718  
 작성자 - 마스터  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemSaveCHE
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #TPDTestReportItem (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestReportItem'       
 IF @@ERROR <> 0 RETURN    
       
  
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestReportItem', -- 원테이블명  
          '#TPDTestReportItem', -- 템프테이블명  
          'Seq           ' , -- 키가 여러개일 경우는 , 로 연결한다.   
          'CompanySeq, Seq         , ItemSeq      ,ItemCode,  
                    Remark    , LastUserSeq , LastDateTime'  
  
  
 -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #TPDTestReportItem WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE _TPDTestReportItem  
     FROM #TPDTestReportItem AS A   
       JOIN _TPDTestReportItem AS B ON ( A.Seq           = B.Seq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
      
   DELETE _TPDTestReportItemDetail  
     FROM #TPDTestReportItem AS A   
       JOIN _TPDTestReportItemDetail AS B ON ( A.Seq           = B.Seq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN      
      
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDTestReportItem WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE _TPDTestReportItem  
      SET ItemSeq       = A.ItemSeq       ,  
                   ItemCode      = A.ItemCode      ,  
                   Remark        = A.Remark        ,  
                   LastUserSeq   = @UserSeq        ,  
                   LastDateTime  = GETDATE()  
     FROM #TPDTestReportItem AS A   
          JOIN _TPDTestReportItem AS B ON ( A.Seq           = B.Seq )   
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #TPDTestReportItem WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO _TPDTestReportItem   
              ( CompanySeq , Seq         , ItemSeq      ,ItemCode,  
                         Remark     , LastUserSeq , LastDateTime)   
         SELECT @CompanySeq, Seq         , ItemSeq      ,ItemCode,  
                         Remark     , @UserSeq    , GETDATE()  
           FROM #TPDTestReportItem AS A     
          WHERE A.WorkingTag = 'A'   
            AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
  
  
 SELECT * FROM #TPDTestReportItem   
RETURN      
     