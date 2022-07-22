IF OBJECT_ID('hencom_SSLCustSalesChgEmpMonthStdQuery ') IS NOT NULL 
    DROP PROC hencom_SSLCustSalesChgEmpMonthStdQuery 
GO 

-- v2017.06.29 

/************************************************************  
    Ver.20140925
 설  명 - 월기준거래처영업담당자변경 : 조회  
 작성일 - 20100303  
 작성자 - 최영규  
************************************************************/  
CREATE PROC dbo.hencom_SSLCustSalesChgEmpMonthStdQuery 
    @xmlDocument    NVARCHAR(MAX) ,              
    @xmlFlags       INT  = 0,              
    @ServiceSeq     INT  = 0,              
    @WorkingTag     NVARCHAR(10)= '',                    
    @CompanySeq     INT  = 1,              
    @LanguageSeq    INT  = 1,              
    @UserSeq        INT  = 0,              
    @PgmSeq         INT  = 0           
      
AS          
   
	DECLARE @docHandle		INT,  
            @DateFr         NCHAR(8), 
            @DateTo         NCHAR(8), 
			@SalesBizSeq	INT,			--영업업무
			@SalesBiz        NVARCHAR(50),
            @BizUnit        INT, 
            @CustSeq        INT, 
            @QDeptSeq       INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @DateFr	    = ISNULL(DateFr,''),  
           @DateTo	    = ISNULL(DateTo,''),  
           @SalesBizSeq	= ISNULL(SalesBizSeq,0),
           @SalesBiz    = ISNULL(SalesBiz,''),
           @BizUnit     = ISNULL(BizUnit,0    ),  
           @CustSeq     = ISNULL(CustSeq,0    ), 
           @QDeptSeq    = ISNULL(QDeptSeq,0 )
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            DateFr         NCHAR(8), 
            DateTo         NCHAR(8), 
            SalesBizSeq		INT,
            SalesBiz        NVARCHAR(50),
            BizUnit         INT, 
            CustSeq         INT, 
            QDeptSeq        INT
           )
    
    IF ISNULL(@SalesBizSeq,0) = 0 -- 법인seq값이 1이 아닌경우 코드도움 코드값을 가져오지 못하는 오류를 위해 보완한 부분 
    BEGIN
        SELECT TOP 1 @SalesBizSeq = MinorSeq FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8062 AND MinorName = @SalesBiz
    END
    
    /*
	IF @SalesBizSeq = 8062001	-- 수주
	BEGIN     
		SELECT DISTINCT		   
			   A.OrderNo AS StdNo,																										--번호
			   A.OrderDate AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLOrderItem												--금액
						WHERE CompanySeq = @CompanySeq AND OrderSeq = A.OrderSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
			   A.OrderSeq AS StdSeq,																									--내부번호
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName,	--현영업담당자
			   (SELECT EmpId FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,		--현영업담당사번
			   (SELECT DeptName From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--현담당부서
			   (SELECT EmpSeq FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq,	--현영업담당자순번
			   (SELECT DeptSeq From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq,	--현담당부서순번
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLOrder AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.OrderDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.OrderDate LIKE @StdMonth + '%'
		   AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)
			OR A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.OrderSeq
	END
	
	IF @SalesBizSeq = 8062002	-- 출하의뢰
	BEGIN     
		SELECT DISTINCT		   
			   A.DVReqNo AS StdNo,																										--번호
			   A.DVReqDate AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLDVReqItem												--금액
						WHERE CompanySeq = @CompanySeq AND DVReqSeq = A.DVReqSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
			   A.DVReqSeq AS StdSeq,																									--내부번호
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName,	--현영업담당자
			   (SELECT EmpId FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,		--현영업담당사번
			   (SELECT DeptName From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--현담당부서
			   (SELECT EmpSeq FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq,	--현영업담당자순번
			   (SELECT DeptSeq From _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq,	--현담당부서순번
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLDVReq AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.DVReqDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.DVReqDate LIKE @StdMonth + '%'
		   AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)
			OR A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.DVReqSeq
	END	
	*/
	IF @SalesBizSeq = 8062003	--거래명세서
	BEGIN     
		SELECT DISTINCT		   
			   A.InvoiceNo AS StdNo,																									--번호
			   A.InvoiceDate AS StdDate,																								--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLInvoiceItem											--금액
						WHERE CompanySeq = @CompanySeq AND InvoiceSeq = A.InvoiceSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
               A.DeptSeq, 
			   A.InvoiceSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLInvoice AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.InvoiceDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND (A.InvoiceDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.InvoiceSeq
	END
	
	IF @SalesBizSeq = 8062004	--매출
	BEGIN     
		SELECT DISTINCT		   
			   A.SalesNo	AS StdNo,																										--번호
			   A.SalesDate	AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLSalesItem												--금액
						WHERE CompanySeq = @CompanySeq AND SalesSeq = A.SalesSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
               A.DeptSeq, 
			   A.SalesSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLSales AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.SalesDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
		   AND (A.SalesDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq ) 
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.SalesSeq
	END
	
	IF @SalesBizSeq = 8062005	--세금계산서
	BEGIN     
		SELECT DISTINCT		   
			   A.BillNo		AS StdNo,																										--번호
			   A.BillDate	AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLBillItem												--금액
						WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
               A.DeptSeq, 
			   A.BillSeq AS StdSeq,																										--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLBill AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.BillDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
           AND (A.BillDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.BillSeq
	END
	
	IF @SalesBizSeq = 8062006	--입금
	BEGIN     
		SELECT DISTINCT		   
			   A.ReceiptNo		AS StdNo,																									--번호
			   A.ReceiptDate	AS StdDate,																								--일자
			  A.CustSeq			AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   ISNULL((	SELECT sum(ISNULL(DomAmt,0)) FROM _TSLReceiptDESC WITH(NOLOCK)																--금액
						WHERE CompanySeq = @CompanySeq AND ReceiptSeq = A.ReceiptSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
               A.DeptSeq, 
			   A.ReceiptSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																			--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
		  FROM _TSLReceipt AS A
			LEFT OUTER JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
												 AND A.CustSeq = B.CustSeq								 					  
			LEFT OUTER JOIN _TSLCustSalesEmpHist AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
													 AND A.CustSeq = C.CustSeq
													 AND (A.ReceiptDate BETWEEN C.SDate AND C.Edate)			
		 WHERE A.CompanySeq = @CompanySeq
           AND (A.ReceiptDate BETWEEN @DateFr AND @DateTo)
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)
           AND (@QDeptSeq = 0 OR A.DeptSeq = @QDeptSeq)
            
		 ORDER BY A.ReceiptSeq
	END

    /*

    IF @SalesBizSeq = 8062007   -- 수출BL
    BEGIN
        SELECT DISTINCT
               @SalesBizSeq AS SalesBizSeq,
               A.BLRefNo	AS StdNo,
               A.BLSeq		AS StdSeq,
               A.BLDate		AS StdDate,
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
               (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,--거래처
               (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,--거래처번호
               ISNULL(( SELECT SUM(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLExpBLItem WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BLSeq = A.BLSeq), 0) AS StdAmt,
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
               (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,--영업담당자
               (SELECT EmpID FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,--영업담당사번
               (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,--담당부서
               (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpName, --현영업담당자
               (SELECT EmpId FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpNo,--현영업담당사번  
               (SELECT DeptName From _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptName,--현담당부서
               (SELECT EmpSeq FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EmpSeq = ISNULL(C.EmpSeq, B.EmpSeq)) AS NowSalesEmpSeq, --현영업담당자순번
               (SELECT DeptSeq From _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = ISNULL(C.DeptSeq, B.DeptSeq)) AS NowDeptSeq, --현담당부서순번
               A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName	--사업부문이름 2015.02.09 김소록 추가
          FROM _TSLExpBL AS A WITH(NOLOCK)
               LEFT OUTER JOIN _TSLCustSalesEmp AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq                  
               LEFT OUTER JOIN _TSLCustSalesEmpHist AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq AND (A.BLDate BETWEEN C.SDate AND C.Edate)     
         WHERE A.CompanySeq = @CompanySeq  
           AND A.BLDate LIKE @StdMonth + '%'  
           AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)  
            OR  A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
      ORDER BY A.BLSeq  
    END --::IF @SalesBizSeq = 8062007   -- 수출BL
	IF @SalesBizSeq = 8062008   -- 판매목표 2015.02.06 김소록 추가
    BEGIN
       SELECT @SalesBizSeq						AS SalesBizSeq,
               ''								AS StdNo,
               A.PlanYM							AS StdSeq,				-- 계획년월을 내부번호로 지정
               A.PlanYM							AS StdDate,
			   A.CustSeq						AS CustSeq,				--거래처코드
               D.CustName						AS CustName,			--거래처
               D.CustNo							AS CustNo,				--거래처번호
               SUM(ISNULL(A.PlanAmt,0))			AS StdAmt,
			   A.EmpSeq							AS EmpSeq,				--담당자코드	
               E.EmpName						AS EmpName,				--영업담당자
               E.EmpID							AS EmpNo,				--영업담당사번
               F.DeptName						AS DeptName,			--담당부서
			   ISNULL(E2.EmpName, E1.EmpName)	AS NowSalesEmpName,		--현영업담당자
			   ISNULL(E2.EmpId, E1.EmpId)		AS NowSalesEmpNo,		--현영업담당사번  
			   ISNULL(F2.DeptName, F1.DeptName) AS NowDeptName,			--현담당부서
			   ISNULL(E2.EmpSeq, E1.EmpSeq)		AS NowSalesEmpSeq,		--현영업담당자순번
			   ISNULL(F2.DeptSeq, F1.DeptSeq)	AS NowDeptSeq,			--현담당부서순번
			   A.BizUnit						AS BizUnit,				--사업부문
			   G.BizUnitName					AS BizUnitName			--사업부문
          FROM _TSLPlanMonthSales						AS A WITH(NOLOCK)
               LEFT OUTER JOIN _TSLCustSalesEmp			AS B WITH(NOLOCK)  ON A.CompanySeq	= B.CompanySeq 
																		  AND A.CustSeq		= B.CustSeq                  
               LEFT OUTER JOIN _TSLCustSalesEmpHist		AS C WITH(NOLOCK)  ON A.CompanySeq	= C.CompanySeq 
																		  AND A.CustSeq		= C.CustSeq 
																		  AND A.PlanYM		= LEFT(C.Edate,6)
			   LEFT OUTER JOIN _TDACust					AS D WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.CustSeq		= D.CustSeq
			   LEFT OUTER JOIN _TDAEmp					AS E WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.EmpSeq		= E.EmpSeq
			   LEFT OUTER JOIN _TDAEmp					AS E1 WITH(NOLOCK) ON B.CompanySeq	= E1.CompanySeq 
																		  AND B.EmpSeq		= E1.EmpSeq	
			   LEFT OUTER JOIN _TDAEmp					AS E2 WITH(NOLOCK) ON C.CompanySeq	= E2.CompanySeq 
																		  AND C.EmpSeq		= E2.EmpSeq	
			   LEFT OUTER JOIN _TDADept					AS F WITH(NOLOCK)  ON A.CompanySeq	= D.CompanySeq  
																		  AND A.DeptSeq		= F.DeptSeq		
			   LEFT OUTER JOIN _TDADept					AS F1 WITH(NOLOCK) ON B.CompanySeq	= F1.CompanySeq 
																		  AND B.DeptSeq		= F1.DeptSeq	
			   LEFT OUTER JOIN _TDADept					AS F2 WITH(NOLOCK) ON C.CompanySeq	= F2.CompanySeq 
																		  AND C.DeptSeq		= F2.DeptSeq
			   LEFT OUTER JOIN _TDABizUnit				AS G WITH(NOLOCK) ON  A.CompanySeq	= G.CompanySeq
																		  AND A.BizUnit		= G.BizUnit													   
										  	
         WHERE A.CompanySeq = @CompanySeq  
           AND A.PlanYM LIKE @StdMonth + '%'   
           AND (A.DeptSeq <> ISNULL(C.DeptSeq, B.DeptSeq)  
            OR  A.EmpSeq <> ISNULL(C.EmpSeq, B.EmpSeq))
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
	  GROUP BY A.BizUnit,	A.DeptSeq,	A.EmpSeq,	 A.PlanYM,		D.CustName,		D.CustNo ,
			   E.EmpName,	E.EmpID ,	F.DeptName,	 E2.EmpName,	E1.EmpName,		E2.EmpId, E1.EmpId,
			   E2.EmpSeq,	E1.EmpSeq,	F2.DeptSeq,	 F1.DeptSeq,	F2.DeptName,	F1.DeptName,
			   A.CustSeq,	A.BizUnit,	G.BizUnitName
      ORDER BY A.PlanYM   
    END --::IF @SalesBizSeq = 8062008   -- 판매목표
    
    */

RETURN
