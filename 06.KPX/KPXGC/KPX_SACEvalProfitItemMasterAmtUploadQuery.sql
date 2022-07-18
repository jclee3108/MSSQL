  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterAmtUploadQuery') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterAmtUploadQuery  
GO  
  
-- v2015.04.21  
  
-- 주간 평가손익마스터 업로드-조회 by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterAmtUploadQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    CREATE TABLE #KPX_TACEvalProfitItemMasterAmtUpload (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TACEvalProfitItemMasterAmtUpload'   
    IF @@ERROR <> 0 RETURN    
    
    -- 최종조회   
    SELECT * 
      FROM #KPX_TACEvalProfitItemMasterAmtUpload AS A 
      
    RETURN  