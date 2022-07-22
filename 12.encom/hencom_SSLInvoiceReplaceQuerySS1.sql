IF OBJECT_ID('hencom_SSLInvoiceReplaceQuerySS1') IS NOT NULL 
    DROP PROC hencom_SSLInvoiceReplaceQuerySS1
GO 

-- v2017.02.10

/************************************************************                            
      설  명 - 데이터-송장규격대체_hencom : 조회1                            
      작성일 - 20151204                            
      작성자 - 박수영                            
      수정자 -       
      선매출처리를 위한 부분 추가by박수영 2016.03.07   
      선매출등록여부 조회조건추가 by박수영 2016.11.25                    
************************************************************/                                     
CREATE PROC dbo.hencom_SSLInvoiceReplaceQuerySS1
         @xmlDocument   NVARCHAR(MAX) ,                                        
         @xmlFlags      INT = 0,                                        
         @ServiceSeq    INT = 0,                                        
         @WorkingTag    NVARCHAR(10)= '',                                              
         @CompanySeq    INT = 1,                                        
         @LanguageSeq   INT = 1,                                        
         @UserSeq       INT = 0,                                        
         @PgmSeq        INT = 0                                   
                                 
     AS                                    
                                     
         DECLARE @docHandle          INT,                            
                 @WorkDateFr         NCHAR(8) ,                            
                 @WorkDateTo         NCHAR(8) ,                           
                 @CustSeq            INT ,                            
                 @PJTSeq             INT ,                            
                 @DeptSeq            INT,                        
                 @IsReplace          NCHAR(1),                        
                 @GoodItemSeq        INT ,        
                 @IsBill             NCHAR(1),        
                 @AssetSeq           INT ,        
                 @BillDateFr         NCHAR(8)  ,        
                 @BillDateTo         NCHAR(8) ,
                 @IsPreSales         NCHAR(1),
				 @UMCustClass        INT
          EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                         
                                 
         SELECT @WorkDateFr         = WorkDateFr         ,                            
                 @WorkDateTo        = WorkDateTo         ,                            
                 @CustSeq           = CustSeq            ,                            
                 @PJTSeq            = PJTSeq             ,                          
                 @DeptSeq           = DeptSeq            ,                        
                 @IsReplace         = ISNULL(IsReplace,''),                        
                 @GoodItemSeq       = GoodItemSeq,        
                 @IsBill            = IsBill,        
                 @AssetSeq          = ISNULL(AssetSeq,0),         
                 @BillDateFr        = ISNULL(BillDateFr,''),         
                 @BillDateTo        = ISNULL(BillDateTo,''),
                 @IsPreSales        = ISNULL(IsPreSales,''),
				 @UMCustClass       = ISNULL(UMCustClass,0)
           FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                            
           WITH (WorkDateFr         NCHAR(8) ,                            
                 WorkDateTo         NCHAR(8) ,                            
                 CustSeq            INT ,                            
                 PJTSeq             INT ,                            
                 DeptSeq            INT ,                        
                 IsReplace          NCHAR(1),                        
                 GoodItemSeq        INT,        
                 IsBill             NCHAR(1),        
                 AssetSeq           INT ,        
                 BillDateFr         NCHAR(8)  ,        
                 BillDateTo         NCHAR(8) ,
                 IsPreSales         NCHAR(1),
				 UMCustClass        INT
                 )                             
                         
      /*        
         SELECT  --B.IsReplace ,                   
             (SELECT  MAX(IsReplace)                
                     FROM hencom_TSLCloseSumReplaceMapping                  
          WHERE CompanySeq = @CompanySeq                 
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
                 D.InvoiceDate ,                     
                 D.ItemSeq ,                    
                 D.Qty ,                    
                 D.Price ,                    
                 D.CurAmt ,                    
                 D.CurVAT ,                    
                 D.CurAmt + D.CurVAT AS TotAmt,                    
                 D.IsInclusedVAT ,                    
                 D.CustSeq ,                    
                 E.CustName ,                    
                 ISNULL((SELECT PJTName FROM _TPJTProject WHERE PJTSeq = D.PJTSeq AND CompanySeq = @CompanySeq), '')  AS PJTName,                    
                 T.ItemName AS GoodItemName,                    
                 RC.DeptSeq ,                  
                 (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = RC.DeptSeq ) AS DeptName,                    
      D.LastUserSeq ,                    
                   D.LastDateTime ,                    
       --            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = RC.UMOutType ) AS UMOutTypeName, --출하구분                    
                 NULL            AS InvoiceSeq,                  
                 NULL            AS SalesSeq,                  
                 ''              AS SumMesKey ,              
                 D.CurAmt - ISNULL(BS.ProcCurAmt,0) AS BalCurAmt,              
                 D.CurVAT - ISNULL(BS.ProcCurVAT,0) AS BalCurVAT,              
     --            D.DomAmt - ISNULL(BS.ProcDomAmt,0) AS BalDomAmt,              
     --            D.DomVAT - ISNULL(BS.ProcDomVat,0) AS BalDomVAT              
                 CASE WHEN BS.ReplaceRegSeq > 0 THEN '1' ELSE '0' END AS IsBill ,          
                 CF.CfmCode AS CfmCode , --대체확정여부          
                 E.BizNo AS BizNo --사업자번호          
         INTO #TMPData                     
         FROM hencom_TSLInvoiceReplace AS C WITH(NOLOCK)                    
           LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS D  WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.ReplaceRegSeq = C.ReplaceRegSeq                    
     --    LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS B WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq                     
     --                                                                    AND B.ReplaceRegSeq = D.ReplaceRegSeq                     
     --                                                                    AND B.ReplaceRegSerl = D.ReplaceRegSerl                     
         LEFT OUTER JOIN (  SELECT  ReplaceRegSeq,                
                         MAX(SumMesKey) AS SumMesKey --사업소 조회하기 위해 추가                  
                 FROM hencom_TSLCloseSumReplaceMapping                  
                 WHERE CompanySeq = @CompanySeq                  
                 GROUP BY ReplaceRegSeq                
                 ) AS B ON  B.ReplaceRegSeq = D.ReplaceRegSeq                  
     --                AND B.ReplaceRegSerl = D.ReplaceRegSerl                     
         LEFT OUTER  JOIN _TDACust AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND E.CustSeq = D.CustSeq                    
         LEFT OUTER JOIN _TDAItem AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq AND T.ItemSeq = D.ItemSeq                    
           LEFT OUTER JOIN hencom_TIFProdWorkReportCloseSum AS RC WITH(NOLOCK) ON RC.CompanySeq = @CompanySeq AND RC.SumMesKey = B.SumMesKey                     
         LEFT OUTER JOIN( SELECT ReplaceRegSeq,              
                                 ReplaceRegSerl,              
                          SUM(ISNULL(ReplaceCurAmt,0)) AS ProcCurAmt ,              
      SUM(ISNULL(ReplaceCurVAT,0)) AS ProcCurVAT ,              
                                 SUM(ISNULL(ReplaceDomAmt,0)) AS ProcDomAmt ,              
                                  SUM(ISNULL(ReplaceDomVat,0)) AS ProcDomVat               
                         FROM hemcom_TSLBillReplaceRelation              
                         WHERE CompanySeq = @CompanySeq               
                         GROUP BY ReplaceRegSeq, ReplaceRegSerl              
                           ) AS BS ON BS.ReplaceRegSeq = D.ReplaceRegSeq AND BS.ReplaceRegSerl = D.ReplaceRegSerl             
         LEFT OUTER JOIN hencom_TSLInvoiceReplace_Confirm AS CF ON CF.CompanySeq = C.CompanySeq AND CF.CfmSeq = C.ReplaceRegSeq          
         WHERE C.CompanySeq = @CompanySeq                            
         AND D.InvoiceDate BETWEEN CASE WHEN @WorkDateFr = '' THEN C.BillDate ELSE @WorkDateFr END                          
                     AND CASE WHEN @WorkDateTo = '' THEN D.InvoiceDate ELSE @WorkDateTo END                          
         AND (@CustSeq = 0 OR D.CustSeq = @CustSeq )                            
         AND (@PJTSeq  = 0 OR D.PJTSeq  = @PJTSeq  )                            
         AND (@DeptSeq = 0 OR RC.DeptSeq = @DeptSeq )                     
                        
         UNION ALL                    
                             
         SELECT '0'          AS IsReplace ,                    
      --    0 as t,                
                 NULL        AS ReplaceRegSeq,                    
                 NULL        AS ReplaceRegSerl,                    
                 V.CurrSeq   AS CurrSeq,                    
                 V.ExRate    AS ExRate,                    
       V.Remark,                    
                 A.PJTSeq ,                    
                 A.WorkDate AS InvoiceDate,                    
          A.GoodItemSeq AS ItemSeq,                    
                 A.OutQty ,                    
                   A.Price ,                     
                 A.CurAmt ,                    
                 A.CurVAT ,                    
                 A.CurAmt + A.CurVAT AS TotAmt,                    
                 A.IsInclusedVAT ,                    
                 A.CustSeq ,                    
                 (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName ,                    
                 ISNULL((SELECT PJTName FROM _TPJTProject WHERE PJTSeq = A.PJTSeq AND CompanySeq = @CompanySeq), '')  AS PJTName,                    
                   T.ItemName AS GoodItemName,                    
                 A.DeptSeq ,                    
                 (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName,                    
                 A.LastUserSeq ,                    
                 A.LastDateTime,                    
       --            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMOutType ) AS UMOutTypeName, --출하구분                    
                 A.InvoiceSeq    AS InvoiceSeq,                  
                 A.SalesSeq      AS SalesSeq,                  
 A.SumMesKey     AS SumMesKey ,              
                 A.CurAmt - ISNULL(J.CurAmt,0) AS BalCurAmt,              
        A.CurVAT - ISNULL(J.CurVAT,0) AS BalCurVAT,              
                 CASE WHEN J.SalesSeq > 0 THEN '1' ELSE '0' END AS IsBill   ,          
                 '0' AS CfmCode ,--대체확정여부           
                 E.BizNo AS BizNo --사업자번호          
         FROM hencom_TIFProdWorkReportCloseSum     AS A                     
    LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS MP WITH(NOLOCK) ON MP.CompanySeq = @CompanySeq                     
                                                                         AND MP.SumMesKey = A.SumMesKey                      
           LEFT OUTER JOIN _TSLInvoice AS V WITH(NOLOCK) ON V.CompanySeq = @CompanySeq                      
                                                     AND V.InvoiceSeq = A.InvoiceSeq                      
         LEFT OUTER JOIN _TDAItem AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq                     
                                                 AND T.ItemSeq = A.GoodItemSeq                 
     -----------------------------------------------------              
         LEFT OUTER JOIN (SELECT Y.SalesSeq, Y.SalesSerl,                 
                                   SUM(Y.CurAmt) AS CurAmt, SUM(Y.CurVAT) AS CurVAT,                 
                                 SUM(Y.DomAmt) AS DomAmt, SUM(Y.DomVAT) AS DomVAT                 
                         FROM  _TSLSalesBillRelation AS Y WITH(NOLOCK)               
                         WHERE Y.CompanySeq = @CompanySeq               
                        GROUP BY Y.SalesSeq, Y.SalesSerl) AS J ON A.SalesSeq  = J.SalesSeq                
                                                            AND J.SalesSerl = 1                
     --------------------------------------------------                 
         LEFT OUTER JOIN _TDACust AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq          
                   
       WHERE A.CompanySeq = @CompanySeq                            
       AND ISNULL(MP.SumMesKey,'') = ''                    
    AND A.WorkDate BETWEEN CASE WHEN @WorkDateFr = '' THEN A.WorkDate ELSE @WorkDateFr END                          
                     AND CASE WHEN @WorkDateTo = '' THEN A.WorkDate ELSE @WorkDateTo END                          
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq )                            
       AND (@PJTSeq  = 0 OR A.PJTSeq  = @PJTSeq  )                            
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )                
       AND A.CfmCode = '1'    --확정건만 조회               
     */          
     --    SELECT * FROM #TMPData           
     -- WHERE ((@IsReplace = '' OR @IsReplace = '2') OR @IsReplace = IsReplace )         
              
         SELECT     
                CASE WHEN ISNULL(PSM.FromSeq,0) <> 0 THEN 0 ELSE A.BalCurAmt END AS BalCurAmt , --A에 컬럼이 있지만 그냥 사용함.by박수영 2016.03.29    
                CASE WHEN ISNULL(PSM.FromSeq,0) <> 0 THEN 0 ELSE A.BalCurVAT END AS BalCurVAT , --A에 컬럼이 있지만 그냥 사용함.by박수영 2016.03.29    
                A.*,         
                A.ItemSeq AS GoodItemSeq, 
         --------------------------------------    
                A.WorkDate          AS InvoiceDate ,        
                PJTADD.UMPayType    AS UMPayType , --결제유형(현장추가정보화면)        
                PJTADD.ClaimPeriod  AS ClaimPeriod ,--청구기간(현장추가정보화면)        
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = PJTADD.UMPayType) AS UMPayTypeName ,        
                IT.AssetSeq ,--품목자산분류코드        
                IA.AssetName , --품목자산분류        
                BL.BillDate   AS BillDate, --세금계산서일자        
                BL.BillNo     AS BillNo, --세금계산서번호    
                -----선매출및관급배정관련 필드    
                PSM.PreSMSeq ,    
                PSM.FromTableSeq ,    
                PSM.FromSeq ,    
            PSM.FromSerl ,    
                PSM.ToTableSeq ,    
                --PSM.ToSeq ,    
                --PSM.ToSerl ,    
                VPS.FromPgmName,    
                PSM.PPSRegSeq,    
                PPS.PublicSalesNo
         FROM hencom_VInvoiceReplaceItem    AS A  WITH(NOLOCK)         
         LEFT OUTER JOIN hencom_TDADeptAdd AS AD WITH(NOLOCK) ON AD.CompanySeq = @CompanySeq AND AD.DeptSeq = A.DeptSeq         
           LEFT OUTER JOIN hencom_TPJTProjectAdd AS PJTADD WITH(NOLOCK) ON PJTADD.CompanySeq = @CompanySeq AND PJTADD.PJTSeq = A.PJTSeq        
         LEFT OUTER JOIN _TDAItem AS IT WITH(NOLOCK) ON IT.CompanySeq = A.CompanySeq AND IT.ItemSeq = A.ItemSeq        
         LEFT OUTER JOIN _TDAItemAsset AS IA WITH(NOLOCK) ON IA.CompanySeq = IT.CompanySeq AND IA.AssetSeq = IT.AssetSeq        
         LEFT OUTER JOIN _TSLBill AS BL WITH(NOLOCK) ON BL.CompanySeq = @CompanySeq AND BL.BillSeq = A.BillSeq     
           LEFT OUTER JOIN hencom_TSLPreSalesMapping AS PSM WITH(NOLOCK) ON PSM.ToTableSeq = A.SourceTableSeq     
                                                                     AND PSM.ToSeq =     
                                                                         (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSeq     
                                                                         WHEN 1000057 THEN A.SumMesKey    
                                                                         WHEN 1000075 THEN A.ReplaceRegSeq    
                                                                         END  )    
                                                                     AND PSM.ToSerl =     
                                                                    (CASE A.SourceTableSeq WHEN 1268 THEN A.InvoiceSerl     
                                                                         WHEN 1000057 THEN 0    
                                                                         WHEN 1000075 THEN A.ReplaceRegSerl    
                                        END  )
         LEFT OUTER JOIN hencom_ViewPreSalesSource AS VPS ON VPS.FromTableSeq = PSM.FromTableSeq     
                                                         AND VPS.FromSeq = PSM.FromSeq     
                                                         AND VPS.FromSerl = PSM.FromSerl    
         LEFT OUTER JOIN hencom_TSLPrePublicSales AS PPS WITH(NOLOCK) ON PPS.CompanySeq = @CompanySeq AND PPS.PPSRegSeq = PSM.PPSRegSeq    
         WHERE A.CompanySeq = @CompanySeq                                       
         AND A.WorkDate BETWEEN CASE WHEN @WorkDateFr = '' THEN A.WorkDate ELSE @WorkDateFr END                          
                 AND CASE WHEN @WorkDateTo = '' THEN A.WorkDate ELSE @WorkDateTo END                          
         AND (@CustSeq = 0 OR A.CustSeq = @CustSeq )                            
         AND (@PJTSeq  = 0 OR A.PJTSeq  = @PJTSeq  )                            
         AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )                
         AND A.CloseCfmCode = '1'    --확정건만 조회          
         AND ((@IsReplace = '' OR @IsReplace = '2') OR @IsReplace = IsReplace )         
