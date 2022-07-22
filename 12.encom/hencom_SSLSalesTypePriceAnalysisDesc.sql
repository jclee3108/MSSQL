IF OBJECT_ID('hencom_SSLSalesTypePriceAnalysisDesc') IS NOT NULL 
    DROP PROC hencom_SSLSalesTypePriceAnalysisDesc 
GO 

-- v2017.03.23 
/************************************************************            
    설  명 - 데이터-매출유형별단가분석(상세)_hencom : 조회            
    작성일 - 20160419         
    작성자 - 박수영         
   ************************************************************/
   CREATE PROC dbo.hencom_SSLSalesTypePriceAnalysisDesc
    @xmlDocument   NVARCHAR(MAX) ,                        
    @xmlFlags      INT  = 0,                        
    @ServiceSeq    INT  = 0,                        
    @WorkingTag    NVARCHAR(10)= '',                              
    @CompanySeq    INT  = 1,                        
    @LanguageSeq   INT  = 1,                        
    @UserSeq       INT  = 0,                        
    @PgmSeq        INT  = 0                     
                   
   AS                    
                
    DECLARE @docHandle      INT,            
            @DeptSeq        INT ,            
            @StdYM          NCHAR(8) ,            
            @StdSaleType    INT,        
            @CurPriceLen    INT,      
            @StdYMTo        NCHAR(8) ,  
            @ItemName       NVARCHAR(100) ,
            @CustSeq        INT, 
            @PJTSeq         INT, 
            @UMChannelSeq   INT 
            --@AssetSeq          INT         
                
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                         
               
       SELECT  @DeptSeq         = ISNULL(DeptSeq       ,0),        
               @StdYM           = ISNULL(StdYM         ,''),        
               @StdSaleType     = ISNULL(StdSaleType   ,0),      
               @StdYMTo         = ISNULL(StdYMTo       ,''),
               @ItemName        = ISNULL(ItemName      ,''),
               @CustSeq         = ISNULL(CustSeq       ,0),
               @PJTSeq          = ISNULL(PJTSeq        ,0),
               @UMChannelSeq    = ISNULL(UMChannelSeq  ,0)
 --              @AssetSeq      = AssetSeq      
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)            
       WITH ( 
                DeptSeq        INT ,           
                StdYM          NCHAR(8) ,      
                StdSaleType    INT,        
                StdYMTo        NCHAR(8) ,  
                ItemName       NVARCHAR(100) ,
                CustSeq        INT, 
                PJTSeq         INT, 
                UMChannelSeq   INT 
            )            
    
    /*0나누기 에러 경고 처리*/                    
       SET ANSI_WARNINGS OFF                    
       SET ARITHIGNORE ON                    
       SET ARITHABORT OFF              
               
        EXEC dbo._SCOMEnv @CompanySeq,10, @UserSeq,@@PROCID,@CurPriceLen OUTPUT   -- 외화 단가소숫점 자릿수        
            
   -- select @CurPriceLen        
   -- return        
            
       CREATE TABLE #TmpTitle                       
       (                                
           ColIDX       INT IDENTITY(0,1),             
           Title         NVARCHAR(100)  ,                          
           TitleSeq      INT      ,                                    
           Sort          INT                      
       )                          
       INSERT #TmpTitle (Title,TitleSeq,Sort)            
       SELECT  A.MinorName       ,            
               A.MinorSeq        ,            
               A.MinorSort               
       FROM _TDAUMinor AS A WITH(NOLOCK)          
       LEFT OUTER JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq           
                                           AND B.MajorSeq = A.MajorSeq           
                                           AND B.MinorSeq = A.MinorSeq           
                                           AND B.Serl = 1000001          
       WHERE A.CompanySeq = @CompanySeq            
       AND A.MajorSeq = 8004            
       AND B.ValueText = '1' 
       AND ( @UMChannelSeq = 0 OR A.MinorSeq = @UMChannelSeq ) 
             
       CREATE TABLE #TmpTitleColumn                
       (                
            TitleSeq2     INT,                
            Title2    NVARCHAR(100)                
  )                
             
       INSERT #TmpTitleColumn                
       SELECT 1, '금액'                  
       INSERT #TmpTitleColumn                
       SELECT 2, '수량'                 
       INSERT #TmpTitleColumn                
       SELECT 3, '단가'         
         
      CREATE TABLE #TmpTitleRst                            
       (                                 
           ColIDX       INT IDENTITY(0,1)  ,                              
           Title        NVARCHAR(100)   ,                        
             TitleSeq     NVARCHAR(100)     ,                 
           Title2        NVARCHAR(100)   ,                        
           TitleSeq2     NVARCHAR(100)                    
               
       )             
       INSERT #TmpTitleRst(Title,TitleSeq,Title2,TitleSeq2)           
       SELECT A.Title,A.TitleSeq,B.Title2,B.TitleSeq2          
       FROM #TmpTitle AS A          
     JOIN #TmpTitleColumn AS B ON 1=1          
       ORDER BY A.Sort ,A.TitleSeq ,B.TitleSeq2              
          
                 
       SELECT * FROM #TmpTitleRst      
  --     return             
               
       CREATE TABLE #TMPRowData             
       (             
           DeptSeq     INT,            
           UMCustClass INT, --유통구조(매출유형)            
           Qty         DECIMAL(19,5),            
           DomAmt      DECIMAL(19,5),            
           DomVAT      DECIMAL(19,5) ,        
           Price       DECIMAL(19,5) ,        
           DataCnt     INT  ,      
           ItemSeq       INT,
           CustSeq       INT,
           PJTSeq        INT           
       )            
                   
      /*        
      IF @StdSaleType = 1011915001 --실적적기준:  거래명세서            
       BEGIN            
       --사업소,유통구조별 합산            
           INSERT #TMPRowData (DeptSeq,UMCustClass,Qty,DomAmt,DomVAT,Price,DataCnt)            
           SELECT  A.DeptSeq , C.UMCustClass,            
                   SUM(ISNULL(B.Qty,0)) AS Qty,            
                   SUM(ISNULL(B.DomAmt,0)) AS DomAmt,            
                   SUM(ISNuLL(B.DomVAT,0)) AS DomVAT,        
                   SUM(ISNULL(CONVERT(DECIMAL(19, 5),CASE WHEN B.Price IS NOT NULL        
                    THEN B.Price        
                    ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0))                   
                                                                 ELSE (ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END),0)) AS Price,   --판매단가          
                   COUNT(B.InvoiceSerl) AS DataCnt            
           FROM _TSLInvoice AS A            
           LEFT OUTER JOIN _TSLInvoiceItem AS B ON B.CompanySeq = A.CompanySeq AND B.InvoiceSeq = A.InvoiceSeq            
          LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq             
                                                       AND C.CustSeq = A.CustSeq             
                                                       AND C.UMajorCustClass = 8004            
           WHERE A.CompanySeq = @CompanySeq             
           AND LEFT(A.InvoiceDate,6) = @StdYM            
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)            
           GROUP BY A.DeptSeq,C.UMCustClass            
       END            
       */        
       IF @StdSaleType = 1011915001 --실적적기준:  mes데이터집계처리, 거래명세서직접입력,대체등록 통합으로 조회한다.        
       BEGIN            
       --사업소,유통구조별 합산            
           INSERT #TMPRowData (DeptSeq,UMCustClass,Qty,DomAmt,DomVAT,Price,DataCnt,ItemSeq,CustSeq,PJTSeq)            
           SELECT  B.DeptSeq , C.UMCustClass,            
                   SUM(ISNULL(B.Qty,0)) AS Qty,            
                   SUM(ISNULL(B.CurAmt,0))  AS DomAmt,            
                SUM(ISNuLL(B.CurVAT,0)) AS DomVAT,        
                   SUM(ISNULL(CONVERT(DECIMAL(19, 5),CASE WHEN B.Price IS NOT NULL        
    THEN B.Price        
                    ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0))                   
                                                               ELSE (ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END),0)) AS Price,   --판매단가          
                   COUNT(1) AS DataCnt ,      
                  B.ItemSeq,
                  B.CustSeq,
                  B.PJTSeq
           FROM hencom_VInvoiceReplaceItem AS B WITH(NOLOCK)            
          LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = B.ItemSeq       
            LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq             
                                                       AND C.CustSeq = B.CustSeq             
                                                       AND C.UMajorCustClass = 8004            
             WHERE B.CompanySeq = @CompanySeq             
           AND B.WorkDate BETWEEN @StdYM  AND @StdYMTo          
           AND (@DeptSeq = 0 OR B.DeptSeq = @DeptSeq)        
 --          AND (@AssetSeq = 0 OR I.AssetSeq = @AssetSeq )         
           AND EXISTS (SELECT 1 FROM #TmpTitle WHERE TitleSeq = C.UMCustClass) --해당하는 유통구조만 포함.      
             --AND B.CloseCfmCode = '1'    --확정건만 조회:매출자료생성조회와 동일     
             AND (@ItemName = '' OR I.ItemName LIKE @ItemName +'%')
             AND (@CustSeq = 0 OR @CustSeq = B.CustSeq )
             AND (@PJTSeq = 0 OR @PJTSeq = B.PJTSeq )
			 AND isNull(B.IsPreSales, '0') = '0'
             AND ( @UMChannelSeq = 0 OR C.UMCustClass = @UMChannelSeq ) 
           GROUP BY B.DeptSeq,C.UMCustClass,B.ItemSeq,B.CustSeq,B.PJTSeq 
       END         
               
            
  -- select * from #TMPRowData        
  /*      
       IF @StdSaleType = 1011915002 --실적적기준:  세금계산서            
       BEGIN            
       --사업소,유통구조별 합산            
           INSERT #TMPRowData (DeptSeq,UMCustClass,Qty,DomAmt,DomVAT,Price,DataCnt)            
           SELECT  A.DeptSeq , C.UMCustClass,            
                   SUM(ISNULL(B.Qty,0)) AS Qty,            
                   SUM(ISNULL(B.DomAmt,0)) AS DomAmt,            
                   SUM(ISNULL(B.DomVAT,0)) AS DomVAT,        
                   SUM(ISNULL(B.Price,0))    ,        
                   COUNT(B.BillSerl) AS DataCnt        
           FROM _TSLBill AS A            
             LEFT OUTER JOIN _TSLBillItem AS B ON B.CompanySeq = B.CompanySeq AND B.BillSeq = A.BillSeq            
           LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq             
                                                       AND C.CustSeq = A.CustSeq             
                                                       AND C.UMajorCustClass = 8004          
          LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = B.ItemSeq         
           WHERE A.CompanySeq = @CompanySeq             
           AND LEFT(A.BillDate,6) = @StdYM            
           AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)            
           GROUP BY A.DeptSeq,C.UMCustClass            
       END            
  */      
      CREATE TABLE #TMPSalesData      
      (      
          DeptSeq     INT ,      
          CustSeq     INT ,      
          BillSeq     INT ,      
          ItemSeq     INT ,      
          CurAmt      DECIMAL(19,5),      
          CurVAT      DECIMAL(19,5),      
          Qty         DECIMAL(19,5),      
          Price      DECIMAL(19,5),      
          IsRep       NCHAR(1) ,
          PJTSeq         INT     
      )      
  ----------------------------------------------------------------------      
      IF @StdSaleType = 1011915002 --실적적기준:  세금계산서            
  BEGIN        
      /*
          INSERT #TMPSalesData(DeptSeq,CustSeq,BillSeq,ItemSeq,CurAmt,CurVAT,Qty,Price,IsRep,PJTSeq)      
          --규격대체를 제외한 세금계산서와 매출관계      
          SELECT  MA.DeptSeq ,      
                  MA.CustSeq,      
                  MA.BillSeq,      
                  MS.ItemSeq,      
                  MB.CurAmt ,      
                  MB.CurVAT ,
                  MS.Qty ,      
                  CASE WHEN ISNULL(MS.ItemPrice,0) = 0 THEN (ISNULL(MB.CurAmt,0) + ISNULL(MB.CurVAT,0))/ MS.Qty ELSE MS.ItemPrice END ,      
                  '0'      ,
                  MS.PJTSeq
          FROM _TSLBill AS MA WITH(NOLOCK)     
          JOIN _TSLSalesBillRelation AS MB WITH(NOLOCK) ON MB.CompanySeq = MA.CompanySeq AND MB.BillSeq = MA.BillSeq      
          LEFT OUTER JOIN _TSLSalesItem AS MS WITH(NOLOCK) ON MS.CompanySeq = MA.CompanySeq AND MS.SalesSeq = MB.SalesSeq AND MS.SalesSerl = MS.SalesSerl      
          LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = MS.ItemSeq       
          
          WHERE MA.CompanySeq = @CompanySeq      
          AND NOT EXISTS (SELECT 1 --규격대체로 청구된 매출을 찾아 제외함. 아래부분에서 추가하고 있음.      
                          FROM _TSLBill AS A      
                            LEFT OUTER JOIN hemcom_TSLBillReplaceRelation AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.BillSeq = A.BillSeq      
                          LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySEq       
                                                                              AND C.ReplaceRegSeq = B.ReplaceRegSeq      
                                                                              AND C.ReplaceRegSerl = B.ReplaceRegSerl      
                            LEFT OUTER JOIN hencom_TIFProdWorkReportCloseSum AS S WITH(NOLOCK) ON S.CompanySeq = C.CompanySeq AND S.SumMesKey = C.SumMesKey      
                          where A.CompanySeq = @CompanySeq       
                          AND A.Billseq = MA.Billseq AND S.SalesSeq =  MB.SalesSeq       
                          )      
          AND LEFT(MA.BillDate,6) BETWEEN @StdYM AND @StdYMTo          
          AND (@DeptSeq = 0 OR MA.DeptSeq = @DeptSeq)        
 --           AND (@AssetSeq = 0 OR I.AssetSeq = @AssetSeq   )
         AND (@ItemName = '' OR I.ItemName LIKE @ItemName +'%')
         AND (@CustSeq = 0 OR @CustSeq = MA.CustSeq )
         AND (@PJTSeq = 0 OR @PJTSeq = MS.PJTSeq )          
         
          --규격대체로 생성된 관계      
          INSERT #TMPSalesData(DeptSeq,CustSeq,BillSeq,ItemSeq,CurAmt,CurVAT,Qty,Price,IsRep,PJTSeq)      
          SELECT  A.DeptSeq,      
                  A.CustSeq,      
                  A.BillSeq,      
                  R.ItemSeq,      
                  B.ReplaceCurAmt ,      
                  B.ReplaceCurVAT ,      
                  R.Qty,      
                  CASE WHEN ISNULL(R.Price,0) = 0 THEN (ISNULL(B.ReplaceCurAmt,0) + ISNULL(B.ReplaceCurVAT,0) )/R.Qty ELSE R.Price END,      
                  '1'      ,
                  R.PJTSeq
          FROM _TSLBill AS A WITH(NOLOCK)      
          JOIN hemcom_TSLBillReplaceRelation AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq       
                                                  AND B.BillSeq = A.BillSeq      
          LEFT OUTER JOIN hencom_TSLInvoiceReplaceItem AS R WITH(NOLOCK) ON R.CompanySeq = A.CompanySeq       
                                                          AND R.ReplaceRegSeq = B.ReplaceRegSeq       
                                                   AND R.ReplaceRegSerl = B.ReplaceRegSerl      
           LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq             
                                                       AND C.CustSeq = A.CustSeq             
    AND C.UMajorCustClass = 8004      
          LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = R.ItemSeq       
          WHERE A.CompanySeq = @CompanySeq      
          AND LEFT(A.BillDate,6) BETWEEN @StdYM AND @StdYMTo      
          AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)         
         AND (@ItemName = '' OR I.ItemName LIKE @ItemName +'%')
         AND (@CustSeq = 0 OR @CustSeq = A.CustSeq )
         AND (@PJTSeq = 0 OR @PJTSeq = R.PJTSeq )          
    */
          INSERT #TMPSalesData(DeptSeq,CustSeq,BillSeq,ItemSeq,CurAmt,CurVAT,Qty,Price,PJTSeq)  
           SELECT  B.DeptSeq , 
                   B.CustSeq ,         
                   B.BillSeq ,
                   B.ItemSeq ,             
                   ISNULL(B.BillAmt,0),            
                   ISNuLL(B.BillVAT,0) ,   
                   ISNULL(B.Qty,0) AS Qty,       
                   ISNULL(CONVERT(DECIMAL(19, 5),CASE WHEN B.Price IS NOT NULL        
                    THEN B.Price        
                    ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.BillAmt,0) + ISNULL(B.BillVAT,0)) / ISNULL(B.Qty,0))                   
                                                               ELSE (ISNULL(B.BillAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END),0) AS Price,   --판매단가   
                    B.PJTSeq       
    
           FROM hencom_VInvoiceReplaceItem AS B WITH(NOLOCK)              
          LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = B.ItemSeq       
          LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq             
                                                       AND C.CustSeq = B.CustSeq             
                                                       AND C.UMajorCustClass = 8004      
            LEFT OUTER JOIN _TSLBill AS BL WITH(NOLOCK) ON BL.CompanySeq = @CompanySeq AND BL.BillSeq = B.BillSeq       
           WHERE B.CompanySeq = @CompanySeq          
           AND B.IsBill = '1'   --세금계산서발행된 것만 조회.
           AND BL.BillDate BETWEEN @StdYM  AND @StdYMTo          
           AND (@DeptSeq = 0 OR B.DeptSeq = @DeptSeq)        
