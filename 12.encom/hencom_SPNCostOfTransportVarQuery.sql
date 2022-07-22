IF OBJECT_ID('hencom_SPNCostOfTransportVarQuery') IS NOT NULL 
    DROP PROC hencom_SPNCostOfTransportVarQuery
GO 

-- v2017.04.21 
/************************************************************  
 설  명 - 데이터-사업계획운송비변수등록_hencom : 조회  
 작성일 - 20161109  
 작성자 - 박수영  
 조회,가져오기에 사용.  
************************************************************/  
  
CREATE PROC dbo.hencom_SPNCostOfTransportVarQuery                  
 @xmlDocument    NVARCHAR(MAX) ,              
 @xmlFlags     INT  = 0,              
 @ServiceSeq     INT  = 0,              
 @WorkingTag     NVARCHAR(10)= '',                    
 @CompanySeq     INT  = 1,              
 @LanguageSeq INT  = 1,              
 @UserSeq     INT  = 0,              
 @PgmSeq         INT  = 0           
      
AS          
    DECLARE @docHandle      INT,  
            @PlanSeq         INT ,  
            @DeptSeq         INT    
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT  @PlanSeq         = PlanSeq          ,  
            @DeptSeq         = DeptSeq            
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
   WITH (PlanSeq          INT ,  
         DeptSeq          INT )  
   
 DECLARE @PlanYear NCHAR(4)  
      
    SELECT @PlanYear = PlanYear   
    FROM hencom_TPNPlan  
    WHERE CompanySeq = @CompanySeq  
    AND PlanSeq = @PlanSeq  
      
 IF @WorkingTag <> 'YM'  
 BEGIN  
     SELECT  A.CompanySeq ,  
                A.COTVRegSeq ,  
                A.DeptSeq ,  
                A.BPYm ,  
                A.OwnMilege ,  
                A.LentMilege ,  
                A.MTCnt ,  
                A.OilAid ,  
                A.LentRotation ,  
                A.WaterUseRate ,  
                A.OwnOTRate ,  
                A.OwnOTMNRate ,  
                A.OwnReturnRate ,  
                A.MinPreserveRate ,  
                A.PayforMeal ,  
                A.IndusAccidInsur ,  
                A.EtcCost ,  
                A.Remark ,  
                A.LastUserSeq ,  
                A.LastDateTime ,  
                A.PlanSeq ,
                A.LentUseRate, 
                A.LentAvgAmt       
        FROM hencom_TPNCostOfTransportVar AS A WITH (NOLOCK)   
        WHERE  A.CompanySeq = @CompanySeq  
        AND A.PlanSeq = @PlanSeq           
        AND A.DeptSeq = @DeptSeq     
        ORDER BY A.BPYm        
    END  
    ELSE  
    BEGIN  
        CREATE TABLE #TMP_YMData  
        (BPYm NCHAR(6))  
          
        INSERT #TMP_YMData (BPYm)  
        SELECT @PlanYear+'01'  
        UNION ALL  
        SELECT @PlanYear+'02'  
         UNION ALL  
        SELECT @PlanYear+'03'  
         UNION ALL  
        SELECT @PlanYear+'04'  
         UNION ALL  
        SELECT @PlanYear+'05'  
         UNION ALL  
        SELECT @PlanYear+'06'  
         UNION ALL  
        SELECT @PlanYear+'07'  
         UNION ALL  
        SELECT @PlanYear+'08'  
         UNION ALL  
        SELECT @PlanYear+'09'  
         UNION ALL  
        SELECT @PlanYear+'10'  
         UNION ALL  
        SELECT @PlanYear+'11'  
         UNION ALL  
        SELECT @PlanYear+'12'  
          
          
          
         SELECT  A.CompanySeq ,  
                A.COTVRegSeq ,  
                A.DeptSeq ,  
                A.BPYm ,  
                A.OwnMilege ,  
                A.LentMilege ,  
                A.MTCnt ,  
                A.OilAid ,  
                A.LentRotation ,  
                A.WaterUseRate ,  
                A.OwnOTRate ,  
                A.OwnOTMNRate ,  
                A.OwnReturnRate ,  
                A.MinPreserveRate ,  
                A.PayforMeal ,  
                A.IndusAccidInsur ,  
                A.EtcCost ,  
                A.Remark ,  
                A.LastUserSeq ,  
                A.LastDateTime ,  
                A.PlanSeq    ,
                A.LentUseRate, 
                A.LentAvgAmt
        FROM hencom_TPNCostOfTransportVar AS A WITH (NOLOCK)   
        WHERE  A.CompanySeq = @CompanySeq  
        AND A.PlanSeq = @PlanSeq           
  AND A.DeptSeq = @DeptSeq     
          
        UNION ALL   
        SELECT  @CompanySeq,  
                NULL AS COTVRegSeq ,  
                NULL AS  DeptSeq ,  
                BPYm AS BPYm ,  
                NULL AS OwnMilege ,  
                NULL AS LentMilege ,  
                NULL AS MTCnt ,  
                  NULL AS OilAid ,  
                NULL AS LentRotation ,  
                NULL AS WaterUseRate ,  
                NULL AS OwnOTRate ,  
                NULL AS OwnOTMNRate ,  
                NULL AS OwnReturnRate ,  
                NULL AS MinPreserveRate ,  
                NULL AS PayforMeal ,  
                NULL AS IndusAccidInsur ,  
                NULL AS EtcCost ,  
                NULL AS Remark ,  
                NULL AS LastUserSeq ,  
                NULL AS LastDateTime ,  
                NULL AS PlanSeq    ,
                NULL AS LentUseRate,
                NULL AS LentAvgAmt
        FROM #TMP_YMData  
        WHERE BPYm NOT IN (  
                         SELECT A.BPYm   
                        FROM hencom_TPNCostOfTransportVar AS A WITH (NOLOCK)   
                        WHERE  A.CompanySeq = @CompanySeq  
                        AND A.PlanSeq = @PlanSeq           
                        AND A.DeptSeq = @DeptSeq         
                        )         
        ORDER BY BPYm  
          
    END  
    
  
RETURN
