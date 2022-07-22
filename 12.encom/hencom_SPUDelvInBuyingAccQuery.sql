IF OBJECT_ID('hencom_SPUDelvInBuyingAccQuery') IS NOT NULL 
    DROP PROC hencom_SPUDelvInBuyingAccQuery
GO 

-- v2017.03.29 
/*************************************************************************************************  
 설  명 - 구매외주입고 정산처리 조회  
 작성일 - 2008.8.18 : CREATEd by 노영진  
 수정일 - 2009.8.25 김현  
          2009.12.29 박소연 생산사양항목/값 추가  
          2009.12.29 박소연 생산사양가져오기 수정  
          2010.03.18 박소연 대/중분류 추가  
          2010.04.19 박소연 외주입고에 대한 활동센터 가져오기 추가  
          2010.05.04 박소연 :: 출납방법 추가  
          2010.07.01 박소연 :: 품목/자산분류, 전표번호 조회조건 추가  
          2011.02.16 hkim   활동센터의 비용구분 조회 추가  
          2011.03.14 차근형 :: 매입이월 데이터 관련 :: 중복 조회문제로 원천코드 담을때 DISTINCT 추가  
                                                    :: 전표관련 조회 최종 SELECT로 이동  
                                                    :: 입고일 최종 SELECT에서 한번더 조회  
         2011.04.25 김세호  :: 납품마스터에서 납품관리번호(DelvMngNo) 조회조건 및 항목 추가  
         2011.05.23 김세호  :: 소급적용 입고건은 수량 0이어도 조회되도록 수정  
         2011.05.27 김세호  :: 출납방법- 구매발주의 자금구분으로 조회되도록 수정  
         2011.06.13 김세호  :: 조회항목 소분류 추가  
         2011.06.30 by 김철웅 1) 하드코딩 없애기  
         2011.10.18 hkim    :: 외주에서 유상사급을 제외한 정산할 자재가 있는데 정산이 되지 않았으면 전표처리 되지 않도록 IsMatCalc 컬럼 추가  
         2011.11.12 김세호  :: 발주번호 조회조건및 조회칼럼 추가  
         2012.02.21 김세호  :; 거래처번호 조회 추가  
         2012.05.18 hkim :: 불공제세부가세유무 컬럼 추가(증빙이 불공제세인데, 부가세에 0이 아닌 값이 있을 경우 체크하여 전표처리시 메시지 출력해준다)  
         2012.09.25 허승남  :: 사업자등록명 컬럼변경  
         2014.04.10 김용현  :: 품목, 품번 조회조건 안 먹는 부분 수정 ( @ItemSeq 로만 조회조건을 씀 )   
         2014.11.11 김용현  :: @DateFr 에 조회조건이 없을 경우 물류시작일로 하여 활동센터(구매요청) 을 끌고 올 수 있도록 함.  
         2015.01.21 황지혜  :: 조회조건 납품거래처 추가   
         2015.06.02 이범확  :: 특이사항(MstRemark)추가
*************************************************************************************************/    
CREATE PROCEDURE hencom_SPUDelvInBuyingAccQuery
    @xmlDocument    NVARCHAR(MAX),              
    @xmlFlags       INT = 0,              
    @ServiceSeq     INT = 0,              
    @WorkingTag     NVARCHAR(10)= '',              
    @CompanySeq     INT = 1,              
    @LanguageSeq    INT = 1,               
    @UserSeq        INT = 0,              
    @PgmSeq         INT = 0              
