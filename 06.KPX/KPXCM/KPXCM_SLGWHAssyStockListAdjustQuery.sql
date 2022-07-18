IF OBJECT_ID('KPXCM_SLGWHAssyStockListAdjustQuery') IS NOT NULL
    DROP PROC KPXCM_SLGWHAssyStockListAdjustQuery
GO 

-- v2015.11.30 

-- 재공재고조정(월) by이재천 

/*********************************************************************************************************************    
    화면명 : 재공재고조회    
    SP Name: _SLGWHAssyStockListQuery    
    작성일 : 2010. 08 : CREATED BY 김준모        
********************************************************************************************************************/    
  
CREATE PROCEDURE KPXCM_SLGWHAssyStockListAdjustQuery
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
            @BizUnit    INT,  
            @StdYM      NCHAR(6), 
            @AccUnit    INT,  
            @EnvMatQty  INT, -- 자재수량소수점자리수  
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
  
    SELECT  @BizUnit    = ISNULL(BizUnit,0),  
            @StdYM      = ISNULL(StdYM,'')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  
            BizUnit INT,  
            StdYM   NCHAR(6)
         )     
    
  
  
    DECLARE @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT               
              
    SELECT @ItemPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5521  And CompanySeq = @CompanySeq --자재단가계산단위                         
    SELECT @GoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq  = 5522  And CompanySeq = @CompanySeq --상품단가계산단위                         
    SELECT @FGoodPriceUnit = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  And CompanySeq = @CompanySeq --제품단가계산단위                         
              
  
    -- 구매/자재수량소수점자리수구하기  
    SELECT @EnvMatQty = EnvValue  
      FROM _TCOMEnv  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 5  
  
    SELECT @AccUnit = ISNULL(AccUnit, 0)  
      FROM _TDABizUnit WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND BizUnit    = @BizUnit  
  
    CREATE TABLE #GetInOutItem  
    (  
        ItemSeq    INT  
    )  
  
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
  
    INSERT INTO #GetInOutItem  
    SELECT DISTINCT A.ItemSeq  
      FROM _TDAItem AS A WITH (NOLOCK)  
           JOIN _TDAItemSales AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                AND A.ItemSeq    = B.ItemSeq  
           JOIN _TDAItemAsset AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                AND A.AssetSeq   = C.AssetSeq  
           LEFT OUTER JOIN _TDAItemClass AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                           AND A.ItemSeq    = D.ItemSeq  
                                                           AND D.UMajorItemClass IN (2001,2004)  
     WHERE A.CompanySeq = @CompanySeq  
       AND C.SMAssetGrp = 6008005
        
    
    
    SELECT @DateFr = @StdYM + '01', 
           @DateTo = CONVERT(NCHAR(8),DATEADD(DAY, -1, CONVERT(NCHAR(8),DATEADD(MONTH, 1, @StdYM + '01'),112)),112)
    
    
    -- 창고재고 가져오기  
    EXEC _SLGGetInOutStockAssy  @CompanySeq   = @CompanySeq,   -- 법인코드  
                                @BizUnit      = @BizUnit,      -- 사업부문  
                                @FactUnit     = 0,     -- 생산사업장  
                                @DateFr       = @DateFr,       -- 조회기간Fr  
                                @DateTo       = @DateTo,       -- 조회기간To  
                                @WHSeq        = 0,        -- 창고지정  
                                @SMWHKind     = 0,     -- 창고구분별 조회  
                                @CustSeq      = 0,      -- 수탁거래처  
                                @IsTrustCust  = '0',  -- 수탁여부  
                                @IsSubDisplay = '0', -- 기능창고 조회  
                                @IsUnitQry    = '0',    -- 단위별 조회  
                                @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고  
                                @MngDeptSeq   = 0  

    SELECT ISNULL(J.MinorName,'') AS WHKindName,  
           ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq),'') AS WHName,  
           ISNULL(C.WHName,'') AS FunctionWHName,  
           ISNULL(B.ItemName, '') AS ItemName,  
           ISNULL(B.ItemNo, '') AS ItemNo,  
           ISNULL(B.Spec, '') AS Spec,  
           ISNULL((SELECT UnitName FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = B.UnitSeq),'') AS UnitName,  
           ISNULL((SELECT AssetName FROM _TDAItemAsset WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND AssetSeq = B.AssetSeq),'') AS AssetName,  
           ROUND(ISNULL(A.STDPrevQty, 0), @EnvMatQty) AS PrevQty,  
           ROUND(ISNULL(A.STDInQty, 0), @EnvMatQty) AS InQty,  
           ROUND(ISNULL(A.STDOutQty, 0), @EnvMatQty) AS OutQty,  
           ROUND(ISNULL(A.STDStockQty, 0), @EnvMatQty) AS StockQty,  
           ISNULL(A.WHSeq, 0) AS WHSeq,  
           ISNULL(A.FunctionWHSeq, 0) AS FunctionWHSeq,  
           ISNULL(A.ItemSeq, 0) AS ItemSeq,  
           ISNULL(B.UnitSeq, 0) AS UnitSeq,  
           ISNULL(B.AssetSeq, 0) AS AssetSeq,  
           ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = D.UMItemClass), '') AS ItemClassName,  
           ISNULL(A.STDStockQty, 0) * ISNULL(E.Price,0) AS StockAmt,  
           '0' AS IsUnitQry,  
           CASE WHEN ISNULL(H.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')       
                                                            FROM _TDAUMinor WITH(NOLOCK)       
                                                            WHERE CompanySeq = @CompanySeq       
                                                            AND MinorSeq = H.ValueSeq) END AS ItemClassLName,  -- 품목대분류  
           CASE WHEN ISNULL(H.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorSeq,0)       
                                                            FROM _TDAUMinor WITH(NOLOCK)       
                                                            WHERE CompanySeq = @CompanySeq       
                                                            AND MinorSeq = H.ValueSeq) END AS ItemClassLSeq,  -- 품목대분류코드  
           CASE WHEN ISNULL(G.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'')       
                                                            FROM _TDAUMinor WITH(NOLOCK)       
                                                            WHERE CompanySeq = @CompanySeq       
                                                            AND MinorSeq = G.ValueSeq) END AS ItemClassMName,  -- 품목중분류  
           CASE WHEN ISNULL(G.ValueSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorSeq,0)       
                                                            FROM _TDAUMinor WITH(NOLOCK)       
                                                            WHERE CompanySeq = @CompanySeq       
                                                            AND MinorSeq = G.ValueSeq) END AS ItemClassMSeq,  -- 품목중분류코드  
           ISNULL(F.MinorName,'')       AS ItemClassSName, -- 품목소분류    
           ISNULL(D.UMItemClass,0)      AS ItemClassSSeq,  -- 품목소분류코드   
           ISNULL((SELECT MinorName FROM _TDASMinor where CompanySeq = @CompanySeq AND MinorSeq = P.SMPurKind), '') AS SMPurKindName, -- 납기구분  
           ISNULL(C.TrustCustSeq,0)     AS CustSeq,  
           ISNULL((SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CustSeq = C.TrustCustSeq),'') AS CustName, 
           ROUND(ISNULL(A.STDStockQty, 0), @EnvMatQty) - ROUND(ISNULL(A.STDPrevQty, 0), @EnvMatQty) AS AdjustQty
      FROM #GetInOutStock AS A  
           LEFT OUTER JOIN _TDAItem  AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                            AND A.ItemSeq    = B.ItemSeq  
           LEFT OUTER JOIN _TDAWHSub AS C WITH (NOLOCK) ON C.CompanySeq    = @CompanySeq  
                                                       AND A.FunctionWHSeq = C.WHSeq  
           LEFT OUTER JOIN _TDAItemClass AS D WITH (NOLOCK) ON B.CompanySeq = D.CompanySeq  
                                                           AND B.ItemSeq    = D.ItemSeq  
                                                           AND D.UMajorItemClass IN (2001,2004)  
           LEFT OUTER JOIN _TESMBItemStdPrice AS E WITH (NOLOCK) ON E.CompanySeq = @CompanySeq  
                                                                AND ((@GoodPriceUnit = 5502002 AND E.CostUnit = @AccUnit)              
                                                                     OR (@GoodPriceUnit = 5502003 AND E.CostUnit = @BizUnit))  
                                                                AND A.ItemSeq    = E.ItemSeq  
           LEFT OUTER JOIN _TDAUMinor AS F WITH(NOLOCK) ON D.CompanySeq  = F.CompanySeq      
                                                       AND D.UMItemClass = F.MinorSeq      
           LEFT OUTER JOIN _TDAUMinorValue AS G WITH(NOLOCK) ON F.CompanySeq = G.CompanySeq       
                                                          AND F.MinorSeq   = G.MinorSeq    
                                                          AND G.Serl       IN (1001,2001)    
                                                          AND G.MajorSeq IN (2001,2004)    
           LEFT OUTER JOIN _TDAUMinorValue AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq       
                                                            AND G.ValueSeq   = H.MinorSeq       
                                                            AND H.Serl       = 2001                                      
                                                            AND H.MajorSeq IN (2002,2005)    
           LEFT OUTER JOIN _TDAWH AS I WITH (NOLOCK) ON I.CompanySeq = @CompanySeq  
                                                    AND A.WHSeq      = I.WHSeq  
           LEFT OUTER JOIN _TDASMinor AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq  
                                                       AND I.SMWHKind = J.MinorSeq  
           LEFT OUTER JOIN _TDAItemPurchase AS P WITH(NOLOCK) ON B.CompanySeq = P.CompanySeq  
                                                             AND B.ItemSeq    = P.ItemSeq                                                             
                                                            
     WHERE (A.STDPrevQty <> 0 OR A.STDInQty <> 0 OR A.STDOutQty <> 0 OR A.STDStockQty <> 0)  
       AND ROUND(ISNULL(A.STDStockQty, 0), @EnvMatQty) <> 0 
     ORDER BY J.MinorName, I.SortSeq, A.WHSeq, A.FunctionWHSeq, B.ItemNo, B.ItemName, A.ItemSeq, A.UnitSeq  

RETURN
GO
exec KPXCM_SLGWHAssyStockListAdjustQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMWHKind />
    <WHKindName />
    <QryType>B</QryType>
    <QryTypeName>자산재고</QryTypeName>
    <IsUnitQry>0</IsUnitQry>
    <BizUnit>1</BizUnit>
    <BizUnitName>상정-본사</BizUnitName>
    <StdYM>201511</StdYM>
    <CustSeq />
    <CustName />
    <AssetSeq />
    <AssetName />
    <WHSeq />
    <WHName />
    <FactUnit />
    <FactUnitName />
    <ItemClassLSeq />
    <ItemClassLName />
    <ItemClassMSeq />
    <ItemClassMName />
    <ItemClassSSeq />
    <ItemClassSName />
    <ItemName />
    <ItemNo />
    <Spec />
    <IsSubDisplay>0</IsSubDisplay>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032828,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027704