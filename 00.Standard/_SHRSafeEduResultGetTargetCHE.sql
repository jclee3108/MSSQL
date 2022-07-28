IF OBJECT_ID('_SHRSafeEduResultGetTargetCHE') IS NOT NULL 
    DROP PROC _SHRSafeEduResultGetTargetCHE
GO 

-- v2015.08.03 
/************************************************************
  설  명 - 데이터-안전교육_capro : 대상자/교육자검색
  작성일 - 20110427
  작성자 - 천경민
 ************************************************************/
 CREATE PROC dbo._SHRSafeEduResultGetTargetCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
      SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      DECLARE @docHandle      INT,
             @BizUnit        INT,
             @MultiWkTeamSeq NVARCHAR(200),
             @MultiUMPgSeq   NVARCHAR(200),
             @WkTeamSeq      INT,
             @UMPgSeq        INT,
             @EmpSeq         INT,
             @EduYM          NCHAR(6),
             @EduType        INT,
             @EduSubject     NVARCHAR(100),
             @QrySerl        INT
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT @BizUnit        = ISNULL(BizUnit, 0),
            @MultiWkTeamSeq = ISNULL(MultiWkTeamSeq, 0),
            @MultiUMPgSeq   = ISNULL(MultiUMPgSeq, 0),
            @EmpSeq         = ISNULL(EmpSeq, 0),
            @EduYM          = ISNULL(EduYM, 0),
            @EduType        = ISNULL(EduType, 0),
            @EduSubject     = ISNULL(EduSubject, 0),
            @QrySerl        = ISNULL(QrySerl, 0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (BizUnit        INT,
             MultiWkTeamSeq NVARCHAR(200),
             MultiUMPgSeq   NVARCHAR(200),
             EmpSeq         INT,
             EduYM          NCHAR(6),
             EduType        INT,
             EduSubject     NVARCHAR(100),
             QrySerl           INT)
  
     IF @WorkingTag = 'Emp' -- 교육자조회(기등록된)
     BEGIN
     
         SELECT B.EmpSeq        AS EmpSeq,      -- 사원코드
                C.EmpName       AS EmpName,     -- 성명
                C.EmpID         AS EmpID,       -- 사번
                C.DeptName      AS DeptName,    -- 소속부서
                C.UMPgName      AS UMPgName,    -- 직급
                C.UMPgSeq       AS UMPgSeq,     -- 직급코드
                C.DeptSeq       AS DeptSeq,     -- 소속부서코드
                B.WkTeamSeq     AS WkTeamSeq,   -- 근무조내부코드
                G.WkTeamName    AS WkTeamName,  -- 근무조
                B.EmpSeq        AS EmpSeqOld,
                B.IsAttend      AS IsAttend,
                B.OverTime    AS OverTime,
                V.ValueSeq      AS WkItemSeq,
                I.WkItemName    AS WkItemName
           FROM _THRSafeEduResultCHE AS A
                JOIN _THRSafeEduResultEmpCHE     AS B ON A.CompanySeq = B.CompanySeq
                                                       AND A.EduYM      = B.EduYM
                                                       AND A.Serl       = B.Serl
                JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON B.EmpSeq     = C.EmpSeq
                JOIN _TDADept                      AS D ON D.CompanySeq = @CompanySeq
                                                       AND C.DeptSeq    = D.DeptSeq
                JOIN _FCOMXmlToSeq(@WkTeamSeq, @MultiWkTeamSeq) AS E ON (B.WkTeamSeq = CASE WHEN E.Code = 0 THEN B.WkTeamSeq ELSE E.Code END)
                JOIN _FCOMXmlToSeq(@UMPgSeq, @MultiUMPgSeq)     AS F ON (C.UMPgSeq   = CASE WHEN F.Code = 0 THEN C.UMPgSeq   ELSE F.Code END)
                JOIN _TPRWkTeam                    AS G ON B.CompanySeq = G.CompanySeq
                                                       AND B.WkTeamSeq  = G.WkTeamSeq
                LEFT OUTER JOIN _TDAUMinorValue   AS V WITH(NOLOCK) ON V.CompanySeq = A.CompanySeq
                       AND V.MinorSeq   = A.EduType
          LEFT OUTER JOIN _TPRWkItem AS I WITH(NOLOCK) ON I.CompanySeq = V.CompanySeq
                     AND I.WkItemSeq = V.ValueSeq
          WHERE A.CompanySeq = @CompanySeq
            AND A.EduYM      = @EduYM
            AND A.Serl       = @QrySerl
            AND (@BizUnit    = 0  OR D.BizUnit   = @BizUnit)
            AND (@EmpSeq     = 0  OR B.EmpSeq    = @EmpSeq) 
      END
     ELSE
     BEGIN
         SELECT M.EmpSeq        AS EmpSeq,      -- 사원코드
                B.EmpName       AS EmpName,     -- 성명
                B.EmpID         AS EmpID,       -- 사번
                B.DeptName      AS DeptName,    -- 소속부서
                B.UMPgName      AS UMPgName,    -- 직급
                B.UMPgSeq       AS UMPgSeq,     -- 직급코드
                B.DeptSeq       AS DeptSeq,     -- 소속부서코드
                M.WkTeamSeq     AS WkTeamSeq,   -- 근무조내부코드
                C.WkTeamName    AS WkTeamName   -- 근무조
                
                --20110519 전경만 추가
                ,V.ValueSeq    AS WkItemSeq
                ,I.WkItemName   AS WkItemName
           FROM _THRSafeEduCloseCHE AS M
                JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON M.EmpSeq     = B.EmpSeq
                JOIN _TPRWkTeam                    AS C ON M.CompanySeq = C.CompanySeq
                                                       AND M.WkTeamSeq  = C.WkTeamSeq
                JOIN _TDADept                      AS D ON D.CompanySeq = @CompanySeq
                                                       AND B.DeptSeq    = D.DeptSeq
                JOIN _FCOMXmlToSeq(@WkTeamSeq, @MultiWkTeamSeq) AS E ON (M.WkTeamSeq = CASE WHEN E.Code = 0 THEN M.WkTeamSeq ELSE E.Code END)
                JOIN _FCOMXmlToSeq(@UMPgSeq, @MultiUMPgSeq)     AS F ON (B.UMPgSeq   = CASE WHEN F.Code = 0 THEN B.UMPgSeq   ELSE F.Code END)
                
                
                LEFT OUTER JOIN _THRSafeEduResultCHE AS R WITH(NOLOCK) ON R.CompanySeq = M.CompanySeq
                        AND R.EduYM = M.EduYM
                        AND R.Serl = M.Serl
                LEFT OUTER JOIN _TDAUMinorValue   AS V WITH(NOLOCK) ON V.CompanySeq = R.CompanySeq
                       AND V.MinorSeq   = R.EduType
          LEFT OUTER JOIN _TPRWkItem AS I WITH(NOLOCK) ON I.CompanySeq = V.CompanySeq
                     AND I.WkItemSeq = V.ValueSeq
          WHERE M.CompanySeq = @CompanySeq
            AND (@BizUnit    = 0  OR D.BizUnit   = @BizUnit)
            AND (@EmpSeq     = 0  OR B.EmpSeq    = @EmpSeq)
            AND (@EduYM      = '' OR M.EduYM     = @EduYM)
            --AND M.EmpSeq NOT IN (SELECT B.EmpSeq -- 해당월 교육에 한번 참석한 사원은 제외
            --                       FROM _THRSafeEduResultCHE AS A
            --                            LEFT OUTER JOIN _THRSafeEduResultEmpCHE AS B ON A.CompanySeq = B.CompanySeq
            --                                                               AND A.EduYM      = B.EduYM
            --                                                               AND A.Serl       = B.Serl
            --                                                               --AND B.IsAttend   = 0
            --                             LEFT OUTER JOIN _THRSafeEduCloseCHE     AS C ON A.CompanySeq = C.CompanySeq
            --                                              AND A.EduYM      = C.EduYM
            --                                              AND A.Serl       = C.Serl
            --                                              --AND C.IsAttend   = 0
            --                      WHERE A.CompanySeq = @CompanySeq
            --                        AND A.EduYM      = @EduYM
            --                        AND ISNULL(B.IsAttend, C.IsAttend) = 1)
          ORDER BY M.EmpSeq
     END
  RETURN