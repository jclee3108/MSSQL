IF OBJECT_ID('hencom_SPUDelvItemListQuery') IS NOT NULL 
    DROP PROC hencom_SPUDelvItemListQuery
GO 

-- v2017.03.24 
/*************************************************************************************************    
 FORM NAME           -       FrmPUDelvList  
 DESCRIPTION         -     구매납품품목현황  
 CREAE DATE          -       2008.10.06      CREATE BY: 김현  
 LAST UPDATE  DATE   -       2008.10.06         UPDATE BY: 김현      
                     - 반품품목이면 진행상태 반품완료로 고정
                       조회칼럼 불량반품수량 추가(입고후 반품한건은 제외) - 11.04.21 BY 김세호
                       2011.05.12          UPDATED BY 김세호 :: 불량반품수량 + 수량으로 조회  
                       2011.05.25          UPDATED BY 김세호 :: 납품구분 납품,반품,불합격반품,입고후반품 으로 맞게 조회될수있도록 수정  
                     - 2011.06.30 by 김철웅
                     1) 하드코딩 없애기 
                     - 2011.10.19          UPDATED BY 김세호 :: 진행상태 조회시 -납품건(반품아님) ABS() 처리
                     - 2012.01.27          UPDATE BY: SYPARK (구매그룹 조회로직 추가)
                     - 2012.07.19          UPDATED BY 김세호 :: 검사품 여부 칼럼 추가
                     - 2012.08.24          UPDATED BY 김세호 :: 불합격건 입고수량 조회 안되도록 
                     - 2013.07.10          UPDATED BY 천경민 :: Memo1~8 컬럼 추가

 설  명 - 구매납품품목현황_hencom (표준SP 수정개발)
 작성일 - 2015.12.03
 작성자 - kth
 수  정 - 2016.01.21  kth     판매처 추가
*************************************************************************************************/    
CREATE PROC hencom_SPUDelvItemListQuery
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    SET NOCOUNT ON          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED   
  
    DECLARE @docHandle          INT          ,      
            @DelvDateFr         NCHAR(8)     ,    
            @DelvDateTo         NCHAR(8)     ,    
            @CustName           NVARCHAR(200),    
            @DelvNo             NVARCHAR(200),    
            @SMImpType          INT          ,    
            @SMStkType          INT          ,    
            @IsWarehoues        NCHAR(1)     ,    
            @SMQcType           INT          ,    
            @WHSeq              INT          ,    
            @ItemNo             NVARCHAR(200),    
            @SMDelvInType       INT          ,    
            @PJTName            NVARCHAR(200),    
            @PJTNo              NVARCHAR(100),    
            @ItemName           NVARCHAR(100),    
            @DeptSeq            INT          ,    
            @EmpSeq             INT          ,    
            @PONo               NVARCHAR(20) ,    
            @SMAssetKind        INT          ,    
            @BizUnit            INT          ,    
            @SMDelvType         INT          ,    
            @UMSupplyType       INT          ,        
            @TopUnitName        NVARCHAR(200),        
            @TopUnitNo          NVARCHAR(200),  
            @Spec               NVARCHAR(200),  
            @CustSeq            INT          ,  
            @LotNo              NVARCHAR(100),   
            @PurGroupDeptSeq    INT          ,
            @DelvCustSeq        INT          ,
            @DeliCustName       NVARCHAR(200),               -- 운송처
            @ItemClassSSeq      INT          ,               -- 소분류코드
            @ItemClassMSeq      INT          ,               -- 중분류코드
            @ItemClassLSeq      INT          ,               -- 대분류코드,
            @IOTag              INT          ,               -- 대한산업 내부/외부 구분
            @ProdDistrictSeq    INT          
   
    DECLARE @Word1 NVARCHAR(50),  
            @Word2 NVARCHAR(50),  
            @Word3 NVARCHAR(50),  
            @Word4 NVARCHAR(50),  
            @Word5 NVARCHAR(50),  
            @Word6 NVARCHAR(50),  
            @Word7 NVARCHAR(50),  
            @Word8 NVARCHAR(50),  
            @Word9 NVARCHAR(50)  
  
    SELECT @Word1 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 25496  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word1, '' ) = '' SELECT @Word1 = N'미입고'  
    SELECT @Word2 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 26717  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word2, '' ) = '' SELECT @Word2 = N'입고중'  
    SELECT @Word3 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 28842  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word3, '' ) = '' SELECT @Word3 = N'반품진행중'  
    SELECT @Word4 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 28843  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word4, '' ) = '' SELECT @Word4 = N'반품완료'  
    SELECT @Word5 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 25474  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word5, '' ) = '' SELECT @Word5 = N'입고완료'  
    SELECT @Word6 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq =  @LanguageSeq AND WordSeq = 22755  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word6, '' ) = '' SELECT @Word6 = N'납품'  
    SELECT @Word7 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 28844  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word7, '' ) = '' SELECT @Word7 = N'입고후반품'  
    SELECT @Word8 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 28845  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word8, '' ) = '' SELECT @Word8 = N'불합격반품'  
    SELECT @Word9 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 13570  
    IF @@ROWCOUNT = 0 OR ISNULL( @Word9, '' ) = '' SELECT @Word9 = N'반품'  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    SELECT  @DelvDateFr       = ISNULL(DelvDateFr     , ''),    
            @DelvDateTo       = ISNULL(DelvDateTo     , ''),    
            @SMQcType         = ISNULL(SMQcType       ,  0),    
            @CustName         = ISNULL(CustName       , ''),    
            @DelvNo           = ISNULL(DelvNo         , ''),    
            @SMImpType        = ISNULL(SMImpType      ,  0),    
            @WHSeq            = ISNULL(WHSeq          ,  0),    
            @ItemNo           = ISNULL(ItemNo         , ''),    
            @PJTName          = ISNULL(PJTName        , ''),    
            @PJTNo            = ISNULL(PJTNo          , ''),    
            @SMDelvInType     = ISNULL(SMDelvInType   ,  0),    
            @ItemName         = ISNULL(ItemName       , ''),         
            @DeptSeq          = ISNULL(DeptSeq        ,  0),         
            @EmpSeq           = ISNULL(EmpSeq         ,  0),         
            @PONo             = ISNULL(PONo           , ''),         
            @SMAssetKind      = ISNULL(SMAssetKind    ,  0),    
            @BizUnit          = ISNULL(BizUnit        ,  0),    
            @SMDelvType       = ISNULL(SMDelvType     ,  0),    
            @UMSupplyType     = ISNULL(UMSupplyType   ,  0),        
            @TopUnitName      = ISNULL(TopUnitName    , ''),                            
            @TopUnitNo        = ISNULL(TopUnitNo      , ''),  
            @Spec             = ISNULL(Spec           , ''),  
            @CustSeq          = ISNULL(CustSeq        ,  0),  
            @LotNo            = ISNULL(LotNo          , ''),  
            @PurGroupDeptSeq  = ISNULL(PurGroupDeptSeq,  0),
            @DelvCustSeq      = ISNULL(DelvCustSeq    ,  0), 
            
            @DeliCustName     = ISNULL(DeliCustName   , ''),
            @ItemClassSSeq    = ISNULL(ItemClassSSeq  ,  0), 
            @ItemClassMSeq    = ISNULL(ItemClassMSeq  ,  0), 
            @ItemClassLSeq    = ISNULL(ItemClassLSeq  ,  0), 
            @IOTag            = ISNULL(IOTag  ,  0), 
            @ProdDistrictSeq  = ISNULL(ProdDistrictSeq,  0)
                         
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (  DelvDateFr         NCHAR(8)     ,    
            DelvDateTo         NCHAR(8)     ,    
            CustName           NVARCHAR(200),    
            DelvNo             NVARCHAR(200),    
            SMImpType          INT          ,    
            SMQcType           INT          ,    
            WHSeq              INT          ,    
            ItemNo             NVARChAR(200),    
            PJTName            NVARCHAR(60) ,    
            PJTNo              NVARCHAR(40) ,    
            SMDelvInType       INT          ,        
            ItemName           NVARCHAR(100),  
            DeptSeq            INT          ,    
            EmpSeq             INT          ,    
            PONo               NVARCHAR(20) ,    
            SMAssetKind        INT          ,    
            BizUnit            INT          ,    
            SMDelvType         INT          ,    
            UMSupplyType       INT          ,      
            TopUnitName        NVARCHAR(200),        
            TopUnitNo          NVARCHAR(200),  
            Spec               NVARCHAR(200),  
            CustSeq            INT          ,  
            LotNo              NVARCHAR(100),  
            PurGroupDeptSeq    INT          ,
            DelvCustSeq        INT          ,
            DeliCustName       NVARCHAR(200),  
            ItemClassSSeq      INT          , 
            ItemClassMSeq      INT          , 
            ItemClassLSeq      INT          , 
            IOTag              INT          , 
            ProdDistrictSeq    INT  
         )    
    
    IF @DelvDateFr = '' SELECT @DelvDateFr = '10000101'    
    IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231'   
    IF @IOTag = 1014674002 SELECT @IOTag = 1  
    IF @IOTag = 1014674003 SELECT @IOTag = 0



    --===================================================  
    -- 구매그룹 정보 가져오기 시작!  
    --===================================================  
    CREATE TABLE #PurGroupInfo  
    (  
        IDX_NO      INT,  
        DeptSeq     INT,  
          UMItemClass  INT,  
        ItemSeq     INT  
    )  
  
    EXEC _SPUBasePurGroupInfo @CompanySeq, @PurGroupDeptSeq  
    --===================================================  
    -- 구매그룹 정보 가져오기 끝!  
    --===================================================                      
    
    -------------------    
    --입고진행여부-----    
    -------------------    
    CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))        
          
    CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1), Qty DECIMAL(19,5), DelvInQty DECIMAL(19, 5), DelvInCurAmt DECIMAL(19, 5), DelvInDomAmt DECIMAL(19, 5), PONo NCHAR(12), ExRate DECIMAL(19, 5), PODate NCHAR(8), CompleteCheck INT, RemainQty DECIMAL(19, 5), RemainAmt DECIMAL(19, 5), RemainVAT DECIMAL(19, 5), CurAmt DECIMAL(19, 5), DomAmt DECIMAL(19, 5), IsReturn NCHAR(2), BadQty DECIMAL(19, 5) )            
        
    CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))          
    
    CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), CurAmt DECIMAL(19,5), CurVAT DECIMAL(19, 5))    
    
    INSERT #TMP_PROGRESSTABLE         
    SELECT 1, '_TPUDelvInItem'               -- 구매입고    
        
    -- 구매납품   
    IF (SELECT COUNT(*) FROM #PurGroupInfo) > 0 -- 구매그룹조건이 존재할경우  
    BEGIN       
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn, Qty, DelvInQty, DelvInCurAmt, DelvInDomAmt, PONo, ExRate, PODate, CurAmt, DomAmt, IsReturn, BadQty)          
        SELECT A.DelvSeq, ISNULL(B.DelvSerl, 0), '1', B.Qty, 0, 0, 0, '', A.ExRate, '', B.CurAmt, B.DomAmt, B.IsReturn, 0     
          FROM _TPUDelv                      AS A WITH(NOLOCK)         
               LEFT OUTER JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                              AND A.DelvSeq    = B.DelvSeq  
               LEFT OUTER JOIN _TDAItemClass AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq   
                                                              AND B.ItemSeq    = C.ItemSeq   
      AND C.UMajorItemClass IN (2001, 2004)        
         WHERE A.CompanySeq = @CompanySeq      
           AND (A.DelvDate  BETWEEN @DelvDateFr AND @DelvDateTo)      
           AND (@DelvNo     = '' OR A.DelvNo    LIKE @DelvNo + '%' )      
           AND (@BizUnit     = 0  OR A.BizUnit   = @BizUnit)    
           AND (@DeptSeq    = 0  OR A.DeptSeq   = @DeptSeq)    
           AND (@EmpSeq     = 0  OR A.EmpSeq    = @EmpSeq)    
           AND (@CustSeq    = 0  OR A.CustSeq   = @CustSeq)    
           AND (@SMImpType  = 0  OR A.SMImpType = @SMImpType)    
           AND (A.SMImpType IN (8008001, 8008002, 8008003))   
           AND (EXISTS   (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = A.DeptSeq AND UMItemClass = C.UMItemClass AND ItemSeq = B.ItemSeq)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = A.DeptSeq AND UMItemClass = C.UMItemClass AND ItemSeq = 0)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = 0         AND UMItemClass = C.UMItemClass AND ItemSeq = B.ItemSeq)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = 0         AND UMItemClass = C.UMItemClass AND ItemSeq = 0)    
               OR EXISTS (SELECT 1 FROM #PurGroupInfo WHERE DeptSeq = A.DeptSeq AND UMItemClass = 0             AND ItemSeq = 0))     
           AND (@DelvCustSeq = 0 OR B.DelvCustSeq = @DelvCustSeq)
    END  
    ELSE   
    BEGIN       
        INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn, Qty, DelvInQty, DelvInCurAmt, DelvInDomAmt, PONo, ExRate, PODate, CurAmt, DomAmt, IsReturn, BadQty)          
        SELECT A.DelvSeq, ISNULL(B.DelvSerl, 0), '1', B.Qty, 0, 0, 0, '', A.ExRate, '', B.CurAmt, B.DomAmt, B.IsReturn, 0       
          FROM _TPUDelv                     AS A WITH(NOLOCK)         
               LEFT OUTER JOIN _TPUDelvItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                               AND A.DelvSeq    = B.DelvSeq    
         WHERE A.CompanySeq = @CompanySeq      
           AND (A.DelvDate  BETWEEN @DelvDateFr AND @DelvDateTo)      
           AND (@DelvNo     = '' OR A.DelvNo    LIKE @DelvNo + '%' )      
           AND (@BizUnit    = 0  OR A.BizUnit   = @BizUnit)    
           AND (@DeptSeq    = 0  OR A.DeptSeq   = @DeptSeq)    
           AND (@EmpSeq     = 0  OR A.EmpSeq    = @EmpSeq)    
           AND (@CustSeq    = 0  OR A.CustSeq   = @CustSeq)    
           AND (@SMImpType  = 0  OR A.SMImpType = @SMImpType)    
           AND (A.SMImpType IN (8008001, 8008002, 8008003))   
           AND (@DelvCustSeq = 0 OR B.DelvCustSeq = @DelvCustSeq)      
    END   
        
  
    EXEC _SCOMProgStatus @CompanySeq, '_TPUDelvItem', 1036002 , '#Temp_Order', 'OrderSeq', 'OrderSerl', '', 'RemainQty', '', 'RemainAmt', 'RemainVAT', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', 'CurVAT', 'DelvSeq', 'DelvSerl', '', '_TPUDelvItem', @PgmSeq     
  

    -- 불량수량 있을 경우, 경우 잔량에 불량 수량을 빼서 진행 상태 관리한다 12.08.24 BY 김세호
    UPDATE #Temp_Order  
       SET RemainQty = A.RemainQty -  B.BadQty,  
           BadQty    = B.BadQty
      FROM #Temp_Order       AS A  
           JOIN _TPUDelvItem AS B WITH(NOLOCK) ON A.OrderSeq  = B.DelvSeq   
                                 AND A.OrderSerl = B.DelvSerl    
     WHERE B.CompanySeq = @CompanySeq  
       AND B.SMQCType   IN (6035004, 6035005, 6035006)  

    -- 진행상태 UPDATE (1 = 미입고, 2 = 입고중 , 3 = 입고완료, 6 = 반품완료 )  
    UPDATE #Temp_Order     
       SET IsDelvIn     =  -- 납품수량과 불량수량이 같거나, 가용납품수량(납품수량-불량수량) 이 잔량과 같을 경우 '미입고' 세팅    12.08.24 BY 김세호
                          CASE WHEN (A.Qty = A.BadQty) OR (A.Qty - A.BadQty = A.RemainQty)     THEN '1'
                               WHEN A.RemainQty > 0         THEN CASE WHEN A.Qty = A.RemainQty THEN '1' ELSE '2' END  
                               WHEN A.RemainQty = 0         THEN '3'   
                               WHEN A.RemainQty < 0         THEN '3'  
                          ELSE '1'  END  ,    
           DelvInQty    = A.Qty - A.RemainQty - A.BadQty ,    
           DelvInCurAmt = CASE WHEN (A.Qty - A.RemainQty - A.BadQty) <> 0 THEN (A.CurAmt - A.RemainAmt) ELSE 0 END,    
           DelvInDomAmt = CASE WHEN (A.Qty - A.RemainQty - A.BadQty) <> 0 THEN A.DomAmt  - (A.RemainAmt * ISNULL(A.ExRate, 1))  ELSE 0 END  
      FROM #Temp_Order                AS A  
    WHERE A.CompleteCheck <> 0   


    -- 납품수량 전량 반품되었을경우 '반품완료'(= 6) 으로 UPDATE         12.08.24 BY 김세호
    UPDATE #Temp_Order  
       SET IsDelvIn = CASE WHEN A.Qty = C.Qty THEN '6' 
                           ELSE A.IsDelvIn    END
      FROM #Temp_Order       AS A  
           JOIN (SELECT SourceSeq, SourceSerl, ABS(SUM(E.Qty)) AS Qty FROM _TPUDelvItem AS E WITH(NOLOCK) 
     JOIN #Temp_Order   AS F ON E.SourceSeq  = F.OrderSeq  
                                                                                                AND E.SourceSerl = F.OrderSerl  
                                                                   WHERE E.CompanySeq = @CompanySeq  
                                                                     AND E.IsReturn   = '1'  
                                                                GROUP BY SourceSeq, SourceSerl) AS C ON A.OrderSeq   = C.SourceSeq  
                                                                                                    AND A.OrderSerl  = C.SourceSerl
   
    --  -납품건(반품아님) ABS() 처리  
    UPDATE #Temp_Order     
       SET IsDelvIn     = CASE WHEN ABS(A.RemainQty) > 0 THEN CASE WHEN ABS(A.Qty) = ABS(A.RemainQty) THEN '1' ELSE '2' END  
             WHEN A.RemainQty = 0 THEN '3'   
             WHEN A.RemainQty < 0 THEN '3'  
                   ELSE '1'  END  ,    
           DelvInQty    = A.Qty - A.RemainQty - A.BadQty ,    
           DelvInCurAmt = A.CurAmt - A.RemainAmt,    
           DelvInDomAmt = A.DomAmt  - (A.RemainAmt * ISNULL(A.ExRate, 1))    
      FROM #Temp_Order                AS A  
     WHERE Qty < 0 AND ISNULL(IsReturn, 0) <> 1   
  
  
    -------------------    
    --입고진행END------    
    -------------------   

   
    -------------------    
    --발주번호 추적 ---    
    -------------------    
    CREATE TABLE #TMP_SOURCETABLE              
    (              
        IDOrder INT,              
        TABLENAME   NVARCHAR(100)              
    )       
    CREATE TABLE #TCOMSourceTracking              
    (               
        IDX_NO      INT,              
        IDOrder     INT,              
        Seq         INT,              
        Serl        INT,              
        SubSerl     INT,              
        Qty         DECIMAL(19, 5),              
        STDQty      DECIMAL(19, 5),              
        Amt         DECIMAL(19, 5),      
        VAT         DECIMAL(19, 5)              
    )       
    CREATE TABLE #TMP_SOURCEITEM        
    (              
        IDX_NO     INT IDENTITY,              
        SourceSeq  INT,              
        SourceSerl INT,              
        Qty        DECIMAL(19, 5)        
    )    
    CREATE TABLE #TMP_EXPENSE        
    (              
          IDX_NO     INT,               
        SourceSeq  INT,              
        SourceSerl INT,              
        ExpenseSeq INT        
    )     
    
    INSERT #TMP_SOURCETABLE        
    SELECT 1,'_TPUORDPOItem'        
    
    INSERT #TMP_SOURCETABLE        
    SELECT 2,'_TPUDelv'    
    
    INSERT #TMP_SOURCEITEM    
         ( SourceSeq    , SourceSerl    , Qty)    
    SELECT A.DelvSeq    , B.DelvSerl    , B.Qty    
      FROM _TPUDelv           AS A WITH(NOLOCK)   
           JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq    
                                  AND A.DelvSeq     = B.DelvSeq    
           LEFT OUTER JOIN _TPJTBOM AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                              AND B.PJTSeq = C.PJTSEq    
                                     AND B.WBSSeq = C.BOMSerl    
     WHERE A.CompanySeq = @CompanySeq    
       AND (A.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)      
       AND (@DelvNo   = '' OR A.DelvNo   LIKE '%' + @DelvNo   + '%')      
       AND (@BizUnit  = 0  OR A.BizUnit = @BizUnit)    
       AND (@SMImpType = 0 OR A.SMImpType = @SMImpType)    
       AND (@CustSeq  = 0  OR A.CustSeq = @CustSeq)    
       AND (A.SMImpType IN (8008001, 8008002, 8008003))    
       AND (@UMSupplyType = 0 OR C.UMSupplyType = @UMSupplyType)    
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''              
  
    UPDATE #Temp_Order    
       SET PONo   = ISNULL(D.PONo  , ''),    
           PODate = ISNULL(D.PODate, '')    
      FROM #Temp_Order               AS A    
           JOIN #TMP_SOURCEITEM      AS B              ON A.OrderSeq   = B.SourceSeq AND A.OrderSerl = B.SourceSerl     
           JOIN #TCOMSourceTracking  AS C              ON B.IDX_NO     = C.IDX_NO    
           LEFT OUTER JOIN _TPUORDPO AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq    
                                                      AND C.Seq        = D.POSeq    
     WHERE C.IDOrder = 1    
       
       
    -- 입고 진행 수량에 검사폐기수량 반영  
      
    ALTER TABLE #Temp_Order ADD QCBreakQty    DECIMAL(19,5)  
  
    UPDATE #Temp_Order  
       SET QCBreakQty = ISNULL(B.DisuseQty,0)  
      FROM #Temp_Order AS A JOIN _TPDQCTestReport AS B ON A.OrderSeq = B.SourceSeq AND A.OrderSerl = B.SourceSerl   
     WHERE B.SourceType = '1'   
       AND B.SMTestResult = 6035003  
         
    UPDATE #Temp_Order  
       SET IsDelvIn = '3'  
      FROM #Temp_Order          AS A  
           JOIN _TPUDelvItem    AS B WITH(NOLOCK) ON A.OrderSeq  = B.DelvSeq  
                                    AND A.OrderSerl = B.DelvSerl  
     WHERE B.CompanySeq = @CompanySeq  
       AND B.SMQCType NOT IN (6035004)          -- 이 부분에서 불합격건의 상태가 바뀌므로 불합격건은 제외해준다.  
       AND A.Qty = ISNULL(DelvInQty,0) + ISNULL(QCBreakQty,0)          
  
    -- 불량반품수량 반영                        -- 11.04.22 김세호 추가  
    ALTER TABLE #Temp_Order ADD BadReturnQty  DECIMAL(19,5)  
      
    SELECT A.IDX_NO     , ISNULL(SUM(B.Qty), 0) AS ReturnQty  
      INTO #DelvItemReturnSUM             
      FROM #Temp_Order         AS A    
           JOIN _TPUDelvItem AS B WITH(NOLOCK) ON A.OrderSeq  = B.SourceSeq     
                                    AND A.OrderSerl = B.SourceSerl    
     WHERE B.CompanySeq = @CompanySeq    
       AND B.SourceType = '2'   
    GROUP BY A.IDX_NO   
  
    UPDATE #Temp_Order  
       SET BadReturnQty = B.ReturnQty * (-1)  
      FROM #Temp_Order          AS A  
      JOIN #DelvItemReturnSUM AS B ON A.IDX_NO = B.IDX_NO  
  
  
    --  반품건은 진행상태 반품완료로 고정       -- 11.04.22 김세호 추가  
    UPDATE #Temp_Order  
       SET IsDelvIn = '6'   
      FROM #Temp_Order  
     WHERE IsReturn = '1'  
  
    
    ------------------------    
    --발주번호 추적 끝  ----    
    ------------------------    

    SELECT     
            G.ItemName             AS ItemName               ,    
            G.ItemNo               AS ItemNo                 ,    
            G.Spec                 AS Spec                   ,    
            H.UnitName             AS UnitName               ,    
              B.Price                AS Price                   ,    
            B.Qty                  AS Qty                    ,    
            B.CurAmt               AS CurAmt                 ,    
            B.CurVAT               AS CurVAT                 ,    
            ISNULL(B.CurAmt,0) +     
            ISNULL(B.CurVAT,0)     AS TotCurAmt              ,    
            B.DomPrice             AS DomPrice               ,    
            B.DomAmt               AS DomAmt                 ,    
			B.DomVAT               AS DomVAT                 ,    
			ISNULL(B.DomAmt,0) +     
            ISNULL(B.DomVAT,0)     AS TotDomAmt              ,    
            ISNULL(B.IsVAT,'')     AS IsVAT                  ,    
            AA.VATRAte             AS VATRate                ,    
            I.WHName               AS WHName                 ,    
            B.WHSeq                AS WHSeq                  ,    
            J.CustName             AS DelvCustName           ,    
            B.DelvCustSeq          AS DelvCustSeq            ,    
            K.MinorName            AS SMQcTypeName           ,    
            ISNULL(QC.SMTestResult,B.SMQcType)        AS SMQcType               ,    
            QC.TestEndDate         AS QcDate                 ,    
            B.QCQty               AS QCQty                  ,    
            B.QCCurAmt             AS QCCurAmt               ,    
            L.UnitName             AS STDUnitName            ,    
            B.StdUnitQty           AS StdUnitQty             ,    
            1                      AS StdConvQty        ,    
            B.ItemSeq              AS ItemSeq                ,    
            B.UnitSeq              AS UnitSeq                ,    
            B.LotNo                AS LotNo                  ,    
            B.FromSerial           AS FromSerial             ,    
            B.Toserial             AS Toserial               ,    
            B.DelvSerl             AS DelvSerl               ,    
            B.Remark               AS Remark                 ,  
            A.Remark               AS MasterRemark          ,---추가    
            --B.LotMngYN             AS LotMngYN              ,     
            A.DelvNo               AS DelvNo                 ,    
            B.DelvSeq              AS DelvSeq                ,    
            ''                     AS Sel                    ,    
            C.CustName             AS CustName               ,    
            M.PJTName              AS PJTName                ,      
            M.PJTNo                AS PJTNo                  ,    
            B.WBSSeq               AS WBSSeq                 ,    
            ''                     AS WBSName                ,    
            A.CustSeq              AS CustSeq                ,    
            M.PJTSeq               AS PJTSeq     ,    
            A.DelvDate             AS DelvDate               ,    
            A.CurrSeq              AS CurrSeq                ,    
            A.ExRate               AS ExRate                 ,    
            CC.CurrName            AS CurrName               ,    
            F.DeptName             AS DeptName               ,    
            D.EmpName              AS EmpName                ,    
            A.BizUnit              AS BizUnit                ,    
            O.BizUnitName          AS BizUnitName            ,    
            P.SMAssetGrp           AS SMAssetKind            ,    
            P.AssetName            AS SMAssetKindName        ,    
            X.DelvInQty            AS DelvInQty              ,    
            X.DelvInCurAmt         AS DelvInCurAmt           ,    
            X.DelvInDomAmt         AS DelvInDomAmt           ,    
            CASE X.IsDelvIn WHEN '3' THEN '1' ELSE '' END AS IsDelvIn   ,    
            CASE X.IsDelvIn WHEN '1' THEN 6062001 WHEN '2' THEN 6062002 WHEN '5' THEN 6062005 WHEN '6' THEN 6062006  ELSE 6062003 END AS SMDelvInType,    
              CASE X.IsDelvIn WHEN '1' THEN @Word1 WHEN '2' THEN @Word2 WHEN '5' THEN @Word3 WHEN '6' THEN @Word4 ELSE @Word5 END AS SMDelvInTypeName,    
   
            CASE ISNULL(B.IsReturn, '0') WHEN '0' THEN 6209001   
                 ELSE (CASE ISNULL(B.SourceType, '') WHEN '1' THEN 6209004 WHEN '2' THEN 6209003 ELSE 6209002 END) END AS SMDelvType,   
            CASE ISNULL(B.IsReturn, '0') WHEN '0' THEN @Word6   
                 ELSE (CASE ISNULL(B.SourceType, '') WHEN '1' THEN @Word7 WHEN '2' THEN @Word8 ELSE @Word9 END) END AS SMDelvTypeName,   
  
            A.SMImpType            AS SMImpType         ,    
            KK.MinorName           AS SMImpTypeName     ,    
            X.PONo                 AS PONo              ,    
            X.PODate               AS PODate            ,    
            A.IsPJT                AS IsPJT             ,    
            M5.UMSupplyType        AS UMSupplyType      ,    
            D1.MinorName           AS UMSupplyTypeName  ,      
            M2.ItemNo AS UpperUnitNo, M2.ItemName AS UpperUnitName,       
            M4.ItemName AS TopUnitName, M4.ItemNo AS TopUnitNo,  
            M5.UMMatQuality AS UMMatQuality,  
            M6.MinorName AS UMMatQualityName,  
            B.IsReturn      AS IsReturn          ,  
            ISNULL(X.BadReturnQty, 0)         AS BadReturnQty,                  -- 11.04.22 김세호 추가  
            ISNULL(QC1.IsInQC, '0')     AS IsQCItem,                            -- 12.07.19 김세호 추가  
            B.Memo1, B.Memo2, B.Memo3, B.Memo4, B.Memo5, B.Memo6, B.Memo7, B.Memo8,
            Cust.CustSeq AS MakerSeq, Cust.CustName AS MakerName,
            B.SMPriceType AS SMPriceType,
            (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = B.SMPriceType) AS SMPriceTypeName,
            ISNULL(WHI.Location, '') AS WHLocation,        -- 20141126 조성환(2014) 추가     

            DA.ProdDistrictSeq,                         -- 산지코드
            PA.ProdDistirct AS ProdDistrictName,        -- 산지
            DA.DeliCustSeq,                             -- 기본운송처코드
            DC.CustName AS DeliCustName,                -- 기본운송처
            ISNULL(DA.DeliChargePrice,0) AS DeliChargePrice,    -- 운송단가
            ISNULL(DA.DeliIsVAT,'')      AS DeliIsVAT,          -- 운송부가세포함여부         
            ISNULL(DA.DeliChargeAmt,0) AS DeliChargeAmt,        -- 운송금액
            ISNULL(DA.DeliChargeVat,0) AS DeliChargeVat,        -- 운송부가세
            ISNULL(DA.DeliChargeAmt,0) + ISNULL(DA.DeliChargeVat,0) AS TotDeliChargeAmt,     -- 운송금액계
            ISNULL(DA.PuPrice,0) AS PuPrice,    -- 매입단가
            ISNULL(DA.PuIsVat,'') AS PuIsVat,   -- 매입부가세포함여부         
            ISNULL(DA.PuAmt,0) AS PuAmt,        -- 매입금액
            ISNULL(DA.PuVat,0) AS PuVat,        -- 매입부가세
            ISNULL(DA.PuAmt,0) + ISNULL(DA.PuVat,0) AS TotPuAmt,     -- 매입금액계
            N.MinorName  AS ItemClassSName, -- 품목소분류       
            X2.MinorName AS ItemClassMName,  -- 품목중분류       
            Y2.MinorName AS ItemClassLName,   -- 품목대분류 
            (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = BBP.SalesCustSeq) AS SalesCustName,
            (Case When C2.MngValText = 1 Then '내부' Else '외부' End) AS SalesCustClass,
			C2.MngValText,
			@IOTag
      FROM _TPUDelv AS A WITH(NOLOCK)     
                      JOIN _TPUDelvItem  AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq     
                                                           AND A.DelvSeq    = B.DelvSeq      
                      JOIN #Temp_Order   AS X               ON B.DelvSeq    = X.OrderSeq       
                                                           AND B.DelvSerl   = X.OrderSerl    
           LEFT OUTER JOIN _TDACust      AS C WITH(NOLOCK)  ON A.CompanySeq = C.CompanySeq     
                                                           AND A.CustSeq    = C.CustSeq    
           LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK)  ON A.CompanySeq = D.CompanySeq     
                                                           AND A.EmpSeq     = D.EmpSeq    
           LEFT OUTER JOIN _TDACurr      AS E WITH(NOLOCK)  ON A.CompanySeq = E.CompanySeq     
                                                           AND A.CurrSeq    = E.CurrSeq          
           LEFT OUTER JOIN _TDADept      AS F WITH(NOLOCK)  ON A.CompanySeq = F.CompanySeq     
                                                           AND A.DeptSeq    = F.DeptSeq       
           LEFT OUTER JOIN _TDAItem      AS G WITH(NOLOCK)  ON B.CompanySeq = G.CompanySeq     
                                                          AND B.ItemSeq    = G.ItemSeq    
           LEFT OUTER JOIN _TDAUnit      AS H WITH(NOLOCK)  ON B.CompanySeq = H.CompanySeq     
                                                           AND B.UnitSeq    = H.UnitSeq    
           LEFT OUTER JOIN _TDAWH        AS I WITH(NOLOCK)  ON B.CompanySeq = I.CompanySeq     
                                                           AND B.WHSeq      = I.WHSeq    
           LEFT OUTER JOIN _TDACust      AS J WITH(NOLOCK)  ON B.CompanySeq = J.CompanySeq     
                                 AND B.DelvCustSeq= J.CustSeq    
           LEFT OUTER JOIN _TDASMinor    AS K WITH(NOLOCK)  ON B.CompanySeq = K.CompanySeq     
                                                           AND B.SMQcType   = K.MinorSeq    
           LEFT OUTER JOIN _TDASMinor    AS KK WITH(NOLOCK)  ON A.CompanySeq = KK.CompanySeq     
                                                           AND A.SMImpType   = KK.MinorSeq     
           LEFT OUTER JOIN _TDAUnit      AS L WITH(NOLOCK)  ON B.CompanySeq = L.CompanySeq     
                                                           AND B.StdUnitSeq = L.UnitSeq    
           LEFT OUTER JOIN _TPJTProject  AS M WITH(NOLOCK)  ON B.CompanySeq = M.CompanySeq     
                                                             AND B.PJTSeq   = M.PJTSeq      
           LEFT OUTER JOIN _TDABizUnit   AS O WITH(NOLOCK)  ON A.CompanySeq = O.CompanySeq     
                                                           AND A.BizUnit    = O.BizUnit    
           LEFT OUTER JOIN _TDAItemAsset AS P WITH(NOLOCK)  ON G.CompanySeq = P.CompanySeq     
                                                           AND G.AssetSeq   = P.AssetSeq    
           LEFT OUTER JOIN _TDAItemSales AS BB WITH(NOLOCK) ON BB.CompanySeq = @CompanySeq    
                                                           AND B.ItemSeq     = BB.ItemSeq    
           LEFT OUTER JOIN _TDAVatRate   AS AA WITH(NOLOCK) ON AA.CompanySeq = BB.CompanySeq      
                                                           AND AA.SMVatType  = BB.SMVatType      
                                                           AND BB.SMVatKind  <> 2003002  -- 면세 제외    
                                                           AND ISNULL(A.DelvDate,CONVERT(NVARCHAR(8),GETDATE(),112)) BETWEEN AA.SDate AND AA.EDate    
           LEFT OUTER JOIN _TDACurr      AS CC WITH(NOLOCK) ON A.CompanySeq = CC.CompanySeq    
                                                           AND A.CurrSeq    = CC.CurrSeq    
           LEFT OUTER JOIN _TPJTBOM      AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySEq        
                                                           AND B.PJTSeq     = M5.PJTSeq        
                                                           AND B.WBSSeq     = M5.BOMSerl        
           LEFT OUTER JOIN _TPJTBOM      AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq        
                                                           AND B.PJTSeq     = M1.PJTSeq     
                                                           AND M1.BOMSerl <> -1 AND M5.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM        
           LEFT OUTER JOIN _TDAItem      AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq        
                                                           AND M1.ItemSeq   = M2.ItemSeq        
           LEFT OUTER JOIN _TPJTBOM      AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq        
                                                           AND B.PJTSeq     = M3.PJTSeq        
                                                           AND M3.BOMSerl   <> -1        
                                                           AND ISNULL(M3.BeforeBOMSerl,0) = 0        
                       AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위        
                                         AND ISNUMERIC(REPLACE(M3.BOMLevel,'.','/')) = 1   
           LEFT OUTER JOIN _TDAItem      AS M4 WITH(NOLOCK)    ON A.CompanySeq      = M4.CompanySeq        
                                                              AND M3.ItemSeq        = M4.ItemSeq        
           LEFT OUTER JOIN _TDAUMinor    AS M6 WITH(NOLOCK)    ON A.CompanySeq      = M6.CompanySeq  
                                                              AND M5.UMMatQuality   = M6.MinorSeq   
           LEFT OUTER JOIN _TDAUMinor    AS D1 WITH(NOLOCK)    ON A.CompanySeq      = D1.CompanySeq    
                             AND M5.UMSupplyType   = D1.MinorSeq    
           LEFT OUTER JOIN _TPDQCTestReport AS QC WITH(NOLOCK) ON B.DelvSeq         = QC.SourceSeq  
                                                              AND B.DelvSerl        = QC.SourceSerl  
                                                              AND QC.SourceType     = '1'  
                                                              AND B.CompanySeq      = QC.CompanySeq  
           LEFT OUTER JOIN _TPDBaseItemQCType AS QC1 WITH(NOLOCK) ON B.CompanySeq   = QC1.CompanySeq  
                                                              AND B.ItemSeq         = QC1.ItemSeq  
                                                              AND QC1.IsInQC        = '1'  
           LEFT OUTER JOIN _TDACust      AS Cust WITH(NOLOCK)  ON B.CompanySeq      = Cust.CompanySeq       
                                                              AND B.MakerSeq        = Cust.CustSeq
           LEFT OUTER JOIN _TDAWHItem    AS WHI WITH(NOLOCK)   ON WHI.CompanySeq    = B.CompanySeq
                                                              AND WHI.WHseq         = B.WHseq   
                                                              AND WHI.Itemseq       = B.Itemseq  -- 창고Location 추가 :: 20141126 조성환(2014)  

            LEFT OUTER JOIN hencom_TPUDelvItemAdd AS DA WITH(NOLOCK) ON DA.CompanySeq  = B.CompanySeq  
                                                                    AND DA.DelvSeq    = B.DelvSeq
                                                                    AND DA.DelvSerl = B.DelvSerl 
            LEFT OUTER JOIN hencom_TPUPurchaseArea AS PA WITH(NOLOCK) ON PA.CompanySeq = DA.CompanySeq    
                                                                     AND PA.ProdDistrictSeq = DA.ProdDistrictSeq  
            LEFT OUTER JOIN _TDACust              AS DC   WITH(NOLOCK) ON DC.CompanySeq  = DA.CompanySeq           
                                                                      AND DC.CustSeq= DA.DeliCustSeq 
            -- 품목 소/중/대분류
            LEFT OUTER JOIN _TDAItemClass AS OC WITH(NOLOCK) ON G.CompanySeq = OC.CompanySeq 
                                                           AND G.ItemSeq = OC.ItemSeq 
                                                           AND OC.UMajorItemClass IN (2001,2004) 
            LEFT OUTER JOIN _TDAUMinor AS N WITH(NOLOCK) ON OC.CompanySeq = N.CompanySeq    
                                                        AND OC.UMItemClass = N.MinorSeq             
            LEFT OUTER JOIN _TDAUMinorValue AS X1 WITH(NOLOCK) ON N.CompanySeq = X1.CompanySeq
                                                        AND N.MinorSeq = X1.MinorSeq
                                                        AND X1.Serl IN (1001, 2001)
            LEFT OUTER JOIN _TDAUMinor      AS X2 WITH(NOLOCK) ON X1.CompanySeq = X2.CompanySeq
                                                        AND X1.ValueSeq = X2.MinorSeq
            LEFT OUTER JOIN _TDAUMinorValue AS Y1 WITH(NOLOCK) ON X2.CompanySeq = Y1.CompanySeq
                                                        AND X2.MinorSeq = Y1.MinorSeq
													     AND Y1.Serl = 2001
            LEFT OUTER JOIN _TDAUMinor      AS Y2 WITH(NOLOCK) ON Y1.CompanySeq = Y2.CompanySeq
                                                       AND Y1.ValueSeq = Y2.MinorSeq
            LEFT OUTER JOIN hencom_VPUBASEBuyPriceItemDate AS BBP ON BBP.CompanySeq = A.CompanySeq
                                                                 AND BBP.CustSeq = A.CustSeq
                                                                 AND BBP.DeptSeq = A.DeptSeq
                                                                 AND BBP.ProdDistrictSeq = DA.ProdDistrictSeq
                                                                 AND BBP.ItemSeq = B.ItemSeq
                                                                 AND ISNULL(BBP.DeliCustSeq, 0) = ISNULL(DA.DeliCustSeq, 0)
                                                                 AND ISNULL(BBP.SalesCustSeq, 0) = ISNULL(DA.SalesCustSeq, 0)
                                                                 AND A.DelvDate BETWEEN BBP.StartDate AND BBP.EndDate  
           LEFT OUTER JOIN _TDACustUserDefine      AS C2 WITH(NOLOCK)  ON C2.CompanySeq = BBP.CompanySeq     
                                                           AND	C2.CustSeq    = BBP.SalesCustSeq
														   AND	C2.MngSerl = 1000005
     WHERE A.CompanySeq    = @CompanySeq    
        AND (A.DelvDate BETWEEN @DelvDateFr    AND  @DelvDateTo)    
        AND (@CustSeq      = 0  OR A.CustSeq   = @CustSeq)    
        AND (@DelvNo       = '' OR A.DelvNo    LIKE @DelvNo   + '%')    
        AND (@SMQcType     = 0  OR B.SMQcType  =    @SMQcType)    
        AND (@WHSeq        = 0  OR B.WHSeq     =    @WHSeq)    
        AND (@ItemNo       = '' OR G.ItemNo    LIKE @ItemNo   + '%')    
        AND (@ItemName     = '' OR G.ItemName  LIKE @ItemName   + '%')  
        AND (@Spec         = '' OR G.Spec      LIKE @Spec     + '%')    
        AND (@PJTName      = '' OR M.PJTName   LIKE @PJTName + '%')    
        AND (@PJTNo        = '' OR M.PJTNo     LIKE @PJTNo   + '%')    
        AND (@SMDelvInType = 0  OR X.IsDelvIn  = RIGHT(@SMDelvInType, 1) OR (@SMDelvInType = 6062004 AND X.IsDelvIn IN ('1', '2'))  )  
        AND (@SMAssetKind  = 0  OR G.AssetSeq  = @SMAssetKind )    
        AND (@PONo         = '' OR X.PONo LIKE @PONo + '%')    
        AND (@UMSupplyType = 0 OR M5.UMSupplyType = @UMSupplyType)    
        AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')             
        AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')   
  
        AND (@SMDelvType   = 0  OR (@SMDelvType = 6209001 AND ISNULL(B.IsReturn, '') <> '1') OR (@SMDelvType = 6209002 AND ISNULL(B.IsReturn, '') = '1')   
             OR (@SMDelvType = 6209003 AND ISNULL(B.SourceType, '') = '2') OR (@SMDelvType = 6209004 AND ISNULL(B.SourceType, '') = '1'))  
  
       AND (A.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)      
       AND (@DelvNo  = '' OR A.DelvNo LIKE @DelvNo + '%' )      
       AND (@BizUnit = 0  OR A.BizUnit = @BizUnit)    
       AND (@DeptSeq = 0  OR A.DeptSeq = @DeptSeq)    
       AND (@EmpSeq  = 0  OR A.EmpSeq  = @EmpSeq)    
       AND (@CustSeq = 0  OR A.CustSeq = @CustSeq)    
       AND (@SMImpType    = 0  OR A.SMImpType =    @SMImpType)    
       AND (A.SMImpType IN (8008001, 8008002, 8008003))   
       AND (@LotNo = '' OR B.LotNo LIKE @LotNo + '%')  

       AND (@CustName      = '' OR C.CustName    LIKE @CustName + '%')   
       AND (@ItemClassSSeq = 0 OR @ItemClassSSeq = OC.UMItemClass)    
       AND (@ItemClassMSeq = 0 OR @ItemClassMSeq = X2.MinorSeq)    
       AND (@ItemClassLSeq = 0 OR @ItemClassLSeq = Y2.MinorSeq)   
       AND (@DeliCustName  = '' OR DC.CustName   LIKE @DeliCustName + '%')   
	   AND (@IOTag = 1014674001 OR @IOTag = ISNULL(C2.MngValText,0))
       AND (@ProdDistrictSeq = 0 OR DA.ProdDistrictSeq = @ProdDistrictSeq)
    ORDER BY A.DelvSeq    
      
    RETURN
    go 
exec hencom_SPUDelvItemListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ItemClassLSeq />
    <ItemClassMSeq />
    <ItemClassSSeq />
    <DeliCustName />
    <IOTag>1014674001</IOTag>
    <BizUnit />
    <DelvDateFr>20151201</DelvDateFr>
    <DelvDateTo>20151231</DelvDateTo>
    <DelvNo />
    <SMDelvType />
    <CustName />
    <WHSeq />
    <WHName />
    <TopUnitName />
    <DeptSeq>46</DeptSeq>
    <TopUnitNo />
    <EmpSeq />
    <ItemNo />
    <ItemName />
    <Spec />
    <SMQcType />
    <PONo />
    <SMImpType />
    <SMDelvInType />
    <PJTName />
    <PJTNo />
    <UMSupplyType />
    <LotNo />
    <SMAssetKind />
    <DelvCustSeq />
    <PurGroupDeptSeq>0</PurGroupDeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033518,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026851