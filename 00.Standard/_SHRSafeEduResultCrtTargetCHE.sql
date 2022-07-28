
IF OBJECT_ID('_SHRSafeEduResultCrtTargetCHE') IS NOT NULL 
    DROP PROC _SHRSafeEduResultCrtTargetCHE
GO 

-- v2015.05.18

/************************************************************
  설  명 - 데이터-안전교육_capro : 대상자생성
  작성일 - 20110427
  작성자 - 천경민
 ************************************************************/
 CREATE PROC dbo._SHRSafeEduResultCrtTargetCHE 
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     DECLARE @docHandle     INT,
             @BizUnit       INT,
             @WkTeamSeq     INT,
             @UMPgSeq       INT,
             @MultiUMPgSeq  NVARCHAR(200),
             @EmpSeq        INT,
             @EduYM         NCHAR(6),
             @EduType       INT,
             @EduSubject    NVARCHAR(100)
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT @BizUnit      = ISNULL(BizUnit, 0),
            @WkTeamSeq    = ISNULL(WkTeamSeq, 0),
            @UMPgSeq      = ISNULL(UMPgSeq, 0),
            @MultiUMPgSeq = ISNULL(MultiUMPgSeq, 0),
            @EduYM        = ISNULL(EduYM, 0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (BizUnit       INT,
             WkTeamSeq     INT,
             UMPgSeq       INT,
             MultiUMPgSeq  NVARCHAR(200),
             EduYM         NCHAR(6))
  
      IF (SELECT COUNT(1) FROM _THRSafeEduResultCHE WHERE CompanySeq = @CompanySeq AND EduYM = @EduYM AND IsClose = '1') > 0
     BEGIN
         SELECT '1' AS IsClose
         RETURN
     END
  
     -- 해당년월 대상자 삭제
     DELETE _THRSafeEduCloseCHE
       FROM _THRSafeEduCloseCHE AS A
            JOIN dbo._fnAdmEmpOrd(@CompanySeq, @EduYM + '01') AS B ON A.EmpSeq     = B.EmpSeq
            --JOIN _FCOMXmlToSeq(@UMPgSeq, @MultiUMPgSeq) AS C ON (B.UMPgSeq = CASE WHEN C.Code = 0 THEN B.UMPgSeq ELSE C.Code END)
            JOIN _TDADept                                     AS D ON D.CompanySeq = @CompanySeq
                                                                  AND B.DeptSeq    = D.DeptSeq
      WHERE A.CompanySeq = @CompanySeq
        AND A.EduYM      = @EduYM
        AND (@BizUnit = 0 OR D.BizUnit = @BizUnit)
  
     INSERT INTO _THRSafeEduCloseCHE (CompanySeq, EduYM, EmpSeq, WkTeamSeq, LastUserSeq, LastDateTime)
     SELECT @CompanySeq, @EduYM, A.EmpSeq, A.WkTeamSeq, @UserSeq, GETDATE()
       FROM _TPRWkEmpTeam AS A WITH(NOLOCK)
            JOIN dbo._fnAdmEmpOrd(@CompanySeq, @EduYM + '01') AS B ON A.EmpSeq     = B.EmpSeq
                                                                  AND B.TypeSeq    = 3031001 -- 재직자만
                                                                  --AND B.PtSeq     IN (1, 2)  -- 상용직, 월급직만
            JOIN _TPRWkTeam                                   AS C ON A.CompanySeq = C.CompanySeq
                                                                  AND A.WkTeamSeq  = C.WkTeamSeq
            JOIN _TDADept                                     AS D ON D.CompanySeq = @CompanySeq
                                                                  AND B.DeptSeq    = D.DeptSeq
            JOIN (SELECT A2.EmpSeq, A2.Seq
                    FROM _TPRWkEmpTeam AS A2
                   WHERE A2.CompanySeq = @CompanySeq
                     AND A2.EndDate = (SELECT MAX(EndDate)
                                         FROM _TPRWkEmpTeam WITH(NOLOCK)
                                        WHERE CompanySeq = @CompanySeq
                                          AND EmpSeq = A2.EmpSeq)
                 ) AS F ON A.EmpSeq = F.EmpSeq 
                       AND A.Seq = F.Seq
            JOIN _FCOMXmlToSeq(@UMPgSeq, @MultiUMPgSeq) AS E ON (B.UMPgSeq = CASE WHEN E.Code = 0 THEN B.UMPgSeq ELSE E.Code END)
      WHERE A.CompanySeq = @CompanySeq
        AND (@BizUnit    = 0 OR D.BizUnit   = @BizUnit)
        AND (@WkTeamSeq  = 0 OR A.WkTeamSeq = @WkTeamSeq)
  
     SELECT '0' AS IsClose
  RETURN