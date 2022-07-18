
IF OBJECT_ID('DTI_SPJTSalesRateTotalListCreate') IS NOT NULL 
    DROP PROC DTI_SPJTSalesRateTotalListCreate
GO 

-- v2014.02.14 

-- 프로젝트진행률대상집계_DTI(대상집계) by이재천
CREATE PROC DTI_SPJTSalesRateTotalListCreate                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle          INT, 
            @ResultStdUnitName  NVARCHAR(100), 
            @QueryKind          INT, 
            @BizUnit            INT, 
            @PJTSeq             INT, 
            @PJTTypeName        NVARCHAR(100), 
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
    
    SELECT @ResultStdUnitName   = ResultStdUnitName  , 
           @QueryKind           = QueryKind          , 
           @BizUnit             = BizUnit            , 
           @PJTSeq              = PJTSeq             , 
           @PJTTypeName         = PJTTypeName        , 
           @PlanFrDate          = PlanFrDate         , 
           @PlanToDate          = PlanToDate         , 
           @PJTTypeSeq          = PJTTypeSeq         
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ResultStdUnitName  NVARCHAR(100) ,
            QueryKind          INT ,
            BizUnit            INT ,
            PJTSeq             INT ,
            PJTTypeName        NVARCHAR(100) ,
            PlanFrDate         NCHAR(8) ,
            PlanToDate         NCHAR(8) ,
            PJTTypeSeq         INT)
    
    CREATE TABLE #TEMP 
    ( 
        InPutYM         NCHAR(6), 
        ItemSeq         INT, 
        ItemKind        INT, 
        BgtName         NVARCHAR(100), 
        PlanQty         DECIMAL(19,5), 
        PlanSalesAmt    DECIMAL(19,5), 
        PlanAmt         DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumSalesAmt     DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5), 
        PJTSeq          INT, 
        BOMSerl         INT 
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
    
    DELETE FROM DTI_TPJTSalesRateTotal WHERE CompanySeq = @CompanySeq AND ResultYM = @ClosingNextCostYM AND PJTSeq = @PJTSeq 
    
    -- 재료자원 계획
    INSERT INTO #TEMP ( ItemKind, ItemSeq, BgtName, PlanQty, PlanSalesAmt, PlanAmt, PJTSeq, BOMSerl )
    SELECT CASE WHEN A.BgtSeq = @EnvSeq11 
                THEN 1000402001
                WHEN A.BgtSeq = @EnvSeq12
                THEN 1000402002
                ELSE 0
                END, A.ItemSeq, C.FSItemName, A.TotQty, B.Amt, ISNULL(A.Price,0) * ISNULL(A.TotQty,0) , A.PJTSeq, A.BOMSerl 
      FROM _TPJTBOM                 AS A 
      LEFT OUTER JOIN DTI_TPJTBOM   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.BOMSerl = A.BOMSerl ) 
      LEFT OUTER JOIN _TCOMFSItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.FSItemSeq = A.BgtSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
       AND A.BgtSeq IN (@EnvSeq11,@EnvSeq12)
    
    -- 재료자원 내부실적
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
     --WHERE I.InputDate = @ClosingNextCostYM 
    
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
    
    INSERT INTO #TEMP ( ItemKind, ItemSeq, BgtName, SumQty, SumSalesAmt, SumAmt, InPutYM, PJTSeq, BOMSerl )  
    SELECT CASE WHEN B.BgtSeq = @EnvSeq11 
                THEN 1000402001 
                WHEN B.BgtSeq = @EnvSeq12
                THEN 1000402002 
                ELSE 0
                END, I.ItemSeq, '', I.Qty, CASE WHEN ISNULL(C.Amt,0) = 0 THEN 0 ELSE ISNULL(A.Amt,0)/ISNULL(C.Amt,0) * ISNULL(C.Amt,0)END, A.Amt, 
                LEFT(I.InPutDate,6), I.PJTSeq, I.BOMSerl 
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
      JOIN _TPJTBOM        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = I.ItemSeq AND B.BOMSerl = I.BOMSerl AND B.PJTSeq = I.PJTSeq )  
      LEFT OUTER JOIN DTI_TPJTBOM AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = B.PJTSeq AND C.BOMSerl = B.BOMSerl )
     WHERE B.BgtSeq IN ( @EnvSeq11, @EnvSeq12 )
       AND I.PjtSeq = @PJTSeq 
       AND LEFT(I.InputDate,6)= @ClosingNextCostYM 
     ORDER BY I.BOMSerl 
    
    --select * from _TPJTBOM as a where CompanySeq = 1 and PJTSeq = 165
    --select * from _TPUORDPOReqItem where CompanySeq = 1 and PJTSeq = 165 
    --select * from _TPDMMOutReqItem where CompanySeq = 1 and PJTSeq = 165 
    --select * from _TPDMMOutItem where CompanySeq = 1 and PJTSeq = 165
    --select * from _TPJTResultMatOut where CompanySeq = 1 and MatOutSeq = 212 
    --select * from _TPDSFCMatinput where CompanySeq =  1 and WorkReportSeq =2027
    
    -- 인적자원 계획
    INSERT INTO #TEMP ( ItemKind, ItemSeq, BgtName, PlanQty, PlanSalesAmt, PlanAmt, PJTSeq, BOMSerl )
    SELECT CASE WHEN D.BgtSeq = 991 
                THEN 1000402003 
                WHEN D.BgtSeq = 992 
                THEN 1000402004  
                END, A.ResrcSeq, N.QualifyName, C.ProcHours, ISNULL(B.Price,0) * ISNULL(C.ProcHours,0), 
                (CASE C.ISStd WHEN '1' 
                              THEN (C.Price * (T.Numerator /isnull( T.Denominator,1))) * (C.ProcHours * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * C.CurrRate
                              ELSE C.Price * C.ProcHours * C.CurrRate 
                              END), 
                A.PJTSeq , 1
      FROM _TPJTResourceWBS AS A 
      LEFT OUTER JOIN DTI_TPJTResourceWBS   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTMemberAssign     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PjtSeq = A.PJTSeq AND C.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTProjectDesc      AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TPJTResource         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTBaseQualify      AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND D.QualifySeq = N.QualifySeq ) 
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND N.PriceUnitSeq = T.CalcUnitSeq AND N.QualifySeq = T.QualifySeq ) --인적자원단가환산단위
      --LEFT OUTER JOIN _TPJTBaseQualify      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND D.QualifySeq = G.QualifySeq ) 
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND X.ResultStdUnitSeq = I.CalcUnitSeq AND N.QualifySeq = I.QualifySeq ) --공수환산단위  

      
     WHERE A.CompanySeq = @CompanySeq 
       AND D.BgtSeq IN ( 991,992 ) 
       AND A.PJTSeq = @PJTSeq 
    
    -- 인적자원 내부실적
    INSERT INTO #TEMP ( ItemKind, ItemSeq, BgtName, SumQty, SumSalesAmt, SumAmt, InPutYM, PJTSeq, BOMSerl ) 
    SELECT CASE WHEN D.BgtSeq = 991 
                THEN 1000402003  
                WHEN D.BgtSeq = 992 
                THEN 1000402004  
                ELSE 0
                END, A.ResrcSeq, 
                '', 
                A.ManHour,        
                (CASE C.ISStd WHEN '1'   
                              THEN (B.Price * (T.Numerator /isnull( T.Denominator,1))) * (A.ManHour * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * C.CurrRate  
                              ELSE B.Price * A.ManHour * C.CurrRate   
                              END), 
                ISNULL(C.Price,0) * ISNULL(A.ManHour,0), 
                LEFT(A.WorkStartDate,6), A.PJTSeq, 1 
                --ISNULL(C.Price,0) * ISNULL(C.ProcHours,0) / (CASE C.ISStd WHEN '1' 
                --                                                          THEN (C.Price * (T.Numerator /isnull( T.Denominator,1))) * (C.ProcHours * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * C.CurrRate
                --                                                          ELSE C.Price * C.ProcHours * C.CurrRate 
                --                                                          END) * ISNULL(B.Price,0) * ISNULL(J.ProcHours,0) , ISNULL(C.Price,0) * ISNULL(C.ProcHours,0), 
           
      FROM _TPJTResultHumanRes              AS A 
      LEFT OUTER JOIN _TPJTMemberAssign     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PjtSeq = A.PJTSeq AND C.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTProjectDesc      AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TPJTResource         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTBaseQualify      AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND D.QualifySeq = N.QualifySeq ) 
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND N.PriceUnitSeq = T.CalcUnitSeq AND N.QualifySeq = T.QualifySeq ) --인적자원단가환산단위
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND X.ResultStdUnitSeq = I.CalcUnitSeq AND N.QualifySeq = I.QualifySeq ) --공수환산단위  
      LEFT OUTER JOIN _TPJTResourceWBS      AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = A.PJTSeq AND J.ResrcSeq = A.ResrcSeq AND J.WBSSeq = A.WBSSeq ) 
      LEFT OUTER JOIN DTI_TPJTResourceWBS   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq AND B.ResrcSeq = A.ResrcSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
       AND D.BgtSeq IN ( 991,992 )
       AND LEFT(A.WorkStartDate,6) = @ClosingNextCostYM 
     ORDER BY A.ResrcSeq 
 
    -- 인적자원 외주실적
    INSERT INTO #TEMP ( ItemKind, ItemSeq, BgtName, SumQty, SumSalesAmt, SumAmt, InPutYM, PJTSeq, BOMSerl ) 
    SELECT CASE WHEN D.BgtSeq = 991 
                THEN 1000402003  
                WHEN D.BgtSeq = 992 
                THEN 1000402004  
                ELSE 0
                END, 
                A.ResrcSeq, 
                '', 
                A.Qty,
                (CASE C.ISStd WHEN '1'   
                              THEN (E.Price * (T.Numerator /isnull( T.Denominator,1))) * (A.Qty * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * C.CurrRate  
                              ELSE E.Price * A.Qty * C.CurrRate   
                              END), 
                ISNULL(C.Price,0) * ISNULL(A.Qty,0), 
                --A.SupplyDelvAmt / (CASE C.ISStd WHEN '1' 
                --                                                          THEN (C.Price * (T.Numerator /isnull( T.Denominator,1))) * (C.ProcHours * isnull((I.Numerator / isnull(I.Denominator,1)),1)) * C.CurrRate
                --                                                          ELSE C.Price * C.ProcHours * C.CurrRate 
                --                                                          END) * ISNULL(E.Price,0) * ISNULL(J.ProcHours,0), 
           LEFT(B.SupplyDelvDate,6), A.PJTSeq, 1
      FROM _TPJTSupplyContDelvItem  AS A 
      JOIN _TPJTSupplyContDelivery  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq  AND B.SupplyDelvSeq = A.SupplyDelvSeq ) 
      LEFT OUTER JOIN _TPJTMemberAssign     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.PjtSeq = A.PJTSeq AND C.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTResource AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN _TPJTProjectDesc      AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TPJTBaseQualify      AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND D.QualifySeq = N.QualifySeq ) 
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND N.PriceUnitSeq = T.CalcUnitSeq AND N.QualifySeq = T.QualifySeq ) --인적자원단가환산단위
      LEFT OUTER JOIN _TPJTBaseQualifySub   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND X.ResultStdUnitSeq = I.CalcUnitSeq AND N.QualifySeq = I.QualifySeq ) --공수환산단위  
      --LEFT OUTER JOIN _TPJTResourceWBS      AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = A.PJTSeq AND J.ResrcSeq = A.ResrcSeq ) 
      LEFT OUTER JOIN DTI_TPJTResourceWBS   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND A.PJTSeq = E.PJTSeq AND A.ResrcSeq = E.ResrcSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = @PJTSeq 
       AND D.BgtSeq IN ( 991,992 ) 
       AND LEFT(B.SupplyDelvDate,6) = @ClosingNextCostYM 
     ORDER BY A.ResrcSeq 
    
    -- 경비 계획
    
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
    --select * from #TEMP 
    --return 
    INSERT INTO #TEMP (ItemKind, ItemSeq, PlanAmt, PJTSeq, BOMSerl) 
    SELECT 1000402005, 
           A.BgtClassSeq, 
           --ISNULL(X.ClassName, '') AS BgtClassName, 
           A.BgtAmt AS BgtAmt, 
           A.PjtSeq   AS PjtSeq,
           1 

      FROM _TPJTBgtReqExpense     AS A 
      LEFT OUTER JOIN _TPJTBgtReq AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PJTSeq = B.PJTSeq AND BgtReqType = 7006002 )  --  실행예산신청 (예산과목별)로 작성된 건만 조회...  
      LEFT OUTER JOIN #RootClass  AS X              ON ( A.BgtClassSeq = X.ClassSeq ) 
      LEFT OUTER JOIN _TPJTIssue  AS Z WITH(NOLOCK) ON ( A.CompanySeq = Z.CompanySeq AND A.IssueSeq = Z.IssueSeq ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND A.PJTSeq = @PjtSeq 
     ORDER BY X.SortOrder  
    
    -- 경비 실적
   
     CREATE TABLE #TMP_SOURCEITEM      
     (            
         IDX_NO     INT IDENTITY,            
         ExpenseSeq  INT,            
         Serl INT      
     )  
    
     CREATE TABLE #TMP_EXPENSE      
     (            
         IDX_NO     INT,            
         SourceSeq  INT,            
         SourceSerl INT,            
         ExpenseSeq INT      
     )   
    
     INSERT #TMP_SOURCEITEM  
        ( ExpenseSeq    , Serl )  
     SELECT A.ExpenseSeq    , A.Serl   --, A.PJTSeq    
       FROM  _TPJTResultExpenseM AS A1 WITH (NOLOCK)  
             JOIN _TPJTResultExpenseItem AS A WITH (NOLOCK) ON A1.CompanySeq = A.CompanySeq  
                                                           AND A1.ExpenseSeq = A.ExpenseSeq  
      WHERE  A1.CompanySeq  = @CompanySeq  
        AND (@BizUnit = 0 OR A1.BizUnit = @BizUnit)  
        AND (@PJTSeq = 0 OR A.PJTSeq = @PJTSeq)  
      ORDER BY A1.ExpenseSeq, A.Serl  
    --select * from #TMP_SOURCEITEM 
    --return 
 ------------------------------------------------------------------------------------------------------  
   
 --select @SMSource  
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
       --AND A1.InPutYM = @ClosingNextCostYM
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
    
    --select * from #TMP_ExpenseSub where inputym = '201101' and costaccseq = 477 and umcctrkind = 5003008 
    --select * from #TESMBAccount where accseq = 477 and umcctrkind = 5003008 
    ----select * from _TDAUMinor where companyseq = 1 and MajorSeq = 4001
    --return 
    
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
    
    INSERT INTO #TEMP ( InPutYM, ItemSeq, ItemKind, SumAmt, PJTSeq, BOMSerl ) 
    SELECT B.InPutYM, C.UpperFSItemSeq, 1000402005, SUM(B.ExpenseAmt) AS ExpenseAmt, B.PJTSeq, 1
      FROM #TESMBAccount    AS A 
      JOIN #TMP_ExpenseSub  AS B ON ( B.PJTSeq = @PJTSeq AND B.CostAccSeq = A.AccSeq AND B.UMCostType = A.UMCostType AND B.UMCCtrKind = A.UMCCtrKind ) 
      JOIN #TCOMFSFormTree AS C ON ( C.FSItemSeq = A.CostAccSeq AND C.Level = 3 )
      --JOIN #TCOMFSFormTree AS D ON (  D.FSItemSeq = C.UpperFSItemSeq AND D.Level = 2 ) 
     WHERE B.InPutYm = @ClosingNextCostYM
     GROUP BY B.InPutYM, C.UpperFSItemSeq, B.PJTSeq 
    
    --select * from #TEMP where ItemKind = 1000402005 and ItemSeq = 993 and InPutYM = '201101'
    --return 
    CREATE TABLE #TCOMCalendar (Title INT)
    
    CREATE TABLE #Title
    (
        ColIdx          INT IDENTITY(0, 1), 
        Title           NVARCHAR(100), 
        TitleSeq        INT, 
        Title2          NVARCHAR(100), 
        TitleSeq2       INT, 
        COL_SET_INFO	INT,
        DataBlock	    NVARCHAR(50),
        DataFieldName	NVARCHAR(50),
        DataFieldCd	    NVARCHAR(50),
        CellType	    INT,
        DataKey	        NVARCHAR(50),
        ControlKey	    NVARCHAR(50),
        IsCombo	        NCHAR(1),
        IsComboAddTotal	NCHAR(1),
        CodeHelpDefault	NVARCHAR(50),
        CodeHelpParams	NVARCHAR(50),
        CodeHelpConst	INT,
        IsUseOldValue	NCHAR(1),
        MaxLength	    INT,
        Declength	    INT,
        DefaultValue	NVARCHAR(50),
        MaskAndCaption	NVARCHAR(50),
        Row	            INT,
        ColWidth	    INT,
        Formula	        NVARCHAR(50),
        BackColor	    INT,
        ForeColor	    INT
    )
    
    IF @QueryKind = '10001'
    BEGIN 
    
        INSERT INTO #TCOMCalendar (Title)
        SELECT DISTINCT LEFT(Solar,6) AS Title 
          FROM _TCOMCalendar 
         ORDER BY LEFT(Solar,6)
         
        INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
        SELECT STUFF(A.Title,5,0,'년') + '월', A.Title, B.Title2, B.TitleSeq2
          FROM #TCOMCalendar AS A 
          JOIN (SELECT '수량' AS Title2, 100 AS TitleSeq2
                UNION ALL 
                SELECT '매출가', 200
                UNION ALL 
                SELECT '원가', 300
               ) AS B ON ( 1 = 1 )
         WHERE ( LEFT(@PlanFrDate,6) <= A.Title AND LEFT(@PlanToDate,6) >= A.Title ) 
         ORDER BY A.Title 

    END 
    
    IF @QueryKind = '10002'
    BEGIN
        INSERT INTO #TCOMCalendar (Title)
        SELECT DISTINCT CONVERT(NCHAR(4), SYear) + CONVERT(NCHAR(1), SQuarter0) AS Title
          FROM _TCOMCalendar AS A 
         WHERE LEFT(@PlanFrDate,6) <= LEFT(A.Solar,6) AND LEFT(@PlanToDate,6) >= LEFT(A.Solar,6)
         ORDER BY TiTle
        
        INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
        SELECT STUFF(A.Title,5,0,'년 ') + '분기', A.Title, B.Title2, B.TitleSeq2
          FROM #TCOMCalendar AS A 
          JOIN (SELECT '수량' AS Title2, 100 AS TitleSeq2
                UNION ALL 
                SELECT '매출가', 200
                UNION ALL 
                SELECT '원가', 300
               ) AS B ON ( 1 = 1 )
         ORDER BY A.Title 
    END
    
    IF @QueryKind = '10003'
    BEGIN
        INSERT INTO #TCOMCalendar (Title)
        SELECT DISTINCT SYear AS Title 
          FROM _TCOMCalendar 
         ORDER BY SYear
         
        INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
        SELECT CONVERT(NCHAR(4),A.Title) + '년', A.Title, B.Title2, B.TitleSeq2
          FROM #TCOMCalendar AS A 
          JOIN (SELECT '수량' AS Title2, 100 AS TitleSeq2
                UNION ALL 
                SELECT '매출가', 200
                UNION ALL 
                SELECT '원가', 300
               ) AS B ON ( 1 = 1 )
         WHERE ( LEFT(@PlanFrDate,4) <= A.Title AND LEFT(@PlanToDate,4) >= A.Title ) 
         ORDER BY A.Title  
    END
        
    UPDATE A
       SET DataBlock = 'DataBlock2',
           COL_SET_INFO = '',
           DataFieldName = 'Results'+ CONVERT(NCHAR(2),ColIDX), 
           DataFieldCd = '', 
           CellType = 1, -- FloatBox
           DataKey = '',
           ControlKey = CASE WHEN @QueryKind = '10001'
                             THEN (CASE WHEN A.TitleSeq = @ClosingNextCostYM 
                                        THEN '' 
                                        ELSE 'DIS'
                                        END
                                  )
                             ELSE 'DIS'
                             END, 
           IsCombo = 0,
           IsComboAddTotal = 0,
           CodeHelpDefault = '',
           CodeHelpParams = '',
           CodeHelpConst = 0,
           IsUseOldValue = '0',
           MaxLength = 100,
           Declength = 0,
           DefaultValue = '',
           MaskAndCaption = '',
           Row = 0,
           ColWidth = 100,
           Formula = '',
           BackColor = -1,
           ForeColor = -1
      FROM #Title AS A 
    
    UPDATE A
       SET Declength = 2
      FROM #Title AS A
     WHERE TitleSeq2 = 100
    
    SELECT * FROM #Title 
    
    CREATE TABLE #FixCol
    (
        RowIdx          INT IDENTITY(0, 1), 
        ItemKind        NVARCHAR(100), 
        ItemKindSeq     INT, 
        ItemNo          NVARCHAR(500), 
        ItemName        NVARCHAR(500), 
        ItemSeq         INT, 
        PlanQty         DECIMAL(19,5), 
        PlanSalesAmt    DECIMAL(19,5), 
        PlanAmt         DECIMAL(19,5), 
        SumQty          DECIMAL(19,5), 
        SumSalesAmt     DECIMAL(19,5), 
        SumAmt          DECIMAL(19,5), 
        InPutYM         NVARCHAR(6), 
        BOMSerl         INT 
    )
        
        SELECT MAX(InPutYM) AS InPutYM, MAX(ItemSeq) AS ItemSeq, MAX(ItemKind) AS ItemKind, MAX(ISNULL(PlanQty,0)) AS PlanQty, MAX(PlanSalesAmt) AS PlanSalesAmt, 
               MAX(PlanAmt) AS PlanAmt, SUM(ISNULL(SumQty,0)) AS SumQty, SUM(ISNULL(SumSalesAmt,0)) AS SumSalesAmt, SUM(ISNULL(SumAmt,0)) AS SumAmt, MAX(PJTSeq) AS PJTSeq, 
               MAX(A.BgtName) AS BgtName, A.BOMSerl 
          INTO #TEMP_FIX
          FROM #TEMP AS A 
         WHERE (A.InPutYM >= @ClosingNextCostYM OR A.InPutYM IS NULL)
         GROUP BY A.ItemKind, A.ItemSeq, A.PJTSeq, A.BOMSerl
        
        SELECT MAX(C.MinorName) AS ItemKind, MAX(A.BgtName) AS ItemNo, CASE WHEN A.ItemKind IN (1000402003, 1000402004) 
                                                                            THEN MAX(D.ResrcName)
                                                                            WHEN A.ItemKind IN (1000402001, 1000402002) 
                                                                            THEN MAX(B.ItemName)
                                                                            WHEN A.ItemKind = 1000402005 
                                                                            THEN MAX(G.FSItemName)
                                                                            END AS ItemName, 
               A.ItemSeq AS ItemSeq, MAX(ISNULL(A.PlanQty,0)) AS PlanQty, A.ItemKind AS ItemKindSeq, 
               MAX(ISNULL(A.PlanSalesAmt,0)) AS PlanSalesAmt, 
               MAX(ISNULL(A.PlanAmt,0)) AS PlanAmt, 
               MAX(ISNULL((CASE WHEN I.Qty IS NOT NULL THEN I.Qty ELSE A.SumQty END),0)) + SUM(ISNULL(E.Qty,0)) - MAX(ISNULL(I.Qty,0)) AS SumQty, 
               MAX(ISNULL((CASE WHEN I.SalesAmt IS NOT NULL THEN I.SalesAmt ELSE A.SumSalesAmt END),0)) + SUM(ISNULL(E.SalesAmt,0)) - MAX(ISNULL(I.SalesAmt,0)) AS SumSalesAmt, 
               MAX(ISNULL((CASE WHEN I.SalesCost IS NOT NULL THEN I.SalesCost ELSE A.SumAmt END),0)) + SUM(ISNULL(E.SalesCost,0)) - MAX(ISNULL(I.SalesCost,0)) AS SumAmt, 
               MAX(ISNULL(A.InPutYM,E.ResultYM)) AS InPutYM, 
               A.PJTSeq AS PJTSeq, 
               ISNULL(A.BOMSerl, 1) AS BOMSerl 
          INTO #FixCol_Sub
          FROM #TEMP_FIX AS A 
          LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) --AND A.ItemKind  IN (1000402003,1000402004) ) 
          LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.ItemKind ) 
          LEFT OUTER JOIN _TPJTResource AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ResrcSeq = A.ItemSeq ) --AND A.ItemKind IN (1000402001,1000402002) )
          --LEFT OUTER JOIN #TEMP AS F ON ( F.ItemKind = A.ItemKind AND F.ItemSeq = A.ItemSeq AND F.PJTSeq = A.PJTSeq AND F.InPutYM > @ClosingNextCostYM AND A.BOMSerl = F.BOMSerl ) 
          LEFT OUTER JOIN DTI_TPJTSalesRateTotal AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq AND E.SMItemType = A.ItemKind AND E.PJTSeq = A.PJTSeq AND E.Serl = A.BomSerl)--AND A.InPutYM = E.ResultYM ) 
          LEFT OUTER JOIN _TCOMFSItem            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND UMFSItemgrp = 2007008 AND G.FSItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN DTI_TPJTSalesRateTotal AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.ItemSeq = A.ItemSeq AND I.SMItemType = A.ItemKind AND I.PJTSeq = A.PJTSeq AND A.InPutYM = I.ResultYM AND I.Serl = A.BOMSerl ) 
         WHERE A.PJTSeq = @PJTSeq 
         GROUP BY A.PJTSeq, A.ItemKind, A.ItemSeq, A.BOMSerl
         ORDER BY ItemName DESC
    
    --select * from #FixCol_Sub 
    --return 
    --select * from DTI_TPJTSalesRateTotal where CompanySeq = 1 and ItemSeq = 2573
    --return 
    IF @QueryKind = '10001'
    BEGIN 
        INSERT INTO #FixCol ( 
                              ItemKind, ItemNo, ItemName, ItemSeq, PlanQty, ItemKindSeq, 
                              PlanSalesAmt, PlanAmt, SumQty, SumSalesAmt, SumAmt, 
                              InPutYM, BOMSerl
                            )
        SELECT ItemKind, ItemNo, ItemName, ItemSeq, PlanQty, ItemKindSeq, 
               PlanSalesAmt, PlanAmt, SumQty, SumSalesAmt, SumAmt, 
               InPutYM, BOMSerl
          FROM #FixCol_Sub 
         ORDER BY ItemKindSeq
    END 
    IF @QueryKind = '10002' 
    BEGIN
        INSERT INTO #FixCol ( 
                              ItemKind, ItemNo, ItemName, ItemSeq, PlanQty, ItemKindSeq, 
                              PlanSalesAmt, PlanAmt, SumQty, SumSalesAmt, SumAmt, 
                              InPutYM, BOMSerl
                            )
        SELECT MAX(A.ItemKind), MAX(A.ItemNo), MAX(A.ItemName), A.ItemSeq, SUM(A.PlanQty), A.ItemKindSeq, 
               SUM(A.PlanSalesAmt), SUM(A.PlanAmt), SUM(A.SumQty), SUM(A.SumSalesAmt), SUM(A.SumAmt), 
               MAX(CONVERT(NCHAR(4), B.SYear) + CONVERT(NCHAR(1), B.SQuarter0)), A.BOMSerl
          FROM #FixCol_Sub AS A 
          LEFT OUTER JOIN (SELECT DISTINCT LEFT(Solar,6) AS Solar, SYear, SQuarter0
                             FROM _TCOMCalendar 
                          ) AS B ON ( LEFT(B.Solar,6) = A.InPutYM ) 
         GROUP BY A.ItemKindSeq, A.ItemSeq, B.SYear, B.SQuarter0, LEFT(B.Solar,6), A.BOMSerl
         ORDER BY ItemKindSeq
    END
    IF @QueryKind = '10003' 
    BEGIN 
        INSERT INTO #FixCol ( 
                              ItemKind, ItemNo, ItemName, ItemSeq, PlanQty, ItemKindSeq, 
                              PlanSalesAmt, PlanAmt, SumQty, SumSalesAmt, SumAmt, 
                              InPutYM, BOMSerl
                            )
        SELECT MAX(ItemKind), MAX(ItemNo), MAX(ItemName), ItemSeq, SUM(PlanQty), ItemKindSeq, 
               SUM(PlanSalesAmt), SUM(PlanAmt), SUM(SumQty), SUM(SumSalesAmt), SUM(SumAmt), 
               LEFT(A.InPutYM,4), A.BOMSerl 
          FROM #FixCol_Sub AS A 
         GROUP BY LEFT(A.InPutYM,4), A.ItemKindSeq, A.ItemSeq, A.BOMSerl 
         ORDER BY ItemKindSeq
    END 
    
    SELECT * FROM #FixCol 
    
    CREATE TABLE #Value
    (
     SumQty      DECIMAL(19, 5), 
     SumSalesAmt DECIMAL(19,5), 
     SumAmt      DECIMAL(19,5),
     ItemKind    INT, 
     ItemSeq     INT, 
     InPutYM     NCHAR(6), 
     BOMSerl     INT 
    )
    
    --INSERT INTO #Value ( SumQty, SumSalesAmt, SumAmt, ItemKind, ItemSeq, InPutYM ) 
    SELECT Qty, SalesAmt, SalesCost, SMItemType, ItemSeq, ResultYM, Serl AS BOMSerl 
      INTO #Value_Sub
      FROM DTI_TPJTSalesRateTotal 
     WHERE CompanySeq = @CompanySeq 
       AND PJTSeq = @PJTSeq 
    --select * from #Value_Sub
    --select * from #TEMP 
    --return 
    -- return 
    INSERT INTO #Value_Sub ( Qty, SalesAmt, SalesCost, SMItemType, ItemSeq, ResultYM, BOMSerl )
    SELECT SUM(ISNULL(ISNULL(E.Qty,A.SumQty),0)), SUM(ISNULL(ISNULL(E.SalesAmt,A.SumSalesAmt),0)), SUM(ISNULL(ISNULL(E.SalesCost,A.SumAmt),0)), A.ItemKind, A.ItemSeq, MAX(A.InPutYM), A.BOMSerl
      FROM #TEMP AS A 
      LEFT OUTER JOIN DTI_TPJTSalesRateTotal AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq AND E.SMItemType = A.ItemKind AND E.PJTSeq = A.PJTSeq AND A.InPutYM = E.ResultYM AND E.Serl = A.BOMSerl ) 
    WHERE InPutYM >= @ClosingNextCostYM
     GROUP BY A.InPutYM, A.ItemSeq, A.ItemKind, A.BOMSerl
