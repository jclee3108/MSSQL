  
IF OBJECT_ID('KPXCM_SARBizTripCostCheck') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostCheck  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-체크 by 이재천   
CREATE PROC KPXCM_SARBizTripCostCheck  
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
      
    CREATE TABLE #KPXCM_TARBizTripCost( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TARBizTripCost'   
    IF @@ERROR <> 0 RETURN     
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TARBizTripCost WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        DECLARE @BaseDate           NVARCHAR(8),   
                @MaxNo              NVARCHAR(50)  
          
        SELECT @BaseDate    = ISNULL( MAX(RegDate), CONVERT( NVARCHAR(8), GETDATE(), 112 ) )  
          FROM #KPXCM_TARBizTripCost   
         WHERE WorkingTag = 'A'   
           AND Status = 0     
        
        EXEC dbo._SCOMCreateNo 'SITE', 'KPXCM_TARBizTripCost', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT      
          
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TARBizTripCost', 'BizTripSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TARBizTripCost  
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
      
    UPDATE #KPXCM_TARBizTripCost   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TARBizTripCost  
     WHERE Status = 0  
       AND ( BizTripSeq = 0 OR BizTripSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TARBizTripCost   
      
    RETURN  
Go 
begin tran 
EXEC KPXCM_SARBizTripCostCheck @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizTripSeq>0</BizTripSeq>
    <BizTripNo />
    <RegEmpSeq>2028</RegEmpSeq>
    <RegEmpName>이재천</RegEmpName>
    <AccUnit>1</AccUnit>
    <AccUnitName>본사</AccUnitName>
    <CostSeq>1011517001</CostSeq>
    <CostName>이동</CostName>
    <TripFrDate>20150912</TripFrDate>
    <TripToDate>20150913</TripToDate>
    <RegDate>20150902</RegDate>
    <TripDeptSeq>147</TripDeptSeq>
    <TripDeptName>사업개발팀</TripDeptName>
    <TripCCtrSeq>1121</TripCCtrSeq>
    <TripCCtrName>(실적) 테스트 - 1130</TripCCtrName>
    <TripEmpSeq>2028</TripEmpSeq>
    <TripEmpName>이재천</TripEmpName>
    <RemValSeq />
    <RemValName />
    <PayReqDate>20150912</PayReqDate>
    <TripPlace>13</TripPlace>
    <TripCust>13</TripCust>
    <Purpose>14</Purpose>
    <TripPerson>124</TripPerson>
    <Contents>234</Contents>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1031819, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1026397


rollback 