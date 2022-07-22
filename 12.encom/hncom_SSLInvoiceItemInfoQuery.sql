IF OBJECT_ID('hncom_SSLInvoiceItemInfoQuery') IS NOT NULL
    DROP PROC hncom_SSLInvoiceItemInfoQuery
GO 

-- v2017.02.02 
-- 거래명세서품목조회-조회 by이재천
-- Ver.20150210
/*********************************************************************************************************************  
    화면명 : 거래명세서품목현황  
    SP Name: temphncom_SSLInvoiceItemInfoQuery  
    작성일 : 2008.08.07 : CREATEd by 정혜영      
    수정일 : 속도문제로 최종 조회 Join 테이블 줄임 (휴온스) 2010.04.21 by 정혜영
             기타출고구분컬럼추가   2010.06.14 by 정혜영
             청구처 추가            2010.06.17 by 최민석
             LotNo 추가             2010.11.08 by 천경민
             작성 + 진행 check 조회조건 추가 kskwon 권기석
             최종 조회구문 DECIMAL 소수점 자리 수 변환 문제(변환 오버플로)에 따른 CONVERT 수행 2013.01.09 by 박성호
			 2013.05.02 허승남 - 진행상태에 미완료추가
********************************************************************************************************************/  
CREATE PROC hncom_SSLInvoiceItemInfoQuery   
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS         
    SET NOCOUNT ON        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED     
    
    DECLARE @docHandle      INT,  
            @BizUnit        INT,   
            @InvoiceDateFr	NCHAR(8),   
            @InvoiceDateTo	NCHAR(8),   
            @UMOutKind      INT,   
            @InvoiceNo		NVARCHAR(20),  
            @DeptSeq        INT,   
            @EmpSeq         INT,   
            @CustSeq        INT,  
            @CustNo         NVARCHAR(20), 
			@BillCustSeq    INT,           -- 20100617 최민석 청구처 추가  
            @ItemSeq        INT,   
            @ItemNo         NVARCHAR(30),  
            @IsInvConfirm   NCHAR(1),
            @PJTName        NVARCHAR(100),  
            @PJTNo          NVARCHAR(100),  
            @WBSName        NVARCHAR(100),   
            @SMProgressType INT,
			@SMExpKind		INT,
			@WHSeq          INT,
			@DVPlaceSeq     INT,           -- 20110221 오성근 거래처 추가
			@UMChannel      INT,           -- 20150129 이준식 추가
            -- 생산사양용
            @Seq            INT, 
            @OrderSeq       INT, 
            @OrderSerl      INT, 
            @SubSeq         INT, 
            @SpecName       NVARCHAR(200),   
            @SpecValue      NVARCHAR(200),
            @AssetSeq       INT, 
            @LotNo          NVARCHAR(30),
            @SMProgress     NCHAR(1)                -- 진행 + 작성(2012.05.23 kskwon 추가)
            
            
    -- 추가변수
    DECLARE @SourceTableSeq INT,
            @SourceNo       NVARCHAR(30),
            @SourceRefNo    NVARCHAR(30),
            @TableName      NVARCHAR(100),
            @TableSeq       INT,
            @SQL            NVARCHAR(MAX),
            --@IsDelvCfm      NCHAR(1),
            @DomLen         INT,
            @DomPriceLen    INT,
            @CurLen         INT,
            @CurPriceLen    INT,
            @QtyLen         INT,
            @UMEtcOutKind   INT, -- 20130111 박성호 추가
            @SMDelvStatus   INT, -- 20140105 박성호 추가
            @IOTag          INT, -- 대한산업 내부/외부 구분
            @IsIOTag        NCHAR(1) 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
  
    -- Temp에 INSERT      
    --    INSERT INTO #TXBProcessActRevQry(ProcessCd,ProcessRev,ActivitySeq,ActivityRev)      
    SELECT  @BizUnit        = ISNULL(BizUnit, 0),   
            @InvoiceDateFr  = ISNULL(InvoiceDateFr, ''),   
            @InvoiceDateTo  = ISNULL(InvoiceDateTo, ''),   
            @UMOutKind      = ISNULL(UMOutKind, 0),   
            @InvoiceNo      = LTRIM(RTRIM(ISNULL(InvoiceNo, ''))),  
            @DeptSeq        = ISNULL(DeptSeq, 0),   
            @EmpSeq         = ISNULL(EmpSeq, 0),   
            @ItemSeq        = ISNULL(ItemSeq, 0),  
            @ItemNo         = LTRIM(RTRIM(ISNULL(ItemNo, ''))),   
            @CustSeq        = ISNULL(CustSeq, 0),  
            @CustNo         = LTRIM(RTRIM(ISNULL(CustNo, ''))),   
			@BillCustSeq      = ISNULL(BillCustSeq, 0),        -- 20100617 최민석 추가 -- 20130109 박성호 수정[ ISNULL(BillCustSeq, '') -> ISNULL(BillCustSeq, 0) ]
            @PJTName        = ISNULL(PJTName, ''),  
            @PJTNo          = ISNULL(PJTNo, ''),  
            @WBSName        = ISNULL(WBSName, ''),   
            @SMProgressType   = ISNULL(SMProgressType, 0),
            @SourceTableSeq   = ISNULL(SourceTableSeq, 0),  -- 추가
            @SourceNo         = ISNULL(SourceNo, ''),       -- 추가
            @SourceRefNo      = ISNULL(SourceRefNo, ''),     -- 추가
			@SMExpKind		= ISNULL(SMExpKind,0),
            --@IsDelvCfm      = ISNULL(IsDelvCfm,''),
            @WHSeq          = ISNULL(WHSeq,0),
            @DVPlaceSeq     = ISNULL(DVPlaceSeq, 0),             --20110221 오성근 추가
            @AssetSeq       = ISNULL(AssetSeq, 0),
            @LotNo          = ISNULL( LotNo, '' ),
            @SMProgress     = ISNULL(SMProgress, '0'),
            @UMEtcOutKind   = ISNULL(UMEtcOutKind, 0), -- 20130111 박성호 추가
            @SMDelvStatus   = ISNULL(SMDelvStatus, 0), -- 20140105 박성호 추가
            @UMChannel      = ISNULL(UMChannel,0),      -- 20150129 이준식 추가
            @IOTag          = ISNULL(IOTag,0)
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (BizUnit INT, InvoiceDateFr NCHAR(8), InvoiceDateTo NCHAR(8), UMOutKind INT,            InvoiceNo NVARCHAR(20),   
          DeptSeq INT, EmpSeq        INT,      CustSeq       INT,      CustNo NVARCHAR(20),      BillCustSeq  INT,
          ItemSeq INT, ItemNo  NVARCHAR(30),   PJTName       NVARCHAR(100), PJTNo NVARCHAR(100), WBSName NVARCHAR(100),  
          SMProgressType INT,
          SourceTableSeq      INT,            -- 추가
          SourceNo            NVARCHAR(30),   -- 추가
          SourceRefNo         NVARCHAR(30),   -- 추가
		  SMExpKind		INT,
          --IsDelvCfm     NCHAR(1),
          WHSeq         INT,
          DVPlaceSeq    INT,
          AssetSeq      INT,
          LotNo         NVARCHAR(30),
          SMProgress    NVARCHAR(1),
          UMEtcOutKind  INT, -- 20130111 박성호 추가
          SMDelvStatus  INT,
          UMChannel     INT, 
          IOTag         INT -- 대한산업 내부/외부 구분
          ) -- 20140105 박성호 추가
  
    IF @InvoiceDateTo = ''  
        SELECT @InvoiceDateTo = '99991231' 
    -- 환경설정 소숫점 가저오기
    EXEC dbo._SCOMEnv @CompanySeq,15, @UserSeq,@@PROCID,@DomLen OUTPUT   -- 원화 소숫점 자릿수
    EXEC dbo._SCOMEnv @CompanySeq,9, @UserSeq,@@PROCID,@DomPriceLen OUTPUT   -- 원화 단가소숫점 자릿수
    EXEC dbo._SCOMEnv @CompanySeq,14, @UserSeq,@@PROCID,@CurLen OUTPUT   -- 외화 소숫점 자릿수
    EXEC dbo._SCOMEnv @CompanySeq,10, @UserSeq,@@PROCID,@CurPriceLen OUTPUT   -- 외화 단가소숫점 자릿수
    EXEC dbo._SCOMEnv @CompanySeq,8, @UserSeq,@@PROCID,@QtyLen OUTPUT   -- 수량 소숫점 자릿수  

    IF @IOTag = 1014674002 
    BEGIN
        SELECT @IsIOTag = '1'
    END 

    IF @IOTag = 1014674003
    BEGIN
        SELECT @IsIOTag = '0'
    END 
