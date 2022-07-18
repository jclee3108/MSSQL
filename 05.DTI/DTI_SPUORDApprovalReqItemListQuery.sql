
IF OBJECT_ID('DTI_SPUORDApprovalReqItemListQuery') IS NOT NULL
    DROP PROC DTI_SPUORDApprovalReqItemListQuery
    
GO

-- v2013.06.12

-- 구매품의품목현황 (매출처,EndUser 추가) by 이재천
/*************************************************************************************************      
   FORM NAME           -       FrmPUORDApproReqItemList    
   DESCRIPTION         -       구매품의품목현황    
   CREAE DATE          -       2008.07.21  CREATE BY: 김현    
   LAST UPDATE  DATE   -       2008.07.21         UPDATE BY: 김현        
   수정일 : 2010.04.23  정동혁 (발주예정일, 발주예정경과일 추가.)  
  *************************************************************************************************/      
CREATE PROC DTI_SPUORDApprovalReqItemListQuery      
      @xmlDocument    NVARCHAR(MAX),      
      @xmlFlags       INT = 0,      
      @ServiceSeq     INT = 0,      
      @WorkingTag     NVARCHAR(10)= '',      
      @CompanySeq     INT = 1,      
      @LanguageSeq    INT = 1,      
      @UserSeq        INT = 0,      
      @PgmSeq         INT = 0      
  AS             
      DECLARE @docHandle              INT            ,      
              @ApproReqDateFr         NCHAR(8)       ,      
              @ApproReqDateTO         NCHAR(8)       ,      
              @DelvDateFr             NCHAR(8)       ,      
              @DelvDateTo             NCHAR(8)       ,      
              @PoDueDate              NCHAR(8)       ,      
              @PoDueDateTo            NCHAR(8)       ,      
              --@CustName               NVARCHAR(100)  ,    
              @CustSeq                INT            ,    
              @DeptSeq                INT            ,      
              @EmpSeq                 INT            ,      
              @ApproReqNo             NVARCHAR(12)   ,      
              @ItemName               NVARCHAR(100)  ,      
              @ItemNo                 NVARCHAR(100)  ,      
              @SMInOutType            INT            ,      
              @SMAssetType            INT            ,      
              @IsPO                   INT            ,      
              @CfmType                INT            ,      
              @SMImpType              INT            ,      
              @PJTName                NVARCHAR(60)   ,      
              @PJTNo                  NVARCHAR(40)   ,      
              @SMPOStatus             INT            ,    
              @SMCurrStatus           INT            ,    
              @POReqNo                NVARCHAR(12)   ,        
              @UMSupplyType           INT            ,        
              @TopUnitName            NVARCHAR(200)  ,        
              @TopUnitNo              NVARCHAR(200)      
        
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument            
        
      SELECT @ApproReqDateFr   = ISNULL(ApproReqDateFr, ''),      
             @ApproReqDateTo   = ISNULL(ApproReqDateTo, ''),      
             @DelvDateFr       = ISNULL(DelvDateFr    , ''),      
             @DelvDateTo       = ISNULL(DelvDateTo    , ''),      
             @PoDueDate        = ISNULL(PoDueDate     , ''),      
             @PoDueDateTo      = ISNULL(PoDueDateTo   , ''),      
             --@CustName         = ISNULL(CustName      , ''),   
             @CustSeq          = ISNULL(CustSeq       ,  0),     
             @DeptSeq          = ISNULL(DeptSeq       ,  0),      
             @EmpSeq           = ISNULL(EmpSeq        ,  0),      
             @ApproReqNo       = ISNULL(ApproReqNo    , ''),      
             @ItemName         = ISNULL(ItemName      , ''),      
             @ItemNo           = ISNULL(ItemNo        , ''),      
             @SMInOutType      = ISNULL(SMInOutType   ,  0),      
             @SMAssetType      = ISNULL(SMAssetType   ,  0),      
             @IsPO             = ISNULL(IsPO          ,  0),      
             @CfmType          = ISNULL(CfmType       ,  0),      
             @SMImpType        = ISNULL(SMImpType     ,  0),      
             @SMPOStatus       = ISNULL(SMPOStatus    ,  0),      
             @SMCurrStatus     = ISNULL(SMCurrStatus  ,  0),      
             @PJTName          = ISNULL(PJTName       , ''),                   
             @PJTNo            = ISNULL(PJTNo         , ''),      
             @POReqNo          = ISNULL(POReqNo       , ''),        
             @UMSupplyType     = ISNULL(UMSupplyType ,  0),        
             @TopUnitName      = ISNULL(TopUnitName  , ''),                            
             @TopUnitNo        = ISNULL(TopUnitNo    , '')    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
      WITH ( ApproReqDateFr     NCHAR(8)        ,      
             ApproReqDateTo     NCHAR(8)        ,      
             DelvDateFr         NCHAR(8)        ,      
             DelvDateTo         NCHAR(8)        ,      
             --CustName           NVARCHAR(100)   ,  
             CustSeq            INT             ,     
             DeptSeq            INT             ,      
             EmpSeq             INT             ,      
             ApproReqNo         NVARCHAR(12)    ,      
             ItemName           NVARCHAR(100)   ,      
             ItemNo             NVARCHAR(100)   ,      
             SMInOutType        INT             ,      
             SMAssetType        INT             ,      
             IsPO               INT             ,      
             CfmType            INT             ,      
             SMImpType          INT             ,      
             SMPOStatus         INT             ,     
             SMCurrStatus       INT             ,     
             PJTName            NVARCHAR(80)    ,      
             PJTNo              NVARCHAR(40)    ,    
             POReqNo            NVARCHAR(12)    ,        
             UMSupplyType       INT             ,        
             TopUnitName        NVARCHAR(200)   ,        
             TopUnitNo          NVARCHAR(200)   ,  
             PoDueDate          NCHAR(8)        ,  
             PoDueDateTo        NCHAR(8)  
             )      
     
        
      IF @ApproReqDateFr = '' SET @ApproReqDateFr = '10000101'      
      IF @ApproReqDateTo = '' SET @ApproReqDateTo = '99991231'      
      IF @DelvDateFr     = '' SET @DelvDateFr = '10000101'      
      IF @DelvDateTo     = '' SET @DelvDateTo = '99991231'      
        
      -- 구매요청 진행 테이블      
      CREATE TABLE #TEMP_TPUORDApprovalReqItemProg(IDX_NO INT IDENTITY, ApproReqSeq INT, ApproReqSerl INT, CompleteCHECK INT, SMCurrStatus INT, IsStop NCHAR(1), POReqNo NCHAR(12) ,Qty DECIMAL(19, 5))        
        
      INSERT INTO #TEMP_TPUORDApprovalReqItemProg(ApproReqSeq, ApproReqSerl, CompleteCHECK, SMCurrStatus, IsStop, POReqNo, Qty)        
      SELECT A.ApproReqSeq, B.ApproReqSerl, -1, 0, B.IsStop, '', B.Qty     
        FROM _TPUORDApprovalReq          AS A WITH(NOLOCK)         
             JOIN _TPUORDApprovalReqItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.ApproReqSeq = B.ApproReqSeq      
             LEFT OUTER JOIN _TPJTProject AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND B.PJTSeq = C.PJTSeq  
             LEFT OUTER JOIN _TDAItem AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSEq  
             LEFT OUTER JOIN _TPJTBOM       AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySEq          
                                                             AND B.PJTSeq = M.PJTSeq          
                                                             AND B.WBSSeq = M.BOMSerl          
             LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq          
                                                             AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM          
             LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq          
                                                             AND M1.ItemSeq = M2.ItemSeq          
             LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq          
                                                            AND B.PJTSeq = M3.PJTSeq          
                   AND M3.BOMSerl <> -1          
                                                        AND ISNULL(M3.BeforeBOMSerl,0) = 0          
                                                             AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위          
           LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq          
                                                             AND M3.ItemSeq = M4.ItemSeq          
       WHERE A.CompanySeq = @CompanySeq          
         AND (A.ApproReqDate BETWEEN @ApproReqDateFr AND @ApproReqDateTo)      
         AND (B.DelvDate     BETWEEN @DelvDateFr     AND @DelvDateTo    )      
         AND (@ApproReqNo  = '' OR A.ApproReqNo LIKE @ApproReqNo + '%' )      
         AND (@DeptSeq     =  0 OR A.DeptSeq = @DeptSeq)      
         AND (@EmpSeq      =  0 OR A.EmpSeq  = @EmpSeq)      
         AND (@PJTName = '' OR C.PJTName LIKE @PJTName + '%')  
         AND (@PJTNo = '' OR C.PJTNo LIKE @PJTNo + '%')  
         AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')  
         AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')  
         AND (@UMSupplyType = 0  OR M.UMSupplyType = @UMSupplyType)          
         AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')               
         AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')   
       
    EXEC _SCOMProgStatus @CompanySeq, '_TPUORDApprovalReqItem', 1036002, '#TEMP_TPUORDApprovalReqItemProg', 'ApproReqSeq', 'ApproReqSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'StdUnitQty', 'CurAmt', '', 'ApproReqSeq', 'ApproReqSerl', '', '_
 TPUORDApprovalReqItem', @PgmSeq     
        
      UPDATE #TEMP_TPUORDApprovalReqItemProg         
         SET SMCurrStatus = (SELECT CASE WHEN A.IsStop = '1' THEN 6036005       -- 중단        
                                         WHEN A.CompleteCHECK = 1 THEN 6036002  -- 확정(승인)      
                                         WHEN A.CompleteCHECK = 40 THEN 6036004 --완료  
                                         WHEN A.CompleteCHECK = 20 THEN 6036003 -- 진행중  
                                         ELSE 6036001 END)        
        FROM #TEMP_TPUORDApprovalReqItemProg AS A         
      -------------------      
      --발주진행여부-----      
      -------------------      
      --CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))          
              
      --CREATE TABLE #Temp_Order(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT,IsPO NCHAR(1), Qty DECIMAL(19, 5))          
            
        
      --CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))            
        
      --CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))      
        
      --INSERT #TMP_PROGRESSTABLE           
      --SELECT 1, '_TPUORDPOItem'               -- 구매발주      
            
      ---- 구매요청      
      --INSERT INTO #Temp_Order(OrderSeq, OrderSerl, IsPO, Qty)          
      --SELECT  A.ApproReqSeq, B.ApproReqSerl, '2', B.Qty          
      --  FROM _TPUORDApprovalReq     AS A WITH(NOLOCK)           
      --  JOIN _TPUORDApprovalReqItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq          
      --                                               AND A.ApproReqSeq   = B.ApproReqSeq          
      --       LEFT OUTER JOIN _TPJTProject AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND B.PJTSeq = C.PJTSeq  
      --       LEFT OUTER JOIN _TDAItem AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSEq  
      --       LEFT OUTER JOIN _TPJTBOM       AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySEq          
      --                                                       AND B.PJTSeq = M.PJTSeq          
      --                                                       AND B.WBSSeq = M.BOMSerl          
      --       LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq          
      --                                                        AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM          
      --       LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq          
      --                                                     AND M1.ItemSeq = M2.ItemSeq          
    --       LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq    
      --                                                       AND B.PJTSeq = M3.PJTSeq          
      --                                                       AND M3.BOMSerl <> -1          
      --                                                       AND ISNULL(M3.BeforeBOMSerl,0) = 0          
      --                                                       AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위          
      --       LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq          
      --                                                       AND M3.ItemSeq = M4.ItemSeq          
      -- WHERE A.CompanySeq   = @CompanySeq        
      --   AND (A.ApproReqDate BETWEEN @ApproReqDateFr AND @ApproReqDateTo)        
      --   AND (B.DelvDate     BETWEEN @DelvDateFr     AND @DelvDateTo    )        
      --   AND (@ApproReqNo  = '' OR A.ApproReqNo LIKE @ApproReqNo + '%' )        
      --   AND (@DeptSeq     =  0 OR A.DeptSeq = @DeptSeq)      
      --   AND (@EmpSeq      =  0 OR A.EmpSeq  = @EmpSeq)   
      --   AND (@PJTName = '' OR C.PJTName LIKE @PJTName + '%')  
      --   AND (@PJTNo = '' OR C.PJTNo LIKE @PJTNo + '%')  
      --   AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')  
      --   AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')  
      --   AND (@UMSupplyType = 0  OR M.UMSupplyType = @UMSupplyType)          
      --   AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')               
      --   AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')      
            
      --EXEC _SCOMProgressTracking @CompanySeq, '_TPUORDApprovalReqItem', '#Temp_Order', 'OrderSeq', 'OrderSerl', ''          
            
      --INSERT INTO #OrderTracking          
      --SELECT IDX_NO,          
      --       SUM(CASE IDOrder WHEN 1 THEN Qty     ELSE 0 END),          
      --       SUM(CASE IDOrder WHEN 1 THEN Amt     ELSE 0 END)         
      --  FROM #TCOMProgressTracking          
      -- GROUP BY IDX_No          
      
      --UPDATE #Temp_Order       
      --  SET  IsPo = '3'      
      -- FROM  #Temp_Order AS A      
      --       JOIN #OrderTracking AS B ON A.IDX_No = B.IDX_No      
      -- WHERE B.Qty <> 0    
        
      --UPDATE #Temp_Order       
      --  SET  IsPo = '1'      
      -- FROM  #Temp_Order AS A      
      --       JOIN #OrderTracking AS B ON A.IDX_No = B.IDX_No      
      -- WHERE A.Qty = B.Qty OR A.Qty < B.Qty    
      
      --UPDATE #TEMP_TPUORDApprovalReqItemProg    
      --   SET SMCurrStatus = 6036004    
      --  FROM #TEMP_TPUORDApprovalReqItemProg AS A    
      --       JOIN #Temp_Order                AS B ON A.ApproReqSeq  = B.OrderSeq    
      --                                           AND A.ApproReqSerl = B.OrderSerl    
      -- WHERE B.IsPO = '1'    
      
      --UPDATE #TEMP_TPUORDApprovalReqItemProg    
      --   SET SMCurrStatus = 6036003    
      --  FROM #TEMP_TPUORDApprovalReqItemProg AS A    
      --       JOIN #Temp_Order                AS B ON A.ApproReqSeq  = B.OrderSeq    
      --                                           AND A.ApproReqSerl = B.OrderSerl    
      -- WHERE B.IsPO = '3'    
      
      -------------------      
      --발주진행END------      
    -------------------      
      -------------------    
      --요청번호 추적 ---    
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
      SELECT '','_TPUORDPOReqItem'        
        
      INSERT #TMP_SOURCEITEM    
           ( SourceSeq    , SourceSerl    , Qty)    
   SELECT ApproReqSeq, ApproReqSerl, Qty  
     FROM #TEMP_TPUORDApprovalReqItemProg           
      --SELECT A.ApproReqSeq    , B.ApproReqSerl    , B.Qty    
      --  FROM _TPUORDApprovalReq          AS A    
      --       JOIN _TPUORDApprovalReqItem AS B ON A.CompanySeq  = B.CompanySeq    
      --                                       AND A.ApproReqSeq = B.ApproReqSeq    
      --       LEFT OUTER JOIN _TPJTProject AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND B.PJTSeq = C.PJTSeq  
      --       LEFT OUTER JOIN _TDAItem AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND B.ItemSeq = D.ItemSEq  
      --       LEFT OUTER JOIN _TPJTBOM       AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySEq          
      --                                                       AND B.PJTSeq = M.PJTSeq          
      --                                                       AND B.WBSSeq = M.BOMSerl          
      --       LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq          
      --                                                       AND B.PJTSeq = M1.PJTSeq AND M1.BOMSerl <> -1 AND M.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM          
      --       LEFT OUTER JOIN _TDAItem       AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq          
      --                                                       AND M1.ItemSeq = M2.ItemSeq          
      --       LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq          
      --                                                       AND B.PJTSeq = M3.PJTSeq          
      --                                                       AND M3.BOMSerl <> -1          
      --                                                       AND ISNULL(M3.BeforeBOMSerl,0) = 0          
      --                                                       AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위          
      --       LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq          
      --                                                       AND M3.ItemSeq = M4.ItemSeq     
      -- WHERE A.CompanySeq = @CompanySeq    
      --   AND (A.ApproReqDate BETWEEN @ApproReqDateFr AND @ApproReqDateTo)      
      --   AND (B.DelvDate     BETWEEN @DelvDateFr     AND @DelvDateTo    )      
      --   AND (@ApproReqNo  = '' OR A.ApproReqNo LIKE @ApproReqNo + '%' )      
      --   AND (@DeptSeq     =  0 OR A.DeptSeq = @DeptSeq)     
      --   AND (@EmpSeq      =  0 OR A.EmpSeq  = @EmpSeq )   
      --   AND (@PJTName = '' OR C.PJTName LIKE @PJTName + '%')  
      --   AND (@PJTNo = '' OR C.PJTNo LIKE @PJTNo + '%')  
      --   AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')  
      --   AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')  
      --   AND (@UMSupplyType = 0  OR M.UMSupplyType = @UMSupplyType)          
      --   AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')               
      --   AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')     
      
      EXEC _SCOMSourceTracking @CompanySeq, '_TPUORDApprovalReqItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''              
      
      --UPDATE #TEMP_TPUORDApprovalReqItemProg    
      --   SET POReqNo = ISNULL(D.POReqNo, '')     
      --  FROM #TEMP_TPUORDApprovalReqItemProg  AS A    
      --       JOIN #TMP_SOURCEITEM             AS B ON A.ApproReqSeq = B.SourceSeq    
      --       JOIN #TCOMSourceTracking         AS C ON B.IDX_NO = C.IDX_NO    
      --       LEFT OUTER JOIN _TPUORDPOReq     AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq    
      --                                                         AND C.Seq        = D.POReqSeq    
      -- WHERE (@POReqNo     = '' OR D.POReqNo LIKE @POReqNo + '%')    
    -------------------    
      --요청번호 추적 끝  ----    
      -------------------       
   CREATE INDEX IX_#TEMP_TPUORDApprovalReqItemProg ON #TEMP_TPUORDApprovalReqItemProg (ApproReqSeq, ApproReqSerl) --                                
   CREATE INDEX IX_#TMP_SOURCEITEM ON #TMP_SOURCEITEM (SourceSeq, SourceSerl) --                                
   CREATE INDEX IX_#TCOMSourceTracking ON #TMP_SOURCEITEM (IDX_NO) --                                
           
      SELECT A.ApproReqSeq    , A.ApproReqSerl    , A.ItemSeq        , A.MakerSeq    , A.UnitSeq    ,      
             A.Qty            ,  A.ExRate         ,      
             ISNULL(A.Price, 0) AS Price          ,       
             ISNULL(A.CurAmt,0) AS CurAmt         ,       
             ISNULL(A.CurVAT,0) AS CurVAT         ,       
             ISNULL(A.CurAmt + A.CurVAT, 0) AS TotCurAmt,      
             ISNULL(A.DomPrice, 0) AS DomPrice   ,       
             ISNULL(A.DomAmt  , 0) AS DomAmt     ,       
             ISNULL(A.DomVAT  , 0) AS DomVAT     ,       
             ISNULL(A.DomAmt + A.DomVAT, 0) AS TotDomAmt,      
             A.CustSeq        , A.Remark     ,      
             A.CurrSeq        , A.StdUnitSeq     , A.StdUnitQty  , A.SMImpType  ,      
             B.DeptSeq        , B.EmpSeq          , B.ApproReqDate   , C.ItemName    , C.ItemNo     ,       
             C.Spec           , D.UnitName        , E.CurrName       , F.CustName    , (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.MakerSeq) AS MakerName,      
             A.DelvDate       , B.ApproReqNo      , G.EmpName        , H.DeptName    , Z.SMCurrStatus,      
             I.PJTName        , I.PJTNo           , J.WBSSeq         , J.WBSName     , I.PJTSeq,      
             --ISNULL(Z.POReqNo, '')  AS POReqNo,    
             ISNULL(Q.POReqNo, '') AS POReqNo,  
             --ISNULL(X.IsPO, '')     AS IsPO,      
             K.SMAssetGrp           AS SMAssetType,      
             K.AssetName            AS SMAssetTypeName,    
             B.IsPJT                AS IsPJT,    
             ISNULL(A.IsStop, '')   AS IsStop,    
               
             DD.UnitName            AS STDUnitName,    
             A.StopRemark           AS StopRemark ,    
             A.WHSeq                AS WHSeq      ,    
             L.WHName               AS WHName     ,      
             M2.ItemNo AS UpperUnitNo, M2.ItemName AS UpperUnitName,       
             M4.ItemName AS TopUnitName, M4.ItemNo AS TopUnitNo,    
             M.UMMatQuality AS UMMatQuality,    
             M5.MinorName AS UMMatQualityName  ,  
             R.CustName AS SalesCustName,
             S.CustName AS EndUserName,
             CONVERT(NCHAR(8), DATEADD(D, (ISNULL(BP.PreLeadTime,0)+ISNULL(BP.LeadTime,0)+ISNULL(BP.PostLeadTime,0)) * (-1), A.DelvDate), 112)   AS PoDueDate,     -- 발주예정일 (납기요청일로부터 조달일자 이전일)
             A.LastDateTime AS LastDate
  
        INTO #TPUORDApprovalReqItem  
        FROM _TPUORDApprovalReqItem               AS A WITH(NOLOCK)                 
             JOIN _TPUORDApprovalReq              AS B WITH(NOLOCK) ON A.CompanySeq   = B.CompanySeq       
                                                       AND A.ApproReqSeq  = B.ApproReqSeq                 
             JOIN #TEMP_TPUORDApprovalReqItemProg AS Z              ON A.ApproReqSeq  = Z.ApproReqSeq       
                                                                   AND A.ApproReqSerl = Z.ApproReqSerl     
             LEFT OUTER JOIN #TMP_SOURCEITEM        AS X     ON Z.ApproReqSeq = X.SourceSeq  
                   AND Z.ApproReqSerl = X.SourceSerl  
             LEFT OUTER JOIN #TCOMSourceTracking    AS Y     ON X.IDX_NO  = Y.IDX_NO  
             LEFT OUTER JOIN _TPUORDPOReq   AS Q     ON Q.CompanySeq = @CompanySEq  
                   AND Y.Seq   = Q.POReqSeq                                                                  
  --JOIN #Temp_Order                     AS X              ON A.ApproReqSeq  = X.OrderSeq         
             --                                                      AND A.ApproReqSerl = X.OrderSerl      
             LEFT OUTER JOIN _TDAItem             AS C WITH(NOLOCK) ON A.CompanySeq   = C.CompanySeq       
                                                                 AND A.ItemSeq      = C.ItemSeq    
             LEFT OUTER JOIN _TDAUnit             AS D WITH(NOLOCK) ON A.CompanySeq   = D.CompanySeq       
                          AND A.UnitSeq      = D.UnitSeq      
             LEFT OUTER JOIN _TDAUnit             AS DD WITH(NOLOCK) ON A.CompanySeq  = DD.CompanySeq       
                                                                    AND A.StdUnitSeq  = DD.UnitSeq      
             LEFT OUTER JOIN _TDACurr             AS E WITH(NOLOCK) ON A.CompanySeq   = E.CompanySeq       
                                                                   AND A.CurrSeq      = E.CurrSeq      
             LEFT OUTER JOIN _TDACust             AS F WITH(NOLOCK) ON A.CompanySeq   = F.CompanySeq       
                                                                   AND A.CustSeq      = F.CustSeq      
             LEFT OUTER JOIN _TDAEmp              AS G WITH(NOLOCK) ON B.CompanySeq   = G.CompanySeq       
                                                                   AND B.EmpSeq       = G.EmpSeq      
             LEFT OUTER JOIN _TDADept             AS H WITH(NOLOCK) ON B.CompanySeq   = H.CompanySeq       
                                                                   AND B.DeptSeq      = H.DeptSeq      
             LEFT OUTER JOIN _TPJTProject         AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq        
                                                                   AND A.PJTSeq       = I.PJTSeq      
             LEFT OUTER JOIN _TPJTWBS             AS J WITH(NOLOCK) ON I.CompanySeq   = J.CompanySeq       
                                                                   AND I.PJTSeq       = J.PJTSeq       
                                                                   AND A.WBSSeq       = J.WBSSeq      
             LEFT OUTER JOIN _TDAItemAsset        AS K WITH(NOLOCK) ON C.CompanySeq   = K.CompanySeq       
                                                                   AND C.AssetSeq     = K.AssetSeq       
             LEFT OUTER JOIN _TDAWH               AS L WITH(NOLOCK) ON A.CompanySeq   = L.CompanySeq       
                                                                   AND A.WHSeq        = L.WHSeq      
             LEFT OUTER JOIN _TPJTBOM       AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySEq        
                                                             AND A.PJTSeq = M.PJTSeq        
                                                             AND A.WBSSeq = M.BOMSerl        
             LEFT OUTER JOIN _TPJTBOM       AS M1 WITH(NOLOCK) ON A.CompanySeq = M1.CompanySeq        
                                                             AND A.PJTSeq = M1.PJTSeq     
                                                             AND M1.BOMSerl <> -1 AND M.UpperBOMSerl = M1.BOMSerl AND ISNULL(M1.BeforeBOMSerl,0) = 0 -- 상위 BOM        
             LEFT OUTER JOIN _TDAItem      AS M2 WITH(NOLOCK) ON A.CompanySEq = M2.CompanySeq        
                                                     AND M1.ItemSeq = M2.ItemSeq        
             LEFT OUTER JOIN _TPJTBOM       AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq        
                                                             AND A.PJTSeq = M3.PJTSeq        
                                                             AND M3.BOMSerl <> -1   
                                                             AND ISNULL(M3.BeforeBOMSerl,0) = 0        
                                                             AND SUBSTRING(M1.TreeCode,1,6) = M3.TreeCode     -- 최상위        
             LEFT OUTER JOIN _TDAItem       AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq        
              AND M3.ItemSeq = M4.ItemSeq        
             LEFT OUTER JOIN _TDAUMinor     AS M5 WITH(NOLOCK) ON A.CompanySeq = M5.CompanySeq    
                                                              AND M.UMMatQuality = M5.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor     AS N WITH(NOLOCK) ON A.CompanySeq = N.CompanySeq        
                                                             AND M.UMSupplyType = N.MinorSeq        
           LEFT OUTER JOIN _TDAUMinor     AS O WITH(NOLOCK) ON A.CompanySeq = O.CompanySeq        
                                                             AND M.UMRegType = O.MinorSeq        
             LEFT OUTER JOIN _TDAEmp        AS P WITH(NOLOCK) ON A.CompanySeq = P.CompanySeq        
                                                             AND A.StopEmpSeq = P.EmpSeq        
             LEFT OUTER JOIN _TPUBASEBuyPriceItem AS BP WITH(NOLOCK) ON A.CompanySeq = BP.CompanySeq  
                                                                    AND A.ItemSeq    = BP.ItemSeq  
                                                                    AND A.CustSeq    = BP.CustSeq  
                                                                    AND A.CurrSeq    = BP.CurrSeq  
                                                                    AND A.UnitSeq    = BP.UnitSeq  
                                                                    AND A.DelvDate   BETWEEN BP.StartDate AND BP.EndDate  
            LEFT OUTER JOIN _TDACust      AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = A.Memo1 )
            LEFT OUTER JOIN _TDACust      AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.CustSeq = A.Memo2 ) 
            
       WHERE A.CompanySeq   = @CompanySeq      
         AND (@PJTName  = '' OR I.PJTName  LIKE @PJTName + '%')      
         AND (@PJTNo    = '' OR I.PJTNo    LIKE @PJTNo   + '%')      
         AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')      
         AND (@ItemNo   = '' OR C.ItemNo   LIKE @ItemNo + '%')      
         --AND (@CustName = '' OR F.CustName LIKE @CustName + '%')    
         AND (@CustSeq     = 0  OR A.CustSeq  = @CustSeq)    
         AND (@ApproReqNo  = '' OR B.ApproReqNo LIKE @ApproReqNo + '%' )      
         AND (@SMImpType   = 0  OR A.SMImpType = @SMImpType)      
         AND (@SMAssetType = 0  OR C.AssetSeq = @SMAssetType)      
         --AND (@SMPOStatus  = 0  OR RIGHT(@SMPOStatus, 1) = X.IsPO)      
         AND (@POReqNo     = '' OR Q.POReqNo LIKE @POReqNo + '%')    
         AND (@SMCurrStatus= 0  OR Z.SMCurrStatus = @SMCurrStatus OR (@SMCurrStatus= 6036006 AND Z.SMCurrStatus IN (6036001, 6036002, 6036003)) )    
         AND (@UMSupplyType = 0  OR M.UMSupplyType = @UMSupplyType)        
         AND (@TopUnitName  = '' OR M4.ItemName LIKE @TopUnitName + '%')             
         AND (@TopUnitNo    = '' OR M4.ItemNo   LIKE @TopUnitNo + '%')        
      
       SELECT A.*  
             ,CASE WHEN A.SMCurrStatus NOT IN (6036005,6036004) THEN DATEDIFF(D, A.PoDueDate, GETDATE()) END   AS PoDueOverDays     -- 발주예정경과일 (완료(중단)되지 않은 건만 계산)  
        FROM #TPUORDApprovalReqItem       AS A   
       WHERE (@PoDueDate      = '' OR A.PoDueDate     >= @PoDueDate)  
         AND (@PoDueDateTo    = '' OR A.PoDueDate     <= @PoDueDateTo)  
     
     
        
        
  RETURN