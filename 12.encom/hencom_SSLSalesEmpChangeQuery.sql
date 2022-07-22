IF OBJECT_ID('hencom_SSLSalesEmpChangeQuery') IS NOT NULL 
    DROP PROC hencom_SSLSalesEmpChangeQuery
GO 

-- v2017.04.17 

/************************************************************  
    Ver.20140925
 설  명 - 월기준거래처영업담당자변경 : 조회  
 작성일 - 20100303  
 작성자 - 최영규  
************************************************************/  
CREATE PROC dbo.hencom_SSLSalesEmpChangeQuery
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
            @StdMonthFr     NCHAR(6),	--기준월
            @StdMonthTo     NCHAR(6),	--기준월
			@SalesBizSeq	INT,			--영업업무
			@SalesBiz        NVARCHAR(50),
            @DeptSeq        INT, 
            @BizUnit        INT, 
            @EmpSeq         INT,
			@CustSeq        int
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @StdMonthFr  = ISNULL(StdMonthFr,''),  
           @StdMonthTo  = ISNULL(StdMonthTo,''),  
           @SalesBizSeq	= ISNULL(SalesBizSeq,0),
           @SalesBiz    = ISNULL(SalesBiz,''),
           @DeptSeq     = ISNULL(DeptSeq,0    ),  --담당부서조회 조건 추가 20150128 황지혜 
           @BizUnit     = ISNULL(BizUnit,0    ),  --사업부문 조회 조건 추가 20150128 황지혜
           @EmpSeq      = ISNULL(EmpSeq ,0    ),   --영업담당자 조회 조건 추가 20150128 황지혜
           @CustSeq     = ISNULL(CustSeq ,0    )   --영업담당자 조회 조건 추가 20150128 황지혜
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (StdMonthFr      NCHAR(6),  
            StdMonthTo      NCHAR(6),   
            SalesBizSeq		INT,
            SalesBiz        NVARCHAR(50),
            DeptSeq         INT,
            BizUnit         INT,
            EmpSeq          INT,
			CustSeq         int)
    
    IF ISNULL(@SalesBizSeq,0) = 0 -- 법인seq값이 1이 아닌경우 코드도움 코드값을 가져오지 못하는 오류를 위해 보완한 부분 
    BEGIN
        SELECT TOP 1 @SalesBizSeq = MinorSeq FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8062 AND MinorName = @SalesBiz
    END
    
	
	IF @SalesBizSeq = 8062003	--거래명세서
	BEGIN     
		SELECT A.InvoiceNo AS StdNo,																									--번호
			   A.InvoiceDate AS StdDate,																								--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptNameOri,						--담당부서
			   A.InvoiceSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--사업부문이름 2015.02.09 김소록 추가

			   i.CurAmt + i.CurVAT AS StdAmt,		   
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.ItemSeq,
			   ( select ItemNo  from _TDAItem where CompanySeq = a.CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.invoiceserl   AS StdSerl
			   
		  FROM _TSLInvoice AS A
		    join _TSLInvoiceItem as i on i.CompanySeq = a.CompanySeq
			                       and i.InvoiceSeq = a.InvoiceSeq
 left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
               and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.InvoiceDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.InvoiceSeq, i.InvoiceSerl
	END
	
	IF @SalesBizSeq = 8062004	--매출
	BEGIN     
		SELECT DISTINCT		   
			   A.SalesNo	AS StdNo,																										--번호
			   A.SalesDate	AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
			   A.SalesSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--사업부문이름 2015.02.09 김소록 추가
			   i.CurAmt + i.CurVAT AS StdAmt,		   
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.ItemSeq,
			   ( select ItemNo  from _TDAItem where CompanySeq = a.CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.salesserl   AS StdSerl

		  FROM _TSLSales AS A
		  join _TSLSalesitem as i on i.CompanySeq = a.CompanySeq
			                     and i.salesseq = a.salesseq
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.SalesDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.SalesSeq
	END
	
	IF @SalesBizSeq = 8062005	--세금계산서   청구는 따로 프로젝트를 가지고 있지 않으므로 매출에 현장을 수정하던가 대체의 현장을 수정해야 한다
	BEGIN     


		SELECT A.BillSeq,
		       A.BillNo		AS StdNo,																										--번호
			   A.BillDate	AS StdDate,																									--일자
			   A.CustSeq	AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   --ISNULL((	SELECT sum(ISNULL(DomAmt,0) + ISNULL(DomVAT,0)) FROM _TSLBillItem												--금액
						--WHERE CompanySeq = @CompanySeq AND BillSeq = A.BillSeq), 0) AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptNameOri,						--담당부서
			   A.BillSeq AS StdSeq,																										--내부번호
			   @SalesBizSeq AS SalesBizSeq,																								--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--사업부문이름 2015.02.09 김소록 추가
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId
          into #result
		  FROM _TSLBill AS A
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.BillDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.BillSeq
		 select a.StdNo,
				a.StdDate,
				a.CustSeq,
				a.CustName,
				a.CustNo,
				a.EmpSeq,
				a.EmpName,
				a.EmpNo,
				a.DeptNameOri,
				a.StdSeq,
				a.SalesBizSeq,
				a.BizUnit,
				a.BizUnitName,
				i.CurAmt + i.CurVAT  as StdAmt,
				i.PJTSeq,
				(select PJTName  from _TPJTProject where companyseq = @CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
				ItemSeq,
				( select ItemNo  from _TDAItem where CompanySeq = @CompanySeq and ItemSeq = i.ItemSeq ) as ItemName,
				a.BizNo,
				a.PersonId,
				(select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) as PJTEmpSeq,
				(select  empname from _TDAEmp where companyseq = @CompanySeq and EmpSeq = (select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) ) as PJTEmpName
		   from #result as a
left outer join (		       
			  select si.billseq,si.PJTBillSerl, si.PJTSeq, si.ItemSeq, si.CurAmt, si.CurVAT
			   FROM _TSLBill AS m WITH(NOLOCK)
	           JOIN _TPJTSLBillItem          AS si WITH(NOLOCK)  ON si.CompanySeq = m.CompanySeq
														   		AND si.BillSeq   = m.BillSeq
               join #result as a on a.BillSeq = m.BillSeq 
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (1) 
				union all
             select m.billseq, si.SalesSerl, si.PJTSeq, si.ItemSeq, si.CurAmt, si.CurVAT
			   FROM _TSLBill AS m WITH(NOLOCK)
               join #result as a on a.BillSeq = m.BillSeq 
	           JOIN _TSLSalesBillRelation  AS br WITH(NOLOCK)  ON br.CompanySeq  = m.CompanySeq
															  AND br.BillSeq     = m.BillSeq
			   join (  select companyseq, SalesSeq, billseq
					     from _TSLSalesBillRelation
					    where companyseq = @CompanySeq
					   except
					   select companyseq, salesseq, billseq 
					     from hencom_VSLInvReplace
					    where companyseq = @CompanySeq) as nr on nr.CompanySeq = m.CompanySeq
					                                         and nr.SalesSeq = br.SalesSeq
															 and nr.BillSeq = br.BillSeq
				JOIN _TSLSalesItem          AS si WITH(NOLOCK)  ON si.CompanySeq = br.CompanySeq
														   				  AND si.SalesSeq   = br.SalesSeq
																		  AND si.SalesSerl  = br.SalesSerl
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (2,3)  
			union all
             select m.billseq, i.ReplaceRegSerl, i.PJTSeq, i.ItemSeq, i.CurAmt, i.CurVAT
	           FROM _TSLBill AS  m WITH(NOLOCK)
               join #result as a on a.BillSeq = m.BillSeq 
			   join hemcom_TSLBillReplaceRelation as r on r.CompanySeq = m.CompanySeq
													  and r.BillSeq = m.BillSeq
			   join hencom_TSLInvoiceReplaceItem as i on i.CompanySeq = m.CompanySeq
													 and i.ReplaceRegSeq = r.ReplaceRegSeq
													 and i.ReplaceRegSerl = r.ReplaceRegSerl
              where m.CompanySeq = @CompanySeq
			    and m.BillID     in (2,3)  
				) as i on i.billseq = a.billseq
 

	END
	
	IF @SalesBizSeq = 8062006	--입금
	BEGIN     
		SELECT DISTINCT		   
			   A.ReceiptNo		AS StdNo,																									--번호
			   A.ReceiptDate	AS StdDate,																								--일자
			  A.CustSeq			AS CustSeq,	--거래처코드 2015.02.09 김소록 추가
			   (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName,						--거래처
			   (SELECT CustNo FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustNo,							--거래처번호
			   i.curamt * i.SMDrOrCr AS StdAmt,		   
			   A.EmpSeq	  AS EmpSeq,				--담당자코드 2015.02.09 김소록 추가
			   (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,							--영업담당자
			   (SELECT EmpID FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpNo,								--영업담당사번
			   (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,						--담당부서
			   A.ReceiptSeq AS StdSeq,																									--내부번호
			   @SalesBizSeq AS SalesBizSeq,																			--영업업무코드
			   A.BizUnit AS BizUnit,	--사업부문 2015.02.09 김소록 추가
			   (SELECT BizUnitName From _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,	--사업부문이름 2015.02.09 김소록 추가
			   i.PJTSeq,
			   (select PJTName  from _TPJTProject where companyseq = a.CompanySeq and pjtseq = i.PJTSeq ) as PJTName,
			   i.UMReceiptKind as ItemSeq,
			   ( select minorname  from _TDAuminor where CompanySeq = a.CompanySeq and MinorSeq = i.UMReceiptKind ) as ItemName,
			   case isnull(c.bizno,'') when '' then '' else  substring(c.BizNo,1,3) + '-' + substring(c.BizNo,4,2) + '-' + substring(c.BizNo,6,5) end as BizNo,
		       ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(c.PersonId, '_TDACust', 'PersonId', @CompanySeq)),'') AS PersonId,
			   i.ReceiptSerl   AS StdSerl,
				(select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) as PJTEmpSeq,
				(select  empname from _TDAEmp where companyseq = @CompanySeq and EmpSeq = (select ChargeEmpSeq from _TPJTProject where companyseq = @CompanySeq and PJTSeq = i.PJTSeq ) ) as PJTEmpName
			
		  FROM _TSLReceipt AS A
		  join _TSLReceiptDesc as i on i.companyseq = a.companyseq
		                           and    i.receiptseq = a.receiptseq
left outer join _TDACust as c on c.CompanySeq = a.CompanySeq
                              and c.CustSeq = a.CustSeq
		 WHERE A.CompanySeq = @CompanySeq
		   AND LEFT(A.ReceiptDate,6) BETWEEN @StdMonthFr AND @StdMonthTo 
           AND (@BizUnit = 0 OR A.BizUnit = @BizUnit  )    --사업부문 조회 조건 추가 20150128 황지혜
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq  )    --담당부서조회 조건 추가 20150128 황지혜
           AND (@EmpSeq  = 0 OR A.EmpSeq  = @EmpSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
           AND (@CustSeq  = 0 OR A.CustSeq  = @CustSeq   )    --영업담당자 조회 조건 추가 20150128 황지혜
            
		 ORDER BY A.ReceiptSeq
	END

RETURN
