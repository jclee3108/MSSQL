  
IF OBJECT_ID('hencom_SACPaymentPricePlanCheck') IS NOT NULL   
    DROP PROC hencom_SACPaymentPricePlanCheck  
GO  
  
-- v2017.06.02
  
-- 정기분대금지급계획-체크 by 이재천
CREATE PROC hencom_SACPaymentPricePlanCheck  
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
      
    CREATE TABLE #hencom_TACPaymentPricePlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACPaymentPricePlan'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 일마감이 되어 신규저장/수정/삭제를(을) 할 수 없습니다.
    UPDATE A
       SET Result = '일마감이 되어 신규저장/수정/시트삭제를(을) 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACPaymentPricePlan  AS A 
      JOIN hencom_TACFundPlanClose      AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
     WHERE B.Check1 = '1' 
       AND A.Status = 0 
    -- 체크1, END 
    
    SELECT * FROM #hencom_TACPaymentPricePlan   
      
    RETURN  
    GO
begin tran 
exec hencom_SACPaymentPricePlanCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>전사</SlipUnitName>
    <MatAmt1>213</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>213</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>213</SumAmt>
    <Remark />
    <SlipUnit>1</SlipUnit>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>테스트</SlipUnitName>
    <MatAmt1>0</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>0</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>0</SumAmt>
    <Remark />
    <SlipUnit>2</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>군산사업소</SlipUnitName>
    <MatAmt1>123</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>123</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>123</SumAmt>
    <Remark />
    <SlipUnit>3</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>담양사업소</SlipUnitName>
    <MatAmt1>0</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>0</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>0</SumAmt>
    <Remark />
    <SlipUnit>4</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>당진사업소</SlipUnitName>
    <MatAmt1>0</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>0</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>0</SumAmt>
    <Remark />
    <SlipUnit>5</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>대전사업소</SlipUnitName>
    <MatAmt1>0</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>123</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>123</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>123</SumAmt>
    <Remark />
    <SlipUnit>6</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SlipUnitName>서대전사업소</SlipUnitName>
    <MatAmt1>0</MatAmt1>
    <MatAmt2>0</MatAmt2>
    <MatAmt3>0</MatAmt3>
    <MatAmt4>0</MatAmt4>
    <SumMatAmt>0</SumMatAmt>
    <GoodsAmt1>0</GoodsAmt1>
    <GoodsAmt3>0</GoodsAmt3>
    <GoodsAmt4>0</GoodsAmt4>
    <SumGoodsAmt>0</SumGoodsAmt>
    <ReAmt1>0</ReAmt1>
    <ReAmt2>0</ReAmt2>
    <SumReAmt>0</SumReAmt>
    <EtcAmt1>0</EtcAmt1>
    <SumEtcAmt>0</SumEtcAmt>
    <SumAmt>0</SumAmt>
    <Remark />
    <SlipUnit>7</SlipUnit>
    <StdDate>20170710</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512352,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033717
rollback 