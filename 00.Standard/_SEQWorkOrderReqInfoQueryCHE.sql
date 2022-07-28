
IF OBJECT_ID('_SEQWorkOrderReqInfoQueryCHE') IS NOT NULL 
    DROP PROC _SEQWorkOrderReqInfoQueryCHE
GO 

-- v2015.01.27 
/*********************************************************************************************************************  
     화면명 : 작업요청내역조회(일반) - 조회
     작성일 : 2011.04.29 전경만
 ********************************************************************************************************************/ 
 CREATE PROCEDURE _SEQWorkOrderReqInfoQueryCHE  
     @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달
     @xmlFlags    INT = 0         ,    -- 해당 XML문서의 TYPE
     @ServiceSeq  INT = 0         ,    -- 서비스 번호
     @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그
     @CompanySeq  INT = 1         ,    -- 회사 번호
     @LanguageSeq INT = 1         ,    -- 언어 번호
     @UserSeq     INT = 0         ,    -- 사용자 번호
     @PgmSeq      INT = 0              -- 프로그램 번호
  AS
    DECLARE @docHandle  INT,
            @ReqDateFr  NCHAR(8),
            @ReqDateTo  NCHAR(8),
            @DeptSeq  INT,
            @EmpSeq   INT,
            @WorkType  INT,
            @WorkOperSeq INT,
            @ProgType       INT,
            @ToolSeq        INT,
            @WorkContents   NVARCHAR(400),
            @FactUnit  INT,
            @SectionCode NVARCHAR(100)
    
    -- XML문서
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- 생성된 XML문서를 @docHandle로 핸들한다.
    -- XML문서의 DataBlock1으로부터 값을 가져와 변수에 저장한다.
    SELECT  @EmpSeq   = ISNULL(EmpSeq, 0),
            @DeptSeq  = ISNULL(DeptSeq, 0),
            @ReqDateFr  = ISNULL(ReqDateFr, ''),
            @ReqDateTo  = ISNULL(ReqDateTo, ''),
            @WorkType  = ISNULL(WorkType, 0),
            @WorkOperSeq = ISNULL(WorkOperSeq, 0),
            @ProgType       = ISNULL(ProgType,0),
            @ToolSeq        = ISNULL(ToolSeq,0),
            @WorkContents   = ISNULL(WorkContents,''),
            @FactUnit  = ISNULL(FactUnit, 0),
            @SectionCode = ISNULL(SectionCode, '')
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML문서의 DataBlock1으로부터
      WITH (EmpSeq   INT,
            DeptSeq   INT,
            ReqDateFr  NCHAR(8),
            ReqDateTo  NCHAR(8),
            WorkType  INT,
            WorkOperSeq     INT,
            ProgType        INT,
            ToolSeq         INT,
            WorkContents    NVARCHAR(400),
            FactUnit  INT,
            SectionCode  NVARCHAR(100))
    
    IF @ReqDateFr = '' 
    SELECT @ReqDateFr = '19000101'
    IF @ReqDateTo = '' 
    SELECT @ReqDateTo = '99991231'
   
    SELECT A.WOReqSeq,
           A.ReqDate,
           A.DeptSeq,
           D.DeptName,
           A.EmpSeq,
           E.EmpName,
           A.WorkType,
           W.MinorName  AS WorkTypeName,
           A.ReqCloseDate,
           A.WONo,
           A.WorkContents,
           B.WOReqSerl,
           B.WorkOperSeq,
           O.MinorName  AS WorkOperName,
           B.ToolSeq,
           T.ToolName,
           T.ToolNo,
           B.ToolNo   AS NonCodeToolNo,
           B.SectionSeq,
           P.MinorName  AS PdAssUnitName,
           B.PdAccUnitSeq,
           ISNULL(S.FactUnitName,'') AS  PdAccUnitName  ,
           B.ProgType,
           ISNULL(F4.MinorName,'')     AS ProgTypeName     , 
           --A.ModifyNo,
           --A.SpendNo,
           --A.ModifyType,
           A.AddDocYn,
           --A.MRIssueYn,
           A.SafeCfmType,
           A.WorkName,
           B.WORNo,
           CASE WHEN ISNULL(B.ToolSeq,0) <>0 THEN TU.MngValText ELSE SC.SectionCode END AS SectionCode,
           CASE WHEN ISNULL(B.ToolSeq,0) <>0 THEN CONVERT(INT,TP.MngValText) ELSE SC.CCtrSeq END  AS ActCenterSeq,
           CASE WHEN ISNULL(B.ToolSeq,0) <>0 THEN CC2.CCtrName ELSE CC.CCtrName END AS ActCenterName, 
           C1.ReceiptReason, 
           STUFF(STUFF(CONVERT(NCHAR(8),A.FirstDateTime,112),5,0,'-'),8,0,'-') + ' ' + CONVERT(NVARCHAR(10),A.FirstDateTime,108) AS FirstDateTime
    
      FROM _TEQWorkOrderReqMasterCHE                    AS A
      LEFT OUTER JOIN _TEQWorkOrderReqItemCHE           AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.WOReqSeq = A.WOReqSeq
      LEFT OUTER JOIN _TDAEmp                           AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.EmpSeq = A.EmpSeq
      LEFT OUTER JOIN _TDADept                          AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.DeptSeq = A.DeptSeq
      LEFT OUTER JOIN _TDAUMinor                        AS W WITH(NOLOCK) ON W.CompanySeq = A.CompanySeq AND W.MinorSeq = A.WorkType
      LEFT OUTER JOIN _TDAUMinor                        AS O WITH(NOLOCK) ON O.CompanySeq = B.CompanySeq AND O.MinorSeq = B.WorkOperSeq
      LEFT OUTER JOIN _TPDTool                          AS T WITH(NOLOCK) ON T.CompanySeq = B.CompanySeq AND T.ToolSeq = B.ToolSeq
      LEFT OUTER JOIN _TDAUMinor                        AS P WITH(NOLOCK) ON P.CompanySeq  = B.CompanySeq AND P.MinorSeq = B.PdAccUnitSeq
      LEFT OUTER JOIN _TDAUMinor                        AS F4 WITH (NOLOCK) ON B.CompanySeq = F4.CompanySeq AND B.ProgType = F4.MinorSeq    -- 진행상태 
      LEFT OUTER JOIN _TEQWorkOrderReceiptItemCHE       AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq AND B.WOReqSerl = C.WOReqSerl
      LEFT OUTER JOIN _TEQWorkOrderReceiptMasterCHE     AS C1 WITH(NOLOCK) ON C.CompanySeq = C1.CompanySeq AND C.ReceiptSeq = C1.ReceiptSeq   
      LEFT OUTER JOIN _TDAFactUnit                      AS S WITH (NOLOCK) ON B.CompanySeq = S.CompanySeq  AND B.PdAccUnitSeq = S.FactUnit    -- 생산사업장                                                        
      LEFT OUTER JOIN _TPDSectionCodeCHE                AS SC WITH(NOLOCK) ON B.CompanySeq = SC.CompanySeq AND B.SectionSeq = SC.SectionSeq
      LEFT OUTER JOIN _TDACCtr                          AS CC WITH (NOLOCK) ON SC.CompanySeq = CC.CompanySeq AND SC.CCtrSeq = CC.CCtrSeq  
      LEFT OUTER JOIN _TPDToolUserDefine                AS TP WITH (NOLOCK) ON B.CompanySeq = TP.CompanySeq AND B.ToolSeq    = TP.ToolSeq AND TP.MngSerl = 1000005                                                                                                                            
      LEFT OUTER JOIN _TDACCtr                          AS CC2 WITH (NOLOCK) ON TP.CompanySeq = CC2.CompanySeq AND TP.MngValText = CC2.CCtrSeq                                                                   
      LEFT OUTER JOIN _TPDToolUserDefine                AS TU WITH (NOLOCK) ON B.CompanySeq = TU.CompanySeq AND B.ToolSeq    = TU.ToolSeq AND TU.MngSerl = 1000003                                                                
     WHERE A.CompanySeq = @CompanySeq
       AND (A.ReqDate BETWEEN @ReqDateFr AND @ReqDateTo)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkType = 0 OR A.WorkType = @WorkType)
       AND (@WorkOperSeq = 0 OR B.WorkOperSeq = @WorkOperSeq)
       AND (@ProgType = 0 OR B.ProgType = @ProgType)
       AND A.ProgType NOT IN (20109009)
       AND (@ToolSeq = 0 OR B.ToolSeq = @ToolSeq)
       AND (@WorkContents = '' OR A.WorkContents LIKE '%'+ @WorkContents + '%')
       AND (@FactUnit = 0 OR B.PdAccUnitSeq = @FactUnit)
       AND (@SectionCode = '' OR SC.SectionCode LIKE @SectionCode + '%')
     ORDER BY A.WONo, PdAccUnitName
    
    RETURN
 GO 
exec _SEQWorkOrderReqInfoQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WorkType>20104005</WorkType>
    <FactUnit />
    <ReqDateFr>20150303</ReqDateFr>
    <ReqDateTo>20150303</ReqDateTo>
    <EmpSeq />
    <DeptSeq />
    <ProgType>20109001</ProgType>
    <ToolSeq />
    <WorkOperSeq />
    <SectionSeq />
    <SectionCode />
    <WorkContents />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100148