--         AND ((@IsBill = '' OR  @IsBill = '2') OR @IsBill = IsBill) --세금계산서청구여부       
        --세금계산서청구여부 : 선매출연결된 것도 청구된 것으로 인식.by박수영2016.05.16  
         AND ((@IsBill = '' OR  @IsBill = '2') OR @IsBill = (CASE WHEN A.IsBill = '1' OR ISNULL(PSM.FromSeq,0) <> 0 THEN '1' ELSE A.IsBill END) )   
         AND (@AssetSeq = 0 OR IT.AssetSeq = @AssetSeq)        
         AND ((@BillDateFr <> '' OR @BillDateTo <> '' ) AND BL.BillDate BETWEEN CASE WHEN @BillDateFr = '' THEN BL.BillDate ELSE @BillDateFr END          
                         AND CASE WHEN @BillDateTo = '' THEN BL.BillDate ELSE @BillDateTo END          
             OR (@BillDateFr = '' AND @BillDateTo = '' )        
     )        
        AND ((@IsPreSales = '' OR @IsPreSales = '2') OR A.IsPreSales = @IsPreSales ) --선매출여부 조회조건 : 공백 ='' 또는 전체 ='2', 선매출='1', 일반='0'
		AND (@UMCustClass = 0 OR A.UMCustClass = @UMCustClass ) 
         ORDER BY AD.DispSeq ,A.WorkDate DESC  ,A.CustSeq ,A.PJTSeq,A.ItemSeq             
          /*대체여부 조회조건 공백 ='' 또는 전체 ='2', 대체='1', 미대체='0' */       
                               
RETURN
