
IF OBJECT_ID('amoerp_SPRWkRequestCheck')IS NOT NULL 
    DROP PROC amoerp_SPRWkRequestCheck
GO 
    
-- v2013.10.31 

-- 근태청구원_amoerp(체크) by이재천
CREATE PROC amoerp_SPRWkRequestCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    DECLARE @MessageType INT, 
            @Status      INT, 
            @Results     NVARCHAR(250) 
    
    CREATE TABLE #amoerp_TPRWkRequest (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#amoerp_TPRWkRequest'
    
    -- 마스터 키 생성
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #amoerp_TPRWkRequest WHERE WorkingTag = 'A' AND Status = 0
    IF @Count > 0 
    BEGIN 
        EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'amoerp_TPRWkRequest','ReqSeq',@Count --rowcount  
        UPDATE #amoerp_TPRWkRequest 
           SET ReqSeq  = @MaxSeq + DataSeq 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
    END 
               
    SELECT * FROM #amoerp_TPRWkRequest 
    
    RETURN 
GO