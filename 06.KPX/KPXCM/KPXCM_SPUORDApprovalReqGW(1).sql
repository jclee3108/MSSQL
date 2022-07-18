IF OBJECT_ID('KPXCM_SPUORDApprovalReqGW') IS NOT NULL
    DROP PROC KPXCM_SPUORDApprovalReqGW
GO
/************************************************************
 설  명 - 데이터-구매품의전자결재_KPXCM : 
 작성일 - 20150705
 작성자 - 박상준
 수정자 - 
************************************************************/
CREATE PROC dbo.KPXCM_SPUORDApprovalReqGW                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    DECLARE  @docHandle         INT
            ,@ApproReqSeq       INT
            ,@TotDomAmt         DECIMAL(19,5)
            ,@TotCurAmt         DECIMAL(19,5)
            ,@Date              NCHAR(8)
            ,@DateFr            NCHAR(8)
            ,@DateTo            NCHAR(8)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT  @ApproReqSeq  = ApproReqSeq   
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
                ApproReqSeq   INT 
           )
/*=================================================================================================
=================================================================================================*/
  --1758,1759
SELECT @Date = ApproReqDate
FROM _TPUORDApprovalReq WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq
SELECT  @DateTo = CONVERT(NCHAR(8),DATEADD(DD,-1,@Date),112)
       ,@DateFr = CONVERT(NCHAR(8),DATEADD(MM,-3,@Date),112)

-- 대상품목 
CREATE TABLE #GetInOutItem
( 
    ItemSeq INT, 
    ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- 품목소분류
    ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- 품목중분류
    ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- 품목대분류
)
INSERT INTO #GetInOutItem(ItemSeq)
SELECT ItemSeq
FROM _TPUORDApprovalReqItem
WHERE CompanySeq = @CompanySeq
AND ApproReqSeq = @ApproReqSeq

