
IF OBJECT_ID('costel_SPUORDPOItemListQuery') IS NOT NULL 
    DROP PROC costel_SPUORDPOItemListQuery 
GO

-- v2013.11.18 

-- 구매발주및수입발주품목조회_costel by이재천
CREATE PROCEDURE costel_SPUORDPOItemListQuery 
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
     
     DECLARE @docHandle        INT,
             @PODateFr         NCHAR(8),
             @PODateTo         NCHAR(8),
             @PONo             NVARCHAR(24),
             @CustSeq          INT,
             @DeptSeq          INT,
             @EmpSeq           INT,
             @ItemName         NVARCHAR(100),       
             @ItemNo           NVARCHAR(100),
             @SMAssetType      INT,
             @SMImpType        INT,
             @SMCurrStatus     INT,
             @Cnt              INT,
             @Seq              INT,
             @DelvDateFr       NCHAR(8),
             @DelvDateTo       NCHAR(8),
             @SMDelvInType     INT,
             @WHSeq            INT,             -- 20100325 박소연 추가
             @Spec             NVARCHAR(100),
             @PurGroupDeptSeq  INT  
  
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      SELECT @PODateFr         = ISNULL(PODateFr       , ''),
            @PODateTo         = ISNULL(PODateTo       , ''),
            @PONo             = ISNULL(PONo           , ''),
            @CustSeq          = ISNULL(CustSeq    ,  0),
            @DeptSeq          = ISNULL(DeptSeq        ,  0),
            @EmpSeq           = ISNULL(EmpSeq         ,  0),
            @ItemName         = ISNULL(ItemName       , ''),
            @ItemNo           = ISNULL(ItemNo         , ''),
            @SMAssetType      = ISNULL(SMAssetType    ,  0),
            @SMImpType        = ISNULL(SMImpType      ,  0),                    
            @SMCurrStatus     = ISNULL(SMCurrStatus   ,  0),
            @DelvDateFr       = ISNULL(DelvDateFr     , ''),
            @DelvDateTo       = ISNULL(DelvDateTo     , ''),
            @SMDelvInType     = ISNULL(SMDelvInType   ,  0),   
            @WHSeq            = ISNULL(WHSeq          ,  0), -- 20100325 박소연 추가
            @Spec             = ISNULL(Spec           , ''),
            @PurGroupDeptSeq  = ISNULL(PurGroupDeptSeq,  0) 
          
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH ( PODateFr           NCHAR(8)     ,
            PODateTo           NCHAR(8)     ,
            PONo               NVARCHAR(24) ,
            CustSeq            INT          ,
            DeptSeq            INT          ,
            EmpSeq             INT          ,
            ItemName           NVARCHAR(100),
            ItemNo             NVARCHAR(100),
            SMAssetType        INT          ,
            SMImpType          INT          ,
            SMCurrStatus       INT          ,
            DelvDateFr         NCHAR(8)     ,
            DelvDateTo         NCHAR(8)     ,
            SMDelvInType       INT          ,  
            WHSeq              INT          ,    -- 20100325 박소연 추가
            Spec               NVARCHAR(200), 
            PurGroupDeptSeq    INT
          )
  
           
    IF @PODateFr = '' SET @PODateFr = '11110101'
    IF @PODateTo = '' SET @PODateTo = '99991231'
    IF @DelvDateFr = '' SET @DelvDateFr = '11110101'
    IF @DelvDateTo = '' SET @DelvDateTo = '99991231' 
          
    -------------------
    --납품진행여부-----
    -------------------
    CREATE TABLE #TMP_PROGRESSTABLE
    (
        IDOrder INT, 
        TABLENAME   NVARCHAR(100)
    )    
       
     CREATE TABLE #Temp_POProgress
     (
        IDX_NO          INT IDENTITY, 
        POSeq           INT, 
        POSerl          INT, 
        Qty             DECIMAL(19, 5), 
        IsDelv          NCHAR(1), 
        IsStop          NCHAR(1), 
        SMCurrStatus    INT, 
        CurAmt          DECIMAL(19, 5), 
        CurVAT          DECIMAL(19, 5), 
        DelvSeq         INT, 
        DelvSerl        INT, 
        DelvAmt         DECIMAL(19, 5), 
        DelvVAT         DECIMAL(19, 5), 
        DelvQty         DECIMAL(19, 5), 
        DelvInSeq       INT, 
        DelvInSerl      INT, 
        DelvInAmt       DECIMAL(19, 5), 
        DelvInVAT       DECIMAL(19, 5), 
        DelvInQty       DECIMAL(19, 5), 
        DelvDate        NCHAR(8), 
        DelvInDate      NCHAR(8), 
        DelvExRate      DECIMAL(19, 5), 
        DelvInExRate    DECIMAL(19, 5), 
        CompleteCHECK   INT, 
        ApproReqNo      NCHAR(12), 
        POReqNO         NCHAR(12), 
        ReqEmpSeq       INT,
        ApproReqEmpSeq  INT,
        ApproReqDeptSeq INT,
        DelvDomAmt      DECIMAL(19, 5),         -- 12.04.13 김세호 추가
        DelvInDomAmt    DECIMAL(19, 5)          -- 12.04.13 김세호 추가
    )    
    
     CREATE TABLE #Temp_POProgressSub
     (
        IDX_NO          INT IDENTITY, 
        POSeq           INT, 
        POSerl          INT, 
        Qty             DECIMAL(19, 5), 
        IsDelv          NCHAR(1), 
        IsStop          NCHAR(1), 
        SMCurrStatus    INT, 
        CurAmt          DECIMAL(19, 5), 
        CurVAT          DECIMAL(19, 5), 
        DelvSeq         INT, 
        DelvSerl        INT, 
        DelvAmt         DECIMAL(19, 5), 
        DelvVAT         DECIMAL(19, 5), 
        DelvQty         DECIMAL(19, 5), 
        DelvInSeq       INT, 
        DelvInSerl      INT, 
        DelvInAmt       DECIMAL(19, 5), 
        DelvInVAT       DECIMAL(19, 5), 
        DelvInQty       DECIMAL(19, 5), 
        DelvDate        NCHAR(8), 
        DelvInDate      NCHAR(8), 
        DelvExRate      DECIMAL(19, 5), 
        DelvInExRate    DECIMAL(19, 5), 
        CompleteCHECK   INT, 
        ApproReqNo      NCHAR(12), 
        POReqNO         NCHAR(12), 
        ReqEmpSeq       INT,
        ApproReqEmpSeq  INT,
        ApproReqDeptSeq INT,
        DelvDomAmt      DECIMAL(19, 5),         -- 12.04.13 김세호 추가
        DelvInDomAmt    DECIMAL(19, 5)          -- 12.04.13 김세호 추가
    )    
    
    CREATE TABLE #TCOMProgressTracking
    (
        IDX_NO      INT, 
        IDOrder     INT, 
        Seq         INT,
        Serl        INT, 
        SubSerl     INT,
        Qty         DECIMAL(19, 5), 
        StdQty      DECIMAL(19,5) , 
        Amt         DECIMAL(19, 5),
        VAT         DECIMAL(19,5)
    )      
    CREATE TABLE #OrderTracking
    (
        IDX_NO  INT, 
        IDOrder INT,
        Qty     DECIMAL(19,5), 
        Amt     DECIMAL(19,5), 
        VAT     DECIMAL(19,5)
    )
    CREATE TABLE #TMP_SOURCETABLE          
    (          
        IDOrder     INT,          
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
   
    DECLARE @DelvWH TABLE
    (
        POSeq    INT,
        POSerl   INT,
        WHSeq    INT
    )
    
    -- 구매발주 데이터 담기
    INSERT INTO #Temp_POProgress(POSeq, POSerl, Qty, IsDelv, IsStop, SMCurrStatus, CurAmt, CurVAT, DelvSeq, DelvSerl, DelvAmt, DelvVAT, DelvQty, DelvInSeq, DelvInSerl, DelvInAmt, DelvInVAT, DelvInQty, DelvExRate, DelvInExRate, CompleteCHECK,  DelvDomAmt, DelvInDomAmt)    
    SELECT A.POSeq, B.POSerl, B.Qty, '1', B.IsStop, 6036001, ISNULL(SUM(B.CurAmt), 0), ISNULL(SUM(B.CurVAT), 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 -- 미납으로 셋팅    
      FROM _TPUORDPO               AS A WITH(NOLOCK)     
      JOIN _TPUORDPOItem           AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq ) 
      JOIN _TDAItem                AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TPJTBOM     AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND B.PJTSeq = C.PJTSeq AND B.WBSSeq = C.BOMSerl ) 
      LEFT OUTER JOIN _TDACust     AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CustSeq = E.CustSeq ) 
      LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON ( B.CompanySeq = F.CompanySeq AND B.PJTSeq = F.PJTSeq ) 
    WHERE A.CompanySeq   = @CompanySeq  
      AND (A.PODate      BETWEEN @PODateFr AND @PODateTo)  
      AND (@DeptSeq      = 0  OR A.DeptSeq      = @DeptSeq)
      AND (@EmpSeq       = 0  OR A.EmpSeq       = @EmpSeq)
      AND (@PONo         = '' OR A.PONo         LIKE @PONo + '%' )
      AND (A.SMImpType   IN (8008001, 8008002, 8008003))
      AND (@ItemName     = '' OR D.ItemName     LIKE @ItemName+'%')
      AND (@ItemNo       = '' OR D.ItemNo       LIKE @ItemNo+'%')
      AND (@CustSeq      = 0  OR A.CustSeq      = @CustSeq)
      AND (@Spec         = '' OR D.Spec         LIKE @Spec + '%')
      AND (@SMImpType    = 0  OR A.SMImpType    = @SMImpType )
      AND (@SMAssetType  = 0  OR D.AssetSeq     = @SMAssetType)
      AND (B.DelvDate    = '' OR B.DelvDate     IS NULL OR B.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
    GROUP BY A.POSeq, B.POSerl, B.Qty, B.IsStop  
    
    -- 수출Order 데이터 담기
    INSERT INTO #Temp_POProgressSub(POSeq, POSerl, Qty, IsDelv, IsStop, SMCurrStatus, CurAmt, CurVAT, DelvSeq, DelvSerl, DelvAmt, DelvVAT, DelvQty, DelvInSeq, DelvInSerl, DelvInAmt, DelvInVAT, DelvInQty, DelvExRate, DelvInExRate, CompleteCHECK,  DelvDomAmt, DelvInDomAmt)    
    SELECT A.POSeq, B.POSerl, B.Qty, '1', B.IsStop, 6036001, ISNULL(SUM(B.CurAmt), 0), ISNULL(SUM(B.CurVAT), 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 -- 미납으로 셋팅    
      FROM _TPUORDPO               AS A WITH(NOLOCK)     
      JOIN _TPUORDPOItem           AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq ) 
      JOIN _TDAItem                AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TPJTBOM     AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND B.PJTSeq = C.PJTSeq AND B.WBSSeq = C.BOMSerl ) 
      LEFT OUTER JOIN _TDACust     AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CustSeq = E.CustSeq ) 
      LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON ( B.CompanySeq = F.CompanySeq AND B.PJTSeq = F.PJTSeq )                                                
     WHERE A.CompanySeq   = @CompanySeq  
      AND (A.PODate      BETWEEN @PODateFr AND @PODateTo)  
      AND (@DeptSeq      = 0  OR A.DeptSeq      = @DeptSeq)
      AND (@EmpSeq       = 0  OR A.EmpSeq       = @EmpSeq)
      AND (@PONo         = '' OR A.PONo         LIKE @PONo + '%' )
      AND (A.SMImpType   IN (8008004, 8008006, 8008007, 8008008, 8008009, 8008010, 8008011, 8008012, 8008013, 8008014))
      AND (@ItemName     = '' OR D.ItemName     LIKE @ItemName+'%')
      AND (@ItemNo       = '' OR D.ItemNo       LIKE @ItemNo+'%')
      AND (@CustSeq      = 0  OR A.CustSeq      = @CustSeq)
      AND (@Spec         = '' OR D.Spec         LIKE @Spec + '%')
      AND (@SMImpType    = 0  OR A.SMImpType    = @SMImpType )
      AND (@SMAssetType  = 0  OR D.AssetSeq     = @SMAssetType)
      AND (B.DelvDate    = '' OR B.DelvDate     IS NULL OR B.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo)
     GROUP BY A.POSeq, B.POSerl, B.Qty, B.IsStop   
          
    -- 진행상태 체크 
    -- 구매진행상태
    EXEC _SCOMProgStatus @CompanySeq, '_TPUORDPOItem', 1036002, '#Temp_POProgress', 'POSeq', 'POSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', '', 'POSeq', 'POSerl', '', '_TPUORDPOItem', @PgmSeq 
    
    -- 수입진행상태
    EXEC _SCOMProgStatus @CompanySeq, '_TPUORDPOItem', 1036007, '#Temp_POProgressSub', 'POSeq', 'POSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', 'CurVAT', 'POSeq', 'POSerl', '', '_TPUORDPO', @pgmSeq
    
    UPDATE #Temp_POProgress     
       SET SMCurrStatus = (SELECT CASE WHEN A.IsStop = '1'       THEN 6036005       -- 중단    
                                       WHEN A.CompleteCHECK = 1  THEN 6036002  -- 확정(승인)  
                                       WHEN A.CompleteCHECK = 40 THEN 6036004 -- 완료
                                       WHEN A.CompleteCHECK = 20 THEN 6036003 -- 진행중
                                       ELSE 6036001 
                                       END
                          )    
      FROM #Temp_POProgress AS A 
    
    UPDATE #Temp_POProgressSub     
       SET SMCurrStatus = (SELECT CASE WHEN A.IsStop = '1'      THEN 6036005       -- 중단    
                                       WHEN A.CompleteCHECK = 1 THEN 6036002  -- 확정(승인)  
                                       WHEN A.CompleteCHECK = 40 THEN 6036004 -- 완료
                                       WHEN A.CompleteCHECK = 20 THEN 6036003 -- 진행중
                                       ELSE 6036001 
                                       END
                          )    
       FROM #Temp_POProgressSub AS A 
    
    TRUNCATE TABLE #TMP_PROGRESSTABLE
    TRUNCATE TABLE #TCOMProgressTracking
    
  /*
     INSERT #TMP_PROGRESSTABLE     
        SELECT 1, '_TPUDelvItem'               -- 구매납품
    UNION ALL
        SELECT 2, '_TPUDelvInItem'      -- 구매입고
     
     EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_POProgress', 'POSeq', 'POSerl', ''    
     EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDPOItem', '#Temp_POProgressSub', 'POSeq', 'POSerl', ''    
    
    select * from #Temp_POProgress 
    select * from #Temp_POProgressSub
    return
     납품, 입고 금액 가져오기
    INSERT INTO #OrderTracking
    SELECT IDX_NO,
           IDOrder,
           SUM(Qty), 
           SUM(Amt),
           SUM(VAT)
    FROM #TCOMProgressTracking    
      GROUP BY IDX_NO, IDOrder 
      
    구매납품 데이터 업데이트
     UPDATE #Temp_POProgress 
       SET  DelvSeq      = B.Seq  ,
            DelvSerl     = B.Serl ,
            DelvAmt      = D.Amt  ,
            DelvVAT      = D.VAT  ,
            DelvQty      = D.Qty  ,
            DelvDate     = C.DelvDate,
            DelvExRate   = C.ExRate,
            DelvDomAmt   = E.DomAmt              -- 12.04.13 김세호 추가     
      FROM  #Temp_POProgress     AS A  
      JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No AND B.IDOrder = 1
      JOIN _TPUDelv              AS C ON C.CompanySeq = @CompanySeq AND B.Seq = C.DelvSeq
      JOIN #OrderTracking        AS D ON A.IDX_No = D.IDX_No
      JOIN _TPUDelvItem          AS E ON B.Seq = E.DelvSeq AND B.Serl = E.DelvSerl AND E.CompanySeq = @CompanySeq
   WHERE D.IDOrder = 1 -- 구매납품
   
     UPDATE #Temp_POProgress 
       SET  DelvInSeq      = B.Seq  ,
            DelvInSerl     = B.Serl ,
            DelvInAmt      = D.Amt  ,
            DelvInVAT      = D.VAT  ,
            DelvInQty      = D.Qty  ,
            DelvInDate     = C.DelvInDate,
            DelvInExRate   = C.ExRate,
            DelvInDomAmt   = E.DomAmt           -- 12.04.13 김세호 추가     
      FROM  #Temp_POProgress                AS A  
      JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No AND B.IDOrder = 2
      JOIN _TPUDelvIn            AS C ON C.CompanySeq = @CompanySeq AND B.Seq = C.DelvInSeq
      JOIN #OrderTracking        AS D ON A.IDX_No = D.IDX_No
      JOIN _TPUDelvInItem        AS E ON B.Seq = E.DelvInSeq AND B.Serl = E.DelvInSerl AND E.CompanySeq = @CompanySeq
   WHERE D.IDOrder = 2 -- 구매입고

     --*/
    
    -- 구매발주데이터 조회
    SELECT A.POSeq, 
           A.POSerl, 
           C.PODate, 
           C.PONo, 
           C.CustSeq, 
           D.CustName, 
           D.CustNo, 
           C.DeptSeq, 
           E.DeptName, 
           C.EmpSeq, 
           F.EmpName, 
           A.ItemSeq, 
           G.ItemName, 
           G.ItemNo, 
           G.Spec, 
           A.UnitSeq, 
           H.UnitName, 
           ISNULL(A.Qty,0) AS Qty, 
           ISNULL(A.Price,0) AS Price, 
           ISNULL(A.CurAmt,0) AS CurAmt, 
           ISNULL(A.CurVAT,0) AS CurVAT, 
           ISNULL(A.CurAmt,0) + ISNULL(A.CurVAT,0) AS TotCurAmt, 
           C.CurrSeq, 
           I.CurrName, 
           C.ExRate, 
           ISNULL(A.DomPrice,0) AS DomPrice, 
           ISNULL(A.DomAmt,0) AS DomAmt, 
           ISNULL(A.DomVAT,0) AS DomVAT, 
           ISNULL(A.DomAmt,0) + ISNULL(A.DomVAT,0) AS TotDomAmt, 
           A.DelvDate, 
           C.SMImpType, 
           J.MinorName AS SMImpTypeName, 
           A.Remark1, 
           A.Remark2, 
           B.SMCurrStatus, 
           K.MinorName AS SMCurrStatusName, 
           L.SMAssetGrp AS SMAssetType, 
           M.MinorName AS SMAssetTypeName, 
           A.WHSeq, 
           N.WHName, 
           '_TPUORDPOItem' AS TableName, 
           1 AS Kind
           
      FROM _TPUORDPOItem AS A 
      JOIN #Temp_POProgress AS B              ON ( B.POSeq = A.POSeq AND B.POSerl = A.POSerl ) 
      JOIN _TPUORDPO        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.POSeq ) 
      LEFT OUTER JOIN _TDACust AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDADept AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = C.EmpSeq ) 
      LEFT OUTER JOIN _TDAItem AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDACurr AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = C.CurrSeq ) 
      LEFT OUTER JOIN _TDASMinor AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = C.SMImpType ) 
      LEFT OUTER JOIN _TDASMinor AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = B.SMCurrStatus ) 
      LEFT OUTER JOIN _TDAItemAsset AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.AssetSeq = G.AssetSeq ) 
      LEFT OUTER JOIN _TDASMinor AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = L.SMAssetGrp ) 
      LEFT OUTER JOIN _TDAWH     AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.WHSeq = A.WHSeq ) 
      
   WHERE A.CompanySeq = @CompanySeq 
     AND (@WHSeq = 0 OR A.WHSeq = @WHSeq ) -- OR @WHSeq = 0 OR R.WHSeq = @WHSeq) 
     AND (@SMCurrStatus  = 0 
      OR (B.SMCurrStatus  = @SMCurrStatus AND @SMCurrStatus <> 6036006)  --OR (ZZ.SMCurrStatus  = @SMCurrStatus AND @SMCurrStatus <> 6036006)
      OR (@SMCurrStatus = 6036006 AND B.SMCurrStatus IN (6036001, 6036002, 6036003)))-- OR @SMCurrStatus = 6036006 AND ZZ.SMCurrStatus IN (6036001, 6036002, 6036003)) 
    