--           AND (@AssetSeq = 0 OR I.AssetSeq = @AssetSeq )         
           AND EXISTS (SELECT 1 FROM #TmpTitle WHERE TitleSeq = C.UMCustClass) --해당하는 유통구조만 포함.   
            AND (@ItemName = '' OR I.ItemName LIKE @ItemName +'%')
            AND (@CustSeq = 0 OR @CustSeq = B.CustSeq )
            AND (@PJTSeq = 0 OR @PJTSeq = B.PJTSeq ) 
			AND isNull(B.IsPreSales, '0') = '0'
            AND ( @UMChannelSeq = 0 OR C.UMCustClass = @UMChannelSeq ) 
           
          INSERT  #TMPRowData (DeptSeq,UMCustClass,Qty,DomAmt,DomVAT,Price,DataCnt,ItemSeq,CustSeq,PJTSeq)       
          SELECT  A.DeptSeq ,       
                  C.UMCustClass,            
                  SUM(ISNULL(A.Qty,0)),            
                  SUM(ISNULL(A.CurAmt,0)),            
                  SUM(ISNULL(A.CurVAT,0)) ,        
                  SUM(ISNULL(A.Price,0)) ,        
                  COUNT(1) AS DataCnt ,       
                  A.ItemSeq,
                  A.CustSeq,
                  A.PJTSeq    
          FROM #TMPSalesData AS A      
          LEFT OUTER JOIN _TDACustClass AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq             
                                                       AND C.CustSeq = A.CustSeq             
                                                       AND C.UMajorCustClass = 8004          
          LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq  = A.ItemSeq        
          WHERE EXISTS (SELECT 1 FROM #TmpTitle WHERE TitleSeq = C.UMCustClass) --해당하는 유통구조만 포함.      
          GROUP BY A.DeptSeq,C.UMCustClass,A.ItemSeq,A.CustSeq,A.PJTSeq 
      END      
            
         
  ----------------------------------------------------------------------      
  --전체합계 추가      
     INSERT #TMPRowData (DeptSeq,UMCustClass,Qty,DomAmt,DomVAT,Price,DataCnt,ItemSeq,CustSeq,PJTSeq)       
       SELECT -1,UMCustClass,SUM(ISNULL(Qty,0)),SUM(ISNULL(DomAmt,0)),SUM(ISNULL(DomVAT,0)),SUM(ISNULL(Price,0)),SUM(ISNULL(DataCnt,0)),-1,-1,-1      
     FROM #TMPRowData       
     GROUP BY UMCustClass      
           
 --    select '#TMPRowData',* from #TMPRowData return      
    --사업소별 합산            
     CREATE TABLE #TMPSumData             
     (            
         RowIDX      INT IDENTITY(0,1),            
         DeptSeq     INT,            
         ItemSeq     INT,
         CustSeq     INT,
         PJTSeq      INT,  
         UMCustClass INT, 
         SumQty      DECIMAL(19,5) ,            
         SumAmt      DECIMAL(19,5) ,        
         Price       DECIMAL(19,5) ,        
         DataCnt     INT            
     )            
             
      SELECT  A.DeptSeq, A.ItemSeq,A.CustSeq,A.PJTSeq,A.UMCustClass, 
              SUM(ISNULL(A.Qty,0)) AS SumQty ,                 
              SUM(ISNULL(A.DomAmt,0))  AS SumAmt   ,    
              SUM(ISNULL(A.Price,0))  AS Price,        
              SUM(ISNULL(A.DataCnt,0)) AS DataCnt      
       INTO #TMPSumDataTMP        
       FROM #TMPRowData  AS A           
       WHERE A.DeptSeq <> -1       
       GROUP BY A.DeptSeq ,A.ItemSeq,A.CustSeq,A.PJTSeq,A.UMCustClass     
               
     --합계데이터      
       INSERT #TMPSumData(DeptSeq,ItemSeq,CustSeq,PJTSeq,UMCustClass,SumQty,SumAmt,Price,DataCnt) 
       SELECT  -1,-1,-1,-1,-1, 
             SUM(ISNULL(A.SumQty,0)) ,            
             SUM(ISNULL(A.SumAmt,0)) AS SumAmt   ,           
             SUM(ISNULL(A.SumAmt,0)) / SUM(ISNULL(A.SumQty,0)),      
             SUM(ISNULL(A.DataCnt,0)) AS DataCnt        
       FROM #TMPSumDataTMP  AS A         
         
     --사업소관리(추가정보)와 연결.      
       INSERT #TMPSumData(DeptSeq,ItemSeq,CustSeq,PJTSeq,UMCustClass,SumQty,SumAmt,Price,DataCnt)
       SELECT  A.DeptSeq,              
               A.ItemSeq,
               A.CustSeq,
               A.PJTSeq  ,            
               A.UMCustClass, 
               ISNULL(A.SumQty,0) ,            
               ISNULL(A.SumAmt,0) AS SumAmt   ,        
               ISNULL(A.Price,0) AS Price,        
               ISNULL(A.DataCnt,0) AS DataCnt 
       FROM #TMPSumDataTMP  AS A         
       LEFT OUTER JOIN hencom_TDADeptAdd AS DDA WITH(NOLOCK) ON DDA.DeptSeq = A.DeptSeq          
       WHERE A.DeptSeq <> -1       
      ORDER BY DDA.DispSeq        
               
 --      select '#TMPSumData',* from #TMPSumData        
               
   --사업계획            
 --      CREATE TABLE #TMPBisPlan            
 --      (            
 --          DeptSeq     INT,          
 --          AssetSeq   INT,        
 --          Qty         DECIMAL(19,5),            
 --          BisPanAmt   DECIMAL(19,5)            
 --      )            
           
   --실행계획            
 --      CREATE TABLE #TMPActPlan            
 --      (            
 --          DeptSeq     INT,            
 --          AssetSeq   INT,      
 --          Qty         DECIMAL(19,5),            
 --          ActPanAmt   DECIMAL(19,5)            
 --      )            
         
                   
       SELECT A.RowIDX ,             
              A.DeptSeq ,            
             A.ItemSeq,
             A.CustSeq,
             A.PJTSeq,                     
             CASE WHEN A.DeptSeq = -1 THEN 'TOTAL' ELSE D.DeptName END AS DeptName ,               
             O.MinorName AS UMChannelName,          
              A.SumAmt AS SalesAmt , --매출금액      
              A.SumQty AS SalesQty, --매출수량            
             A.SumAmt / A.SumQty AS StdAvgPrice, --평균단가    
             I.ItemName,
             C.CustName,
             C.BizNo,
             P.PJTName
             
       FROM #TMPSumData AS A                    
       LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq    
       LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq
       LEFT OUTER JOIN _TDACust AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq
       LEFT OUTER JOIN _TPJTProject AS P WITH(NOLOCK) ON P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq
       LEFT OUTER JOIN _TDAUMinor   AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.MinorSeq = A.UMCustClass ) 
       ORDER BY A.RowIDX      
                   
                   
 --            select '#TMPRowData',* from #TMPRowData      
                   
       SELECT FIX.RowIDX,             
               T.ColIDX,             
  ISNULL(DYM.DomAmt,0)   AS Amt , --금액       
               DYM.Qty AS Qty, --수량,          
              ISNULL(DYM.DomAmt,0) / DYM.Qty  AS SaleTypePrice   --단가            
       FROM #TMPRowData AS DYM            
       JOIN #TmpTitle AS T ON T.TitleSeq = DYM.UMCustClass             
       JOIN #TMPSumData AS FIX ON FIX.DeptSeq = DYM.DeptSeq AND FIX.ItemSeq = DYM.ItemSeq AND FIX.CustSeq = DYM.CustSeq AND FIX.PJTSeq = DYM.PJTSeq        
       ORDER BY FIX.RowIDX  ,T.ColIDX         
  RETURN
  go
  begin tran 
exec hencom_SSLSalesTypePriceAnalysisDesc @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>20151201</StdYM>
    <CustSeq />
    <PJTSeq />
    <ItemName />
    <UMChannelSeq>8004001</UMChannelSeq>
    <StdYMTo>20151231</StdYMTo>
    <DeptSeq />
    <StdSaleType>1011915001</StdSaleType>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036539,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029951
rollback 