/***********************************************************************************************************************************************/  
---------------------- 조직도 연결 여부  
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
  
    IF @InvoiceDateTo = '99991231'  
        SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)  
    ELSE  
        SELECT  @OrgStdDate = @InvoiceDateTo 
  
    SELECT @SMOrgSortSeq = 0  
    SELECT @SMOrgSortSeq = SMOrgSortSeq  
      FROM _TCOMOrgLinkMng WITH(NOLOCK) 
     WHERE CompanySeq = @CompanySeq  
       AND PgmSeq     = @PgmSeq  
    
    DECLARE @DeptTable Table( DeptSeq INT )  
  
    INSERT  @DeptTable  
    SELECT  DISTINCT DeptSeq  
      FROM  dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)  
  
---------------------- 조직도 연결 여부 
   
    -- 거래명세서진행상태 Table  
    CREATE TABLE #Tmp_InvoiceProg(IDX_NO INT IDENTITY, InvoiceSeq INT, InvoiceSerl INT, CompleteCHECK INT, SMProgressType INT, 
                                  SalesSeq INT,        OrderSeq   INT,   OrderSerl INT, IsSpec NCHAR(1), Qty DECIMAL(19,5), IsDelvCfm NCHAR(1))  
    -- 진행 
    CREATE TABLE #TMP_PROGRESSTABLE      
    (      
        IDOrder INT,      
        TABLENAME   NVARCHAR(100)      
    )      
    CREATE TABLE #TCOMProgressTracking      
    (       IDX_NO      INT,      
            IDOrder     INT,      
            Seq         INT,      
            Serl        INT,      
            SubSerl     INT,      
            Qty         DECIMAL(19, 5),      
            STDQty         DECIMAL(19, 5),      
            Amt         DECIMAL(19, 5)   ,      
            VAT         DECIMAL(19, 5)      
    )      
    CREATE TABLE #TempOrderProg
    (
        Seq             INT,
        Serl            INT,
        PaymentQty      DECIMAL(19,5),
        PaymentSTDQty   DECIMAL(19,5),
        InvoiceQty      DECIMAL(19,5),
        InvoiceSTDQty   DECIMAL(19,5),
        BLQty           DECIMAL(19,5),
        BLSTDQty        DECIMAL(19,5),
        PermitQty       DECIMAL(19,5),
        PermitSTDQty    DECIMAL(19,5),
        DelvQty         DECIMAL(19,5),
        DelvSTDQty      DECIMAL(19,5)
    )
    -- 원천 및 진행 데이터테이블
    CREATE TABLE #TempResult
    (
        InOutSeq		INT,  -- 진행내부번호
        InOutSerl		INT,  -- 진행순번
        InOutSubSerl    INT,
        SourceRefNo     NVARCHAR(30),
        SourceNo        NVARCHAR(30)
    )
    CREATE TABLE #TMP_SOURCETABLE      
    (      
        IDOrder INT IDENTITY,      
        TABLENAME   NVARCHAR(100)      
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
    
    CREATE TABLE #TMP_SOURCEITEM
    (      
        IDX_NO        INT IDENTITY,      
        SourceSeq     INT,      
        SourceSerl    INT,      
        SourceSubSerl INT
    )  
    -- 생산사양 항목  
    CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(100), SpecValue NVARCHAR(100))  
    --/***********************************
    -- 기초 데이터 조회                 
    --***********************************/
    INSERT INTO #Tmp_InvoiceProg(InvoiceSeq, InvoiceSerl, CompleteCHECK, Qty, IsDelvCfm)  
    SELECT A.InvoiceSeq, D.InvoiceSerl, -1, D.Qty, ISNULL(A.IsDelvCfm, '0')
      FROM _TSLInvoice              AS A WITH(NOLOCK)
      JOIN _TSLInvoiceItem          AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.InvoiceSeq = D.InvoiceSeq )  
      JOIN _TDASMinorValue          AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.SMExpKind = B.MinorSeq AND B.Serl = 1001 AND B.ValueText = '1' ) 
      LEFT OUTER JOIN _TDACust      AS C WITh(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDAItem      AS J WITH(NOLOCK) ON ( D.CompanySeq = J.CompanySeq AND D.ItemSeq = J.ItemSeq )
      LEFT OUTER JOIN _TDAItemAsset AS E WITH(NOLOCK) ON ( J.CompanySeq = E.CompanySeq AND J.AssetSeq = E.AssetSeq )       
      
	  LEFT OUTER JOIN _TPJTProject AS P WITH (NOLOCK) ON D.CompanySeq = P.CompanySeq  
													 AND D.PJTSeq     = P.PJTSeq  
                                                         
	  LEFT OUTER JOIN _TPJTWBS AS W WITH (NOLOCK) ON D.CompanySeq = W.CompanySeq  
                                                 AND D.PJTSeq     = W.PJTSeq  
                                                 AND D.WBSSeq     = W.WBSSeq      
                                                
	  LEFT OUTER JOIN _TDACustGroup AS O WITH(NOLOCK) ON A.CompanySeq  = O.CompanySeq  
													 AND A.CustSeq     = O.CustSeq  
													 AND O.UMCustGroup = 8014002
      LEFT OUTER JOIN _TDACustClass AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq    --20150129 이준식 추가
                                                     AND A.CustSeq = F.CustSeq
                                                     AND F.UMajorCustClass = 8004 
      LEFT OUTER JOIN _TDACustUserDefine AS G WITH(NOLOCK) ON G.CompanySeq = @CompanySeq     
                                                          AND G.CustSeq    = A.CustSeq
														  AND G.MngSerl = 1000005
                                                                                           
     WHERE A.CompanySeq = @CompanySeq      
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)    
       AND (A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo)    
       AND (@InvoiceNo = '' OR A.InvoiceNo LIKE @InvoiceNo + '%')    
       AND (@UMOutKind = 0 OR A.UMOutKind = @UMOutKind)    
