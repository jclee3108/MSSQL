  
IF OBJECT_ID('DTI_SSLBillConsignListQuery') IS NOT NULL   
    DROP PROC DTI_SSLBillConsignListQuery  
GO  
  
-- v2014.05.20  
  
-- 위수탁세금계산서조회_DTI-조회 by 이재천   
CREATE PROC DTI_SSLBillConsignListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT, 
            @DtiType        INT, 
            @MyCustSeq      INT, 
            @SMProgType     INT, 
            @BizUnit        INT, 
            @RemSeq         INT, 
            @BillDateTo     NCHAR(8), 
            @BillDateFr     NCHAR(8), 
            @CustSeq        INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @DtiType        = DtiType         ,
           @MyCustSeq      = MyCustSeq       ,
           @SMProgType     = SMProgType      ,
           @BizUnit        = BizUnit         ,
           @RemSeq         = RemSeq          ,
           @BillDateTo     = BillDateTo      ,
           @BillDateFr     = BillDateFr      ,
           @CustSeq        = CustSeq         
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
                DtiType         INT ,
                MyCustSeq       INT ,
                SMProgType      INT ,
                BizUnit         INT ,
                RemSeq          INT ,
                BillDateTo      NCHAR(8) ,
                BillDateFr      NCHAR(8) ,
                CustSeq         INT 
           )
    
    SELECT A.BillSeq, 
           A.BillNo, 
           A.BillDate, 
           A.MyCustSeq, 
           C.CustName AS MyCustName, -- 공급자
           STUFF(STUFF(C.BizNo,4,0,'-'),7,0,'-') AS MyCustBizNo, 
           A.CustSeq, 
           D.CustName, 
           STUFF(STUFF(D.BizNo,4,0,'-'),7,0,'-') AS CustBizNo, 
           E.RemValueName AS RemName, -- 영화명
           A.ItemName, 
           A.Qty, 
           A.Price, 
           A.Amt, 
           A.VAT AS Vat, 
           ISNULL(A.Amt,0) + ISNULL(A.VAT,0) AS SumAmt, 
           A.MyMail, -- 공급자 이메일
           A.CustMail, -- 공급받는자 이메일
           A.ConsignMail, -- 수탁자 이메일
           CASE WHEN ABS(ISNULL(J.TotCurAmt,0)) - ABS(ISNULL(J.ReceiptCurAmt,0)) = 0 THEN 1070001 ELSE 1070002 END AS SMProgType,   -- 진행상태코드
           CASE WHEN ABS(ISNULL(J.TotCurAmt,0)) - ABS(ISNULL(J.ReceiptCurAmt,0)) = 0 
                THEN (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1070001) 
                ELSE (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1070002)  
                END AS SMProgTypeName  -- 진행상태
    
      FROM DTI_TSLBillConsign               AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TDACust              AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.MyCustSeq ) 
      LEFT OUTER JOIN _TDACust              AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAAccountRemValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.RemValueSerl = A.RemSeq ) 
      LEFT OUTER JOIN _TDADept              AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.DeptSeq = A.DeptSeq ) 
      CROSS APPLY ( --합계 구하기  
                    SELECT A1.BillSeq, 
                           SUM(A1.Amt) AS CurAmt, SUM(A1.VAT) AS CurVAT, SUM(A1.Amt) + SUM(A1.VAT) AS TotCurAmt, 
                           SUM(A1.Amt) AS DomAmt, SUM(A1.VAT) AS DomVAT, SUM(A1.Amt) + SUM(A1.VAT) AS TotDomAmt, 
                           (SELECT SUM(CurAmt) FROM DTI_TSLReceiptConsignBill WHERE CompanySeq = @CompanySeq AND BillSeq = A1.BillSeq) AS ReceiptCurAmt,
                           (SELECT SUM(DomAmt) FROM DTI_TSLReceiptConsignBill WHERE CompanySEq = @CompanySeq AND BillSeq = A1.BillSeq) AS ReceiptDomAmt 
                      FROM DTI_TSLBillConsign AS A1 WITH(NOLOCK)  
                     WHERE A1.CompanySeq = @CompanySeq  
                       AND A1.BillSeq = A.BillSeq 
                     GROUP BY A1.BillSeq   
                  ) AS J 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @BizUnit = 0 OR F.BizUnit = @BizUnit ) 
       AND ( A.BillDate BETWEEN @BillDateFr AND @BillDateTo ) 
       AND ( @RemSeq = 0 OR A.RemSeq = @RemSeq ) -- 영화명 조회조건
       AND ( @MyCustSeq = 0 OR A.MyCustSeq = @MyCustSeq ) 
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
       -- 전송상태 @DtiType
       AND ( @SMProgType = 0 
          OR (@SMProgType = 1070001 AND ABS(ISNULL(J.TotCurAmt,0)) - ABS(ISNULL(J.ReceiptCurAmt,0)) = 0)  
          OR (@SMProgType = 1070002 AND ABS(ISNULL(J.TotCurAmt,0)) - ABS(ISNULL(J.ReceiptCurAmt,0)) > 0)
            )  -- 진행상태 
    
    RETURN  