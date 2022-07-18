IF OBJECT_ID('hye_SSLOrderItemInfoQuery') IS NOT NULL 
    DROP PROC hye_SSLOrderItemInfoQuery
GO 

-- v2016.08.05 

-- 주문품목조회_hye-조회 by이재천
/*********************************************************************************************************************  

    Ver.20140630

    화면명 : 수주품목현황  
    SP Name: _SSLOrderItemInfoQuery  
    작성일 : 2008.07.28 : CREATEd by 정혜영      
    수정일 : 판매후보관컬럼추가 및 최종 조회튜닝 - 2010.07.02 정혜영
             수주품목현황(제약)에서 FormID별로 점프될수 있도록 추가 - 2010.09.06 허승남
             생산의뢰번호 추가 - 2011.12.19 이성덕
             납품시분 추가 - 2012.02.15 이성덕
             할인율 수정 - ItemPrice를 CustPrice로 수정 - 2012.09.27 이성덕
	         2013.04.26  UPDATE BY 허승남 :: 진행상태에 미완료 추가    
********************************************************************************************************************/  
CREATE PROCEDURE hye_SSLOrderItemInfoQuery    
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
            @OrderDateFr    NCHAR(8),   
            @OrderDateTo    NCHAR(8),   
            @DVDateFr       NCHAR(8),   
            @DVDateTo       NCHAR(8),   
            @UMOrderKind    INT,   
            @SMExpKind      INT,   
            @OrderNo        NVARCHAR(100),  
            @DeptSeq        INT,   
            @EmpSeq         INT,   
            @CustSeq        INT,  
            @PoNo           NVARCHAR(100),   
            @ItemSeq        INT,   
            @ItemNo         NVARCHAR(100),   
            @ModelName      NVARCHAR(100),  
            @WHSeq          INT,  
            @SMConfirm      INT,   
            @SMProgressType   INT,
            @Seq            INT,
            @OrderSeq       INT,
            @OrderSerl      INT,
            @SubSeq         INT, 
            @SpecName       NVARCHAR(200), 
            @SpecValue      NVARCHAR(200),
            @SMProgress     NCHAR(1),
            @SMProgressType2 INT,
            @PJTName		NVARCHAR(200),
            @PJTNo			NVARCHAR(200),
            @AssetSeq       INT,
            @Spec           NVARCHAR(200),
            @UMChannel      INT, --20150129 이준식 추가
            @UMSalesKind    INT, 
            @ShipBizUnit    INT, 
            @UMWorkCenter   INT, 
            @ServiceCustSeq INT, 
            @UMDVConditionSeq   INT 

  
    -- 추가변수
    DECLARE @SourceTableSeq INT,
            @SourceNo       NVARCHAR(30),
            @SourceRefNo    NVARCHAR(30),
            @TableName      NVARCHAR(100),
            @TableSeq       INT,
            @SQL            NVARCHAR(MAX),
            @UMEtcOutKind   INT -- 20130111 박성호 추가


    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
  
    -- Temp에 INSERT      
    --    INSERT INTO #TXBProcessActRevQry(ProcessCd,ProcessRev,ActivitySeq,ActivityRev)      
    SELECT  @BizUnit            = ISNULL(BizUnit, 0),   
            @OrderDateFr        = ISNULL(OrderDateFr, ''),   
            @OrderDateTo        = ISNULL(OrderDateTo, ''),   
            @DVDateFr           = ISNULL(DVDateFr, ''),   
            @DVDateTo           = ISNULL(DVDateTo, ''),   
            @UMOrderKind        = ISNULL(UMOrderKind, 0),   
            @SMExpKind          = ISNULL(SMExpKind, 0),   
            @OrderNo            = LTRIM(RTRIM(ISNULL(OrderNo, ''))),  
            @DeptSeq            = ISNULL(DeptSeq, 0),   
            @EmpSeq             = ISNULL(EmpSeq, 0),   
            @CustSeq            = ISNULL(CustSeq, 0),  
            @ItemSeq            = ISNULL(ItemSeq, 0),  
            @ItemNo             = LTRIM(RTRIM(ISNULL(ItemNo, ''))),   
            @PoNo               = LTRIM(RTRIM(ISNULL(PONo, ''))),   
            @ModelName          = LTRIM(RTRIM(ISNULL(ModelName, ''))),  
            @WHSeq              = ISNULL(WHSeq , 0),  
            @SMConfirm          = ISNULL(SMConfirm, 0),   
            @SMProgressType     = ISNULL(SMProgressType, 0),
            @SourceTableSeq     = ISNULL(SourceTableSeq, 0),  -- 추가
          @SourceNo           = ISNULL(SourceNo, ''),       -- 추가
            @SourceRefNo        = ISNULL(SourceRefNo, ''),    -- 추가
            @SMProgress         = ISNULL(SMProgress, 0),
            @SMProgressType2    = ISNULL(SMProgressType2, 0),
            @UMEtcOutKind       = ISNULL(UMEtcOutKind, 0), -- 20130111 박성호 추가
            @PJTName            = ISNULL(PJTName, ''),
            @PJTNo              = ISNULL(PJTNo, ''),
            @AssetSeq           = ISNULL(AssetSeq,0),
            @Spec               = ISNULL(Spec, ''),
            @UMChannel          = ISNULL(UMChannel       ,0), 
            @UMSalesKind        = ISNULL(UMSalesKind     ,0), 
            @ShipBizUnit        = ISNULL(ShipBizUnit     ,0), 
            @UMWorkCenter       = ISNULL(UMWorkCenter    ,0), 
            @ServiceCustSeq     = ISNULL(ServiceCustSeq  ,0), 
            @UMDVConditionSeq   = ISNULL(UMDVConditionSeq,0) 
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
    WITH (BizUnit INT, OrderDateFr NCHAR(8), OrderDateTo NCHAR(8), UMOrderKind INT,     OrderNo NVARCHAR(100),   
          DeptSeq INT, DVDateFr    NCHAR(8), DVDateTo    NCHAR(8), EmpSeq      INT,     CustSeq INT,     
          ItemSeq INT, ItemNo  NVARCHAR(100), WHSeq       INT,      PONo NVARCHAR(100),   SMConfirm INT,   
          ModelName NVARCHAR(100), SMProgressType INT,    SMExpKind INT,
          SourceTableSeq    INT,            -- 추가
          SourceNo          NVARCHAR(30),   -- 추가
          SourceRefNo       NVARCHAR(30),   -- 추가
          SMProgress        NCHAR(1),
          SMProgressType2   INT,
          UMEtcOutKind      INT,
          PJTName           NVARCHAR(200),
          PJTNo             NVARCHAR(200),
          AssetSeq          INT,-- 20130111 박성호 추가
          UMChannel         INT,-- 20150129 이준식 추가
          Spec              NVARCHAR(200) , 
          UMSalesKind       INT, 
          ShipBizUnit       INT, 
          UMWorkCenter      INT, 
          ServiceCustSeq    INT, 
          UMDVConditionSeq  INT 
          ) 
  
    IF @OrderDateTo = ''  
        SELECT @OrderDateTo = '99991231'  
    IF @DVDateTo = ''   
        SELECT @DVDateTo = '99991231'  
  