-- 입출고
CREATE TABLE #GetInOutStock
(
    WHSeq           INT,
    FunctionWHSeq   INT,
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
-- 상세입출고내역 
CREATE TABLE #TLGInOutStock  
(  
    InOutType INT,  
    InOutSeq  INT,  
    InOutSerl INT,  
    DataKind  INT,  
    InOutSubSerl  INT,  
    InOut INT,  
    InOutDate NCHAR(8),  
    WHSeq INT,  
    FunctionWHSeq INT,  
    ItemSeq INT,  
    UnitSeq INT,  
    Qty DECIMAL(19,5),  
    StdQty DECIMAL(19,5),
    InOutKind INT,
    InOutDetailKind INT 
)

    -- 창고재고 가져오기
    EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- 법인코드
                           ,@BizUnit      = 0                   -- 사업부문
                           ,@FactUnit     = 0                   -- 생산사업장
                           ,@DateFr       = @DateFr             -- 조회기간Fr
                           ,@DateTo       = @DateTo             -- 조회기간To
                           ,@WHSeq        = 0                   -- 창고지정
                           ,@SMWHKind     = 0                   -- 창고구분 
                           ,@CustSeq      = 0                   -- 수탁거래처
                           ,@IsTrustCust  = ''                  -- 수탁여부
                           ,@IsSubDisplay = 0                   -- 기능창고 조회
                           ,@IsUnitQry    = 0                   -- 단위별 조회
                           ,@QryType      = 'S'                 -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                           ,@MngDeptSeq   = 0                   
                           ,@IsUseDetail  = '1'

  SELECT  @CompanySeq                 AS CompanySeq
         ,ItemSeq
         ,SUM(ISNULL(STDOutQty,0))    AS OutQty
    INTO #OutQty
    FROM #GetInOutStock
GROUP BY ItemSeq

TRUNCATE TABLE #GetInOutStock
TRUNCATE TABLE #TLGInOutStock

    -- 창고재고 가져오기
    EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq         -- 법인코드
                           ,@BizUnit      = 0                   -- 사업부문
                           ,@FactUnit     = 0                   -- 생산사업장
                           ,@DateFr       = @Date               -- 조회기간Fr
                           ,@DateTo       = @Date               -- 조회기간To
                           ,@WHSeq        = 0                   -- 창고지정
                           ,@SMWHKind     = 0                   -- 창고구분 
                           ,@CustSeq      = 0                   -- 수탁거래처
                           ,@IsTrustCust  = ''                  -- 수탁여부
                           ,@IsSubDisplay = 0                   -- 기능창고 조회
                           ,@IsUnitQry    = 0                   -- 단위별 조회
                           ,@QryType      = 'S'                 -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                           ,@MngDeptSeq   = 0                   
                           ,@IsUseDetail  = '1'

  SELECT  @CompanySeq                   AS CompanySeq
         ,ItemSeq
         ,SUM(ISNULL(STDStockQty,0))    AS StockQty
    INTO #StockQty
    FROM #GetInOutStock 
GROUP BY ItemSeq



/*=================================================================================================
=================================================================================================*/
    
    
    
    SELECT ROW_NUMBER() OVER( ORDER BY B.ApproReqSeq, B.ApproReqSerl ) AS Num 
           ,ISNULL(H.ItemName       ,'')       AS ItemName
           ,ISNULL(H.ItemNo         ,'')       AS ItemNo
           ,ISNULL(H.Spec           ,'')       AS Spec
           ,ISNULL(B.Memo1          ,'')       AS PurPose              --용도
           ,ISNULL(B.Memo5          , 0)       AS PackingSeq           --포장구분
           ,ISNULL(I.MinorName      ,'')       AS PackingName          --포장구분
           ,ISNULL(M.Price          , 0)       AS CurentPrice          --종전가
           ,ISNULL(B.Memo7          , 0)       AS FirstPrice           --1차견적가
           ,(CASE WHEN ISNULL(M.Price, 0) = 0
                 THEN ISNULL(B.Memo7, 0)
                 ELSE ISNULL(M.Price, 0)
            END)-ISNULL(B.Price, 0)            AS DiffPrice --단가차이        => ABS???
           ,CASE WHEN ISNULL(M.Price, 0)=0
                 THEN 0
                 ELSE ((CASE WHEN ISNULL(M.Price, 0)=0
                             THEN ISNULL(B.Memo7, 0)
                             ELSE ISNULL(M.Price, 0)
                        END)-ISNULL(B.Price, 0))/ISNULL(M.Price, 0)
            END AS TransRate               --변동율(%)
           ,ISNULL(B.Qty            , 0)       AS Qty                --수량
           ,ISNULL(B.DelvDate       ,'')       AS DelvDate           --납기요청일
           ,ISNULL(J.TotCurAmt      , 0)       AS TotCurAmt          --구매금액
           ,ISNULL(N.OutQty         , 0)       AS OutQty             --평균사용량
           ,ISNULL(O.StockQty       , 0)       AS StockQty           --현재고량

      FROM _TPUORDApprovalReq                  AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TPUORDApprovalReqItem              AS B WITH(NOLOCK)ON A.CompanySeq    = B.CompanySeq
                                                                          AND A.ApproReqSeq   = B.ApproReqSeq
      LEFT OUTER JOIN _TDADept                            AS C WITH(NOLOCK)ON A.CompanySeq    = C.CompanySeq
                                                                          AND A.DeptSeq       = C.DeptSeq
      LEFT OUTER JOIN _TDACurr                            AS D WITH(NOLOCK)ON B.CompanySeq    = D.CompanySeq
                                                                          AND B.CurrSeq       = D.CurrSeq
      LEFT OUTER JOIN _TDAEmp                             AS E WITH(NOLOCK)ON A.CompanySeq    = E.CompanySeq
                                                                          AND A.EmpSeq        = E.EmpSeq
      LEFT OUTER JOIN _TDACust                            AS F WITH(NOLOCK)ON B.CompanySeq    = F.CompanySeq
                                                                          AND B.CustSeq       = F.CustSeq
      LEFT OUTER JOIN _TDACust                            AS G WITH(NOLOCK)ON B.CompanySeq    = G.CompanySeq
                                                                          AND B.MakerSeq      = G.CustSeq
      LEFT OUTER JOIN _TDAItem                            AS H WITH(NOLOCK)ON B.CompanySeq    = H.CompanySeq
                                                                          AND B.ItemSeq       = H.ItemSeq
      LEFT OUTER JOIN _TDAUMinor                          AS I WITH(NOLOCK)ON B.CompanySeq    = I.CompanySeq
                                                                          AND B.Memo5         = I.MinorSeq
      LEFT OUTER JOIN (
                          SELECT  CompanySeq
                                 ,ApproReqSeq
                                 ,MAX(UnitSeq)            AS UnitSeq
                                 ,SUM(DomAmt + DomVAT)    AS TotDomAmt
                                 ,SUM(CurAmt + CurVAT)    AS TotCurAmt
                            FROM _TPUORDApprovalReqItem
                           WHERE CompanySeq  = @CompanySeq
                             AND ApproReqSeq = @ApproReqSeq
                        GROUP BY CompanySeq,ApproReqSeq
                      )                                   AS J             ON A.CompanySeq    = J.CompanySeq
                                                                          AND A.ApproReqSeq   = J.ApproReqSeq
      LEFT OUTER JOIN _TDAUnit                            AS K WITH(NOLOCK)ON J.CompanySeq    = K.CompanySeq
                                                                          AND J.UnitSeq       = K.UnitSeq
      LEFT OUTER JOIN (
                          SELECT X.CompanySeq,MAX(X.DelvInSeq) AS DelvInSeq,X.DelvInSerl,X.ItemSeq
                            FROM _TPUDelvIn       AS Z
                            JOIN _TPUDelvInItem   AS X WITH(NOLOCK)ON Z.CompanySeq = X.CompanySeq
                                                                  AND Z.DelvInSeq  = X.DelvInSeq
                           WHERE Z.CompanySeq = @CompanySeq
                             AND Z.DelvInDate <= (SELECT ApproReqDate     FROM _TPUORDApprovalReq     WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)
                             AND X.ItemSeq    IN (SELECT DISTINCT ItemSeq FROM _TPUORDApprovalReqItem WHERE CompanySeq = @CompanySeq AND ApproReqSeq = @ApproReqSeq)      --통화같은건진 나중에 확인하기
                        GROUP BY X.CompanySeq,X.DelvInSerl,X.ItemSeq
                      )                                   AS L             ON B.CompanySeq    = L.CompanySeq
                                                                          AND B.ItemSeq       = L.ItemSeq
      LEFT OUTER JOIN _TPUDelvInItem                      AS M WITH(NOLOCK)ON L.CompanySeq    = M.CompanySeq
                                                                          AND L.DelvInSeq     = M.DelvInSeq
                                                                          AND L.DelvInSerl    = M.DelvInSerl
      LEFT OUTER JOIN #OutQty                             AS N WITH(NOLOCK)ON B.CompanySeq    = N.CompanySeq
                                                                          AND B.ItemSeq       = N.ItemSeq
      LEFT OUTER JOIN #StockQty                           AS O WITH(NOLOCK)ON B.CompanySeq    = O.CompanySeq
                                                                          AND B.ItemSeq       = O.ItemSeq
                                                                          
     WHERE A.CompanySeq    = @CompanySeq
       AND A.ApproReqSeq   = @ApproReqSeq


/*=================================================================================================
=================================================================================================*/    
RETURN
go

EXEC _SCOMGroupWarePrint 2, 1, 1, 1025093, 'ApprovalReq_CM', '13', ''