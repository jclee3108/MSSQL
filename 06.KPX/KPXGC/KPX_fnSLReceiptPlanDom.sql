
IF OBJECT_ID('KPX_fnSLReceiptPlanDom') IS NOT NULL
    DROP FUNCTION KPX_fnSLReceiptPlanDom
GO

-- v2014.12.19 

-- 거래처별수금예정계획_KPX 공통함수 by이재천 
CREATE FUNCTION KPX_fnSLReceiptPlanDom  
(  
    @CompanySeq INT,  
    @CustSeq    INT,  
    @SMLocalExp INT  -- 8918001 : 내수, 8918002 : 수출 (select * from _TDASMinor where MajorSeq = 8918)  
)  
RETURNS @SalesReceiptPlan TABLE  
(  
    --BillSeq         INT,  
    --EmpSeq          INT,  
    BizUnit         INT,  
    CustName        NVARCHAR(100),  
    CustNo          NVARCHAR(100),  
    CustSeq         INT,  
    SMCustStatus    INT,  
    BillDate        NCHAR(8),  
    ReceiptDate     NCHAR(8),  
    SMCondStd       INT,  
    SMReceiptKind   INT,  
    CurrSeq         INT,  
    CurAmt          DECIMAL(19,5),  
    DomAmt          DECIMAL(19,5),  
    RemCurAmt       DECIMAL(19,5),  
    RemDomAmt       DECIMAL(19,5)  
)  
  
