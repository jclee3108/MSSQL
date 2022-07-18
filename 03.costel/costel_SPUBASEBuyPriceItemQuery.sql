
IF OBJECT_ID('costel_SPUBASEBuyPriceItemQuery')IS NOT NULL 
    DROP PROC costel_SPUBASEBuyPriceItemQuery
GO

-- v2013.10.01 

-- 구매품목가져오기_costel(조회) by이재천
CREATE PROC costel_SPUBASEBuyPriceItemQuery 
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
            @ItemSeq    INT, 
            @CustSeq    INT, 
            @FrDate     NCHAR(8), 
            @ToDate     NCHAR(8), 
            @Last       INT, 
            @ItemName   NVARCHAR(100), 
            @ItemNo     NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
        
    SELECT @CustSeq     = ISNULL(CustSeq    , 0) , 
           @ItemSeq     = ISNULL(ItemSeq    , 0) , 
           @FrDate      = ISNULL(FromDate   , ''), 
           @ToDate      = ISNULL(ToDate     , ''), 
           @ItemName    = ISNULL(ItemName   , ''), 
           @ItemNo      = ISNULL(ItemNo     , ''), 
           @Last        = ISNULL(Last       , 0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)             
      WITH (  
            CustSeq     INT, 
            ItemSeq     INT, 
            FromDate    NCHAR(8), 
            ToDate      NCHAR(8), 
            ItemName    NVARCHAR(100), 
            ItemNo      NVARCHAR(100), 
            Last        INT 
           )            
    
    IF ISNULL(@ToDate,'') = '' SELECT @ToDate = '99991231'    
    
    -- 최종조회    
    SELECT A.Serl        AS Serl        , -- Serl    
           A.ItemSeq     AS ItemSeq     ,    
           A.ItemSeq     AS ItemOldSeq  ,    
           C.CustName    AS CustName    , -- 거래처명    
           E.CurrName    AS CurrName    , -- 화폐    
           D.UnitName    AS UnitName    , -- 구매단위명    
           F.CustName    AS MakerName   , --  Maker    
           A.Price       AS Price       , -- 단구    
           A.IsPrice     AS IsPrice     , -- 대표구분    
           A.MinQty      AS MinQty      , -- 구매최소수량    
           A.StepQty     AS StepQty     , -- 구매간격수량    
           A.StartDate   AS StartDate   , -- 적용시작일    
           A.EndDate     AS EndDate     , -- 적용종료일    
           A.ImpType     AS ImpType     , -- 수입구분    
           A.Remark      AS Remark      , -- 비고    
           ''            AS StkUnitName , -- 재고단위    
           ''            AS StdUnitQty  , -- 재고단위 환산수량    
           A.ImpType     AS ImpType     , -- 구매구분    
           A.CustSeq     AS CustSeq     , -- 구매처코드    
           A.CustSeq     AS CustOldSeq  , -- 구매구분(OLD)    
           A.UnitSeq     AS UnitSeq     , -- 구매단위코드    
           A.UnitSeq     AS UnitOldSeq  , -- 구매단위코드(OLD)    
           A.CurrSeq     AS CurrSeq     , -- 화폐코드    
           A.CurrSeq     AS CurrOldSeq  , -- 화폐코드(Old)    
           A.MakerSeq    AS MakerSeq    ,-- MakerSeq    
           A.WHSeq       AS WHSeq       ,  
           G.WHName      AS WHName      ,  
           A.PreLeadTime AS PreLeadTime ,  
           A.LeadTime    AS LeadTime    ,  
           A.PostLeadTime AS PostLeadTime,  
           B.ItemName    AS ItemName    ,  
           B.ItemNo      AS ItemNo      ,  
           B.Spec        AS Spec        ,  
           S.AssetName   AS AssetName   ,  
           A.QCLeadTime  AS QCLeadTime  , 
           CONVERT(INT,REPLACE(I.MinorName,'%','')) AS VATRate, -- 부가세율
           A.UnitSeq     AS STDUnitSeq, 
           D.UnitName    AS STDUnitName  
     FROM _TPUBASEBuyPriceItem      AS A WITH(NOLOCK)     
                JOIN _TDAItem       AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq ) 
                JOIN _TDAItemAsset  AS S WITH(NOLOCK) ON ( A.CompanySeq = S.CompanySeq AND B.AssetSeq = S.AssetSeq ) 
                JOIN _TDACust       AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq ) 
     LEFT OUTER JOIN _TDAUnit       AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.UnitSeq = D.UnitSeq ) 
     LEFT OUTER JOIN _TDACurr       AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CurrSeq = E.CurrSeq ) 
     LEFT OUTER JOIN _TDACust       AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.MakerSeq = F.CustSeq ) 
     LEFT OUTER JOIN _TDAWH         AS G WITH(NOLOCK) ON ( A.CompanySeq = G.CompanySeq AND A.WHSeq = G.WHSeq ) 
     LEFT OUTER JOIN _TDAItemSales  AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = A.ItemSeq ) 
     LEFT OUTER JOIN _TDASMinor     AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.SMVatType ) 
  
    WHERE A.CompanySeq  = @CompanySeq  
      AND (@CustSeq     = 0 OR A.CustSeq   = @CustSeq)    
      AND (@ItemSeq     = 0 OR A.ItemSeq   = @ItemSeq)    
      AND  A.StartDate BETWEEN @FrDate  AND @ToDate    
      AND (@Last        = 0 OR A.EndDate = (SELECT TOP 1 EndDate   
                                              FROM _TPUBASEBuyPriceItem WITH(NOLOCK)  
                                             WHERE CompanySeq = A.CompanySeq  
                                               AND ItemSeq = A.ItemSeq  
                                               AND CustSeq = A.CustSeq  
                                             ORDER BY EndDate DESC ))  
     AND (@ItemName    ='' OR B.ItemName LIKE  @ItemName + '%')  
     AND (@ItemNo      ='' OR B.ItemNo   LIKE  @ItemNo + '%')  
  
    ORDER BY C.CustName,B.ItemNo, A.StartDate    
    
    RETURN 
GO
exec costel_SPUBASEBuyPriceItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CustSeq>0</CustSeq>
    <ItemName />
    <ItemNo />
    <Last>1</Last>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018264,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015504
    
--select * from _TDAItemSales where companyseq = 1 