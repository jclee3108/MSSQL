 
IF OBJECT_ID('hencom_SSLCustSalesReceiptListQuery') IS NOT NULL   
    DROP PROC hencom_SSLCustSalesReceiptListQuery  
GO  
  
-- v2017.04.13
  
-- 거래처별판매및수금내역_hencom-조회 by 이재천   
CREATE PROC hencom_SSLCustSalesReceiptListQuery  
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
            @BizUnit    INT, 
            @DeptSeq    INT, 
            @UMChannel  INT, 
            @StdYM      NCHAR(6) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit  , 0 ),  
           @DeptSeq     = ISNULL( DeptSeq  , 0 ),  
           @UMChannel   = ISNULL( UMChannel, 0 ),  
           @StdYM       = ISNULL( StdYM    , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              BizUnit    INT, 
              DeptSeq    INT, 
              UMChannel  INT, 
              StdYM      NCHAR(6)
           )    
    
    -- 결과테이블 
    CREATE TABLE #Result 
    (
        DeptSeq         INT, 
        CustSeq         INT, 
        PastCreditAmt   DECIMAL(19,5), 
        SalesAmt        DECIMAL(19,5), 
        ReceiptAmt      DECIMAL(19,5), 
        CreditAmt       DECIMAL(19,5), 
        CreditAmt12     DECIMAL(19,5), 
        CreditAmt6      DECIMAL(19,5), 
        CreditAmt3      DECIMAL(19,5), 
        CreditAmt2      DECIMAL(19,5), 
        CreditAmt1      DECIMAL(19,5), 
        NowCreditAmt    DECIMAL(19,5)
    )
    
    DECLARE @AccInitYM  NCHAR(6), 
            @FrDate     NCHAR(6), 
            @PrevFromYM NCHAR(6), 
            @FromDate   NCHAR(8), 
            @ToDate     NCHAR(8)

    SELECT @FromDate = @StdYM + '01'    
    SELECT @ToDate = CONVERT(NCHAR(8),DATEADD(D,-1,CONVERT(NCHAR(8),DATEADD(M,1,@StdYM+'01'),112)),112)    

    ------- 회기월 찾기                                  
    SELECT @AccInitYM = FrSttlYM                                  
      FROM _TDAAccFiscal                                  
     WHERE CompanySeq = @CompanySeq                                  
       AND LEFT(@FromDate, 6) BETWEEN FrSttlYM AND ToSttlYM    
             
    SELECT @FrDate = @AccInitYM     
    SELECT @PrevFromYM = CONVERT(NCHAR(6), DATEADD(month, -1, @FromDate), 112)   
    
    
    --select @FrDate, @ToDate 
    --return 
    -- 전월말미수금액
    INSERT INTO #Result ( CustSeq, DeptSeq, PastCreditAmt )
    SELECT A.CustSeq, A.DeptSeq,  
           SUM(CASE WHEN A.SumYM = @FrDate AND A.SumType = 0 THEN A.CurAmt      
                    WHEN A.SumYM BETWEEN @FrDate AND @PrevFromYM AND A.SumType = 1 THEN  A.CurAmt + A.CurVAT      
                    WHEN A.SumYM BETWEEN @FrDate AND @PrevFromYM AND A.SumType = 2 THEN A.CurAmt * (-1)
                    ELSE 0 END ) AS  PrevCreditAmt 
      FROM _TSLBillCreditSum AS A WITH(NOLOCK)
     WHERE A.CompanySeq = @CompanySeq     
       AND (@BizUnit = 0 OR a.BizUnit = @BizUnit)    
       AND  A.SumYM BETWEEN @FrDate AND @ToDate
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
     GROUP BY A.CustSeq, A.DeptSeq
    
    -- 당월매출액 
    --INSERT INTO #Result ( CustSeq, DeptSeq, SalesAmt )
    --SELECT A.CustSeq, A.DeptSeq, SUM(ISNULL(B.CurAmt,0) + ISNULL(B.CurVAT,0)) 
    --  FROM _TSLBill     AS A 
    --  JOIN _TSLBillItem AS B ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq ) 
    -- WHERE A.CompanySeq = @CompanySeq 
    --   AND LEFT(A.BillDate,6) = @StdYM 
    --   AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
    --   AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
    -- GROUP BY A.CustSeq, A.DeptSeq
    
    --select * From #Result 
    --where custseq = 7077
    --return 

    INSERT INTO #Result ( CustSeq, DeptSeq, SalesAmt )
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM = @StdYM       
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    
    -- 기간수금액    
    INSERT INTO #Result ( CustSeq, DeptSeq, ReceiptAmt )
    SELECT  M.CustSeq,
            M.DeptSeq,    
           SUM(CASE WHEN M.SumType = 2 THEN ISNULL(M.CurAmt,0) + ISNULL(M.CurVat,0)  ELSE 0 END) AS ReceiptAmt --기간수금액    
      FROM _TSLBillCreditSum AS M WITH(NOLOCK)
     WHERE M.CompanySeq = @CompanySeq
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)
       AND M.SumYM = @StdYM
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
    GROUP BY M.CustSeq, M.DeptSeq

    -- 당월말미수금 
    UPDATE A
       SET CreditAmt = ISNULL(A.PastCreditAmt,0) + ISNULL(A.SalesAmt,0) - ISNULL(A.ReceiptAmt,0) 
      FROM #Result AS A  
    
    -- 결과 데이터 집계 ( 사업소, 거래처 ) 
    SELECT DeptSeq, 
           CustSeq, 
           SUM(ISNULL(PastCreditAmt,0)) AS PastCreditAmt,
           SUM(ISNULL(SalesAmt     ,0)) AS SalesAmt     ,
           SUM(ISNULL(ReceiptAmt   ,0)) AS ReceiptAmt   ,
           SUM(ISNULL(CreditAmt    ,0)) AS CreditAmt    ,
           CONVERT(DECIMAL(19,5),0)     AS CreditAmt12  ,
           CONVERT(DECIMAL(19,5),0)     AS CreditAmt6   ,
           CONVERT(DECIMAL(19,5),0)     AS CreditAmt3   ,
           CONVERT(DECIMAL(19,5),0)     AS CreditAmt2   ,
           CONVERT(DECIMAL(19,5),0)     AS CreditAmt1   ,
           CONVERT(DECIMAL(19,5),0)     AS NowCreditAmt 
      INTO #ResultSum
      FROM #Result 
     GROUP BY DeptSeq, CustSeq 
    
    -- 전체 매출, 입금 데이터구하기 
    CREATE TABLE #SalesReceipt 
    (
        DeptSeq         INT, 
        CustSeq         INT, 
        ReceiptAmt      DECIMAL(19,5), -- 총 입금금액 
        SalesAmt12      DECIMAL(19,5), -- 12개월 이상 매출
        SalesAmt6       DECIMAL(19,5), -- 6개월 이상 매출
        SalesAmt3       DECIMAL(19,5), -- 3개월 이상 매출
        SalesAmt2       DECIMAL(19,5), -- 2개월 이상 매출
        SalesAmt1       DECIMAL(19,5), -- 1개월 이상 매출
        SalesAmt        DECIMAL(19,5)  -- 당월 매출
    ) 
    
    -- 전체입금액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, ReceiptAmt ) 
    SELECT M.CustSeq,
           M.DeptSeq,    
           SUM(CASE WHEN M.SumType = 2 THEN ISNULL(M.CurAmt,0) + ISNULL(M.CurVat,0)  ELSE 0 END) AS ReceiptAmt --기간수금액    
      FROM _TSLBillCreditSum AS M WITH(NOLOCK)
     WHERE M.CompanySeq = @CompanySeq
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)
       AND M.SumYM <= @StdYM
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
     GROUP BY M.CustSeq, M.DeptSeq

    -- 당월 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM = @StdYM       
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM = @StdYM       
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0 
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 
    
    -- 1개월 이상 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt1 ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM = CONVERT(NCHAR(6),DATEADD(MONTH,-1,@StdYM + '01'),112)       
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 
    
    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM = CONVERT(NCHAR(6),DATEADD(MONTH,-1,@StdYM + '01'),112)       
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 
    
    -- 2개월 이상 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt2 ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM = CONVERT(NCHAR(6),DATEADD(MONTH,-2,@StdYM + '01'),112)
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM = CONVERT(NCHAR(6),DATEADD(MONTH,-2,@StdYM + '01'),112)
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 
    
    -- 3개월 이상 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt3 ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM BETWEEN CONVERT(NCHAR(6),DATEADD(MONTH,-5,@StdYM + '01'),112) AND CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-2,@StdYM + '01')),112) 
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM BETWEEN CONVERT(NCHAR(6),DATEADD(MONTH,-5,@StdYM + '01'),112) AND CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-2,@StdYM + '01')),112) 
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 

    -- 6개월 이상 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt6 ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM BETWEEN CONVERT(NCHAR(6),DATEADD(MONTH,-11,@StdYM + '01'),112) AND CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-5,@StdYM + '01')),112) 
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM BETWEEN CONVERT(NCHAR(6),DATEADD(MONTH,-11,@StdYM + '01'),112) AND CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-5,@StdYM + '01')),112) 
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 

    -- 12개월 이상 매출액 
    INSERT INTO #SalesReceipt ( CustSeq, DeptSeq, SalesAmt12 ) 
	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) +SUM(M.CurVat) 
      FROM _TSLBillCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR m.BizUnit = @BizUnit)         
       AND M.SumYM <= CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-11,@StdYM + '01')),112)
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 1
    GROUP BY M.CustSeq, M.DeptSeq 

    UNION ALL 

	SELECT M.CustSeq ,     
           M.DeptSeq,    
           SUM(M.CurAmt) + SUM(M.CurVat) 
      FROM _TSLCreditSum AS M 
     WHERE M.CompanySeq = @CompanySeq 
       AND (@BizUnit = 0 OR M.BizUnit = @BizUnit)         
       AND M.SumYM <= CONVERT(NCHAR(6),DATEADD(DAY,-1,DATEADD(MONTH,-11,@StdYM + '01')),112)
       AND (@DeptSeq = 0 OR M.DeptSeq = @DeptSeq)
       AND M.SumType = 0
       AND M.SumYM = '201601'
    GROUP BY M.CustSeq, M.DeptSeq 

    -- 사업소, 거래처로 집계 
    SELECT A.DeptSeq, 
           A.CustSeq, 
           SUM(ISNULL(A.ReceiptAmt,0)) AS ReceiptAmt,
           SUM(ISNULL(A.SalesAmt12,0)) AS SalesAmt12,
           SUM(ISNULL(A.SalesAmt6 ,0)) AS SalesAmt6 ,
           SUM(ISNULL(A.SalesAmt3 ,0)) AS SalesAmt3 ,
           SUM(ISNULL(A.SalesAmt2 ,0)) AS SalesAmt2 ,
           SUM(ISNULL(A.SalesAmt1 ,0)) AS SalesAmt1 ,
           SUM(ISNULL(A.SalesAmt  ,0)) AS SalesAmt  
      INTO #SalesReceiptSum
      FROM #SalesReceipt AS A 
     GROUP BY A.DeptSeq, A.CustSeq 
    
    -- 선입선출 개념으로 매출액을 입금액을 순서대로 처리, Srt
    UPDATE A 
       SET SalesAmt12 = CASE WHEN SalesAmt12 - ReceiptAmt > 0 THEN SalesAmt12 - ReceiptAmt ELSE 0 END, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt12 > 0 THEN ReceiptAmt - SalesAmt12 ELSE 0 END
      FROM #SalesReceiptSum AS A 
    UPDATE A 
       SET SalesAmt6 = CASE WHEN SalesAmt6 - ReceiptAmt > 0 THEN SalesAmt6 - ReceiptAmt ELSE 0 END, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt6 > 0 THEN ReceiptAmt - SalesAmt6 ELSE 0 END
      FROM #SalesReceiptSum AS A 
    UPDATE A 
       SET SalesAmt3 = CASE WHEN SalesAmt3 - ReceiptAmt > 0 THEN SalesAmt3 - ReceiptAmt ELSE 0 END, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt3 > 0 THEN ReceiptAmt - SalesAmt3 ELSE 0 END
      FROM #SalesReceiptSum AS A 
    UPDATE A 
       SET SalesAmt2 = CASE WHEN SalesAmt2 - ReceiptAmt > 0 THEN SalesAmt2 - ReceiptAmt ELSE 0 END, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt2 > 0 THEN ReceiptAmt - SalesAmt2 ELSE 0 END
      FROM #SalesReceiptSum AS A 
    UPDATE A 
       SET SalesAmt1 = CASE WHEN SalesAmt1 - ReceiptAmt > 0 THEN SalesAmt1 - ReceiptAmt ELSE 0 END, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt1 > 0 THEN ReceiptAmt - SalesAmt1 ELSE 0 END
      FROM #SalesReceiptSum AS A 
    UPDATE A 
       SET SalesAmt = SalesAmt - ReceiptAmt, 
           ReceiptAmt = CASE WHEN ReceiptAmt - SalesAmt > 0 THEN ReceiptAmt - SalesAmt ELSE 0 END
      FROM #SalesReceiptSum AS A 
    -- 선입선출 개념으로 매출액을 입금액을 순서대로 처리, End 
    
    -- 결과 테이블에 선입선출 개념 연결 
    UPDATE A
       SET CreditAmt12  = B.SalesAmt12,
           CreditAmt6   = B.SalesAmt6 ,
           CreditAmt3   = B.SalesAmt3 ,
           CreditAmt2   = B.SalesAmt2 ,
           CreditAmt1   = B.SalesAmt1 ,
           NowCreditAmt = B.SalesAmt  
      FROM #ResultSum       AS A 
      JOIN #SalesReceiptSum AS B ON ( B.DeptSeq = A.DeptSeq AND B.CustSeq = A.CustSeq ) 
   
    -- 최종결과 
    -- 속도가 늦지 않아, 유지보수 편하게 하기 위해 최종에서 조회조건 추가 
    SELECT B.DeptName, 
           C.CustName, 
           A.DeptSeq, 
           A.CustSeq, 
           A.PastCreditAmt, 
           A.SalesAmt, 
           A.ReceiptAmt, 
           A.CreditAmt, 
           A.CreditAmt12, 
           A.CreditAmt6, 
           A.CreditAmt3, 
           A.CreditAmt2, 
           A.CreditAmt1, 
           A.NowCreditAmt, 
           @StdYM AS StdYM
      FROM #ResultSum               AS A 
      LEFT OUTER JOIN _TDADept      AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDACust      AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACustClass AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN hencom_TDADeptAdd AS E ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
     WHERE ( @UMChannel = 0 OR D.UMCustClass = @UMChannel ) 
       AND ( A.PastCreditAmt <> 0 OR A.SalesAmt <> 0 OR A.ReceiptAmt <> 0 OR A.CreditAmt <> 0 OR A.CreditAmt12 <> 0 OR A.CreditAmt6 <> 0 
          OR A.CreditAmt3 <> 0 OR A.CreditAmt2 <> 0 OR A.CreditAmt1 <> 0 OR NowCreditAmt <> 0 
           )
       AND ISNULL(E.UMTotalDiv,0) <> 0   
     ORDER BY B.DeptName, C.CustName 
    
    RETURN

go 
begin tran 
exec hencom_SSLCustSalesReceiptListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <StdYM>201703</StdYM>
    <DeptSeq>41</DeptSeq>
    <UMChannel />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511654,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033187
rollback 