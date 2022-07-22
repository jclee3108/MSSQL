drop proc hencom_SSLReceiptBillDeptData
go

create proc hencom_SSLReceiptBillDeptData
    @companyseq int = 1 
as 


select C.ReceiptNo, d.BillNo, C.BizUnit AS ReceiptBizUnit, D.BizUnit AS BillBizUnit, 
       C.CustSeq AS ReceiptCustSeq, D.CustSeq AS BillCustSeq, C.DeptSeq AS ReceiptDeptSeq, D.DeptSeq AS BillDeptSeq, '선수금' AS TypeName
  into #result
  from _TSLPreReceiptItem   as a 
  join _TSLPreReceipt       as f on ( f.companyseq = @companyseq and f.preoffseq = a.preoffseq ) 
  join _TSLReceipt          as C on ( C.companyseq = @companyseq and C.ReceiptSeq = a.ReceiptSeq ) 
  JOIN _TSLPreReceiptBill   as b on ( b.companyseq = @companyseq and b.preoffseq = a.preoffseq )
  join _TSLBill             as d on ( d.companyseq = @companyseq and d.billseq = b.billseq ) 
 where a.companyseq = @companyseq
   and c.deptseq <> d.deptseq 

 union all 

select  A.ReceiptNo, C.BillNo, A.BizUnit AS ReceiptBizUnit, C.BizUnit AS BillBizUnit, 
        A.CustSeq AS ReceiptCustSeq, C.CustSeq AS BillCustSeq, A.DeptSeq AS ReceiptDeptSeq, C.DeptSeq AS BillDeptSeq, '일반' AS TypeName
  from _TSLReceipt AS A 
  JOIN _TSLReceiptBill as b on ( b.companyseq = @companyseq and b.receiptseq = a.ReceiptSeq ) 
  join _TSLBill         as c on ( c.companyseq = @companyseq and c.billseq = b.billseq ) 
  where a.companyseq = @companyseq 
     and a.isprereceipt = '0'
     and a.deptseq <> c.deptseq 
    

select B.BizUnitName AS '입금 사업부문', 
       C.BizUnitName AS '계산서 사업부문', 
       D.CustName AS '입금 거래처', 
       e.CustName AS '계산서 거래처', 
       f.deptname AS '입금 부서', 
       h.deptname as '계산서 부서', 
       a.ReceiptNo as '입금번호', 
       a.BillNo as '계산서번호', 
       a.TypeName as '선수금/일반'
  from #result as a 
  left outer join _TdaBizUnit as b on ( b.companyseq = @companyseq and b.bizunit = a.receiptbizunit ) 
  left outer join _TDABizunit as c on ( c.companyseq = @CompanySeq and c.bizunit = a.billBizUnit ) 
  left outer join _TDACust    as d on ( d.companyseq = @companyseq and d.custseq = a.receiptcustseq ) 
  left outer join _TDACust    as e on ( e.companyseq = @companyseq and e.custseq = a.billcustseq ) 
  left outer join _tdadept    as f on ( f.companyseq = @companyseq and f.deptseq = a.receiptdeptseq ) 
  left outer join _Tdadept    as h on ( h.companyseq = @companyseq and h.deptseq = a.billdeptseq ) 




return 
go
exec hencom_SSLReceiptBillDeptData 1 