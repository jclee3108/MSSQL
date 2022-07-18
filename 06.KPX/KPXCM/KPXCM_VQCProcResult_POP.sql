IF OBJECT_ID('KPXCM_VQCProcResult_POP') IS NOT NULL
    DROP VIEW KPXCM_VQCProcResult_POP
GO 

-- v2016.05.12 

CREATE VIEW KPXCM_VQCProcResult_POP
AS
    

         SELECT  B.CompanySeq                           AS CompanySeq           --법인코드
                ,ROw_Number() OVER(PARTITION BY B.SourceSeq,B.SourceSerl ORDER BY B.CompanySeq,B.QCSeq,B.QCSerl)        AS IDX
----------------원천데이터------------------------------------------------------------------------------------------------
                ,B.SourceSeq                            AS WorkOrderSeq         --원천코드D
                ,B.SourceSerl                           AS WorkOrderSerl        --원천순번D
----------------원천구분,공정구분-----------------------------------------------------------------------------------------
                ,B.SMSourceType                         AS SMSourceType         --원천구분코드
                ,J.MinorName                            AS SMSourceTypeName     --원천구분명
                ,CASE WHEN ISNULL(A.QCType,0)=0 
                           THEN ISNULL(B.QCType,0)
                           ELSE ISNULL(A.QCType,0)
                 END                                    AS QCType               --검사공정코드(Union)
                ,CASE WHEN ISNULL(A.QCType,0)=0                                 
                           THEN ISNULL(K.QCTypeName,'')
                           ELSE ISNULL(E.QCTypeName,'')
                 END                                    AS QCTypeName           --검사공정명(Union)
----------------검사데이터------------------------------------------------------------------------------------------------
                ,A.QCSeq                                AS QCSeq                --검사코드
                ,B.QCSerl                               AS QCSerl               --검사순번
                ,A.QCNo                                 AS QCNo                 --검사번호
                ,A.ItemSeq                              AS ItemSeq              --품목코드M
                ,M.ItemName                             AS ItemName             --품명M
                ,M.ItemNo                               AS ItemNo               --품번M
                ,A.LotNo                                AS LotNo                --LotNo
                ,A.SMTestResult                         AS SMTestResultM         --검사결과코드(Master)
                ,C.MinorName                            AS SMTestResultMName     --검사결과(Master)
                ,A.IsEnd                                AS IsEnd                --완료여부
                ,A.WorkCenterSeq                        AS WorkCenterSeq        --워크센터
                ,A.OKQty                                AS OKQty                --합격수량
                ,A.BadQty                               AS BadQty               --불량수량
                ,B.TestItemSeq                          AS TestItemSeq          --검사항목코드
                ,F.TestItemName                         AS TestItemName         --검사항목내부코드
                ,F.OutTestItemName                      AS OutTestItemName      --검사항목명(사외용)
                ,F.InTestItemName                       AS InTestItemName       --검사항목명(사내용)
                ,B.QAAnalysisType                       AS QAAnalysisType       --분석방법코드
                ,D.QAAnalysisTypeName                   AS QAAnalysisTypeName   --분석방법명
                ,B.QCUnit                               AS QCUnit               --검사단위코드
                ,H.QCUnitName                           AS QCUnitName           --검사단위명
                ,B.TestValue                            AS TestValue            --측정치
                ,B.SMTestResult                         AS SMTestResultD         --합/부판정코드(Detail)
                ,I.MinorName                            AS SMTestResultDName     --합/부판정명(Detail)
                ,B.IsSpecial                            AS IsSpecial            --특채처리
                ,B.TestHour                             AS TestHour             --소요시간
                ,B.Remark                               AS Remark               --항목특별사항
                ,B.TestDate                             AS TestDate             --검사일자
                ,CONVERT(NCHAR(8),B.RegDate,112)        AS RegDate              --검사결과등록일
                ,CONVERT(NCHAR(5),B.RegDate,108)        AS RegTime              --검사결과시간
                ,CONVERT(NCHAR(8),B.LastDateTime,112)   AS LastDate             --최종수정일
                ,B.UMTestGroup                          AS UMTestGroup          --검사그룸코드(Detail)
                ,L.MinorName                            AS UMTestGroupName      --검사그룸명(Detail)
                ,B.EmpSeq                               AS EmpSeq               --담당자코드(Detail)
                ,N.EmpName                              AS EmpName              --담당자명(Detail)
                ,B.RegEmpSeq                            AS RegEmpSeq            --등록자코드(Detail)
                ,O.EmpName                              AS RegEmpName           --등록자명(Detail)
                ,Q.EmpSeq                               AS LastEmpSeq           --최종수정자코드
                ,Q.EmpName                              AS LastEmpName          --최종수정자명
