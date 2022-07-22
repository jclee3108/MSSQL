IF OBJECT_ID('hencom_SPNProfitSalesAnalysisGraph') IS NOT NULL 
    DROP PROC hencom_SPNProfitSalesAnalysisGraph
GO 

-- v2017.05.23 
/************************************************************    
  설  명 - 데이터-매출및한계이익_그래프_HNCOM : 조회    
  작성일 - 20161128    
  작성자 - 박수영    
 ************************************************************/    
  CREATE PROC dbo.hencom_SPNProfitSalesAnalysisGraph                    
  @xmlDocument      NVARCHAR(MAX) ,                
  @xmlFlags         INT  = 0,                
  @ServiceSeq       INT  = 0,                
  @WorkingTag       NVARCHAR(10)= '',                      
  @CompanySeq       INT  = 1,                
  @LanguageSeq      INT  = 1,                
  @UserSeq          INT  = 0,                
  @PgmSeq           INT  = 0             
         
 AS            
      
    DECLARE @docHandle      INT,    
            @StdYY          NCHAR(4) ,    
            @DeptSeq        INT ,    
            @Sql            NVARCHAR(MAX) ,    
            @CfmPlanSeq     INT  ,  
            @PrevYY NCHAR(4) ,  
            @ProdDeptSeq INT  
                 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
            
    SELECT  @StdYY   = StdYY    ,    
            @DeptSeq = DeptSeq      
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
        WITH (StdYY    NCHAR(4) ,    
              DeptSeq  INT )    
   /*0나누기 에러 경고 처리*/          
    SET ANSI_WARNINGS OFF          
    SET ARITHIGNORE ON          
    SET ARITHABORT OFF
                  
    SET @PrevYY = @StdYY-1  
  
    CREATE TABLE #TMPYMMaster    
    (    
        YM NCHAR(2)    
    )    
    
    --월마스터    
    INSERT #TMPYMMaster    
    SELECT '1' UNION ALL SELECT '2' UNION ALL SELECT '3'     
    UNION ALL SELECT '4' UNION ALL SELECT '5'     
    UNION ALL SELECT '6' UNION ALL SELECT '7'     
    UNION ALL SELECT '8' UNION ALL SELECT '9'     
    UNION ALL SELECT '10' UNION ALL SELECT '11' UNION ALL SELECT '12'    
    
     CREATE TABLE #TMP_Result_Graph    
     (    
         ItemSeq INT ,    
         ItemName NVARCHAR(200),    
         ItemNo NVARCHAR(200),    
         Spec NVARCHAR(200),    
         ITemClassLName NVARCHAR(200),    
         ITemClassLSeq INT  ,    
         PrevQty DECIMAL(19,5),    
         PrevAmt  DECIMAL(19,5),    
         PrevPrice  DECIMAL(19,5),    
         MatitemSeq INT ,    
         PrevTotQty  DECIMAL(19,5) ,    
         PrevTotAmt  DECIMAL(19,5),    
         PrevAvgPrice  DECIMAL(19,5),    
         Qty1  DECIMAL(19,5),    
         Amt1  DECIMAL(19,5),    
         Price1  DECIMAL(19,5),    
         Qty2  DECIMAL(19,5),    
         Amt2  DECIMAL(19,5),    
         Price2  DECIMAL(19,5),    
         Qty3  DECIMAL(19,5),    
         Amt3  DECIMAL(19,5),     
         Price3  DECIMAL(19,5),     
         Qty4  DECIMAL(19,5),     
         Amt4  DECIMAL(19,5),     
         Price4  DECIMAL(19,5),     
         Qty5  DECIMAL(19,5),    
         Amt5  DECIMAL(19,5),    
         Price5  DECIMAL(19,5),    
         Qty6  DECIMAL(19,5),    
         Amt6  DECIMAL(19,5),    
         Price6  DECIMAL(19,5) ,    
         Qty7  DECIMAL(19,5),    
         Amt7  DECIMAL(19,5),    
         Price7  DECIMAL(19,5),    
         Qty8  DECIMAL(19,5),    
         Amt8 DECIMAL(19,5),     
         Price8  DECIMAL(19,5),    
         Qty9  DECIMAL(19,5),    
         Amt9  DECIMAL(19,5),    
         Price9  DECIMAL(19,5),    
         Qty10  DECIMAL(19,5),    
         Amt10  DECIMAL(19,5),     
         Price10  DECIMAL(19,5),    
         Qty11  DECIMAL(19,5),    
         Amt11  DECIMAL(19,5),    
         Price11  DECIMAL(19,5),     
         Qty12  DECIMAL(19,5),     
         Amt12  DECIMAL(19,5),    
         Price12  DECIMAL(19,5),    
         TotQty  DECIMAL(19,5),    
         TotAmt  DECIMAL(19,5),    
         AvgPrice  DECIMAL(19,5),    
         PrevM3Qty  DECIMAL(19,5),    
         PrevM3TotQty  DECIMAL(19,5),    
         TotM3Qty  DECIMAL(19,5),    
         M3Qty1  DECIMAL(19,5),    
         M3Qty2  DECIMAL(19,5),    
         M3Qty3  DECIMAL(19,5) ,    
         M3Qty4  DECIMAL(19,5),     
         M3Qty5  DECIMAL(19,5),     
         M3Qty6 DECIMAL(19,5),     
         M3Qty7  DECIMAL(19,5),     
         M3Qty8  DECIMAL(19,5),     
         M3Qty9  DECIMAL(19,5),     
         M3Qty10  DECIMAL(19,5),     
         M3Qty11 DECIMAL(19,5),     
         M3Qty12  DECIMAL(19,5)    
     )    
         
    --해당년도 차수중에 확정차수        
    SELECT @CfmPlanSeq = PlanSeq         
    FROM hencom_TPNPlan WITH(NOLOCK)         
    WHERE CompanySeq = @CompanySeq         
    AND PlanYear = @StdYY         
    AND IsCfm = '1'         
