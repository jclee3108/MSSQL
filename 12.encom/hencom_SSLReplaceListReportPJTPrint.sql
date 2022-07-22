IF OBJECT_ID('hencom_SSLReplaceListReportPJTPrint') IS NOT NULL 
    DROP PROC hencom_SSLReplaceListReportPJTPrint
GO 

-- v2017.06.23 
/************************************************************    
  설  명 - 데이터-매출자료생성조회출력_hencom : 출력    
  작성일 - 20160622    
  작성자 - 박수영    
 ************************************************************/    
 CREATE PROC dbo.hencom_SSLReplaceListReportPJTPrint    
  @xmlDocument    NVARCHAR(MAX),      
  @xmlFlags       INT     = 0,      
  @ServiceSeq     INT     = 0,      
  @WorkingTag     NVARCHAR(10)= '',      
  @CompanySeq     INT     = 1,      
  @LanguageSeq    INT     = 1,      
  @UserSeq        INT     = 0,      
  @PgmSeq         INT     = 0      
     
 AS       
      
  CREATE TABLE #TSLInvoicePrint (WorkingTag NCHAR(1) NULL)      
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoicePrint'         
  IF @@ERROR <> 0 RETURN      
  --마스터에서 수집한 출력일자
     DECLARE @MstPrintDate NCHAR(8)
     
     SELECT @MstPrintDate = MstPrintDate 
     FROM #TSLInvoicePrint
  --SELECT  @MstPrintDate
 --IsReplace  대체여부    
 --ReplaceRegSerl 대체등록순번    
 --ReplaceRegSeq 대체등록코드    
 --IsOnlyInv 거래명세서직접    
 --InvoiceSeq 거래명세서코드    
 --InvoiceSerl 거래명세서품목순번    
 --SumMesKey 합계연동Key    
 --IsPreSales 선매출발생건여부    
     
     SELECT  M.WorkDate ,   
             M.AttachDate ,    
             CASE WHEN ISNULL(M.AttachDate,'') <> '' THEN M.AttachDate ELSE M.WorkDate END AS PrintDate ,  
             M.DeptSeq,   
             M.CustSeq,  
     --마스터  
     --상세  
             M.ItemSeq  ,  
             M.Qty ,  
             M.Price ,  
             M.CurAmt ,  
             M.CurVAT ,  
             M.TotAmt,  
             M.Remark ,
             I.ItemName,
             IC.ItemClassMSeq, 
             M.PJTSeq 

     INTO #TMPData  
     FROM #TSLInvoicePrint AS A    
     JOIN hencom_VInvoiceReplaceItem AS M ON ISNULL(M.IsReplace,0) = A.IsReplace    
                                         AND ISNULL(M.ReplaceRegSerl,0) = A.ReplaceRegSerl    
                                         AND ISNULL(M.ReplaceRegSeq,0) = A.ReplaceRegSeq    
                                         AND ISNULL(M.IsOnlyInv,0) = A.IsOnlyInv    
                                         AND ISNULL(M.InvoiceSeq,0) = A.InvoiceSeq    
                                         AND ISNULL(M.InvoiceSerl,0)= A.InvoiceSerl     
                                         AND ISNULL(M.SumMesKey,0) = A.SumMesKey   
     LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = M.ItemSeq   
     LEFT OUTER JOIN V_ItemClass AS IC WITH(NOLOCK) ON IC.CompanySeq = @CompanySeq      
                                                 AND IC.ItemSeq = M.ItemSeq    
     WHERE M.CompanySeq = @CompanySeq     
