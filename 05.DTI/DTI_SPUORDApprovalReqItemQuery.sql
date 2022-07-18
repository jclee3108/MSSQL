
IF OBJECT_ID('DTI_SPUORDApprovalReqItemQuery') IS NOT NULL
    DROP PROC DTI_SPUORDApprovalReqItemQuery

GO

-- v2013.06.12

-- 구매품의세부조회_DTI By이재천
CREATE PROC DTI_SPUORDApprovalReqItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    DECLARE @docHandle     INT,
            @ApproReqSerl  INT
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #TPUORDApprovalReqItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDApprovalReqItem'   
    IF @@ERROR <> 0 RETURN    

    SELECT @ApproReqSerl = ApproReqSerl FROM #TPUORDApprovalReqItem
    -------------------
    --요청번호 추적 ---
    -------------------
    CREATE TABLE #TMP_SOURCETABLE          
    (          
        IDOrder INT,          
        TABLENAME   NVARCHAR(100)          
    )   
    CREATE TABLE #TMP_SOURCEITEM    
    (          
        IDX_NO     INT IDENTITY,          
        SourceSeq  INT,          
        SourceSerl INT 
    )
    CREATE TABLE #TCOMSourceTracking          
    (           
        IDX_NO      INT,          
        IDOrder     INT,          
        Seq         INT,          
        Serl        INT,          
        SubSerl     INT,          
        Qty         DECIMAL(19, 5),          
        STDQty      DECIMAL(19, 5),          
        Amt         DECIMAL(19, 5),          
        VAT         DECIMAL(19, 5)          
    )   

    INSERT #TMP_SOURCETABLE    
    SELECT '','_TPUORDPOReqItem'    
    IF ISNULL(@ApproReqSerl,0) = 0 
    BEGIN
        INSERT #TMP_SOURCEITEM(SourceSeq, SourceSerl)
        SELECT A.ApproReqSeq    , B.ApproReqSerl 
          FROM #TPUORDApprovalReqItem AS A JOIN _TPUORDApprovalReqItem AS B ON ( A.ApproReqSeq = B.ApproReqSeq ) 
         WHERE B.CompanySeq = @CompanySeq
    END
    ELSE
    BEGIN
        INSERT #TMP_SOURCEITEM(SourceSeq, SourceSerl)
        SELECT A.ApproReqSeq    , A.ApproReqSerl 
          FROM #TPUORDApprovalReqItem          AS A
    END
  
    EXEC _SCOMSourceTracking @CompanySeq, '_TPUORDApprovalReqItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''          
    --------------------
    --요청번호 추적 끝--
    --------------------  
  
    SELECT A.ApproReqSeq, A.ApproReqSerl, A.ItemSeq , A.MakerSeq   , A.UnitSeq, 
           A.Qty        , A.Price       , A.CurAmt  , A.CustSeq    , A.Remark ,
           A.ExRate     , A.CurrSeq     , A.DomAmt  , A.StdUnitSeq , A.StdUnitQty,
           A.DelvDate   , A.SMImpType   , A.DCRate  , A.OriginPrice, A.SMPayType ,
           B.ItemName   , B.ItemNo      , B.Spec    , C.UnitName   , D.CustName  , D.CustNo, 
           E.CurrName   , A.CurVAT      , A.DomPrice, A.DomVAT     , A.IsVAT     ,
           A.CurAmt + A.CurVAT AS TotCurAmt,
           A.DomAmt + A.DomVAT AS TotDomAmt,
           --H.VatRate,
           (SELECT CustName FROM _TDACust WHERE Companyseq = A.CompanySeq AND CustSeq = A.MakerSeq)   AS MakerName,
           (SELECT UnitName FROM _WTDAUnit WHERE Companyseq = A.CompanySeq AND UnitSeq = A.STDUnitSeq) AS STDUnitName,
           Z.IDX_NO   AS IDX_NO,
           A.PJTSeq, F.PJTName, F.PJTNo, A.WBSSeq, O.DelvDate AS ReqDelvDate,
           A.WHSeq    AS WHSeq ,
           P.WHName   AS WHName,
           CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                     ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                                                   ELSE 0 END AS VATRate,
           (SELECT CurrName  FROM _TDACurr   WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS  CurrName,
           (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMImpType) AS SMImpTypeName,
           A.Memo1 AS SalesCustSeq, 
           A.Memo2 AS EndUserSeq, 
           A.Memo3, 
           A.Memo4, 
           A.Memo5, 
           A.Memo6,
           H.CustName AS SalesCustName,
           I.CustName AS EndUserName
            
      FROM #TPUORDApprovalReqItem     AS Z WITH(NOLOCK)  
      JOIN _TPUORDApprovalReqItem     AS A WITH(NOLOCK) ON ( Z.ApproReqSeq = A.ApproReqSeq AND (@ApproReqSerl IS NULL OR Z.ApproReqSerl = A.ApproReqSerl))
      JOIN _TPUORDApprovalReq         AS J WITH(NOLOCK) ON ( Z.ApproReqSeq = J.ApproReqSeq AND J.CompanySeq = @CompanySeq )
      LEFT OUTER JOIN _TDAItem        AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit        AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDACust        AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.CustSeq = D.CustSeq ) 
      LEFT OUTER JOIN _TDACurr        AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.CurrSeq = E.CurrSeq ) 
      LEFT OUTER JOIN _TPJTProject    AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.PJTSeq = F.PJTSeq ) 
      --LEFT OUTER JOIN _TPJTWBS      AS G WITH(NOLOCK) ON ( A.CompanySeq = G.CompanySeq AND A.PJTSeq = G.PJTSeq AND A.WBSSeq = G.WBSSeq ) 
      LEFT OUTER JOIN _TDAItemSales   AS V WITH(NOLOCK) ON ( A.CompanySeq = V.CompanySeq AND A.ItemSeq = V.ItemSeq ) 
      LEFT OUTER JOIN _TDAVATRate     AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND V.SMVatType = Q.SMVatType AND J.ApproReqDate BETWEEN Q.SDate AND Q.EDate ) 
      LEFT OUTER JOIN _TDASMinorValue AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND A.SMImpType  = R.MinorSeq AND R.Serl = 1002 )
      LEFT OUTER JOIN _TDASMinorValue  AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND A.SMImpType  = S.MinorSeq AND S.Serl = 1002 )
      --LEFT OUTER JOIN _TDAVATRate AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND J.ApproReqDate BETWEEN H.SDate AND H.EDate AND SMVatType = 8028001
      LEFT OUTER JOIN #TMP_SOURCEITEM AS M ON ( A.ApproReqSeq = M.SourceSeq AND A.ApproReqSerl = M.SourceSerl )
      LEFT OUTER JOIN #TCOMSourceTracking AS N ON ( M.IDX_NO = N.IDX_NO )
      LEFT OUTER JOIN _TPUORDPOReqItem AS O WITH(NOLOCK) ON ( A.CompanySeq = O.CompanySeq AND N.Seq = O.POReqSeq AND N.Serl = O.POReqSerl )
      LEFT OUTER JOIN _TDAWH           AS P WITH(NOLOCK) ON ( A.CompanySeq = P.CompanySeq AND A.WHSeq = P.WHSeq )
      LEFT OUTER JOIN _TDACust         AS H WITH(NOLOCk) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.Memo1 ) 
      LEFT OUTER JOIN _TDACust         AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.Memo2 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND (@WorkingTag <> 'JQuery' OR (@WorkingTag = 'JQuery' AND A.IsStop <> '1') )  -- 구매품의에서 발주로 점프시 중단건은 조회되지 않도록 추가 2011. 9. 15 hkim  
        
     
     RETURN
GO
exec DTI_SPUORDApprovalReqItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ApproReqSeq>16569</ApproReqSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015926,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013785