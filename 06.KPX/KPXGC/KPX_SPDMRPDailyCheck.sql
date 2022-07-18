  
IF OBJECT_ID('KPX_SPDMRPDailyCheck') IS NOT NULL   
    DROP PROC KPX_SPDMRPDailyCheck  
GO  
  
-- v2014.12.15  
  
-- 일별자재소요계산-체크 by 이재천   
CREATE PROC KPX_SPDMRPDailyCheck  
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
      
    CREATE TABLE #KPX_TPDMRPDaily( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDMRPDaily'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPDMRPDaily WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
    
        DECLARE @BaseDate   NVARCHAR(8),   
                @MaxNo      NVARCHAR(50)  
          
        SELECT @BaseDate = CONVERT( NVARCHAR(8), GETDATE(), 112 ) 
          FROM #KPX_TPDMRPDaily   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TPDMRPDaily', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT     
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDMRPDaily', 'MRPDailySeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TPDMRPDaily  
           SET MRPDailySeq = @Seq + DataSeq, 
               MRPNo = @MaxNo 
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TPDMRPDaily   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPDMRPDaily  
     WHERE Status = 0  
       AND ( MRPDailySeq = 0 OR MRPDailySeq IS NULL )  
      
    SELECT * FROM #KPX_TPDMRPDaily   
      
    RETURN  
GO 
begin tran 
exec KPX_SPDMRPDailyCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMInOutTypePur />
    <SMInOutTypePurName />
    <MRPType>6403002</MRPType>
    <MRPTypeName>생산계획</MRPTypeName>
    <MRPNo />
    <SMMrpKind>6004001</SMMrpKind>
    <SMMrpKindName>MRP</SMMrpKindName>
    <DateFr>20141201</DateFr>
    <DateTo>20141215</DateTo>
    <PlanDateTime />
    <MRPDailySeq>0</MRPDailySeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414

rollback 