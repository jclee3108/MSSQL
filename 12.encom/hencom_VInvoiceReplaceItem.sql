IF OBJECT_ID('hencom_VInvoiceReplaceItem') IS NOT NULL 
    DROP VIEW hencom_VInvoiceReplaceItem 
GO 

/**************************************                    
설명: MES출하집계데이터와 송장규격대체데이터를 보여주기 위함.                    
      매출자료생성조회_hencom 화면의 데이터와 동일함.                    
      2015.12.29 by 박수영           
      수정:     
      세금계산서일자가져오기 위한 BillSeq 추가 by박수영 2016.03.04      
      선매출여부 추가 by박수영 2016.03.07      
      선매출관급발생맵핑에 사용된 값 추가     
'hencom_TIFProdWorkReportCloseSum' : 1000057    
'hencom_TSLInvoiceReplaceItem' : 1000075    
'_TSLInvoiceItem' : 1268    
    
select * from _TCATables where tablename = 'hencom_TSLInvoiceReplaceItem'    
***************************************/                    
CREATE VIEW hencom_VInvoiceReplaceItem
AS                    
 SELECT C.CompanySeq    ,                        
        (SELECT  MAX(IsReplace)                            
                FROM hencom_TSLCloseSumReplaceMapping                              
                WHERE CompanySeq = D.CompanySeq                             
                AND ReplaceRegSeq = D.ReplaceRegSeq                             
                AND ReplaceRegSerl = D.ReplaceRegSerl                            
                ) AS IsReplace,                            
            C.ReplaceRegSeq ,                                
            D.ReplaceRegSerl ,                                
--            C.BillDate ,                                
            C.CurrSeq ,                                
            C.ExRate ,                                
            C.Remark,                                
            -----------------                                
            D.PJTSeq ,                                
            D.InvoiceDate AS WorkDate,                                
            D.ItemSeq ,                                
            D.Qty ,                                
            D.Price ,                                
            D.CurAmt ,                                
            D.CurVAT ,                                
            D.CurAmt + D.CurVAT AS TotAmt,                                
            D.IsInclusedVAT ,                                
            D.CustSeq ,                                
            E.CustName ,                                
            ISNULL((SELECT PJTName FROM _TPJTProject WHERE PJTSeq = D.PJTSeq AND CompanySeq = D.CompanySeq), '')  AS PJTName,                                
            T.ItemName AS GoodItemName,                                
            CASE WHEN RC.UMOutType = 8020097 THEN RC.PurDeptSeq ELSE RC.DeptSeq END  AS DeptSeq,    --전출일 경우 매출자료는 매입사업소로 조회됨.                            
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = RC.CompanySeq AND DeptSeq =               
                                                    (CASE WHEN RC.UMOutType = 8020097 THEN RC.PurDeptSeq ELSE RC.DeptSeq END)              
            ) AS DeptName,                                

            RC.DeptSeq AS PDDeptSeq, 
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = RC.CompanySeq AND DeptSeq = RC.DeptSeq) AS PDDeptName,

            D.LastUserSeq ,                                
            D.LastDateTime ,                                
            rc.InvoiceSeq            AS InvoiceSeq,                
            1            AS InvoiceSerl,                           
            rc.SalesSeq            AS SalesSeq,                              
			1           as SalesSerl,
            ''              AS SumMesKey ,                          
            D.CurAmt - ISNULL(BS.ProcCurAmt,0) AS BalCurAmt,                          
            D.CurVAT - ISNULL(BS.ProcCurVAT,0) AS BalCurVAT,                          
            0 AS ReceiptCurAmt,                          
            0 AS ReceiptCurVAT,                          
            CASE WHEN BS.ReplaceRegSeq > 0 THEN '1' ELSE '0' END AS IsBill ,                      
            CF.CfmCode AS CfmCode , --대체확정여부                      
            E.BizNo AS BizNo , --사업자번호                      
            '1' AS CloseCfmCode, --집계확정                    
            D.Qty AS ProdQty ,                      
            D.Qty AS OutQty  ,                  
            '0' as IsOnlyInv,      
              isnull(BS.BillSeq,0) AS  BillSeq, --세금계산서내부코드(분할 청구없어야 함.)       
            isnull(D.IsPreSales,'0')  AS IsPreSales , --선매출여부    
              1000075       AS SourceTableSeq  ,
              D.AttachDate as AttachDate,  
