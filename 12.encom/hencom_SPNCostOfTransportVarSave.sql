IF OBJECT_ID('hencom_SPNCostOfTransportVarSave') IS NOT NULL 
    DROP PROC hencom_SPNCostOfTransportVarSave
GO 

-- v2017.04.21

/************************************************************  
 설  명 - 데이터-사업계획운송비변수등록_hencom : 저장  
 작성일 - 20161109  
 작성자 - 박수영  
************************************************************/  
CREATE PROC dbo.hencom_SPNCostOfTransportVarSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #hencom_TPNCostOfTransportVar (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TPNCostOfTransportVar'       
 IF @@ERROR <> 0 RETURN    
       
  
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
 DECLARE @TableColumns NVARCHAR(4000)  
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TPNCostOfTransportVar')   
                      
 -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)                 
    EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    'hencom_TPNCostOfTransportVar', -- 원테이블명  
                    '#hencom_TPNCostOfTransportVar', -- 템프테이블명  
                    'COTVRegSeq ' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    @TableColumns,
                    '',
                    @PgmSeq   
                                      
 -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN    
   DELETE hencom_TPNCostOfTransportVar  
     FROM #hencom_TPNCostOfTransportVar A   
       JOIN hencom_TPNCostOfTransportVar B ON ( A.COTVRegSeq = B.COTVRegSeq )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE hencom_TPNCostOfTransportVar  
      SET           BPYm            = A.BPYm            ,  
                    OwnMilege       = A.OwnMilege       ,  
                    LentMilege      = A.LentMilege      ,  
                    MTCnt           = A.MTCnt           ,  
                    OilAid          = A.OilAid          ,  
                    LentRotation    = A.LentRotation    ,  
                    WaterUseRate    = A.WaterUseRate    ,  
                    OwnOTRate       = A.OwnOTRate       ,  
                    OwnOTMNRate     = A.OwnOTMNRate     ,  
                    OwnReturnRate   = A.OwnReturnRate   ,  
                    MinPreserveRate = A.MinPreserveRate ,  
                    PayforMeal      = A.PayforMeal      ,  
                    IndusAccidInsur = A.IndusAccidInsur ,  
                    EtcCost         = A.EtcCost         ,  
                    Remark          = A.Remark          ,  
                    LentUseRate     = A.LentUseRate     , --용차사용율
                    LastUserSeq     = @UserSeq          ,  
                    LastDateTime    = GETDATE()         , 
                    LentAvgAmt      = A.LentAvgAmt
     FROM #hencom_TPNCostOfTransportVar AS A   
          JOIN hencom_TPNCostOfTransportVar AS B ON ( A.COTVRegSeq = B.COTVRegSeq )   
                           
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
        
   IF @@ERROR <> 0  RETURN  
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #hencom_TPNCostOfTransportVar WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
   INSERT INTO hencom_TPNCostOfTransportVar ( CompanySeq ,COTVRegSeq ,DeptSeq ,BPYm ,OwnMilege ,LentMilege ,  
                                                        MTCnt ,OilAid ,LentRotation ,WaterUseRate ,OwnOTRate ,OwnOTMNRate ,  
        OwnReturnRate ,MinPreserveRate ,PayforMeal ,IndusAccidInsur ,EtcCost ,  
                                                        Remark ,LastUserSeq ,LastDateTime ,PlanSeq,LentUseRate , LentAvgAmt)   
   SELECT @CompanySeq ,COTVRegSeq ,DeptSeq ,BPYm ,OwnMilege ,LentMilege ,  
      MTCnt ,OilAid ,LentRotation ,WaterUseRate ,OwnOTRate ,OwnOTMNRate ,  
                                                        OwnReturnRate ,MinPreserveRate ,PayforMeal ,IndusAccidInsur ,EtcCost ,  
                                                        Remark ,@UserSeq ,GETDATE() ,PlanSeq  ,LentUseRate , LentAvgAmt
                    
    FROM #hencom_TPNCostOfTransportVar AS A     
    WHERE A.WorkingTag = 'A'   
      AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
 END     
  
  
 SELECT * FROM #hencom_TPNCostOfTransportVar   
RETURN
