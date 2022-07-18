IF OBJECT_ID('KPX_SHRBasCertificateGWQuery') IS NOT NULL 
    DROP PROC KPX_SHRBasCertificateGWQuery 
GO 

-- v2015.09.25 

/************************************************************  
 설  명 - 증명서신청-GW조회  
 작성일 - 2014.12.18  
 작성자 - 전경만  
************************************************************/  
  CREATE PROC dbo.KPX_SHRBasCertificateGWQuery      
  @xmlDocument    NVARCHAR(MAX),    
  @xmlFlags       INT     = 0,    
  @ServiceSeq     INT     = 0,    
  @WorkingTag     NVARCHAR(10)= '',    
  @CompanySeq     INT     = 1,    
  @LanguageSeq    INT     = 1,    
  @UserSeq        INT     = 0,    
  @PgmSeq         INT     = 0    
 AS     
    
    CREATE TABLE #GWTemp 
    (
        EmpSeq      INT, 
        CertiSeq    INT 
    ) 
    INSERT INTO #GWTemp ( EmpSeq, CertiSeq ) 
    SELECT CONVERT(INT,LEFT(TblKey,CHARINDEX(',',TblKey) - 1)), CONVERT(INT,REPLACE(TblKey, LEFT(TblKey,CHARINDEX(',',TblKey) - 1) + ',', ''))
      FROM #TblKeyData 
    
    
    SELECT  ISNULL(B.EmpName      , '') AS EmpName      ,    -- 사원  
            ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,    -- 사원(코드)  
            ISNULL(B.EmpID        , '') AS EmpID        ,    -- 사번  
            ISNULL(D.DeptName     , '') AS DeptName     ,    -- 부서  
            ISNULL(A.CertiSeq     ,  0) AS CertiSeq     ,    -- 증명서일련번호  
            ISNULL(A.SMCertiType  ,  0) AS SMCertiType  ,    -- 증명서구분(코드)  
            ISNULL(A.ApplyDate    , '') AS ApplyDate    ,     -- 신청일  
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
            --ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS ResidID      ,    -- 주민번호  
            --ISNULL(dbo._FCOMMaskConv(@EnvValue1,dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq))),  '') AS ResidIdM, --주민번호  
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
                       AND CompanySeq = A.CompanySeq), '') AS SMCertiStatusName, -- 증명서구분  
            ISNULL((SELECT MinorName  
                      FROM _TDASMinor WITH(NOLOCK)  
                     WHERE MinorSeq     = A.SMCertiType  
                       AND A.CompanySeq = CompanySeq), '') AS SMCertiTypeName, -- 발생사원  
            ISNULL((SELECT EmpName  
                      FROM _TDAEmp WITH(NOLOCK)  
          WHERE CompanySeq   = A.CompanySeq  
                       AND EmpSeq       = A.IssueEmpSeq), '')  AS IssueEmpName  
                --DATEDIFF(MONTH, CONVERT(DATETIME, EntDate), CONVERT(DATETIME, RetireDate)) + 1 AS Term,    -- 재직기간  
                --ISNULL(@CompanyName, '') AS CompanyName,    -- 회사명  
                --ISNULL(@Owner      , '') AS Owner      ,    -- 대표자  
                --ISNULL(@OwnerJpName, '') AS OwnerJpName,    -- 대표직책  
                --ISNULL(B.TypeSeq   ,  0) AS TypeSeq         -- 재직/퇴직여부  
                                                     -- 사원정보(사번, 부서 등)  
           FROM #GWTemp AS Z 
                      JOIN _THRBasCertificate               AS A WITH(NOLOCK) ON A.CompanySeq = @CompanySeq AND A.EmpSeq = Z.EmpSeq AND A.CertiSeq = Z.CertiSeq 
                      JOIN _fnAdmEmpOrd(@CompanySeq, '')   AS B              ON A.CompanySeq = @CompanySeq AND A.EmpSeq = B.EmpSeq  -- 영문사원명과 주민번호  
                      JOIN _TDAEmp                         AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq  
                                                     -- 영문부서명  
           LEFT OUTER JOIN _TDADept                         AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND B.DeptSeq = D.DeptSeq  
    
    RETURN
go
    EXEC _SCOMGroupWarePrint 2, 1, 1, 1026509, 'CTM_CM','GROUP000000000000065', '' 