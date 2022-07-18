IF OBJECT_ID('KPXCM_SQCProcessInspectionPlacementMonitoringQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCProcessInspectionPlacementMonitoringQuery
GO 

-- v2016.05.09 

/************************************************************
 설  명 - 데이터-검사결과모니터링(배치식) : 조회
 작성일 - 20141224
 작성자 - 오정환
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SQCProcessInspectionPlacementMonitoringQuery
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       
AS        
    
    DECLARE @docHandle          INT,
            @WorkCenterSeq      INT,
            @ReqDate          NCHAR(8),
            @BizUnit            INT
 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    SELECT @WorkCenterSeq   = ISNULL(WorkCenterSeq  ,  0),
           @ReqDate       = ISNULL(ReqDate      , ''),
           @BizUnit         = ISNULL(BizUnit        ,  0)       
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (WorkCenterSeq       INT ,
            ReqDate           NCHAR(8),
            BizUnit             INT )
    DECLARE @SMSourceType   INT,
            @QCSeq          INT
    -- WorkCenter별 등록된 검사 중 최종 1건만 조회
    SELECT TOP 1
           @SMSourceType    = B.SMSourceType,
           @QCSeq           = A.QCSeq   
      FROM KPX_TQCTestResult AS A JOIN KPX_TQCTestResultItem    AS B ON A.CompanySeq    = B.CompanySeq
                                                                    AND A.QCSeq         = B.QCSeq 
                                  JOIN KPX_TQCTestRequest       AS D ON A.CompanySeq    = D.CompanySeq
                                                                    AND A.ReqSeq        = D.ReqSeq
     WHERE 1=1
       AND A.CompanySeq     = @CompanySeq
       AND A.WorkCenterSeq  = @WorkCenterSeq
       AND D.ReqDate        = @ReqDate
       AND ISNULL(B.TestValue, '') <> ''
       --AND ISNULL(B.IsChecked, '') <> '1'
       AND NOT EXISTS (SELECT 1 FROM KPXCM_TQCTestResultMonitoring WHERE CompanySeq = @CompanySeq AND QCSeq = A.QCSeq AND UserSeq = @UserSeq) -- 추가 by이재천 
  ORDER BY B.LastDateTime DESC


    SELECT @ReqDate               AS TestDateSub              ,
           A.QCNo                                               ,
           A.ItemSeq                                            ,
           C.ItemName                                           ,
           C.ItemNo                                             ,
           A.LotNo                                              ,
           Q.ReqQty                 AS Qty                      ,
           D.UnitName                                           ,
           B.QCType                                             ,
           E.QCTypeName                                         ,
           A.IsEnd                                              ,
           B.TestItemSeq                                        ,
           F.InTestItemName         AS  TestItemName            ,
           B.QAAnalysisType         AS AnalysisSeq              ,
           G.QAAnalysisTypeName     AS AnalysisName             ,
           I.SMInputType                                        ,
           J.MinorName              AS SMInputTypeName          ,
           I.LowerLimit                                         ,
           I.UpperLimit                                         ,
           B.QCUnit                                             ,
           H.QCUnitName                                         ,
           B.TestValue                                          ,
           B.SMTestResult                                       ,
           K.MinorName              AS SMTestResultName         ,
           B.IsSpecial                                          ,
           B.EmpSeq                                             ,
           L.EmpName                                            ,
           B.TestDate                                           ,
   '0'          AS Field                     ,
           CONVERT(NCHAR(8), B.RegDate, 112)  AS RegDate        ,
           CONVERT(NCHAR(5), B.RegDate, 108)  AS RegTime        ,
           B.RegEmpSeq                                          ,
           M.EmpName                        AS RegEmpName       ,
           CONVERT(NCHAR(8), B.LastDateTime, 112)  AS LastDate  ,
           O.EmpSeq                                             ,
           O.EmpName,
           B.QCSeq,
           B.QCSerl
      FROM KPX_TQCTestResult AS A WITH (NOLOCK) JOIN KPX_TQCTestResultItem      B ON A.CompanySeq    = B.CompanySeq
                                                                                 --AND A.SMSourceType      = B.SMSourceType      
                                                                                 AND A.QCSeq         = B.QCSeq
                                     LEFT OUTER JOIN KPX_TQCTestRequestItem     Q ON Q.CompanySeq    = B.CompanySeq
                                                                                 AND Q.SMSourceType  = B.SMSourceType
                                                                                 AND Q.SourceSeq     = B.SourceSeq
                                                                                 AND Q.SourceSerl    = B.SourceSerl
                                                                                 AND Q.QCType        = B.QCType
                                     LEFT OUTER JOIN _TDAItem                   C ON A.CompanySeq    = C.CompanySeq
                                                                                 AND A.ItemSeq       = C.ItemSeq
                                     LEFT OUTER JOIN _TDAUnit                   D ON C.CompanySeq    = D.CompanySeq
                                                                                 AND C.UnitSeq       = D.UnitSeq
                                     LEFT OUTER JOIN KPX_TQCQAProcessQCType     E ON B.CompanySeq   = E.CompanySeq     
                                                                                 AND B.QCType       = E.QCType
                                     LEFT OUTER JOIN KPX_TQCQATestItems         F ON B.CompanySeq   = F.CompanySeq
                                                                                 AND B.TestItemSeq  = F.TestItemSeq
                                     LEFT OUTER JOIN KPX_TQCQAAnalysisType      G ON B.CompanySeq   = G.CompanySeq
                                                                                 AND B.QAAnalysisType  = G.QAAnalysisType
                                     LEFT OUTER JOIN KPX_TQCQAProcessQCUnit     H ON B.CompanySeq   = H.CompanySeq
                                                                                 AND B.QCUnit       = H.QCUnit
                                     LEFT OUTER JOIN KPX_TQCQASpec              I ON B.CompanySeq   = I.CompanySeq
                                                                                 AND B.QCType       = I.QCType
                                                                                 AND A.ItemSeq      = I.ItemSeq
                                                                                 AND B.TestItemSeq  = I.TestItemSeq
                                                                                 AND B.QAAnalysisType  = I.QAAnalysisType
                                                                                 AND B.QCUnit       = I.QCUnit
                                                                                 AND B.TestDate BETWEEN I.SDate AND I.EDate 
                                     LEFT OUTER JOIN _TDASMinor                 J ON I.CompanySeq   = J.CompanySeq
                                                                                 AND I.SMInputType  = J.MinorSeq
                                     LEFT OUTER JOIN _TDASMinor                 K ON B.CompanySeq   = K.CompanySeq
                                                                                 AND B.SMTestResult = K.MinorSeq
                                   LEFT OUTER JOIN _TDAEmp                    L ON B.CompanySeq   = L.CompanySeq
                                                         AND B.EmpSeq       = L.EmpSeq
                                     LEFT OUTER JOIN _TDAEmp                    M ON B.CompanySeq   = M.CompanySeq
                                                                                 AND B.RegEmpSeq    = M.EmpSeq
                                     LEFT OUTER JOIN _TCAUser                   N ON B.CompanySeq   = N.CompanySeq
                                                                                 AND B.LastUserSeq  = N.UserSeq
                                     LEFT OUTER JOIN _TDAEmp                    O ON N.CompanySeq   = O.CompanySeq
                                                                                 AND N.EmpSeq       = O.EmpSeq
     
     WHERE A.CompanySeq     = @CompanySeq
       AND B.SMSourceType   = @SMSourceType      
       AND A.QCSeq          = @QCSeq
       --AND ISNULL(B.TestValue, '') <> ''
       --AND ISNULL(B.IsChecked, '') <> '1'
  ORDER BY I.Sort
RETURN


GO