---------- 조직도 연결 변경 부분    
       AND (@DeptSeq = 0   
            OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
            OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
---------- 조직도 연결 변경 부분     
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)    
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
       AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%')  
--	   AND (@BillCustSeq = 0 OR A.CustSeq = @BillCustSeq)  --20100616 최민석추가
       AND (@ItemSeq = 0 OR D.ItemSeq = @ItemSeq)  
       AND (@ItemNo = '' OR J.ItemNo LIKE @ItemNo + '%')  
	   AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)
	   AND (@WHSeq = 0 OR D.WHSeq = @WHSeq) 
       AND (@DVPlaceSeq = 0 OR A.DVPlaceSeq = @DVPlaceSeq)
       AND (@AssetSeq = 0 OR E.AssetSeq = @AssetSeq) 
       AND ( @LotNo = '' OR D.LotNo LIKE @LotNo + '%' ) 
       
       AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')  
       AND (@PJTNo   = '' OR P.PJTNo   LIKE @PJTNo   + '%')  
       AND (@WBSName = '' OR W.WBSName LIKE @WBSName + '%')  
       --AND (@IsDelvCfm = '0' OR (@IsDelvCfm = '1' AND A.IsDelvCfm = '0' OR A.IsDelvCfm = ''))
       AND (@BillCustSeq = 0 OR (ISNULL(O.UpperCustSeq,0) = 0 AND A.CustSeq = @BillCustSeq) OR (O.UpperCustSeq = @BillCustSeq))
       AND (@UMEtcOutKind = 0 OR D.UMEtcOutKind = @UMEtcOutKind) -- 20130111 박성호 추가
       AND (@UMChannel = 0 OR F.UMCustClass = @UMChannel)   -- 20150129 이준식 추가    
       AND (@IOTag = 1014674001 OR @IsIOTag = ISNULL(G.MngValText,'0'))

    -- 출고처리 조회조건에 따라 출고 건 조회 시에는 미출고 건을 삭제하고,
    -- 미출고 건 조회시에는 출고 건을 삭제합니다. :: 20140105 박성호 추가
    IF @SMDelvStatus = '1' -- 출고
    BEGIN
        DELETE #Tmp_InvoiceProg WHERE IsDelvCfm = '0' -- 미출고 건 삭제
    END
    ELSE IF @SMDelvStatus = '2' -- 미출고
    BEGIN
        DELETE #Tmp_InvoiceProg WHERE IsDelvCfm = '1' -- 출고 건 삭제
    END
    
       
    --/***********************************
    -- 진행상태조회                     
    --***********************************/
    EXEC _SCOMProgStatus @CompanySeq, '_TSLInvoiceItem', 1036001, '#Tmp_InvoiceProg', 
                         'InvoiceSeq', 'InvoiceSerl', '', '', '', '', '', '', 'CompleteCHECK', 1,  
                         'Qty', 'STDQty', 'CurAmt', 'CurVAT',  
                         'InvoiceSeq', 'InvoiceSerl', '', '_TSLInvoice', @PgmSeq   
    UPDATE #Tmp_InvoiceProg   
       SET SMProgressType = B.MinorSeq  
      FROM #Tmp_InvoiceProg AS A   
            LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                        AND B.CompanySeq = @CompanySeq  
                                                        AND A.CompleteCHECK = B.Minorvalue  

--SELECT * FROM _TDASMinor WHERE CompanySeq = 1 AND MajorSeq = 1037
  
    --/*********************************** 
    -- 진행내역 데이터 조회
    --***********************************/   
    INSERT #TMP_PROGRESSTABLE      
    SELECT 1,'_TSLSalesItem'      
    exec _SCOMProgressTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceProg', 'InvoiceSeq', 'InvoiceSerl', ''
    --/**************************************************************************
    -- 생산사양Data                                                                
    --**************************************************************************/ 
    INSERT #TMP_SOURCETABLE
    SELECT '_TSLOrderItem'
    -- 수주Data찾기(원천)
    EXEC _SCOMSourceTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceProg', 'InvoiceSeq', 'InvoiceSerl', ''     
    UPDATE #Tmp_InvoiceProg
       SET OrderSeq  = Seq,
           OrderSerl = Serl, 
           IsSpec = '1'
      FROM #Tmp_InvoiceProg AS A
            JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
            JOIN _TSLOrderItemSpec   AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                      AND B.Seq        = C.OrderSeq
                                                      AND B.Serl       = C.OrderSerl

    -- 생산사양 조회를 위한 기초데이터
    INSERT INTO #TempSOSpec(OrderSeq, OrderSerl)
    SELECT DISTINCT OrderSeq, OrderSerl
      FROM #Tmp_InvoiceProg

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
              FROM _TSLOrderItemspecItem WITH(NOLOCK) 
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl > @SubSeq AND CompanySeq = @CompanySeq  
             ORDER BY OrderSpecSerl  
  
            IF @@Rowcount = 0 BREAK  
  
            SET ROWCOUNT 0  
  
            IF ISNULL(@SpecName,'') = ''  
            BEGIN  
                SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')  
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)  
                  FROM _TSLOrderItemspecItem AS A WITH(NOLOCK)
                  JOIN _TSLSpec AS B WITH(NOLOCK) ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq  
                 WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq  
            END  
            ELSE  
            BEGIN  
                SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')  
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)  
                  FROM _TSLOrderItemspecItem AS A WITH(NOLOCK)
                  JOIN _TSLSpec AS B WITH(NOLOCK) ON A.SpecSeq = B.SpecSeq AND B.CompanySeq = @CompanySeq  
                 WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq  
            END  
  
            UPDATE #TempSOSpec  
               SET SpecName = @SpecName, SpecValue = @SpecValue  
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl  
  
        END  
  
    END  
    SET ROWCOUNT 0  
    ----------------------------------------------------------------------------      
    -- 원천진행 조회                                                            
    ----------------------------------------------------------------------------   
    IF ISNULL(@SourceTableSeq, 0) <> 0
    BEGIN
    
        DELETE #TMP_SOURCETABLE 
        DELETE #TCOMSourceTracking    
            
        IF ISNULL(@TableName, '') <> ''
        BEGIN
            SELECT @TableSeq = ProgTableSeq    
              FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블    
             WHERE ProgTableName = @TableName  
        END
        IF ISNULL(@TableSeq,0) = 0
        BEGIN
            SELECT @TableSeq = ISNULL(ProgTableSeq, 0)
              FROM _TCAPgmDev WITH(NOLOCK) 
             WHERE PgmSeq = @PgmSeq
            SELECT @TableName = ISNULL(ProgTableName, '')
              FROM _TCOMProgTable WITH(NOLOCK)
             WHERE ProgTableSeq = @TableSeq
