
IF OBJECT_ID('amoerp_SLGInOutDailyListQuery') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyListQuery
GO

-- v2013.11.25 

-- 위탁출고조회_amoerp by이재천
  /*************************************************************************************************
  설  명 - 입출고현황 조회
  작성일 - 2008.10 : CREATED BY 김준모
 *************************************************************************************************/
  -- 입출고조회 - 조회 
 CREATE PROC amoerp_SLGInOutDailyListQuery
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
             @CustSeq            INT,
             @OutWHSeq           INT,
             @InWHSeq            INT,
             @DVPlaceSeq         INT,
             @InOutType          INT,
             @InOutKind          INT,
             @InOutDetailType    INT,
             @IsTrans            NCHAR(1),
             @CompleteDateFr     NCHAR(8),
             @CompleteDateTo     NCHAR(8),
             @IsCompleted        NCHAR(1),
             @SMProgressType     INT,        -- 진행상태
             @InKind             INT,        -- 입고구분
             @UseDeptSeq         INT,
             @PJTName            NVARCHAR(200),    -- 2012.06.25 윤보라 추가    
             @PJTNo              NVARCHAR(100), 
             @ReqDeptSeq         INT,  -- v2013.11.05 ADD By이재천
             @ReqEmpSeq          INT   -- v2013.11.05 ADD By이재천 
  
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
             @CustSeq            = ISNULL(CustSeq,0),
             @OutWHSeq           = ISNULL(OutWHSeq,0),
             @InWHSeq            = ISNULL(InWHSeq,0),
             @DVPlaceSeq         = ISNULL(DVPlaceSeq,0),
             @InOutType          = ISNULL(InOutType,0),
             @InOutKind          = ISNULL(InOutKind,0),
             @InOutDetailType    = ISNULL(InOutDetailType,0),
             @IsTrans            = ISNULL(IsTrans,''),
             @CompleteDateFr     = ISNULL(CompleteDateFr,''),
             @CompleteDateTo     = ISNULL(CompleteDateTo,''),
             @IsCompleted        = ISNULL(IsCompleted,''),
             @SMProgressType     = ISNULL(SMProgressType, 0),
             @InKind             = ISNULL(InKind, 0),
             @UseDeptSeq         = ISNULL(UseDeptSeq, 0),
             @PJTName            = ISNULL(PJTName, ''),
             @PJTNo              = ISNULL(PJTNo, ''), 
             @ReqDeptSeq         = ISNULL(ReqDeptSeq, 0), 
             @ReqEmpSeq          = ISNULL(ReqEmpSeq, 0)  
             
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
             CustSeq            INT,
             OutWHSeq           INT,
             InWHSeq            INT,
             DVPlaceSeq         INT,
             InOutType          INT,
             InOutKind          INT,
             InOutDetailType    INT,
             IsTrans            NCHAR(1),
             CompleteDateFr     NCHAR(8),
             CompleteDateTo     NCHAR(8),
             IsCompleted        NCHAR(1),
             SMProgressType     INT,
             InKind             INT,
             UseDeptSeq         INT,
             PJTName            NVARCHAR(200),
             PJTNo              NVARCHAR(100), 
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
             @CustSeq            = ISNULL(LTRIM(RTRIM(@CustSeq)),0),
             @OutWHSeq           = ISNULL(LTRIM(RTRIM(@OutWHSeq)),0),
             @InWHSeq            = ISNULL(LTRIM(RTRIM(@InWHSeq)),0),
             @DVPlaceSeq         = ISNULL(LTRIM(RTRIM(@DVPlaceSeq)),0),
             @InOutType          = ISNULL(LTRIM(RTRIM(@InOutType)),0),
             @InOutDetailType    = ISNULL(LTRIM(RTRIM(@InOutDetailType)),0),
             @IsTrans            = ISNULL(LTRIM(RTRIM(@IsTrans)),''),
             @CompleteDateFr     = ISNULL(LTRIM(RTRIM(@CompleteDateFr)),''),
             @CompleteDateTo     = ISNULL(LTRIM(RTRIM(@CompleteDateTo)),''),
             @IsCompleted        = ISNULL(LTRIM(RTRIM(@IsCompleted)),''),
             @SMProgressType     = ISNULL(LTRIM(RTRIM(@SMProgressType)), 0),
             @UseDeptSeq         = ISNULL(LTRIM(RTRIM(@UseDeptSeq)), 0),
             @PJTName            = ISNULL(LTRIM(RTRIM(@PJTName)),''),
             @PJTNo              = ISNULL(LTRIM(RTRIM(@PJTNo)),''),
             @ReqDeptSeq         = ISNULL(LTRIM(RTRIM(@ReqDeptSeq)),0), 
             @ReqEmpSeq          = ISNULL(LTRIM(RTRIM(@ReqEmpSeq)),0) 
              
     -- 입출고진행 Table
     CREATE TABLE #Temp_InOutProg
     (
         IDX_NO INT IDENTITY, 
         InOutType INT, 
         InOutSeq INT, 
         CompleteCHECK INT, 
         SMProgressType INT NULL, 
         IsStop NCHAR(1),
         OutWHSeq INT, 
         InWHSeq INT,
         IsProd NCHAR(1) 
     )
      INSERT INTO #Temp_InOutProg(InOutType, InOutSeq, CompleteCHECK, IsStop, OutWHSeq, InWHSeq, IsProd )
     SELECT A.InOutType, A.InOutSeq, -1, '0', 
            MAX(ISNULL( F.OutWHSeq, (CASE ISNULL(E.OutWHSeq,0) WHEN 0 THEN A.OutWHSeq ELSE E.OutWHSeq END) )),
            MAX(ISNULL( F.InWHSeq, (CASE ISNULL(E.InWHSeq,0) WHEN 0 THEN A.InWHSeq ELSE E.InWHSeq END) )),
            (CASE SUM(1) WHEN SUM(CASE WHEN H.SMAssetGrp IN (6008002, 6008004) THEN 1 ELSE 0 END) THEN '1' ELSE '0' END) 
       FROM _TLGInOutDaily    AS A WITH (NOLOCK)
       JOIN _TDASMinor        AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND B.MajorSeq = 8042 AND A.InOutType  = B.MinorValue
       JOIN _TDASMinorValue   AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.MajorSeq = 8042 AND B.MinorSeq = D.MinorSeq AND D.Serl = 1002 AND D.ValueText = '1' -- 입출고테이블 
       JOIN amoerp_TLGInOutDailyItemMerge               AS E WITH(NOLOCK) ON ( A.CompanySeq = E.CompanySeq AND A.InOutType = E.InOutType AND A.InOutSeq = E.InOutSeq )
       LEFT OUTER JOIN _TLGInOutDailyItemSub AS F WITH(NOLOCK) ON ( E.CompanySeq = F.CompanySeq AND E.InOutType = F.InOutType AND E.InOutSeq = F.InOutSeq AND E.InOutSerl = F.InOutSerl AND F.InOutKind IN (8023008, 8023012) )
       JOIN _TDAItem                         AS G WITH(NOLOCK) ON ( E.CompanySeq = G.CompanySeq AND E.ItemSeq = G.ItemSeq )
       JOIN _TDAItemAsset                    AS H WITH(NOLOCK) ON ( G.CompanySeq = H.CompanySeq AND G.AssetSeq = H.AssetSeq )
      WHERE A.CompanySeq      = @CompanySeq
        AND (@InOutType       = 0
             OR  A.InOutType = @InOutType
             OR (    (A.InOutType    IN (80, 81, 85)     AND     @InOutType  = 80)
                 OR  (A.InOutType    IN (82, 83, 84)     AND     @InOutType  = 82)
                 OR  (A.InOutType    IN (50, 51)         AND     @InOutType  = 50)   )
             )
        AND (@BizUnit         = 0     OR  A.BizUnit           = @BizUnit)
        AND (@InOutDateFr     = ''    OR  A.InOutDate         >= @InOutDateFr)
        AND (@InOutDateTo     = ''    OR  A.InOutDate         <= @InOutDateTo)
        AND (@CompleteDateFr  = ''    OR  A.CompleteDate      >= @CompleteDateFr)
        AND (@CompleteDateTo  = ''    OR  A.CompleteDate      <= @CompleteDateTo)
        AND (@InOutNo         = ''    OR  A.InOutNo           LIKE @InOutNo + '%')
        AND (@FactUnit        = 0     OR  A.FactUnit          = @FactUnit)
        AND (@ReqBizUnit      = 0     OR  A.ReqBizUnit        = @ReqBizUnit)
        AND (@DeptSeq         = 0     OR  A.DeptSeq           = @DeptSeq)
        AND (@EmpSeq          = 0     OR  A.EmpSeq            = @EmpSeq)
        AND (@CustSeq         = 0     OR  A.CustSeq           = @CustSeq)
        AND ( @OutWHSeq = 0 OR F.OutWHSeq = @OutWHSeq OR E.OutWHSeq = @OutWHSeq OR A.OutWHSeq = @OutWHSeq )
        AND ( @InWHSeq = 0  OR F.InWHSeq = @InWHSeq   OR E.InWHSeq = @InWHSeq   OR A.InWHSeq = @InWHSeq )
        AND (@DVPlaceSeq      = 0     OR  A.DVPlaceSeq        = @DVPlaceSeq)
        AND (@InOutDetailType = 0     OR  A.InOutDetailType   = @InOutDetailType)
        AND (@IsTrans         = ''    OR  A.IsTrans           = @IsTrans)
        AND (@IsCompleted     = ''    OR  A.IsCompleted       = @IsCompleted)
        AND (@UseDeptSeq      = 0     OR  A.UseDeptSeq        = @UseDeptSeq)
      GROUP BY A.InOutType, A.InOutSeq 
      EXEC _SCOMProgStatus @CompanySeq, '_TLGInOutDailyItem', 1036004, '#Temp_InOutProg', 'InOutSeq', '', 'InOutType', '', '', '', '', '', 'CompleteCHECK', 1, 'Qty', 'STDQty', '', '', 'InOutSeq', 'InOutSerl', 'InOutType', '_TLGInOutDaily', @PgmSeq
     
     UPDATE #Temp_InOutProg
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --진행중단
                                          WHEN A.IsStop = '1' THEN 1037005 -- 중단
                                          ELSE B.MinorSeq END)
       FROM #Temp_InOutProg AS A
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                         AND B.MajorSeq = 1037
                                                         AND A.CompleteCHECK = B.Minorvalue
  
     -- 입출고요청데이터찾기,  2013.11.06 ADD By이재천 
   
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))  
   
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,  
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))  
   
     INSERT #TMP_SOURCETABLE  
     SELECT 1,'_TLGInOutReqItem'   -- 입출고요청  
   
     EXEC _SCOMSourceTracking @CompanySeq, '_TLGInOutDailyItem', '#Temp_InOutProg', 'InOutSeq', '', ''  
   
     -- 입출고요청데이터찾기, END  
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
         IsPMS       NCHAR(1)
     )
      INSERT INTO #JumpPgmId ( SMInOutType, InOutType, InOutSeq, SMLocalKind, IsReturn, IsPMS )
     SELECT D.MinorSeq, A.InOutType, A.InOutSeq, 8918001, '0', '0'
       FROM #Temp_InOutProg            AS X
            JOIN _TLGInOutDaily        AS A WITH(NOLOCK) ON X.InOutType  = A.InOutType
                                                        AND X.InOutSeq   = A.InOutSeq
            JOIN _TDASMinor            AS D WITH(NOLOCK) ON D.MinorValue = A.InOutType
                                                        AND D.MajorSeq   = 8042
                                                        AND D.CompanySeq = @CompanySeq
            JOIN ( SELECT E.CompanySeq, E.InOutType, E.InOutSeq, MAX(E.PJTSeq)  AS PJTSeq, 
                                                                 MAX(F.PJTName) AS PJTName, 
                                                                 MAX(F.PJTNo)   AS PJTNo
                     FROM amoerp_TLGInOutDailyItemMerge           AS E WITH(NOLOCK)
                          LEFT OUTER JOIN _TPJTProject AS F WITH(NOLOCK) ON E.PJTSeq     = F.PJTSeq 
                                          AND E.CompanySeq = F.CompanySeq
                    GROUP BY E.CompanySeq, E.InOutType, E.InOutSeq ) AS G ON A.CompanySeq = G.CompanySeq 
                                                                         AND A.InOutType  = G.InOutType  
                                                                         AND A.InOutSeq   = G.InOutSeq
      WHERE A.CompanySeq = @CompanySeq
        AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)
        AND (@InKind = 0 OR (@InKind = 6043001 AND ISNULL(A.IsCompleted, '0')  = '1')
                         OR (@InKind = 6043002 AND ISNULL(A.IsCompleted, '0') <> '1'))
        AND (@PJTName = '' OR G.PJTName LIKE @PJTName + '%')
        AND (@PJTNo   = '' OR G.PJTNo   LIKE @PJTNo   + '%')
      GROUP BY D.MinorSeq, A.InOutType, A.InOutSeq
  
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
      -- 입출고요청 마스터 데이터 담기 v2013.11.06 ADD By이재천
     SELECT IDX_NO, IDOrder, Seq, MAX(C.EmpName) AS ReqEmpName, 
            MAX(D.DeptName) AS ReqDeptName, MAX(B.DeptSeq) AS ReqDeptSeq, MAX(B.EmpSeq) AS ReqEmpSeq
       INTO #TCOMSourceTrackingSub  
       FROM #TCOMSourceTracking AS A 
       JOIN _TLGInOutReq        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.Seq ) 
       LEFT OUTER JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.EmpSeq ) 
       LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq ) 
      GROUP BY IDX_NO, IDOrder, Seq
     -- END,  
      -- 최종조회
     SELECT  A.InOutSeq      AS InOutSeq,
             ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND BizUnit = A.BizUnit), '') AS BizUnitName,
             ISNULL(A.BizUnit, 0)  AS BizUnit,
             ISNULL(A.InOutNo, '')   AS InOutNo,
             ISNULL((SELECT FactUnitName FROM _TDAFactUnit WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND FactUnit = A.FactUnit), '') AS FactUnitName,
             ISNULL(A.FactUnit, 0) AS FactUnit,
             ISNULL((SELECT BizUnitName FROM _TDABizUnit WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND BizUnit = A.ReqBizUnit), '') AS ReqBizUnitName,
             ISNULL(A.ReqBizUnit, 0) AS ReqBizUnit,
             ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq), '') AS DeptName,
             ISNULL(A.DeptSeq, 0) AS DeptSeq,
             ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND EmpSeq = A.EmpSeq), '') AS EmpName,
             ISNULL(A.EmpSeq, 0)  AS EmpSeq,
             ISNULL(A.InOutDate, '') AS InOutDate,
             ISNULL((SELECT CustName FROM _TDACust WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND CustSeq = A.CustSeq), '') AS CustName,
             ISNULL(A.CustSeq, 0) AS CustSeq,
             ISNULL((SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = X.OutWHSeq), '') AS OutWHName,
             ISNULL(X.OutWHSeq, 0) AS OutWHSeq,
             ISNULL((SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = X.InWHSeq), '') AS InWHName,
             ISNULL(X.InWHSeq, 0) AS InWHSeq,
             ISNULL(A.DVPlaceSeq, 0) AS DVPlaceSeq,
             ISNULL((SELECT DVPlaceName FROM _TSLDeliveryCust WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND DVPlaceSeq = A.DVPlaceSeq), '') AS DVPlaceName,
             ISNULL(A.IsTrans, '0')   AS IsTrans,
             ISNULL(A.CompleteDate,'') AS CompleteDate,
             ISNULL(A.IsCompleted, '0') AS IsCompleted,   -- 입고여부
             ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.CompleteDeptSeq), '') AS CompleteDeptName,
             ISNULL(A.CompleteDeptSeq, 0) AS CompleteDeptSeq,
             ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND EmpSeq = A.CompleteEmpSeq), '') AS CompleteEmpName,
             ISNULL(A.CompleteEmpSeq, 0) AS CompleteEmpSeq,
             ISNULL(A.InOutType, 0) AS InOutType,
             ISNULL(B.MinorName,'') AS InOutTypeName,
             ISNULL(A.InOutDetailType, 0) AS InOutDetailType,
             ISNULL(A.Remark, '') AS Remark,
             ISNULL(A.Memo, '') AS Memo,
             ISNULL(C.MinorName, '')  AS  SMProgressTypeName,  -- 진행상태
             ISNULL((SELECT UserName FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UserSeq = A.LastUserSeq), '') AS LastUserName,
             ISNULL(A.LastDateTime, '') AS LastDateTime,
             ISNULL((SELECT ValueText FROM _TDASMinorValue WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MajorSeq = 8042 AND MinorSeq = B.MinorSeq AND Serl = 1001) , '') AS FormID,
             ISNULL(A.UseDeptSeq, '') AS UseDeptSeq,
             ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.UseDeptSeq), '') AS UseDeptName, 
             CASE ISNULL(I.PgmId, '') WHEN '' THEN T.PgmId ELSE I.PgmId END AS JumpOutPgmId, -- 20130621 박성호 추가
             --CASE A.InOutType WHEN 10 THEN (CASE WHEN H.InvoiceSeq IS NULL THEN 'FrmSLInvoice' ELSE 'FrmSLExpInvoice' END)   -- 거래명세표 (10.3.22 임시방편)  
             --               WHEN 11 THEN 'FrmSLReturnInvoice'   -- 반품명세표  
             --               WHEN 30 THEN 'FrmLGEtcOut'   -- 기타출고  
             --               WHEN 40 THEN 'FrmLGEtcIn'   -- 기타입고  
             --               WHEN 50 THEN (CASE WHEN ISNULL(G.PJTSeq,0) = 0 THEN 'FrmLGCommitOut' ELSE 'FrmLGCommitOut_Project' END)   -- 위탁출고  
             --               WHEN 51 THEN (CASE WHEN ISNULL(G.PJTSeq,0) = 0 THEN 'FrmLGCommitReturn' ELSE 'FrmLGCommitReturn_Project' END)   -- 위탁반품  
             --               WHEN 60 THEN 'FrmLGItemUnitConvert'   -- 단위대체  
             --               WHEN 70 THEN 'FrmLGBadIn'   -- 불량처리  
             --               WHEN 71 THEN 'FrmLGBadOut'   -- 양품처리  
             --               WHEN 80 THEN 'FrmLGMove'   -- 이동처리  
             --               WHEN 81 THEN 'FrmLGTrans'   -- 적송처리  
             --               WHEN 90 THEN 'FrmLGItemConvert'   -- 규격대체  
             --               WHEN 100 THEN 'FrmLGConsignOut'   -- 수탁출고  
             --               WHEN 110 THEN 'FrmLGConsignIn'   -- 수탁입고  
             --               WHEN 120 THEN 'FrmLGSetItemIn'   -- 세트입고처리  
             --               WHEN 130 THEN 'FrmPDSFCWorkReport'   -- 생산실적  
             --               WHEN 140 THEN 'FrmPDSFCGoodIn'   -- 생산입고  
             --               WHEN 150 THEN 'FrmPDOSPDelvIn'   -- 외주입고  
             --               WHEN 160 THEN 'FrmPUDelv'   -- 구매납품  
             --               WHEN 170 THEN 'FrmPUDelvIn'   -- 구매입고  
             --               WHEN 180 THEN 'FrmPDMMOutProc'   -- 자재출고  
             --               WHEN 190 THEN 'FrmPDOSPDelv'   -- 외주납품  
             --               WHEN 240 THEN 'FrmUIImpDelvery'   -- 수입입고  
             --               WHEN 250 THEN 'FrmLGVesselRecovery'   -- 용기회수  
             --               WHEN 31 THEN 'FrmLGEtcOutMat'   -- 자재기타출고  
             --               WHEN 41 THEN 'FrmLGEtcInMat'   -- 자재기타입고  
             --               WHEN 82 THEN 'FrmLGMoveMat'   -- 자재이동처리  
             --               WHEN 83 THEN 'FrmLGTransMat'   -- 자재적송처리  
             --               WHEN 171 THEN 'FrmPUDelvInReturn'   -- 구매반품  
             --               WHEN 280 THEN 'FrmPDQAAfterInBadItem'  
             --               WHEN 121 THEN 'FrmLGSetItemOut'  
             --               ELSE '' END      AS JumpOutPgmId,   
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
                            ELSE 'InOutSeq' END AS ColumnName,
             X.IsProd,
             
             ISNULL(G.PJTSeq, 0) AS PJTSeq,                                       -- 프로젝트코드             -- 2012.06.25 윤보라 추가
             ISNULL(G.PJTName, '') AS PJTName,                                    -- 프로젝트명
             ISNULL(G.PJTNo, '') AS PJTNo,                                        -- 프로젝트번호
             CASE WHEN ISNULL(G.PJTSeq,0) <> 0 THEN '1' ELSE '0' END AS IsPJT     -- 프로젝트여부      
             ,F.ReqDeptSeq AS ReqDeptSeq   -- v2013.11.06 ADD By이재천
             ,F.ReqEmpSeq AS ReqEmpSeq     -- v2013.11.06 ADD By이재천
             ,F.ReqDeptName AS ReqDeptName -- v2013.11.06 ADD By이재천
             ,F.ReqEmpName AS ReqEmpName   -- v2013.11.06 ADD By이재천
      FROM #Temp_InOutProg AS X
             JOIN _TLGInOutDaily AS A WITH (NOLOCK) ON X.InOutType = A.InOutType
                                                   AND X.InOutSeq  = A.InOutSeq
             JOIN _TDASMinor AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                               AND B.MajorSeq   = 8042
                                               AND A.InOutType  = B.MinorValue
             JOIN _TDASMinorValue AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq
                                                    AND D.MajorSeq   = 8042
                                                    AND B.MinorSeq   = D.MinorSeq
                                                    AND D.Serl       = 1002
                                                    AND D.ValueText  = '1'
            LEFT OUTER JOIN _TSLExpInvoice AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq
                                                             AND A.InOutType IN (10, 11)  
                                                             AND A.InOutSeq = H.InvoiceSeq  
            LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                        AND X.SMProgressType = C.MinorSeq
            -- ※ 마감작업 때문에 item없이 마스터 데이터만 생성되는 case를 위해 ..
            -- ※ item테이블과 join하여 item 데이터가 없는 건은 조회되지 않게 하기 위해 .. 
            -- ※ 여기서는 방법이 없이 JOIN하는 것이 최선임 
            JOIN ( SELECT E.CompanySeq, E.InOutType, E.InOutSeq,                                 -- 2012.06.25 윤보라 추가
                                     MAX(E.PJTSeq)  AS PJTSeq, 
                                     MAX(F.PJTName)     AS PJTName, 
                                     MAX(F.PJTNo)  AS PJTNo
                                FROM amoerp_TLGInOutDailyItemMerge  AS E 
                                LEFT OUTER JOIN _TPJTProject AS F WITH (NOLOCK) ON E.PJTSeq     = F.PJTSeq 
                                                 AND E.CompanySeq = F.CompanySeq
                            GROUP BY E.CompanySeq, E.InOutType, E.InOutSeq ) AS G ON A.CompanySeq = G.CompanySeq 
                                                                                 AND A.InOutType  = G.InOutType  
                                                                                 AND A.InOutSeq   = G.InOutSeq
           JOIN #JumpPgmId         AS P              ON A.InOutSeq          = P.InOutSeq
                                                    AND A.InOutType         = P.InOutType
           JOIN _TLGInOutJumpPgmId AS I WITH(NOLOCK) ON I.CompanySeq        = @CompanySeq 
                                                    AND I.SMInOutType       = P.SMInOutType
                                                    AND I.SMLocalKind       = P.SMLocalKind
                                                    AND I.IsReturn          = P.IsReturn
                                                    AND I.IsPMS             = P.IsPMS
           LEFT OUTER JOIN _TCAPgm AS T WITH(NOLOCK) ON ISNULL(A.PgmSeq, 0) = T.PgmSeq        
           LEFT OUTER JOIN #TCOMSourceTrackingSub AS F ON ( F.IDX_NO = X.IDX_NO )                                      -- v2013.11.06 ADD By이재천
           
      WHERE A.CompanySeq  = @CompanySeq
        AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)
        AND (@InKind = 0 OR (@InKind = 6043001 AND ISNULL(A.IsCompleted, '0') = '1')
                        OR (@InKind = 6043002 AND ISNULL(A.IsCompleted, '0') <> '1'))
        AND ( @PJTName = '' OR G.PJTName LIKE @PJTName + '%' )
        AND ( @PJTNo = ''   OR G.PJTNo   LIKE @PJTNo + '%' ) 
        AND ( @ReqDeptSeq = 0 OR F.ReqDeptSeq = @ReqDeptSeq ) -- v2013.11.06 ADD By이재천
        AND ( @ReqEmpSeq = 0 OR F.ReqEmpSeq = @ReqEmpSeq )    -- v2013.11.06 ADD By이재천
      ORDER BY A.InOutDate
      
     RETURN