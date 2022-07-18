
IF OBJECT_ID('DTI_SSLReceiptConsignBillQuery') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignBillQuery
GO 

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁세금계산서연결조회) by이재천
CREATE PROCEDURE DTI_SSLReceiptConsignBillQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS 
    
    DECLARE @docHandle    INT,  
            @ReceiptSeq   INT,  
            @ReceiptSerl   INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @ReceiptSeq  = ISNULL(ReceiptSeq,0)  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)         
    WITH (  ReceiptSeq     INT)     
    
    CREATE TABLE #TempBill  
    (  
        ReceiptSeq    INT,  
        BillSeq      INT,  
        CurAmt       DECIMAL(19,5),  
        DomAmt       DECIMAL(19,5)  
    )  
    
    INSERT INTO #TempBill  
    SELECT ReceiptSeq, BillSeq, SUM(CurAmt) AS CurAmt, SUM(DomAmt) AS DomAmt  
      FROM DTI_TSLReceiptConsignBill 
     WHERE CompanySeq = @CompanySeq  
       AND ReceiptSeq = @ReceiptSeq  
     GROUP BY ReceiptSeq, BillSeq  
    
    
    SELECT A.ReceiptSeq AS ReceiptSeq, -- 선수금대체내부번호  
           A.BillSeq    AS BillSeq,  
           B.BillNo     AS BillNo,  
           B.BillDate   AS BillDate,  
           C.CurAmt AS BillCurAmt, -- 세금계산서금액  
           C.DomAmt AS BillDomAmt, -- 세금계산서원화금액  
           ISNULL(D.CurAmt,0) AS PreBillCurAmt, -- 누계입금액  
           ISNULL(D.DomAmt,0) AS PreBillDomAmt, -- 누계입금원화금액  
           A.CurAmt AS CurAmt, -- 금회입금액  
           A.DomAmt AS DomAmt, -- 금회입금원화금액  
           
           E.RemValueName AS RemName, -- 영화명
           B.RemSeq, 
           B.MyCustSeq, 
           B.CustSeq, 
           F.CustName AS MyCustName, -- 공급자 
           G.CustName AS CustName -- 공급받는자
           
        
      FROM  #TempBill AS A   
      LEFT OUTER JOIN DTI_TSLBillConsign AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.Amt + X.VAT) AS CurAmt, SUM(X.Amt + X.Vat) AS DomAmt -- 세금계산서금액  
                         FROM DTI_TSLBillConsign AS X WITH (NOLOCK)  
                         JOIN #TempBill AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq ) 
                        GROUP BY X.BillSeq
                      ) AS C ON ( A.BillSeq = C.BillSeq )
      LEFT OUTER JOIN (SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt -- 누계반제  
                         FROM DTI_TSLReceiptConsignBill AS X WITH (NOLOCK)  
                         JOIN #TempBill AS Y ON ( X.CompanySeq = @CompanySeq AND X.BillSeq = Y.BillSeq ) 
                        GROUP BY X.BillSeq
                      ) AS D ON ( A.BillSeq = D.BillSeq ) 
      LEFT OUTER JOIN _TDAAccountRemValue AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.RemValueSerl = B.RemSeq )   
      LEFT OUTER JOIN _TDACust            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.MyCustSeq ) 
      LEFT OUTER JOIN _TDACust            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = B.CustSeq ) 
     WHERE A.ReceiptSeq   = @ReceiptSeq  
     ORDER BY A.ReceiptSeq, B.BillNo  
    
    RETURN 
GO
exec DTI_SSLReceiptConsignBillQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ReceiptSeq>24</ReceiptSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019203