--select * from hencom_TPNPlan    
--select @StdYY    
      
    --제품단위당이익조회 의 한계이익부분 결과만 담는다.    
    EXEC hencom_SPNMarginalProfitsItemQuery_SubQry @CompanySeq ,@DeptSeq,@CfmPlanSeq    
 --select * from #TMP_Result_Graph  where ItemSeq = 77777774 return     
    UPDATE #TMP_Result_Graph     
      SET Price1 = CASE WHEN Price1 is null THEN 0 ELSE Price1 END ,    
        Price2 = CASE WHEN Price2 is null THEN 0 ELSE Price2 END ,    
        Price3 = CASE WHEN Price3 is null THEN 0 ELSE Price3 END ,    
        Price4 = CASE WHEN Price4 is null THEN 0 ELSE Price4 END ,    
        Price5 = CASE WHEN Price5 is null THEN 0 ELSE Price5 END ,    
        Price6 = CASE WHEN Price6 is null THEN 0 ELSE Price6 END ,    
        Price7 = CASE WHEN Price7 is null THEN 0 ELSE Price7 END ,    
        Price8 = CASE WHEN Price8 is null THEN 0 ELSE Price8 END ,    
        Price9 = CASE WHEN Price9 is null THEN 0 ELSE Price9 END ,    
        Price10 = CASE WHEN Price10 is null THEN 0 ELSE Price10 END ,    
        Price11 = CASE WHEN Price11 is null THEN 0 ELSE Price11 END ,    
        Price12 = CASE WHEN Price12 is null THEN 0 ELSE Price12 END     
    WHERE ItemSeq = 77777774    
  
  
  
    --실적      
    CREATE TABLE #TMP_SalesData      
     (      
         YM         NCHAR(6),        
         Amt        DECIMAL(19,5),  
         Qty        DECIMAL(19,5)  
     )

    --매출자료생성조회 -- Mes출하기준      
    INSERT #TMP_SalesData      
    SELECT  LEFT(A.WorkDate,6)      AS StdYM,        
            SUM(ISNULL(A.CurAmt,0)) AS Amt  ,  
            SUM(ISNULL(A.OutQty,0)) AS Qty      
     FROM hencom_VInvoiceReplaceItem AS A WITH(NOLOCK)            
     WHERE A.CompanySeq = @CompanySeq   
     AND A.DeptSeq = @DeptSeq  
     AND A.WorkDate BETWEEN @PrevYY+'0101' AND @StdYY+'1231'  --전년도 ~ 당해년도
     GROUP BY LEFT(A.WorkDate,6)  
           
      --사업부문 레미콘을 제외한 거래명세서 데이터      
     INSERT #TMP_SalesData      
     SELECT LEFT(A.InvoiceDate,6) AS StdYM,   
          SUM(ISNULL(B.DomAmt,0)) AS Amt,  
          SUM(ISNULL(B.Qty,0)) AS Qty  
    FROM _TSLInvoice AS A WITH(NOLOCK)      
     LEFT OUTER JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq       
                                           AND B.InvoiceSeq = A.invoiceSeq   
    WHERE A.CompanySeq = @CompanySeq      
    AND A.DeptSeq = @DeptSeq
    AND A.InvoiceDate BETWEEN @PrevYY+'0101' AND @StdYY+'1231'   
    AND A.BizUnit <> 1 --사업부문 레미콘 제외.      
    GROUP BY LEFT(A.InvoiceDate,6)
  
