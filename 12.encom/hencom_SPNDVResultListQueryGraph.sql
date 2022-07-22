
IF OBJECT_ID('hencom_SPNDVResultListQueryGraph') IS NOT NULL   
    DROP PROC hencom_SPNDVResultListQueryGraph  
GO  
  
-- v2017.05.22
  
-- 출하실적현황-조회 by 이재천 
CREATE PROC hencom_SPNDVResultListQueryGraph  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYM      NCHAR(6), 
            @PrevYM     NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYM   NCHAR(6))    
    
    /*0나누기 에러 경고 처리*/          
    SET ANSI_WARNINGS OFF          
    SET ARITHIGNORE ON          
    SET ARITHABORT OFF
                  
    SET @PrevYM = CONVERT(NCHAR(4),LEFT(@StdYM,4) -1) + RIGHT(@StdYM,2)
    
    
    --SELECT @PrevYM, @StdYM 
    --return 


  
    CREATE TABLE #DeptName    
    (    
        IDX_NO          INT IDENTITY, 
        DeptName        NVARCHAR(200), 
        DeptSeq         INT, 
        ProdDeptSeq     INT, 
        DispSeq         INT 
    )    
    
    INSERT INTO #DeptName ( DeptName, DeptSeq, ProdDeptSeq, DispSeq ) 
    SELECT A.DeptName, A.DeptSeq, B.ProdDeptSeq, B.DispSeq
      FROM _TDADept                     AS A 
      LEFT OUTER JOIN hencom_TDADeptAdd AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.IsUseReport = '1' 
    
    
    
    CREATE TABLE #TMP_Result_Graph   
    (    
        DeptSeq INT, 
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
    
    
    DECLARE @CfmPlanSeq INT
    
    --해당년도 차수중에 확정차수        
    SELECT @CfmPlanSeq = PlanSeq         
    FROM hencom_TPNPlan WITH(NOLOCK)         
    WHERE CompanySeq = @CompanySeq         
    AND PlanYear = LEFT(@StdYM,4)
    AND IsCfm = '1'         
    
    
    EXEC hencom_SPNMarginalProfitsItemQuery_AllDept @CompanySeq, @CfmPlanSeq



    --제품단위당이익조회 의 한계이익부분 결과만 담는다.    
    --EXEC hencom_SPNMarginalProfitsItemQuery_SubQry @CompanySeq ,@DeptSeq,@CfmPlanSeq    
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
         DeptSeq    INT, 
         StdYM      NCHAR(6),
         Amt        DECIMAL(19,5),  
         Qty        DECIMAL(19,5)  
     )
    --매출자료생성조회 -- Mes출하기준      
    INSERT INTO #TMP_SalesData      
    SELECT A.DeptSeq, 
           LEFT(A.WorkDate,6)      AS StdYM,        
           SUM(ISNULL(A.CurAmt,0)) AS Amt  ,  
           SUM(ISNULL(A.OutQty,0)) AS Qty      
      FROM hencom_VInvoiceReplaceItem   AS A WITH(NOLOCK)            
      JOIN #DeptName                    AS C              ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND ( LEFT(A.WorkDate,6) = @PrevYM OR LEFT(A.WorkDate,6) = @StdYM ) 
     GROUP BY A.DeptSeq, LEFT(A.WorkDate,6)  
    

    --사업부문 레미콘을 제외한 거래명세서 데이터      
    INSERT INTO #TMP_SalesData      
    SELECT A.DeptSeq, 
           LEFT(A.InvoiceDate,6) AS StdYM, 
           SUM(ISNULL(B.DomAmt,0)) AS Amt,  
           SUM(ISNULL(B.Qty,0)) AS Qty  
      FROM _TSLInvoice AS A WITH(NOLOCK)      
      LEFT OUTER JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.InvoiceSeq = A.invoiceSeq ) 
                 JOIN #DeptName       AS C              ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq      
       AND ( LEFT(A.InvoiceDate,6) = @PrevYM OR LEFT(A.InvoiceDate,6) = @StdYM ) 
       AND A.BizUnit <> 1 --사업부문 레미콘 제외.      
     GROUP BY A.DeptSeq, LEFT(A.InvoiceDate,6)
    

    

    ----투입자재  
    SELECT B.DeptSeq, LEFT(A.InOutDate,6) AS StdYM ,SUM(ISNULL(Amt,0)) AS Amt    
      INTO #TMP_MatInputAmt   
      FROM _TESMGInOutStock     AS A WITH(NOLOCK)
      JOIN #DeptName            AS B              ON ( B.ProdDeptSeq = A.DeptSeq ) 
      WHERE CompanySeq = @CompanySeq      
      AND InOutType = 130 --생산실적에서 자재투입  
      AND InOut = -1  
      AND ( LEFT(A.InOutDate,6) = @PrevYM OR LEFT(A.InOutDate,6) = @StdYM ) 
      GROUP BY B.DeptSeq, LEFT(InOutDate,6)     
    

    /*당해 년도의 도급비*/  
    CREATE TABLE #TMP_ContrAmt  
    (  
        DeptSeq INT, 
        StdYM   NCHAR(6),  
        Amt     DECIMAL(19,5)  
    )
    
    --운반비  
    INSERT INTO #TMP_ContrAmt  
    SELECT A.DeptSeq, LEFT(A.WorkDate,6) AS StdYM,  
             SUM(ISNULL(A.Amt,0)  + ISNULL(A.AddPayAmt,0) + ISNULL(A.OTAmt,0) - ISNULL(A.DeductionAmt,0)) AS Amt   
      FROM hencom_TPUSubContrCalc       AS A  
      LEFT OUTER JOIN _TDAUMinorValue   AS Mv ON Mv.CompanySeq = A.CompanySeq   
                                             AND Mv.MajorSeq = 8030   
                                             AND Mv.MinorSeq = A.UMCarClass   
                                             AND Mv.Serl = 1000001  
                 JOIN #DeptName         AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
     AND ( LEFT(A.WorkDate,6) = @PrevYM OR LEFT(A.WorkDate,6) = @StdYM ) 
     AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.  
     GROUP BY A.DeptSeq, LEFT(A.WorkDate,6)  
       
       
    --주유금액(자차와 용차)  
    INSERT INTO #TMP_ContrAmt  
    SELECT A.DeptSeq, 
           A.FuelCalcYM AS StdYM, 
           SUM(ISNULL(A.RefTotAmt,0)) AS Amt 
     FROM hencom_TPUFuelCalc                AS A  
     LEFT OUTER JOIN hencom_TPUSubContrCar  AS B ON B.CompanySeq = A.CompanySeq AND B.SubContrCarSeq = A.SubContrCarSeq  
     LEFT OUTER JOIN _TDAUMinorValue        AS Mv ON Mv.CompanySeq = A.CompanySeq   
                                                 AND Mv.MajorSeq = 8030   
                                                 AND Mv.MinorSeq = B.UMCarClass   
                                                 AND Mv.Serl = 1000001  
                JOIN #DeptName              AS C ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.  
       AND ( A.FuelCalcYM = @PrevYM OR A.FuelCalcYM = @StdYM ) 
     GROUP BY A.DeptSeq, A.FuelCalcYM
    

    -- 사업계획 한계이익 
    DECLARE @ColumnName NVARCHAR(100), 
            @Sql        NVARCHAR(MAX)
    SELECT @ColumnName = 'Price' + CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(@StdYM,2)))

    CREATE TABLE #Price 
    (
        DeptSeq INT, 
        Price   DECIMAL(19,5)
    )
    
    SELECT @Sql = '  INSERT INTO #Price
                     SELECT DeptSeq, Price 
                       FROM ( SELECT DeptSeq, ' + @ColumnName + ' FROM #TMP_Result_Graph WHERE ItemSeq = 77777774 ) AS Z 
                       UNPIVOT ( Price FOR ColumnName in ( ' + @ColumnName + ' ) ) AS Y ' 
    

    Execute (@Sql) 

    -- 최종조회     
    SELECT A.DeptName,    
         --MST.YM+'월'AS YM_Kor ,    
         '사업계획' AS TypeClass1 ,    
         B.Price AS Amt1,    
          '전년도' AS TypeClass2 ,    
         (ISNULL(PrevS.Amt,0) - ISNULL(PrevMat.Amt,0) - ISNULL(PrevCon.Amt,0)) / PrevS.Qty AS Amt2 ,   
         '기준년도' AS TypeClass3 ,    
         (ISNULL(S.Amt,0) - ISNULL(Mat.Amt,0) - ISNULL(Con.Amt,0) ) / S.Qty AS Amt3  

     FROM #DeptName AS A    
    LEFT OUTER JOIN #Price AS B ON ( B.DeptSeq = A.DeptSeq ) 
    LEFT OUTER JOIN (SELECT DeptSeq, 
                            SUM(ISNULL(Amt,0)) AS Amt ,   
                            SUM(ISNULL(Qty,0)) AS Qty   
                       FROM #TMP_SalesData 
                      WHERE StdYM = @StdYM GROUP BY DeptSeq) AS S ON S.DeptSeq = A.DeptSeq
    LEFT OUTER JOIN (SELECT DeptSeq, 
                            SUM(ISNULL(Amt,0)) AS Amt,   
                            SUM(ISNULL(Qty,0)) AS Qty   
                       FROM #TMP_SalesData 
                      WHERE StdYM = @PrevYM GROUP BY DeptSeq) PrevS ON PrevS.DeptSeq = A.DeptSeq  
    LEFT OUTER JOIN (SELECT DeptSeq, Amt   
                       FROM #TMP_MatInputAmt 
                      WHERE StdYM = @StdYM) AS Mat ON Mat.DeptSeq = A.DeptSeq  
    LEFT OUTER JOIN (SELECT DeptSeq, Amt   
                       FROM #TMP_MatInputAmt 
                      WHERE StdYM = @PrevYM) AS PrevMat ON PrevMat.DeptSeq = A.DeptSeq  
    LEFT OUTER JOIN (SELECT DeptSeq, SUM(ISNULL(Amt,0)) AS Amt   
                       FROM #TMP_ContrAmt 
                      WHERE StdYM = @StdYM GROUP BY DeptSeq) AS Con ON Con.DeptSeq = A.DeptSeq  
    LEFT OUTER JOIN (SELECT DeptSeq, SUM(ISNULL(Amt,0)) AS Amt   
                       FROM #TMP_ContrAmt 
                      WHERE StdYM = @PrevYM GROUP BY DeptSeq) AS PrevCon ON PrevCon.DeptSeq = A.DeptSeq  
     ORDER BY A.DispSeq
    
    RETURN  
    go
exec hencom_SPNDVResultListQueryGraph @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201705</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512268,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033643