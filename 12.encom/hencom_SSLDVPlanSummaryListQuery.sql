IF OBJECT_ID('hencom_SSLDVPlanSummaryListQuery') IS NOT NULL 
    DROP PROC hencom_SSLDVPlanSummaryListQuery
GO 

-- v2017.03.23 
/************************************************************        
  설  명 - 데이터-출하예정총괄현황_hencom : 조회        
  작성일 - 20151215        
  작성자 - 박수영     
 ************************************************************/        
         
 CREATE PROC dbo.hencom_SSLDVPlanSummaryListQuery                        
  @xmlDocument    NVARCHAR(MAX) ,                    
  @xmlFlags     INT  = 0,                    
  @ServiceSeq     INT  = 0,                    
  @WorkingTag     NVARCHAR(10)= '',                          
  @CompanySeq     INT  = 1,                    
  @LanguageSeq  INT  = 1,                    
  @UserSeq      INT  = 0,                    
  @PgmSeq         INT  = 0                 
             
 AS                
          
     DECLARE @docHandle      INT,        
             @StdDate        NCHAR(8) ,        
             @DeptSeq        INT,        
             @LastDate       NCHAR(8),      
             @LastYM         NCHAR(6)          
       
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                     
         
     SELECT  @StdDate     = StdDate      ,        
             @DeptSeq     = DeptSeq              
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)        
    WITH (StdDate      NCHAR(8) ,        
          DeptSeq      INT )        
                     
     SELECT @LastDate = CONVERT(NCHAR,DATEADD(DD,-1,@StdDate),112)        
     SELECT @LastYM = CONVERT(NCHAR,DATEADD(YY,-1,@StdDate),112)       
           
   /*0나누기 에러 경고 처리*/                
     SET ANSI_WARNINGS OFF                
     SET ARITHIGNORE ON                
     SET ARITHABORT OFF          
           
     CREATE TABLE #TMPMst  
     (  
         DeptSeq INT,  
         DispSeq INT,  
         UMTotalDiv INT  
     )  
     --사업소관리(추가정보)의 사업소집계구분 값이 있는 것만 조회.  
     INSERT #TMPMst (DeptSeq,DispSeq,UMTotalDiv)  
     SELECT M.DeptSeq,A.DispSeq,A.UMTotalDiv  
     FROM _TDADept AS M    
     LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq AND A.DeptSeq = M.DeptSeq    
     LEFT OUTER JOIN _TDAUMinor AS UM WITH (NOLOCK) ON UM.CompanySeq = @CompanySeq AND UM.MinorSeq = A.UMTotalDiv  
     WHERE  M.CompanySeq = @CompanySeq    
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)     
     AND ISNULL(A.UMTotalDiv,0) <> 0  
     
     
     SELECT  A.ExpShipDate             AS ExpShipDate,        
             A.DeptSeq                 AS DeptSeq  ,        
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName ,        
             A.ItemSeq                 AS ItemSeq  ,        
             B.SMAssetGrp              AS SMAssetGrp,        
             (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = B.SMAssetGrp ) AS AssetName,        
             SUM(ISNULL(A.Qty,0))      AS Qty      ,        
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt   ,        
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT         
     INTO #TMPData        
     FROM hencom_TSLExpShipment  AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
   WHERE  A.CompanySeq = @CompanySeq        
     AND (LEFT(A.ExpShipDate,6) = LEFT(@StdDate,6)  OR A.ExpShipDate = @LastDate )           
     AND (@DeptSeq = 0 OR A.DeptSeq  = @DeptSeq)        
     GROUP BY A.ExpShipDate,A.DeptSeq,A.ItemSeq,B.SMAssetGrp        
           
 --출하기준데이터     
 /*  
     SELECT  A.DeptSeq ,      
             A.WorkDate,      
             SUM(ISNULL(A.ProdQty,0))  AS ProdQty ,      
             SUM(ISNULL(A.OutQty,0))   AS OutQty ,      
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt ,      
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT,       
             B.SMAssetGrp              AS SMAssetGrp      
     INTO #TMPCloseData      
     FROM hencom_TIFProdWorkReportClosesum AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.GoodItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
     WHERE A.CompanySeq = @CompanySeq      
     AND (LEFT(A.WorkDate,6) = LEFT(@StdDate,6) OR A.WorkDate = @LastDate OR LEFT(A.WorkDate,6) = @LastYM)      
     GROUP BY A.DeptSeq ,A.WorkDate,B.SMAssetGrp      
 */  
  SELECT     A.DeptSeq ,      
             A.WorkDate,      
             SUM(ISNULL(A.ProdQty,0))  AS ProdQty ,      
             SUM(ISNULL(A.OutQty,0))   AS OutQty ,      
             SUM(ISNULL(A.CurAmt,0))   AS CurAmt ,      
             SUM(ISNULL(A.CurVAT,0))   AS CurVAT,       
             B.SMAssetGrp              AS SMAssetGrp      
     INTO #TMPCloseData      
     FROM hencom_VInvoiceReplaceItem AS A WITH (NOLOCK)         
     LEFT OUTER JOIN _TDAItem AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq        
     LEFT OUTER JOIN _TDAItemAsset AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.AssetSeq = I.AssetSeq        
     WHERE A.CompanySeq = @CompanySeq      
     AND (LEFT(A.WorkDate,6) = LEFT(@StdDate,6) OR A.WorkDate = @LastDate OR LEFT(A.WorkDate,6) = @LastYM)      
     GROUP BY A.DeptSeq ,A.WorkDate,B.SMAssetGrp      
       
 --연간판매계획의 월별데이터    
     CREATE TABLE #TMPActPlan    
     (    
         DeptSeq     INT,
         ActPlanQty  DECIMAL(19,5) ,
         ActPlanAmt  DECIMAL(19,5) 
     )    
     INSERT #TMPActPlan (DeptSeq,ActPlanQty,ActPlanAmt)
     SELECT DeptSeq,SUM(ISNULL(PlanQty,0)),SUM(ISNULL(PlanAmt,0)) --,PlanYM
     FROM _TSLPlanYearSales
     WHERE CompanySeq = @CompanySeq
     AND PlanYM = LEFT(@StdDate,6)
     GROUP BY DeptSeq 
     
 --    select * from #TMPCloseData        
 --      return      
     SELECT  
         (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq ) AS DeptName ,      
         W.Weather,        
		 W.Remark,
         W.Temperature, 
         A.Qty,        
         A.CurAmt,        
         L.Qty    AS LastQty,        
         LI.Qty   AS LastItemQty, --전일 제품출하량        
         LG.QTy   AS LastGoodQty, --전일 상품출하량        
         ISNULL(LI.Qty,0) + ISNULL(LG.QTy,0) AS LastTotQty , --전일 제품+상품출하량        
         L.CurAmt            AS LastCurAmt , --전일예정금액       
         AccI.Qty            AS AccItemQty  ,----당월누적출하량 : 제품      
         AccG.Qty            AS AccGoodQty  ,--당월누적출하량 : 상품      
         ISNULL(AccI.Qty,0) + ISNULL(AccG.Qty,0) AS AccTotQty , --합계수량      
         AccTot.CurAmt       AS AccCurAmt , --누적출하금액      
         PrvAcc.CurAmt       AS PrevMMQty , --전년동월출하량      
         PL.ActPlanQty     AS YMPalnQty  , --당월목표수량      
         (ISNULL(AccI.Qty,0) + ISNULL(AccG.Qty,0))/ PL.ActPlanQty * 100 AS SuccQtyRate ,     --수량목표달성율     
         PL.ActPlanAmt                       AS YMPalnAmt ,      --당월목표금액
         AccTot.CurAmt / PL.ActPlanAmt * 100 AS SuccAmtRate     --금액목표달성율
     FROM #TMPMst AS M     
     LEFT OUTER JOIN (SELECT DeptSeq, Remark,Temperature,(SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq 
                                                                        AND MinorSeq = UMWeather) AS Weather --금일 날씨
                        FROM hencom_TSLWeather WHERE CompanySeq = @CompanySeq 
                                                AND WDate = @StdDate        
                  ) AS W ON W.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(Qty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --금일예정        
                  FROM #TMPData         
                  WHERE ExpShipDate = @StdDate         
                  GROUP BY DeptSeq ) AS A ON A.DeptSeq = M.DeptSeq       
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(Qty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --전일예정        
                  FROM #TMPData         
                  WHERE ExpShipDate = @LastDate         
                  GROUP BY DeptSeq ) AS L ON L.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --전일출하:제품        
                  FROM #TMPCloseData         
                  WHERE WorkDate = @LastDate AND SMAssetGrp IN ( 6008002 ,6008003) --제품  ,서비스      
                  GROUP BY DeptSeq ) AS LI ON LI.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --전일출하:상품        
                  FROM #TMPCloseData         
                  WHERE WorkDate = @LastDate AND SMAssetGrp = 6008001 --상품        
                    GROUP BY DeptSeq ) AS LG ON LG.DeptSeq = M.DeptSeq         
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --당월누적출하:제품        
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)       
                  AND SMAssetGrp IN ( 6008002 ,6008003) --제품  ,서비스         
                  GROUP BY DeptSeq ) AS AccI ON AccI.DeptSeq = M.DeptSeq        
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --당월누적출하:상품        
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)       
                  AND SMAssetGrp = 6008001 --상품        
                  GROUP BY DeptSeq ) AS AccG ON AccG.DeptSeq = M.DeptSeq               
       LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --당월누적출하: 합계      
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = LEFT(@StdDate,6)        
                  GROUP BY DeptSeq ) AS AccTot ON AccTot.DeptSeq = M.DeptSeq         
     LEFT OUTER JOIN (SELECT DeptSeq,SUM(ISNULL(OutQty,0)) AS Qty ,SUM(ISNULL(CurAmt,0)) AS CurAmt  --당월누적출하: 합계      
                  FROM #TMPCloseData         
                  WHERE LEFT(WorkDate,6) = @LastYM      
                  GROUP BY DeptSeq ) AS PrvAcc ON PrvAcc.DeptSeq = M.DeptSeq   
     LEFT OUTER JOIN #TMPActPlan  AS PL ON PL.DeptSeq = M.DeptSeq    --당월목표
     ORDER BY M.DispSeq    
	
 RETURN
