  
IF OBJECT_ID('KPX_SPDQCRequestInsPurchaseCheck') IS NOT NULL   
    DROP PROC KPX_SPDQCRequestInsPurchaseCheck  
GO  

-- v2015.01.15 
  
-- 구매납품-수입의뢰데이터 생성 체크 by 이재천   
CREATE PROC KPX_SPDQCRequestInsPurchaseCheck  
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
      
    CREATE TABLE #KPX_TQCTestRequest( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCTestRequest'   
    IF @@ERROR <> 0 RETURN     
    
    CREATE TABLE #KPX_TQCTestRequestItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TQCTestRequestItem'   
    IF @@ERROR <> 0 RETURN     
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TQCTestRequest WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
                
        DECLARE @BaseDate   NVARCHAR(8), 
                @MaxNo      NVARCHAR(50) 
        
        SELECT @BaseDate    = CONVERT( NVARCHAR(8), GETDATE(), 112 ) 
          FROM #KPX_TQCTestRequest   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
            
        EXEC dbo._SCOMCreateNo 'SITE', 'KPX_TQCTestRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT 
            
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCTestRequest', 'ReqSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TQCTestRequest  
           SET ReqSeq = @Seq + DataSeq, 
               ReqNo = @MaxNo, 
               ReqDate = @BaseDate
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    
    DECLARE @Serl   INT 
    
    SELECT @Serl = (SELECT MAX(ReqSerl) FROM KPX_TQCTestRequestItem WHERE CompanySeq = @CompanySeq AND ReqSeq = (SELECT TOP 1 ReqSeq FROM #KPX_TQCTestRequest WHERE WorkingTag = 'A'))
    
    SELECT @Count = COUNT(1) FROM #KPX_TQCTestRequestItem WHERE WorkingTag = 'A' AND Status = 0  
    IF @Count > 0  
    BEGIN  
        
        UPDATE A
           SET A.ReqSeq = (SELECT TOP 1 ReqSeq FROM #KPX_TQCTestRequest WHERE WorkingTag = 'A'), 
               A.ReqSerl = ISNULL(@Serl,0) + A.DataSeq, 
               A.SMSourceType = 1000522008 
          FROM #KPX_TQCTestRequestItem AS A 
        
    END 
    
    
    SELECT * FROM #KPX_TQCTestRequest 
    SELECT * FROM #KPX_TQCTestRequestItem 
    
    RETURN  
    