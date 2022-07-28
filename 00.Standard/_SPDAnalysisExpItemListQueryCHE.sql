
IF OBJECT_ID('_SPDAnalysisExpItemListQueryCHE') IS NOT NULL 
    DROP PROC _SPDAnalysisExpItemListQueryCHE
GO 

/************************************************************  
  설  명 - 데이터-공정분석자료(수출)조회 : 수출Invoice품목현황조회  
  작성일 - 20090625  
  작성자 - 박헌기  
 ************************************************************/  
 CREATE PROC dbo._SPDAnalysisExpItemListQueryCHE                 
  @xmlDocument    NVARCHAR(MAX) ,              
  @xmlFlags     INT  = 0,              
  @ServiceSeq     INT  = 0,              
  @WorkingTag     NVARCHAR(10)= '',                    
  @CompanySeq     INT  = 1,              
  @LanguageSeq INT  = 1,              
  @UserSeq     INT  = 0,              
  @PgmSeq         INT  = 0           
       
 AS          
  
     DECLARE @docHandle      INT,
             @BizUnit        INT,
             @DVReqDateFr    NCHAR(8),
             @DVReqDateTo    NCHAR(8),
             @DVReqNo        NVARCHAR(100),
             @UMOutKind      INT,
             @SMExpKind      INT,
             @CustSeq        INT,
             @DeptSeq        INT,
             @EmpSeq         INT,
             @UMPriceTerms   INT,
             @UMPayment1     INT,
             @UMPayment2     INT,
             @ItemName       NVARCHAR(100),
             @ItemNo         NVARCHAR(100), 
             @ItemSeq        INT,
             @SMProgressType INT,
             @PJTName        NVARCHAR(100),
             @PJTNo          NVARCHAR(100),
             @Spec   NVARCHAR(100)   -- 규격 (20110311 이상화 추가)
      -- 추가변수 20091201 박소연 
     DECLARE @SourceTableSeq INT,  
             @SourceNo       NVARCHAR(30),  
             @SourceRefNo    NVARCHAR(30),  
             @TableName      NVARCHAR(100),  
             @TableSeq       INT,  
             @SQL            NVARCHAR(MAX)  
  
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
     
     SELECT  @BizUnit            = ISNULL(BizUnit,0),
             @DVReqDateFr        = ISNULL(DVReqDateFr,''),
             @DVReqDateTo        = ISNULL(DVReqDateTo,''),
             @DVReqNo            = LTRIM(RTRIM(ISNULL(DVReqNo,''))),
             @UMOutKind          = ISNULL(UMOutKind,0),
             @SMExpKind          = ISNULL(SMExpKind,0),
             @CustSeq            = ISNULL(CustSeq,0),
             @DeptSeq            = ISNULL(DeptSeq,0),
             @EmpSeq             = ISNULL(EmpSeq,0),
             @UMPriceTerms       = ISNULL(UMPriceTerms,0),
             @UMPayment1         = ISNULL(UMPayment1,0),
             @UMPayment2         = ISNULL(UMPayment2,0),
             @ItemName           = LTRIM(RTRIM(ISNULL(ItemName,''))),
             @ItemNo             = LTRIM(RTRIM(ISNULL(ItemNo,''))), 
             @ItemSeq            = LTRIM(RTRIM(ISNULL(ItemSeq,0))), 
             @SMProgressType     = ISNULL(SMProgressType, 0),  
             @SourceTableSeq     = ISNULL(SourceTableSeq, 0),  -- 추가 20091201 박소연 
             @SourceNo           = ISNULL(SourceNo, ''),       -- 추가 20091201 박소연 
             @SourceRefNo        = ISNULL(SourceRefNo, ''),    -- 추가 20091201 박소연
             @PJTName            = ISNULL(PJTName, ''),
             @PJTNo              = ISNULL(PJTNo, ''),
             @Spec    = ISNULL(Spec, '')            -- 규격 (20110311 이상화 추가)
                 
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)         
     WITH (  BizUnit             INT, 
             DVReqDateFr         NCHAR(8),
             DVReqDateTo         NCHAR(8),
             DVReqNo             NVARCHAR(100),
             UMOutKind           INT,
             SMExpKind           INT,
             CustSeq             INT,
             DeptSeq             INT,
             EmpSeq              INT,
             UMPriceTerms        INT,
             UMPayment1          INT,
             UMPayment2          INT,
             ItemName            NVARCHAR(100),
             ItemNo              NVARCHAR(100),
             ItemSeq             INT,
             SMProgressType      INT,  
             SourceTableSeq      INT,            -- 추가 20091201 박소연 
             SourceNo            NVARCHAR(30),   -- 추가 20091201 박소연 
             SourceRefNo         NVARCHAR(30),   -- 추가 20091201 박소연
             PJTName             NVARCHAR(100),
             PJTNo               NVARCHAR(100),
             Spec    NVARCHAR(100)  ) -- 규격 (20110311 이상화 추가) 
                 
     IF @DVReqDateTo = ''    
         SELECT @DVReqDateTo = '99991231' 
 /***********************************************************************************************************************************************/  
  ---------------------- 조직도 연결 여부  
     DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)  
   
     IF @DVReqDateTo  = '99991231'  
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
    -- 수출출하진행 Table      
     CREATE TABLE #Temp_DVReqItemProg(IDX_NO INT IDENTITY, DVReqSeq INT, DVReqSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1))      
       
     -- 조회조건에 따른 조회      
     INSERT INTO #Temp_DVReqItemProg(DVReqSeq, DVReqSerl, CompleteCHECK, IsStop)      
     SELECT A.DVReqSeq, A.DVReqSerl, -1, A.IsStop  
       FROM  _TSLDVReqItem AS A WITH (NOLOCK)
             JOIN _TSLDVReq AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DVReqSeq = B.DVReqSeq
             JOIN _TDASMinorValue AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
                                                   AND B.SMExpKind = E.MinorSeq
             LEFT OUTER JOIN _TSLExpDVReq AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DVReqSeq = C.DVReqSeq
             LEFT OUTER JOIN _TDAItem AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                        AND A.ItemSeq = D.ItemSeq
             
             LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq
                                                           AND A.PJTSeq = F.PJTSeq
   WHERE  A.CompanySeq = @CompanySeq
        AND (@BizUnit = 0 OR B.BizUnit = @BizUnit)    
        AND (B.DVReqDate BETWEEN @DVReqDateFr AND @DVReqDateTo) 
        AND (@DVReqNo = '' OR B.DVReqNo LIKE @DVReqNo + '%')
        AND (@UMOutKind   = 0 OR B.UMOutKind   = @UMOutKind)    
        AND (@SMExpKind   = 0 OR B.SMExpKind   = @SMExpKind)    
        AND (@CustSeq = 0 OR B.CustSeq = @CustSeq)    
 ---------- 조직도 연결 변경 부분    
        AND (@DeptSeq = 0   
             OR (@SMOrgSortSeq = 0 AND B.DeptSeq = @DeptSeq)        
             OR (@SMOrgSortSeq > 0 AND B.DeptSeq IN (SELECT DeptSeq FROM @DeptTable)))        
 ---------- 조직도 연결 변경 부분    
        AND (@EmpSeq = 0 OR B.EmpSeq = @EmpSeq)    
        AND (@UMPriceTerms = 0 OR C.UMPriceTerms = @UMPriceTerms)    
        AND (@UMPayment1 = 0 OR C.UMPayment1 = @UMPayment1)    
        AND (@UMPayment2 = 0 OR C.UMPayment2 = @UMPayment2)    
        AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')
        AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')
        AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)
        AND (@PJTNo = '' OR F.PJTNo LIKE @PJTNo + '%')
        AND (@PJTName = '' OR F.PJTName LIKE @PJTName + '%')
        AND E.Serl = 1002 AND E.ValueText = '1'
        AND (@Spec = '' OR D.Spec LIKE @Spec + '%')
    
 --select * from #Temp_DVReqItemProg      
     EXEC _SCOMProgStatus @CompanySeq, '_TSLDVReqItem', 1036001, '#Temp_DVReqItemProg', 'DVReqSeq', 'DVReqSerl', '', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT', 'DVReqSeq', 'DVReqSerl', '', '_TSLDVReq', @PgmSeq
      UPDATE #Temp_DVReqItemProg       
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --진행중단      
                                          WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료      
                                          WHEN A.IsStop = '1' THEN 1037005 -- 중단      
                                          ELSE B.MinorSeq END)      
       FROM #Temp_DVReqItemProg AS A       
           LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.MajorSeq = 1037      
                                                       AND A.CompleteCHECK = B.Minorvalue
      -------------------------------------------        
     -- 원천진행 조회   20091201 박소연 추가
     -------------------------------------------     
     CREATE TABLE #TempResult  
     (  
         InOutSeq  INT,  -- 진행내부번호  
         InOutSerl  INT,  -- 진행순번  
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
   
     IF ISNULL(@SourceTableSeq, 0) <> 0  
     BEGIN  
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
           FROM #Temp_DVReqItemProg     AS A WITH(NOLOCK)           
   
   
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
      -- 수주원천조회
     DELETE FROM #TMP_SOURCETABLE
     DELETE FROM #TCOMSourceTracking
     
     INSERT INTO #TMP_SOURCETABLE
     SELECT '_TSLOrderItem'
     
     EXEC _SCOMSourceTracking @CompanySeq, '_TSLDVReqItem', '#Temp_DVReqItemProg', 'DVReqSeq', 'DVReqSerl', ''
  
      --출하검사여부체크
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
            FROM #Temp_DVReqItemProg             AS A 
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
     CREATE INDEX IX_#TempResult ON #TempResult(InOutSeq, InOutSerl)
     
 /************************************************************************************************************************************************************************/      
     -- 최종조회    
    SELECT A.DVReqSeq          AS DVReqSeq, 
            A.DVReqSerl         AS DVReqSerl,  
            A.IsStop            AS IsStop, 
            B.BizUnit           AS BizUnit, 
            LTRIM(RTRIM(ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH(NOLOCK) WHERE CompanySeq = B.CompanySeq AND BizUnit = B.BizUnit),''))) AS BizUnitName,
            B.DVReqDate         AS DVReqDate, 
            B.DVReqNo           AS DVReqNo, 
            B.SMExpKind         AS SMExpKind, 
            B.UMOutKind         AS UMOutKind, 
            LTRIM(RTRIM(ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = B.CompanySeq AND MinorSeq = B.UMOutKind),''))) AS UMOutKindName,
            LTRIM(RTRIM(ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE CompanySeq = B.CompanySeq AND MinorSeq = B.SMExpKind),''))) AS SMExpKindName,
            B.CustSeq           AS CustSeq, 
            LTRIM(RTRIM(ISNULL((SELECT CustName FROM _TDACust WHERE CompanySeq = A.CompanySeq AND CustSeq = B.CustSeq),''))) AS CustName,
            B.CurrSeq           AS CurrSeq, 
            LTRIM(RTRIM(ISNULL((SELECT CurrName FROM _TDACurr WHERE CompanySeq = A.CompanySeq AND CurrSeq = B.CurrSeq),''))) AS CurrName,
            C.UMPriceTerms      AS UMPriceTerms, 
            LTRIM(RTRIM(ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = C.CompanySeq AND MinorSeq = C.UMPriceTerms),''))) AS UMPriceTermsName, 
            C.UMPayment1        AS UMPayment1, 
            LTRIM(RTRIM(ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = C.CompanySeq AND MinorSeq = C.UMPayment1),''))) AS UMPayment1Name, 
            C.UMPayment2        AS UMPayment2, 
            LTRIM(RTRIM(ISNULL((SELECT MinorName FROM _TDAUMinor WITH(NOLOCK) WHERE CompanySeq = C.CompanySeq AND MinorSeq = C.UMPayment2),''))) AS UMPayment2Name,
            B.DeptSeq           AS DeptSeq, 
            LTRIM(RTRIM(ISNULL((SELECT DeptName FROM _TDADept WHERE CompanySeq = B.CompanySeq AND DeptSeq = B.DeptSeq),''))) AS DeptName, 
            B.EmpSeq            AS EmpSeq, 
            B.ExRate            AS ExRate,
            LTRIM(RTRIM(ISNULL((SELECT EmpName FROM _TDAEmp WHERE CompanySeq = A.CompanySeq AND EmpSeq = B.EmpSeq),''))) AS EmpName,
            A.ItemSeq           AS ItemSeq,
            ISNULL(LTRIM(RTRIM(D.ItemName)),'') AS ItemName,
            ISNULL(LTRIM(RTRIM(D.ItemNo)),'') AS ItemNo,
            ISNULL(LTRIM(RTRIM(D.Spec)),'') AS Spec,
            A.UnitSeq           AS UnitSeq,
            LTRIM(RTRIM(ISNULL((SELECT UnitName FROM _TDAUnit WHERE CompanySeq = A.CompanySeq AND UnitSeq = A.UnitSeq),''))) AS UnitName,
            A.Qty               AS Qty,
            --CASE A.Qty WHEN 0 THEN 0 ELSE (A.CurAmt / A.Qty) END AS Price, -- 판매단가
            CASE WHEN A.Price IS NOT NULL THEN A.Price
                 ELSE CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 
                           ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0)        
                                      ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END) 
                           END 
                 END AS Price, -- 판매단가
            A.ItemPrice         AS ItemPrice, -- 정가
            A.CustPrice         AS CustPrice,
            A.VATRate           AS VATRate,
            A.CurAmt            AS CurAmt, 
            A.CurVAT            AS CurVAT, 
            A.DomAmt            AS DomAmt,  -- 원화금액
            A.DomVAT            AS DomVAT, 
            (A.DomAmt + A.DomVAT) AS TotDom, 
            B.Remark            AS Remark,
            A.StdUnitSeq        AS StdUnitSeq,
            LTRIM(RTRIM(ISNULL((SELECT UnitName FROM _TDAUnit WHERE CompanySeq = A.CompanySeq AND UnitSeq = A.StdUnitSeq),''))) AS StdUnitName,
            A.StdQty            AS StdQty,
            A.DVDate            AS DVDateD, --납기일
            A.WHSeq     AS WHSeq,
            LTRIM(RTRIM(ISNULL((SELECT WHName FROM _TDAWH WHERE CompanySeq = A.CompanySeq AND WHSeq = A.WHSeq),''))) AS WHName, 
            K.MinorName         AS SMProgressTypeName,     --진행상태  
            ISNULL(Z.SourceNo,'') AS SourceNo,             -- 추가 20091201 박소연 
            ISNULL(Z.SourceRefNo, '') AS SourceRefNo,       -- 추가 20091201 박소연                
            B.ISPJT,            
            F.PJTName, 
            F.PJTNo,            
            CASE WHEN ISNULL(A.IsQAItem,'') <> '1' THEN '무검사'                   
                 WHEN ISNULL(Q.SourceTypeName, '' ) = '' THEN '미검사'                 
                 ELSE Q.SourceTypeName 
                 END AS SMQCTypeName,            
           --ISNULL(K.PassedQty, 0)      AS PassedQty,     --합격수량            
           --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN B.Qty ELSE ISNULL(K.PassedQty, 0) END AS DVQty,            
           --CASE WHEN ISNULL(B.IsQAItem,'') <> '1'  THEN ISNULL(B.STDQty, 0)  ELSE ISNULL(K.QCStdUnitQty, 0) END  AS QCStdUnitQty,            
           CASE WHEN ISNULL(A.IsQAItem,'') <> '1' THEN '' ELSE Q.TestEndDate END AS QCDate,            
           CASE WHEN ISNULL(A.IsQAItem,'') <> '1' THEN 6035001 WHEN ISNULL(Q.SMTestResult,0) = 0 THEN 6035002 ELSE Q.SMTestResult END AS SMQCType,            
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = C.LoadingPort) AS LoadingPortKOR ,  
           (SELECT Remark FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = C.LoadingPort) AS LoadingPort , -- 선적항(영문)  
           C.DischargingPort,  
           C.Destination,  
           C.ETD,  
           CASE WHEN ISNULL(M.VesselName, '') = '' 
                THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.UMVesselName)
                ELSE M.VesselName END AS VesselName,            
           D.ItemEngName, 
           T2.CustName AS BKCustName       
        FROM #Temp_DVReqItemProg AS X              
        JOIN _TSLDVReqItem AS A WITH(NOLOCK) ON X.DVReqSeq = A.DVReqSeq
                                            AND X.DVReqSerl = A.DVReqSerl             
        JOIN _TSLDVReq      AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq                                                   
                                             AND A.DVReqSeq = B.DVReqSeq             
        JOIN _TDASMinorValue AS E WITH(NOLOCK) ON B.CompanySeq = E.CompanySeq                                                   
                                              AND B.SMExpKind = E.MinorSeq                   
        LEFT OUTER JOIN _TSLExpDVReq   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                        AND A.DVReqSeq = C.DVReqSeq
        LEFT OUTER JOIN _TDAItem AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                   AND A.ItemSeq = D.ItemSeq                       
        LEFT OUTER JOIN _TDASMinor AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq
                                                    AND X.SMProgressType = K.MinorSeq
        LEFT OUTER JOIN #TempResult AS Z WITH(NOLOCK) ON A.CompanySeq = @CompanySeq  -- 추가 20091201 박소연
                                                     AND A.DVReqSeq = Z.InOutSeq     -- 추가 20091201 박소연
                                                     AND A.DVReqSerl = Z.InOutSerl   -- 추가 20091201 박소연
        LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq
                                                      AND A.PJTSeq = F.PJTSeq
        LEFT OUTER JOIN #tem_QCData AS Q               ON A.CompanySeq = Q.CompanySeq
                                                      AND A.DVReqSeq   = Q.DVReqSeq
                                                      AND A.DVReqSerl  = Q.DVReqSerl
        LEFT OUTER JOIN #TCOMSourceTracking AS T ON X.IDX_NO = T.IDX_NO AND T.IDOrder = 1
        LEFT OUTER JOIN _TSLExpMaster  AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq
                                                        AND T.Seq        = M.OrderSeq
        LEFT OUTER JOIN _TDACust         AS T2            ON B.CompanySeq   = T2.CompanySeq    
                                                         AND B.BKCustSeq    = T2.CustSeq  
     WHERE A.CompanySeq = @CompanySeq      
       AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)
       AND E.Serl = 1002 AND E.ValueText = '1' 
       AND (@SourceNo = '' OR Z.SourceNo LIKE @SourceNo + '%')  
       AND (@SourceRefNo = '' OR Z.SourceRefNo LIKE @SourceRefNo + '%')       
     ORDER BY A.DVReqSeq, A.DVReqSerl 
    
    RETURN