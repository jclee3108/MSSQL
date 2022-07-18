
IF OBJECT_ID('DTI_SPUDelvItemListQuery') IS NOT NULL
    DROP PROC DTI_SPUDelvItemListQuery
    
GO
--v2013.06.17

-- 구매납품품목조회_DTI (매출처/EndUser 추가) By이재천
/************************************************************  
 설  명 - 데이터-구매납품품목조회_DTI : 구매납품품목현황조회  
 작성일 - 20101014  
 작성자 - 김진비  
************************************************************/  
CREATE PROC DTI_SPUDelvItemListQuery                  
    @xmlDocument  NVARCHAR(MAX) ,              
    @xmlFlags     INT  = 0,              
    @ServiceSeq   INT  = 0,              
    @WorkingTag   NVARCHAR(10)= '',                    
    @CompanySeq   INT  = 1,              
    @LanguageSeq  INT  = 1,              
    @UserSeq      INT  = 0,              
    @PgmSeq       INT  = 0           
AS          
       
    DECLARE @docHandle      INT          ,        
            @DelvDateFr     NCHAR(8)     ,      
            @DelvDateTo     NCHAR(8)     ,      
            @CustName       NVARCHAR(200),      
            @DelvNo         NVARCHAR(200),      
            @SMImpType      INT          ,      
            @SMStkType      INT          ,      
            @IsWarehoues    NCHAR(1)     ,      
            @SMQcType       INT          ,      
            @WHSeq          INT          ,      
            @ItemNo         NVARCHAR(200),      
            @SMDelvInType INT    ,      
            @PJTName        NVARCHAR(200) ,      
            @PJTNo          NVARCHAR(100) ,      
            @ItemName       NVARCHAR(100),      
            @DeptSeq        INT          ,      
            @EmpSeq         INT          ,      
            @PONo           NVARCHAR(20) ,      
            @SMAssetKind    INT          ,      
            @BizUnit        INT          ,      
            @SMDelvType     INT          ,      
            @UMSupplyType   INT    ,          
            @TopUnitName    NVARCHAR(200)  ,          
            @TopUnitNo      NVARCHAR(200),    
            @Spec           NVARCHAR(200),    
            @CustSeq        INT,  
            @ItemTypeSeq    INT,  
            @ItemClassS     INT,  
            @ItemClassL     INT,  
            @ItemClassM     INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument            
      
    SELECT @DelvDateFr   = ISNULL(DelvDateFr,''),      
           @DelvDateTo   = ISNULL(DelvDateTo,''),      
           @SMQcType     = ISNULL(SMQcType  , 0),      
           @CustName     = ISNULL(CustName  ,''),      
           @DelvNo       = ISNULL(DelvNo    ,''),      
           @SMImpType    = ISNULL(SMImpType , 0),      
           @WHSeq        = ISNULL(WHSeq     , 0),      
           @ItemNo       = ISNULL(ItemNo    ,''),      
           @PJTName      = ISNULL(PJTName   ,''),      
           @PJTNo        = ISNULL(PJTNo     ,''),      
           @SMDelvInType = ISNULL(SMDelvInType, 0),      
           @ItemName     = ISNULL(ItemName  ,''),           
           @DeptSeq      = ISNULL(DeptSeq   , 0),           
           @EmpSeq       = ISNULL(EmpSeq    , 0),           
           @PONo         = ISNULL(PONo      ,''),           
           @SMAssetKind  = ISNULL(SMAssetKind, 0),      
           @BizUnit      = ISNULL(BizUnit   , 0),      
           @SMDelvType   = ISNULL(SMDelvType, 0),      
           @UMSupplyType = ISNULL(UMSupplyType,0),          
           @TopUnitName  = ISNULL(TopUnitName  , ''),                              
           @TopUnitNo    = ISNULL(TopUnitNo    , ''),    
           @Spec         = ISNULL(Spec         , ''),    
           @CustSeq      = ISNULL(CustSeq      ,0),  
           @ItemTypeSeq  = ISNULL(ItemTypeSeq      ,0),  
           @ItemClassS   = ISNULL(ItemClassS      ,0),  
           @ItemClassL   = ISNULL(ItemClassL      ,0),  
           @ItemClassM   = ISNULL(ItemClassM      ,0)  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
     WITH (DelvDateFr     NCHAR(8)       ,      
           DelvDateTo     NCHAR(8)       ,      
           CustName       NVARCHAR(200)  ,      
           DelvNo         NVARCHAR(200)  ,      
           SMImpType      INT            ,      
           SMQcType       INT             ,      
           WHSeq          INT            ,      
           ItemNo         NVARChAR(200)  ,      
           PJTName        NVARCHAR(60)   ,      
           PJTNo          NVARCHAR(40)   ,      
           SMDelvInType   INT     ,      
           ItemName       NVARCHAR(100)  ,    
           DeptSeq        INT            ,      
           EmpSeq         INT            ,      
           PONo           NVARCHAR(20)   ,      
           SMAssetKind    INT            ,      
           BizUnit        INT            ,      
           SMDelvType     INT            ,      
           UMSupplyType   INT     ,          
           TopUnitName    NVARCHAR(200)  ,          
           TopUnitNo      NVARCHAR(200)  ,    
           Spec           NVARCHAR(200)  ,    
           CustSeq        INT,  
           ItemTypeSeq    INT,  
           ItemClassS     INT,  
           ItemClassL     INT,  
           ItemClassM     INT)      
      
    IF @DelvDateFr = '' SELECT @DelvDateFr = '10000101'      
    IF @DelvDateTo = '' SELECT @DelvDateTo = '99991231'      
      
    -------------------      
    --입고진행여부-----      
    -------------------      
    CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))          
            
    CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsDelvIn NCHAR(1), Qty DECIMAL(19,5), DelvInQty DECIMAL(19, 5), DelvInCurAmt DECIMAL(19, 5), DelvInDomAmt DECIMAL(19, 5), PONo NCHAR(12), ExRate DECIMAL(19, 5), PODate NCHAR(8)  