AS  
BEGIN  
  
    INSERT @SalesReceiptPlan  
    SELECT 
    --MAX(ISNULL(ISNULL(G.EmpSeq, H.EmpSeq), 0))   AS EmpSeq,  -- 영업담당자코드  
           --MAX(ISNULL(ISNULL(G.DeptSeq, H.DeptSeq), 0)) AS DeptSeq, -- 영업담당부서코드 
           A.BizUnit AS BizUnit, 
           MAX(F.CustName)           AS CustName,     -- 거래처명 
           MAX(F.CustNo)             AS CustNo, -- 거래처번호 
           A.CustSeq                 AS CustSeq,      -- 거래처코드  
           MAX(F.SMCustStatus)       AS SMCustStatus, -- 거래처상태  
           A.BillDate                AS BillDate,     -- 세금계산서일자  
           (CASE WHEN I.SMReceiptPoint = 8122001  
                 THEN (CASE WHEN I.ReceiptDate1 > I.ReceiptDate2   
                            THEN I.ReceiptDate2  
                            ELSE I.ReceiptDate1   
                       END)  
                 ELSE ReceiptDate3  
           END)                      AS ReceiptDate,  -- 수금예정일  
           MAX(I.SMCondStd)          AS SMCondStd,    -- 회수구분  
           MAX(I.SMReceiptKind)      AS SMReceiptKind,-- 입금구분  
           A.CurrSeq                 AS CurrSeq,      -- 통화  
           ISNULL(SUM(C.CurAmt), 0)  AS CurAmt,       -- 판매금액  
           ISNULL(SUM(C.DomAmt), 0)  AS DomAmt,       -- 원화판매금액   
           ISNULL(SUM(C.CurAmt), 0) - (ISNULL(SUM(D.CurAmt), 0) + ISNULL(SUM(E.CurAmt), 0)) AS RemCurAmt, -- 미수잔액  
           ISNULL(SUM(C.DomAmt), 0) - (ISNULL(SUM(D.DomAmt), 0) + ISNULL(SUM(E.DomAmt), 0)) AS RemDomAmt  -- 원화미수잔액  
      FROM _TSLBill AS A WITH(NOLOCK)  
           CROSS APPLY (-- 세금계산서 매출금액계  
                        SELECT X.BillSeq, SUM(Y.CurAmt + Y.CurVAT) AS CurAmt, SUM(Y.DomAmt + Y.DomVAT) AS DomAmt  
                          FROM _TSLSalesBillRelation AS X WITH(NOLOCK)  
                               JOIN _TSLSalesItem    AS Y WITH(NOLOCK) ON X.CompanySeq = Y.CompanySeq  
                                                                      AND X.SalesSeq   = Y.SalesSeq  
                                                                      AND X.SalesSerl  = Y.SalesSerl  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS C  
           OUTER APPLY (-- 세금계산서 입금액계  
                        SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt  
                          FROM _TSLReceiptBill AS X WITH(NOLOCK)  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS D  
           OUTER APPLY (-- 세금계산서 선수금대체금액계  
                        SELECT X.BillSeq, SUM(X.CurAmt) AS CurAmt, SUM(X.DomAmt) AS DomAmt  
                          FROM _TSLPreReceiptBill AS X WITH(NOLOCK)  
                         WHERE X.CompanySeq = @CompanySeq  
                           AND X.BillSeq    = A.BillSeq  
                         GROUP BY X.BillSeq  
                       ) AS E  
           OUTER APPLY (-- 청구처매출회수조건에 의한 자금예정일 계산  
                        SELECT TOP 1   
                               I1.CustSeq,  
                               I1.SMCondStd,  
                               I1.SMReceiptPoint,  
                               I2.SMReceiptKind,  
                               (CONVERT(NVARCHAR(8), DATEADD(DAY, -1, DATEADD(MONTH, 1, CONVERT(NVARCHAR(6), DATEADD(MONTH, I2.ReceiptMonth, A.BillDate), 112) + '01')), 112) ) AS ReceiptDate1, -- 회수월에 의한 말일 계산 (회수일이 없는 월을 구분하기 위한 작업)  
                               (CONVERT(NVARCHAR(6), DATEADD(MONTH, I2.ReceiptMonth, A.BillDate), 112)  
                                  + (CASE WHEN I2.ReceiptDate < 10 THEN '0'+ CONVERT(NVARCHAR(2), I2.ReceiptDate)  
                                          ELSE CONVERT(NVARCHAR(2), I2.ReceiptDate)  
                                          END  
                                    )  
                               ) AS ReceiptDate2, -- 회수월 + 회수일로 계산  
                               CONVERT(NVARCHAR(8),DATEADD(DAY, I1.Term, A.BillDate), 112) AS ReceiptDate3 -- 회수기간에 의한 일자  
                          FROM _TDACustSalesReceiptCond AS I1 WITH(NOLOCK)  
                               JOIN _TDACustSalesReceiptStd  AS I2 WITH(NOLOCK) ON ( I1.CompanySeq = I2.CompanySeq AND I1.CondSeq = I2.CondSeq )  
                         WHERE I1.CompanySeq = @CompanySeq  
                           AND I1.CustSeq    = A.CustSeq  
                         ORDER BY I2.CondSerl  
                       ) AS I  
                      JOIN _TDACust              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq )  
           --LEFT OUTER JOIN _TSLCustSalesEmp      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = A.CustSeq AND G.SDate <= A.BillDate )  
           --LEFT OUTER JOIN _TSLCustSalesEmpHist  AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.CustSeq AND A.BillDate BETWEEN H.SDate AND H.EDate )  
     WHERE A.CompanySeq = @CompanySeq  
       AND ISNULL(C.DomAmt, 0) > (ISNULL(D.DomAmt, 0) + ISNULL(E.DomAmt, 0))  
       AND (@SMLocalExp = 0 OR (@SMLocalExp = 8918001 AND EXISTS (SELECT TOP 1 1   
                                                                    FROM _TDASMinorValue   
                                                                   WHERE CompanySeq = @CompanySeq   
                                                                     AND MinorSeq   = A.SMExpKind   
                                                                     AND Serl       = 1001 -- 내수  
                                                                     AND ValueText  = '1'))  
                            OR (@SMLocalExp = 8918002 AND EXISTS (SELECT TOP 1 1   
                                                                    FROM _TDASMinorValue   
                                                                   WHERE CompanySeq = @CompanySeq   
                                                                     AND MinorSeq   = A.SMExpKind   
                                                                     AND Serl       = 1002 -- 수출  
                                                                     AND ValueText  = '1')) )  
     GROUP BY A.CustSeq,   
              A.BillDate, 
              A.BizUnit,  
              (CASE WHEN I.SMReceiptPoint = 8122001  
                    THEN (CASE WHEN I.ReceiptDate1 > I.ReceiptDate2   
                               THEN I.ReceiptDate2  
                               ELSE I.ReceiptDate1   
                          END)  
                    ELSE ReceiptDate3  
              END),   
              A.CurrSeq  
  
    RETURN  
END  