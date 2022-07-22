IF OBJECT_ID('hencom_SSIAFebCollectQuery') IS NOT NULL 
    DROP PROC hencom_SSIAFebCollectQuery 
GO 

-- v2017.04.14 
/*************************************************************************************************
  설  명 - 집금내역반영 (조회)
  작성일 - 2008.7.9
  작성자 - 박진희
  
  사이트용 수정by박수영2016.01.22
  hencom_TDABankAccAdd 테이블 컬럼의 집금내역회계전표표시여부(IsCollectMoneyDis) 체크된 출금계좌만 조회되도록 함.
 *************************************************************************************************/
 CREATE PROCEDURE hencom_SSIAFebCollectQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
      @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
 AS
    DECLARE @docHandle      INT,
            @DateFr         NCHAR(8),
            @DateTo         NCHAR(8),
            @ProcType       NCHAR(8),
            @FeeAccName     NVARCHAR(100),
            @FeeAccSeq      INT,
            @Remark         NVARCHAR(100), 
            @UMBankAccKind  INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    SELECT @DateFr          = ISNULL(DateFr,''),
           @DateTo          = ISNULL(DateTo,''),
           @ProcType        = ISNULL(ProcType,''), 
           @UMBankAccKind   = ISNULL(UMBankAccKind, 0)
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)
       WITH (
                DateFr          NCHAR(8),
                DateTo          NCHAR(8),
                ProcType        NCHAR(8), 
                UMBankAccKind   INT 
            )
      IF @DateFr = ''
         SELECT @DateFr = '20000101'
     
     IF @DateTo = ''
         SELECT @DateTo = '99991231'
         
