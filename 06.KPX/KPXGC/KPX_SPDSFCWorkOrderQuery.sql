
IF OBJECT_ID('KPX_SPDSFCWorkOrderQuery') IS NOT NULL
    DROP PROC KPX_SPDSFCWorkOrderQuery
GO 

-- v2015.04.09 

-- 작업지시조회_KPX by이재천
/************************************************************  
  설  명 - 작업지시조회    
  작성일 - 2008년 10월 16일     
  작성자 - 정동혁    
  수정일 - 2009.12.28 BY 박소연    
           2009.12.29 BY 박소연 워크센터명 조회조건 수정    
           2010.01.04 BY 박소연 생산사양수정    
           2010.01.05 BY 박소연 생산계획번호 조회조건 수정    
           2010.01.21 BY 박소연 반제품의 모제품을 찾아 모제품의 생산사양 가져오기    
           2010.07.21 BY 박소연 양품/불량수량    
           2010.11.24 BY 정영훈 거래처 품번 / 품명 / 규격 추가    
           2010.12.09 BY 송기연 주야구분 추가 (생산계획 작업지시분할 화면에서 입력된 주야 구분 조회)    
           2010.12.26 BY 김현   최종검사불량재작업,입고후불량재작업건의 LotNo 추적해서 가져오기    
           2011. 3. 9 BY 김현   거래처를 수주에서 흘러오지 않은 건은 생산의뢰에서 가져오도록 수정    
           2011.04.25 BY 김서진 납기일 추가    
           2011.11.22 BY 김세호 :: 지시수량 0 인건 조회 안되도록 막음( 파낙스이텍 배치분할 관련 0인건 생겨서 임시로 조건 추가)    
           2012.1.5 hkim :: 최종수정자 컬럼 추가    
           2012.01.10 BY 김세호 :: 거래처명 거래처별OEM품목등록에 등록안되있으면 생산의뢰품목의 거래처명 조회되도록 수정 
           2012.05.24 BY 김세호 :: 재작업건도 원천작업지시건의 거래처 조회되도록 수정 및 거래처 가져오는 우선순위 수정 
                                  (1. 거래처별 OEM품목 -> 2. 생산의뢰  -> 3. 수주)
           2013.01.08 BY 김수창 :: BOM차수명 추가 _TPDBOMManagement 에서 ItemBOMRevRemark 출력 빈값일시 기존 BOM차수명 나오도록 수정
           2013.05.22 BY 김권우 :: 작업지시조회 화면에서 계획번호로 조회 시 해당 품목의 데이터만 표기 되도록 수정
           2014.04.04 BY 김용현 :: 재작업지시건이 있으면, 원천작업지시건도 담는다 부분에서 위에 템프 #TPDSFCWorkOrder 에 담을 때,
                                   컬럼 2개가 추가 되어서 INSERT 컬럼수가 안맞아서 오류나는 부분 수정
  ************************************************************/    
 CREATE PROC KPX_SPDSFCWorkOrderQuery   
      @xmlDocument    NVARCHAR(MAX) ,                
      @xmlFlags       INT = 0,                
      @ServiceSeq     INT = 0,                
      @WorkingTag     NVARCHAR(10)= '',                      
      @CompanySeq     INT = 1,                
      @LanguageSeq    INT = 1,                
      @UserSeq        INT = 0,                
      @PgmSeq         INT = 0      
  AS             
      CREATE TABLE #TMP_PROGRESSTABLE          
      (          
          IDOrder             INT,          
          TABLENAME           NVARCHAR(100)          
      )         
      
      CREATE TABLE #TCOMProgressTracking          
      (    
          IDX_NO              INT,          
          IDOrder             INT,          
          Seq                 INT,          
          Serl                INT,          
          SubSerl             INT,          
          Qty                 DECIMAL(19, 5),          
          STDQty              DECIMAL(19, 5),          
          Amt                 DECIMAL(19, 5)   ,          
          VAT                 DECIMAL(19, 5)          
      )          
      
      DECLARE @docHandle          INT,    
              @WorkOrderSeq       INT,    
              @WorkOrderSerl      INT,    
              @FactUnit           INT,    
              @DeptSeq            INT,    
              @ChainGoodsSeq      INT,            -- 연산품조회이면 1, 아니면 0    
              @ProgStatus         INT,    
              @WorkType           INT,    
              --@DeptName           NVARCHAR(100),    
              @WorkOrderNo     NVARCHAR(20),    
              @ProdPlanNo         NVARCHAR(20),    
              @GoodItemName       NVARCHAR(200),    
              @GoodItemNo         NVARCHAR(100),    
              @GoodItemSpec       NVARCHAR(100),    
              @WorkCenterSeq      INT,    
              @WorkCenterName     NVARCHAR(200),    
              @ProcName           NVARCHAR(100),    
              @WorkOrderDate      NCHAR(8),    
              @WorkOrderDateTo    NCHAR(8),    
              @WorkDate         NCHAR(8),    
              @WorkDateTo         NCHAR(8),    
              -- 프로젝트 여부 판단 변수    
              @Cnt                INT            ,    
              @Seq                INT            ,    
              @WHSeq              INT            ,    
              @PJTName            NVARCHAR(60)   ,    
              @PJTNo              NVARCHAR(40)  ,    
              @CustSeq            INT            , -- 20091228 박소연 추가    
              @PoNo               NVARCHAR(40)   ,  -- 20091228 박소연 추가    
              @PlanEndDateFr      NCHAR(8), 
              @PlanEndDateTo      NCHAR(8)

                       
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
      
      SELECT  @WorkOrderSeq       = ISNULL(WorkOrderSeq       ,0),    
              @WorkOrderSerl      = ISNULL(WorkOrderSerl      ,0),    
              @FactUnit           = ISNULL(FactUnit           ,0),    
              @DeptSeq            = ISNULL(DeptSeq            ,0),    
              @ChainGoodsSeq      = ISNULL(ChainGoodsSeq      ,0),    
            @ProgStatus         = ISNULL(ProgStatus         ,0),    
              @WHSeq              = ISNULL(WHSeq              ,0),    
              @WorkType           = ISNULL(WorkType           ,0),    
       --@DeptName           = ISNULL(DeptName           , ''),    
              @WorkOrderNo     = ISNULL(WorkOrderNo        , ''),    
              @ProdPlanNo         = ISNULL(ProdPlanNo         , ''),    
              @GoodItemName       = ISNULL(GoodItemName       , ''),    
              @GoodItemNo         = ISNULL(GoodItemNo         , ''),    
              @GoodItemSpec       = ISNULL(GoodItemSpec       , ''),    
              @WorkCenterSeq      = ISNULL(WorkCenterSeq      ,0),    
              @WorkCenterName     = ISNULL(WorkCenterName     , ''),    
              @ProcName           = ISNULL(ProcName           , ''),    
              @WorkOrderDate     = ISNULL(WorkOrderDate      , ''),    
              @WorkOrderDateTo    = ISNULL(WorkOrderDateTo    , ''),    
              @WorkDate         = ISNULL(WorkDate           , ''),    
              @WorkDateTo         = ISNULL(WorkDateTo         , ''),                
              @PJTName         = ISNULL(PJTName            , ''),        -- 프로젝트 여부 추가    09.1.3 김현    
              @PJTNo             = ISNULL(PJTNo              , ''),        -- 프로젝트 여부 추가    09.1.3 김현    
              @CustSeq            = ISNULL(CustSeq           ,0),          -- 20091228 박소연 추가    
              @PoNo               = ISNULL(PoNo               , ''),          -- 20091228 박소연 추가    
              @PlanEndDateFr      = ISNULL(PlanEndDateFr, ''), 
              @PlanEndDateTo      = ISNULL(PlanEndDateTo, '') 
              
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
        WITH (
              WorkOrderSeq        INT,    
              WorkOrderSerl       INT,    
              FactUnit            INT,    
              DeptSeq             INT,    
              ChainGoodsSeq       INT,    
              ProgStatus          INT,    
              WHSeq               INT,    
              WorkType            INT,    
              --DeptName            NVARCHAR(100),    
              WorkOrderNo         NVARCHAR(20),    
              ProdPlanNo         NVARCHAR(20),    
              GoodItemName        NVARCHAR(200),    
              GoodItemNo          NVARCHAR(100),    
              GoodItemSpec        NVARCHAR(100),    
              WorkCenterSeq       INT,    
              WorkCenterName      NVARCHAR(200),    
              ProcName            NVARCHAR(100),    
              WorkOrderDate       NCHAR(8),    
              WorkOrderDateTo     NCHAR(8),    
              WorkDate         NCHAR(8),    
              WorkDateTo         NCHAR(8),    
              PJTName             NVARCHAR(60),                -- 프로젝트 여부 추가    09.1.3 김현    
              PJTNo               NVARCHAR(40),                -- 프로젝트 여부 추가    09.1.3 김현    
              CustSeq             INT,                         -- 20091228 박소연 추가    
              PoNo                NVARCHAR(40), 
              PlanEndDateFr      NCHAR(8),
              PlanEndDateTo      NCHAR(8)
             )                -- 20091228 박소연 추가    
      
      -- 조회조건을 임시테이블로 생성    
      CREATE TABLE #TPDSFCProdOrder (WorkingTag NCHAR(1) NULL)      
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCProdOrder'         
      IF @@ERROR <> 0 RETURN        
    
    IF @PlanEndDateTo = '' SELECT @PlanEndDateTo = '99991231'
  --select @WorkOrderDate, @WorkOrderDateTo    
  --    IF ISNULL(@WorkOrderDate,'') = '' SELECT @WorkOrderDate = '00000000'    
      
      ---- #TempTable 에 담는 방식을 INTO 가 아닌 생성후에 넣어주는 형태로 변경 ---- 2014.04.04 김용현
      CREATE TABLE #TPDSFCWorkOrder  
      (  
         WorkOrderSeq        INT                 ,       
         FactUnit            INT                 ,  
         WorkOrderNo         NVARCHAR(30)        ,  
         WorkOrderSerl       INT                 ,  
         WorkOrderDate       NCHAR(8)            ,  
         ProdPlanSeq         INT                 ,  
         WorkPlanSerl        INT                 ,  
         DailyWorkPlanSerl   INT                 ,  
         WorkCenterSeq       INT                 ,  
         GoodItemSeq         INT                 ,  
         ProcSeq             INT                 ,  
         AssyItemSeq         INT                 ,  
         ProdUnitSeq         INT                 ,  
         OrderQty            DECIMAL(19,5)       ,  
         ProgressQty         DECIMAL(19,5)       ,  
         OKQty               DECIMAL(19,5)       ,  
         BadQty              DECIMAL(19,5)       ,  
         ProdQty             DECIMAL(19,5)       ,  
         MatProgQty          DECIMAL(19,5)       ,  
         ProgStatus          INT                 ,  
         StdUnitQty          DECIMAL(19,5)       ,  
         WorkDate            NCHAR(8)            ,  
         WorkStartTime       NCHAR(4)            ,  
         WorkEndTime         NCHAR(4)            ,  
         ChainGoodsSeq       INT                 ,  
         WorkType            INT                  ,  
         DeptSeq             INT                 ,  
         ItemUnitSeq         INT                 ,  
         ProcRev             NCHAR(2)            ,  
         ItemBomRev          NCHAR(2)            ,  
         ItemBomRevName      NVARCHAR(2)         ,  
         Remark              NVARCHAR(200)       ,  
         IsProcQC            NCHAR(1)            ,  
         IsLastProc          NCHAR(1)            ,  
         IsPjt               NCHAR(1)            ,  
         PjtSeq              INT                 ,  
         WBSSeq              INT                 ,  
         ProdOrderSeq        INT                 ,  
         IsCancel            NCHAR(1)            ,  
         ProcNo              INT                 ,  
         Priority            INT                 ,  
         GoodItemName        NVARCHAR(200)       ,  
         GoodItemNo          NVARCHAR(100)       ,  
         GoodItemSpec        NVARCHAR(100)       ,  
         AssyItemName        NVARCHAR(200)       ,  
         AssyItemNo          NVARCHAR(100)       ,  
         AssyItemSpec        NVARCHAR(100)       ,  
         DeptName            NVARCHAR(200)       ,  
         ItemUnitName        NVARCHAR(30)        ,  
         ProdUnitName        NVARCHAR(30)        ,  
         WorkCenterName      NVARCHAR(100)       ,  
         ProcName            NVARCHAR(50)        ,  
         ProcRevName         NVARCHAR(40)        ,  
         ChainGoodsName      NVARCHAR(200)       ,  
         ChainGoodsNo        NVARCHAR(100)       ,  
         IDX_NO              INT IDENTITY(1, 1)  ,  
         PJTName             NVARCHAR(60)        ,  
         PJTNo               NVARCHAR(40)        ,  
         WBSName             NVARCHAR(80)        ,  
         ProdPlanNo          NVARCHAR(30)        ,  
         ProdPlanQty         DECIMAL(19,5)       ,  
         WHName              NVARCHAR(100)       ,  
         WorkerQty           DECIMAL(19,5)       ,  
         IsConfirm           NCHAR(1)            ,  
         WorkCond1           NVARCHAR(500)       ,  
         WorkCond2           NVARCHAR(500)       ,  
         WorkCond3           NVARCHAR(500)       ,  
         WorkCond4           DECIMAL(19,5)       ,  
         WorkCond5           DECIMAL(19,5)       ,  
         WorkCond6           DECIMAL(19,5)       ,  
         WorkCond7           DECIMAL(19,5)       ,  
         WorkTimeGroupName   NVARCHAR(100)       ,  
         RealLotNo      NVARCHAR(100)       ,  
         LastUserName        NVARCHAR(40)        ,  
         ProdRemark          NVARCHAR(200)       ,  
         LastDateTime        DATETIME            ,  
         EmpSeq              INT                  ,  
         EmpName             NVARCHAR(100)  , 
         ProdPlanDate       NCHAR(8), 
         PlanSrtDate        NCHAR(8), 
         PlanEndDate        NCHAR(8) , 
         IsMatInput         NCHAR(1), 
         IsGoodIn           NCHAR(1), 
         ReportEmpName      NVARCHAR(100), 
         ReportEmpSeq       INT 
         
      )  
     
      IF @WorkOrderSeq > 0  OR @WorkingTag = 'P' -- 점프해서 온 경우 다른 조건은 뺀다.    
      BEGIN    
      
          SELECT  @FactUnit           = 0,    
                  @DeptSeq            = 0,    
                  @WHSeq              = 0,    
                  --@DeptName           = '',    
                  @DeptSeq            = 0,    
                  @WorkOrderNo     = '',    
                  @ProdPlanNo         = '',    
                  @GoodItemName       = '',    
                  @GoodItemNo         = '',    
                  @GoodItemSpec       = '',    
                  @WorkCenterSeq      = 0,    
            @ProcName           = '',    
                  @WorkDate         = '',    
                  @WorkDateTo         = '',      
                @WorkOrderDate      = '',      
                  @WorkOrderDateTo    = ''    
      
      END    
      
      
      INSERT INTO #TPDSFCWorkOrder  
         (  
             WorkOrderSeq        , FactUnit            , WorkOrderNo         , WorkOrderSerl       , WorkOrderDate       ,   
             ProdPlanSeq         , WorkPlanSerl        , DailyWorkPlanSerl   , WorkCenterSeq       , GoodItemSeq         ,   
             ProcSeq             , AssyItemSeq         , ProdUnitSeq         , OrderQty            , ProgressQty         ,   
             OKQty               , BadQty              , ProdQty             , MatProgQty          , ProgStatus          ,   
               StdUnitQty           , WorkDate            , WorkStartTime       , WorkEndTime         , ChainGoodsSeq       ,   
             WorkType            , DeptSeq             , ItemUnitSeq         , ProcRev             , ItemBomRev          ,   
             ItemBomRevName      , Remark              , IsProcQC            , IsLastProc          , IsPjt               ,   
             PjtSeq              , WBSSeq              , ProdOrderSeq        , IsCancel            , ProcNo              ,   
             Priority            , GoodItemName        , GoodItemNo          , GoodItemSpec        , AssyItemName        ,   
             AssyItemNo          , AssyItemSpec        , DeptName            , ItemUnitName        , ProdUnitName        ,   
             WorkCenterName      , ProcName            , ProcRevName         , ChainGoodsName      , ChainGoodsNo        ,   
             PJTName             , PJTNo               , WBSName             , ProdPlanNo          , ProdPlanQty         ,   
             WHName              , WorkerQty           , IsConfirm           , WorkCond1           , WorkCond2           ,   
             WorkCond3           , WorkCond4           , WorkCond5           , WorkCond6           , WorkCond7           ,   
             WorkTimeGroupName   , RealLotNo           , LastUserName        , ProdRemark          , LastDateTime        ,   
             EmpSeq              , EmpName             , ProdPlanDate       , PlanSrtDate          , PlanEndDate         , 
             IsMatInput          , IsGoodIn            , ReportEmpName      , ReportEmpSeq  
             
             
             
             
             
         ) 
      SELECT   A.WorkOrderSeq    
              ,A.FactUnit    
              ,A.WorkOrderNo    
              ,A.WorkOrderSerl    
              ,A.WorkOrderDate    
              ,A.ProdPlanSeq    
              ,A.WorkPlanSerl    
              ,A.DailyWorkPlanSerl    
              ,A.WorkCenterSeq    
              ,A.GoodItemSeq    
              ,A.ProcSeq    
              ,A.AssyItemSeq    
              ,A.ProdUnitSeq    
              ,A.OrderQty    
              ,CONVERT(DECIMAL(19,5),0) AS ProgressQty      -- 생산수량    
              ,CONVERT(DECIMAL(19,5),0) AS OKQty            -- 양품수량    
              ,CONVERT(DECIMAL(19,5),0) AS BadQty           -- 불량수량    
              ,A.OrderQty               AS ProdQty          -- 잔량    
              ,CONVERT(DECIMAL(19,5),0) AS MatProgQty     -- 자재출고진행수량    
              ,6036001                  AS ProgStatus       -- 생산진행상태    
              ,A.StdUnitQty    
              ,A.WorkDate    
              ,A.WorkStartTime    
              ,A.WorkEndTime    
              ,A.ChainGoodsSeq    
              ,A.WorkType    
              ,A.DeptSeq    
              ,A.ItemUnitSeq    
      
              ,A.ProcRev    
              ,A.ItemBomRev    
              ,CASE WHEN ISNULL(BM.ItemBOMRevRemark,'') = '' THEN  A.ItemBomRev ELSE BM.ItemBOMRevRemark END  AS ItemBomRevName      -- ECO 적용내역이에서 가져오지않고 그냥BOM차수 그대로 조회하도록        12.07.25 BY 김세호
 --             ,ISNULL((SELECT BOMRevName FROM _TPDBOMECOApply WHERE CompanySeq = A.CompanySeq AND ItemSeq = A.GoodItemSeq AND chgBOMRev = A.ItemBomRev and IsRevUp = '1' AND IsApplied = '1'), A.ItemBomRev) AS ItemBomRevName    
              ,A.Remark    
              ,A.IsProcQC    
              ,A.IsLastProc    
              ,A.IsPjt    
              ,A.PjtSeq    
              ,A.WBSSeq    
              ,A.ProdOrderSeq    
              ,A.IsCancel    
              ,A.ProcNo    
              ,A.Priority    
      
              ,I.ItemName             AS GoodItemName    
              ,I.ItemNo               AS GoodItemNo    
              ,I.Spec                 AS GoodItemSpec    
              ,S.ItemName             AS AssyItemName    
              ,S.ItemNo               AS AssyItemNo    
              ,S.Spec                 AS AssyItemSpec    
              ,D.DeptName          
              ,U.UnitName             AS ItemUnitName    
              ,Y.UnitName             AS ProdUnitName    
              ,W.WorkCenterName       AS WorkCenterName    
              ,P.ProcName             AS ProcName    
              ,ISNULL(V.ProcRevName,A.ProcRev)           AS ProcRevName    
      
              ,C.ChainGoodsName       AS ChainGoodsName    
              ,C.ChainGoodsNo         AS ChainGoodsNo    
              ,F.PJTName              AS PJTName    -- 프로젝트 여부 추가 09.1.3 김현    
              ,F.PJTNo                AS PJTNo      -- 프로젝트 여부 추가 09.1.3 김현    
              ,G.WBSName              AS WBSName    -- 프로젝트 여부 추가 09.1.3 김현    
              ,M.ProdPlanNo           AS ProdPlanNo    
              ,M.ProdQty              AS ProdPlanQty    
              ,WH.WHName              AS WHName    
              ,(Select SUM(CurrWorkerCnt) from _TPDBaseWorkCenterEmp where CompanySeq = 14 AND WorkCenterSeq = A.WorkCenterSeq)   AS WorkerQty    
              ,ISNULL((SELECT CONVERT(NCHAR(1),CfmCode) FROM _TPDSFCWorkOrder_Confirm WITH(NOLOCK)     
                                                           WHERE CompanySeq = @CompanySeq    
                                                             AND CfmSeq = A.WorkOrderSeq    
                                                             AND CfmSerl = A.WorkOrderSerl),'0')         AS IsConfirm    
              ,A.WorkCond1    
              ,A.WorkCond2    
              ,A.WorkCond3    
              ,A.WorkCond4    
              ,A.WorkCond5    
              ,A.WorkCond6    
              ,A.WorkCond7    
              ,ISNULL((SELECT MinorName FROM _TDAUMinor where CompanySeq = @CompanySeq AND A.WorkTimeGroup = MinorSeq),'')  AS WorkTimeGroupName -- 송기연 추가    
              ,CONVERT(NVARCHAR(50), '') AS RealLotNo     -- 2010. 12. 26 hkim 추가(불량재작업건 LotNo 추적위해)    
              ,LU.UserName AS LastUserName  
              ,M.Remark    AS ProdRemark
              ,A.LastDateTime AS LastDateTime  
              ,A.EmpSeq       AS EmpSeq   -- 20140103 김용현추가
              ,Emp.EmpName     AS EmpName  -- 20140103 김용현추가
              ,M.ProdPlanDate 
              ,M.SrtDate 
              ,M.EndDate 
              ,CASE WHEN EXISTS (SELECT 1 FROM _TPDSFCMatinput WHERE CompanySeq = @CompanySeq AND WorkReportSeq = ZZ.WorkReportSeq) THEN '1' ELSE '0'END AS IsMatInput 
              ,CASE WHEN EXISTS (SELECT 1 FROM _TPDSFCGoodIn WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WorkReportSeq = ZZ.WorkReportSeq) THEN '1' ELSE '0' END AS IsGoodIn 
              ,ZZ.EmpName
              ,ZZ.EmpSeq 
        FROM  _TPDSFCWorkOrder            AS A WITH(NOLOCK)     
          LEFT OUTER JOIN _TDAItem        AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq    
                    AND A.GoodItemSeq  = I.ItemSeq    
          LEFT OUTER JOIN _TDAItem        AS S WITH(NOLOCK) ON A.CompanySeq   = S.CompanySeq    
                                AND A.AssyItemSeq  = S.ItemSeq    
          LEFT OUTER JOIN _TDAUnit        AS U WITH(NOLOCK) ON A.CompanySeq   = U.CompanySeq    
                                                           AND A.ItemUnitSeq  = U.UnitSeq    
          LEFT OUTER JOIN _TDAUnit        AS Y WITH(NOLOCK) ON A.CompanySeq   = Y.CompanySeq    
                                     AND A.ProdUnitSeq  = Y.UnitSeq    
      
          LEFT OUTER JOIN _TDADept        AS D WITH(NOLOCK) ON A.CompanySeq   = D.CompanySeq    
                                                           AND A.DeptSeq      = D.DeptSeq    
          LEFT OUTER JOIN _TPDBaseWorkCenter  AS W WITH(NOLOCK) ON A.CompanySeq   = W.CompanySeq    
                                                           AND A.WorkCenterSeq      = W.WorkCenterSeq    
          LEFT OUTER JOIN _TPDBaseProcess  AS P WITH(NOLOCK) ON A.CompanySeq   = P.CompanySeq    
                                                           AND A.ProcSeq      = P.ProcSeq    
          LEFT OUTER JOIN _TPDROUItemProcRev  AS V WITH(NOLOCK) ON A.CompanySeq   = V.CompanySeq    
                                                           AND A.GoodItemSeq      = V.ItemSeq    
                                                           AND A.ProcRev          = V.ProcRev    
          LEFT OUTER JOIN _TPDBOMChainProd    AS C WITH(NOLOCK) ON A.CompanySeq   = C.CompanySeq    
                                                           AND A.ChainGoodsSeq    = C.ChainGoodsSeq    
          LEFT OUTER JOIN _TPJTProject    AS F WITH(NOLOCK) ON A.CompanySeq   = F.CompanySeq            -- 프로젝트 여부 추가 09.1.3 김현    
                                                           AND A.PJTSeq       = F.PJTSeq    
          LEFT OUTER JOIN _TPJTWBS        AS G WITH(NOLOCK) ON A.CompanySeq   = G.CompanySeq           -- 프로젝트 여부 추가 09.1.3 김현    
                                                           AND A.PJTSeq       = G.PJTSeq    
                                                           AND A.WBSSeq       = G.WBSSeq    
          LEFT OUTER JOIN _TPDMPSDailyProdPlan AS M WITH(NOLOCK) ON A.CompanySeq   = M.CompanySeq     
                                                           AND A.ProdPlanSeq       = M.ProdPlanSeq
          LEFT OUTER JOIN _TPDBOMManagement    AS BM WITH(NOLOCK) ON A.CompanySeq = BM.CompanySeq
                                                                 AND M.ItemSeq    = BM.ItemSeq
                                                                 AND M.BOMRev     = BM.ItemBomRev
          LEFT OUTER JOIN _TDAWH          AS WH WITH(NOLOCK) ON A.CompanySeq   = WH.CompanySeq     
                                                            AND W.FieldWhSeq = WH.WHSeq    
          LEFT OUTER JOIN _TCAUser        AS LU WITH(NOLOCK) ON A.CompanySeq = LU.CompanySeq    
                                                            AND A.LastUserSeq = LU.UserSeq    
          LEFT OUTER JOIN _TDAEmp         AS EMP WITH(NOLOCK) ON A.EmpSeq     = EMP.EmpSeq
                                                             AND A.CompanySeq = EMP.CompanySeq 
          OUTER APPLY (
                        SELECT TOP 1 Z.WorkReportSeq, Z.EmpSeq, Y.EmpName
                          FROM _TPDSFCWorkReport AS Z 
                          LEFT OUTER JOIN _TDAEmp AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.EmpSeq = Z.EmpSeq ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkOrderSeq = A.WorkOrderSeq 
                           AND Z.WorkOrderSerl = A.WorkOrderSerl 
                     ) AS ZZ 
       WHERE  A.CompanySeq        = @CompanySeq     
         AND  (@WorkOrderSeq      = 0     OR A.WorkOrderSeq   = @WorkOrderSeq)    
         AND  (@WorkOrderSerl     = 0     OR A.WorkOrderSerl  = @WorkOrderSerl)    
         AND  (@WorkOrderNo       = ''    OR A.WorkOrderNo    LIKE @WorkOrderNo + '%')    
         AND  (@FactUnit          = 0     OR A.FactUnit       = @FactUnit)    
         AND  (@DeptSeq           = 0     OR A.DeptSeq        = @DeptSeq)    
         --AND  (@DeptName          = ''    OR D.DeptName       LIKE @DeptName + '%')    
         AND  (@WorkDate          = ''    OR A.WorkDate       >= @WorkDate)    
         AND  (@WorkDateTo        = ''    OR A.WorkDate       <= @WorkDateTo)    
         AND  (@WorkOrderDate  = ''    OR A.WorkOrderDate  >= @WorkOrderDate)    
         AND  (@WorkOrderDateTo   = ''    OR A.WorkOrderDate  <= @WorkOrderDateTo)    
         AND  (@WorkOrderNo       = ''    OR A.WorkOrderNo    LIKE @WorkOrderNo + '%')    
             
         AND  (@GoodItemName      = ''    OR I.ItemName       LIKE @GoodItemName + '%')    
         AND  (@GoodItemNo        = ''    OR I.ItemNo         LIKE @GoodItemNo + '%')    
         AND  (@GoodItemSpec      = ''    OR I.Spec           LIKE @GoodItemSpec + '%')    
         AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
         AND  (@ProcName          = ''    OR P.ProcName       LIKE @ProcName + '%')    
             
         AND  (@ProdPlanNo        = ''    OR ISNULL(M.ProdPlanNo, '')       LIKE @ProdPlanNo + '%') -- 20100105 박소연 수정    
         AND  ((@ChainGoodsSeq > 0 AND A.ChainGoodsSeq > 0)     OR A.ChainGoodsSeq  = @ChainGoodsSeq) -- @ChainGoodsSeq : 연산품조회이면 1, 아니면 0    
         AND  (@PJTName           = ''    OR F.PJTName        LIKE @PJTName + '%')                -- 프로젝트 여부 추가 09.1.3 김현    
         AND  (@PJTNo            = ''    OR F.PJTNo          LIKE @PJTNo   + '%')                -- 프로젝트 여부 추가 09.1.3 김현    
         AND  (@WHSeq             = 0     OR W.FieldWhSeq     = @WHSeq)    
         AND  (@WorkingTag <> 'P' OR EXISTS (SELECT 1 FROM #TPDSFCProdOrder WHERE ProdOrderSeq = A.ProdOrderSeq))    
         AND  (@PgmSeq            IN (1009,5563)  OR W.SMWorkCenterType   IN (6011001,6011002))  -- 작업지시입력화면에서는 모두 보이고 작업지시조회 화면에서는 외주는 제외    
         AND (@WorkType          = 0     OR A.WorkType       = @WorkType)
         AND (M.EndDate BETWEEN @PlanEndDateFr AND @PlanEndDateTo) 
     
  
      -- 재작업지시건이 있으면, 원천작업지시건도 담는다
      --(_SCOMSourceTracking 하여 원천작업지시건의 거래처 가져오기 위해. 최종조회시에는 제외됨)  -- 12.06.01 BY 김세호
     IF EXISTS(SELECT 1  
                 FROM #TPDSFCWorkOrder AS A  
                   JOIN #TPDSFCWorkOrder AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                WHERE A.WorkType IN (6041003, 6041009))  
     BEGIN  
         INSERT #TPDSFCWorkOrder(WorkOrderSeq, FactUnit, WorkOrderNo, WorkOrderSerl, GoodItemSeq, WorkDate)  
         SELECT B.WorkOrderSeq, 0, '0', MIN(B.WorkOrderSerl), B.GoodItemSeq, MIN(B.WorkDate)  
           FROM #TPDSFCWorkOrder AS A  
             JOIN _TPDSFCWorkORder AS B WITH(NOLOCK) ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                    AND B.CompanySeq   = @CompanySeq  
          WHERE A.WorkType IN (6041003, 6041009)  
            AND  B.WorkType IN (6041001)  
          GROUP BY B.WorkOrderSeq, B.GoodItemSeq  
     END  
  
      -- 생산진행상태.    
      INSERT #TMP_PROGRESSTABLE    
      SELECT 1, '_TPDSFCWorkReport'    
      UNION    
      SELECT 2, '_TPDMMOutReqGood'    
          
      
      EXEC _SCOMProgressTracking  @CompanySeq, '_TPDSFCWorkOrder', '#TPDSFCWorkOrder','WorkOrderSeq', 'WorkOrderSerl',''    
      
      
      SELECT A.IDX_NO, A.IDOrder, SUM(A.Qty) AS Qty, SUM(C.OKQty) AS OKQty, SUM(C.BadQty) AS BadQty    
        INTO #TCOMProgressTrackingSUM    
        FROM #TCOMProgressTracking      AS A    
             JOIN _TPDSFCWorkReport     AS C ON C.CompanySeq = @CompanySeq -- 양품/불량수량 20100721 박소연 추가    
                                            AND C.WorkReportSeq = A.Seq    
       GROUP BY IDX_NO, IDOrder    
      
      
      UPDATE #TPDSFCWorkOrder    
         SET ProgressQty = ISNULL(B.Qty, 0)  ,    
             OKQty       = ISNULL(B.OKQty, 0),    
             BadQty      = ISNULL(B.BadQty, 0),    
             ProdQty     = CASE --WHEN A.WorkType = 6041004 AND ISNULL(B.Qty,0) - A.OrderQty <= 0 THEN 0     
                                --WHEN A.WorkType = 6041004 AND ISNULL(B.Qty,0) - A.OrderQty > 0 THEN  A.OrderQty - ISNULL(B.Qty,0)    
                                WHEN A.OrderQty - ISNULL(B.Qty,0) <= 0 THEN 0     
                                ELSE A.OrderQty - ISNULL(B.Qty,0)     
                           END,    
             ProgStatus  = CASE WHEN A.IsCancel = '1' THEN 6036005 -- 중단    
                                WHEN EXISTS(SELECT 1 
                                              FROM _TPDSFCWorkReport AS A1 WITH(NOLOCK) 
                                                   JOIN _TPDSFCGoodIn AS B1 WITH(NOLOCK) ON A1.WorkReportSeq = B1.WorkReportSeq
                                                                                        AND A1.CompanySeq    = B1.CompanySeq
                                             WHERE A1.CompanySeq       = @CompanySeq 
                        AND A1.WorkOrderSeq  = A.WorkOrderSeq 
                                               AND A1.WorkOrderSerl = A.WorkOrderSerl
                                               AND B1.IsWorkOrderEnd = '1') THEN 6036004 --완료     
                                -- 2010.11.19 정동혁수정. 생산입고화면의 작업지시완료에 체크를 하게되면 작지수량만큼 생산이 진행되지 않더라도 해당작지를 완료로 처리한다.     
                                WHEN ABS(A.OrderQty) > ABS(B.Qty) THEN 6036003 -- 진행중    
                                WHEN ABS(A.OrderQty) <= ABS(B.Qty) THEN 6036004 --완료    
                                WHEN A.IsConfirm = '1' THEN 6036002   -- 확정    
                                ELSE 6036001 -- 작성    
                           END     
        FROM #TPDSFCWorkOrder                      AS A    
          LEFT OUTER JOIN #TCOMProgressTrackingSUM AS B ON A.IDX_NO = B.IDX_NO    
                                                       AND B.IDOrder = 1    
  
      
      UPDATE #TPDSFCWorkOrder    
         SET MatProgQty = B.Qty     
        FROM #TPDSFCWorkOrder             AS A    
          JOIN #TCOMProgressTrackingSUM   AS B ON A.IDX_NO = B.IDX_NO    
                                              AND B.IDOrder = 2    
      
  /***********[PoNo가져오기]원천 가져오기 시작 20091228 박소연 추가 **************/      
        
      -- 원천테이블        
      CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))                
          
      -- 원천 데이터 테이블        
      CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,                
                                        Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))                      
          
        
      INSERT #TMP_SOURCETABLE          
         
       SELECT 2, '_TPDMPSProdReqItem'            -- 생산의뢰      
      union    
      SELECT 3, '_TSLOrderItem'               -- 수주      
      UNION      
      SELECT 4, '_TPDQAAfterInBadReworkItem'  -- 입고후 불량처리    
      UNION     
      SELECT 5, '_TPDQCLastProcBad'           -- 최종검사불량    
          
      
        
      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDSFCWorkOrder', '#TPDSFCWorkOrder','WorkOrderSeq', 'WorkOrderSerl',''     
        
      SELECT X.IDX_NO ,      
             X.ProdPlanSeq,    
             ISNULL(C.OrderNo,'') AS SoNo ,      
             ISNULL(C.PONo   ,'') AS PoNo ,    
             ISNULL(C.CustSeq, 0) AS CustSeq,        
             ISNULL(A.Seq, 0) AS OrderSeq,    
             ISNULL(A.Serl, 0) AS OrderSerl,
             ISNULL(D.ItemSeq, 0) AS ItemSeq     
        INTO #SOInfo      
        FROM #TPDSFCWorkOrder AS X Left Outer JOIN #TCOMSourceTracking AS A ON X.IDX_NO = A.IDX_NO    
             Left OUTER JOIN _TSLOrder AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND A.Seq  = C.OrderSeq
             LEFT OUTER JOIN _TSLOrderItem AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND A.Seq = D.OrderSeq AND A.Serl = D.OrderSerl        
       WHERE A.IDOrder = 3      
         AND C.CompanySeq = @CompanySeq      
  
      -- 수주거래처가 없는 경우 생산의뢰의 거래처 가져오도록 추가 2011. 3. 9 hkim           
      SELECT DISTINCT     -- 한건이 분할되어 진행 되었을 경우 중복해서 조회될 수가 있어서 DISTINCT 추가 2011. 6. 14 hkim    
             X.IDX_NO,    
             ISNULL(C.CUstSeq, 0) AS CustSeq,     
             C.DelvDate    
        INTO #ProdReqInfo               
        FROM #TPDSFCWorkOrder AS X JOIN #TCOMSourceTracking AS A ON X.IDX_NO = A.IDX_NO    
             JOIN _TPDMPSProdReqItem  AS C ON A.Seq  = C.ProdReqSeq    
                                          AND A.Serl = C.Serl    
       WHERE A.IDOrder = 2        
         AND C.CompanySeq = @CompanySeq            
  
      -- 입고후 불량 검사 Lot번호 추적    
      UPDATE #TPDSFCWorkOrder    
         SET RealLotNo = B.LotNo    
        FROM #TPDSFCWorkOrder AS X     
             JOIN #TCOMSourceTracking         AS A ON X.IDX_NO = A.IDX_NO    
             JOIN _TPDQAAfterInBadReworkItem  AS B ON A.Seq    = B.BadReworkSeq    
                             AND A.Serl   = B.BadReworkSerl    
       WHERE A.IDOrder    = 4    
         AND B.CompanySeq = @CompanySeq    
      -- 최종검사 불량 Lot번호 추적    
      UPDATE #TPDSFCWorkOrder    
         SET RealLotNo = C.RealLotNo    
        FROM #TPDSFCWorkOrder AS X     
             JOIN #TCOMSourceTracking         AS A ON X.IDX_NO     = A.IDX_NO    
             JOIN _TPDQCTestReport            AS B ON A.Seq        = B.QCSeq    
         JOIN _TPDSFCWorkReport           AS C ON B.CompanySeq = C.CompanySeq    
                                                  AND B.SourceSeq  = C.WorkReportSeq    
       WHERE A.IDOrder    = 5    
         AND B.CompanySeq = @CompanySeq    
         AND B.SourceType = '3'    
             
      
      INSERT INTO #SOInfo    
      SELECT A.IDX_NO,    
             A.ProdPlanSeq,    
           '','',0,0,0,0    
        FROM #TPDSFCWorkOrder AS A LEFT OUTER JOIN #SOInfo AS B ON A.IDX_NO = B.IDX_NO    
       WHERE B.IDX_NO IS NULL    
  
   -- 생산계획코드로 수주번호를 찾도록 수정 2010. 4. 5 김현    
   SELECT A.IDX_NO AS IDX_NO,     
       B.ProdPlanSeq AS ProdPlanSeq    
     INTO #ProdInfo    
     FROM #SOInfo        AS A    
       JOIN _TPDDailyProdPlanSemiPlan AS B ON A.ProdPlanSeq = B.SemiProdPlanSeq AND B.CompanySeq = @CompanySeq    
    WHERE ISNULL(A.SONo, '') = ''      
       
   DELETE FROM  #TCOMSourceTracking      
      
      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDMPSDailyProdPlan', '#ProdInfo','ProdPlanSeq', '',''      
      
     UPDATE #SOInfo    
      SET SONo  = ISNULL(C.OrderNo,'') ,    
       PONo  = ISNULL(C.PONo   ,'') ,    
       CustSeq = ISNULL(C.CustSeq, 0)  ,    
       OrderSeq = ISNULL(B.Seq, 0)  ,    
       OrderSerl= ISNULL(B.Serl, 0)   
     FROM #SOInfo     AS A    
       JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO    
             Left OUTER JOIN _TSLOrder AS C WITH(NOLOCK) ON B.Seq  = C.OrderSeq        
       WHERE C.CompanySeq = @CompanySeq    
         AND B.IDOrder    = 3     
   -- 2010. 4. 5. 김현    
      
       DELETE FROM  #TCOMSourceTracking  -- 20100121 박소연 추가     
      
      
  --  /*반제품의 모제품 수주번호가져오기 20100121 박소연 추가*/    
  --    SELECT C.WorkOrderSeq, C.WorkOrderSerl, A.IDX_NO, 0 AS OrderSeq, 0 AS OrderSerl, CONVERT(NVARCHAR(200), '') AS OrderNo    
  --      INTO #SemiProd    
  --      FROM #TPDSFCWorkOrder AS A     
  --           JOIN _TPDDailyProdPlanSemiPlan AS B ON B.CompanySeq = @CompanySeq AND A.ProdPlanSeq = B.SemiProdPlanSeq    
  --           JOIN _TPDSFCWorkOrder AS C ON B.CompanySeq = C.CompanySeq AND B.ProdPlanSeq = C.ProdPlanSeq    
  --     WHERE A.IDX_NO NOT IN(SELECT IDX_NO FROM #SOInfo)    
  --      
  --      EXEC _SCOMSourceTracking  @CompanySeq, '_TPDSFCWorkOrder', '#SemiProd','WorkOrderSeq', 'WorkOrderSerl',''     
  --    
  ----SELECT * FROM #TCOMSourceTracking    
  --    
  --    UPDATE A    
  --       SET A.OrderSeq  = ISNULL(B.Seq, 0),    
  --           A.OrderSerl = ISNULL(B.Serl, 0),    
  --           A.OrderNo   = ISNULL(C.OrderNo,'')    
  --      FROM #SemiProd AS A    
  --           JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO      
  --           JOIN _TSLOrder AS C WITH(NOLOCK) ON B.Seq  = C.OrderSeq       
  ----           JOIN _TSLOrderItem AS I WITH(NOLOCK) ON B.Seq = I.OrderSeq AND B.Serl = I.OrderSerl AND B.SubSerl = I.OrderSubSerl                                        
  -- WHERE B.IDOrder = 3      
  --       AND C.CompanySeq  =@CompanySeq      
      
     /*반제품의 모제품 수주번호가져오기 끝*/    
      
                
  /**************************[PoNo가져오기]원천 가져오기 끝********************************/      
      
  /**************************[생산사양 가져오기] 20091228 박소연 추가***********************************/    
  DECLARE @SpecName NVARCHAR(100), @SpecValue NVARCHAR(100), @OrderSeq INT, @OrderSerl INT, @SpecSeq INT, @SubSeq INT    
      
  CREATE TABLE #TempSOSpec    
  (    
      Seq      INT IDENTITY,    
      OrderSeq INT,    
      OrderSerl INT,    
      SpecName  NVARCHAR(100),    
      SpecValue NVARCHAR(100)    
  )    
      
      
  INSERT INTO #TempSOSpec    
  SELECT DISTINCT C.OrderSeq, C.OrderSerl,'',''    
    FROM #SOInfo AS A JOIN _TSLOrder AS D ON A.Sono = D.OrderNo AND D.CompanySeq = @CompanySeq    
                    JOIN _TSLOrderItem AS B ON D.OrderSeq = B.OrderSeq AND B.CompanySeq = @CompanySeq    
                      JOIN _TSLOrderItemspecItem AS C ON B.OrderSeq = C.OrderSeq AND B.OrderSerl = C.OrderSerl AND C.CompanySeq = @CompanySeq    
      
  --UNION  -- 20100121 박소연 추가     
  --    
  --SELECT DISTINCT C.OrderSeq, C.OrderSerl,'',''  -- 20100121 박소연 추가     
  --  FROM #SemiProd AS A JOIN _TSLOrder AS D ON A.OrderNo = D.OrderNo AND D.CompanySeq = @CompanySeq    
  --                      JOIN _TSLOrderItem AS B ON D.OrderSeq = B.OrderSeq AND B.CompanySeq = @CompanySeq    
  --     JOIN _TSLOrderItemspecItem AS C ON B.OrderSeq = C.OrderSeq AND B.OrderSerl = C.OrderSerl AND C.CompanySeq = @CompanySeq    
  -- WHERE A.OrderSeq <> 0     
       SELECT @SpecSeq = 0    
      
      WHILE (1=1)    
      BEGIN    
          SET ROWCOUNT 1    
      
          SELECT @SpecSeq = Seq, @OrderSeq = OrderSeq, @OrderSerl = OrderSerl    
            FROM #TempSOSpec    
           WHERE Seq > @SpecSeq    
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
  /*********************[생산사양 가져오기] 끝***************************************************/      
  
 ---------------------------------------------------------------------------------------------------------
     -- 거래처 가져오기 ( 우선순위 : 거래처별OEM품목 -> 생산의뢰 -> 수주)        -- 12.05.24 BY 김세호
 ---------------------------------------------------------------------------------------------------------
     
        ALTER TABLE #TPDSFCWorkOrder ADD CustSeq INT
         UPDATE #TPDSFCWorkOrder    
          SET CustSeq = B.CustSeq
         FROM #TPDSFCWorkOrder AS A 
         JOIN _TPDBaseCustOEMItem AS B ON A.GoodItemSeq = B.ItemSeq 
                                      AND B.CompanySeq = @CompanySeq   
                                      AND A.WorkDate BETWEEN B.DateFr AND B.DateTo                           
  
         UPDATE #TPDSFCWorkOrder
           SET CustSeq = CASE WHEN ISNULL(B.CustSeq, 0) = 0 THEN ISNULL(C.CustSeq, 0) ELSE ISNULL(B.CustSeq, 0) END
          FROM #TPDSFCWorkOrder           AS A
          LEFT OUTER JOIN #ProdReqInfo    AS B ON A.IDX_NO = B.IDX_NO    
          LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO   
         WHERE A.CustSeq IS NULL
   
         -- 재작업건들은 원천 작업지시의 거래처 코드 조회되도록
         UPDATE #TPDSFCWorkOrder
            SET CustSeq = (SELECT TOP 1 CustSeq FROM #TPDSFCWorkOrder WHERE WorkOrderSeq = WorkOrderSeq AND CustSeq <> 0)
           FROM #TPDSFCWorkOrder AS A
          WHERE A.WorkType IN (6041003, 6041009)
          DELETE FROM #TPDSFCWorkOrder WHERE WorkOrderNo = '0'        -- 거래처떄문에 담았던 원천작업지시건은 제외
 ---------------------------------------------------------------------------------------------------------
       -- 진행연결은 양품수량이 아닌 생산수량으로 한다.     
      -- 워크센터별작업지시현황은 양품수량을 조회 하므로         
      IF @WorkingTag = 'W'    
          GOTO WorkCenterList -- 워크센터별 작업지시현황    
  -----------------------------------------------------------------------------------------------------------------    
      
  
       SELECT      
             A.*    
             ,ISNULL( ch1.FactUnitName, '')    AS FactUnitName    
             ,ISNULL( ch2.MinorName, '')   AS ProgStatusName    
             ,ISNULL( ch3.MinorName, '')   AS WorkTypeName    
             --,ISNULL((SELECT TOP 1 '1' FROM #TCOMProgressTracking WHERE IDX_NO = A.IDX_NO AND IDOrder = '2'),'0') AS MatOutYn    
             ,(SELECT TOP 1 1 FROM _TPDMMOutReqItem WHERE CompanySeq = @CompanySeq AND WorkOrderSeq = A.WorkOrderSeq AND WorkOrderSerl = A.WorkOrderSerl) AS MatOutYn     -- 2011.5.6 hkim 자재출고요청으로 진행상태 관련 변경하여     
             ,C.PoNo    
             ,A.CustSeq  AS CustSeq      -- 12.05.24 BY 김세호 수정
             ,J.CustName AS CustName     -- 12.05.24 BY 김세호 수정
             ,(SELECT TOP 1 1 FROM _TSLOrderItemSpec WHERE CompanySeq = @CompanySeq AND OrderSeq = C.OrderSeq AND OrderSerl = C.OrderSerl)AS IsSpec  -- 20100121 박소연 추가    
             ,ISNULL(D.SpecName,'')   AS SpecName  -- 20100121 박소연 추가     
             ,ISNULL(D.SpecValue, '') AS SpecValue -- 20100121 박소연 추가    
             ,ISNULL(CASE ISNULL(H.CustItemNo, '')      
                      WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemNo END, '')  AS  CustItemNo       
             ,ISNULL(CASE ISNULL(H.CustItemName, '')      
                      WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0) 
                      ELSE H.CustItemName END, '') AS  CustItemName      
             ,ISNULL(CASE ISNULL(H.CustItemSpec, '')      
                      WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemSpec END, '') AS  CustItemSpec     
             ,A.Remark AS ProdRemark    
              -- 2011.04.25 김서진 추가    
             , CASE ISNULL(I.DelvDate,'') WHEN '' THEN CASE ISNULL(G.DVDate,'') WHEN '' THEN Z.DVDate     
                       ELSE G.DVDate     
                        END     
              ELSE I.DelvDate 
                 END AS DVDate             
        FROM #TPDSFCWorkOrder     AS A    
         LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO AND A.GoodItemSeq = C.ItemSeq   
         LEFT OUTER JOIN #ProdReqInfo    AS I ON A.IDX_NO = I.IDX_NO               
         LEFT OUTER JOIN #TempSOSpec     AS D ON D.OrderSeq = C.OrderSeq AND D.OrderSerl = C.OrderSerl       
         LEFT OUTER JOIN _TSLOrderItem   AS G ON G.OrderSeq   = C.OrderSeq                         -- 20101124 정영훈 추가    
                                            AND G.OrderSerl  = C.OrderSerl                        -- 20101124 정영훈 추가    
                                            AND G.CompanySeq = @CompanySeq                        -- 20101124 정영훈 추가    
                                            AND G.OrderSubSerl = 0                                -- 판매옵션은 제외     
         LEFT OUTER JOIN _TSLOrder AS Z ON  Z.CompanySeq = G.CompanySeq     
                                       AND Z.OrderSeq = G.OrderSeq        -- 2011.04.25 김서진 추가    
         LEFT OUTER JOIN _TSLCustItem    AS H WITH(NOLOCK) ON G.ItemSeq = H.ItemSeq            -- 20101124 정영훈 추가    
                                                         AND C.CustSeq     = H.CustSeq            -- 20101124 정영훈 추가    
                                                         AND G.UnitSeq     = H.UnitSeq            -- 20101124 정영훈 추가    
                                                             AND G.CompanySeq  = H.CompanySeq         -- 20101124 정영훈 추가    
         LEFT OUTER JOIN _TDAFactUnit AS ch1 ON ch1.CompanySeq = @CompanySeq     
                  AND ch1.FactUnit = A.FactUnit      
         LEFT OUTEr JOIN _TDASMinor   AS ch2 ON ch2.CompanySeq = @CompanySeq     
                  AND ch2.MajorSeq = 6036             
                  AND ch2.MinorSeq = A.ProgStatus    
         LEFT OUTER JOIN _TDASMinor   AS ch3 ON ch3.CompanySeq = @CompanySeq     
                  AND ch3.MajorSeq = 6041             
                  AND ch3.MinorSeq = A.WorkType  
         LEFT OUTER JOIN _TDACust  AS J ON J.CompanySeq = @CompanySeq
                                       AND J.CustSeq = A.CustSeq  
       WHERE (@ProgStatus = 0     
              OR (@ProgStatus = 6036006 AND A.ProgStatus IN (6036001,6036002,6036003))    
              OR A.ProgStatus = @ProgStatus)    
         AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
         AND (@PoNo = '' OR C.PoNo LIKE @PoNo + '%')   
  
  --       AND A.OrderQty > 0    
         --AND  (@GoodItemName      = ''    OR A.GoodItemName       LIKE @GoodItemName + '%')    
         --AND  (@GoodItemNo        = ''    OR A.GoodItemNo         LIKE @GoodItemNo + '%')    
         --AND  (@GoodItemSpec      = ''    OR A.GoodItemSpec           LIKE @GoodItemSpec + '%')    
         --AND  (@ProcName          = ''    OR A.ProcName       LIKE @ProcName + '%')    
         --AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
      
      ORDER BY A.WorkOrderNo, A.ProcNo    
      
      
  RETURN    
  /**********************************************************************************************************/    
  WorkCenterList:     
      
      
      -- 작업지시별 양품수량, 불량수량.    
      
      SELECT R.WorkOrderSeq    
            ,R.WorkOrderSerl    
            ,SUM(OKQty)   AS MadeQty    
            ,SUM(BadQty)  AS ProgBadQty    
        INTO #WorkQty    
        FROM _TPDSFCWorkReport        AS R WITH(NOLOCK)     
       WHERE R.CompanySeq        = @CompanySeq     
         AND EXISTS (SELECT 1 FROM #TPDSFCWorkOrder WHERE WorkOrderSeq = R.WorkOrderSeq AND WorkOrderSerl = R.WorkOrderSerl)    
      GROUP BY R.WorkOrderSeq,R.WorkOrderSerl    
         
        
      SELECT      
             A.*    
             ,ISNULL( ch1.FactUnitName, '')    AS FactUnitName    
             ,ISNULL( ch2.MinorName, '')   AS ProgStatusName    
             ,ISNULL( ch3.MinorName, '')   AS WorkTypeName    
             ,ISNULL(B.MadeQty, 0)             AS MadeQty    
             ,ISNULL(B.ProgBadQty , 0)         AS ProgBadQty    
             ,DATENAME(WEEKDAY, A.WorkDate)    AS WeekDay    
             ,C.PoNo     
             ,A.CustSeq   AS CustSeq    -- 12.05.24 BY 김세호 수정
             ,J.CustName  AS CustName   -- 12.05.24 BY 김세호 수정              
             ,(SELECT TOP 1 1 FROM _TSLOrderItemSpec WHERE CompanySeq = @CompanySeq AND OrderSeq = C.OrderSeq AND OrderSerl = C.OrderSerl)AS IsSpec  -- 20100121 박소연 추가    
             ,ISNULL(D.SpecName, '')   AS SpecName  -- 20100121 박소연 추가     
             ,ISNULL(D.SpecValue, '') AS SpecValue  -- 20100121 박소연 추가    
      
             ,ISNULL(CASE ISNULL(H.CustItemNo, '')      
                      WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemNo END, '')  AS  CustItemNo       
             ,ISNULL(CASE ISNULL(H.CustItemName, '')      
                      WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemName END, '') AS  CustItemName      
             ,ISNULL(CASE ISNULL(H.CustItemSpec, '')      
                      WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = C.CustSeq  AND A.GoodItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)       
                      ELSE H.CustItemSpec END, '') AS  CustItemSpec      
             ,A.Remark AS ProdRemark    
             -- 2011.04.25 김서진 추가    
             , CASE ISNULL(I.DelvDate,'') WHEN '' THEN CASE ISNULL(G.DVDate,'') WHEN '' THEN Z.DVDate     
                       ELSE G.DVDate     
                        END     
                ELSE I.DelvDate     
                 END AS DVDate    
         FROM #TPDSFCWorkOrder             AS A    
             LEFT OUTER JOIN #WorkQty        AS B ON A.WorkOrderSeq = B.WorkOrderSeq     
                                              AND A.WorkOrderSerl = B.WorkOrderSerl    
             LEFT OUTER JOIN #SOInfo         AS C ON A.IDX_NO = C.IDX_NO    
             LEFT OUTER JOIN #ProdReqInfo    AS I ON A.IDX_NO = I.IDX_NO    
             LEFT OUTER JOIN #TempSOSpec     AS D ON D.OrderSeq = C.OrderSeq AND D.OrderSerl = C.OrderSerl    
   
           LEFT OUTER JOIN _TSLOrderItem   AS G ON G.OrderSeq   = C.OrderSeq                         -- 20101124 정영훈 추가    
                                                AND G.OrderSerl  = C.OrderSerl                        -- 20101124 정영훈 추가    
                                                ANd G.CompanySeq = @CompanySeq                        -- 20101124 정영훈 추가    
                                                AND G.OrderSubSerl = 0                                -- 판매옵션은 제외     
           LEFT OUTER JOIN _TSLOrder AS Z ON  Z.CompanySeq = G.CompanySeq                            -- 2011.04.25 김서진 추가    
                                               AND Z.OrderSeq = G.OrderSeq    
           LEFT OUTER JOIN _TSLCustItem    AS H WITH(NOLOCK) ON G.ItemSeq = H.ItemSeq            -- 20101124 정영훈 추가    
                                                             AND C.CustSeq     = H.CustSeq            -- 20101124 정영훈 추가    
                          AND G.UnitSeq     = H.UnitSeq            -- 20101124 정영훈 추가    
                                                             AND G.CompanySeq  = H.CompanySeq         -- 20101124 정영훈 추가    
             LEFT OUTER JOIN _TDAFactUnit AS ch1 ON ch1.CompanySeq = @CompanySeq     
                      AND ch1.FactUnit = A.FactUnit      
             LEFT OUTEr JOIN _TDASMinor   AS ch2 ON ch2.CompanySeq = @CompanySeq     
                      AND ch2.MajorSeq = 6036             
                      AND ch2.MinorSeq = A.ProgStatus    
             LEFT OUTEr JOIN _TDASMinor   AS ch3 ON ch3.CompanySeq = @CompanySeq     
                      AND ch3.MajorSeq = 6041             
                      AND ch3.MinorSeq = A.WorkType    
             LEFT OUTER JOIN _TDACust  AS J ON J.CompanySeq = @CompanySeq
                                           AND J.CustSeq = A.CustSeq  
       WHERE (@ProgStatus = 0     
              OR (@ProgStatus = 6036006 AND A.ProgStatus IN (6036001,6036002,6036003))    
              OR A.ProgStatus = @ProgStatus)    
         AND (@CustSeq = 0 OR A.CustSeq = @CustSeq)    
         AND (@PoNo = '' OR C.PoNo LIKE @PoNo + '%')  
   
         --AND  (@WorkCenterSeq     = 0     OR A.WorkCenterSeq = @WorkCenterSeq)    
      
         --AND  (@GoodItemName      = ''    OR A.GoodItemName       LIKE @GoodItemName + '%')    
         --AND  (@GoodItemNo        = ''    OR A.GoodItemNo         LIKE @GoodItemNo + '%')    
         --AND  (@GoodItemSpec      = ''    OR A.GoodItemSpec       LIKE @GoodItemSpec + '%')    
         --AND  (@ProcName          = ''    OR A.ProcName           LIKE @ProcName + '%')    
      
       
          
  RETURN    
 /**********************************************************************************************************/