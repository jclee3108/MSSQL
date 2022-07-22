  
IF OBJECT_ID('hncom_SPRAdjWithHoldListSS2DelCheck') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListSS2DelCheck  
GO  
  
-- v2017.02.08
      
-- 원천세신고목록-SS2삭제체크 by 이재천   
CREATE PROC hncom_SPRAdjWithHoldListSS2DelCheck  
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
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN     
      
    SELECT * FROM #hncom_TAdjWithHoldList   
      
    RETURN  