AS              
    DECLARE   @docHandle    INT,               
              @DelvInSeq    INT,          
              @DateFr       NCHAR(8),          
              @DateTo       NCHAR(8),          
              @EmpSeq       INT,          
              @DeptSeq      INT,          
              @CustSeq      INT,          
              @MakerSeq     INT,        
              @SMImpType    INT,          
              @IsSlip       INT,          
              @FactUnit     INT,          
              @BizUnit      INT,          
              @SMSourceType INT,          
              @PJTName      NVARCHAR(200),          
              @PJTNo        NVARCHAR(100),          
              @DelvInNo     NVARCHAR(100),        
              @POEmpSeq     INT,          
              @PODeptSeq    INT,        
              @ItemMClass   INT,            -- 20100318 박소연 추가  
              @ItemLClass   INT,            -- 20100318 박소연 추가  
              @WHSeq        INT,            -- 2010.06.09 정동혁추가  
              @AssetSeq     INT,            -- 20100701 박소연 추가  
              @ItemSeq      INT,            -- 20100701 박소연 추가  
              @SlipId       NVARCHAR(40),   -- 20100701 박소연 추가  
              @OrderTypeSeq INT,        
              @CustNo       NVARCHAR(30),    
              @DelvMngNo    NCHAR(24),       -- 11.04.25 김세호 추가  
              @ItemName     NVARCHAR(100),    
              @ItemNo       NVARCHAR(100),    
              @Spec         NVARCHAR(100),    
              @PONo         NVARCHAR(12),     -- 11.11.23. 김세호 추가  
              @IsPJTPur     INT,  
              @WorkOrderNo  NVARCHAR(100),  
              @DelvCustSeq  INT  ,             --납품거래처 20150121 황지혜 추가   
              @DelvNo       NCHAR(12),         --납품번호   20150212 황지혜 추가   
              @MstRemark    NVARCHAR(100)      --특이사항   20150602 이범확 추가 
             ,@ProdDistrictSeq INT 
                
    DECLARE @Word1 NVARCHAR(50),    
            @Word2 NVARCHAR(50)    
        
    SELECT @Word1 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 16015    
      IF  @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = '외주'     
        
    SELECT @Word2 = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq AND WordSeq = 2896    
    IF @@ROWCOUNT = 0 OR ISNULL( @Word2, '' ) = '' SELECT @Word2 = '구매'     
            
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                    
          
    SELECT  @DelvInSeq    = ISNULL(DelvInSeq    , 0),          
            @DateFr       = ISNULL(DateFr       ,''),          
            @DateTo       = ISNULL(DateTo       ,''),          
            @EmpSeq       = ISNULL(EmpSeq       , 0),          
            @DeptSeq      = ISNULL(DeptSeq      , 0),          
            @CustSeq      = ISNULL(CustSeq      , 0),          
            @SMImpType    = ISNULL(SMImpType    , 0),          
            @IsSlip       = ISNULL(IsSlip       , 0),          
            @FactUnit     = ISNULL(FactUnit     , 0),          
            @BizUnit      = ISNULL(BizUnit      , 0),          
            @SMSourceType = ISNULL(SMSourceType , 0),          
            @PJTName      = ISNULL(PJTName      ,''),          
            @PJTNo        = ISNULL(PJTNo        ,''),          
            @POEmpSeq     = ISNULL(POEmpSeq     , 0),          
            @PODeptSeq    = ISNULL(PODeptSeq    , 0),        
            @DelvInNo     = ISNULL(DelvInNo  ,''),        
            @ItemMClass   = ISNULL(ItemMClass   , 0),       -- 20100318 박소연 추가  
            @ItemLClass   = ISNULL(ItemLClass   , 0),       -- 20100318 박소연 추가  
            @WHSeq        = ISNULL(WHSeq        , 0),        
            @AssetSeq     = ISNULL(AssetSeq     , 0),       -- 20100701 박소연 추가  
            @ItemSeq      = ISNULL(ItemSeq      , 0),       -- 20100701 박소연 추가  
            @SlipId       = ISNULL(SlipId       ,''),       -- 20100701 박소연 추가  
            @OrderTypeSeq = ISNULL(OrderTypeSeq, 0),        
            @CustNo       = ISNULL(CustNo      , ''),        
            @MakerSeq     = ISNULL(MakerSeq     , 0),    
            @DelvMngNo    = ISNULL(DelvMngNo    , ''),       -- 11.04.25  김세호 추가  
            @ItemName     = ISNULL(ItemName     , ''),    
            @ItemNo       = ISNULL(ItemNo       , ''),    
            @Spec         = ISNULL(Spec         , ''),    
            @PONo         = ISNULL(PONo         , ''),        -- 11.11.23. 김세호 추가  
            @IsPJTPur     = ISNULL(IsPJTPur,   0)    ,  
            @WorkOrderNo  = ISNULL(WorkOrderNo  , ''),  
            @DelvCustSeq  = ISNULL(DelvCustSeq  ,   0),        --납품거래처 20150121 황지혜 추가   
            @DelvNo       = ISNULL(DelvNo       , ''),         -- 납품번호  20150212 황지혜 추가   
            @MstRemark    = ISNULL(MstRemark    , '')          -- 특이사항   20150602 이범확 추가
           ,@ProdDistrictSeq = ISNULL(ProdDistrictSeq,0)
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)                   
    WITH (  DelvInSeq    INT ,          
            DateFr       NCHAR(8),       
            DateTo       NCHAR(8),          
            EmpSeq       INT,          
            DeptSeq      INT,          
            CustSeq      INT,          
            SMImpType    INT,          
            IsSlip       INT,         
            FactUnit     INT,          
            BizUnit      INT,          
            SMSourceType INT,          
            PJTName      NVARCHAR(200),          
            PJTNo        NVARCHAR(100),          
            POEmpSeq     INT,          
            PODeptSeq    INT,        
            DelvInNo     NVARCHAR(100),        
            ItemMClass   INT,           -- 20100318 박소연 추가        
            ItemLClass   INT,           -- 20100318 박소연 추가               
            WHSeq          INT,        
            AssetSeq     INT,           -- 20100701 박소연 추가        
            ItemSeq      INT,           -- 20100701 박소연 추가        
            SlipId       NVARCHAR(40),   -- 20100701 박소연 추가        
            OrderTypeSeq INT,        
            CustNo       NVARCHAR(30),        
            MakerSeq     INT,    
            DelvMngNo    NCHAR(24),     -- 11.04.25 김세호 추가    
            ItemName     NVARCHAR(100),        
              ItemNo       NVARCHAR(100),        
            Spec         NVARCHAR(100),    
            PONo         NVARCHAR(12),   -- 11.11.23. 김세호 추가     
            IsPJTPur     INT ,  
            WorkOrderNo  NVARCHAR(100),    
            DelvCustSeq  INT,             -- 납품거래처 20150121 황지혜 추가  
            DelvNo       NCHAR(12),       -- 납품번호   20150212 황지혜 추가   
            MstRemark    NVARCHAR(100)    -- 특이사항   20150602 이범확 추가
           ,ProdDistrictSeq INT 
         )        
            
 IF @DateFr = '' SET @DateFr = '19000101'          
    IF @DateTo = ''           
    BEGIN          
        SELECT @DateTo = '99991231'          
 END          
  
    --=====================--  
    -- 물류시작월 가져오기 --  
    --=====================-- 2014.11.11 김용현 추가  
    DECLARE @EnvValue NCHAR(6)  
      
    EXEC dbo._SCOMEnv @CompanySeq,1006,@UserSeq,@@PROCID,@EnvValue OUTPUT      
            
     -- 활동센터(구매요청)을 가져오기 위함  2014.11.11 김용현 추가         
     SELECT EmpSeq AS EmpSeq ,          
            CCtrSeq AS CCtrSeq ,          
            CCtrName AS CCtrName          
       INTO #CCrt           
       FROM _FnAdmEmpCCtr(@CompanySeq, CASE WHEN LEFT(@DateFr, 6) = '190001' THEN @EnvValue ELSE LEFT(@DateFr, LEFT(@DateFr, 6)) END  )           
            
            
    -- PaymentNo를 가져오기 위한 로직 추가           
    CREATE TABLE #Tmp_Payment          
    (          
        IDX_NO         INT ,          
        SourceSeq      INT,          
        SourceSerl     INT,          
        SourceType     NCHAR(1),          
          PaymentNo      NVARCHAR(100),           
        PaymentSeq     INT          
    )          
            
    CREATE TABLE #Tmp_BuyingAccInfo          
    (          
        IDX_NO         INT IDENTITY,          
        SourceSeq      INT,          
        SourceSerl     INT,          
        SourceType     NCHAR(1)          
    )          
            
    -- 원천테이블            
    CREATE TABLE #TMP_PROGRESSTABLE         
    (        
        IDOrder INT,         
        TABLENAME   NVARCHAR(100)        
    )                    
            
    -- 원천 데이터 테이블            
    CREATE TABLE #TCOMProgressTracking         
    (        
        IDX_NO INT,                     
        IDOrder INT,                    
        Seq  INT,                    
        Serl  INT,                
        SubSerl     INT,                    
        Qty    DECIMAL(19, 5),          
        STDQty  DECIMAL(19, 5),         
        Amt  DECIMAL(19, 5),         
        VAT   DECIMAL(19, 5)        
    )          
                
    -- 원천테이블              
    CREATE TABLE #TMP_SOURCETABLE         
    (        
        IDOrder INT,         
        TABLENAME   NVARCHAR(100)        
    )                      
              
    -- 원천 데이터 테이블              
    CREATE TABLE #TCOMSourceTracking         
    (        
        IDX_NO INT,                     
        IDOrder INT,                    
        Seq  INT,                    
        Serl  INT,                
        SubSerl     INT,                      
        Qty    DECIMAL(19, 5),          
        STDQty  DECIMAL(19, 5),         
        Amt  DECIMAL(19, 5),         
        VAT   DECIMAL(19, 5)        
    )                            
              
    CREATE TABLE #TmpPOData          
    (          
        IDX_NO         INT IDENTITY,          
        SourceSeq      INT,          
        SourceSerl    INT,            
        SourceType     NCHAR(1)        
    )          
          
    CREATE TABLE #TempSOSpec          
    (          
       Seq       INT IDENTITY,          
       OrderSeq  INT,          
       OrderSerl INT,          
       SpecName  NVARCHAR(100),          
       SpecValue NVARCHAR(100)          
    )          
    CREATE TABLE #TMP_ACC_DATA        
    (        
        IDX_NO         INT IDENTITY,          
        SourceSeq      INT,          
        SourceSerl     INT,          
        SourceType     NCHAR(1)      
    )          
 -- 원천코드 담기        
       
    INSERT INTO #TMP_ACC_DATA          
         SELECT DISTINCT    -- 20110314 추가           
                A.SourceSeq         AS SourceSeq   , -- 원천순번          
                  A.SourceSerl        AS SourceSerl  ,          
                A.SourceType        AS SourceType    
           From _TPUBuyingAcc                   AS A  WITH(NOLOCK)            
                           JOIN _TDACust        AS B  WITH(NOLOCK) ON A.CompanySeq      = B.CompanySeq          
                                                                  AND A.CustSeq         = B.CustSeq          
                           JOIN _TDAItem        AS C  WITH(NOLOCK) ON A.CompanySeq      = C.CompanySeq          
                                                                  AND A.ItemSeq         = C.ItemSeq          
                           JOIN _TDAItemAsset   AS CA WITH(NOLOCK) ON C.CompanySeq      = CA.CompanySeq          
                                                                  AND C.AssetSeq        = CA.AssetSeq          
                LEFT OUTER JOIN _TDAUnit        AS D  WITH(NOLOCK) ON A.companySeq      = D.CompanySeq          
                                                                  AND A.UnitSeq         = D.UnitSeq          
                LEFT OUTER JOIN _TDAEmp         AS E  WITH(NOLOCK) ON A.CompanySeq      = E.CompanySeq          
                                                                  AND A.EmpSeq          = E.EmpSeq          
                LEFT OUTER JOIN _TDADept        AS I  WITH(NOLOCK) ON A.CompanySeq      = I.CompanySeq          
                                                                  AND A.DeptSeq         = I.DeptSeq          
                LEFT OUTER JOIN _TDAWH          AS J  WITH(NOLOCK) ON A.CompanySeq      = J.CompanySeq          
                                                    AND A.WHSeq           = J.WHSeq          
                LEFT OUTER JOIN _TACSlipRow     AS R  WITH(NOLOCK) ON A.CompanySeq      = R.CompanySeq          
                                                                  AND A.SlipSeq         = R.SlipSeq          
                LEFT OUTER JOIN _TDAFactUnit    AS T  WITH(NOLOCK) ON A.CompanySeq      = T.CompanySeq      --            
                                                                  AND A.FactUnit        = T.FactUnit          
                LEFT OUTER JOIN _TDAFactUnit    AS TT WITH(NOLOCK) ON J.CompanySeq      = TT.CompanySeq     --            
                                                                  AND J.FactUnit        = TT.FactUnit          
                LEFT OUTER JOIN _TDABizUnit     AS SS WITH(NOLOCK) ON T.CompanySeq      = SS.CompanySeq     --            
                                                                  AND T.BizUnit         = SS.BizUnit          
                LEFT OUTER JOIN _TPJTProject    AS P  WITH(NOLOCK) ON A.CompanySeq      = P.CompanySeq          
                                                                  AND A.PJTSeq          = P.PJTSeq    
                LEFT OUTER JOIN _TPUDelvInRetro    AS RE WITH(NOLOCK) ON A.SourceSeq   = RE.DelvInSeq       -- 2011.05.23 김세호 추가    
                                                                  AND A.CompanySeq  = RE.CompanySeq    
          WHERE A.CompanySeq   = @CompanySeq          
 AND   (@FactUnit  = 0 OR A.FactUnit    = @FactUnit OR TT.FactUnit = @FactUnit)          
            AND   (@BizUnit  = 0 OR A.BizUnit    = @BizUnit OR SS.BizUnit = @BizUnit)          
            And (@IsSlip = 0 or                                         -- 2011. 5. 26 hkim 주석처리 되어 있던 것을 다시 살려놓음    
                (@IsSlip = '1039001' And A.SlipSeq > 0 ) or            
                (@IsSlip = '1039002' And ISNULL(A.SlipSeq,0) = 0))            
            AND A.DelvInDate BETWEEN @DateFr AND @DateTo    
            AND (@EmpSeq  = 0 OR   (  E.EmpSeq = @EmpSeq))          
            AND (@DeptSeq = 0 OR  ( I.DeptSeq = @DeptSeq))          
            AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)          
            AND (@CustNo  = ''        OR B.CustNo    Like @CustNo + '%')        
            AND (@SMImpType = 0 OR A.SMImpType = @SMImpType)          
    AND (@SMSourceType = 0 OR A.SourceType = RIGHT(@SMSourceType, 1) )          
            AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')          
            AND (@PJTNo = '' OR P.PJTNo LIKE @PJTNo + '%')           
            AND (@DelvInNo = '' OR A.DelvInNo LIKE @DelvInNo + '%')        
            AND (@AssetSeq     = 0         OR CA.AssetSeq  = @AssetSeq)        -- 20100701 박소연 추가        
            AND (@SlipId       = ''        OR R.SlipID     LIKE @SlipId + '%') -- 20100701 박소연 추가    -- 2011. 5. 26 hkim 주석처리 되어 있던 것을 다시 살려놓음    
            AND (@WHSeq        = 0         OR A.WHSeq      = @WHSeq)       
            AND (@ItemSeq  = 0  OR A.ItemSeq = @ItemSeq)    
            --AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')    
            --AND (@ItemNo   = '' OR C.ItemNo LIKE @ItemNo + '%')    
            --AND (@Spec = '' OR C.Spec LIKE @Spec + '%')    
            AND ((A.Qty <> 0) OR (ISNULL(RE.DelvInSeq, 0) <> 0))                 -- 2011.05.23 김세호 추가              
            
   -- Payment 원천담기        
  INSERT INTO #Tmp_Payment        
  SELECT IDX_NO    ,   
         SourceSeq ,        
         SourceSerl ,        
         SourceType ,        
         '', 0        
    FROM #TMP_ACC_DATA        
   WHERE SourceType = '1'      
       
      
