
IF OBJECT_ID('amoerp_SLGInOutDailyItemListQuery') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemListQuery 
GO

-- v2013.11.25 
-- 입출고품목현황(조회)_amoerp by이재천
  /*************************************************************************************************
  설  명 - 입출고품목현황 조회
  작성일 - 2008.10 : CREATED BY 김준모
  수정일 - 2009.11.07 : Modify by 허승남 
           LotNo 추가
           요청부서, 요청자 추가 - 2010.06.24 정혜영 
           2011.06.01 by 김철웅 
           1) 품목 대/중/소 분류도 호출하기 
 *************************************************************************************************/
-- v2013.05.06
  /*************************************************************************************************
  설  명 - 입출고품목현황 조회
  작성일 - 2008.10 : CREATED BY 김준모
  수정일 - 2009.11.07 : Modify by 허승남 
           LotNo 추가
           요청부서, 요청자 추가 - 2010.06.24 정혜영 
           2011.06.01 by 김철웅 
           1) 품목 대/중/소 분류도 호출하기 
 *************************************************************************************************/
 CREATE PROCEDURE amoerp_SLGInOutDailyItemListQuery
      @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10) = '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
     DECLARE @docHandle          INT,
             @InOutSeq           INT,
             @BizUnit            INT,
             @InOutNo            NVARCHAR(20),
             @FactUnit           INT,
             @ReqBizUnit         INT,
             @DeptSeq            INT,
             @EmpSeq             INT,
             @InOutDateFr        NCHAR(8),
             @InOutDateTo        NCHAR(8),
             @CompleteDateFr     NCHAR(8),
             @CompleteDateTo     NCHAR(8),
             @CustSeq            INT,
             @OutWHSeq           INT,
             @InWHSeq            INT,
             @DVPlaceSeq         INT,
             @InOutType          INT,
             @InOutDetailType    INT,
             @InOutKind          INT,
             @InOutDetailKind    INT,
             @ItemName           NVARCHAR(200),
             @ItemNo             NVARCHAR(100),
             @Spec               NVARCHAR(100),
             @ItemSeq            INT,
             @UnitSeq            INT,
             @CCtrSeq            INT,
             @DVPlaceSeqItem     INT,
             @SMProgressType     INT,            -- 진행상태
             @AssetSeq           INT,
             @InKind             INT,            -- 입고구분
             @ReqNo              NVARCHAR(20),
             @UseDeptSeq         INT,            -- 사용부서     
             @CostEnv            INT,            -- 사용원가 환경설정
             @IFRSEnv            INT,            -- IFRS 사용 여부 환경설정
             @SMCostMng          INT,
             @LotNo              NVARCHAR(30),
             @PJTName            NVARCHAR(200),    -- 2012.06.25 by 윤보라
             @PJTNo              NVARCHAR(100),    -- 2012.06.25 by 윤보라
             @PJTComplete        NCHAR(1),         -- 2012.07.09 by 윤보라 
             @ReqDeptSeq         INT, -- v2013.11.05 ADD By이재천
             @ReqEmpSeq          INT  -- v2013.11.05 ADD By이재천
             
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @InOutSeq           = ISNULL(InOutSeq,0),
             @BizUnit            = ISNULL(BizUnit,0),
             @InOutNo            = ISNULL(InOutNo,''),
             @FactUnit           = ISNULL(FactUnit,0),
             @ReqBizUnit         = ISNULL(ReqBizUnit,0),
             @DeptSeq            = ISNULL(DeptSeq,0),
             @EmpSeq             = ISNULL(EmpSeq,0),
             @InOutDateFr        = ISNULL(InOutDateFr,''),
             @InOutDateTo        = ISNULL(InOutDateTo,''),
             @CompleteDateFr     = ISNULL(CompleteDateFr,''),
             @CompleteDateTo     = ISNULL(CompleteDateTo,''),
             @CustSeq            = ISNULL(CustSeq,0),
             @OutWHSeq           = ISNULL(OutWHSeq,0),
             @InWHSeq            = ISNULL(InWHSeq,0),
             @DVPlaceSeq         = ISNULL(DVPlaceSeq,0),
             @InOutType          = ISNULL(InOutType,0),
             @InOutDetailType    = ISNULL(InOutDetailType,0),
             @InOutKind          = ISNULL(InOutKind,0),
             @InOutDetailKind    = ISNULL(InOutDetailKind,0),
             @ItemName           = ISNULL(ItemName,''),
             @ItemNo             = ISNULL(ItemNo,''),
             @Spec               = ISNULL(Spec,''),
             @ItemSeq  = ISNULL(ItemSeq,0),
             @UnitSeq            = ISNULL(UnitSeq,0),
             @CCtrSeq             = ISNULL(CCtrSeq,0),
             @DVPlaceSeqItem     = ISNULL(DVPlaceSeqItem,0),
             @SMProgressType     = ISNULL(SMProgressType, 0),
             @AssetSeq           = ISNULL(AssetSeq,0),
             @InKind             = ISNULL(InKind, 0),
             @ReqNo              = ISNULL(ReqNo, ''),
             @UseDeptSeq         = ISNULL(UseDeptSeq,0),
             @LotNo              = ISNULL(LotNo, ''),
             @PJTName            = ISNULL(PJTName, ''),
             @PJTNo              = ISNULL(PJTNo, ''),
             @PJTComplete        = ISNULL(PJTComplete,'0'), 
             @ReqDeptSeq         = ISNULL(ReqDeptSeq,0), 
             @ReqEmpSeq          = ISNULL(ReqEmpSeq,0) 
             
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH (  InOutSeq           INT,
             BizUnit            INT,
             InOutNo            NVARCHAR(20),
             FactUnit           INT,
             ReqBizUnit         INT,
             DeptSeq            INT,
             EmpSeq             INT,
             InOutDateFr        NCHAR(8),
             InOutDateTo        NCHAR(8),
             CompleteDateFr     NCHAR(8),
             CompleteDateTo     NCHAR(8),
             CustSeq            INT,
             OutWHSeq           INT,
             InWHSeq            INT,
             DVPlaceSeq         INT,
             InOutType          INT,
             InOutDetailType    INT,
             InOutKind          INT,
             InOutDetailKind    INT,
             ItemName           NVARCHAR(200),
             ItemNo             NVARCHAR(100),
             Spec               NVARCHAR(100),
             ItemSeq            INT,
             UnitSeq            INT,
             CCtrSeq            INT,
             DVPlaceSeqItem     INT,
             SMProgressType     INT,
             AssetSeq           INT,
             InKind             INT,
             ReqNo              NVARCHAR(20),
             UseDeptSeq         INT,
             LotNo              NVARCHAR(30),
             PJTName            NVARCHAR(200),
             PJTNo              NVARCHAR(100),
             PJTComplete        NCHAR(1), 
             ReqDeptSeq         INT, 
             ReqEmpSeq          INT
          ) 
      SELECT  @InOutSeq           = ISNULL(LTRIM(RTRIM(@InOutSeq)),0),
             @BizUnit            = ISNULL(LTRIM(RTRIM(@BizUnit)),0),
             @InOutNo            = ISNULL(LTRIM(RTRIM(@InOutNo)),''),
             @FactUnit           = ISNULL(LTRIM(RTRIM(@FactUnit)),0),
             @ReqBizUnit         = ISNULL(LTRIM(RTRIM(@ReqBizUnit)),0),
             @DeptSeq            = ISNULL(LTRIM(RTRIM(@DeptSeq)),0),
             @EmpSeq             = ISNULL(LTRIM(RTRIM(@EmpSeq)),0),
             @InOutDateFr        = ISNULL(LTRIM(RTRIM(@InOutDateFr)),''),
             @InOutDateTo        = ISNULL(LTRIM(RTRIM(@InOutDateTo)),''),
             @CompleteDateFr     = ISNULL(LTRIM(RTRIM(@CompleteDateFr)),''),
             @CompleteDateTo     = ISNULL(LTRIM(RTRIM(@CompleteDateTo)),''),
             @CustSeq            = ISNULL(LTRIM(RTRIM(@CustSeq)),0),
             @OutWHSeq           = ISNULL(LTRIM(RTRIM(@OutWHSeq)),0),
             @InWHSeq            = ISNULL(LTRIM(RTRIM(@InWHSeq)),0),
             @DVPlaceSeq         = ISNULL(LTRIM(RTRIM(@DVPlaceSeq)),0),
             @InOutType          = ISNULL(LTRIM(RTRIM(@InOutType)),0),
             @InOutDetailType    = ISNULL(LTRIM(RTRIM(@InOutDetailType)),0),
             @InOutKind          = ISNULL(LTRIM(RTRIM(@InOutKind)),0),
             @InOutDetailKind    = ISNULL(LTRIM(RTRIM(@InOutDetailKind)),0),
             @ItemName           = ISNULL(LTRIM(RTRIM(@ItemName)),''),
             @ItemNo             = ISNULL(LTRIM(RTRIM(@ItemNo)),''),
             @Spec               = ISNULL(LTRIM(RTRIM(@Spec)),''),
             @ItemSeq            = ISNULL(LTRIM(RTRIM(@ItemSeq)),0),
             @UnitSeq            = ISNULL(LTRIM(RTRIM(@UnitSeq)),0),
             @CCtrSeq            = ISNULL(LTRIM(RTRIM(@CCtrSeq)),0),
             @DVPlaceSeqItem     = ISNULL(LTRIM(RTRIM(@DVPlaceSeqItem)),0),
             @ReqNo              = ISNULL(LTRIM(RTRIM(@ReqNo)), ''),
             @UseDeptSeq         = ISNULL(LTRIM(RTRIM(@UseDeptSeq)), 0),
             @LotNo              = ISNULL(LTRIM(RTRIM(@LotNo)), ''),
             @PJTName            = ISNULL(LTRIM(RTRIM(@PJTName)), ''),
             @PJTNo              = ISNULL(LTRIM(RTRIM(@PJTNo)), ''),
             @PJTComplete        = ISNULL(LTRIM(RTRIM(@PJTComplete)),'0'), 
             @ReqDeptSeq         = ISNULL(LTRIM(RTRIM(@ReqDeptSeq)),0), 
             @ReqEmpSeq          = ISNULL(LTRIM(RTRIM(@ReqEmpSeq)),0) 
  
     /*************** Get PgmId by InOutType [20130621 박성호 추가] ***************/
     
     -- _TLGInOutJumpPgmId에 InOutType별 PgmId가 존재합니다. -> ( sp_help _TLGInOutJumpPgmId / SELECT * FROM _TLGInOutJumpPgmId )
     -- 일단 #JumpPgmId에 각 구분값(Local구분, 반품구분, 프로젝트구분)에 대한 디폴드 값을 INSERT 한 후,
     -- 조회조건에 해당하는 데이터를 검토하여 조건 별로 UPDATE 해 줍니다.
     -- 이렇게 UPDATE 된 #JumpPgmId를 통해, _TLGInOutJumpPgmId과 JOIN하여 PgmId를 조회합니다.
      
     CREATE TABLE #JumpPgmId (
         SMInOutType INT,
         InOutType   INT,
         InOutSeq    INT,
         SMLocalKind INT,
         IsReturn    NCHAR(1),
         IsPMS       NCHAR(1),
         InOutSerl   INT
     )
      INSERT INTO #JumpPgmId ( SMInOutType, InOutType, InOutSeq, SMLocalKind, IsReturn, IsPMS, InOutSerl )
     SELECT D.MinorSeq, A.InOutType, A.InOutSeq, 8918001, '0', '0', A.InOutSerl
       FROM amoerp_TLGInOutDailyItemMerge           AS A WITH(NOLOCK)
            JOIN _TLGInOutDaily          AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                          AND A.InOutType  = B.InOutType
                                                          AND A.InOutSeq   = B.InOutSeq
            LEFT OUTER JOIN _TDAItem     AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                          AND A.ItemSeq    = C.ItemSeq
            LEFT OUTER JOIN _TPJTProject AS K WITH(NOLOCK) ON A.PJTSeq     = K.PJTSeq                                       
                                                          AND A.CompanySeq = K.CompanySeq
            JOIN _TDASMinor              AS D WITH(NOLOCK) ON D.MinorValue = A.InOutType
                                                          AND D.MajorSeq   = 8042
                                                          AND D.CompanySeq = @CompanySeq
      WHERE A.CompanySeq      = @CompanySeq
        AND (@BizUnit         = 0   OR B.BizUnit         =  @BizUnit)
        AND (@FactUnit        = 0   OR B.FactUnit        =  @FactUnit)
        AND (@ReqBizUnit      = 0   OR B.ReqBizUnit      =  @ReqBizUnit)
        AND (@DeptSeq         = 0   OR B.DeptSeq         =  @DeptSeq)
        AND (@EmpSeq          = 0   OR B.EmpSeq          =  @EmpSeq)
        AND (@OutWHSeq        = 0   OR A.OutWHSeq        =  @OutWHSeq)
        AND (@DVPlaceSeq      = 0   OR B.DVPlaceSeq      =  @DVPlaceSeq)
        AND (@InOutDetailType = 0   OR B.InOutDetailType =  @InOutDetailType)
        AND (@InOutKind       = 0   OR A.InOutKind       =  @InOutKind)
        AND (@InOutDetailKind = 0   OR A.InOutDetailKind =  @InOutDetailKind)
        AND (@ItemSeq         = 0   OR A.ItemSeq         =  @ItemSeq)
        AND (@UnitSeq         = 0   OR A.UnitSeq         =  @UnitSeq)
        AND (@CCtrSeq         = 0   OR A.CCtrSeq         =  @CCtrSeq)
        AND (@DVPlaceSeqItem  = 0   OR A.DVPlaceSeq      =  @DVPlaceSeqItem)
        AND (@AssetSeq        = 0   OR C.AssetSeq        =  @AssetSeq)
        AND (@UseDeptSeq      = 0   OR B.UseDeptSeq      =  @UseDeptSeq) 
        AND (@PJTComplete     = '0' OR K.ISComplete      =  @PJTComplete )      
        AND (@InOutDateFr     = ''  OR B.InOutDate       >= @InOutDateFr)
        AND (@InOutDateTo     = ''  OR B.InOutDate       <= @InOutDateTo)
        AND (@CompleteDateFr  = ''  OR B.CompleteDate    >= @CompleteDateFr)
        AND (@CompleteDateTo  = ''  OR B.CompleteDate    <= @CompleteDateTo)      
        AND (@InOutNo         = ''   OR B.InOutNo       LIKE @InOutNo  + '%')
        AND (@ItemName        = ''  OR C.ItemName      LIKE @ItemName + '%')
        AND (@ItemNo          = ''  OR C.ItemNo        LIKE @ItemNo   + '%')
        AND (@Spec            = ''  OR C.Spec          LIKE @Spec     + '%')
        AND (@LotNo           = ''  OR A.LotNo         LIKE @LotNo    + '%')
        AND (@PJTName         = ''  OR K.PJTName       LIKE @PJTName  + '%')
        AND (@PJTNo           = ''  OR K.PJTNo         LIKE @PJTNo    + '%') 
        AND (@InOutType       = 0
            OR A.InOutType    = @InOutType
            OR (  (A.InOutType IN (80, 81, 85) AND @InOutType  = 80)
               OR (A.InOutType IN (82, 83, 84) AND @InOutType  = 82)
               OR (A.InOutType IN (50, 51)     AND @InOutType  = 50)   
               OR (A.InOutType IN (70, 71)     AND @InOutType  = 70) ))      
        AND (@InKind    = 0
            OR (@InKind = 6043001 AND ISNULL(B.IsCompleted, '0') =  '1')
            OR (@InKind = 6043002 AND ISNULL(B.IsCompleted, '0') <> '1'))
        AND (@CustSeq   = 0 OR ((     ISNULL(A.PJTSeq,0) = 0  AND B.CustSeq = @CustSeq)
                                  OR (ISNULL(A.PJTSeq,0) <> 0 AND K.CustSeq = @CustSeq)))
      GROUP BY D.MinorSeq, A.InOutType, A.InOutSeq, A.InOutSerl
  
     /* 프로젝트 구분 UPDATE */
     UPDATE #JumpPgmId
        SET IsPMS = '1'
       FROM #JumpPgmId                AS A
            JOIN _TLGInOutDaily       AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                       AND A.InOutType  = B.InOutType
            JOIN _TSLInvoice          AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                       AND B.InOutType  IN (10, 11)
                                                       AND B.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.IsPJT, '') = '1'
         
      /* 내수수출구분 UPDATE */
      -- 거래명세표(10) & 반품명세표(11)
     UPDATE #JumpPgmId
        SET SMLocalKind = 8918002
       FROM #JumpPgmId                     AS A
            JOIN _TLGInOutDaily            AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                            AND A.InOutType  = B.InOutType
            LEFT OUTER JOIN _TSLExpInvoice AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                            AND A.InOutType  IN (10, 11)
                                                            AND A.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.InvoiceSeq, 0) <> 0
      -- 판매매출(20)
     UPDATE #JumpPgmId
        SET SMLocalKind = 8918002
       FROM #JumpPgmId                      AS A
            JOIN _TLGInOutDaily             AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                             AND A.InOutType  = B.InOutType
            LEFT OUTER JOIN _TSLSales       AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq 
                                                             AND A.InOutSeq   = C.SalesSeq
                                                             AND A.InOutType  = 20
            LEFT OUTER JOIN _TDASMinorValue AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq
                                                             AND C.SMExpKind  = D.MinorSeq
                                                             AND D.Serl       = 1001
      WHERE D.ValueText <> '1'
  
     /*****  반품구분 UPDATE *****/
     UPDATE #JumpPgmId
        SET IsReturn = '1'
       FROM #JumpPgmId              AS A
            JOIN _TLGInOutDaily     AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                     AND A.InOutType  = B.InOutType
            JOIN amoerp_TLGInOutDailyItemMerge AS C WITH(NOLOCK) ON B.InOutSeq   = C.InOutSeq  
                                                     AND B.InOutType  = C.InOutType 
                                                     AND B.CompanySeq = C.CompanySeq
      WHERE B.InOutType  = 180
        AND C.InOutKind <> 8023020
      
     /****************************************************************************/
  
  
             
     -- 원천테이블
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))
      -- 원천 데이터 테이블
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))
      -- 데이터테이블
     CREATE TABLE #TempResult
     (   IDX_NO INT IDENTITY,
         InOutSeq            INT,            InOutSerl        INT,           BizUnitName     NVARCHAR(100),  BizUnit         INT,            InOutNO         NVARCHAR(20),
         FactUnitName        NVARCHAR(100),  FactUnit         INT,           ReqBizUnitName  NVARCHAR(100),  ReqBizUnit      INT,            DeptName        NVARCHAR(100),
         DeptSeq             INT,            EmpName          NVARCHAR(100), EmpSeq          INT,            InOutDate       NCHAR(8),       CompleteDate    NCHAR(8),
         IsCompleted         NCHAR(1),       CompleteDeptName NVARCHAR(100), CompleteDeptSeq INT,            CompleteEmpName NVARCHAR(100),  CompleteEmpSeq  INT,
         CustName            NVARCHAR(100),  CustSeq          INT,           OutWHName       NVARCHAR(100),  OutWHSeq        INT,            InWHName        NVARCHAR(100),
         InWHSeq             INT,            DVPlaceSeq       INT,           DVPlaceName     NVARCHAR(100),  IsTrans         NCHAR(1),       InOutType       INT,
         InOutDetailType     INT,            Remark           NVARCHAR(200), Memo            NVARCHAR(200),  InOutKindName   NVARCHAR(100),  InOutKind       INT,
         InOutDetailKindName NVARCHAR(100) , InOutDetailKind  INT,           ItemName        NVARCHAR(200),  ItemNo          NVARCHAR(100),  Spec            NVARCHAR(100),
         ItemSeq             INT,            Price            DECIMAL(19,5), Amt             DECIMAL(19,5),  Qty             DECIMAL(19,5),  UnitName        NVARCHAR(30),
         UnitSeq             INT,            STDUnitName      NVARCHAR(30),  STDUnitSeq      INT,            STDQty          DECIMAL(19,5),  InOutRemark     NVARCHAR(200),
         CCtrName            NVARCHAR(100),  CCtrSeq          INT,           DVPlaceSeqItem  NVARCHAR(100),  OriItemName     NVARCHAR(200),  OriItemNo       NVARCHAR(100),
         OriSpec             NVARCHAR(100),  OriItemSeq       INT,           OriUnitName     NVARCHAR(30),   OriUnitSeq      INT,            OriSTDUnitName  NVARCHAR(30),
         OriSTDUnitSeq       INT,            OriQty           DECIMAL(19,5), OriSTDQty       DECIMAL(19,5),  LastUserName    NVARCHAR(100),  LastDateTime    DATETIME,
         InOutTypeName       NVARCHAR(100),  LotNo            NVARCHAR(100), UseDeptSeq      INT,            UseDeptName     NVARCHAR(100),  FormID          NVARCHAR(100),  
         IsExistsSubEtcOut   NCHAR(1),       TransInQty       DECIMAL(19,5), SubEtcOutQty    DECIMAL(19,5),  SMProgressTypeName NVARCHAR(50), SMProgressType INT,            
         ReqSeq              INT,            ReqSerl          INT,           ReqNo           NVARCHAR(20),   InvProgQty       DECIMAL(19,5), InvNotProgQty   DECIMAL(19,5),  
         JumpOutPgmId        NVARCHAR(50),   ColumnName       NVARCHAR(50),  ReqDeptName     NVARCHAR(100),  ReqEmpName       NVARCHAR(100), IsProd          NCHAR(1),
         AssetName   NVARCHAR(100),  PJTName          NVARCHAR(200), PJTNo           NVARCHAR(100),  PJTSeq           INT,           IsPJT           NCHAR(10),
         CustItemName        NVARCHAR(100),  CustItemNo       NVARCHAR(100), CustItemSpec    NVARCHAR(100),  SerialNo        NVARCHAR(30),   ReqDeptSeq      INT, 
         ReqEmpSeq           INT -- v2013.11.05 ADD By이재천 (ReqDeptSeq, ReqEmpSeq)
     )
      -- 입출고진행 Table
     CREATE TABLE #Temp_InOutItemProg(IDX_NO INT IDENTITY, InOutType INT, InOutSeq INT, InOutSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1))
      INSERT INTO #TempResult
     SELECT ISNULL(A.InOutSeq, 0) AS InOutSeq,
            ISNULL(A.InOutSerl, 0) AS InOutSerl,
            ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND BizUnit = B.BizUnit), '') AS BizUnitName,
            ISNULL(B.BizUnit, 0)  AS BizUnit,
            ISNULL(RTRIM(B.InOutNo), '')   AS InOutNo,
            ISNULL((SELECT FactUnitName FROM _TDAFactUnit WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND FactUnit = B.FactUnit), '') AS FactUnitName,
            ISNULL(B.FactUnit, 0) AS FactUnit,
            ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND BizUnit = B.ReqBizUnit), '') AS ReqBizUnitName,
            ISNULL(B.ReqBizUnit, 0) AS ReqBizUnit,
            ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND DeptSeq = B.DeptSeq), '') AS DeptName,
            ISNULL(B.DeptSeq, 0) AS DeptSeq,
            ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND EmpSeq = B.EmpSeq), '') AS EmpName,
            ISNULL(B.EmpSeq, 0)  AS EmpSeq,
            ISNULL(B.InOutDate, '') AS InOutDate,
            ISNULL(B.CompleteDate, '') AS CompleteDate,
            --ISNULL(K.ISComplete, '0') AS IsCompleted,
            CASE WHEN ISNULL(B.CompleteDate, '') <> '' THEN '1' ELSE '0' END AS IsCompleted,
            ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND DeptSeq = B.CompleteDeptSeq), '') AS CompleteDeptName,
            ISNULL(B.CompleteDeptSeq, 0) AS CompleteDeptSeq,
            ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND EmpSeq = B.CompleteEmpSeq), '') AS CompleteEmpName,
            ISNULL(B.CompleteEmpSeq, 0) AS CompleteEmpSeq,
            --ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND CustSeq = B.CustSeq), '') AS CustName,
            --ISNULL(B.CustSeq, 0) AS CustSeq,
            CASE WHEN ISNULL(A.PJTSeq, 0) = 0 THEN ISNULL(L.CustName,'')  
                                              ELSE ISNULL(M.CustName,'')  
                                              END AS CustName,            -- 2012.07.09 by 윤보라    
            CASE WHEN ISNULL(A.PJTSeq, 0) = 0 THEN ISNULL(L.CustSeq,0)  
                                              ELSE ISNULL(M.CustSeq,0)  
                                              END AS CustSeq,             -- 2012.07.09 by 윤보라    
            --ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND WHSeq = B.OutWHSeq), '') AS OutWHName,
            --ISNULL(B.OutWHSeq, 0) AS OutWHSeq,
            CASE WHEN ISNULL(A.OutWHSeq,0) = 0 THEN ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND WHSeq = B.OutWHSeq), '')
                                               ELSE ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND WHSeq = A.OutWHSeq), '') END AS OutWHName,
            CASE WHEN ISNULL(A.OutWHSeq,0) = 0 THEN ISNULL(B.OutWHSeq, 0) ELSE ISNULL(A.OutWHSeq, 0) END AS OutWHSeq,
             CASE WHEN ISNULL(A.InWHSeq,0)  = 0 THEN ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND WHSeq = B.InWHSeq), '')
                                               ELSE ISNULL((SELECT WHName FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND WHSeq = A.InWHSeq), '') END AS InWHName,
            CASE WHEN ISNULL(A.InWHSeq,0)  = 0 THEN ISNULL(B.InWHSeq, 0)  ELSE ISNULL(A.InWHSeq, 0) END AS InWHSeq,
            ISNULL(B.DVPlaceSeq, 0) AS DVPlaceSeq,
            ISNULL((SELECT DVPlaceName FROM _TSLDeliveryCust WITH (NOLOCK) WHERE CompanySeq = B.CompanySeq AND DVPlaceSeq = B.DVPlaceSeq), '') AS DVPlaceName,
            ISNULL(B.IsTrans, '0') AS IsTrans,
            ISNULL(B.InOutType, 0) AS InOutType,
            ISNULL(B.InOutDetailType, 0) AS InOutDetailType,
            ISNULL(A.InOutRemark, '') AS Remark,
            ISNULL(B.Memo, '') AS Memo,
            ISNULL(E.MinorName,'') AS InOutKindName,
            ISNULL(A.InOutKind, 0) AS InOutKind,
            ISNULL((SELECT ISNULL(MinorName,'') FROM _TDAUMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MinorSeq = A.InOutDetailKind),'') AS InOutDetailKindName,
            ISNULL(A.InOutDetailKind, 0) AS InOutDetailKind,
            ISNULL(C.ItemName, '') AS ItemName,
            ISNULL(C.ItemNo, '') AS ItemNo,
            ISNULL(C.Spec, '') AS Spec,
            ISNULL(A.ItemSeq, 0) AS ItemSeq,
            CASE WHEN ISNULL(A.Qty, 0) = 0 THEN 0 ELSE ISNULL(A.Amt, 0) / ISNULL(A.Qty, 0) END  AS Price,
            ISNULL(A.Amt, 0) AS Amt,
            ISNULL(A.Qty, 0) AS Qty,
            ISNULL((SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq),'') AS UnitName,
            ISNULL(A.UnitSeq, 0) AS UnitSeq,
            ISNULL((SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = C.UnitSeq),'') AS STDUnitName,
            ISNULL(C.UnitSeq, 0) AS STDUnitSeq,
            ISNULL(A.STDQty, 0) AS STDQty,
            ISNULL(A.InOutRemark, 0) AS InOutRemark,
            ISNULL((SELECT ISNULL(CCtrName,'') FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq),'') AS CCtrName,
            ISNULL(A.CCtrSeq, 0) AS CCtrSeq,
            ISNULL(A.DVPlaceSeq, 0) AS DVPlaceSeqItem,
            ISNULL(D.ItemName, '') AS OriItemName,
            ISNULL(D.ItemNo, '') AS OriItemNo,
            ISNULL(D.Spec, '') AS OriSpec,
            ISNULL(A.OriItemSeq, 0) AS OriItemSeq,
            ISNULL((SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = A.OriUnitSeq),'') AS OriUnitName,
            ISNULL(A.OriUnitSeq, 0) AS OriUnitSeq,
            ISNULL((SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND UnitSeq = D.UnitSeq),'') AS OriSTDUnitName,
            ISNULL(D.UnitSeq, 0) AS OriSTDUnitSeq,
            ISNULL(A.OriQty, 0) AS OriQty,
            ISNULL(A.OriSTDQty, 0) AS OriSTDQty,
            ISNULL((SELECT UserName FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UserSeq = A.LastUserSeq), '') AS LastUserName,
            ISNULL(A.LastDateTime, '') AS LastDateTime,
            ISNULL((SELECT MinorName FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MajorSeq = 8042 AND MinorValue = B.InOutType),'') AS InOutTypeName,
            ISNULL(LotNo, '')    AS LotNo,     --2009.11.07 snheo
            ISNULL(B.UseDeptSeq, '') AS UseDeptSeq,  
            ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = B.UseDeptSeq), '') AS UseDeptName,  
            ISNULL((SELECT ValueText FROM _TDASMinorValue WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MajorSeq = 8042 AND MinorSeq = E.MinorSeq AND Serl = 1001) , '') AS FormID,
           '0',0, 0,
           '' AS SMProgressTypeName,
           0  AS SMProgressType,  -- 진행상태
           0, 0, '', -- 요청데이터
           0, 0, 
           CASE ISNULL(G.PgmId, '') WHEN '' THEN T.PgmId ELSE G.PgmId END AS JumpOutPgmId, -- 20130621 박성호 추가
 --          CASE A.InOutType WHEN 10 THEN (CASE WHEN H.InvoiceSeq IS NULL THEN 'FrmSLInvoice' ELSE 'FrmSLExpInvoice' END)   -- 거래명세표 (10.3.22 임시방편)
 --                           WHEN 11 THEN 'FrmSLReturnInvoice'   -- 반품명세표
 --                           WHEN 30 THEN 'FrmLGEtcOut'   -- 기타출고
 --                           WHEN 40 THEN 'FrmLGEtcIn'   -- 기타입고
 --                           WHEN 50 THEN (CASE WHEN ISNULL(A.PJTSeq,0) = 0 THEN 'FrmLGCommitOut' ELSE 'FrmLGCommitOut_Project' END)   -- 위탁출고
 --                           WHEN 51 THEN (CASE WHEN ISNULL(A.PJTSeq,0) = 0 THEN 'FrmLGCommitReturn' ELSE 'FrmLGCommitReturn_Project' END)   -- 위탁반품
 --                           WHEN 60 THEN 'FrmLGItemUnitConvert'   -- 단위대체
 --                           WHEN 70 THEN 'FrmLGBadIn'   -- 불량처리
 --                           WHEN 71 THEN 'FrmLGBadOut'   -- 양품처리
 --                            WHEN 80 THEN 'FrmLGMove'   -- 이동처리
 --                           WHEN 81 THEN 'FrmLGTrans'   -- 적송처리
 --                           WHEN 90 THEN 'FrmLGItemConvert'   -- 규격대체
 --                           WHEN 100 THEN 'FrmLGConsignOut'   -- 수탁출고
 --                           WHEN 110 THEN 'FrmLGConsignIn'   -- 수탁입고
 --                           WHEN 120 THEN 'FrmLGSetItemIn'   -- 세트입고처리
 --                           WHEN 130 THEN 'FrmPDSFCWorkReport'   -- 생산실적
 --                           WHEN 140 THEN 'FrmPDSFCGoodIn'   -- 생산입고
 --                           WHEN 150 THEN 'FrmPDOSPDelvIn'   -- 외주입고
 --                           WHEN 160 THEN 'FrmPUDelv'   -- 구매납품
 --                           WHEN 170 THEN 'FrmPUDelvIn'   -- 구매입고
 --                           WHEN 180 THEN 'FrmPDMMOutProc'   -- 자재출고
 --                           WHEN 190 THEN 'FrmPDOSPDelv'   -- 외주납품
 ----                             WHEN 200 THEN    -- 구매정산
 ----                             WHEN 210 THEN    -- 구매납품검사
 ----                             WHEN 220 THEN    -- AS수탁입고
 ----                             WHEN 230 THEN    -- AS수탁출고
 --                           WHEN 240 THEN 'FrmUIImpDelvery'   -- 수입입고
 --                           WHEN 250 THEN 'FrmLGVesselRecovery'   -- 용기회수
 --                           WHEN 31 THEN 'FrmLGEtcOutMat'   -- 자재기타출고
 --                           WHEN 41 THEN 'FrmLGEtcInMat'   -- 자재기타입고
 --                           WHEN 82 THEN 'FrmLGMoveMat'   -- 자재이동처리
 --                           WHEN 83 THEN 'FrmLGTransMat'   -- 자재적송처리
 ----                             WHEN 260 THEN    -- 구매후검사이동
 ----                             WHEN 84 THEN    -- 원료이동처리
 ----                             WHEN 85 THEN    -- 제품이동처리
 --                           WHEN 171 THEN 'FrmPUDelvInReturn'   -- 구매반품
 ----                             WHEN 270 THEN    -- 수입후검사이동
 --                           WHEN 280 THEN 'FrmPDQAAfterInBadItem'
 --                           WHEN 121 THEN 'FrmLGSetItemOut'
 --                           ELSE '' END,   -- 세트해체처리
           CASE A.InOutType WHEN 10 THEN 'InvoiceSeq'   -- 거래명세표
                            WHEN 11 THEN 'InvoiceSeq'   -- 반품명세표
                            WHEN 130 THEN 'WorkReportSeq'   -- 생산실적
                            WHEN 140 THEN 'GoodInSeq'   -- 생산입고
                            WHEN 150 THEN 'OSPDelvInSeq'   -- 외주입고
                            WHEN 160 THEN 'DelvSeq'   -- 구매납품
                            WHEN 170 THEN 'DelvInSeq'   -- 구매입고
                            WHEN 180 THEN 'MatOutSeq'   -- 자재불출
                            WHEN 190 THEN 'OSPDelvSeq'   -- 외주납품
                            WHEN 240 THEN 'DelvSeq'   -- 수입입고
                            WHEN 171 THEN 'DelvInSeq'   -- 구매반품
                            WHEN 280 THEN 'BadReworkSeq' -- 입고후불량재작업
                            ELSE 'InOutSeq' END, 
           '', '', -- 요청부서, 담당자
           CASE WHEN J.SMAssetGrp IN (6008002, 6008004) THEN '1' ELSE '0' END AS IsProd, --2010.11.25 sjjin 수정 IFRS용 기타입력등록화면 추가로 점프시 제품, 반제품일 경우에만 점프되도록 변경
     I.AssetName,
           ISNULL(K.PJTName, '')            AS PJTName,                         -- 프로젝트명           -- 2012.06.25 윤보라 추가
           ISNULL(K.PJTNo, '')              AS PJTNo,                           -- 프로젝트번호         -- 2012.06.25 윤보라 추가
           ISNULL(A.PJTSeq, 0)              AS PJTSeq,                          -- 프로젝트코드         -- 2012.06.25 윤보라 추가
           CASE WHEN ISNULL(A.PJTSeq,0) <> 0 THEN '1' ELSE '0' END AS IsPJT,    -- 프로젝트여부         -- 2012.06.25 윤보라 추가   
           ISNULL(CASE ISNULL(N.CustItemName, '')    
                  WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = B.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                          ELSE ISNULL(N.CustItemName, '') END, '')  AS CustItemName,     -- 거래처품명    
           ISNULL(CASE ISNULL(N.CustItemNo, '')     
                  WHEN '' THEN (SELECT CI.CustItemNo   FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = B.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                          ELSE ISNULL(N.CustItemNo, '') END, '')    AS CustItemNo,   -- 거래처품번    
           ISNULL(CASE ISNULL(N.CustItemSpec, '')     
                  WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = B.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                          ELSE ISNULL(N.CustItemSpec, '') END, '')  AS CustItemSpec,      -- 거래처품목규격  
           ISNULL(A.SerialNo, '') AS SerialNo, -- 20130430 박성호 추가
           0,0 -- ReqEmpSeq, ReqDeptSeq v2013.11.05 ADD By이재천
       FROM amoerp_TLGInOutDailyItemMerge  AS A WITH (NOLOCK)
           JOIN _TLGInOutDaily AS B WITH (NOLOCK)      ON A.CompanySeq = B.CompanySeq
                                                      AND A.InOutType  = B.InOutType
                                                      AND A.InOutSeq   = B.InOutSeq
           LEFT OUTER JOIN _TDAItem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                      AND A.ItemSeq    = C.ItemSeq
           LEFT OUTER JOIN _TDAItemAsset AS J WITH(NOLOCK)ON C.AssetSeq = J.AssetSeq 
                                                         AND C.CompanySeq = J.CompanySeq  
           LEFT OUTER JOIN _TDAItem AS D WITH (NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                      AND A.OriItemSeq = D.ItemSeq
           JOIN _TDASMinor AS E WITH (NOLOCK) ON B.CompanySeq = E.CompanySeq
                                             AND E.MajorSeq   = 8042
                                             AND B.InOutType  = E.MinorValue
           JOIN _TDASMinorValue AS F WITH (NOLOCK) ON F.CompanySeq = @CompanySeq
                                                  AND F.MajorSeq   = 8042
                                                  AND E.MinorSeq   = F.MinorSeq
                                                  AND F.Serl       = 1002
                                                  AND F.ValueText  = '1'
           LEFT OUTER JOIN _TSLExpInvoice AS H WITH (NOLOCK) ON F.CompanySeq = H.CompanySeq
                                                            AND A.InOutType IN (10, 11)
                                                            AND A.InOutSeq = H.InvoiceSeq
     LEFT OUTER JOIN _TDAItemAsset AS I WITH(NOLOCK) ON ( C.AssetSeq = I.AssetSeq AND C.CompanySeq = I.CompanySeq )
           LEFT OUTER JOIN _TPJTProject AS K WITH (NOLOCK) ON A.PJTSeq = K.PJTSeq                        -- 2012.06.25 윤보라 추가                              
                                                          AND A.CompanySeq = K.CompanySeq  
           LEFT OUTER JOIN _TDACust AS L WITH(NOLOCK) ON B.CustSeq = L.CustSeq                           -- 2012.07.09 윤보라 추가  
                                                     AND B.CompanySeq = L.CompanySeq   
           LEFT OUTER JOIN _TDACust AS M WITH(NOLOCK) ON K.CustSeq = M.CustSeq                           -- 2012.07.09 윤보라 추가  
                                                     AND K.CompanySeq = M.CompanySeq  
           LEFT OUTER JOIN _TSLCustItem  AS N WITH(NOLOCK) ON N.CompanySeq = @CompanySeq    
                                                          AND A.ItemSeq    = N.ItemSeq    
                                                          AND N.CustSeq    = B.CustSeq    
                                                 AND A.UnitSeq    = N.UnitSeq
           JOIN #JumpPgmId         AS P              ON A.InOutSeq          = P.InOutSeq
                                                    AND A.InOutType         = P.InOutType
                                                    AND A.InOutSerl         = P.InOutSerl
           JOIN _TLGInOutJumpPgmId AS G WITH(NOLOCK) ON G.CompanySeq        = @CompanySeq 
                                                    AND G.SMInOutType       = P.SMInOutType
              AND G.SMLocalKind       = P.SMLocalKind
                                                    AND G.IsReturn          = P.IsReturn
                                                    AND G.IsPMS             = P.IsPMS
           LEFT OUTER JOIN _TCAPgm AS T WITH(NOLOCK) ON ISNULL(B.PgmSeq, 0) = T.PgmSeq                    
      WHERE A.CompanySeq      = @CompanySeq
       AND (@InOutType       = 0
             OR  A.InOutType = @InOutType
             OR  (   (A.InOutType    IN (80, 81, 85) AND @InOutType  = 80)
                 OR  (A.InOutType    IN (82, 83, 84) AND @InOutType  = 82)
                 OR  (A.InOutType    IN (50, 51)     AND @InOutType  = 50)   
                 OR  (A.InOutType    IN (70, 71)     AND @InOutType  = 70)   )
             )
       AND (@BizUnit         = 0     OR  B.BizUnit           = @BizUnit)
       AND (@InOutDateFr     = ''    OR  B.InOutDate         >= @InOutDateFr)
       AND (@InOutDateTo     = ''    OR  B.InOutDate         <= @InOutDateTo)
       AND (@CompleteDateFr  = ''    OR  B.CompleteDate      >= @CompleteDateFr)
       AND (@CompleteDateTo  = ''    OR  B.CompleteDate      <= @CompleteDateTo)
       AND (@InOutNo         = ''    OR  B.InOutNo           LIKE @InOutNo + '%')
       AND (@FactUnit        = 0     OR  B.FactUnit          = @FactUnit)
       AND (@ReqBizUnit      = 0     OR  B.ReqBizUnit        = @ReqBizUnit)
       AND (@DeptSeq         = 0     OR  B.DeptSeq           = @DeptSeq)
       AND (@EmpSeq          = 0     OR  B.EmpSeq            = @EmpSeq)
       AND (@CustSeq         = 0     OR  ((   ISNULL(A.PJTSeq,0) = 0  AND B.CustSeq = @CustSeq)          -- 2012.07.09 윤보라 추가
                                          OR (ISNULL(A.PJTSeq,0) <> 0 AND K.CustSeq = @CustSeq)))
       AND (@OutWHSeq        = 0     OR  A.OutWHSeq          = @OutWHSeq)
       AND (@DVPlaceSeq      = 0     OR  B.DVPlaceSeq        = @DVPlaceSeq)
       AND (@InOutDetailType = 0     OR  B.InOutDetailType   = @InOutDetailType)
       AND (@InOutKind       = 0     OR  A.InOutKind         = @InOutKind)
       AND (@InOutDetailKind = 0     OR  A.InOutDetailKind   = @InOutDetailKind)
       AND (@ItemName        = ''    OR  C.ItemName          LIKE @ItemName + '%')
       AND (@ItemNo          = ''    OR  C.ItemNo            LIKE @ItemNo + '%')
       AND (@Spec            = ''    OR  C.Spec              LIKE @Spec + '%')
       AND (@ItemSeq         = 0     OR  A.ItemSeq           = @ItemSeq)
       AND (@UnitSeq         = 0     OR  A.UnitSeq           = @UnitSeq)
       AND (@CCtrSeq         = 0     OR  A.CCtrSeq           = @CCtrSeq)
       AND (@DVPlaceSeqItem  = 0     OR  A.DVPlaceSeq        = @DVPlaceSeqItem)
       AND (@AssetSeq        = 0     OR  C.AssetSeq          = @AssetSeq)
       AND (@InKind          = 0
             OR (@InKind     = 6043001   AND     ISNULL(B.IsCompleted, '0') = '1')
             OR (@InKind     = 6043002   AND     ISNULL(B.IsCompleted, '0') <> '1')
             )
       AND (@UseDeptSeq      = 0     OR  B.UseDeptSeq        = @UseDeptSeq) 
       AND (@LotNo           = ''    OR  A.LotNo             LIKE @LotNo + '%')
       AND ( @PJTName        = ''    OR  K.PJTName           LIKE @PJTName + '%' )
       AND ( @PJTNo          = ''    OR  K.PJTNo             LIKE @PJTNo   + '%' ) 
       AND ( @PJTComplete    = '0'   OR  K.ISComplete        = @PJTComplete )
     ORDER BY A.InOutSeq, A.InOutSerl
    /***************************************************************************************************
         진행상태
     ***************************************************************************************************/
     INSERT INTO #Temp_InOutItemProg(InOutType, InOutSeq, InOutSerl, CompleteCHECK, IsStop)
     SELECT InOutType, InOutSeq, InOutSerl, -1, '0'
       FROM #TempResult
      EXEC _SCOMProgStatus @CompanySeq, '_TLGInOutDailyItem', 1036004, '#Temp_InOutItemProg', 'InOutSeq', 'InOutSerl', 'InOutType', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', '', '', 'InOutSeq', 'InOutSerl', 'InOutType', '_TLGInOutDaily', @PgmSeq
      UPDATE #Temp_InOutItemProg
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --진행중단
                                          WHEN A.IsStop = '1' THEN 1037005 -- 중단
                                          ELSE B.MinorSeq END)
       FROM #Temp_InOutItemProg AS A
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                         AND B.MajorSeq = 1037
                                                         AND A.CompleteCHECK = B.Minorvalue
     UPDATE #TempResult
        SET SMProgressTypeName = ISNULL(C.MinorName, ''),
            SMProgressType = C.MinorSeq
       FROM #TempResult AS A
             LEFT OUTER JOIN #Temp_InOutItemProg AS B ON A.InOutType = B.InOutType
                                                     AND A.InOutSeq  = B.InOutSeq
                                                     AND A.InOutSerl = B.InOutSerl
             LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                         AND B.SMProgressType = C.MinorSeq
 -----------------------------------------------------------------------------------------------
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
      UPDATE #TempResult
        SET Amt = ISNULL(Y.Amt, 0)
       FROM #TempResult AS X
            JOIN (SELECT A.InOutType, A.InOutSeq, A.InOutSerl, MAX(C.Amt) AS Amt
                    FROM #TempResult     AS A
 --                   JOIN _TLGInOutStock  AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
 --                                                        AND A.InOutType  = B.InOutType
 --                                                        AND A.InOutSeq   = B.InOutSeq
 --                                                        AND A.InOutSerl  = B.InOutSerl
                    LEFT OUTER JOIN _TESMGInoutstock AS C WITH(NOLOCK) ON C.CompanySeq    = @CompanySeq
                                                                      AND A.InOutSeq      = C.InOutSeq
                                                                      AND A.InOutSerl     = C.InOutSerl
                                                                      AND A.InOutType     = C.InOutType
                    LEFT OUTER JOIN _TESMDCostKey    AS D WITH(NOLOCK) ON D.CompanySeq    = C.CompanySeq
                                                                      AND D.CostKeySeq    = C.CostKeySeq
                                                                      AND D.SMCostMng     = @SMCostMng
                           AND C.InOutDate     LIKE D.CostYM + '%'  
                                                                      AND D.RptUnit       = 0
                                                                      AND D.CostMngAmdSeq = 0
                                                                      AND D.PlanYear      = ''
                   GROUP BY A.InOutType, A.InOutSeq, A.InOutSerl) AS Y ON X.InOutType     = Y.InOutType
                                                                      AND X.InOutSeq      = Y.InOutSeq
                                                                      AND X.InOutSerl     = Y.InOutSerl
     WHERE X.InOutType IN (30, 31)               -- 제상품기타출고, 자재기타출고만 원가에서 금액을 가지고 오도록
  
 -----------------------------------------------------------------------------------------------
      /***************************************************************************************************
         입출고요청번호찾기
     ***************************************************************************************************/
     -- 원천테이블
     INSERT #TMP_SOURCETABLE
     SELECT 1,'_TLGInOutReqItem'   -- 입출고요청
      -- 원천데이터 찾기 (이동요청데이터)
     EXEC _SCOMSourceTracking @CompanySeq, '_TLGInOutDailyItem', '#TempResult', 'InOutSeq', 'InOutSerl', ''
      UPDATE #TempResult
        SET ReqSeq       = B.Seq,
            ReqSerl      = B.Serl,
            ReqNo        = C.ReqNo, 
            ReqDeptName  = D.DeptName, -- 요청부서
            ReqEmpName   = E.EmpName,   -- 요청자
            ReqDeptSeq   = C.DeptSeq, -- v2013.11.05 ADD By이재천
            ReqEmpSeq    = C.EmpSeq   -- v2013.11.05 ADD By이재천
       FROM #TempResult AS A
             LEFT OUTER JOIN #TCOMSourceTracking AS B ON A.IDX_NO = B.IDX_NO
             LEFT OUTER JOIN _TLGInOutReq AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                           AND B.Seq        = C.ReqSeq
             LEFT OUTER JOIN _TDADept     AS D WITH(NOLOCK) ON C.CompanySeq = D.CompanySeq
                                                           AND C.DeptSeq    = D.DeptSeq
             LEFT OUTER JOIN _TDAEmp      AS E WITH(NOLOCK) ON C.CompanySeq = E.CompanySeq                                 
                                                           AND C.EmpSeq     = E.EmpSeq
  
     --원천데이터 찾기 END
      UPDATE #TempResult
        SET IsExistsSubEtcOut = CASE WHEN ISNULL(B.EtcQty,0) = 0 THEN '0' ELSE '1' END,
            SubEtcOutQty      = ISNULL(B.EtcQty,0)
       FROM #TempResult AS A
            JOIN (SELECT X.InOutSeq, X.InOutSerl, SUM(ISNULL(Y.Qty,0)) AS EtcQty
                    FROM #TempResult AS X
                         LEFT OUTER JOIN _TLGInOutDailyItemSub AS Y WITH (NOLOCK) ON Y.CompanySeq = @CompanySeq
                                                                                 AND X.InOutType  = Y.InOutType
                                                                                 AND X.InOutSeq   = Y.InOutSeq
                                                                                 AND X.InOutSerl  = Y.InOutSerl
                                                                                 AND Y.InOutKind  = 8023003
                    GROUP BY X.InOutSeq, X.InOutSerl) AS B ON A.InOutSeq  = B.InOutSeq
                                                          AND A.InOutSerl = B.InOutSerl
  
     UPDATE #TempResult
        SET TransInQty     = ISNULL(TransQty,0),
            InWHSeq        = (CASE WHEN ISNULL(B.InWHSeq,0) = 0 THEN A.InWHSeq ELSE ISNULL(B.InWHSeq,0) END),
            InWHName       = (CASE WHEN ISNULL(B.InWHSeq,0) = 0 THEN A.InWHName ELSE ISNULL((SELECT ISNULL(WHName,'') FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = B.InWHSeq),'') END)
       FROM #TempResult AS A
            JOIN (SELECT X.InOutSeq, X.InOutSerl, Y.InWHSeq, SUM(ISNULL(Y.Qty,0)) AS TransQty
                    FROM #TempResult AS X
                         LEFT OUTER JOIN _TLGInOutDailyItemSub AS Y WITH (NOLOCK) ON Y.CompanySeq = @CompanySeq
                                                                                 AND X.InOutType  = Y.InOutType
                                                                                 AND X.InOutSeq   = Y.InOutSeq
                                                                                 AND X.InOutSerl  = Y.InOutSerl
                                                                                 AND Y.InOutKind  IN (8023008,8023012)
                    GROUP BY X.InOutSeq, X.InOutSerl, Y.InWHSeq) AS B ON A.InOutSeq  = B.InOutSeq
                                                                     AND A.InOutSerl = B.InOutSerl
     /***************************************************************************************************
         거래명세서진행수량찾기 - 위탁출고품목조회에서 사용
     ***************************************************************************************************/
     -- 진행체크할 테이블값 테이블
     CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))
      -- 진행된 내역 테이블 : _SCOMProgressTracking 에서 사용
     CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,
                                        Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))
      --select * from #TempResult
     --select * from #Temp_InOutItemProg
     INSERT #TMP_PROGRESSTABLE
     SELECT 1, '_TSLInvoiceItem'    --거래명세서
      EXEC _SCOMProgressTracking @CompanySeq, '_TLGInOutDailyItem', '#TempResult', 'InOutSeq', 'InOutSerl', 'InOutType'
      UPDATE #TempResult
        SET InvProgQty    = ISNULL(B.Qty, 0),
            InvNotProgQty = ISNULL(A.Qty, 0) - ISNULL(B.Qty, 0)
       FROM #TempResult AS A
             LEFT OUTER JOIN (SELECT IDX_NO, SUM(Qty) AS Qty FROM #TCOMProgressTracking GROUP BY IDX_NO )AS B ON A.IDX_NO  = B.IDX_NO
      --select * from #TCOMProgressTracking
  
     SELECT A.*, B.ItemClasSName, B.ItemClasMName, B.ItemClasLName 
       FROM #TempResult AS A 
       LEFT OUTER JOIN _FDAGetItemClass( @CompanySeq, 0 ) AS B ON ( A.ItemSeq = B.ItemSeq )
      WHERE (@SMProgressType = 0 OR A.SMProgressType = @SMProgressType)
        AND (@ReqNo = '' OR A.ReqNo = @ReqNo)
        AND (@InWHSeq  = 0 OR A.InWHSeq = @InWHSeq) 
        AND (@ReqDeptSeq = 0 OR A.ReqDeptSeq = @ReqDeptSeq) -- v2013.11.05 ADD By이재천
        AND (@ReqEmpSeq = 0 OR A.ReqEmpSeq = @ReqEmpSeq)    -- v2013.11.05 ADD By이재천
      ORDER BY A.InOutSeq, A.InOutSerl
   RETURN