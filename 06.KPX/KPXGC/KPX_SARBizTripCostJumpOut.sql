

IF OBJECT_ID('KPX_SARBizTripCostJumpOut') IS NOT NULL 
    DROP PROC KPX_SARBizTripCostJumpOut
GO 

-- v2015.01.08 

-- 법인카드사용내역회계전표생성 -> 출장비지출품의서 점프아웃 by 이재천
 CREATE PROC KPX_SARBizTripCostJumpOut  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    
    CREATE TABLE #TSIAFebCardCfm (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSIAFebCardCfm'   
    IF @@ERROR <> 0 RETURN    
    
    
    
    DECLARE @JuridCardAcc       NVARCHAR(100),  
            @IndivCardAcc       NVARCHAR(100),  
            @CardAddAcc         NVARCHAR(100),   
            @JuridCardAccSeq    INT,  
            @IndivCardAccSeq    INT,  
            @CardAddAccSeq      INT,  
            @pEmpSeq            INT,  
            @ISAppr             NCHAR(1),
            @PgmID              NVARCHAR(100),
            @IsEmpQry           NCHAR(1),
            @IniEmpQry          INT,                --초기 넘어오는 값으로 화면상에 사용자가 입력할 수 있는 값
            @EnvValue8927       DECIMAL(19,5),      --해당 금액 이하는 최초 조회시 부가세체크를 해제 한다.
            @EnvValue8929       INT                -- 해당 체크가 해제되면 활동센터가 공란으로 조회된다. 
    
 
    SELECT @EnvValue8927 = 0
    SELECT @EnvValue8927 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8927   -- <법인카드>      K-Branch SI_법인카드사용내역회계전표생성 부가세체크 해제 설정금액
    SELECT @EnvValue8929 = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8929   -- <법인카드>      K-Branch 법인카드사용내역 활동센터디폴트여부   SELECT * FROM _TCOMEnv WHERE EnvSeq = 8918
    SELECT @ISAppr       = EnvValue FROM _TCOMEnv where CompanySeq = @CompanySeq AND EnvSeq = 8923   -- <외화금액>      K-Branch 외화금액 매입일자 기준으로 조회 여부
    
    
    ---- 확정여부 : 확정프로세스 미사용 또는 슈퍼유저인 경우 ''
    --IF @IsDefine IS NULL  
    --BEGIN  
    --    SELECT @IsDefine = CASE EnvValue WHEN '0' THEN '' ELSE '0' END  FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8918  -- <법인카드>      K-Branch법인카드확정프로세스사용여부
    --    IF EXISTS (SELECT 1 FROM _TCOMEnvSlipSuper WHERE CompanySeq = @CompanySeq AND EmpSeq = @EmpSeq)  
    --    BEGIN  
    --        SELECT @IsDefine = ''  
    --    END  
    --END 
    
    --■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    --------------------------------------------------------------------------------------------------------------------
    -- 2011.07.05 법인카드사용내역회계전표생성(개인)화면에서 넘어오는 QryEmpSeq 수정
    -- @QryEmpSeq가 (개인)화면에서 넘어오는 경우에는 법인카드테이블에 담당자가 저장된 상태에서는 조회되어도,
    -- 조회시 자동으로 보여지는 사원의 조건으로는 걸리질 않는다.
    -- 때문에, @QryEmpSeq가 Parameter로 넘어오는 경우 @QryEmpSeq는 0으로 만들어 조건에 걸리지 않도록 수정하고,
    -- @EmpSeq를 @QryEmpSeq로 넣어주고 기본 로직을 탈 수 있도록 수정한다.
    -- 단, 개인화면이 아닌곳에서 사용자를 변경하는 경우라면, QryEmpSeq ==> EmpSeq로 바꿔주면 안됨
    --------------------------------------------------------------------------------------------------------------------
    --■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
    
  --  SELECT @PgmID = PgmID FROM _TCAPgm WHERE PgmSeq = @PgmSeq
    
  --  SELECT @IsEmpQry = '0'
    
  --  SELECT @IniEmpQry = @QryEmpSeq
  --   -- (개인)용 화면에서는 @QryEmpSeq가 무조건 넘어온다..
  --  IF @QryEmpSeq <> 0 AND @PgmID = 'FrmSIAFebCardCfm_Per'
  --  BEGIN
  --      SELECT @EmpSeq = @QryEmpSeq
  --      SELECT @QryEmpSeq = 0
  --      SELECT @IniEmpQry = 0               --개인용 화면에서는 불필요
  --  END
  --  -- 일반 화면에서는 @QryEmpSeq를 직접 넣을 수 있는데, 아래쪽에서 SuperUser인 경우는 다시 @Empseq = 0으로 바꿔주고 있음.
  --  ELSE
  --  BEGIN
  --      --SELECT @EmpSeq = @EmpSeq
  --       IF @QryEmpSeq <> 0   
  --      --    SELECT @QryEmpSeq = @EmpSeq
  --      --ELSE
  --      -- @QryEmpSeq 가 0이 아니라는 이야기는 변수가 입력이 되었다는 이야기로, 이럴경우, superuser라도 @QryEmpSeq를 0으로 바꾸지 않도록 한다.                
  --      BEGIN
  --          SELECT @QryEmpSeq = @QryEmpSeq
  --          SELECT @IsEmpQry = '1'
  --      END
  --  END
 
  --  -- FBS카드사용자등록되있는정보 담는 Table  
  --  CREATE TABLE #TFBSCardUser  
  --  (  
  --      CardSeq INT,  
  --      EmpSeq  INT  
  --  )  
  --   -- 슈퍼유저여부  
  --  IF EXISTS (SELECT 1 FROM _TCOMEnvSlipSuper WHERE CompanySeq = @CompanySeq AND EmpSeq = @EmpSeq) -- 로그인사용자가  SuperUser일경우 EmpSeq = 0   
  --  BEGIN 
  --IF @PgmID <> 'FrmSIAFebCardCfm_Per' 
  --BEGIN
  -- SELECT @EmpSeq = 0  
  --END
        
  --      --수퍼유저이면서 개인화면이 아니면 @QryEmpSeq = 0 으로 한다.
  --      IF @PgmID <> 'FrmSIAFebCardCfm_Per' AND @IsEmpQry <> '1'
  --      BEGIN
  --          SELECT @QryEmpSeq = 0
  --      END
  --  END  
  
    --IF EXISTS (SELECT 1 FROM _TSIAFebCardUserInfo WHERE EmpSeq = @EmpSeq) -- 로그인사용자가  SuperUser일경우 EmpSeq = 0   
    --BEGIN  
    -- INSERT INTO #TFBSCardUser  
    -- SELECT A.CardSeq,  
    --        CASE WHEN @EmpSeq = 0 THEN 0  
    --             ELSE ISNULL(C.EmpSeq,0) END AS EmpSeq  
    --   FROM _TDACard AS A   
    --        JOIN _TSIAFebCardUserInfo AS C ON A.CompanySeq = C.CompanySeq AND A.CardSeq = C.CardSeq  
    --  WHERE A.CompanySeq = @CompanySeq  
    --    AND (@EmpSeq = 0 OR C.EmpSeq = @EmpSeq)  
    --    AND (@CardSeq = 0 OR A.CardSeq = @CardSeq)  
  
    --    SELECT @IsDefine = ''  
  
    --END  
  
    
    
    -- 법인카드상대계정, 코드  
    SELECT @JuridCardAcc = C.AccName, @JuridCardAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8901  
  
  
    -- 개인카드상대계정, 코드  
    SELECT @IndivCardAcc = C.AccName, @IndivCardAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8902  
  
  
    -- 카드부가세계정, 코드  
    SELECT @CardAddAcc = C.AccName, @CardAddAccSeq = B.AccSeq  
      FROM _TCOMEnvAcc AS A  
        JOIN _TCOMEnvAccKind AS B ON A.CompanySeq = B.CompanySeq  
                                 AND A.AccKindSeq = B.AccKindSeq  
        JOIN _TDAAccount  AS C ON B.CompanySeq = C.CompanySeq  
                              AND B.AccSeq     = C.AccSeq  
     WHERE  A.CompanySeq = @CompanySeq  
        AND A.AccKindSeq = 8903  
    
    --select * from #TSIAFebCardCfm 
    --return 
    -- 거래처정보  
    SELECT REPLACE(B.BizNo, '-', '') AS BizNo, Min(B.CustSeq) AS CustSeq  
      into #TCustInfo  
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                )  
                 JOIN _TDACust AS B ON A.CompanySeq = B.CompanySeq  
                                      AND REPLACE(A.CHAIN_ID, '-', '') = REPLACE(B.BizNo, '-', '')
                                      AND A.CHAIN_ID <> ''  
      GROUP BY REPLACE(B.BizNo, '-', '')
    
    --return 
    -- 카드사용자  
     SELECT A.CardSeq,  
            ISNULL(B.EmpSeq,A.EmpSeq) AS EmpSeq,  
            CASE WHEN ISNULL(B.DistribDate,'') = '' THEN A.IssueDate ELSE B.DistribDate END AS StartDate,   
            CASE WHEN ISNULL(B.ReturnDate,'') = '' THEN (  
                                                         CASE WHEN ISNULL(A.ExpireYm,'') = '' THEN '99991231' ELSE A.ExpireYm END  
                                                        )  
                 ELSE B.ReturnDate END AS EndDate  
       INTO #TCardUser  
       FROM _TDACard AS A   
            LEFT OUTER JOIN _TDACardUser AS B ON A.CompanySeq = B.CompanySeq AND A.CardSeq = B.CardSeq  
      WHERE A.CompanySeq = @CompanySeq  
        --AND (@EmpSeq = 0 OR (A.EmpSeq = @EmpSeq OR B.EmpSeq = @EmpSeq))  
        --AND (@CardSeq = 0 OR A.CardSeq = @CardSeq)  
    -- 서비스 마스타  
    -- A.Chain_Type = 2 일때 (간이과세) 는 승인금액이 곧 공급가액, 합계금액이고 부가세여부/불공제여부 체크하지 않는다.
     /*
     --=============================================================================================================================
    -- 조회 전 관리항목(RemSeq)가 없는경우 Update한다. (조건 : 승인기간에해당하는 것만.)
    --=============================================================================================================================
    --UPDATE _TSIAFebCardCfm
    --   SET RemSeq = D.RemSeq
    --  FROM _TSIAFebCardCfm AS A
    --  JOIN _TDAAccountSub  AS B ON A.AccSeq = B.AccSeq AND A.CompanySeq = B.CompanySeq
    --  JOIN _TDAAccountRem  AS C ON B.RemSeq = C.RemSeq AND A.CompanySeq = C.CompanySeq
    --  LEFT OUTER JOIN (
    --        SELECT A.AccSeq, A.RemSeq, MIN(A.Sort) AS SortNum
    --          FROM _TDAAccountSub AS A WITH (NOLOCK)  
    --               LEFT JOIN _TDAAccountRem AS B WITH (NOLOCK)  
    --                      ON B.CompanySeq   = A.CompanySeq  
    --                     AND B.RemSeq       = A.RemSeq  
    --         WHERE A.CompanySeq = @CompanySeq 
    --           AND B.SMInputType = 4016002  -- 고정 codehelp
    --           AND B.CodeHelpSeq = 40031
    --         GROUP BY A.AccSeq, A.RemSeq, A.Sort
    --        ) AS D ON A.AccSeq = D.AccSeq AND B.Sort = D.SortNum
    -- WHERE A.CompanySeq = @CompanySeq 
    --   AND ISNULL(A.AccSeq, 0) <> 0 
    --   AND ISNULL(A.RemSeq, 0) = 0
    --   AND C.SMInputType = 4016002  -- 고정 codehelp
    --   AND C.CodeHelpSeq = 40031
    --   AND (A.APPR_DATE >= @DateFr  OR @DateFr = '')  
    --   AND (A.APPR_DATE <= @DateTo  OR @DateTo = '') 
    --=============================================================================================================================
    */
    
    --IF @DateFr = '' SELECT @DateFr = '19000101'
    --IF @DateTo = '' SELECT @DateTo = '99991231'
    --SELECT DISTINCT APPR_NO
    --  INTO #CancelSource
    --  FROM _TSIAFebCardCfm 
    -- WHERE CompanySeq = @CompanySeq
    --   AND CANCEL_YN = 'Y'
    --   AND APPR_DATE BETWEEN @DateFr AND @DateTo
    
     -- _TDACard 테이블의 CardNo가 암호화 필드로 설정된 경우에는 where절에서 복호화 조건이 걸리게 되면 index를 타지 못하여 임시테이블에 담아서 조회하도록 수정
    SELECT CompanySeq, BizUnit, CardSeq, dbo._FCOMDecrypt(CardNo, '_TDACard', 'CardNo', @CompanySeq) AS CardNo, CardName,  
           SMComOrPriv, UMCardKind, EmpSeq, IssueDate, ExpireYm,  
           SttlDay, SttlLimitDay, SttlAccNo, CardStatus, StopDate,  
           Remark, LastUserSeq, LastDateTime, SttlBankSeq, SttlOwner,  
           ManageDeptSeq, RemarkNum  
      INTO #TDACardTemp
      FROM _TDACard  
    
    
    SELECT CompanySeq, BizUnit, CardSeq, LEFT(REPLACE(CardNo, '-', ''),16) AS CardNo, CardName,  
           SMComOrPriv, UMCardKind, EmpSeq, IssueDate, ExpireYm,  
           SttlDay, SttlLimitDay, SttlAccNo, CardStatus, StopDate,  
           Remark, LastUserSeq, LastDateTime, SttlBankSeq, SttlOwner,  
           ManageDeptSeq, RemarkNum  
      INTO #TDACard
      FROM #TDACardTemp  
    
    ALTER TABLE #TDACard ADD CONSTRAINT TPK_TDACard PRIMARY KEY CLUSTERED (CompanySeq, BizUnit, CardSeq) 
    CREATE UNIQUE INDEX IDXTemp_TDACard ON #TDACard(CompanySeq, BizUnit, CardSeq)
    
    DROP TABLE #TDACardTemp
    
    --select * from #TSIAFebCardCfm 
    
    --return 
    
    SELECT  CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN '처리' ELSE '미처리' END AS ProcType,   -- 처리상황  
            --dbo._FCOMDecrypt(B.CardNo, '_TDACard', 'CardNo', @CompanySeq)                AS CARD_CD,              -- 카드번호  
            B.CardNo                 AS CardNo,             -- 카드번호
            B.CardName               AS CardName,            -- 카드명
            A.APPR_DATE              AS ApprDate,            -- 승인일자  
            A.APPR_NO                AS ApprNo,              -- 승인번호  
            A.CHAIN_NM               AS ChainName,           -- 가맹점명  
            A.CHAIN_ID               AS ChainBizNo,          -- 가맹점 사업자번호  
            ISNULL(CT.MinorName, '미확인')            AS ChainType,
   ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                              WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprAmt,             -- 승인금액  
            ISNULL(ABS(A.APPR_TAX),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprTax,             -- 승인금액부가가치세  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)            
                 WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
        WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- 공급가액이(+)로 은행에서 넘어온 경우
                 WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) 
                 ELSE A.SupplyAmt  
            END  AS SupplyAmt,           -- 공급가액  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
          WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- 공급가액이(+)로 은행에서 넘어온 경우 
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))    
                      ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                               WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,ABS(ISNULL(A.APPR_AMT, 0) - ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                  WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                 END - ISNULL(A.DisSupplyAmt,0) - ISNULL(A.Tip_Amt,0)   
            ELSE 0 END   AS UpdateVat ,          -- 수정부가세  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)                 
                ELSE
                CASE WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
            WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- 공급가액이(+)로 은행에서 넘어온 경우 
                     WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                     ELSE A.SupplyAmt  
                END  +         -- 공급가액  
                CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                     CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
              WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- 공급가액이(+)로 은행에서 넘어온 경우   
                          WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                          ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                   WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,(ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                     END    
                ELSE 0 END
            END AS TotalAmt ,          -- 합계금액  
             A.AccSeq                 AS AccSeq,              -- 계정코드  
            A.AccSeq                 AS AccSeqOld,           -- 계정코드   
            A.HALBU                  AS HALBU,               -- 할부기간  
            A.RemSeq                 AS RemSeq,              -- 관리항목
            AR.RemName               AS RemName,             -- 관리항목명
            CASE WHEN ARV1.RemValueName IS NULL THEN ARV2.RemValueName 
                 ELSE ARV1.RemValueName
            END                      AS RemValue,            -- 관리항목값
            A.RemValueSeq            AS RemValueSeq,         -- 관리항목값코드
            A.CANCEL_YN              AS CANCEL_YN,           -- 승인취소여부 키  
            CASE A.CANCEL_YN WHEN '3' THEN (CASE WHEN A.BUYING_DIST IN ('02', '04') THEN '취소'
                                                 WHEN A.BUYING_DIST = '06' THEN '환급' END)     --외환은행 추가
                             WHEN 'Y' THEN '취소'  
                             ELSE '승인'  
            END                      AS CancelYN,  -- 승인취소여부  
            E.AccName                AS AccName,             -- 발생계정  
            A.Remark                 AS Remark,              -- 비고1  
            C.EmpName                AS EmpName,             -- 사원  
     CASE WHEN ISNULL(D.CustName,'') = '' THEN D2.CustName ELSE D.CustName END AS CustName,      -- 거래처  
            CASE WHEN ISNULL(A.CustSeq, 0) = 0   THEN D1.CustSeq  ELSE A.CustSeq  END AS CustSeq,       -- 거래처코드  
            CASE WHEN ISNULL(A.ERPKey,'') = ''   THEN H.SlipID    ELSE A.ERPKey   END AS ERPKey,    -- 전표번호  
            A.SlipSeq               AS SlipSeq  ,                                   -- 발생전표코드  
            C.EmpSeq                AS EmpSeq     ,        -- 사번  
            A.APPR_SEQ              AS APPR_SEQ,            -- 승인순번  
            B.CardSeq               AS CardSeq,             -- 카드코드  
            G.CCtrName              AS CCtrName,            -- 활동센터명
            G.CCtrSeq               AS CCtrSeq,             -- 활동센터코드
            F.DeptName              AS DeptName,            -- 부서명
            F.Deptseq               AS DeptSeq,             -- 부서코드
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAcc  
                WHEN 4019002 THEN @IndivCardAcc  
            END         AS CrAccName, --' 상대계정 -미지급금(카드)' AS OutAccNm,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAccSeq  
                WHEN 4019002 THEN @IndivCardAccSeq  
            END         AS CrAccSeq,     -- 상대계정코드  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'            
                 WHEN ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)) THEN '1' ELSE A.VatSel END AS VatSel, -- 부가세여부  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'             
                 WHEN A.VatYN = 'Y' THEN '1'  
                 WHEN A.VatYN = 'N' THEN '0'  
            END AS VATYN,        --부가세환급대상여부   
            CASE WHEN A.Chain_Type IN (2,3) THEN ''
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAcc 
                 WHEN A.IsNonVat = '1' THEN @CardAddAcc 
      ELSE '' END AS VatSttlItem, -- 부가세계정  ,
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAccSeq ELSE '' END AS AddTaxAccSeq, -- 부가세계정코드  
            A.IsDefine,  
            A.EvidSeq,  
            Q.EvidName,  
            CASE WHEN ISNULL(A.ModDate,'') = '' THEN A.APPR_DATE ELSE A.ModDate END AS ModDate,  
            A.EvidSeq AS EvidSeq2,  
            Q.EvidName AS EvidName2,  
            A.MASTER,  
            ISNULL((CASE WHEN CHARINDEX('-',A.MERCHZIPCODE) <> 0 THEN A.MERCHZIPCODE ELSE LEFT(A.MERCHZIPCODE,3) + '-' + RIGHT(A.MERCHZIPCODE,3) END ),'')   AS MERCHZIPCODE,  
            A.MERCHADDR1,  
            A.MERCHADDR2,  
             A.APPRTOT * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS APPRTOT,  
            A.MCCNAME,  
            A.MCCCODE,  
            A.TAXTYPE,  
            A.MERCHCESSDATE,  
            @CardAddAcc  AS AddTaxAccNameOld, -- 부가세계정Old  
            @CardAddAccSeq AS AddTaxAccSeqOld,-- 부가세계정코드Old  
            B.UMCardKind AS UMCardKind,  
            B1.ValueSeq AS CardCustSeq,  
            B2.CustName AS CardCustName,   
   R.MinorName AS UMCardKindName,  
            A.PURDATE,  -- 매입일자 (안철수연구소에서는 승인일자로 쓰임)  
            A.TIP_AMT,  -- 팁  
         T.MinorSeq AS UMCostType,  
            T.MinorName AS UMCostTypeName,  
            CASE WHEN ISNULL(A.TaxUnit,0) = 0 THEN S.TaxUnit ELSE A.TaxUnit END AS TaxUnit,  
            CASE WHEN ISNULL(A.EmpSeq,0) = 0 THEN 0 ELSE 1 END IsEmpSave,  
            CASE WHEN A.CustSeq IS NULL THEN 0 ELSE 1 END IsCustSave,  
            --불공제관련추가 3개 항목  
            CASE WHEN A.Chain_Type IN (2,3) AND A.CostAmtDr IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                             WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)        
                 WHEN ISNULL(A.CostAmtDr,0) = 0 THEN 
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                            WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
           WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1)    -- 공급가액이(+)로 은행에서 넘어온 경우 
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1) 
                      ELSE A.SupplyAmt + ISNULL(A.Tip_Amt,0)  END -- CostAmtDr 금액이 없으면 공급가액을 가져오는 것과 동일하게 가져옴.  
            ELSE A.CostAmtDr END AS CostAmtDr,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0                  
            ELSE ISNULL(A.NotVatAmt,0) END AS NotVatAmt,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN '' 
                 WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''              
            ELSE ISNULL(A.NotVatSel,'') END AS NotVatSel,
            ISNULL(A.APPR_TIME,'') AS APPR_TIME,
            ISNULL(A.CURAMT ,0)  * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS CURAMT  ,
            --ISNULL(A.STTL_DATE,'')         AS STTL_DATE,
            CASE WHEN ISNULL(A.STTL_DATE,'') <> '' 
                    THEN ISNULL(A.STTL_DATE,'')
                 WHEN ISNULL(A.STTL_DATE,'') = '' 
                    THEN 
                        CASE WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') = '' AND ISNULL(B.SttlDay,'') <> '' 
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay)
                                            ELSE LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --결제일이 결제한도일보다 이후인경우
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) >= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --결제한도일 이전 승인인경우 해당년월+결제일
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제한도일이 지났고, 결제일 이전인 경우 해당년월+1월의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                AND CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제일 이후에 승인된 경우 해당년월+2월의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --결제일이 결제한도일보다 이전인 경우(즉 다음달 결제)
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) < CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --결제한도일이 이전인 경우 해당년월+1의 결제일
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제한도일이 이후인 경우 해당년월+2의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                         END   
            END  
            AS STTL_DATE,            
            CASE WHEN ISNULL(A.CHAIN_TYPE, '0') IN('0', '', '1', '4', '99') THEN '0'
                 ELSE '1'
            END                             AS IsDisVatYN ,
            ISNULL(AR.CodeHelpSeq   , 0)    AS MCodeHelpSeq    ,
            ISNULL(AR.CodeHelpParams, '')   AS MCodeHelpParams,
            ISNULL(A.DisSupplyAmt,0) AS DisSupplyAmt,
            B.SMComOrPriv           AS ComOrPriv,
            CP.MinorName            AS ComOrPrivName,
            CASE DW.SWeek0 WHEN '0' THEN '일요일'
                           WHEN '1' THEN '월요일'
                           WHEN '2' THEN '화요일'
                           WHEN '3' THEN '수요일'
                           WHEN '4' THEN '목요일'
                           WHEN '5' THEN '금요일'
                           WHEN '6' THEN '토요일'
            ELSE '' END AS DayOfTheWeek,
            IsNonVat,
            B.BizUnit,
            W.BizUnitName,
            X.PjtSeq AS PJTSeq,
            X.PjtName AS PJTName,
            ISNULL(A.LastDateTime,'') AS LastDateTime,
            ISNULL(A.LastUserSeq,0) AS LastUserSeq ,A.SERVTYPEYN,
            Z.MinorSeq AS ChannelSeq,
            ISNULL(Z.MinorName, '') AS ChannelName,
            --ISNULL(usr.UserName,'') AS LastUserName
            A.APPR_BUY_SEQ          AS APPR_BUY_SEQ,
            A.CHAIN_TYPE            AS CHAIN_TYPE,
           A.Dummy1,A.Dummy2,A.Dummy3,A.Dummy4,A.Dummy5,
           A.Dummy6,A.Dummy7,A.Dummy8,A.Dummy9,A.Dummy10, 
           --REPLACE(AA.CardNo,'-',''),
           --AA.ApprDate, 
           AA.ApprSeq 
           --AA.ApprNo
           INTO #TempResult
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                ) 
                   JOIN #TDACard      AS B  ON B.CompanySeq = A.CompanySeq  
                                                       AND B.CardNo = A.CARD_CD
        LEFT OUTER JOIN _TDAUMinorValue  AS B1  ON B.CompanySeq = B1.CompanySeq    
                                                           AND B1.MinorSeq = B.UMCardKind  
                                                           AND B1.Serl = 1001  
                                                           AND B1.MajorSeq = 4004  
        LEFT OUTER JOIN _TDACust         AS B2  ON B1.CompanySeq = B2.CompanySeq    
                                                           AND B1.ValueSeq   = B2.CustSeq  
        LEFT OUTER JOIN #TCardUser       AS U               ON B.CardSeq    = U.CardSeq  
                                                           AND A.APPR_DATE BETWEEN U.StartDate AND U.EndDate  
        LEFT OUTER JOIN _TDAEmp     AS C  ON C.CompanySeq = A.CompanySeq  
                                                     AND C.EmpSeq     = CASE ISNULL(A.EmpSeq,0) WHEN 0 THEN U.EmpSeq ELSE A.EmpSeq END  
        LEFT OUTER JOIN (  
                            SELECT A.EmpSeq,   
                             A.DeptSeq,   
                                   A.OrdDate      AS DeptDateFr,   
                                   A.OrdEndDate   AS DeptDateTo,   
                                   CASE WHEN @EnvValue8929 = '1' THEN B.CCtrSeq ELSE '' END AS CCtrSeq,   
                                   ISNULL(B.BegYM, '190001') + '01' AS CCtrDateFr,   
                                   ISNULL(B.EndYM, '299912') + '31' AS CCtrDateTo  
                              FROM _THRADMOrdEmp AS A   
                                   LEFT OUTER JOIN _THROrgDeptCCtr AS B  ON A.CompanySeq = B.CompanySeq   
                                                                                    AND A.DeptSeq = B.DeptSeq  
                                                                                    AND (  A.OrdDate    BETWEEN B.BegYM + '01' AND B.EndYM + '31'   
                                                                                        OR A.OrdEndDate BETWEEN B.BegYM + '01' AND B.EndYM + '31')  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND A.IsOrdDateLast = '1' AND ISNULL(B.IsLast, '1') = '1'
                         ) AS C1 ON C.EmpSeq = C1.EmpSeq   
                                AND A.APPR_DATE BETWEEN C1.DeptDateFr AND C1.DeptDateTo    
                                AND A.APPR_DATE BETWEEN C1.CCtrDateFr AND C1.CCtrDateTo 
        --left outer join _THRADMOrdEmp   AS C1 ON C.CompanySeq  = C1.CompanySeq and C.EmpSeq = C1.EmpSeq AND A.APPR_DATE BETWEEN C1.OrdDate AND C1.OrdEndDate AND C1.IsOrdDateLast = '1'  
        --left outer join _THROrgDeptCCtr AS C2 ON C1.CompanySeq = C2.CompanySeq and C1.DeptSeq = C2.DeptSeq AND A.APPR_DATE BETWEEN C2.BegYM + '01' AND C2.EndYM + '31'  
  
        LEFT OUTER JOIN _TDACust    AS D   ON D.CompanySeq  = A.CompanySeq  
                                                      AND D.CustSeq     = A.CustSeq  
        LEFT OUTER JOIN #TCustInfo  AS D1              ON REPLACE(A.CHAIN_ID, '-', '') = REPLACE(D1.BizNo, '-', '')
        LEFT OUTER JOIN _TDACust    AS D2  ON D2.CompanySeq = @CompanySeq  
                                                      AND D1.CustSeq    = D2.CustSeq  
        LEFT OUTER JOIN _TDAAccount AS E   ON E.CompanySeq  = A.CompanySeq  
                                                      AND E.AccSeq      = A.AccSeq  
        LEFT OUTER JOIN _TDADept    AS F   ON F.CompanySeq  = A.CompanySeq  
                                                      AND F.DeptSeq     = CASE ISNULL(A.DeptSeq,0) WHEN 0 THEN C1.DeptSeq ELSE A.DeptSeq END  
        LEFT OUTER JOIN _TDACCtr    AS G   ON G.CompanySeq  = A.CompanySeq  
               AND G.CCtrSeq     = CASE ISNULL(A.CCtrSeq,0) WHEN 0 THEN C1.CCtrSeq ELSE A.CCtrSeq END  
        LEFT OUTER JOIN _TACSlipRow AS H   ON A.CompanySeq  = H.CompanySeq  
                                                      AND A.SlipSeq     = H.SlipSeq  
        LEFT OUTER JOIN _TACSlip    AS P   ON H.CompanySeq  = P.CompanySeq  
                                                      AND H.SlipMstSeq  = P.SlipMstSeq  
        LEFT OUTER JOIN _TDAEvid    AS Q   ON A.CompanySeq  = Q.CompanySeq  
                                                      AND A.EvidSeq     = Q.EvidSeq  
        LEFT OUTER JOIN _TDAUMinor  AS R   ON A.CompanySeq  = R.CompanySeq  
                                                      AND R.MinorSeq    = B.UMCardKind  
                                                      AND R.MajorSeq    = 4004  
        -- 사업자번호 나타나도록 수정 2009.12.?? 한혜진  
        LEFT OUTER JOIN _TDATaxUnit AS S WITH (NOLOCK) ON (S.CompanySeq = F.CompanySeq AND F.TaxUnit    = S.TaxUnit )  
        LEFT OUTER JOIN _TDAUMinor  AS T  ON A.CompanySeq = T.CompanySeq  
                                                     AND T.MinorSeq = CASE ISNULL(A.UMCostType,0) WHEN 0 THEN F.UMCostType ELSE A.UMCostType END   
        LEFT OUTER JOIN _TDAAccount AS V   ON A.CompanySeq = V.CompanySeq     AND A.VatAccSeq  = V.AccSeq 
        LEFT OUTER JOIN _TDASminor  AS CT  ON A.CompanySeq = CT.CompanySeq AND CT.MajorSeq = 8920 AND A.CHAIN_TYPE = RTRIM(LTRIM(CT.MinorValue))
        LEFT OUTER JOIN _TDAAccountRem AS AR  ON A.CompanySeq = AR.CompanySeq AND A.RemSeq = AR.RemSeq
        LEFT OUTER JOIN ( SELECT A.SlipSeq, B.RemSeq, B.RemValSeq
                            FROM _TACSlipRow AS A 
                            JOIN _TACSlipRem AS B  ON A.CompanySeq = B.CompanySeq
                                          AND A.SlipSeq = B.SlipSeq
                           WHERE A.CompanySeq = @CompanySeq   
                        ) AS Slip ON A.SlipSeq = Slip.SlipSeq
                                 AND A.RemSeq = Slip.RemSeq
                                 AND A.RemSeq <> 0
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV1  ON A.CompanySeq = ARV1.CompanySeq AND Slip.RemSeq = ARV1.RemSeq AND Slip.RemValSeq = ARV1.RemValueSerl
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV2  ON A.CompanySeq = ARV2.CompanySeq AND A.RemSeq = ARV2.RemSeq AND A.RemValueSeq = ARV2.RemValueSerl
        LEFT OUTER JOIN _TDASMinor AS CP  ON A.CompanySeq   = CP.CompanySeq AND B.SMComOrPriv   = CP.MinorSeq AND CP.MajorSeq = 4019
        LEFT OUTER JOIN _TCOMCalendar AS DW  ON DW.Solar = A.APPR_DATE
        LEFT OUTER JOIN _TDABizUnit AS W  ON B.CompanySeq = W.CompanySeq AND B.BizUnit = W.BizUnit
        LEFT OUTER JOIN _TPjtProject AS X  ON A.CompanySeq = X.CompanySeq AND A.PJTSeq = X.PJTSeq
        LEFT OUTER JOIN _TDACustClass AS Y  ON A.CompanySeq = Y.CompanySeq AND D2.CustSeq = Y.CustSeq AND Y.UMajorCustClass = 8004
        LEFT OUTER JOIN _TDAUMinor AS Z  ON A.CompanySeq = Z.CompanySeq AND Y.UMCustClass = Z.MinorSeq
    
    UNION   
    
    -- 카드번호는 등록되어 있는데 사용자가 등록되어 있지 않거나, 배부일이 사용날짜 이후인 것들 내역은 나오고 담당자만 비어서 나오도록 함   
    SELECT  CASE WHEN ISNULL(A.SlipSeq, 0) <> 0 OR ISNULL(A.ERPKey, '') <> '' THEN '처리' ELSE '미처리' END AS ProcType,   -- 처리상황  
            --dbo._FCOMDecrypt(B.CardNo, '_TDACard', 'CardNo', @CompanySeq)                 AS CARD_CD,              -- 카드번호  
            B.CardNo                 AS CARD_CD,             -- 카드번호
            B.CardName               AS CardName,            -- 카드명
            A.APPR_DATE              AS APPR_DATE,            -- 승인일자  
            A.APPR_NO                AS ApprNo,              -- 승인번호  
            A.CHAIN_NM               AS ChainName,           -- 가맹점명  
            A.CHAIN_ID               AS ChainBizNo,          -- 가맹점 사업자번호  
   ISNULL(CT.MinorName, '미확인')    AS ChainType,
            ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprAmt,             -- 승인금액  
            ISNULL(ABS(A.APPR_TAX),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)     AS ApprTax,             -- 승인금액부가가치세  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)            
                 WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
        WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- 공급가액이(+)로 은행에서 넘어온 경우 
                 WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                 ELSE A.SupplyAmt  
            END  AS SupplyAmt,           -- 공급가액  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
          WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- 공급가액이(+)로 은행에서 넘어온 경우   
                      WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                      ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                               WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,ABS(ISNULL(A.APPR_AMT, 0) - ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                 END - ISNULL(A.DisSupplyAmt,0) - ISNULL(A.Tip_Amt,0)   
            ELSE 0 END   AS UpdateVat ,          -- 수정부가세  
            CASE WHEN A.Chain_Type IN (2,3) AND SupplyAmt IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)                 
                ELSE
                CASE WHEN (ISNULL(A.SupplyAmt, 0) = 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
            WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) -- 공급가액이(+)로 은행에서 넘어온 경우 
                     WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1)
                     ELSE A.SupplyAmt  
                END  +         -- 공급가액  
                CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0
                 WHEN ISNULL(A.NotVatSel,'') <> '1' THEN   
                     CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN ABS(ISNULL(A.APPR_TAX,0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
              WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1)) -- 공급가액이(+)로 은행에서 넘어온 경우   
                          WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN (ABS(ISNULL(A.APPR_AMT, 0)) * (-1) - A.SupplyAmt * (-1))
                          ELSE (ABS(ISNULL(A.APPR_AMT, 0)) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                   WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)) - ISNULL(A.SupplyAmt,(ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                                                                                                     WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END))  
                     END    
                ELSE 0 END
            END AS TotalAmt ,          -- 합계금액  
 
            A.AccSeq                 AS AccSeq,              -- 계정코드  
            A.AccSeq                 AS AccSeqOld,           -- 계정코드
            A.HALBU                  AS HALBU,               -- 할부기간
            A.RemSeq                 AS RemSeq,              -- 관리항목
            AR.RemName               AS RemName,             -- 관리항목명
            CASE WHEN ARV1.RemValueName IS NULL THEN ARV2.RemValueName ELSE ARV1.RemValueName END       AS RemValue,            -- 관리항목값
            A.RemValueSeq            AS RemValueSeq,         -- 관리항목값코드
            A.CANCEL_YN,    -- 승인취소여부 키  
            CASE A.CANCEL_YN WHEN '3' THEN (CASE WHEN A.BUYING_DIST IN ('02', '04') THEN '취소'
                                                 WHEN A.BUYING_DIST = '06' THEN '환급' END)     --외환은행 추가
                             WHEN 'Y' THEN '취소'  
                             ELSE '승인'  
            END  AS CancelYN,  -- 승인취소여부  
            E.AccName                AS AccName,             -- 발생계정  
            A.Remark                 AS Remark,              -- 비고1  
            C.EmpName                AS EmpName,             -- 사원  
            CASE WHEN ISNULL(D.CustName,'') = '' THEN D2.CustName ELSE D.CustName END AS CustName,      -- 거래처  
            CASE WHEN ISNULL(A.CustSeq, 0) = 0   THEN D1.CustSeq  ELSE A.CustSeq  END AS CustSeq,       -- 거래처코드  
            CASE WHEN ISNULL(A.ERPKey,'') = ''   THEN H.SlipID    ELSE A.ERPKey   END AS ERPKey,        -- 전표번호  
            A.SlipSeq    ,                                   -- 발생전표코드  
            C.EmpSeq    AS EmpSeq     ,        -- 사번  
            A.APPR_SEQ  AS APPR_SEQ,            -- 승인순번  
            B.CardSeq,  
            G.CCtrName,  
            G.CCtrSeq AS CCtrSeq,  
            F.DeptName,  
            F.Deptseq AS DeptSeq,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAcc  
                WHEN 4019002 THEN @IndivCardAcc  
            END         AS CrAccName, --' 상대계정 -미지급금(카드)' AS OutAccNm,  
            CASE B.SMComOrPriv  
                WHEN 4019001 THEN @JuridCardAccSeq  
                WHEN 4019002 THEN @IndivCardAccSeq  
            END         AS CrAccSeq,     -- 상대계정코드  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'            
                 WHEN ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)) THEN '1' ELSE A.VatSel END AS VatSel, -- 부가세여부  
            CASE WHEN A.Chain_Type IN (2,3) THEN '0'
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN '0'             
                 WHEN A.VatYN = 'Y' THEN '1'  
                 WHEN A.VatYN = 'N' THEN '0'  
            END AS VATYN,        --부가세환급대상여부   
            CASE WHEN A.Chain_Type IN (2,3) THEN ''
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAcc 
                 WHEN A.IsNonVat = '1' THEN @CardAddAcc 
      ELSE '' END AS VatSttlItem, -- 부가세계정  ,
            CASE WHEN A.Chain_Type IN (2,3) THEN 0
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0             
                 WHEN (A.VatSel = '1' OR ((A.VatSel IS NULL OR A.VatSel = '') AND (A.VatYN = 'Y' OR ISNULL(A.APPR_TAX,0) <> 0)))  THEN @CardAddAccSeq ELSE '' END AS AddTaxAccSeq, -- 부가세계정코드  
            A.IsDefine,  
            A.EvidSeq,  
            Q.EvidName,  
            CASE WHEN ISNULL(A.ModDate,'') = '' THEN A.APPR_DATE ELSE A.ModDate END AS ModDate,  
            A.EvidSeq,  
            Q.EvidName,  
            A.MASTER,  
            ISNULL((CASE WHEN CHARINDEX('-',A.MERCHZIPCODE) <> 0 THEN A.MERCHZIPCODE ELSE LEFT(A.MERCHZIPCODE,3) + '-' + RIGHT(A.MERCHZIPCODE,3) END ),'')   AS MERCHZIPCODE,  
            A.MERCHADDR1,  
            A.MERCHADDR2,  
             A.APPRTOT * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END),  
            A.MCCNAME,  
            A.MCCCODE,  
            A.TAXTYPE,  
            A.MERCHCESSDATE,  
            @CardAddAcc  AS AddTaxAccNameOld, -- 부가세계정Old  
            @CardAddAccSeq AS AddTaxAccSeqOld,-- 부가세계정코드Old  
            B.UMCardKind AS UMCardKind,  
            B1.ValueSeq AS CardCustSeq,  
            B2.CustName AS CardCustName,  
            R.MinorName AS UMCardKindName,  
            A.PURDATE,  -- 매입일자 (안철수연구소에서는 승인일자로 쓰임)  
            A.TIP_AMT,  -- 팁  
            T.MinorSeq AS UMCostType,  
            T.MinorName AS UMCostTypeName,  
            CASE WHEN ISNULL(A.TaxUnit,0) = 0 THEN S.TaxUnit ELSE A.TaxUnit END AS TaxUnit,  
            --A.TaxNo  
            CASE WHEN A.EmpSeq IS NULL THEN 0 ELSE 1 END IsEmpSave,  
            CASE WHEN A.CustSeq IS NULL THEN 0 ELSE 1 END IsCustSave,  
            --불공제관련추가 3개 항목  
            CASE WHEN A.Chain_Type IN (2,3) AND A.CostAmtDr IS NULL THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ISNULL(ABS(A.APPR_AMT),0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                             WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)        
                 WHEN ISNULL(A.CostAmtDr,0) = 0 THEN 
                 CASE WHEN ISNULL(A.SupplyAmt, 0) = 0 THEN (ABS(ISNULL(A.APPR_AMT, 0)) - ABS(ISNULL(A.APPR_TAX,0))) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 
                                                                                                                            WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END)  
           WHEN (A.CANCEL_YN IN ('3','Y') AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1)    -- 공급가액이(+)로 은행에서 넘어온 경우 
           WHEN (A.SERVTYPEYN ='Y' AND A.SupplyAmt > 0) THEN A.SupplyAmt * (-1) + ISNULL(A.Tip_Amt,0)*(-1) 
                      ELSE A.SupplyAmt + ISNULL(A.Tip_Amt,0)  END -- CostAmtDr 금액이 없으면 공급가액을 가져오는 것과 동일하게 가져옴.  
            ELSE A.CostAmtDr END AS CostAmtDr,  
            CASE WHEN A.Chain_Type IN (2,3) THEN 0 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN 0                  
            ELSE ISNULL(A.NotVatAmt,0) END AS NotVatAmt,  
            CASE WHEN A.Chain_Type IN (2,3)  THEN '' 
                 WHEN A.Chain_Type IN (2,3)  THEN 0 
                 --환경설정 금액 이하건 최초 조회시 부가세체크 해제 처리
                 WHEN A.VatSel IS NULL AND @EnvValue8927 >= ISNULL(ABS(A.APPR_AMT),0) THEN ''              
            ELSE ISNULL(A.NotVatSel,'') END AS NotVatSel,
            ISNULL(A.APPR_TIME,'') AS APPR_TIME,
            ISNULL(A.CURAMT ,0) * (CASE WHEN A.CANCEL_YN IN ('3','Y') THEN -1 WHEN A.SERVTYPEYN ='Y' THEN -1 ELSE 1 END) AS CURAMT, 
            --ISNULL(A.STTL_DATE,'')         AS STTL_DATE,
            CASE WHEN ISNULL(A.STTL_DATE,'') <> '' 
                    THEN ISNULL(A.STTL_DATE,'')
                 WHEN ISNULL(A.STTL_DATE,'') = '' 
                    THEN 
                        CASE WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') = '' AND ISNULL(B.SttlDay,'') <> '' 
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay)
                                            ELSE LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --결제일이 결제한도일보다 이후인경우
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) >= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --결제한도일 이전 승인인경우 해당년월+결제일
            THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(A.APPR_DATE,6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제한도일이 지났고, 결제일 이전인 경우 해당년월+1월의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                AND CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제일 이후에 승인된 경우 해당년월+2월의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2),  B.SttlDay))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                             --결제일이 결제한도일보다 이전인 경우(즉 다음달 결제)
                             WHEN ISNULL(RIGHT(B.SttlLimitDay,2),'') <> '' AND ISNULL(B.SttlDay,'') <> '' 
                                  AND CONVERT(INT,CONVERT(NCHAR(2), B.SttlDay)) < CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                  --결제한도일이 이전인 경우 해당년월+1의 결제일
                                  THEN CASE WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) <= CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 1, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                  --결제한도일이 이후인 경우 해당년월+2의 결제일
                                            WHEN CONVERT(INT,RIGHT(A.APPR_DATE,2)) > CONVERT(INT,CONVERT(NCHAR(2), RIGHT(B.SttlLimitDay,2)))
                                                THEN LEFT(CONVERT(NCHAR(8),DATEADD(mm, 2, A.APPR_DATE),112),6)+ CONVERT(NCHAR(2), B.SttlDay) 
                                       END
                         END   
            END  
            AS STTL_DATE,  
            CASE WHEN ISNULL(A.CHAIN_TYPE, '0') IN('0', '', '1', '4', '99') THEN '0'
            ELSE '1' END AS IsDisVatYN,
            ISNULL(AR.CodeHelpSeq   , 0) AS MCodeHelpSeq    ,
            ISNULL(AR.CodeHelpParams, '') AS MCodeHelpParams,
            ISNULL(A.DisSupplyAmt,0) AS DisSupplyAmt  ,
            B.SMComOrPriv           AS ComOrPriv,
            CP.MinorName            AS ComOrPrivName,
            CASE DW.SWeek0 WHEN '0' THEN '일요일'
                           WHEN '1' THEN '월요일'
                           WHEN '2' THEN '화요일'
                           WHEN '3' THEN '수요일'
                           WHEN '4' THEN '목요일'
                           WHEN '5' THEN '금요일'
                           WHEN '6' THEN '토요일'
            ELSE '' END AS DayOfTheWeek,
            A.IsNonVat,
            B.BizUnit,
            W.BizUnitName,
            X.PjtSeq AS PJTSeq,
            X.PjtName AS PJTName,
            ISNULL(A.LastDateTime,'') AS LastDateTime,
            ISNULL(A.LastUserSeq,0) AS LastUserSeq, A.SERVTYPEYN,
            Z.MinorSeq AS ChannelSeq,
            ISNULL(Z.MinorName, '') AS ChannelName,
            --ISNULL(usr.UserName,'') AS LastUserName                   
            A.APPR_BUY_SEQ          AS APPR_BUY_SEQ,
            A.CHAIN_TYPE            AS CHAIN_TYPE,
           A.Dummy1,A.Dummy2,A.Dummy3,A.Dummy4,A.Dummy5,
           A.Dummy6,A.Dummy7,A.Dummy8,A.Dummy9,A.Dummy10, 
           --REPLACE(AA.CardNo,'-',''),
           --AA.ApprDate, 
           AA.ApprSeq 
           --AA.ApprNo
           
      FROM #TSIAFebCardCfm AS AA 
      LEFT OUTER JOIN _TSIAFebCardCfm   AS A ON ( A.CompanySeq = @CompanySeq 
                                              AND REPLACE(AA.CardNo,'-','') = A.CARD_CD 
                                              AND AA.ApprDate = A.APPR_DATE 
                                              AND AA.ApprSeq = A.APPR_SEQ 
                                              AND AA.ApprNo = A.APPR_No 
                                              AND AA.CANCEL_YN = A.CANCEL_YN
                                                ) 
                 JOIN #TDACard          AS B  ON ( B.CompanySeq = A.CompanySeq AND B.CardNo = A.CARD_CD ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS B1 ON B.CompanySeq = B1.CompanySeq    
                                                           AND B1.MinorSeq = B.UMCardKind  
                                                           AND B1.Serl = 1001  
                                                           AND B1.MajorSeq = 4004  
      LEFT OUTER JOIN _TDACust          AS B2 ON B1.CompanySeq = B2.CompanySeq AND B1.ValueSeq = B2.CustSeq  
                 JOIN _TDAEmp           AS C  ON C.CompanySeq = A.CompanySeq AND C.EmpSeq = A.EmpSeq  
      LEFT OUTER JOIN (  
                            SELECT A.EmpSeq,   
                             A.DeptSeq,   
                                   A.OrdDate      AS DeptDateFr,   
                                   A.OrdEndDate   AS DeptDateTo,   
                                   CASE WHEN @EnvValue8929 = '1' THEN B.CCtrSeq ELSE '' END AS CCtrSeq,   
                                   ISNULL(B.BegYM, '190001') + '01' AS CCtrDateFr,   
                                   ISNULL(B.EndYM, '299912') + '31' AS CCtrDateTo  
                              FROM _THRADMOrdEmp AS A   
                                   LEFT OUTER JOIN _THROrgDeptCCtr AS B  ON A.CompanySeq = B.CompanySeq   
                                                                                    AND A.DeptSeq = B.DeptSeq  
                                                                                    AND (  A.OrdDate    BETWEEN B.BegYM + '01' AND B.EndYM + '31'   
                                                                                        OR A.OrdEndDate BETWEEN B.BegYM + '01' AND B.EndYM + '31')  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND A.IsOrdDateLast = '1' AND ISNULL(B.IsLast, '1') = '1'  
                         ) AS C1 ON C.EmpSeq = C1.EmpSeq   
                                AND A.APPR_DATE BETWEEN C1.DeptDateFr AND C1.DeptDateTo  
                                AND A.APPR_DATE BETWEEN C1.CCtrDateFr AND C1.CCtrDateTo                                 
        LEFT OUTER JOIN _TDACust    AS D   ON D.CompanySeq = A.CompanySeq  
                                                      AND D.CustSeq    = A.CustSeq  
        LEFT OUTER JOIN #TCustInfo  AS D1              ON REPLACE(A.CHAIN_ID, '-', '') = REPLACE(D1.BizNo, '-', '')
        LEFT OUTER JOIN _TDACust    AS D2  ON D2.CompanySeq = @CompanySeq  
                                                      AND D1.CustSeq    = D2.CustSeq  
        LEFT OUTER JOIN _TDAAccount AS E  ON E.CompanySeq = A.CompanySeq  
                                                     AND E.AccSeq     = A.AccSeq  
        LEFT OUTER JOIN _TDADept    AS F  ON F.CompanySeq = A.CompanySeq  
                                                     AND F.DeptSeq    = CASE ISNULL(A.DeptSeq,0) WHEN 0 THEN C1.DeptSeq ELSE A.DeptSeq END  
        LEFT OUTER JOIN _TDACCtr    AS G  ON G.CompanySeq = A.CompanySeq  
                                                     AND G.CCtrSeq    = CASE ISNULL(A.CCtrSeq,0) WHEN 0 THEN C1.CCtrSeq ELSE A.CCtrSeq END  
        LEFT OUTER JOIN _TACSlipRow AS H  ON A.CompanySeq = H.CompanySeq  
                                                     AND A.SlipSeq    = H.SlipSeq  
        LEFT OUTER JOIN _TACSlip    AS P  ON H.CompanySeq = P.CompanySeq  
                                                     AND H.SlipMstSeq = P.SlipMstSeq  
        LEFT OUTER JOIN _TDAEvid    AS Q  ON A.CompanySeq = Q.CompanySeq  
                                                     AND A.EvidSeq    = Q.EvidSeq  
        left outer join _TDAUMinor  AS R  ON A.CompanySeq = R.CompanySeq  
                                                     AND R.MinorSeq = B.UMCardKind  
                                                     AND R.MajorSeq = 4004  
        -- 사업자번호 나타나도록 수정 2009.12.?? 한혜진  
        LEFT OUTER JOIN _TDATaxUnit AS S WITH (NOLOCK) ON (S.CompanySeq = F.CompanySeq AND F.TaxUnit    = S.TaxUnit )  
        left outer join _TDAUMinor  AS T  ON A.CompanySeq = T.CompanySeq  
                                                     AND T.MinorSeq = CASE ISNULL(A.UMCostType,0) WHEN 0 THEN F.UMCostType ELSE A.UMCostType END   
        LEFT OUTER JOIN _TDAAccount AS V  ON A.CompanySeq = V.CompanySeq  
                                                     AND A.VatAccSeq  = V.AccSeq  
        LEFT OUTER JOIN _TDASminor AS CT  ON A.CompanySeq = CT.CompanySeq AND CT.MajorSeq = 8920 AND ISNULL(A.CHAIN_TYPE, '0') = RTRIM(LTRIM(CT.MinorValue))
        LEFT OUTER JOIN _TDAAccountRem AS AR  ON A.CompanySeq = AR.CompanySeq AND A.RemSeq = AR.RemSeq
        LEFT OUTER JOIN ( SELECT A.SlipSeq, B.RemSeq, B.RemValSeq
                            FROM _TACSlipRow AS A 
                            JOIN _TACSlipRem AS B  ON A.CompanySeq = B.CompanySeq
                                          AND A.SlipSeq = B.SlipSeq
                           WHERE A.CompanySeq = @CompanySeq   
                        ) AS Slip ON A.SlipSeq = Slip.SlipSeq
                                 AND A.RemSeq = Slip.RemSeq
                                 AND A.RemSeq <> 0
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV1  ON A.CompanySeq = ARV1.CompanySeq AND Slip.RemSeq = ARV1.RemSeq AND Slip.RemValSeq = ARV1.RemValueSerl
        LEFT OUTER JOIN _TDAAccountRemValue AS ARV2  ON A.CompanySeq = ARV2.CompanySeq AND A.RemSeq = ARV2.RemSeq AND A.RemValueSeq = ARV2.RemValueSerl
        LEFT OUTER JOIN _TDASMinor AS CP  ON A.CompanySeq   = CP.CompanySeq AND B.SMComOrPriv   = CP.MinorSeq AND CP.MajorSeq = 4019    
        LEFT OUTER JOIN _TCOMCalendar AS DW  ON DW.Solar = A.APPR_DATE
        LEFT OUTER JOIN _TDABizUnit AS W  ON A.CompanySeq = W.CompanySeq AND B.BizUnit = W.BizUnit
        LEFT OUTER JOIN _TPjtProject AS X  ON A.CompanySeq = X.CompanySeq AND A.PJTSeq = X.PJTSeq
        LEFT OUTER JOIN _TDACustClass AS Y  ON A.CompanySeq = Y.CompanySeq AND D2.CustSeq = Y.CustSeq AND Y.UMajorCustClass = 8004
        LEFT OUTER JOIN _TDAUMinor AS Z  ON A.CompanySeq = Z.CompanySeq AND Y.UMCustClass = Z.MinorSeq
     ORDER BY ApprDate, CardNo, ApprNo  
    
    SELECT * FROM #TempResult
    
RETURN
GO 
begin tran 
exec KPX_SARBizTripCostJumpOut @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>7</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CardNo>4336927028349406</CardNo>
    <ApprDate>20080805</ApprDate>
    <ApprNo>36949294</ApprNo>
    <ApprSeq>1</ApprSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <CardNo>4336927028349406</CardNo>
    <ApprDate>20080805</ApprDate>
    <ApprNo>75868955</ApprNo>
    <ApprSeq>3</ApprSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=857
rollback 