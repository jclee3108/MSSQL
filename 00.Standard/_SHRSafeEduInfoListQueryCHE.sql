
IF OBJECT_ID('_SHRSafeEduInfoListQueryCHE') IS NOT NULL 
    DROP PROC _SHRSafeEduInfoListQueryCHE
GO 

-- v2015.07.30 

/************************************************************
  설  명 - 데이터-안전교육_capro : 현황조회
  작성일 - 20110427
  작성자 - 천경민
 ************************************************************/
 CREATE PROC dbo._SHRSafeEduInfoListQueryCHE
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
      DECLARE @docHandle     INT,
             @EduYM         NCHAR(6),
             @EduYMTo       NCHAR(6),
             @EduType       INT,
             @IsOverTime    NCHAR(1),
             @IsClose       NCHAR(1),
             @NotAttend     NCHAR(1), 
             @EmpSeq        INT, 
             @DeptSeq       INT, 
             @BizUnit       INT 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT @EduYM      = ISNULL(EduYM     , ''),
            @EduYMTo    = ISNULL(EduYMTo   , ''),
            @EduType    = ISNULL(EduType   , 0),
            @IsOverTime = ISNULL(IsOverTime, '0'),
            @IsClose    = ISNULL(IsClose   , '0'),
            @NotAttend  = ISNULL(NotAttend , '0'), 
            @EmpSeq     = ISNULL(EmpSeq,0), 
            @DeptSeq    = ISNULL(DeptSeq,0), 
            @BizUnit    = ISNULL(BizUnit,0) 
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH (EduYM         NCHAR(6),
             EduYMTo       NCHAR(6),
             EduType       INT,
             IsOverTime    NCHAR(1),
             IsClose       NCHAR(1),
             NotAttend     NCHAR(1), 
             EmpSeq        INT,
             DeptSeq       INT,
             BizUnit       INT 
             )
    SELECT @EduYMTo = '999912' WHERE @EduYMTo = ''
    
    SELECT A.EduYM,
            CASE WHEN A.IsClose = '1' THEN '마감' ELSE '' END AS IsCloseName,
            A.EduDate,
            A.EduType,
            D.MinorName AS EduTypeName,
            A.EduSubject,
            C.EmpName,
            C.EmpID,
            C.DeptName,
            E.WkTeamName,
            ISNULL(B.IsAttend, F.IsAttend) AS IsAttend,
            ISNULL(B.OverTime, F.OverTime) AS OverTime,
            H.WkItemName AS Reason,
            A.Serl, 
            J.BizUnit, 
            J.BizUnitName, 
            I.DeptSeq
             --Reason
       FROM _THRSafeEduResultCHE AS A
            LEFT OUTER JOIN _THRSafeEduResultEmpCHE AS F ON A.CompanySeq = F.CompanySeq
                                                          AND A.EduYM      = F.EduYM
                                                          AND A.Serl       = F.Serl
                                                          --AND A.IsClose    = '0'
                                                          AND @IsClose     = '0'
            LEFT OUTER JOIN _THRSafeEduCloseCHE     AS B ON A.CompanySeq = B.CompanySeq
                                                          AND A.EduYM      = B.EduYM
                                                          AND A.Serl       = B.Serl
                                                          --AND A.IsClose    = '1'
                                                          AND @IsClose     = '1'
            LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS C ON C.EmpSeq = ISNULL(B.EmpSeq, F.EmpSeq)
            LEFT OUTER JOIN _TDAUMinor                AS D ON A.CompanySeq = D.CompanySeq
                                                          AND A.EduType    = D.MinorSeq
            LEFT OUTER JOIN _TPRWkTeam                AS E ON E.CompanySeq = @CompanySeq
                                                          AND E.WkTeamSeq  = ISNULL(B.WkTeamSeq, F.WkTeamSeq)
            LEFT OUTER JOIN _TPRwkAbsEmp AS G WITH(NOLOCK) ON G.CompanySeq = A.CompanySeq
                    AND G.AbsDate = A.EduDate
                    AND G.EmpSeq = C.EmpSeq
                    AND ISNULL(B.IsAttend, F.IsAttend) = '0'
      LEFT OUTER JOIN _TPRWkItem AS H WITH(NOLOCK) ON H.CompanySeq = A.CompanySeq
              AND H.WkItemSeq = G.WkItemSeq
      LEFT OUTER JOIN _TDADept AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDABizUnit AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.BizUnit = I.BizUnit ) 
      WHERE A.CompanySeq = @CompanySeq
        AND A.EduYM BETWEEN @EduYM AND @EduYMTo
        AND (@EduType    = 0   OR A.EduType = @EduType)
        AND (@IsClose    = '0' OR A.IsClose = @IsClose)
        AND (@IsOverTime = '0' OR (@IsOverTime = '1' AND ISNULL(B.OverTime, F.OverTime) > 0))
        --AND (@NotAttend  = '0' OR (@IsClose = '1' AND NOT B.IsAttend = @NotAttend))
        AND (@NotAttend  = '0' OR NOT ISNULL(B.IsAttend, F.IsAttend) = @NotAttend)
        AND (@BizUnit = 0 OR I.BizUnit = @BizUnit) 
        AND (@EmpSeq = 0 OR ISNULL(B.EmpSeq, F.EmpSeq) = @EmpSeq) 
        AND (@DeptSeq = 0 OR I.DeptSeq = @DeptSeq) 
        
      ORDER BY A.EduYM, A.Serl, C.EmpName
 RETURN
 GO 
 exec _SHRSafeEduInfoListQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsOverTime>0</IsOverTime>
    <IsClose>0</IsClose>
    <NotAttend>0</NotAttend>
    <BizUnit />
    <EmpSeq />
    <DeptSeq />
    <EduYM>201501</EduYM>
    <EduYMTo>201507</EduYMTo>
    <EduType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10062,@WorkingTag=N'SS1',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100143