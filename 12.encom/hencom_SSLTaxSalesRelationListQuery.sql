IF OBJECT_ID('hencom_SSLTaxSalesRelationListQuery') IS NOT NULL 
    DROP PROC hencom_SSLTaxSalesRelationListQuery
GO 

-- v2017.04.25 

/************************************************************
 설  명 - 데이터-계산서청구내역조회_hencom : 조회
 작성일 - 20160415
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SSLTaxSalesRelationListQuery                
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

	DECLARE @docHandle      INT,
		    @BizUnit         INT ,
            @TaxDateTo       NVARCHAR(8) ,
            @DeptSeq         INT ,
            @TaxDateFr       NVARCHAR(8) ,
            @CustSeq         INT  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @BizUnit         = BizUnit          ,
            @TaxDateTo       = TaxDateTo        ,
            @DeptSeq         = DeptSeq          ,
            @TaxDateFr       = TaxDateFr        ,
            @CustSeq         = CustSeq          
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (BizUnit          INT ,
            TaxDateTo        NVARCHAR(8) ,
            DeptSeq          INT ,
            TaxDateFr        NVARCHAR(8) ,
            CustSeq          INT )
	
	SELECT  A.BillSeq         , 
			DeptSeq         , 
			DeptName        , 
			CustSeq         , 
			CustName        ,
			BizNo           , 
			BillDate        , 
            BillNo          , 
			curamt as BillAmt         , 
			curvat as BillVat         , 
			totcuramt as TotBillAmt      , 
			prereceiptcuramt +  ReceiptCurAmt as ReceiptAmt      , 
            acctreceivable as BalanceAmt      , 
            FundArrangeDate ,
			( select max(ReceiptDate) from _TSLReceipt where CompanySeq = a.companyseq 
			                                  and ReceiptSeq in (
			
			                  SELECT ReceiptSeq FROM _TSLReceiptBill WHERE CompanySeq = a.CompanySeq AND BillSeq = a.BillSeq  
							  union
							  select ReceiptSeq  from _TSLPreReceiptitem
							                where PreOffSeq in (SELECT PreOffSeq FROM _TSLPreReceiptBill WHERE CompanySeq = a.CompanySeq AND BillSeq = a.BillSeq)
							                                       ) ) as MaxInDate,
			( Select COUNT(DISTINCT k.PJTSeq) From hencom_VInvoiceReplaceItem as k Where k.CompanySeq = a.CompanySeq AND k.BillSeq = A.BillSeq) As PjtCount,
			a.Remark, 
            B.Qty, 
            CASE WHEN ISNULL(B.AttachDate,'') = '' THEN '0' ELSE '1' END AS IsAttachDate, 
            A.EmpSeq, 
            A.EmpName 
      FROM  hencom_VSLBill AS A 
      LEFT OUTER JOIN (
                        SELECT BillSeq, SUM(Qty) AS Qty, MAX(ISNULL(AttachDate,'')) AS AttachDate
                          FROM hencom_VInvoiceReplaceItem 
                         WHERE CompanySeq = @CompanySeq 
                         GROUP BY BillSeq 
                      ) AS B ON ( B.BillSeq = A.BillSeq ) 
	 WHERE  A.CompanySeq = @CompanySeq
       AND  A.BizUnit = @BizUnit
	   AND  A.BillDate between @TaxDateFr and @TaxDateTo
	   AND  (@DeptSeq = 0 or A.DeptSeq          = @DeptSeq )
	   AND  (@CustSeq = 0 or A.CustSeq          = @CustSeq )
RETURN
go
exec hencom_SSLTaxSalesRelationListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <TaxDateFr>20170101</TaxDateFr>
    <TaxDateTo>20170131</TaxDateTo>
    <DeptSeq>44</DeptSeq>
    <CustSeq>1191</CustSeq>
      </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036435,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029883

         
                         