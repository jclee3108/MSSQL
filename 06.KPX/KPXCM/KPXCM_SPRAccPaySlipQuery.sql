IF OBJECT_ID('KPXCM_SPRAccPaySlipQuery') IS NOT NULL 
    DROP PROC KPXCM_SPRAccPaySlipQuery
GO 

-- v2015.11.12 

/************************************************************************************************
  설    명 - 회계처리급상여내역 조회
  작 성 일 - 2008.12.00 :
  작 성 자 - CREATEd by
  수정내역 - 급여종료일 추가(2012.05.21)
 *************************************************************************************************/
  -- SP파라미터들
 CREATE PROCEDURE KPXCM_SPRAccPaySlipQuery
     @xmlDocument NVARCHAR(MAX)    ,    -- : 화면의 정보를 XML로 전달
     @xmlFlags    INT = 0          ,    -- : 해당 XML의 Type
     @ServiceSeq  INT = 0          ,    -- : 서비스 번호
     @WorkingTag  NVARCHAR(10) = '',    -- : WorkingTag
     @CompanySeq  INT = 1          ,    -- : 회사 번호
     @LanguageSeq INT = 1          ,    -- : 언어 번호
     @UserSeq     INT = 0          ,    -- : 사용자 번호
     @PgmSeq      INT = 0               -- : 프로그램 번호
  AS
      -- 사용할 변수를 선언한다.
     DECLARE @docHandle INT     ,
             @EnvValue  INT     ,
             @AccUnit   INT     ,
             @PuSeq     INT     ,
             @PbYM      NCHAR(6),
             @SerialNo  INT     ,
             @Sql       NVARCHAR(4000)
  
      -- XML파싱
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument의 XML을 @docHandle로 핸들한다.
      SELECT @EnvValue = ISNULL(EnvValue,  0),    -- 원가구분
            @AccUnit  = ISNULL(AccUnit ,  0),    -- 회계단위
            @PuSeq    = ISNULL(PuSeq   ,  0),    -- 급여작업군
            @PbYM     = ISNULL(PbYM    , ''),    -- 적용연월
            @SerialNo = ISNULL(SerialNo,  0)     -- 일련번호
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML의 DataBlock1으로부터
       WITH (EnvValue INT     ,
             AccUnit  INT     ,
             PuSeq    INT     ,
             PbYM     NCHAR(6),
             SerialNo INT
            )
  
      -- 시트조회
     SELECT A.Seq               AS Seq,             -- 행번호
            A.PbYM              AS PbYM,            -- 적용년월
            A.PuSeq             AS PuSeq,           -- 급여작업군
            (SELECT PUName FROM _TPRBasPu WHERE  CompanySeq = A.CompanySeq AND PuSeq = A.PuSeq) AS PuName,
            A.SerialNo          AS SerialNo,        -- 일련번호
            C.AccUnit           AS AccUnit,         -- 회계단위
            (SELECT AccUnitName FROM _TDAAccUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND AccUnit = C.AccUnit) AS AccUnitName,          -- 회계단위명
            A.SlipUnit          AS SlipUnit,        -- 전표관리단위코드
            (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND SlipUnit = A.SlipUnit) AS SlipUnitName,     -- 전표관리단위
            A.RowSlipUnit       AS RowSlipUnit,     -- 행별전표관리단위
            (SELECT SlipUnitName FROM _TACSlipUnit WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND SlipUnit = A.RowSlipUnit) AS RowSlipUnitName, -- 행별전표관리단위
            A.AccSeq            AS AccSeq,          -- 계정내부코드
            B.AccName           AS AccName,         -- 계정과목
            A.UMCostType        AS UMCostType,      -- 비용구분
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMCostType) AS UMCostTypeName,                   -- 비용구분
            A.SMDrOrCr          AS SMDrOrCr,        -- 차대구분
            (SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorValue = A.SMDrOrCr AND MajorSeq = 4001) AS SMDrOrCrName, -- 차대구분
            A.DrAmt             AS DrAmt,           -- 차변금액
            A.CrAmt             AS CrAmt,           -- 대변금액
            A.DrForAmt          AS DrForAmt,        -- 외화차변금액
            A.CrForAmt          AS CrForAmt,        -- 외화대변금액
            A.SlipDeptSeq       AS SlipDeptSeq,     -- 예산부서코드
             CASE WHEN @EnvValue = 5518003 THEN
                      (SELECT DetlDeptName FROM _TPEACDetlBizSubDept WHERE CompanySeq = A.CompanySeq AND Seq = A.SlipDeptSeq )
                 ELSE
                      (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.SlipDeptSeq) 
            END AS SlipDeptName,    -- 예산부서
            A.CostDeptSeq       AS CostDeptSeq,     -- 귀속부서코드
            (SELECT DeptName FROM _TDADept WHERE CompanySeq  = A.CompanySeq AND DeptSeq = A.CostDeptSeq) AS CostDeptName,    -- 귀속부서
            A.SlipCCtrSeq       AS SlipCCtrSeq,     -- 예산활동센터코드
            CASE WHEN @EnvValue = 5518003 THEN
                      (SELECT DetlDeptName FROM _TPEACDetlBizSubDept WHERE CompanySeq = A.CompanySeq AND Seq = A.SlipCCtrSeq )
                 ELSE
                      (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.SlipCCtrSeq)
            END AS SlipCCtrName,    -- 예산활동센터
            A.CostCCtrSeq       AS CostCCtrSeq,     -- 귀속활동센터코드
            (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.CostCCtrSeq) AS CostCCtrName,    -- 귀속활동센터
            A.DeptSeq           AS DeptSeq,         -- 발생부서코드
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName,            -- 발생부서
            A.DtlSeq            AS DtlSeq,          -- 발생원천코드
            CASE WHEN A.EnvValue = 5518002 THEN 
                      (SELECT CCtrName FROM _TDACCtr WHERE CompanySeq = A.CompanySeq AND CCtrSeq = A.DtlSeq)
                 ELSE
                      (SELECT DeptName FROM _TDADept WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DtlSeq)
             END                 AS DtlName,        -- 발생원천
            A.BgtSeq            AS BgtSeq,          -- 예산과목내부코드
            (SELECT BgtName FROM _TACBgtItem WHERE CompanySeq = A.CompanySeq AND BgtSeq = A.BgtSeq) AS BgtName,         -- 예산과목
            A.CurrSeq           AS CurrSeq,         -- 통화내부코드
            (SELECT CurrName FROM _TDACurr WHERE CompanySeq = A.CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName,        -- 통화
            A.ExRate            AS ExRate,          -- 환율
            A.RemSeq1           AS RemSeq1,         -- 관리항목내부코드1
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq1) AS RemName1,    -- 관리항목1
            A.RemValSeq1        AS RemValSeq1,      -- 관리항목내부코드값1
            SPACE(200)          AS RemValName1,     -- 관리항목값1
            A.RemValText1       AS RemValText1,     -- 관리항목텍스트값1
            A.RemSeq2           AS RemSeq2,         -- 관리항목내부코드2
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq2) AS RemName2,    -- 관리항목2
            A.RemValSeq2        AS RemValSeq2,      -- 관리항목내부코드값2
            SPACE(200)          AS RemValName2,     -- 관리항목값2
            A.RemValText2       AS RemValText2,     -- 관리항목텍스트값2
            A.RemSeq3           AS RemSeq3,         -- 관리항목내부코드3
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq3) AS RemName3,    -- 관리항목3
            A.RemValSeq3        AS RemValSeq3,      -- 관리항목내부코드값3
            SPACE(200)          AS RemValName3,     -- 관리항목값3
            A.RemValText3       AS RemValText3,     -- 관리항목텍스트값3
            A.RemSeq4           AS RemSeq4,         -- 관리항목내부코드4
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq4) AS RemName4,    -- 관리항목4
            A.RemValSeq4        AS RemValSeq4,      -- 관리항목내부코드값4
            SPACE(200)          AS RemValName4,     -- 관리항목값4
            A.RemValText4       AS RemValText4,     -- 관리항목텍스트값4
            A.RemSeq5           AS RemSeq5,         -- 관리항목내부코드5
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq5) AS RemName5,    -- 관리항목5
            A.RemValSeq5        AS RemValSeq5,      -- 관리항목내부코드값5
            SPACE(200)          AS RemValName5,     -- 관리항목값5
            A.RemValText5       AS RemValText5,     -- 관리항목텍스트값5
            A.RemSeq6           AS RemSeq6,         -- 관리항목내부코드6
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq6) AS RemName6,    -- 관리항목6
            A.RemValSeq6        AS RemValSeq6,      -- 관리항목내부코드값6
            SPACE(200)          AS RemValName6,     -- 관리항목값6
            A.RemValText6       AS RemValText6,     -- 관리항목텍스트값6
            A.RemSeq7           AS RemSeq7,         -- 관리항목내부코드7
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq7) AS RemName7,    -- 관리항목7
            A.RemValSeq7        AS RemValSeq7,      -- 관리항목내부코드값7
            SPACE(200)          AS RemValName7,     -- 관리항목값7
            A.RemValText7       AS RemValText7,     -- 관리항목텍스트값7
            A.RemSeq8           AS RemSeq8,         -- 관리항목내부코드8
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq8) AS RemName8,    -- 관리항목8
            A.RemValSeq8        AS RemValSeq8,      -- 관리항목내부코드값8
            SPACE(200)          AS RemValName8,     -- 관리항목값8
            A.RemValText8       AS RemValText8,     -- 관리항목텍스트값8
            A.RemSeq9           AS RemSeq9,         -- 관리항목내부코드9
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq9) AS RemName9,    -- 관리항목9
            A.RemValSeq9        AS RemValSeq9,      -- 관리항목내부코드값9
            SPACE(200)          AS RemValName9,     -- 관리항목값9
            A.RemValText9       AS RemValText9,     -- 관리항목텍스트값9
            A.RemSeq10          AS RemSeq10,        -- 관리항목내부코드10
            (SELECT RemName FROM _TDAAccountRem WHERE CompanySeq = A.CompanySeq AND RemSeq = A.RemSeq10) AS RemName10,  -- 관리항목10
            A.RemValSeq10       AS RemValSeq10,     -- 관리항목내부코드값10
            SPACE(200)          AS RemValName10,    -- 관리항목값10
            A.RemValText10      AS RemValText10,    -- 관리항목텍스트값10
            SPACE(200)          AS RemValText,      -- 변수텍스트
            A.AccDate           AS AccDate,         -- 회계일
            A.Remark            AS Remark,          -- 적요
            A.SlipSeq           AS SlipSeq,         -- 기표일련번호
            A.IsSet             AS IsSet,           -- 승인여부
            ISNULL((SELECT SlipID FROM _TACSlipRow WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipSeq = A.SlipSeq), '') AS SlipID,
            A.PayEndDate        AS PayEndDate       -- 급여종료일(2012.05.21)
        INTO #TPRAccPaySlip
        FROM _TPRAccPaySlip AS A LEFT OUTER JOIN _TDAAccount AS B ON A.CompanySeq = B.CompanySeq
                                                                AND A.AccSeq     = B.AccSeq
        LEFT OUTER JOIN _TDACCtr    AS C ON ( C.CompanySeq = @CompanySeq AND C.CCtrSeq = A.DtlSeq ) 
       WHERE A.CompanySeq = @CompanySeq
        AND A.EnvValue   = @EnvValue
        AND C.AccUnit    = @AccUnit
        AND A.PuSeq      = @PuSeq
        AND A.PbYM       = @PbYM
        AND A.SerialNo   = @SerialNo
    ORDER BY A.Seq
  
      SET @Sql = ''
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD CodeHelpSeq    INT '
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD CodeHelpParams NVARCHAR(50) '  
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD RemName        NVARCHAR(100) '  
     SET @Sql = @Sql + 'ALTER TABLE #TPRAccPaySlip ADD RemRefValue    NVARCHAR(400) '  
  
      EXEC SP_EXECUTESQL @Sql
  
      IF @@ERROR <> 0
     BEGIN
         RETURN
     END
      -- 만들어진 임시테이블의 컬럼을 구성하기 끝.
  
      -- 명칭을 가져온다.    
     -- 실행 후에는 ValueName 컬럼이 자동생성되어 진다.
     IF EXISTS (SELECT RemValSeq1 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq1, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq1', 'RemValName1'  
     END
      IF EXISTS (SELECT RemValSeq2 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq2, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq2', 'RemValName2'  
     END
      IF EXISTS (SELECT RemValSeq3 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq3, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq3', 'RemValName3'  
     END
      IF EXISTS (SELECT RemValSeq4 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq4, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq4', 'RemValName4'  
     END
      IF EXISTS (SELECT RemValSeq5 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq5, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq5', 'RemValName5'  
     END
      IF EXISTS (SELECT RemValSeq6 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq6, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq6', 'RemValName6'  
     END
      IF EXISTS (SELECT RemValSeq7 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq7, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq7', 'RemValName7'  
     END
      IF EXISTS (SELECT RemValSeq8 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq8, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq8', 'RemValName8'  
     END
      IF EXISTS (SELECT RemValSeq9 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq9, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq9', 'RemValName9'  
     END
      IF EXISTS (SELECT RemValSeq10 FROM #TPRAccPaySlip WHERE ISNULL(RemValSeq10, 0) <> 0)
     BEGIN
         EXEC _SPRPaySlipRemData @CompanySeq, @LanguageSeq, '#TPRAccPaySlip','RemSeq10', 'RemValName10'  
     END
  
      SELECT * FROM #TPRAccPaySlip ORDER BY SMDrOrCr DESC, AccSeq, Seq
  RETURN
GO 
