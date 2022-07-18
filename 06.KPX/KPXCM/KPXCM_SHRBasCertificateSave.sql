IF OBJECT_ID('KPXCM_SHRBasCertificateSave') IS NOT NULL 
    DROP PROC KPXCM_SHRBasCertificateSave
GO 

-- v2015.10.07 

-- KPX용 SubKey, Groupkey 추가 by이재천 
 /************************************************************************************************
  설  명 - 증명서 등록
  작성일 - 2008. 07.17 : 
  작성자 - CREATED BY BCLEE
  수정자 - 
 *************************************************************************************************/
  -- SP파라미터들
 CREATE PROCEDURE KPXCM_SHRBasCertificateSave
     @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML문서로 전달
     @xmlFlags    INT = 0         ,    -- 해당 XML문서의 TYPE
     @ServiceSeq  INT = 0         ,    -- 서비스 번호
     @WorkingTag  NVARCHAR(10)= '',    -- WorkingTag
     @CompanySeq  INT = 1         ,    -- 회사 번호
     @LanguageSeq INT = 1         ,    -- 언어 번호
     @UserSeq     INT = 0         ,    -- 사용자 번호
     @PgmSeq      INT = 0              -- 프로그램 번호
  AS
      -- 서비스 마스터 등록 생성
     CREATE TABLE #THRBasCertificate (WorkingTag NCHAR(1) NULL)
      -- 임시 테이블에 지정된 컬럼을 추가하고, XML문서로부터의 값을 INSERT한다.(DataBlock1의 컬럼들을 임시테이블에 삽입한다.)
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THRBasCertificate'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- 에러가 발생하면 리턴
     END
  
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
     EXEC _SCOMLog @CompanySeq         ,    -- 회사번호
                   @UserSeq            ,    -- 사용자 번호
                   '_THRBasCertificate',    -- 원테이블명    
                   '#THRBasCertificate',    -- 임시 테이블명    
                   'EmpSeq, CertiSeq'  ,    -- 키가 여러개일 경우는 , 로 연결한다.
                   'CompanySeq, EmpSeq, CertiSeq, SMCertiType, ApplyDate, CertiCnt, CertiDecCnt, CertiUseage, CertiSubmit, SMCertiStatus, Task,
                    IsAgree, IsPrt, IssueDate, IssueNo, IssueEmpSeq, IsNoIssue, NoIssueReason, IsEmpApp, LastUserSeq, LastDateTime, TaxFrYm,
                    TaxToYm, TaxPlace, TaxEmpName,ResidIDMYN'    -- 원테이블의 컬럼들
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- 에러가 발생하면 리턴
     END
  
  
  --    -- 승인여부 설정(확정테이블이 아닌 본테이블의 승인컬럼을 갱신하여 준다.)
 --    UPDATE #THRBasCertificate
 --       SET IsAgree = '0'
 --     WHERE (WorkingTag <> 'D' AND Status = 0 AND IsAgree <> '1')
 --
 --    -- 발행여부 설정
 --    UPDATE #THRBasCertificate
 --       SET IsPrt = '0'
 --     WHERE (WorkingTag <> 'D' AND Status = 0 AND IsPrt <> '1')
  
  
      -- DELETE
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'D' AND Status = 0)
     BEGIN
          DELETE _THRBasCertificate
            FROM #THRBasCertificate AS A JOIN _THRBasCertificate B ON B.CompanySeq = @CompanySeq
                                                                 AND A.EmpSeq     = B.EmpSeq
                                                                 AND A.CertiSeq   = B.CertiSeq
           WHERE (A.WorkingTag = 'D' AND A.Status = 0)
  
         IF @@ERROR <> 0
         BEGIN
             RETURN
         END
      END
  
  
      -- UPDATE
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'U' AND Status = 0)
     BEGIN
   
         UPDATE _THRBasCertificate
             SET SMCertiType = A.SMCertiType, ApplyDate     = A.ApplyDate  ,    -- 증명서구분    , 신청일자,
                CertiCnt    = A.CertiCnt   , CertiDecCnt   = A.CertiDecCnt,    -- 신청매수      , 확정매수,
                CertiUseage = A.CertiUseage, CertiSubmit   = A.CertiSubmit,    -- 용도          , 제출처  ,
                Task        = ISNULL(A.JobName,  ''),    -- 담당업무     20100419 직무값컬럼으로 변경 강진아
                IsPrt       = ISNULL(A.IsPrt  , '0'),    -- 발행여부      
                IssueDate   = A.IssueDate  , IssueEmpSeq   = A.IssueEmpSeq  ,    -- 발행일      , 발행자사원코드,
                IsNoIssue   = A.IsNoIssue  , NoIssueReason = A.NoIssueReason,    -- 발급불가여부, 사유          ,
                IsEmpApp    = A.IsEmpApp   , SMCertiStatus = A.SMCertiStatus,    -- 개인신청여부, 발급상태      ,
                LastUserSeq = @UserSeq     , LastDateTime  = GETDATE()      ,
                TaxFrYm     = ISNULL(A.TaxFrYm   , ''), 
                TaxToYm    = ISNULL(A.TaxToYm   , ''), 
                TaxPlace    = ISNULL(A.TaxPlace  , ''),
                TaxEmpName  = ISNULL(A.TaxEmpName, ''),
                IssueNo    = ISNULL(A.IssueNo   , ''),
                ResidIDMYN  = isnull(A.ResidIDMYN, 0 )
                
            FROM #THRBasCertificate AS A JOIN _THRBasCertificate AS B ON B.CompanySeq = @CompanySeq
                                                                    AND A.EmpSeq     = B.EmpSeq
                                                                    AND A.CertiSeq   = B.CertiSeq
          WHERE (A.WorkingTag = 'U' AND A.Status = 0)
  
         IF @@ERROR <> 0
         BEGIN
             RETURN
         END
      END
  
      -- INSERT  
     IF EXISTS (SELECT 1 FROM #THRBasCertificate WHERE WorkingTag = 'A' AND Status = 0)
     BEGIN
     INSERT INTO _THRBasCertificate(CompanySeq   , EmpSeq     ,    -- 법인코드          , 사원코드
                                            CertiSeq     , SMCertiType,    -- 증명서일련번호    , 증명서구분
                                            ApplyDate    , CertiCnt   ,    -- 신청일자          , 발급매수(신청부수)      
                                            CertiDecCnt  , CertiUseage,    -- 확정매수(발급부수), 용도           
                                            CertiSubmit  , Task       ,    -- 제출처            , 담당업무
                                            IsAgree      , IsPrt      ,    -- 승인여부          , 발행여부      
                                            IssueDate    , IssueNo    ,    -- 발행일            , 발행번호
                                            IssueEmpSeq  , IsNoIssue  ,    -- 발행자사원코드    , 발급불가여부
                                            NoIssueReason, IsEmpApp   ,    -- 사유              , 개인신청여부
                                            SMCertiStatus, TaxFrYm    ,    -- 발급상태          , 시작년월
                                            TaxToYm      , TaxPlace   ,    -- 종료년월          , 세무서
                                            TaxEmpName   , LastUserSeq,    -- 담당자            , 작업자
                                            LastDateTime , ResidIdMYN )    -- 작업일시          , 주민등록번호별표처리여부 
                   SELECT @CompanySeq    , A.EmpSeq   ,    -- 회사번호      , 사원코드      ,
                         A.CertiSeq     , A.SMCertiType,    -- 증명서일련번호, 증명서구분코드,
                         A.ApplyDate    , A.CertiCnt   ,    -- 신청일자      , 발급매수      ,
                         A.CertiDecCnt  , A.CertiUseage,    -- 확정매수      , 용도          ,
                         A.CertiSubmit  , ISNULL(A.JobName,  ''),    -- 제출처        , 담당업무      , --  20100419 직무값컬럼으로 변경 강진아
                         '1'            , ISNULL(A.IsPrt  , '0'),    -- 승인여부      , 발행여부      ,
                         A.IssueDate    , A.IssueNo    ,    -- 발행일        , 발행번호      ,
                         A.IssueEmpSeq  , A.IsNoIssue  ,    -- 발행자사원코드, 발급불가여부  ,
                         A.NoIssueReason, A.IsEmpApp   ,    -- 사유          , 개인신청여부  ,
          A.SMCertiStatus, A.TaxFrYm    ,    -- 발급상태, 시작년월
          CASE WHEN A.SMCertiType =3067006 OR  A.SMCertiType =3067007 OR  A.SMCertiType =3067008 THEN  
                             CASE WHEN ISNULL(A.TaxToYm    , '')='' THEN CONVERT(VARCHAR(6), getdate(),112) ELSE  ISNULL(A.TaxToYm    , '') END
                         ELSE  ISNULL(A.TaxToYm    , '') END   , 
                         A.TaxPlace      ,                     -- 종료년월, 세무서
          A.TaxEmpName    , @UserSeq     ,    -- 담당자, 작업자,
                         GETDATE()       , A.ResidIDMYN   -- 작업일시, 주민등록번호별표처리여부
                     FROM #THRBasCertificate AS A
                    WHERE (A.WorkingTag = 'A' AND A.Status = 0)
  
          IF @@ERROR <> 0
      BEGIN
          RETURN
      END
      END
  
  
      -- 발행자 사원 갱신
     UPDATE #THRBasCertificate
         SET IssueEmpName = B.EmpName
        FROM #THRBasCertificate AS A JOIN _TDAEmp AS B ON A.IssueEmpSeq = B.EmpSeq
       WHERE A.Status = 0 AND B.CompanySeq = @CompanySeq
  
    
    UPDATE A   
       SET SubKey = CONVERT(NVARCHAR(10),EmpSeq) + ',' + CONVERT(NVARCHAR(10),CertiSeq)  
      FROM #THRBasCertificate AS A   
    
     SELECT * FROM #THRBasCertificate    -- Output
  RETURN