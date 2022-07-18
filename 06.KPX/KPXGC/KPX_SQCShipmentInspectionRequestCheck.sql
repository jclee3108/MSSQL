  
IF OBJECT_ID('KPX_SQCShipmentInspectionRequestCheck') IS NOT NULL   
    DROP PROC KPX_SQCShipmentInspectionRequestCheck  
GO  
  
-- v2014.12.11  
  
-- 출하검사의뢰(탱크로리)-체크 by 이재천   
CREATE PROC KPX_SQCShipmentInspectionRequestCheck  
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
    
    CREATE TABLE #KPX_TQCShipmentInspectionRequest( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TQCShipmentInspectionRequest'   
    IF @@ERROR <> 0 RETURN     
    
    --select * From #KPX_TQCShipmentInspectionRequest 
    --return 
    -- 중복여부 체크 :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
    --                      @LanguageSeq       ,  
    --                      3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
    --                      --3543, '값2'  
      
    --UPDATE #KPX_TQCShipmentInspectionRequest  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPX_TQCShipmentInspectionRequest AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPX_TQCShipmentInspectionRequest AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPX_TQCShipmentInspectionRequest AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPX_TQCShipmentInspectionRequest   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND ReqSeq = A1.ReqSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
    
    -- 번호+코드 따기 :           
    DECLARE @Count      INT,  
            @Seq        INT, 
            @BaseDate   NVARCHAR(8),   
            @MaxNo      NVARCHAR(50), 
            @NoCnt      INT 
    
    
    SELECT @Count = COUNT(1) FROM #KPX_TQCShipmentInspectionRequest WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        SELECT @NoCnt = 1 
        
        WHILE ( 1 = 1 ) 
        BEGIN 
            SELECT @BaseDate = ReqDate 
              FROM #KPX_TQCShipmentInspectionRequest   
             WHERE WorkingTag = 'A'   
               AND Status = 0     
               AND DataSeq = @NoCnt 
            
            EXEC dbo._SCOMCreateNo 'SL', 'KPX_TQCShipmentInspectionRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT       
            
            UPDATE A
               SET ReqNo = @MaxNo
              FROM #KPX_TQCShipmentInspectionRequest AS A 
             WHERE A.WorkingTag = 'A'
               AND A.Status = 0 
               AND A.DataSeq = @NoCnt 
            
            IF @NoCnt = (SELECT MAX(DataSeq) FROM #KPX_TQCShipmentInspectionRequest WHERE WorkingTag = 'A' AND Status = 0)
            BEGIN
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @NoCnt = @NoCnt + 1 
            END 
            
        END         
        
          
        SELECT @BaseDate = ISNULL( MAX(ReqDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPX_TQCShipmentInspectionRequest   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        EXEC dbo._SCOMCreateNo 'SL', 'KPX_TQCShipmentInspectionRequest', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TQCShipmentInspectionRequest', 'ReqSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TQCShipmentInspectionRequest  
           SET ReqSeq = @Seq + DataSeq--,  
               --SampleNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TQCShipmentInspectionRequest   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TQCShipmentInspectionRequest  
     WHERE Status = 0  
       AND ( ReqSeq = 0 OR ReqSeq IS NULL )  
    
    SELECT * FROM #KPX_TQCShipmentInspectionRequest   
    
    RETURN  
GO 

begin tran 
exec KPX_SQCShipmentInspectionRequestCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqDate>20141211</ReqDate>
    <QCType>3</QCType>
    <ItemSeq>1051579</ItemSeq>
    <LotNo>111</LotNo>
    <Qty>12</Qty>
    <UnitSeq>2</UnitSeq>
    <CustSeq>40635</CustSeq>
    <EmpSeq>1373</EmpSeq>
    <DeptSeq>1656</DeptSeq>
    <ReqNo />
    <Remark />
    <ReqSeq>0</ReqSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqDate>20141211</ReqDate>
    <QCType>3</QCType>
    <ItemSeq>24732</ItemSeq>
    <LotNo>111</LotNo>
    <Qty>1</Qty>
    <UnitSeq>2</UnitSeq>
    <CustSeq>27753</CustSeq>
    <EmpSeq>1368</EmpSeq>
    <DeptSeq>1000043</DeptSeq>
    <ReqNo />
    <Remark />
    <ReqSeq>0</ReqSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqDate>20141212</ReqDate>
    <QCType>3</QCType>
    <ItemSeq>1051579</ItemSeq>
    <LotNo>111</LotNo>
    <Qty>156</Qty>
    <UnitSeq>2</UnitSeq>
    <CustSeq>38177</CustSeq>
    <EmpSeq>1364</EmpSeq>
    <DeptSeq>1000039</DeptSeq>
    <ReqNo />
    <Remark />
    <ReqSeq>0</ReqSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ReqDate>20141213</ReqDate>
    <QCType>3</QCType>
    <ItemSeq>22143</ItemSeq>
    <LotNo>111</LotNo>
    <Qty>75</Qty>
    <UnitSeq>2</UnitSeq>
    <CustSeq>33761</CustSeq>
    <EmpSeq>1366</EmpSeq>
    <DeptSeq>1000042</DeptSeq>
    <ReqNo />
    <Remark />
    <ReqSeq>0</ReqSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026674,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022335

rollback 