  
IF OBJECT_ID('KPX_SPDMRPMonthQuerySub') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthQuerySub  
GO  
  
-- v2014.12.16  
  
-- 월별자재소요계산-Item조회 by 이재천   
CREATE PROC KPX_SPDMRPMonthQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ProdPlanYM NCHAR(6) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ProdPlanYM = ISNULL( ProdPlanYM, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ProdPlanYM NCHAR(6)) 
    
    CREATE TABLE #ProdItem 
    (
        IDX_NO          INT IDENTITY, 
        ItemSeq         INT, 
        ProdQty         DECIMAL(19,5), 
        YM              NCHAR(6) 
    )
    
    INSERT INTO #ProdItem ( ItemSeq, ProdQty, YM ) 
    SELECT A.ItemSeq, SUM(A.ProdPlanQty) AS ProdQty, A.PlanYM AS YM
      FROM KPX_TPDSFCMonthProdPlan AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanYM >= @ProdPlanYM 
     GROUP BY A.ItemSeq, A.PlanYM
     ORDER BY YM, ItemSeq
    
    
    CREATE TABLE #Result
    ( 
        ItemSeq     INT, 
        YM          NCHAR(6), 
        StockQty    DECIMAL(19,5), 
        NeedQty     DECIMAL(19,5), 
        Etc         DECIMAL(19,5) 
    )
    
    IF EXISTS (SELECT 1 FROM #ProdItem) 
    BEGIN
        
        ----------------------------------------------------------------------
        -- BOM 데이터 가져오기 
        ----------------------------------------------------------------------
        
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
             YM                  NCHAR(6)
         )  
        
        DECLARE @Cnt        INT, 
                @YM         NCHAR(6), 
                @ProdQty    DECIMAL(19,5), 
                @ItemSeq    INT  
        
        SELECT @Cnt = 1 
        
        WHILE ( 1 = 1 ) 
        BEGIN
            SELECT @ItemSeq = ItemSeq, 
                   @ProdQty = ProdQty, 
                   @YM = YM  
              FROM #ProdItem 
             WHERE IDX_NO = @Cnt 
        
            
            EXEC _SPDBOMSpread @CompanySeq  = @CompanySeq
                              ,@ItemSeq     = @ItemSeq
                              ,@ItemBomRev  = '' 
            
            
            INSERT INTO #BOMSpread_Sub 
            (
                ItemSeq            ,ItemBOMRev         ,UnitSeq            ,BOMLevelText       ,Location           ,             
                Remark             ,Serl               ,NeedQtyNumerator   ,NeedQtyDenominator ,NeedQty            ,
                Seq                ,ParentSeq          ,Sort               ,BOMLevel           ,YM
            )  
            
            
            SELECT ItemSeq            ,ItemBOMRev         ,UnitSeq            ,BOMLevelText       ,Location           ,             
                   Remark             ,Serl               ,NeedQtyNumerator   ,NeedQtyDenominator ,NeedQty * @ProdQty  ,
                   Seq                ,ParentSeq          ,Sort               ,BOMLevel           ,@YM 
              FROM #BOMSpread WHERE BOMLevelText <> '01'
            
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #ProdItem) 
            BEGIN 
                BREAK
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1     
            END 
        
        END 
        
        SELECT A.ItemSeq, A.YM, SUM(A.NeedQty) AS NeedQty 
          INTO #BOMSpread_Sub_Sum 
          FROM #BOMSpread_Sub AS A 
          JOIN _TDAItemProduct AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.SMMrpKind = 6004001 ) 
         GROUP BY A.ItemSeq, A.YM 
        
    
        --select * from  #BOMSpread_Sub_Sum
        -- where itemSeq = 23911 
        --return 
        ------------------------------------------------------------------------
        ---- 재고가져오기
        ------------------------------------------------------------------------ 
        
        DECLARE @StkDate NCHAR(8)
        SELECT @StkDate = CONVERT(NCHAR(8),DATEADD(DAY, -1, @ProdPlanYM + '01'),112) 
        
        
        CREATE TABLE #GetInOutItem
        (
            ItemSeq    INT
        )
        INSERT INTO #GetInOutItem
        SELECT ItemSeq
          FROM #BOMSpread_Sub_Sum     
        
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
        
        EXEC _SLGGetInOutStock @CompanySeq    = @CompanySeq,       -- 법인코드
                               @BizUnit       = 0,       -- 사업부문
                               @FactUnit      = 0,       -- 생산사업장
                               @DateFr        = @StkDate, -- 조회기간Fr
                               @DateTo        = @StkDate, -- 조회기간To
                               @WHSeq         = 0,       -- 창고지정
                               @SMWHKind      = 0,       -- 창고구분별 조회
                               @CustSeq       = 0,       -- 수탁거래처
                               @IsSubDisplay  = '', -- 기능창고 조회
                               @IsUnitQry     = '', -- 단위별 조회
                               @QryType       = 'S'  -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
        
        SELECT ItemSeq, SUM(StockQty) AS StockQty 
          INTO #GetInOutStock_Sub 
          FROM #GetInOutStock
         GROUP BY ItemSeq 
        
        --select *from #BOMSpread_Sub_Sum 
        
        --return 
    

        INSERT INTO #Result (ItemSeq, YM, StockQty, NeedQty, Etc)
        SELECT A.ItemSeq, 
               A.YM, 
               ISNULL(B.StockQty,0) - ISNULL(C.NeedQty_Sum,0) StockQty, -- 소요량 뺀 현재고
               ISNULL(A.NeedQty,0) AS NeedQty, -- 소요량
               (ISNULL(B.StockQty,0) - ISNULL(C.NeedQty_Sum,0)) - ISNULL(A.NeedQty,0) AS Etc -- 부족량 
          FROM #BOMSpread_Sub_Sum AS A 
          LEFT OUTER JOIN #GetInOutStock_Sub AS B ON ( B.ItemSeq = A.ItemSeq ) 
          OUTER APPLY ( SELECT Z.ItemSeq, SUM(Z.NeedQty) AS NeedQty_Sum
                          FROM #BOMSpread_Sub_Sum AS Z 
                         WHERE Z.ItemSeq = A.ItemSeq 
                           AND Z.YM < A.YM
                         GROUP BY Z.itemSeq
                      ) AS C 
         ORDER BY A.ItemSeq, A.YM 
    
    END 
    
    -- Title 
    CREATE TABLE #Title
    (
         ColIdx     INT IDENTITY(0, 1), 
         Title      NVARCHAR(100), 
         TitleSeq   INT
    )
    
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT DISTINCT STUFF(A.YM,5,0,'-') AS Title , A.YM AS TitleSeq 
      FROM #ProdItem AS A 
     ORDER BY TitleSeq 
    
    SELECT * FROM #Title ORDER BY ColIdx
    
    -- 고정행 
    CREATE TABLE #FixCol_Sub
    (
         RowIdx     INT IDENTITY(0, 1), 
         ItemSeq    INT, 
         Total      DECIMAL(19,5), 
         Kind       INT 
    )
    
    INSERT INTO #FixCol_Sub (ItemSeq, Total, Kind) 
    SELECT ItemSeq, MAX(StockQty), 1 
      FROM #Result 
     GROUP BY ItemSeq
    
    UNION ALL 
    
    SELECT ItemSeq, SUM(NeedQty), 2 
      FROM #Result 
     GROUP BY ItemSeq
     
    UNION ALL 
    
    SELECT ItemSeq, MIN(Etc), 3 
      FROM #Result 
     GROUP BY ItemSeq
    
    
    CREATE TABLE #FixCol
    (
        RowIdx              INT IDENTITY(0,1), 
        ItemName            NVARCHAR(100), 
        ItemSeq             INT, 
        ItemNo              NVARCHAR(100), 
        Spec                NVARCHAR(100), 
        UnitSeq             INT, 
        UnitName            NVARCHAR(100), 
        DelvTerm            DECIMAL(19,5), 
        MinPurQty           DECIMAL(19,5), 
        CustSeq             INT, 
        CustName            NVARCHAR(100), 
        AssetName           NVARCHAR(100), 
        AssetSeq            INT, 
        ItemClassSeq        INT, 
        ItemClassName       NVARCHAR(100), 
        KindSeq             INT, 
        KindName            NVARCHAR(100), 
        Total               DECIMAL(19,5), 
        SMInOutTypePur      INT, 
        SMInOutTypePurName  NVARCHAR(100) 
    ) 
    
    INSERT INTO #FixCol 
    (
        ItemName,   ItemSeq,    ItemNo,         Spec,           UnitSeq,    
        UnitName,   DelvTerm,   MinPurQty,      CustSeq,        CustName,   
        AssetName,  AssetSeq,   ItemClassSeq,   ItemClassName,  KindSeq, 
        KindName,   Total,      SMInOutTypePur, SMInOutTypePurName 
    )
    SELECT C.ItemName, 
           A.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           D.UnitSeq, 
           D.UnitName,  
           B.LeadTime AS DelvTerm, 
           B.MinQty AS MinPurQty, 
           B.CustSeq, 
           E.CustName, 
           F.AssetName, 
           F.AssetSeq, 
           G.ItemClassSSeq AS ItemClassSeq, 
           G.ItemClasSName AS ItemClassName, 
           A.Kind AS KindSeq, 
           CASE WHEN A.Kind = 1 THEN '현재고' 
                WHEN A.Kind = 2 THEN '소요량' 
                WHEN A.Kind = 3 THEN '부족량' 
                ELSE ''
                END AS KindName, 
           A.Total, 
           H.SMPurKind  AS SMInOutTypePur, 
           I.MinorName AS SMInOutTypePurName 
    
      FROM #FixCol_Sub AS A 
      LEFT OUTER JOIN _TPUBASEBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.IsPrice = '1' )
      LEFT OUTER JOIN _TDAItem             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit             AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDACust             AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAItemAsset        AS F ON ( F.CompanySeq = @CompanySeq AND F.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS G ON ( G.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemPurchase     AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDASMinor           AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.SMPurKind ) 
     ORDER BY ItemSeq, KindSeq 
    
    SELECT * FROM #FixCol ORDER BY RowIdx
    
    -- 가변행 
    CREATE TABLE #Value
    (
         ItemSeq        INT, 
         YM             NCHAR(6), 
         Value          DECIMAL(19,5), 
         Kind           INT  
    )
    
    INSERT INTO #Value ( ItemSeq, YM, Value, Kind ) 
    SELECT A.ItemSeq, A.YM, StockQty, 1
      FROM #Result AS A 
    
    UNION ALL 
    
    SELECT A.ItemSeq, A.YM, NeedQty, 2 
      FROM #Result AS A 
    
    UNION ALL 
    
    SELECT A.ItemSeq, A.YM, Etc, 3 
      FROM #Result AS A 
    
    --select * from #Value 
    
    SELECT B.RowIdx, A.ColIdx, C.Value AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.YM ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq AND B.KindSeq = C.Kind ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
GO 
begin tran 
exec KPX_SPDMRPMonthQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ProdPlanYM>201412</ProdPlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026809,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021412

rollback 