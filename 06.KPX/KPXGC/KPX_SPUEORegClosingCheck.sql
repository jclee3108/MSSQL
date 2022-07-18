  
IF OBJECT_ID('KPX_SPUEORegClosingCheck') IS NOT NULL   
    DROP PROC KPX_SPUEORegClosingCheck  
GO  
  
-- v2016.01.13
  
-- EO구매입고생성처리- 마감체크 by 이재천 
CREATE PROC KPX_SPUEORegClosingCheck  
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
      
    CREATE TABLE #Closing( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#Closing'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------
    -- 업무(구매)마감 체크 
    ------------------------------------------------------
    UPDATE A 
       SET Result = '업무(구매)마감이 되었습니다. 처리 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #Closing   AS A 
      JOIN _TCOMClosingYM   AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = 1292 AND B.ClosingYM = LEFT(A.InOutDate,6) AND B.IsClose = '1' )
     WHERE A.Status = 0 
    ------------------------------------------------------
    -- 업무(구매)마감 체크, END  
    ------------------------------------------------------
    
    ------------------------------------------------------
    -- 수불(자재)마감 체크 
    ------------------------------------------------------
    UPDATE A 
       SET Result = '수불(자재)마감이 되었습니다. 처리 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #Closing   AS A 
      JOIN _TCOMClosingYM   AS B ON ( B.CompanySeq = @CompanySeq AND B.ClosingSeq = 69 AND B.ClosingYM = LEFT(A.InOutDate,6) AND B.IsClose = '1' AND B.DtlUnitSeq = 1 )
     WHERE A.Status = 0 
    ------------------------------------------------------
    -- 수불(자재)마감 체크, END  
    ------------------------------------------------------
    
    SELECT * FROM #Closing   
      
    RETURN  