  
IF OBJECT_ID('yw_SPUProdSalesTotalInfoCheck') IS NOT NULL   
    DROP PROC yw_SPUProdSalesTotalInfoCheck  
GO  
  
-- v2013.11.28  
  
-- 통합장표자료생성(구매)_YW(체크) by이재천   
CREATE PROC yw_SPUProdSalesTotalInfoCheck  
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
      
    CREATE TABLE #YW_TPUProdSalesTotalInfo (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPUProdSalesTotalInfo' 
    IF @@ERROR <> 0 RETURN     
    
    SELECT * FROM #YW_TPUProdSalesTotalInfo   
      
    RETURN  