/***********************************************************************************************************************************************/  
    -- 수주진행 Table  
    CREATE TABLE #Tmp_OrderItemSLProg(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT, OrderSubSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1), SMConfirm INT)  
    CREATE TABLE #Tmp_OrderItemUIProg(IDX_NO INT, OrderSeq INT, OrderSerl INT, OrderSubSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1))  
    CREATE TABLE #Tmp_OrderItemPUProg(IDX_NO INT, OrderSeq INT, OrderSerl INT, OrderSubSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1))  
    

    ---------------------- 조직도 연결 여부  
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
  
    IF @OrderDateTo = '99991231'  
        SELECT  @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)  
    ELSE  
        SELECT  @OrgStdDate = @OrderDateTo  
  
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
  
    INSERT INTO #Tmp_OrderItemSLProg(OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, IsStop)  
    SELECT A.OrderSeq, B.OrderSerl, B.OrderSubSerl, -1, B.IsStop  
      FROM _TSLOrder AS A WITH(NOLOCK)   
            JOIN _TSLOrderItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                AND A.OrderSeq   = B.OrderSeq  
            LEFT OUTER JOIN _TDASMinorValue AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                             AND A.SMExpKind = C.MinorSeq
            LEFT OUTER JOIN _TDACustClass   AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                             AND A.CustSeq = D.CustSeq
                                                             AND D.UMajorCustClass = 8004 --20150129 이준식 수정                         
     WHERE A.CompanySeq = @CompanySeq    
       AND (@BizUnit = 0  OR A.BizUnit = @BizUnit)  
       AND (A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo)  
       AND (@DVDateFr = '' OR (B.DVDate >= @DVDateFr) OR (B.DVDate = '' AND A.DVDate >= @DVDateFr))
       AND (@DVDateTo = '' OR (B.DVDate <= @DVDateTo) OR (B.DVDate = '' AND A.DVDate <= @DVDateTo))     
       AND (@UMOrderKind = 0 OR A.UMOrderKind = @UMOrderKind)  
       AND (@SMExpKind   = 0 OR A.SMExpKind   = @SMExpKind)  
---------- 조직도 연결 변경 부분    
       AND (@DeptSeq = 0   
            OR (@SMOrgSortSeq = 0 AND A.DeptSeq = @DeptSeq)        
            OR (@SMOrgSortSeq > 0 AND A.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
---------- 조직도 연결 변경 부분          
	   AND (@EmpSeq  = 0  OR A.EmpSeq  = @EmpSeq)  
       AND (@CustSeq = 0  OR A.CustSeq = @CustSeq)  
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')  
       AND (@PoNo = ''    OR A.PONo LIKE @PoNo + '%')  
       AND (@ItemSeq = 0  OR B.ItemSeq = @ItemSeq)  
       AND (@WHSeq   = 0  OR B.WHSeq   = @WHSeq)  
       AND C.Serl = 1001 AND C.ValueText = '1'
       AND (@UMChannel = 0 OR D.UMCustClass = @UMChannel)   --20150129 이준식 추가

      
    ---------------------------------------------------------------------------------------------------------
    -- 진행상태 구하기 (영업, 구매, 생산)
    ---------------------------------------------------------------------------------------------------------
    INSERT #Tmp_OrderItemUIProg(IDX_NO, OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, SMProgressType, IsStop)
    SELECT IDX_NO, OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, SMProgressType, IsStop
      FROM #Tmp_OrderItemSLProg

    INSERT #Tmp_OrderItemPUProg(IDX_NO, OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, SMProgressType, IsStop)
    SELECT IDX_NO, OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, SMProgressType, IsStop
      FROM #Tmp_OrderItemSLProg    
  
    -- 영업
    EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036001, '#Tmp_OrderItemSLProg',  
                         'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '',  
                         'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT',  
                         'OrderSeq', 'OrderSerl', '', '_TSLOrder', @PgmSeq    
        
    UPDATE #Tmp_OrderItemSLProg   
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --진행중단  
                                         WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료  
                                         WHEN A.IsStop = '1' THEN 1037005 -- 중단  
                                         ELSE B.MinorSeq END)  
      FROM #Tmp_OrderItemSLProg AS A  
            LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                        AND A.CompleteCHECK = B.Minorvalue  
    -- 구매
    EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036002, '#Tmp_OrderItemUIProg',  
                         'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '',  
                         'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT',  
                         'OrderSeq', 'OrderSerl', '', '_TSLOrder', @PgmSeq   


    UPDATE #Tmp_OrderItemUIProg   
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --진행중단  
                                         WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료  
                                         WHEN A.IsStop = '1' THEN 1037005 -- 중단  
                                         ELSE B.MinorSeq END)  
      FROM #Tmp_OrderItemUIProg AS A  
            LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                        AND A.CompleteCHECK = B.Minorvalue  

    
    -- 생산
    EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036003, '#Tmp_OrderItemPUProg',  
                         'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '',  
                         'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT',  
                         'OrderSeq', 'OrderSerl', '', '_TSLOrder', @PgmSeq   

    UPDATE #Tmp_OrderItemPUProg   
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037008 --진행중단  
                                         WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료  
                                         WHEN A.IsStop = '1' THEN 1037005 -- 중단  
                                         ELSE B.MinorSeq END)  
      FROM #Tmp_OrderItemPUProg AS A  
            LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037  
                                                        AND A.CompleteCHECK = B.Minorvalue  


    -- 생산의뢰번호
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
            STDQty      DECIMAL(19, 5),          
            Amt         DECIMAL(19, 5)   ,          
            VAT         DECIMAL(19, 5)          
    )          

    INSERT #TMP_PROGRESSTABLE          
    SELECT 1, '_TPDMPSProdReqItem'  -- 생산의뢰  
     UNION      
    SELECT 2, '_TSLInvoiceItem'   --거래명세서  --20140205 이삭 추가
    
    exec _SCOMProgressTracking @CompanySeq, '_TSLOrderItem', '#Tmp_OrderItemPUProg', 'OrderSeq', 'OrderSerl', 'OrderSubSerl'    
   
   CREATE TABLE #OrderTracking(IDX_NO INT,  InvoiceQty DECIMAL(19,5), InvoiceAmt DECIMAL(19,5)  )   
                               

