
IF OBJECT_ID('DTI_SSLInterTransferPJTCreate') IS NOT NULL 
    DROP PROC DTI_SSLInterTransferPJTCreate
GO

-- v2014.01.13 

-- 사내대체등록(프로젝트)_DTI(인터빌링정보 가져오기) by이재천 
CREATE PROC dbo.DTI_SSLInterTransferPJTCreate 
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle  INT,
            @StdYM      NCHAR(6)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @StdYM = ISNULL(StdYM,'') 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
      WITH (StdYM NCHAR(6))
    
    CREATE TABLE #TMP_TPJTProject
    (
        CompanySeq      INT,
        PJTSeq          INT,
        PJTTypeSeq      INT,
        InputSumRate    DECIMAL(19,5)
    )
    -- 프로젝트 매출정보 담기
    INSERT INTO #TMP_TPJTProject ( CompanySeq, PJTSeq, PJTTypeSeq, InputSumRate )
    SELECT A.CompanySeq, A.PJTSeq, A.PJTTypeSeq, B.InputSumRate
      FROM _TPJTProject AS A WITH (NOLOCK)
      JOIN (SELECT A.CompanySeq, A.PJTSeq, A.PJTTypeSeq, A.InputSumRate
              FROM _TPJTERPSales AS A
              JOIN (SELECT A.CompanySeq, A.PJTSeq, A.PJTTypeSeq, A.SalesYM
                      FROM _TPJTERPSales AS A
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.SalesYM = @StdYM
                     --GROUP BY A.CompanySeq, A.PJTSeq, A.PJTTypeSeq 
                   ) AS B ON A.CompanySeq = B.CompanySeq AND A.PJTSeq = B.PJTSeq AND A.PJTTypeSeq = B.PJTTypeSeq AND A.SalesYM = B.SalesYM
            ) AS B ON A.CompanySeq = B.CompanySeq AND A.PJTSeq = B.PJTSeq AND A.PJTTypeSeq = B.PJTTypeSeq
     WHERE A.CompanySeq = @CompanySeq 
    
    -- 품목분류 담기
    SELECT DISTINCT X.ItemSeq,
           Y.UMItemClass   AS ItemTypeSeq,         --제상품유형구분코드
           X.LSeq          AS  ItemClassLSeq,      --품목대분류코드
           X.ValueSeq      AS ItemClassMSeq,       --품목중분류코드
           X.UMItemClass   AS ItemSClassSeq        --품목소분류코드
      INTO #ItemClass
      FROM (  SELECT A.ItemSeq, B.valueseq, C.ValueSeq AS LSeq, A.UMItemClass
                FROM _TDAItemClass AS A
                JOIN _TDAUMinorValue AS B ON A.CompanySeq = B.CompanySeq
                                         AND A.UMItemClass = B.MinorSeq
                                         AND B.serl = 1001
                                         AND A.UMajorItemClass =2001
                JOIN _TDAUMinorValue AS C ON B.CompanySeq = C.CompanySeq
                                         AND B.valueseq = C.MinorSeq
                                         AND C.Serl = 2001
               WHERE A.CompanySeq = @CompanySeq and A.UMajorItemClass = 2001 ) X
      LEFT OUTER JOIN (  SELECT ItemSeq, UMItemClass FROM _TDAItemClass WHERE CompanySeq = @CompanySeq and UMajorItemClass = 1000203 ) Y ON X.ItemSeq = Y.ItemSeq
    
    --================================================================================================================================
    -- 프로젝트 판매단가 입력조회
    --================================================================================================================================
    SELECT B.PJTTypeSeq,
           B.InputSumRate,
           A.*
      INTO #TmpOutPut
      FROM (   -- 재료자원검색
            SELECT A.PJTSeq                    AS PJTSeq,
                   A.ItemSeq                   AS ResourceSeq,         -- 자원규격
                   SUM(A.TotQty)               AS Qty,                 -- 수량
                   MAX(A.Price)                AS PlanPrice,           -- 단가
                   CASE SUM(A.TotQty) WHEN 0 THEN 0 ELSE ROUND(SUM(ISNULL(D.Amt, 0))/SUM(A.TotQty), 0) END AS Price,
                   SUM(ISNULL(D.Amt, 0))       AS Amt,
                   MAX(ISNULL(A.CurrRate, 1))  AS CurrRate,
                   SUM(A.Price * ISNULL(A.CurrRate, 1) * A.TotQty) AS PlanAmt  -- 계획금액
              FROM (  -- 최종 BOM 데이터
                    SELECT A.PJTSeq, A.BOMSerl, A.ItemSeq, A.TotQty, A.Price, A.CurrRate
                      FROM _TPJTBOM AS A WITH (NOLOCK)
                     WHERE A.CompanySeq = @CompanySeq
                       AND A.PJTSeq IN (SELECT PJTSeq FROM #TMP_TPJTProject)
                       AND A.BOMSerl <> -1
                       AND ISNULL(A.BeforeBOMSerl,0) = 0
                       --AND (ISNULL(A.IssueSeq, 0) = @IssueSeq)
                    UNION ALL
                    -- 과거 BOM 데이터
                    SELECT A.PJTSeq, A.BOMSerl, A.ItemSeq, A.TotQty, A.Price, A.CurrRate
                      FROM _TPJTBOMRevHist AS A WITH (NOLOCK)
                     WHERE A.CompanySeq = @CompanySeq
                       AND A.PJTSeq IN (SELECT PJTSeq FROM #TMP_TPJTProject)
                       AND A.BOMSerl <> -1
                       --AND (ISNULL(A.IssueSeq, 0) = @IssueSeq)
                   ) AS A
              LEFT OUTER JOIN DTI_TPJTBOM     AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.PJTSeq = A.PJTSeq AND D.BOMSerl = A.BOMSerl
             GROUP BY A.PJTSeq, A.ItemSeq
           ) AS A
      JOIN #TMP_TPJTProject AS B ON B.PJTSeq = A.PJTSeq
     ORDER BY B.PJTTypeSeq, A.PJTSeq, A.ResourceSeq
    
    --================================================================================================================================
    -- 임시 테이블 제거
    --================================================================================================================================
    DROP TABLE #TMP_TPJTProject
    
    DECLARE @Tmp DECIMAL(19, 5)
    SET @Tmp = 0
    
    SELECT A.PJTSeq,
           A.PJTTypeSeq,
           A.InputSumRate,
           A.ResourceSeq,
           A.Qty,
           A.PlanPrice,
           A.Price,
           A.Amt,
           A.CurrRate,
           A.PlanAmt,
           B.ItemTypeSeq,
           B.ItemClassLSeq,
           B.ItemClassMSeq,
           B.ItemSClassSeq,
           0 AS OwnerShipDeptSeq,
           @Tmp AS InterbillingRate 
      INTO #OutPut
      FROM #TmpOutPut AS A
      LEFT OUTER JOIN #ItemClass AS B ON A.ResourceSeq = B.ItemSeq
    
    UPDATE A
       SET OwnerShipDeptSeq = ISNULL(C.DeptSeq,0),
           InterbillingRate = ISNULL(C.IBPercent,0)
      FROM #OutPut AS A
      LEFT OUTER JOIN DTI_TSLInterBillingBase AS C ON C.CompanySeq = @CompanySeq
                                                  AND C.ItemTypeSeq = A.ItemTypeSeq
                                                  AND C.ItemClassSeq = A.ItemClassMSeq 
     WHERE ISNULL(C.ItemSClassSeq,0) = 0 
       AND C.IBPercent <> 0 
    
    SELECT A.ItemClassMSeq, COUNT(DISTINCT C.DeptSeq) AS Cnt 
      INTO #TMP_Count
      FROM #OutPut AS A
      LEFT OUTER JOIN DTI_TSLInterBillingBase AS C ON C.CompanySeq = @CompanySeq
                                                  AND C.ItemTypeSeq = A.ItemTypeSeq
                                                  AND C.ItemClassSeq = A.ItemClassMSeq 
      JOIN _TPDSFCMatinput                    AS D ON ( D.CompanySeq = @CompanySeq 
                                                    AND D.MatItemSeq = A.ResourceSeq 
                                                    AND LEFT(D.InputDate,6) = @StdYM
                                                      )
     WHERE ISNULL(C.ItemSClassSeq,0) = 0 
       AND C.IBPercent <> 0 
     GROUP BY A.ItemTypeSeq, A.ItemClassMSeq, A.PJTSeq 
     HAVING COUNT(DISTINCT C.DeptSeq) > 1 
    
    SELECT XX.*,
           ISNULL(Z.Amt, 0) AS InputAmt,
           Z.Date AS InputYM,
           ISNULL(Z.Qty, 0) AS InputQty,
           CASE WHEN XX.PlanAmt = 0 THEN 0 ELSE (ISNULL(Z.Amt, 0)/XX.PlanAmt) * 100 END AS InputProgRate,
           XX.InterbillingRate * (CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END - ISNULL(Z.Amt, 0)) / 100. AS InterbillingAmt,
           (CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END - ISNULL(Z.Amt, 0)) AS GP,      -- 판매금액 - 수요계획금액
           CASE WHEN CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END = 0 THEN 0 ELSE ((CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END - ISNULL(Z.Amt, 0))/
           CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END * 100) END AS GPRate,      -- (판매금액 - 계획금액) / 판매금액
           CASE XX.Qty WHEN 0 THEN 0 ELSE ROUND(XX.Amt / XX.Qty * ISNULL(Z.Qty, 0), 0) END AS Cost
      INTO #Tmp_InterBilling
      FROM #OutPut AS XX
      LEFT OUTER JOIN ( SELECT PjtSeq AS PjtSeq,
                               Date AS Date,
                               SUM(AMT) AS Amt,
                               SUM(Qty) AS Qty,
                               ResourceSeq ,
                               Kind
                          FROM ( -- 재료자원
                                SELECT 1 as Kind, I.PjtSeq,
                                       (LEFT(I.InputDate, 6)) AS Date,
                                       (ISNULL(Y.Amt, 0)) AS Amt,
                                       (Y.Qty) AS QTY,
                                       I.MatItemSeq AS ResourceSeq
                                  FROM _TPDSFCMatinput    AS I WITH(NOLOCK)                                       -- 자재투입테이블
                                  LEFT OUTER JOIN _TPJTProject  AS X WITH(NOLOCK) ON I.CompanySeq = X.CompanySeq          -- 프로젝트체크09.1.3 김현
                                                                                 AND I.PJTSeq     = X.PJTSeq
                                  LEFT OUTER JOIN _TLGInOutStock AS Y WITH(NOLOCK) ON I.CompanySeq = Y.CompanySeq
                                                                                  AND I.WorkReportSeq = Y.InOutSeq
                                                                                  AND I.ItemSerl = Y.InOutSubSerl
                                                                                  AND Y.InOutType = 130
                                 WHERE I.CompanySeq = @CompanySeq
                                   AND (LEFT(I.InputDate,6) = @StdYM)
                               ) Y  
                         GROUP BY y.Kind, Y.PJTSeq, Y.Date, Y.ResourceSeq
                      ) AS Z ON Z.PjtSeq = XX.PjtSeq  AND Z.ResourceSeq = XX.Resourceseq AND ISNULL(Z.ResourceSeq, 0) <> 0
     WHERE XX.InterbillingRate <> 0 
      AND Z.Date = @StdYM
     ORDER BY XX.PJTTypeSeq, XX.PJTSeq, XX.ResourceSeq
    
   DELETE A
     FROM DTI_TSLInterTransferPJT AS A 
    WHERE A.CompanySeq = @CompanySeq
      AND (A.StdYM = @StdYM 
       OR  A.InputYM = @StdYM)
   
    INSERT INTO DTI_TSLInterTransferPJT 
        (
            CompanySeq, InputYM, PJTSeq, ResourceSeq, StdYM,
            
            ReceiptDeptSeq, SendDeptSeq, SalesAmt, GPAmt, 
            OwnershipGPAmt, 
            
            PJTProcRate, PreInterBillingAmt, 
            InterBillingAmt, 
            LastUserSeq, LastDateTime,
            
            InterbillingAmtSub
        )
    SELECT @CompanySeq, A.InPutYM, A.PJTSeq, A.ResourceSeq, @StdYM, 
    
           A.ReceiptDeptSeq, A.SendDeptSeq, A.SalesAmt, A.GPAmt,
           A.OwnershipGPAmt, 
           
           C.InPutSumRate, ISNULL(A.PreInterBillingAmt,0) + ISNULL(A.InterBillingAmt,0), 
           CASE WHEN FLOOR(ISNULL(A.PreInterBillingAmt,0) + ISNULL(A.InterBillingAmt,0)) = FLOOR(A.InterbillingAmtSub)
                THEN 0 
                ELSE (ISNULL(A.InterbillingAmtSub,0) * ISNULL(C.InPutSumRate,0) / 100) - (ISNULL(A.PreInterBillingAmt,0) + ISNULL(A.InterBillingAmt,0))
                END , 
           @UserSeq, GETDATE(), 
           
           FLOOR(A.InterbillingAmtSub)
      FROM DTI_TSLInterTransferPJT AS A 
      LEFT OUTER JOIN #Tmp_InterBilling AS B WITH(NOLOCK) ON ( A.PJTSeq = B.PJTSeq ) 
      JOIN #OutPut                      AS C WITH(NOLOCK) ON ( C.PJTSeq = A.PJTSeq AND C.ResourceSeq = A.ResourceSeq )--AND A.ReceiptDeptSeq = C.OwnerShipDeptSeq ) 
     WHERE A.StdYm = CONVERT(NCHAR(6),DATEADD(MONTH,-1,@StdYM + '01'),112) 
       AND A.PJTProcRate < 100 
       AND FLOOR(ISNULL(A.PreInterBillingAmt,0) + ISNULL(A.InterBillingAmt,0)) < FLOOR(A.InterbillingAmtSub)
       AND A.CompanySeq = @CompanySeq 
    UNION ALL
    SELECT @CompanySeq, A.InPutYM, A.PJTSeq, A.ResourceSeq, @StdYM, 
    
           A.OwnershipDeptSeq, B.ChargeDeptSeq, ISNULL(A.Price,0) * ISNULL(A.InPutQty,0), (ISNULL(A.Price,0) * ISNULL(A.InPutQty,0)) - ISNULL(A.InPutAmt,0), 
           FLOOR(((ISNULL(A.Price,0) * ISNULL(A.InPutQty,0)) - ISNULL(A.InPutAmt,0)) * A.InterbillingRate / 100), 
           
           A.InputSumRate, 0, 
           FLOOR((((ISNULL(A.Price,0) * ISNULL(A.InPutQty,0)) - ISNULL(A.InPutAmt,0)) * A.InterbillingRate / 100) * ISNULL(A.InputSumRate,0) / 100), 
           @UserSeq, GETDATE(), 
           
           FLOOR(((ISNULL(A.Price,0) * ISNULL(A.InPutQty,0)) - ISNULL(A.InPutAmt,0)) * A.InterbillingRate / 100)
      FROM #Tmp_InterBilling AS A 
      LEFT OUTER JOIN _TPJTProject AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE ISNULL(A.InputYM, '') <> ''
    
    SELECT CASE WHEN EXISTS (SELECT 1 FROM #TMP_Count) 
                THEN N'인터빌링 중분류가 여러부서에 연결되어 있습니다. [ 중분류명 : '+ (SELECT MAX(ItemClasMName)
                                                                                         FROM _FDAGetItemClass(@CompanySeq, 0) AS A
                                                                                        WHERE A.ItemClassMSeq = ( SELECT TOP 1 ItemClassMSeq from #TMP_Count )) 
                                                                                     +' ] [ 부서명 : '+(SELECT REPLACE(REPLACE(REPLACE((SELECT B.DeptName 
                                                                                                          FROM DTI_TSLInterBillingBase AS A 
                                                                                                           JOIN _TDADept               AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
                                                                                                          WHERE A.CompanySeq = @CompanySeq 
                                                                                                            AND A.ItemClassSeq IN( SELECT TOP 1 ItemClassMSeq from #TMP_Count )
                                                                                                            AND A.IBPercent <> 0 
                                                                                                            FOR XML AUTO, ELEMENTS), '</DeptName></B><B><DeptName>',','),'<B><DeptName>',''),'</DeptName></B>',''))+' ]' 
                ELSE '' END  AS Result, 
           CASE WHEN EXISTS (SELECT 1 FROM #TMP_Count) THEN 1234 ELSE 0 END AS Status, 
           @StdYM AS StdYM,  
           C.DeptName AS ReceiptDeptName, 
           A.ReceiptDeptSeq, 
           A.SendDeptSeq, 
           D.DeptName AS SendDeptName, 
           A.ResourceSeq, 
           E.ItemName AS ResourceName, 
           B.PJTName, 
           A.InputYM, 
           A.InterBillingAmt, 
           A.PreInterBillingAmt, 
           A.SalesAmt, 
           ISNULL(F.InterBillingRate,I.InterBillingRate) AS OwnershipRate, 
           G.CustName, 
           B.CustSeq, 
           A.PJTProcRate, 
           A.GPAmt, 
           B.PJTSeq, 
           InterBillingAmtSub AS InterBillingSumAmt 
    
      FROM DTI_TSLInterTransferPJT AS A 
      LEFT OUTER JOIN _TPJTProject AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDADept     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.ReceiptDeptSeq ) 
      LEFT OUTER JOIN _TDADept     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = SendDeptSeq ) 
      LEFT OUTER JOIN _TDAItem     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ResourceSeq ) 
      LEFT OUTER JOIN #Tmp_InterBilling AS F WITH(NOLOCK) ON ( F.PJTSeq = A.PJTSeq AND F.InPutYM = A.InPutYM AND F.ResourceSeq = A.ResourceSeq ) 
      LEFT OUTER JOIN _TDACust          AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN #OutPut           AS I              ON ( I.PJTSeq = A.PJTSeq AND I.ResourceSeq = A.ResourceSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdYm = @StdYM
    
    IF EXISTS (SELECT 1 FROM #TMP_Count) 
    BEGIN 
        DELETE A
          FROM DTI_TSLInterTransferPJT AS A 
         WHERE A.CompanySeq = @CompanySeq
           AND (A.StdYM = @StdYM 
            OR  A.InputYM = @StdYM)
    END
    
    RETURN
    
GO
begin tran 
exec DTI_SSLInterTransferPJTCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201106</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020494,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1017229
rollback  