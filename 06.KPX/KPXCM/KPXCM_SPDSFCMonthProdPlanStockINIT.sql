  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockINIT') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockINIT  
GO  
  
-- v2015.10.20 
  
-- 월생산계획-INIT by 이재천 
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockINIT  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT, 
            @Date       NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (FactUnit   INT)    
    
    SELECT @Date = CONVERT(NCHAR(8),GETDATE(),112)
    
    -- 대상품목 
    CREATE TABLE #GetInOutItem
    ( 
        ItemSeq         INT
    )
    INSERT INTO #GetInOutItem ( ItemSeq ) 
    SELECT A.ItemSeq 
      FROM _TDAItem                 AS A 
      LEFT OUTER JOIN _TDAItemAsset AS B ON ( B.CompanySeq = @CompanySeq AND B.AssetSeq = A.AssetSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.SMAssetGrp IN ( 6008002, 6008004 ) -- 제품, 반제품 
       AND A.SMStatus = 2001001 
    
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
    
    SELECT A.ItemSeq, 
           B.BaseQty, 
           C.ItemNo, CASE WHEN C.ItemEngSName <> '' THEN C.ItemEngSName ELSE C.ItemName END AS ItemName, 
           CASE WHEN E.MngValSeq IN ( 1010168007, 1010168010 ) 
                THEN E.MngValSeq 
                ELSE (
                        CASE WHEN D.AssetSeq = 18 -- PPG제품 
                             THEN 1010168001
                             WHEN D.AssetSeq = 20 -- PPG반제품 
                             THEN 1010168002 
                             END 
                     ) 
                END AS GubunSeq 
           
      FROM #GetInOutItem AS A 
      JOIN ( 
            SELECT ItemSeq, SUM(StockQty) AS BaseQty  
              FROM #GetInOutStock 
             GROUP BY ItemSeq 
           ) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset     AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = C.ItemSeq AND E.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MngValSeq ) 
     ORDER BY GubunSeq, ItemName
    
    RETURN  
GO 
exec KPXCM_SPDSFCMonthProdPlanStockINIT @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FactUnit />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069