-------납품 원천 담기---------------      
        
  INSERT #TMP_SOURCETABLE             
  SELECT 1, '_TPUDelvItem'                
                 
  EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#Tmp_Payment','SourceSeq', 'SourceSerl',''            
       
    SELECT A.IDX_NO ,             
           I.DelvSeq,      
           I.DelvSerl,      
           I.MakerSeq      
      INTO #TMP_DelvItem      
      FROM #TCOMSourceTracking AS A             
             JOIN _TPUDelv      AS C WITH(NOLOCK) ON C.CompanySeq  =@CompanySeq AND A.Seq  = C.DelvSeq             
           JOIN _TPUDelvItem  AS I WITH(NOLOCK) ON I.CompanySeq  =@CompanySeq AND A.Seq = I.DelvSeq AND A.Serl = I.DelvSerl        
     WHERE ISNULL(C.IsReturn, '') <> '1' -- 2011. 3. 3 hkim 추가 ; 반품건은 중복해서 납품 코드를 가져올수 있다.       
      
    
      
      
  TRUNCATE TABLE #TMP_SOURCETABLE        
  TRUNCATE TABLE #TCOMSourceTracking                
      
-----------------------------------------      
      
       
  -- Payment  찾기        
  INSERT #TMP_PROGRESSTABLE              
  SELECT 1, '_TSLImpPaymentItem'         -- 수입Payment          
           
  EXEC _SCOMProgressTracking  @CompanySeq, '_TPUDelvInItem', '#Tmp_Payment','SourceSeq', 'SourceSerl',''              
           
  UPDATE #Tmp_Payment          
     SET PaymentNo  = C.PaymentRefNo,          
      PaymentSeq = C.PaymentSeq          
    FROM #Tmp_Payment                   AS A          
         JOIN #TCOMProgressTracking     AS B ON A.IDX_NO = B.IDX_NO          
         LEFT OUTER JOIN _TSLImpPayment AS C ON C.CompanySeq = @CompanySeq           
                                            AND B.Seq        = C.PaymentSeq         
       
  TRUNCATE TABLE #TMP_PROGRESSTABLE            
  TRUNCATE TABLE #TCOMProgressTracking       
      
      
  -- 외주건들 담기        
  SELECT *           
    INTO #Tmp_BuyingAccInfoOSP          
    from #TMP_ACC_DATA          
   WHERE SourceType = '2'          
        
  INSERT #TMP_SOURCETABLE             
  SELECT 1, '_TSLOrderItem'         -- 수주            
  UNION ALL        
  SELECT 2, '_TPDOSPPOItem'         -- 외주발주          
           
  EXEC _SCOMSourceTracking  @CompanySeq, '_TPDOSPDelvInItem', '#Tmp_BuyingAccInfoOSP','SourceSeq', 'SourceSerl',''           
             
  SELECT DISTINCT         
      IDX_NO ,             
      ISNULL(C.OrderNo,'') AS SoNo ,            
      ISNULL(C.PONo   ,'') AS PoNo ,          
      ISNULL(C.CustSeq, 0) AS CustSeq,            
      ISNULL(I.OrderSeq, 0) AS OrderSeq,          
      ISNULL(I.OrderSerl, 0) AS OrderSerl         
    INTO #SOInfo            
    FROM #TCOMSourceTracking AS A             
           JOIN _TSLOrder AS C WITH(NOLOCK) ON C.CompanySeq  =@CompanySeq AND A.Seq  = C.OrderSeq              
         JOIN _TSLOrderItem AS I WITH(NOLOCK) ON I.CompanySeq  =@CompanySeq AND A.Seq = I.OrderSeq AND A.Serl = I.OrderSerl --AND A.SubSerl = I.OrderSubSerl                                              
   WHERE A.IDOrder = 1         
        
    SELECT DISTINCT        
           A.IDX_NO,          
           A.SourceType,          
           0 AS Seq, --B.Seq AS Seq,     
           C.OSPPONo AS PONo,        -- 11.11.23 김세호 추가         
           C.DeptSeq AS PODeptSeq,          
           C.EmpSeq AS POEmpSeq,     
           CONVERT(INT, '')  AS SMPayType,         
           A.SourceSeq,          
           A.SourceSerl,        
           F.CCtrSeq,  -- 20100419 박소연 추가        
           C.IsAdjMat,  -- 20111018 hkim    
           0 AS MatCalcCnt,  -- 입고건에 정산된 자재 카운트    
           (SELECT COUNT(1) FROM _TPDOSPPOItemMat WHERE CompanySeq = @CompanySeq AND OSPPOSeq = D.OSPPOSeq AND OSPPOSerl = D.OSPPOSerl AND IsSale <> '1') AS MatCnt, -- 2011. 10. 18 hkim      
           E.WorkOrderNo       
      INTO #TmpPO          
      FROM #Tmp_BuyingAccInfoOSP    AS A          
           JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO          
           JOIN _TPDOSPPO   AS C ON B.Seq = C.OSPPOSeq          
           JOIN _TPDOSPPOItem  AS D ON D.CompanySeq = @CompanySeq AND D.OSPPOSeq = B.Seq AND D.OSPPOSerl = B.Serl        
           LEFT OUTER JOIN _TPDSFCWorkOrder AS E ON E.CompanySeq = D.CompanySeq AND E.WorkOrderSeq = D.WorkOrderSeq AND E.WorkOrderSerl = D.WorkOrderSerl -- 20100419 박소연 추가        
           LEFT OUTER JOIN _TPDBaseWorkCenter AS F ON F.CompanySeq = E.CompanySeq AND F.WorkCenterSeq = E.WorkCenterSeq                                   -- 20100419 박소연 추가        
     WHERE C.CompanySeq = @CompanySeq          
       AND A.SourceType = 2          
       AND B.Qty <> 0        
       AND B.IDOrder = 2    
    -- 외주건 추적 끝      
    
    
    
    -- 외주발주대로 불출이 아닌 건은 아래 계약의 Mat이 담길테니 일단 0으로 업데이트 2011. 11. 2 hkim    
      UPDATE #TmpPO    
       SET MatCnt = 0    
      FROM #TmpPO    
     WHERE IsAdjMat <> '1'    
    
    
    -- 외주발주대로 정산이 아닌 건은 계약의 유상사급을 제외한 자재수 담기 2011. 10. 18 hkim    
    UPDATE #TmpPO    
       SET MatCnt = (SELECT COUNT(1) FROM _TPDOSPPriceSubItem WHERE CompanySeq = @CompanySeq AND GoodItemSeq = C.ItemSeq AND CustSeq = C.CustSeq AND FactUnit = C.FactUnit AND Serl = C.Serl AND ISNULL(IsSale, '') <> '1')    
      FROM #TmpPO                 AS A    
           JOIN _TPDOSPDelvIn     AS D ON A.SourceSeq  = D.OSPDelvInSeq AND D.CompanySeq = @CompanySeq    
           JOIN _TPDOSPDelvInItem AS B ON A.SourceSeq  = B.OSPDelvInSeq     
                                      AND A.SourceSerl = B.OSPDelvInSerl    
           JOIN _TPDOSPPriceItem  AS C ON B.CompanySeq = C.CompanySeq     
                                      AND B.ItemSeq    = C.ItemSeq     
                    AND B.OSPAssySeq = C.AssySeq     
                                      AND B.ItemBOMRev = C.ItemBOMRev    
                                      AND B.ProcRev    = C.ProcRev    
                                      AND D.CustSeq    = C.CustSeq    
                                      AND D.FactUnit   = C.FactUnit    
     WHERE A.Sourcetype = '2'    
       AND A.IsAdjMat <> '1'    
       AND B.CompanySeq = @CompanySeq    
       AND D.OSPDelvInDate BETWEEN C.StartDate AND C.EndDate    
     
    
    -- 해당입고건의 정산된 자재 카운트 = MatCalcCnt, 정산 대상 자재 카운트 = MatCnt -- 12.05.23 BY 김세호    
    
    UPDATE #TmpPO    
       SET MatCalcCnt = (SELECT COUNT(1) FROM _TPDOSPDelvInItemMat WHERE CompanySeq = @CompanySeq AND OSPDelvInSeq = A.SourceSeq AND OSPDelvInSerl = A.SourceSerl)    
      FROM #TmpPO AS A    
    
    
    
    -- 내수건 담기        
    SELECT *           
      INTO #Tmp_BuyingAccInfoDelvIn        
      from #TMP_ACC_DATA          
     WHERE SourceType <> '2'          
        
    TRUNCATE TABLE #TMP_SOURCETABLE        
    TRUNCATE TABLE #TCOMProgressTracking          
            
            
    INSERT #TMP_SOURCETABLE             
      SELECT 1, '_TSLOrderItem'            -- 수주            
    UNION ALL        
    SELECT 2, '_TPUORDPOItem'            -- 발주          
    UNION ALL  
    SELECT 3, '_TPUORDPOReqItem'         -- 구매요청  
      
    EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#Tmp_BuyingAccInfoDelvIn','SourceSeq', 'SourceSerl',''           
                         
    SELECT DISTINCT        
           IDX_NO ,             
           ISNULL(C.OrderNo,'') AS OrderNo       
      INTO #SOInfo2            
      FROM #TCOMSourceTracking AS A             
           JOIN _TSLOrder AS C WITH(NOLOCK) ON C.CompanySeq  =@CompanySeq AND A.Seq  = C.OrderSeq             
     WHERE A.IDOrder = 1         
          
  INSERT INTO #TmpPO          
  SELECT DISTINCT         
      A.IDX_NO,          
      A.SourceType,          
      0 AS Seq, --B.Seq AS Seq,     
      C.PONo AS PONo,        -- 11.11.23 김세호 추가              
      C.DeptSeq AS PODeptSeq,          
      C.EmpSeq  AS POEmpSeq,                  
      ISNULL(D.SMPayType, 0) AS SMPayType,     -- 11.05.27 김세호 추가         
      A.SourceSeq,          
      A.SourceSerl,        
      0 AS CCtrSeq  ,-- 20100419 박소연 추가         
      '' AS IsAdjMat,    -- 2011. 10. 18 hkim    
      0  AS MatCnt,    -- 2011. 10. 18 hkim    
      0  AS MatCalcCnt,  
      ''    
    FROM #Tmp_BuyingAccInfoDelvIn AS A          
      JOIN #TCOMSourceTracking    AS B ON A.IDX_NO = B.IDX_NO          
      JOIN _TPUORDPO              AS C ON B.Seq = C.POSeq          
      JOIN _TPUORDPOItem          AS D ON B.Seq = D.POSeq    
                                      AND B.Serl = D.POSerl    
                                      AND C.CompanySeq= D.CompanySeq     
   WHERE C.CompanySeq = @CompanySeq     
     AND A.SourceType = 1 AND B.Qty <> 0 AND B.IDOrder =  2           
  
  
  
