IF OBJECT_ID('mnpt_SHRBasCertificateRptQuery') IS NOT NULL 
    DROP PROC mnpt_SHRBasCertificateRptQuery
GO 

-- v2018.01.05
/*********************************************************************************************
 설    명 - 증명서 출력
 작 성 일 - 
 작 성 자 - 박민아
 수정내역 - 최민석 2011.01.27 거래처 사업자번호, 사업부문, 전화번호, Fax번호 추가
          - 안병국 2011.02.09 발행자 사원의 성명, 부서명, 연락처 추가
          - 안병국 2011.03.11 직책 추가
          - 안병국 2011.04.06 퇴직사유 추가
          - 주소를 출력할 때 재직자/퇴직자를 구분하여 출력(2011.03.24)
          - 재직자의 경우에는 주소/시작종료일을 체크, 퇴직자의 경우에는 체크하지 않는다.
          - 사번추가(2011.11.21)  
          - 주민등록번호별표처리여부를 판단해서 출력
          - 유희선 2016.05.25 [시스템제공코드분류값등록]에서 설정한 직인으로 출력되도록 수정
          - 2016.07.08 (주소 출력 조건 변경)
          - 유희선 0016.07.29 기간 수정
          - 이상화 2017.05.11 퇴직작의 경우 퇴직일 기준 부서명칭 가져오기 위해 수정
**********************************************************************************************/
-- SP파라미터들
CREATE PROCEDURE mnpt_SHRBasCertificateRptQuery
    @xmlDocument NVARCHAR(MAX)    ,    -- 화면의 정보를 XML로 전달
    @xmlFlags    INT = 0          ,    -- 해당 XML의 TYPE
    @ServiceSeq  INT = 0          ,    -- 서비스 번호
    @WorkingTag  NVARCHAR(10) = '',    -- WorkingTag
    @CompanySeq  INT = 1          ,    -- 회사 번호
    @LanguageSeq INT = 1          ,    -- 언어 번호
    @UserSeq     INT = 0          ,    -- 사용자 번호
    @PgmSeq      INT = 0               -- 프로그램 번호
