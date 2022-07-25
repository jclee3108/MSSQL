
IF OBJECT_ID('amoerp_SLGInOutDailyListQuery') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyListQuery
GO

-- v2013.11.25 

-- ��Ź�����ȸ_amoerp by����õ
  /*************************************************************************************************
  ��  �� - �������Ȳ ��ȸ
  �ۼ��� - 2008.10 : CREATED BY ���ظ�
 *************************************************************************************************/
  -- �������ȸ - ��ȸ 
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
             @SMProgressType     INT,        -- �������
             @InKind             INT,        -- �԰���
             @UseDeptSeq         INT,
             @PJTName            NVARCHAR(200),    -- 2012.06.25 ������ �߰�    
             @PJTNo              NVARCHAR(100), 
             @ReqDeptSeq         INT,  -- v2013.11.05 ADD By����õ
             @ReqEmpSeq          INT   -- v2013.11.05 ADD By����õ 
  
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
              
     -- ��������� Table
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
       JOIN _TDASMinorValue   AS D WITH (NOLOCK) ON D.CompanySeq = @CompanySeq AND D.MajorSeq = 8042 AND B.MinorSeq = D.MinorSeq AND D.Serl = 1002 AND D.ValueText = '1' -- ��������̺� 
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
        SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --�����ߴ�
                                          WHEN A.IsStop = '1' THEN 1037005 -- �ߴ�
                                          ELSE B.MinorSeq END)
       FROM #Temp_InOutProg AS A
             LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                         AND B.MajorSeq = 1037
                                                         AND A.CompleteCHECK = B.Minorvalue
  
     -- ������û������ã��,  2013.11.06 ADD By����õ 
   
     CREATE TABLE #TMP_SOURCETABLE (IDOrder INT, TABLENAME   NVARCHAR(100))  
   
     CREATE TABLE #TCOMSourceTracking (IDX_NO INT,             IDOrder INT,            Seq  INT,            Serl  INT,        SubSerl     INT,  
                                       Qty    DECIMAL(19, 5),  STDQty  DECIMAL(19, 5), Amt  DECIMAL(19, 5), VAT   DECIMAL(19, 5))  
   
     INSERT #TMP_SOURCETABLE  
     SELECT 1,'_TLGInOutReqItem'   -- ������û  
   
     EXEC _SCOMSourceTracking @CompanySeq, '_TLGInOutDailyItem', '#Temp_InOutProg', 'InOutSeq', '', ''  
   
     -- ������û������ã��, END  
      /*************** Get PgmId by InOutType [20130621 �ڼ�ȣ �߰�] ***************/
     
     -- _TLGInOutJumpPgmId�� InOutType�� PgmId�� �����մϴ�. -> ( sp_help _TLGInOutJumpPgmId / SELECT * FROM _TLGInOutJumpPgmId )
     -- �ϴ� #JumpPgmId�� �� ���а�(Local����, ��ǰ����, ������Ʈ����)�� ���� ������ ���� INSERT �� ��,
     -- ��ȸ���ǿ� �ش��ϴ� �����͸� �����Ͽ� ���� ���� UPDATE �� �ݴϴ�.
     -- �̷��� UPDATE �� #JumpPgmId�� ����, _TLGInOutJumpPgmId�� JOIN�Ͽ� PgmId�� ��ȸ�մϴ�.
      
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
  
     /* ������Ʈ ���� UPDATE */
     UPDATE #JumpPgmId
        SET IsPMS = '1'
       FROM #JumpPgmId                AS A
            JOIN _TLGInOutDaily       AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                       AND A.InOutType  = B.InOutType
            JOIN _TSLInvoice          AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                       AND B.InOutType  IN (10, 11)
                                                       AND B.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.IsPJT, '') = '1'
         
      /* �������ⱸ�� UPDATE */
      -- �ŷ���ǥ(10) & ��ǰ��ǥ(11)
     UPDATE #JumpPgmId
        SET SMLocalKind = 8918002
       FROM #JumpPgmId                     AS A
            JOIN _TLGInOutDaily            AS B WITH(NOLOCK) ON A.InOutSeq   = B.InOutSeq
                                                            AND A.InOutType  = B.InOutType
            LEFT OUTER JOIN _TSLExpInvoice AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                            AND A.InOutType  IN (10, 11)
                                                            AND A.InOutSeq   = C.InvoiceSeq
      WHERE ISNULL(C.InvoiceSeq, 0) <> 0
      -- �ǸŸ���(20)
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
  
     /*****  ��ǰ���� UPDATE *****/
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
      -- ������û ������ ������ ��� v2013.11.06 ADD By����õ
     SELECT IDX_NO, IDOrder, Seq, MAX(C.EmpName) AS ReqEmpName, 
            MAX(D.DeptName) AS ReqDeptName, MAX(B.DeptSeq) AS ReqDeptSeq, MAX(B.EmpSeq) AS ReqEmpSeq
       INTO #TCOMSourceTrackingSub  
       FROM #TCOMSourceTracking AS A 
       JOIN _TLGInOutReq        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.Seq ) 
       LEFT OUTER JOIN _TDAEmp  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.EmpSeq ) 
       LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = B.DeptSeq ) 
      GROUP BY IDX_NO, IDOrder, Seq
     -- END,  
      -- ������ȸ
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
             ISNULL(A.IsCompleted, '0') AS IsCompleted,   -- �԰���
             ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.CompleteDeptSeq), '') AS CompleteDeptName,
             ISNULL(A.CompleteDeptSeq, 0) AS CompleteDeptSeq,
             ISNULL((SELECT EmpName FROM _TDAEmp WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND EmpSeq = A.CompleteEmpSeq), '') AS CompleteEmpName,
             ISNULL(A.CompleteEmpSeq, 0) AS CompleteEmpSeq,
             ISNULL(A.InOutType, 0) AS InOutType,
             ISNULL(B.MinorName,'') AS InOutTypeName,
             ISNULL(A.InOutDetailType, 0) AS InOutDetailType,
             ISNULL(A.Remark, '') AS Remark,
             ISNULL(A.Memo, '') AS Memo,
             ISNULL(C.MinorName, '')  AS  SMProgressTypeName,  -- �������
             ISNULL((SELECT UserName FROM _TCAUser WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND UserSeq = A.LastUserSeq), '') AS LastUserName,
             ISNULL(A.LastDateTime, '') AS LastDateTime,
             ISNULL((SELECT ValueText FROM _TDASMinorValue WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND MajorSeq = 8042 AND MinorSeq = B.MinorSeq AND Serl = 1001) , '') AS FormID,
             ISNULL(A.UseDeptSeq, '') AS UseDeptSeq,
             ISNULL((SELECT DeptName FROM _TDADept WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DeptSeq = A.UseDeptSeq), '') AS UseDeptName, 
             CASE ISNULL(I.PgmId, '') WHEN '' THEN T.PgmId ELSE I.PgmId END AS JumpOutPgmId, -- 20130621 �ڼ�ȣ �߰�
             --CASE A.InOutType WHEN 10 THEN (CASE WHEN H.InvoiceSeq IS NULL THEN 'FrmSLInvoice' ELSE 'FrmSLExpInvoice' END)   -- �ŷ���ǥ (10.3.22 �ӽù���)  
             --               WHEN 11 THEN 'FrmSLReturnInvoice'   -- ��ǰ��ǥ  
             --               WHEN 30 THEN 'FrmLGEtcOut'   -- ��Ÿ���  
             --               WHEN 40 THEN 'FrmLGEtcIn'   -- ��Ÿ�԰�  
             --               WHEN 50 THEN (CASE WHEN ISNULL(G.PJTSeq,0) = 0 THEN 'FrmLGCommitOut' ELSE 'FrmLGCommitOut_Project' END)   -- ��Ź���  
             --               WHEN 51 THEN (CASE WHEN ISNULL(G.PJTSeq,0) = 0 THEN 'FrmLGCommitReturn' ELSE 'FrmLGCommitReturn_Project' END)   -- ��Ź��ǰ  
             --               WHEN 60 THEN 'FrmLGItemUnitConvert'   -- ������ü  
             --               WHEN 70 THEN 'FrmLGBadIn'   -- �ҷ�ó��  
             --               WHEN 71 THEN 'FrmLGBadOut'   -- ��ǰó��  
             --               WHEN 80 THEN 'FrmLGMove'   -- �̵�ó��  
             --               WHEN 81 THEN 'FrmLGTrans'   -- ����ó��  
             --               WHEN 90 THEN 'FrmLGItemConvert'   -- �԰ݴ�ü  
             --               WHEN 100 THEN 'FrmLGConsignOut'   -- ��Ź���  
             --               WHEN 110 THEN 'FrmLGConsignIn'   -- ��Ź�԰�  
             --               WHEN 120 THEN 'FrmLGSetItemIn'   -- ��Ʈ�԰�ó��  
             --               WHEN 130 THEN 'FrmPDSFCWorkReport'   -- �������  
             --               WHEN 140 THEN 'FrmPDSFCGoodIn'   -- �����԰�  
             --               WHEN 150 THEN 'FrmPDOSPDelvIn'   -- �����԰�  
             --               WHEN 160 THEN 'FrmPUDelv'   -- ���ų�ǰ  
             --               WHEN 170 THEN 'FrmPUDelvIn'   -- �����԰�  
             --               WHEN 180 THEN 'FrmPDMMOutProc'   -- �������  
             --               WHEN 190 THEN 'FrmPDOSPDelv'   -- ���ֳ�ǰ  
             --               WHEN 240 THEN 'FrmUIImpDelvery'   -- �����԰�  
             --               WHEN 250 THEN 'FrmLGVesselRecovery'   -- ���ȸ��  
             --               WHEN 31 THEN 'FrmLGEtcOutMat'   -- �����Ÿ���  
             --               WHEN 41 THEN 'FrmLGEtcInMat'   -- �����Ÿ�԰�  
             --               WHEN 82 THEN 'FrmLGMoveMat'   -- �����̵�ó��  
             --               WHEN 83 THEN 'FrmLGTransMat'   -- ��������ó��  
             --               WHEN 171 THEN 'FrmPUDelvInReturn'   -- ���Ź�ǰ  
             --               WHEN 280 THEN 'FrmPDQAAfterInBadItem'  
             --               WHEN 121 THEN 'FrmLGSetItemOut'  
             --               ELSE '' END      AS JumpOutPgmId,   
           CASE A.InOutType WHEN 10 THEN 'InvoiceSeq'   -- �ŷ���ǥ  
                            WHEN 11 THEN 'InvoiceSeq'   -- ��ǰ��ǥ  
                            WHEN 130 THEN 'WorkReportSeq'   -- �������  
                            WHEN 140 THEN 'GoodInSeq'   -- �����԰�  
                            WHEN 150 THEN 'OSPDelvInSeq'   -- �����԰�  
                            WHEN 160 THEN 'DelvSeq'   -- ���ų�ǰ  
                            WHEN 170 THEN 'DelvInSeq'   -- �����԰�  
                            WHEN 180 THEN 'MatOutSeq'   -- �������  
                            WHEN 190 THEN 'OSPDelvSeq'   -- ���ֳ�ǰ  
                            WHEN 240 THEN 'DelvSeq'   -- �����԰�  
                            WHEN 171 THEN 'DelvInSeq'   -- ���Ź�ǰ  
                            WHEN 280 THEN 'BadReworkSeq' -- �԰��ĺҷ����۾�  
                            ELSE 'InOutSeq' END AS ColumnName,
             X.IsProd,
             
             ISNULL(G.PJTSeq, 0) AS PJTSeq,                                       -- ������Ʈ�ڵ�             -- 2012.06.25 ������ �߰�
             ISNULL(G.PJTName, '') AS PJTName,                                    -- ������Ʈ��
             ISNULL(G.PJTNo, '') AS PJTNo,                                        -- ������Ʈ��ȣ
             CASE WHEN ISNULL(G.PJTSeq,0) <> 0 THEN '1' ELSE '0' END AS IsPJT     -- ������Ʈ����      
             ,F.ReqDeptSeq AS ReqDeptSeq   -- v2013.11.06 ADD By����õ
             ,F.ReqEmpSeq AS ReqEmpSeq     -- v2013.11.06 ADD By����õ
             ,F.ReqDeptName AS ReqDeptName -- v2013.11.06 ADD By����õ
             ,F.ReqEmpName AS ReqEmpName   -- v2013.11.06 ADD By����õ
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
            -- �� �����۾� ������ item���� ������ �����͸� �����Ǵ� case�� ���� ..
            -- �� item���̺�� join�Ͽ� item �����Ͱ� ���� ���� ��ȸ���� �ʰ� �ϱ� ���� .. 
            -- �� ���⼭�� ����� ���� JOIN�ϴ� ���� �ּ��� 
            JOIN ( SELECT E.CompanySeq, E.InOutType, E.InOutSeq,                                 -- 2012.06.25 ������ �߰�
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
           LEFT OUTER JOIN #TCOMSourceTrackingSub AS F ON ( F.IDX_NO = X.IDX_NO )                                      -- v2013.11.06 ADD By����õ
           
      WHERE A.CompanySeq  = @CompanySeq
        AND (@SMProgressType = 0 OR X.SMProgressType = @SMProgressType)
        AND (@InKind = 0 OR (@InKind = 6043001 AND ISNULL(A.IsCompleted, '0') = '1')
                        OR (@InKind = 6043002 AND ISNULL(A.IsCompleted, '0') <> '1'))
        AND ( @PJTName = '' OR G.PJTName LIKE @PJTName + '%' )
        AND ( @PJTNo = ''   OR G.PJTNo   LIKE @PJTNo + '%' ) 
        AND ( @ReqDeptSeq = 0 OR F.ReqDeptSeq = @ReqDeptSeq ) -- v2013.11.06 ADD By����õ
        AND ( @ReqEmpSeq = 0 OR F.ReqEmpSeq = @ReqEmpSeq )    -- v2013.11.06 ADD By����õ
      ORDER BY A.InOutDate
      
     RETURN