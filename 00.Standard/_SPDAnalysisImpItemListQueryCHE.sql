
IF OBJECT_ID('_SPDAnalysisImpItemListQueryCHE') IS NOT NULL 
    DROP PROC _SPDAnalysisImpItemListQueryCHE
GO 

/************************************************************  
  ��  �� - ������-�����м��ڷ�(����)��ȸ : �ŷ�����ǰ����Ȳ��ȸ  
  �ۼ��� - 20090625  
  �ۼ��� - �����  
 ************************************************************/  
 CREATE PROC dbo._SPDAnalysisImpItemListQueryCHE
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.    
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
             -- �������
             @Seq            INT, 
             @OrderSeq       INT, 
             @OrderSerl      INT, 
             @SubSeq         INT, 
             @SpecName       NVARCHAR(200),   
             @SpecValue      NVARCHAR(200)  
      -- �߰�����
     DECLARE @SourceTableSeq INT,
             @SourceNo       NVARCHAR(30),
             @SourceRefNo    NVARCHAR(30),
             @TableName      NVARCHAR(100),
             @TableSeq       INT,
             @SQL            NVARCHAR(MAX)
   
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
   
     -- Temp�� INSERT      
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
             @SourceTableSeq   = ISNULL(SourceTableSeq, 0),  -- �߰�
             @SourceNo         = ISNULL(SourceNo, ''),       -- �߰�
             @SourceRefNo      = ISNULL(SourceRefNo, '')     -- �߰�  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (BizUnit INT, DVReqDateFr NCHAR(8), DVReqDateTo NCHAR(8), UMOutKind INT,       DVReqNo NVARCHAR(20),   
           DeptSeq INT, EmpSeq         INT,   CustSeq        INT,   CustNo NVARCHAR(20), SMConfirm INT,   
           ItemSeq INT, ItemNo  NVARCHAR(30), SMProgressType INT,   DVDateFrom NCHAR(8), DVDateTo NCHAR(8),
           SMExpKind INT, IsReturn  NCHAR(1),
           SourceTableSeq      INT,            -- �߰�
           SourceNo            NVARCHAR(30),   -- �߰�
           SourceRefNo         NVARCHAR(30))   -- �߰�)     
   
     IF @DVReqDateTo = ''  
         SELECT @DVReqDateTo = '99991231'  
      IF @DVDateTo = ''  
         SELECT @DVDateTo = '99991231'  
   
 /***********************************************************************************************************************************************/  
 ---------------------- ������ ���� ����  
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
   
 ---------------------- ������ ���� ����    
      CREATE TABLE #Tmp_DVReqItemProg(IDX_NO INT IDENTITY, DVReqSeq INT, DVReqSerl INT, CompleteCHECK INT, SMProgressType INT NULL, 
                                     IsStop NCHAR(1) NULL, DVDate NCHAR(8), OrderSeq INT, OrderSerl INT, IsSpec NCHAR(1))  
      -- ��õ���̺�
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))        
      -- ��õ ������ ���̺�
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,        
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))    
      -- ������ �׸�  
     CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(200), SpecValue NVARCHAR(200))  
  
      --/**************************************************************************
     -- ����Data                                                                
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
 ---------- ������ ���� ���� �κ�    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- ������ ���� ���� �κ�          
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)  
        AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)  
        AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)  
        AND (@ItemSeq = 0 OR B.ItemSeq = @ItemSeq)  
        AND (@ItemNo = '' OR E.ItemNo LIKE @ItemNo + '%') 
        AND C.Serl = 1001 AND C.ValueText = '1'  
        AND ((@IsReturn = '1' AND ISNULL(D.ValueText,'') = '1') 
             OR (@IsReturn <> '1' AND ISNULL(D.ValueText,'') <> '1'))
  
   --/**************************************************************************
     -- ����Data                                                                
     --**************************************************************************/  
     EXEC _SCOMProgStatus @CompanySeq, '_TSLDVReqItem', 1036001, '#Tmp_DVReqItemProg', 'DVReqSeq', 'DVReqSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'DVReqSeq', 'DVReqSerl', '', '_TSLDVReq', @pgmSeq
   
     UPDATE #Tmp_DVReqItemProg   
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --�����ߴ�  
                                          WHEN B.MinorSeq = 1037009 THEN 1037009 -- �Ϸ�  
                                          WHEN A.IsStop = '1' THEN 1037005 -- �ߴ�  
                                          ELSE B.MinorSeq END)   
   
       FROM #Tmp_DVReqItemProg AS A   
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                         AND A.CompleteCHECK = B.Minorvalue  
     --/**************************************************************************
     -- ������Data                                                                
     --**************************************************************************/ 
     INSERT #TMP_SOURCETABLE
     SELECT '_TSLOrderItem'
      -- ����Dataã��(��õ)
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
     -- ��õ���� ��ȸ 
     -------------------------------------------   
     CREATE TABLE #TempResult
     (
         InOutSeq  INT,  -- ���೻�ι�ȣ
         InOutSerl  INT,  -- �������
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
               FROM _TCOMProgTable WITH(NOLOCK)--���������̺�    
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
  
         -- ����
         INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(����), 2(������)    
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
     -- ������ȸ                                                                
     --**************************************************************************/  
     SELECT CASE A.IsStop WHEN '1' THEN '1' ELSE I.IsStop END AS IsStop,              --�ߴ�  
            (SELECT BizUnitName  FROM _TDABizUnit WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)      AS BizUnitName,         --����ι�  
            A.DVReqNo            AS DVReqNo,             --�����Ƿڹ�ȣ  
            A.DVReqSeq           AS DVReqSeq,            --�����Ƿڳ��ι�ȣ  
            I.DVReqSerl          AS DVReqSerl,           --�����Ƿڼ���  
            A.DVReqDate          AS DVReqDate,           --�����Ƿ�����  
            (SELECT MinorName    FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND A.SMExpKind = MinorSeq)    AS SMExpKindName,       --���ⱸ��  
            (SELECT MinorName    FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND A.UMOutKind = MinorSeq)    AS UMOutKindName,       --�����  
            A.SMConsignKind      AS SMConsignKind,       --��Ź�����ڵ�
            (SELECT MinorName    FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND A.SMConsignKind = MinorSeq)         AS SMConsignKindName,   --��Ź����
            (SELECT DeptName     FROM _TDADept   WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)       AS DeptName,            --�μ�  
            (SELECT EmpName      FROM _TDAEmp    WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EmpSeq)         AS EmpName,             --�����  
            F.CustName           AS CustName,            --�ŷ�ó  
            F.CustNo             AS CustNo,              --�ŷ�ó��ȣ  
            A.CustSeq            AS CustSeq,             --�ŷ�ó�ڵ�  
            J.ItemName           AS ItemName,            --ǰ��  
            J.ItemEngName        AS ItemEngName,
            J.ItemNo             AS ItemNo,              --ǰ��  
            J.Spec               AS Spec,                --�԰�  
            (SELECT UnitName     FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND I.UnitSeq = UnitSeq)       AS UnitName,            --�ǸŴ���  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.Qty * -1 ELSE I.Qty END AS Qty,                 --����  
            (SELECT UnitName     FROM _TDAUnit    WHERE CompanySeq = @CompanySeq AND I.STDUnitSeq = UnitSeq)           AS STDUnitName,         --���ش���  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.STDQty * -1 ELSE I.STDQty END  AS STDQty,              --���ش�������  
            I.ItemPrice          AS ItemPrice,           --ǰ��ܰ�  
            I.CustPrice          AS CustPrice,           --ȸ��ܰ�  
  --           CASE WHEN ISNULL(I.Qty,0) = 0 THEN 0 ELSE (CASE WHEN I.IsInclusedVAT = '1' THEN (ISNULL(I.CurAmt,0) + ISNULL(I.CurVat,0)) / ISNULL(I.Qty,0)  
 --                                                                                       ELSE ISNULL(I.CurAmt,0) / ISNULL(I.Qty,0) END) END AS Price,  
             -- �ܰ����� :: �̼���
            CASE WHEN I.Price IS NOT NULL
                 THEN I.Price
                 ELSE (CASE WHEN ISNULL(I.Qty,0) = 0 THEN 0 ELSE (CASE WHEN I.IsInclusedVAT = '1' THEN (ISNULL(I.CurAmt,0) + ISNULL(I.CurVat,0)) / ISNULL(I.Qty,0)  
                                                                                        ELSE ISNULL(I.CurAmt,0) / ISNULL(I.Qty,0) END) END) END AS Price,     --�ǸŴܰ�
  
            I.IsInclusedVAT      AS IsInclusedVAT,       --�ΰ�������  
            I.VATRate            AS VATRate,             --�ΰ�����  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.CurVAT * -1 ELSE I.CurVAT END AS CurVAT,              --�ΰ����ݾ�  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.CurAmt * -1 ELSE I.CurAmt END AS CurAmt,              --�Ǹűݾ�  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.DomVAT * -1 ELSE I.DomVAT END AS DomVAT,              --��ȭ�ΰ����ݾ�  
            CASE WHEN ISNULL(@IsReturn,'') = '1' THEN I.DomAmt * -1 ELSE I.DomAmt END AS DomAmt,              --��ȭ�Ǹűݾ�             
            X.DVDate             AS DVDateD,             --��������
            I.DVTime             AS DVTime,              --����ú�  
            (SELECT WHName       FROM _TDAWH WHERE CompanySeq = @CompanySeq AND I.WHSeq = WHSeq)       AS WHName,              --â��  
            (SELECT DVPlaceName  FROM _TSLDeliveryCust WHERE CompanySeq = @CompanySeq AND I.DVPlaceSeq = DVPlaceSeq)       AS DVPlaceName,         --��ǰó  
            I.Remark             AS RemarkD,             --���  
            N.MinorName        AS SMProgressTypeName,   --�������  
            ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMExpKind),'') AS SMExpKindName, 
            X.IsSpec         AS IsSpec,       -- ������
            S.SpecName       AS SpecName,     -- �������׸�
            S.SpecValue      AS SpecValue,     --�������׸�
            ISNULL(ZZ.SourceNo,'') AS SourceNo, -- �߰�
            ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo, -- �߰�
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN '���˻�'  
                 WHEN ISNULL(Q.SourceTypeName, '' ) = '' THEN '�̰˻�'
                 ELSE Q.SourceTypeName END AS SMQCTypeName,
            --ISNULL(K.PassedQty, 0)      AS PassedQty,     --�հݼ���
            --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN B.Qty ELSE ISNULL(K.PassedQty, 0) END AS DVQty,
            --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN ISNULL(B.STDQty, 0)  ELSE ISNULL(K.QCStdUnitQty, 0) END  AS QCStdUnitQty,
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN '' ELSE Q.TestEndDate END AS QCDate,
            CASE WHEN ISNULL(I.IsQAItem,'') <> '1' THEN 6035001
                 WHEN ISNULL(Q.SMTestResult,0) = 0 THEN 6035002
                 ELSE Q.SMTestResult     END AS SMQCType,
            ISNULL(CASE ISNULL(T.CustItemName, '')  
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(T.CustItemNo, '')   
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(T.CustItemSpec, '')   
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND I.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                   ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- �ŷ�óǰ��԰�
            I.UMReturnKind, -- ��ǰ����  
            A.UMDVConditionSeq   AS UMDVConditionSeq,
            A.IsStockSales   AS IsStockSales,
            ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMDVConditionSeq),'') AS UMDVConditionName,
            ISNULL( ( SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8025 AND MinorSeq = I.UMEtcOutKind ), '' ) AS UMEtcOutKindName, -- ��Ÿ�����, 2011.11.04 by ��ö��  
            A.ExRate            AS ExRate,            --�ΰ����� 
            A.CurrSeq,
            C.CurrName  -- ��ȭ
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
             LEFT OUTER JOIN #TempResult AS ZZ WITH(NOLOCK) ON I.CompanySeq  = @CompanySeq  -- �߰�
                                                           AND I.DVReqSeq  = ZZ.InOutSeq  -- �߰�
                                                           AND I.DVReqSerl = ZZ.InOutSerl -- �߰�
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