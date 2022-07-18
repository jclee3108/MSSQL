
IF OBJECT_ID('DTI_SPJTSalesProfitListCreate') IS NOT NULL 
    DROP PROC DTI_SPJTSalesProfitListCreate
GO 

-- v2014.03.18 

-- 프로젝트별매출이익현황_DTI(계획집계) by이재천
CREATE PROC dbo.DTI_SPJTSalesProfitListCreate
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0
AS   
    
    DECLARE @docHandle          INT, 
            @PlanRev            INT, 
            @PJTSeq             INT, 
            @PlanFrDate         NCHAR(8),   
            @PlanToDate         NCHAR(8),   
            @ClosingNextCostYM  NCHAR(6),   
            @EnvSeq11           INT,   
            @EnvSeq12           INT,   
            @SMCostMng          INT,   
            @CostEnv            INT,            -- 사용원가 환경설정    
            @IFRSEnv            INT,            -- IFRS 사용 여부 환경설정    
            @PJTTypeSeq         INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @PlanRev     = ISNULL(PlanRev,0), 
           @PJTSeq      = ISNULL(PJTSeq,0), 
           @PlanFrDate  = ISNULL(PlanFrDate,''), 
           @PlanToDate  = ISNULL(PlanToDate,''), 
           @PJTTypeSeq  = ISNULL(PJTTypeSeq,0)
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
      WITH (
            PlanRev            INT, 
            PJTSeq             INT, 
            PlanFrDate         NCHAR(8), 
            PlanToDate         NCHAR(8), 
            PJTTypeSeq         INT
           )
    
    SELECT @EnvSeq11 = (SELECT EnvValue FROM DTI_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 11)   
    SELECT @EnvSeq12 = (SELECT EnvValue FROM DTI_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 12)   

    SELECT @ClosingNextCostYM = ISNULL((  
                                         SELECT CONVERT(NCHAR(6),DATEADD(MONTH, 1, MAX(A.CostYM) + '01'),112)  
                                           FROM _TESMDCostKey AS A   
                                           JOIN _TESMCProfClosing AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq )   
                                          WHERE B.IsClosing = '1'   
                                            AND A.CompanySeq = @CompanySeq   
                                       ),'19000101'--SELECT RegDate FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND   
                                      )  
                                      
    -- _TLGInOutStock Amt을 _TESMGInoutstock 의 Amt로 바꿔줌 dykim    
    
    EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@CostEnv OUTPUT     
    EXEC dbo._SCOMEnv @CompanySeq,5563,@UserSeq,@@PROCID,@IFRSEnv OUTPUT        
      
    
    IF @CostEnv = 5518001 AND ISNULL(@IFRSEnv, 0) = 0          -- 기본원가 사용    
    BEGIN    
        SELECT @SMCostMng = 5512004    
    END    
    ELSE IF @CostEnv = 5518001 AND @IFRSEnv = 1     -- 기본원가, IFRS 사용    
    BEGIN    
        SELECT @SMCostMng = 5512006    
    END    
    ELSE IF @CostEnv = 5518002 AND ISNULL(@IFRSEnv, 0) = 0     -- 활동기준원가 사용    
    BEGIN    
        SELECT @SMCostMng = 5512001    
    END    
    ELSE IF @CostEnv = 5518002 AND @IFRSEnv = 1     -- 활동기준원가, IFRS 사용    
    BEGIN       
        SELECT @SMCostMng = 5512005    
    END 
    
    CREATE TABLE #TEMP 
    (
        PJTSeq          INT, 
        BOMSerl         INT, 
        SMCostType      INT, 
        SMItemType      INT, 
        NowPlanAmt      DECIMAL(19,5), 
        PJTYM           NCHAR(6), 
        ResultAmt       DECIMAL(19,5), 
        ItemSeq         INT 
    )
    