AS
    -- 사용할 변수를 선언한다.
    DECLARE @docHandle    INT          ,    -- XML을 핸들할 변수  
            @EmpSeq       INT          ,    -- 사원(코드)
            @DeptSeq      INT          ,    -- 부서(코드)
            @FrApplyDate  NCHAR(8)     ,    -- 신청일(Fr)
            @ToApplyDate  NCHAR(8)     ,    -- 신청일(To)
            @SMCertiType  INT          ,    -- 증명서구분
            @CertiUseage  NVARCHAR(200),    -- 용도
            @IsAgree      NCHAR(1)     ,    -- 승인여부
            @IsPrt        NCHAR(1)     ,    -- 발행여부
            @CompanyName  NVARCHAR(100),    -- 회사명
            @Owner        NVARCHAR(50) ,    -- 대표자
            @OwnerJpName  NVARCHAR(100),    -- 대표자직책
            @Count        INT          ,    -- 발행매수
            @Counter      INT          ,
            @pEmpSeq      NVARCHAR(MAX),
            @Certi        NVARCHAR(MAX),
            @cEmpSeq      INT          ,
            @cCertiSeq    INT          ,
            @SealPhoto    NVARCHAR(MAX),    -- 직인
            @LenSealPhoto INT		   ,    -- 직인사이즈  
            @TaxNo		  NVARCHAR(30) ,	-- 사업자번호변수
            @TopTelNo	  NVARCHAR(60) ,	-- 대표전화번호변수
            @TopFaxNo	  NVARCHAR(60) ,    -- 대표FAX번호변수
            @WkTrm        NCHAR(8)     ,
            @EntDate      NCHAR(8)     ,
            @IssueDate    NCHAR(8)     ,
            @RetireDate   NCHAR(8)     ,
            @WkYear1      INT          ,    -- 년수(재직)
            @WkMonth1     INT          ,    -- 월수(재직)
            @WkDay1		  INT		   ,	-- 일수(재직)
            @WkYear2      INT          ,    -- 년수(경력)
            @WkMonth2     INT          ,    -- 월수(경력)
            @WkDay2       INT          ,    -- 월수(경력)
            @BaseDate     NCHAR(8)     ,    -- 현재일자
            @SMSealType   INT               -- 3336001:법인직인, 3336002:대표이사직인
            

    -- XML파싱
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument의 XML을 @docHandle로 핸들한다.
    -- XML 데이터를 담을 임시테이블 생성
  	CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)
	EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'    -- XML의 DataBlock1의 데이터를 임시테이블에 담는다.
	IF @@ERROR <> 0
    BEGIN
        RETURN    -- 에러가 발생하면 리턴
    END
    -- #Temp테이블로 부터 값을 읽는다.
    SELECT @SMCertiType = ISNULL(SMCertiType, 0),
           @Count       = COUNT                 ,
           @pEmpSeq     = Emp                   ,
           @Certi       = Certi
      FROM #Temp 

    -- 임시테이블 생성
    CREATE TABLE #TempTemp
    (
         Num      INT IDENTITY (1, 1),
         EmpSeq   INT,
         CertiSeq INT
    )

    -- 기간을 구할 임시테이블
    CREATE TABLE #EmpDate  
    (
         EmpSeq     INT NULL,  
         EntDate    NCHAR(8) NULL,
         IssueDate  NCHAR(8) NULL,
         RetireDate NCHAR(8) NULL
    )

    SELECT @Counter = 1
    WHILE @Counter <= @Count         
    BEGIN
        EXEC _SCAOBGetCols @pEmpSeq OUTPUT, @cEmpSeq OUTPUT
        EXEC _SCAOBGetCols @Certi   OUTPUT, @cCertiSeq OUTPUT
        INSERT #TempTemp(EmpSeq, CertiSeq)
        SELECT @cEmpSeq, @cCertiSeq
        SELECT @Counter = @Counter + 1
    END

    -- 회사명과 대표자명을 가져온다.  
    IF (@SMCertiType = 3067003 OR @SMCertiType = 3067004)       --영문
    BEGIN
        SELECT @CompanyName = CompanyForName, @Owner = OwnerForName, @OwnerJpName = OwnerJpForName
          FROM _TCACompanyForName
         WHERE CompanySeq = @CompanySeq AND LanguageSeq = 2
    END
    ELSE
    BEGIN
        SELECT @CompanyName = CompanyName, @Owner = Owner, @OwnerJpName = OwnerJpName
          FROM _TCACompany
         WHERE CompanySeq = @CompanySeq
    END
    -- 어떤직인을 사용할지 가져온다 3336001:법인직인, 3336002:대표이사직인
    SELECT @SMSealType = CASE WHEN ISNULL(B.ValueText, '0') = '1' THEN 3336001 ELSE 3336002 END
      FROM _TDASMinor AS A
            LEFT OUTER JOIN _TDASMinorValue AS B WITH(NOLOCK) ON B.CompanySeq  = A.CompanySeq
                                                             AND B.MinorSeq    = A.MinorSeq
                                                             AND B.Serl        = 1005 --법인직인출력
     WHERE A.CompanySeq = @CompanySeq
           AND A.MajorSeq = 3067    -- 증명서구분
           AND A.MinorSeq = @SMCertiType
           
          

    -- 기산일 담기
    INSERT INTO #EmpDate (EmpSeq, EntDate, IssueDate, RetireDate)
         SELECT A.EmpSeq, ISNULL(B.EntDate, ''), ISNULL(C.IssueDate, ''), 
                CASE WHEN ISNULL(B.RetireDate, 0) = 0 OR B.RetireDate = '' THEN '99991231' ELSE B.RetireDate END
           FROM #TempTemp AS A JOIN _fnDAEmpDate(@CompanySeq) AS B ON A.EmpSeq = B.EmpSeq
                               JOIN _THRBasCertificate AS C ON C.CompanySeq = @CompanySeq
                                                           AND A.EmpSeq     = C.EmpSeq
                                                           AND A.CertiSeq   = C.CertiSeq
    
    -- 직인을 가져온다
    SELECT @SealPhoto    = ISNULL(SealPhoto, '' ),
           @LenSealPhoto = LEN(SealPhoto)
     FROM _THRBasCompanySeal WITH(NOLOCK)
    WHERE CompanySeq = @CompanySeq
      AND SMSealType = @SMSealType -- 3336001:법인직인, 3336002:대표이사직인

    -- 연월일
    CREATE TABLE #Temp_Term1
    (
         Num      INT IDENTITY (1, 1),
         EmpSeq   INT,
         WkYear1  INT,
         WkMonth1 INT,
         WkDay1	  INT
    )

    -- 기간구하기
    DECLARE CurWorkCalc INSENSITIVE CURSOR FOR
     SELECT EmpSeq, EntDate, IssueDate, RetireDate
       FROM #EmpDate
   --GROUP BY EmpSeq, EntDate, IssueDate, RetireDate -- #EmpDate에 발행매수만큼 가져와서 그룹바이함.
    FOR READ ONLY
    OPEN CurWorkCalc
    WHILE (1 = 1)
    BEGIN
        
        FETCH CurWorkCalc INTO @EmpSeq, @EntDate, @IssueDate, @RetireDate
        IF (@@FETCH_STATUS != 0)
            BREAK
        
        -- 재직년월일 계산
        IF @RetireDate < @IssueDate 
        BEGIN
            EXEC _SCOMWorkCntCalc @EntDate, @RetireDate , @WkTrm OUTPUT
		    INSERT INTO #Temp_Term1
            SELECT @EmpSeq, CONVERT(INT, SUBSTRING(@WkTrm, 1, 2)) AS WkYear1, CONVERT(INT, SUBSTRING(@WkTrm, 3, 2)) AS WkMonth1, CONVERT(INT, SUBSTRING(@WkTrm, 5, 2)) AS WkDay1
        END
        ELSE
        BEGIN
            EXEC _SCOMWorkCntCalc @EntDate, @IssueDate , @WkTrm OUTPUT
		    INSERT INTO #Temp_Term1
            SELECT @EmpSeq, CONVERT(INT, SUBSTRING(@WkTrm, 1, 2)) AS WkYear1, CONVERT(INT, SUBSTRING(@WkTrm, 3, 2)) AS WkMonth1, CONVERT(INT, SUBSTRING(@WkTrm, 5, 2)) AS WkDay1
        END
    END
    CLOSE CurWorkCalc
    DEALLOCATE CurWorkCalc
    -- 시트에 값을 출력하는 부분
    SELECT E.Num,
           A.CertiSeq  AS CertiSeq ,
