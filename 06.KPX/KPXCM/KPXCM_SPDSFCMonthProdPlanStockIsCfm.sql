  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockIsCfm') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockIsCfm  
GO  
  
-- v2015.11.03 
  
-- 월생산계획-확정 by 이재천 
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockIsCfm  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    CREATE TABLE #KPXCM_TPDSFCMonthProdPlanStock( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthProdPlanStock'   
    IF @@ERROR <> 0 RETURN  
    
    UPDATE B
       SET IsCfm = A.IsCfm 
      FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
      JOIN KPXCM_TPDSFCMonthProdPlanStock  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq ) 
    
    DELETE A 
      FROM KPXCM_TPDSFCMonthMatUsePlanStock AS A 
      JOIN (
            SELECT Y.FactUnit, Y.PlanYM
              FROM #KPXCM_TPDSFCMonthProdPlanStock AS Z 
              JOIN KPXCM_TPDSFCMonthProdPlanStock  AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.PlanSeq = Z.PlanSeq AND Y.PlanYMSub = Y.PlanYM ) 
           ) AS B ON ( B.FactUnit = A.FactUnit AND B.PlanYM = A.PlanYM ) 
     WHERE A.CompanySeq = @CompanySeq 
      
    
    
    IF (SELECT TOP 1 IsCfm FROM #KPXCM_TPDSFCMonthProdPlanStock) = '1' 
    BEGIN 
    
        SELECT ROW_NUMBER() OVER(ORDER BY B.PlanSeq, B.PlanSerl, B.PlanYMSub) AS IDX_NO, B.*, D.ProdPlanQty AS ProdPlanQtyM1, E.ProdPlanQty AS ProdPlanQtyM2
          INTO #BaseData 
          FROM #KPXCM_TPDSFCMonthProdPlanStock      AS A 
          JOIN KPXCM_TPDSFCMonthProdPlanStockItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq ) 
          JOIN KPXCM_TPDSFCMonthProdPlanStock       AS C ON ( C.CompanySeq = @CompanySeq AND C.PlanSeq = A.PlanSeq AND C.PlanYMSub = B.PlanYMSub ) 
          OUTER APPLY ( 
                        SELECT ProdPlanQty 
                          FROM KPXCM_TPDSFCMonthProdPlanStockItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.PlanSeq = A.PlanSeq 
                           AND Z.PlanSerl = B.PlanSerl 
                           AND Z.PlanYMSub = CONVERT(NCHAR(6),DATEADD(MM,1,C.PlanYMSub + '01'),112) 
                      ) AS D
          OUTER APPLY ( 
                        SELECT ProdPlanQty
                          FROM KPXCM_TPDSFCMonthProdPlanStockItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.PlanSeq = A.PlanSeq 
                           AND Z.PlanSerl = B.PlanSerl 
                           AND Z.PlanYMSub = CONVERT(NCHAR(6),DATEADD(MM,2,C.PlanYMSub + '01'),112)
                      ) AS E 
         WHERE B.PlanYMSub = C.PlanYM 
        

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
        DECLARE @Cnt                INT, 
                @ItemSeq            INT, 
                @ProdPlanQty        DECIMAL(19,5), 
                @ProdPlanQtyM1      DECIMAL(19,5), 
                @ProdPlanQtyM2      DECIMAL(19,5), 
                @MaxDataSeq         INT
        
        SELECT @Cnt = 1 
        SELECT @MaxDataSeq = (SELECT MAX(IDX_NO) FROM #BaseData) 
        
        
        CREATE TABLE #GetInOutItem 
        (
            ItemSeq         INT, 
            StockQty		DECIMAL(19,5), 
            ProdQtyM		DECIMAL(19,5), 
            ProdQtyM1		DECIMAL(19,5), 
            ProdQtyM2       DECIMAL(19,5), 
        )
        INSERT INTO #GetInOutItem (ItemSeq, StockQty, ProdQtyM, ProdQtyM1, ProdQtyM2) 
        SELECT A.ItemSeq, 0, 0, 0, 0
          FROM _TDAItem         AS A 
          JOIN _TDAItemAsset    AS B ON ( B.CompanySeq = @CompanySeq AND B.AssetSeq = A.AssetSeq AND B.SMAssetGrp = 6008006 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.SMStatus = 2001001 
        
        --select * from _TDAItem where companyseq = 1 
        
        --select * from #Result 
        --return 
        
        WHILE ( 1 = 1 ) 
        BEGIN 
            
            SELECT @ItemSeq = A.ItemSeq, 
                   @ProdPlanQty = A.ProdPlanQty, 
                   @ProdPlanQtyM1 = A.ProdPlanQtyM1, 
                   @ProdPlanQtyM2 = A.ProdPlanQtyM2
              FROM #BaseData  AS A 
             WHERE IDX_NO = @Cnt 
            
            TRUNCATE TABLE #BOMSpread 

            EXEC dbo._SPDBOMSpreadTree @CompanySeq    = @CompanySeq
                                      ,@ItemSeq       = @ItemSeq
                                      ,@ItemBomRev    = '00'
                                      ,@SemiType      = 0
                                      ,@IsReverse     = 0
                                      ,@BOMNeedQty    = 0
            
            UPDATE A
               SET ProdQtyM = ISNULL(A.ProdQtyM,0) + (ISNULL(@ProdPlanQty,0) * ISNULL(B.NeedQty,0)), 
                   ProdQtyM1 = ISNULL(A.ProdQtyM1,0) + (ISNULL(@ProdPlanQtyM1,0) * ISNULL(B.NeedQty,0)), 
                   ProdQtyM2 = ISNULL(A.ProdQtyM2,0) + (ISNULL(@ProdPlanQtyM2,0) * ISNULL(B.NeedQty,0)) 
              FROM #GetInOutItem    AS A 
              JOIN #BOMSpread       AS B ON ( B.ItemSeq = A.ItemSeq ) 
            
            IF @Cnt >= (SELECT ISNULL(@MaxDataSeq,0))
            BEGIN 
                BREAK 
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END 
        
        DECLARE @Date       NCHAR(8), 
                @FactUnit   INT 
        
        SELECT @Date = CONVERT(NCHAR(8),GETDATE(),112), 
               @FactUnit = (SELECT TOP 1 B.FactUnit 
                              FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
                              JOIN KPXCM_TPDSFCMonthProdPlanStock  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq ) 
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
        
        
        -- 창고재고 가져오기
        EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                               @BizUnit      = 0, -- 사업부문
                               @FactUnit     = @FactUnit,     -- 생산사업장
                               @DateFr       = @Date,       -- 조회기간Fr
                               @DateTo       = @Date,       -- 조회기간To
                               @WHSeq        = 0,        -- 창고지정
                               @SMWHKind     = 0,     -- 창고구분 
                               @CustSeq      = 0,      -- 수탁거래처
                               @IsTrustCust  = '0',  -- 수탁여부
                               @IsSubDisplay = '0', -- 기능창고 조회
                               @IsUnitQry    = '0',    -- 단위별 조회
                               @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                               @MngDeptSeq   = 0,
                               @IsUseDetail  = '1'
        
        UPDATE A 
           SET StockQty = B.StockQty
          FROM #GetInOutItem AS A 
          JOIN ( 
                SELECT SUM(StockQty) AS StockQty, ItemSeq 
                  FROM #GetInOutStock 
                 GROUP BY ItemSeq 
               ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
        
        
        INSERT INTO KPXCM_TPDSFCMonthMatUsePlanStock
        (
            CompanySeq, FactUnit, PlanYM, ItemSeq, StockQty, 
            ProdQtyM, RepalceQtyM, ProdQtyM1, RepalceQtyM1, ProdQtyM2, 
            RepalceQtyM2, LastUserSeq, LastDateTime, PgmSeq
        )
        SELECT @CompanySeq , @FactUnit, (SELECT TOP 1 PlanYMSub FROM #BaseData), A.ItemSeq, A.StockQty, 
               A.ProdQtyM, A.ProdQtyM, A.ProdQtyM1, A.ProdQtyM1, A.ProdQtyM2, 
               A.ProdQtyM2, @UserSeq, GETDATE(), @PgmSeq 
          FROM #GetInOutItem AS A 
        
    END 
    
    SELECT * FROM #KPXCM_TPDSFCMonthProdPlanStock 
      
    RETURN  
GO
begin tran 
exec KPXCM_SPDSFCMonthProdPlanStockIsCfm @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanSeq>27</PlanSeq>
    <IsCfm>1</IsCfm>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069
select * from KPXCM_TPDSFCMonthMatUsePlanStock
rollback 