
IF OBJECT_ID('costel_SSLInvoiceRptQuery')IS NOT NULL
    DROP PROC costel_SSLInvoiceRptQuery 
GO

-- v2013.11.06 

-- 거래명세서출력물_costel by이재천
CREATE PROC costel_SSLInvoiceRptQuery      
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle    INT,      
            @InvoiceSeq   INT,     
            @TotCurAmt    DECIMAL(19,5),    
            @TotVAT       DECIMAL(19,5),     
            @TotAmt       DECIMAL(19,5),     -- 20101224 김준식 추가  
            @TotDomAmt    DECIMAL(19,5),     -- 20101224 김준식 추가  
            @InvoiceDate  NCHAR(8),  
            @HapAmt       Money,  
            @ABSHapAmt    Money,  
            @HanAmt       NVARCHAR(100),  
            @HapDomAmt    Money,            -- 20101224 김준식 추가  
            @ABSHapDomAmt Money,            -- 20101224 김준식 추가           
            @HanDomAmt    NVARCHAR(100),    -- 20101224 김준식 추가  
  
            -- 생산사양용  
            @Seq            INT,   
            @OrderSeq       INT,   
            @OrderSerl      INT,   
            @SubSeq         INT,   
            @SpecName       NVARCHAR(200),     
            @SpecValue      NVARCHAR(200),  
            @CustSeq        INT      
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    -- Temp에 INSERT        
    
    SELECT  @InvoiceSeq  = InvoiceSeq,  
            @InvoiceDate = InvoiceDate    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
    WITH (InvoiceSeq INT,  
          InvoiceDate NCHAR(8))     
            
    -- 거래처품목명칭을 가져오기위해 거래처코드 조회    
    SELECT @CustSeq = CustSeq    
      FROM _TSLInvoice   
     WHERE CompanySeq = @CompanySeq  
       AND InvoiceSeq = @InvoiceSeq                              
    
    
