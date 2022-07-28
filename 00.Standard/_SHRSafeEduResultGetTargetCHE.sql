IF OBJECT_ID('_SHRSafeEduResultGetTargetCHE') IS NOT NULL 
    DROP PROC _SHRSafeEduResultGetTargetCHE
GO 

-- v2015.08.03 
/************************************************************
  ��  �� - ������-��������_capro : �����/�����ڰ˻�
  �ۼ��� - 20110427
  �ۼ��� - õ���
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
  
     IF @WorkingTag = 'Emp' -- ��������ȸ(���ϵ�)
     BEGIN
     
         SELECT B.EmpSeq        AS EmpSeq,      -- ����ڵ�
                C.EmpName       AS EmpName,     -- ����
                C.EmpID         AS EmpID,       -- ���
                C.DeptName      AS DeptName,    -- �ҼӺμ�
                C.UMPgName      AS UMPgName,    -- ����
                C.UMPgSeq       AS UMPgSeq,     -- �����ڵ�
                C.DeptSeq       AS DeptSeq,     -- �ҼӺμ��ڵ�
                B.WkTeamSeq     AS WkTeamSeq,   -- �ٹ��������ڵ�
                G.WkTeamName    AS WkTeamName,  -- �ٹ���
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
         SELECT M.EmpSeq        AS EmpSeq,      -- ����ڵ�
                B.EmpName       AS EmpName,     -- ����
                B.EmpID         AS EmpID,       -- ���
                B.DeptName      AS DeptName,    -- �ҼӺμ�
                B.UMPgName      AS UMPgName,    -- ����
                B.UMPgSeq       AS UMPgSeq,     -- �����ڵ�
                B.DeptSeq       AS DeptSeq,     -- �ҼӺμ��ڵ�
                M.WkTeamSeq     AS WkTeamSeq,   -- �ٹ��������ڵ�
                C.WkTeamName    AS WkTeamName   -- �ٹ���
                
                --20110519 ���游 �߰�
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
            --AND M.EmpSeq NOT IN (SELECT B.EmpSeq -- �ش�� ������ �ѹ� ������ ����� ����
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