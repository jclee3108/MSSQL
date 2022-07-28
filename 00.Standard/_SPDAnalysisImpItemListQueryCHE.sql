
IF OBJECT_ID('_SPDAnalysisImpItemListQueryCHE') IS NOT NULL 
    DROP PROC _SPDAnalysisImpItemListQueryCHE
GO 

/************************************************************  
  설  명 - 데이터-공정분석자료(내수)조회 : 거래명세서품목현황조회  
  작성일 - 20090625  
  작성자 - 박헌기  
 ************************************************************/  
 CREATE PROC dbo._SPDAnalysisImpItemListQueryCHE
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
      DECLARE @docHandle      INT,  
             @BizUnit        INT,   
             @DVReqDateFr    NCHAR(8),   
             @DVReqDateTo    NCHAR(8),   
             @UMOutKind      INT,   
             @DVReqNo        NVARCHAR(20),  
             @DeptSeq        INT,   
             @EmpSeq         INT,   
             @CustSeq        INT,  
             @CustNo         NVARCHAR(20),   
             @ItemSeq        INT,   
             @ItemNo         NVARCHAR(30),   
             @SMConfirm      INT,   
             @SMProgressType   INT,
             @DVDateFrom     NCHAR(8),
             @DVDateTo       NCHAR(8),
             @SMExpKind      INT,
             @IsReturn       NCHAR(1),
             -- 생산사양용
             @Seq            INT, 
             @OrderSeq       INT, 
             @OrderSerl      INT, 
             @SubSeq         INT, 
             @SpecName       NVARCHAR(200),   
             @SpecValue      NVARCHAR(200)  
      -- 추가변수
     DECLARE @SourceTableSeq INT,
             @SourceNo       NVARCHAR(30),
             @SourceRefNo    NVARCHAR(30),
             @TableName      NVARCHAR(100),
             @TableSeq       INT,
             @SQL            NVARCHAR(MAX)
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
   
     -- Temp에 INSERT      
     --    INSERT INTO #TXBProcessActRevQry(ProcessCd,ProcessRev,ActivitySeq,ActivityRev)      
     SELECT  @BizUnit        = ISNULL(BizUnit, 0),   
             @DVReqDateFr    = ISNULL(DVReqDateFr, ''),   
             @DVReqDateTo    = ISNULL(DVReqDateTo, ''),   
             @UMOutKind      = ISNULL(UMOutKind, 0),   
             @DVReqNo        = LTRIM(RTRIM(ISNULL(DVReqNo, ''))),  
             @DeptSeq        = ISNULL(DeptSeq, 0),   
             @EmpSeq         = ISNULL(EmpSeq, 0),   
             @ItemSeq        = ISNULL(ItemSeq, 0),  
             @ItemNo         = LTRIM(RTRIM(ISNULL(ItemNo, ''))),   
             @CustSeq        = ISNULL(CustSeq, 0),  
             @CustNo         = LTRIM(RTRIM(ISNULL(CustNo, ''))),   
             @SMConfirm      = ISNULL(SMConfirm, 0),   
             @SMProgressType = ISNULL(SMProgressType, 0),
             @DVDateFrom     = ISNULL(DVDateFrom, ''),
             @DVDateTo       = ISNULL(DVDateTo, ''),
             @SMExpKind      = ISNULL(SMExpKind, 0),
             @IsReturn       = ISNULL(IsReturn,''),
             @SourceTableSeq   = ISNULL(SourceTableSeq, 0),  -- 추가
             @SourceNo         = ISNULL(SourceNo, ''),       -- 추가
             @SourceRefNo      = ISNULL(SourceRefNo, '')     -- 추가  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (BizUnit INT, DVReqDateFr NCHAR(8), DVReqDateTo NCHAR(8), UMOutKind INT,       DVReqNo NVARCHAR(20),   
           DeptSeq INT, EmpSeq         INT,   CustSeq        INT,   CustNo NVARCHAR(20), SMConfirm INT,   
           ItemSeq INT, ItemNo  NVARCHAR(30), SMProgressType INT,   DVDateFrom NCHAR(8), DVDateTo NCHAR(8),
           SMExpKind INT, IsReturn  NCHAR(1),
           SourceTableSeq      INT,            -- 추가
           SourceNo            NVARCHAR(30),   -- 추가
           SourceRefNo         NVARCHAR(30))   -- 추가)     
   
     IF @DVReqDateTo = ''  
         SELECT @DVReqDateTo = '99991231'  
      IF @DVDateTo = ''  
         SELECT @DVDateTo = '99991231'  
   
 /***********************************************************************************************************************************************/  
 ---------------------- 조직도 연결 여부  
     DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
   
     IF @DVReqDateTo = '99991231'  
         SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)  
     ELSE  
         SELECT  @OrgStdDate = @DVReqDateTo  
   
     SELECT  @SMOrgSortSeq = 0  
     SELECT  @SMOrgSortSeq = SMOrgSortSeq  
       FROM  _TCOMOrgLinkMng  
      WHERE  CompanySeq = @CompanySeq  
        AND  PgmSeq     = @PgmSeq  
   
     DECLARE @DeptTable Table  
     (   DeptSeq     INT)  
   
     INSERT  @DeptTable  
     SELECT  DISTINCT DeptSeq  
       FROM  dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)  
   
 ---------------------- 조직도 연결 여부    
      CREATE TABLE #Tmp_DVReqItemProg(IDX_NO INT IDENTITY, DVReqSeq INT, DVReqSerl INT, CompleteCHECK INT, SMProgressType INT NULL, 
                                     IsStop NCHAR(1) NULL, DVDate NCHAR(8), OrderSeq INT, OrderSerl INT, IsSpec NCHAR(1))  
      -- 원천테이블
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))        
      -- 원천 데이터 테이블
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))    
      -- 생산사양 항목  
     CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(200), SpecValue NVARCHAR(200))  
  
      --/**************************************************************************
     -- 기초Data                                                                
     --**************************************************************************/
     INSERT INTO #Tmp_DVReqItemProg(DVReqSeq, DVReqSerl, CompleteCHECK, IsStop, DVDate)  
     SELECT A.DVReqSeq, B.DVReqSerl, -1, CASE A.IsStop WHEN '1' THEN '1' ELSE B.IsStop END,
            CASE WHEN ISNULL(B.DVDate,'') = '' THEN ISNULL(A.DVDate,'') ELSE ISNULL(B.DVDate,'') END
       FROM _TSLDVReq AS A WITH(NOLOCK)   
             JOIN _TSLDVReqItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                 AND A.DVReqSeq   = B.DVReqSeq      
             JOIN _TDASMinorValue AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                   AND A.SMExpKind = C.MinorSeq  
             LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                              AND A.UMOutKind  = D.MinorSeq
                                                              AND D.Serl       = 2002
             LEFT OUTER JOIN _TDAItem        AS E WITH(NOLOCK) ON B.CompanySeq = E.CompanySeq
                                                              AND B.ItemSeq    = E.ItemSeq                                                             
      WHERE A.CompanySeq = @CompanySeq    
        AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)  
        AND (A.DVReqDate BETWEEN @DVReqDateFr AND @DVReqDateTo)  
        AND ((CASE WHEN ISNULL(B.DVDate,'') = '' THEN ISNULL(A.DVDate,'') ELSE ISNULL(B.DVDate,'') END) BETWEEN @DVDateFrom AND @DVDateTo)
        AND (@UMOutKind = 0 OR A.UMOutKind = @UMOutKind)  
        AND (@DVReqNo = '' OR A.DVReqNo LIKE @DVReqNo + '%')  
 ---------- 조직도 연결 변경 부분    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- 조직도 연결 변경 부분          
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)  
        AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)  
        AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)  
        AND (@ItemSeq = 0 OR B.ItemSeq = @ItemSeq)  
        AND (@ItemNo = '' OR E.ItemNo LIKE @ItemNo + '%') 
        AND C.Serl = 1001 AND C.ValueText = '1'  
        AND ((@IsReturn = '1' AND ISNULL(D.ValueText,'') = '1') 
             OR (@IsReturn <> '1' AND ISNULL(D.ValueText,'') <> '1'))
  
   --/**************************************************************************
     -- 진행Data                                                                
     --**************************************************************************/  
     EXEC _SCOMProgStatus @CompanySeq, '_TSLDVReqItem', 1036001, '#Tmp_DVReqItemProg', 'DVReqSeq', 'DVReqSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'DVReqSeq', 'DVReqSerl', '', '_TSLDVReq', @pgmSeq
   
     UPDATE #Tmp_DVReqItemProg   
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --진행중단  
                                          WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료  
                                          WHEN A.IsStop = '1' THEN 1037005 -- 중단  
                                          ELSE B.MinorSeq END)   
   
       FROM #Tmp_DVReqItemProg AS A   
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                         AND A.CompleteCHECK = B.Minorvalue  
     --/**************************************************************************
     -- 생산사양Data                                                                
     --**************************************************************************/ 
     INSERT #TMP_SOURCETABLE
     SELECT '_TSLOrderItem'
      -- 수주Data찾기(원천)
     EXEC _SCOMSourceTracking @CompanySeq, '_TSLDVReqItem', '#Tmp_DVReqItemProg', 'DVReqSeq', 'DVReqSerl', ''       
      UPDATE #Tmp_DVReqItemProg
        SET OrderSeq  = Seq,
            OrderSerl = Serl, 
            IsSpec = '1'
       FROM #Tmp_DVReqItemProg AS A
             JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
             JOIN _TSLOrderItemSpec   AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                       AND B.Seq        = C.OrderSeq
                                                       AND B.Serl       = C.OrderSerl
      INSERT INTO #TempSOSpec 
     SELECT DISTINCT Seq, Serl, '', ''
       FROM #TCOMSourceTracking
  
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
  
  
 --select * from #Tmp_DVReqItemProg  
 --select * from #TCOMSourceTracking
      -------------------------------------------      
     -- 원천진행 조회 
     -------------------------------------------   
     CREATE TABLE #TempResult
     (
         InOutSeq  INT,  -- 진행내부번호
         InOutSerl  INT,  -- 진행순번
         InOutSubSerl    INT,
         SourceRefNo     NVARCHAR(30),
         SourceNo        NVARCHAR(30)
     )
      IF ISNULL(@SourceTableSeq, 0) <> 0
     BEGIN
         DELETE #TMP_SOURCETABLE     
         
         DELETE #TCOMSourceTracking      
         
         CREATE TABLE #TMP_SOURCEITEM
         (      
             IDX_NO        INT IDENTITY,      
             SourceSeq     INT,      
             SourceSerl    INT,      
             SourceSubSerl INT
         )         
  
         IF ISNULL(@TableName, '') <> ''
         BEGIN
             SELECT @TableSeq = ProgTableSeq    
               FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블    
              WHERE ProgTableName = @TableName  
         END
          IF ISNULL(@TableSeq,0) = 0
         BEGIN
             SELECT @TableSeq = ISNULL(ProgTableSeq, 0)
               FROM _TCAPgmDev
              WHERE PgmSeq = @PgmSeq
              SELECT @TableName = ISNULL(ProgTableName, '')
               FROM _TCOMProgTable
              WHERE ProgTableSeq = @TableSeq
         END
          INSERT INTO #TMP_SOURCETABLE(TABLENAME)    
         SELECT ISNULL(ProgTableName,'')
           FROM _TCOMProgTable
          WHERE ProgTableSeq = @SourceTableSeq
  
         -- 주의
         INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(진행), 2(미진행)    
         SELECT  A.DVReqSeq, A.DVReqSerl, 0 
           FROM #Tmp_DVReqItemProg     AS A WITH(NOLOCK)    
  
         EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''      
  
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
  
         EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq
          SELECT @SQL = ''
      END
  
     CREATE TABLE #tem_QCData
     (
         CompanySeq      INT,
         DVReqSeq        INT,
         DVReqSerl       INT,
         TestEndDate     NCHAR(8),
         Qty             DECIMAL(19,5),
         PassedQty       DECIMAL(19,5),
         QCStdUnitQty    DECIMAL(19,5),
         SourceTypeName  NVARCHAR(100),
         SMTestResult    INT
     )
       INSERT INTO #tem_QCData(CompanySeq  ,DVReqSeq,  DVReqSerl,   TestEndDate,   Qty,     PassedQty,  QCStdUnitQty, SourceTypeName, SMTestResult)
          SELECT  @CompanySeq,    
                 B.SourceSeq,    
                 B.SourceSerl,   
                 SUBSTRING(TestEndDate,1,8) , 
                 C.Qty  ,
                 SUM(ISNULL(B.PassedQty,0)),
                 SUM(ISNULL(CASE WHEN ISNULL(ConvDen,0) = 0 THEN 0 ELSE ISNULL(B.PassedQty,0) * (ConvNum/ConvDen) END,0)),
                 ISNULL(E.MinorName,'')  AS SourceTypeName,
                 B.SMTestResult
            FROM #Tmp_DVReqItemProg             AS A 
                       JOIN _TPDQCTestReport         AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                      AND A.DVReqSeq    = B.SourceSeq
                                                                      AND A.DVReqSerl   = B.SourceSerl
                                                                      AND B.SourceType = '5'
                       JOIN _TSLDVReqItem            AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
                                                                      AND C.DVReqSeq    = B.SourceSeq
                                                                      AND C.DVReqSerl   = B.SourceSerl
            LEFT OUTER JOIN _TDAItemUnit             AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq
                                                                      AND C.ItemSeq    = D.ItemSeq
                                                                      AND C.UnitSeq    = D.UnitSeq
            LEFT OUTER JOIN _TDASMinor               AS E WITH(NOLOCK) ON B.CompanySeq = E.CompanySeq 
                                                                      AND B.SMTestResult = E.MinorSeq
      GROUP BY B.SourceSeq, B.SourceSerl,C.Qty,B.TestEndDate,B.SMTestResult, E.MinorName
  
     CREATE INDEX IX_#tem_QCData ON #tem_QCData(DVReqSeq, DVReqSerl)
     CREATE INDEX IX_#TempSOSpec ON #TempSOSpec(OrderSeq, OrderSerl)
     CREATE INDEX IX_#TempResult ON #TempResult(InOutSeq, InOutSerl)
      --/**************************************************************************
     -- 최종조회                                                                
     --**************************************************************************/  
     SELECT CASE A.IsStop WHEN '1' THEN '1' ELSE I.IsStop END AS IsStop,              --중단  
            (SELECT BizUnitName  FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)      AS BizUnitName,         --사업부문  
            A.DVReqNo            AS DVReqNo,             --출하의뢰번호  
            A.DVReqSeq           AS DVReqSeq,            --출하의뢰내부번호  
            I.DVReqSerl          AS DVReqSerl,           --출하의뢰순번  
            A.DVReqDate          AS DVReqDate,           --출하의뢰일자  
            (SELECT MinorName    FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND A.SMExpKind = MinorSeq)    AS SMExpKindName,       --수출구분  
            (SELECT MinorName    FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND A.UMOutKind = MinorSeq)    AS UMOutKindName,       --출고구분  
            A.SMConsignKind      AS SMConsignKind,       --위탁구분코드
            (SELECT MinorName    FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND A.SMConsignKind = MinorSeq)         AS SMConsignKindName,   --위탁구분
            (SELECT DeptName     FROM _TDADept   WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)       AS DeptName,            --부서  
            (SELECT EmpName      FROM _TDAEmp    WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EmpSeq)         AS EmpName,             --담당자  
            F.CustName           AS CustName,            --거래처  
            F.CustNo             AS CustNo,              --거래처번호  
            A.CustSeq            AS CustSeq,             --거래처코드  
            J.ItemName           AS ItemName,            --품명  
            J.ItemEngName        AS ItemEngName,
            J.ItemNo             AS ItemNo,              --품번  
            J.Spec               AS Spec,                --규격  
            (SELECT UnitName     FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND I.UnitSeq = UnitSeq)       AS UnitName,            --판매단위  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.Qty * -1 ELSE I.Qty END AS Qty,                 --수량  
            (SELECT UnitName     FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND I.STDUnitSeq = UnitSeq)           AS STDUnitName,         --기준단위  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.STDQty * -1 ELSE I.STDQty END  AS STDQty,              --기준단위수량  
            I.ItemPrice          AS ItemPrice,           --품목단가  
            I.CustPrice          AS CustPrice,           --회사단가  
  --           CASE WHEN ISNULL(I.Qty,0) = 0 THEN 0 ELSE (CASE WHEN I.IsInclusedVAT = '1' THEN (ISNULL(I.CurAmt,0) + ISNULL(I.CurVat,0)) / ISNULL(I.Qty,0)  
 --                                                                                       ELSE ISNULL(I.CurAmt,0) / ISNULL(I.Qty,0) END) END AS Price,  
             -- 단가수정 :: 이성덕
            CASE WHEN I.Price IS NOT NULL
                 THEN I.Price
                 ELSE (CASE WHEN ISNULL(I.Qty,0) = 0 THEN 0 ELSE (CASE WHEN I.IsInclusedVAT = '1' THEN (ISNULL(I.CurAmt,0) + ISNULL(I.CurVat,0)) / ISNULL(I.Qty,0)  
                                                                                        ELSE ISNULL(I.CurAmt,0) / ISNULL(I.Qty,0) END) END) END AS Price,     --판매단가
  
            I.IsInclusedVAT      AS IsInclusedVAT,       --부가세포함  
            I.VATRate            AS VATRate,             --부가세율  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.CurVAT * -1 ELSE I.CurVAT END AS CurVAT,              --부가세금액  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.CurAmt * -1 ELSE I.CurAmt END AS CurAmt,              --판매금액  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.DomVAT * -1 ELSE I.DomVAT END AS DomVAT,              --원화부가세금액  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.DomAmt * -1 ELSE I.DomAmt END AS DomAmt,              --원화판매금액             
            X.DVDate             AS DVDateD,             --납기일자
            I.DVTime             AS DVTime,              --납기시분  
            (SELECT WHName       FROM _TDAWH WHERE CompanySeq = @CompanySeq AND I.WHSeq = WHSeq)       AS WHName,              --창고  
            (SELECT DVPlaceName  FROM _TSLDeliveryCust WHERE CompanySeq = @CompanySeq AND I.DVPlaceSeq = DVPlaceSeq)       AS DVPlaceName,         --납품처  
            I.Remark             AS RemarkD,             --비고  
            N.MinorName        AS SMProgressTypeName,   --진행상태  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMExpKind),'') AS SMExpKindName, 
            X.IsSpec         AS IsSpec,       -- 생산사양
            S.SpecName       AS SpecName,     -- 생산사양항목
            S.SpecValue      AS SpecValue,     --생산사양항목값
            ISNULL(ZZ.SourceNo,'') AS SourceNo, -- 추가
            ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo, -- 추가
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN '무검사'  
                 WHEN ISNULL(Q.SourceTypeName, '' ) = '' THEN '미검사'
                 ELSE Q.SourceTypeName END AS SMQCTypeName,
            --ISNULL(K.PassedQty, 0)      AS PassedQty,     --합격수량
            --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN B.Qty ELSE ISNULL(K.PassedQty, 0) END AS DVQty,
            --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN ISNULL(B.STDQty, 0)  ELSE ISNULL(K.QCStdUnitQty, 0) END  AS QCStdUnitQty,
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN '' ELSE Q.TestEndDate END AS QCDate,
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN 6035001
                 WHEN ISNULL(Q.SMTestResult,0) = 0 THEN 6035002
                 ELSE Q.SMTestResult     END AS SMQCType,
            ISNULL(CASE ISNULL(T.CustItemName, '')  
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명  
            ISNULL(CASE ISNULL(T.CustItemNo, '')   
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번  
            ISNULL(CASE ISNULL(T.CustItemSpec, '')   
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                   ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- 거래처품목규격
            I.UMReturnKind, -- 반품유형  
            A.UMDVConditionSeq   AS UMDVConditionSeq,
            A.IsStockSales   AS IsStockSales,
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMDVConditionSeq),'') AS UMDVConditionName,
            ISNULL( ( SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8025 AND MinorSeq = I.UMEtcOutKind ), '' ) AS UMEtcOutKindName, -- 기타출고구분, 2011.11.04 by 김철웅  
            A.ExRate            AS ExRate,            --부가세율 
            A.CurrSeq,
            C.CurrName  -- 통화
       FROM #Tmp_DVReqItemProg AS X   
             LEFT OUTER JOIN _TSLDVReq AS A WITH(NOLOCK) ON X.DVReqSeq = A.DVReqSeq  
                        JOIN _TSLDVReqItem  AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq  
                                                  AND X.DVReqSeq   = I.DVReqSeq  
                                                  AND X.DVReqSerl  = I.DVReqSerl  
             LEFT OUTER JOIN _TDACust   AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                         AND A.CustSeq    = F.CustSeq  
             LEFT OUTER JOIN _TDAItem   AS J WITH(NOLOCK) ON I.CompanySeq = J.CompanySeq  
                                                         AND I.ItemSeq    = J.ItemSeq  
             LEFT OUTER JOIN _TDASMinor AS N WITH(NOLOCK) ON I.CompanySeq = N.CompanySeq  
                                                         AND X.SMProgressType = N.MinorSeq  
             LEFT OUTER JOIN #TempSOSpec AS S WITH(NOLOCK) ON X.OrderSeq  = S.OrderSeq
                                                          AND X.OrderSerl = S.OrderSerl
             LEFT OUTER JOIN #TempResult AS ZZ WITH(NOLOCK) ON I.CompanySeq  = @CompanySeq  -- 추가
                                                           AND I.DVReqSeq  = ZZ.InOutSeq  -- 추가
                                                           AND I.DVReqSerl = ZZ.InOutSerl -- 추가
             LEFT OUTER JOIN #tem_QCData AS Q               ON I.CompanySeq = Q.CompanySeq
                                                           AND I.DVReqSeq   = Q.DVReqSeq  
                                                           AND I.DVReqSerl  = Q.DVReqSerl  
             LEFT OUTER JOIN _TSLCustItem  AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq  
                                                            AND I.ItemSeq    = T.ItemSeq  
                                                            AND A.CustSeq    = T.CustSeq  
         AND I.UnitSeq = T.UnitSeq  
             LEFT OUTER JOIN _TDACurr   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                                                         AND A.CurrSeq    = C.CurrSeq  
      WHERE A.CompanySeq = @CompanySeq   
        AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)  
        AND (@SourceNo = '' OR ISNULL(ZZ.SourceNo,'') LIKE @SourceNo + '%')
        AND (@SourceRefNo = '' OR ZZ.SourceRefNo LIKE @SourceRefNo + '%')
      ORDER BY A.DVReqNo, I.DVReqSerl
 RETURN