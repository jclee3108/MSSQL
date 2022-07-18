
IF OBJECT_ID('jongie_SSLInvoiceLisPrint')IS NOT NULL
DROP PROC jongie_SSLInvoiceLisPrint

GO 

-- v2013.09.16 

-- 거래명세서-청구서(출력물)_jongie by이재천

CREATE PROC jongie_SSLInvoiceLisPrint                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10) = '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS 
    
	CREATE TABLE #TSLInvoice (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoice'     
	IF @@ERROR <> 0 RETURN  
    
    SELECT TOP 1 BizItem, Addr1 + Addr2 AS Addr, TaxName, Owner, BizType, TaxNo
      INTO #TDATaxUnit
      FROM _TDATaxUnit 
     WHERE SMTaxationType = 4128001
    
	SELECT (SELECT BizItem FROM #TDATaxUnit) AS BizItem, 
	       D.ItemNo, 
	       STUFF(RIGHT(B.InvoiceDate,4),3,0,'-') AS InvoiceDate, 
	       D.ItemName, 
	       F.CustNo, 
           (SELECT Addr FROM #TDATaxUnit) AS Addr, 
           G.DVPlaceName AS DelvCustName, 
           E.EmpName, 
           --TotCutAmt, 
           DateTot, 
           C.Qty, 
           (
               SELECT (C.Qty) % (P.ConvNum) / (P.ConvDen)
                 FROM jongie_TCOMEnv AS O WITH(NOLOCK) 
                 JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = C.ItemSeq ) 
                WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1
           ) AS Rest, 
           --Total, 
           C.InvoiceSerl, 
           SUBSTRING(B.InvoiceDate,5,2) AS InvoiceMonth, 
           (SELECT TaxName FROM #TDATaxUnit) AS TaxName, 
           C.Price, 
           B.InvoiceSeq, 
           LEFT(B.InvoiceDate,4) AS InvoiceYear, 
           F.CustName, 
           (SELECT Owner FROM #TDATaxUnit) AS Owner, 
           (SELECT BizType FROM #TDATaxUnit) AS BizType, 
           CONVERT(NVARCHAR(8),GETDATE(),112) AS Present, 
           (SELECT TaxNo FROM #TDATaxUnit) AS  TaxNo, 
           C.CurAmt, 
           C.CurVAT, 
           --DelvCustTot,
           CASE WHEN (SELECT (C.Qty) / (P.ConvNum) / (P.ConvDen)
                       FROM jongie_TCOMEnv AS O WITH(NOLOCK) 
                       JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = C.ItemSeq ) 
                      WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1) > 0 
                THEN FLOOR(
                           (
                               SELECT (C.Qty) / (P.ConvNum) / (P.ConvDen)
                                 FROM jongie_TCOMEnv AS O WITH(NOLOCK) 
                                 JOIN _TDAItemUnit   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.UnitSeq = O.EnvValue AND P.ItemSeq = C.ItemSeq ) 
                                WHERE O.CompanySeq = @CompanySeq AND O.EnvSeq = 1
                           )
                          )
                ELSE 0 
                END AS Box, 
           (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 5 AND EnvSerl = 1) AS Bank1, 
           (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 6 AND EnvSerl = 1) AS Bank2 
      FROM #TSLInvoice AS A 
      JOIN _TSLInvoice AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      LEFT OUTER JOIN _TSLInvoiceItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.InvoiceSeq = B.InvoiceSeq ) 
      LEFT OUTER JOIN _TDAItem        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDAEmp         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDACust        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TSLDeliveryCust AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DVPlaceSeq = B.DVPlaceSeq ) 
     ORDER BY InvoiceMonth, F.CustName, G.DVPlaceName, B.InvoiceDate, D.ItemName
    RETURN
GO
exec jongie_SSLInvoiceLisPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>1000774</InvoiceSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>1000783</InvoiceSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InvoiceSeq>1000776</InvoiceSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017839,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1276