--select * from #TCOMProgressTracking


    SELECT A.IDX_NO,
           MAX(A.OrderSeq) AS OrderSeq,
           MAX(A.OrderSerl) AS OrderSerl,
           MAX(A.OrderSubSerl) AS OrderSubSerl,
           MAX(C.ProdReqNo) AS ProdReqNo
      INTO #Tmp_ProdReq
      FROM #Tmp_OrderItemPUProg AS A
           JOIN #TCOMProgressTracking AS B ON B.IDX_NO = A.IDX_NO
           LEFT OUTER JOIN _TPDMPSProdReq AS C ON C.CompanySeq = @CompanySeq AND C.ProdReqSeq = B.Seq
     WHERE B.IDOrder = 1
     GROUP BY A.IDX_NO


  INSERT INTO #OrderTracking      --20140205 이삭 추가
    SELECT A.IDX_NO,      
           SUM(CASE IDOrder WHEN 2 THEN A.Qty     ELSE 0 END),      
           SUM(CASE IDOrder WHEN 2 THEN A.Amt     ELSE 0 END)     
      FROM #TCOMProgressTracking A  
     GROUP BY A.IDX_No      

    ---------------------------------------------------------------------------------------------------------
    -- 생산사양 항목
    ---------------------------------------------------------------------------------------------------------
    Create Table #TempSOSpec
    (
        Seq      INT IDENTITY,
        OrderSeq INT,
        OrderSerl INT,
        SpecName  NVARCHAR(200),
        SpecValue NVARCHAR(200)
    )

    INSERT INTO #TempSOSpec
    SELECT DISTINCT A.OrderSeq, A.OrderSerl,'',''
      FROM #Tmp_OrderItemSLProg AS A
           JOIN _TSLOrderItemspecItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND A.OrderSeq   = B.OrderSeq
                                                       AND A.OrderSerl  = B.OrderSerl

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
                SELECT @SpecName = B.SpecName, @SpecValue = (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq
                 WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq
            END
            ELSE
            BEGIN
                SELECT @SpecName = @SpecName +'/'+B.SpecName, @SpecValue = @SpecValue+'/'+ (CASE WHEN B.UMSpecKind = 84003 THEN ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SpecItemValue), '')
                                                                                            ELSE ISNULL(A.SpecItemValue, '') END)
                  FROM _TSLOrderItemspecItem AS A JOIN _TSLSpec AS B ON A.SpecSeq = B.SpecSeq AND A.CompanySeq = B.CompanySeq
                 WHERE A.CompanySeq = @CompanySeq AND OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl AND OrderSpecSerl = @SubSeq
            END

            UPDATE #TempSOSpec
               SET SpecName = @SpecName, SpecValue = @SpecValue
             WHERE OrderSeq = @OrderSeq AND OrderSerl = @OrderSerl

        END

    END
    SET ROWCOUNT 0

    -------------------------------------------      
    -- 원천진행 조회 
    -------------------------------------------   
    CREATE TABLE #TempResult
    (
        InOutSeq		INT,  -- 진행내부번호
        InOutSerl		INT,  -- 진행순번
        InOutSubSerl    INT,
        SourceRefNo     NVARCHAR(30),
        SourceNo        NVARCHAR(30)
    )

    IF ISNULL(@SourceTableSeq, 0) <> 0
    BEGIN
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
        SELECT  A.OrderSeq, A.OrderSerl, A.OrderSubSerl    
          FROM #Tmp_OrderItemSLProg     AS A WITH(NOLOCK)         


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


    CREATE INDEX IX_#TempSOSpec ON #TempSOSpec(OrderSeq,OrderSerl) 
    CREATE INDEX IX_#TempResult ON #TempResult(InOutSeq)
  
-- (협진) 작성+진행 조회조건 
IF @SMProgress = '1'  -- 작성+진행
BEGIN
    Set @SMProgressType  = 1037001
    Set @SMProgressType2 = 1037006