@SMCertiType AS SMCertiType ,
           ISNULL(B.EmpSeq     ,  0) AS EmpSeq     ,
           ISNULL(GrpInfo.GrpEntDate, '') AS GrpEntDate , --그룹입사일,  
           ISNULL(B.EmpID      , '') AS EmpID      ,    -- 사번(2011.11.21)
           ISNULL(B.EmpName    , '') AS EmpName    ,    -- 사원
           ISNULL(A.ApplyDate  , '') AS ApplyDate  ,    -- 신청일자
           ISNULL(A.CertiCnt   ,  0) AS CertiCnt   ,    -- 발급매수
           ISNULL(A.CertiUseage, '') AS CertiUseage,    -- 용도
           ISNULL(A.CertiSubmit, '') AS CertiSubmit,    -- 제출처
           ISNULL(A.IssueDate  , '') AS IssueDate  ,    -- 발행일
           ISNULL(A.IssueNo    ,  0) AS IssueNo    ,    -- 발행번호
           ISNULL(B.EntDate    , '') AS EntDate    ,    -- 입사일
           CASE WHEN ISNULL(B.RetireDate   , '') = '' THEN ''
                WHEN B.RetireDate < A.IssueDate       THEN B.RetireDate
                ELSE A.IssueDate END AS RetireDate,    -- 퇴사일
           
           case when A.ResidIDMYN = 1 THEN  ISNULL(dbo._fnResidMask(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq)),'')   -- 주민등록번호
                ELSE ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') end AS ResidID    ,   -- 주민번호
           CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(G.ValueText, '') ELSE ISNULL(B.UMJpName, '') END AS UMJpName,    -- 직위
           CASE WHEN ISNULL(C.EmpEngFirstName, '') <> '' AND ISNULL(C.EmpEngLastName, '') <> '' THEN C.EmpEngLastName + ', ' + C.EmpEngFirstName
                ELSE ISNULL(C.EmpEngLastName, '') + ISNULL(C.EmpEngFirstName, '') END AS EmpEngName,    -- 영문사원명(영문성이 없을경우 ,를 쓰지 않는다.)
           ISNULL(A.Task       , '') AS Task       ,                                              -- 담당업무
           --CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(D.EngDeptName, '') ELSE ISNULL(D.DeptName, '') END AS DeptName,    -- (영문)부서명
            CASE WHEN (@SMCertiType = 3067002 OR @SMCertiType = 3067004) -- 경력증명서의 경우
			     THEN  CASE WHEN @SMCertiType = 3067004 THEN ISNULL(DH.EngDeptName, '')  -- 영문
						    ELSE ISNULL(DH.DeptName, '') END  -- 한글
				 ELSE  CASE WHEN @SMCertiType = 3067003 THEN ISNULL(D.EngDeptName, '')  -- 영문 -- 재직증명서
						    ELSE ISNULL(D.DeptName, '') END  END AS DeptName,    -- 한글 -- 부서명
           -- 재직자와 퇴직자를 구분한다.(재직자의 경우에는 주소시작일/종료일을 체크하고 퇴직자의 경우에는 하지 않는다.)
           CASE WHEN B.RetireDate >= A.IssueDate THEN    -- 재직자의 경우
                -- 주소정보(실거주지가 없으면 주민등록상의 거주지로 한다.)
                CASE WHEN ISNULL((SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                              ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                          END
                                    FROM _THRBasAddress
                                   WHERE  A.CompanySeq = CompanySeq
                                     AND  A.EmpSeq = EmpSeq
                                     AND  SMAddressType = 3055002    -- 주민등록상 거주지 주소 -- 2016.07.08 수정
                                     AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                 ), '') = '' THEN (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                                               ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                                           END
                                                     FROM _THRBasAddress
                                                    WHERE  A.CompanySeq = CompanySeq
                                                      AND  A.EmpSeq = EmpSeq
                                                      AND  SMAddressType = 3055003    -- 실거주지 주소 -- 2016.07.08 수정
                                                      AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                                  )
                     ELSE (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                       ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                   END
                             FROM _THRBasAddress
                            WHERE  A.CompanySeq = CompanySeq
                              AND  A.EmpSeq = EmpSeq
                              AND  SMAddressType = 3055002    -- 주민등록상 거주지 주소 -- 2016.07.08 수정
                              AND (A.IssueDate BETWEEN BegDate AND EndDate)
                          )
                 END
                 ELSE    -- 퇴직자의 경우
                 -- 주소정보(실거주지가 없으면 주민등록상의 거주지로 한다.)
                 CASE WHEN ISNULL((SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                               ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                           END
                                     FROM _THRBasAddress
                                    WHERE  A.CompanySeq = CompanySeq
                                      AND  A.EmpSeq = EmpSeq
                                      AND  SMAddressType = 3055002    -- 주민등록상 거주지 주소 -- 2016.07.08 수정
                                      AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                  ), '') = '' THEN (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                                                ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                                            END
                                                      FROM _THRBasAddress
                                                     WHERE  A.CompanySeq = CompanySeq
                                                       AND  A.EmpSeq = EmpSeq
                                                       AND  SMAddressType = 3055003    -- 실거주지 주소 -- 2016.07.08 수정
                                                       AND (A.IssueDate BETWEEN BegDate AND EndDate)
                                                   )
                      ELSE (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                        ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                    END
                              FROM _THRBasAddress
                             WHERE  A.CompanySeq = CompanySeq
                               AND  A.EmpSeq = EmpSeq
                               AND  SMAddressType = 3055002    -- 주민등록상 거주지 주소 -- 2016.07.08 수정
                               AND (A.IssueDate BETWEEN BegDate AND EndDate)
                           )
                 END
            END AS Addr, 
            -- 주소정보(본적)
             (SELECT CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(AddrEng1)) +  ' ' + LTRIM(RTRIM(AddrEng2))    -- 영문증명서일 경우 영문주소
                                        ELSE LTRIM(RTRIM(Addr1)) +  ' ' + LTRIM(RTRIM(Addr2))    -- 아니면 한글주소
                                    END
                              FROM _THRBasAddress
                             WHERE  A.CompanySeq = CompanySeq
                               AND  A.EmpSeq = EmpSeq
                               AND  SMAddressType = 3055001    -- 본적
                               AND (A.IssueDate BETWEEN BegDate AND EndDate)
                           ) AS Addr2, 
            T1.WkYear1 AS TermYy , 
            T1.WkMonth1 AS TermMm , 
            T1.WkDay1 AS TermDay,
           F.TaxName AS CompanyName, 
           F.Owner AS Owner, 
           @OwnerJpName AS OwnerJpName,    -- 회사명, 대표자, 대표직책  
           F.TaxEngName, 
           CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004 ) THEN LTRIM(RTRIM(F.AddrEng1)) +  ' ' + LTRIM(RTRIM(F.AddrEng2)) +  ' ' + LTRIM(RTRIM(F.AddrEng3))
                       ELSE F.Addr1+F.Addr2 END  AS CompanyAddr  ,                   -- 회사주소


           @SealPhoto      AS SealPhoto ,      @LenSealPhoto    AS LenSealPhoto,     -- 대표이사직인  
           
           B.UMJdName	       AS UMJdName     ,       -- 직책             20110311 추가
           B.UMPgName		            AS UMPgName		,		-- 직급				20110127 추가
           ISNULL(I.BizUnitName, '')	AS BizUnitName	,		-- 사업부문			20110127 추가
           ISNULL(F.TaxNo, '')			AS TaxNo		,		-- 사업자번호		20110127 추가				
           ISNULL(F.TelNo, '')   		AS TopTelNo		,		-- 회사 대표번호	20110127 추가
           ISNULL(F.FaxNo, '')	    	AS TopFaxNo		,		-- 회사 FAX번호		20110127 추가
          ISNULL(J.EmpName    , '')   AS IssueEmpName,        -- 발행자사원명 (2011.02.09 추가)
          CASE WHEN ISNULL(K.EmpEngFirstName, '') <> '' AND ISNULL(K.EmpEngLastName, '') <> '' THEN K.EmpEngFirstName + ',' + K.EmpEngLastName
               ELSE ISNULL(K.EmpEngFirstName, '') + ISNULL(K.EmpEngLastName, '') END AS IssueEmpEngName,    -- 발행자 영문사원명 (2011.02.09 추가)
          CASE WHEN (@SMCertiType = 3067003 OR @SMCertiType = 3067004) THEN ISNULL(L.EngDeptName, '') ELSE ISNULL(L.DeptName, '') END AS IssueEmpDeptName,    -- 발행자 (영문)부서명 (2011.02.09 추가)
          ISNULL(M.Phone      , '')   AS IssueEmpPhone,       -- 발행자사원의 전화번호  (2011.02.09 추가)
          ISNULL(M.Extension  , '')   AS IssueEmpExtension,   -- 발행자사원의 사내번호  (2011.02.09 추가)
          ISNULL(O.MinorName  , '')   AS UMRetReasonName ,    -- 퇴직사유 (2011.04.06 추가)
          ISNULL(dbo._FCOMDecrypt(C.ResidID, '_TDAEmp', 'ResidID', @CompanySeq), '') AS Pwd,
          ISNULL(B.SMSexName  , '')   AS SMSexName,           -- 성별     (2016.05.18 추가)
          ISNULL(B.BirthDate  , '')   AS BirthDate            -- 생년월일 (2016.05.18 추가)
     FROM #TempTemp AS E JOIN _THRBasCertificate AS A WITH(NOLOCK) ON A.EmpSeq   = E.EmpSeq
                                                                   AND A.CertiSeq = E.CertiSeq
                          -- 사원정보(사번, 부서 등)를 가져오기 위한 조인
                          JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B   ON A.CompanySeq = @CompanySeq
                                                                   AND E.EmpSeq     = B.EmpSeq
                          -- 영문사원명과 주민번호를 가져오기 위한 조인
                          JOIN _TDAEmp                       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                                              AND E.EmpSeq     = C.EmpSeq
                          -- 영문부서명을 가져오기 위한 조인  
                          JOIN _TDADept                      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                              AND B.DeptSeq    = D.DeptSeq
						  -- 퇴직작의 경우 퇴직일 기준 부서명칭 가져오기 위해
                          LEFT OUTER JOIN _TDADeptHist		 AS DH WITH(NOLOCK) ON A.CompanySeq =DH.CompanySeq
																			   AND B.DeptSeq   = DH.DeptSeq
																			   AND B.RetireDate BETWEEN DH.BegDate AND DH.EndDate 
                          LEFT OUTER JOIN _TDABizUnit		 AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq 
															     			   AND D.BizUnit	= I.BizUnit  
  
                          LEFT OUTER JOIN _TDATaxUnit        AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                                              AND D.TaxUnit    = F.TaxUnit  
                          LEFT OUTER JOIN _TDAUMinorValue    AS G WITH(NOLOCK) ON A.CompanySeq = G.companySeq  
                                                                              AND G.MinorSeq   = B.UMJpSeq  
                                                                              AND G.MajorSeq   = 3052  
                                                                              AND G.Serl       = 1001
                          LEFT OUTER JOIN _fnDAEmpDate(@CompanySeq) AS GrpInfo ON A.EmpSeq = GrpInfo.EmpSeq                                                                              
                          -- 발행자 사원정보(성명, 부서 등)를 가져오기 위한 조인 (2011.02.09 추가)
                          LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS J   ON A.CompanySeq   = @CompanySeq
                                                                               AND A.IssueEmpSeq = J.EmpSeq
                          -- 발행자 사원 영문사원명을 가져오기 위한 조인 (2011.02.09 추가)
                          LEFT OUTER JOIN _TDAEmp                       AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq
                                                                                          AND A.IssueEmpSeq = K.EmpSeq
                          -- 발행자 사원 영문부서명을 가져오기 위한 조인 (2011.02.09 추가)
                          LEFT OUTER JOIN _TDADept                      AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq  
                                                                                          AND J.DeptSeq   = L.DeptSeq 
                          -- 발행자 사원 연락처를 가져오기 위한 조인 (2011.02.09 추가)                                            
                          LEFT OUTER JOIN _TDAEmpIn                     AS M WITH(NOLOCK) ON A.CompanySeq   = M.CompanySeq
                                                                                          AND A.IssueEmpSeq = M.EmpSeq
                          -- 퇴직사유 (2011.04.06 추가)
                          LEFT OUTER JOIN _THRAdmEmpRetReason           AS N WITH(NOLOCK) ON A.CompanySeq   = N.CompanySeq
                                                                                          AND A.EmpSeq      = N.EmpSeq      
                          LEFT OUTER JOIN _TDAUMinor                    AS O WITH(NOLOCK) ON N.CompanySeq      = O.CompanySeq
                                                                                          AND N.UMRetReasonSeq = O.MinorSeq  
                          LEFT OUTER JOIN #Temp_Term1					AS T1 WITH(NOLOCK) ON A.EmpSeq = T1.EmpSeq AND E.Num = T1.Num                                                                                                                                                                                                                     
     WHERE A.CompanySeq = @CompanySeq
  ORDER BY E.Num

     --   FROM _TDABizUnit AS A 
     --   LEFT OUTER JOIN _TTAXBizTaxUnit AS B 
     --                ON A.CompanySeq    = B.CompanySeq
     --               AND A.BizUnit       = B.BizUnit
     --   LEFT OUTER JOIN _TDATaxUnit     AS C 
     --                ON A.CompanySeq    = C.CompanySeq
     --               AND B.TaxUnit       = C.TaxUnit
     --WHERE A.CompanySeq = @CompanySeq           


RETURN
go
begin tran 
exec mnpt_SHRBasCertificateRptQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ApplyDate>20171219</ApplyDate>
    <ResidIDMYN>0</ResidIDMYN>
    <SMCertiType>3067002</SMCertiType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <Emp>53_/</Emp>
    <Certi>2_/</Certi>
    <Count>1</Count>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820108,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1819
rollback 

--select * from _TDABizUnit 

--select * From sysobjects where name like '_T%BizUnit%'