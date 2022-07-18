
IF OBJECT_ID('DTI_SLGLongStockPlanItemQuery') IS NOT NULL 
    DROP PROC DTI_SLGLongStockPlanItemQuery
GO 

-- v2014.01.02 

-- 재고소진계획작성(계약)_DTI(조회) by이재천                         
  CREATE PROC DTI_SLGLongStockPlanItemQuery                  
      @xmlDocument   NVARCHAR(MAX), 
      @xmlFlags      INT = 0, 
      @ServiceSeq    INT = 0, 
      @WorkingTag    NVARCHAR(10)= '', 
      @CompanySeq    INT = 1, 
      @LanguageSeq   INT = 1, 
      @UserSeq       INT = 0, 
      @PgmSeq        INT = 0 
                      
  AS                    
     
     DECLARE @docHandle          INT,                    
             @StdYM              NCHAR(6),   -- 기준월                    
             @DeptSeq            INT,        -- 부서                    
             @EmpSeq             INT,                    
             @IsMngStock         NCHAR(1),--관리재고                    
             @IsEtcCondition1    NCHAR(1),                    
             @IsEtcCondition2    NCHAR(1),                    
             @IsEtcCondition3    NCHAR(1),                    
             @UnSold             NCHAR(1),                    
             @SchBegMonth        NCHAR(6),   -- 시작월,                    
             @SchEndMonth        NCHAR(6),   -- 종료월                    
             @ItemSeq            INT,                    
             @IsOrgDept          NCHAR(1),    -- 하위부서포함여부                    
             @LongMonthFrom      INT,                    
             @LongMonthTo        INT,                    
             @ProductType        INT,                  
             @IsZero             NCHAR(1)
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                    
     
     SELECT @StdYM      = ISNULL(StdYM, ''),                    
            @DeptSeq    = ISNULL(DeptSeq, 0),                    
            @EmpSeq     = ISNULL(EmpSeq, 0),                    
            @IsMngStock = ISNULL(IsMngStock, '0'),                    
            @IsEtcCondition1   = ISNULL(IsEtcCondition1, '0'),                    
            @IsEtcCondition2   = ISNULL(IsEtcCondition2, '0'),                    
            @IsEtcCondition3   = ISNULL(IsEtcCondition3, '0'),                    
            @UnSold            = ISNULL(UnSold,'0'),                    
            @SchBegMonth       =SchBegMonth,                    
            @SchEndMonth       =SchEndMonth,                    
            @ItemSeq           =ISNULL(ItemSeq, ''),                    
            @IsOrgDept         =ISNULL(IsOrgDept, ''),                    
            @LongMonthFrom     =ISNULL(LongMonthFrom, 0),                    
            @LongMonthTo       =ISNULL(LongMonthTo, 0),                    
            @ProductType       =ISNULL(ProductType, 0), 
            @IsZero            =ISNULL(IsZero, '0')                    
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                          
       WITH ( StdYM          NCHAR(6),                    
              DeptSeq        INT,                    
              EmpSeq         INT,                    
              IsMngStock     NCHAR(1),                    
              IsEtcCondition1    NCHAR(1),                    
              IsEtcCondition2    NCHAR(1),                    
              IsEtcCondition3    NCHAR(1),                    
              UnSold             NCHAR(1),                    
              SchBegMonth    NCHAR(6),                     
              SchEndMonth    NCHAR(6),                     
              ItemSeq        INT,                    
              IsOrgDept      NCHAR(1),                    
              LongMonthFrom  INT,                
              LongMonthTo    INT,                    
              ProductType     INT, 
              IsZero          INT 
            )                          
     
     IF @SchBegMonth is NULL                  
         SELECT @SchBegMonth = CONVERT(NCHAR(6),DATEADD(MONTH, -1, @StdYM + '01'),112)                  
     IF @SchEndMonth is NULL                  
         SELECT @SchEndMonth = @StdYM            
    IF @SchBegMonth = ''                  
         SELECT @SchBegMonth = CONVERT(NCHAR(6),DATEADD(MONTH, -1, @StdYM + '01'),112)                    
     IF @SchEndMonth = ''                  
         SELECT @SchEndMonth = ISNULL(@StdYM, '999912')                  
     
     ---------------------- 조직도 연결 여부                        
     DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)                        
     
     SELECT @OrgStdDate = @SchEndMonth + '01'                        
     
     SELECT @SMOrgSortSeq = 0                        
     SELECT @SMOrgSortSeq = SMOrgSortSeq                        
       FROM _TCOMOrgLinkMng                        
      WHERE CompanySeq = @CompanySeq                        
        AND PgmSeq = @PgmSeq                        
     
      DECLARE @DeptTable Table                        
      ( DeptSeq INT)                        
     
     INSERT @DeptTable                        
     SELECT DISTINCT DeptSeq                      
       FROM dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)                        
     --select * from DTI_TLGLongStockItem                    
     
  ---------------------- 조직도 연결 여부                        
  --관리대상재고 합계  DataBlock2 MngStockSum
  --예상출고금액 합계  DataBlock2 TotalOutAmt
  --예상재고금액 합계  DataBlock2 TotalStockAmt
    
    CREATE TABLE #DTI_TLGLongStockItem 
        (
            CompanySeq      INT,
            StdYM           NCHAR(6), 
            DeptSeq         INT, 
            ItemSeq         INT, 
            LotNo           NVARCHAR(100), 
            EmpSeq          INT, 
            StockQty        DECIMAL(19,5), 
            Price           DECIMAL(19,5), 
            InDate          NCHAR(8), 
            LongMonth       INT, 
            EstSalesDate    NVARCHAR(100), 
            StockPlan       NVARCHAR(100), 
            SpecNote        NVARCHAR(200), 
            LastUserSeq     INT, 
            LastDateTime    DATETIME, 
            IsMngStock      NCHAR(1), 
            IsEtcCondition1 NCHAR(1), 
            IsEtcCondition2 NCHAR(1), 
            IsEtcCondition3 NCHAR(1), 
            EstSalesQty     DECIMAL(19,5), 
            ContractSYM     NCHAR(6), 
            ContractEYM     NCHAR(6), 
            UMSalesCond     INT, 
            UMStockKind     INT, 
            Feedback        NVARCHAR(200), 
            ContractSeq     INT, 
            ContractSerl    INT 
        )

        IF @IsZero = '0' 
        BEGIN
            INSERT INTO #DTI_TLGLongStockItem
            SELECT *
              FROM DTI_TLGLongStockItem AS A
             WHERE A.CompanySeq = @CompanySeq 
             AND A.StockQty <> 0 
             AND A.StdYM BETWEEN @SchBegMonth AND @SchEndMonth                    
          ---------- 조직도 연결 변경 부분                          
             AND (@DeptSeq = 0                    
              OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)                              
              OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))    
          ---------- 조직도 연결 변경 부분                                
             AND (@EmpSeq = 0 Or A.EmpSeq = @EmpSeq)                    
             AND (@IsMngStock = 0 OR A.IsMngStock = @IsMngStock )                  
             AND (@IsEtcCondition1 = '0' OR A.IsEtcCondition1 = @IsEtcCondition1)                    
             AND (@IsEtcCondition2 = '0' OR A.IsEtcCondition2 = @IsEtcCondition2)                    
             AND (@IsEtcCondition3 = '0' OR A.IsEtcCondition3 = @IsEtcCondition3)  
             AND (@LongMonthFrom = 0 OR A.LongMonth >= @LongMonthFrom)       
             AND (@LongMonthTo = 0 OR A.LongMonth <= @LongMonthTo) 
         END     
         ELSE 
         BEGIN
              INSERT INTO #DTI_TLGLongStockItem
              SELECT *
                FROM DTI_TLGLongStockItem AS A
               WHERE A.CompanySeq = @CompanySeq 
                 AND A.StdYM BETWEEN @SchBegMonth AND @SchEndMonth                    
       ---------- 조직도 연결 변경 부분                          
                 AND (@DeptSeq = 0                    
                  OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)                              
                  OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))    
              ---------- 조직도 연결 변경 부분                                
                 AND (@EmpSeq = 0 Or A.EmpSeq = @EmpSeq)                    
                 AND (@IsMngStock = 0 OR A.IsMngStock = @IsMngStock )                  
                 AND (@IsEtcCondition1 = '0' OR A.IsEtcCondition1 = @IsEtcCondition1)                    
                 AND (@IsEtcCondition2 = '0' OR A.IsEtcCondition2 = @IsEtcCondition2)                    
                 AND (@IsEtcCondition3 = '0' OR A.IsEtcCondition3 = @IsEtcCondition3)  
                 AND (@LongMonthFrom = 0 OR A.LongMonth >= @LongMonthFrom)       
                 AND (@LongMonthTo = 0 OR A.LongMonth <= @LongMonthTo) 
         END
         
        SELECT ROW_NUMBER() OVER(ORDER BY B.OrderSeq) AS IDX_NO, B.OrderSeq, B.OrderSerl 
          INTO #TSLOrderItem
          FROM #DTI_TLGLongStockItem AS A 
          JOIN _TSLOrderItem        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.Dummy6 = A.ContractSeq AND B.Dummy7 = A.ContractSerl ) 
        
        CREATE TABLE #TMP_ProgressTable 
            (IDOrder   INT, 
            TableName NVARCHAR(100)) 
        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
            SELECT 1, '_TSLInvoiceItem'   -- 데이터 찾을 테이블
        CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
       
        EXEC _SCOMProgressTracking 
                @CompanySeq = @CompanySeq, 
                @TableName = '_TSLOrderItem',    -- 기준이 되는 테이블
                @TempTableName = '#TSLOrderItem',  -- 기준이 되는 템프테이블
                @TempSeqColumnName = 'OrderSeq',  -- 템프테이블의 Seq
                @TempSerlColumnName = 'OrderSerl',  -- 템프테이블의 Serl
                @TempSubSerlColumnName = ''  
          
        SELECT B.Seq AS InvoiceSeq, B.Serl AS InvoiceSerl, A.OrderSeq, A.OrderSerl 
          INTO #TSLOrderItem_SUB
          FROM #TSLOrderItem AS A 
          JOIN #TCOMProgressTracking AS B ON ( A.IDX_NO = B.IDX_NO ) 
          --select * from #TSLOrderItem_SUB
        SELECT A.StdYM         AS StdYM,           -- 기준월                      
               A.DeptSeq       AS DeptSeq,         -- 부서코드                      
               A.ItemSeq       AS ItemSeq,         -- 자재내역                      
               A.LotNo         AS LotNo,           -- Lot No                       
               A.EmpSeq        AS EmpSeq,          -- 담당자코드                      
               A.StockQty      AS StockQty,        -- 가용재고                      
               ROUND(A.Price,0) AS Price,           -- 단가                      
               A.InDate        AS InDate,          -- 매입일                      
               A.LongMonth     AS LongMonth,       -- 보유개월                      
               A.EstSalesDate  AS EstSalesDate,    -- 매출예정일                      
               A.StockPlan     AS StockPlan,       -- 재고소진계획      
               H.StockPlan     AS PreStockPlan,                      
               A.SpecNote      AS SpecNote,        -- 매출처 및 특이사항                      
               B.ItemName      AS ItemName,        -- 품명                      
               C.EmpName       AS EmpName,         -- 사원명                      
               (A.StockQty * ROUND(A.Price,0)) AS TotPrice, -- 전체값                      
               H.StockQty      AS PreStockQty,     -- 전월재고                      
               A.UMStockKind AS ProductType, --(CASE WHEN F.UMItemClass = '1000203003' THEN 0 ELSE 1 END) AS ProductType,                      
               A.IsMngStock, -- 관리재고                      
               A.IsEtcCondition1,                       
               A.IsEtcCondition2,                       
               A.IsEtcCondition3,                       
               A.EstSalesQty ,                      
               A.ContractSYM ,                      
               A.ContractEYM ,                      
               A.Feedback,                      
               --A.UMSalesCond,      
               H.EstSalesDate AS PreEstSalesDate,   
               A.ContractSeq,   
               A.ContractSerl,    
               CASE WHEN CONVERT(INT,I.Memo1) = K.CustSeq AND CONVERT(INT,I.Memo2) = K.BKCustSeq THEN 1 ELSE 0 END AS IsNormal,   
               CASE WHEN CONVERT(NVARCHAR(8),GETDATE(),112) > L.EDate THEN 1 ELSE 0 END AS IsContractEnd,   
               ISNULL(U.Qty, M.Qty) FPlanQty,   
               L.SDate AS ContractFrDate,   
               L.EDate AS ContractToDate,   
               O.CustName,  
               L.CustSeq AS CustSeq,   
               P.CustName AS EndUser,   
               L.BKCustSeq AS EndUserSeq, 
               T.MinorName AS UMSalesCondName,  
               L.UMSalesCond AS UMSalesCond,  
               T.MinorName AS UMSalesCondSubName,  
               L.UMSalesCond AS UMSalesCondSub,  
               ISNULL(R.CustName,O.CustName) AS FCustName,  
               ISNULL(R.CustSeq,L.CustSeq) AS FCustSeq,   
               ISNULL(W.CustName,P.CustName) AS FEndUser,   
               ISNULL(Y.BKCustSeq,L.BKCustSeq) AS FEndUserSeq,   
               ISNULL(Y.SDate,L.SDate) AS FContractFrDate,   
               ISNULL(Y.EDate, L.EDate) AS FContractToDate,   
               ISNULL(S.MinorName,T.MinorName) AS FUMSalesCondName,   
               ISNULL(Y.UMSalesCond,L.UMSalesCond) AS FUMSalesCond,  
               ISNULL((SELECT SUM(S.Qty)   
                         FROM _TSLInvoice AS R   
                         LEFT OUTER JOIN _TSLInvoiceItem AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.InvoiceSeq = R.InvoiceSeq )   
                        WHERE R.CompanySeq = @CompanySeq   
                          AND R.IsDelvCfm = '1'   
                          AND S.InvoiceSeq = Q.InvoiceSeq 
                          AND S.InvoiceSerl = Q.InvoiceSerl 
                      ),0) AS RealQty,  
               ISNULL(A.StockQty,0) - ISNULL((SELECT SUM(S.Qty)   
                                                FROM _TSLInvoice AS R   
                                                LEFT OUTER JOIN _TSLInvoiceItem AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.InvoiceSeq = R.InvoiceSeq )   
                                               WHERE R.COmpanySeq = @CompanySeq   
                                                 AND R.IsDelvCfm = '1'   
                                                 AND R.InvoiceSeq = Q.InvoiceSeq   
                                             ),0
                                            ) AS DiffQty,  
                CASE WHEN ISNULL(H.StockQty,0)  <> 0    
                     THEN ISNULL(H.StockQty,0) 
                     ELSE 0    
                     END AS LastMQty, 
               H.EstSalesDate AS LastMEstSalesDate, 
               (SELECT MinorName FROM _TDAUMinor AS Z WHERE Z.CompanySeq = @CompanySeq AND Z.MinorSeq = H.UMSalesCond) AS LastMUMSalesCondName, 
               A.EstSalesDate  AS EstSalesDateSub,    -- 매출예정일 
               A.EstSalesQty AS EstSalesQtySub
        
          INTO #TEMP 
          FROM #DTI_TLGLongStockItem AS A WITH (NOLOCK)                      
          LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq 
          LEFT OUTER JOIN _TDAEmp AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq 
          LEFT OUTER JOIN _TDAItemClass AS F WITH (NOLOCK) ON F.CompanySeq = @CompanySeq AND F.UMajorItemClass = 1000203 AND F.ItemSeq = A.ItemSeq 
          LEFT OUTER JOIN #DTI_TLGLongStockItem AS H WITH (NOLOCK) ON H.CompanySeq = @CompanySeq 
                                                                  AND H.StdYM      = CONVERT(CHAR(6), DATEADD(MONTH, -1, A.StdYM + '01'), 112) 
                                                                  AND H.DeptSeq    = A.DeptSeq 
                                                                  AND H.EmpSeq     = A.EmpSeq 
                                                                  AND H.ItemSeq    = A.ItemSeq 
                                                                  AND H.LotNo      = A.LotNo 
          LEFT OUTER JOIN _TPUORDApprovalReqItem AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.Memo3 = A.ContractSeq AND I.Memo4 = A.ContractSerl )   
          LEFT OUTER JOIN DTI_TSLContractMng     AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.ContractSeq = A.ContractSeq )   
          LEFT OUTER JOIN DTI_TSLContractMngItem AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.ContractSeq = A.ContractSeq AND M.ContractSerl = A.ContractSerl  )   
          LEFT OUTER JOIN _TSLOrderItem          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.Dummy6 = A.ContractSeq AND J.Dummy7 = A.ContractSerl )   
          LEFT OUTER JOIN _TSLOrder              AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = J.OrderSeq )   
          LEFT OUTER JOIN _TPUDelvItem           AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.Memo3 = A.ContractSeq AND N.Memo4 = A.ContractSerl )   
          LEFT OUTER JOIN _TDACust               AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = L.CustSeq )   
          LEFT OUTER JOIN _TDACust               AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.CustSeq = L.EndUserSeq )   
          LEFT OUTER JOIN #TSLOrderItem_SUB      AS Q WITH(NOLOCK) ON ( Q.OrderSeq = J.OrderSeq AND Q.OrderSerl = J.OrderSerl )   
          LEFT OUTER JOIN _TDAUMinor             AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.MinorSeq = L.UMSalesCond )   
          LEFT OUTER JOIN DTI_TSLContractMngRev  AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.ContractSeq = L.ContractSeq ) 
          LEFT OUTER JOIN DTI_TSLContractMngItemRev AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq 
                                                                       AND U.ContractSeq = M.ContractSeq 
                                                                       AND U.ContractSerl = M.ContractSerl 
                                                                       AND U.ContractRev = 0
                                                                         ) 
          LEFT OUTER JOIN _TDACust               AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = Y.CustSeq )   
          LEFT OUTER JOIN _TDACust               AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.CustSeq = Y.EndUserSeq )   
          LEFT OUTER JOIN _TDAUMinor             AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = Y.UMSalesCond )   
         WHERE (@UnSold <> '1' OR H.StockQty = A.StockQty)         
        
        SELECT SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 THEN 0 ELSE (ROUND(A.Price, 0) * A.StockQty) END)      AS PDTPrice,                    
               SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 THEN 0 ELSE (A.StockQty) END)        AS PDTQty,                    
               SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 THEN (ROUND(A.Price, 0) * A.StockQty) ELSE 0 END) AS MNPrice,                    
               SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 THEN (A.StockQty) ELSE 0 END)         AS MNQty,                    
               --조회 월 기준 익월만 SUM                  
               SUM(CASE WHEN CONVERT(CHAR(6), A.EstSalesDate) = CONVERT(CHAR(6), DATEADD(MONTH, 1, @SchBegMonth + '01'), 112)  THEN  A.EstSalesQty  ELSE 0 END)   AS TotalOutQty, ---익월예상출고수량                       
               SUM(CASE WHEN CONVERT(CHAR(6), A.EstSalesDate) = CONVERT(CHAR(6), DATEADD(MONTH, 1, @SchBegMonth + '01'), 112)  THEN  ROUND(A.Price, 0) * A.EstSalesQty  ELSE 0 END)   AS TotalOutAmt, ---*
               --전체 SUM
               SUM(ROUND(A.Price,0) * A.StockQty)   AS TotSumPrice,--매입금액 합계                    
               SUM(CASE WHEN A.LongMonth < 4 THEN 0                     
                                                   ELSE (CASE WHEN CONVERT(CHAR(6), A.EstSalesDate) = CONVERT(CHAR(6), DATEADD(MONTH, 1, @SchBegMonth + '01'), 112)  THEN A.EstSalesQty ELSE 0 END)                   
                                           END)   AS LongOutQty, ---장기재고예상 출고수량                   
               SUM(CASE WHEN A.LongMonth < 4 THEN 0                     
                                                   ELSE (CASE WHEN CONVERT(CHAR(6), A.EstSalesDate) = CONVERT(CHAR(6), DATEADD(MONTH, 1, @SchBegMonth + '01'), 112)  THEN ROUND(A.Price, 0) * A.EstSalesQty ELSE 0 END)                           
                                           END)   AS LongOutAmt,   ---장기재고예상 출고금액                      
               SUM(CASE WHEN A.LongMonth < 4 THEN 0 ELSE ROUND(A.Price, 0) * A.StockQty END) AS LongStockAmt  ,                    
               SUM(CASE WHEN A.IsMngStock <> '1' THEN 0 ELSE ROUND(A.Price, 0) * A.StockQty END) AS MngStockAmt  ,                  
               SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 Or A.LongMonth < 4 THEN 0 ELSE (ROUND(A.Price, 0) * A.StockQty) END)      AS LongPDTPrice,                    
               SUM(CASE WHEN ISNULL(A.UMStockKind, 0) = 1000394002 Or A.LongMonth < 4 THEN 0 ELSE (A.StockQty) END)        AS LongPDTQty 
          INTO #TEMP_SUB
          FROM #DTI_TLGLongStockItem AS A WITH (NOLOCK)                    
          LEFT OUTER JOIN #DTI_TLGLongStockItem AS H WITH (NOLOCK) ON H.CompanySeq = @CompanySeq                     
                                                                  AND H.StdYM       = CONVERT(CHAR(6), DATEADD(MONTH, -1, A.StdYM + '01'), 112)                    
                                                                  AND H.DeptSeq     = A.DeptSeq                     
                                                                  AND H.EmpSeq      = A.EmpSeq                    
                                                                  AND H.ItemSeq     = A.ItemSeq                    
                                                                  AND H.LotNo       = A.LotNo                    
        
        SELECT A.*, B.*,                    
               (SELECT DeptName FROM _TDADept where CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,                    
               A.PreStockQty - A.StockQty AS DiffStockQty,               
               B.TotSumPrice - B.TotalOutAmt AS TotalStockAmt ,                  
               B.LongStockAmt - B.LongOutAmt AS LongEstStockAmt,                  
               B.PDTPrice - B.LongPDTPrice AS ShortPDTPrice,                 
               (SELECT MinorName FROM _TDAUMinor where CompanySeq = @CompanySeq AND MinorSeq = A.ProductType) AS ProductTypeName 
          FROM #TEMP AS A                     
          JOIN #TEMP_SUB AS B ON ( 1 = 1 ) 
         ORDER BY A.ProductType, A.EmpSeq                    
    
    RETURN
GO
exec DTI_SLGLongStockPlanItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EmpSeq />
    <IsMngStock>0</IsMngStock>
    <IsEtcCondition1>0</IsEtcCondition1>
    <IsEtcCondition2>0</IsEtcCondition2>
    <IsEtcCondition3>0</IsEtcCondition3>
    <UnSold>0</UnSold>
    <ProductType />
    <IsZero>0</IsZero>
    <StdYM>201401</StdYM>
    <DeptSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020091,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016908