--            ,RC.UMOutType AS UMOutType --출고구분        
            ISNULL(BS.ProcCurAmt,0) AS BillAmt, --세금계산서금액                          
            ISNULL(BS.ProcCurVAT,0) AS BillVAT,  --세금계산서부가세
            CustClass.UMCustClass AS UMCustClass,      --거래처구분코드          
            UMinrClss.MinorName   AS UMCustClassName  --거래처구분명            
    FROM hencom_TSLInvoiceReplace AS C WITH(NOLOCK)
		JOIN hencom_TSLInvoiceReplaceItem AS D  WITH(NOLOCK) ON D.CompanySeq = C.CompanySeq AND D.ReplaceRegSeq = C.ReplaceRegSeq                                          
		LEFT OUTER JOIN (  SELECT CompanySeq,ReplaceRegSeq,                            
                                  MAX(SumMesKey) AS SumMesKey --사업소 조회하기 위해 추가                               
                           FROM	  hencom_TSLCloseSumReplaceMapping                              
                           GROUP BY CompanySeq,ReplaceRegSeq                            
                         ) AS B ON  B.CompanySeq = D.CompanySeq AND B.ReplaceRegSeq = D.ReplaceRegSeq                                              
		LEFT OUTER JOIN _TDACust AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq AND E.CustSeq = D.CustSeq
		LEFT OUTER JOIN _TDAItem AS T WITH(NOLOCK) ON T.CompanySeq = D.CompanySeq AND T.ItemSeq = D.ItemSeq
		LEFT OUTER JOIN hencom_TIFProdWorkReportCloseSum AS RC WITH(NOLOCK) ON RC.CompanySeq = B.CompanySeq AND RC.SumMesKey = B.SumMesKey                                 
		LEFT OUTER JOIN( SELECT CompanySeq,                    
                                ReplaceRegSeq,                             
                                ReplaceRegSerl,                          
                                SUM(ISNULL(ReplaceCurAmt,0)) AS ProcCurAmt ,                          
                                SUM(ISNULL(ReplaceCurVAT,0)) AS ProcCurVAT ,                          
                                SUM(ISNULL(ReplaceDomAmt,0)) AS ProcDomAmt ,                          
                                SUM(ISNULL(ReplaceDomVat,0)) AS ProcDomVat ,      
                                MAX(BillSeq) AS BillSeq                         
                          FROM  hemcom_TSLBillReplaceRelation                          
                          GROUP BY CompanySeq,ReplaceRegSeq, ReplaceRegSerl                          
                        ) AS BS ON BS.CompanySeq = D.CompanySeq                     
                            AND BS.ReplaceRegSeq = D.ReplaceRegSeq                     
                            AND BS.ReplaceRegSerl = D.ReplaceRegSerl
		LEFT OUTER JOIN _TDACustClass AS CustClass WITH(NOLOCK) ON CustClass.CompanySeq = E.CompanySeq
                                                               AND CustClass.CustSeq = E.CustSeq
                                                               AND CustClass.UMajorCustClass = 8004
		LEFT OUTER JOIN _TDAUMinor    AS UMinrClss WITH(NOLOCK) ON UMinrClss.CompanySeq = CustClass.CompanySeq
                                                               AND UMinrClss.MinorSeq = CustClass.UMCustClass
  /*  LEFT OUTER JOIN (SELECT CompanySeq,SalesSeq, SalesSerl,                             
                            SUM(CurAmt) AS CurAmt                      
                    FROM  _TSLAltReceipt  WITH(NOLOCK)                           
               GROUP BY CompanySeq,SalesSeq, SalesSerl) AS Rec ON Rec.CompanySeq = rc.CompanySeq                     
                                                                AND Rec.SalesSeq = rc.SalesSeq                            
                                                                AND Rec.SalesSerl = 1       */
    LEFT OUTER JOIN hencom_TSLInvoiceReplace_Confirm AS CF ON CF.CompanySeq = C.CompanySeq AND CF.CfmSeq = C.ReplaceRegSeq                      
                                  
    UNION ALL                                
                                    
    SELECT  A.CompanySeq AS CompanySeq,                    
            '0'          AS IsReplace ,                                      
            NULL        AS ReplaceRegSeq,                                
            NULL        AS ReplaceRegSerl,                                    
            V.CurrSeq   AS CurrSeq,                                
            V.ExRate    AS ExRate,                                
            V.Remark,                                
            A.PJTSeq ,                                
            A.WorkDate AS WorkDate,
            A.GoodItemSeq AS ItemSeq,
            A.OutQty ,                                
            A.Price ,                                 
            A.CurAmt ,                                
            A.CurVAT ,
            A.CurAmt + A.CurVAT AS TotAmt,                                
            A.IsInclusedVAT ,                                
            A.CustSeq ,                                
            (SELECT CustName FROM _TDACust WHERE CompanySeq = A.CompanySeq AND CustSeq = A.CustSeq) AS CustName ,                                
            ISNULL((SELECT PJTName FROM _TPJTProject WHERE PJTSeq = A.PJTSeq AND CompanySeq = A.CompanySeq), '')  AS PJTName,                                
              T.ItemName AS GoodItemName,                                
             CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END  AS DeptSeq,    --전출일 경우 매출자료는 매입사업소로 조회됨.                            
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq =               
                                                    (CASE WHEN A.UMOutType = 8020097 THEN A.PurDeptSeq ELSE A.DeptSeq END)              
            ) AS DeptName,      
            
            A.DeptSeq AS PDDeptSeq, 
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq) AS PDDeptName,

            A.LastUserSeq ,                                
            A.LastDateTime,                               
            A.InvoiceSeq    AS InvoiceSeq,              
            case when isnull(a.invoiceseq,0) = 0 then 0 else 1 end               AS InvoiceSerl,                            
            A.SalesSeq      AS SalesSeq,                              
			1           as SalesSerl,
            A.SumMesKey     AS SumMesKey ,                          
            A.CurAmt - ISNULL(J.CurAmt,0) AS BalCurAmt,                          
            A.CurVAT - ISNULL(J.CurVAT,0) AS BalCurVAT,                          
            0 AS ReceiptCurAmt,                          
            0 AS ReceiptCurVAT,                          
            CASE WHEN J.SalesSeq > 0 THEN '1' ELSE '0' END AS IsBill   ,                      
            '0' AS CfmCode ,--대체확정여부                       
            E.BizNo AS BizNo, --사업자번호                       
            A.CfmCode AS CloseCfmCode ,--집계확정                    
            A.ProdQty AS ProdQty,                    
            A.OutQty AS OutQty,                  
            '0' as IsOnlyInv,         
            isnull(J.BillSeq,0) AS BillSeq, --세금계산서내부코드(분할 청구없어야 함.)      
            '0'         AS IsPreSales ,--선매출여부    
            1000057     AS SourceTableSeq  ,
            a.AttachDate , 
