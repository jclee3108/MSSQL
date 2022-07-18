IF OBJECT_ID('DTI_SSLBillBadListQuery') IS NOT NULL   
    DROP PROC DTI_SSLBillBadListQuery  
GO  
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
            @BadEndDate     NCHAR(8),  
            @BizUnit        INT,  
            @BizNo          NVARCHAR(100),  
            @CustSeqTemp    INT,  
            @FullName       NVARCHAR(100),  
            @BillDateFr     NVARCHAR(10),  
            @BillDateTo     NVARCHAR(10),  
            @DeptSeqTemp    INT,  
            @EmpSeqTemp     INT             
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    
    SELECT  @BillNo         = ISNULL(BillNo, ''),  
            @BadDeptSeq     = ISNULL(BadDeptSeq, 0),  
            @BadEmpSeq      = ISNULL(BadEmpSeq, 0),  
            @CustSeq        = ISNULL(CustSeq, 0),  
            @BadBegDate     = ISNULL(BadBegDate, ''),  
            @BadEndDate     = ISNULL(BadEndDate, ''),  
            @BizUnit        = ISNULL(BizUnit, 0),  
            @BizNo          = ISNULL(BizNo, ''),  
            @CustSeqTemp    = ISNULL(CustSeqTemp , 0),  
            @FullName       = ISNULL(FullName, ''),  
            @BillDateFr     = ISNULL(BillDateFr, ''),  
            @BillDateTo     = ISNULL(BillDateTo, ''),  
            @DeptSeqTemp    = ISNULL(DeptSeqTemp, 0),  
            @EmpSeqTemp     = ISNULL(EmpSeqTemp, 0)  
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
      WITH (   
            BillNo         NVARCHAR(50),  
            BadDeptSeq     INT,  
            BadEmpSeq      INT,  
            CustSeq        INT,  
            BadBegDate     NCHAR(8),  
            BadEndDate     NCHAR(8),  
            BizUnit        INT,  
            BizNo          NVARCHAR(100),  
            CustSeqTemp    INT,  
            FullName       NVARCHAR(100),  
            BillDateFr     NVARCHAR(10),  
            BillDateTo     NVARCHAR(10),  
            DeptSeqTemp    INT,  
            EmpSeqTemp     INT             
            
           )        
    
    SELECT @BillDateTo = CASE WHEN ISNULL(@BillDateTo,'') = '' THEN '99991231' ELSE @BillDateTo END 
    
  SELECT  
        A.*,  
        (A.BadAmt - A.ReceiptAmt) AS NoReceiptAmt       -- 미회수금액  
    FROM   
    (  
        SELECT F.BizNo, -- 사업자번호(청구처) 
               D.DeptName      AS DeptNameTemp, -- 세금계산서 담당부서  
               E.EmpName       AS EmpNameTemp,  -- 세금계산서 담당자   
               A.BillSeq       AS BillSeq,      -- 세금계산서코드  
               B.BillNo        AS BillNo,       -- 세금계산서번호  
               B.BillDate      AS BillDate,     -- 세금계산서일자  
               A.BadDate       AS BadDate,      -- 부실채권발생일  
               A.RegEmpSeq     AS RegEmpSeq,    -- 작업자코드  
               A.BadDeptSeq    AS BadDeptSeq,   -- 부실채권관리부서코드  
               A.BadEmpSeq     AS BadEmpSeq,    -- 부실채권관리담당자코드     
               A.Note          AS Note,         -- 발생사유  
               B.CustSeq       AS CustSeq,      -- 청구처  
               ISNULL(A.BadAmt, 0) AS BadAmt,       -- 발생금액  
               (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.BadDeptSeq) AS BadDeptName,  -- 부실채권관리담당자  
               (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.RegEmpSeq) AS RegEmpName,       -- 작업자  
               (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.BadEmpSeq) AS BadEmpName,       -- 부실채권관리담당자  
               F.CustName, -- 청구처
               ISNULL((SELECT SUM(ReceiptAmt) FROM DTI_TSLBillBadReceipt WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS ReceiptAmt   -- 회수금액  
               
          FROM DTI_TSLBillBad           AS A WITH(NOLOCK)      
          JOIN _TSLBill                 AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BillSeq = A.BillSeq )  
          LEFT OUTER JOIN _TDABizUnit   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = B.BizUnit ) -- 사업부문  
          LEFT OUTER JOIN _TDADept      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq ) -- 세금계산서 담당부서  
          LEFT OUTER JOIN _TDAEmp       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = B.EmpSeq ) -- 세금계산서 담당자  
          LEFT OUTER JOIN _TDACust      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.CustSeq ) -- 청구처 
          
         WHERE A.CompanySeq = @CompanySeq    
           AND ( @BillNo = '' OR B.BillNo LIKE '%'+@BillNo+'%' )      
           AND ( @BadDeptSeq = 0 OR A.BadDeptSeq = @BadDeptSeq )  
           AND ( @BadEmpSeq = 0 OR A.BadEmpSeq = @BadEmpSeq )  
           AND ( @CustSeq = 0 OR B.CustSeq = @CustSeq )  
           AND ( @BadBegDate = '' OR A.BadDate >= @BadBegDate )  
           AND ( @BadEndDate = '' OR A.BadDate <= @BadEndDate )  
           AND B.BizUnit = @BizUnit 
           AND ( @BizNo = '' OR B.TaxUnit LIKE @BizNo+'%' ) 
           --AND ( @CustSeqTemp = 0 OR F.CustSeq = @CustSeqTemp) -- 거래처(미확정) 
           AND ( @FullName = '' OR F.FullName LIKE @FullName +'%' )  
           AND B.BillDate BETWEEN @BillDateFr AND @BillDateTo
           AND ( @DeptSeqTemp = 0 OR B.DeptSeq = @DeptSeqTemp )  
           AND ( @EmpSeqTemp = 0 OR B.EmpSeq = @EmpSeqTemp )  
        
    ) AS A  
    
    RETURN  
GO
