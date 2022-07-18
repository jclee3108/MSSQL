
IF OBJECT_ID('KPX_SSLCustCreditListQuery') IS NOT NULL 
    DROP PROC KPX_SSLCustCreditListQuery
GO 

-- v2014.12.29 

-- 여신한도조회 - 조회 by이재천 
CREATE PROC KPX_SSLCustCreditListQuery                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
AS 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT, 
            @CustStatus     INT, 
            @StdDate        NCHAR(8), 
            @CustNo         NVARCHAR(100), 
            @CustName       NVARCHAR(100), 
            @BizNo          NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @CustStatus  = ISNULL(CustStatus,0), 
            @StdDate    = ISNULL(StdDate,''), 
            @CustNo     = ISNULL(CustNo,''), 
            @CustName   = ISNULL(CustName,''), 
            @BizNo      = ISNULL(BizNo,'') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            CustStatus      INT,  
            StdDate         NCHAR(8) ,  
            CustNo          NVARCHAR(100) ,  
            CustName        NVARCHAR(100) ,  
            BizNo           NVARCHAR(100) 
           )  
    
    CREATE TABLE #Temp 
    (
        CustSeq     INT, 
        CreditAmt   DECIMAL(19,5), 
        Kind        INT 
    ) 
    
    INSERT INTO #Temp ( CustSeq, CreditAmt, Kind ) 
    SELECT A.CustSeq, SUM(CreditAmt), 1
      FROM KPX_TSLCustCreditCalc AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND @StdDate BETWEEN A.SDate AND EDate 
     GROUP BY A.CustSeq 
     
    UNION ALL 
    
    SELECT A.CustSeq, SUM(A.SecuSetAmt), 2
      FROM KPX_TSLCustSecurity AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND @StdDate BETWEEN A.SecuSetDate AND A.SecuCancDate 
     GROUP BY A.CustSeq 
    
    UNION ALL 
    
    SELECT A.CustSeq, SUM(A.Amt), 3 
      FROM KPX_SLCustCreditEtc AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND @StdDate BETWEEN A.SDate AND A.EDate 
     GROUP BY A.CustSeq 
    
    SELECT A.CustSeq, 
           X.CustName, 
           X.CustNo, 
           X.BizNo,
           ISNULL(B.Amt,0) AS CreditAmt, 
           ISNULL(C.Amt,0) AS SecuritiesAmt, 
           ISNULL(D.Amt,0) AS SpecialAmt, 
           ISNULL(B.Amt,0) + ISNULL(C.Amt,0) + ISNULL(D.Amt,0) AS TotCredit, 
           ISNULL(E.Amt,0) AS CreditSalesAmt 
      FROM (SELECT DISTINCT CustSeq FROM #Temp) AS A 
      LEFT OUTER JOIN _TDACust AS X ON ( X.CompanySeq = @CompanySeq AND X.CustSeq = A.CustSeq ) 
      OUTER APPLY ( SELECT SUM(CreditAmt) AS Amt
                      FROM #Temp AS Z 
                     WHERE Z.CustSeq = A.CustSeq 
                       AND Z.Kind = 1 
                  ) AS B
      OUTER APPLY ( SELECT SUM(CreditAmt) AS Amt
                      FROM #Temp AS Z 
                     WHERE Z.CustSeq = A.CustSeq 
                       AND Z.Kind = 2 
                  ) AS C
      OUTER APPLY ( SELECT SUM(CreditAmt) AS Amt 
                      FROM #Temp AS Z 
                     WHERE Z.CustSeq = A.CustSeq 
                       AND Z.Kind = 3 
                  ) AS D
      OUTER APPLY (  SELECT Z.CustSeq, SUM(Y.DomAmt) AS Amt 
                       FROM _TSLSales     AS Z 
                       JOIN _TSLSalesItem AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.SalesSeq = Z.SalesSeq ) 
                       LEFT OUTER JOIN _TSLSalesBillRelation AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.SalesSeq = Y.SalesSeq AND Q.SalesSerl = Y.SalesSerl ) 
                       LEFT OUTER JOIN _TSLReceiptBill       AS W ON ( W.CompanySeq = @CompanySeq AND W.BillSeq = Q.BillSeq ) 
                      WHERE Z.CompanySeq = @CompanySeq 
                        AND ISNULL(W.ReceiptSeq,0) = 0 
                        AND Z.CustSeq = A.CustSeq 
                      GROUP BY Z.CustSeq 
                  ) AS E 
    
    
    /*
    반제되지 않은금액 구하기위한 도움
    SELECT *
  FROM _TACSlipRow AS A 
  JOIN _TACSlipOn AS B ON ( B.CompanySeq = 1 AND B.SlipSeq = A.SlipSeq ) 
  LEFT OUTER JOIN _TACSlipRem   AS C ON ( C.CompanySeq = 1 AND C.SlipSeq = A.SlipSeq AND C.RemSeq = 1017 ) 
  LEFT OUTER JOIN _TACSlipOff   AS D ON ( D.CompanySeq = 1 AND D.OnSlipSeq = B.SlipSeq ) 
  
 WHERE A.CompanySeq = 1 
   and A.AccSeq = 26


    
    
    
    */
    
    
    RETURN  
GO 

exec KPX_SSLCustCreditListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate>20141229</StdDate>
    <CustName />
    <CustNo />
    <CustStatus />
    <BizNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027170,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022717
