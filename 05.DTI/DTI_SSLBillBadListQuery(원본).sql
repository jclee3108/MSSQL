/************************************************************      
 설  명 - 데이터-부실채권처리_DTI : 현황-조회
 작성일 - 20100519 : CREATEd by
 작성자 - 문태중
 ************************************************************/      
 CREATE PROC dbo.DTI_SSLBillBadListQuery
     @xmlDocument    NVARCHAR(MAX) ,
     @xmlFlags       INT  = 0,
     @ServiceSeq     INT  = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT  = 1,
     @LanguageSeq    INT  = 1,
     @UserSeq        INT  = 0,
     @PgmSeq         INT  = 0
  AS
      DECLARE @docHandle      INT,
             @BillNo         NVARCHAR(50),
             @BadDeptSeq     INT,
             @BadEmpSeq      INT,
             @CustSeq        INT,
             @BadBegDate     NCHAR(8),
             @BadEndDate     NCHAR(8)
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @BillNo         = ISNULL(BillNo, ''),
             @BadDeptSeq     = ISNULL(BadDeptSeq, 0),
             @BadEmpSeq      = ISNULL(BadEmpSeq, 0),
             @CustSeq        = ISNULL(CustSeq, 0),
             @BadBegDate     = ISNULL(BadBegDate, ''),
             @BadEndDate     = ISNULL(BadEndDate, '')
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
       WITH ( 
             BillNo         NVARCHAR(50),
             BadDeptSeq     INT,
             BadEmpSeq      INT,
             CustSeq        INT,
             BadBegDate     NCHAR(8),
             BadEndDate     NCHAR(8)     
           )      
      SELECT
         A.*,
         (A.BadAmt - A.ReceiptAmt) AS NoReceiptAmt       -- 미회수금액
     FROM 
     (
         SELECT  A.BillSeq       AS BillSeq,      -- 세금계산서코드
                 B.BillNo        AS BillNo,       -- 세금계산서번호
                 B.BillDate      AS BillDate,     -- 세금계산서일자
                 A.BadDate       AS BadDate,      -- 부실채권발생일
                 A.RegEmpSeq     AS RegEmpSeq,    -- 작업자코드
                 A.BadDeptSeq    AS BadDeptSeq,   -- 부실채권관리부서코드
                 A.BadEmpSeq     AS BadEmpSeq,    -- 부실채권관리담당자코드   
                 A.Note          AS Note,         -- 발생사유
                 B.CustSeq       AS CustSeq,      -- 청구처
                 ISNULL(A.BadAmt, 0)        AS BadAmt,       -- 발생금액
                 (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.BadDeptSeq) AS BadDeptName,  -- 부실채권관리담당자
                 (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.RegEmpSeq) AS RegEmpName,       -- 작업자
                 (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.BadEmpSeq) AS BadEmpName,       -- 부실채권관리담당자
                 (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = B.CustSeq) AS CustName,        -- 청구처
                 ISNULL((SELECT SUM(ReceiptAmt) FROM DTI_TSLBillBadReceipt WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS ReceiptAmt   -- 회수금액
           FROM DTI_TSLBillBad AS A WITH (NOLOCK)    
             INNER JOIN _TSLBill AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq
          WHERE A.CompanySeq = @CompanySeq  
            AND (@BillNo = '' OR B.BillNo like '%' + @BillNo + '%')    
            AND (@BadDeptSeq = 0 OR A.BadDeptSeq = @BadDeptSeq)
            AND (@BadEmpSeq = 0 OR A.BadEmpSeq = @BadEmpSeq)
            AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)
            AND (@BadBegDate = '' OR A.BadDate >= @BadBegDate)
            AND (@BadEndDate = '' OR A.BadDate <= @BadEndDate)
     ) AS A
  
 RETURN