--            ,A.UMOutType AS UMOutType --출고구분       
            ISNULL(J.CurAmt,0) AS BillAmt ,                         
            ISNULL(J.CurVAT,0) AS BillVAT,
			CustClass.UMCustClass AS UMCustClass,      --거래처구분코드          
            UMinrClss.MinorName   AS UMCustClassName  --거래처구분명    
    FROM hencom_TIFProdWorkReportCloseSum     AS A  WITH(NOLOCK)                                
	    LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS MP WITH(NOLOCK) ON MP.CompanySeq = A.CompanySeq                                 
                                                                           AND MP.SumMesKey = A.SumMesKey                                   
        LEFT OUTER JOIN _TSLInvoice AS V WITH(NOLOCK) ON V.CompanySeq = A.CompanySeq                                 
                                                    AND V.InvoiceSeq = A.InvoiceSeq                                  
        LEFT OUTER JOIN _TDAItem AS T WITH(NOLOCK) ON T.CompanySeq = A.CompanySeq                                 
                                                  AND T.ItemSeq = A.GoodItemSeq                              
-----------------------------------------------------                          
        LEFT OUTER JOIN (SELECT Y.CompanySeq,Y.SalesSeq, Y.SalesSerl,                             
                                SUM(Y.CurAmt) AS CurAmt, SUM(Y.CurVAT) AS CurVAT,                             
                                SUM(Y.DomAmt) AS DomAmt, SUM(Y.DomVAT) AS DomVAT, MAX(Y.BillSeq) AS BillSeq                             
                         FROM   _TSLSalesBillRelation AS Y WITH(NOLOCK)                           
                         GROUP BY Y.CompanySeq,Y.SalesSeq, Y.SalesSerl) AS J ON J.CompanySeq = A.CompanySeq                      
                                                                            AND J.SalesSeq = A.SalesSeq                             
                                                                            AND J.SalesSerl = 1                            