UNION ALL 
    -- 수입Order 데이터 조회
    SELECT A.PoSeq, 
           A.PoSerl, 
           C.PODate, 
           C.PONo, 
           C.CustSeq, 
           D.CustName, 
           D.CustNo, 
           C.DeptSeq, 
           E.DeptName, 
           C.EmpSeq, 
           F.EmpName, 
           A.ItemSeq, 
           G.ItemName, 
           G.ItemNo, 
           G.Spec, 
           A.UnitSeq, 
           H.UnitName, 
           ISNULL(A.Qty,0) AS Qty, 
           ISNULL(A.Price,0) AS Price, 
           ISNULL(A.CurAmt,0) AS CurAmt, 
           ISNULL(A.CurVAT,0) AS CurVAT, 
           ISNULL(A.CurAmt,0) + ISNULL(A.CurVAT,0) AS TotCurAmt, 
           C.CurrSeq, 
           I.CurrName, 
           C.ExRate, 
           ISNULL(A.DomPrice,0) AS DomPrice, 
           ISNULL(A.DomAmt,0) AS DomAmt, 
           ISNULL(A.DomVAT,0) AS DomVAT, 
           ISNULL(A.DomAmt,0) + ISNULL(A.DomVAT,0) AS TotDomAmt, 
           A.DelvDate, 
           C.SMImpType, 
           J.MinorName AS SMImpTypeName, 
           A.Remark1, 
           A.Remark2, 
           B.SMCurrStatus, 
           K.MinorName AS SMCurrStatusName, 
           L.SMAssetGrp AS SMAssetType, 
           M.MinorName AS SMAssetTypeName, 
           A.WHSeq, 
           N.WHName, 
           '_TPUORDPOItem' AS TableName, 
           2 AS Kind
           
      FROM _TPUORDPOItem AS A 
      JOIN #Temp_POProgressSub AS B              ON ( B.POSeq = A.POSeq AND B.POSerl = A.POSerl ) 
      JOIN _TPUORDPO           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.POSeq ) 
      LEFT OUTER JOIN _TDACust AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDADept AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp  AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = C.EmpSeq ) 
      LEFT OUTER JOIN _TDAItem AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDACurr AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CurrSeq = C.CurrSeq ) 
      LEFT OUTER JOIN _TDASMinor AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = C.SMImpType ) 
      LEFT OUTER JOIN _TDASMinor AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = B.SMCurrStatus ) 
      LEFT OUTER JOIN _TDAItemAsset AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.AssetSeq = G.AssetSeq ) 
      LEFT OUTER JOIN _TDASMinor AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = L.SMAssetGrp ) 
      LEFT OUTER JOIN _TDAWH     AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.WHSeq = A.WHSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq 
       AND (@WHSeq = 0 OR A.WHSeq = @WHSeq ) 
       AND (@SMCurrStatus  = 0 
        OR (B.SMCurrStatus  = @SMCurrStatus AND @SMCurrStatus <> 6036006)
        OR (@SMCurrStatus = 6036006 AND B.SMCurrStatus IN (6036001, 6036002, 6036003)))
    
     ORDER BY PODate
    
    RETURN    
     
GO
exec costel_SPUORDPOItemListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PODateFr>20131001</PODateFr>
    <PODateTo>20131118</PODateTo>
    <PONo />
    <DeptSeq />
    <EmpSeq />
    <SMAssetType />
    <ItemNo />
    <ItemName />
    <Spec />
    <CustSeq />
    <CustName />
    <SMCurrStatus>6036004</SMCurrStatus>
    <SMDelvInType />
    <WHSeq />
    <SMImpType />
    <DelvDateFr />
    <DelvDateTo />
    <PurGroupDeptSeq>147</PurGroupDeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019317,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016330