, CompleteCheck INT, RemainQty DECIMAL(19, 5), RemainAmt DECIMAL(19, 5), RemainVAT DECIMAL(19, 5), CurAmt DECIMAL(19, 5), POSeq INT)--*            
          
    CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))            
      
    CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), CurAmt DECIMAL(19,5), CurVAT DECIMAL(19, 5))      
      
    INSERT #TMP_PROGRESSTABLE           
    SELECT 1, '_TPUDelvInItem'               -- 구매입고      
          
    -- 구매납품      
    INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsDelvIn, Qty, DelvInQty, DelvInCurAmt, DelvInDomAmt, PONo, ExRate, PODate, CurAmt)          
    SELECT  A.DelvSeq, ISNULL(B.DelvSerl, 0), '1', B.Qty, 0, 0, 0, '', A.ExRate, '', B.CurAmt      
      FROM _TPUDelv                     AS A WITH(NOLOCK)           
     LEFT OUTER JOIN _TPUDelvItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq      
               AND A.DelvSeq   = B.DelvSeq      
     WHERE A.CompanySeq   = @CompanySeq        
       AND (A.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)        
       AND (@DelvNo  = '' OR A.DelvNo LIKE @DelvNo + '%' )        
       AND (@BizUnit = 0  OR A.BizUnit = @BizUnit)      
       AND (@DeptSeq = 0  OR A.DeptSeq = @DeptSeq)      
       AND (@EmpSeq  = 0  OR A.EmpSeq  = @EmpSeq)      
       AND (@CustSeq = 0  OR A.CustSeq = @CustSeq)      
       AND (@SMImpType    = 0  OR A.SMImpType =    @SMImpType)      
       AND (A.SMImpType IN (8008001, 8008002, 8008003))      
                   
    
 EXEC _SCOMProgStatus @CompanySeq, '_TPUDelvItem', 1036002 , '#Temp_Order', 'OrderSeq', 'OrderSerl', '', 'RemainQty', '', 'RemainAmt', 'RemainVAT', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', 'CurVAT', 'DelvSeq', 'DelvSerl', '', '_TPUDelvItem',  
 @PgmSeq       
    
    UPDATE #Temp_Order       
       SET IsDelvIn     = CASE WHEN A.RemainQty > 0 THEN '2'     
          WHEN A.RemainQty = 0 THEN '3'     
          WHEN A.RemainQty < 0 THEN '3'    
                ELSE '1'  END  ,      
           DelvInQty    = A.Qty - A.RemainQty ,      
           DelvInCurAmt = A.CurAmt - A.RemainAmt,      
           DelvInDomAmt = (A.CurAmt * ISNULL(A.ExRate, 1))  - (A.RemainAmt * ISNULL(A.ExRate, 1))    
      FROM #Temp_Order                AS A    
  WHERE A.CompleteCheck <> 0           
           
  --  UPDATE #Temp_Order       
  --     SET IsDelvIn     = '3'     ,      
    --         DelvInQty    = A.Qty - A.RemainQty , --D.Qty   ,      
  --         DelvInCurAmt = B.CurAmt - A.RemainAmt,      
  --         DelvInDomAmt = (B.CurAmt * ISNULL(A.ExRate, 1))  - (A.RemainAmt * ISNULL(A.ExRate, 1))    
  --    FROM #Temp_Order                AS A     
  --   JOIN _TPUDelvItem    AS B     
  --WHERE B.CompanySeq = @CompanySeq           
           
  --   WHERE A.RemainQty = 0     
          
    --INSERT INTO #OrderTracking          
    --SELECT IDX_NO,          
    --       SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),          
    --   SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END),      
    --       SUM(CASE IDOrder WHEN 1 THEN VAT     ELSE 0 END)         
    --  FROM #TCOMProgressTracking          
    -- GROUP BY IDX_No          
      
    --UPDATE #Temp_Order       
    --   SET IsDelvIn     = '2'     ,      
    --       DelvInQty    = D.Qty   ,      
    --       DelvInCurAmt = D.CurAmt,      
    --       DelvInDomAmt = D.CurAmt * ISNULL(A.ExRate, 1)      
    --  FROM #Temp_Order                AS A        
    --       JOIN #OrderTracking        AS D ON A.IDX_No = D.IDX_No      
    --       JOIN #TCOMProgressTracking AS B ON D.IDX_No = B.IDX_No      
    --       JOIN _TPUDelvInItem        AS C ON C.CompanySeq = @CompanySeq    
    --                                      AND B.Seq    = C.DelvInSeq      
    --                                      AND B.Serl   = C.DelvInSerl        
    -- WHERE A.Qty <> D.Qty      
       
    --UPDATE #Temp_Order       
    --   SET IsDelvIn      = '3'     ,      
    --       DelvInQty     = D.Qty   ,      
    --       DelvInCurAmt  = D.CurAmt,      
    --       DelvInDomAmt  = D.CurAmt * ISNULL(A.ExRate, 1)      
    -- FROM #Temp_Order                 AS A        
    --       JOIN #OrderTracking        AS D ON A.IDX_No = D.IDX_No      
    --       JOIN #TCOMProgressTracking AS B ON D.IDX_No = B.IDX_No      
    --       JOIN _TPUDelvInItem        AS C ON C.CompanySeq = @CompanySeq    
    --                                      AND B.Seq    = C.DelvInSeq      
    --                                      AND B.Serl   = C.DelvInSerl      
    -- WHERE A.Qty = D.Qty          
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
    --CREATE TABLE #Temp_Delv    
    --(          
    --    IDX_NO      INT,          
    --    DelvSeq     INT,          
    --    DelvSerl    INT    
    --)   
    INSERT #TMP_SOURCETABLE          
    SELECT 1,'_TPUORDPOItem'          
      
    INSERT #TMP_SOURCETABLE          
    SELECT 2,'_TPUDelv'      
      
  
    INSERT #TMP_SOURCEITEM      
         ( SourceSeq    , SourceSerl    , Qty)      
    SELECT A.DelvSeq    , B.DelvSerl    , B.Qty      
      FROM _TPUDelv           AS A      
           JOIN _TPUDelvItem  AS B ON A.CompanySeq  = B.CompanySeq      
                     AND A.DelvSeq     = B.DelvSeq      
           LEFT OUTER JOIN _TPJTBOM AS C ON A.CompanySeq = C.CompanySeq      
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
           PODate = ISNULL(D.PODate, ''),  
           POSeq = ISNULL(D.POSeq, 0)   
      FROM #Temp_Order               AS A      
           JOIN #TMP_SOURCEITEM      AS B              ON A.OrderSeq   = B.SourceSeq AND A.OrderSerl = B.SourceSerl       
           JOIN #TCOMSourceTracking  AS C              ON B.IDX_NO     = C.IDX_NO      
           LEFT OUTER JOIN _TPUORDPO AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq      
                                                      AND C.Seq        = D.POSeq  
     WHERE C.IDOrder = 1    
       
     DELETE   #TMP_SOURCETABLE  
     DELETE   #TCOMSourceTracking  
     DELETE   #TMP_SOURCEITEM  
     --DELETE   #TMP_EXPENSE  
    ------------------------      
    --발주번호 추적 끝  ----      
    ------------------------   
    --=====================================================================================================================    
    -- 품의로부터 진행된 구매납품건의 품의 담당자와 부서코드 가져오기    
    --=====================================================================================================================    
  
    --CREATE TABLE #TMP_SOURCETABLE    
    --(    
    --    IDOrder     INT,    -- 순번    
    --    TABLENAME   NVARCHAR(100)  -- 검색할 테이블명    
    --)      
    
    ---- 결과 테이블    
    --CREATE TABLE #TCOMSourceTracking        
    --(       IDX_NO      INT,        
    --        IDOrder     INT,        
    --        Seq         INT,        
    --        Serl        INT,        
    --        SubSerl     INT,        
    --        FromQty     DECIMAL(19, 5),        
    --        FromAmt     DECIMAL(19, 5) ,        
    --        ToQty       DECIMAL(19, 5),        
    --        ToAmt       DECIMAL(19, 5)        
    --)     
    
    INSERT #TMP_SOURCETABLE     
    SELECT '1', '_TPUORDApprovalReqItem'    -- 구매품의    
    
    -- 구매납품 테이블    
    CREATE TABLE #Temp_Delv    
    (          
        IDX_NO      INT IDENTITY,          
        DelvSeq     INT,          
        DelvSerl    INT,  
        LotNo       NVARCHAR(40),  
        ItemSeq     INT    
    )     
        
    -- 구매납품    
    --INSERT INTO #Temp_Delv (  IDX_NO, DelvSeq, DelvSerl )    
    --SELECT    
    --    A.DataSeq, A.DelvSeq, A.DelvSerl    
    --FROM #TMP_SOURCEITEM AS A    
    --WHERE A.WorkingTag IN ('A','U')    
    --  AND A.Status = 0  
      
      
      
    INSERT INTO #Temp_Delv (DelvSeq, DelvSerl, LotNo, ItemSeq )       
    SELECT A.DelvSeq    , B.DelvSerl, B.LOTNo, B.ItemSeq   
      FROM _TPUDelv           AS A      
           JOIN _TPUDelvItem  AS B ON A.CompanySeq  = B.CompanySeq      
                                  AND A.DelvSeq     = B.DelvSeq      
           LEFT OUTER JOIN _TPJTBOM AS C ON A.CompanySeq = C.CompanySeq      
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
    
    EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#Temp_Delv', 'DelvSeq', 'DelvSerl', ''    
    
    
    
    -- 품의 데이터가 존재하는 데이터만 따로 테이블에 저장    
    CREATE TABLE #DTI_TLGLogEmpAutoDelv    
    (    
        CompanySeq  INT,  
        DelvSeq     INT,  
        LotNo       NVARCHAR(30),    
        ItemSeq     INT,    
        DeptSeq     INT,    
        EmpSeq      INT,    
        WorkingTag  NCHAR(1),    
        Status      INT  
    )    
    
    
    INSERT INTO #DTI_TLGLogEmpAutoDelv ( CompanySeq, DelvSeq, LotNo, ItemSeq, DeptSeq, EmpSeq, WorkingTag, Status)    
    SELECT --DISTINCT  
        @CompanySeq, A.DelvSeq, A.LotNo, A.ItemSeq, C.DeptSeq, C.EmpSeq, 'A', 0  
    FROM #Temp_Delv AS A    
        INNER JOIN #TCOMSourceTracking AS B ON B.IDX_NO = A.IDX_NO    
        INNER JOIN _TPUORDApprovalReq AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq AND C.ApproReqSeq = B.Seq    
    --select * from #Temp_Delv  
   --select * from #DTI_TLGLogEmpAutoDelv  
   --select * from #Temp_Order  
   --select * from #TCOMSourceTracking  
   --select * from _TPUORDApprovalReq where CompanySeq = 1 and ApproReqSeq = 1514  
      --=====================================================================================================================    
    -- 품의로부터 진행된 구매납품건의 품의 담당자와 부서코드 가져오기 끝  
    --=====================================================================================================================   
      
    --출력--    
    SELECT     
            G.ItemName             AS ItemName               ,      
            G.ItemNo               AS ItemNo                 ,      
            G.Spec                 AS Spec                   ,      
            H.UnitName             AS UnitName               ,      
            B.Price                AS Price                  ,      
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
            B.QCQty                AS QCQty                  ,      
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
            CASE X.IsDelvIn WHEN '1' THEN 6062001 WHEN '2' THEN 6062002 ELSE 6062003 END AS SMDelvInType,      
            CASE X.IsDelvIn WHEN '1' THEN '미입고' WHEN '2' THEN '입고중' ELSE '입고완료' END AS SMDelvInTypeName,      
            -- 구매납품에서 반품시 수정필요      
            CASE ISNULL(B.IsReturn, '') WHEN '1' THEN 6209002 ELSE 6209001 END                AS SMDelvType        ,      
            CASE ISNULL(B.IsReturn, '') WHEN '1' THEN '반품' ELSE '납품' END                 AS SMDelvTypeName    ,      
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
            B.IsReturn      AS IsReturn,   
            Y.UMItemClass AS ItemTypeSeq,    
            (SELECT MinorName FROM _TDAUMinor where CompanySeq = 1 and MinorSeq = Y.UMItemClass)  AS ItemType ,  
            Z.UMItemClass AS ItemClassS,  
            Z1.ValueSeq AS ItemClassM,  
            Z2.ValueSeq AS ItemClassL,  
            IsNULL((SELECT X.MinorName FROM _TDAUMinor X WITH(NOLOCK) WHERE X.CompanySeq = @CompanySeq And X.MinorSeq = Z2.ValueSeq), '') as ItemClassLName,   
            IsNULL((SELECT X.MinorName FROM _TDAUMinor X WITH(NOLOCK) WHERE X.CompanySeq = @CompanySeq And X.MinorSeq = Z1.ValueSeq), '') as ItemClassMName,   
            IsNULL((SELECT X.MinorName FROM _TDAUMinor X WITH(NOLOCK) WHERE X.CompanySeq = @CompanySeq And X.MinorSeq = Z.UMItemClass), '') as ItemClassSName,   
           X2.DeptSeq AS DeptSeq,  
           X2.EmpSeq AS EmpSeq,  
           F2.DeptName AS CDeptName, ---------------품의부서  
           D2.EmpName AS CEmpName, ---------------품의담당자  
           B.Memo1    AS SalesCustSeq,
           B.Memo2    AS EndUserSeq,
           Q.CustName AS SalesCustName,
           R.CustName AS EndUserName 
           
      FROM _TPUDelv AS A WITH(NOLOCK)       
                      JOIN _TPUDelvItem  AS B               ON A.CompanySeq = B.CompanySeq       
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
                                                           AND B.PJTSeq     = M.PJTSeq      
