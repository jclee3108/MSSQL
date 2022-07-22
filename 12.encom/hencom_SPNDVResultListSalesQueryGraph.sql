IF OBJECT_ID('hencom_SPNDVResultListSalesQueryGraph') IS NOT NULL 
    DROP PROC hencom_SPNDVResultListSalesQueryGraph
GO 

-- v2017.05.23
/************************************************************  
  설  명 - 데이터-매출및한계이익_그래프_HNCOM : 매출조회  
  작성일 - 20161129  
  작성자 - 박수영  
 ************************************************************/  
  CREATE PROC dbo.hencom_SPNDVResultListSalesQueryGraph                  
  @xmlDocument      NVARCHAR(MAX) ,              
  @xmlFlags         INT  = 0,              
  @ServiceSeq       INT  = 0,              
  @WorkingTag       NVARCHAR(10)= '',                    
  @CompanySeq       INT  = 1,              
  @LanguageSeq      INT  = 1,              
  @UserSeq          INT  = 0,              
  @PgmSeq           INT  = 0           
       
 AS          
    
    DECLARE @docHandle  INT,  
            @StdYM      NCHAR(6), 
            @PrevYM     NCHAR(6)    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
                
    SELECT @StdYM = ISNULL(StdYM,'') 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH ( StdYM     NCHAR(6) )  
           
    SET @PrevYM = CONVERT(NCHAR(4),LEFT(@StdYM,4) -1) + RIGHT(@StdYM,2) 
  
    
    CREATE TABLE #DeptName    
    (    
        IDX_NO          INT IDENTITY, 
        DeptName        NVARCHAR(200), 
        DeptSeq         INT, 
        DispSeq         INT
    )    
    
    INSERT INTO #DeptName ( DeptName, DeptSeq, DispSeq ) 
    SELECT A.DeptName, A.DeptSeq, B.DispSeq
      FROM _TDADept                     AS A 
      LEFT OUTER JOIN hencom_TDADeptAdd AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.IsUseReport = '1' 

    DECLARE @CfmPlanSeq INT 
    
    --해당년도 차수중에 확정차수      
    SELECT @CfmPlanSeq = PlanSeq       
      FROM hencom_TPNPlan WITH(NOLOCK)       
     WHERE CompanySeq = @CompanySeq       
       AND PlanYear = LEFT(@StdYM,4)
       AND IsCfm = '1'       

    --사업계획 ItemSeq = 0 인 경우 상품, 그외 제품.      
    SELECT B.BPYm AS StdYM,
           A.DeptSeq,         
           SUM(ISNULL(B.SalesQty,0)) AS Qty,      
           SUM(ISNULL(B.SalesAmt,0)) AS Amt       
      INTO #TMP_SalePlan  
      FROM hencom_TPNPSalesPlan AS A WITH(NOLOCK)      
      JOIN hencom_TPNPSalesPlanD AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq       
                                                  AND B.PSalesRegSeq = A.PSalesRegSeq         
      WHERE A.CompanySeq = @CompanySeq      
       AND A.PlanSeq = @CfmPlanSeq   --사업계획 매출수량: 해당년도의 확정차수  
     GROUP BY A.DeptSeq, B.BPYm
    
    
    CREATE TABLE #TMP_SalesData      
    (      
        StdYM       NCHAR(6), 
        DeptSeq     INT, 
        Qty         DECIMAL(19,5)  
    )  
         
    --실적      
    --매출자료생성조회 -- Mes출하기준      
    INSERT INTO #TMP_SalesData ( StdYM, DeptSeq, Qty ) 
    SELECT LEFT(A.WorkDate,6) AS StdYM, 
           A.DeptSeq, 
           SUM(ISNULL(A.Qty,0)) AS Qty        
      FROM hencom_VInvoiceReplaceItem AS A WITH(NOLOCK)            
     WHERE A.CompanySeq = @CompanySeq   
       AND ( LEFT(A.WorkDate,6) = @PrevYM OR LEFT(A.WorkDate,6) = @StdYM )
     GROUP BY LEFT(A.WorkDate,6), DeptSeq
    
    --사업부문 레미콘을 제외한 거래명세서 데이터      
     INSERT INTO #TMP_SalesData ( StdYM, DeptSeq, Qty ) 
     SELECT LEFT(A.InvoiceDate,6) AS StdYM,   
            A.DeptSeq, 
            SUM(ISNULL(B.Qty,0)) AS Qty  
      FROM _TSLInvoice AS A WITH(NOLOCK)      
      JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq       
                                            AND B.InvoiceSeq = A.invoiceSeq   
     WHERE A.CompanySeq = @CompanySeq      
       AND ( LEFT(A.InvoiceDate,6) = @PrevYM OR LEFT(A.InvoiceDate,6) = @StdYM )
       AND A.BizUnit <> 1 --사업부문 레미콘 제외.      
     GROUP BY LEFT(A.InvoiceDate,6), A.DeptSeq 
    
    --최종조회  
    SELECT A.DeptName  AS DeptName ,  
           '사업계획'  AS TypeClass1 ,    
           B.Qty       AS Amt1,    
           -------------------
           '전년도'    AS TypeClass2 ,    
           PrevS.Qty       AS Amt2 ,
           -------------------    
           '기준년도'      AS TypeClass3 ,    
           S.Qty           AS Amt3    
      FROM #DeptName AS A  
      LEFT OUTER JOIN #TMP_SalePlan AS B ON B.StdYM = @StdYM AND B.DeptSeq = A.DeptSeq  
      LEFT OUTER JOIN (SELECT DeptSeq, SUM(ISNULL(Qty,0)) AS Qty   
                         FROM #TMP_SalesData 
                        WHERE StdYM = @StdYM GROUP BY DeptSeq) AS S ON S.DeptSeq = A.DeptSeq  
      LEFT OUTER JOIN (SELECT DeptSeq, SUM(ISNULL(Qty,0)) AS Qty   
                         FROM #TMP_SalesData 
                        WHERE StdYM = @PrevYM GROUP BY DeptSeq) AS PrevS ON PrevS.DeptSeq = A.DeptSeq  
     ORDER BY A.DispSeq
    
  RETURN
GO

exec hencom_SPNDVResultListSalesQueryGraph @xmlDocument=N'<ROOT>
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