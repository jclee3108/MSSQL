
IF OBJECT_ID('DTI_SSLBillCollectRateSubQuery') IS NOT NULL
    DROP PROC DTI_SSLBillCollectRateSubQuery
GO

-- v2014.02.12 

-- 채권회수율(담당자)_DTI-조회 by이재천 
CREATE PROC DTI_SSLBillCollectRateSubQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    DECLARE @docHandle          INT        ,    
            -- 조회조건     
            @BizUnit            INT        ,  
            @FundArrangeDateFr  NVARCHAR(8),    
            @FundArrangeDateTo  NVARCHAR(8),  
            @STDDate            NVARCHAR(8),  
            @BillDateFr         NVARCHAR(8),  
            @BillDateTo         NVARCHAR(8),  
            @DeptSeq            INT        ,  
            @EmpSeq             INT             
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @BizUnit           = ISNULL( BizUnit          , 0  ),            
           @FundArrangeDateFr = ISNULL( FundArrangeDateFr, '' ),  
           @FundArrangeDateTo = ISNULL( FundArrangeDateTo, 0  ),  
           @STDDate           = ISNULL( STDDate          , '' ),  
           @BillDateFr        = ISNULL( BillDateFr       , '' ),  
           @BillDateTo        = ISNULL( BillDateTo       , '' ),  
           @DeptSeq           = ISNULL( DeptSeq          , 0  ),  
           @EmpSeq            = ISNULL( EmpSeq           , 0  )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (BizUnit            INT        ,  
            FundArrangeDateFr  NVARCHAR(8),  
            FundArrangeDateTo  NVARCHAR(8),  
            STDDate            NVARCHAR(8),  
            BillDateFr         NVARCHAR(8),  
            BillDateTo         NVARCHAR(8),  
            DeptSeq            INT        ,  
            EmpSeq             INT          
           )  
    
    -- 자금예정일To가 공백일 경우      
    IF @FundArrangeDateTo = '' SELECT @FundArrangeDateTo = '99991231'  
    
    -- 임시 테이블 
    CREATE TABLE #Temp_TSLBill  
    (   
        IDX_NO          INT IDENTITY,  
        SalesSeq        INT,
        SalesSerl       INT,
        BillSeq         INT, 
        Qty             DECIMAL(19,5),
        SalesDomAmt     DECIMAL(19,5),
        BizUnit         INT,
        CustSeq         INT,
        DeptSeq         INT,
        EmpSeq          INT,
        FundArrangeDate NVARCHAR(8),
        BillDate        NVARCHAR(8),
        DelvInAmt       DECIMAL(19,5)
    )
    
    -- 진행 테이블명 테이블 
    CREATE TABLE #TMP_SOURCETABLE( IDOrder INT IDENTITY, TableName NVARCHAR(100) )        
    
    -- 원천 테이블 
    CREATE TABLE #TCOMSourceTracking( IDX_NO INT, IDOrder INT, Seq INT, Serl INT, SubSerl INT, 
	                                  Qty DECIMAL(19, 5), STDQty DECIMAL(19, 5), Amt DECIMAL(19, 5), VAT DECIMAL(19, 5) )        
	
    INSERT INTO #Temp_TSLBill  
    (
        SalesSeq, SalesSerl, BillSeq, Qty, SalesDomAmt,
        BizUnit, CustSeq, DeptSeq, EmpSeq, FundArrangeDate, 
        BillDate
    )                
    SELECT B.SalesSeq, B.SalesSerl, A.BillSeq, ISNULL(C.Qty,0), ISNULL(C.DomAmt,0) AS SalesDomAmt,
           A.BizUnit, A.CustSeq, A.DeptSeq, A.EmpSeq, A.FundArrangeDate, 
           A.BillDate
           
      FROM _TSLBill AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TSLSalesBillRelation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.BillSeq = B.BillSeq ) 
      LEFT OUTER JOIN _TSLSalesItem         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND B.SalesSeq = C.SalesSeq AND B.SalesSerl = C.SalesSerl )
      
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND A.FundArrangeDate BETWEEN @FundArrangeDateFr AND @FundArrangeDateTo 
       AND A.BillDate BETWEEN @BillDateFr AND @BillDateTo 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq )              
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq )               
    
    INSERT #TMP_SOURCETABLE(TableName)
    SELECT '_TSLInvoiceItem'  
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLSalesItem', '#Temp_TSLBill', 'SalesSeq', 'SalesSerl', '' -- 원천
    
    -- 구매입고금액 Update
    UPDATE Z 
       SET Z.DelvInAmt   = ISNULL(C.DomAmt,0) + ISNULL(C.DomVAT,0)
      FROM #Temp_TSLBill AS Z
      LEFT OUTER JOIN #TCOMSourceTracking AS A WITH(NOLOCK) ON ( A.IDX_NO = Z.IDX_NO )
      LEFT OUTER JOIN _TSLInvoiceItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl AND A.IDOrder = 1 )
      LEFT OUTER JOIN _TPUDelvinItem      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.LotNo = B.LotNo )
    
    -- 세금계산서 건별 집계
    -- 평균GP율 (세금계산서 기준)
    SELECT A.BillSeq,
           CONVERT(DECIMAL(19,5),0) AS TotDomAmt,-- 채권총액
           ISNULL((SUM(A.SalesDomAmt) - SUM(A.DelvInAmt)) / NULLIF(SUM(A.SalesDomAmt),0),0) * 100 AS AvgGPRate,
           MAX(A.BizUnit) AS BizUnit, 
           MAX(A.CustSeq) AS CustSeq, 
           MAX(A.DeptSeq) AS DeptSeq, 
           MAX(A.EmpSeq) AS EmpSeq, 
           MAX(A.FundArrangeDate) AS FundArrangeDate, 
           MAX(A.BillDate) AS BillDate,
           CONVERT(DECIMAL(19,5),0) AS AvgCollectDate,
           CONVERT(DECIMAL(19,5),0) AS TotNoReceiptAmt, -- 미수총액
           CONVERT(DECIMAL(19,5),0) AS TotOverdueAmt,   -- 연체총액
           CONVERT(DECIMAL(19,5),0) AS TotMortageAmt   -- 담보총액
    
      INTO #TSLBill  
      FROM #Temp_TSLBill AS A
     GROUP BY A.BillSeq
    
    -- 채권총액(=세금계산서총액), 평균회수일, 미수금액, 담보금액 Update                     
    UPDATE A
       SET A.AvgCollectDate  = ISNULL(B.AvgCollectDate,0), 
           A.TotNoReceiptAmt = ISNULL(Z.TotDomAmt,0) - ISNULL(B.TotNoReceiptAmt,0),
           A.TotOverdueAmt   = (CASE WHEN @STDDate <= A.FundArrangeDate THEN 0 ELSE ISNULL(Z.TotDomAmt,0) - ISNULL(B.TotNoReceiptAmt,0) END), 
           A.TotMortageAmt   = ISNULL(C.SpecCreditAmt,0),
           A.TotDomAmt       = ISNULL(Z.TotDomAmt,0)
           
      FROM #TSLBill AS A 
           LEFT OUTER JOIN (SELECT A.BillSeq, SUM(ISNULL(B.DomAmt,0)+ISNULL(B.DomVAT,0)) AS TotDomAmt
                              FROM #TSLBill AS A
                              JOIN _TSLBillItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq )
                             GROUP BY A.BillSeq
                           )  AS Z ON ( Z.BillSeq = A.BillSeq )
                           
           LEFT OUTER JOIN (SELECT A.BillSeq,
                                   AVG(DATEDIFF(DAY, A.BillDate, E.ReceiptDate)) AS AvgCollectDate, -- 회수일 = 입금일 - 세금계산서일
                                   SUM(ISNULL(C.DomAmt,0)+ISNULL(D.DomAmt,0)) AS TotNoReceiptAmt
                              FROM #TSLBill AS A
                              LEFT OUTER JOIN _TSLReceiptBill     AS C WITH(NOLOCK) ON ( C.companySeq = @CompanySeq AND C.BillSeq = A.BillSeq ) -- 입금 
                              LEFT OUTER JOIN _TSLPreReceiptBill  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BillSeq = A.BillSeq ) -- 선수금 
                              LEFT OUTER JOIN _TSLReceipt         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ReceiptSeq = C.ReceiptSeq )
                             WHERE E.ReceiptDate <= @STDDate
                             GROUP BY A.BillSeq
                           )  AS B ON ( B.BillSeq = A.BillSeq )
 
           LEFT OUTER JOIN (SELECT A.BillSeq, SUM(ISNULL(B.SpecCreditAmt,0)) AS SpecCreditAmt
                              FROM #TSLBill AS A
                              JOIN _TSLCustSpecCredit  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq )
                             WHERE @STDDate BETWEEN B.SDate AND B.EDate
                             GROUP BY A.BillSeq
                           )  AS C ON ( A.BillSeq = C.BillSeq )
    
    -- 최종조회(부서담당자별)  
    SELECT A.DeptSeq,
           MAX(B.DeptName) AS DeptName,
           A.EmpSeq,  
           MAX(C.EmpName) AS EmpName,
           SUM(A.TotDomAmt) AS TotBondAmt, -- 채권총액  
           SUM(A.TotNoReceiptAmt) AS TotNoReceiptAmt, -- 미수총액 (세금계산서조회 화면로직 참조)
           SUM(A.TotOverdueAmt) AS TotOverdueAmt, -- 연체총액 : 자금예정일이 기준일을 지난 미수금  
           SUM(A.TotMortageAmt) AS TotMortageAmt, -- 담보금액   
           AVG(A.AvgCollectDate) AS AvgCollectDate,  -- 평균회수일  
           AVG(A.AvgGPRate) AS AvgGPRate, -- 평균GP율 (세금계산서기준) 
           ISNULL(SUM(A.TotMortageAmt)/NULLIF(SUM(A.TotDomAmt),0),0)*100 AS MortageRate, -- 담보비율 : 담보금액/채권총액*100  
           ISNULL(SUM(A.TotOverdueAmt)/NULLIF(SUM(A.TotDomAmt),0),0)*100 AS OverdueRate  -- 연체비율 : 연체채권/채권총액*100
           
       FROM #TSLBill AS A  
      JOIN _TDADept AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq )
      JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq )
     GROUP BY A.DeptSeq, A.EmpSeq  
    
    RETURN 
GO
exec DTI_SSLBillCollectRateSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FundArrangeDateFr />
    <FundArrangeDateTo />
    <STDDate>20140212</STDDate>
    <BillDateFr>20140201</BillDateFr>
    <BillDateTo>20140212</BillDateTo>
    <BizUnit>1</BizUnit>
    <DeptSeq/>
    <EmpSeq/>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1014863,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1012960