--           LEFT OUTER JOIN _TPJTWBS      AS N WITH(NOLOCK)  ON B.CompanySeq = N.CompanySeq       
--                                                           AND B.PJTSeq     = N.PJTSeq       
--                                                           AND B.WBSSeq     = N.WBSSeq        
           LEFT OUTER JOIN _TDABizUnit   AS O WITH(NOLOCK)  ON A.CompanySeq = O.CompanySeq       
                                                           AND A.BizUnit    = O.BizUnit      
           LEFT OUTER JOIN _TDAItemAsset AS P WITH(NOLOCK)  ON G.CompanySeq = P.CompanySeq       
                                                           AND G.AssetSeq   = P.AssetSeq      
           LEFT OUTER JOIN _TDAItemSales AS BB WITH(NOLOCK) ON BB.CompanySeq= @CompanySeq      
                                                           AND B.ItemSeq    = BB.ItemSeq      
           LEFT OUTER JOIN _TDAVatRate   AS AA WITH(NOLOCK) ON AA.CompanySeq= BB.CompanySeq        
                                                           AND AA.SMVatType = BB.SMVatType        
                                                           AND BB.SMVatKind <> 2003002  -- 면세 제외      
                                        AND ISNULL(A.DelvDate,CONVERT(NVARCHAR(8),GETDATE(),112))      
                                                                BETWEEN AA.SDate AND AA.EDate      
           LEFT OUTER JOIN _TDACurr      AS CC WITH(NOLOCK) ON A.CompanySeq = CC.CompanySeq      
                                                           AND A.CurrSeq    = CC.CurrSeq      
           LEFT OUTER JOIN _TPJTBOM       AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySEq          
                                                           AND B.PJTSeq = M5.PJTSeq          
                                                           AND B.WBSSeq = M5.BOMSerl          
           LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq          
                                                           AND B.PJTSeq = M1.PJTSeq       
                                                           AND M1.BOMSerl <> -1 AND M5.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM          
           LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq          
                                                           AND M1.ItemSeq = M2.ItemSeq          
           LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq          
                             AND B.PJTSeq = M3.PJTSeq          
                                                           AND M3.BOMSerl <> -1          
                                                           AND ISNULL(M3.BeforeBOMSerl,0) = 0          
                                                           AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위          
           LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq          
                                                           AND M3.ItemSeq = M4.ItemSeq          
           LEFT OUTER JOIN _TDAUMinor     AS M6 WITH(NOLOCK) ON A.CompanySeq = M6.CompanySeq    
                                                            AND M5.UMMatQuality = M6.MinorSeq     
           LEFT OUTER JOIN _TDAUMinor    AS D1 WITH(NOLOCK) ON A.CompanySeq = D1.CompanySeq      
                                                           AND M5.UMSupplyType = D1.MinorSeq      
           LEFT OUTER JOIN _TPDQCTestReport AS QC WITH(NOLOCK) ON B.DelvSeq = QC.SourceSeq    
                                                              AND B.DelvSerl = QC.SourceSerl    
                                                              AND QC.SourceType = '1'    
                                                              AND B.CompanySeq = QC.CompanySeq  
           LEFT OUTER JOIN  _TDAItemClass AS Y WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq  
                                                            AND G.ItemSeq = Y.ItemSeq  
                                                            AND Y.UMajorItemClass = 1000203       
           LEFT OUTER JOIN _TDAItemClass   AS Z WITH(NOLOCK) ON Z.CompanySeq = @CompanySeq  
                                                              AND G.ItemSeq = Z.ItemSeq  
                                                              AND ( Z.UMajorItemClass = 2004 Or Z.UMajorItemClass = 2001)    
          LEFT OUTER JOIN _TDAUMinorValue Z1 WITH(NOLOCK) ON Z1.CompanySeq = @CompanySeq   
                                                         AND Z1.MinorSeq = Z.UMItemClass   
                                                         AND Z1.Serl = Case Z.UMajorItemClass When 2001 then 1001 else 2001 end   
          LEFT OUTER JOIN _TDAUMinorValue Z2 WITH(NOLOCK)  ON Z2.CompanySeq = @CompanySeq   
                                                        AND Z2.MinorSeq = Z1.ValueSeq AND Z2.Serl = 2001   
          ----LEFT OUTER JOIN _TPUORDPO X2 WITH(NOLOCK)     ON X.POSeq = X2.POSeq  
          LEFT OUTER JOIN #DTI_TLGLogEmpAutoDelv AS X2     ON X2.CompanySeq = @CompanySeq  
        AND B.DelvSeq    = X2.DelvSeq  
                                                           AND B.LotNo      = X2.LotNo  
                                                           AND B.ItemSeq    = X2.ItemSeq  
           LEFT OUTER JOIN _TDAEmp       AS D2 WITH(NOLOCK)  ON D2.CompanySeq = @CompanySeq       
                                                           AND X2.EmpSeq     = D2.EmpSeq           
           LEFT OUTER JOIN _TDADept      AS F2 WITH(NOLOCK)  ON F2.CompanySeq  = @CompanySeq     
                                                           AND X2.DeptSeq    = F2.DeptSeq                                       
           LEFT OUTER JOIN _TDACust      AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.CustSeq = B.Memo1 ) 
           LEFT OUTER JOIN _TDACust      AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = B.Memo2 ) 
     WHERE A.CompanySeq    = @CompanySeq      
        AND (A.DelvDate BETWEEN @DelvDateFr    AND  @DelvDateTo)      
        --AND (@CustName     = '' OR C.CustName  LIKE @CustName + '%')      
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
        AND (@SMAssetKind  = 0  OR G.AssetSeq  = RIGHT(@SMAssetKind, 1) )      
        AND (@PONo         = '' OR X.PONo LIKE @PONo + '%')      
        AND (@UMSupplyType = 0 OR M5.UMSupplyType = @UMSupplyType)      
        AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')               
        AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')     
        AND (@SMDelvType   = 0  OR (@SMDelvType = 6209001 AND ISNULL(B.IsReturn, '') <> '1') OR (@SMDelvType = 6209002 AND ISNULL(B.IsReturn, '') = '1') )  
        AND (@ItemClassS = 0 OR Z.UMItemClass = @ItemClassS)  
        AND (@ItemClassM = 0 OR Z1.ValueSeq = @ItemClassM)   
        AND (@ItemClassL = 0 OR Z2.ValueSeq = @ItemClassL)  
        AND (@ItemTypeSeq = 0 OR Y.UMItemClass = @ItemTypeSeq)  
    ORDER BY A.DelvSeq      
      
    --select * from _TDAUMinorValue where companyseq = 1 and Serl = 2001     
RETURN        