----------------의뢰데이터------------------------------------------------------------------------------------------------
                ,A.ReqSeq                               AS ReqSeq               --의뢰코드M
                ,A.ReqSerl                              AS ReqSerl              --의뢰순번M
                ,S.BizUnit                              AS ReqBizUnit              --의뢰사업부문코드
                ,Y.BizUnitName                          AS ReqBizUnitName          --의뢰사업부문명
                ,S.ReqDate                              AS ReqDate              --의뢰일자
                ,S.ReqNo                                AS ReqNo                --의뢰번호
                ,S.DeptSeq                              AS ReqDeptSeq              --의뢰부서코드
                ,Z.DeptName                             AS ReqDeptName             --의뢰부서명
                ,S.EmpSeq                               AS ReqEmpSeq               --의뢰담당자코드
                ,A1.EmpName                             AS ReqEmpName              --의뢰담당자명
                ,S.CustSeq                              AS ReqCustSeq              --의뢰고객사코드
                ,B1.CustName                            AS ReqCustName             --의뢰고색사명
                ,R.LotNo                                AS ReqLotNo                --의뢰LotNo
                ,R.WHSeq                                AS ReqWHSeq                --의뢰창고코드
                ,T.WHName                               AS ReqWHName               --의뢰창고명
                ,R.UnitSeq                              AS ReqUnitSeq              --의뢰단위코드
                ,U.UnitName                             AS ReqUnitName             --의뢰단위명
                ,R.ReqQty                               AS ReqReqQty               --의뢰수량
                ,R.Remark                               AS ReqRemark               --의뢰비고
                ,R.PreItemSeq                           AS ReqPreItemSeq           --전적제품코드
                ,X.ItemName                             AS ReqPreItemName          --전적제품명
                ,R.CleanYN                              AS ReqCleanYN              --세차여부
                ,R.Memo1                                AS ReqMemo1                --메모1
                ,R.AfterWeight                          AS ReqAfterWeight          --적재후무게
                ,R.BeforWeight                          AS ReqBeforWeight          --공차무게
                ,R.StockWeight                          AS ReqStockWeight          --적재무게
                ,R.ProcGubunSeq                         AS ReqProcGubunSeq         --공정구분코드
                ,V.MinorName                            AS ReqProcGubunName        --공정구분명
                ,R.CustInReqTime                        AS ReqCustInReqTime        --업체입고요청시간
                ,R.UpCarTemp                            AS ReqUpCarTemp            --상차온도
                ,R.CarSeq                               AS ReqCarSeq               --차량코드
                ,W.CarNo                                AS ReqCarNo                --차량번호
                ,W.Driver                               AS ReqDriver               --운전사명
                ,W.TelNo1                               AS ReqTelNo1               --연락처
                ,CAST(C1.LowerLimit AS NVARCHAR(MAX))   AS LowerLimit              --하한치
                ,CAST(C1.UpperLimit AS NVARCHAR(MAX))   AS UpperLimit              --상한치
                ----,C1.LowerLimit                          AS LowerLimit              --하한치
                ----,C1.UpperLimit                          AS UpperLimit              --상한치
           FROM KPX_TQCTestResult                   AS A WITH(NOLOCK)
LEFT OUTER JOIN KPX_TQCTestResultItem               AS B WITH(NOLOCK)ON A.CompanySeq        = B.CompanySeq
                                                                    AND A.QCSeq             = B.QCSeq
LEFT OUTER JOIN _TDAUMinor                          AS C WITH(NOLOCK)ON A.CompanySeq        = C.CompanySeq
                                                                    AND A.SMTestResult      = C.MinorSeq
LEFT OUTER JOIN KPX_TQCQAAnalysisType               AS D WITH(NOLOCK)ON B.CompanySeq        = D.CompanySeq
                                                                    AND B.QAAnalysisType    = D.QAAnalysisType
LEFT OUTER JOIN KPX_TQCQAProcessQCType              AS E WITH(NOLOCK)ON A.CompanySeq        = E.CompanySeq     
                                                                    AND A.QCType            = E.QCType
LEFT OUTER JOIN KPX_TQCQATestItems                  AS F WITH(NOLOCK)ON B.CompanySeq        = F.CompanySeq
                                                                    AND B.TestItemSeq       = F.TestItemSeq
LEFT OUTER JOIN KPX_TQCQAAnalysisType               AS G WITH(NOLOCK)ON B.CompanySeq        = G.CompanySeq
                                                                    AND B.QAAnalysisType    = G.QAAnalysisType
LEFT OUTER JOIN KPX_TQCQAProcessQCUnit              AS H WITH(NOLOCK)ON B.CompanySeq        = H.CompanySeq
                                                                    AND B.QCUnit            = H.QCUnit
LEFT OUTER JOIN _TDASMinor                          AS I WITH(NOLOCK)ON B.CompanySeq        = I.CompanySeq
                                                                    AND B.SMTestResult      = I.MinorSeq
LEFT OUTER JOIN _TDASMinor                          AS J WITH(NOLOCK)ON B.CompanySeq        = J.CompanySeq
                                                                    AND B.SMSourceType      = J.MinorSeq
LEFT OUTER JOIN KPX_TQCQAProcessQCType              AS K WITH(NOLOCK)ON B.COmpanySeq        = K.CompanySeq
                                                                    AND B.QCType            = K.QCType
LEFT OUTER JOIN _TDAUMinor                          AS L WITH(NOLOCK)ON B.CompanySeq        = L.CompanySeq
                                                                    AND B.UMTestGroup       = L.MinorSeq
