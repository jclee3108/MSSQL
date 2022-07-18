  
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrderCheck') IS NOT NULL   
    DROP PROC KPXGC_SPDSFCProdPackOrderCheck  
GO  
  
-- v2015.08.18  
  
-- 포장작업지시입력(공정)-체크 by 이재천   
CREATE PROC KPXGC_SPDSFCProdPackOrderCheck  
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
    
    CREATE TABLE #KPX_TPDSFCProdPackOrder( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPDSFCProdPackOrder'   
    IF @@ERROR <> 0 RETURN     
        UPDATE A
       SET WorkingTag = 'U' 
      FROM #KPX_TPDSFCProdPackOrder AS A 
     WHERE WorkingTag = 'A' 
       AND ISNULL(PackOrderSeq,0) <> 0
    
    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    IF NOT EXISTS ( SELECT 1   
                      FROM #KPX_TPDSFCProdPackOrder AS A   
                      JOIN KPX_TPDSFCProdPackOrder AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #KPX_TPDSFCProdPackOrder  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    

    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TPDSFCProdPackOrder WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
          DECLARE @BaseDate           NVARCHAR(8),   
                  @SMFirstInitialUnit INT,  
                  @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = ISNULL( MAX(PackDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPX_TPDSFCProdPackOrder   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
          
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TPDSFCProdPackOrder', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDSFCProdPackOrder', 'PackOrderSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TPDSFCProdPackOrder  
           SET PackOrderSeq = @Seq + DataSeq, 
               OrderNo = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE A   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TPDSFCProdPackOrder AS A 
     WHERE Status = 0  
       AND ( PackOrderSeq = 0 OR PackOrderSeq IS NULL )  
      
    SELECT * FROM #KPX_TPDSFCProdPackOrder   
      
    RETURN  
GO 
begin tran 
exec KPXGC_SPDSFCProdPackOrderCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <OrderNo />
    <PackOrderSeq>0</PackOrderSeq>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <PackDate>20150819</PackDate>
    <Remark />
    <IsCfm>0</IsCfm>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031473,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026201

rollback 