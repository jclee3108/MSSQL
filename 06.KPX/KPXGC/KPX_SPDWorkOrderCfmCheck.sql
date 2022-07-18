  
IF OBJECT_ID('KPX_SPDWorkOrderCfmCheck') IS NOT NULL   
    DROP PROC KPX_SPDWorkOrderCfmCheck  
GO  
  
-- v2014.10.16  
  
-- 작업지시서생성-체크 by 이재천   
CREATE PROC KPX_SPDWorkOrderCfmCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #TPDSFCWorkOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkOrder'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #TPDSFCWorkOrder   
      
    RETURN  