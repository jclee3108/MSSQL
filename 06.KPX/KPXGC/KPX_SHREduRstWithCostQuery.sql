
IF OBJECT_ID('KPX_SHREduRstWithCostQuery') IS NOT NULL 
    DROP PROC KPX_SHREduRstWithCostQuery
GO 

-- v2014.11.19 

-- 교육결과등록(조회) by이재천 
CREATE PROCEDURE KPX_SHREduRstWithCostQuery  
    @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달  
    @xmlFlags    INT = 0         ,    -- 해당 XML문서의 TYPE  
    @ServiceSeq  INT = 0         ,    -- 서비스 번호  
    @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그  
    @CompanySeq  INT = 1         ,    -- 회사 번호  
    @LanguageSeq INT = 1         ,    -- 언어 번호  
    @UserSeq     INT = 0         ,    -- 사용자 번호  
    @PgmSeq      INT = 0              -- 프로그램 번호  
AS  
    
 -- 사용할 변수를 선언한다.  
    DECLARE @docHandle      INT     ,       -- XML문서를 핸들할 변수  
            @SMEduPlanType  INT     ,       -- 계획구분코드변수  
            @UMEduHighClass INT     ,       -- 학습대분류코드 변수  
            @UMEduMidClass  INT     ,       -- 학습중분류코드 변수  
            @EduClassSeq    INT     ,       -- 학습분류코드 변수  
            @UMEduGrpType   INT     ,       -- 학습구분코드 변수  
            @EduTypeSeq     INT     ,       -- 학습형태코드 변수  
            @RegBegDate     NCHAR(8),       -- 등록시작일 변수  
            @RegEndDate     NCHAR(8),       -- 등록종료일 변수  
            @DeptSeq        INT     ,       -- 부서코드 변수  
            @EmpSeq         INT     ,       -- 사원코드 변수  
            @IsRst          NCHAR(1),       -- 결과내역포함 변수  
            @IsEndEval      NCHAR(1),       -- 평가완료된내역포함 변수  
            @IsEnd          NCHAR(1),       -- 확정된내역포함 변수  
            @RstNo          NVARCHAR(20),   -- 학습결과번호 변수  
            @CfmEmpSeq      INT     ,       -- 승인자사원코드 변수  
            @EduRstType     INT     ,       -- 결과구분코드 변수  
            @IsConfirm      NCHAR(1),       -- 확정포함 변수  
            @IsNotConfirm   NCHAR(1),       -- 미확정포함 변수  
            @EduCourseSeq   INT     ,       -- 학습과정 변수  
            @UMCostItem     INT             -- 대표비용항목  
  
  
      
  
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- 생성된 XML문서를 @docHandle로 핸들한다.  
  
 -- XML문서의 DataBlock1으로부터 값을 가져와 변수에 저장한다.  
    SELECT @DeptSeq       = ISNULL(DeptSeq      ,  0),    -- 소속부서코드를 가져온다.  
           @EmpSeq        = ISNULL(EmpSeq       ,  0),    -- 사원코드를 가져온다.  
           @SMEduPlanType = ISNULL(SMEduPlanType,  0),    -- 계획구분코드를 가져온다.  
           @UMEduHighClass= ISNULL(UMEduHighClass,  0),   -- 학습대분류코드를 가져온다.  
           @UMEduMidClass = ISNULL(UMEduMidClass,  0),    -- 학습중분류코드를 가져온다.  
           @EduClassSeq   = ISNULL(EduClassSeq  ,  0),    -- 학습분류코드를 가져온다.  
           @UMEduGrpType  = ISNULL(UMEduGrpType ,  0),    -- 학습구분코드를 가져온다.  
           @EduTypeSeq    = ISNULL(EduTypeSeq   ,  0),    -- 학습형태코드를 가져온다.  
           @RegBegDate    = ISNULL(RegBegDate   , ''),    -- 등록시작일을 가져온다.  
           @RegEndDate    = ISNULL(RegEndDate   , ''),    -- 등록종료일을 가져온다.  
           @IsRst         = ISNULL(IsRst        , ''),    -- 결과내역포함을 가져온다.  
           @IsEndEval     = ISNULL(IsEndEval    , ''),    -- 평가완료된내역포함을 가져온다.  
           @IsEnd         = ISNULL(IsEnd        , ''),    -- 확정된내역포함을 가져온다.  
           @RstNo         = ISNULL(RstNo        , ''),    -- 학습결과번호를 가져온다.  
           @CfmEmpSeq     = ISNULL(CfmEmpSeq    ,  0),    -- 승인자사원코드를 가져온다.  
           @EduRstType    = ISNULL(EduRstType   ,  0),    -- 결과구분코드 가져온다.  
           @IsConfirm     = ISNULL(IsConfirm    , ''),    -- 확정포함을 가져온다.  
           @IsNotConfirm  = ISNULL(IsNotConfirm , ''),    -- 미확정포함을 가져온다.  
           @EduCourseSeq  = ISNULL(EduCourseSeq ,  0)     -- 학습과정을 가져온다.  
  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML문서의 DataBlock1으로부터  
  
      WITH (DeptSeq         INT     ,  
            EmpSeq          INT     ,  
            SMEduPlanType   INT     ,  
            UMEduHighClass  INT     ,  
            UMEduMidClass   INT     ,  
            EduClassSeq     INT     ,  
            UMEduGrpType    INT     ,  
            EduTypeSeq      INT     ,  
            RegBegDate      NCHAR(8),  
            RegEndDate      NCHAR(8),  
            IsRst           NCHAR(1),  
            IsEndEval       NCHAR(1),  
            IsEnd           NCHAR(1),  
            RstNo           NVARCHAR(20),  
            CfmEmpSeq       INT,  
            EduRstType      INT,  
            IsConfirm       NCHAR(1),  
            IsNotConfirm    NCHAR(1),  
            EduCourseSeq    INT  
           )  
  
    -- 대표학습비용 가져오기  
    SELECT TOP 1 @UMCostItem =  MinorSeq  
      FROM _TDAUMinorValue  
     WHERE CompanySeq = @CompanySeq  
       AND MajorSeq = 3906  
       AND Serl = 1002  
       AND ValueText = 1  
  
  
    SELECT ISNULL(A.RstSeq       ,  0) AS RstSeq       , ISNULL(A.RstNo        , '') AS RstNo        ,    -- 학습결과코드    , 학습결과번호    ,  
           ISNULL(A.EmpSeq       ,  0) AS EmpSeq       , ISNULL(D.EmpName      , '') AS EmpName      ,    -- 사원코드        , 사원            ,  
           ISNULL(D.EmpID        , '') AS EmpID        , ISNULL(D.DeptSeq      ,  0) AS DeptSeq      ,    -- 사번            , 부서코드        ,  
           ISNULL(D.DeptName     , '') AS DeptName     , ISNULL(D.UMJpSeq      ,  0) AS UMJpSeq      ,    -- 부서            , 직위코드        ,  
           ISNULL(D.UMJpName     , '') AS UMJpName     , ISNULL(D.PosSeq       ,  0) AS PosSeq       ,    -- 직위            , 포지션코드      ,  
           ISNULL(D.PosName      , '') AS PosName      , ISNULL(A.EduClassSeq  ,  0) AS EduClassSeq  ,    -- 포지션          , 학습분류코드    ,  
           ISNULL(F.EduClassName , '') AS EduClassName , ISNULL(A.UMEduGrpType ,  0) AS UMEduGrpType ,    -- 학습분류        , 학습구분코드    ,  
           ISNULL(A.EtcCourseName, '') AS EtcCourseName, ISNULL(A.EduCourseSeq ,  0) AS EduCourseSeq ,    -- 기타학습과정명  , 학습과정코드    ,  
           ISNULL(E.EduCourseName, '') AS EduCourseName, ISNULL(A.EduBegDate   , '') AS EduBegDate   ,    -- 학습과정명      , 등록시작일      ,  
           ISNULL(A.EduEndDate   , '') AS EduEndDate   , ISNULL(A.EduDd        ,  0) AS EduDd        ,    -- 등록종료일      , 학습일수        ,  
           ISNULL(A.EduTm        ,  0) AS EduTm        , ISNULL(A.RegDate      , '') AS RegDate      ,    -- 학습시간        , 등록일          ,  
           ISNULL(A.EduOkDd      ,  0) AS EduOkDd      , ISNULL(A.EduOkTm      ,  0) AS EduOkTm      ,    -- 인정학습일수    , 인정학습시간    ,  
           ISNULL(A.SMGradeSeq   ,  0) AS SMGradeSeq   , ISNULL(A.IsEndEval    , '') AS IsEndEval    ,    -- 평가등급코드    , 평가완료여부    ,  
           ISNULL(C.CfmCode      , '') AS IsEnd        , ISNULL(A.EduTypeSeq   ,  0) AS EduTypeSeq   ,    -- 평가확정여부    , 학습형태코드    ,  
           ISNULL(A.SMEduPlanType,  0) AS SMEduPlanType, ISNULL(B.RstCost      ,  0) AS RstCost      ,    -- 학습계획구분코드, 학습비용        ,  
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMEduGrpType) , '') AS UMEduGrpTypeName ,    -- 학습구분,  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMGradeSeq)   , '') AS SMGradeName      ,    -- 평가등급,  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMEduPlanType), '') AS SMEduPlanTypeName,    -- 학습계획구분  
           ISNULL(A.CfmEmpSeq    ,  0) AS CfmEmpSeq    , ISNULL(G.EmpName      , '') AS CfmEmpName   ,    --승인자코드       , 승인자   
           ISNULL(A.FileNo       ,  0) AS FileNo       , ISNULL(H.EduTypeName  , '') AS EduTypeName  ,    -- 파일번호        , 학습형태  
           ISNULL(A.SMInOutType  ,  0) AS SMInOutType  , ISNULL(B.ReturnAmt    ,  0) AS ReturnAmt    ,    -- 사내외구분코드  , 환급비용  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMInOutType)  , '') AS SMInOutTypeName,      -- 사내외구분  
           '3204001'                   AS EduRstType   , I.MinorName                 AS EduRstTypeName,   -- 결과구분-일반  
           ISNULL(A.ReqSeq       ,  0) AS ReqSeq       , 0                           AS PlanSeq       ,   -- 신청코드        , 계획코드  
           ISNULL(A.UMInstitute  ,  0) AS UMInstitute  , 0                           AS PlanSerl      ,   -- 학습기관코드    , 계획순번  
             ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq  = A.UMInstitute)  , '') AS UMInstituteName,      -- 학습기관  
           ISNULL(A.UMlocation   ,  0) AS UMlocation   , ISNULL(A.LecturerSeq  ,  0) AS LecturerSeq   ,                      
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMlocation)   , '') AS UMlocationName ,      -- 학습장소  
           CASE WHEN ISNULL(J.LecturerName, '') <> '' THEN ISNULL(J.LecturerName, '') ELSE ISNULL(J1.EmpName, '') END    AS LecturerName   ,      -- 강사    
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SatisLevel)   , '') AS SatisLevelName ,    -- 만족수준  
           ISNULL(A.SatisLevel   ,  0) AS SatisLevel    , ISNULL(A.EduPoint     ,  0) AS EduPoint      ,  -- 만족수준코드    , 인정학점  
           ISNULL(A.RstSummary   , '') AS RstSummary    , ISNULL(A.RstRem       , '') AS RstRem ,          -- 내용요약        , 비고  
           K.IsEI, 
           K.SMComplate, 
           L.MinorName AS SMComplateName 
  
  
                                            -- 대상자 정보(사원, 부서 등)를 가져오기 위한 조인  
      FROM _THREduPersRst AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')     AS D              ON A.CompanySeq = @CompanySeq  
                                                                                                    AND A.EmpSeq     = D.EmpSeq  
  
                                            -- 학습분류코드, 학습과정명을 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduCourse          AS E WITH(NOLOCK) ON A.CompanySeq   = E.CompanySeq  
                                                                                                    AND A.EduCourseSeq = E.EduCourseSeq    -- 학습과정코드가 같은부분  
  
                                            -- 학습분류명을 가져오기 위한 조인  
                                            LEFT OUTER JOIN _fnHREduClass(@CompanySeq) AS F          ON A.CompanySeq  =@CompanySeq  
                                                                                                    AND A.EduClassSeq = F.EduClassSeq    -- 학습분류코드가 같은부분  
  
                                            -- 학습비용을 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduPersRstCost     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                                                    AND A.RstSeq     = B.RstSeq  
                                                                                                    AND B.UMCostItem = @UMCostItem      -- 대표비용으로 체크된 항목  
  
                                            -- 확정여부를 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduPersRst_Confirm AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                                                                    AND A.RstSeq     = C.CfmSeq  
                                            -- 승인자를 가져오기 위한 조인  
                                            LEFT OUTER JOIN _TDAEmp                AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq   
                                                                                                    AND A.CfmEmpSeq = G.EmpSeq   
                                            -- 학습형태를 가져오기 위한 조인  
                                            JOIN _THREduType                       AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq   
                                                                                                    AND A.EduTypeSeq = H.EduTypeSeq  
                                            -- 결과구분  
                                            LEFT OUTER JOIN _TDAUMinor             AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq   
                                                                                                    AND MinorSeq ='3204001'  
                                            -- 강사명을 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduLecturer        AS J WITH(NOLOCK) ON A.CompanySeq  = J.CompanySeq   
                                             AND A.LecturerSeq = J.LecturerSeq  
                                            LEFT OUTER JOIN _TDAEmp                AS J1 WITH(NOLOCK) ON J.CompanySeq  = J1.CompanySeq   
                                                                                                     AND J.EmpSeq = J1.EmpSeq  
                                            LEFT OUTER JOIN KPX_THREduRstWithCost  AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.RstSeq = A.RstSeq ) 
                                            LEFT OUTER JOIN _TDASMinor             AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.SMComplate ) 
  
  
     WHERE  A.CompanySeq        = @CompanySeq  
       AND (A.EduTypeSeq        = @EduTypeSeq       OR @EduTypeSeq      =  0)       -- 받아온 학습형태코드와      
       AND (A.EduCourseSeq      = @EduCourseSeq     OR @EduCourseSeq    =  0)       -- 받아온 학습과정코드와      
       --AND (A.RstNo             = @RstNo            OR @RstNo           =  0)       -- 받아온 학습신청번호와  
       AND (D.DeptSeq           = @DeptSeq          OR @DeptSeq         =  0)       -- 받아온 부서코드와  
       AND (D.EmpSeq            = @EmpSeq           OR @EmpSeq          =  0)       -- 받아온 사원코드와  
       AND (A.RegDate          >= @RegBegDate       OR @RegBegDate      = '')       -- 받아온 일자 사이에 있는 조건  
       AND (A.RegDate          <= @RegEndDate       OR @RegEndDate      = '')  
  
  ORDER BY EmpName    -- 사원이름 순으로 정렬  
  
  
RETURN  
  