-- sdlee ---------------------------------------------------------------------------------------------------------  
  
    CREATE TABLE #TEMP_TPUORDPOReq  
    (  
        IDX_NO          INT,  
        POReqEmpSeq     INT  
    )  
  
    INSERT INTO #TEMP_TPUORDPOReq  
    (  
        IDX_NO,  
        POReqEmpSeq  
    )  
    SELECT A.IDX_NO,  
           B.EmpSeq  
    FROM #TCOMSourceTracking AS A  
    JOIN _TPUORDPOReq AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.IDOrder = 3 AND B.POReqSeq = A.Seq  
  
  
-----------------------------------------------------------------------------------------------------------  
  
  
  
     
/**************************[생산사양 가져오기] 20091229 박소연 추가***********************************/          
     
DECLARE @SpecName NVARCHAR(100), @SpecValue NVARCHAR(100), @OrderSeq INT, @OrderSerl INT, @SpecSeq INT, @SubSeq INT      
        
INSERT INTO  #TempSOSpec      
SELECT DISTINCT C.OrderSeq, C.OrderSerl,'',''      
  FROM #SOInfo AS A JOIN _TSLOrder AS D ON A.Sono = D.OrderNo AND D.CompanySeq = @CompanySeq      
        JOIN _TSLOrderItem AS B ON D.OrderSeq = B.OrderSeq AND B.CompanySeq = @CompanySeq      
                    JOIN _TSLOrderItemspecItem AS C ON B.OrderSeq = C.OrderSeq AND B.OrderSerl = C.OrderSerl AND C.CompanySeq = @CompanySeq      
      
    SELECT @SpecSeq = 0      
      
    WHILE (1=1)      
    BEGIN      
        SET ROWCOUNT 1      
      
        SELECT @SpecSeq = Seq, @OrderSeq = OrderSeq, @OrderSerl = OrderSerl      
          FROM #TempSOSpec      
         WHERE Seq > @SpecSeq      
         ORDER BY Seq      
      
        IF @@Rowcount = 0 BREAK      
      
        SET ROWCOUNT 0      
      
        SELECT @SubSeq = 0, @SpecName = '', @SpecValue = ''      
      
        WHILE(1=1)      
        BEGIN      
            SET ROWCOUNT 1      
      
            SELECT @SubSeq = OrderSpecSerl      
              FROM _TSLOrderItemspecItem      
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq      
             ORDER BY OrderSpecSerl      
      
            IF @@Rowcount = 0 BREAK      
      
            SET ROWCOUNT 0      
      
            IF ISNULL(@SpecName,'') = ''      
              BEGIN       
                SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')      
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)      
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq      
                 WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq      
            END      
            ELSE      
            BEGIN      
                SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')      
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)      
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq      
                 WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq      
            END      
      
            UPDATE #TempSOSpec      
               SET SpecName = @SpecName, SpecValue = @SpecValue      
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl      
      
        END      
      
    END      
    SET ROWCOUNT 0       