END
        INSERT INTO #TMP_SOURCETABLE(TABLENAME)    
        SELECT ISNULL(ProgTableName,'')
          FROM _TCOMProgTable WITH(NOLOCK)
         WHERE ProgTableSeq = @SourceTableSeq
        -- 주의
        INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(진행), 2(미진행)    
        SELECT  A.InvoiceSeq, A.InvoiceSerl, 0    
          FROM #Tmp_InvoiceProg     AS A WITH(NOLOCK)         

        EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''      
-- 수정시작
        SELECT @SQL = 'INSERT INTO #TempResult '
        SELECT @SQL = @SQL + 'SELECT C.SourceSeq, C.SourceSerl, C.SourceSubSerl, ' +
                             CASE WHEN ISNULL(A.ProgMasterTableName,'') = '' THEN ''''' AS InOutRefNo, '''' AS InOutNo ' 
                                                                             ELSE (CASE WHEN ISNULL(A.ProgTableRefNoColumn,'') = '' THEN ''''' AS InOutNo, ' ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableRefNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutNo, ' END) +
                                                                                  (CASE WHEN ISNULL(A.ProgTableNoColumn,'') = '' THEN ''''' AS InOutRefNo ' ELSE (CASE WHEN ISNULL(A.ProgMasterSubTableName,'') = '' THEN 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo '                                                                                                                                                                                                                          
                                                                                                                                                                                                                   ELSE 'ISNULL((SELECT ' + ISNULL(A.ProgTableNoColumn,'') + ' FROM ' + ISNULL(A.ProgMasterSubTableName,'') + ' WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ' + A.ProgTableSeqColumn + ' = A.Seq), '''') AS InOutRefNo  ' END) END) END + 
                            ' FROM #TCOMSourceTracking AS A  ' +
                            ' JOIN #TMP_SOURCETABLE AS B ON A.IDOrder = B.IDOrder ' +
                            ' JOIN #TMP_SOURCEITEM AS  C ON A.IDX_NO  = C.IDX_NO ' +
                            ' JOIN _TCOMProgTable AS D WITH(NOLOCK) ON B.TableName = D.ProgTableName  '
          FROM _TCOMProgTable AS A WITH(NOLOCK) 
         WHERE A.ProgTableSeq = @SourceTableSeq
-- 수정종료
        EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq
        SELECT @SQL = ''
    END
    -- 많은 양의 데이터 조회시 속도를 줄여줄 인덱스 추가 (2010.07.01 휴온스에서 튜닝작업)
    CREATE INDEX IX_#TCOMProgressTracking ON #TCOMProgressTracking (IDX_NO) 
    CREATE INDEX IX_#Tmp_InvoiceProg ON #Tmp_InvoiceProg (InvoiceSeq, InvoiceSerl)
    --================================================================================================                             
    -- ************** 프로젝트 거래명세서품목 조회/일반 영업 거래명세서품목 조회 체크*****************                           
    --================================================================================================
    IF @PgmSeq = 6045   -- 프로젝트 거래명세서품목 조회
    BEGIN 
    --========================================================================================                            
     -- 권한범위내의 프로젝트만 가져오기 (일반 영업/PJT 여부 체크)                           
    --========================================================================================                              
    CREATE TABLE #TPJT_AUTH                            
    (                            
        PJTSeq INT                            
    ) 
                        
    IF EXISTS (SELECT 1 FROM _TCOMEnv WHERE EnvSeq = 7020 AND EnvValue = '1' AND CompanySeq = @CompanySeq)            
    BEGIN                
        EXEC _SPJTGetAuthProject @CompanySeq, @UserSeq             
    END
    ELSE            
    BEGIN            
        INSERT INTO #TPJT_AUTH             
        SELECT PJTSeq FROM _TPJTProject WHERE CompanySeq = @CompanySeq            
    END        
    /*********************************** 
    -- 최종 데이터 조회
    ***********************************/  
    SELECT (SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)   AS BizUnitName,     --사업부문  
           A.InvoiceSeq     AS InvoiceSeq,      --거래명세서내부코드  
           A.InvoiceDate    AS InvoiceDate,     --거래명세서일  
           B.InvoiceSerl    AS InvoiceSerl,     --거래명세서순번  
           A.InvoiceNo      AS InvoiceNo,       --거래명세서번호  
           A.SMExpKind      AS SMExpKind,       --수출구분코드  
           (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.SMExpKind = MinorSeq)      AS SMExpKindName,   --수출구분  
           H.MinorName      AS UMOutKindName,   --출고구분  
           A.UMOutKind      AS UMOutKind,       --출고구분코드  
           I.ValueText      AS IsSales,         --매출동시발생  
           (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)      AS DeptName,        --부서  
           (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EmpSeq)        AS EmpName,         --담당자  
           F.CustName       AS CustName,        --거래처  
           F.CustNo         AS CustNo,          --거래처번호  
           A.CustSeq        AS CustSeq,         --거래처코드
           (SELECT DVPlaceName  FROM _TSLDeliveryCust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DVPlaceSeq = DVPlaceSeq)       AS DVPlaceName,    --납품거래처  
           A.IsStockSales   AS IsStockSales,    --판매후보관
           J.ItemSeq        AS ItemSeq,         --품목내부코드
           J.ItemName       AS ItemName,        --품명  
           J.ItemNo         AS ItemNo,          --품번  
           J.Spec           AS Spec,            --규격  
           (SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)       AS UnitName,        --판매단위  
           B.ItemPrice      AS ItemPrice,       --품목단가  
           B.CustPrice      AS CustPrice,       --회사단가  
           B.Qty            AS Qty,             --수량  
           B.RetroactivityQty            AS RetroactivityQty,             --수량(단가소급)
           B.IsInclusedVAT  AS IsInclusedVAT,   --부가세포함  
           B.VATRate        AS VATRate,         --부가세율
	       A.CurrSeq		AS CurrSeq,			--통화코드
	       (SELECT CurrName FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq)	AS CurrName,		--통화   
	       CONVERT(DECIMAL(19, 5), A.ExRate)         AS ExRate,          -- 환율
           CONVERT(DECIMAL(19, 5), 
           CASE WHEN B.Price IS NOT NULL
                THEN B.Price
                ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0))           
                                                           ELSE (ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END) AS Price,   --판매단가  
           ROUND(B.CurAmt,@CurLen)         AS CurAmt,          --판매금액  
           ROUND(B.CurVAT,@CurLen)         AS CurVAT,          --부가세액  
           CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen)) AS TotCurAmt, -- 판매금액총액
           ROUND(ISNULL(B.DomAmt, 0), @DomLen)         AS DomAmt,          --원화판매금액  
           ROUND(ISNULL(B.DomVAT, 0), @DomLen)         AS DomVAT,          --원화부가세액  
           CONVERT(DECIMAL(19, 5), ROUND(ISNULL(B.DomAmt, 0), @DomLen) + ROUND(ISNULL(B.DomVAT, 0), @DomLen)) AS TotDomAmt, -- 원화판매금액총액
           ISNULL((SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq), '')        AS STDUnitName,     --기준단위  
           B.STDQty         AS STDQty,          --기준단위수량  
           (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.WHSeq = WHSeq)        AS WHName,          --창고
           A.Remark         AS RemarkM,          --마스터비고  
           B.Remark         AS RemarkI,          --비고  
           --(SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq)   AS SMProgressTypeName, --진행상태 
           CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 THEN  (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) + ' ' + ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMEtcOutKind), '')
           ELSE (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) END AS SMProgressTypeName, --진행상태    20141107 이삭 수정
           Z.SMProgressType         AS SMProgressType,
           ISNULL(U.SalesSeq,0) AS SalesSeq,  
           ISNULL(U.SalesSerl,0) AS SalesSerl,  
           ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = B.CCtrSeq), '') AS CCtrName,
           B.CCtrSeq                AS CCtrSeq,
           B.PJTSeq                 AS PJTSeq,  
           B.WBSSeq                 AS WBSSeq,  
           P.PJTName                AS PJTName,  
           P.PJTNo                  AS PJTNo,  
           W.WBSName                AS WBSName,  
           A.IsDelvCfm              AS IsDelvCfm,
           CASE WHEN ISNULL(A.SMSalesCrtKind,0) = 0 THEN ISNULL(Q.SMSalesPoint,0) ELSE ISNULL(A.SMSalesCrtKind,0) END AS SMSalesCrtKind,  
           CASE WHEN ISNULL(A.SMSalesCrtKind,0) = 0 THEN ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = Q.SMSalesPoint), '')   
                                                    ELSE ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMSalesCrtKind), '') END AS SMSalesCrtKindName,
           A.IsPJT AS IsPJT,
           CASE WHEN ISNULL(O.UpperCustSeq,0) = 0 THEN A.CustSeq ELSE O.UpperCustSeq END AS BillCustSeq,
           CASE WHEN ISNULL(R.CustName,'') = '' THEN F.CustName ELSE R.CustName END AS BillCustName,
           ISNULL(ZZ.SourceNo,'')     AS SourceNo,      -- 추가
           ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo,   -- 추가
           OutK.ValueText             AS IsReturn,      -- 반품
           Z.IsSpec                   AS IsSpec,        -- 생산사양
           S.SpecName                 AS SpecName,      -- 생산사양항목
           S.SpecValue                AS SpecValue,     --생산사양항목값           
		   CONVERT(DECIMAL(19, 5), ISNULL(U.SalesQty,0))		  AS SalesQty,		--매출진행수량
		   CONVERT(DECIMAL(19, 5), ISNULL(U.SalesAmt+U.SalesVAT, 0)) AS SalesPrice,	--매출금액
           CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen) - ROUND(ISNULL(U.SalesAmt,0),@CurLen) - ROUND(ISNULL(U.SalesVAT,0),@CurLen)) AS NonSalesAmt,
           ISNULL(CASE ISNULL(T.CustItemName, '')  
                  WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명  
           ISNULL(CASE ISNULL(T.CustItemNo, '')   
                  WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번  
           ISNULL(CASE ISNULL(T.CustItemSpec, '')   
              WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                  ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- 거래처품목규격  
            B.UMEtcOutKind          AS UMEtcOutKind, -- 기타출고구분코드
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMEtcOutKind), '') AS UMEtcOutKindName, -- 기타출고구분 
            ISNULL(B.LotNo, '')     AS LotNo,
            ISNULL(B.SerialNo, '')  AS SerialNo,
            C.AssetName AS AssetName,
            A.UMDVConditionSeq,
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMDVConditionSeq), '') AS UMDVConditionName,
            A.Memo,
            ISNULL(B.Dummy1,  '') AS Dummy1,
            ISNULL(B.Dummy2,  '') AS Dummy2,
            ISNULL(B.Dummy3,  '') AS Dummy3,
            ISNULL(B.Dummy4,  '') AS Dummy4,
            ISNULL(B.Dummy5,  '') AS Dummy5,
            ISNULL(B.Dummy6,  0)  AS Dummy6,
            ISNULL(B.Dummy7,  0)  AS Dummy7,
            ISNULL(B.Dummy8,  '') AS Dummy8,
            ISNULL(B.Dummy9,  '') AS Dummy9,
            ISNULL(B.Dummy10, '') AS Dummy10,
            -- 20130107 박성호 추가 (Dummy1 ~ 10)
            UU.ValueText AS IsRetroactivity,
            CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 and  A.IsDelvCfm =1  THEN '완료' ELSE '미완료' END  AS UMEtcOutProgress, --기타출고진행상태  20141107 이삭
            CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 THEN '1' ELSE '0' END   AS IsUMEtcOutKind,                               --기타출고구분여부  이삭
            D.UMCustClass   AS UMChannel,
            E.MinorName     AS UMChannelName,
            F.BizNo         AS CustBizNo
      FROM #Tmp_InvoiceProg AS Z    
            JOIN _TSLInvoice AS A WITH(NOLOCK) ON Z.InvoiceSeq = A.InvoiceSeq  
            JOIN _TSLInvoiceItem      AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                       AND A.InvoiceSeq = B.InvoiceSeq  
                                                       AND Z.InvoiceSerl = B.InvoiceSerl
            JOIN _TDASMinorValue      AS X WITH(NOLOCK) ON X.CompanySeq = @CompanySeq  
                                                       AND A.SMExpKind  = X.MinorSeq  
                                                       AND X.Serl       = 1001  
                                                       AND X.ValueText  = '1' 
            JOIN _TDAUMinorValue AS OutK WITH(NOLOCK) ON A.CompanySeq = OutK.CompanySeq 
                                                     AND A.UMOutKind  = Outk.MinorSeq
                                                     AND OutK.Serl = 2002    
            LEFT OUTER JOIN _TDACust  AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                       AND A.CustSeq    = F.CustSeq  
            LEFT OUTER JOIN _TDAUMinor AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq  
                                                        AND A.UMOutKind  = H.MinorSeq  
            LEFT OUTER JOIN _TDAItem   AS J WITH(NOLOCK) ON B.CompanySeq = J.CompanySeq  
                                                        AND B.ItemSeq    = J.ItemSeq  
            LEFT OUTER JOIN _TDAUMinorValue AS I WITH(NOLOCK) ON I.CompanySeq = H.CompanySeq  
                                                             AND I.MinorSeq   = H.MinorSeq  
                                                             AND I.Serl       = 2001  
            LEFT OUTER JOIN (SELECT A.InvoiceSeq, A.InvoiceSerl, MAX(B.Seq) AS SalesSeq, MAX(B.Serl) AS SalesSerl, 
                                    SUM(B.Qty) AS SalesQty, SUM(STDQty) AS SalesSTDQty, SUM(Amt) AS SalesAmt, SUM(VAT) AS SalesVat
                               FROM #Tmp_InvoiceProg AS A  
                                    JOIN #TCOMProgressTracking AS B ON A.IDX_NO = B.IDX_NO  
                              WHERE A.Qty * B.Qty >= 0  -- 반품건까지 포함되어 조건추가
                              GROUP BY A.InvoiceSeq, A.InvoiceSerl
                                ) AS U ON B.InvoiceSeq  = U.InvoiceSeq  
                                      AND B.InvoiceSerl = U.InvoiceSerl  
            LEFT OUTER JOIN _TPJTProject AS P WITH (NOLOCK) ON B.CompanySeq = P.CompanySeq  
                                                           AND B.PJTSeq     = P.PJTSeq  
            LEFT OUTER JOIN _TPJTWBS AS W WITH (NOLOCK) ON B.CompanySeq = W.CompanySeq  
                                                       AND B.PJTSeq     = W.PJTSeq  
                                                       AND B.WBSSeq     = W.WBSSeq  
            LEFT OUTER JOIN _TDACustGroup AS O WITH(NOLOCK) ON A.CompanySeq  = O.CompanySeq  
                                                           AND A.CustSeq     = O.CustSeq  
                                                           AND O.UMCustGroup = 8014002  
            LEFT OUTER JOIN _TDACustSalesReceiptCond AS Q WITH (NOLOCK) ON O.CompanySeq = Q.CompanySeq  
                                                                       AND O.UpperCustSeq = Q.CustSeq  
                                                                       AND O.CustSeq      = Q.ReceiptCustSeq
            LEFT OUTER JOIN _TDACust    AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq    
                                                         AND O.UpperCustSeq = R.CustSeq    
            LEFT OUTER JOIN #TempResult AS ZZ ON B.CompanySeq  = @CompanySeq  -- 추가
                                                          AND B.InvoiceSeq  = ZZ.InOutSeq  -- 추가
                                                          AND B.InvoiceSerl = ZZ.InOutSerl -- 추가
            LEFT OUTER JOIN #TempSOSpec AS S ON Z.OrderSeq  = S.OrderSeq
                                                         AND Z.OrderSerl = S.OrderSerl
            LEFT OUTER JOIN _TSLCustItem  AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq  
                                                           AND T.ItemSeq    = B.ItemSeq  
                                                           AND T.CustSeq    = A.CustSeq  
                                                           AND T.UnitSeq = B.UnitSeq 
            LEFT OUTER JOIN _TDAItemAsset AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                           AND C.AssetSeq = J.AssetSeq                                               
            LEFT OUTER JOIN _TDAUMinorValue AS UU WITH(NOLOCK) ON UU.CompanySeq = @CompanySeq AND UU.MajorSeq = 8020 AND UU.MinorSeq = A.UMOutKind AND UU.Serl = 2006
                       JOIN #TPJT_AUTH      AS AU WITH(NOLOCK) ON B.PJTSeq = AU.PJTSeq
            
            LEFT OUTER JOIN _TDACustClass   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq 
                                                           AND A.CustSeq = D.CustSeq
                                                           AND D.UMajorCustClass = 8004
            LEFT OUTER JOIN _TDAUMinor      AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq
                                                             AND D.UMCustClass = E.MinorSeq                                                         
                                                                        
     WHERE A.CompanySeq = @CompanySeq    
       AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')  
       AND (@PJTNo   = '' OR P.PJTNo   LIKE @PJTNo   + '%')  
       AND (@WBSName = '' OR W.WBSName LIKE @WBSName + '%')  
       AND ((@SMProgress = '0' AND (@SMProgressType = 0 OR (Z.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND Z.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )) OR (@SMProgress = '1' AND Z.SMProgressType IN (1037002, 1037003,1037001, 1037006)))
       AND (@SourceNo = '' OR ISNULL(ZZ.SourceNo,'') LIKE @SourceNo + '%')
       AND (@SourceRefNo = '' OR ZZ.SourceRefNo LIKE @SourceRefNo + '%')
       AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)
       --AND (@IsDelvCfm = '0' OR (@IsDelvCfm = '1' AND A.IsDelvCfm = '0' OR A.IsDelvCfm = ''))
       AND (@BillCustSeq = 0 OR (ISNULL(O.UpperCustSeq,0) = 0 AND A.CustSeq = @BillCustSeq) OR (O.UpperCustSeq = @BillCustSeq))
       AND (@UMEtcOutKind = 0 OR B.UMEtcOutKind = @UMEtcOutKind) -- 20130111 박성호 추가
     ORDER BY A.InvoiceDate, A.InvoiceNo, B.InvoiceSerl     
    END
    ELSE    -- 일반 영업 거래명세서품목 조회
    BEGIN  
    /*********************************** 
    -- 최종 데이터 조회
    ***********************************/  
    SELECT (SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)   AS BizUnitName,     --사업부문  
           A.InvoiceSeq     AS InvoiceSeq,      --거래명세서내부코드  
           A.InvoiceDate    AS InvoiceDate,     --거래명세서일  
           B.InvoiceSerl    AS InvoiceSerl,     --거래명세서순번  
           A.InvoiceNo      AS InvoiceNo,       --거래명세서번호  
           A.SMExpKind      AS SMExpKind,       --수출구분코드  
           (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.SMExpKind = MinorSeq)      AS SMExpKindName,   --수출구분  
           H.MinorName      AS UMOutKindName,   --출고구분  
           A.UMOutKind      AS UMOutKind,       --출고구분코드  
           I.ValueText      AS IsSales,         --매출동시발생  
           (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)      AS DeptName,        --부서  
           (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EmpSeq)        AS EmpName,         --담당자  
           F.CustName       AS CustName,        --거래처  
           F.CustNo         AS CustNo,          --거래처번호  
           A.CustSeq        AS CustSeq,         --거래처코드
           (SELECT DVPlaceName  FROM _TSLDeliveryCust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DVPlaceSeq = DVPlaceSeq)       AS DVPlaceName,    --납품거래처  
           A.IsStockSales   AS IsStockSales,    --판매후보관
           J.ItemSeq        AS ItemSeq,         --품목내부코드
           J.ItemName       AS ItemName,        --품명  
           J.ItemNo         AS ItemNo,          --품번  
           J.Spec           AS Spec,            --규격  
           (SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)       AS UnitName,        --판매단위  
           B.ItemPrice      AS ItemPrice,       --품목단가  
           B.CustPrice      AS CustPrice,       --회사단가  
           B.Qty            AS Qty,             --수량  
           B.RetroactivityQty            AS RetroactivityQty,             --수량(단가소급)
           B.IsInclusedVAT  AS IsInclusedVAT,   --부가세포함  
           B.VATRate        AS VATRate,         --부가세율
	       A.CurrSeq		AS CurrSeq,			--통화코드
	       (SELECT CurrName FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq)	AS CurrName,		--통화   
	       CONVERT(DECIMAL(19, 5), A.ExRate)         AS ExRate,          -- 환율
           CONVERT(DECIMAL(19, 5), 
           CASE WHEN B.Price IS NOT NULL
                THEN B.Price
                ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0))           
                                                           ELSE (ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END) AS Price,   --판매단가  
           ROUND(B.CurAmt,@CurLen)         AS CurAmt,          --판매금액  
           ROUND(B.CurVAT,@CurLen)         AS CurVAT,          --부가세액  
           CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen)) AS TotCurAmt, -- 판매금액총액
           ROUND(ISNULL(B.DomAmt, 0), @DomLen)         AS DomAmt,          --원화판매금액  
           ROUND(ISNULL(B.DomVAT, 0), @DomLen)         AS DomVAT,          --원화부가세액  
           CONVERT(DECIMAL(19, 5), ROUND(ISNULL(B.DomAmt, 0), @DomLen) + ROUND(ISNULL(B.DomVAT, 0), @DomLen)) AS TotDomAmt, -- 원화판매금액총액
           ISNULL((SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq), '')        AS STDUnitName,     --기준단위  
           B.STDQty         AS STDQty,          --기준단위수량  
           (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.WHSeq = WHSeq)        AS WHName,          --창고
           A.Remark         AS RemarkM,          --마스터비고  
           B.Remark         AS RemarkI,          --비고  
           --(SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq)   AS SMProgressTypeName, --진행상태  
           CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 THEN  (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) + ' ' + ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMEtcOutKind), '')
           ELSE (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq) END AS SMProgressTypeName, --진행상태    20141107 이삭 수정           
           Z.SMProgressType         AS SMProgressType,
           ISNULL(U.SalesSeq,0) AS SalesSeq,  
           ISNULL(U.SalesSerl,0) AS SalesSerl,  
           ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = B.CCtrSeq), '') AS CCtrName,
           B.CCtrSeq                AS CCtrSeq,
           B.PJTSeq                 AS PJTSeq,  
           B.WBSSeq                 AS WBSSeq,  
           P.PJTName                AS PJTName,  
           P.PJTNo                  AS PJTNo,  
           W.WBSName                AS WBSName,  
           A.IsDelvCfm              AS IsDelvCfm,
           CASE WHEN ISNULL(A.SMSalesCrtKind,0) = 0 THEN ISNULL(Q.SMSalesPoint,0) ELSE ISNULL(A.SMSalesCrtKind,0) END AS SMSalesCrtKind,  
           CASE WHEN ISNULL(A.SMSalesCrtKind,0) = 0 THEN ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = Q.SMSalesPoint), '')   
                                                    ELSE ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMSalesCrtKind), '') END AS SMSalesCrtKindName,
           A.IsPJT AS IsPJT,
           CASE WHEN ISNULL(O.UpperCustSeq,0) = 0 THEN A.CustSeq ELSE O.UpperCustSeq END AS BillCustSeq,
           CASE WHEN ISNULL(R.CustName,'') = '' THEN F.CustName ELSE R.CustName END AS BillCustName,
           ISNULL(ZZ.SourceNo,'')     AS SourceNo,      -- 추가
           ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo,   -- 추가
           OutK.ValueText             AS IsReturn,      -- 반품
           Z.IsSpec                   AS IsSpec,        -- 생산사양
           S.SpecName                 AS SpecName,      -- 생산사양항목
           S.SpecValue                AS SpecValue,     --생산사양항목값           
		   CONVERT(DECIMAL(19, 5), ISNULL(U.SalesQty,0))		  AS SalesQty,		--매출진행수량
		   CONVERT(DECIMAL(19, 5), ISNULL(U.SalesAmt+U.SalesVAT, 0)) AS SalesPrice,	--매출금액
           CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen) - ROUND(ISNULL(U.SalesAmt,0),@CurLen) - ROUND(ISNULL(U.SalesVAT,0),@CurLen)) AS NonSalesAmt,
           ISNULL(CASE ISNULL(T.CustItemName, '')  
                  WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명  
           ISNULL(CASE ISNULL(T.CustItemNo, '')   
                  WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번  
           ISNULL(CASE ISNULL(T.CustItemSpec, '')   
                  WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                  ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- 거래처품목규격  
            B.UMEtcOutKind          AS UMEtcOutKind, -- 기타출고구분코드
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMEtcOutKind), '') AS UMEtcOutKindName, -- 기타출고구분 
            ISNULL(B.LotNo, '')     AS LotNo,
            ISNULL(B.SerialNo, '')  AS SerialNo,
            C.AssetName AS AssetName,
            A.UMDVConditionSeq,
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMDVConditionSeq), '') AS UMDVConditionName,
            A.Memo,
            ISNULL(B.Dummy1,  '') AS Dummy1,
            ISNULL(B.Dummy2,  '') AS Dummy2,
            ISNULL(B.Dummy3,  '') AS Dummy3,
            ISNULL(B.Dummy4,  '') AS Dummy4,
            ISNULL(B.Dummy5,  '') AS Dummy5,
            ISNULL(B.Dummy6,  0)  AS Dummy6,
            ISNULL(B.Dummy7,  0)  AS Dummy7,
            ISNULL(B.Dummy8,  '') AS Dummy8,
            ISNULL(B.Dummy9,  '') AS Dummy9,
            ISNULL(B.Dummy10, '') AS Dummy10,
            -- 20130107 박성호 추가 (Dummy1 ~ 10)
            UU.ValueText AS IsRetroactivity,
            CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 and  A.IsDelvCfm =1  THEN '완료' ELSE '미완료' END  AS UMEtcOutProgress, --기타출고진행상태  20141107 이삭
            CASE WHEN ISNULL(B.UMEtcOutKind,0) <> 0 THEN '1' ELSE '0' END   AS IsUMEtcOutKind,                               --기타출고구분여부  이삭
            ISNULL(WHI.Location, '') AS WHLocation,        -- 20141126 조성환(2014) 추가     
            D.UMCustClass   AS UMChannel,
            E.MinorName     AS UMChannelName,
            F.BizNo         AS CustBizNo
      FROM #Tmp_InvoiceProg AS Z    
            JOIN _TSLInvoice                AS A WITH(NOLOCK) ON Z.InvoiceSeq       = A.InvoiceSeq  
            JOIN _TSLInvoiceItem            AS B WITH(NOLOCK) ON A.CompanySeq       = B.CompanySeq  
                                                             AND A.InvoiceSeq       = B.InvoiceSeq  
                                                             AND Z.InvoiceSerl      = B.InvoiceSerl
            JOIN _TDASMinorValue            AS X WITH(NOLOCK) ON X.CompanySeq       = @CompanySeq  
                                                             AND A.SMExpKind        = X.MinorSeq  
                                                             AND X.Serl             = 1001  
                                                             AND X.ValueText        = '1' 
            JOIN _TDAUMinorValue            AS OutK WITH(NOLOCK) ON A.CompanySeq    = OutK.CompanySeq 
                                                             AND A.UMOutKind        = Outk.MinorSeq
                                                             AND OutK.Serl          = 2002    
            LEFT OUTER JOIN _TDACust        AS F WITH(NOLOCK) ON A.CompanySeq       = F.CompanySeq  
                                                             AND A.CustSeq          = F.CustSeq  
            LEFT OUTER JOIN _TDAUMinor      AS H WITH(NOLOCK) ON A.CompanySeq       = H.CompanySeq  
                                                             AND A.UMOutKind        = H.MinorSeq  
            LEFT OUTER JOIN _TDAItem        AS J WITH(NOLOCK) ON B.CompanySeq       = J.CompanySeq  
                                                             AND B.ItemSeq          = J.ItemSeq  
      LEFT OUTER JOIN _TDAUMinorValue AS I WITH(NOLOCK) ON I.CompanySeq       = H.CompanySeq  
                                                             AND I.MinorSeq         = H.MinorSeq  
                                                             AND I.Serl             = 2001  
            LEFT OUTER JOIN (SELECT A.InvoiceSeq, A.InvoiceSerl, MAX(B.Seq) AS SalesSeq, MAX(B.Serl) AS SalesSerl, 
                                    SUM(B.Qty) AS SalesQty, SUM(STDQty) AS SalesSTDQty, SUM(Amt) AS SalesAmt, SUM(VAT) AS SalesVat
                               FROM #Tmp_InvoiceProg AS A  
                                    JOIN #TCOMProgressTracking AS B ON A.IDX_NO = B.IDX_NO  
                              WHERE A.Qty * B.Qty >= 0  -- 반품건까지 포함되어 조건추가
                              GROUP BY A.InvoiceSeq, A.InvoiceSerl
                                ) AS U ON B.InvoiceSeq  = U.InvoiceSeq  
                                      AND B.InvoiceSerl = U.InvoiceSerl  
            LEFT OUTER JOIN _TPJTProject    AS P WITH (NOLOCK) ON B.CompanySeq      = P.CompanySeq  
                                                              AND B.PJTSeq          = P.PJTSeq  
            LEFT OUTER JOIN _TPJTWBS        AS W WITH (NOLOCK) ON B.CompanySeq      = W.CompanySeq  
                                                              AND B.PJTSeq          = W.PJTSeq  
                                                              AND B.WBSSeq          = W.WBSSeq  
            LEFT OUTER JOIN _TDACustGroup   AS O WITH(NOLOCK) ON A.CompanySeq       = O.CompanySeq  
                                                              AND A.CustSeq         = O.CustSeq  
                                                              AND O.UMCustGroup     = 8014002  
            LEFT OUTER JOIN _TDACustSalesReceiptCond AS Q WITH (NOLOCK) ON O.CompanySeq   = Q.CompanySeq  
                                                                       AND O.UpperCustSeq = Q.CustSeq  
                                                                       AND O.CustSeq      = Q.ReceiptCustSeq
            LEFT OUTER JOIN _TDACust        AS R WITH(NOLOCK)   ON R.CompanySeq     = @CompanySeq    
                                                               AND O.UpperCustSeq   = R.CustSeq    
            LEFT OUTER JOIN #TempResult     AS ZZ               ON B.CompanySeq     = @CompanySeq  -- 추가
                                                               AND B.InvoiceSeq     = ZZ.InOutSeq  -- 추가
                                                               AND B.InvoiceSerl    = ZZ.InOutSerl -- 추가
            LEFT OUTER JOIN #TempSOSpec     AS S                ON Z.OrderSeq       = S.OrderSeq
                                                               AND Z.OrderSerl      = S.OrderSerl
            LEFT OUTER JOIN _TSLCustItem    AS T WITH(NOLOCK)   ON T.CompanySeq     = @CompanySeq  
                                                               AND T.ItemSeq        = B.ItemSeq  
                                                               AND T.CustSeq        = A.CustSeq  
                                                               AND T.UnitSeq        = B.UnitSeq 
            LEFT OUTER JOIN _TDAItemAsset   AS C WITH(NOLOCK)   ON C.CompanySeq     = @CompanySeq
                                                               AND C.AssetSeq       = J.AssetSeq                                               
            LEFT OUTER JOIN _TDAUMinorValue AS UU WITH(NOLOCK)  ON UU.CompanySeq    = @CompanySeq AND UU.MajorSeq = 8020 AND UU.MinorSeq = A.UMOutKind AND UU.Serl = 2006
            LEFT OUTER JOIN _TDAWHItem      AS WHI WITH(NOLOCK) ON WHI.CompanySeq   = B.CompanySeq
                                                               AND WHI.WHseq        = B.WHseq   
                                                               AND WHI.Itemseq      = B.Itemseq  -- 창고Location 추가 :: 20141126 조성환(2014)
            LEFT OUTER JOIN _TDACustClass   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq 
                                                             AND A.CustSeq = D.CustSeq
                                                             AND D.UMajorCustClass = 8004
            LEFT OUTER JOIN _TDAUMinor      AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq
                                                             AND D.UMCustClass = E.MinorSeq                                                               
     WHERE A.CompanySeq = @CompanySeq    
       AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')  
       AND (@PJTNo   = '' OR P.PJTNo   LIKE @PJTNo   + '%')  
       AND (@WBSName = '' OR W.WBSName LIKE @WBSName + '%')  
       AND ((@SMProgress = '0' AND (@SMProgressType = 0 OR (Z.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND Z.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )) OR (@SMProgress = '1' AND Z.SMProgressType IN (1037002, 1037003,1037001, 1037006)))
       AND (@SourceNo = '' OR ISNULL(ZZ.SourceNo,'') LIKE @SourceNo + '%')
       AND (@SourceRefNo = '' OR ZZ.SourceRefNo LIKE @SourceRefNo + '%')
       AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)
       --AND (@IsDelvCfm = '0' OR (@IsDelvCfm = '1' AND A.IsDelvCfm = '0' OR A.IsDelvCfm = ''))
       AND (@BillCustSeq = 0 OR (ISNULL(O.UpperCustSeq,0) = 0 AND A.CustSeq = @BillCustSeq) OR (O.UpperCustSeq = @BillCustSeq))
       AND (@UMEtcOutKind = 0 OR B.UMEtcOutKind = @UMEtcOutKind) -- 20130111 박성호 추가
     ORDER BY A.InvoiceDate, A.InvoiceNo, B.InvoiceSerl     
    END
	RETURN    
