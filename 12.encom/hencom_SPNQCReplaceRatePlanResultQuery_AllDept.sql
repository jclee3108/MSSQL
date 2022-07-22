IF OBJECT_ID('hencom_SPNQCReplaceRatePlanResultQuery_AllDept') IS NOT NULL 
    DROP PROC hencom_SPNQCReplaceRatePlanResultQuery_AllDept
GO 

-- 2017.04.25
/************************************************************      
  설  명 - 데이터-사업계획치환율및표준배합등록재료비결과_hencom : 조회      
  작성일 - 20161111      
  작성자 - 박수영      
  수정: 월별 비율 컬럼 추가되어 평균단가 계산 수정됨.2017.03.30 by박수영
 ************************************************************/      
CREATE PROC dbo.hencom_SPNQCReplaceRatePlanResultQuery_AllDept                    
    @xmlDocument    NVARCHAR(MAX) ,                  
    @xmlFlags       INT  = 0,                  
    @ServiceSeq     INT  = 0,                  
    @WorkingTag     NVARCHAR(10)= '',                        
    @CompanySeq     INT  = 1,                  
    @LanguageSeq    INT  = 1,                  
    @UserSeq        INT  = 0,                  
    @PgmSeq         INT  = 0               
 AS 
    
    DECLARE @docHandle      INT, 
            @PlanSeq        INT        
     
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                   
       
    SELECT @PlanSeq = PlanSeq        
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
    WITH (PlanSeq  INT )      
    
    /*0나누기 에러 경고 처리*/          
    SET ANSI_WARNINGS OFF          
    SET ARITHIGNORE ON          
    SET ARITHABORT OFF  
    
    DECLARE @Year       NCHAR(4),  
            @PrevYear   NCHAR(4)
            --@ProdDeptSeq    INT, 
            --@PrevCfmPlanSeq INT   
     
    SELECT @Year        = PlanYear, 
           @PrevYear    = CONVERT(INT,PlanYear)-1  
      FROM hencom_TPNPlan WITH(NOLOCK)      
     WHERE CompanySeq = @CompanySeq      
       AND PlanSeq = @PlanSeq      
   
    /*
    SELECT @ProdDeptSeq = ProdDeptSeq   
    FROM hencom_TDADeptAdd WITH(NOLOCK) 
    WHERE CompanySeq= @CompanySeq  
    AND DeptSeq = @DeptSeq  
    */
    --생산사업소찾기     
    SELECT DeptSeq, ProdDeptSeq  
      INTO #hencom_TDADeptAdd 
      FROM hencom_TDADeptAdd WITH(NOLOCK) 
     WHERE CompanySeq = @CompanySeq 



    ----전년도 차수중에 확정차수  
    --SELECT @PrevCfmPlanSeq = PlanSeq   
    --  FROM hencom_TPNPlan WITH(NOLOCK)   
    -- WHERE CompanySeq = @CompanySeq   
    --   AND PlanYear = @PrevYear   
    --   AND IsCfm = '1'   
    
    -- 사업계획년도와 전년도에 해당하는 표준배합자재들을 담는다.     
    CREATE TABLE #TMP_MatItem (Gubun INT, DeptSeq INT, ItemSeq INT )   
         
    --출하량 담기위해
    INSERT #TMP_MatItem (Gubun , DeptSeq, ItemSeq)
    SELECT -1, DeptSeq, -1 
      FROM #hencom_TDADeptAdd
     
    INSERT #TMP_MatItem (DeptSeq, ItemSeq)    
    SELECT DISTINCT DeptSeq, ItemSeq     
      FROM hencom_VPNPalnMatItemMapping     
     WHERE CompanySeq = @CompanySeq
       AND StYear = @Year
       AND ISNULL(ItemSeq,0) <> 0    
    
    
    --해당차수 데이터 조회 -----------------------------------------------------------------------------------------
    -- 제품매출계획  
    SELECT '해당차수 제품매출계획' AS Test,  
           A.DeptSeq, 
           A.ItemSeq,  
           B.BPYm,  
           SUM(ISNULL(B.SalesQty,0)) AS SalesQty ,
           SUM(ISNULL(b.SalesAmt,0)) as SalesAmt  
      INTO #TMP_SalesPlanThis  
      FROM hencom_TPNPSalesPlan  AS A WITH(NOLOCK) 
      JOIN #hencom_TDADeptAdd    AS C              ON ( C.DeptSeq = A.DeptSeq ) 
      JOIN hencom_TPNPSalesPlanD AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.PSalesRegSeq = A.PSalesRegSeq ) 
     WHERE A.ItemSeq <> 0  --제품인 경우.  
       AND A.PlanSeq = @PlanSeq  
     GROUP BY A.DeptSeq, A.ItemSeq, B.BPYm  
   

 --  select '#TMP_SalesPlanThis',* from #TMP_SalesPlanThis return
 --자재매입단가: 소수점첫째자리에서 반올림처리.  
     SELECT '자재매입단가' AS Test,  
            A.DeptSeq AS DeptSeq, 
            A.ItemSeq AS MatItemSeq,  
            ROUND(SUM(ISNULL(B.Price01*B.WegtRate1*0.01,0)),0) AS Price01 ,
            ROUND(SUM(ISNULL(B.Price02*B.WegtRate2*0.01,0)),0) AS Price02 ,
            ROUND(SUM(ISNULL(B.Price03*B.WegtRate3*0.01,0)),0) AS Price03 ,
            ROUND(SUM(ISNULL(B.Price04*B.WegtRate4*0.01,0)),0) AS Price04 ,
            ROUND(SUM(ISNULL(B.Price05*B.WegtRate5*0.01,0)),0) AS Price05 ,
            ROUND(SUM(ISNULL(B.Price06*B.WegtRate6*0.01,0)),0) AS Price06 ,
            ROUND(SUM(ISNULL(B.Price07*B.WegtRate7*0.01,0)),0) AS Price07 ,
            ROUND(SUM(ISNULL(B.Price08*B.WegtRate8*0.01,0)),0) AS Price08 ,
            ROUND(SUM(ISNULL(B.Price09*B.WegtRate9*0.01,0)),0) AS Price09 ,
            ROUND(SUM(ISNULL(B.Price10*B.WegtRate10*0.01,0)),0) AS Price10 ,
            ROUND(SUM(ISNULL(B.Price11*B.WegtRate11*0.01,0)),0) AS Price11 ,
            ROUND(SUM(ISNULL(B.Price12*B.WegtRate12*0.01,0)),0) AS Price12
      INTO #TMP_MatPriceThis  
      FROM hencom_TPNMatPrice   AS A WITH(NOLOCK) 
      JOIN #hencom_TDADeptAdd   AS C              ON ( C.DeptSeq = A.DeptSeq ) 
      JOIN hencom_TPNMatPriceD  AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.MatPriceSeq = A.MatPriceSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlanSeq = @PlanSeq  
     GROUP BY A.DeptSeq, A.ItemSeq  
   


 --  select * from #TMP_MatPriceThis return
   --월별 자재매입단가의 평균단가
     SELECT U.DeptSeq, 
            U.MatItemSeq,  
            @Year+RIGHT(U.YM,2) AS YM,  
            U.Price  
     INTO #TMP_ThisYMPrice  
     FROM #TMP_MatPriceThis AS B    
     UNPIVOT (Price FOR YM IN (Price01 ,Price02,Price03,Price04,Price05,Price06  
     ,Price07,Price08,Price09,Price10,Price11,Price12  
     )) AS U 
    

     SELECT 'hencom_VPNPalnReplaceRateMonthItem' AS Test,  
             A.StYM,  
             A.DeptSeq, 
             A.ItemSeq,  
             A.PerQty / f.ConvFactor as PerQty,  
             P.MatItemSeq ,  
             (SELECT Price FROM #TMP_ThisYMPrice WHERE YM = A.StYM AND MatItemSeq =P.MatItemSeq) AS Price  
     INTO #TMP_MonthItemThis  --월별 단가
     FROM hencom_VPNPalnReplaceRateMonthItem AS A  
     LEFT OUTER JOIN (SELECT DeptSeq, MatItem, ItemSeq AS MatItemSeq  
                     FROM hencom_VPNPalnMatItemMapping  
                     WHERE CompanySeq = @CompanySeq 
                     AND StYear = @Year  --년도
                     ) AS P ON ( P.DeptSeq = A.DeptSeq AND P.MatItem = A.MatItem ) 
     left outer join hencom_VPDConvFactorDate as f on f.CompanySeq = a.CompanySeq
	                                              and f.DeptSeq = a.DeptSeq
												  and f.ItemSeq = p.MatItemSeq
     WHERE A.PlanSeq = @PlanSeq 
	 
   


    SELECT M.DeptSeq, 
           P.MatItemSeq                                 AS MatItemSeq, --투입자재  
           M.BPYm                                        AS BPYm , 
           SUM(ISNULL(M.SalesQty*P.PerQty,0))            AS MatInputQty,  
           SUM(ISNULL(M.SalesQty*P.PerQty*P.Price,0))    AS MatInputAmt  
      INTO #TMP_ThisMatInputPaln  
      FROM #TMP_SalesPlanThis AS M  
      JOIN #TMP_MonthItemThis AS P ON P.StYM = M.BPYm AND P.ItemSeq = M.ItemSeq AND P.DeptSeq = M.DeptSeq 
     WHERE ISNULL(P.MatItemSeq,0) <> 0  
     GROUP BY M.DeptSeq, P.MatItemSeq,M.BPYm
    




      SELECT B.DeptSeq, 
             B.MatItemSeq    
             --수량    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '01' THEN MatInputQty ELSE 0 END) AS MatInputQty1    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '02' THEN MatInputQty ELSE 0 END) AS MatInputQty2    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '03' THEN MatInputQty ELSE 0 END) AS MatInputQty3    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '04' THEN MatInputQty ELSE 0 END) AS MatInputQty4    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '05' THEN MatInputQty ELSE 0 END) AS MatInputQty5    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '06' THEN MatInputQty ELSE 0 END) AS MatInputQty6    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '07' THEN MatInputQty ELSE 0 END) AS MatInputQty7    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '08' THEN MatInputQty ELSE 0 END) AS MatInputQty8    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '09' THEN MatInputQty ELSE 0 END) AS MatInputQty9    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '10' THEN MatInputQty ELSE 0 END) AS MatInputQty10    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '11' THEN MatInputQty ELSE 0 END) AS MatInputQty11    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '12' THEN MatInputQty ELSE 0 END) AS MatInputQty12    
             --금액    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '01' THEN MatInputAmt ELSE 0 END) AS MatInputAmt1    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '02' THEN MatInputAmt  ELSE 0 END) AS MatInputAmt2    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '03' THEN MatInputAmt ELSE 0 END) AS MatInputAmt3    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '04' THEN MatInputAmt ELSE 0 END) AS MatInputAmt4    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '05' THEN MatInputAmt ELSE 0 END) AS MatInputAmt5    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '06' THEN  MatInputAmt ELSE 0 END) AS MatInputAmt6    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '07' THEN MatInputAmt ELSE 0 END) AS MatInputAmt7    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '08' THEN MatInputAmt ELSE 0 END) AS MatInputAmt8    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '09' THEN MatInputAmt ELSE 0 END) AS MatInputAmt9    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '10' THEN MatInputAmt ELSE 0 END) AS MatInputAmt10    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '11' THEN MatInputAmt ELSE 0 END) AS MatInputAmt11    
             ,MAX(CASE WHEN RIGHT(B.BPYm,2) = '12' THEN MatInputAmt ELSE 0 END) AS MatInputAmt12    
     INTO #TMP_ThisMatInputPalnYMData
     FROM #TMP_ThisMatInputPaln AS B
     GROUP BY B.DeptSeq, B.MatItemSeq






      --해당 차수의 총계
     SELECT DeptSeq, 
            MatItemSeq,
            SUM(ISNULL(MatInputQty,0)) AS TotQty,
            SUM(ISNULL(MatInputAmt,0)) AS TotAmt,
            SUM(ISNULL(MatInputAmt,0)) / SUM(ISNULL(MatInputQty,0)) AS AvgPrice
     INTO #TMP_ThisTot
     FROM #TMP_ThisMatInputPaln
     GROUP BY DeptSeq, MatItemSeq
    



  


     --MES 출하시스템에서 넘어온 출하데이터를 합계처리한 출하실적합계 
		 ---- 당년월별계획 및 당년합계
      SELECT -1 AS Gubun   ,
             B.DeptSeq, 
             max(LEFT(BPYm,4)) AS YY
             --수량    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '01' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty1    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '02' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty2    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '03' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty3    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '04' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty4    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '05' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty5    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '06' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty6    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '07' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty7    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '08' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty8    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '09' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty9    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '10' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty10    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '11' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty11    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '12' THEN ISNULL(SalesQty,0) ELSE 0 END) AS Qty12    
             --금액    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '01' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt1    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '02' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt2    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '03' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt3    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '04' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt4    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '05' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt5    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '06' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt6    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '07' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt7    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '08' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt8    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '09' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt9    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '10' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt10    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '11' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt11    
            ,SUM(CASE WHEN RIGHT(BPYm,2) = '12' THEN ISNULL(SalesAmt,0) ELSE 0 END) AS Amt12    
      INTO #TMPIFProdWorkReportCloseSumThisYear
      FROM #TMP_SalesPlanThis AS B 
     GROUP BY B.DeptSeq 

    

    SELECT -1 AS Gubun ,
           B.DeptSeq, 
           LEFT(WorkDate,4) AS YY ,
           SUM(ISNULL(OutQty,0)) AS OutQty ,
           SUM(ISNULL(CurAmt,0)) AS CurAmt
      INTO #TMPIFProdWorkReportCloseSumThisTot
      FROM hencom_TIFProdWorkReportCloseSum AS B
      JOIN #hencom_TDADeptAdd               AS C ON ( C.DeptSeq = B.DeptSeq ) 
     WHERE CompanySeq = @CompanySeq
       AND LEFT(WorkDate,4) IN (@PrevYear )
     GROUP BY B.DeptSeq, LEFT(WorkDate,4)
     



