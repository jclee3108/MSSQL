IF OBJECT_ID('KPXCM_SHRBasCertificateQuery') IS NOT NULL 
    DROP PROC KPXCM_SHRBasCertificateQuery
GO 

-- v2015.10.07 

-- KPX용 SubKey, Groupkey 추가 by이재천 
/*************************************************************************************************
  설    명 - 증명서 조회
  작 성 일 - 2008. 07.17 : 
  작 성 자 - CREATED BY BCLEE
  수정내역 - 주소를 주민등록상거주지가 없을경우 실거주지로 조회(있으면 주민등록상거주지로 조회)
             주소를 조회할때는 발행일에 속하는 주소로 조회한다.
             주소를 출력할 때(주소1 + 주소2) 공백을 제거하고 출력(2011.10.28)
             주민등록번호 ResidID울 추가(2012.05.04)
 **************************************************************************************************/
  -- SP파라미터들
 CREATE PROCEDURE KPXCM_SHRBasCertificateQuery
     @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML로 전달
     @xmlFlags    INT = 0         ,    -- 해당 XML의 TYPE
     @ServiceSeq  INT = 0         ,    -- 서비스 번호
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag
     @CompanySeq  INT = 1         ,    -- 회사 번호
     @LanguageSeq INT = 1         ,    -- 언어 번호
     @UserSeq     INT = 0         ,    -- 사용자 번호
     @PgmSeq      INT = 0              -- 프로그램 번호
  AS
      -- 사용할 변수를 선언한다.
     DECLARE @docHandle    INT          ,    -- XML을 핸들할 변수
             @EmpSeq       INT          ,    -- 사원
             @DeptSeq      INT          ,    -- 부서
             @FrApplyDate  NCHAR(8)     ,    -- 신청일(Fr)
             @ToApplyDate  NCHAR(8)     ,    -- 신청일(To)
             @SMCertiType  INT          ,    -- 증명서구분
             @CertiUseage  NVARCHAR(200),    -- 용도
             @IsAgree      NCHAR(1)     ,    -- 승인여부
             @IsPrt        NCHAR(1)     ,    -- 발행여부
             @CompanyName  NVARCHAR(100),    -- 회사명
             @CompanyAddr  NVARCHAR(200),    -- 회사주소
             @Owner        NVARCHAR(50) ,    -- 대표자
             @OwnerJpName  NVARCHAR(100),    -- 대표직책
             @IsConfirmUse NCHAR(1),         -- 확정사용여부
             @EnvValue1    NVARCHAR(100)     -- 환경설정[주민등록번호형식]
             
  
      -- XML파싱
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument XML을 @docHandle로 핸들한다.
      -- XML의 DataBlock1으로부터 값을 가져와 변수에 저장한다.
     SELECT @EmpSeq      = ISNULL(EmpSeq     ,   0),    -- 사원을 가져온다.
            @DeptSeq     = ISNULL(DeptSeq    ,   0),    -- 부서를 가져온다.
            @FrApplyDate = ISNULL(FrApplyDate,  ''),    -- 신청일(Fr)을 가져온다.
            @ToApplyDate = ISNULL(ToApplyDate,  ''),    -- 신청일(To)을 가져온다.
            @SMCertiType = ISNULL(SMCertiType,   0),    -- 증명서구분을 가져온다.
            @CertiUseage = ISNULL(CertiUseage,  ''),    -- 용도를 가져온다.
            @IsAgree     = ISNULL(IsAgree    , '0'),    -- 승인여부포함을 가져온다.
            @IsPrt       = ISNULL(IsPrt      , '0')     -- 발행여부포함을 가져온다.
        FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML의 DataBlock1으로부터
        WITH (EmpSeq      INT          ,
             DeptSeq     INT          ,
    FrApplyDate NCHAR(8)     ,
    ToApplyDate NCHAR(8)     , 
             SMCertiType INT          ,
             CertiUseage NVARCHAR(200),
             IsAgree     NCHAR(1)     ,
             IsPrt       NCHAR(1)
            )
      -- 환경설정에따른주민등록번호형식을담는다.
     SELECT @EnvValue1 = ISNULL(EnvValue, '') FROM _TCOMEnv WHERE CompanySeq = 1 ANd EnvSeq = 16
     IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue1, '') = ''
     BEGIN
         SELECT @EnvValue1 = '999999-9999999'
     END 
   -- 회사명과 대표자명을 가져온다.
     SELECT @CompanyName = CompanyName, @Owner = Owner, @OwnerJpName = OwnerJpName FROM _TCACompany WHERE CompanySeq = @CompanySeq
      -- 회사주소를 가져온다.
  -- SELECT @CompanyAddr = Addr1 + Addr2 FROM _TDATaxUnit
  
      IF(@IsPrt = '1')    -- 발행여부에 체크가 되어 있으면
     BEGIN
          SELECT ISNULL(B.EmpName      , '') AS EmpName      ,    -- 사원
                ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- 사원(코드)
                ISNULL(B.EmpID        , '') AS EmpID        ,    -- 사번
                ISNULL(D.DeptName     , '') AS DeptName     ,    -- 부서
                ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- 증명서일련번호
                ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- 증명서구분(코드)
                ISNULL(A.ApplyDate    , '') AS ApplyDate    ,  -- 신청일
                ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- 신청발급매수
 ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  ,    -- 확정발급부수
                ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- 용도
                ISNULL(A.CertiSubmit  , '') AS CertiSubmit  ,    -- 제출처
                -- ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- 승인여부
                ISNULL(A.IsPrt        , '') AS IsPrt        ,    -- 발행여부
                ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- 발행일
                ISNULL(A.IssueNo      ,  0) AS IssueNo      ,    -- 발행번호
                ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- 발행자사원(코드)
                ISNULL(A.IsNoIssue    , '') AS IsNoIssue    ,    -- 발급불가여부
                ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- 사유
                ISNULL(A.IsEmpApp     , '') AS IsEmpApp     ,    -- 개인신청여부
                ISNULL(B.EntDate      , '') AS EntDate      ,    -- 입사일
                ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- 퇴사일
                ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- 주민번호
                ISNULL(dbo._FCOMMaskConv(@EnvValue1,dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --주민번호
                isnull(A.ResidIDMYN,0)      AS ResidIDMYN   ,    -- 주민등록번호별표처리여부
                ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- 직위
                ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus,    -- 발급상태
                ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- 증명서시작년월
                ISNULL(A.TaxToYm      , '') AS TaxToYm      ,    -- 증명서종료년월
                ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- 세무서
                ISNULL(A.TaxEmpName   , '') AS TaxEmpName   ,    -- 담당자
                ISNULL(A.Task         , B.JobName) AS JobName,    -- 업무
                 -- 증명서발행명
                ISNULL((SELECT MinorName
                          FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq = A.SMCertiStatus
                           AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,
                 -- 영문사원명(영문성이 없을경우 ,를 쓰지 않는다.)
                CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
                     ELSE ISNULL(C.EmpEngLastName + ', ' + C.EmpEngFirstName, '') END AS EmpEngName,
                 -- 주소
                CASE WHEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002          -- 주민등록상거주지의
                                     AND A.IssueDate BETWEEN BegDate AND EndDate       -- 최종주소가 없을 경우
                                  ), '') = ''
                     THEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055003             -- 실거주지의
                                     AND A.IssueDate BETWEEN BegDate AND EndDate), '')    -- 최종주소로 조회한다.
                     ELSE ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002             -- 있으면 주민등록상거주지의
                                     AND A.IssueDate BETWEEN BegDate AND EndDate), '')    -- 최종주소로 조회한다.
                 END AS Addr,    -- 주소
                 -- 증명서구분
                ISNULL((SELECT MinorName
                 FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq     = A.SMCertiType
                           AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,
                 -- 발생사원
                ISNULL((SELECT EmpName
                          FROM _TDAEmp WITH(NOLOCK)
                         WHERE CompanySeq   = A.CompanySeq
                           AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName,
                 DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- 재직기간
                ISNULL(@CompanyName, '') AS CompanyName,    -- 회사명
                ISNULL(@Owner      , '') AS Owner      ,    -- 대표자
                ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- 대표직책
                ISNULL(B.TypeSeq   ,  0) AS TypeSeq,         -- 재직/퇴직여부
                                                      -- 사원정보(사번, 부서 등)
                CONVERT(NVARCHAR(10),ISNULL(A.EmpSeq,  0)) + ',' +  CONVERT(NVARCHAR(10),ISNULL(A.CertiSeq,0)) AS SubKey, 
                G.GroupKey 
           FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
                                                                                                                 AND A.EmpSeq     = B.EmpSeq
                                                      -- 영문사원명과 주민번호
                                                     JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                                                                 AND A.EmpSeq     = C.EmpSeq
                                                      -- 영문부서명
                                                     LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
                                                                                                                 AND B.DeptSeq    = D.DeptSeq
                                                      -- 확정여부
                                                     -- LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                                                     --                                                             AND A.EmpSeq     = E.CfmSeq
                                                     --                                                             AND A.CertiSeq   = E.CfmSerl
                                                     LEFT OUTER JOIN _TCOMGroupWare AS G WITH(NOLOCK)ON A.CompanySeq  = G.CompanySeq  
                                                                                                    AND G.TblKey = CAST(A.EmpSeq AS NVARCHAR) + ',' + CAST(A.CertiSeq AS NVARCHAR)  
                                                                                                    AND G.WorkKind = 'CTM_CM'
           WHERE  A.CompanySeq     = @CompanySeq
            AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =   0)
            AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =   0)    -- 증명서 구분
            AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate =  '')
            AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate =  '')
            AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =   0)
            AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage =  '')    -- 용도
            --AND A.IsEmpApp <> 1    -- 발행화면에서 등록한 경우 20100421 강진아 // 주석처리 20150701 신명철
      END
     ELSE
     BEGIN
          SELECT ISNULL(B.EmpName      , '') AS EmpName      ,    -- 사원
                ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- 사원(코드)
                ISNULL(B.EmpID        , '') AS EmpID        ,    -- 사번
                ISNULL(D.DeptName     , '') AS DeptName     ,    -- 부서
                ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- 증명서일련번호
                ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- 증명서구분(코드)
                ISNULL(A.ApplyDate    , '') AS ApplyDate    ,    -- 신청일
                ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- 신청발급매수
                ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  ,    -- 확정발급부수
                ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- 용도
                ISNULL(A.CertiSubmit  , '') AS CertiSubmit  ,    -- 제출처
                -- ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- 승인여부
                ISNULL(A.IsPrt        , '') AS IsPrt        ,    -- 발행여부
                ISNULL(A.IssueDate     , '') AS IssueDate    ,    -- 발행일
                ISNULL(A.IssueNo      ,  0) AS IssueNo      ,    -- 발행번호
                ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- 발행자사원(코드)
                ISNULL(A.IsNoIssue    , '') AS IsNoIssue    ,    -- 발급불가여부
                ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- 사유
                ISNULL(A.IsEmpApp     , '') AS IsEmpApp     ,    -- 개인신청여부
                ISNULL(B.EntDate      , '') AS EntDate      ,    -- 입사일
                ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- 퇴사일
                ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- 주민번호
                ISNULL(dbo._FCOMMaskConv(@EnvValue1, dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --주민번호
                isnull(A.ResidIDMYN,0)      AS ResidIDMYN   ,    -- 주민등록번호별표처리여부
                ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- 직위
                ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus,    -- 발급상태
                ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- 증명서시작년월
                ISNULL(A.TaxToYm      , '') AS TaxToYm      ,    -- 증명서종료년월
                ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- 세무서
                ISNULL(A.TaxEmpName   , '') AS TaxEmpName   ,    -- 담당자
                ISNULL(A.Task         , B.JobName) AS JobName,    -- 업무
                 -- 증명서발행명
                ISNULL((SELECT MinorName
                          FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq = A.SMCertiStatus
                           AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,
                 -- 영문사원명(영문성이 없을경우 ,를 쓰지 않는다.)
                CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
                     ELSE ISNULL(C.EmpEngLastName + ', ' + C.EmpEngFirstName, '') END AS EmpEngName,
                 -- 주소
                CASE WHEN ISNULL((SELECT ISNULL(Addr1, '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE CompanySeq    = @CompanySeq
                                     AND EmpSeq        = A.EmpSeq
                                     AND SMAddressType = 3055002          -- 주민등록상거주지의
                                     AND EndDate       = '99991231'       -- 최종주소가 없을 경우
                                  ), '') = ''
                     THEN ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE A.CompanySeq  = CompanySeq
                                     AND A.EmpSeq      = EmpSeq
                                     AND SMAddressType = 3055003             -- 실거주지의
                                     AND EndDate       = '99991231'), '')    -- 최종주소로 조회한다.
                     ELSE ISNULL((SELECT ISNULL(LTRIM(RTRIM(Addr1)), '') + ' ' + ISNULL(LTRIM(RTRIM(Addr2)), '')
                                    FROM _THRBasAddress WITH(NOLOCK)
                                   WHERE A.CompanySeq  = CompanySeq
                                     AND A.EmpSeq      = EmpSeq
                                     AND SMAddressType = 3055002             -- 있으면 주민등록상거주지의
                                     AND EndDate       = '99991231'), '')    -- 최종주소로 조회한다.
                 END AS Addr,    -- 주소
                 -- 증명서구분
                ISNULL((SELECT MinorName
                          FROM _TDASMinor WITH(NOLOCK)
                         WHERE MinorSeq     = A.SMCertiType
                           AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,
                 -- 발생사원
                ISNULL((SELECT EmpName
                          FROM _TDAEmp WITH(NOLOCK)
                         WHERE CompanySeq   = A.CompanySeq
                           AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName,
                 DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- 재직기간
                ISNULL(@CompanyName, '') AS CompanyName,    -- 회사명
                ISNULL(@Owner      , '') AS Owner      ,    -- 대표자
                ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- 대표직책
                ISNULL(B.TypeSeq   ,  0) AS TypeSeq,         -- 재직/퇴직여부
                                                      -- 사원정보(사번, 부서 등)
                CONVERT(NVARCHAR(10),ISNULL(A.EmpSeq,  0)) + ',' +  CONVERT(NVARCHAR(10),ISNULL(A.CertiSeq,0)) AS SubKey, 
                G.GroupKey 
           FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON A.CompanySeq = @CompanySeq 
                                                                                            AND A.EmpSeq     = B.EmpSeq
                                                      -- 영문사원명과 주민번호
                                                     JOIN _TDAEmp                       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                                                         AND A.EmpSeq     = C.EmpSeq
                                                      -- 영문부서명
                                                     LEFT OUTER JOIN _TDADept           AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
                                                                                                         AND B.DeptSeq    = D.DeptSeq
                                                      -- 확정여부
                                                     -- LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
                                                     --                                                             AND A.EmpSeq     = E.CfmSeq
                                                     --                                                             AND A.CertiSeq   = E.CfmSerl
                                                     LEFT OUTER JOIN _TCOMGroupWare AS G WITH(NOLOCK)ON A.CompanySeq  = G.CompanySeq  
                                                                                                    AND G.TblKey = CAST(A.EmpSeq AS NVARCHAR) + ',' + CAST(A.CertiSeq AS NVARCHAR)  
                                                                                                    AND G.WorkKind = 'CTM_CM'
           WHERE  A.CompanySeq     = @CompanySeq
            AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =  0)
            AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =  0)    -- 증명서 구분
            AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate = '')
            AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate = '')
            AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =  0)
            AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage = '')    -- 용도
            AND (ISNULL(A.IsPrt  , 0) = @IsPrt)
           -- AND A.IsEmpApp <> 1       -- 발행화면에서 등록한 경우 20100421 강진아 // 주석처리 20150701 신명철
      END
      -- 시트에 값을 출력하는 부분
 --    IF(@IsAgree = '1' AND @IsPrt = '1')
 --    BEGIN
 --
 --        SELECT ISNULL(B.EmpName      , '') AS EmpName      , ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- 사원          , 사원코드      ,
 --               ISNULL(A.CertiSeq     ,  0) AS CertiSeq     , ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- 증명서일련번호, 증명서구분코드,
 --               ISNULL(A.ApplyDate    , '') AS ApplyDate    , ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- 신청일        , 신청발급매수  ,
 --               ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  , ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- 확정발급부수  , 용도          ,
 --               ISNULL(A.CertiSubmit  , '') AS CertiSubmit  , ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- 제출처        , 승인여부      ,
 --               ISNULL(A.IsPrt        , '') AS IsPrt        , ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- 발행여부      , 발행일        ,
 --               ISNULL(A.IssueNo      ,  0) AS IssueNo      , ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- 발행번호      , 발행자사원코드,
 --               ISNULL(A.IsNoIssue    , '') AS IsNoIssue    , ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- 발급불가여부  , 사유  ,
 --               ISNULL(A.IsEmpApp     , '') AS IsEmpApp     , ISNULL(B.EmpID        , '') AS EmpID        ,    -- 개인신청여부  , 사번          ,
 --               ISNULL(B.EntDate      , '') AS EntDate      , ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- 입사일        , 퇴사일        ,
 --               ISNULL(C.ResidID      , '') AS ResidID      , ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- 주민번호      , 직위          ,
 --               ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus, ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- 발급상태    , 증명서시작년월,
 --               ISNULL(A.TaxToYm      , '') AS TaxToYm      , ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- 증명서종료년월, 세무서        ,
 --               ISNULL(A.TaxEmpName   , '') AS TaxEmpName   , ISNULL(A.Task         , '') AS JobName         ,    -- 담당자        , 업무          ,
 --               ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE MinorSeq = A.SMCertiStatus AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,    -- 증명서발행명
 --               CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
 --                    ELSE ISNULL(C.EmpEngFirstName + ',' + C.EmpEngLastName, '') END AS EmpEngName,    -- 영문사원명(영문성이 없을경우 ,를 쓰지 않는다.),
 --               CASE WHEN (@SMCertiType = 3067001 OR @SMCertiType = 3067002) THEN D.DeptName ELSE D.EngDeptName END AS DeptName,    -- (영문)부서명,
 --               ISNULL((SELECT Addr1 + Addr2 FROM _THRBasAddress WHERE A.CompanySeq = CompanySeq    AND A.EmpSeq     = EmpSeq AND SMAddressType = 3055003 AND EndDate = '99991231'), '') AS Addr,    -- 주소
 --               ISNULL((SELECT MinorName     FROM _TDASMinor     WHERE MinorSeq     = A.SMCertiType AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,    -- 증명서구분,
 --               ISNULL((SELECT EmpName       FROM _TDAEmp        WHERE CompanySeq   = A.CompanySeq  AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName   ,    -- 발행자사원,
 --               DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- 재직기간
 --               @CompanyName AS CompanyName, @Owner AS Owner, @OwnerJpName AS OwnerJpName, B.TypeSeq AS TypeSeq    -- 회사명, 대표자, 대표직책, 재직/퇴직여부
 --
 --                                                    -- 사원정보(사번, 부서 등)를 가져오기 위한 조인
 --          FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
 --                                                                                                                AND A.EmpSeq     = B.EmpSeq
 --
 --                                                    -- 영문사원명과 주민번호를 가져오기 위한 조인
 --                                                    JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
 --                                                                                                                AND A.EmpSeq     = C.EmpSeq
 --
 --                                                    -- 영문부서명을 가져오기 위한 조인
 --                                                    LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
 --                                                                                                                AND B.DeptSeq    = D.DeptSeq
 --
 --                                                    -- 확정여부를 가져오기 위한 조인
 --                                                    LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
 --                                                                                                                AND A.EmpSeq     = E.CfmSeq
 --                                                                                                                AND A.CertiSeq   = E.CfmSerl
 --
 --         WHERE  A.CompanySeq     = @CompanySeq
 --           AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =  0)
 --           AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =  0)    -- 증명서 구분
 --           AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate = '')
 --           AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate = '')
 --           AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =  0)
 --           AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage = '')    -- 용도
 --           AND A.IsEmpApp <> 1       -- 발행화면에서 등록한 경우 20100421 강진아
 --
 --    END
 --    ELSE IF(@IsAgree = '1')
 --    BEGIN
 --
 --        SELECT ISNULL(B.EmpName      , '') AS EmpName      , ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- 사원          , 사원코드      ,
 --               ISNULL(A.CertiSeq     ,  0) AS CertiSeq     , ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- 증명서일련번호, 증명서구분코드,
 --               ISNULL(A.ApplyDate    , '') AS ApplyDate    , ISNULL(A.CertiCnt     ,  0) AS CertiCnt     ,    -- 신청일        , 신청발급매수  ,
 --               ISNULL(A.CertiDecCnt  ,  0) AS CertiDecCnt  , ISNULL(A.CertiUseage  , '') AS CertiUseage  ,    -- 확정발급부수  , 용도          ,
 --               ISNULL(A.CertiSubmit  , '') AS CertiSubmit  , ISNULL(E.CfmCode      , '') AS IsAgree      ,    -- 제출처        , 승인여부      ,
 --               ISNULL(A.IsPrt        , '') AS IsPrt        , ISNULL(A.IssueDate    , '') AS IssueDate    ,    -- 발행여부      , 발행일        ,
 --               ISNULL(A.IssueNo      ,  0) AS IssueNo      , ISNULL(A.IssueEmpSeq  ,  0) AS IssueEmpSeq  ,    -- 발행번호      , 발행자사원코드,
 --               ISNULL(A.IsNoIssue    , '') AS IsNoIssue    , ISNULL(A.NoIssueReason, '') AS NoIssueReason,    -- 발급불가여부  , 사유          ,
 --               ISNULL(A.IsEmpApp     , '') AS IsEmpApp     , ISNULL(B.EmpID        , '') AS EmpID        ,    -- 개인신청여부  , 사번          ,
 --               ISNULL(B.EntDate      , '') AS EntDate      , ISNULL(B.RetireDate   , '') AS RetireDate   ,    -- 입사일        , 퇴사일        ,
 --               ISNULL(C.ResidID      , '') AS ResidID      , ISNULL(B.UMJpName     , '') AS UMJpName     ,    -- 주민번호      , 직위          ,
 --               ISNULL(A.SMCertiStatus,  0) AS SMCertiStatus, ISNULL(A.TaxFrYm      , '') AS TaxFrYm      ,    -- 발급상태    , 증명서시작년월,
 --               ISNULL(A.TaxToYm      , '') AS TaxToYm      , ISNULL(A.TaxPlace     , '') AS TaxPlace     ,    -- 증명서종료년월, 세무서        ,
 --               ISNULL(A.TaxEmpName   , '') AS TaxEmpName   , ISNULL(A.Task         , '') AS JobName         ,    -- 담당자        , 업무          ,
 --               ISNULL((SELECT MinorName FROM _TDASMinor WITH(NOLOCK) WHERE MinorSeq = A.SMCertiStatus AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName,    -- 증명서발행명
 --               CASE WHEN ISNULL(EmpEngLastName, '') = '' THEN ISNULL(C.EmpEngFirstName + C.EmpEngLastName, '')
 --                    ELSE ISNULL(C.EmpEngFirstName + ',' + C.EmpEngLastName, '') END AS EmpEngName,    -- 영문사원명(영문성이 없을경우 ,를 쓰지 않는다.),
 --               CASE WHEN (@SMCertiType = 3067001 OR @SMCertiType = 3067002) THEN D.DeptName ELSE D.EngDeptName END AS DeptName,    -- (영문)부서명,
 --               ISNULL((SELECT Addr1 + Addr2 FROM _THRBasAddress WHERE A.CompanySeq = CompanySeq    AND A.EmpSeq     = EmpSeq AND SMAddressType = 3055003 AND EndDate = '99991231'), '') AS Addr,    -- 주소
 --               ISNULL((SELECT MinorName     FROM _TDASMinor     WHERE MinorSeq     = A.SMCertiType AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName,    -- 증명서구분,
 --               ISNULL((SELECT EmpName       FROM _TDAEmp        WHERE CompanySeq   = A.CompanySeq  AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName   ,    -- 발행자사원,
 --               DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- 재직기간
 --               @CompanyName AS CompanyName, @Owner AS Owner, @OwnerJpName AS OwnerJpName, B.TypeSeq AS TypeSeq    -- 회사명, 대표자, 대표직책, 재직/퇴직여부
 --
 --                                                    -- 사원정보(사번, 부서 등)를 가져오기 위한 조인
 --          FROM _THRBasCertificate AS A WITH(NOLOCK) JOIN _fnAdmEmpOrd(@CompanySeq, '')         AS B              ON A.CompanySeq = @CompanySeq 
 --                                                                                                                AND A.EmpSeq     = B.EmpSeq
 --
 --                                                    -- 영문사원명과 주민번호를 가져오기 위한 조인
 --                                                     JOIN _TDAEmp                               AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
 --                                                                                                                AND A.EmpSeq     = C.EmpSeq
 --
 --                                                    -- 영문부서명을 가져오기 위한 조인
 --                                                    LEFT OUTER JOIN _TDADept                   AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
 --                                                                                                                AND B.DeptSeq    = D.DeptSeq
 --
 --                                                    -- 확정여부를 가져오기 위한 조인
 --                                                    LEFT OUTER JOIN _THRBasCertificate_Confirm AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq
 --                                                                                                                AND A.EmpSeq     = E.CfmSeq
 --                                                                                                                AND A.CertiSeq   = E.CfmSerl
 --         WHERE  A.CompanySeq     = @CompanySeq
 --           AND (A.EmpSeq         = @EmpSeq            OR @EmpSeq      =   0)
 --           AND (A.SMCertiType    = @SMCertiType       OR @SMCertiType =   0)    -- 증명서 구분
 --           AND (A.ApplyDate     <= @ToApplyDate       OR @ToApplyDate =  '')
 --           AND (A.ApplyDate     >= @FrApplyDate       OR @FrApplyDate =  '')
 --           AND (B.DeptSeq        = @DeptSeq           OR @DeptSeq     =   0)
 --           AND (A.CertiUseage LIKE @CertiUseage + '%' OR @CertiUseage =  '')    -- 용도
 --           AND (ISNULL(A.IsPrt,0)          = @IsPrt             OR @IsPrt       = '0')
 --           AND A.IsEmpApp <> 1       -- 발행화면에서 등록한 경우 20100421 강진아
 --
 --    END
  RETURN