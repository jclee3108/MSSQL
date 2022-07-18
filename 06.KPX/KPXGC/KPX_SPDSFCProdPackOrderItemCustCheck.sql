  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemCustCheck') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemCustCheck  
GO  
  
-- v2014.11.25  
  
-- 포장작업지시입력-거래처 체크 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderItemCustCheck
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
      
    CREATE TABLE #KPX_TPDSFCProdPackOrderItemCust( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TPDSFCProdPackOrderItemCust'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItemCust   
      
    RETURN  
GO 



