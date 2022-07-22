


drop table #Main

SELECT A.SumMesKey, 
           A.WorkOrderSeq, 
           A.WorkReportSeq, 
           A.InvoiceSeq, 
           A.SalesSeq, 
           A.ProdQty, 
           A.CurAmt, 
           A.CurVAT, 
           CONVERT(INT,0) AS GoodInSeq         
      INTO #Main
      FROM hencom_TIFProdWorkReportCloseSum AS A WITH(NOLOCK)                                     
     WHERE A.CompanySeq = 1 
       AND A.WorkDate = '20151209' and a.deptseq = 42
       AND (   
               ISNULL(A.WorkOrderSeq,0) <> 0 
            OR ISNULL(A.WorkReportSeq,0) <> 0 
            OR ISNULL(A.InvoiceSeq,0) <> 0 
            OR ISNULL(A.SalesSeq,0) <> 0 
           )





select TOP 1 * from _TPDSFCWorkOrder where companyseq = 1 and workorderseq in ( select WorkOrderSeq from #Main ) 
select TOP 1 * from _TPDSFCWorkReport where companyseq = 1 and WorkReportSeq in ( select WorkReportSeq from #Main ) 
select TOP 1 * from _TPDSFCMatInPut where companyseq = 1 and  WorkReportSeq in ( select WorkReportSeq from #Main ) 
select TOP 1 * from _TPDSFCGoodIn where companyseq = 1 and WorkReportSeq in ( select WorkReportSeq from #Main ) 
select TOP 1 * from _TSLInvoice where companyseq = 1 and InvoiceSeq in ( select InvoiceSeq from #Main ) 
select TOP 1 * from _TSLInvoiceItem where companyseq = 1 and InvoiceSeq in ( select InvoiceSeq from #Main ) 
select TOP 1 * from _TSLSales where companyseq = 1 and SalesSeq in ( select SalesSeq from #Main ) 
select TOP 1 * from _TSLSalesItem where companyseq = 1 and SalesSeq in ( select SalesSeq from #Main ) 


select * From _TCOMSourceDaily where companyseq = 1 and fromtableseq = 5 and fromseq in ( select workorderseq from #main )
select * From _TCOMSourceDaily where companyseq = 1 and fromtableseq = 6 and fromseq in ( select WorkReportSeq from #main )
select * from _TCOMSourceDaily where companyseq = 1 and fromtableseq = 18 and fromseq in ( select invoiceseq from #main ) 

select * From _TLGInOutDaily where companyseq = 1 and inouttype = 130 and inoutseq in ( select WorkReportSeq from #main )
select * From _TLGInOutDailyItem where companyseq = 1 and inouttype = 130 and inoutseq in ( select WorkReportSeq from #main )
select * From _TLGInOutDaily where companyseq = 1 and inouttype = 140 and inoutseq in ( select GoodInSeq from _TPDSFCGoodIn where WorkReportSeq in ( select WorkReportSeq from #main) )
select * From _TLGInOutDailyItem where companyseq = 1 and inouttype = 140 and inoutseq in ( select GoodInSeq from _TPDSFCGoodIn where WorkReportSeq in ( select WorkReportSeq from #main) )
select * From _TLGInOutDaily where companyseq = 1 and inouttype = 10 and inoutseq in ( select InvoiceSEq from #main )
select * From _TLGInOutDailyItem where companyseq = 1 and inouttype = 10 and inoutseq in ( select InvoiceSEq from #main )


--select * From _TCOMProgTable 
--select * From _TDASMInor where majorseq = 8042 