--     select * from #TMPIFProdWorkReportCloseSumThis return
  --최종조회  
     INSERT INTO #tmepresult2 
     SELECT A.DeptSeq, 
            A.ItemSeq,  
            B.ItemName,  
            B.ItemNo,  
            B.Spec,    
            C.ItemClasLName                         AS ItemClassLName, --자재대분류     
            C.ItemClassLSeq                         AS ItemClassLSeq  ,  
            0 AS PrevQty , --전년도 실적  
            0 AS PrevAmt, --전년도 실적  
            0 AS PrevPrice, --전년도 실적  
            0 AS MatItemSeq,--전년도 사업계획 자재  
            0 AS PrevTotQty, --전년도 사업계획 투입자재 수량  
            0 AS PrevTotAmt , --전년도 사업계획 투입자재 금액  
            0 AS PrevAvgPrice , --전년도 사업계획 투입자재 단가 
            T.MatInputQty1 AS Qty1 ,
            T.MatInputAmt1 AS Amt1 ,
            T.MatInputAmt1 / T.MatInputQty1 AS Price1 ,
            T.MatInputQty2 AS Qty2 ,
            T.MatInputAmt2 AS Amt2 ,
            T.MatInputAmt2 / T.MatInputQty2 AS Price2 ,
            T.MatInputQty3 AS Qty3 ,
            T.MatInputAmt3 AS Amt3 ,
            T.MatInputAmt3 / T.MatInputQty3 AS Price3 ,
            T.MatInputQty4 AS Qty4 ,
            T.MatInputAmt4 AS Amt4 ,
            T.MatInputAmt4 / T.MatInputQty4 AS Price4 ,
            T.MatInputQty5 AS Qty5 ,
            T.MatInputAmt5 AS Amt5 ,
            T.MatInputAmt5 / T.MatInputQty5 AS Price5 ,
            T.MatInputQty6 AS Qty6 ,
            T.MatInputAmt6 AS Amt6 ,
            T.MatInputAmt6 / T.MatInputQty6 AS Price6 ,
            T.MatInputQty7 AS Qty7 ,
            T.MatInputAmt7 AS Amt7 ,
            T.MatInputAmt7 / T.MatInputQty7 AS Price7 ,
            T.MatInputQty8 AS Qty8 ,
            T.MatInputAmt8 AS Amt8 ,
            T.MatInputAmt8 / T.MatInputQty8 AS Price8 ,
            T.MatInputQty9 AS Qty9 ,
            T.MatInputAmt9 AS Amt9 ,
            T.MatInputAmt9 / T.MatInputQty9 AS Price9 ,
            T.MatInputQty10 AS Qty10 ,
            T.MatInputAmt10 AS Amt10 ,
            T.MatInputAmt10 / T.MatInputQty10 AS Price10 ,
            T.MatInputQty11 AS Qty11 ,
            T.MatInputAmt11 AS Amt11 ,
            T.MatInputAmt11 / T.MatInputQty11 AS Price11 ,
            T.MatInputQty12 AS Qty12 ,
            T.MatInputAmt12 AS Amt12,
            T.MatInputAmt12 / T.MatInputQty12 AS Price12 ,
            S.TotQty      AS TotQty,
            S.TotAmt      AS TotAmt,
            S.AvgPrice    AS AvgPrice, 
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0
      --INTO #tempresult_sub
      FROM #TMP_MatItem         AS A    
      LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN dbo._FDAGetItemClass(@CompanySeq,0)   AS C ON C.ItemSeq = A.ItemSeq   
     LEFT OUTER JOIN #TMP_ThisMatInputPalnYMData            AS T ON ( T.DeptSeq = A.DeptSeq AND T.MatItemSeq = A.ItemSeq ) 
     LEFT OUTER JOIN #TMP_ThisTot                           AS S ON ( S.DeptSeq = A.DeptSeq AND S.MatItemSeq = A.ItemSeq ) 
     WHERE ISNULL(A.Gubun,0) = 0

    




    --select * from #TMP_MatItem 
    --return 

    --INSERT INTO #tempresult_sub
    INSERT INTO #tmepresult2 
    SELECT  A.DeptSeq, 
            -1 AS ItemSeq,  
            '출하' AS ItemName,  
            '' AS ItemNo,  
            '' AS Spec,    
            '' AS ItemClassLName, --자재대분류     
            0 AS ItemClassLSeq  ,  
            0 AS PrevQty , --전년도 실적  
            0 AS PrevAmt, --전년도 실적  
            0 AS PrevPrice, --전년도 실적  
            0 AS MatItemSeq,--전년도 사업계획 자재  
            0 AS PrevTotQty, --전년도 사업계획 투입자재 수량  
            0 AS PrevTotAmt , --전년도 사업계획 투입자재 금액  
            0 AS PrevAvgPrice , --전년도 사업계획 투입자재 단가 
            S.Qty1 AS Qty1 ,
            S.Amt1 AS Amt1 ,
            S.Amt1 / S.Qty1 AS Price1 ,
            S.Qty2 AS Qty2 ,
            S.Amt2 AS Amt2 ,
            S.Amt2 / S.Qty2 AS Price2 ,
            S.Qty3 AS Qty3 ,
            S.Amt3 AS Amt3 ,
            S.Amt3 / S.Qty3 AS Price3 ,
            S.Qty4 AS Qty4 ,
            S.Amt4 AS Amt4 ,
            S.Amt4 / S.Qty4 AS Price4 ,
            S.Qty5 AS Qty5 ,
            S.Amt5 AS Amt5 ,
            S.Amt5 / S.Qty5 AS Price5 ,
            S.Qty6 AS Qty6 ,
            S.Amt6 AS Amt6 ,
            S.Amt6 / S.Qty6 AS Price6 ,
            S.Qty7 AS Qty7 ,
            S.Amt7 AS Amt7 ,
            S.Amt7 / S.Qty7 AS Price7 ,
            S.Qty8 AS Qty8 ,
            S.Amt8 AS Amt8 ,
            S.Amt8 / S.Qty8 AS Price8 ,
            S.Qty9 AS Qty9 ,
            S.Amt9 AS Amt9 ,
            S.Amt9 / S.Qty9 AS Price9 ,
            S.Qty10 AS Qty10 ,
            S.Amt10 AS Amt10 ,
            S.Amt10  / S.Qty10 AS Price10 ,
            S.Qty11 AS Qty11 ,
            S.Amt11 AS Amt11 ,
            S.Amt11 / S.Qty11 AS Price11 ,
            S.Qty12 AS Qty12 ,
            S.Amt12 AS Amt12,
            S.Amt12 / S.Qty12 AS Price12 ,
            ST.SalesQty      AS TotQty,
            ST.SalesAmt      AS TotAmt,
            ST.SalesAmt /ST.SalesQty   AS AvgPrice, 
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0,
            0, 
            0,
            0
     FROM #TMP_MatItem AS A    
     LEFT OUTER JOIN #TMPIFProdWorkReportCloseSumThisYear AS S ON ( S.DeptSeq = A.DeptSeq AND S.Gubun = A.Gubun ) 
     LEFT OUTER JOIN ( SELECT DeptSeq, SUM(SalesQty) as SalesQty, SUM(SalesAmt) as SalesAmt   
                         FROM #TMP_SalesPlanThis
                        GROUP BY DeptSeq 
                     ) AS ST ON ( ST.DeptSeq = A.DeptSeq )  ---- 당해년도계획토탈    ---- 애는 다시만들어야 함
     WHERE A.Gubun = -1 
    
    UPDATE A
       SET 
		   PrevM3Qty = 0, 
           PrevM3TotQty = 0, 
           Price1 = a.Amt1  / b.Qty1 ,
           Price2 = a.Amt2  / b.Qty2,
           Price3 = a.Amt3   / b.Qty3,
           Price4 = a.Amt4   / b.Qty4,
           Price5 = a.Amt5   / b.Qty5,
           Price6 = a.Amt6   / b.Qty6,
           Price7 = a.Amt7   / b.Qty7,
           Price8 = a.Amt8   / b.Qty8,
           Price9 = a.Amt9   / b.Qty9,
           Price10 = a.Amt10   / b.Qty10,
           Price11 = a.Amt11   / b.Qty11,
           Price12 = a.Amt12   / b.Qty12,
           AvgPrice = a.TotAmt / b.TotQty,
           TotM3Qty = a.TotQty / b.TotQty,
           M3Qty1 = a.Qty1 / b.Qty1,
           M3Qty2 = a.Qty2 / b.Qty2,
           M3Qty3 = a.Qty3 / b.Qty3,
           M3Qty4 = a.Qty4 / b.Qty4,
           M3Qty5 = a.Qty5 / b.Qty5,
           M3Qty6 = a.Qty6 / b.Qty6,
           M3Qty7 = a.Qty7 / b.Qty7,
           M3Qty8 = a.Qty8 / b.Qty8,
           M3Qty9 = a.Qty9 / b.Qty9,
           M3Qty10 = a.Qty10 / b.Qty10,
           M3Qty11 = a.Qty11 / b.Qty11,
           M3Qty12 = a.Qty12 / b.Qty12
      FROM #tmepresult2 as a
      JOIN #tmepresult2 as b on ( b.DeptSeq = a.DeptSeq AND b.ItemSeq = -1 ) 
     WHERE A.ItemSeq <> -1
    
    --select *
    --  from #tmepresult2 
    -- where deptseq = 35 
    -- order by itemseq
    --*/
 RETURN
--go
--exec hencom_SPNQCReplaceRatePlanResultQuery_AllDept 
--@xmlDocument='<ROOT>  
--     <DataBlock1>  
--    <WorkingTag>A</WorkingTag>  
--    <IDX_NO>1</IDX_NO>  
--    <Status>0</Status>  
--    <DataSeq>1</DataSeq>  
--    <Selected>1</Selected>  
--    <TABLE_NAME>DataBlock1</TABLE_NAME>  
--    <IsChangedMst>1</IsChangedMst>  
--    <DeptSeq>0</DeptSeq>  
--    <PlanSeq>3</PlanSeq>  
--     </DataBlock1>  
--   </ROOT>'  ,@xmlFlags=2,@ServiceSeq=1510198,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031857  