LEFT OUTER JOIN _TDAItem                            AS M WITH(NOLOCK)ON A.CompanySeq        = M.CompanySeq
                                                                    AND A.ItemSeq           = M.ItemSeq
LEFT OUTER JOIN _TDAEmp                             AS N WITH(NOLOCK)ON B.CompanySeq        = N.CompanySeq
                                                                    AND B.EmpSeq            = N.EmpSeq
LEFT OUTER JOIN _TDAEmp                             AS O WITH(NOLOCK)ON B.CompanySeq        = O.CompanySeq
                                                                    AND B.RegEmpSeq         = O.EmpSeq
LEFT OUTER JOIN _TCAUser                            AS P WITH(NOLOCK)ON B.CompanySeq        = P.CompanySeq
                                                                    AND B.LastUserSeq       = P.UserSeq
LEFT OUTER JOIN _TDAEmp                             AS Q WITH(NOLOCK)ON P.CompanySeq        = Q.CompanySeq
                                                                    AND P.EmpSeq            = Q.EmpSeq
LEFT OUTER JOIN KPX_TQCTestRequestItem              AS R WITH(NOLOCK)ON A.CompanySeq        = R.CompanySeq
                                                                    AND A.ReqSeq            = R.ReqSeq
                                                                    AND A.ReqSerl           = R.ReqSerl
LEFT OUTER JOIN KPX_TQCTestRequest                  AS S WITH(NOLOCK)ON R.CompanySeq        = S.CompanySeq
                                                                    AND R.ReqSeq            = S.ReqSeq
LEFT OUTER JOIN _TDAWH                              AS T WITH(NOLOCK)ON R.CompanySeq        = T.CompanySeq
                                                                    AND R.WHSeq             = T.WHSeq
LEFT OUTER JOIN _TDAUnit                            AS U WITH(NOLOCK)ON R.CompanySeq        = U.CompanySeq
                                                                    AND R.UnitSeq           = U.UnitSeq
LEFT OUTER JOIN _TDAUMinor                          AS V WITH(NOLOCK)ON R.CompanySeq        = V.CompanySeq
                                                                    AND R.ProcGubunSeq      = V.MinorSeq
LEFT OUTER JOIN _TLGCar                             AS W WITH(NOLOCK)ON R.CompanySeq        = W.CompanySeq
                                                                    AND R.CarSeq            = W.CarSeq
LEFT OUTER JOIN _TDAItem                            AS X WITH(NOLOCK)ON R.CompanySeq        = X.CompanySeq
                                                                    AND R.PreItemSeq        = X.ItemSeq
LEFT OUTER JOIN _TDABizUnit                         AS Y WITH(NOLOCK)ON S.CompanySeq        = Y.CompanySeq
                                                                    AND S.BizUnit           = Y.BizUnit
LEFT OUTER JOIN _TDADept                            AS Z WITH(NOLOCK)ON S.CompanySeq        = Z.CompanySeq
                                                                    AND S.DeptSeq           = Z.DeptSeq
LEFT OUTER JOIN _TDAEmp                             AS A1 WITH(NOLOCK)ON S.CompanySeq       = A1.CompanySeq
                                                                     AND S.EmpSeq           = A1.EmpSeq
LEFT OUTER JOIN _TDACust                            AS B1 WITH(NOLOCK)ON S.CompanySeq       = B1.CompanySeq
                                                                     AND S.CustSeq          = B1.CustSeq
LEFT OUTER JOIN KPX_TQCQASpec                       AS C1 WITH(NOLOCK)ON C1.CompanySeq      = B.CompanySeq
                                                                     AND C1.QCType          = B.QCType
                                                                     AND C1.QAAnalysisType  = B.QAAnalysisType
                                                                     AND C1.TestItemSeq     = B.TestItemSeq
                                                                     AND C1.QCUnit          = B.QCUnit
                                                                     AND C1.ItemSeq         = A.ItemSeq
                                                                     AND S.ReqDate          BETWEEN C1.SDate AND C1.EDate 
          WHERE  A.CompanySeq     = 2
            --AND B.SMSourceType NOT IN (1000522004,1000522008)
            --AND (CASE WHEN A.ItemSeq = R.ItemSeq THEN '1' ELSE '99999999999' END) <>'1'
       --ORDER BY  B.SMSourceType                     --원천구분코드
                --,(CASE WHEN ISNULL(A.QCType,0)=0 
                --           THEN ISNULL(B.QCType,0)
                --           ELSE ISNULL(A.QCType,0)
                -- END)                                --검사공정코드(Union)

/*
------품목검사규격테이블 (아래)
------LEFT OUTER JOIN KPX_TQCQASpec                       AS T WITH(NOLOCK)ON T.CompanySeq        = B.CompanySeq
------                                                                    AND T.QCType            = B.QCType
------                                                                    AND T.TestItemSeq       = B.TestItemSeq
------                                                                    AND T.QAAnalysisType    = B.QAAnalysisType
------                                                                    AND T.QCUnit            = B.QCUnit
------                                                                    AND T.ItemSeq           = A.ItemSeq
*/
GO