END


        -- 최종 조회  
    SELECT CASE A.IsStop WHEN '1' THEN '1' ELSE H.IsStop END AS IsStop,              --중단  
           (SELECT BizUnitName  FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.BizUnit = BizUnit)      AS BizUnitName,         --사업부문  
           A.OrderNo            AS OrderNo,             --수주번호  
           A.OrderRev           AS OrderRev,            --수주차수  
           A.OrderSeq           AS OrderSeq,            --수주내부번호  
           H.OrderSerl          AS OrderSerl,           --수주순번  
           H.OrderSubSerl       AS OrderSubSerl,        --수주하위순번  
           A.OrderDate          AS OrderDate,           --수주일자  
           A.SMExpKind          AS SMExpKind,           
           ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMExpKind), '') AS SMExpKindName,
           (SELECT MinorName    FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.UMOrderKind = MinorSeq)       AS UMOrderKindName,     --수주구분  
           (SELECT DeptName     FROM _TDADept   WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.DeptSeq = DeptSeq)            AS DeptName,            --부서  
           (SELECT EmpName      FROM _TDAEmp    WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.EmpSeq  = EmpSeq)             AS EmpName,             --담당자  
           F.CustName           AS CustName,            --거래처  
           F.CustNo             AS CustNo,              --거래처번호  
           A.CustSeq            AS CustSeq,             --거래처코드  
           A.PONo               AS PONo,                --PONo  
           (SELECT CurrName     FROM _TDACurr   WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND A.CurrSeq = CurrSeq)            AS CurrName,            --통화  
           A.CurrSeq            AS CurrSeq,             --통화코드  
           A.ExRate             AS ExRate,              --환율  
           A.IsStockSales       AS IsStockSales,        --판매후보관
           I.ItemName           AS ItemName,            --품명  
           I.ItemNo             AS ItemNo,              --품번  
           I.Spec               AS Spec,                --규격  
           H.ItemSeq            AS ItemSeq,             --품목내부코드
           O.ModelName          AS ModelName,           --모델  
           (SELECT UnitName     FROM _TDAUnit    WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND H.UnitSeq = UnitSeq)           AS UnitName,            --판매단위  
           CASE WHEN ISNULL(H.STDUnitSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UnitName,'')   
                                                                FROM _TDAUnit WITH (NOLOCK)     
                                                               WHERE CompanySeq = @CompanySeq AND UnitSeq = H.STDUnitSeq) END AS StdUnitName, --기준단위  
           ISNULL(H.ItemPrice,0)   AS ItemPrice,        --정가  
           ISNULL(H.CustPrice,0)   AS CustPrice,        --판매기준가  

