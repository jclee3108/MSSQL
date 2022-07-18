  
IF OBJECT_ID('KPXCM_SPDDailyStockListSubQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyStockListSubQuery  
GO  
  
-- v2016.04.20  
  
-- 일일재고현황-조회 by 이재천   
CREATE PROC KPXCM_SPDDailyStockListSubQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @IsItem     NCHAR(1),
            @FactUnit   INT, 
            @StdDate    NCHAR(8), 
            @SrtDate    NCHAR(8)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @IsItem      = ISNULL( IsItem, '0' ),  
           @FactUnit    = ISNULL( FactUnit, 0 ), 
           @StdDate     = ISNULL( StdDate, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            IsItem     NCHAR(1),
            FactUnit   INT, 
            StdDate    NCHAR(8) 
           )    
    
    
    SELECT @SrtDate = LEFT(@StdDate,6) + '01'  
    
    -- 대상품목 
    CREATE TABLE #GetInOutItem
    ( 
        ItemSeq     INT, 
        AssetSeq    INT 
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
    
    INSERT INTO #GetInOutItem ( ItemSeq, AssetSeq ) 
    SELECT A.ItemSeq, B.AssetSeq 
      FROM _TDAItem                 AS A 
      LEFT OUTER JOIN _TDAItemAsset AS B ON ( B.CompanySeq = A.CompanySeq AND B.AssetSeq = A.AssetSeq ) 
      LEFT OUTER JOIN _TDAItemSales AS C ON ( C.CompanySeq = A.CompanySeq AND C.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.AssetSeq IN ( 18, 20 ) 
       AND C.IsSet = '0'  
       AND A.SMStatus = 2001001 
    
    --select * From _TDASMinor where MajorSeq = 2001 and CompanySeq = 2 
    
    -- 창고재고 가져오기
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                           @BizUnit      = 0,      -- 사업부문
                           @FactUnit     = @FactUnit,     -- 생산사업장
                           @DateFr       = @SrtDate,       -- 조회기간Fr
                           @DateTo       = @StdDate,       -- 조회기간To
                           @WHSeq        = 0,        -- 창고지정
                           @SMWHKind     = 0,     -- 창고구분 
                           @CustSeq      = 0,      -- 수탁거래처
                           @IsTrustCust  = '0',  -- 수탁여부
                           @IsSubDisplay = '0', -- 기능창고 조회
                           @IsUnitQry    = '0',    -- 단위별 조회
                           @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                           @MngDeptSeq   = 0,
                           @IsUseDetail  = '1'
    
    
    --select SUM(StdQty) From #TLGInOutStock where InOutType = 180 and InOut = -1 and ItemSeq = 426 
    --select StdQty , ItemSeq, WHSeq From #TLGInOutStock where InOutType = 140 and InOut = 1
    --select StdQty , ItemSeq, WHSeq From #TLGInOutStock where InOutType = 140 and InOut = -1
    --return 
    
    
    
    CREATE TABLE #Result_Sub 
    (
        GubunName       NVARCHAR(200), 
        Gubun           INT, 
        ItemName        NVARCHAR(200), 
        ItemSeq         INT, 
        AssetSeq        INT, 
        OpenStockQty    DECIMAL(19,5), 
        DailyProdQty    DECIMAL(19,5), 
        SumProdQty      DECIMAL(19,5), 
        DailySalsQty    DECIMAL(19,5), 
        SumSalsQty      DECIMAL(19,5), 
        DailySelfQty    DECIMAL(19,5), 
        SumSelfQty      DECIMAL(19,5), 
        EtcOutQty       DECIMAL(19,5), 
        ClosStockQty    DECIMAL(19,5), 
        InQty           DECIMAL(19,5), 
        OutQty          DECIMAL(19,5) 
    ) 
    CREATE TABLE #Result
    (
        GubunName       NVARCHAR(200), 
        Gubun           INT, 
        ItemName        NVARCHAR(200), 
        ItemSeq         INT, 
        AssetSeq        INT, 
        OpenStockQty    DECIMAL(19,5), 
        DailyProdQty    DECIMAL(19,5), 
        SumProdQty      DECIMAL(19,5), 
        DailySalsQty    DECIMAL(19,5), 
        SumSalsQty      DECIMAL(19,5), 
        DailySelfQty    DECIMAL(19,5), 
        SumSelfQty      DECIMAL(19,5), 
        EtcOutQty       DECIMAL(19,5), 
        ClosStockQty    DECIMAL(19,5), 
        InQty           DECIMAL(19,5), 
        OutQty          DECIMAL(19,5) 
    ) 
    
    -- 품목정보 
    INSERT INTO #Result_Sub ( ItemSeq, ItemName, AssetSeq ) 
    SELECT A.ItemSeq, B.ItemEngSName, B.AssetSeq
      FROM #GetInOutItem    AS A 
      JOIN _TDAItem         AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq )    
    
    -- 기초재고 
    UPDATE A 
       SET OpenStockQty = ISNULL(B.PrevQty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN (
                        SELECT Z.ItemSeq, SUM(PrevQty) AS PrevQty
                          FROM #GetInOutStock AS Z 
                         GROUP BY Z.ItemSeq 
                       ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    -- 생산량 
    UPDATE A
       SET DailyProdQty = ISNULL(C.Qty,0), 
           SumProdQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 140 
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 140 
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 

    -- 판매량 
    UPDATE A
       SET DailySalsQty = ISNULL(C.Qty,0), 
           SumSalsQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 10 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 10 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- 자가소비량 
    UPDATE A
       SET DailySelfQty = ISNULL(C.Qty,0), 
           SumSelfQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType = 130 
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 130  
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- 기타출고 
    UPDATE A
       SET EtcOutQty = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate = @StdDate 
                           AND Z.InOutType = 30 
                           AND Z.InOut = -1 
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    -- 기말재고 
    UPDATE A
       SET ClosStockQty = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(STDStockQty) AS Qty 
                          FROM #GetInOutStock AS Z 
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
    
    -- 그외의 입고, 출고 
    UPDATE A
       SET InQty = ISNULL(C.Qty,0), 
           OutQty   = ISNULL(B.Qty,0)
      FROM #Result_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType IN ( 80, 81, 90 ) -- 이동, 적송, 규격대체
                           AND Z.InOut = -1
                         GROUP BY Z.ItemSeq 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ItemSeq, SUM(StdQty) AS Qty 
                          FROM #TLGInOutStock AS Z 
                         WHERE Z.InOutDate BETWEEN @SrtDate AND @StdDate 
                           AND Z.InOutType IN ( 170, 110, 150, 240, 40, 41, 80, 81, 90 ) -- 구매입고, 수탁입고, 외주입고, 수입입고, 기타입고, 자재기타입고, 이동, 적송, 규격대체
                           AND Z.InOut = 1
                         GROUP BY Z.ItemSeq 
                      ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    -- 제품 분류하기 
    UPDATE A 
       SET GubunName = CASE WHEN C.ValueSeq IN ( 1012814002, 1012814003 ) THEN D.MinorName ELSE 'PPG 제품' END, 
           Gubun = CASE WHEN C.ValueSeq = 1012814002 THEN 101 
                        WHEN C.ValueSeq = 1012814003 THEN 102 
                        ELSE 100 END 
      From #Result_Sub                  AS A 
      LEFT OUTER JOIN _TDAItemUserDefine AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MngValSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
     --WHERE A.AssetSeq = 18 
    
    
    -- 반제품 분류하기 
    UPDATE A 
       SET GubunName = CASE WHEN C.ValueSeq IN ( 1012814002, 1012814003 ) THEN D.MinorName ELSE 'PPG 반제품' END, 
           Gubun = CASE WHEN C.ValueSeq = 1012814002 THEN 301 
                        WHEN C.ValueSeq = 1012814003 THEN 302
                        ELSE 300 END 
      From #Result_Sub                  AS A 
      LEFT OUTER JOIN _TDAItemUserDefine AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MngValSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
     WHERE A.AssetSeq = 20
    
    IF @IsItem = '1' -- 품목별조회여부 
    BEGIN
        
        -- 기본데이터 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
               OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
               DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
               OutQty         
          FROM #Result_Sub
        
        -- 제품 소계 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '소 계', 200, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE Gubun < 200  
         
        -- 반제품 소계 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '소 계', 350, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE 300 <= Gubun 
        
        -- 합계 소계 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '합 계', 400, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub 
         WHERE Gubun NOT IN ( 350, 200 ) 
    
    END 
    ELSE
    BEGIN
    
        -- 기본데이터 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT MAX(GubunName)      ,Gubun          ,''       ,0        ,0       ,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         GROUP BY Gubun
        
        -- 제품 소계 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '소 계', 200, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub
         WHERE Gubun < 200  
         
        -- 합계 소계 
        INSERT INTO #Result
        (
            GubunName      ,Gubun          ,ItemName       ,ItemSeq        ,AssetSeq       ,
            OpenStockQty   ,DailyProdQty   ,SumProdQty     ,DailySalsQty   ,SumSalsQty     ,
            DailySelfQty   ,SumSelfQty     ,EtcOutQty      ,ClosStockQty   ,InQty          ,
            OutQty         
        )
        SELECT '합 계', 400, '', 0, 0,
               SUM(OpenStockQty)   ,SUM(DailyProdQty)   ,SUM(SumProdQty)     ,SUM(DailySalsQty)   ,SUM(SumSalsQty)     ,
               SUM(DailySelfQty)   ,SUM(SumSelfQty)     ,SUM(EtcOutQty)      ,SUM(ClosStockQty)   ,SUM(InQty)          ,
               SUM(OutQty)         
          FROM #Result_Sub 
         WHERE Gubun <> 200 
        
    END 
    
    
    SELECT * FROM #Result ORDER BY Gubun, ItemSeq 
    
    

    
    RETURN  
go
EXEC KPXCM_SPDDailyStockListSubQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit>3</FactUnit>
    <StdDate>20160408</StdDate>
    <IsItem>0</IsItem>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1036580, @WorkingTag = N'', @CompanySeq = 2, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1029979

