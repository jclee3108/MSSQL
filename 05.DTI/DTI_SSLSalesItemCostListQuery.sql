
IF OBJECT_ID('DTI_SSLSalesItemCostListQuery') IS NOT NULL 
    DROP PROC DTI_SSLSalesItemCostListQuery
GO 

-- v2014.02.10 

-- 매출품목원가현황(조회) by이재천 (계약번호추가)
CREATE PROC DTI_SSLSalesItemCostListQuery          
     @xmlDocument    NVARCHAR(MAX),                
     @xmlFlags       INT     = 0,                
     @ServiceSeq     INT     = 0,                
     @WorkingTag     NVARCHAR(10)= '',                
     @CompanySeq     INT     = 1,                
     @LanguageSeq    INT     = 1,                
     @UserSeq        INT     = 0,                
     @PgmSeq         INT     = 0                
 AS                 
    
    DECLARE @docHandle      INT,                  
            @BizUnit        INT,                   
            @SalesDateFr    NCHAR(8),                   
            @SalesDateTo    NCHAR(8),                 
            @SalesNo        NVARCHAR(20),                    
            @SMExpKind      INT,                 
            @DeptSeq        INT,                   
            @EmpSeq         INT,                   
            @CustSeq        INT,                  
            @CustNo         NVARCHAR(20),                   
            @ItemSeq        INT,                   
            @ItemNo         NVARCHAR(30),                  
            @PJTName        NVARCHAR(100),                  
            @PJTNo          NVARCHAR(100),                
            @AssetSeq       INT,                
            @BillNo         NVARCHAR(20),                
            @InvoiceNo      NVARCHAR(20),            
            @UMItemClassL   INT,            
            @UMItemClassM   INT,            
            @UMItemClassS   INT,            
            @ItemTypeSeq    INT,            
            @ContractNo     NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                   
    
    
    SELECT @BizUnit        = ISNULL(BizUnit, 0),                   
           @SalesDateFr    = ISNULL(SalesDateFr, ''),                   
           @SalesDateTo    = ISNULL(SalesDateTo, ''),                  
           @SalesNo        = LTRIM(RTRIM(ISNULL(SalesNo, ''))),                 
           @SMExpKind      = ISNULL(SMExpKind, 0),                   
           @DeptSeq        = ISNULL(DeptSeq, 0),                   
           @EmpSeq         = ISNULL(EmpSeq, 0),                   
           @ItemSeq        = ISNULL(ItemSeq, 0),                  
           @ItemNo         = LTRIM(RTRIM(ISNULL(ItemNo, ''))),                   
           @CustSeq        = ISNULL(CustSeq, 0),                  
           @CustNo         = LTRIM(RTRIM(ISNULL(CustNo, ''))),                   
           @PJTName        = ISNULL(PJTName, ''),                  
           @PJTNo          = ISNULL(PJTNo, ''),                
           @AssetSeq       = ISNULL(AssetSeq, 0),                
           @BillNo         = ISNULL(BillNo, ''),                
           @InvoiceNo      = ISNULL(InvoiceNo, ''),            
           @UMItemClassL   = ISNULL(UMItemClassL, 0),             
           @UMItemClassM   = ISNULL(UMItemClassM, 0),             
           @UMItemClassS   = ISNULL(UMItemClassS, 0),             
           @ItemTypeSeq    = ISNULL(ItemTypeSeq, 0),              
           @ContractNo     = ISNULL(ContractNo, '') 
    
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                       
     WITH (  BizUnit         INT,                 
             SalesDateFr     NCHAR(8),                 
             SalesDateTo     NCHAR(8),                 
             SalesNo         NVARCHAR(20),                 
             SMExpKind       INT,                   
             DeptSeq         INT,                 
             EmpSeq          INT,                      
             CustSeq         INT,                       
             CustNo          NVARCHAR(20),                 
             ItemSeq         INT,                 
             ItemNo          NVARCHAR(30),                   
             PJTName         NVARCHAR(100),                 
             PJTNo           NVARCHAR(100),                
             AssetSeq        INT,                
             BillNo          NVARCHAR(20),                
             InvoiceNo       NVARCHAR(20),            
             UMItemClassL    INT,            
             UMItemClassM    INT,            
             UMItemClassS    INT,            
             ItemTypeSeq     INT, 
             ContractNo      NVARCHAR(100) 
          )               
    
    IF @SalesDateTo = ''                  
        SELECT @SalesDateTo = '99991231'               
     --=====================================================================================================================              
     -- 매출정보 검색              
     --=====================================================================================================================              
 ---------------------- 조직도 연결 여부  ----------------------                
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)                  
    
    IF @SalesDateTo = '99991231'                  
        SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)                  
    ELSE                  
        SELECT  @OrgStdDate = @SalesDateTo                 
    
    SELECT  @SMOrgSortSeq = 0                  
    SELECT  @SMOrgSortSeq = SMOrgSortSeq                  
      FROM  _TCOMOrgLinkMng                  
     WHERE  CompanySeq = @CompanySeq                  
       AND  PgmSeq     = @PgmSeq                  
    
    DECLARE @DeptTable Table                  
    (   DeptSeq     INT)                  
    
    INSERT  @DeptTable                  
    SELECT  DISTINCT DeptSeq                  
      FROM  dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)                  
    
 ---------------------- 조직도 연결 여부 ----------------------                
    
    CREATE TABLE #Temp_Sales              
    (              
        IDX_NO      INT IDENTITY(1,1),                    
        SalesSeq    INT,                    
        SalesSerl   INT,              
        BillSeq     INT              
     )              
    
    INSERT INTO #Temp_Sales (SalesSeq, SalesSerl, BillSeq)                
    SELECT A.SalesSeq, A.SalesSerl, F.BillSeq                
      FROM _TSLSalesItem AS A WITH (NOLOCK)                
             JOIN _TSLSales AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq                
                                              AND A.SalesSeq = B.SalesSeq                
             LEFT OUTER JOIN _TDACust AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq                
                                                         AND B.CustSeq = C.CustSeq                                                             
                 
             LEFT OUTER JOIN _TDAItem AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq                
                                                         AND A.ItemSeq = D.ItemSeq                
             LEFT OUTER JOIN _TPJTProject AS E WITH (NOLOCK) ON A.CompanySeq = E.CompanySeq                
                                                            AND A.PJTSeq = E.PJTSeq                
             LEFT OUTER JOIN _TSLSalesBillRelation AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq                
                                                                    AND A.SalesSeq   = F.SalesSeq                
                                                                    AND A.SalesSerl  = F.SalesSerl                
                             
     WHERE A.CompanySeq = @CompanySeq                
       AND (@BizUnit = 0 OR B.BizUnit = @BizUnit)                  
       AND (B.SalesDate BETWEEN @SalesDateFr AND @SalesDateTo)                  
       AND (@SalesNo = '' OR B.SalesNo LIKE @SalesNo + '%')                  
       AND (@SMExpKind = 0 OR B.SMExpKind = @SMExpKind)                
 ---------- 조직도 연결 변경 부분                    
       AND (@DeptSeq = 0                   
            OR (@SMOrgSortSeq = 0 AND B.DeptSeq = @DeptSeq)                        
            OR (@SMOrgSortSeq > 0 AND B.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))                        
 ---------- 조직도 연결 변경 부분                       
       AND (@EmpSeq = 0 OR B.EmpSeq = @EmpSeq)                  
       AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)                  
       AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%')                  
       AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)                  
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')                         
       AND (@PJTName = '' OR E.PJTName LIKE @PJTName + '%')          
       AND (@PJTNo   = '' OR E.PJTNo   LIKE @PJTNo   + '%')                     
       AND (@AssetSeq = 0 OR D.AssetSeq = @AssetSeq)                
               
     --=====================================================================================================================              
     -- 매출정보로 거래명세서, 수주정보 SourceTracking              
     --=====================================================================================================================              
               
     -- 결과 테이블              
    CREATE TABLE #TCOMSourceTracking                  
    (                     
         IDX_NO      INT,                  
         IDOrder     INT,                  
         Seq         INT,                 Serl        INT,                  
         SubSerl     INT,                  
         FromQty     DECIMAL(19, 5),                  
         FromAmt     DECIMAL(19, 5) ,                  
         ToQty       DECIMAL(19, 5),                  
         ToAmt       DECIMAL(19, 5)                  
    )                
    
    CREATE TABLE #TMP_SOURCETABLE                   
    (                    
        IDOrder     INT,                    
        TABLENAME   NVARCHAR(100)                    
    )               
    
    INSERT #TMP_SOURCETABLE               
        SELECT '1', '_TSLInvoiceItem'   -- 1. 거래명세서              
    UNION ALL              
        SELECT '2', '_TSLOrderItem'     -- 2. 수주              
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLSalesItem', '#Temp_Sales', 'SalesSeq', 'SalesSerl', ''                   
    
     --=====================================================================================================================              
     -- 매입원가정보 검색              
     --=====================================================================================================================              
     -- 구매입고              
    CREATE TABLE #TMP_DelvIn              
    (              
        IDX_NO      INT,              
        Seq         INT,              
        Serl        INT,              
        InDate      NCHAR(8),              
        CustSeq     INT,              
        UnitSeq     INT,              
        Price       DECIMAL(19,5),              
        Qty         INT,              
        CurAmt      DECIMAL(19,5),              
        DomAmt      DECIMAL(19,5),              
        STDUnitSeq  INT,              
        STDQty      INT              
    )              
               
    -- 기초재고 정보검색              
    DECLARE @StartYM    NCHAR(6),              
            @InitYM     NCHAR(6)              
               
    SET @StartYM = CONVERT(CHAR(6), @SalesDateFr)              
    EXEC dbo._SCOMEnv @CompanySeq,1006, @UserSeq, @@PROCID, @StartYM OUTPUT                      
               
    SELECT @InitYM = FrSttlYM FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND @StartYM BETWEEN FrSttlYM AND ToSttlYM                
    
    INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
    SELECT A.IDX_NO, 0, 0, '', 0, 0, (C.Amt / NULLIF(C.Qty, 0)) AS Price, C.Qty, C.Amt, C.Amt, 0, 0              
      FROM #Temp_Sales AS AA               
           INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
           INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
           INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- 거래명세서      
           INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
           INNER JOIN _TESMGMonthlyLotStockAmt AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq AND C.InOutKind = 8023000              
           INNER JOIN _TESMDCostKey AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.SMCostMng = 5512001 AND D.CostYM = @InitYM AND D.CostKeySeq = C.CostKeySeq              
     WHERE A.IDOrder = '1' 
    
     -- 구매입고 정보검색              
    INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
    SELECT A.IDX_NO, C.DelvInSeq, C.DelvInSerl, D.DelvInDate, D.CustSeq, C.UnitSeq, C.DomPrice, C.Qty, C.CurAmt, C.DomAmt, C.StdUnitSeq, C.StdUnitQty --             
      FROM #Temp_Sales AS AA               
           INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
           INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
           
                 --INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- 거래명세서      
                 JOIN ( SELECT A.*   
                 FROM #TCOMSourceTracking AS A   
                 JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
             ) AS A ON A.IDX_NO = AA.IDX_NO    
                   
         INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
         INNER JOIN _TPUDelvInItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq              
         INNER JOIN _TPUDelvIn AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DelvInSeq = C.DelvInSeq              
     WHERE A.IDOrder = '1'              
       AND NOT EXISTS (SELECT 1 FROM #TMP_DelvIn WHERE IDX_NO = A.IDX_NO)              
            
            
            
      INSERT INTO #TMP_DelvIn ( IDX_NO, Seq, Serl, InDate, CustSeq, UnitSeq, Price, Qty, CurAmt, DomAmt, STDUnitSeq, STDQty )              
     SELECT              
         A.IDX_NO, C.DelvSeq, C.DelvSerl, D.DelvDate, D.CustSeq, C.UnitSeq,        
          CASE WHEN ISNULL(C.Qty, 0) = 0 THEN 0 ELSE (C.DomAmt / C.Qty) END,--C.Price,         
          C.Qty, C.OKCurAmt, C.OKDomAmt, C.StdUnitSeq, C.STDQty              
     FROM #Temp_Sales AS AA               
                 INNER JOIN _TSLSales AS AB WITH (NOLOCK) ON AB.CompanySeq = @CompanySeq AND AB.SalesSeq = AA.SalesSeq              
                 INNER JOIN _TSLSalesItem AS AC WITH (NOLOCK) ON AC.CompanySeq = @CompanySeq AND AC.SalesSeq = AA.SalesSeq AND AC.SalesSerl = AA.SalesSerl              
                   
                 --INNER JOIN #TCOMSourceTracking AS A ON A.IDX_NO = AA.IDX_NO AND A.IDOrder = '1' AND  AC.DomAmt * A.FromAmt >= 0     -- 거래명세서      
               JOIN ( SELECT A.*   
                 FROM #TCOMSourceTracking AS A   
                 JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
             ) AS A ON A.IDX_NO = AA.IDX_NO    
                   
         INNER JOIN _TSLInvoiceItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.Seq AND B.InvoiceSerl = A.Serl              
         INNER JOIN _TUIImpDelvItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.LotNo = B.LotNo AND C.ItemSeq = B.ItemSeq              
         INNER JOIN _TUIImpDelv AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DelvSeq = C.DelvSeq              
     WHERE A.IDOrder = '1'              
       AND NOT EXISTS (SELECT 1 FROM #TMP_DelvIn WHERE IDX_NO = A.IDX_NO)                
       --select * from #TMP_DelvIn            
     --=====================================================================================================================              
     -- 매출대비 원가분석현황 검색              
     --=====================================================================================================================              
 SELECT              
         A.*,              
         (CASE WHEN A.TmpOrderGPRate < -100 THEN -100 WHEN A.TmpOrderGPRate > 100 THEN 100 ELSE A.TmpOrderGPRate END) AS OrderGPRate,    -- 수주GP              
         (CASE WHEN A.TmpInvGPRate < -100 THEN -100 WHEN A.TmpInvGPRate > 100 THEN 100 ELSE A.TmpInvGPRate END) AS InvGPRate,            -- 거래명세서GP              
         (CASE WHEN A.TmpSalesGPRate < -100 THEN -100 WHEN A.TmpSalesGPRate > 100 THEN 100 ELSE A.TmpSalesGPRate END) AS SalesGPRate     -- 매출GP              
     FROM              
     (              
         SELECT              
             A.*,              
             B.ItemNo        AS ItemNo,          -- 품목번호              
             B.ItemName      AS ItemName,        -- 품목명              
             B.Spec          AS Spec,            -- 규격              
           C.AssetName     AS AssetName,       -- 품목자산분류              
             J.SlipID        AS SlipID,          -- 전표번호              
             D.CustName      AS CustName,        -- 매입처명              
             D.CustNo        AS CustNo,          -- 매입처번호   OrderInAmtGPCal   InvoiceInAmtGPCal   SalesInAmtGPCal      
             (ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmtGPCal, 0)) AS OrderGP,     -- 수주GP              
                 (CASE WHEN (ISNULL(A.OrderDomAmt, 0) = ISNULL(A.OrderInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.OrderDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.OrderInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmtGPCal, 0)) / NULLIF(A.OrderDomAmt, 0) * 100, 2), 0) END) AS TmpOrderGPRate,              
             (ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmtGPCal, 0)) AS InvGP,     -- 거래명세서GP              
               (CASE WHEN (ISNULL(A.InvDomAmt, 0) = ISNULL(A.InvoiceInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.InvDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.InvoiceInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmtGPCal, 0)) / NULLIF(A.InvDomAmt, 0) * 100, 2), 0) END) AS TmpInvGPRate,              
             (ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmtGPCal, 0)) AS SalesGP,     -- 매출GP = 원화판매금액 - 매입원가_매출금액          
                 (CASE WHEN (ISNULL(A.DomAmt, 0) = ISNULL(A.SalesInAmtGPCal, 0)) THEN 0               
                       WHEN ISNULL(A.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.SalesInAmtGPCal, 0)) * 100, 2)               
                       ELSE ISNULL(ROUND((ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmtGPCal, 0)) / NULLIF(A.DomAmt, 0) * 100, 2), 0) END) AS TmpSalesGPRate,              
               --(ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmt, 0)) AS OrderGP,     -- 수주GP              
             --    (CASE WHEN (ISNULL(A.OrderDomAmt, 0) = ISNULL(A.OrderInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.OrderDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.OrderInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.OrderDomAmt, 0) - ISNULL(A.OrderInAmt, 0)) / NULLIF(A.OrderDomAmt, 0) * 100, 2), 0) END) AS TmpOrderGPRate,              
             --(ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmt, 0)) AS InvGP,     -- 거래명세서GP              
             --  (CASE WHEN (ISNULL(A.InvDomAmt, 0) = ISNULL(A.InvoiceInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.InvDomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.InvoiceInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.InvDomAmt, 0) - ISNULL(A.InvoiceInAmt, 0)) / NULLIF(A.InvDomAmt, 0) * 100, 2), 0) END) AS TmpInvGPRate,              
             --(ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmt, 0)) AS SalesGP,     -- 매출GP = 원화판매금액 - 매입원가_매출금액          
             --    (CASE WHEN (ISNULL(A.DomAmt, 0) = ISNULL(A.SalesInAmt, 0)) THEN 0               
             --          WHEN ISNULL(A.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(A.SalesInAmt, 0)) * 100, 2)               
             --          ELSE ISNULL(ROUND((ISNULL(A.DomAmt, 0) - ISNULL(A.SalesInAmt, 0)) / NULLIF(A.DomAmt, 0) * 100, 2), 0) END) AS TmpSalesGPRate,              
             (CASE WHEN A.TmpOrderSalesGPRate < -100 THEN -100 WHEN A.TmpOrderSalesGPRate > 100 THEN 100 ELSE A.TmpOrderSalesGPRate END) AS OrderSalesGPRate,    -- 수주GP              
             (SELECT BizUnitName FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND BizUnit = A.BizUnit) AS BizUnitName,-- 사업부문명              
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,         -- 구매부서명              
             (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.EmpSeq) AS EmpName,              -- 구매담당자명              
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.InvDeptSeq) AS InvDeptName,   -- 거래명세서부서명              
             (SELECT EmpName FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.InvEmpSeq) AS InvEmpName,        -- 거래명세서담당자명              
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.InvCustSeq) AS InvCustName,   -- 거래명세서매출처              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq) AS UnitName,         -- 판매단위명              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.STDUnitSeq) AS STDUnitName,   -- 수주기준단위명              
             (SELECT WHName FROM _TDAWH WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq) AS WHName,                   -- 창고명              
             (SELECT AccName FROM _TDAAccount WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.AccSeq) AS AccName,     -- 정산계정              
             (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMExpKind) AS SMExpKindName,      -- 수출구분명                
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.OrderUnitSeq) AS OrderUnitName,       -- 수주판매단위명              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.OrderSTDUnitSeq) AS OrderSTDUnitName, -- 수주기준단위명              
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.InCustSeq) AS InCustName,             -- 매입거래처              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InUnitSeq) AS InUnitName,             -- 매입판매단위명              
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InSTDUnitSeq) AS InSTDUnitName,       -- 매입기준단위명              
               (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InvUnitSeq) AS InvUnitName,             -- 거래명세서판매단위명              
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.InvSTDUnitSeq) AS InvSTDUnitName,        -- 거래명세서기준단위명            
              CASE WHEN ISNULL(L.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')               
                                                                FROM _TDAUMinor WITH(NOLOCK)               
                                                               WHERE CompanySeq = @CompanySeq               
                                                                 AND MinorSeq = L.ValueSeq) END AS ItemClassLName,              
              CASE WHEN ISNULL(K.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')               
                                                                FROM _TDAUMinor WITH(NOLOCK)               
                                                               WHERE CompanySeq = @CompanySeq               
                                                                 AND MinorSeq = K.ValueSeq) END AS ItemClassMName,              
             ISNULL(H.MinorName,'') AS ItemClassSName, -- 품목소분류              
             ISNULL(Y.MinorName, '') AS ItemType--  제상품유형구분               
         FROM            
         (              
             SELECT              
                 A.SalesSeq          AS SalesSeq,        -- 수출내부코드              
                 A.SalesSerl         AS SalesSerl,       -- 수출내부순번              
                 B.BizUnit           AS BizUnit,         -- 사업부문              
                 B.SalesDate         AS SalesDate,       -- 수출일              
                 B.SalesNo           AS SalesNo,         -- 수출번호               
                 B.SMExpKind         AS SMExpKind,       -- 수출구분              
                 B.DeptSeq           AS DeptSeq,         -- 부서              
                 B.EmpSeq            AS EmpSeq,          -- 담당자              
                 B.CustSeq           AS CustSeq,         -- 거래처              
                 EI.LotNo            AS LotNo,           -- Lot NO              
                 C.ItemSeq           AS ItemSeq,         -- 품목코드              
                 C.UnitSeq           AS UnitSeq,         -- 판매단위              
                 C.ItemPrice         AS ItemPrice,       -- 품목단가              
                 C.CustPrice         AS CustPrice,       -- 회사단가              
                 (C.DomAmt / NULLIF(C.Qty, 0))  AS Price,-- 판매단가              
                 C.Qty               AS Qty,             -- 수량              
                 C.IsInclusedVAT     AS IsInclusedVAT,   -- 부가세포함여부              
                 C.VATRate           AS VATRate,         -- 부가세율              
                 C.CurAmt            AS CurAmt,          -- 판매금액              
                 C.CurVAT            AS CurVAT,          -- 부가세액              
                 C.DomAmt            AS DomAmt,          -- 원화판매금액              
                 C.DomVAT            AS DomVAT,          -- 원화부가세액              
                 C.STDUnitSeq        AS STDUnitSeq,      -- 기준단위              
                 C.STDQty            AS STDQty,          -- 기준단위수량              
                 C.WHSeq             AS WHSeq,           -- 창고코드              
                 C.Remark            AS Remark,          -- 비고              
                 C.AccSeq            AS AccSeq,          -- 정산계정              
                 G.OrderSeq          AS OrderSeq,        -- 수주내부코드              
                 G.OrderSerl         AS OrderSerl,       -- 수주내부순번              
                 G.UnitSeq           AS OrderUnitSeq,        -- 수주판매단위              
                 G.ItemPrice         AS OrderItemPrice,      -- 수주품목단가              
                 G.CustPrice         AS OrderCustPrice,      -- 수주회사단가              
                   (G.DomAmt / G.Qty)  AS OrderPrice,          -- 수주판매단가              
                 G.Qty               AS OrderQty,            -- 수주수량              
                 G.IsInclusedVAT     AS OrderIsInclusedVAT,  -- 수주부가세포함여부              
                 G.VATRate           AS OrderVATRate,        -- 수주부가세율              
                 G.CurAmt            AS OrderCurAmt,         -- 수주판매금액              
                 G.CurVAT            AS OrderCurVAT,         -- 수주부가세액              
                 G.DomAmt            AS OrderDomAmt,         -- 수주원화판매금액 **************************                
                 G.DomVAT            AS OrderDomVAT,         -- 수주원화부가세액              
                 G.STDUnitSeq        AS OrderSTDUnitSeq,     -- 수주기준단위              
                 G.STDQty            AS OrderSTDQty,         -- 수주기준단위수량              
                 E.InvoiceSeq        AS InvoiceSeq,      -- 거래명세서내부코드              
                 E.InvoiceNo         AS InvoiceNo,       -- 거래명세서번호              
                 E.DeptSeq           AS InvDeptSeq,      -- 거래명세서담당부서              
                 E.EmpSeq            AS InvEmpSeq,       -- 거래명세서담당자              
                 E.CustSeq           AS InvCustSeq,      -- 거래명세서거래처              
                 EI.InvoiceSerl      AS InvoiceSerl,                
                 EI.UnitSeq          AS InvUnitSeq,          -- 거래명세서 판매단위              
                 EI.ItemPrice        AS InvItemPrice,        -- 거래명세서 품목단가              
                 EI.CustPrice        AS InvCustPrice,        -- 거래명세서 회사단가              
                 (EI.DomAmt / EI.Qty) AS InvPrice,           -- 거래명세서 판매단가              
                 EI.Qty              AS InvQty,              -- 거래명세서 수량              
                 EI.IsInclusedVAT    AS InvIsInclusedVAT,    -- 거래명세서 부가세포함여부              
                 EI.VATRate          AS InvVATRate,          -- 거래명세서 부가세율              
                 EI.CurAmt           AS InvCurAmt,           -- 거래명세서 판매금액              
                 EI.CurVAT           AS InvCurVAT,           -- 거래명세서 부가세액              
                 EI.DomAmt           AS InvDomAmt,           -- 거래명세서 원화판매금액 **************************             
                 EI.DomVAT           AS InvDomVAT,           -- 거래명세서 원화부가세액              
                 EI.STDUnitSeq       AS InvSTDUnitSeq,       -- 거래명세서 기준단위              
                 EI.STDQty           AS InvSTDQty,           -- 거래명세서 기준단위수량              
                 I.BillSeq           AS BillSeq,             -- 세금계산서내부코드              
                 I.BillNo            AS BillNo,              -- 세금계산서번호              
                 J.InDate            AS InDate,              -- 매입일자              
                 J.CustSeq           AS InCustSeq,           -- 매입거래처              
                 J.UnitSeq           AS InUnitSeq,           -- 매입단위              
                 J.Price             AS InPrice,             -- 매입원가              
                 J.Qty               AS InQty,               -- 매입수량              
                 J.CurAmt            AS InCurAmt,            -- 매입원가금액              
                 J.DomAmt            AS InDomAmt,            -- 매입원화금액              
                 J.STDUnitSeq        AS InSTDUnitSeq,        -- 매입기준단위              
                 J.STDQty            AS InSTDQty,            -- 매입기준단위수량              
                 J.Price             AS LOTPrice,       
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty)* G.Qty) END  AS OrderInAmtGPCal,          -- 매입원가           
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * EI.Qty) END  AS InvoiceInAmtGPCal,        -- 매입원가      
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * C.Qty) END  AS SalesInAmtGPCal,           -- 매입원가      
                   
                 -- 수입건에 대하여 J.Price 는 수입입고단가이고 수입입고원가단가가 아니기에 차이가 발생 함   
                 -- 수입입고원가 = 입고금액 + 비용  
                   --(J.Price * G.Qty)   AS OrderInAmt,          -- 매입원가_수주금액  **************************            
                 --(J.Price * EI.Qty)  AS InvoiceInAmt,        -- 매입원가_거래명세서금액     **************************         
                 --(J.Price * C.Qty)  AS SalesInAmt,          -- 매입원가_매출금액      **************************        
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty)* G.Qty) END  AS OrderInAmt,          -- 매입원가           
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * EI.Qty) END  AS InvoiceInAmt,        -- 매입원가      
                 CASE WHEN J.Qty IS NULL THEN 0 ELSE ((J.DomAmt/J.Qty) * C.Qty) END  AS SalesInAmt,           -- 매입원가      
                   
                 (CASE WHEN B.SlipSeq = 0 THEN I.SlipSeq ELSE B.SlipSeq END) AS SlipSeq,     -- 전표코드              
                 (ISNULL(G.DomAmt, 0) - ISNULL(C.DomAmt, 0)) AS OrderSalesGP,     -- 수주-매출GP              
                     (CASE WHEN (ISNULL(G.DomAmt, 0) = ISNULL(C.DomAmt, 0)) THEN 0               
                           WHEN ISNULL(G.DomAmt, 0) = 0 THEN ROUND((0 - ISNULL(C.DomAmt, 0)) * 100, 2)               
                           ELSE ISNULL(ROUND((ISNULL(G.DomAmt, 0) - ISNULL(C.DomAmt, 0)) / NULLIF(G.DomAmt, 0) * 100, 2), 0) END) AS TmpOrderSalesGPRate,                   
                 K.ContractNo 
             FROM #Temp_Sales AS A               
                 INNER JOIN _TSLSales AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq              
                 INNER JOIN _TSLSalesItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.SalesSeq = A.SalesSeq AND C.SalesSerl = A.SalesSerl              
                   
                 --LEFT OUTER JOIN #TCOMSourceTracking AS D ON D.IDX_NO = A.IDX_NO AND D.IDOrder = '1'  AND  C.DomAmt * D.FromAmt >= 0     -- 거래명세서              
                 LEFT OUTER JOIN ( SELECT A.*   
                            FROM #TCOMSourceTracking AS A   
                            JOIN ( SELECT IDX_NO, MAX(Seq) AS Seq FROM #TCOMSourceTracking GROUP BY IDX_NO ) AS B ON ( A.IDX_NO = B.IDX_NO AND A.Seq = B.Seq )  
                           ) AS D ON A.IDX_NO = D.IDX_NO    
                   
                 LEFT OUTER JOIN _TSLInvoice AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.InvoiceSeq = D.Seq              
                 LEFT OUTER JOIN _TSLInvoiceItem AS EI WITH (NOLOCK) ON EI.CompanySeq = @CompanySeq AND EI.InvoiceSeq = D.Seq AND EI.InvoiceSerl = D.Serl             
                 LEFT OUTER JOIN #TCOMSourceTracking AS F ON F.IDX_NO = A.IDX_NO AND F.IDOrder = '2'    -- 수주              
                 LEFT OUTER JOIN _TSLOrderItem AS G WITH (NOLOCK) ON G.CompanySeq = @CompanySeq AND G.OrderSeq = F.Seq AND G.OrderSerl = F.Serl              
                 LEFT OUTER JOIN _TSLBill AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.BillSeq = A.BillSeq              
                 LEFT OUTER JOIN #TMP_DelvIn AS J ON J.IDX_NO = D.IDX_NO 
                 LEFT OUTER JOIN DTI_TSLContractMngItem AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ContractSeq = CONVERT(INT,G.Dummy6) AND H.ContractSerl = CONVERT(INT,G.Dummy7) ) 
                 LEFT OUTER JOIN DTI_TSLContractMng     AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ContractSeq = H.ContractSeq ) 
             WHERE (@InvoiceNo = '' OR E.InvoiceNo LIKE @InvoiceNo + '%')              
               AND (@BillNo = '' OR I.BillNo LIKE @BillNo + '%')     AND C.DomAmt * EI.DomAmt >= 0 
               AND (@ContractNo = '' OR K.ContractNo LIKE @ContractNo +'%') 
         ) AS A              
             LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq              
             LEFT OUTER JOIN _TDAItemAsset AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq              
             LEFT OUTER JOIN _TDACust AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq              
             LEFT OUTER JOIN _TACSlipRow AS J WITH (NOLOCK) ON J.CompanySeq = @CompanySeq AND J.SlipSeq = A.SlipSeq            
             LEFT OUTER JOIN _TDAItemClass AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq            
                                                           AND A.ItemSeq    = O.ItemSeq              
                                                             AND O.UMajorItemClass IN (2001,2004)             
            LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK)    ON H.CompanySeq  = @CompanySeq     -- 품목소분류          
                                                           AND O.UMItemClass = H.MinorSeq               
            LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON K.CompanySeq  = @CompanySeq --품목중분류             
                                                             AND H.MinorSeq   = K.MinorSeq               
                                                             AND K.Serl = (CASE O.UMajorItemClass WHEN 2001 THEN 1001 ELSE 2001 END)         
                                                             --AND K.MajorSeq IN (2001,2004)              
            LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON L.CompanySeq  = @CompanySeq   --품목대분류            
                                                             AND K.ValueSeq   = L.MinorSeq               
                                                             AND L.MajorSeq IN (2002,2005)              
            LEFT OUTER JOIN _TDAItemClass AS Z WITH(NOLOCK) ON Z.CompanySeq  = @CompanySeq              
                                                           AND A.ItemSeq    = Z.ItemSeq  --제상품유형구분            
                                                           AND Z.UMajorItemClass = 1000203             
            LEFT OUTER JOIN _TDAUMinor AS Y WITH(NOLOCK)    ON Y.CompanySeq  = @CompanySeq              
                                                           AND Z.UMItemClass = Y.MinorSeq            
             WHERE (@UMItemClassL = 0 OR L.ValueSeq = @UMItemClassL)            
               AND (@UMItemClassM = 0 OR K.ValueSeq = @UMItemClassM)            
               AND (@UMItemClassS = 0 OR O.UMItemClass = @UMItemClassS)            
               AND (@ItemTypeSeq  = 0 OR Z.UMItemClass = @ItemTypeSeq)            
     ) AS A            
     ORDER BY A.SalesSeq, A.SalesSerl              
     --=====================================================================================================================              
     -- 임시테이블 제거               
     --=====================================================================================================================       
  --SELECT              
  --              C.DomAmt , D.FromAmt, C.DomAmt * D.FromAmt, *              
  --           FROM #Temp_Sales AS A               
  --               INNER JOIN _TSLSales AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.SalesSeq = A.SalesSeq              
  --               INNER JOIN _TSLSalesItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.SalesSeq = A.SalesSeq AND C.SalesSerl = A.SalesSerl              
  --               INNER JOIN #TCOMSourceTracking AS D ON D.IDX_NO = A.IDX_NO AND D.IDOrder = '1' AND  C.DomAmt * D.FromAmt >= 0     -- 거래명세서              
  --               LEFT OUTER JOIN _TSLInvoice AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.InvoiceSeq = D.Seq              
  --               LEFT OUTER JOIN _TSLInvoiceItem AS EI WITH (NOLOCK) ON EI.CompanySeq = @CompanySeq AND EI.InvoiceSeq = D.Seq AND EI.InvoiceSerl = D.Serl             
  --               LEFT OUTER JOIN #TCOMSourceTracking AS F ON F.IDX_NO = A.IDX_NO AND F.IDOrder = '2'    -- 수주              
  --               LEFT OUTER JOIN _TSLOrderItem AS G WITH (NOLOCK) ON G.CompanySeq = @CompanySeq AND G.OrderSeq = F.Seq AND G.OrderSerl = F.Serl              
  --               LEFT OUTER JOIN _TSLBill AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq AND I.BillSeq = A.BillSeq              
  --               LEFT OUTER JOIN #TMP_DelvIn AS J ON J.IDX_NO = D.IDX_NO              
  --           WHERE (@InvoiceNo = '' OR E.InvoiceNo LIKE @InvoiceNo + '%')              
  --             AND (@BillNo = '' OR I.BillNo LIKE @BillNo + '%')         
                   
  --             select * from #TMP_DelvIn    
  --             select * from #TCOMSourceTracking where IDOrder = '1'     
    --             select * from #TCOMSourceTracking where IDOrder = '2'     
     --DROP TABLE #Temp_Sales              
     --DROP TABLE #TMP_DelvIn              
     --DROP TABLE #TMP_SOURCETABLE              
     --DROP TABLE #TCOMSourceTracking                  
      
    RETURN         