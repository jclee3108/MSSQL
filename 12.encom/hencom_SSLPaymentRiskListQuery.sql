 
IF OBJECT_ID('hencom_SSLPaymentRiskListQuery') IS NOT NULL   
    DROP PROC hencom_SSLPaymentRiskListQuery  
GO  

-- v2018.12.11
  
-- 결제조건위반현황(입금완료포함)_hencom-조회 by 이재천   
CREATE PROC hencom_SSLPaymentRiskListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdDate    NCHAR(8), 
            @DeptSeq    INT, 
            @CustSeq    INT, 
            @Over1Times NCHAR(1),
            @Over2Times NCHAR(1), 
            @Over3Times NCHAR(1), 
            @IsLongTerm NCHAR(1) 

      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdDate     = ISNULL( StdDate   , '' ),  
           @DeptSeq     = ISNULL( DeptSeq   , 0 ),  
           @CustSeq     = ISNULL( CustSeq   , 0 ),  
           @Over1Times  = ISNULL( Over1Times, '0' ),  
           @Over2Times  = ISNULL( Over2Times, '0' ),  
           @Over3Times  = ISNULL( Over3Times, '0' ),  
           @IsLongTerm  = ISNULL( IsLongTerm, '0' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdDate    NCHAR(8),
            DeptSeq    INT, 
            CustSeq    INT, 
            Over1Times NCHAR(1),
            Over2Times NCHAR(1),
            Over3Times NCHAR(1),
            IsLongTerm NCHAR(1) 
           )    
    
    -- 조회 
    -- 세금계산서에 연결되어 있는입금내역 가져오기
    SELECT D.DeptName, 
           A.DeptSeq, 
           C.CustName, 
           A.CustSeq, 
           C.BizNo,
           A.BillNo, 
           A.BillDate, 
           A.FundArrangeDate,
           B.TotCurAmt,
           E.LastReceiptDate, 
           E.TotReceiptAmt, 
           ISNULL(B.TotCurAmt,0) - ISNULL(E.TotReceiptAmt,0) AS AcctReceivable, 
           '1' AS IsOverdue, 
           '0' AS Over1Times, 
           '0' AS Over2Times, 
           '0' AS Over3Times, 
           '0' AS IsLongTerm, 
           ROW_NUMBER() OVER(PARTITION BY A.DeptSeq, A.CustSeq ORDER BY A.DeptSeq, A.CustSeq) AS RowNumber -- 사업소, 거래처별로의 Count
      INTO #Result 
      FROM _TSLBill AS A 
      OUTER APPLY (
                    SELECT Z.BillSeq, SUM(Z.CurAmt) AS TotCurAmt 
                      FROM _TSLBillItem AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.BillSeq = A.BillSeq 
                     GROUP BY Z.BillSeq 
                   ) AS B
      OUTER APPLY (
                    SELECT MAX(Q.ReceiptDate) AS LastReceiptDate, SUM(Y.CurAmt) AS TotReceiptAmt
                      FROM _TSLReceiptBill              AS Z 
                      LEFT OUTER JOIN _TSLReceipt       AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.ReceiptSeq = Z.ReceiptSeq ) 
                      LEFT OUTER JOIN _TSLReceiptDesc   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ReceiptSeq = Q.ReceiptSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.BillSeq = A.BillSeq 
                     GROUP BY Z.BillSeq 
                  ) AS E 
      LEFT OUTER JOIN _TDACust      AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept      AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BillDate <= @StdDate 
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( (ISNULL(B.TotCurAmt,0) - ISNULL(E.TotReceiptAmt,0) > 0) OR (E.LastReceiptDate > A.FundArrangeDate) )
       --AND @StdDate BETWEEN D.BegDate AND D.EndDate 
    ORDER BY A.DeptSeq, A.CustSeq, A.BillDate, A.BillNo

    -- Count별로 위반 횟수 Update 
    UPDATE A
       SET Over1Times = CASE WHEN RowNumber >= 1 THEN '1' ELSE '0' END, 
           Over2Times = CASE WHEN RowNumber >= 2 THEN '1' ELSE '0' END, 
           Over3Times = CASE WHEN RowNumber >= 3 THEN '1' ELSE '0' END, 
           IsLongTerm = CASE WHEN RowNumber >= 4 THEN '1' ELSE '0' END 
      FROM #Result AS A 

    -- 최종 위반 횟수 조회조건
    SELECT * 
      FROM #Result  
     WHERE RowNumber >= CASE WHEN @Over1Times = '1' THEN 1 
                             WHEN @Over2Times = '1' THEN 2 
                             WHEN @Over3Times = '1' THEN 3 
                             WHEN @IsLongTerm = '1' THEN 4 
                             END 
     ORDER BY DeptSeq, CustSeq, BillDate, BillNo
       
    RETURN  

    go

    exec hencom_SSLPaymentRiskListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CustSeq />
    <DeptSeq />
    <Over3Times>1</Over3Times>
    <IsLongTerm>0</IsLongTerm>
    <Over1Times>1</Over1Times>
    <Over2Times>1</Over2Times>
    <StdDate>20181211</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=2000046,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=562,@PgmSeq=2000049