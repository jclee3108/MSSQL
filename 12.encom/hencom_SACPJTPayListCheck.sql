IF OBJECT_ID('hencom_SACPJTPayListCheck') IS NOT NULL 
    DROP PROC hencom_SACPJTPayListCheck
GO 

-- v2017.05.10 
/************************************************************
  설  명 - 데이터-현장별임금대장_hencom : 체크
  작성일 - 20160119
  작성자 - 영림원
 ************************************************************/
 CREATE PROC dbo.hencom_SACPJTPayListCheck
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 1,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0  
  AS   
   DECLARE @MessageType INT,
      @Status    INT,
      @Results   NVARCHAR(250)
        
   CREATE TABLE #hencom_TACPJTPayList (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACPJTPayList'
   
  -----------------------------
  ---- 필수입력 체크
  -----------------------------
  
  ---- 필수입력 Message 받아오기
  --EXEC dbo._SCOMMessage @MessageType OUTPUT,
  --       @Status      OUTPUT,
  --       @Results     OUTPUT,
  --       1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')
  --       @LanguageSeq       , 
  --       0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
   ---- 필수입력 Check 
  --UPDATE #hencom_TACPJTPayList
  --   SET Result        = @Results,
  --    MessageType   = @MessageType,
  --    Status        = @Status
  --  FROM #hencom_TACPJTPayList AS A
  -- WHERE A.WorkingTag IN ('A','U')
  --   AND A.Status = 0
  ---- guide : 이곳에 필수입력 체크 할 항목을 조건으로 넣으세요.
  ---- e.g.   :
  ---- AND (A.DBPatchSeq           = 0
  ----      OR A.DBWorkSeq          = 0
  ----      OR A.DBPatchListName    = '')
         
    ------------------------------------------------------------
    -- 체크1, 전표처리 된 데이터는 수정/삭제 할 수 없습니다. 
    ------------------------------------------------------------
    UPDATE A
       SET Result = '전표처리 된 데이터는 수정/삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #hencom_TACPJTPayList    AS A 
      JOIN hencom_TACPJTPayList     AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTPayRegSeq = A.PJTPayRegSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND ISNULL(B.SlipSeq,0) <> 0 
    ------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------


  ---------------------------
  -- 중복여부 체크
  ---------------------------  
  -- 중복체크 Message 받아오기    
  EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
         @LanguageSeq       ,     
         0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'    
       
  -- 중복여부 Check
  UPDATE #hencom_TACPJTPayList 
     SET Status = 6,      -- 중복된 @1 @2가(이) 입력되었습니다.      
      result = @Results      
    FROM #hencom_TACPJTPayList A      
   WHERE A.WorkingTag IN ('A', 'U')
     AND A.Status = 0
    AND EXISTS (SELECT 1  FROM hencom_TACPJTPayList   
                              WHERE CompanySeq = @CompanySeq   
                                AND payym = a.payym
                                and EmpCustSeq = a.EmpCustSeq
                                and PJTPayRegSeq <> a.PJTPayRegSeq  
                                AND PJTSeq = A.PJTSeq )    
  
   --시트에 중복된 데이터 체크  
     UPDATE #hencom_TACPJTPayList   
     SET Status = 6,      -- 중복된 @1 @2가(이) 입력되었습니다.        
      result = '중복된 데이터가 존재합니다. 확인 후 작업하세요'        
    FROM #hencom_TACPJTPayList AS A        
   WHERE A.WorkingTag IN ('A', 'U')  
     AND A.Status = 0  
     AND EXISTS (SELECT 1 FROM #hencom_TACPJTPayList WHERE IDX_NO <> A.IDX_NO   
                                                         AND payym = A.payym  
                                                         AND EmpCustSeq = A.EmpCustSeq  
                                                         AND PJTSeq = A.PJTSeq
                                                         ) 
           
   -- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
    DECLARE @MaxSeq INT,    
             @Count  INT     
     SELECT @Count = Count(1) FROM #hencom_TACPJTPayList WHERE WorkingTag = 'A' AND Status = 0    
     IF @Count >0     
     BEGIN    
     EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'hencom_TACPJTPayList','PJTPayRegSeq',@Count --rowcount      
           UPDATE #hencom_TACPJTPayList                 
              SET PJTPayRegSeq  = @MaxSeq + DataSeq    
            WHERE WorkingTag = 'A'                
              AND Status = 0     
     END     
   SELECT * FROM #hencom_TACPJTPayList 
  RETURN
