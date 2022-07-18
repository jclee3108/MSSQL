IF OBJECT_ID('KPXCM_SLGWHStockListDynamicQuery') IS NOT NULL 
    DROP PROC KPXCM_SLGWHStockListDynamicQuery
GO 

-- v2013.05.02 
  -- 창고재고조회-조회, 2012.05.17 by 김철웅 
 CREATE PROC KPXCM_SLGWHStockListDynamicQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
     DECLARE   @docHandle          INT,
               @BizUnit            INT,
               @AccUnit            INT,
               @FactUnit           INT,
               @WHSeq              INT,
               @FunctionWHSeq      INT,
               @SMWHKind           INT, -- 창고구분 
               @DateFr             NCHAR(8),
               @DateTo             NCHAR(8),
               @AssetSeq           INT,
               @ItemName           NVARCHAR(200),
               @ItemNo             NVARCHAR(100),
               @Spec               NVARCHAR(100),
               @ItemSeq            INT,
               @ConvUnitSeq        INT,
               @IsUnitQry          NCHAR(1), -- 단위별조회 
               @IsSubDisplay       NCHAR(1),
               @QryType            NCHAR(1), -- 조회기준 
               @IsSetItem          NCHAR(1),
               @IsTrustCust        NCHAR(1),
               @CustSeq            INT,
               @WHCustSeq          INT, -- ?? 
               @MngDeptSeq         INT,
               @ItemClassLSeq      INT,
               @ItemClassMSeq      INT,
               @ItemClassSSeq      INT,
               @IsZeroQty          NCHAR(1)
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @BizUnit            = ISNULL(BizUnit,0),
             @FactUnit           = ISNULL(FactUnit,0),
             @DateFr             = ISNULL(DateFr,''),
             @DateTo             = ISNULL(DateTo,''),
             @WHSeq              = ISNULL(WHSeq,0),
             @FunctionWHSeq      = ISNULL(FunctionWHSeq,0),
             @SMWHKind           = ISNULL(SMWHKind,0),
             @AssetSeq           = ISNULL(AssetSeq,0),
             @ItemName           = ISNULL(ItemName,''),
             @ItemNo             = ISNULL(ItemNo,''),
             @Spec               = ISNULL(Spec,''),
             @ItemSeq            = ISNULL(ItemSeq,0),
             @CustSeq            = ISNULL(CustSeq,0),
             @ConvUnitSeq        = ISNULL(ConvUnitSeq,0),
             @IsUnitQry          = ISNULL(IsUnitQry,''),
             @IsSubDisplay       = ISNULL(IsSubDisplay,''),
             @QryType            = ISNULL(QryType,''),
             @IsSetItem          = ISNULL(IsSetItem, ''),
             @IsTrustCust        = ISNULL(IsTrustCust, ''),
             @WHCustSeq          = ISNULL(WHCustSeq,0),
             @MngDeptSeq         = ISNULL(MngDeptSeq,0),
             @ItemClassLSeq      = ISNULL(ItemClassLSeq,0),
             @ItemClassMSeq      = ISNULL(ItemClassMSeq,0),
             @ItemClassSSeq      = ISNULL(ItemClassSSeq,0),
             @IsZeroQty          = ISNULL(IsZeroQty,'0')
             
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (BizUnit        INT,
             FactUnit       INT,
             DateFr         NCHAR(8),
             DateTo         NCHAR(8),
             WHSeq          INT,
             FunctionWHSeq  INT,
             SMWHKind       INT,
             AssetSeq       INT,
             ItemName       NVARCHAR(200),
             ItemNo         NVARCHAR(100),
             Spec           NVARCHAR(100),
             ItemSeq        INT,
             CustSeq        INT,
             ConvUnitSeq    INT,
             IsUnitQry      NCHAR(1),
             IsSubDisplay   NCHAR(1),
             QryType        NCHAR(1),
             IsSetItem      NCHAR(1),
             IsTrustCust    NCHAR(1),
             WHCustSeq      INT,
             MngDeptSeq     INT,
             ItemClassLSeq  INT,
             ItemClassMSeq  INT,
             ItemClassSSeq  INT,
             IsZeroQty      NCHAR(1)
  )   
      SELECT  @BizUnit            = ISNULL(@BizUnit,0),
             @FactUnit           = ISNULL(@FactUnit,0),
             @DateFr             = ISNULL(@DateFr,''),
             @DateTo             = ISNULL(@DateTo,''),
             @WHSeq              = ISNULL(@WHSeq,0),
             @FunctionWHSeq      = ISNULL(@FunctionWHSeq,0),
             @SMWHKind           = ISNULL(@SMWHKind,0),
             @AssetSeq           = ISNULL(@AssetSeq,0),
             @ItemName           = ISNULL(@ItemName,''),
             @ItemNo             = ISNULL(@ItemNo,''),
             @Spec               = ISNULL(@Spec,''),
             @ItemSeq            = ISNULL(@ItemSeq,0),
             @CustSeq            = ISNULL(@CustSeq,0),
             @ConvUnitSeq        = ISNULL(@ConvUnitSeq,0),
             @IsUnitQry          = ISNULL(@IsUnitQry,''),
             @IsSubDisplay       = ISNULL(@IsSubDisplay,''),
             @QryType            = ISNULL(@QryType,''),
             @IsSetItem          = ISNULL(@IsSetItem,''),
             @IsTrustCust        = ISNULL(@IsTrustCust,''),
             @WHCustSeq          = ISNULL(@WHCustSeq,0),
             @MngDeptSeq         = ISNULL(@MngDeptSeq,0),
             @ItemClassLSeq      = ISNULL(@ItemClassLSeq,0),
             @ItemClassMSeq      = ISNULL(@ItemClassMSeq,0),
             @ItemClassSSeq      = ISNULL(@ItemClassSSeq,0)  
      DECLARE @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT             
     
     /*
     select * from _TComEnv where CompanySeq = 1 and EnvSeq  = 5521 
     */
     -- 환경설정-활동기준원가 
     SELECT @ItemPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --자재단가계산단위                       
     SELECT @GoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --상품단가계산단위                       
     SELECT @FGoodPriceUnit = EnvValue FROM _TCOMEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --제품단가계산단위                       
     
     -- 구매/자재수량소수점자리수구하기
     --SELECT @EnvMatQty = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 5
     
     -- 사업부문등록 : 사업부문 & 회계단위 
     SELECT @AccUnit = ISNULL(AccUnit, 0) FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit
     
     -- 대상품목 
     CREATE TABLE #GetInOutItem
     ( 
         ItemSeq INT, 
         ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- 품목소분류
         ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- 품목중분류
         ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- 품목대분류
     )
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
     
     -- 다이나믹 Title 
     CREATE TABLE #Temp_InOutTitle( ColIDX INT IDENTITY(0, 1), Title NVARCHAR(100), TitleSeq INT, Title2 NVARCHAR(200), TitleSeq2 INT )      
     
     -- 고정 Column  
     CREATE TABLE #Temp_FixCol      
     (
         RowIDX INT IDENTITY(0, 1),    
         
         WHKindName NVARCHAR(200), WHName NVARCHAR(100), FunctionWHName NVARCHAR(100), ItemName NVARCHAR(200), ItemNo NVARCHAR(100),
   
         Spec NVARCHAR(100), UnitName NVARCHAR(30), AssetName NVARCHAR(100), PrevQty DECIMAL(19,5), InQty DECIMAL(19,5),
         
         OutQty DECIMAL(19,5), StockQty DECIMAL(19,5), SalesUnitQty DECIMAL(19,5), SalesUnitName NVARCHAR(100), SalesUnitSeq INT, 
         
         WHSeq INT, FunctionWHSeq INT, ItemSeq INT, UnitSeq INT, AssetSeq INT, 
         
         ItemClassName NVARCHAR(200), StockAmt DECIMAL(19,5), IsUnitQry NCHAR(1),
                
         ItemClassSSeq INT, ItemClassSName NVARCHAR(200), 
         ItemClassMSeq INT, ItemClassMName NVARCHAR(200), 
         ItemClassLSeq INT, ItemClassLName NVARCHAR(200), 
                
         SMPurKindName NVARCHAR(200), CustSeq INT, CustName NVARCHAR(100), DateFr NCHAR(8), DateTo NCHAR(8),
         SafetyQty DECIMAL(19, 5)
     )
     
     -- 다이나믹 Column 
     CREATE TABLE #Temp_InOutStock( ItemSeq INT, UnitSeq INT, WHSeq INT, InOutType INT, InOut INT, Qty DECIMAL(19,5), IsUnitQry NCHAR(1), InOutKind INT )      
     
     -- 대상품목 담기 
     INSERT INTO #GetInOutItem
     ( 
         ItemSeq, 
         ItemClassSSeq, ItemClassSName, -- 품목소분류
         ItemClassMSeq, ItemClassMName, -- 품목중분류
         ItemClassLSeq, ItemClassLName  -- 품목대분류
     )
     SELECT DISTINCT A.ItemSeq,
            C.MinorSeq AS ItemClassSSeq, C.MinorName AS ItemClassSName, -- '품목소분류' 
         E.MinorSeq AS ItemClassMSeq, E.MinorName AS ItemClassMName, -- '품목중분류' 
         G.MinorSeq AS ItemClassLSeq, G.MinorName AS ItemClassLName  -- '품목대분류' 
       FROM _TDAItem                     AS A WITH (NOLOCK)
       JOIN _TDAItemSales                AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.ItemSeq = H.ItemSeq 
       JOIN _TDAItemAsset                AS I WITH (NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.AssetSeq = I.AssetSeq -- 품목자산분류 
       
       -- 소분류 
       LEFT OUTER JOIN _TDAItemClass     AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) AND A.CompanySeq = B.CompanySeq )
       LEFT OUTER JOIN _TDAUMinor  AS C WITH(NOLOCK) ON ( B.UMItemClass = C.MinorSeq AND B.CompanySeq = C.CompanySeq AND C.IsUse = '1' )
       LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( C.MinorSeq = D.MinorSeq AND D.Serl in (1001,2001) AND C.MajorSeq = D.MajorSeq AND C.CompanySeq = D.CompanySeq )
       -- 중분류 
       LEFT OUTER JOIN _TDAUMinor  AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq AND E.IsUse = '1' )
       LEFT OUTER JOIN _TDAUMinorValue AS F WITH(NOLOCK) ON ( E.MinorSeq = F.MinorSeq AND F.Serl = 2001 AND E.MajorSeq = F.MajorSeq AND E.CompanySeq = F.CompanySeq )
       -- 대분류 
       LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( F.ValueSeq = G.MinorSeq AND F.CompanySeq = G.CompanySeq AND G.IsUse = '1' )
       WHERE A.CompanySeq = @CompanySeq
        AND ( @AssetSeq = 0  OR A.AssetSeq = @AssetSeq )
        AND ( @ItemName = '' OR A.ItemName LIKE @ItemName + '%' )
        AND ( @ItemNo   = '' OR A.ItemNo   LIKE @ItemNo + '%' )
        AND ( @Spec     = '' OR A.Spec     LIKE @Spec + '%' )
        AND ( @ItemSeq  = 0  OR A.ItemSeq = @ItemSeq )
        AND ( @QryType <> 'B' OR (@QryType = 'B' AND H.IsSet <> '1') ) -- 조회기준: select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8030 
        AND ( @IsSetItem <> '1' OR (H.IsSet = @IsSetItem) )
        
        AND ( @ItemClassSSeq = 0 OR C.MinorSeq = @ItemClassSSeq ) -- 품목소분류 
        AND ( @ItemClassMSeq = 0 OR E.MinorSeq = @ItemClassMSeq ) -- 품목중분류 
        AND ( @ItemClassLSeq = 0 OR G.MinorSeq = @ItemClassLSeq ) -- 품목대분류 
        
        AND I.IsQty <> '1' -- 재고수량 관리 
     
     -- 창고재고 가져오기
     EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                            @BizUnit      = @BizUnit,      -- 사업부문
                            @FactUnit     = @FactUnit,     -- 생산사업장
                            @DateFr       = @DateFr,       -- 조회기간Fr
                            @DateTo       = @DateTo,       -- 조회기간To
                            @WHSeq        = @WHSeq,        -- 창고지정
                            @SMWHKind     = @SMWHKind,   -- 창고구분 
                            @CustSeq      = @CustSeq,      -- 수탁거래처
                            @IsTrustCust  = @IsTrustCust,  -- 수탁여부
                            @IsSubDisplay = @IsSubDisplay, -- 기능창고 조회
                            @IsUnitQry    = @IsUnitQry,    -- 단위별 조회
                           @QryType      = @QryType,      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                            @MngDeptSeq   = @MngDeptSeq,
                            @IsUseDetail  = '1'
     
     -- 다이나믹 Title (입출고 Title) 담기 
     -- ※ 구분기준을 입출고유형으로 할건지 아니면 입출고구분으로 할건지에 대한 부분이 변경가능하게 주석처리하였음 
     -- ※ 현재는 입출고구분 기준 
     INSERT INTO #Temp_InOutTitle( Title, TitleSeq, Title2, TitleSeq2 )  
     SELECT (CASE A.InOut WHEN 1 THEN N'입고' WHEN -1 THEN N'출고' ELSE '' END), A.InOut, 
            --B.MinorName, A.InOutType 
            MAX(C.MinorName), A.InOutKind
       FROM #TLGInOutStock   AS A  
       --JOIN _TDASMinor       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MajorSeq = 8042 AND A.InOutType = B.MinorValue ) -- 입출고유형(8042)
       JOIN _TDASMinor       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 8023 AND A.InOutKind = C.MinorSeq ) -- 입출고구분(8023)
      WHERE A.InOutDate BETWEEN @DateFr AND @DateTo  
     --GROUP BY A.InOut, A.InOutType 
      GROUP BY A.InOut, A.InOutKind 
      ORDER BY A.InOut DESC 
     
     -- ?? 
     IF ISNULL(@WHCustSeq,0) > 0
     BEGIN
         DELETE #GetInOutStock
           FROM #GetInOutStock AS A
           JOIN _TDAWH         AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.WHSeq = B.WHSeq
          WHERE B.CommissionCustSeq <> @WHCustSeq
     END
     
     -- 최종 조회 
     IF @IsUnitQry = '1' -- 단위별조회(O)
     BEGIN
         
         -- 고정 Column 담기 
         INSERT INTO #Temp_FixCol      
         (
             WHKindName, WHName, FunctionWHName, ItemName, ItemNo,
             Spec, UnitName, AssetName, PrevQty, InQty,
             OutQty, StockQty, SalesUnitQty, SalesUnitName, SalesUnitSeq, 
             WHSeq, FunctionWHSeq, ItemSeq, UnitSeq, AssetSeq, 
             ItemClassName, StockAmt, IsUnitQry,
             ItemClassSSeq, ItemClassSName, 
             ItemClassMSeq, ItemClassMName, 
             ItemClassLSeq, ItemClassLName, 
             SMPurKindName, CustSeq, CustName, DateFr, DateTo, SafetyQty 
         )
         SELECT X.WHKindName, X.WHName, X.FunctionWHName, X.ItemName, X.ItemNo,
                X.Spec, X.UnitName, X.AssetName, X.PrevQty, X.InQty,
                X.OutQty, X.StockQty, X.SalesUnitQty, X.SalesUnitName, X.SalesUnitSeq, 
                X.WHSeq, X.FunctionWHSeq, X.ItemSeq, X.UnitSeq, X.AssetSeq,
                ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = Y.UMItemClass), '') AS ItemClassName, -- ?? 
                ISNULL(X.StockQty, 0) * ISNULL(Z.Price,0) AS StockAmt,X.IsUnitQry,
                
                X.ItemClassSSeq, X.ItemClassSName, -- 품목소분류 
                X.ItemClassMSeq, X.ItemClassMName, -- 품목중분류 
                X.ItemClassLSeq, X.ItemClassLName, -- 품목대분류 
                
                X.SMPurKindName,  -- 납기구분
                X.CustSeq,
                X.CustName,
                @DateFr AS DateFr,
                @DateTo AS DateTo,
                S.SafetyQty
       
           FROM (
                 -- 기준단위수량 아님 ... 
                 SELECT CASE WHEN ISNULL(D.SMWHKind,0) = 0 THEN '' ELSE (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = D.SMWHKind) END AS WHKindName,
                        ISNULL(D.WHName,'') AS WHName,
                        ISNULL(C.WHName,'') AS FunctionWHName,
                        ISNULL(B.ItemName, '') AS ItemName,
                        ISNULL(B.ItemNo, '') AS ItemNo,
                        ISNULL(B.Spec, '') AS Spec,
                        ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq),'') AS UnitName,
                        ISNULL((SELECT AssetName FROM _TDAItemAsset WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AssetSeq = B.AssetSeq),'') AS AssetName,
                        ISNULL(A.PrevQty, 0) AS PrevQty,
                        ISNULL(A.InQty, 0) AS InQty,
                        ISNULL(A.OutQty, 0) AS OutQty,
                        ISNULL(A.StockQty, 0) AS StockQty,
                        FLOOR(
                                CASE WHEN (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END) = 0 
                                     THEN 0 
                                     ELSE ISNULL(A.StockQty, 0) / (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END) 
                                     END 
                             ) AS SalesUnitQty,
                        H.UnitName AS SalesUnitName, 
                        H.UnitSeq AS SalesUnitSeq, 
                        ISNULL(A.WHSeq, 0) AS WHSeq,
                        ISNULL(A.FunctionWHSeq, 0) AS FunctionWHSeq,
                        ISNULL(A.ItemSeq, 0) AS ItemSeq,
                        ISNULL(A.UnitSeq, 0) AS UnitSeq,
                        ISNULL(B.AssetSeq, 0) AS AssetSeq,
                        '0' AS IsUnitQry,
                        Z.ItemClassSSeq, Z.ItemClassSName, -- 품목소분류
                        Z.ItemClassMSeq, Z.ItemClassMName, -- 품목중분류
                        Z.ItemClassLSeq, Z.ItemClassLName,  -- 품목대분류
                        
                        ISNULL((SELECT MinorName FROM _TDASMinor where CompanySeq = @CompanySeq AND MinorSeq = P.SMPurKind), '') AS SMPurKindName, -- 납기구분
                        ISNULL(C.TrustCustSeq,0) AS CustSeq, -- 수탁거래처코드
                        ISNULL((SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = C.TrustCustSeq),'') AS CustName, -- 수탁거래처
                        D.SortSeq
                   FROM #GetInOutStock               AS A
                   JOIN _TDAItem                     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )
                   LEFT OUTER JOIN _TDAWHSub         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.FunctionWHSeq = C.WHSeq )
                   LEFT OUTER JOIN _TDAWH            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND A.WHSeq = D.WHSeq )
                   LEFT OUTER JOIN _TDAItemPurchase  AS P WITH(NOLOCK) ON ( B.CompanySeq = P.CompanySeq AND B.ItemSeq = P.ItemSeq )
                   JOIN #GetInOutItem                AS Z              ON ( A.ItemSeq = Z.ItemSeq )
                   LEFT OUTER JOIN _TDAItemDefUnit      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.ItemSeq AND F.UMModuleSeq = 1003002 ) 
                   LEFT OUTER JOIN _TDAItemUnit         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq AND G.UnitSeq = F.STDUnitSeq ) 
                   LEFT OUTER JOIN _TDAUnit              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = F.StdUnitSeq ) 
                  WHERE ((@IsZeroQty <> '1' AND (A.PrevQty <> 0 OR A.InQty <> 0 OR A.OutQty <> 0 OR A.StockQty <> 0))
                      OR @IsZeroQty = '1'
                        )
                 
                 UNION ALL
                 
                 -- 기준단위수량 ... 
                 SELECT ISNULL(J.MinorName,'') AS WHKindName,
                        ISNULL(F.WHName,'') AS WHName,
                        ISNULL(C.WHName,'') AS FunctionWHName,
                        ISNULL(B.ItemName, '') AS ItemName,
                        ISNULL(B.ItemNo, '') AS ItemNo,
                        ISNULL(B.Spec, '') AS Spec,
                        ISNULL(D.UnitName,'') AS UnitName,
                        ISNULL(E.AssetName,'') AS AssetName,
                        SUM(ISNULL(A.STDPrevQty, 0)) AS PrevQty,
                        SUM(ISNULL(A.STDInQty, 0)) AS InQty,
                        SUM(ISNULL(A.STDOutQty, 0)) AS OutQty,
                        SUM(ISNULL(A.STDStockQty, 0)) AS StockQty,
                        SUM(FLOOR(
                                    CASE WHEN (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END) = 0 
                                         THEN 0 
                                         ELSE ISNULL(A.STDStockQty, 0) / (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END)
                                         END 
                                 )
                           ) AS SalesUnitQty,
                        H.UnitName AS SalesUnitName, 
                        H.UnitSeq AS SalesUnitSeq, 
                        
                        ISNULL(A.WHSeq, 0) AS WHSeq,
                        ISNULL(A.FunctionWHSeq, 0) AS FunctionWHSeq,
                        ISNULL(A.ItemSeq, 0) AS ItemSeq,
                        ISNULL(B.UnitSeq, 0) AS UnitSeq,
                        ISNULL(B.AssetSeq, 0) AS AssetSeq,
                        '1' AS IsUnitQry, 
                        Z.ItemClassSSeq, MAX(Z.ItemClassSName), -- 품목소분류
                        Z.ItemClassMSeq, MAX(Z.ItemClassMName), -- 품목중분류
                        Z.ItemClassLSeq, MAX(Z.ItemClassLName),  -- 품목대분류
                        
                        ISNULL(PN.MinorName, '')     AS SMPurKindName, -- 납기구분
                        ISNULL(MAX(C.TrustCustSeq),0) AS CustSeq, -- 수탁거래처코드
                        ISNULL((SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = MAX(C.TrustCustSeq)),'') AS CustName, -- 수탁거래처
                        F.SortSeq
                        
                   FROM #GetInOutStock               AS A
                   JOIN _TDAItem                     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )
                   LEFT OUTER JOIN _TDAWHSub         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.FunctionWHSeq = C.WHSeq )
                   LEFT OUTER JOIN _TDAUnit          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND B.UnitSeq = D.UnitSeq )
                   LEFT OUTER JOIN _TDAItemAsset     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND B.AssetSeq = E.AssetSeq )
                   LEFT OUTER JOIN _TDAWH            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND A.WHSeq = F.WHSeq )
                   LEFT OUTER JOIN _TDASMinor        AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = F.SMWHKind )
                   LEFT OUTER JOIN _TDAItemPurchase  AS P  WITH(NOLOCK) ON ( B.CompanySeq = P.CompanySeq AND B.ItemSeq = P.ItemSeq )
                   LEFT OUTER JOIN _TDASMinor        AS PN WITH(NOLOCK) ON ( P.CompanySeq = PN.CompanySeq AND P.SMPurKind = PN.MinorSeq )
                   JOIN #GetInOutItem                AS Z               ON ( A.ItemSeq = Z.ItemSeq )
                   LEFT OUTER JOIN _TDAItemDefUnit      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.ItemSeq AND F.UMModuleSeq = 1003002 ) 
                   LEFT OUTER JOIN _TDAItemUnit         AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq AND G.UnitSeq = F.STDUnitSeq ) 
                   LEFT OUTER JOIN _TDAUnit              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = F.StdUnitSeq ) 
                  WHERE ((@IsZeroQty <> '1' AND (A.STDPrevQty <> 0 OR A.STDInQty <> 0 OR A.STDOutQty <> 0 OR A.STDStockQty <> 0))
                      OR @IsZeroQty = '1'
                        )
                  GROUP BY J.MinorName, F.WHName, C.WHName, B.ItemName, B.ItemNo, 
                           B.Spec, D.UnitName, E.AssetName, A.WHSeq, A.FunctionWHSeq, 
                           A.ItemSeq, B.UnitSeq, B.AssetSeq, Z.ItemClassLSeq, Z.ItemClassMSeq, 
                           Z.ItemClassSSeq, PN.MinorName, F.SortSeq
                ) AS X
           LEFT OUTER JOIN _TDAItemClass      AS Y WITH (NOLOCK) ON Y.CompanySeq = @CompanySeq AND X.ItemSeq = Y.ItemSeq AND Y.UMajorItemClass IN (2001,2004)
           LEFT OUTER JOIN _TESMBItemStdPrice AS Z WITH (NOLOCK) ON Z.CompanySeq = @CompanySeq 
                                                                AND ((@GoodPriceUnit = 5502002 AND Z.CostUnit = @AccUnit) OR (@GoodPriceUnit = 5502003 AND Z.CostUnit = @BizUnit))
                                                                AND X.ItemSeq = Z.ItemSeq
           
           LEFT OUTER JOIN _TDAWHItem        AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.ItemSeq = X.ItemSeq AND S.WHSeq = X.WHSeq )
          ORDER BY X.WHKindName, X.SortSeq, X.WHSeq, X.FunctionWHSeq, X.ItemNo, 
                   X.ItemName, X.ItemSeq, X.UnitSeq, X.IsUnitQry DESC 
         
         -- 다이나믹 Column 담기 
         INSERT INTO #Temp_InOutStock( ItemSeq, UnitSeq, WHSeq, InOutKind, InOut, Qty, IsUnitQry )   
         --INSERT INTO #Temp_InOutStock( ItemSeq, UnitSeq, WHSeq, InOutType, InOut, Qty, IsUnitQry )   
         
         -- 기준단위수량 아님 ... 
         SELECT A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutKind, A.InOut, ISNULL(SUM(A.Qty),0), '0' 
         --SELECT A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutType, A.InOut, ISNULL(SUM(A.Qty),0), '0' 
           FROM #TLGInOutStock       AS A  
          WHERE A.InOutDate BETWEEN @DateFr AND @DateTo  
          GROUP BY A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutKind, A.InOut
          --GROUP BY A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutType, A.InOut
          
         UNION ALL 
         
         -- 기준단위수량 ... 
         SELECT A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutKind, A.InOut, ISNULL(SUM(A.STDQty),0), '1'
         --SELECT A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutType, A.InOut, ISNULL(SUM(A.STDQty),0), '1'
           FROM #TLGInOutStock       AS A  
           LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )
          WHERE A.InOutDate BETWEEN @DateFr AND @DateTo  
         GROUP BY A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutKind, A.InOut
         --GROUP BY A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutType, A.InOut
         
     END
     ELSE -- 단위별조회(X)
     BEGIN
         
         -- 고정 Column 담기 
         INSERT INTO #Temp_FixCol      
      (
             WHKindName, WHName, FunctionWHName, ItemName, ItemNo,
             Spec, UnitName, AssetName, PrevQty, InQty,
             OutQty, StockQty, SalesUnitQty, SalesUnitName, SalesUnitSeq, 
             WHSeq, FunctionWHSeq, ItemSeq, UnitSeq, AssetSeq, 
             ItemClassName, StockAmt, IsUnitQry,
             ItemClassSSeq, ItemClassSName, 
             ItemClassMSeq, ItemClassMName, 
             ItemClassLSeq, ItemClassLName, 
             SMPurKindName, CustSeq, CustName, DateFr, DateTo, SafetyQty 
         )
   SELECT ISNULL(J.MinorName,'') AS WHKindName,
                ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq),'') AS WHName,
                ISNULL(C.WHName,'') AS FunctionWHName,
                ISNULL(B.ItemName, '') AS ItemName,
                ISNULL(B.ItemNo, '') AS ItemNo,
                
                ISNULL(B.Spec, '') AS Spec,
                ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq),'') AS UnitName,
                ISNULL((SELECT AssetName FROM _TDAItemAsset WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AssetSeq = B.AssetSeq),'') AS AssetName,
                ISNULL(A.STDPrevQty, 0) AS PrevQty,
                ISNULL(A.STDInQty, 0) AS InQty,
                
                ISNULL(A.STDOutQty, 0) AS OutQty,
                ISNULL(A.STDStockQty, 0) AS StockQty,
                FLOOR(
                        CASE WHEN (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END) = 0 
                             THEN 0 
                             ELSE ISNULL(A.STDStockQty, 0) / (CASE WHEN ISNULL(G.ConvDen,0) = 0 THEN 0 ELSE ISNULL(G.ConvNum,0) / ISNULL(G.ConvDen,0) END)
                             END 
                     ) AS SalesUnitQty, 
                H.UnitName AS SalesUnitName, 
                H.UnitSeq AS SalesUnitSeq, 
                
                ISNULL(A.WHSeq, 0) AS WHSeq,
                ISNULL(A.FunctionWHSeq, 0) AS FunctionWHSeq,
                ISNULL(A.ItemSeq, 0) AS ItemSeq,
                
                ISNULL(B.UnitSeq, 0) AS UnitSeq,
                ISNULL(B.AssetSeq, 0) AS AssetSeq,
                ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = D.UMItemClass), '') AS ItemClassName, -- ?? 
                ISNULL(A.STDStockQty, 0) * ISNULL(E.Price,0) AS StockAmt,
                '1' AS IsUnitQry,
                Z.ItemClassSSeq, Z.ItemClassSName, -- 품목소분류
                Z.ItemClassMSeq, Z.ItemClassMName, -- 품목중분류
                Z.ItemClassLSeq, Z.ItemClassLName,  -- 품목대분류
                        
                ISNULL((SELECT MinorName FROM _TDASMinor where CompanySeq = @CompanySeq AND MinorSeq = P.SMPurKind), '') AS SMPurKindName, -- 납기구분
                ISNULL(C.TrustCustSeq,0) AS CustSeq, -- 수탁거래처코드
                ISNULL((SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = C.TrustCustSeq),'') AS CustName, -- 수탁거래처
                @DateFr AS DateFr,
                @DateTo AS DateTo,
                S.SafetyQty
           FROM #GetInOutStock                   AS A
           LEFT OUTER JOIN _TDAItem              AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )
           LEFT OUTER JOIN _TDAWHSub             AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.FunctionWHSeq = C.WHSeq )
           LEFT OUTER JOIN _TESMBItemStdPrice    AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND ((@GoodPriceUnit = 5502002 AND E.CostUnit = @AccUnit) OR (@GoodPriceUnit = 5502003 AND E.CostUnit = @BizUnit)) AND A.ItemSeq = E.ItemSeq )
           LEFT OUTER JOIN _TDAItemClass         AS D WITH(NOLOCK) ON B.CompanySeq = D.CompanySeq AND B.ItemSeq    = D.ItemSeq AND D.UMajorItemClass IN (2001,2004)
           LEFT OUTER JOIN _TDAWH                AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND A.WHSeq = I.WHSeq )
           LEFT OUTER JOIN _TDASMinor            AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND I.SMWHKind = J.MinorSeq )
           LEFT OUTER JOIN _TDAItemPurchase      AS P WITH(NOLOCK) ON ( B.CompanySeq = P.CompanySeq AND B.ItemSeq = P.ItemSeq )
           JOIN #GetInOutItem                    AS Z              ON ( A.ItemSeq = Z.ItemSeq )
           LEFT OUTER JOIN _TDAWHItem            AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.ItemSeq = A.ItemSeq AND S.WHSeq = A.WHSeq )
           LEFT OUTER JOIN _TDAItemDefUnit       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.ItemSeq AND F.UMModuleSeq = 1003002 ) 
           LEFT OUTER JOIN _TDAItemUnit          AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq AND G.UnitSeq = F.STDUnitSeq ) 
           LEFT OUTER JOIN _TDAUnit              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = F.StdUnitSeq ) 
          WHERE ((@IsZeroQty <> '1' AND (A.STDPrevQty <> 0 OR A.STDInQty <> 0 OR A.STDOutQty <> 0 OR A.STDStockQty <> 0))
              OR @IsZeroQty = '1'
                )
          ORDER BY J.MinorName, I.SortSeq, A.WHSeq, A.FunctionWHSeq, B.ItemNo, 
                   B.ItemName, A.ItemSeq, A.UnitSeq
        
        
        
         -- 다이나믹 Column 담기  
         INSERT INTO #Temp_InOutStock( ItemSeq, UnitSeq, WHSeq, InOutKind, InOut, Qty, IsUnitQry )   
         --INSERT INTO #Temp_InOutStock( ItemSeq, UnitSeq, WHSeq, InOutType, InOut, Qty, IsUnitQry )   
         SELECT A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutKind, A.InOut, ISNULL(SUM(A.STDQty),0), '1' 
         --SELECT A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutType, A.InOut, ISNULL(SUM(A.STDQty),0), '1' 
           FROM #TLGInOutStock       AS A  
           LEFT OUTER JOIN _TDAItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )
          WHERE A.InOutDate BETWEEN @DateFr AND @DateTo  
          GROUP BY A.ItemSeq, B.UnitSeq, A.WHSeq, A.InOutKind, A.InOut 
          --GROUP BY A.ItemSeq, A.UnitSeq, A.WHSeq, A.InOutType, A.InOut 
         
     END
     
     --/*
     
     -- 최종 조회 3번 
     
     SELECT Title, TitleSeq, Title2, TitleSeq2 FROM #Temp_InOutTitle ORDER BY ColIDX  
     
     SELECT --/*
            RowIDX,
            WHKindName, WHName, FunctionWHName, ItemName, ItemNo,
            Spec, UnitName, AssetName, PrevQty, InQty,
            OutQty, StockQty, SalesUnitQty, SalesUnitName, SalesUnitSeq, 
            WHSeq, FunctionWHSeq, ItemSeq, UnitSeq, AssetSeq, --ItemClassName, StockAmt, 
            IsUnitQry,
            ItemClassSSeq, ItemClassSName, 
            ItemClassMSeq, ItemClassMName, 
            ItemClassLSeq, ItemClassLName, 
            SMPurKindName, CustSeq, CustName, DateFr, DateTo, SafetyQty
            --*/
       FROM #Temp_FixCol 
      ORDER BY RowIDX 
         
     SELECT C.RowIDX, 
            B.ColIDX, 
            ISNULL(SUM(A.Qty),0) AS Qty,
            MAX(A.InOutKind)
       FROM #Temp_InOutStock AS A 
       --JOIN #Temp_InOutTitle AS B ON ( A.InOut = B.TitleSeq AND A.InOutType = B.TitleSeq2 )      
       JOIN #Temp_InOutTitle AS B ON ( A.InOut = B.TitleSeq AND A.InOutKind = B.TitleSeq2 )      
       JOIN #Temp_FixCol     AS C ON ( A.ItemSeq = C.ItemSeq AND A.UnitSeq = C.UnitSeq AND A.WHSeq = C.WHSeq AND A.IsUnitQry = C.IsUnitQry ) 
      GROUP BY C.RowIDX, B.ColIDX      
     
  RETURN
GO
exec KPXCM_SLGWHStockListDynamicQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsUnitQry>0</IsUnitQry>
    <IsZeroQty>0</IsZeroQty>
    <BizUnit>2</BizUnit>
    <BizUnitName>상정-본사</BizUnitName>
    <DateFr>20151001</DateFr>
    <DateTo>20151028</DateTo>
    <SMWHKind />
    <WHKindName />
    <CustSeq />
    <CustName />
    <QryType>B</QryType>
    <QryTypeName>자산재고</QryTypeName>
    <FactUnit />
    <FactUnitName />
    <WHSeq />
    <WHName />
    <AssetSeq />
    <AssetName />
    <ItemClassLSeq />
    <ItemClassLName />
    <ItemClassMSeq />
    <ItemClassMName />
    <ItemClassSSeq />
    <ItemClassSName />
    <ItemName />
    <ItemNo />
    <Spec />
    <SMABC />
    <IsSubDisplay>0</IsSubDisplay>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032828,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027178