/*************************************************** 계획 *********************************************************/
    -- 프로젝트매출 S/W, H/W
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, A.BOMSerl, 1000418001, 
           CASE WHEN A.BgtSeq = @EnvSeq11 
                THEN 1000419002 
                WHEN A.BgtSeq = @EnvSeq12 
                THEN 1000419001 
                ELSE 0 
                END, 
           B.Amt, 
           
           '', 0, A.ItemSeq 
           
      FROM _TPJTBOM                 AS A 
      LEFT OUTER JOIN DTI_TPJTBOM   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.BOMSerl = A.BOMSerl )   
      --LEFT OUTER JOIN _TCOMFSItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.FSItemSeq = A.BgtSeq )   
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq   
       AND A.BgtSeq IN (@EnvSeq11,@EnvSeq12)  
    
    -- 프로젝트매출 내부용역, 외부용역 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418001, 
           CASE WHEN B.BgtSeq = 991   
                THEN 1000419003   
                WHEN B.BgtSeq = 992   
                THEN 1000419004    
                END, 
           ISNULL(F.Amt, 0), 
           
           '', 0, A.ResrcSeq
            
      FROM (      
            SELECT      
                A.PJTSeq, A.ResrcSeq, SUM(ProcHours) AS ProcHours      
            FROM _TPJTResourceWBS AS A      
            WHERE A.CompanySeq = @CompanySeq      
              AND A.PJTSeq = @PJTSeq 
            GROUP BY A.PJTSeq, A.ResrcSeq      
           ) AS A       
      LEFT OUTER JOIN _TPJTResource       AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN DTI_TPJTResourceWBS AS F WITH (NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.PJTSeq = A.PJTSeq AND F.ResrcSeq = A.ResrcSeq ) 
    
    -- 직접비(PJT원가) S/W, H/W 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, A.BOMSerl, 1000418002, 
           CASE WHEN A.BgtSeq = @EnvSeq11 
                THEN 1000419001 
                WHEN A.BgtSeq = @EnvSeq12 
                THEN 1000419002
                ELSE 0 
                END, 
           ISNULL(A.Price,0) * ISNULL(A.TotQty,0), 
           
           '', 0, A.ItemSeq 
      FROM _TPJTBOM                 AS A   
      --LEFT OUTER JOIN DTI_TPJTBOM   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.BOMSerl = A.BOMSerl )   
      --LEFT OUTER JOIN _TCOMFSItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.FSItemSeq = A.BgtSeq )   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.PJTSeq = @PJTSeq   
       AND A.BgtSeq IN (@EnvSeq11,@EnvSeq12) 
    
    -- 직접비(PJT원가)내부용역, 외부용역 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418002, 
           CASE WHEN B.BgtSeq = 991   
                THEN 1000419003   
                WHEN B.BgtSeq = 992   
                THEN 1000419004    
                END, 
           CASE A.ISStd WHEN '1' THEN (A.Price * (H.Numerator /isnull( H.Denominator,1))) * (A.ProcHours * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * A.CurrRate
                                 ELSE A.Price * A.ProcHours * A.CurrRate 
                                 END AS ProcPrice, -- 투입금액 =(단가 * 단가단위의 환산단위(분자/분모) ) * (투입공수 * 단가단위의 환산단위(분자/분모)) 
           '', 0, A.ResrcSeq
    
      FROM _TPJTMemberAssign AS A WITH (NOLOCK)
      LEFT OUTER JOIN _TPJTResource       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.ResrcSeq = B.ResrcSeq
      LEFT OUTER JOIN _TPJTBaseQualify    AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq AND B.QualifySeq = G.QualifySeq
      LEFT OUTER JOIN _TPJTBaseQualifySub AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND G.PriceUnitSeq = H.CalcUnitSeq AND B.QualifySeq = H.QualifySeq --단가환산단위
      LEFT OUTER JOIN _TPJTProjectDesc    AS H1 WITH(NOLOCK) ON A.CompanySeq = H1.CompanySeq AND A.PJTSeq = H1.PJTSEq
      LEFT OUTER JOIN _TPJTBaseQualifySub AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND H1.ResultStdUnitSeq = I.CalcUnitSeq AND B.QualifySeq = I.QualifySeq --공수환산단위  
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
    
    -- 직접비(PJT원가)사전영업비 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT @PJTSeq, 1, 1000418002, 1000419005, 0, '', 0, 0 
    
    -- 직접비(PJT원가)경비 
    -- 상위 예산분류명 가져오기    
    CREATE TABLE #RootClass    
    (       
        PJTTypeSeq         INT NULL,              
        ROOTClassSeq       INT NULL,      
        ROOTClassName      NVARCHAR(100)  NULL,    
        UpperClassSeq      INT NULL,      
        UpperClassName     NVARCHAR(100)  NULL,    
        ClassSeq           INT NULL,      
        ClassName          NVARCHAR(100)  NULL,    
        SortOrder          INT NULL   
    )  
    EXEC _SPJTTypeFClass  @CompanySeq, 3, 14, @PJTTypeSeq 
    
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418002, 1000419006, A.BgtAmt, 
           '', 0, A.BgtClassSeq 
      FROM _TPJTBgtReqExpense     AS A   
      LEFT OUTER JOIN _TPJTBgtReq AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PJTSeq = B.PJTSeq AND BgtReqType = 7006002 )  --  실행예산신청 (예산과목별)로 작성된 건만 조회...    
      LEFT OUTER JOIN #RootClass  AS X              ON ( A.BgtClassSeq = X.ClassSeq )   
      --LEFT OUTER JOIN _TPJTIssue  AS Z WITH(NOLOCK) ON ( A.CompanySeq = Z.CompanySeq AND A.IssueSeq = Z.IssueSeq )   
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PjtSeq 
     ORDER BY X.SortOrder 
    