/***********************************************************************************************************************************************/    
    CREATE TABLE #Tmp_InvoiceProg(IDX_NO INT IDENTITY, InvoiceSeq INT, InvoiceSerl INT, OrderSeq   INT NULL,   OrderSerl INT NULL)       
  
    -- 원천테이블  
    CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))          
  
    -- 원천 데이터 테이블  
    CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,          
                                      Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))      
  
    -- 생산사양 항목    
    CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(100), SpecValue NVARCHAR(100))    
      
    -- 거래처품목명칭가져오기  
    CREATE TABLE #TempCustItem(InvoiceSeq   INT,           InvoiceSerl INT,           ItemSeq INT,   
                               CustItemName NVARCHAR(100), CustItemNo  NVARCHAR(100), CustItemSpec NVARCHAR(100))                                 
  
    --/**************************************************************************  
    -- 생산사양Data                                                                  
    --**************************************************************************/   
    INSERT INTO #Tmp_InvoiceProg(InvoiceSeq, InvoiceSerl, OrderSeq, OrderSerl)  
    SELECT InvoiceSeq, InvoiceSerl, 0, 0  
      FROM _TSLInvoiceItem   
     WHERE CompanySeq = @CompanySeq  
       AND InvoiceSeq = @InvoiceSeq  
  
    INSERT #TMP_SOURCETABLE  
    SELECT 1, '_TSLOrderItem'  
  
    -- 수주Data찾기(원천)  
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceProg', 'InvoiceSeq', 'InvoiceSerl', ''       
  
    UPDATE #Tmp_InvoiceProg  
       SET OrderSeq  = Seq,  
           OrderSerl = Serl  
      FROM #Tmp_InvoiceProg AS A  
              JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO  
  
    SELECT @Seq = 0    
    
    WHILE (1=1)    
    BEGIN    
        SET ROWCOUNT 1    
    
        SELECT @Seq = Seq, @OrderSeq = OrderSeq, @OrderSerl = OrderSerl    
          FROM #TempSOSpec    
         WHERE Seq > @Seq    
         ORDER BY Seq    
    
        IF @@Rowcount = 0 BREAK    
    
        SET ROWCOUNT 0    
    
        SELECT @SubSeq = 0, @SpecName = '', @SpecValue = ''    
    
        WHILE(1=1)    
        BEGIN    
            SET ROWCOUNT 1    
    
            SELECT @SubSeq = OrderSpecSerl    
              FROM _TSLOrderItemspecItem    
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq    
             ORDER BY OrderSpecSerl    
    
            IF @@Rowcount = 0 BREAK    
    
            SET ROWCOUNT 0    
    
            IF ISNULL(@SpecName,'') = ''    
            BEGIN    
                SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN (SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue)     
                                                                                            ELSE A.SpecItemValue END)    
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq    
                 WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq    
            END    
            ELSE    
            BEGIN    
                SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN (SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue)     
                                                                                            ELSE A.SpecItemValue END)    
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq    
                 WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq    
            END    
    
            UPDATE #TempSOSpec    
               SET SpecName = @SpecName, SpecValue = @SpecValue    
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl    
    
        END    
    
    END    
    SET ROWCOUNT 0    
  
    --/**************************************************************************  
    -- 금액                                                                  
    --**************************************************************************/   
    SELECT @TotCurAmt = SUM(CurAmt),     
           @TotVAT    = SUM(CurVAT),     
           @TotAmt    = ISNULL(SUM(CurAmt), 0) + ISNULL(SUM(CurVAT), 0),  
           @TotDomAmt = ISNULL(SUM(DomAmt), 0) + ISNULL(SUM(DomVAT), 0)     -- 20101224 김준식 추가  
     FROM _TSLInvoiceItem    
    WHERE CompanySeq = @CompanySeq    
      AND InvoiceSeq = @InvoiceSeq    
  
    
    /* 합계금액을 한글로 변환 */     
    -- 금액을 한글로 변환       
    SELECT @ABSHapAmt = ABS(@TotAmt)    
    EXEC _SDAGetAmtHan @ABSHapAmt , @HanAmt OUTPUT  
  
    -- 원화금액을 한글로 변환  
    SELECT @ABSHapDomAmt = ABS(@TotDomAmt)                      -- 20101224 김준식 추가  
    EXEC _SDAGetAmtHan @ABSHapDomAmt , @HanDomAmt OUTPUT        -- 20101224 김준식 추가  
  
       
    -- 거래처품명 찾기  
    INSERT INTO #TempCustItem(InvoiceSeq, InvoiceSerl, ItemSeq, CustItemName, CustItemNo, CustItemSpec)  
    SELECT A.InvoiceSeq, A.InvoiceSerl, A.ItemSeq,   
           ISNULL(CASE ISNULL(B.CustItemName, '') WHEN '' THEN (SELECT ISNULL(CI.CustItemName, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)  
                                                  ELSE ISNULL(B.CustItemName, '') END, ''),   
             ISNULL(CASE ISNULL(B.CustItemNo, '') WHEN '' THEN (SELECT ISNULL(CI.CustItemNo, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND  A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)  
                                                ELSE ISNULL(B.CustItemNo, '') END, ''),   
           ISNULL(CASE ISNULL(B.CustItemSpec, '') WHEN '' THEN (SELECT ISNULL(CI.CustItemSpec, '') FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)  
                                                  ELSE ISNULL(B.CustItemSpec, '') END, '')  
      FROM _TSLInvoiceItem AS A  
            LEFT OUTER JOIN _TSLCustItem AS B ON A.CompanySeq = B.CompanySeq  
                                             AND B.CustSeq    = @CustSeq  
                                             AND A.ItemSeq    = B.ItemSeq  
                                             AND A.UnitSeq    = B.UnitSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.InvoiceSeq = @InvoiceSeq                                               
       
 -------------------------------------------------------------------    
    -- 사업자이력 START  
    -------------------------------------------------------------------    
    SELECT TaxUnit, TaxNo, TaxSerial, '' AS TaxNoSerl,    
           FrDate,     
           ToDate,      
           TaxName, Owner, BizType, BizItem,     
           Zip,     Addr1, Addr2,   Addr3,   VATRptAddr,    
           TelNo,   FaxNo    
      INTO #TTaxUnit    
      FROM _TDATaxUnitHist     
     WHERE CompanySeq = @CompanySeq    
     UNION ALL    
    SELECT TaxUnit, TaxNo, TaxSerial, TaxNoSerl,     
           ISNULL((SELECT CONVERT(NCHAR(8),DATEADD(DD,1,MAX(ToDate)),112) FROM _TDATaxUnitHist WHERE CompanySeq = A.CompanySeq AND TaxUnit = A.TaxUnit),'19000101'),    
           '99991231',     
           TaxName, Owner, BizType, BizItem,     
           Zip,     Addr1, Addr2,   Addr3,  VATRptAddr,    
           TelNo,   FaxNo    
      FROM _TDATaxUnit A    
     WHERE CompanySeq = @CompanySeq    
     ORDER BY TaxUnit, ToDate   
  
  
  
       
    DECLARE @pIsAccTax        INT,  -- 사업자단위과세제도여부    
            @pIsAccTaxDate    NCHAR(8),  -- 사업자단위과세제도 적용시점    
            @pIsAccTaxUnit    NCHAR(15) -- 사업자단위과세제도 주사업자 번호   
              
    SELECT @pIsAccTax     = ISNULL((SELECT EnvValue FROM _TCOMEnv WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = '4016'),'0')    
    SELECT @pIsAccTaxDate = ISNULL((SELECT EnvValue FROM _TCOMEnv WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = '4017'),'19000101')    
    SELECT @pIsAccTaxUnit = ISNULL((SELECT TOP 1 TaxUnit FROM _TDATaxUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SMTaxationType = '4128002'),0)    
 -------------------------------------------------------------------    
    -- 사업자이력 END   
    -------------------------------------------------------------------    
      
    CREATE TABLE #TSLInvoice  
    (  
        NameA   NVARCHAR(100),  
        NameB   NVARCHAR(100),   
        InvoiceNo  NVARCHAR(20),  
        HapAmt   Money,  
        HanAmt   NVARCHAR(100),  
        HapDomAmt       Money,                  -- 20101224 김준식 추가  
        HanDomAmt       NVARCHAR(100),          -- 20101224 김준식 추가  
        My_TaxNo  NVARCHAR(100),    
        My_TaxName  NVARCHAR(100),       
        My_TaxOwner  NVARCHAR(100),    
        My_VatAddr  NVARCHAR(100),  
        My_VatBizType NVARCHAR(200),   -- 20100908 최민석 추가  
        My_VatBizItem NVARCHAR(200),   -- 20100908 최민석 추가  
        InvoiceDate  NCHAR(8),  
        YY    NCHAR(4),   
        MM    NCHAR(2),   
        DD    NCHAR(2),    
        BKCustName  NVARCHAR(200),      
        CustName  NVARCHAR(200),  
        BizType   NVARCHAR(200),   -- 20100908 최민석 추가  
        BizKind   NVARCHAR(200),   -- 20100908 최민석 추가  
        CurrName        NVARCHAR(100),          -- 20120709 이성덕 추가  
        Remark          NVARCHAR(1000),         -- 20120709 이성덕 추가  
        Memo            NVARCHAR(1000),         -- 20120709 이성덕 추가  
        CurAmt   Money,   
        CurVAT   Money,  
        DomAmt   Money,           -- 20101224 김준식 추가  
          DomVAT   Money,           -- 20101224  김준식 추가  
        Qty    DECIMAL(19, 5),   
        Price   Money,  
        DomPrice        Money,           -- 20101224 김준식 추가  
        ItemName  NVARCHAR(100),   
        ItemNo   NVARCHAR(200),   
        Spec   NVARCHAR(100),   
        UnitName  NVARCHAR(100),  
        SpecName  NVARCHAR(200),          -- 생산사양항목  
        SpecValue  NVARCHAR(200),          -- 생산사양항목값  
     LotNo   NVARCHAR(60),   -- 20091208 전경만 추가  
     ValiDate  NVARCHAR(60),   -- 20091208 전경만 추가  
        BizNo   NVARCHAR(40),  
        ItemRemark  NVARCHAR(500),  
        Owner   NVARCHAR(60),  
        Addr   NVARCHAR(300),  
        ItemClassSName  NVARCHAR(200), -- 품목소분류   
        ItemSName       NVARCHAR(100), -- 품목약명  
  
        -- 2012.12.27 이성덕 더미 추가  
        Dummy1          NVARCHAR(100),  
        Dummy2          NVARCHAR(100),  
        Dummy3          NVARCHAR(100),  
        Dummy4          NVARCHAR(100),  
        Dummy5          NVARCHAR(100),  
        Dummy6          INT,  
        Dummy7          INT,  
        Dummy8          NVARCHAR(100),  
        Dummy9          NVARCHAR(100),  
        Dummy10         NVARCHAR(100),  
        InvoiceSerl     INT,             -- 20130409 박성호 추가  
        --BizNo           NVARCHAR(20)
    )  
    INSERT INTO #TSLInvoice
    SELECT '去來明細票'                  AS NameA,    
           '(공급자 보관용)'             AS NameB,   
           A.InvoiceNo,  
           @TotAmt                       AS HapAmt,  
           @HanAmt                       AS HanAmt,  
           @TotDomAmt                    AS HapDomAmt,          -- 20101224 김준식 추가  
           @HanDomAmt                    AS HanDomAmt,          -- 20101224 김준식 추가  
           SUBSTRING( Z.TaxNo, 1, 3 ) + '-' + SUBSTRING( Z.TaxNo, 4, 2 ) + '-' + SUBSTRING( Z.TaxNo, 6, 5 ), -- 사업자등록번호  
           Z.TaxName, -- 사업자상호  
           Z.Owner, -- 사업자대표자  
           CASE WHEN ISNULL( Z.VatRptAddr, '' ) = '' 
                THEN CONVERT(VARCHAR(150), LTRIM(RTRIM(Z.Addr1)) + LTRIM(RTRIM(Z.Addr2)) + LTRIM(RTRIM(Z.Addr3)) )   
                ELSE Z.VatRptAddr   
                END, -- 사업장주소   
     CONVERT( VARCHAR(50), LTRIM(RTRIM( Z.BizType )) ), -- 사업자업태  
           CONVERT( VARCHAR(50), LTRIM(RTRIM( Z.BizItem )) ), -- 사업자종목   
     --      CASE WHEN LEN(ISNULL(H.TaxNo, G.TaxNo) ) = 10  THEN SUBSTRING(ISNULL(H.TaxNo, G.TaxNo),1,3) +'-'+ SUBSTRING(ISNULL(H.TaxNo, G.TaxNo),4,2) + '-' + SUBSTRING(ISNULL(H.TaxNo, G.TaxNo),6,5) ELSE ISNULL(H.TaxNo, G.TaxNo) END AS My_TaxNo,     
     --      ISNULL(H.TaxName, G.TaxName)  AS My_TaxName,   -- 공급자 대표     
     --      ISNULL(H.Owner, G.Owner)      AS My_TaxOwner,  -- 공급자 대표    
     --      ISNULL(H.VATRptAddr, G.VATRptAddr) AS My_VatAddr, -- 공급자 주소  
     --      ISNULL(H.BizType, G.BizType) AS My_VatBizType,  -- 공급자 업태  
     --ISNULL(H.BizItem, G.BizItem) AS My_VatBizItem,  -- 공급자 업종  
     A.InvoiceDate     AS InvoiceDate,   -- 거래명세서일  
           LEFT(@InvoiceDate, 4)         AS YY,     -- 거래명세서일    
           SUBSTRING(@InvoiceDate, 5, 2) AS MM,   
           RIGHT(@InvoiceDate, 2)        AS DD,  
             
           I.CustName                    AS BKCustName,   -- 중개인  
           E.CustName                    AS CustName,   -- 거래처  
     E.BizType      AS BizType,   -- 업태  
     E.BizKind      AS BizKind,   -- 업종  
           ISNULL(Cu.CurrName,'')        AS CurrName,        -- 통화  
           ISNULL(A.Remark,'')           AS Remark,           -- 비고  
           ISNULL(A.Memo,'')             AS Memo,             -- 메모  
           B.CurAmt,  
           B.CurVAT,  
           B.DomAmt                AS DomAmt,             -- 20101224 김준식 추가  
           B.DomVAT                AS DomVAT,             -- 20101224 김준식 추가  
           B.Qty,  
           --ItemPrice                     AS Price,  
           CASE WHEN B.Price IS NOT NULL  
                THEN B.Price  
                ELSE (CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)        
                                                                                        ELSE ISNULL(B.CurAmt,0)  / ISNULL(B.Qty,0) END) END) END AS Price, -- 판매단가    
           CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN (ISNULL(B.DomAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0)        
                                                                                      ELSE ISNULL(B.DomAmt,0) / ISNULL(B.Qty,0) END) END AS DomPrice,   -- 20101224 김준식 추가  
           B1.ItemName,  
           B1.ItemNo,  
           B1.Spec,  
           B2.UnitName,  
           S.SpecName,   
           S.SpecValue,  
     B.LotNo,           -- LotNo 20091208 전경만 추가  
     ISNULL((SELECT ValiDate FROM _TLGLotMaster WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND LotNo = B.LotNo AND ItemSeq = B.ItemSeq),'') AS ValiDate,  -- 유효일자 20091208 전경만 추가  
     CASE WHEN E.BizNo = '' THEN '' ELSE ISNULL(SUBSTRING(E.BizNo,1,3) + '-' +SUBSTRING(E.BizNo,4,2) + '-' + SUBSTRING(E.BizNo, 6,LEN(E.BizNo)) ,'') END    AS BizNo        ,  
     ISNULL(B.Remark, '')     AS ItemRemark   ,  
     ISNULL(E.Owner, '')      AS Owner        ,  
     ISNULL(RTRIM(L.KorAddr1) + RTRIM(L.KorAddr2) + RTRIM(L.KorAddr3), '') AS Addr,  
     Y.MinorName AS ItemClassSName, -- 품목소분류   
     B1.ItemSName, -- 품목약명   
           B.Dummy1,  
           B.Dummy2,  
           B.Dummy3,  
           B.Dummy4,  
           B.Dummy5,  
           B.Dummy6,  
           B.Dummy7,  
           B.Dummy8,  
           B.Dummy9,  
           B.Dummy10,  
           B.InvoiceSerl
           --STUFF(E.BizNo,4,0,'-') AS BizNo
      FROM _TSLInvoice                  AS A  WITH(NOLOCK)  
      LEFT OUTER JOIN _TSLInvoiceItem   AS B  WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.InvoiceSeq= B.InvoiceSeq  
      LEFT OUTER JOIN _TDAItem          AS B1 WITH(NOLOCK) ON B.CompanySeq = B1.CompanySeq AND B.ItemSeq= B1.ItemSeq   
  
      LEFT OUTER JOIN _TDAItemClass     AS X  WITH(NOLOCK) ON ( B.CompanySeq = X.CompanySeq AND B.ItemSeq = X.ItemSeq AND X.UMajorItemClass IN (2001,2004) )   
      LEFT OUTER JOIN _TDAUMinor        AS Y  WITH(NOLOCK) ON ( X.UMItemClass = Y.MinorSeq AND X.CompanySeq = Y.CompanySeq AND Y.IsUse = '1' )  
  
        
      LEFT OUTER JOIN _TDAUnit          AS B2 WITH(NOLOCK) ON B.CompanySeq = B2.CompanySeq AND B.UnitSeq= B2.UnitSeq  
      LEFT OUTER JOIN _TDADept          AS C  WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DeptSeq   = C.DeptSeq  
      LEFT OUTER JOIN _TDACurr          AS Cu WITH(NOLOCK) ON Cu.CompanySeq = A.CompanySeq AND Cu.CurrSeq = A.CurrSeq  
      JOIN #TTaxUnit                    AS Z  WITH(NOLOCK) ON Z.TaxUnit  = ( CASE WHEN ( @pIsAccTax = 4125002 ) AND ( A.InvoiceDate >= @pIsAccTaxDate )    
                                                                                     THEN @pIsAccTaxUnit   
                                                                                     ELSE C.TaxUnit  
                                                                                          --CASE WHEN ISNULL( A.TaxUnit, '' ) = ''   
                                                                                               --THEN C.TaxUnit -- _TDADept  
                                                                                               --ELSE A.TaxUnit -- _TSLBill  
                                                                                               --END     
                                                                                     END ) AND A.InvoiceDate BETWEEN Z.FrDate AND Z.ToDate     
      LEFT OUTER JOIN _TDAEmp           AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.EmpSeq    = D.EmpSeq    
      LEFT OUTER JOIN _TDACust          AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq AND A.CustSeq   = E.CustSeq  
      LEFT OUTER JOIN _TDACust          AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.BKCustSeq = I.CustSeq    
      --LEFT OUTER JOIN _TDATaxUnit     AS G WITH(NOLOCK) ON C.CompanySeq = G.CompanySeq AND C.TaxUnit   = G.TaxUnit      
        --LEFT OUTER JOIN _TDATaxUnitHist AS H WITH(NOLOCK) ON C.CompanySeq = H.CompanySeq AND C.TaxUnit   = H.TaxUnit  AND @InvoiceDate BETWEEN H.FrDate AND H.ToDate    
      LEFT OUTER JOIN #Tmp_InvoiceProg  AS J              ON B.InvoiceSeq   = J.InvoiceSeq AND B.InvoiceSerl  = J.InvoiceSerl  
      LEFT OUTER JOIN #TempSOSpec       AS S              ON J.OrderSeq     = S.OrderSeq AND J.OrderSerl    = S.OrderSerl  
      LEFT OUTER JOIN _TDACustAdd       AS L WITH(NOLOCK) ON L.CompanySeq = @CompanySeq  AND E.CustSeq = L.CustSeq  
     WHERE A.CompanySeq = @CompanySeq    
       AND A.InvoiceSeq = @InvoiceSeq  
     ORDER BY B.InvoiceSerl 

    SELECT * FROM #TSLInvoice ORDER BY InvoiceSerl
  
 RETURN 
 GO     
exec costel_SSLInvoiceRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InvoiceSeq>1000950</InvoiceSeq>
    <InvoiceDate>20131101</InvoiceDate>
    <CustSeq>37606</CustSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019183,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1275


--select * from _TDACust where companyseq = 1 and Custseq = 37606
--select * from _TDACustAdd where companyseq = 1 and custseq = 37606
--select * from _TDACustAddr where companyseq = 1 


--select * from sysobjects where name like '[_]TDACust%'