--------------------------------------------------                             
  /*  LEFT OUTER JOIN (SELECT CompanySeq,SalesSeq, SalesSerl,                             
                              SUM(CurAmt) AS CurAmt                      
                    FROM  _TSLAltReceipt  WITH(NOLOCK)                           
               GROUP BY CompanySeq,SalesSeq, SalesSerl) AS Rc ON Rc.CompanySeq = A.CompanySeq                     
                                                                AND Rc.SalesSeq = A.SalesSeq                            
                                                                AND Rc.SalesSerl = 1              */             
        LEFT OUTER JOIN _TDACust AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.CustSeq = A.CustSeq                      
        LEFT OUTER JOIN V_mstm_UMOutType AS UO ON UO.CompanySeq = A.CompanySeq AND UO.MinorSeq = A.UMOutType
		LEFT OUTER JOIN _TDACustClass AS CustClass WITH(NOLOCK) ON CustClass.CompanySeq = E.CompanySeq
                                                               AND CustClass.CustSeq = E.CustSeq
                                                               AND CustClass.UMajorCustClass = 8004
		LEFT OUTER JOIN _TDAUMinor    AS UMinrClss WITH(NOLOCK) ON UMinrClss.CompanySeq = CustClass.CompanySeq
                                                               AND UMinrClss.MinorSeq = CustClass.UMCustClass
    WHERE ISNULL(MP.SumMesKey,'') = ''              
      AND ISNULL(UO.SetPrice,0) <> 1011590002  --출고구분의 추가정보에 단가구분이 0이 아닌것만 조회.          

    union all                  
                  
    select a.CompanySeq,                  
           '0' as IsReplace,                  
     null as ReplaceRegSeq,                  
     null as ReplaceRegSerl,                  
     a.CurrSeq,                  
     a.ExRate,                  
     a.Remark,                  
     b.PJTSeq,                  
     a.InvoiceDate as WorkDate,                  
     b.ItemSeq,                  
     b.Qty,                  
     CASE WHEN B.Price IS NOT NULL                  
      THEN B.Price                  
            ELSE (CASE WHEN ISNULL(B.Qty,0) = 0                  
            THEN 0                  
            ELSE (CASE WHEN B.IsInclusedVAT = '1'                  
               THEN (ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)                          
               ELSE ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0) END) END) END AS Price, -- 판매단가                        
     b.CurAmt,                  
     b.CurVAT,                  
     b.CurAmt + b.CurVAT as TotAmt,                  
     b.IsInclusedVAT,                  
     a.CustSeq,                  
     c.CustName,                  
     (select PJTName  from _TPJTProject where CompanySeq = a.CompanySeq and PJTSeq = b.PJTSeq ) as PJTName,                  
     (select ItemName  from _TDAItem where CompanySeq = a.CompanySeq and ItemSeq = b.ItemSeq ) as ItemName,                  
     a.DeptSeq,                  
     (select DeptName  from _TDADept where CompanySeq = a.CompanySeq and DeptSeq = a.DeptSeq ) as DeptName,                  
     a.DeptSeq AS PDDeptSeq, 
     (select DeptName  from _TDADept where CompanySeq = a.CompanySeq and DeptSeq = a.DeptSeq ) as PDDeptName,                  
     a.LastUserSeq,                  
     a.LastDateTime,                  
     a.InvoiceSeq as InvoiceSeq,                 
     B.InvoiceSerl AS InvoiceSerl,             
     s.SalesSeq as SalesSeq,                  
	 s.SalesSerl,
     0 as SumMesKey,                  
     b.CurAmt - ISNULL(J.CurAmt,0) AS BalCurAmt,                          
     b.CurVAT - ISNULL(J.CurVAT,0) AS BalCurVAT,                          
     0 AS ReceiptCurAmt,                           
     0 AS ReceiptCurVAT,                          
     CASE WHEN J.SalesSeq > 0 THEN '1' ELSE '0' END AS IsBill   ,                      
    '0' AS CfmCode ,--대체확정여부                       
     c.BizNo,                  
     '1' AS CloseCfmCode, --집계확정                 
     b.Qty as ProdQty,                  
     b.Qty as OutQty,                  
     '1' as IsOnlyInv ,         
     isnull(J.BillSeq,0)  AS BillSeq , --세금계산서내부코드(분할 청구없어야 함.)      
     '0'    AS IsPreSales , --선매출여부    
     1268   AS SourceTableSeq,
     b.Dummy2   as AttachDate,
    ISNULL(J.CurAmt,0) AS BillAmt ,                         
    ISNULL(J.CurVAT,0) AS BillVAT,
	CustClass.UMCustClass AS UMCustClass,      --거래처구분코드          
    UMinrClss.MinorName   AS UMCustClassName  --거래처구분명    
    FROM _TSLInvoice AS A WITH(NOLOCK)                      
       JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq = B.InvoiceSeq                   
       JOIN _TDACust        AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq                
       left outer join ( SELECT CompanySeq, fromseq as InvoiceSeq, FromSerl as InvoiceSerl, ToSeq as SalesSeq, ToSerl as SalesSerl              
                         FROM   _TCOMSourceDaily WITH(NOLOCK)
                         WHERE  FromTableSeq = 18
                         AND    ToTableSeq = 20
                         GROUP BY CompanySeq,fromseq,fromserl, ToSeq, ToSerl
                         having sum(add_del) > 0) as SD on sd.CompanySeq = a.CompanySeq
                                                       and SD.InvoiceSeq = a.InvoiceSeq              
                                                       and SD.InvoiceSerl = b.InvoiceSerl              
       left outer join _TSLSalesItem as s on s.CompanySeq = a.CompanySeq                  
                                         and s.SalesSeq = SD.SalesSeq                  
                                         and s.SalesSerl = SD.SalesSerl                    
       JOIN _TDASMinorValue AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq                      
                                             AND A.SMExpKind  = D.MinorSeq                      
                                             AND D.Serl       = 1001                    
       LEFT OUTER JOIN _TDAUMinorValue AS OutK WITH(NOLOCK) ON A.CompanySeq = OutK.CompanySeq                    
                                                           AND A.UMOutKind  = Outk.MinorSeq                    
                                                           AND OutK.Serl    = 2002                    
       LEFT OUTER JOIN (SELECT Y.CompanySeq,Y.SalesSeq, Y.SalesSerl,                             
                               SUM(Y.CurAmt) AS CurAmt, SUM(Y.CurVAT) AS CurVAT,                             
                               SUM(Y.DomAmt) AS DomAmt, SUM(Y.DomVAT) AS DomVAT ,MAX(Y.BillSeq) AS BillSeq                            
                        FROM   _TSLSalesBillRelation AS Y WITH(NOLOCK)                           
                        GROUP BY Y.CompanySeq,Y.SalesSeq, Y.SalesSerl) AS J ON J.CompanySeq = A.CompanySeq
                                                                           AND J.SalesSeq = s.SalesSeq
                                                                           AND J.SalesSerl = s.SalesSerl
  /*  LEFT OUTER JOIN (SELECT CompanySeq,SalesSeq, SalesSerl,                             
SUM(CurAmt) AS CurAmt                      
                    FROM  _TSLAltReceipt  WITH(NOLOCK)                           
               GROUP BY CompanySeq,SalesSeq, SalesSerl) AS Rc ON Rc.CompanySeq = A.CompanySeq                     
                                                                AND Rc.SalesSeq = s.SalesSeq                            
                                                                AND Rc.SalesSerl = s.SalesSerl       */                     
       LEFT OUTER JOIN V_mstm_UMOutType AS UO ON UO.CompanySeq = A.CompanySeq AND UO.MinorSeq = A.UMOutKind
       LEFT JOIN hencom_TIFProdWorkReportCloseSum AS CS WITH(NOLOCK) ON CS.CompanySeq = a.CompanySeq AND CS.InvoiceSeq = a.InvoiceSeq -- 2016.11.17
       LEFT OUTER JOIN _TDACustClass AS CustClass WITH(NOLOCK) ON CustClass.CompanySeq = C.CompanySeq
                                                              AND CustClass.CustSeq = C.CustSeq
                                                              AND CustClass.UMajorCustClass = 8004
       LEFT OUTER JOIN _TDAUMinor    AS UMinrClss WITH(NOLOCK) ON UMinrClss.CompanySeq = CustClass.CompanySeq
                                                              AND UMinrClss.MinorSeq = CustClass.UMCustClass
    WHERE a.BizUnit = 1 -- 레미콘 사업부만
    and CS.InvoiceSeq is null
    -- and a.InvoiceSeq not in ( select isnull(InvoiceSeq,0) from hencom_TIFProdWorkReportCloseSum where companyseq = a.CompanySeq )                  
    and a.IsDelvCfm = '1'               
    AND ISNULL(UO.SetPrice,0) <> 1011590002  --출고구분의 추가정보에 단가구분이 0이 아닌것만 조회.
