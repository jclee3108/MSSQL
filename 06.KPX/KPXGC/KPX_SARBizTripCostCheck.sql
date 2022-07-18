  
IF OBJECT_ID('KPX_SARBizTripCostCheck') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostCheck  
GO  
  
-- v2015.01.08  
  
-- 출장비지출품의서-체크 by 이재천   
CREATE PROC KPX_SARBizTripCostCheck  
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
    
    CREATE TABLE #KPX_TARBizTripCost( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TARBizTripCost'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 전표가 생성 된 데이터는 수정, 삭제 할 수 없습니다. 
    
    UPDATE A
       SET Result = '전표가 생성 된 데이터는 수정, 삭제 할 수 없습니다. ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TARBizTripCost AS A 
      JOIN KPX_TARBizTripCost  AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq AND B.SlipMstSeq <> 0 ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
    -- 체크1, END 
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_TARBizTripCost WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = CONVERT( NVARCHAR(8), GETDATE(), 112 ) 
          FROM #KPX_TARBizTripCost   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'SITE', 'KPX_TARBizTripCost', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
        
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TARBizTripCost', 'BizTripSeq', @Count  
        
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_TARBizTripCost  
           SET BizTripSeq = @Seq + DataSeq,   
               BizTripNo  = @MaxNo      
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_TARBizTripCost   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_TARBizTripCost  
     WHERE Status = 0  
       AND ( BizTripSeq = 0 OR BizTripSeq IS NULL )  
      
    SELECT * FROM #KPX_TARBizTripCost   
    
    RETURN  
GO 
begin tran 
exec KPX_SARBizTripCostCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizTripNo>201501092</BizTripNo>
    <RegDate>20150109</RegDate>
    <SMTripKind>1013002</SMTripKind>
    <SMTripKindName>해외</SMTripKindName>
    <EmpSeq>1317</EmpSeq>
    <EmpName>윤삼혁</EmpName>
    <UMJpName>1급사원</UMJpName>
    <DeptName>생산관리본부(환경)</DeptName>
    <CCtrSeq>1239</CCtrSeq>
    <CCtrName>(프로젝트별)과세10% - X 품목 생성</CCtrName>
    <UMCostTypeName>제조</UMCostTypeName>
    <UMCostType>4001001</UMCostType>
    <TripPlace>123</TripPlace>
    <Purpose>123</Purpose>
    <BizTripSeq>8</BizTripSeq>
    <TripFrDate>20150101</TripFrDate>
    <TripToDate>20150102</TripToDate>
    <TermNight>1</TermNight>
    <TermDay>2</TermDay>
    <TransCost>2323</TransCost>
    <DailyCost>2323</DailyCost>
    <LodgeCost>2323</LodgeCost>
    <EctCost>2323</EctCost>
    <SumCost>9292</SumCost>
    <CardOutCost>124123</CardOutCost>
    <AccSeq>1182</AccSeq>
    <OppAccSeq>5</OppAccSeq>
    <AccName>복리후생비1</AccName>
    <OppAccName>현금</OppAccName>
    <SlipUnit>1</SlipUnit>
    <SlipUnitName>전사</SlipUnitName>
    <CostSeq>3</CostSeq>
    <CostName>교육훈련비</CostName>
    <SlipMstID>A0-S1-20150109-0001</SlipMstID>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022816
rollback 