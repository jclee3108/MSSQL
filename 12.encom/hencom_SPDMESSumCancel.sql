  
IF OBJECT_ID('hencom_SPDMESSumCancel') IS NOT NULL   
    DROP PROC hencom_SPDMESSumCancel  
GO  
  
-- v2017.02.20
  
-- MES집계취소(선택)-저장 by 이재천
CREATE PROC hencom_SPDMESSumCancel  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TIFProdWorkReportClosesum (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TIFProdWorkReportClosesum'   
    IF @@ERROR <> 0 RETURN    
    
    
    --마감데이터 자재 삭제                                        
    DELETE A                                         
      FROM hencom_TIFProdMatInputCloseSum AS A                                        
     WHERE A.CompanySeq = @CompanySeq                                          
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey  = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN 
    
    --마감데이터 송장 삭제                                                    
    DELETE A                                         
      FROM hencom_TIFProdWorkReportCloseSum AS A                                        
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                         
    
    IF @@ERROR <> 0 RETURN                                         
    
    --송장데이터 마감테이블키 업데이트                                        
    UPDATE A 
       SET SumMesKey = NULL,
           IsErpApply = NULL                                      
      FROM hencom_TIFProdWorkReportClose AS A                           
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN                                         
    
    --송장자재데이터 마감테이블키 업데이트                                        
    UPDATE A 
       SET SumMesKey = NULL, SumMesSerl = NULL   ,IsErpApply = NULL                                      
      FROM hencom_TIFProdMatInputClose AS A                                        
     WHERE CompanySeq = @CompanySeq 
        AND EXISTS (SELECT 1 FROM #hencom_TIFProdWorkReportClosesum WHERE SumMesKey = A.SumMesKey)                                        
    
    IF @@ERROR <> 0 RETURN                      
    
    SELECT * FROM #hencom_TIFProdWorkReportClosesum 
    
    RETURN  
