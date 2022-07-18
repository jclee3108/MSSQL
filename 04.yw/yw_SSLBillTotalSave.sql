
IF OBJECT_ID('yw_SSLBillTotalSave') IS NOT NULL
    DROP PROC yw_SSLBillTotalSave
GO

-- 2013.08.26 

-- 건별세금계산서 집계발행_YW(저장) By이재천
CREATE PROC yw_SSLBillTotalSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
	CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoiceItem'     
	IF @@ERROR <> 0 RETURN  
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
    EXEC _SCOMLog @CompanySeq   ,
                  @UserSeq      ,
                  '_TSLInvoiceItem', -- 원테이블명
                  '#TSLInvoiceItem', -- 템프테이블명
                  'InvoiceSeq, InvoiceSerl' , -- 키가 여러개일 경우는 , 로 연결한다. 
                  'CompanySeq, InvoiceSeq, InvoiceSerl, ItemSeq, UnitSeq, ItemPrice, CustPrice, Qty, IsInclusedVAT, VATRate, CurAmt, CurVAT, DomAmt, DomVAT,
                   STDUnitSeq, STDQty, WHSeq, Remark, UMEtcOutKind, TrustCustSeq, LotNo, SerialNo, PJTSeq, WBSSeq, CCtrSeq, LastUserSeq, LastDateTime,Price,PgmSeq,Dummy1,Dummy2,Dummy3,Dummy4,Dummy5,Dummy6,Dummy7,Dummy8,Dummy9,Dummy10',
                  '', @PgmSeq 
    
    -- UPDATE    
	IF EXISTS (SELECT 1 FROM #TSLInvoiceItem WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE B
			   SET Price = A.Price, 
			       CurAmt = A.InvoiceCurAmt, 
			       CurVAT = A.InvoiceCurVAT, 
			       DomAmt = A.InvoiceDomAmt, 
			       DomVAT = A.InvoiceDomVAT, 
                   LastUserSeq = @UserSeq, 
			       LastDateTime = GetDate()
			  FROM #TSLInvoiceItem AS A 
              JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq AND A.InvoiceSerl = B.InvoiceSerl ) 
             WHERE A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
    
    SELECT * FROM #TSLInvoiceItem 
    
    RETURN    

GO

exec yw_SSLBillTotalSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnitNameBizUnitName />
    <BizUnit>1</BizUnit>
    <InvoiceSeq>1000747</InvoiceSeq>
    <InvoiceNo>Invoice201308190004</InvoiceNo>
    <InvoiceSerl>1</InvoiceSerl>
    <InvoiceDate>20130819</InvoiceDate>
    <ExpKindName>내수</ExpKindName>
    <SMExpKind>8009001</SMExpKind>
    <OutKindName>판매반품</OutKindName>
    <UMOutKind>8020004</UMOutKind>
    <InvDeptName>사업개발팀</InvDeptName>
    <InvDeptSeq>147</InvDeptSeq>
    <InvEmpName>손미나</InvEmpName>
    <InvEmpSeq>2026</InvEmpSeq>
    <InvoiceCustName>mn_거래처</InvoiceCustName>
    <InvoiceCustSeq>1000057</InvoiceCustSeq>
    <CustName>mn_거래처</CustName>
    <CustSeq>1000057</CustSeq>
    <BKCustSeq>0</BKCustSeq>
    <CurrName>KRW</CurrName>
    <CurrSeq>1</CurrSeq>
    <ExRate>1</ExRate>
    <IsStockSales>0</IsStockSales>
    <Remark />
    <ItemName>mn_테스트세트</ItemName>
    <ItemSeq>1000573</ItemSeq>
    <ItemNo>mn_테스트세트</ItemNo>
    <Spec />
    <BizUnitName>당진사업장</BizUnitName>
    <UnitSeq>3</UnitSeq>
    <ItemPrice>0</ItemPrice>
    <CustPrice>0</CustPrice>
    <Price>600</Price>
    <InvoiceQty>-50</InvoiceQty>
    <IsInclusedVAT>0</IsInclusedVAT>
    <VATRate>10</VATRate>
    <InvoiceCurAmt>-30000</InvoiceCurAmt>
    <InvoiceCurVAT>-3000</InvoiceCurVAT>
    <InvoiceCurAmtTotal>-33000</InvoiceCurAmtTotal>
    <InvoiceDomAmt>-30000</InvoiceDomAmt>
    <InvoiceDomVAT>-3000</InvoiceDomVAT>
    <InvoiceDomAmtTotal>-33000</InvoiceDomAmtTotal>
    <Qty>-50</Qty>
    <CurAmt>-30000</CurAmt>
    <CurVAT>-3000</CurVAT>
    <CurAmtTotal>-33000</CurAmtTotal>
    <DomAmt>-30000</DomAmt>
    <DomVAT>-3000</DomVAT>
    <DomAmtTotal>-33000</DomAmtTotal>
    <STDUnitName>BOX</STDUnitName>
    <STDUnitSeq>3</STDUnitSeq>
    <STDQty>-50</STDQty>
    <WHName>mn_제상품창고</WHName>
    <WHSeq>1000164</WHSeq>
    <IsQtyChange />
    <TrustCustName />
    <TrustCustSeq />
    <LotNo />
    <SerialNo />
    <IsOverCredit>0</IsOverCredit>
    <IsMinAmt>0</IsMinAmt>
    <IsSalesWith />
    <SMSalesCrtKindName>세금계산서매출</SMSalesCrtKindName>
    <SMSalesCrtKind>8017002</SMSalesCrtKind>
    <AccName>상품매출(내수)</AccName>
    <AccSeq>410</AccSeq>
    <DeptName>사업개발팀</DeptName>
    <DeptSeq>147</DeptSeq>
    <EmpName>손미나</EmpName>
    <EmpSeq>2026</EmpSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017309,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014801