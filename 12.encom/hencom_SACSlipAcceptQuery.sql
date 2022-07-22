IF OBJECT_ID('hencom_SACSlipAcceptQuery') IS NOT NULL 
    DROP PROC hencom_SACSlipAcceptQuery
GO 

-- v2017.08.22
/************************************************************
설  명 - 전표 접수, 승인, 출력, 삭제 조회
작성일 - 2005년 6월 16일
작성자 - 김일주
************************************************************/
CREATE PROC hencom_SACSlipAcceptQuery
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10) = '',
    @CompanySeq     INT = 0,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    -- 변수 선언
    DECLARE @docHandle      INT,
            @AccUnit        INT,
            @SlipUnit       INT,
            @AccDateFrom    NVARCHAR(8),
            @AccDateTo      NVARCHAR(8),
            @SlipNoFrom     NVARCHAR(4),
            @SlipNoTo       NVARCHAR(4),
            @SlipKind       INT,
            @RegDeptSeq     INT,
            @RegEmpSeq      INT,
            @SMCurrStatus   INT,
            @IsSet          NVARCHAR(7),
            @IncludeSubDept NCHAR(1),
            @AccClass       INT,
            @PgmID          NVARCHAR(100),
            @SlipSetNoFrom  NVARCHAR(4),
            @SlipSetNoTo    NVARCHAR(4),
            @SetAccDateFrom NVARCHAR(8),
            @SetAccDateTo   NVARCHAR(8),
            @DataIsSet      NCHAR(1),
            @EnvValue       NCHAR(1),
            @AptEmpSeq      INT,
            @EnvValue4007   NCHAR(1),
            @IsDoneGW       NCHAR(1),        --전자결재완료여부
			@SetEmpSeq      INT
    -- xml준비
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT  @AccUnit        = ISNULL(AccUnit, 0),
            @SlipUnit       = ISNULL(SlipUnit, 0),
            @AccDateFrom    = ISNULL(AccDateFrom, ''),
            @AccDateTo      = ISNULL(AccDateTo, ''),
            @SlipNoFrom     = LTRIM(RTRIM(SlipNoFrom)),
            @SlipNoTo       = LTRIM(RTRIM(SlipNoTo)),
            @SlipKind       = ISNULL(SlipKind, 0),
            @RegDeptSeq     = ISNULL(RegDeptSeq, 0),
            @RegEmpSeq      = ISNULL(RegEmpSeq, 0),
            @SMCurrStatus   = ISNULL(SMCurrStatus, 0),
            @IsSet          = ISNULL(IsSet, ''),
            @IncludeSubDept = ISNULL(IncludeSubDept, ''),
            @SlipSetNoFrom  = ISNULL(SlipSetNoFrom, ''),
            @SlipSetNoTo    = ISNULL(SlipSetNoTo, ''),
            @SetAccDateFrom = ISNULL(SetAccDateFrom, ''),
            @SetAccDateTo   = ISNULL(SetAccDateTo, ''),
            @AptEmpSeq      = ISNULL(AptEmpSeq,0),
            @IsDoneGW       = ISNULL(IsDoneGW, '0'),
			@SetEmpSeq      = ISNULL(SetEmpSeq,0)
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (  AccUnit         INT,
            SlipUnit        INT,
            AccDateFrom     NCHAR(8),
            AccDateTo       NCHAR(8),
            SlipNoFrom      NCHAR(4),
            SlipNoTo        NCHAR(4),
            SlipKind        INT,
            RegDeptSeq      INT,
            RegEmpSeq       INT,
            SMCurrStatus    INT,
            IsSet           NVARCHAR(7),
            IncludeSubDept  NCHAR(1),
            SlipSetNoFrom   NCHAR(4),
            SlipSetNoTo     NCHAR(4),
            SetAccDateFrom  NCHAR(8),
            SetAccDateTo    NCHAR(8),
            AptEmpSeq       INT,
            IsDoneGW        NCHAR(1),
			SetEmpSeq       INT)
    -- [계정과목정보]의 "자금승인여부"에 체크된 계정이 포함된 전표는 [자금승인처리]화면에서만 승인처리 가능하다.
    -- FrmACSlipApproval	    전표승인처리
    -- FrmACSlipApprovalCash	자금승인처리
    SELECT @PgmID = ISNULL(PgmID, '') FROM _TCAPgm WITH(NOLOCK) WHERE PgmSeq = @PgmSeq
    --화면[전표승인처리]에서재무승인+자금승인설정전표는조회하지않음
    EXEC dbo._SCOMEnv @CompanySeq,4042,@UserSeq,@@PROCID, @EnvValue OUTPUT    
    --_TACSlip 에 있는 RegAccDate가 없던 시절의 코딩으로 현재 의미가 없어 제거함.
    IF @SetAccDateFrom <> '' OR @SetAccDateTo <> '' OR @SlipSetNoFrom <> '' OR @SlipSetNoFrom <> ''
    BEGIN
    --    SELECT @AccDateFrom = '', @AccDateTo = ''
        SELECT @DataIsSet = '1'
    END
     
	IF @PgmSeq = 300257   -- 전표연속출력
	BEGIN 
		SELECT @EnvValue4007 = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq and EnvSeq = 4007 -- 접수처리 사용 여부
		IF @EnvValue4007 = '0'
		BEGIN 
			SELECT @AptEmpSeq = 0
		END	
	END
     
    IF @SlipNoTo = '' SELECT @SlipNoTo = 'zzzz' 
    IF @SlipSetNoTo = '' SELECT @SlipSetNoTo = 'zzzz'
    IF @SetAccDateTo = '' AND @SetAccDateFrom <> '' SELECT @SetAccDateTo = '99991231'
    SELECT @SlipNoFrom = RIGHT('000' + RTRIM(LTRIM(@SlipNoFrom)), 4)
    SELECT @SlipNoTo = RIGHT('000' + RTRIM(LTRIM(@SlipNoTo)), 4)
    SELECT @SlipSetNoFrom = RIGHT('000' + RTRIM(LTRIM(@SlipSetNoFrom)), 4)
    SELECT @SlipSetNoTo = RIGHT('000' + RTRIM(LTRIM(@SlipSetNoTo)), 4)
   
    -- 전표 jumpID를 가져오기 위해 임시테이블로 변경
    CREATE TABLE #temp_TACSlipMaster
    (
        SlipMstID       NVARCHAR(30),
        CheckValue      NCHAR(1),
        AptRemark       NVARCHAR(100),
        AptDate         NCHAR(8),
        AptDeptName     NVARCHAR(100),
        AptEmpName      NVARCHAR(100),
        SetEmpName      NVARCHAR(100),
        DrAmt           DECIMAL(19,5),
        CrAmt           DECIMAL(19,5),
        DrForAmt        DECIMAL(19,5),
        CrForAmt        DECIMAL(19,5),
        CurrName        NVARCHAR(100),       
        RegDeptName     NVARCHAR(100),
        RegEmpName      NVARCHAR(100),
        Remark          NVARCHAR(2000),
        CompanySeq      INT,
        SlipMstSeq      INT,
        SMCurrStatus    INT,   
        SMCheckStatus   INT, 
        IsSet           NCHAR(1),
        LinkedPgmID     NVARCHAR(100),
        LinkedPgmName   NVARCHAR(200),
        SlipNo          NVARCHAR(100),
        AccDate         NCHAR(8),
        BfrAccDate      NCHAR(8),
        AccUnit         INT,
        SlipUnit        INT,
        RegDeptSeq      INT
    )

    IF @WorkingTag <> ''
    BEGIN
        IF @IncludeSubDept = '1' AND @RegDeptSeq <> ''
        BEGIN
            SELECT DISTINCT
                   A.SlipMstSeq
              INTO #tmpDept
              FROM _TACSlip A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow F WITH (NOLOCK)
                           ON F.CompanySeq  = A.CompanySeq
                          AND F.SlipMstSeq  = A.SlipMstSeq
                   INNER JOIN _TDAAccount H WITH (NOLOCK)
                           ON H.CompanySeq  = F.CompanySeq
                          AND H.AccSeq      = F.AccSeq
                          AND H.IsFundSet   = CASE WHEN @WorkingTag = 'FUND' THEN '1'
                                                   WHEN @WorkingTag = 'ACC'  THEN '0' END
                   INNER JOIN (
                            SELECT DeptSeq FROM _fnOrgDept(@CompanySeq, 3059001, @RegDeptSeq, @AccDateTo)
                            UNION
                            SELECT @RegDeptSeq) O ON O.DeptSeq = A.RegDeptSeq
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '')  OR (@IsSet = 1016001 AND A.IsSet In ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
        END
        ELSE
        BEGIN
            SELECT DISTINCT
                   A.SlipMstSeq
              INTO #tmp
              FROM _TACSlip A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow F WITH (NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.SlipMstSeq = A.SlipMstSeq
                   INNER JOIN _TDAAccount H WITH (NOLOCK) ON H.CompanySeq = F.CompanySeq AND H.AccSeq = F.AccSeq
                                                         AND H.IsFundSet = CASE WHEN @WorkingTag = 'FUND' THEN '1'
                                                                                WHEN @WorkingTag = 'ACC' THEN '0' END
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))  
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '') OR (@IsSet = 1016001 AND A.IsSet IN ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@RegDeptSeq = 0  OR A.RegDeptSeq = @RegDeptSeq)
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
       
        END

        IF @IncludeSubDept = '1' AND @RegDeptSeq <> ''
        BEGIN
           INSERT INTO #temp_TACSlipMaster( SlipMstID       ,CheckValue      ,AptRemark       ,AptDate         ,AptDeptName     ,
                                            AptEmpName      ,SetEmpName      ,DrAmt          ,CrAmt           ,DrForAmt        ,
                                            CrForAmt        ,CurrName        ,RegDeptName     ,RegEmpName      ,Remark          ,
                                            CompanySeq      ,SlipMstSeq      ,SMCurrStatus    ,SMCheckStatus   ,IsSet           ,
                                            LinkedPgmID     ,LinkedPgmName   ,SlipNo          ,AccDate         ,BfrAccDate      ,
                                            AccUnit         ,SlipUnit        ,RegDeptSeq)
           SELECT 
                   MAX(A.SlipMstID)     AS SlipMstID,       -- 전표기표번호
                   0                    AS CheckValue,      -- 선택
                   MAX(A.AptRemark)     AS AptRemark,       -- 메모
                   MAX(A.AptDate)       AS AptDate,         -- 접수일
                   MAX(C.DeptName)      AS AptDeptName,     -- 접수부서
                   MAX(B.EmpName)       AS AptEmpName,      -- 접수자
                   MAX(D.EmpName)       AS SetEmpName,      -- 승인자
                   SUM(F.DrAmt)         AS DrAmt,           -- 원화차변금액
                   SUM(F.CrAmt)         AS CrAmt,           -- 원화대변금액
                   SUM(F.DrForAmt)      AS DrForAmt,        -- 외화차변금액
                   SUM(F.CrForAmt)      AS CrForAmt,        -- 외화대변금액
                   MAX(E.CurrName)      AS CurrName,        -- 통화
                   MAX(G.DeptName)      AS RegDeptName,     -- 기표부서
                   MAX(H.EmpName)       AS RegEmpName,      -- 기표자
                   MAX(A.Remark)        AS Remark,          -- 적요
                   A.CompanySeq,                            -- 법인코드
                   A.SlipMstSeq,                            -- 전표마스터코드
                   MAX(A.SMCurrStatus)  AS SMCurrStatus,    -- 접수상태
                   MAX(A.SMCheckStatus) AS SMCheckStatus,   -- 정정상태
                   MAX(A.IsSet)         AS IsSet,           -- 승인여부
                   MAX(P.PgmId)         AS LinkedPgmID,
                   MAX(P.Caption)       AS LinkedPgmName,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.SetSlipID)
                        ELSE '' END AS SlipNo,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.AccDate) 
                        ELSE '' END AS AccDate,