/*************************************************** 계획, END ****************************************************/
    
/*************************************************** 실적 *********************************************************/
    -- 프로젝트매출 S/W, H/W 
    SELECT ROW_NUMBER() OVER(ORDER BY C.MatOutSeq, C.OutItemSerl) AS IDX_NO,   
           I.WorkReportSeq,   
           I.ItemSerl,   
           C.MatOutSeq,   
           C.OutItemSerl,   
           I.InputDate,   
           I.Qty  
      INTO #TPDMMOutItem  
      FROM _TPDSFCMatinput AS I   
      JOIN _TPJTResultMatOut AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = I.WorkReportSeq AND B.ItemSerl = I.ItemSerl )   
      JOIN _TPDMMOutItem     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MatOutSeq = B.MatOutSeq AND C.OutItemSerl = B.ItemSerl AND C.PJTSeq = @PJTSeq )   
    
    CREATE TABLE #TMP_SourceTable   
            (IDOrder   INT,   
             TableName NVARCHAR(100))    
      
    INSERT INTO #TMP_SourceTable (IDOrder, TableName)   
         SELECT 1, '_TPUORDPOReqItem'   -- 찾을 데이터의 테이블  
  
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
             @TableName = '_TPDMMOutItem',  -- 기준 테이블  
             @TempTableName = '#TPDMMOutItem',  -- 기준템프테이블  
             @TempSeqColumnName = 'MatOutSeq',  -- 템프테이블 Seq  
             @TempSerlColumnName = 'OutItemSerl',  -- 템프테이블 Serl  
             @TempSubSerlColumnName = ''   
      
    SELECT A.WorkReportSeq,   
           A.ItemSerl,   
           A.MatOutSeq,   
           A.OutItemSerl,   
           D.PJTSeq,   
           D.BOMSerl,   
           D.ItemSeq,   
           A.InputDate,   
           A.Qty  
      INTO #TEMP_SUB  
      FROM #TPDMMOutItem        AS A   
      JOIN #TCOMSourceTracking  AS B              ON ( B.IDX_NO = A.IDX_NO )   
      JOIN _TPUORDPOReqItem     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POReqSeq = B.Seq AND C.POReqSerl = B.Serl )   
      JOIN _TPJTBOM             AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = C.PJTSeq AND D.ItemSeq = C.ItemSeq AND D.BOMSerl = C.BOMSerl )   
    
    
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT I.PJTSeq, I.BOMSerl, 1000418001, 
           CASE WHEN B.BgtSeq = @EnvSeq11   
                THEN 1000419001   
                WHEN B.BgtSeq = @EnvSeq12  
                THEN 1000419002   
                ELSE 0  
                END, 
           0, 
           
           LEFT(I.InPutDate,6), 
           CASE WHEN ISNULL(C.Amt,0) = 0 THEN 0 ELSE (ISNULL(A.Amt,0)/(ISNULL(B.Price,0) * ISNULL(B.TotQty,0))) * ISNULL(C.Amt,0)END, 
           I.ItemSeq 
           
      FROM #TEMP_SUB AS I   
      JOIN (SELECT Y.CompanySeq, Y.InOutSeq, Y.InOutSubSerl, Y.Amt, Y.InOutSerl      -- left outer join 에서 join으로 변경 2012. 2. 5 hkim  
              FROM _TESMGInoutstock AS Y WITH(NOLOCK)     
              JOIN _TESMDCostKey    AS Z WITH(NOLOCK) ON Z.CompanySeq    = Y.CompanySeq    
                                                     AND Z.CostKeySeq    = Y.CostKeySeq    
                                                     AND Z.SMCostMng     = @SMCostMng    
                                                     AND Z.RptUnit       = 0    
                                                     AND Z.CostMngAmdSeq = 0    
                                                     AND Z.PlanYear      = ''    
             WHERE Y.InOutType       = 130  
               AND Y.CompanySeq = @CompanySeq          -- 법인코드와 일자 추가 2012. 2. 5 hkim  
               AND LEFT(Y.InOutDate,6) >= @ClosingNextCostYM ) AS A ON A.CompanySeq = @CompanySeq   
                                                                   AND I.WorkReportSeq = A.InOutSeq    
                                                                   AND I.ItemSerl = A.InOutSubSerl   
      LEFT OUTER JOIN _TPJTBOM    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = I.ItemSeq AND B.BOMSerl = I.BOMSerl AND B.PJTSeq = I.PJTSeq )    
      LEFT OUTER JOIN DTI_TPJTBOM AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = B.PJTSeq AND C.BOMSerl = B.BOMSerl )  
     WHERE B.BgtSeq IN ( @EnvSeq11, @EnvSeq12 )  
       AND I.PjtSeq = @PJTSeq   
       AND LEFT(I.InputDate,6)= @ClosingNextCostYM   
     ORDER BY I.BOMSerl  
    
    -- 프로젝트매출 내부용역,외부용역 
    -- 내부 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418001, 
           CASE WHEN D.BgtSeq = 991   
                THEN 1000419003    
                WHEN D.BgtSeq = 992   
                THEN 1000419004    
                ELSE 0  
                END, 
           0, 
           
           LEFT(A.WorkStartDate,6), 
           (CASE C.ISStd WHEN '1'     
                         THEN (ISNULL(B.Price,0) * (ISNULL(T.Numerator,0) /isnull( T.Denominator,1))) * (ISNULL(A.ManHour,0) * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * ISNULL(C.CurrRate,0) 
                         ELSE ISNULL(B.Price,0) * ISNULL(A.ManHour,0) * ISNULL(C.CurrRate,0)     
                         END), 
           A.ResrcSeq 
      FROM _TPJTResultHumanRes              AS A   
      LEFT OUTER JOIN _TPJTMemberAssign     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PjtSeq = A.PJTSeq AND C.ResrcSeq = A.ResrcSeq )   
      LEFT OUTER JOIN _TPJTProjectDesc      AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.PJTSeq = A.PJTSeq )   
      LEFT OUTER JOIN _TPJTResource         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ResrcSeq )   
      LEFT OUTER JOIN _TPJTBaseQualify      AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND D.QualifySeq = N.QualifySeq )   
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND N.PriceUnitSeq = T.CalcUnitSeq AND N.QualifySeq = T.QualifySeq ) --인적자원단가환산단위  
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND X.ResultStdUnitSeq = I.CalcUnitSeq AND N.QualifySeq = I.QualifySeq ) --공수환산단위    
      --LEFT OUTER JOIN _TPJTResourceWBS      AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = A.PJTSeq AND J.ResrcSeq = A.ResrcSeq AND J.WBSSeq = A.WBSSeq )   
      LEFT OUTER JOIN DTI_TPJTResourceWBS   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ResrcSeq = A.ResrcSeq )   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.PJTSeq = @PJTSeq   
       AND D.BgtSeq IN ( 991,992 )  
       AND LEFT(A.WorkStartDate,6) = @ClosingNextCostYM   
     ORDER BY A.ResrcSeq 
    
    -- 외부
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418001, 
           CASE WHEN D.BgtSeq = 991   
                THEN 1000419003    
                WHEN D.BgtSeq = 992   
                THEN 1000419004    
                ELSE 0  
                END, 
           0, 
           
           LEFT(B.SupplyDelvDate,6), 
           (CASE C.ISStd WHEN '1'     
                         THEN (ISNULL(E.Price,0) * (ISNULL(T.Numerator,0) /isnull( T.Denominator,1))) * (ISNULL(A.Qty,0) * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * ISNULL(C.CurrRate,0) 
                         ELSE ISNULL(E.Price,0) * ISNULL(A.Qty,0) * ISNULL(C.CurrRate,0) 
                         END), 
           A.ResrcSeq 
      FROM _TPJTSupplyContDelvItem          AS A   
      JOIN _TPJTSupplyContDelivery          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq  AND B.SupplyDelvSeq = A.SupplyDelvSeq )   
      LEFT OUTER JOIN _TPJTMemberAssign     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PjtSeq = A.PJTSeq AND C.ResrcSeq = A.ResrcSeq )   
      LEFT OUTER JOIN _TPJTResource         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ResrcSeq )   
      LEFT OUTER JOIN _TPJTBaseQualify      AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND D.QualifySeq = N.QualifySeq )   
      LEFT OUTER JOIN _TPJTProjectDesc      AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.PJTSeq = A.PJTSeq )   
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND N.PriceUnitSeq = T.CalcUnitSeq AND N.QualifySeq = T.QualifySeq ) --인적자원단가환산단위  
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND X.ResultStdUnitSeq = I.CalcUnitSeq AND N.QualifySeq = I.QualifySeq ) --공수환산단위    
      LEFT OUTER JOIN DTI_TPJTResourceWBS   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND A.PJTSeq = E.PJTSeq AND A.ResrcSeq = E.ResrcSeq )   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.PJTSeq = @PJTSeq   
       AND D.BgtSeq IN ( 991,992 )   
       AND LEFT(B.SupplyDelvDate,6) = @ClosingNextCostYM   
     ORDER BY A.ResrcSeq 
    
    -- 직접비(PJT원가) S/W, H/W 
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT I.PJTSeq, I.BOMSerl, 1000418002, 
           CASE WHEN B.BgtSeq = @EnvSeq11   
                THEN 1000419001   
                WHEN B.BgtSeq = @EnvSeq12  
                THEN 1000419002   
                ELSE 0  
                END, 
           0, 
           
           LEFT(I.InPutDate,6), 
           A.Amt, 
           I.ItemSeq 
           
      FROM #TEMP_SUB AS I   
      JOIN (SELECT Y.CompanySeq, Y.InOutSeq, Y.InOutSubSerl, Y.Amt, Y.InOutSerl      -- left outer join 에서 join으로 변경 2012. 2. 5 hkim  
              FROM _TESMGInoutstock AS Y WITH(NOLOCK)     
              JOIN _TESMDCostKey    AS Z WITH(NOLOCK) ON Z.CompanySeq    = Y.CompanySeq    
                                                     AND Z.CostKeySeq    = Y.CostKeySeq    
                                                     AND Z.SMCostMng     = @SMCostMng    
                                                     AND Z.RptUnit       = 0    
                                                     AND Z.CostMngAmdSeq = 0    
                                                     AND Z.PlanYear      = ''    
             WHERE Y.InOutType       = 130  
               AND Y.CompanySeq = @CompanySeq          -- 법인코드와 일자 추가 2012. 2. 5 hkim  
               AND LEFT(Y.InOutDate,6) >= @ClosingNextCostYM ) AS A ON A.CompanySeq = @CompanySeq   
                                                                   AND I.WorkReportSeq = A.InOutSeq    
                                                                   AND I.ItemSerl = A.InOutSubSerl   
      LEFT OUTER JOIN _TPJTBOM    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = I.ItemSeq AND B.BOMSerl = I.BOMSerl AND B.PJTSeq = I.PJTSeq )    
      LEFT OUTER JOIN DTI_TPJTBOM AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = B.PJTSeq AND C.BOMSerl = B.BOMSerl )  
     WHERE B.BgtSeq IN ( @EnvSeq11, @EnvSeq12 )  
       AND I.PjtSeq = @PJTSeq   
       AND LEFT(I.InputDate,6)= @ClosingNextCostYM   
     ORDER BY I.BOMSerl 
    
    -- 직접비(PJT원가) 내부용역 
    DECLARE @EnvValue INT 
    SELECT @EnvValue = (SELECT EnvValue FROM DTI_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 19) 
    
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT A.PJTSeq, 1, 1000418002, 1000419003, 0, 
           A.InterBillingYM, (ISNULL(A.InterBIllingAmt,0) * (-1)) + C.Amt, A.ResrcSeq 
      FROM DTI_TSLInterBillingItemEmp   AS A 
      LEFT OUTER JOIN _TPJTResource     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ResrcSeq = A.ResrcSeq AND B.BgtSeq = 991 )   
      LEFT OUTER JOIN (SELECT Z.RemValSeq, SUM(X.DrAmt - X.CrAmt) * MAX(Y.SMDrOrCr) AS Amt
                         FROM _TACSlipRem AS Z
                         LEFT OUTER JOIN _TACSlipRow AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.SlipSeq = Z.SlipSeq AND X.AccSeq = @EnvValue) 
                         LEFT OUTER JOIN _TDAAccount AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.AccSeq = X.AccSeq ) 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND RemSeq = 1036 
                          AND LEFT(X.AccDate,6) = @ClosingNextCostYM 
                       GROUP BY Z.RemValSeq 
                      ) AS C ON ( C.RemValSeq = A.PJTSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
       AND A.InterBillingYM = @ClosingNextCostYM 
    
    -- 직접비(PJT원가) 외부용역
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT @PJTSeq, 1, 1000418002, 1000419004, 0, 
           '', 0, 0 
    
    -- 경비     
    CREATE TABLE #TMP_SOURCEITEM        
    (              
        IDX_NO      INT IDENTITY,              
        ExpenseSeq  INT,              
        Serl        INT        
    )    
    
    CREATE TABLE #TMP_EXPENSE        
    (              
        IDX_NO     INT,              
        SourceSeq  INT,              
        SourceSerl INT,              
        ExpenseSeq INT        
    )     
    
    INSERT #TMP_SOURCEITEM ( ExpenseSeq, Serl )    
    SELECT A.ExpenseSeq, A.Serl   --, A.PJTSeq      
      FROM _TPJTResultExpenseM AS A1 WITH (NOLOCK)    
      JOIN _TPJTResultExpenseItem AS A WITH (NOLOCK) ON A1.CompanySeq = A.CompanySeq AND A1.ExpenseSeq = A.ExpenseSeq    
     WHERE  A1.CompanySeq  = @CompanySeq    
       AND (@PJTSeq = 0 OR A.PJTSeq = @PJTSeq)    
     ORDER BY A1.ExpenseSeq, A.Serl 
    
    
    SELECT A.PJTSeq,   
           SUM(A.ExpenseAmt) AS ExpenseAmt,    
           G.UMCCtrKind,   
           S.PJTTypeSeq,   
           G.UMCostType,   
           A.CostAccSeq,   
           LEFT(A1.ExpenseDate,6) AS InPutYM  
      INTO #TMP_ExpenseSub  
      FROM  #TMP_SOURCEITEM AS A2    
      JOIN _TPJTResultExpenseItem   AS A WITH(NOLOCK) ON ( A2.ExpenseSeq = A.ExpenseSeq AND A2.Serl = A.Serl )   
      JOIN _TPJTResultExpenseM      AS A1 WITH(NOLOCK) ON ( A.CompanySeq = A1.CompanySeq AND A2.ExpenseSeq = A1.ExpenseSeq  )  
      LEFT OUTER JOIN _TPJTProject  AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.PJTSeq = B.PJTSeq )   
      LEFT OUTER JOIN _TDADept      AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.CostDeptSeq = D.DeptSeq )   
      LEFT OUTER JOIN _TPJTType     AS S WITH(NOLOCK) ON ( B.CompanySeq = S.CompanySeq AND B.PJTTypeSeq = S.PJTTypeSeq )   
      LEFT OUTER JOIN _TDATaxUnit   AS ZZ WITH(NOLOCK) ON ( A.CompanySeq = ZZ.CompanySeq AND D.TaxUnit = ZZ.TaxUnit )   
      LEFT OUTER JOIN _TDACCtr      AS G WITH(NOLOCK) ON ( A.CompanySeq = G.CompanySeq AND A.CCtrSeq = G.CCtrSeq )   
     WHERE  A.CompanySeq  = @CompanySeq    
     GROUP BY A.PJTSeq, G.UMCCtrKind, S.PJTTypeSeq, G.UMCostType, A.CostAccSeq, LEFT(A1.ExpenseDate,6)  
    
    SELECT A.CostAccSeq,   
           A.CostAccName,  
           F.AccSeq      ,   
           A.UMCostType  ,   
           A.UMCCtrKind  ,   
           F.AccName   
      INTO #TESMBAccount  
      FROM _TESMBAccount AS A WITH (NOLOCK)  
      LEFT OUTER JOIN _TDAAccount AS F WITH(NOLOCK) ON ( A.CompanySeq = F.CompanySeq AND A.AccSeq = F.AccSeq )   
     WHERE A.CompanySeq = @CompanySeq  
    
    DECLARE @FSKindSeq1  INT,   
            @FormatSeq   INT   
    
    SELECT @FSKindSeq1 = FSKindSeq  
      FROM _TCOMFSKind AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FSKindNo = 'PJTBGT'  
    SELECT @FormatSeq = FormatSeq FROM _TCOMFSForm WHERE CompanySeq = @CompanySeq AND FSKindSeq = @FSKindSeq1  
    
    SELECT ISNULL(A.FormatSerl,0)  AS Sort,  
                   A.FSItemLevel AS Level,     --트리 필수 컬럼  
                   A.FormatSerl,  
                   C.FSItemTypeName AS FSItemTypeName,  
                   A.FSItemName,  
                   A.FSItemSeq,  
                   A.UpperFSItemSeq  
      INTO #TCOMFSFormTree  
      FROM _TCOMFSFormTree AS A WITH (NOLOCK)  
      LEFT OUTER JOIN _TCOMFSItemType AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.FSItemTypeSeq = C.FSItemTypeSeq )   
     WHERE A.CompanySeq = @CompanySeq  
       AND A.FormatSeq  = @FormatSeq  
    
    INSERT INTO #TEMP 
    (
        PJTSeq, BOMSerl, SMCostType, SMItemType, NowPlanAmt, 
        PJTYM, ResultAmt, ItemSeq 
    ) 
    SELECT B.PJTSeq, 1, 1000418002, 1000419006, 0, 
           B.InPutYM, ISNULL(B.ExpenseAmt,0), C.UpperFSItemSeq 
      FROM #TESMBAccount    AS A   
      JOIN #TMP_ExpenseSub  AS B ON ( B.PJTSeq = @PJTSeq AND B.CostAccSeq = A.AccSeq AND B.UMCostType = A.UMCostType AND B.UMCCtrKind = A.UMCCtrKind )   
      JOIN #TCOMFSFormTree AS C ON ( C.FSItemSeq = A.CostAccSeq AND C.Level = 3 )  
     WHERE B.InPutYm = @ClosingNextCostYM  
       --GROUP BY B.InPutYM, C.UpperFSItemSeq,  B.PJTSeq   
    SELECT A.PJTSeq, A.SMCostType, A.SMItemType, SUM(A.NowPlanAmt) AS NowPlanAmt,  MAX(PJTYM) AS PJTYM, SUM(ResultAmt) AS ResultAmt
      INTO #TMP_Result 
      FROM #TEMP AS A 
     GROUP BY A.PJTSeq, SMCostType, SMItemType
     ORDER BY A.SMCostType, A.SMItemType 
    
    -- 해당 데이터 지우기
    DELETE FROM DTI_TPJTSalesProfitPlan WHERE CompanySeq = @CompanySeq AND PJTSeq = @PJTSeq 
    DELETE FROM DTI_TPJTSalesProfitResult WHERE CompanySeq = @CompanySeq AND PJTSeq = @PJTSeq AND ResultYM = @ClosingNextCostYM 
    
    -- 테이블에 데이터 넣기 (계획,실적)
    INSERT INTO DTI_TPJTSalesProfitPlan 
    (
        CompanySeq, PJTSeq, SMCostType, SMItemType, Rev, 
        PlanAmt, RevRemark, RevDate, LastUserSeq, LastDateTime, 
        PgmSeq 
    )
    SELECT @CompanySeq, A.PJTSeq, A.SMCostType, A.SMItemType, 0, 
           A.NowPlanAmt, '', '', @UserSeq, GETDATE(), 
           @PgmSeq 
      FROM #TMP_Result AS A 
    
    INSERT INTO DTI_TPJTSalesProfitResult 
    (
        CompanySeq, PJTSeq, SMCostType, SMItemType, ResultYM, 
        FcstAmt, ResultAmt, LastUserSeq, LastDateTime, PgmSeq 
    )
    SELECT @CompanySeq, A.PJTSeq, A.SMCostType, A.SMItemType, A.PJTYM, 
           0, A.ResultAmt, @UserSeq, GETDATE(), @PgmSeq 
      FROM #TMP_Result AS A 
     WHERE A.PJTYM = @ClosingNextCostYM 
    
    RETURN 

GO
exec DTI_SPJTSalesProfitListCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PJTSeq>156</PJTSeq>
    <PlanFrDate>20121226</PlanFrDate>
    <PlanToDate>20130625</PlanToDate>
    <PJTTypeSeq>1</PJTTypeSeq>
    <PJTTypeName>공공프로젝트</PJTTypeName>
    <PlanRev />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021749,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1018260