  
IF OBJECT_ID('KPX_SSLCustStockQuery') IS NOT NULL   
    DROP PROC KPX_SSLCustStockQuery  
GO  
  
-- v2014.11.18  
  
-- 거래처재고현황-조회 by 이재천   
CREATE PROC KPX_SSLCustStockQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @InOutKind      INT, 
            @StdDate        NCHAR(8), 
            @CustName       NVARCHAR(100), 
            @DVPlaceName    NVARCHAR(100), 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @InOutKind    = ISNULL( InOutKind  , 0 ), 
           @StdDate      = ISNULL( StdDate    , '' ), 
           @CustName     = ISNULL( CustName   , '' ), 
           @DVPlaceName  = ISNULL( DVPlaceName, '' ),
           @ItemName     = ISNULL( ItemName   , '' ), 
           @ItemNo       = ISNULL( ItemNo     , '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            InOutKind      INT, 
            StdDate        NCHAR(8), 
            CustName       NVARCHAR(100),
            DVPlaceName    NVARCHAR(100),
            ItemName       NVARCHAR(100),
            ItemNo         NVARCHAR(100) 
           )    
    
    DECLARE @FromDate NCHAR(8), 
            @Day      INT
    
    SELECT @Day = ISNULL((SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 6 AND EnvSerl = 1),0)
    SELECT @FromDate = (SELECT CONVERT(NCHAR(8),DATEADD(DAY,@Day * (-1),@StdDate),112))
    
    IF @StdDate = '' 
    BEGIN
        SELECT @FromDate = '' 
        SELECT @StdDate = '99991231'
    END 
        
    
    
    
    CREATE TABLE #SMExpKind
    (
        SMExpKind       INT, 
        InOutKind       INT 
    )
    
    
    
    -- 내수수출구분 조회하기위한 셋팅 
    IF @InOutKind = 8918001 
    BEGIN 
        INSERT INTO #SMExpKind (SMExpKind, InOutKind) 
        SELECT MinorSeq,8918001 FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 8009 AND Serl = 1001 AND ValueText = '1'
    END 
    ELSE IF @InOutKind = 0 
    BEGIN
        INSERT INTO #SMExpKind (SMExpKind, InOutKind) 
        SELECT MinorSeq,8918001 FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 8009 AND Serl = 1001 AND ValueText = '1'
        
        INSERT INTO #SMExpKind (SMExpKind, InOutKind) 
        SELECT MinorSeq,8918002 FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 8009 AND Serl = 1002 AND ValueText = '1'
        
    END 
    ELSE 
    BEGIN  
        INSERT INTO #SMExpKind (SMExpKind, InOutKind) 
        SELECT MinorSeq, 8918002 FROM _TDASminorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 8009 AND Serl = 1002 AND ValueText = '1'
    END 
    
    
    CREATE TABLE #Invoice 
    (
        IDX_NO      INT IDENTITY, 
        InvoiceSeq  INT, 
        InvoiceSerl INT, 
        CustSeq     INT, 
        DVPlaceSeq  INT, 
        SMExpKind   INT, 
        ItemSeq     INT, 
        AssetSeq    INT, 
        UnitSeq     INT, 
        Qty         DECIMAL(19,5), 
        CustName    NVARCHAR(100), 
        CustNo      NVARCHAR(100), 
        DVPlaceName NVARCHAR(100), 
        ItemName    NVARCHAR(100), 
        ItemNo      NVARCHAR(100), 
        Spec        NVARCHAR(100), 
        InOutKind   INT 
    )
    
    INSERT INTO #Invoice 
    ( 
        InvoiceSeq, InvoiceSerl, CustSeq, DVPlaceSeq, SMExpKind, 
        ItemSeq, AssetSeq, UnitSeq, Qty, CustName, 
        CustNo, DVPlaceName, ItemName, ItemNo, Spec, 
        InOutKind
    ) 
    SELECT A.InvoiceSeq, B.InvoiceSerl, A.CustSeq, A.DVPlaceSeq, A.SMExpKind, 
           B.ItemSeq, E.AssetSeq, B.UnitSeq, B.Qty, C.CustName, 
           C.CustNo, D.DVPlaceName, E.ItemName, E.ItemNo, E.Spec, 
           F.InOutKind 
      FROM _TSLInvoice                  AS A 
      JOIN _TSLInvoiceItem              AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TSLDeliveryCust  AS D ON ( D.CompanySeq = @CompanySeq AND D.DVPlaceSeq = A.DVPlaceSeq ) 
      LEFT OUTER JOIN _TDAItem          AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
      CROSS APPLY (SELECT Z.SMExpKind, MAX(InOutKind) AS InOutKind 
                     FROM #SMExpKind AS Z 
                    WHERE Z.SMExpKind = A.SMExpKind 
                    GROUP BY Z.SMExpKind
                   ) AS F 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.IsDelvCfm = '1' 
       AND (A.InvoiceDate BETWEEN @FromDate AND @StdDate)
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%') 
       AND (@DVPlaceName = '' OR D.DVPlaceName LIKE @DVPlaceName + '%') 
       AND (@ItemName = '' OR E.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR E.ItemNo LIKE @ItemNo + '%') 
       AND (@InOutKind = 0 OR F.InOutKind = @InOutKind)
    
    
    CREATE TABLE #TMP_ProgressTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    ) 
    
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TSLSalesItem'   -- 데이터 찾을 테이블
    
    CREATE TABLE #TCOMProgressTracking
    (
        IDX_NO  INT,  
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
    
    EXEC _SCOMProgressTracking @CompanySeq = @CompanySeq, 
                               @TableName = '_TSLInvoiceItem',    -- 기준이 되는 테이블
                               @TempTableName = '#Invoice',  -- 기준이 되는 템프테이블
                               @TempSeqColumnName = 'InvoiceSeq',  -- 템프테이블의 Seq
                               @TempSerlColumnName = 'InvoiceSerl',  -- 템프테이블의 Serl
                               @TempSubSerlColumnName = ''  
    
    SELECT MAX(MinorName) AS InOutKindName, 
           A.InOutKind, 
           MAX(A.CustName) AS CustName, 
           MAX(A.CustNo) AS CustNo,
           A.CustSeq, 
           MAX(A.DVPlaceName) AS DVPlaceName, 
           A.DVPlaceSeq, 
           MAX(A.ItemName) AS ItemName, 
           MAX(A.ItemNo) AS ItemNo, 
           MAX(A.Spec) AS Spec,
           A.ItemSeq, 
           MAX(E.ItemClasLName) AS ItemClasLName, 
           MAX(E.ItemClasMName) AS ItemClasMName, 
           MAX(E.ItemClasSName) AS ItemClasSName, 
           MAX(F.AssetName) AS AssetName, 
           MAX(A.AssetSeq) AS AssetSeq, 
           MAX(A.UnitSeq) AS UnitSeq, 
           MAX(G.UnitName) AS UnitName, 
           SUM(ISNULL(A.Qty,0)) AS OutQty, 
           SUM(ISNULL(C.Qty,0)) AS SalesQty,  
           SUM(ISNULL(A.Qty,0)) - SUM(ISNULL(C.Qty,0)) AS DiffQty 
      FROM #Invoice AS A 
      LEFT OUTER JOIN #TCOMProgressTracking AS B ON ( A.IDX_NO = B.IDX_NO ) 
      LEFT OUTER JOIN _TSLSalesItem         AS C ON ( C.CompanySeq = @CompanySeq AND C.SalesSeq = B.Seq AND C.SalesSerl = B.Serl ) 
      LEFT OUTER JOIN _TSLSales             AS D ON ( D.CompanySeq = @CompanySeq AND D.SalesSeq = C.SalesSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS E ON ( E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset         AS F ON ( F.CompanySeq = @CompanySeq AND F.AssetSeq = A.AssetSeq ) 
      LEFT OUTER JOIN _TDAUnit              AS G ON ( G.CompanySeq = @CompanySeq AND G.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDASMinor            AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.InOutKind ) 
     GROUP BY A.CustSeq, A.DVPlaceSeq, A.ItemSeq, A.InOutKind 
    
    RETURN  
GO 

exec KPX_SSLCustStockQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InOutKind />
    <StdDate>20141118</StdDate>
    <CustName />
    <DVPlaceName />
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025939,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021327
    