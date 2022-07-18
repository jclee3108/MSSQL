  
IF OBJECT_ID('jongie_SSLSalesItemGroupListQuery') IS NOT NULL   
    DROP PROC jongie_SSLSalesItemGroupListQuery  
GO  
  
-- v2013.09.23  
  
-- 일별실적집계조회_jongie(조회) by 이재천   
CREATE PROC jongie_SSLSalesItemGroupListQuery  
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
            @InvoiceDateFr  NVARCHAR(8), 
            @InvoiceDateTo  NVARCHAR(8), 
            @SMExpKind      INT, 
            @UMOutKind      INT, 
            @UMCustClass    INT, 
            @EmpSeq         INT, 
            @CustSeq        INT, 
            @ItemName       NVARCHAR(200), 
            @ItemNo         NVARCHAR(100), 
            @ChkItemName    NVARCHAR(1), 
            @ChkCustName    NVARCHAR(1), 
            @ChkEmpName     NVARCHAR(1) 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
	SELECT @InvoiceDateFr   = ISNULL(InvoiceDateFr,''), 
           @InvoiceDateTo   = ISNULL(InvoiceDateTo,''), 
           @SMExpKind       = ISNULL(SMExpKind,0), 
           @UMOutKind       = ISNULL(UMOutKind,0), 
           @UMCustClass     = ISNULL(UMCustClass,0), 
           @EmpSeq          = ISNULL(EmpSeq,0), 
           @CustSeq         = ISNULL(CustSeq,0), 
           @ItemName        = ISNULL(ItemName,''), 
           @ItemNo          = ISNULL(ItemNo,''), 
           @ChkItemName     = ISNULL(ChkItemName,0), 
           @ChkCustName     = ISNULL(ChkCustName,0), 
           @ChkEmpName      = ISNULL(ChkEmpName,0) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( 
            InvoiceDateFr  NVARCHAR(8), 
            InvoiceDateTo  NVARCHAR(8), 
            SMExpKind      INT, 
            UMOutKind      INT, 
            UMCustClass    INT, 
            EmpSeq         INT, 
            CustSeq        INT, 
            ItemName       NVARCHAR(200),
            ItemNo         NVARCHAR(100),
            ChkItemName    NVARCHAR(1), 
            ChkCustName    NVARCHAR(1), 
            ChkEmpName     NVARCHAR(1) 
           ) 
      
    DECLARE @EnvValue INT
    SELECT @EnvValue = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 1 AND EnvSerl = 1
    
    -- 집계하기 전 조회조건에 대한 데이터 담기
   
    SELECT A.EmpSeq, 
           F.EmpName,  
           E.CustName, 
           A.CustSeq, 
           ISNULL(A.DVPlaceSeq,0) AS DelvCustSeq, 
           ISNULL(G.DVPlaceName,'') AS DelvCustName, 
           D.ItemName, 
           D.ItemNo, 
           D.Spec, 
           B.ItemSeq, 
           B.Qty, 
           ISNULL(CONVERT(DECIMAL(19,5),(B.Qty / (H.ConvNum / H.ConvDen))),0) AS BoxUnitQty, 
           B.CurAmt, 
           B.CurVAT, 
           B.CurAmt + B.CurVAT AS TotCurAmt, 
           @ChkCustName AS ChkCustName, 
           @ChkItemName AS ChkItemName, 
           @ChkEmpName AS ChkEmpName
    
      INTO #TSLInvoice
      FROM _TSLInvoice                 AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TSLInvoiceItem  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      LEFT OUTER JOIN _TDACustClass    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq AND UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAItem         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDACust         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TSLDeliveryCust AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DVPlaceSeq = A.DVPlaceSeq ) 
      LEFT OUTER JOIN _TDAItemUnit     AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.UnitSeq = @EnvValue AND H.ItemSeq = B.ItemSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo) 
       AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind) 
       AND (@UMOutKind = 0 OR A.UMOutKind = @UMOutKind) 
       AND (@UMCustClass = 0 OR C.UMCustClass = @UMCustClass) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
       AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%') 
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')
    
    -- 최종조회 
    SELECT SUM(Qty) AS Qty, 
           SUM(BoxUnitQty) AS BoxUnitQty, 
           SUM(CurAmt) AS CurAmt, 
           SUM(CurVAT) AS CurVAT, 
           SUM(CurAmt) + SUM(CurVAT) AS TotCurAmt, 
           CASE WHEN (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN EmpName 
                ELSE '' 
                END AS EmpName, 
           CASE WHEN (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN EmpSeq 
                ELSE '' 
                END AS EmpSeq, 
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN ItemName 
                ELSE '' 
                END AS ItemName,
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN ItemSeq 
                ELSE '' 
                END AS ItemSeq,
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN ItemNo 
                ELSE '' 
                END AS ItemNo,
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN Spec 
                ELSE '' 
                END AS Spec,
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN CustName 
                ELSE '' 
                END AS CustName, 
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN CustSeq 
                ELSE '' 
                END AS CustSeq, 
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN DelvCustName 
                ELSE '' 
                END AS DelvCustName, 
           CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                  OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                  OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                  OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                THEN DelvCustSeq 
                ELSE '' 
                END AS DelvCustSeq
      
      FROM #TSLInvoice 
     GROUP BY CASE WHEN (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                       THEN EmpName 
                       ELSE '' 
                       END, 
              CASE WHEN (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN EmpSeq 
                   ELSE '' 
                   END, 
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN ItemName 
                   ELSE '' 
                   END,
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN ItemSeq 
                   ELSE '' 
                   END,
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN ItemNo 
                   ELSE '' 
                   END,
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 0)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN Spec 
                   ELSE '' 
                   END,
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN CustName 
                   ELSE '' 
                   END, 
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN CustSeq 
                   ELSE '' 
                   END, 
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN DelvCustName 
                   ELSE '' 
                   END, 
              CASE WHEN (ChkEmpName = 0 AND ChkItemName = 0 AND ChkCustName = 1)
                     OR (ChkEmpName = 0 AND ChkItemName = 1 AND ChkCustName = 1)
                     OR (ChkEmpName = 1 AND ChkItemName = 0 AND ChkCustName = 1) 
                     OR (ChkEmpName = 1 AND ChkItemName = 1 AND ChkCustName = 1) 
                   THEN DelvCustSeq 
                   ELSE '' 
                   END
    
    RETURN  
GO
exec jongie_SSLSalesItemGroupListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <InvoiceDateFr>20130923</InvoiceDateFr>
    <InvoiceDateTo>20130923</InvoiceDateTo>
    <SMExpKind />
    <UMOutKind />
    <UMCustClass />
    <EmpSeq />
    <CustSeq />
    <ItemName />
    <ItemNo />
    <ChkEmpName>1</ChkEmpName>
    <ChkCustName>1</ChkCustName>
    <ChkItemName>1</ChkItemName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017907,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015318