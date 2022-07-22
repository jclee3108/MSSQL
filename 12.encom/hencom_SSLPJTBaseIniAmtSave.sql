IF OBJECT_ID('hencom_SSLPJTBaseIniAmtSave') IS NOT NULL 
    DROP PROC hencom_SSLPJTBaseIniAmtSave
GO 

-- v2017.02.24 
/************************************************************  
 설  명 - 데이터-현장별기초잔액등록_hencom : 저장  
 작성일 - 20160219  
 작성자 - 박수영  
************************************************************/  
CREATE PROC dbo.hencom_SSLPJTBaseIniAmtSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #hencom_TSLSalesCreditBasicData (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLSalesCreditBasicData'       
 IF @@ERROR <> 0 RETURN    
       
  -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)  
       
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TSLSalesCreditBasicData')  
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          'hencom_TSLSalesCreditBasicData', -- 원테이블명  
          '#hencom_TSLSalesCreditBasicData', -- 템프테이블명  
          'CBDRegSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
          @TableColumns,  
           '',   
           @PgmSeq   
                     
  
 -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE hencom_TSLSalesCreditBasicData  
     FROM #hencom_TSLSalesCreditBasicData A   
       JOIN hencom_TSLSalesCreditBasicData B ON ( A.CBDRegSeq = B.CBDRegSeq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE hencom_TSLSalesCreditBasicData  
      SET CurAmt     = A.CurAmt     ,  
          DomAmt     = A.CurAmt     ,  
           PJTSeq     = A.PJTSeq     ,  
           DeptSeq    = A.DeptSeq    ,  
           CustSeq    = A.CustSeq  ,  
           Remark     = A.Remark  ,
           BizUnit  =  A.BizUnit,
		   WorkDate = A.WorkDate,
		   ReturnRegSeq = A.ReturnRegSeq
     FROM #hencom_TSLSalesCreditBasicData AS A   
          JOIN hencom_TSLSalesCreditBasicData AS B ON ( A.CBDRegSeq = B.CBDRegSeq )   
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #hencom_TSLSalesCreditBasicData WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO hencom_TSLSalesCreditBasicData ( CompanySeq,CBDRegSeq,CustSeq,DeptSeq,PJTSeq,CurrSeq,Qty,CurAmt  
                                                        ,CurVAT,DomAmt,DomVat,Remark,LastUserSeq,LastDateTime,BizUnit,workdate, ReturnRegSeq )   
                                                          
   SELECT @CompanySeq,CBDRegSeq,CustSeq,DeptSeq,PJTSeq,NULL,0,CurAmt  
                ,0,CurAmt,0,Remark,@UserSeq,GETDATE()  ,BizUnit, workdate, ReturnRegSeq
     FROM #hencom_TSLSalesCreditBasicData AS A     
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
    
    SELECT * FROM #hencom_TSLSalesCreditBasicData 
    
    RETURN 