go
begin tran 
exec hencom_SACPJTPayListCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTPayRegSeq>3</PJTPayRegSeq>
    <PayYM>201601</PayYM>
    <PJTSeq>1</PJTSeq>
    <PJTName>테스트중</PJTName>
    <DeptSeq>58</DeptSeq>
    <DeptName>경영지원담당</DeptName>
    <EmpCustSeq>70853</EmpCustSeq>
    <EmpCustName>(구)부산식당</EmpCustName>
    <PersonId />
    <SlipSeq>0</SlipSeq>
    <SlipID />
    <WorkingDay>3</WorkingDay>
    <Price>1200</Price>
    <TotalPay>256000</TotalPay>
    <IncomTax>200</IncomTax>
    <ResidenceTax>120</ResidenceTax>
    <TaxSum>320</TaxSum>
    <HealthIns>100</HealthIns>
    <NationalPension>200</NationalPension>
    <InsSum>300</InsSum>
    <DepSum>620</DepSum>
    <UnemployIns>210</UnemployIns>
    <DeductionAmt>830</DeductionAmt>
    <RealAmt>255170</RealAmt>
    <ContributionAmt>200</ContributionAmt>
    <UMBankHQ>4003021</UMBankHQ>
    <BankAccNo>111</BankAccNo>
    <Owner>김혜숙예금주</Owner>
    <TelNo />
    <SubcCustSeq>70853</SubcCustSeq>
    <SubcCustName>(구)부산식당</SubcCustName>
    <Addr>경남 양산시 하북면 지산리 4-4 </Addr>
    <Remark>비고</Remark>
    <SubsAccSeq>102</SubsAccSeq>
    <SubsAccName>외상매입금_원재료</SubsAccName>
    <CalcAccSeq>0</CalcAccSeq>
    <CalcAccName />
    <PrepaidExpenseAccSeq>1266</PrepaidExpenseAccSeq>
    <PrepaidExpenseAccName>선급비용_기타</PrepaidExpenseAccName>
    <PayAccSeq>107</PayAccSeq>
    <PayAccName>미지급금_업체</PayAccName>
    <Calc2AccSeq>372</Calc2AccSeq>
    <Calc2AccName>대손충당금_외상매출금</Calc2AccName>
    <CashDate>20170501</CashDate>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PJTPayRegSeq>4</PJTPayRegSeq>
    <PayYM>201601</PayYM>
    <PJTSeq>1</PJTSeq>
    <PJTName>테스트중</PJTName>
    <DeptSeq>58</DeptSeq>
    <DeptName>경영지원담당</DeptName>
    <EmpCustSeq>4203</EmpCustSeq>
    <EmpCustName>(농)대림포크</EmpCustName>
    <PersonId />
    <SlipSeq>3305</SlipSeq>
    <SlipID>A0-S1-20160125-0002-004</SlipID>
    <WorkingDay>2</WorkingDay>
    <Price>23000</Price>
    <TotalPay>29000</TotalPay>
    <IncomTax>300</IncomTax>
    <ResidenceTax>100</ResidenceTax>
    <TaxSum>400</TaxSum>
    <HealthIns>200</HealthIns>
    <NationalPension>100</NationalPension>
    <InsSum>300</InsSum>
    <DepSum>700</DepSum>
    <UnemployIns>200</UnemployIns>
    <DeductionAmt>900</DeductionAmt>
    <RealAmt>28100</RealAmt>
    <ContributionAmt>100</ContributionAmt>
    <UMBankHQ>4003013</UMBankHQ>
    <BankAccNo>444</BankAccNo>
    <Owner>대림포크예금주</Owner>
    <TelNo />
    <SubcCustSeq>4782</SubcCustSeq>
    <SubcCustName>(농)산애들발효연구소</SubcCustName>
    <Addr xml:space="preserve">  </Addr>
    <Remark />
    <SubsAccSeq>5</SubsAccSeq>
    <SubsAccName>현금</SubsAccName>
    <CalcAccSeq>5</CalcAccSeq>
    <CalcAccName>현금</CalcAccName>
    <PrepaidExpenseAccSeq>1266</PrepaidExpenseAccSeq>
    <PrepaidExpenseAccName>선급비용_기타</PrepaidExpenseAccName>
    <PayAccSeq>107</PayAccSeq>
    <PayAccName>미지급금_업체</PayAccName>
    <Calc2AccSeq>372</Calc2AccSeq>
    <Calc2AccName>대손충당금_외상매출금</Calc2AccName>
    <CashDate>20170502</CashDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034419,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028494
rollback 