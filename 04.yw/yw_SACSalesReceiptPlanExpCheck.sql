  
IF OBJECT_ID('yw_SACSalesReceiptPlanExpCheck') IS NOT NULL   
    DROP PROC yw_SACSalesReceiptPlanExpCheck  
GO  
  
-- v2013.12.16 
  
-- 채권수금계획(수출)_yw-체크 by 이재천   
CREATE PROC yw_SACSalesReceiptPlanExpCheck  
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
      
    CREATE TABLE #yw_TACSalesReceiptPlan( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TACSalesReceiptPlan'   
    IF @@ERROR <> 0 RETURN     
      
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #yw_TACSalesReceiptPlan WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        SELECT @Seq = (
                       SELECT MAX(B.Serl) 
                         FROM #yw_TACSalesReceiptPlan    AS A 
                         JOIN yw_TACSalesReceiptPlan     AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanYM = A.PlanYM AND PlanType = '1' ) 
                      )
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #yw_TACSalesReceiptPlan  
           SET Serl = ISNULL(@Seq,0) + DataSeq     
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   

    SELECT * FROM #yw_TACSalesReceiptPlan   
      
    RETURN  
GO
exec yw_SACSalesReceiptPlanExpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <DeptName>1</DeptName>
    <CustName>2</CustName>
    <SMInTypeName>3</SMInTypeName>
    <PlanAmt>4</PlanAmt>
    <ReceiptAmt>5</ReceiptAmt>
    <ReceiptAmt1>6</ReceiptAmt1>
    <ReceiptAmt2>7</ReceiptAmt2>
    <ReceiptAmt3>8</ReceiptAmt3>
    <ReceiptAmt4>9</ReceiptAmt4>
    <ReceiptAmt5>1</ReceiptAmt5>
    <ReceiptAmt6>2</ReceiptAmt6>
    <LongBondAmt>3</LongBondAmt>
    <BadBondAmt>4</BadBondAmt>
    <SumAmt>5</SumAmt>
    <DeptSeq>6</DeptSeq>
    <CustSeq>7</CustSeq>
    <SMInType>8</SMInType>
    <Serl>0</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PlanYM>201312</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019843,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016756