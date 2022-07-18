
IF OBJECT_ID('costel_SLGMoveInvoicePrint') IS NOT NULL
    DROP PROC costel_SLGMoveInvoicePrint 
GO

-- v2013.11.11 

-- 이동입력거래명세서출력물_costel by이재천
CREATE PROC dbo.costel_SLGMoveInvoicePrint                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle  INT,
            @InOutSeq   INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @InOutSeq = InOutSeq       
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (InOutSeq INT )
    
    CREATE TABLE #TLGInOutDaily
    (
        IDX_NO      INT IDENTITY, 
        InOutSeq    INT, 
    ) 
    
    INSERT INTO #TLGInOutDaily (InOutSeq) 
    SELECT @InOutSeq 
    
    DECLARE @TaxNo      NVARCHAR(100), 
            @TaxName    NVARCHAR(100), 
            @TaxOwner   NVARCHAR(100), 
            @VatAddr    NVARCHAR(200), 
            @VatBizTy   NVARCHAR(100), 
            @VatBizItem NVARCHAR(100),  
            @SMTaxationType INT
    
    SELECT @SMTaxationType = 4128002
    SELECT @TaxNo = TaxNo FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    SELECT @TaxName = TaxName FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    SELECT @TaxOwner = Owner FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    SELECT @VatAddr = ISNULL(Addr1,'') + ISNULL(Addr2,'') FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    SELECT @VatBizTy = BizType FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    SELECT @VatBizItem = BizItem FROM _TDATaxUnit WHERE CompanySeq = @CompanySeq AND SMTaxationType = @SMTaxationType
    
    CREATE TABLE #TMP_SourceTable 
        (
         IDOrder    INT, 
         TableName  NVARCHAR(100)
        )
    INSERT INTO #TMP_SourceTable(IDOrder,TableName) 
    SELECT 1, '_TLGInOutReqItem'
    
    CREATE TABLE #TCOMSourceTracking 
            (IDX_NO  INT, 
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
          
    EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TLGInOutDailyItem',  -- 기준 테이블
             @TempTableName = '#TLGInOutDaily',  -- 기준템프테이블
             @TempSeqColumnName = 'InOutSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = '',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 



    SELECT A.IDX_NO, C.Seq AS ReqSeq, A.InOutSeq, B.CCtrSeq 
      INTO #TLGInOutDailySub
      FROM #TLGInOutDaily       AS A
      LEFT OUTER JOIN #TCOMSourceTracking  AS C              ON ( C.IDX_NO = A.IDX_NO) 
      LEFT OUTER JOIN _TLGInOutReqItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = C.Seq ) 
     GROUP BY A.IDX_NO, C.Seq, A.InOutSeq, B.CCtrSeq

    SELECT DATEPART(YY,C.InOutDate) AS YY, 
           DATEPART(MM,C.InOutDate) AS MM, 
           DATEPART(DD,C.InOutDate) AS DD, 
           C.InOutNo, 
           E.ItemNo, 
           E.ItemName, 
           E.Spec, 
           D.Qty, 
           F.CustName AS BKCustName, 
           G.CustName, 
           ISNULL(H.KorAddr1,'') + ISNULL(H.KorAddr2,'') AS Addr, 
           G.Owner, 
           STUFF(STUFF(G.BizNo,4,0,'-'),7,0,'-') AS BizNo, 
           @TaxNo       AS My_TaxNo, 
           @TaxName     AS My_TaxName, 
           @TaxOwner    AS My_TaxOwner, 
           @VatAddr     AS My_VatAddr, 
           @VatBizTy    AS My_VatBizTy, 
           @VatBizItem  AS My_VatBizItem, 
           G.BizType, 
           G.BizKind, 
           C.Remark, 
           C.Memo 
      
      FROM #TLGInOutDailySub             AS A 
      LEFT OUTER JOIN _TSLOrder          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TLGInOutDaily     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.InOutSeq = A.InOutSeq AND C.InOutType IN (80,81) )
      LEFT OUTER JOIN _TLGInOutDailyItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.InOutSeq = C.InOutSeq AND D.InOutType IN (80,81) ) 
      LEFT OUTER JOIN _TDAItem           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = D.ItemSeq ) 
      LEFT OUTER JOIN _TDACust           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = B.BKCustSeq ) 
      LEFT OUTER JOIN _TDACust           AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDACustAdd        AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = B.CustSeq ) 
    
    RETURN

GO