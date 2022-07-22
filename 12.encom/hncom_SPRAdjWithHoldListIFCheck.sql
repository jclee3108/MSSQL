  
IF OBJECT_ID('hncom_SPRAdjWithHoldListIFCheck') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListIFCheck  
GO  
  
-- v2017.02.07
  
-- 원천세신고목록-연동체크 by이재천
CREATE PROC hncom_SPRAdjWithHoldListIFCheck  
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
      
    CREATE TABLE #hncom_TAdjWithHoldList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #hncom_TAdjWithHoldList   
      
    RETURN  