--           CASE WHEN H.IsInclusedVAT = '1' THEN       
--                    CASE ISNULL(H.Qty, 0) WHEN 0 THEN ISNULL(H.CurAmt, 0) + ISNULL(H.CurAmt * ISNULL(H.VATRate, 0) /100, 0)      
--                        ELSE (ISNULL(H.CurAmt, 0) + ISNULL(H.CurVAT, 0)) / ISNULL(H.Qty, 0)  END      
--                                   ELSE       
--                    CASE ISNULL(H.Qty, 0) WHEN 0 THEN ISNULL(H.CurAmt, 0) ELSE ISNULL(H.CurAmt, 0) / ISNULL(H.Qty, 0) END      
--                                   END              AS Price,               --판매단가  

           CASE WHEN H.Price IS NOT NULL
                THEN H.Price
                ELSE (CASE WHEN H.IsInclusedVAT = '1' THEN       
                    CASE ISNULL(H.Qty, 0) WHEN 0 THEN ISNULL(H.CurAmt, 0) + ISNULL(H.CurAmt * ISNULL(H.VATRate, 0) /100, 0)      
                        ELSE (ISNULL(H.CurAmt, 0) + ISNULL(H.CurVAT, 0)) / ISNULL(H.Qty, 0)  END      
                                   ELSE       
                    CASE ISNULL(H.Qty, 0) WHEN 0 THEN ISNULL(H.CurAmt, 0) ELSE ISNULL(H.CurAmt, 0) / ISNULL(H.Qty, 0) END      
                                   END) END AS Price,     --판매단가

           ISNULL(H.Qty,0)                          AS Qty,                 --수량  
           H.IsInclusedVAT                          AS IsInclusedVAT,       --부가세포함  
           ISNULL(H.VATRate,0)                      AS VATRate,             --부가세율  
           ISNULL(H.CurVAT,0) + ISNULL(P.CurVAT,0)  AS CurVAT,              --부가세액  
           ISNULL(H.CurAmt,0) + ISNULL(P.CurAmt,0)  AS CurAmt,              --판매금액  
           ISNULL(H.DomAmt, 0)                      AS DomAmt,              --원화판매금액  
           ISNULL(H.DomVAT, 0)                      AS DomVAT,              --원화부가세  
           ISNULL(H.DomAmt, 0) + ISNULL(H.DomVAT, 0)    AS DomAmtTotal,     --원화판매금액계  
           CASE WHEN ISNULL(H.DVDate,'') = '' THEN ISNULL(A.DVDate,'') ELSE ISNULL(H.DVDate,'') END                             AS IDVDate,     --납기일  
           H.DVTime,    -- 납품시분 추가 : 2012.02.15 이성덕
           (SELECT WHName          FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND H.WHSeq = WHSeq)                 AS WHName,      --창고  
           CASE WHEN P.OrderSerl IS NULL THEN '0' ELSE '1' END AS SalesOption, -- 판매옵션  
           CASE WHEN ISNULL(H.DVPlaceSeq,0) = 0 THEN '' ELSE (SELECT DVPlaceName FROM _TSLDeliveryCust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DVPlaceSeq = H.DVPlaceSeq) END AS DVPlaceName, -- 납품처
           CASE WHEN M.OrderSerl IS NULL THEN '0' ELSE '1' END AS IsSpec ,--사양  
           (SELECT MinorName       FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND X.SMProgressType = MinorSeq)       AS SMProgressTypeName,      -- 영업진행상태
           (SELECT MinorName       FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND UI.SMProgressType = MinorSeq) AS SMUMProgressTypeName,    -- 구매진행상태
           (SELECT MinorName       FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND PU.SMProgressType = MinorSeq) AS SMPMProgressTypeName,    -- 생산진행상태
           (SELECT AssetName FROM _TDAItemAsset WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AssetSeq = I.AssetSeq) AS AssetName , --품목자산분류  
           H.Remark             AS IRemark,                 -- 비고  
           ISNULL(O.SMModelKind,0)  AS SMModelKind  ,
           '' AS FactUnitName,
           0           AS FactUnit,
           S.SpecName           AS SpecName,
           S.SpecValue          AS SpecValue,
           CASE WHEN ISNULL(H.CustPrice,0) = 0 OR ISNULL(H.Qty,0) = 0 THEN 0 ELSE (CASE WHEN H.IsInclusedVAT = '1' THEN ROUND(100 - (ISNULL(H.CurAmt,0) + ISNULL(H.CurVat,0)) / (ISNULL(H.CustPrice,0) * ISNULL(H.Qty,0)) * 100,0)
                                                                                                                   ELSE ROUND(100 - (ISNULL(H.CurAmt,0) / (ISNULL(H.CustPrice,0) * ISNULL(H.Qty,0))) * 100,0) END) END AS DiscountRate,
           ISNULL(ZZ.SourceNo,'') AS SourceNo, -- 추가
           ISNULL(ZZ.SourceRefNo, '') AS SourceRefNo,  -- 추가
           (SELECT UserName FROM _TCAUser WHERE CompanySeq = @CompanySeq AND UserSeq = H.LastUserSeq) AS LastUserName, 
           CONVERT(NCHAR(8), H.LastDateTime, 112) AS LastDate,
           ISNULL(CASE ISNULL(T.CustItemName, '')  
                  WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND H.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명  
           ISNULL(CASE ISNULL(T.CustItemNo, '')   
                  WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND H.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                          ELSE ISNULL(T.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번  
           ISNULL(CASE ISNULL(T.CustItemSpec, '')   
                  WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = A.CustSeq AND H.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                  ELSE ISNULL(T.CustItemSpec, '') END, '')  AS CustItemSpec,  -- 거래처품목규격  
           A.UMOrderKind       AS UMOrderKind,
		   ISNULL(N.MinorName, '') AS SMConsignKindName,
           A.UMDVConditionSeq,
           ISNULL( ( SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 8025 AND MinorSeq = H.UMEtcOutKind ), '' ) AS UMEtcOutKindName, -- 기타출고구분, 2011.11.04 by 김철웅  
           ISNULL(A.Memo, '') AS MemoM,     -- 마스터메모, 2012.07.03 by 윤보라 
           ISNULL(A.Remark, '') AS Remark,   -- 마스터비고, 2012.07.03 by 윤보라 
           ISNULL(H.Dummy1, '')  AS Dummy1,
           ISNULL(H.Dummy2, '')  AS Dummy2,
           ISNULL(H.Dummy3, '')  AS Dummy3,
           ISNULL(H.Dummy4, '')  AS Dummy4,
           ISNULL(H.Dummy5, '')  AS Dummy5,
           ISNULL(H.Dummy6, 0)   AS Dummy6,
           ISNULL(H.Dummy7, 0)   AS Dummy7,
           ISNULL(H.Dummy8, '')  AS Dummy8,
           ISNULL(H.Dummy9, '')  AS Dummy9,
           ISNULL(H.Dummy10, '') AS Dummy10, -- 20120107 박성호 추가(Dummy1 ~ Dummy10)
           ISNULL(H.PJTSeq, 0) AS PJTSeq,
           ISNULL(PJT.PJTName, '') AS PJTName,
           ISNULL(PJT.PJTNo, '') AS PJTNo,
           ISNULL(H.STDQty, 0) AS STDQty, -- 20130416 박성호 추가
          (ISNULL(H.Qty, 0) - ISNULL(C.InvoiceQty, 0)) AS MiQty, --20140205 이삭 추가,
           Z.MinorName          AS UMChannelName,   --20150129 이준식 추가
           Y.UMCustClass        AS UMChannel        --20150129 이준식 추가
      INTO #tmp_Last
      FROM #Tmp_OrderItemSLProg AS X   
            JOIN _TSLOrder     AS A WITH(NOLOCK) ON X.OrderSeq   = A.OrderSeq     
            JOIN _TSLOrderItem AS H WITH(NOLOCK) ON A.CompanySeq = H.Companyseq  
                                                AND X.OrderSeq   = H.OrderSeq  
                                                AND X.OrderSerl  = H.OrderSerl  
                                                AND X.OrderSubSerl = H.OrderSubSerl  
            JOIN #Tmp_OrderItemUIProg AS UI ON X.OrderSeq   = UI.OrderSeq
                                           AND X.OrderSerl  = UI.OrderSerl
                                           AND X.OrderSubSerl = UI.OrderSubSerl
            JOIN #Tmp_OrderItemPUProg AS PU ON X.OrderSeq   = PU.OrderSeq
                                           AND X.OrderSerl  = PU.OrderSerl
                                           AND X.OrderSubSerl= PU.OrderSubSerl
			LEFT OUTER JOIN _TDASMinor AS N WITH(NOLOCK) ON A.CompanySeq = N.CompanySeq
														AND A.SMConsignKind = N.MinorSeq
            LEFT OUTER JOIN _TDACust   AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                        AND A.CustSeq    = F.CustSeq  
            LEFT OUTER JOIN _TDACust   AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  
                                                        AND A.BKCustSeq  = G.CustSeq  
  
            LEFT OUTER JOIN _TDAItem   AS I WITH(NOLOCK) ON H.CompanySeq = I.CompanySeq  
                                                        AND H.ItemSeq    = I.ItemSeq  
            LEFT OUTER JOIN _TSLOrderItemSpec AS M WITH(NOLOCK) ON H.CompanySeq = M.CompanySeq  
                                                               AND H.OrderSeq   = M.OrderSeq  
                                                               AND H.OrderSerl  = M.OrderSerl   
            LEFT OUTER JOIN _TDAModel  AS O WITH(NOLOCK) ON H.CompanySeq = O.CompanySeq  
                                                        AND H.ModelSeq   = O.ModelSeq  
            LEFT OUTER JOIN _TSLOrderOptionItem AS P WITH(NOLOCK) ON H.CompanySeq = P.CompanySeq  
                                                                 AND H.OrderSeq   = P.OrderSeq  
                                                                 AND H.OrderSerl  = P.OrderOptionSerl  
            LEFT OUTER JOIN #TempSOSpec AS S ON H.CompanySeq = @CompanySeq
                                            AND H.OrderSeq   = S.OrderSeq
                                            AND H.OrderSerl  = S.OrderSerl
            LEFT OUTER JOIN #TempResult AS ZZ WITH(NOLOCK) ON H.CompanySeq  = @CompanySeq  -- 추가
                                                          AND H.OrderSeq  = ZZ.InOutSeq  -- 추가
                                                          AND H.OrderSerl = ZZ.InOutSerl -- 추가
                                                          AND H.OrderSubSerl = ZZ.InOutSubSerl -- 추가
            LEFT OUTER JOIN _TSLCustItem  AS T WITH(NOLOCK) ON T.CompanySeq = @CompanySeq  
                                                           AND H.ItemSeq    = T.ItemSeq  
                                                           AND T.CustSeq    = A.CustSeq  
                                                           AND H.UnitSeq = T.UnitSeq 
            LEFT OUTER JOIN _TPJTProject AS PJT WITH(NOLOCK) ON H.CompanySeq = PJT.CompanySeq
                                                          AND H.PJTSeq = PJT.PJTSeq 
            LEFT OUTER JOIN #OrderTracking  AS C ON X.IDX_No = C.IDX_No     --20140205 이삭 추가                                                                                                 
		    LEFT OUTER JOIN _TDACustClass   AS Y ON A.CompanySeq = Y.CompanySeq --20150129 이준식 추가
		                                        AND A.CustSeq = Y.CustSeq
		                                        AND Y.UMajorCustClass = 8004
            LEFT OUTER JOIN _TDAUMinor      AS Z ON Y.CompanySeq = Z.CompanySeq --20150129 이준식 추가
                                                AND Y.UMCustClass = Z.MinorSeq		                                        
     WHERE A.CompanySeq = @CompanySeq  
       AND (@ItemNo  = '' OR I.ItemNo  LIKE @ItemNo + '%')
       AND (@Spec    = '' OR I.Spec    LIKE @Spec + '%')
       AND (@ModelName = '' OR O.ModelName LIKE @ModelName + '%')  
       AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType OR X.SMProgressType = @SMProgressType2
								OR ( @SMProgressType = 8098001 AND X.SMProgressType IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1037 AND Serl = 1001 AND ValueText = '1' )) )  
       AND (@SourceNo = '' OR ISNULL(ZZ.SourceNo,'') LIKE @SourceNo + '%')
       AND (@SourceRefNo = '' OR ZZ.SourceRefNo LIKE @SourceRefNo + '%')
       AND (@UMEtcOutKind = 0 OR H.UMEtcOutKind = @UMEtcOutKind) -- 20130111 박성호 추가
       AND (@PJTName = '' OR PJT.PJTName LIKE @PJTName + '%')
       AND (@PJTNo = '' OR PJT.PJTNo LIKE @PJTNo + '%')
       AND (@AssetSeq = 0 OR I.AssetSeq = @AssetSeq)
       AND (@UMDVConditionSeq = 0 OR A.UMDVConditionSeq = @UMDVConditionSeq) -- 운송수단 
    -- ORDER BY A.OrderDate, A.OrderNo, H.OrderSerl

    -- 생산 사업장 가져오기
    CREATE TABLE #TSLOrderFact
    (
        OrderSeq     INT,
        OrderSerl    INT,
        OrderSubSerl INT,
        FactUnit     INT
    )

    INSERT INTO #TSLOrderFact
    SELECT A.OrderSeq, A.OrderSerl, A.OrderSubSerl, MIN(E.FactUnit)
      FROM #tmp_Last AS A 
           JOIN _TSLOrderItem AS B ON B.CompanySeq = @CompanySeq 
                                  AND A.OrderSeq = B.OrderSeq 
                                  AND A.OrderSerl = B.OrderSerl                   
                                  AND A.OrderSubSerl = B.OrderSubSerl  
           JOIN _TSLOrder AS C ON C.CompanySeq = @CompanySeq
                              AND B.OrderSeq   = C.OrderSeq
           JOIN _TDAItemClass AS D ON D.CompanySeq = @CompanySeq
                                  AND B.ItemSeq    = D.ItemSeq  
                                  AND D.UMajorItemClass = 2001
           JOIN _TPDBaseDeptItemClassFactUnit AS E ON E.CompanySeq = @CompanySeq
                                                  AND C.BizUnit    = E.BizUnit
                                                  AND C.DeptSeq    = E.DeptSeq
                                                  AND D.UMItemClass = E.ItemClassSeq
    GROUP BY A.OrderSeq, A.OrderSerl, A.OrderSubSerl


    INSERT INTO #TSLOrderFact
    SELECT A.OrderSeq, A.OrderSerl, A.OrderSubSerl, MIN(E.FactUnit)
      FROM #tmp_Last AS A 
           JOIN _TSLOrderItem AS B ON B.CompanySeq = @CompanySeq 
                                  AND A.OrderSeq = B.OrderSeq 
                                  AND A.OrderSerl = B.OrderSerl           
                                  AND A.OrderSubSerl = B.OrderSubSerl        
           JOIN _TSLOrder AS C ON C.CompanySeq = @CompanySeq
                              AND B.OrderSeq   = C.OrderSeq
           JOIN _TDAItemClass AS D ON D.CompanySeq = @CompanySeq
                                  AND B.ItemSeq    = D.ItemSeq  
                                  AND D.UMajorItemClass = 2001
           JOIN _TPDBaseDeptItemClassFactUnit AS E ON E.CompanySeq = @CompanySeq
                                                  AND C.BizUnit    = E.BizUnit
                                                  AND D.UMItemClass = E.ItemClassSeq
           LEFT OUTER JOIN #TSLOrderFact AS F ON A.OrderSeq = F.OrderSeq
                                             AND A.OrderSerl = F.OrderSerl
                                             AND A.OrderSubSerl = F.OrderSubSerl
     WHERE E.DeptSeq = 0
       AND F.OrderSeq IS NULL
     GROUP BY A.OrderSeq, A.OrderSerl, A.OrderSubSerl


    INSERT INTO #TSLOrderFact
    SELECT A.OrderSeq, A.OrderSerl, A.OrderSubSerl, MIN(E.FactUnit)
      FROM #tmp_Last AS A        
           JOIN _TSLOrder AS C ON C.CompanySeq = @CompanySeq
                              AND A.OrderSeq   = C.OrderSeq
           JOIN _TPDBaseDeptItemClassFactUnit AS E ON E.CompanySeq = @CompanySeq
                                                  AND C.BizUnit    = E.BizUnit
                                                  AND C.DeptSeq    = E.DeptSeq
           LEFT OUTER JOIN #TSLOrderFact AS F ON A.OrderSeq = F.OrderSeq
                                             AND A.OrderSerl = F.OrderSerl
                                             AND A.OrderSubSerl = F.OrderSubSerl
     WHERE E.ItemClassSeq = 0
       AND F.OrderSeq IS NULL
     GROUP BY A.OrderSeq, A.OrderSerl, A.OrderSubSerl


    INSERT INTO #TSLOrderFact
    SELECT A.OrderSeq, A.OrderSerl, A.OrderSubSerl, MIN(E.FactUnit)
      FROM #tmp_Last AS A 
           JOIN _TSLOrder AS C ON C.CompanySeq = @CompanySeq
                              AND A.OrderSeq   = C.OrderSeq
           JOIN _TPDBaseDeptItemClassFactUnit AS E ON E.CompanySeq = @CompanySeq
                                                  AND C.BizUnit    = E.BizUnit
           LEFT OUTER JOIN #TSLOrderFact AS F ON A.OrderSeq = F.OrderSeq
                                             AND A.OrderSerl = F.OrderSerl
                                             AND A.OrderSubSerl = F.OrderSubSerl
     WHERE F.OrderSeq IS NULL
     GROUP BY A.OrderSeq, A.OrderSerl, A.OrderSubSerl


    INSERT INTO #TSLOrderFact
    SELECT A.OrderSeq, A.OrderSerl, A.OrderSubSerl, MIN(E.FactUnit)
      FROM #tmp_Last AS A            
           JOIN _TSLOrder AS C ON C.CompanySeq = @CompanySeq
                              AND A.OrderSeq   = C.OrderSeq
           JOIN _TDAFactUnit AS E ON E.CompanySeq = @CompanySeq
                                 AND C.BizUnit    = E.BizUnit
           LEFT OUTER JOIN #TSLOrderFact AS F ON A.OrderSeq = F.OrderSeq
                                             AND A.OrderSerl = F.OrderSerl
                                             AND A.OrderSubSerl = F.OrderSubSerl
     WHERE F.OrderSeq IS NULL
     GROUP BY A.OrderSeq, A.OrderSerl, A.OrderSubSerl



    SELECT A.IsStop,              --중단  
           A.BizUnitName,         --사업부문  
           A.OrderNo,             --수주번호  
           A.OrderRev,            --수주차수  
           A.OrderSeq,            --수주내부번호  
           A.OrderSerl,           --수주순번  
           A.OrderSubSerl,        --수주하위순번  
           A.OrderDate,           --수주일자  
           A.SMExpKind,           
           A.SMExpKindName,
           A.UMOrderKindName,     --수주구분  
           A.DeptName,            --부서  
           A.EmpName,             --담당자  
           A.CustName,            --거래처  
           A.CustNo,              --거래처번호  
           A.CustSeq,             --거래처코드  
           A.PONo,                --PONo  
           A.CurrName,            --통화  
           A.CurrSeq,             --통화코드  
           A.ExRate,              --환율  
           A.IsStockSales,        --판매후보관
           A.ItemName,            --품명  
           A.ItemNo,              --품번  
           A.Spec,                --규격  
           A.ItemSeq,             --품목내부코드
           A.ModelName,           --모델  
           A.UnitName,            --판매단위  
           A.StdUnitName, --기준단위  
           A.ItemPrice,           --정가  
           A.CustPrice,           --판매기준가  
           A.Price,           --판매단가  
           A.Qty,       --수량  
           A.IsInclusedVAT,          --부가세포함  
           A.VATRate,             --부가세율  
           A.CurVAT,              --부가세액  
           A.CurAmt,              --판매금액  
           A.DomAmt,               --원화판매금액  
           A.DomVAT,               --원화부가세  
           A.DomAmtTotal, --원화판매금액계  
           A.IDVDate,                 --납기일  
           A.DVTime,                 --납품시분
           A.WHName,                  --창고  
           A.SalesOption, -- 판매옵션  
           A.DVPlaceName, -- 납품처
           A.IsSpec ,--사양  
           A.SMProgressTypeName,      -- 영업진행상태
           A.SMUMProgressTypeName,    -- 구매진행상태
           A.SMPMProgressTypeName,    -- 생산진행상태
           A.AssetName , --품목자산분류  
           A.IRemark,                 -- 비고  
           A.SMModelKind  ,
           ISNULL((SELECT FactUnitName FROM _TDAFactUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND FactUnit = B.FactUnit),'') AS FactUnitName,
           B.FactUnit,
           A.SpecName,
           A.SpecValue,
           A.DiscountRate,
           A.SourceNo, -- 추가
           A.SourceRefNo,  -- 추가
           A.LastUserName, 
           A.LastDate,
           A.CustItemName,
           A.CustItemNo,
           A.CustItemSpec,
           A.UMOrderKind,
		   A.SMConsignKindName, 
           ISNULL(C.ProdReqNo,'') AS ProdReqNo,
           ISNULL((SELECT ValueText fROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 8022 AND MinorSeq = UMOrderKind  AND Serl = 1002),'')  AS FormID,
           
           UMEtcOutKindName, -- 기타출고구분, 2011.11.04 by 김철웅 
           A.Remark,         -- 마스터비고, 2012.07.03 by 윤보라
           A.MemoM,           -- 마스터메모, 2012.07.03 by 윤보라
           A.Dummy1,
           A.Dummy2,
           A.Dummy3,
           A.Dummy4,
           A.Dummy5,
           A.Dummy6,
           A.Dummy7,
           A.Dummy8,
           A.Dummy9,
           A.Dummy10, -- 20120107 박성호 추가(Dummy1 ~ Dummy10)
           A.PJTSeq,
           A.PJTName,
           A.PJTNo,
           A.StdQty, -- 20130416 박성호 추가
           A.MiQty,  -- 20140205 이삭 추가
           A.UMChannelName, --20150129 이준식 추가
           A.UMChannel,      --20150129 이준식 추가
           E.IsDirect, -- 직송여부 
           E.PUQty,  -- 매입량 
           E.PUCustSeq,  -- 매입처코드
           F.CustName AS PUCustName, -- 매입처 
           F.CustNo AS PUCustNo, -- 매입처번호 
           E.DrumQty, -- 드럼환산수량 
           E.DelvPrice, -- 매입단가 
           E.StdPrice, -- 기준단가 
           E.StdPrice - E.DelvPrice AS DiffPrice, -- 단가차이 
           E.UMCancelReason, -- 취소사유코드
           G.MinorName AS UMCancelReasonName, -- 취소사유
           E.OrderNo AS ItemOrderNo, -- OrderNo
           E.ShipmentNo, -- ShipmentNo
           H.DelvNo, -- 납품번호 
           CONVERT(NVARCHAR(100),E.LastDateTime,120) AS LastDateTime, -- 최종작업일 
           I.UserName AS LastUserName,  -- 최종작업자 
           J.MinorName AS UMSalesKindName, -- 매출유형 
           K.BizUnitname AS ShipBizUnitName, -- 배송사업장 
           L.MinorName AS UMWorkCenterName,  -- 작업지
           M.CustName AS ServiceCustName,  -- 용역업체
           M.CustNo AS ServiceCustNo, -- 용역업체번호
           (SELECT MinorName    FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND A.UMDVConditionSeq = MinorSeq)    AS DVConditionName, -- 운송수단
           N.CfmCode AS Confirm 
      FROM #tmp_Last                        AS A
      LEFT OUTER JOIN #TSLOrderFact         AS B ON ( A.OrderSeq = B.OrderSeq AND A.OrderSerl = B.OrderSerl AND A.OrderSubSerl = B.OrderSubSerl ) 
      LEFT OUTER JOIN #Tmp_ProdReq          AS C ON ( C.OrderSeq = A.OrderSeq AND C.OrderSerl = A.OrderSerl AND C.OrderSubSerl = A.OrderSubSerl ) 
      LEFT OUTER JOIN HYE_TSLOrderAdd       AS D ON ( D.CompanySeq = @CompanySeq AND D.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN HYE_TSLOrderItemAdd   AS E ON ( E.CompanySeq = @CompanySeq AND E.OrderSeq = A.OrderSeq AND E.OrderSerl = A.OrderSerl ) 
      LEFT OUTER JOIN _TDACust              AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = E.PUCustSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = E.UMCancelReason ) 
      LEFT OUTER JOIN _TPUDelv              AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = E.DelvSeq ) 
      LEFT OUTER JOIN _TCAUser              AS I ON ( I.CompanySeq = @CompanySeq AND I.UserSeq = E.LastUserSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = D.UMSalesKind ) 
      LEFT OUTER JOIN _TDABizUnit           AS K ON ( K.CompanySeq = @CompanySeq AND K.BizUnit = D.ShipBizUnit ) 
      LEFT OUTER JOIN _TDAUMinor            AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = D.UMWorkCenter ) 
      LEFT OUTER JOIN _TDACust              AS M ON ( M.CompanySeq = @CompanySeq AND M.CustSeq = D.ServiceCustSeq )
      LEFT OUTER JOIN _TSLOrder_Confirm      AS N ON ( N.CompanySeq = @CompanySeq AND N.CfmSeq = A.OrderSeq )  
     WHERE (@DVDateFr = '' OR A.IDVDate >= @DVDateFr ) 
       AND (@DVDateTo = '' OR A.IDVDate <= @DVDateTo ) 
       AND (@UMSalesKind = 0 OR D.UMSalesKind = @UMSalesKind) -- 판매유형 
       AND (@ShipBizUnit = 0 OR D.ShipBizUnit = @ShipBizUnit) -- 배송사업장 
       AND (@UMWorkCenter = 0 OR D.UMWorkCenter = @UMWorkCenter) -- 작업지 
       AND (@ServiceCustSeq = 0 OR D.ServiceCustSeq = @ServiceCustSeq) -- 용역업체 
            
     ORDER BY  A.OrderDate, A.OrderNo, A.OrderSerl 
    
    RETURN

go
exec HYE_SSLOrderItemInfoQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMProgress>0</SMProgress>
    <PJTName />
    <PJTNo />
    <UMSalesKind />
    <ShipBizUnit />
    <UMWorkCenter />
    <ServiceCustSeq />
    <BizUnit>1</BizUnit>
    <OrderDateFr>20160801</OrderDateFr>
    <OrderDateTo>20160805</OrderDateTo>
    <DVDateFr />
    <DVDateTo />
    <OrderNo />
    <UMOrderKind />
    <CustSeq />
    <DeptSeq />
    <EmpSeq />
    <ItemSeq />
    <ItemNo />
    <Spec />
    <SMProgressType />
    <PONo />
    <UMChannel />
    <SourceTableSeq />
    <SourceRefNo />
    <SourceNo />
    <UMEtcOutKind />
    <UMEtcOutKindName />
    <AssetSeq />
    <AssetName />
    <ModelName />
    <SMExpKind />
    <WHSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1520049,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=1520037