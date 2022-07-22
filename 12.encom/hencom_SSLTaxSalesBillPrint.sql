IF OBJECT_ID('hencom_SSLTaxSalesBillPrint') IS NOT NULL 
    DROP PROC hencom_SSLTaxSalesBillPrint
GO 

-- v2017.07.03 
/************************************************************      
  설  명 - 데이터-계산서청구내역조회출력_hencom : 출력      
  작성일 - 20160621      
  작성자 - 박수영      
  수정 :by박수영2016.06.23 - 일자,품목중분류,규격명칭이 동일하면 합산.      
 ************************************************************/      
 CREATE PROC dbo.hencom_SSLTaxSalesBillPrint
  @xmlDocument    NVARCHAR(MAX),        
  @xmlFlags       INT     = 0,        
  @ServiceSeq     INT     = 0,        
  @WorkingTag     NVARCHAR(10)= '',        
  @CompanySeq     INT     = 1,        
  @LanguageSeq    INT     = 1,        
  @UserSeq        INT     = 0,        
  @PgmSeq         INT     = 0        
  AS         
        
  CREATE TABLE #TSLBillPrint (WorkingTag NCHAR(1) NULL)        
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLBillPrint'           
  IF @@ERROR <> 0 RETURN        
            
    SELECT  M.BillSeq,      
             MAX(A.BillDate) AS PrintDate ,      
             MAX(A.DeptSeq) AS DeptSeq ,      
             MAX(A.CustName) AS CustName,      
             1 AS Sort,      
             SUM(A.TotCurAmt) AS TotAmt,        
             dbo._FDAGetAmtHan(SUM(A.TotCurAmt)) AS TotalHanAmt,
			 A.Remark
     INTO #TMPMstAmt
     FROM #TSLBillPrint AS M
     JOIN hencom_VSLBill AS A WITH(NOLOCK) ON A.BillSeq = M.BillSeq
     WHERE A.CompanySeq = @CompanySeq
     GROUP BY M.BillSeq, A.Remark
        
  --일자,규격명칭,단가,품목중분류는 합산처리      
       SELECT  M.BillSeq,      
            I.ItemName ,         
            IC.ItemClassMSeq ,      
            CASE WHEN ISNULL(A.AttachDate,'') = '' THEN A.WorkDate ELSE A.AttachDate END AS WorkDate ,      
             ISNULL(A.price,0)              AS Price   ,        
             SUM(ISNULL(A.Qty,0))           AS Qty     ,        
             SUM(ISNULL(A.CurAmt,0))        AS CurAmt     ,         
             SUM(ISNULL(A.CurVAT,0))        AS CurVAT     ,         
             SUM(ISNULL(A.TotAmt,0))        AS TotAmt
     INTO #TMPItem      
     FROM #TSLBillPrint AS M      
     JOIN hencom_VInvoiceReplaceItem AS A WITH(NOLOCK) ON A.BillSeq = M.BillSeq      
     LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq       
     LEFT OUTER JOIN V_ItemClass AS IC WITH(NOLOCK) ON IC.CompanySeq = @CompanySeq          
                                                 AND IC.ItemSeq = A.ItemSeq       
     WHERE A.CompanySeq = @CompanySeq        
    GROUP BY M.BillSeq,I.ItemName ,IC.ItemClassMSeq ,ISNULL(A.price,0) ,CASE WHEN ISNULL(A.AttachDate,'') = '' THEN A.WorkDate ELSE A.AttachDate END      
        
   
    SELECT  A.BillSeq,      
            A.ItemName ,         
            A.ItemClassMSeq ,   
             A.Price         AS SalesPrice   ,        
             SUM(ISNULL(A.Qty,0))           AS SalesQty     ,        
             SUM(ISNULL(A.CurAmt,0))        AS SalesAmt     ,         
             SUM(ISNULL(A.CurVAT,0))        AS SalesVat     ,         
             SUM(ISNULL(A.TotAmt,0))        AS TotSalesAmt        
     INTO #TMPItemSum      
     FROM #TMPItem AS A      
    GROUP BY A.BillSeq,A.ItemName ,A.ItemClassMSeq ,A.Price --,A.WorkDate      
      
  
       SELECT  A.BillSeq,      
             0 AS IsSum ,      
             ROW_NUMBER() OVER(PARTITION BY A.BillSeq ORDER BY A.BillSeq )  AS RowNum,      
             A.WorkDate      AS InvoiceDate  ,         
             A.ItemName      AS ItemName     ,        
             A.ItemClassMSeq AS ItemClassMSeq ,       
             A.Qty           AS SalesQty     ,         
             A.price         AS SalesPrice   ,        
             A.CurAmt        AS SalesAmt     ,         
             A.CurVAT        AS SalesVat     ,         
             A.TotAmt        AS TotSalesAmt
     INTO #TMPResult      
     FROM #TMPItem AS A      
     UNION ALL      
     SELECT A.BillSeq,      
       1 AS IsSum ,      
             -1 AS RowNum ,       
             '' AS InvoiceDate,      
             A.ItemName,      
             A.ItemClassMSeq,      
             A.SalesQty ,      
             A.SalesPrice ,      
             A.SalesAmt ,      
             A.SalesVat ,      
             A.TotSalesAmt
      FROM #TMPItemSum AS A      
      
   SELECT    M.IDX_NO, 
             M.BillSeq,      
             A.RowNum,      
             MAT.CustName,      
             MAT.PrintDate AS PrintDate ,      
             A.IsSum AS IsSum,      
             SUBSTRING( T.TaxNo, 1, 3 ) + '-' + SUBSTRING( T.TaxNo, 4, 2 ) + '-' + SUBSTRING( T.TaxNo, 6, 5 ) AS TaxNo, -- 사업자등록번호      
             T.TaxName AS TaxName, -- 사업자상호       
             CASE WHEN ISNULL( T.VatRptAddr, '' ) = '' THEN CONVERT(VARCHAR(150), LTRIM(RTRIM(T.Addr1)) + LTRIM(RTRIM(T.Addr2)) + LTRIM(RTRIM(T.Addr3)) )          
             ELSE T.VatRptAddr  END AS Addr, -- 사업장주소           
             T.Owner         AS Owner, -- 사업자대표자        
               MAT.TotAmt      AS TotalAmt,  
             MAT.TotalHanAmt AS TotalHanAmt,      
             --마스터정보      
             --품목정보      
             A.InvoiceDate      AS WorkDate, --거래명세서일자           
             A.ItemName  AS GoodItemName,      
             A.SalesQty           AS Qty     ,         
             A.SalesPrice         AS Price   ,        
             A.SalesAmt        AS CurAmt     ,         
             A.SalesVat        AS CurVAT     ,         
             CASE WHEN A.IsSum = 1 THEN '규격계' ELSE UM.MinorName END AS MName,      
             MAT.Remark      
     FROM #TSLBillPrint AS M      
     JOIN #TMPResult AS A WITH(NOLOCK) ON A.BillSeq = M.BillSeq      
     JOIN #TMPMstAmt AS MAT ON MAT.BillSeq = M.BillSeq      
     LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DeptSeq = MAT.DeptSeq      
     LEFT OUTER JOIN _TDATaxUnit AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq          
                                                     AND T.TaxUnit = D.TaxUnit        
        LEFT OUTER JOIN _TDAUMinor AS UM ON UM.CompanySeq = @CompanySeq AND UM.MinorSeq = A.ItemClassMSeq      
           
     ORDER BY M.IDX_NO, MAT.PrintDate,M.BillSeq,A.IsSum,A.InvoiceDate,A.ItemName      
        
  RETURN