--                   CASE WHEN MAX(A.IsSet) = '0' OR MAX(A.IsSet) = '' THEN MAX(A.AccDate) 
--                        ELSE '' END AS BfrAccDate
                   MAX(A.RegAccDate) AS BfrAccDate,
                   MAX(A.AccUnit)    AS AccUnit,
                   MAX(A.SlipUnit)   AS SlipUnit,
                   MAX(A.RegDeptSeq) AS RegDeptSeq
              FROM _TACSlip A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow F WITH (NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.SlipMstSeq = A.SlipMstSeq
                   INNER JOIN (
                            SELECT DeptSeq FROM _fnOrgDept(@CompanySeq, 3059001, @RegDeptSeq, @AccDateTo)
                            UNION
                            SELECT @RegDeptSeq) O ON O.DeptSeq = A.RegDeptSeq
                   LEFT JOIN _TACSlipKind AS K WITH (NOLOCK)
                           ON K.CompanySeq  = A.CompanySeq
                          AND K.SlipKind    = A.SlipKind
                   LEFT JOIN _TCAPgm AS P WITH (NOLOCK)
                           ON P.PgmSeq      = K.PgmSeq
                   LEFT JOIN _TDAEmp    B WITH (NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.EmpSeq = A.AptEmpSeq
                   LEFT JOIN _TDADept   C WITH (NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.DeptSeq = A.AptDeptSeq
                   LEFT JOIN _TDAEmp    D WITH (NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.EmpSeq = A.SetEmpSeq
                   LEFT JOIN _TDACurr   E WITH (NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.CurrSeq = F.CurrSeq
                   LEFT JOIN _TDADept   G WITH (NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.DeptSeq = A.RegDeptSeq
                   LEFT JOIN _TDAEmp AS H WITH (NOLOCK) ON H.CompanySeq = A.CompanySeq AND H.EmpSeq = A.RegEmpSeq
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))  
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '') OR (@IsSet = 1016001 AND A.IsSet IN ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@RegEmpSeq  = 0  OR A.RegEmpSeq = @RegEmpSeq)
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND EXISTS (SELECT * FROM #tmpDept WHERE SlipMstSeq = A.SlipMstSeq)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
               AND (@AptEmpSeq  = 0 OR A.AptEmpSeq = @AptEmpSeq)
			   AND (@SetEmpSeq  = 0 OR A.SetEmpSeq = @SetEmpSeq)
             GROUP BY A.CompanySeq, A.SlipMstSeq, F.SlipID
             ORDER BY MAX(A.SlipMstID)
        END
        ELSE
        BEGIN
           INSERT INTO #temp_TACSlipMaster( SlipMstID       ,CheckValue      ,AptRemark       ,AptDate         ,AptDeptName     ,
                                            AptEmpName      ,SetEmpName      ,DrAmt           ,CrAmt           ,DrForAmt        ,
                                            CrForAmt        ,CurrName        ,RegDeptName     ,RegEmpName      ,Remark          ,
                                            CompanySeq      ,SlipMstSeq      ,SMCurrStatus    ,SMCheckStatus   ,IsSet           ,
                                            LinkedPgmID     ,LinkedPgmName   ,SlipNo          ,AccDate         ,BfrAccDate      ,
                                            AccUnit         ,SlipUnit        ,RegDeptSeq)
           SELECT
                   MAX(A.SlipMstID)     AS SlipMstID,       -- 전표기표번호
                   0                    AS CheckValue,      -- 선택
                   MAX(A.AptRemark)     AS AptRemark,       -- 메모
                   MAX(A.AptDate)       AS AptDate,         -- 접수일
                   MAX(C.DeptName)      AS AptDeptName,     -- 접수부서
                   MAX(B.EmpName)       AS AptEmpName,      -- 접수자
                   MAX(D.EmpName)       AS SetEmpName,      -- 승인자
                   SUM(F.DrAmt)         AS DrAmt,           -- 원화차변금액
                   SUM(F.CrAmt)         AS CrAmt,           -- 원화대변금액
                   SUM(F.DrForAmt)      AS DrForAmt,        -- 외화차변금액
                   SUM(F.CrForAmt)      AS CrForAmt,        -- 외화대변금액
                   MAX(E.CurrName)      AS CurrName,        -- 통화
                   MAX(G.DeptName)      AS RegDeptName,     -- 기표부서
                   MAX(H.EmpName)       AS RegEmpName,      -- 기표자
                   MAX(A.Remark)        AS Remark,          -- 적요
                   A.CompanySeq,                            -- 법인코드
                   A.SlipMstSeq,                            -- 전표마스터코드
                   MAX(A.SMCurrStatus)  AS SMCurrStatus,    -- 접수상태
                   MAX(A.SMCheckStatus) AS SMCheckStatus,   -- 정정상태
                   MAX(A.IsSet)         AS IsSet,           -- 승인여부
                   MAX(P.PgmId)         AS LinkedPgmID,
                   MAX(P.Caption)       AS LinkedPgmName,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.SetSlipID)
                        ELSE '' END AS SlipNo,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.AccDate) 
                        ELSE '' END AS AccDate,
--                   CASE WHEN MAX(A.IsSet) = '0' OR MAX(A.IsSet) = '' THEN MAX(A.AccDate) 
--                        ELSE '' END AS BfrAccDate
                   MAX(A.RegAccDate) AS BfrAccDate,
                   MAX(A.AccUnit)    AS AccUnit,
                   MAX(A.SlipUnit)   AS SlipUnit,
                   MAX(A.RegDeptSeq) AS RegDeptSeq                   
              FROM _TACSlip A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow   F WITH (NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.SlipMstSeq = A.SlipMstSeq
                   LEFT  JOIN _TACSlipKind AS K WITH (NOLOCK)
                           ON K.CompanySeq  = A.CompanySeq
                          AND K.SlipKind    = A.SlipKind
                   LEFT  JOIN _TCAPgm AS P WITH (NOLOCK)
                           ON P.PgmSeq      = K.PgmSeq
                   LEFT JOIN _TDAEmp        B WITH (NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.EmpSeq = A.AptEmpSeq
                   LEFT JOIN _TDADept       C WITH (NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.DeptSeq = A.AptDeptSeq
                   LEFT JOIN _TDAEmp        D WITH (NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.EmpSeq = A.SetEmpSeq
                   LEFT JOIN _TDACurr       E WITH (NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.CurrSeq = F.CurrSeq
                   LEFT JOIN _TDADept       G WITH (NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.DeptSeq = A.RegDeptSeq
                   LEFT  JOIN _TDAEmp AS H WITH (NOLOCK)
                           ON H.CompanySeq  = A.CompanySeq
                          AND H.EmpSeq      = A.RegEmpSeq
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))  
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '') OR (@IsSet = 1016001 AND A.IsSet IN ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@RegDeptSeq = 0  OR A.RegDeptSeq = @RegDeptSeq)
               AND (@RegEmpSeq  = 0  OR A.RegEmpSeq = @RegEmpSeq)
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND EXISTS (SELECT * FROM #tmp WHERE SlipMstSeq = A.SlipMstSeq)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
               AND (@AptEmpSeq  = 0 OR A.AptEmpSeq = @AptEmpSeq)
			   AND (@SetEmpSeq  = 0 OR A.SetEmpSeq = @SetEmpSeq)
             GROUP BY A.CompanySeq, A.SlipMstSeq, F.SlipID
             ORDER BY MAX(A.SlipMstID)
            DROP TABLE #tmp
        END
    END
    ELSE
    BEGIN
        IF @IncludeSubDept = '1' AND @RegDeptSeq <> ''
        BEGIN
           INSERT INTO #temp_TACSlipMaster( SlipMstID       ,CheckValue      ,AptRemark       ,AptDate         ,AptDeptName     ,
                                            AptEmpName      ,SetEmpName      ,DrAmt           ,CrAmt           ,DrForAmt        ,
                                            CrForAmt        ,CurrName        ,RegDeptName     ,RegEmpName      ,Remark          ,
                                            CompanySeq      ,SlipMstSeq      ,SMCurrStatus    ,SMCheckStatus   ,IsSet           ,
                                            LinkedPgmID     ,LinkedPgmName   ,SlipNo          ,AccDate         ,BfrAccDate      ,
                                            AccUnit         ,SlipUnit        ,RegDeptSeq)
            SELECT
                   MAX(A.SlipMstID)     AS SlipMstID,       -- 전표기표번호
                   0                    AS CheckValue,      -- 선택
                   MAX(A.AptRemark)     AS AptRemark,       -- 메모
                   MAX(A.AptDate)       AS AptDate,         -- 접수일
                   MAX(C.DeptName)      AS AptDeptName,     -- 접수부서
                   MAX(B.EmpName)       AS AptEmpName,      -- 접수자
                   MAX(D.EmpName)       AS SetEmpName,      -- 승인자
                   SUM(F.DrAmt)         AS DrAmt,           -- 원화차변금액
                   SUM(F.CrAmt)         AS CrAmt,           -- 원화대변금액
                   SUM(F.DrForAmt)      AS DrForAmt,        -- 외화차변금액
                   SUM(F.CrForAmt)      AS CrForAmt,        -- 외화대변금액
                   MAX(E.CurrName)      AS CurrName,        -- 통화
                   MAX(G.DeptName)      AS RegDeptName,     -- 기표부서
                   MAX(H.EmpName)       AS RegEmpName,      -- 기표자
                   MAX(A.Remark)        AS Remark,          -- 적요
                   A.CompanySeq,                            -- 법인코드
                   A.SlipMstSeq,                            -- 전표마스터코드
                   MAX(A.SMCurrStatus)  AS SMCurrStatus,    -- 접수상태
                   MAX(A.SMCheckStatus) AS SMCheckStatus,   -- 정정상태
                   MAX(A.IsSet)         AS IsSet,           -- 승인여부
                   MAX(P.PgmId)         AS LinkedPgmID,
                   MAX(P.Caption)       AS LinkedPgmName,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.SetSlipID)
                        ELSE '' END AS SlipNo,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.AccDate) 
                        ELSE '' END AS AccDate,
--                   CASE WHEN MAX(A.IsSet) = '0' OR MAX(A.IsSet) = '' THEN MAX(A.AccDate) 
--                        ELSE '' END AS BfrAccDate
                   MAX(A.RegAccDate) AS BfrAccDate,
                   MAX(A.AccUnit)    AS AccUnit,
                   MAX(A.SlipUnit)   AS SlipUnit,
                   MAX(A.RegDeptSeq) AS RegDeptSeq                   
              FROM _TACSlip A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow F WITH (NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.SlipMstSeq = A.SlipMstSeq
                   INNER JOIN (
                            SELECT DeptSeq FROM _fnOrgDept(@CompanySeq, 3059001, @RegDeptSeq, @AccDateTo)
                            UNION
                            SELECT @RegDeptSeq) O ON O.DeptSeq = A.RegDeptSeq
                   LEFT  JOIN _TACSlipKind AS K WITH (NOLOCK)
                           ON K.CompanySeq  = A.CompanySeq
                          AND K.SlipKind    = A.SlipKind
                   LEFT  JOIN _TCAPgm AS P WITH (NOLOCK)
                           ON P.PgmSeq      = K.PgmSeq
                   LEFT JOIN _TDAEmp    B WITH (NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.EmpSeq = A.AptEmpSeq
                   LEFT JOIN _TDADept   C WITH (NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.DeptSeq = A.AptDeptSeq
                   LEFT JOIN _TDAEmp    D WITH (NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.EmpSeq = A.SetEmpSeq
                   LEFT JOIN _TDACurr   E WITH (NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.CurrSeq = F.CurrSeq
                   LEFT JOIN _TDADept   G WITH (NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.DeptSeq = A.RegDeptSeq
                   LEFT JOIN _TDAEmp AS H WITH (NOLOCK) ON H.CompanySeq = A.CompanySeq AND H.EmpSeq = A.RegEmpSeq
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))  
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '') OR (@IsSet = 1016001 AND A.IsSet IN ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@RegEmpSeq  = 0  OR A.RegEmpSeq = @RegEmpSeq)
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
               AND (@AptEmpSeq  = 0 OR A.AptEmpSeq = @AptEmpSeq)
			   AND (@SetEmpSeq  = 0 OR A.SetEmpSeq = @SetEmpSeq)
             GROUP BY A.CompanySeq, A.SlipMstSeq
             ORDER BY MAX(A.SlipMstID)
        END
        ELSE
        BEGIN
           INSERT INTO #temp_TACSlipMaster( SlipMstID       ,CheckValue      ,AptRemark       ,AptDate         ,AptDeptName     ,
     AptEmpName      ,SetEmpName      ,DrAmt           ,CrAmt           ,DrForAmt        ,
                                            CrForAmt        ,CurrName        ,RegDeptName     ,RegEmpName      ,Remark          ,
                                            CompanySeq      ,SlipMstSeq      ,SMCurrStatus    ,SMCheckStatus   ,IsSet           ,
                                            LinkedPgmID     ,LinkedPgmName   ,SlipNo          ,AccDate         ,BfrAccDate      ,
                                            AccUnit         ,SlipUnit        ,RegDeptSeq)
            SELECT
                   MAX(A.SlipMstID)     AS SlipMstID,       -- 전표기표번호
                   0                    AS CheckValue,      -- 선택
                   MAX(A.AptRemark)     AS AptRemark,       -- 메모
                   MAX(A.AptDate)       AS AptDate,         -- 접수일
                   MAX(C.DeptName)      AS AptDeptName,     -- 접수부서
                   MAX(B.EmpName)       AS AptEmpName,      -- 접수자
                   MAX(D.EmpName)       AS SetEmpName,      -- 승인자
                   SUM(F.DrAmt)         AS DrAmt,           -- 원화차변금액
                   SUM(F.CrAmt)         AS CrAmt,           -- 원화대변금액
                   SUM(F.DrForAmt)      AS DrForAmt,        -- 외화차변금액
                   SUM(F.CrForAmt)      AS CrForAmt,        -- 외화대변금액
                   MAX(E.CurrName)      AS CurrName,        -- 통화
                   MAX(G.DeptName)      AS RegDeptName,     -- 기표부서
                   MAX(H.EmpName)       AS RegEmpName,      -- 기표자
                   MAX(A.Remark)        AS Remark,          -- 적요
                   A.CompanySeq,                            -- 법인코드
                   A.SlipMstSeq,                            -- 전표마스터코드
                   MAX(A.SMCurrStatus)  AS SMCurrStatus,    -- 접수상태
                   MAX(A.SMCheckStatus) AS SMCheckStatus,   -- 정정상태
                   MAX(A.IsSet)         AS IsSet,           -- 승인여부
                   MAX(P.PgmId)         AS LinkedPgmID,
                   MAX(P.Caption)       AS LinkedPgmName,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.SetSlipID)
                        ELSE '' END AS SlipNo,
                   CASE WHEN MAX(A.IsSet) = '1' THEN MAX(A.AccDate) 
                        ELSE '' END AS AccDate,
                   MAX(A.RegAccDate) AS BfrAccDate,
                   MAX(A.AccUnit)    AS AccUnit,
                   MAX(A.SlipUnit)   AS SlipUnit,
                   MAX(A.RegDeptSeq) AS RegDeptSeq                   
              FROM _TACSlip AS A WITH (NOLOCK)
                   INNER JOIN _TACSlipRow AS F WITH (NOLOCK)
                           ON F.CompanySeq  = A.CompanySeq
                          AND F.SlipMstSeq  = A.SlipMstSeq
                   LEFT  JOIN _TACSlipKind AS K WITH (NOLOCK)
                           ON K.CompanySeq  = A.CompanySeq
                          AND K.SlipKind    = A.SlipKind
                   LEFT  JOIN _TCAPgm AS P WITH (NOLOCK)
                           ON P.PgmSeq      = K.PgmSeq
                   LEFT  JOIN _TDAEmp AS B WITH (NOLOCK)
                           ON B.CompanySeq  = A.CompanySeq
                          AND B.EmpSeq      = A.AptEmpSeq
                   LEFT  JOIN _TDADept AS C WITH (NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.DeptSeq = A.AptDeptSeq
                   LEFT  JOIN _TDAEmp AS D WITH (NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.EmpSeq = A.SetEmpSeq
                   LEFT  JOIN _TDACurr AS E WITH (NOLOCK) ON E.CompanySeq = A.CompanySeq AND E.CurrSeq = F.CurrSeq
                   LEFT  JOIN _TDADept AS G WITH (NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.DeptSeq = A.RegDeptSeq
                   LEFT  JOIN _TDAEmp AS H WITH (NOLOCK)
                           ON H.CompanySeq  = A.CompanySeq
                          AND H.EmpSeq      = A.RegEmpSeq
             WHERE A.CompanySeq = @CompanySeq
               AND (@AccUnit    = 0  OR A.AccUnit   = @AccUnit)
               AND (@SlipUnit   = 0  OR A.SlipUnit  = @SlipUnit)
--                AND (A.AccDate BETWEEN @AccDateFrom AND @AccDateTo)
--                AND A.AccDate + A.SlipNo >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))  
--                AND A.AccDate + A.SlipNo <= LTRIM(RTRIM(@AccDateTo)) + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'  
               AND (@SlipKind   = 0  OR A.SlipKind  = @SlipKind)
               AND ((@IsSet = '') OR (@IsSet = 1016001 AND A.IsSet IN ('', '0')) OR (@IsSet = 1016002 AND A.IsSet = '1'))
               AND (@RegDeptSeq = 0  OR A.RegDeptSeq = @RegDeptSeq)
               AND (@RegEmpSeq  = 0  OR A.RegEmpSeq = @RegEmpSeq)
               AND (@SMCurrStatus = 0 OR case when A.SMCurrStatus = 0 then 1015001 else A.SMCurrStatus end = @SMCurrStatus)
               AND ((A.IsSet = '1'  AND A.AccDate    BETWEEN @SetAccDateFrom AND RTRIM(@SetAccDateTo) + '99999999' 
                                    AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999' )
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate BETWEEN @AccDateFrom   AND RTRIM(@AccDateTo) + '99999999'))
        
               AND ((A.IsSet = '1'     AND A.AccDate + A.SetSlipNo >= LTRIM(RTRIM(@SetAccDateFrom)) + LTRIM(RTRIM(@SlipSetNoFrom))       
                                       AND A.AccDate + A.SetSlipNo <= LTRIM(RTRIM(@SetAccDateTo))   + LTRIM(RTRIM(@SlipSetNoTo)) + 'zzz'
                                       AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz'
                        OR (ISNULL(A.IsSet, '0') IN ('0', '') AND A.RegAccDate + A.SlipNo    >= LTRIM(RTRIM(@AccDateFrom)) + LTRIM(RTRIM(@SlipNoFrom))       
                                                       AND A.RegAccDate + A.SlipNo    <= LTRIM(RTRIM(@AccDateTo))   + LTRIM(RTRIM(@SlipNoTo)) + 'zzz')))
               AND (@AptEmpSeq  = 0 OR A.AptEmpSeq = @AptEmpSeq)
			   AND (@SetEmpSeq  = 0 OR A.SetEmpSeq = @SetEmpSeq)
             GROUP BY A.CompanySeq, A.SlipMstSeq
             ORDER BY MAX(A.SlipMstID)
        END
    END

    -- 2012.02.09 by bgKeum : 마스터 비고가 없는 경우 첫 번째 행의 비고를 보여주도록 수정
    UPDATE A
       SET Remark     = RTRIM(B.RowNo) + ' : ' + B.Summary
      FROM #temp_TACSlipMaster AS A JOIN _TACSlipRow AS B WITH(NOLOCK) 
                                      ON B.CompanySeq   = @CompanySeq
                                     AND A.SlipMstSeq   = B.SlipMstSeq
                                     AND B.RowNo        = (SELECT MIN(RowNo)
                                                             FROM _TACSlipRow WITH (NOLOCK)
                                                            WHERE CompanySeq    = @CompanySeq
                                                              AND SlipMstSeq    = A.SlipMstSeq)
     WHERE ISNULL(A.Remark, '') = ''

    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    ----------------------------------------------------------------------------------------------------------------------------------
    -- 분개전표 Jump 화면 구분 처리 ----- START
    ----------------------------------------------------------------------------------------------------------------------------------
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    CREATE TABLE #SlipJumpSeq --조회대상이 되는 SlipSeq를 받기 위함
        (
            SlipSeq           INT
        )
    CREATE TABLE #SlipJumpPgmID -- 대상이 되는 전표의 SMAccStd 의 값을 바탕으로 GAAP인지 IFRS인지를 판단 하기 위함
        (
            Seq           INT,
            SlipJumpPgmID NVARCHAR(100)
        )
    INSERT INTO #SlipJumpSeq SELECT DISTINCT SlipMstSeq FROM #temp_TACSlipMaster
    EXEC _SACSlipJumpPgmID @CompanySeq, '1'
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    ----------------------------------------------------------------------------------------------------------------------------------
    -- 분개전표 Jump 화면 구분 처리 ----- END
    ----------------------------------------------------------------------------------------------------------------------------------
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

    --==============================================================================================================
    -- 화면별 항목 삭제
    --==============================================================================================================
    CREATE TABLE #SlipInfo 
	(
        SlipMstSeq      INT,
        SMSetType       INT
	)
    -- 자금승인처리, 전표승인처리 화면의 분리
    -- 1) 자금승인처리 : [계정과목정보]의 "승인구분"에 체크된 계정이 포함된 전표만
    -- 2) 전표승인처리 : [계정과목정보]의 "승인구분"에 체크된 계정이 포함되지 않은 전표만
-- select * from #temp_TACSlipMaster
-- 
    IF ISNULL(@EnvValue,'0') <> '1'
    BEGIN
    -- 전표승인처리(FrmACSlipApproval)는 모든 전표가 조회될 수 있도록 수정  2010.12.20 by bgKeum
--  IF @PgmID IN ('FrmACSlipApprovalCash', 'FrmACSlipApprovalDept_hencom', 'FrmACSlipApprovalAccount')
        IF @PgmID IN ('FrmACSlipApprovalCash', 'FrmACSlipApprovalAccount')
        BEGIN
            INSERT INTO #SlipInfo (SlipMstSeq, SMSetType)
                SELECT a.SlipMstSeq, 0
                  FROM #temp_TACSlipMaster AS a JOIN _TACSlipRow AS row WITH (NOLOCK)
                                                  ON row.CompanySeq     = @CompanySeq
                                                 AND a.SlipMstSeq       = row.SlipMstSeq
            UPDATE #SlipInfo
               SET SMSetType = 4148002
              FROM #SlipInfo AS A 
                    JOIN _TACSlipRow AS row WITH(NOLOCK) ON row.CompanySeq     = @CompanySeq
														AND A.SlipMstSeq       = row.SlipMstSeq 
                 WHERE EXISTS (SELECT 1 FROM _TDAAccount AS acc WITH (NOLOCK)
                                 WHERE acc.CompanySeq   = @CompanySeq
                                   AND row.AccSeq       = acc.AccSeq
                                   AND acc.SMSetType = 4148002)  --재무승인

            UPDATE #SlipInfo
               SET SMSetType = 4148001
              FROM #SlipInfo AS A 
                    JOIN _TACSlipRow AS row WITH(NOLOCK) ON row.CompanySeq     = @CompanySeq
														AND A.SlipMstSeq       = row.SlipMstSeq 
                 WHERE EXISTS (SELECT 1 FROM _TDAAccount AS acc WITH (NOLOCK)
                                 WHERE acc.CompanySeq   = @CompanySeq
                                   AND row.AccSeq       = acc.AccSeq
                                   AND acc.SMSetType = 4148001)  --자금승인

    -- select * From #SlipInfo
    -- select @PgmID
            DELETE #temp_TACSlipMaster 
              FROM #temp_TACSlipMaster AS A
                        JOIN #SlipInfo AS B ON A.SlipMstSeq = B.SlipMstSeq                                      
             WHERE ((@PgmID = 'FrmACSlipApprovalCash' AND B.SMSetType IN (4148002, 0))
                    OR  (@PgmID = 'FrmACSlipApprovalAccount' AND B.SMSetType IN (4148001, 0))
                    OR  (@PgmID = 'FrmACSlipApprovalDept_hencom' AND B.SMSetType IN (4148001, 4148002))  )
        END
    END 
    ELSE
    BEGIN
        IF @PgmID IN ('FrmACSlipApprovalCash', 'FrmACSlipApprovalDept_hencom', 'FrmACSlipApprovalAccount')
        BEGIN
            INSERT INTO #SlipInfo (SlipMstSeq, SMSetType)
                SELECT a.SlipMstSeq, 0
                  FROM #temp_TACSlipMaster AS a JOIN _TACSlipRow AS row WITH (NOLOCK)
                                                  ON row.CompanySeq     = @CompanySeq
                                                 AND a.SlipMstSeq       = row.SlipMstSeq
            UPDATE #SlipInfo
               SET SMSetType = 4148002
              FROM #SlipInfo AS A 
                    JOIN _TACSlipRow AS row WITH(NOLOCK)  ON row.CompanySeq     = @CompanySeq
														 AND A.SlipMstSeq       = row.SlipMstSeq 
                 WHERE EXISTS (SELECT 1 FROM _TDAAccount AS acc WITH (NOLOCK)
                                 WHERE acc.CompanySeq   = @CompanySeq
                                   AND row.AccSeq       = acc.AccSeq
                                   AND acc.SMSetType = 4148002)  --재무승인

            UPDATE #SlipInfo
               SET SMSetType = 4148001
              FROM #SlipInfo AS A 
                    JOIN _TACSlipRow AS row WITH(NOLOCK)  ON row.CompanySeq     = @CompanySeq
														 AND A.SlipMstSeq       = row.SlipMstSeq 
                 WHERE EXISTS (SELECT 1 FROM _TDAAccount AS acc WITH (NOLOCK)
                                 WHERE acc.CompanySeq   = @CompanySeq
                                   AND row.AccSeq       = acc.AccSeq
                                   AND acc.SMSetType = 4148001)  --자금승인

    -- select * From #SlipInfo
    -- select @PgmID
            DELETE #temp_TACSlipMaster 
              FROM #temp_TACSlipMaster AS A
                        JOIN #SlipInfo AS B ON A.SlipMstSeq = B.SlipMstSeq                                      
             WHERE ((@PgmID = 'FrmACSlipApprovalCash' AND B.SMSetType IN (4148002, 0))
                    OR  (@PgmID = 'FrmACSlipApprovalAccount' AND B.SMSetType IN (4148001, 0))
                    OR  (@PgmID = 'FrmACSlipApprovalDept_hencom' AND B.SMSetType IN (4148001, 4148002))  )
        END
    
    END 
--    SELECT A.* , B.SlipJumpPgmID  
--      FROM #temp_TACSlipMaster AS A LEFT OUTER JOIN #SlipJumpPgmID AS B ON A.SlipMstSeq = B.Seq  
    --최종 승인일시를 표시하기 위해 MaxSerl값을 찾는다.
    CREATE TABLE #TACSlipSetData
    (
            SlipMstSeq          INT,
            Serl                INT,
            ApprovalDateTime    DATETIME
    )
    
    INSERT INTO #TACSlipSetData(SlipMstSeq, Serl)
    SELECT A.SlipMstSeq, MAX(Serl)
      FROM #temp_TACSlipMaster AS A JOIN _TACSlipSetData AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
																		  AND A.SlipMstSeq = B.SlipMstSeq
     WHERE A.IsSet = '1'
     GROUP BY A.SlipMstSeq
     
     UPDATE A
        SET A.ApprovalDateTime = B.ApprovalDateTime
       FROM #TACSlipSetData AS A JOIN _TACSlipSetData AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
																	   AND A.SlipMstSeq = B.SlipMstSeq
																	   AND A.Serl       = B.Serl
                                                          
                                                          
----------------------------------------
----공기업요청 원천화면 찾아가서 점프  --by shcho
---------------------------------------- 
	CREATE TABLE #Temp_TACSlipOriPgm
	(
		IDX				INT IDENTITY(1,1),
		SlipMstSeq		INT,
		SlipSeq			INT,
		TableName		VARCHAR(100),
		SlipColumnName	VARCHAR(100),
		ColumnName		VARCHAR(100))
		
	CREATE TABLE #Temp_TACSlipOriPgmResult
	(
		SlipMstSeq INT,
		OriSeq     INT,
		ColumnName NVARCHAR(100)
	)	
	IF @PgmSeq= 12023	-- 공공용 화면에서만 사용하므로 이때만 돌자 FrmPESlipApproval	 전표승인처리(공공)
	BEGIN 
		INSERT INTO #Temp_TACSlipOriPgm(SlipMstSeq, SlipSeq, TableName,  SlipColumnName, ColumnName) 
		SELECT  A.SlipMstSeq, E.SlipSeq, D.TableName, D.SlipColumnName, C.ColumnName
		  FROM #temp_TACSlipMaster AS A
					JOIN _TACSlipKind    AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq 
														  AND A.LinkedPgmID = D.SlipKindNo
					JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
														  AND A.LinkedPgmID = B.SlipKindNo
					JOIN _TACSlipAutoEnvKey AS C WITH(NOLOCK) ON B.Companyseq = C.CompanySeq
															 AND B.SlipAutoEnvSeq = C.SlipAutoEnvSeq
															 AND C.IsUsedQry = '1'
					JOIN _TACSlipRow AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq 
													  AND A.SlipMstSeq = E.SlipMstSeq				                            
		                          
		                    
		DECLARE @IDX			INT,
				@MAXIDX			INT,
				@SlipMstSeq		INT,
				@SlipSeq		INT,
				@TableName		NVARCHAR(100),
				@SlipColumnName	NVARCHAR(100),
				@ColumnName		NVARCHAR(100),
				@SQL			NVARCHAR(MAX)  
		SET @IDX = 1
		SELECT @MAXIDX = MAX(IDX) FROM #Temp_TACSlipOriPgm
		WHILE (@IDX <= @MAXIDX)
		BEGIN
			SELECT	@SlipMstSeq		= SlipMstSeq,
					@SlipSeq		= SlipSeq,
					@TableName		= TableName,
					@SlipColumnName	= SlipColumnName,
					@ColumnName		= ColumnName
			  FROM #Temp_TACSlipOriPgm 
			 WHERE IDX = @IDX

			SELECT @SQL = ''  
			SELECT @SQL =  @SQL  
			+ 'INSERT INTO #Temp_TACSlipOriPgmResult(OriSeq, SlipMstSeq, ColumnName)'   
			+ ' SELECT ' + CASE WHEN @ColumnName = '' THEN '0'   
												ELSE @ColumnName END  +  ', ' +  CONVERT(NVARCHAR(100), @SlipMstSeq) + ',''' + @ColumnName + ''''  
			+ ' FROM ' + @TableName  + ' WITH(NOLOCK) '
			+ ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(100), @CompanySeq)  
			+ '   AND ' + @SlipColumnName + ' = ' + CONVERT(NVARCHAR(100), @SlipSeq)  
			PRINT @SQL  
			EXEC SP_EXECUTESQL @SQL  
			SET @IDX = @IDX + 1
		END
	END
    --DECLARE @SQL NVARCHAR(MAX)  
    --DECLARE DIV_cursor CURSOR  
    --READ_ONLY  
    --FOR SELECT TableName,ColumnName,SlipMstSeq,SlipColumnName,SlipSeq FROM #Temp_TACSlipOriPgm  
    --DECLARE @TableName NVARCHAR(MAX),@ColumnName NVARCHAR(MAX),@SlipMstSeq INT,@SlipColumnName NVARCHAR(MAX),@SlipSeq INT  
    --OPEN DIV_cursor  
    --FETCH NEXT FROM DIV_cursor INTO @TableName,@ColumnName,@SlipMstSeq,@SlipColumnName,@SlipSeq  
    --WHILE (@@fetch_status <> -1)  
    --BEGIN  
    --    IF (@@fetch_status <> -2)  
    --    BEGIN  
    --        SELECT @SQL = ''  
    --        SELECT @SQL =  @SQL  
    --        + 'INSERT INTO #Temp_TACSlipOriPgmResult(OriSeq, SlipMstSeq, ColumnName)'   
    --        + ' SELECT ' + CASE WHEN @ColumnName = '' THEN '0'   
    --                                         ELSE @ColumnName END  +  ', ' +  CONVERT(NVARCHAR(100), @SlipMstSeq) + ',''' + @ColumnName + ''''  
    --        + ' FROM ' + @TableName  
    --        + ' WHERE CompanySeq = ' + CONVERT(NVARCHAR(100), @CompanySeq)  
    --        + '   AND ' + @SlipColumnName + ' = ' + CONVERT(NVARCHAR(100), @SlipSeq)  
    --        PRINT @SQL  
    --        EXEC SP_EXECUTESQL @SQL  
    --    END  
    --FETCH NEXT FROM DIV_cursor INTO @TableName,@ColumnName,@SlipMstSeq,@SlipColumnName,@SlipSeq  
    --END  
    --CLOSE DIV_cursor  
    --DEALLOCATE DIV_cursor  
     
----------------------------------------
----공기업요청 원천화면 찾아가서 점프  --by shcho
---------------------------------------- 
    SELECT A.SlipMstID, A.CheckValue, A.AptRemark, A.AptDate, 
           A.AptDeptName, A.AptEmpName, A.SetEmpName,
           A.DrAmt, A.CrAmt, A.DrForAmt, A.CrForAmt, A.CurrName, A.RegDeptName, A.RegEmpName, A.Remark,
           A.CompanySeq, A.SlipMstSeq, A.SMCurrStatus, A.SMCheckStatus, A.IsSet, A.LinkedPgmID, A.LinkedPgmName,
           ISNULL(C.SetSlipID, '') AS SlipNo, --------------------------------------------------> 11.09 by bgKeum 수정
           A.AccDate, A.BfrAccDate, B.SlipJumpPgmID,
           E.SlipUnitName, F.SlipKindName, C.LastUserSeq, C.LastDateTime, G.UserName AS LastUserName, C.RegDateTime, C.RegAccDate,
           ISNULL(H.PrintCnt, 0) AS PrintCnt,
           I.ApprovalDateTime AS ApprovalDateTime,
           A.AccUnit, A.SlipUnit, A.RegDeptSeq,
           K.MinorSeq  AS GWStatus,                                 -- ywkim 20130122
           K.MinorName AS GWStatusName,                             -- ywkim 20130122
           M.Summary,
           A.LinkedPgmID AS OriPgmId, 
           A.LinkedPgmName AS OriPgmCaption,
           N.OriSeq        AS OriSeq, 
           N.ColumnName    AS OriColumnName
      FROM #temp_TACSlipMaster AS A LEFT OUTER JOIN #SlipJumpPgmID AS B 
                                                 ON A.SlipMstSeq   = B.Seq
                                    LEFT OUTER JOIN _TACSlip AS C WITH(NOLOCK) 
                                                 ON C.CompanySeq = @CompanySeq
                                                AND A.SlipMstSeq = C.SlipMstSeq
            --                      LEFT OUTER JOIN _TACSlipSetNo AS D
            --                                   ON D.CompanySeq    = @CompanySeq
            --                                  AND D.AccUnit       = C.AccUnit
            --                                  AND D.SlipMstSeq    = C.SlipMstSeq
            --                                  AND D.SetSlipNo     = C.SetSlipNo
								    LEFT OUTER JOIN _TACSlipUnit AS E WITH(NOLOCK)       
										         ON C.SlipUnit = E.SlipUnit       
									            AND E.CompanySeq = @CompanySeq      
									LEFT OUTER JOIN _TACSlipKind AS F WITH(NOLOCK)       
										         ON C.SlipKind = F.SlipKind       
									            AND F.CompanySeq = @CompanySeq  
                                    LEFT OUTER JOIN _TCAUser AS G WITH(NOLOCK) 
                                                 ON G.CompanySeq = @CompanySeq
                                                AND G.UserSeq = C.LastUserSeq
                                    LEFT OUTER JOIN _TACSlipPrintCount AS H WITH(NOLOCK) 
                                                 ON H.CompanySeq    = @CompanySeq
                                                AND A.SlipMstSeq    = H.SlipMstSeq
                                    LEFT OUTER JOIN #TACSlipSetData AS I
                                                 ON A.SlipMstSeq    = I.SlipMstSeq
                                    LEFT OUTER JOIN _TACSlip_Confirm AS J WITH(NOLOCK)  -- ywkim 20130122
                                                 ON J.CompanySeq = @CompanySeq
                                                AND C.SlipMstSeq = J.CfmSeq
                                    LEFT OUTER JOIN _TDASMinor AS K WITH (NOLOCK)
                                                 ON K.CompanySeq = @CompanySeq
                                                AND K.MinorSeq = (CASE J.CfmCode WHEN 1 THEN 4163004    -- 전자결재완료
                                                                                 WHEN 5 THEN 4163003    -- 전자결재진행중
                                                                                 WHEN 0 THEN 0 END )
									LEFT OUTER JOIN(SELECT SlipMstSeq, MIN(SlipSeq) AS SlipSeq
									                  FROM _TACSlipRow WITH(NOLOCK) 
									                 WHERE CompanySeq = @CompanySeq
									                 GROUP BY SlipMstSeq) AS L ON A.SlipMstSeq = L.SlipMstSeq
									LEFT OUTER JOIN _TACSlipRow AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq AND L.SlipSeq = M.SlipSeq
									LEFT OUTER JOIN (SELECT SlipMstSeq, MAX(OriSeq) AS OriSeq, MAX(ColumnName) AS ColumnName  
									                   FROM #Temp_TACSlipOriPgmResult 
									                  GROUP BY SlipMstSeq) AS N ON A.SlipMstSeq = N.SlipMstSeq
							                                                                                                
                                                 
     WHERE ((@DataIsSet = '1' AND A.IsSet = '1') OR  (ISNULL(@DataIsSet, '') <> '1' AND A.IsSet IN('', '0', '1', '2'))) 
       AND (@IsDoneGW = '0' OR (@IsDoneGW = '1' AND J.CfmCode = 1)) --결재완료건만 조회
     ORDER BY A.SlipMstID
    
    RETURN
/*******************************************************************************************************************/