--투입자재  
--생산사업소찾기    
     SELECT @ProdDeptSeq = ProdDeptSeq     
     FROM hencom_TDADeptAdd WITH(NOLOCK)   
     WHERE CompanySeq= @CompanySeq    
     AND DeptSeq = @DeptSeq   
     
  SELECT LEFT(InOutDate,6) AS YM ,SUM(ISNULL(Amt,0)) AS Amt    
      INTO #TMP_MatInputAmt   
      FROM _TESMGInOutStock  WITH(NOLOCK)     
      WHERE CompanySeq = @CompanySeq      
      AND DeptSeq = @ProdDeptSeq  
      AND InOutType = 130 --생산실적에서 자재투입  
      AND InOut = -1  
      AND InOutDate BETWEEN @PrevYY+'0101' AND @StdYY+'1231'   
      GROUP BY LEFT(InOutDate,6)     
        
--        
    /*당해 년도의 도급비*/  
    CREATE TABLE #TMP_ContrAmt  
    (  
        YM      NCHAR(6),  
        Amt     DECIMAL(19,5)  
    )
    
    --운반비  
    INSERT #TMP_ContrAmt  
     SELECT  LEFT(A.WorkDate,6) AS YM,  
             SUM(ISNULL(A.Amt,0)  + ISNULL(A.AddPayAmt,0) + ISNULL(A.OTAmt,0) - ISNULL(A.DeductionAmt,0)) AS Amt   
     FROM hencom_TPUSubContrCalc AS A  
      LEFT OUTER JOIN _TDAUMinorValue AS Mv ON Mv.CompanySeq = A.CompanySeq   
                                             AND Mv.MajorSeq = 8030   
                                             AND Mv.MinorSeq = A.UMCarClass   
                                             AND Mv.Serl = 1000001  
     WHERE A.CompanySeq = @CompanySeq  
     AND A.DeptSeq = @DeptSeq  
     AND A.WorkDate BETWEEN @PrevYY+'0101' AND @StdYY + '1231'    
     AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.  
     GROUP BY  LEFT(A.WorkDate,6)  
       
       
 --주유금액(자차와 용차)  
    INSERT #TMP_ContrAmt  
     SELECT A.FuelCalcYM AS YM ,  
           SUM(ISNULL(A.RefTotAmt,0)) AS Amt  
     FROM hencom_TPUFuelCalc AS A  
     LEFT OUTER JOIN hencom_TPUSubContrCar AS B ON B.CompanySeq = A.CompanySeq AND B.SubContrCarSeq = A.SubContrCarSeq  
     LEFT OUTER JOIN _TDAUMinorValue AS Mv ON Mv.CompanySeq = A.CompanySeq   
                                         AND Mv.MajorSeq = 8030   
                                         AND Mv.MinorSeq = B.UMCarClass   
                                         AND Mv.Serl = 1000001  
     WHERE A.CompanySeq = @CompanySeq  
     AND A.DeptSeq = @DeptSeq  
     AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.  
     AND A.FuelCalcYM BETWEEN @PrevYY+'01' AND @StdYY + '12'
     GROUP BY A.FuelCalcYM  
       

--SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,SUM(ISNULL(Amt,0)) AS Amt
--FROM #TMP_SalesData   
--WHERE LEFT(YM,4) = @StdYY GROUP BY YM --return  
--SELECT CONVERT(INT,RIGHT(YM,2)) AS YM,Amt   
--FROM #TMP_MatInputAmt WHERE LEFT(YM,4) = @StdYY   
--SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,SUM(ISNULL(Amt,0)) AS Amt   
--FROM #TMP_ContrAmt WHERE LEFT(YM,4) = @StdYY GROUP BY YM  
--return  
  
    SELECT MST.YM,    
         MST.YM+'월'AS YM_Kor ,    
         '사업계획' AS TypeClass1 ,    
         MP.Amt AS Amt1,    
           
          '전년도' AS TypeClass2 ,    
         (ISNULL(PrevS.Amt,0) - ISNULL(PrevMat.Amt,0) - ISNULL(PrevCon.Amt,0)) / PrevS.Qty AS Amt2 ,   
           
         '기준년도' AS TypeClass3 ,    
         (ISNULL(S.Amt,0) - ISNULL(Mat.Amt,0) - ISNULL(Con.Amt,0) ) / S.Qty AS Amt3  
     FROM #TMPYMMaster AS MST    
    LEFT OUTER JOIN (SELECT  REPLACE(U.YM,'Price','') AS YM ,    
                             U.MP AS Amt 
                    FROM #TMP_Result_Graph AS A    
                    UNPIVOT (MP FOR YM IN(Price1 ,Price2,Price3,Price4,Price5,Price6,Price7,Price8,Price9,Price10,Price11,Price12)    
                    ) AS U    
                    WHERE U.ItemSeq = 77777774 --한계이익 사업계획  
     ) AS MP ON MP.YM = MST.YM    
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,  
                            SUM(ISNULL(Amt,0)) AS Amt ,   
                            SUM(ISNULL(Qty,0)) AS Qty   
                        FROM #TMP_SalesData 
                        WHERE LEFT(YM,4) = @StdYY GROUP BY YM) AS S ON S.YM = MST.YM  
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,  
                            SUM(ISNULL(Amt,0)) AS Amt,   
                            SUM(ISNULL(Qty,0)) AS Qty   
                        FROM #TMP_SalesData 
                        WHERE LEFT(YM,4) = @PrevYY GROUP BY YM) AS PrevS ON PrevS.YM = MST.YM  
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM,Amt   
                        FROM #TMP_MatInputAmt 
                        WHERE LEFT(YM,4) = @StdYY ) AS Mat ON Mat.YM = MST.YM  
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM,Amt   
                        FROM #TMP_MatInputAmt 
                        WHERE LEFT(YM,4) = @PrevYY ) AS PrevMat ON PrevMat.YM = MST.YM  
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,SUM(ISNULL(Amt,0)) AS Amt   
                        FROM #TMP_ContrAmt 
                        WHERE LEFT(YM,4) = @StdYY GROUP BY YM) AS Con ON Con.YM = MST.YM  
    LEFT OUTER JOIN (SELECT CONVERT(INT,RIGHT(YM,2)) AS YM ,SUM(ISNULL(Amt,0)) AS Amt   
                        FROM #TMP_ContrAmt 
                        WHERE LEFT(YM,4) = @PrevYY GROUP BY YM) AS PrevCon ON PrevCon.YM = MST.YM  
 RETURN    