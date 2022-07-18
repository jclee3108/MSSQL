IF OBJECT_ID('KPXCM_SQCInQCIResultMasterSave') IS NOT NULL 
    DROP PROC KPXCM_SQCInQCIResultMasterSave
GO 

-- v2016.05.19 

 -- 테이블 수정 by이재천 
 
 -- v2015.11.02 무검사여부 추가 by이재천 
 /************************************************************  
  설  명 - 데이터-수입검사등록_KPX : 저장  
  작성일 - 20141219  
  작성자 - 박상준  
  수정자 -   
 ************************************************************/  
 CREATE PROC KPXCM_SQCInQCIResultMasterSave
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT     = 0,    
     @ServiceSeq     INT     = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT     = 1,    
     @LanguageSeq    INT     = 1,    
     @UserSeq        INT     = 0,    
     @PgmSeq         INT     = 0  
 AS     
     
     CREATE TABLE #KPX_TQCTestResult (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestResult'       
     IF @@ERROR <> 0 RETURN    
     
     -- 로그 남기기    
     DECLARE @TableColumns NVARCHAR(4000)    
       
     -- Master 로그   
     SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResult')    
       
     EXEC _SCOMLog @CompanySeq   ,        
                   @UserSeq      ,        
                   'KPX_TQCTestResult'    , -- 테이블명        
                   '#KPX_TQCTestResult'    , -- 임시 테이블명        
                   'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                   @TableColumns , 'InQCSeq', @PgmSeq  -- 테이블 모든 필드명  
   
     -- DELETE      
     IF EXISTS (SELECT TOP 1 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'D' AND Status = 0)    
     BEGIN    
         
         DELETE B  
           FROM #KPX_TQCTestResult  AS A   
           JOIN KPX_TQCTestResult   AS B ON A.InQCSeq = B.QCSeq 
          WHERE B.CompanySeq = @CompanySeq  
            AND A.WorkingTag = 'D'   
            AND A.Status = 0      
         
         IF @@ERROR <> 0  RETURN  
         
         
         SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TQCTestResultItem')    
           
         EXEC _SCOMLog @CompanySeq   ,        
                       @UserSeq      ,        
                       'KPX_TQCTestResultItem'    , -- 테이블명        
                       '#KPX_TQCTestResult'    , -- 임시 테이블명        
                       'QCSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                       @TableColumns , 'InQCSeq', @PgmSeq  -- 테이블 모든 필드명   
         
         DELETE B  
           FROM #KPX_TQCTestResult      AS A   
           JOIN KPX_TQCTestResultItem   AS B ON A.InQCSeq = B.QCSeq 
          WHERE B.CompanySeq  = @CompanySeq  
            AND A.WorkingTag  = 'D'   
            AND A.Status      = 0      
         
         IF @@ERROR <> 0  RETURN  
     
     END    
    
     -- UPDATE      
     IF EXISTS (SELECT 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'U' AND Status = 0)    
     BEGIN  
         
         UPDATE B  
            SET SMTestResult = A.SMTestResult 
               ,OKQty        = A.OKQty 
               ,BadQty       = A.BadQty
               ,LastUserSeq = @UserSeq  
               ,LastDateTime = GetDate()  
           FROM #KPX_TQCTestResult      AS A JOIN KPX_TQCTestResult       AS B ON A.ReqSeq = B.ReqSeq AND A.ReqSerl = B.ReqSerl 
          WHERE B.CompanySeq = @CompanySeq  
            AND A.WorkingTag = 'U'   
            AND A.Status     = 0      
         
         IF @@ERROR <> 0  RETURN  
     
     END    
   
     -- INSERT  
     IF EXISTS (SELECT 1 FROM #KPX_TQCTestResult WHERE WorkingTag = 'A' AND Status = 0)    
     BEGIN    
         INSERT INTO KPX_TQCTestResult   
         (  
             CompanySeq, QCSeq, QCNo, ItemSeq, LotNo, 
             QCType, SMTestResult, WHSeq, LimitDate, CHLimitDate, 
             CHMonth, ReqSeq, ReqSerl, IsEnd, WorkCenterSeq, 
             LastUserSeq, LastDateTime,
             OKQty, BadQty, IsNoTest
         )   
         SELECT @CompanySeq, A.InQCSeq, A.InQCNo, A.ItemSeq, A.LotNo, 
                A.QCType, A.SMTestResult, 0, '', '', 
                0, ReqSeq, ReqSerl, '0', 0, 
                @UserSeq,   GETDATE(),
                OKQty, BadQty, IsNoTest
           FROM #KPX_TQCTestResult AS A     
          WHERE A.WorkingTag = 'A'   
            AND A.Status = 0      
         
         IF @@ERROR <> 0 RETURN 
     
     END     
     
     SELECT * FROM #KPX_TQCTestResult   
     
 RETURN      
  GO
 BEGIN TRAN
 exec KPXCM_SQCInQCIResultMasterSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <SMTestResult>1010418004</SMTestResult>
    <SMTestResultName>미검사</SMTestResultName>
    <InQCNo>201605190001</InQCNo>
    <LotNo>E115813320</LotNo>
    <ReqNo>201511100022</ReqNo>
    <ReqSeq>14976</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <ReqDate>20151110</ReqDate>
    <InQCSeq>221</InQCSeq>
    <ItemSeq>100</ItemSeq>
    <ItemName>Water C VALVE CV-140</ItemName>
    <ItemNo>2000100</ItemNo>
    <Qty>10080.00000</Qty>
    <DelvNo />
    <CustName />
    <DelvDate xml:space="preserve">        </DelvDate>
    <InOutType>수입</InOutType>
    <QCType>11</QCType>
    <QCTypeName />
    <TestDate>20160519</TestDate>
    <DelvSeq>186</DelvSeq>
    <DelvSerl>1</DelvSerl>
    <SMSourceType>1000522007</SMSourceType>
    <OKQty>0.00000</OKQty>
    <BadQty>0.00000</BadQty>
    <EmpSeq>0</EmpSeq>
    <DeptSeq>0</DeptSeq>
    <SourceType>1</SourceType>
    <IsNoTest>0</IsNoTest>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030782,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026257

select * from KPX_TQCTestResult where reqseq = 14976 and reqserl = 1 
 ROLLBACK TRAN



