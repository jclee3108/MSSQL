  
IF OBJECT_ID('hencom_SSLInvoiceBillJumpCheck') IS NOT NULL   
    DROP PROC hencom_SSLInvoiceBillJumpCheck  
GO  
  
-- v2017.04.25
  
-- 거래명세서품목조회-세금계산서Jump체크 by 이재천
CREATE PROC hencom_SSLInvoiceBillJumpCheck  
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
      
    CREATE TABLE #TSLInvoiceItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoiceItem'   
    IF @@ERROR <> 0 RETURN     
    

    IF NOT EXISTS (SELECT 1 FROM #TSLInvoiceItem)
    BEGIN 
        SELECT * FROM #TSLInvoiceItem 
        RETURN 
    END 
    
    -- 수량 * 단가와 판매금액이 다른경우 체크메시지
    IF EXISTS ( SELECT 1 
                  FROM #TSLInvoiceItem              AS A 
                  JOIN _TSLInvoiceItem   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
                 WHERE ROUND(B.Qty * B.Price,0) <> B.CurAmt
              ) 
    BEGIN 
        DECLARE @ErrMessage NVARCHAR(MAX) 

        SELECT @ErrMessage = '' 

        SELECT @ErrMessage = @ErrMessage + '[' +  
                                '일자:' + STUFF(STUFF(D.InvoiceDate,5,0,'-'),8,0,'-') 
                            + ' & 규격:' + C.ItemName 
                            + ' & 금액(수량*단가):' + CONVERT(NVARCHAR(100),dbo._FCOMNumberToStr(CONVERT(DECIMAL(19,0),ROUND(B.Qty * B.Price,0)),0)) 
                            + ' & 판매금액:' + CONVERT(NVARCHAR(100),dbo._FCOMNumberToStr(CONVERT(DECIMAL(19,0),B.CurAmt),0)) 
                            + '],@#$%'
          FROM #TSLInvoiceItem              AS A 
                     JOIN _TSLInvoiceItem   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq AND B.InvoiceSerl = A.InvoiceSerl ) 
                     JOIN _TSLInvoice       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.InvoiceSeq = B.InvoiceSeq ) 
          LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
         WHERE ROUND(B.Qty * B.Price,0) <> B.CurAmt
        
        -- 엔터 처리
        SELECT @ErrMessage = SUBSTRING(@ErrMessage,1,LEN(@ErrMessage)-5)
        SELECT @ErrMessage = REPLACE(@ErrMessage, '@#$%', NCHAR(10))
        
        -- 오류메시지 
        SELECT '금액(수량*단가)이 판매금액과 아래와 같이 같지 않습니다. 진행하시겠습니까? ' + NCHAR(10) + @ErrMessage AS Result, 
               1234 AS Status, 
               1234 AS MessageType 
        RETURN 
    END 

    SELECT @ErrMessage AS Result, 
           0 AS Status, 
           0 AS MessageType 

    RETURN  
go
begin tran 
exec hencom_SSLInvoiceBillJumpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>219</InvoiceSeq>
    <InvoiceSerl>1</InvoiceSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>2804</InvoiceSeq>
    <InvoiceSerl>1</InvoiceSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>5</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>377</InvoiceSeq>
    <InvoiceSerl>1</InvoiceSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511098,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032746
rollback 