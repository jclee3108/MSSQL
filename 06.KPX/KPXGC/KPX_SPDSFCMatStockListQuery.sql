  
IF OBJECT_ID('KPX_SPDSFCMatStockListQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCMatStockListQuery  
GO  
  
-- v2014.12.10  
  
-- 자재재고현황-조회 by 이재천   
CREATE PROC KPX_SPDSFCMatStockListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @FactUnit       INT,  
            @ProdPlanDateFr NCHAR(8), 
            @ProdPlanDateTo NCHAR(8), 
            @ItemSeq        INT, 
            @StockDate      NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit       = ISNULL( FactUnit, 0 ),  
           @ProdPlanDateFr = ISNULL( ProdPlanDateFr, '' ), 
           @ProdPlanDateTo = ISNULL( ProdPlanDateTo, '' )  
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            ProdPlanDateFr NCHAR(8),
            ProdPlanDateTo NCHAR(8)
           )    
    
    --select * from _TDAitem  where companyseq = 1 
    
    CREATE TABLE #TEMP 
    (
        Cnt         INT IDENTITY, 
        ItemSeq     INT, 
        SrtDate     NCHAR(8), 
        ProdQty     DECIMAl(19,5) 
    )
    INSERT INTO #TEMP (ItemSeq, SrtDate, ProdQty)
    SELECT A.ItemSeq, 
           A.SrtDate, 
           SUM(ISNULL(A.ProdQty,0))
      FROM _TPDMPSDailyProdPlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.SrtDate BETWEEN @ProdPlanDateFr AND @ProdPlanDateTo 
       AND @FactUnit = A.FactUnit 
     GROUP BY A.ItemSeq, A.SrtDate 
    
    
    
    --select * from #GetInOutStock 
    
    --return 
    
    CREATE TABLE #BOMSpread 
    (
         ItemSeq             INT,
         ItemBOMRev          NCHAR(2),
         UnitSeq             INT,
         BOMLevelText        NVARCHAR(200),
         Location            NVARCHAR(1000),
         Remark              NVARCHAR(500),
         Serl                INT,
         NeedQtyNumerator    DECIMAL(19,5),
         NeedQtyDenominator  DECIMAL(19,5),
         NeedQty             DECIMAL(19,10),
         Seq                 INT IDENTITY(1,1),
         ParentSeq           INT,
         Sort                INT,
         BOMLevel            INT
     )  
     
    CREATE TABLE #BOMSpread_Sub 
    (
         ItemSeq             INT,
         ItemBOMRev          NCHAR(2),
         UnitSeq             INT,
         BOMLevelText        NVARCHAR(200),
         Location            NVARCHAR(1000),
         Remark              NVARCHAR(500),
         Serl                INT,
         NeedQtyNumerator    DECIMAL(19,5),
         NeedQtyDenominator  DECIMAL(19,5),
         NeedQty             DECIMAL(19,10),
         Seq                 INT, 
         ParentSeq           INT,
         Sort                INT,
         BOMLevel            INT, 
         DateFr              NCHAR(8)
     )  
    
    
    DECLARE @Cnt  INT, 
            @Date NCHAR(8), 
            @ProdQty DECIMAL(19,5) 
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN
        SELECT @ItemSeq = ItemSeq, 
               @Date = SrtDate, 
               @ProdQty = ProdQty 
          FROM #TEMP 
         WHERE Cnt = @Cnt 
    
        
        EXEC _SPDBOMSpread @CompanySeq  = @CompanySeq
                          ,@ItemSeq     = @ItemSeq
                          ,@ItemBomRev  = '' 
        
        
        INSERT INTO #BOMSpread_Sub 
        (
            ItemSeq            ,ItemBOMRev         ,UnitSeq            ,BOMLevelText       ,Location           ,             
            Remark             ,Serl               ,NeedQtyNumerator   ,NeedQtyDenominator ,NeedQty            ,
            Seq                ,ParentSeq          ,Sort               ,BOMLevel           ,DateFr           
        )  
        
        
        SELECT ItemSeq            ,ItemBOMRev         ,UnitSeq            ,BOMLevelText       ,Location           ,             
               Remark             ,Serl               ,NeedQtyNumerator   ,NeedQtyDenominator ,NeedQty * @ProdQty  ,
               Seq                ,ParentSeq          ,Sort               ,BOMLevel           , @Date
          FROM #BOMSpread WHERE BOMLevelText <> '01'
        
        IF @Cnt = (SELECT MAX(Cnt) FROM #TEMP) 
        BEGIN 
            BREAK
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1     
        END 
    
    END 
    
     -- 대상품목 
     CREATE TABLE #GetInOutItem
     ( 
         ItemSeq INT
     )
     
     INSERT INTO #GetInOutItem 
     SELECT DISTINCT ItemSeq 
       FROM #BOMSpread_Sub 
       
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
    
    --select * from #GetInOutItem 
    
    SELECT @StockDate = (SELECT CONVERT(NCHAR(8),DATEADD(DAY,-1,@ProdPlanDateFr),112))
    
    -- 창고재고 가져오기
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                            @BizUnit      = 0,      -- 사업부문
                            @FactUnit     = @FactUnit,     -- 생산사업장
                            @DateFr       = @StockDate,       -- 조회기간Fr
                            @DateTo       = @StockDate,       -- 조회기간To
                            @WHSeq        = 0,        -- 창고지정
                            @SMWHKind     = 0,     -- 창고구분 
                            @CustSeq       = 0,      -- 수탁거래처
                            @IsTrustCust  = '',  -- 수탁여부
                            @IsSubDisplay = '', -- 기능창고 조회
                            @IsUnitQry    = '',    -- 단위별 조회
                            @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                            @MngDeptSeq   = 0,
                            @IsUseDetail  = '1' 
    
    CREATE TABLE #Main 
    (
        ItemSeq     INT, 
        NeedQty     DECIMAL(19,5), 
        DateFr      NCHAR(8)
    )
    
    INSERT INTO #Main (ItemSeq, NeedQty, DateFr)
    SELECT A.ItemSeq, SUM(A.NeedQty) AS NeedQty, DateFr  
      FROM #BOMSpread_Sub            AS A 
      JOIN _TDAItemUserDefine   AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.MngSerl = 1000001 AND (B.MngValText = 'True' OR B.MngValText = '1') )
     GROUP BY A.ItemSeq, DateFr  
    
    CREATE TABLE #DelvQty
    (
        ItemSeq     INT, 
        InQty       DECIMAL(19,5), 
        DateFr      NCHAR(8)
    )    
    
    -- 내수 
    INSERT INTO #DelvQty ( ItemSeq, InQty, DateFr ) 
    SELECT A.ItemSeq, SUM(A.Qty) AS InQty, B.DelvInDate AS DateFr
      FROM _TPUDelvInItem           AS A 
      LEFT OUTER JOIN _TPUDelvIn    AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
      JOIN #Main                    AS C ON ( C.ItemSeq = A.ItemSeq AND C.DateFr = B.DelvInDate ) 
     WHERE A.CompanySeq = @CompanySeq 
    GROUP BY A.ItemSeq, B.DelvInDate 
    
    -- 수입
    INSERT INTO #DelvQty ( ItemSeq, InQty, DateFr ) 
    SELECT A.ItemSeq, SUM(A.Qty) AS InQty, B.DelvDate AS DateFr
      FROM _TUIImpDelvItem           AS A 
      LEFT OUTER JOIN _TUIImpDelv    AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      JOIN #Main                    AS C ON ( C.ItemSeq = A.ItemSeq AND C.DateFr = B.DelvDate ) 
     WHERE A.CompanySeq = @CompanySeq 
    GROUP BY A.ItemSeq, B.DelvDate 
    
    
    CREATE TABLE #Title 
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT, 
        Title2     NVARCHAR(100), 
        TitleSeq2  INT
    )
    
    INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
    SELECT STUFF(STUFF(A.Solar,5,0,'-'),8,0,'-'), A.Solar, B.Title2, B.TitleSeq2
      FROM _TCOMCalendar AS A 
      LEFT OUTER JOIN ( SELECT '입고' AS Title2, 100 AS TitleSeq2
                        UNION ALL 
                        SELECT '사용', 200
                        UNION ALL 
                        SELECT '재고', 300
                      ) AS B ON ( 1 = 1 ) 
     WHERE A.Solar BETWEEN @ProdPlanDateFr AND @ProdPlanDateTo
    
    SELECT * FROM #Title  
    
    CREATE TABLE #FixCol
    (
         RowIdx     INT IDENTITY(0, 1), 
         ItemName   NVARCHAR(100), 
         ItemSeq    INT, 
         BaseQty    DECIMAL(19,5)
    )
    
    
    INSERT INTO #FixCol ( ItemName, ItemSeq, BaseQty ) 
    SELECT B.ItemName, A.ItemSeq, C.StockQty
      FROM #Main AS A 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN (SELECT SUM(StockQty) AS StockQty, Z.ItemSeq 
                         FROM #GetInOutStock AS Z 
                        GROUP BY Z.ItemSeq 
                       ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    SELECT * FROM #FixCol 
    
    CREATE TABLE #Value
    (
        Value1     DECIMAL(19, 5), 
        Value2     DECIMAL(19, 5), 
        Value3     DECIMAL(19, 5), 
        ItemSeq    INT, 
        DateFr      NCHAR(8) 
    )
    
    INSERT INTO #Value (Value1, Value2, Value3, ItemSeq, DateFr)
    SELECT ISNULL(B.InQty,0), A.NeedQty, ISNULL(C.StockQty,0) - ISNULL(B.InQty,0) - ISNULL(A.NeedQty,0), A.ItemSeq, A.DateFr
      FROM #Main AS A 
      LEFT OUTER JOIN ( SELECT SUM(Z.InQty) AS InQty, Z.ItemSeq, Z.DateFr  
                          FROM #DelvQty AS Z 
                         GROUP BY Z.ItemSeq, Z.DateFr 
                      ) AS B ON ( B.ItemSeq = A.ItemSeq AND B.DateFr = A.DateFr ) 
      LEFT OUTER JOIN (SELECT SUM(StockQty) AS StockQty, Z.ItemSeq 
                         FROM #GetInOutStock AS Z 
                        GROUP BY Z.ItemSeq 
                       ) AS C ON ( C.ItemSeq = A.ItemSeq ) 
    
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN A.TitleSeq2 = 100 THEN C.Value1 
                WHEN A.TitleSeq2 = 200 THEN C.Value2 
                WHEN A.TitleSeq2 = 300 THEN C.Value3 
                ELSE 0 
                END AS Value 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.DateFr ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    
    RETURN  
GO 
exec KPX_SPDSFCMatStockListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <ProdPlanDateFr>20141205</ProdPlanDateFr>
    <ProdPlanDateTo>20141206</ProdPlanDateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026651,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021345