
IF OBJECT_ID('amoerp_SSLInvoiceItemInfoQuery') IS NOT NULL 
    DROP PROC amoerp_SSLInvoiceItemInfoQuery 
GO

-- v2013.11.25 

-- �ŷ�����ǰ����Ȳ_amoerp by����õ
  /*********************************************************************************************************************  
     ȭ��� : �ŷ�����ǰ����Ȳ  
     SP Name: temp_SSLInvoiceItemInfoQuery  
     �ۼ��� : 2008.08.07 : CREATEd by ������      
     ������ : �ӵ������� ���� ��ȸ Join ���̺� ���� (�޿½�) 2010.04.21 by ������
              ��Ÿ������÷��߰�   2010.06.14 by ������
              û��ó �߰�            2010.06.17 by �ֹμ�
              LotNo �߰�             2010.11.08 by õ���
              �ۼ� + ���� check ��ȸ���� �߰� kskwon �Ǳ⼮
              ���� ��ȸ���� DECIMAL �Ҽ��� �ڸ� �� ��ȯ ����(��ȯ �����÷�)�� ���� CONVERT ���� 2013.01.09 by �ڼ�ȣ
     2013.05.02 ��³� - ������¿� �̿Ϸ��߰�
 ********************************************************************************************************************/  
 CREATE PROC amoerp_SSLInvoiceItemInfoQuery    
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
             @InvoiceDateFr NCHAR(8),   
             @InvoiceDateTo NCHAR(8),   
             @UMOutKind      INT,   
             @InvoiceNo  NVARCHAR(20),  
             @DeptSeq        INT,   
             @EmpSeq         INT,   
             @CustSeq        INT,  
             @CustNo         NVARCHAR(20), 
    @BillCustSeq    INT,           -- 20100617 �ֹμ� û��ó �߰�  
             @ItemSeq        INT,   
             @ItemNo         NVARCHAR(30),  
             @IsInvConfirm   NCHAR(1),
             @PJTName        NVARCHAR(100),  
             @PJTNo          NVARCHAR(100),  
             @WBSName        NVARCHAR(100),   
             @SMProgressType INT,
    @SMExpKind  INT,
    @WHSeq          INT,
    @DVPlaceSeq     INT,           -- 20110221 ������ �ŷ�ó �߰�
             -- �������
             @Seq            INT, 
             @OrderSeq       INT, 
             @OrderSerl      INT, 
             @SubSeq         INT, 
             @SpecName       NVARCHAR(200),   
             @SpecValue      NVARCHAR(200),
             @AssetSeq       INT, 
             @LotNo          NVARCHAR(30),
             @SMProgress     NCHAR(1)                -- ���� + �ۼ�(2012.05.23 kskwon �߰�)
             
     -- �߰�����
     DECLARE @SourceTableSeq INT,
             @SourceNo       NVARCHAR(30),
             @SourceRefNo    NVARCHAR(30),
             @TableName      NVARCHAR(100),
             @TableSeq       INT,
             @SQL            NVARCHAR(MAX),
             @IsDelvCfm      NCHAR(1),
              @DomLen         INT,
             @DomPriceLen    INT,
             @CurLen         INT,
             @CurPriceLen    INT,
             @QtyLen         INT,
             @UMEtcOutKind   INT -- 20130111 �ڼ�ȣ �߰�
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
   
     -- Temp�� INSERT      
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
    @BillCustSeq      = ISNULL(BillCustSeq, 0),        -- 20100617 �ֹμ� �߰� -- 20130109 �ڼ�ȣ ����[ ISNULL(BillCustSeq, '') -> ISNULL(BillCustSeq, 0) ]
             @PJTName        = ISNULL(PJTName, ''),  
             @PJTNo          = ISNULL(PJTNo, ''),  
    @WBSName        = ISNULL(WBSName, ''),   
             @SMProgressType   = ISNULL(SMProgressType, 0),
             @SourceTableSeq   = ISNULL(SourceTableSeq, 0),  -- �߰�
             @SourceNo         = ISNULL(SourceNo, ''),       -- �߰�
             @SourceRefNo      = ISNULL(SourceRefNo, ''),     -- �߰�
    @SMExpKind  = ISNULL(SMExpKind,0),
             @IsDelvCfm      = ISNULL(IsDelvCfm,''),
             @WHSeq          = ISNULL(WHSeq,0),
             @DVPlaceSeq     = ISNULL(DVPlaceSeq, 0),             --20110221 ������ �߰�
             @AssetSeq       = ISNULL(AssetSeq, 0),
             @LotNo          = ISNULL( LotNo, '' ),
             @SMProgress     = ISNULL(SMProgress, '0'),
             @UMEtcOutKind   = ISNULL(UMEtcOutKind, 0) -- 20130111 �ڼ�ȣ �߰�
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
     WITH (BizUnit INT, InvoiceDateFr NCHAR(8), InvoiceDateTo NCHAR(8), UMOutKind INT,            InvoiceNo NVARCHAR(20),   
           DeptSeq INT, EmpSeq        INT,      CustSeq       INT,      CustNo NVARCHAR(20),      BillCustSeq  INT,
           ItemSeq INT, ItemNo  NVARCHAR(30),   PJTName       NVARCHAR(100), PJTNo NVARCHAR(100), WBSName NVARCHAR(100),  
           SMProgressType INT,
           SourceTableSeq      INT,            -- �߰�
           SourceNo            NVARCHAR(30),   -- �߰�
           SourceRefNo         NVARCHAR(30),   -- �߰�
     SMExpKind  INT,
           IsDelvCfm     NCHAR(1),
           WHSeq         INT,
           DVPlaceSeq    INT,
           AssetSeq      INT,
           LotNo         NVARCHAR(30),
           SMProgress    NVARCHAR(1),
           UMEtcOutKind  INT) -- 20130111 �ڼ�ȣ �߰�
   
     IF @InvoiceDateTo = ''  
         SELECT @InvoiceDateTo = '99991231' 
      -- ȯ�漳�� �Ҽ��� ��������
     EXEC dbo._SCOMEnv @CompanySeq,15, @UserSeq,@@PROCID,@DomLen OUTPUT   -- ��ȭ �Ҽ��� �ڸ���
     EXEC dbo._SCOMEnv @CompanySeq,9, @UserSeq,@@PROCID,@DomPriceLen OUTPUT   -- ��ȭ �ܰ��Ҽ��� �ڸ���
      EXEC dbo._SCOMEnv @CompanySeq,14, @UserSeq,@@PROCID,@CurLen OUTPUT   -- ��ȭ �Ҽ��� �ڸ���
     EXEC dbo._SCOMEnv @CompanySeq,10, @UserSeq,@@PROCID,@CurPriceLen OUTPUT   -- ��ȭ �ܰ��Ҽ��� �ڸ���
      EXEC dbo._SCOMEnv @CompanySeq,8, @UserSeq,@@PROCID,@QtyLen OUTPUT   -- ���� �Ҽ��� �ڸ���  
 /***********************************************************************************************************************************************/  
 ---------------------- ������ ���� ����  
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
   
 ---------------------- ������ ���� ���� 
    
     -- �ŷ������������ Table  
     CREATE TABLE #Tmp_InvoiceProg(IDX_NO INT IDENTITY, InvoiceSeq INT, InvoiceSerl INT, CompleteCHECK INT, SMProgressType INT, 
                                   SalesSeq INT,        OrderSeq   INT,   OrderSerl INT, IsSpec NCHAR(1), Qty DECIMAL(19,5))  
      -- ���� 
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
      -- ��õ �� ���� ���������̺�
      CREATE TABLE #TempResult
     (
         InOutSeq  INT,  -- ���೻�ι�ȣ
         InOutSerl  INT,  -- �������
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
      -- ������ �׸�  
     CREATE TABLE #TempSOSpec(Seq INT IDENTITY, OrderSeq INT, OrderSerl INT,  SpecName  NVARCHAR(100), SpecValue NVARCHAR(100))  
      --/***********************************
     -- ���� ������ ��ȸ                 
     --***********************************/
     INSERT INTO #Tmp_InvoiceProg(InvoiceSeq, InvoiceSerl, CompleteCHECK, Qty)  
     SELECT A.InvoiceSeq, D.InvoiceSerl, -1, D.Qty  
       FROM _TSLInvoice              AS A WITH(NOLOCK)
       JOIN amoerp_TSLInvoiceItemMerge          AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.InvoiceSeq = D.InvoiceSeq )  
       JOIN _TDASMinorValue          AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.SMExpKind = B.MinorSeq AND B.Serl = 1001 AND B.ValueText = '1' ) 
       LEFT OUTER JOIN _TDACust      AS C WITh(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq ) 
       LEFT OUTER JOIN _TDAItem      AS J WITH(NOLOCK) ON ( D.CompanySeq = J.CompanySeq AND D.ItemSeq = J.ItemSeq )
       LEFT OUTER JOIN _TDAItemAsset AS E WITH(NOLOCK) ON ( J.CompanySeq = E.CompanySeq AND J.AssetSeq = E.AssetSeq )                                              
      WHERE A.CompanySeq = @CompanySeq      
        AND (@BizUnit = 0 OR A.BizUnit = @BizUnit)    
        AND (A.InvoiceDate BETWEEN @InvoiceDateFr AND @InvoiceDateTo)    
        AND (@InvoiceNo = '' OR A.InvoiceNo LIKE @InvoiceNo + '%')    
        AND (@UMOutKind = 0 OR A.UMOutKind = @UMOutKind)    
 ---------- ������ ���� ���� �κ�    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- ������ ���� ���� �κ�     
        AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)    
        AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
        AND (@CustNo = '' OR C.CustNo LIKE @CustNo + '%')  
 --    AND (@BillCustSeq = 0 OR A.CustSeq = @BillCustSeq)  --20100616 �ֹμ��߰�
        AND (@ItemSeq = 0 OR D.ItemSeq = @ItemSeq)  
        AND (@ItemNo = '' OR J.ItemNo LIKE @ItemNo + '%')  
     AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)
     AND (@WHSeq = 0 OR D.WHSeq = @WHSeq) 
        AND (@DVPlaceSeq = 0 OR A.DVPlaceSeq = @DVPlaceSeq)
        AND (@AssetSeq = 0 OR E.AssetSeq = @AssetSeq) 
        AND ( @LotNo = '' OR D.LotNo LIKE @LotNo + '%' ) 
        
     --/***********************************
     -- ���������ȸ                     
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
     -- ���೻�� ������ ��ȸ
     --***********************************/   
     INSERT #TMP_PROGRESSTABLE      
     SELECT 1,'_TSLSalesItem'      
      exec _SCOMProgressTracking @CompanySeq, '_TSLInvoiceItem', '#Tmp_InvoiceProg', 'InvoiceSeq', 'InvoiceSerl', ''
      --/**************************************************************************
     -- ������Data                                                                
     --**************************************************************************/ 
     INSERT #TMP_SOURCETABLE
     SELECT '_TSLOrderItem'
      -- ����Dataã��(��õ)
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
  
     -- ������ ��ȸ�� ���� ���ʵ�����
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
     -- ��õ���� ��ȸ                                                            
     ----------------------------------------------------------------------------   
     IF ISNULL(@SourceTableSeq, 0) <> 0
     BEGIN
     
         DELETE #TMP_SOURCETABLE 
         DELETE #TCOMSourceTracking    
             
         IF ISNULL(@TableName, '') <> ''
         BEGIN
             SELECT @TableSeq = ProgTableSeq    
               FROM _TCOMProgTable WITH(NOLOCK)--���������̺�    
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
          -- ����
         INSERT INTO #TMP_SOURCEITEM(SourceSeq, SourceSerl, SourceSubSerl) -- IsNext=1(����), 2(������)    
         SELECT  A.InvoiceSeq, A.InvoiceSerl, 0    
           FROM #Tmp_InvoiceProg     AS A WITH(NOLOCK)         
  
         EXEC _SCOMSourceTracking @CompanySeq, @TableName, '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''      
  -- ��������
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
 -- ��������
          EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT', @CompanySeq
          SELECT @SQL = ''
      END
      -- ���� ���� ������ ��ȸ�� �ӵ��� �ٿ��� �ε��� �߰� (2010.07.01 �޿½����� Ʃ���۾�)
     CREATE INDEX IX_#TCOMProgressTracking ON #TCOMProgressTracking (IDX_NO) 
     CREATE INDEX IX_#Tmp_InvoiceProg ON #Tmp_InvoiceProg (InvoiceSeq, InvoiceSerl) 
     /*********************************** 
     -- ���� ������ ��ȸ
     ***********************************/  
     SELECT (SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)   AS BizUnitName,     --����ι�  
            A.InvoiceSeq     AS InvoiceSeq,      --�ŷ����������ڵ�  
            A.InvoiceDate    AS InvoiceDate,     --�ŷ�������  
            B.InvoiceSerl    AS InvoiceSerl,     --�ŷ���������  
            A.InvoiceNo      AS InvoiceNo,       --�ŷ�������ȣ  
            A.SMExpKind      AS SMExpKind,       --���ⱸ���ڵ�  
            (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.SMExpKind = MinorSeq)      AS SMExpKindName,   --���ⱸ��  
            H.MinorName      AS UMOutKindName,   --�����  
            A.UMOutKind      AS UMOutKind,       --������ڵ�  
            I.ValueText      AS IsSales,         --���⵿�ù߻�  
            (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)      AS DeptName,        --�μ�  
            (SELECT EmpName FROM _TDAEmp WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EmpSeq)        AS EmpName,         --�����  
            F.CustName       AS CustName,        --�ŷ�ó  
            F.CustNo         AS CustNo,          --�ŷ�ó��ȣ  
            A.CustSeq        AS CustSeq,         --�ŷ�ó�ڵ�
            (SELECT DVPlaceName  FROM _TSLDeliveryCust WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DVPlaceSeq = DVPlaceSeq)       AS DVPlaceName,    --��ǰ�ŷ�ó  
            A.IsStockSales   AS IsStockSales,    --�Ǹ��ĺ���
            J.ItemName       AS ItemName,        --ǰ��  
            J.ItemNo         AS ItemNo,          --ǰ��  
            J.Spec           AS Spec,            --�԰�  
            (SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.UnitSeq = UnitSeq)       AS UnitName,        --�ǸŴ���  
            B.ItemPrice      AS ItemPrice,       --ǰ��ܰ�  
            B.CustPrice      AS CustPrice,       --ȸ��ܰ�  
            B.Qty            AS Qty,             --����  
            B.IsInclusedVAT  AS IsInclusedVAT,   --�ΰ�������  
            B.VATRate        AS VATRate,         --�ΰ�����
         A.CurrSeq  AS CurrSeq,   --��ȭ�ڵ�
         (SELECT CurrName FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName,  --��ȭ   
         CONVERT(DECIMAL(19, 5), A.ExRate)         AS ExRate,          -- ȯ��
            CONVERT(DECIMAL(19, 5), 
            CASE WHEN B.Price IS NOT NULL
                 THEN B.Price
                 ELSE (ROUND(CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE (CASE WHEN B.IsInclusedVAT = '1' THEN ((ISNULL(B.CurAmt,0) + ISNULL(B.CurVat,0)) / ISNULL(B.Qty,0))           
                                                            ELSE (ISNULL(B.CurAmt,0) / ISNULL(B.Qty,0)) END) END, @CurPriceLen)) END) AS Price,   --�ǸŴܰ�  
            ROUND(B.CurAmt,@CurLen)         AS CurAmt,          --�Ǹűݾ�  
            ROUND(B.CurVAT,@CurLen)         AS CurVAT,          --�ΰ�����  
            CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen)) AS TotCurAmt, -- �Ǹűݾ��Ѿ�
            ROUND(ISNULL(B.DomAmt, 0), @DomLen)         AS DomAmt,          --��ȭ�Ǹűݾ�  
            ROUND(ISNULL(B.DomVAT, 0), @DomLen)         AS DomVAT,          --��ȭ�ΰ�����  
            CONVERT(DECIMAL(19, 5), ROUND(ISNULL(B.DomAmt, 0), @DomLen) + ROUND(ISNULL(B.DomVAT, 0), @DomLen)) AS TotDomAmt, -- ��ȭ�Ǹűݾ��Ѿ�
            ISNULL((SELECT UnitName  FROM _TDAUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.STDUnitSeq = UnitSeq), '')        AS STDUnitName,     --���ش���  
            B.STDQty         AS STDQty,          --���ش�������  
            (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND B.WHSeq = WHSeq)        AS WHName,          --â��
            A.Remark         AS RemarkM,          --�����ͺ��  
            B.Remark         AS RemarkI,          --���  
       (SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND Z.SMProgressType = MinorSeq)   AS SMProgressTypeName, --�������  
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
            ISNULL(ZZ.SourceNo,'')     AS SourceNo,      -- �߰�
            ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo,   -- �߰�
            OutK.ValueText             AS IsReturn,      -- ��ǰ
            Z.IsSpec                   AS IsSpec,        -- ������
            S.SpecName                 AS SpecName,      -- �������׸�
            S.SpecValue                AS SpecValue,     --�������׸�           
      CONVERT(DECIMAL(19, 5), ISNULL(U.SalesQty,0))    AS SalesQty,  --�����������
      CONVERT(DECIMAL(19, 5), ISNULL(U.SalesAmt+U.SalesVAT, 0)) AS SalesPrice, --����ݾ�
            CONVERT(DECIMAL(19, 5), ROUND(B.CurAmt,@CurLen) + ROUND(B.CurVAT,@CurLen) - ROUND(ISNULL(U.SalesAmt,0),@CurLen) - ROUND(ISNULL(U.SalesVAT,0),@CurLen)) AS NonSalesAmt,
            ISNULL(CASE ISNULL(T.CustItemName, '')  
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(T.CustItemNo, '')   
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                           ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- �ŷ�óǰ��  
            ISNULL(CASE ISNULL(T.CustItemSpec, '')   
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WITH(NOLOCK) WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND B.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                   ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- �ŷ�óǰ��԰�  
             B.UMEtcOutKind          AS UMEtcOutKind, -- ��Ÿ������ڵ�
             ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = B.UMEtcOutKind), '') AS UMEtcOutKindName, -- ��Ÿ����� 
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
             ISNULL(B.Dummy10, '') AS Dummy10
             -- 20130107 �ڼ�ȣ �߰� (Dummy1 ~ 10)
       FROM #Tmp_InvoiceProg AS Z    
             JOIN _TSLInvoice AS A WITH(NOLOCK) ON Z.InvoiceSeq = A.InvoiceSeq  
             JOIN amoerp_TSLInvoiceItemMerge      AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
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
                               WHERE A.Qty * B.Qty >= 0  -- ��ǰ�Ǳ��� ���ԵǾ� �����߰�
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
             LEFT OUTER JOIN #TempResult AS ZZ ON B.CompanySeq  = @CompanySeq  -- �߰�
                                                           AND B.InvoiceSeq  = ZZ.InOutSeq  -- �߰�
                                                           AND B.InvoiceSerl = ZZ.InOutSerl -- �߰�
             LEFT OUTER JOIN #TempSOSpec AS S ON Z.OrderSeq  = S.OrderSeq
                                                          AND Z.OrderSerl = S.OrderSerl
             LEFT OUTER JOIN _TSLCustItem  AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq  
                                                            AND T.ItemSeq    = B.ItemSeq  
                                                            AND T.CustSeq    = A.CustSeq  
                                                            AND T.UnitSeq = B.UnitSeq 
             LEFT OUTER JOIN _TDAItemAsset AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                            AND C.AssetSeq = J.AssetSeq                                               
      WHERE A.CompanySeq = @CompanySeq    
        AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%')  
        AND (@PJTNo   = '' OR P.PJTNo   LIKE @PJTNo   + '%')  
        AND (@WBSName = '' OR W.WBSName LIKE @WBSName + '%')  
        AND ((@SMProgress = '0' AND (@SMProgressType = 0 OR (Z.SMProgressType = @SMProgressType) OR ( @SMProgressType = 8098001 AND Z.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )) OR (@SMProgress = '1' AND Z.SMProgressType IN (1037002, 1037003,1037001, 1037006)))
        AND (@SourceNo = '' OR ISNULL(ZZ.SourceNo,'') LIKE @SourceNo + '%')
        AND (@SourceRefNo = '' OR ZZ.SourceRefNo LIKE @SourceRefNo + '%')
        AND (@SMExpKind = 0 OR A.SMExpKind = @SMExpKind)
        AND (@IsDelvCfm = '0' OR (@IsDelvCfm = '1' AND A.IsDelvCfm = '0' OR A.IsDelvCfm = ''))
        AND (@BillCustSeq = 0 OR (ISNULL(O.UpperCustSeq,0) = 0 AND A.CustSeq = @BillCustSeq) OR (O.UpperCustSeq = @BillCustSeq))
        AND (@UMEtcOutKind = 0 OR B.UMEtcOutKind = @UMEtcOutKind) -- 20130111 �ڼ�ȣ �߰�
      ORDER BY A.InvoiceDate, A.InvoiceNo, B.InvoiceSerl     
   RETURN