/* 주석처리by박수영2016.01.22
      SELECT  CompanySeq     , SITE_NO        , SEQ            , REMIT_DAY      , REMIT_TIME     ,
             OUT_BANK       , OUT_ACCTNO     , IN_BANK        , IN_ACCTNO      , REMIT_AMT      ,
             FEE            , REMIT_CURBAL   , REMITSTS       , ERR_CD         , REMITTYPE2     ,
             REMIT_USER_ID  , REMIT_DATETIME , REMIT_CLIENT_NO, BUKRS          , Worksta1       ,
             Worksta2       , Worksta3       , Remark         , ERPKey         , SlipSeq        ,
             LastUserSeq    , LastDateTime   , MST_SEQ
       INTO #TEMP_TSIAFebCollect
       FROM _TSIAFebCollect WITH(NOLOCK)
      WHERE REMIT_DAY BETWEEN @DateFr AND @DateTo
 --        AND (@ProcType   = '' OR (ISNULL(ERPKey, '') <> '' AND @ProcType = '0')  
 --                              OR (ISNULL(ERPKey, '')  = '' AND @ProcType = '1'))  
        AND (@ProcType   = '' OR ((ISNULL(SlipSeq, 0) <> 0 OR ISNULL(ERPKey, '') <> '') AND @ProcType = '0')  
                              OR ((ISNULL(SlipSeq, 0) = 0 AND ISNULL(ERPKey, '') = '') AND @ProcType = '1'))  
        AND CompanySeq = @CompanySeq
*/
--  hencom_TDABankAccAdd 테이블 컬럼의 집금내역회계전표표시여부(IsCollectMoneyDis) 체크된 출금계좌만 조회되도록 함.
      SELECT A.CompanySeq     , A.SITE_NO        , A.SEQ            , A.REMIT_DAY      , A.REMIT_TIME     ,
             A.OUT_BANK       , A.OUT_ACCTNO     , A.IN_BANK        , A.IN_ACCTNO      , A.REMIT_AMT      ,
             A.FEE            , A.REMIT_CURBAL   , A.REMITSTS       , A.ERR_CD         , A.REMITTYPE2     ,
             A.REMIT_USER_ID  , A.REMIT_DATETIME , A.REMIT_CLIENT_NO, A.BUKRS          , A.Worksta1       ,
             A.Worksta2       , A.Worksta3       , A.Remark         , A.ERPKey         , A.SlipSeq        ,
             A.LastUserSeq    , A.LastDateTime   , A.MST_SEQ
       INTO #TEMP_TSIAFebCollect
       FROM _TSIAFebCollect AS A WITH(NOLOCK) 
       JOIN _TDABankAcc   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                           AND A.OUT_ACCTNO = REPLACE(B.BankAccNo, '-', '')
        LEFT OUTER JOIN hencom_TDABankAccAdd AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq 
                                                              AND C.BankAccSeq = B.BankAccSeq
      WHERE A.REMIT_DAY BETWEEN @DateFr AND @DateTo
        AND (@ProcType   = '' OR ((ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '') AND @ProcType = '0')  
                              OR ((ISNULL(A.SlipSeq, 0) = 0 AND ISNULL(A.ERPKey, '') = '') AND @ProcType = '1'))  
        AND A.CompanySeq = @CompanySeq
        AND C.IsCollectMoneyDis = '1' --집금내역회계전표표시여부
        

      -- 수수료계정, 코드
     SELECT @FeeAccName = C.AccName, @FeeAccSeq = B.AccSeq
       FROM _TCOMEnvAcc AS A WITH(NOLOCK)
         JOIN _TCOMEnvAccKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                               AND A.AccKindSeq = B.AccKindSeq
         JOIN _TDAAccount  AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                            AND B.AccSeq     = C.AccSeq
      WHERE  A.CompanySeq = @CompanySeq
         AND A.AccKindSeq = 8906
         
      -- 집금처리 적요    8907
     SELECT @Remark = A.EnvValue
       FROM _TCOMEnv AS A WITH(NOLOCK)
      WHERE  A.CompanySeq = @CompanySeq
         AND A.EnvSeq     = 8907
  
      -- 계좌의 계정 적용시 계좌에 여러개의 계정이 등록된 경우 계정코드가 가장 작은 것으로 적용.
     SELECT DISTINCT B.CompanySeq, B.BankAccSeq AS OUTBankAccSeq, B.BankAccNo AS OUTBankAccNo, B.BankAccName AS OUTBankAccName, B.BankSeq AS OUTBankSeq, B.AccSeq AS OUTAccSeq
       INTO #TEMP_OUT_BANKACC
       FROM #TEMP_TSIAFebCollect AS A
         JOIN _TDABankAcc   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                             AND A.OUT_ACCTNO = REPLACE(B.BankAccNo, '-', '')
         JOIN _TDABankAcc   AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq
                                              AND A.IN_ACCTNO  = REPLACE(B1.BankAccNo, '-', '')
         JOIN (
               SELECT CompanySeq, MIN(AccSeq) AS AccSeq, BankAccNo
                 FROM _TDABankAcc WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq
                GROUP BY CompanySeq, BankAccNo
              ) AS C ON B.CompanySeq = C.CompanySeq
                    AND B.BankAccNo = C.BankAccNo
                    AND B.AccSeq = C.AccSeq
              
      -- 계좌의 계정 적용시 계좌에 여러개의 계정이 등록된 경우 계정코드가 가장 작은 것으로 적용.
     SELECT DISTINCT B1.CompanySeq, B1.BankAccSeq AS INBankAccSeq, B1.BankAccNo AS INBankAccNo, B1.BankAccName AS INBankAccName, B1.BankSeq AS INBankSeq, B1.AccSeq AS INAccSeq
       INTO #TEMP_IN_BANKACC
       FROM #TEMP_TSIAFebCollect AS A
         JOIN _TDABankAcc   AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq
                                              AND A.IN_ACCTNO  = REPLACE(B1.BankAccNo, '-', '')
         JOIN (
               SELECT CompanySeq, MIN(AccSeq) AS AccSeq, BankAccNo
                 FROM _TDABankAcc WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq
                GROUP BY CompanySeq, BankAccNo
              ) AS C ON B1.CompanySeq = C.CompanySeq
                    AND B1.BankAccNo = C.BankAccNo
                    AND B1.AccSeq = C.AccSeq
      -- 서비스 마스타
     SELECT  --CASE ISNULL(A.ERPKey, '') WHEN '' THEN '미처리' ELSE '처리' END AS ProcType,   -- 처리상황
             CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN '처리' ELSE '미처리' END AS ProcType,   -- 처리상황
             A.REMIT_DAY    AS RemitDate ,        -- 집금일
             A.OUT_ACCTNO   AS OutBankAccNo,      -- 출금계좌번호    -- 대변
             B.OUTBankAccName  AS OutBankAccName,    -- 출금계좌관리명
             C.BankName    AS OutBankName,       -- 출금은행
              A.IN_ACCTNO    AS InBankAccNo,       -- 입금계좌번호    -- 차변
             D.INBankAccName         AS InBankAccName,     -- 입금계좌관리번호
             E.BankName    AS InBankName,        -- 입금은행
             A.REMIT_AMT + A.FEE     AS OutAmt,            -- 출금액  -- REMIT_AMT 은 수수료를 제외한 이체금액입니다. (2013.12.03 mypark)
             A.FEE     AS FeeAmt,            -- 수수료
              A.REMIT_AMT    AS InAmt,             -- 입금액
             CASE WHEN ISNULL(A.ERPKey, '') = '' THEN H.SlipID ELSE A.ERPKey END AS ERPKey,            -- 전표번호
             A.Remit_Day + '_' + CONVERT(VARCHAR(19),A.Seq) AS RemitSeq,           -- 집금일련번호
             A.SEQ     AS SEQ,               -- 순번
             A.SITE_NO    AS SITE_NO,           -- 일련번호
             @FeeAccName    AS FeeAccName,        -- 수수료계정
             @FeeAccSeq    AS FeeAccSeq ,        -- 수수료계정코드
             G.AccName    AS DrAccName ,     -- 차변계정    
             F.AccName    AS CrAccName ,     -- 대변계정    
             D.INAccSeq    AS DrAccSeq  ,     -- 차변계정코드
              B.OUTAccSeq    AS CrAccSeq  ,     -- 대변계정코드
             CASE WHEN ISNULL(A.Remark, '') = '' THEN @Remark ELSE A.Remark END AS Remark,            -- 집금처리 비고
             B.OUTBankAccSeq   AS OutBankAccSeq,     -- 출금계좌코드
             C.BankSeq    AS OutBankSeq,        -- 출금은행코드
             D.INBankAccSeq   AS InBankAccSeq,      -- 입금계좌코드
              E.BankSeq    AS InBankSeq,         -- 입금은행코드
             A.SlipSeq    AS SlipSeq  ,         -- 전표번호코드
             A.REMIT_AMT + A.FEE  AS SumRemFeeAmt,      -- 집금액수수료합 (입금금액기준으로 수수료를 + 함 (집금액 + 수수료))
             A.MST_SEQ    AS MST_SEQ,
			 ba.MainAccSeq,
			 (select accname from _TDAAccount where companyseq = @CompanySeq and accseq = ba.MainAccSeq ) as MainAccName, 
             CONVERT(INT,ba.Memo1) AS UMBankAccKind, 
             I.MinorName AS UMBankAccKindName 
       FROM #TEMP_TSIAFebCollect AS A WITH(NOLOCK)
             LEFT OUTER JOIN _TACSlipRow AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq
                                                          AND A.SlipSeq    = H.SlipSeq
             LEFT OUTER JOIN #TEMP_OUT_BANKACC AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                            AND A.OUT_ACCTNO = REPLACE(B.OUTBankAccNo, '-', '')
             LEFT OUTER JOIN #TEMP_IN_BANKACC AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
                                                            AND A.IN_ACCTNO  = REPLACE(D.INBankAccNo, '-', '')
             LEFT OUTER JOIN _TDABank      AS C WITH(NOLOCK) ON C.CompanySeq = B.CompanySeq
                                                            AND C.BankSeq    = B.OUTBankSeq 
             LEFT OUTER JOIN _TDABank      AS E WITH(NOLOCK) ON E.CompanySeq = D.CompanySeq
                                                            AND E.BankSeq    = D.INBankSeq
             LEFT OUTER JOIN _TDAAccount   AS F WITH(NOLOCK) ON B.CompanySeq = F.CompanySeq
                                                            AND B.OUTAccSeq     = F.AccSeq
             LEFT OUTER JOIN _TDAAccount   AS G WITH(NOLOCK) ON D.CompanySeq = G.CompanySeq
                                                            AND D.INAccSeq     = G.AccSeq
			 LEFT OUTER JOIN hencom_TDABankAccAdd AS ba WITH(NOLOCK) ON ba.CompanySeq = @CompanySeq 
                                                                    AND ba.BankAccSeq = B.OUTBankAccSeq
             LEFT OUTER JOIN _TDAUMinor AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = CONVERT(INT,ba.Memo1) ) 
      WHERE ( @UMBankAccKind = 0 OR CONVERT(INT,ba.Memo1) = @UMBankAccKind ) 
      ORDER BY A.REMIT_DAY, A.SEQ
RETURN