/*********************[생산사양 가져오기] 끝***************************************************/            
    
 CREATE INDEX IDX_#Tmp_Payment ON #Tmp_Payment(SourceSeq, SourceSerl, SourceType)        
 CREATE INDEX IDX_#TMP_ACC_DATA ON #TMP_ACC_DATA(IDX_No, SourceSeq, SourceSerl, SourceType)        
 CREATE INDEX IDX_#TmpPO ON #TmpPO(SourceSeq, SourceSerl, SourceType)        
 CREATE INDEX IDX_#SOInfo ON #SOInfo(IDX_NO)        
 CREATE INDEX IDX_#SOInfo2 ON #SOInfo2(IDX_NO)        
   
 CREATE INDEX IDX_#TMP_DelvItem ON #TMP_DelvItem (IDX_NO)  
 CREATE INDEX IDX_#TCOMSourceTracking ON #TCOMSourceTracking (IDOrder, IDX_NO)  
 CREATE INDEX IDX_#TEMP_TPUORDPOReq ON #TEMP_TPUORDPOReq (IDX_NO)    
    
        SELECT  A.CustSeq                AS CustSeq     , -- 거래처코드          
                B.CustName               AS CustName    , -- 거래처먕        
                B.CustNo                  AS  CustNo      , -- 거래처번호     -- 12.02.21 김세호 추가       
                A.DelvInDate             AS DelvInDate  , -- 입고일          
                A.BuyingAccDate          AS BuyingAccDate   ,        
                ISNULL(IG.MinorName ,'') AS ItemLClassName  , -- 20100318 박소연 추가          
                ISNULL(IH.MinorName ,'') AS ItemMClassName  , -- 20100318 박소연 추가     
                ISNULL(IL.MinorName ,'') AS ItemSClassName  , -- 20110613 김세호 추가    
                ISNULL(C.ItemName   ,'') AS ItemName    , -- 품명          
                ISNULL(C.ItemNo     ,'') AS ItemNo      , -- 품번          
                ISNULL(C.Spec       ,'') AS Spec        , -- 규격          
               ISNULL(D.UnitName   ,'') AS UnitName    , -- 단위          
                ISNULL(E.EmpName   ,'')  AS EmpName     , -- 담당자          
                ISNULL(G.CurrName   ,'') AS CurrName    , -- 통화          
                A.ExRate                 AS ExRate      , -- 환율          
                A.CurrSeq                AS CurrSeq     , -- 통화코드          
                ISNULL(E.EmpSeq   ,'')   AS EmpSeq      , -- 사원코드          
                ISNULL(I.DeptName ,'')   AS DeptName    , -- 부서          
                ISNULL(I.DeptSeq  ,'')   AS DeptSeq     , -- 부서내부코드          
                ISNULL(A.Price      ,0)  AS Price       , -- 입고단가          
                ISNULL(A.PriceUnitSeq,0) AS PriceUnitSeq,          
                ISNULL(A.PriceQty   ,0)  AS PriceQty    ,          
                  ISNULL(UU.UnitName  ,'') AS PriceUnitName   ,          
                ISNULL(A.Qty        ,0)  AS Qty         , -- 입고수량          
                ISNULL(A.CurAmt     ,0)  AS CurAmt      , -- 입고금액          
                ISNULL(A.CurVAT     ,0)  AS CurVAT      , -- 부가세          
                ISNULL(A.CurAmt,0) +           
                ISNULL(A.CurVAT,0)       AS TotCurAmt   , -- 금액계          
                ISNULL(A.DomAmt     ,0)  AS DomAmt      , -- 입고원화금액          
                ISNULL(A.DomPrice   ,0)  AS DomPrice    , -- 입고원화단가          
                ISNULL(A.DomVAT     ,0)  AS DomVAT      , -- 원화부가세          
                ISNULL(A.DomAmt     ,0)  +          
                ISNULL(A.DomVAT     ,0)  AS TotDomAmt   , -- 입고원화금액          
                ISNULL(A.IsVAT      ,0)  AS IsVAT       , -- 부가세포함여부          
                ISNULL(J.WHName     ,'') AS WHName      , -- 창고          
                A.TaxDate                AS TaxDate     , -- 세금계산서일          
                A.PayDate                AS PayDate     , -- 지급예정일          
                A.WHSeq                  AS WHSeq       , -- 창고내부코드          
                ISNULL(A.StdUnitQty,0)   AS STDUnitQty  , -- 기준단위수량          
                ISNULL(K.UnitName   ,'') AS StdUnitName , -- 단위(기준단위)          
                ''                       AS Sel         , --선택          
                ISNULL(A.AccSeq     ,0)  AS AccSeq      ,         
                ISNULL(W.AccName    ,'') AS AccName     ,          
                ISNULL(A.AntiAccSeq ,0)  AS AntiAccSeq  ,          
                ISNULL(X.AccName    ,'') AS AntiAccName ,          
                ISNULL(A.VatAccSeq  ,0)  AS VATAccSeq   ,          
                ISNULL(YY.AccName    ,'')AS VATAccName  ,          
                ISNULL(A.MatAccSeq  ,0)  AS MatAccSeq   ,          
                ISNULL(Y.AccName    ,'') AS MatAccname  ,          
                A.CustSeq                AS CustSeq     , -- 거래처코드          
                A.UnitSeq                AS UnitSeq     , -- 단위코드          
                A.StdUnitSeq             AS STDUnitSeq  , --           
                (CASE WHEN ISNULL(A.Remark,'') = '' AND A.SourceType  = '2' THEN (SELECT Remark FROM _TPDOSPDelvInitem WHERE OSPDelvInSeq = A.SourceSeq AND OSPDelvInSerl = A.SourceSerl and CompanySeq = @CompanySeq) ELSE ISNULL(A.Remark,'') END)    AS Remark, -- 비고          
         
                A.IsFiction              AS IsFiction   , -- 의제매입여부          
                A.FicRateNum             AS FicRateNum  , -- 의제매입 분자          
                A.FicRateDen             AS FicRateDen  , -- 의제매입 분모          
                ISNULL(Q.EvidName,'')    AS EvidName    , -- 증빙          
                A.EvidSeq                AS EvidSeq     , -- 증빙내부코드          
                R.SlipId                 AS SlipId      , -- SlipId            
                A.SourceType             AS SourceType  , -- 원천타입           
                A.SourceSeq              AS SourceSeq   , -- 원천순번          
                A.SourceSerl             AS SourceSerl  , -- 원천세부순번          
                A.BizUnit                AS BizUnit     ,          
                A.FactUnit               AS FactUnit    ,          
                  CASE ISNULL(S.BizUnitName , '') WHEN '' THEN SS.BizUnitName ELSE S.BizUnitName END AS BizUnitName ,          
                CASE ISNULL(T.FactUnitName, '') WHEN '' THEN TT.FactUnitName ELSE T.FactUnitName END       AS FactUnitName,          
                CASE WHEN A.SourceType  = '1' THEN @Word2          
                     WHEN A.SourceType  = '2' THEN @Word1      
                     ELSE ''          
                END                      AS SourceTypeName ,          
                A.SlipSeq                AS SlipSeq        ,          
                A.BuyingAccSeq           AS BuyingAccSeq   ,       
                ISNULL(A.SMPayType, 0)   AS SMPayType      ,           
                  A.DelvCustSeq            AS DelvCustSeq    ,              
                A.ItemSeq                AS ItemSeq        ,          
                U.CustName               AS DelvCustName   ,          
                AA.VatRate               AS VatRate        ,          
                ZZ.TaxUnit               AS TaxUnit        ,          
              --  ZZ.TaxName               AS TaxNo          ,          
                ZZ.TaxNoAlias            AS TaxNo          ,        
                A.SMImpType              AS SMImpType      ,          
                V.MinorName              AS SMImpTypeName  ,          
                A.PJTSeq                 AS PJTSeq         ,          
                P.PJTName               ,         
                P.PJTNo                 ,          
                IM.PaymentNo             AS PaymentNo      ,          
                IM.PaymentSeq            AS PaymentSeq     ,          
                A.DelvInNo               AS DelvInNo       ,          
                IR.SpecName              AS SpecName       ,  -- 20091229 박소연 추가 생산사양항목          
                IR.SpecValue             AS SpecValue      ,  -- 20091229 박소연 추가 생산사양항목값          
                IR.ORDERSEQ,           
                IR.ORDERSERL,          
                (CASE WHEN ISNULL(A.CCtrSeq, 0) = 0 THEN (CASE A.SourceType WHEN '1' THEN ISNULL(CC.CCtrName, '') WHEN '2' THEN ISNULL(DJ.CCtrName, '') END) ELSE ISNULL(DL.CCtrName, '') END) AS CCtrName, -- 20100419 박소연 수정         
                (CASE WHEN ISNULL(A.CCtrSeq, 0) = 0 THEN (CASE A.SourceType WHEN '1' THEN ISNULL(CC.CCtrSeq, 0)  WHEN '2' THEN ISNULL(DJ.CCtrSeq, 0)  END) ELSE ISNULL(A.CCtrSeq, 0) END) AS CCtrSeq,  -- 20100419 박소연 수정         
                ISNULL(CCrt.CCtrName,'') AS POReqCCtrName,  
                ISNULL(CCrt.CCtrSeq,0) AS POReqCCtrSeq,  
                (CASE WHEN ISNULL(A.CCtrSeq, 0) = 0 THEN (CASE A.SourceType WHEN '1' THEN ISNULL(EA.UMCostType, 0) WHEN '2' THEN ISNULL(DJ.UMCostType, 0) END) ELSE ISNULL(DL.UMCostType, 0) END) AS UMCostType,        -- 2011. 2. 16 hkim        
                (CASE WHEN ISNULL(A.CCtrSeq, 0) = 0 THEN (CASE A.SourceType WHEN '1' THEN ISNULL(EB.MinorName, '')  WHEN '2' THEN ISNULL(EC.MinorName, '')  END) ELSE ISNULL(ED.MinorName, 0) END) AS UMCostTypeName,   -- 2011. 2. 16 hkim     
       
     CASE ISNULL(A.SMRNPMethod, 0) WHEN 0 THEN ISNULL(PO.SMPayType, 0) ELSE ISNULL(A.SMRNPMethod, 0) END AS SMRNPMethod,   -- 11.05.27 김세호 추가            
                ISNULL((SELECT MinorName     
                   From _TDAUMinor     
                   where CompanySeq = @CompanySeq  
                       AND MinorSeq = (CASE ISNULL(A.SMRNPMethod, 0) WHEN 0 THEN ISNULL(PO.SMPayType, 0) ELSE ISNULL(A.SMRNPMethod, 0) END)), '')   AS SMRNPMethodName,   -- 11.05.27 김세호 추가    
                                    
                DI.IsPJT        AS IsPJT,        
                IP2.OrderNo  AS SONO,        
                CA.AssetName AS AssetName,        
                PO.POEmpSeq     AS POEmpSeq,        
                CASE WHEN A.Qty < 0 THEN '1' ELSE '0' END AS IsReturn,  
                
                ISNULL(DE.DelvMngNo, '') AS DelvMngNo,             -- 11.04.24 김세호 추가    
                ISNULL(PO.PONo     , '') AS PONo,                  -- 11.11.23 김세호 추가     
                 CASE WHEN A.SourceType = '1' THEN '1'              -- 2011. 9. 26 hkim 외주자재정산여부 가져오도록 추가    
                                              ELSE CASE WHEN PO.MatCnt = 0 AND PO.MatCalcCnt = 0 THEN '0'     
                                                        WHEN PO.MatCnt > PO.MatCalcCnt THEN '0'    
                                                        ELSE '1' END    
                                              END AS IsMatCalc,    
    
    
                /*자재미정산여부  칼럼 추가(HID)  - 화면에서 전표처리시 해당칼럼 체크되있을경우 메시지처리    
                    (기존처럼 '자재정산여부(=IsMatCalc)' 칼럼으로 전표처리시 메시지처리 할경우,    
             불출자재도없고 정산자재도 없을경우에도 미정산 조회되어서 전표처리시, 자재미정산건이라고 메시지 발생하므로)*/    
    
                 CASE WHEN A.SourceType = '1' THEN '0'                  
                                              ELSE CASE WHEN PO.MatCnt > 0 AND PO.MatCnt > PO.MatCalcCnt   THEN '1'     
                                                   ELSE '0' END    
                                              END AS IsNotMatCalc,    
    
    
    
                 CASE WHEN Q.IsNDVAT = '1' THEN CASE WHEN A.DomVAT <> 0 THEN '1' ELSE '0' END END AS IsNDVAT,  -- 2012. 5. 18 hkim 불공제세부가세유무( 1 - 증빙이 불공제세인데, 부가세가 있는 경우 0 - 그 외)    
                 A.SupplyAmt,  -- 2012. 5. 18 hkim 추가    
                 A.SupplyVAT,   -- 2012. 5. 18 hkim 추가    
                 PO.WorkOrderNo,  
                 EE.EmpName     AS  POEmpName,
                 A.MstRemark    AS  MstRemark,  --2015.06.02 이범확 추가
                 
                ISNULL(DV.MakerSeq, 0) AS MakerSeq,      
                ISNULL(DC.CustName, '') AS MakerName, 
                 
                 -- 2015.10.06   kth     결제구분, 결제기간 추가   
                --P1.PayPeriod AS MakerSeq,      -- 결제기간
                --(SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = P1.UMPayMethod) AS MakerName,     -- 결제구분             
                

                BBP.PayPeriod AS PayPeriod,         -- 결제기간
                BBP.UMPayMethod AS UMPayMethod,     -- 결제구분코드
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = BBP.UMPayMethod) AS UMPayMethodName,     -- 결제구분  

                BBP.DeliPayPeriod AS DeliPayPeriod,         -- 운송결제기간
                BBP.DeliUMPayMethod AS DeliUMPayMethod,     -- 운송결제구분코드
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = BBP.DeliUMPayMethod) AS DeliUMPayMethodName,     -- 운송결제구분            

                DVDA.AccName AS DeliAccName,                 
                AD.DeliAccSeq,                  -- 운송계정코드
                DVOA.AccName AS DeliVsAccName,
                AD.DeliVsAccSeq,                -- 운송상대계정코드
                DVVA.AccName AS DeliVatAccName,
                AD.DeliVatAccSeq,               -- 운송부가세코드
                DVEV.EvidName AS DeliEvidName,
                AD.DeliEvidSeq,                 -- 운송증빙코드
             DVA.DeliCustSeq,                -- 기본운송처코드
                DVB.CustName AS DeliCustName,   -- 기본운송처
                AD.DeliTaxDate,                 -- 운송세금계산서일
                AD.DeliPayDate,                 -- 운송처지급일
                
                ISNULL(DVA.DeliChargePrice,0) AS DeliChargePrice,    -- 운송단가                
                ISNULL(DVA.DeliChargeAmt,0) AS DeliChargeAmt,        -- 운송금액
                ISNULL(DVA.DeliChargeVat,0) AS DeliChargeVat,        -- 운송부가세
                ISNULL(DVA.DeliChargeAmt,0) + ISNULL(DVA.DeliChargeVat,0) AS TotDeliChargeAmt,     -- 운송금액계                
                
                -- 2016.01.13   kth     벌써 4번째정도 또 추가
                ISNULL(DVA.PuPrice,0) AS PuPrice,    -- 매입단가
                ISNULL(DVA.PuIsVat,'') AS PuIsVat,   -- 매입부가세포함여부         

                case a.qty when 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end  AS PuAmt,        -- 매입금액
                case a.qty when 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end AS PuVat,        -- 매입부가세
                case a.qty when 0 then a.CurAmt else ISNULL(DVA.PuAmt,0) end + case a.qty when 0 then a.CurVAT else ISNULL(DVA.PuVat,0) end AS TotPuAmt,     -- 매입금액계

                -- 2016.03.04   kth     약 6번째 추가개발
                ISNULL(BBP.PuPunctuality, 0) AS PuPunctuality,            -- 매입기일엄수
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = BBP.PuPunctuality) AS PuPunctualityNm,

                ISNULL(BBP.DeliPunctuality, 0) AS DeliPunctuality,          -- 운송기일엄수
                (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = BBP.DeliPunctuality) AS DeliPunctualityNm
               ,PA.ProdDistrictSeq AS ProdDistrictSeq
               ,PA.ProdDistirct AS ProdDistrictName


           FROM #TMP_ACC_DATA    AS IT        
                       JOIN _TPUBuyingAcc      AS A  WITH(NOLOCK) ON IT.SourceSeq       = A.SourceSeq        
                                                                 AND IT.SourceSerl      = A.SourceSerl        
                                                                 AND IT.SourceType      = A.SourceType        
                       JOIN _TDACust           AS B WITH(NOLOCK)  ON A.CompanySeq       = B.CompanySeq          
                                                                 AND A.CustSeq          = B.CustSeq          
                       JOIN _TDAItem           AS C WITH(NOLOCK)  ON C.CompanySeq       = @CompanySeq         
                                                                 AND A.ItemSeq          = C.ItemSeq          
                       JOIN _TDAItemAsset      AS CA WITH(NOLOCK) ON C.CompanySeq       = CA.CompanySeq          
                                                                 AND C.AssetSeq         = CA.AssetSeq          
            LEFT OUTER JOIN _TDAUnit           AS D  WITH(NOLOCK) ON A.companySeq       = D.CompanySeq          
                                                                 AND A.UnitSeq          = D.UnitSeq          
            LEFT OUTER JOIN _TDAEmp            AS E  WITH(NOLOCK) ON A.CompanySeq       = E.CompanySeq          
                                                                 AND A.EmpSeq           = E.EmpSeq          
            LEFT OUTER JOIN _TDACurr           AS G  WITH(NOLOCK) ON A.CompanySeq       = G.CompanySeq          
                                                                 AND A.CurrSeq          = G.CurrSeq          
            LEFT OUTER JOIN _TDADept           AS I  WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq          
                                                                 AND A.DeptSeq          = I.DeptSeq          
            LEFT OUTER JOIN _TDAWH             AS J  WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq          
                                                                 AND A.WHSeq            = J.WHSeq          
            LEFT OUTER JOIN _TDAUnit           AS K  WITH(NOLOCK) ON A.Companyseq       = K.CompanySeq          
                                                                 AND A.StdUnitSeq       = K.UnitSeq          
            LEFT OUTER JOIN _TDAEvid            AS Q  WITH(NOLOCK) ON A.CompanySeq       = Q.CompanySeq          
                                                                 AND A.EvidSeq          = Q.EvidSeq          
            LEFT OUTER JOIN _TACSlipRow        AS R  WITH(NOLOCK) ON A.CompanySeq       = R.CompanySeq          
                                                                 AND A.SlipSeq          = R.SlipSeq          
              LEFT OUTER JOIN _TDAAccount        AS W  WITH(NOLOCK) ON A.CompanySeq       = W.CompanySeq     --            
                                                                 AND A.AccSeq           = W.AccSeq           
            LEFT OUTER JOIN _TDAAccount        AS X  WITH(NOLOCK) ON A.CompanySeq       = X.CompanySeq     --            
                                                                   AND A.AntiAccSeq        = X.AccSeq           
            LEFT OUTER JOIN _TDAAccount        AS Y  WITH(NOLOCK) ON A.CompanySeq       = Y.CompanySeq     --            
                                                                 AND A.MatAccSeq        = Y.AccSeq           
            LEFT OUTER JOIN _TDAAccount        AS YY WITH(NOLOCK) ON A.CompanySeq       = YY.CompanySeq     --            
                                                                 AND A.VATAccSeq        = YY.AccSeq           
            LEFT OUTER JOIN _TDABizUnit        AS S  WITH(NOLOCK) ON A.CompanySeq       = S.CompanySeq     --            
                                                                 AND A.BizUnit          = S.BizUnit          
            LEFT OUTER JOIN _TDAFactUnit       AS T  WITH(NOLOCK) ON A.CompanySeq       = T.CompanySeq     --            
                                                                 AND A.FactUnit         = T.FactUnit          
            LEFT OUTER JOIN _TDAFactUnit       AS TT WITH(NOLOCK) ON J.CompanySeq       = TT.CompanySeq     --            
                                                                 AND J.FactUnit         = TT.FactUnit          
            LEFT OUTER JOIN _TDABizUnit        AS SS WITH(NOLOCK) ON T.CompanySeq       = SS.CompanySeq     --            
                                                                 AND T.BizUnit          = SS.BizUnit          
            LEFT OUTER JOIN _TDACust           AS U  WITH(NOLOCK) ON A.Companyseq       = U.CompanySeq          
                                                                 AND A.DelvCustSeq      = U.CustSeq          
            LEFT OUTER  JOIN _TDAUnit          AS UU WITH(NOLOCK) ON A.companySeq       = UU.CompanySeq          
                                                                 AND A.PriceUnitSeq     = UU.UnitSeq             
            LEFT OUTER JOIN _TDAItemSales      AS BB WITH(NOLOCK) ON BB.CompanySeq      = @CompanySeq          
                                                                 AND A.ItemSeq          = BB.ItemSeq          
            LEFT OUTER JOIN _TDAVatRate        AS AA WITH(NOLOCK) ON AA.CompanySeq      = BB.CompanySeq            
                                                                 AND AA.SMVatType       = BB.SMVatType            
                                                                 AND BB.SMVatKind       <> 2003002  -- 면세 제외          
                                                                 AND A.BuyingAccDate BETWEEN AA.SDate AND AA.EDate          
            LEFT OUTER JOIN _TDATaxUnit        AS ZZ WITH(NOLOCK) ON ZZ.CompanySeq      = @CompanySeq          
                                                                 AND I.TaxUnit          = ZZ.TaxUnit          
            LEFT OUTER JOIN _TDASMinor         AS V  WITH(NOLOCK) ON A.CompanySeq       = V.CompanySeq          
                                                                 AND A.SMImpType        = V.MinorSeq          
            LEFT OUTER JOIN _TPJTProject       AS P WITH(NOLOCK)  ON A.CompanySeq       = P.CompanySeq          
                                                                 AND A.PJTSeq           = P.PJTSeq          
            LEFT OUTER JOIN #Tmp_Payment       AS IM              ON IT.SourceSeq       = IM.SourceSeq          
                                                                 AND IT.SourceSerl      = IM.SourceSerl          
                                                                 AND IT.SourceType      = IM.SourceType          
            LEFT OUTER JOIN #SOInfo            AS IP              ON IT.IDX_NO          = IP.IDX_NO    -- 20091229 박소연 추가          
              LEFT OUTER JOIN #SOInfo2           AS IP2              ON IT.IDX_NO          = IP2.IDX_NO            
            LEFT OUTER JOIN #TempSOSpec        AS IR              ON IR.OrderSeq        = IP.OrderSeq        
                                                                   AND IR.OrderSerl       =  IP.OrderSerl -- 20091229 박소연 추가          
            LEFT OUTER JOIN #TmpPO             AS PO              ON A.SourceSeq        = PO.SourceSeq         
                                                                 AND A.SourceSerl       = PO.SourceSerl         
                                                                 AND A.SourceType       = PO.SourceType          
            LEFT OUTER JOIN #CCrt              AS CC              ON A.EmpSeq           = CC.EmpSeq          
            LEFT OUTER JOIN #TMP_DelvItem      AS DV              ON IT.IDX_NO          = DV.IDX_NO      
            LEFT OUTER JOIN _TDACust           AS DC              ON DV.MakerSeq        = DC.CustSeq      
                                                                 AND DC.CompanySeq      = @CompanySeq    
            LEFT OUTER JOIN _TPUDelv           AS DE              ON DV.DelvSeq         = DE.DelvSeq     -- 11.04.25 김세호 추가    
                                                                 AND DE.CompanySeq      = @CompanySeq    
            -- 품목 대/중분류 가져오기 20100318 박소연 추가        
            LEFT OUTER JOIN _TDAItemClass      AS IA              ON A.CompanySeq       = IA.CompanySeq         
                                                                 AND A.ItemSeq          = IA.ItemSeq         
                                                                 AND IA.UMajorItemClass IN (2001, 2004) -- 소    
            LEFT OUTER JOIN _TDAUMinorValue    AS ID              ON ID.Serl            IN (1001,2001)         
                                                                 AND IA.UMItemClass     = ID.MinorSeq             
                                                                 AND IA.CompanySeq      = ID.CompanySeq -- 중         
            LEFT OUTER JOIN _TDAUMinorValue    AS IE              ON IE.Serl            = 2001         
                                                                 AND ID.ValueSeq        = IE.MinorSeq         
                                                                 AND IE.MajorSeq        IN (2002,2005)         
                                                                 AND ID.CompanySeq      = IE.CompanySeq -- 대        
            LEFT OUTER JOIN _TDAUMinor         AS IL              ON IA.UMItemClass     = IL.MinorSeq  AND IA.CompanySeq = IL.CompanySeq -- 소      -- 11.06.13 김세호 추가                
            LEFT OUTER JOIN _TDAUMinor         AS IH              ON ID.ValueSeq        = IH.MinorSeq  AND ID.CompanySeq = IH.CompanySeq -- 중        
            LEFT OUTER JOIN _TDAUMinor         AS IG              ON IE.ValueSeq        = IG.MinorSeq  AND IE.CompanySeq = IG.CompanySeq -- 대        
            LEFT OUTER JOIN _TPUDelvIn         AS DI              ON DI.CompanySeq      = A.CompanySeq AND A.SourceType  = 1 AND A.SourceSeq = DI.DelvInSeq        
            LEFT OUTER JOIN _TDACCtr           AS DJ              ON DJ.CompanySeq      = @CompanySeq  AND DJ.CCtrSeq    = PO.CCtrSeq -- 20100419 박소연 추가        
        LEFT OUTER JOIN _TDACCtr           AS DL              ON DL.CompanySeq      = A.CompanySeq AND DL.CCtrSeq    = A.CCtrSeq  -- 20100419 박소연 추가        
            LEFT OUTER JOIN _TDAUMinor         AS DK              ON A.CompanySeq       = DK.CompanySeq AND A.SMRNPMethod   = DK.MinorSeq      
            -- 비용구분 조회 위하여 추가 2011. 2. 16 hkim        
            LEFT OUTER JOIN _TDACCtr           AS EA WITH(NOLOCK) ON EA.CompanySeq = @CompanySeq        
                                                                 AND CC.CCtrSeq    = EA.CCtrSeq        
            LEFT OUTER JOIN _TDAUMinor         AS EB WITH(NOLOCK) ON EB.CompanySeq = @CompanySeq        
                                                                 AND EA.UMCostType = EB.MinorSeq        
              LEFT OUTER JOIN _TDAUMinor         AS EC WITH(NOLOCK) ON EC.CompanySeq = @CompanySeq        
                                                                 AND DJ.UMCostType = EC.MinorSeq        
              LEFT OUTER JOIN _TDAUMinor         AS ED WITH(NOLOCK) ON ED.CompanySeq = @CompanySeq        
                                                                 AND DL.UMCostType = ED.MinorSeq      
            LEFT OUTER JOIN _TPUDelvInRetro    AS RE WITH(NOLOCK) ON A.SourceSeq   = RE.DelvInSeq       -- 2011.05.23 김세호 추가    
                                                                 AND A.CompanySeq  = RE.CompanySeq    
            --LEFT OUTER JOIN #TCOMSourceTracking AS PR             ON IT.IDX_NO     = PR.IDX_NO  
            --                                                     AND PR.IDOrder    = 3  
            --LEFT OUTER JOIN _TPUORDPOReq        AS Req            ON Req.CompanySeq = @CompanySeq  
            --                                                     AND Req.POReqSeq   = PR.Seq  
            --LEFT OUTER JOIN #CCrt               AS CCrt           ON Req.CompanySeq = @CompanySeq  
            --                                                     AND Req.EmpSeq     = CCrt.EmpSeq  
            LEFT OUTER JOIN #TEMP_TPUORDPOReq AS Req ON Req.IDX_NO = IT.IDX_NO  
            LEFT OUTER JOIN #CCrt               AS CCrt           ON Req.POReqEmpSeq     = CCrt.EmpSeq  
            LEFT OUTER JOIN _TDAEmp             AS EE  WITH(NOLOCK) ON EE.CompanySeq       = @CompanySeq          
                                                                 AND PO.POEmpSeq           = EE.EmpSeq    
                                                                 
            -- 2015.10.06   kth     결제구분, 결제기간 추가                                                                
            --LEFT OUTER JOIN hencom_TPUDeptCustAddInfo AS P1 WITH(NOLOCK) ON P1.CompanySeq = A.CompanySeq    
            --                                                            AND P1.DeptSeq = A.DeptSeq   
            --                                                            AND P1.CustSeq = A.CustSeq      
                                                                        
            -- 2015.11.10   kth     설계변경으로 재개발
            LEFT OUTER JOIN hencom_TPUBuyingAccAdd AS AD WITH(NOLOCK) ON AD.CompanySeq   = A.CompanySeq  
                                                                     AND AD.BuyingAccSeq = A.BuyingAccSeq
            LEFT OUTER JOIN hencom_TPUDelvItemAdd AS DVA WITH(NOLOCK) ON DVA.CompanySeq  = @CompanySeq  
                                                                     AND DVA.DelvSeq    = DV.DelvSeq
                                                                     AND DVA.DelvSerl   = DV.DelvSerl 
            LEFT OUTER JOIN _TDACust              AS DVB   WITH(NOLOCK) ON DVB.CompanySeq  = DVA.CompanySeq           
                                                                       AND DVB.CustSeq= DVA.DeliCustSeq 
            LEFT OUTER JOIN _TDAEvid    AS DVEV WITH(NOLOCK) ON AD.CompanySeq = DVEV.CompanySeq AND AD.DeliEvidSeq   = DVEV.EvidSeq 
            LEFT OUTER JOIN _TDAAccount AS DVDA WITH(NOLOCK) ON AD.CompanySeq = DVDA.CompanySeq AND AD.DeliAccSeq    = DVDA.AccSeq  
            LEFT OUTER JOIN _TDAAccount AS DVOA WITH(NOLOCK) ON AD.CompanySeq = DVOA.CompanySeq AND AD.DeliVsAccSeq  = DVOA.AccSeq  
            LEFT OUTER JOIN _TDAAccount AS DVVA WITH(NOLOCK) ON AD.CompanySeq = DVVA.CompanySeq AND AD.DeliVatAccSeq = DVVA.AccSeq  

            -- 구매납품과 JOIN
            LEFT OUTER JOIN hencom_VPUBASEBuyPriceItemDate AS BBP ON BBP.CompanySeq = A.CompanySeq
                                                                 AND BBP.CustSeq = A.CustSeq
                                                                 AND BBP.DeptSeq = A.DeptSeq
                                                                 AND BBP.ProdDistrictSeq = DVA.ProdDistrictSeq
                                                                 AND ISNULL(BBP.DeliCustSeq, 0) = ISNULL(DVA.DeliCustSeq, 0)
                                                                 AND ISNULL(BBP.SalesCustSeq, 0) = ISNULL(DVA.SalesCustSeq, 0)
                                                                 AND BBP.ItemSeq = A.ItemSeq
                                                                 AND (A.DelvInDate BETWEEN BBP.StartDate AND BBP.EndDate)                                                                                                                                                   
            LEFT OUTER JOIN hencom_TPUPurchaseArea AS PA WITH(NOLOCK) ON PA.CompanySeq = @CompanySeq AND PA.ProdDistrictSeq = DVA.ProdDistrictSeq  
        WHERE A.CompanySeq = @CompanySeq      
          AND (@POEmpSeq     = 0         OR PO.POEmpSeq  = @POEmpSeq)          
          AND (@PODeptSeq    = 0         OR PO.PODeptSeq = @PODeptSeq)        
          AND (@ItemSeq      = 0         OR A.ItemSeq    = @ItemSeq)  -- 2014.04.10 김용현 추가  
          AND (@ItemLClass   = 0         OR IE.ValueSeq  = @ItemLClass)      -- 20100318 박소연 추가        
          AND (@ItemMClass   = 0         OR ID.ValueSeq  = @ItemMClass)      -- 20100318 박소연 추가        
          AND (@OrderTypeSeq = 0         OR ((@OrderTypeSeq = 6212001 AND IP2.OrderNo <> '') OR (@OrderTypeSeq = 6212002 AND IP2.OrderNo = '') )  )        
          AND (A.Qty <> 0 OR ISNULL(RE.DelvInSeq, 0) <> 0)                 -- 2011.05.23 김세호 추가    
          AND (@MakerSeq = 0 OR DV.MakerSeq = @MakerSeq)    
          AND (@IsSlip = 0 OR                                   -- 20110314 추가             
              (@IsSlip = '1039001' AND A.SlipSeq > 0 ) OR            
              (@IsSlip = '1039002' AND ISNULL(A.SlipSeq,0) = 0))    
          AND (@SlipId = '' OR R.SlipID LIKE @SlipId + '%')     -- 20110314 추가    
          AND A.DelvInDate BETWEEN @DateFr AND @DateTo          -- 20110314 추가    
          AND (@DelvMngNo = '' OR DE.DelvMngNo = @DelvMngNo)       -- 11.04.24 김세호 추가    
          AND (@PONo = '' OR PO.PONo LIKE @PONo + '%')          -- 11.11.23 김세호 추가    
          AND (@IsPJTPur = 0 OR (ISNULL(P.PJTSeq,0) =  0 AND @IsPJTPur = 7063001)   --일반구매  
               OR (ISNULL(P.PJTSeq,0) <> 0 AND @IsPJTPur = 7063002))                --프로젝트구매  
          AND (@WorkOrderNo = '' OR PO.WorkOrderNo like @WorkOrderNo + '%')   
          AND (@DelvCustSeq   =0         OR A.DelvCustSeq  = @DelvCustSeq)  ----납품거래처 20150121 황지혜 추가   
          AND (@DelvNo  =''              OR DE.DelvNo      like  @DelvNo + '%')  ----납품거래처 20150121 황지혜 추가       
          AND (@Spec = '' OR C.Spec like @Spec + '%')  --20150325 이삭 추가  
          AND (@ProdDistrictSeq = 0 OR DVA.ProdDistrictSeq = @ProdDistrictSeq)
        ORDER BY  A.CustSeq, A.DelvInNo, A.DelvInDate        
           

 RETURN

 go
 begin tran 
 exec hencom_SPUDelvInBuyingAccQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsPJTPur />
    <BizUnit />
    <FactUnit />
    <DateFr>20170301</DateFr>
    <DateTo>20170329</DateTo>
    <SMSourceType />
    <DeptSeq />
    <EmpSeq />
    <SMImpType />
    <IsSlip />
    <CustSeq />
    <CustNo />
    <DelvInNo />
    <DelvMngNo />
    <PONo />
    <PODeptSeq />
    <POEmpSeq />
    <PJTName />
    <PJTNo />
    <MakerSeq />
    <OrderTypeSeq />
    <OrderType />
    <TopItemName />
    <TopItemNo />
    <DelvCustSeq />
    <DelvNo />
    <Spec />
    <WorkOrderNo />
    <ItemLClass />
    <ItemMClass />
    <WHSeq />
    <ItemSeq />
    <ItemName />
    <ItemNo />
    <AssetSeq />
    <SlipId />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033061,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027349
rollback 