--select * from #Value_Sub
--return 
    IF @QueryKind = '10001'
    BEGIN 
        INSERT INTO #Value ( SumQty, SumSalesAmt, SumAmt, ItemKind, ItemSeq, InPutYM, BOMSerl )  
        SELECT Qty, SalesAmt, SalesCost, SMItemType, ItemSeq, ResultYM, BOMSerl 
          FROM #Value_Sub
    END 
    
    IF @QueryKind = '10002'
    BEGIN
        INSERT INTO #Value ( SumQty, SumSalesAmt, SumAmt, ItemKind, ItemSeq, InPutYM ) 
        SELECT SUM(A.Qty), SUM(A.SalesAmt), SUM(A.SalesCost), SMItemType, ItemSeq, MAX(CONVERT(NCHAR(4), B.SYear) + CONVERT(NCHAR(1), B.SQuarter0))
          FROM #Value_Sub AS A 
          LEFT OUTER JOIN (SELECT DISTINCT LEFT(Solar,6) AS Solar, SYear, SQuarter0
                             FROM _TCOMCalendar 
                          ) AS B ON ( LEFT(B.Solar,6) = A.ResultYM ) 
         GROUP BY A.SMItemType, A.ItemSeq, B.SYear, B.SQuarter0, LEFT(B.Solar,6)
    END 
    IF @QueryKind = '10003' 
    BEGIN
        INSERT INTO #Value ( SumQty, SumSalesAmt, SumAmt, ItemKind, ItemSeq, InPutYM )  
        SELECT SUM(Qty), SUM(SalesAmt), SUM(SalesCost), SMItemType, ItemSeq, LEFT(ResultYM,4) 
          FROM #Value_Sub
         GROUP BY SMItemType, ItemSeq, LEFT(ResultYM,4)
    END 
    
    SELECT B.RowIdx, 
           A.ColIdx, 
           CASE WHEN TitleSeq2 = 100 
                THEN C.SumQty 
                WHEN TitleSeq2 = 200 
                THEN C.SumSalesAmt 
                WHEN TitleSeq2 = 300 
                THEN C.SumAmt 
                ELSE 0
                END AS Results
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.InPutYM ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq AND B.ItemKindSeq = C.ItemKind AND B.BOMSerl = C.BOMSerl ) 
    ORDER BY A.ColIdx, B.RowIdx
    
    RETURN
GO
exec DTI_SPJTSalesRateTotalListCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PJTSeq>140</PJTSeq>
    <PlanFrDate>20121217</PlanFrDate>
    <PlanToDate>20140130</PlanToDate>
    <BizUnit>1</BizUnit>
    <PJTTypeSeq>1</PJTTypeSeq>
    <PJTTypeName>공공프로젝트</PJTTypeName>
    <ResultStdUnitName>Man/Month</ResultStdUnitName>
    <QueryKind>10001</QueryKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020606,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1017344