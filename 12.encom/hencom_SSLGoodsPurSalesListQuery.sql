IF OBJECT_ID('hencom_SSLGoodsPurSalesListQuery') IS NOT NULL 
    DROP PROC hencom_SSLGoodsPurSalesListQuery
GO 

-- v2017.06.23 

/************************************************************
 설  명 - 데이터-매입매출현황_hencom : 조회
 작성일 - 20160819
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SSLGoodsPurSalesListQuery 
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @docHandle  INT,
		    @DateTo     NCHAR(8) ,
            @DateFr     NCHAR(8) ,
            @AssetSeq   INT ,
            @DeptSeq    INT ,
            @CustSeq    INT 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

	SELECT  @DateTo      = DateTo       ,
            @DateFr      = DateFr       ,
            @AssetSeq    = AssetSeq     ,
            @DeptSeq     = DeptSeq      ,
            @CustSeq     = CustSeq      
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (DateTo       NCHAR(8) ,
            DateFr       NCHAR(8) ,
            AssetSeq     INT ,
            DeptSeq      INT ,
            CustSeq      INT )
	
	
	          select a.DeptSeq as PurDeptSeq,
			         a.DelvDate as PurDate,
			         b.DelvCustSeq as PurCustSeq,
                     replace(c.BizNo,'-','') as PurBizNo, 
					 b.ItemSeq as PurItemSeq,
					 b.Qty as PurQty,
					 b.Price as PurPrice,
                     b.CurAmt AS PurAmt, 
                     b.CurVAT AS PurVAT,
					 b.CurAmt + b.CurVAT as PurTotAmt,
					 a.CustSeq as MstCustSeq
			    into #delv		  
				FROM _TPUDelv AS A WITH(NOLOCK)     
                JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
                                                    AND A.DelvSeq = B.DelvSeq      
     left outer join _tdaitem as i on i.CompanySeq = a.CompanySeq
	                              and i.ItemSeq = b.ItemSeq 
     left outer join _tdacust as c on ( c.companyseq = @companyseq and c.custseq = a.custseq ) 
               where a.CompanySeq = @CompanySeq
			     and a.DelvDate between @DateFr and @DateTo
			     and (@DeptSeq = 0 or a.DeptSeq = @DeptSeq)
				 and (@CustSeq = 0 or b.DelvCustSeq = @CustSeq)
				 and i.AssetSeq = @AssetSeq
            
               select a.DeptSeq as SalDeptSeq,
			          a.InvoiceDate as SalDate,
			          a.CustSeq as SalCustSeq,
                      replace(c.BizNo,'-','') as SalBizNo, 
					  b.ItemSeq as SalItemSeq,
					  b.qty as SalQty,
					  CASE WHEN B.Price IS NOT NULL THEN B.Price                  
						   ELSE (CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0                  
									  ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)                          
									  ELSE ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0) END) END) END  as SalPrice,  
                     b.CurAmt AS SalAmt, 
                     b.CurVAT AS SalVAT,
                     b.CurAmt + b.CurVAT as SalTotAmt
                into #Sale
			    FROM _TSLInvoice AS A WITH(NOLOCK)                      
                JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq                   
     left outer join _tdaitem as i on i.CompanySeq = a.CompanySeq
	                              and i.ItemSeq = b.ItemSeq
     left outer join _tdacust as c on ( c.companyseq = @companyseq and c.custseq = a.custseq ) 
               where a.CompanySeq = @CompanySeq
			     and a.InvoiceDate between @DateFr and @DateTo
			     and (@DeptSeq = 0 or a.DeptSeq = @DeptSeq)
				 and (@CustSeq = 0 or a.CustSeq = @CustSeq)
				 and i.AssetSeq = @AssetSeq
            
			  --select * from #delv order by PurDate
			  --select * from #Sale order by SalDate
            
			  select DISTINCT PurDeptSeq,
			         (select deptname from _TDADept where CompanySeq = @CompanySeq and deptseq = PurDeptSeq) as PurDeptName,
					 PurDate,
					 PurCustSeq,
					 (select custname from _TDACust where CompanySeq = @CompanySeq and custseq = PurCustSeq) as PurCustName,
                     PurBizNo, 
					 PurItemSeq,
					 (select itemname from _TDAItem where CompanySeq = @CompanySeq and ItemSeq = PurItemSeq) as PurItemName,
					 PurQty,
					 PurPrice,
					 PurAmt,
                     PurVAT, 
                     PurTotAmt, 
					 SalDeptSeq,
			         (select deptname from _TDADept where CompanySeq = @CompanySeq and deptseq = SalDeptSeq) as SalDeptName,
					 SalDate,
					 SalCustSeq,
					 (select custname from _TDACust where CompanySeq = @CompanySeq and custseq = SalCustSeq) as SalCustName, 
                     SalBizNo, 
					 SalItemSeq,
					 (select itemname from _TDAItem where CompanySeq = @CompanySeq and ItemSeq = SalItemSeq) as SalItemName,
					 SalQty,
					 SalPrice,
					 SalAmt, 
                     SalVAT, 
                     SalTotAmt
			    from (
			  select a.PurDeptSeq,
					 a.PurDate,
					 a.MstCustSeq as PurCustSeq,
                     a.PurBizNo, 
					 a.PurItemSeq,
					 a.PurQty,
					 a.PurPrice,
					 a.PurAmt,
                     a.PurVAT, 
                     a.PurTotAmt, 
					 b.SalDeptSeq,
					 b.SalDate,
					 b.SalCustSeq, 
                     b.SalBizNo, 
					 b.SalItemSeq,
					 b.SalQty,
					 b.SalPrice,
					 b.SalAmt, 
                     b.SalVAT, 
                     b.SalTotAmt
			    from #delv as a 
	            join #Sale as b on b.SalDate = a.PurDate
				               and b.SalDeptSeq = a.PurDeptSeq
							   and b.SalItemSeq = a.PurItemSeq
							   and b.SalQty = a.PurQty
							   and b.SalCustSeq = a.PurCustSeq

                union all

			  select a.PurDeptSeq,
					 a.PurDate,
					 a.MstCustSeq as PurCustSeq, 
                     a.PurBizNo, 
					 a.PurItemSeq,
					 a.PurQty,
					 a.PurPrice,
					 a.PurAmt,
                     a.PurVAT, 
                     a.PurTotAmt, 
					 0,
					 '',
					 0 ,
                     '', 
					 0 ,
					 0 ,
					 0 ,
					 0 , 
                     0 , 
                     0
			    from #delv as a 
                join (
					  select PurDeptSeq, PurDate, PurItemSeq, PurQty, PurCustSeq   from #delv
					  except
					  select SalDeptSeq, SalDate, SalItemSeq, SalQty, SalCustSeq   from #Sale						
					 ) as od on od.PurCustSeq = a.PurCustSeq
					        and od.PurDate = a.PurDate
							and od.PurDeptSeq = a.PurDeptSeq
							and od.PurItemSeq = a.PurItemSeq
							and od.PurQty = a.PurQty
	 
                union all

			  select 0,
					 '',
					 0 ,
                     '', 
					 0 ,
					 0 ,
					 0 ,
					 0 ,
                     0 , 
                     0 , 
					 a.SalDeptSeq,
					 a.SalDate,
					 a.SalCustSeq, 
                     a.SalBizNo, 
					 a.SalItemSeq,
					 a.SalQty,
					 a.SalPrice,
					 a.SalAmt, 
                     a.SalVAT, 
                     a.SalTotAmt 
			    from #Sale as a 
                join (
					  select SalDeptSeq, SalDate, SalItemSeq, SalQty, SalCustSeq   from #Sale
					  except
					  select PurDeptSeq, PurDate, PurItemSeq, PurQty, PurCustSeq   from #delv					
					 ) as od on od.SalCustSeq = a.SalCustSeq
					        and od.SalDate = a.SalDate
							and od.SalDeptSeq = a.SalDeptSeq
							and od.SalItemSeq = a.SalItemSeq
							and od.SalQty = a.SalQty
				     ) as a 



RETURN

go
begin tran 
exec hencom_SSLGoodsPurSalesListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CustSeq />
    <DeptSeq>50</DeptSeq>
    <DateFr>20170601</DateFr>
    <DateTo>20170626</DateTo>
    <AssetSeq>1</AssetSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1038336,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031291
rollback 