--     AND ISNULL(M.IsPreSales,0) <> '1'  --선매출도 포함 by박수영 2016.07.29
    


     SELECT  ROW_NUMBER() OVER(ORDER BY M.CustSeq ) AS PageGubun ,  
             @MstPrintDate AS PrintDate ,
             M.CustSeq ,  
             M.DeptSeq AS DeptSeq ,    
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = M.CustSeq ) AS CustName,    
             M.PJTSeq, 
             (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = M.PJTSeq ) AS PJTName, 
             1 AS Sort,    
             SUM(ISNULL(M.TotAmt,0)) AS TotAmt,      
             dbo._FDAGetAmtHan(SUM(ISNULL(M.TotAmt,0))) AS TotalHanAmt
 --            dbo.hencom_FCAGetHanAmt(SUM(ISNULL(M.TotAmt,0))) AS TotalHanAmt    
     INTO #TMPMstAmt    
     FROM #TMPData AS M  
     GROUP BY M.DeptSeq,M.CustSeq, M.PJTSeq
     
     SELECT  DeptSeq,  
             CustSeq,  
             PJTSeq, 
             PrintDate   ,       
             ItemName    ,       
             ItemClassMSeq  ,
             ISNULL(Price,0) AS Price ,  
             SUM(ISNULL(Qty,0)) AS Qty ,       
             SUM(ISNULL(CurAmt,0)) AS CurAmt  ,       
             SUM(ISNULL(CurVAT,0)) AS CurVAT  ,       
             SUM(ISNULL(TotAmt,0)) AS TotAmt   ,
             MAX(Remark) AS Remark   
     INTO #TMPDataGrp  
     FROM #TMPData 
     GROUP BY DeptSeq,CustSeq,PJTSeq,PrintDate,ItemName,ISNULL(Price,0),ItemClassMSeq
     
      SELECT  M.DeptSeq,  
             M.CustSeq,  
             M.PJTSeq, 
             M.ItemName                  AS ItemName     ,  
             M.ItemClassMSeq      ,
             ISNULL(M.price,0)           AS SalesPrice   ,      
             SUM(ISNULL(M.Qty,0))        AS SalesQty     ,      
             SUM(ISNULL(M.CurAmt,0))     AS SalesAmt     ,
             SUM(ISNULL(M.CurVAT,0))     AS SalesVat     ,       
             SUM(ISNULL(M.TotAmt,0))     AS TotSalesAmt      
     INTO #TMPItemSum    
     FROM #TMPData AS M    
     GROUP BY M.DeptSeq,M.CustSeq,M.PJTSeq,M.ItemName,ISNULL(M.price,0), M.ItemClassMSeq 
      
      
      
    --select * from #TMPDataGrp 
    --return 
      
      SELECT    
             M.DeptSeq,  
             M.CustSeq,
             M.PJTSeq,   
             M.PrintDate ,  
             0 AS IsSum ,    
             ROW_NUMBER() OVER(PARTITION BY M.DeptSeq,M.CustSeq ORDER BY M.PrintDate )  AS RowNum,    
             M.PrintDate      AS InvoiceDate  ,             
             M.ItemName      AS ItemName     ,       
             M.ItemClassMSeq  AS ItemClassMSeq ,
             M.Qty           AS SalesQty     ,       
             M.price         AS SalesPrice   ,      
             M.CurAmt        AS SalesAmt     ,       
             M.CurVAT        AS SalesVat     ,       
             M.TotAmt        AS TotSalesAmt  ,    
             M.Remark    
       INTO #TMPResult    
     FROM #TMPDataGrp AS M     
     UNION ALL    
     SELECT  A.DeptSeq,  
             A.CustSeq,  
             A.PJTSeq, 
             '' ,  
             1 AS IsSum ,    
             -1 AS RowNum ,     
             '' AS InvoiceDate,       
             A.ItemName,    
             A.ItemClassMSeq  AS ItemClassMSeq , 
             A.SalesQty ,    
             A.SalesPrice ,    
             A.SalesAmt ,    
             A.SalesVat ,    
             A.TotSalesAmt ,    
             '' AS Remark    
     
     FROM #TMPItemSum AS  A    
   
          
     SELECT  MAT.PageGubun,  
             A.RowNum,    
             MAT.CustName,    
             MAT.CustSeq,  
             MAT.PJTSeq, 
             MAT.PJTName, 
             MAT.DeptSeq,  
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
             A.Remark    
     FROM #TMPResult AS A   
     JOIN #TMPMstAmt AS MAT ON MAT.DeptSeq = A.DeptSeq    
                             AND MAT.CustSeq = A.CustSeq 
                             AND MAT.PJTSeq = A.PJTSeq
     LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DeptSeq = MAT.DeptSeq    
     LEFT OUTER JOIN _TDATaxUnit AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq        
                                                     AND T.TaxUnit = D.TaxUnit     
     LEFT OUTER JOIN _TDAUMinor AS UM ON UM.CompanySeq = @CompanySeq AND UM.MinorSeq = A.ItemClassMSeq    
         
     ORDER BY MAT.DeptSeq,MAT.CustSeq,MAT.PJTSeq,MAT.PrintDate,A.IsSum,A.InvoiceDate,A.ItemName  
      
   
   
 RETURN

go

exec hencom_SSLReplaceListReportPJTPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsReplace>0</IsReplace>
    <IsPreSales>0</IsPreSales>
    <IsOnlyInv>1</IsOnlyInv>
    <ReplaceRegSerl>0</ReplaceRegSerl>
    <ReplaceRegSeq>0</ReplaceRegSeq>
    <InvoiceSeq>1747</InvoiceSeq>
    <InvoiceSerl>1</InvoiceSerl>
    <SumMesKey>0</SumMesKey>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <MstPrintDate>20170623</MstPrintDate>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>9</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsReplace>0</IsReplace>
    <IsPreSales>0</IsPreSales>
    <IsOnlyInv>1</IsOnlyInv>
    <ReplaceRegSerl>0</ReplaceRegSerl>
    <ReplaceRegSeq>0</ReplaceRegSeq>
    <InvoiceSeq>2260</InvoiceSeq>
    <InvoiceSerl>1</InvoiceSerl>
    <SumMesKey>0</SumMesKey>
    <MstPrintDate>20170623</MstPrintDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037577,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027772