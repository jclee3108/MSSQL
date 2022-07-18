  
IF OBJECT_ID('KPX_SPUTransImpOrderDeleteCheck') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderDeleteCheck  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시- 삭제 체크 by 이재천   
CREATE PROC KPX_SPUTransImpOrderDeleteCheck  
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
    
    CREATE TABLE #KPX_TPUTransImpOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUTransImpOrder'   
    IF @@ERROR <> 0 RETURN    
    
    SELECT * FROM #KPX_TPUTransImpOrder 
    
    RETURN 