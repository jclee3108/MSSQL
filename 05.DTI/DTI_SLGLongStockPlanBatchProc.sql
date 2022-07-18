
IF OBJECT_ID('DTI_SLGLongStockPlanBatchProc') IS NOT NULL 
    DROP PROC DTI_SLGLongStockPlanBatchProc
GO

-- v2013.01.06 

-- 재고소진계획작성(계약)_DTI by이재천          
    CREATE PROC DTI_SLGLongStockPlanBatchProc      
        @xmlDocument  NVARCHAR(MAX), 
        @xmlFlags     INT = 0, 
        @ServiceSeq   INT = 0, 
        @WorkingTag   NVARCHAR(10)= '', 
        @CompanySeq   INT = 1, 
        @LanguageSeq  INT = 1, 
        @UserSeq      INT = 0, 
        @PgmSeq       INT = 0 
AS      
    
    DECLARE @docHandle  INT, 
            @StdYM      NCHAR(6),   -- 기준월      
            @FrDate     NCHAR(8), 
            @ToDate     NCHAR(8) 
    
    -- 서비스 마스타 등록 생성        
    CREATE TABLE #DTI_TLGLongStock (WorkingTag NCHAR(1) NULL) 
    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TLGLongStock'               
    
    IF @@ERROR <> 0       
    BEGIN      
        RETURN           
    END      
    
    SET @StdYM = (SELECT StdYM FROM #DTI_TLGLongStock)      
    --=====================================================================================================================      
    -- 장기재고계획 초기화      
    --=====================================================================================================================      
    -- 장기재고계획 품목삭제      
    DELETE DTI_TLGLongStockItem      
      FROM DTI_TLGLongStockItem      
     WHERE CompanySeq = @CompanySeq      
       AND StdYM = @StdYM      
      
    -- 장기재고계획 마스터삭제      
    --DELETE DTI_TLGLongStock      
    --  FROM DTI_TLGLongStock      
    -- WHERE CompanySeq = @CompanySeq      
    --   AND StdYM = @StdYM      
    --=====================================================================================================================      
    -- 장기재고 가져오기      
    --=====================================================================================================================      
    CREATE TABLE #GetInOutLotEmp          
    (            
         LotNo      NVARCHAR(30),          
         ItemSeq    INT,          
         EmpSeq     INT            
    )            
    
    CREATE TABLE #GetInOutLot          
    (            
         LotNo      NVARCHAR(30),          
         ItemSeq    INT,
         Qty        DECIMAL(19, 5),
         ISPreStock NCHAR(1)            
    )            
    
    CREATE TABLE #GetInOutLotStock           
    (            
         WHSeq           INT,            
         FunctionWHSeq   INT,            
         LotNo           NVARCHAR(30),          
         ItemSeq         INT,            
         UnitSeq         INT,            
         PrevQty         DECIMAL(19,5),            
         InQty           DECIMAL(19,5),            
         OutQty          DECIMAL(19,5),            
         StockQty        DECIMAL(19,5),            
         STDPrevQty      DECIMAL(19,5),            
         STDInQty        DECIMAL(19,5),            
         STDOutQty       DECIMAL(19,5),            
         STDStockQty     DECIMAL(19,5)            
     )      
    
    -- 일괄 생성의 경우 전체 생성      
    INSERT #GetInOutLotEmp      
    SELECT B.LotNo, B.ItemSeq, B.EmpSeq      
    FROM DTI_TLGLotEmp AS B WITH (NOLOCK)      
    INNER JOIN _TDAItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq      
    WHERE B.CompanySeq = @CompanySeq      
      AND C.AssetSeq IN (1, 16)    -- 품목자산분류 - 상품만      
    
    -- 중복제거      
    INSERT INTO #GetInOutLot           
    SELECT DISTINCT A.LotNo, A.ItemSeq, 0, '0'            
      FROM #GetInOutLotEmp AS A       
    
    SELECT @FrDate = CONVERT(CHAR(8), @StdYM + '01', 112)      
    SELECT @ToDate = CONVERT(CHAR(8), DATEADD(DAY,-1,DATEADD(MONTH,1,@FrDate)), 112)      
    
    -- 창고재고가져오기         
    EXEC _SLGGetInOutLotStock @CompanySeq   = @CompanySeq,    -- 법인코드        
                              @BizUnit      = 0,              -- 사업부문           
                              @FactUnit     = 0,              -- 생산사업장           
                              @DateFr       = @FrDate,        -- 조회기간Fr            
                              @DateTo       = @ToDate,        -- 조회기간To            
                              @WHSeq        = 0,              -- 창고지정           
                              @SMWHKind     = 0,              -- 창고구분별조회           
                              @CustSeq      = 0,              -- 수탁거래처           
                              @IsTrustCust  = '0',            -- 수탁여부           
                              @IsSubDisplay = '0',            -- 기능창고조회           
                              @IsUnitQry    = '0',            -- 단위별조회           
                              @QryType      = 'B'             -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고       
    
    DELETE #GetInOutLotStock WHERE STDPrevQty < 0      
    
    TRUNCATE TABLE #GetInOutLot  
    -- 중복제거      
    INSERT INTO #GetInOutLot (LotNo, ItemSeq, Qty, ISPreStock) 
    SELECT DISTINCT A.LotNo, A.ItemSeq, A.STDPrevQty, '0'            
      FROM #GetInOutLotStock AS A  
    
    --select * from DTI_TLGLongStockItem
    --=====================================================================================================================      
    -- 담당자별 재고현황 저장      
    --=====================================================================================================================      
    CREATE TABLE #DTI_TLGLongStockInfo      
    (      
        DeptSeq     INT,      
        ItemSeq     INT,      
        LotNo       NVARCHAR(100),      
        EmpSeq      INT,      
        Qty         DECIMAL(19,5),      
        Price       DECIMAL(19,5),      
        InDate      NCHAR(8),
        StockPlan nvarchar(100),      
        SpecNote nvarchar(100),      
        IsMngStock      NCHAR(1),      
        IsEtcCondition1      NCHAR(1),      
        IsEtcCondition2      NCHAR(1),      
        IsEtcCondition3      NCHAR(1),
        ContractSYM   NCHAR(8),
        ContractEYM   NCHAR(8),
        UMSalesCond     INT,
        UMStockKind     INT,
        Feedback        NVARCHAR(200), 
        ContractSeq     INT, 
        ContractSerl    INT )
     --=====================================================================================================================      
    -- 단가 검색      
    --=====================================================================================================================    
    --------------------------------------    
    --------------------------------------    
    --------------------------------------    
    
    -- 기초재고 정보검색      
    DECLARE @StartYM    NCHAR(6),      
            @InitYM     NCHAR(6)      
      
    SET @StartYM = CONVERT(CHAR(6), @FrDate)      
    EXEC dbo._SCOMEnv @CompanySeq,1006, @UserSeq, @@PROCID, @StartYM OUTPUT         
      
    SELECT @InitYM = FrSttlYM FROM _TDAAccFiscal WHERE CompanySeq = @CompanySeq AND @StartYM BETWEEN FrSttlYM AND ToSttlYM      
    
    CREATE TABLE #GetInOutLotPrice      
    (      
        LotNo       NVARCHAR(30),          
        ItemSeq     INT,      
        Price       DECIMAL(19,5),      
        InDate      NCHAR(8)         
    ) 
    
    -- 구매입고 정보검색      
    INSERT INTO #GetInOutLotPrice ( LotNo, ItemSeq, Price, InDate ) 
    SELECT A.LotNo, A.ItemSeq,           
           ROUND( (CASE WHEN (ISNULL(CASE WHEN B.Qty = 0 
                                          THEN 0 
                                          ELSE B.DomAmt / B.Qty 
                                          END, 0
                                   ) = 0 
                             )
                        THEN (CASE WHEN E.Qty = 0 
                                   THEN 0 
                                   ELSE E.OKDomAmt / E.Qty 
                                   END
                             ) 
                        ELSE (CASE WHEN B.Qty = 0 
                                   THEN 0 
                                   ELSE B.DomAmt / B.Qty 
                                   END 
                             )
                        END
                  ), 1),           
           (CASE WHEN ISNULL(C.DelvInDate, '') = '' THEN F.DelvDate ELSE C.DelvInDate END) 
      FROM #GetInOutLot AS A 
      LEFT OUTER JOIN _TPUDelvInItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq And ISNULL(IsReturn, '') <> '1' 
      LEFT OUTER JOIN _TPUDelvIn AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.DelvInSeq = B.DelvInSeq 
      LEFT OUTER JOIN _TUIImpDelvItem AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.LotNo = A.LotNo AND E.ItemSeq = A.ItemSeq          
      LEFT OUTER JOIN _TUIImpDelv AS F WITH (NOLOCK) ON F.CompanySeq = @CompanySeq AND F.DelvSeq = E.DelvSeq          
     WHERE B.CompanySeq IS NOT NULL OR F.CompanySeq IS NOT NULL 
    
    INSERT INTO #GetInOutLotPrice ( LotNo, ItemSeq, Price, InDate ) 
    SELECT A.LotNo, A.ItemSeq, ROUND((B.Amt / NULLIF(B.Qty, 0)), 0) AS Price, D.CreateDate 
      FROM #GetInOutLot AS A 
      INNER JOIN _TESMGMonthlyLotStockAmt AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                           AND B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq AND B.InOutKind = 8023000          
      INNER JOIN _TESMDCostKey AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.SMCostMng = 5512001 AND C.CostYM = @InitYM AND C.CostKeySeq = B.CostKeySeq          
      LEFT OUTER JOIN _TLGLotMaster AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.LotNo = A.LotNo AND D.ItemSeq = A.ItemSeq          
     WHERE NOT EXISTS (SELECT 1 FROM #GetInOutLotPrice WHERE LotNo = A.LotNo AND ItemSeq = A.ItemSeq)          
    
    /**********************전월 데이터에 ItemSeq, LotNo가 있는 건들은 전월데이터 *********************/  
    INSERT INTO #DTI_TLGLongStockInfo ( DeptSeq, ItemSeq, LotNo, EmpSeq, Qty, Price, InDate, StockPlan, SpecNote, 
                                        IsMngStock, IsEtcCondition1, IsEtcCondition2, IsEtcCondition3, 
                                        ContractSYM, ContractEYM, UMSalesCond,  UMStockKind, Feedback)
    SELECT E.DeptSeq, B.ItemSeq, B.LotNo, E.EmpSeq, A.Qty, F.Price, F.InDate, B.StockPlan, B.SpecNote, B.IsMngStock, 
           B.IsEtcCondition1, B.IsEtcCondition2, B.IsEtcCondition3, B.ContractSYM, B.ContractEYM,
           B.UMSalesCond, B.UMStockKind, B.Feedback
      FROM #GetInOutLot AS A
      JOIN DTI_TLGLongStockItem AS B ON B.CompanySeq = @CompanySeq
                                    AND StdYM = CONVERT(CHAR(6), DATEADD(MONTH, -1, CONVERT(CHAR(8), @StdYM+'01', 112)), 112)
                                    AND A.LotNo = B.LotNo
                                    AND A.ItemSeq = B.ItemSeq      
      LEFT OUTER JOIN DTI_TLGLotEmp AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq AND E.LotNo = A.LotNo AND E.ItemSeq = A.ItemSeq      
      LEFT OUTER JOIN #GetInOutLotPrice AS F ON A.ItemSeq = F.ItemSeq AND A.LotNo = F.LotNo 
    DELETE A
      FROM #GetInOutLot AS A
      JOIN DTI_TLGLongStockItem AS B ON B.CompanySeq = @CompanySeq
                                    AND StdYM = CONVERT(CHAR(6), DATEADD(MONTH, -1, CONVERT(CHAR(8), @StdYM+'01', 112)), 112)
                                    AND A.LotNo = B.LotNo
                                    AND A.ItemSeq = B.ItemSeq      
    
    -----------------------------------------------------------------------------------------------------------------------
    -- 매출처 및 특이사항 검색      
    ----------------------------------------------------------------------------------------------------------------------
    
    CREATE TABLE #GetInOutLotRemark      
    (      
        LotNo       NVARCHAR(30),          
        ItemSeq     INT,      
        Remark      NVARCHAR(400), 
        ContractSeq INT, 
        ContractSerl INT
    )      
    
     -- 수주의 거래처 검색     
     INSERT INTO #GetInOutLotRemark ( LotNo, ItemSeq, Remark, ContractSeq, ContractSerl ) 
     SELECT A.LotNo, A.ItemSeq, D.CustName, B.Dummy6, B.Dummy7 
       FROM #GetInOutLot AS A 
       JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq ) 
       JOIN _TSLOrder     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = B.OrderSeq ) 
       LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.CustSeq ) 
       
    INSERT INTO #GetInOutLotRemark ( LotNo, ItemSeq, Remark, ContractSeq, ContractSerl ) 
    SELECT DISTINCT A.LotNo, A.ItemSeq, B.Memo5, B.Memo3, B.Memo4 
      FROM #GetInOutLot AS A 
      JOIN _TPUDelvItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.LOTNo = A.LotNo AND B.ItemSeq = A.ItemSeq ) 
     WHERE NOT EXISTS (SELECT 1 FROM #GetInOutLotRemark WHERE LotNo = A.LotNo AND ItemSeq = A.ItemSeq) 
    
    -- 구매입고 테이블    
    
    CREATE TABLE #TMP_SOURCETABLE      
    (      
      IDOrder       INT,    -- 순번      
      TABLENAME     NVARCHAR(100)  -- 검색할 테이블명      
    )        
    
    -- 결과 테이블      
    CREATE TABLE #TCOMSourceTracking          
    (   IDX_NO      INT,          
        IDOrder     INT,          
        Seq         INT,          
        Serl        INT,          
        SubSerl     INT,          
        FromQty     DECIMAL(19, 5),          
        FromAmt     DECIMAL(19, 5) ,          
        ToQty       DECIMAL(19, 5),          
        ToAmt       DECIMAL(19, 5)          
    )  
    
    CREATE TABLE #Temp_ImpIn        
    (              
        IDX_NO      INT IDENTITY(1,1),              
        DelvInSeq   INT,              
        DelvInSerl  INT,         
        LotNo       NVARCHAR(30),        
        ItemSeq     INT        
    )        
    
    INSERT #TMP_SOURCETABLE       
    SELECT '1', '_TPUORDApprovalReqItem'    -- 구매품의  
    
    --select * from #GetInOutLot 
    INSERT INTO #Temp_ImpIn ( DelvInSeq, DelvInSerl, A.LotNo, A.ItemSeq )        
    SELECT DelvSeq, DelvSerl, A.LotNo, A.ItemSeq        
      FROM #GetInOutLot AS A        
      INNER JOIN _TUIImpDelvItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq AND B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq        
     WHERE NOT EXISTS (SELECT 1 FROM #GetInOutLotRemark WHERE LotNo = A.LotNo AND ItemSeq = A.ItemSeq)     
    TRUNCATE TABLE #TCOMSourceTracking
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TUIImpDelvItem', '#Temp_ImpIn', 'DelvInSeq', 'DelvInSerl', ''        
    
    INSERT INTO #GetInOutLotRemark ( LotNo, ItemSeq, Remark )        
    SELECT A.LotNo, A.ItemSeq, C.Remark        
      FROM #Temp_ImpIn AS A        
      INNER JOIN #TCOMSourceTracking AS B ON B.IDX_NO = A.IDX_NO AND B.IDOrder = '1'    
      INNER JOIN _TPUORDApprovalReqItem AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.ApproReqSeq = B.Seq AND C.ApproReqSerl = B.Serl        
    
    INSERT INTO #DTI_TLGLongStockInfo ( DeptSeq, ItemSeq, LotNo, EmpSeq, Qty, Price, InDate, StockPlan, SpecNote, 
                                        IsMngStock, IsEtcCondition1, IsEtcCondition2, IsEtcCondition3, 
                                        ContractSYM, ContractEYM, UMSalesCond,  UMStockKind, Feedback, ContractSeq, ContractSerl )
    SELECT E.DeptSeq, A.ItemSeq, A.LotNo, E.EmpSeq, A.Qty, C.Price, C.InDate, '', D.Remark,
           '0', '0', '0', '0', '', '', 0, (CASE WHEN F.UMItemClass = '1000203003' THEN 1000394001 ELSE 1000394002 END) AS UMStockKind, '', D.ContractSeq, D.ContractSerl
      FROM #GetInOutLot AS A      
      LEFT OUTER JOIN #GetInOutLotPrice AS C ON ( C.LotNo = A.LotNo AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN #GetInOutLotRemark AS D ON ( D.LotNo = A.LotNo AND D.ItemSeq = A.ItemSeq )
      LEFT OUTER JOIN DTI_TLGLotEmp AS E WITH (NOLOCK)ON ( E.CompanySeq = @CompanySeq AND E.LotNo = A.LotNo AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemClass AS F WITH (NOLOCK)ON ( F.CompanySeq = @CompanySeq AND F.UMajorItemClass = 1000203 AND F.ItemSeq = A.ItemSeq ) 

        
    SELECT EmpSeq, DeptSeq 
      INTO #Dept
      FROM [dbo].[_FDAGetDept](@CompanySeq, 0, @ToDate)
      
    INSERT INTO DTI_TLGLongStockItem ( CompanySeq,   
                                       StdYM,   
                                       DeptSeq,   
                                       ItemSeq,   
                                       LotNo,   
                                       EmpSeq,   
                                       StockQty,--재고수량   
                                       Price,   
                                       InDate,   
                                       LongMonth,   
                                       EstSalesDate,   
                                       StockPlan,   
                                       SpecNote,   
                                       LastUserSeq,   
                                       LastDateTime,  
                                       IsMngStock,--관리재고  
                                       IsEtcCondition1,  
                                       IsEtcCondition2,  
                                       IsEtcCondition3,  
                                       EstSalesQty,--초기값 0  
                                       ContractSYM,  
                                       ContractEYM,  
                                       UMSalesCond,  
                                       UMStockKind,  
                                       Feedback,   
                                       ContractSeq,   
                                       ContractSerl   
                                     )     
      
    SELECT @CompanySeq, @StdYM,  
           ISNULL(B.DeptSeq,0),   
           A.ItemSeq, A.LotNo, A.EmpSeq, A.Qty, A.Price, A.InDate,         
           DATEDIFF(MONTH, A.InDate, CONVERT(CHAR(8), @StdYM+'01', 112)),   
           ISNULL(CONVERT(NCHAR(8), DATEADD(DAY, -1, DATEADD(MONTH, 1, D.SalesYM + '01')),112),CONVERT(NCHAR(8), DATEADD(DAY, -1, DATEADD(MONTH, 1, C.SalesYM + '01')),112)) ,  
           A.StockPlan, A.SpecNote, @UserSeq, GETDATE(),   
           A.IsMngStock,--IsMngStock  
           A.IsEtcCondition1,  
           A.IsEtcCondition2,  
           A.IsEtcCondition3,  
           ISNULL(D.Qty,C.Qty),   
           A.ContractSYM,  
           A.ContractEYM,  
           A.UMSalesCond,  
           A.UMStockKind,  
           A.Feedback,   
           A.ContractSeq,   
           A.ContractSerl  
      
      FROM #DTI_TLGLongStockInfo AS A  
      LEFT OUTER JOIN #Dept      AS B ON ( B.EmpSeq = A.EmpSeq )   
      LEFT OUTER JOIN DTI_TSLContractMngItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = A.ContractSeq AND C.ContractSerl = A.ContractSerl )   
      LEFT OUTER JOIN DTI_TSLContractMngItemRev AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq   
                                                                   AND D.ContractSeq = A.ContractSeq   
                                                                   AND D.ContractSerl = A.ContractSerl   
                                                                   AND D.ContractRev = 0   
                                                                     )   
      
    --B. 일괄생성 시 전월 재고가 존재 했던 상품은 전월에 입력한 값을 기본값으로 모두 가져와야 한다.  
    -----------------------------------------------------------------------------------------------------------------------    
    --임시 테이블 제거      
    -----------------------------------------------------------------------------------------------------------------------
    DROP TABLE #GetInOutLotStock      
    DROP TABLE #GetInOutLot      
    DROP TABLE #GetInOutLotEmp      
    DROP TABLE #GetInOutLotPrice      
    DROP TABLE #GetInOutLotRemark      
    --DROP TABLE #Temp_DelvIn      
    DROP TABLE #TMP_SOURCETABLE      
    DROP TABLE #TCOMSourceTracking      
    DROP TABLE #DTI_TLGLongStockInfo      
    
    SELECT * FROM #DTI_TLGLongStock 
    --select * from DTI_TLGLongStockItem    
    RETURN
GO
begin tran 
exec DTI_SLGLongStockPlanBatchProc @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYM>201010</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020091,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016908
select * from DTI_TLGLongStockItem where companyseq = 1 and stdym ='201010'
rollback  