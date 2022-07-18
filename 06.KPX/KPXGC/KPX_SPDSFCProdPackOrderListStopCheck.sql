  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderListStopCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderListStopCheck  
GO  
  
-- v2014.11.25  
  
-- 포장작업지시조회- 중단 체크 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderListStopCheck  
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
    
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE #KPX_TPDSFCProdPackOrderItem
       SET WorkingTag = 'U' 
       
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem   
      
    RETURN  
GO 