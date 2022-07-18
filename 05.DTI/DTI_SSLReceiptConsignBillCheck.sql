
IF OBJECT_ID('DTI_SSLReceiptConsignBillCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignBillCheck
GO

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁세금계산서체크) by이재천
CREATE PROC DTI_SSLReceiptConsignBillCheck  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    DECLARE @Count       INT,    
            @Seq         INT,    
            @MessageType INT,    
            @Status      INT,    
            @Results     NVARCHAR(250)    
    
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #DTI_TSLReceiptConsignBill (WorkingTag NCHAR(1) NULL)  
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TSLReceiptConsignBill'    
    
    -------------------------------------------    
    -- 금액초과체크    
    -------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          106                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 106)    
                          @LanguageSeq       ,     
                          1923,'',      -- SELECT * FROM _TCADictionary WHERE Word like '%입금액%'   
                          15045, '',    -- SELECT * FROM _TCADictionary WHERE Word like '%세금계산서%'   
                          290, ''       -- SELECT * FROM _TCADictionary WHERE Word like '%금액%'   
    
    UPDATE #DTI_TSLReceiptConsignBill    
       SET Result        = @Results, --REPLACE(REPLACE(@Results,'@2','세금계산서'),'@3','금액'),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignBill AS A   
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.Amt + X.VAT) AS CurAmt, SUM(X.Amt + X.VAT) AS DomAmt -- 세금계산서금액  
                         FROM DTI_TSLBillConsign            AS X 
                         JOIN #DTI_TSLReceiptConsignBill    AS Y ON X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq  
                        GROUP BY X.BillSeq
                      ) AS C ON ( A.BillSeq = C.BillSeq ) 
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt -- 누계반제  
                         FROM DTI_TSLReceiptConsignBill     AS X 
                         JOIN #DTI_TSLReceiptConsignBill    AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq AND X.ReceiptSeq <> Y.ReceiptSeq ) 
                         GROUP BY X.BillSeq
                      ) AS D ON ( A.BillSeq = D.BillSeq ) 
     WHERE (ABS(C.CurAmt) < ABS(ISNULL(D.CurAmt,0) + A.CurAmt) OR ABS(C.DomAmt) < ABS(ISNULL(D.DomAmt,0) + A.DomAmt))  
       AND @WorkingTag <> 'D'    
    
    SELECT * FROM #DTI_TSLReceiptConsignBill  
    
    RETURN    
GO
exec DTI_SSLReceiptConsignBillCheck @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BillSeq>3</BillSeq>
    <BillNo>140518000002</BillNo>
    <BillDate>20140502</BillDate>
    <BillCurAmt>330000</BillCurAmt>
    <BillDomAmt>330000</BillDomAmt>
    <PreBillCurAmt>330000</PreBillCurAmt>
    <PreBillDomAmt>330000</PreBillDomAmt>
    <CurAmt>100</CurAmt>
    <DomAmt>100</DomAmt>
    <ExRate>1</ExRate>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <ReceiptSeq>31</ReceiptSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1019203