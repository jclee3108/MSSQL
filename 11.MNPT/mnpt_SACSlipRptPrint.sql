IF OBJECT_ID('mnpt_SACSlipRptPrint') IS NOT NULL 
    DROP PROC mnpt_SACSlipRptPrint
GO 

-- v2018.01.15 

CREATE PROC mnpt_SACSlipRptPrint            
    @xmlDocument    NVARCHAR(MAX) ,                              
    @xmlFlags       INT = 0,                              
    @ServiceSeq     INT = 0,                              
    @WorkingTag     NVARCHAR(10)= '',                                    
    @CompanySeq     INT = 1,                              
    @LanguageSeq    INT = 1,                              
    @UserSeq        INT = 0,                              
    @PgmSeq         INT = 0                                 
                                  
AS               
    DECLARE @docHandle      INT
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
                
                        
    DECLARE @SlipMstSeq     INT,            
            @SlipSeq        INT,            
            @AccUnit        INT,            
            @SlipUnit       INT,            
            @AccDate        NCHAR(8),            
            @SlipNo         NCHAR(4),
            @IsNotGW        NCHAR(1)
    
    SELECT @SlipMstSeq      = ISNULL(SlipMstSeq, 0),            
           @SlipSeq         = ISNULL(SlipSeq, 0),            
           @AccUnit         = AccUnit,            
           @SlipUnit        = SlipUnit,            
           @AccDate         = AccDate,            
           @SlipNo          = LTRIM(RTRIM(SlipNo)),
           @IsNotGW         = ISNULL(IsNotGW,'')            
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)            
      WITH (SlipMstSeq      INT,            
            SlipSeq         INT,            
            AccUnit         INT,            
            SlipUnit        INT,            
            AccDate         NCHAR(8),            
            SlipNo          NVARCHAR(4),
            IsNotGW         NCHAR(1))         
    DECLARE @RemTotalCount  INT,          
            @index          INT,          
            @Word           NVARCHAR(200),    
            @EnvValue       NVARCHAR(20),    
            @CurrDate       NCHAR(8),    
            @KORDecimal     INT,    
            @FORDecimal     INT,    
            @ExraDecimal    INT,    
            @Cnt            INT,
            @IniCnt         INT,
            @MaxCnt         INT,
            @SubCnt         INT,
            @SubMaxCnt      INT,
            @DataBlock2     NVARCHAR(Max),
            @XmlData        NVARCHAR(MAX),
            @NativeCurr     INT,
            @PersonId       NVARCHAR(20),            
            @Env4040        NCHAR(1)    --출납잔액기준

    -- xml준비            
  	CREATE TABLE #Temp (Cnt         INT IDENTITY(0,1),
                        SlipMstSeq  INT,
                        DataBlock2  NVARCHAR(MAX)          )
    -- 출력물에서 반복부에 출력할 데이터의 XML문서형식을 담아 둘 임시테이블을 생성한다.  
    CREATE TABLE #Temp_DetailRepeat (   SubCnt          INT IDENTITY(0,1),
                                        SlipMstSeq      INT,
                                        DataBlock2      NVARCHAR(MAX)  )

	INSERT INTO #Temp (SlipMstSeq)
    SELECT ISNULL(SlipMstSeq, 0) AS SlipMstSeq
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
      WITH (SlipMstSeq      INT)
      
            
    SET @SlipNo = RIGHT('000' + LTRIM(RTRIM(@SlipNo)), 4)            
    SELECT @Env4040 = ''
    SELECT @NativeCurr  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 13    -- 자국통화
    SELECT @KORDecimal  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 15    -- 원화소수점자리수        
    SELECT @FORDecimal  = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 14    -- 외화소수점자리수    
    SELECT @ExraDecimal = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 11    -- 환율소수점자리수             
    SELECT @Env4040     = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 4040  -- 출납입력(잔액기준)
    SELECT @EnvValue    = EnvValue FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 17    -- 사업자번호 형태 환경설정에서 가져오기
    IF @@ROWCOUNT = 0 OR ISNULL(@EnvValue, '') = ''
        SELECT @EnvValue = ''
            
    SELECT @PersonId = EnvValue    FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 16    -- 주민등록번호 형태 환경설정에서 가져오기
    IF @@ROWCOUNT = 0 OR ISNULL(@PersonId, '') = ''
        SELECT @PersonId = ''

    IF @KORDecimal  = 0 SELECT @KORDecimal  = -1    
    IF @FORDecimal  = 0 SELECT @FORDecimal  = -1    
    IF @ExraDecimal = 0 SELECT @ExraDecimal = -1    
    SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)
     --================================================================================================================================                 
     -- 환경설정(출납입력(잔액기준))설정에 따른 출납예정일 출력을 위한 임시테이블 생성 (2012.02.01 mypark)     
     --================================================================================================================================       
      CREATE TABLE #tempCash  
     (  
         CompanySeq      INT,   
         SlipSeq         INT,   
         Amt             DECIMAL(19,5),  
         ForAmt          DECIMAL(19,5),   
         CashDate        NCHAR(8),  
         Serl            INT,
         SMInOrOut       INT,
         SMCashMethod    INT
  
     )  
      CREATE TABLE #tempCashOff  
     (  
         CompanySeq      INT,   
         SlipSeq         INT,   
         OffSlipSeq      INT,  
         Serl            INT,  
  
     )              
    --출납관련 데이터를 모두 집계 하지 않도록 SlipSeq를 받아놓는다.
    CREATE TABLE #CashSlipSeq
    (   
        SlipSeq     INT
     )
     
     INSERT INTO #CashSlipSeq (SlipSeq)
     SELECT SlipSeq FROM _TACSlipRow WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND SlipMstSeq IN (SELECT SlipMstSeq FROM #Temp )
     -- 출납잔액기준 사용여부
     IF @Env4040 <> '1'
     BEGIN  --출납(통합)
         INSERT INTO #tempCash (CompanySeq, SlipSeq,Amt, ForAmt, CashDate, Serl, SMInOrOut, SMCashMethod)  
             SELECT A.CompanySeq, A.SlipSeq, A.Amt, A.ForAmt, A.CashDate, A.Serl, B.SMInOrOut, A.SMCashMethod 
               FROM _TAPCashOn AS A WITH(NOLOCK)
                                    JOIN (SELECT CompanySeq, SlipSeq, MIN(Serl) AS Serl
                                            FROM _TAPCashOn WITH(NOLOCK)
                                           WHERE CompanySeq = @CompanySeq
                                             AND SlipSeq IN (SELECT SlipSeq FROM #CashSlipSeq)
                                           GROUP BY CompanySeq, SlipSeq) AS A2
                                      ON A.CompanySeq   = A2.CompanySeq
                                     AND A.SlipSeq      = A2.SlipSeq
                                     AND A.Serl         = A2.Serl
                         LEFT OUTER JOIN _TAPCash AS B WITH(NOLOCK)
                                      ON A.CompanySeq = B.CompanySeq 
                                     AND A.SlipSeq    = B.SlipSeq 
              WHERE A.CompanySeq = @CompanySeq
                AND A.SlipSeq    IN (SELECT SlipSeq FROM #CashSlipSeq)
         INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq, Serl)  
             SELECT CompanySeq, SlipSeq, OffSlipSeq, Serl  
               FROM _TAPCashOff WITH(NOLOCK)
              WHERE CompanySeq  = @CompanySeq 
     END   
     ELSE  
     BEGIN  --출납(잔액기준)
         INSERT INTO #tempCash (CompanySeq, SlipSeq, Amt, ForAmt, CashDate, Serl, SMInOrOut, SMCashMethod)  
             SELECT CompanySeq, SlipSeq, OnAmt, OnForAmt, CashDate, 1, SMInOrOut, SMCashMethod
               FROM _TACCashOn WITH(NOLOCK)
              WHERE CompanySeq = @CompanySeq  
                AND SlipSeq IN (SELECT SlipSeq FROM #CashSlipSeq)
                
         INSERT INTO #tempCashOff (CompanySeq, SlipSeq, OffSlipSeq, Serl)  
             SELECT CompanySeq, OnSlipSeq, SlipSeq,  1  
               FROM _TACCashOff WITH(NOLOCK)
              WHERE CompanySeq = @CompanySeq 
     END  
  
    --================================================================================================================================                
    -- 환경설정(출납입력(잔액기준))설정에 따른 출납예정일 출력을 위한 임시테이블 생성 끝   
    --================================================================================================================================            
     
    SELECT           
           A.CompanySeq,            
           A.SlipMstSeq,        -- 전표마스터코드            
           A.AccUnit,           -- 회계단위            
           A.SlipUnit,          -- 전표관리단위            
           A.AccDate,           -- 회계일            
           A.SlipNo,            -- 기표일련번호            
           A.SlipKind,          -- 전표구분       
           B.SlipKindName,           
           A.RegEmpSeq,         -- 기표자            
           A.RegDeptSeq,        -- 기표부서            
           A.Remark,            -- 비고            
           A.SMCurrStatus,      -- 접수상태            
           A.AptDate,           -- 접수일            
           A.AptEmpSeq,         -- 접수자            
           A.AptDeptSeq,        -- 접수부서            
           A.AptRemark,         -- 접수비고            
           A.SMCheckStatus,     -- 정정상태            
           A.CheckOrigin,       -- 원천번호            
           A.IsSet,             -- 승인여부      
           A.SetSlipNo,         -- 승인일련번호            
           A.SetEmpSeq,         -- 승인자            
           A.SetDeptSeq,        -- 승인부서            
           A.SlipMstID,         -- 전표기표번호            
           CASE WHEN A.IsSet = '1' THEN ISNULL(A.SetSlipID, '')
                ELSE ''          
           END AS SlipAppNo, -- 전표번호            
           A.RegAccDate,     -- 기표번호
           A.RegDateTime,     -- 전표등록일자
           CONVERT(NCHAR(8), A.RegDateTime, 112) AS RTRegAccDate,
           CASE WHEN ISNULL(D.IsSet, '') <> '1' THEN '' ELSE CONVERT(NVARCHAR(100),D.ApprovalDateTime, 121) END AS ApprovalDateTime,--실제 승인일시
           CASE WHEN ISNULL(D.IsSet, '') <> '1' THEN '' ELSE CONVERT(NCHAR(8), D.ApprovalDateTime, 112) END AS RTSetAccDate
      INTO #tmp            
      FROM _TACSlip AS A WITH (NOLOCK)    
                INNER JOIN #Temp        AS C ON A.SlipMstSeq = C.SlipMstSeq   
           LEFT OUTER JOIN _TACSlipKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SlipKind = B.SlipKind     
           LEFT OUTER JOIN _TACSlipSetData AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq 
                                                            AND A.SlipMstSeq = D.SlipMstSeq 
                                                            AND D.Serl      = (SELECT MAX(Serl) AS Serl 
                                                                                FROM _TACSlipSetData WITH(NOLOCK)
                                                                               WHERE CompanySeq = A.CompanySeq
                                                                                 AND SlipMstSeq = A.SlipMstSeq
                                                                               )
     WHERE A.CompanySeq = @CompanySeq            
 
 
    SELECT A.SlipMstSeq,        -- 전표마스터코드            
           A.AccUnit,           -- 회계단위            
           A.SlipUnit,          -- 전표관리단위            
           A.AccDate,           -- 회계일            
           A.SlipNo,            -- 기표일련번호            
           A.SlipKind,          -- 전표구분         
           A.SlipKindName,      -- 전표구분         
           A.RegEmpSeq,         -- 기표자            
           A.RegDeptSeq,        -- 기표부서      
           A.Remark,            -- 비고            
           A.SMCurrStatus,      -- 접수상태            
           A.AptDate,           -- 접수일            
           A.AptEmpSeq,         -- 접수자            
           A.AptDeptSeq,        -- 접수부서            
           A.AptRemark,         -- 접수비고            
           A.SMCheckStatus,     -- 정정상태            
           A.CheckOrigin,       -- 원천번호            
           A.IsSet,             -- 승인여부            
           A.SetSlipNo,         -- 승인일련번호            
           A.SetEmpSeq,         -- 승인자            
           A.SetDeptSeq,        -- 승인부서            
           C.EmpName    AS RegEmpName,      -- 기표자            
           F.DeptName   AS RegDeptName,     -- 기표부서            
           D.EmpName    AS AptEmpName,      -- 접수자            
           G.DeptName   AS AptDeptName,     -- 접수부서            
           E.EmpName    AS SetEmpName,      -- 승인자            
           H.DeptName   AS SetDeptName,     -- 승인부서            
           I.SlipUnitName,                  -- 전표관리단위            
           A.SlipMstID,         -- 전표기표번호            
           A.SlipAppNo,         -- 전표번호            
           ISNULL(B.DrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstDrAmt,         -- 차변금액            
           ISNULL(B.CrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstCrAmt,         -- 대변금액            
           ISNULL(B.DrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstDrForAmt,   -- 외화차변금액            
           ISNULL(B.CrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstCrForAmt,   -- 외화대변금액            
           ISNULL(B.DrAmt, CAST(0 AS DECIMAL(19,5)) ) - ISNULL(B.CrAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstBalanceAmt,           -- 대차차액            
           ISNULL(B.DrForAmt, CAST(0 AS DECIMAL(19,5)) ) - ISNULL(B.CrForAmt, CAST(0 AS DECIMAL(19,5)) ) AS MstForBalanceAmt,   -- 외화대차차액            
           A.RegAccDate,    --기표번호
           A.RegDateTime,    -- 전표등록일자
           A.RTRegAccDate,
           A.ApprovalDateTime,
           A.RTSetAccDate
      INTO #Result_tmp          
      FROM #tmp AS A            
           LEFT JOIN (SELECT R.SlipMstSeq,            
                             SUM(R.DrAmt)       AS DrAmt,            
                             SUM(R.CrAmt)       AS CrAmt,            
                             SUM(R.DrForAmt)    AS DrForAmt,            
                             SUM(R.CrForAmt)    AS CrForAmt            
                        FROM _TACSlipRow AS R WITH (NOLOCK) 
                       WHERE R.CompanySeq = @CompanySeq            
                         AND EXISTS (SELECT * FROM #tmp WHERE SlipMstSeq = R.SlipMstSeq)
                       GROUP BY SlipMstSeq
                     ) AS B            
                  ON B.SlipMstSeq   = A.SlipMstSeq            
           LEFT JOIN _TDAEmp AS C WITH (NOLOCK)   -- 기표자            
                  ON C.CompanySeq   = A.CompanySeq            
                 AND C.EmpSeq       = A.RegEmpSeq            
           LEFT JOIN _TDAEmp AS D WITH (NOLOCK)   -- 접수자            
                  ON D.CompanySeq   = A.CompanySeq            
                 AND D.EmpSeq       = A.AptEmpSeq            
           LEFT JOIN _TDAEmp AS E WITH (NOLOCK)   -- 승인자            
                  ON E.CompanySeq   = A.CompanySeq            
                 AND E.EmpSeq       = A.SetEmpSeq            
           LEFT JOIN _TDADept AS F WITH (NOLOCK)  -- 기표부서            
                  ON F.CompanySeq   = A.CompanySeq            
                 AND F.DeptSeq      = A.RegDeptSeq            
           LEFT JOIN _TDADept AS G WITH (NOLOCK)  -- 접수부서            
                  ON G.CompanySeq   = A.CompanySeq            
                 AND G.DeptSeq      = A.AptDeptSeq            
           LEFT JOIN _TDADept AS H WITH (NOLOCK)  -- 승인부서            
                  ON H.CompanySeq   = A.CompanySeq            
                 AND H.DeptSeq      = A.SetDeptSeq            
           LEFT JOIN _TACSlipUnit AS I WITH (NOLOCK)  -- 전표관리단위            
                  ON I.CompanySeq   = A.CompanySeq            
                 AND I.SlipUnit     = A.SlipUnit            
          
    --================================================================================================================================              
    -- 컬럼 정보 생성            
    --================================================================================================================================              
    CREATE TABLE #TempTitle         
    (            
        ColIDX          INT IDENTITY(0, 1),            
        Title           NVARCHAR(100),            
        TitleSeq        INT,            
        SubColIDX       INT,            
        columnName      NVARCHAR(100)            
    )            
            
    EXEC dbo._SCOMEnv @CompanySeq, 4001, @UserSeq, @@PROCID, @RemTotalCount OUTPUT            
    SET @index = 0            
            
    EXEC @Word = _FCOMGetWord @LanguageSeq, 291, '관리항목'            
            
    WHILE @index < @RemTotalCount            
    BEGIN            
        INSERT INTO #TempTitle (Title, TitleSeq)            
        SELECT @Word + CAST(@index + 1 AS VARCHAR),            
               @index + 1            
            
        SELECT @index = @index + 1            
    END            
            
            
    --================================================================================================================================              
    -- 하위 컬럼 정보 생성            
    --================================================================================================================================              
    CREATE TABLE #TempSubTitle            
    (            
        SubColIDX       INT IDENTITY(0, 1),            
        columnName      NVARCHAR(100)            
    )            
            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'RemSeq'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'RemName'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'RemValSeq'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'RemValue'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'IsDrEss'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'IsCrEss'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'Sort'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'CellType'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'CodeHelpSeq'            
    INSERT INTO #TempSubTitle (columnName)  SELECT 'CodeHelpParams'            
            
    -- 초기화면 띄울때는 다른 정보는 필요없으므로 빠져 나감 2009.01.12 by 홍기화            
    IF ISNULL(@SlipMstSeq,0) = 0 AND ISNULL(@SlipSeq,0) = 0             
    BEGIN            
        SELECT 0 AS RowNum FROM _TDAAccUnit WITH(NOLOCK) WHERE 1 = 0            
        SELECT 0 AS RowIDX FROM _TDAAccUnit WITH(NOLOCK) WHERE 1 = 0     
        
        IF ISNULL(@IsNotGW,'') = '1' OR NOT EXISTS(SELECT 1 FROM #Temp) -- 전표연속출력 화면에서 선택없이 낱장출력 시, 결과 테이블수 다르다는 오류로 인해 추가
        BEGIN
	        -- 전표 출력시 계정별 합계표시 여부 
	        SELECT '' AS AccNo FROM _TDAAccUnit WITH(NOLOCK) WHERE 1 = 0     
        END
               
        RETURN            
    END            
    ELSE            
    BEGIN            
        --================================================================================================================================            
        -- 고정컬럼값 조회            
        --================================================================================================================================            
        SELECT --IDENTITY(INT, 0, 1)  AS RowIDX, 
			   0 AS RowIDX,				-- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  
			   0 AS MaxIDX,             -- 연속출력때문에 여러전표가 들어올수 있어서 아래서 번호별 업데이트한다.  
               A.SlipSeq,               -- 전표코드            
               A.SlipMstSeq,            -- 전표마스터코드            
               A.SlipID,                -- 전표기표번호            
               A.AccUnit,               -- 회계단위            
               A.SlipUnit,              -- 전표관리단위            
               A.AccDate,               -- 회계일            
               A.SlipNo,                -- 기표일련번호            
               A.RowNo,                 -- 행번호            
               A.RowSlipUnit,           -- 행별전표관리단위            
               A.AccSeq,                -- 계정코드            
               A.UMCostType,            -- 비용구분            
               A.SMDrOrCr,              -- 차대구분            
               A.DrAmt,                 -- 차변금액            
               A.CrAmt,                 -- 대변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.DrForAmt END AS DrForAmt,              -- 외화차변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CrForAmt END AS CrForAmt,              -- 외화대변금액            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN 0 ELSE A.CurrSeq END AS CurrSeq,               -- 통화코드            
               A.ExRate,                -- 환율            
               A.DivExRate,             -- 나누기 환율            
               A.EvidSeq,               -- 증빙코드            
               0 AS TaxKindSeq,            -- 세무구분코드            
               CAST(0 AS DECIMAL(19,5))  AS NDVATAmt,              -- 불공제세액            
               A.CashItemSeq,           -- 현금흐름표과목코드            
               A.SMCostItemKind,        -- 원가항목유형            
               A.CostItemSeq,           -- 원가항목            
               REPLACE(REPLACE(REPLACE(A.Summary,'<','〈'),'>','〉'),';',':') AS Summary,           -- 적요에 ';' 들어오면 XML파일 파싱오류 발생하여 변환
               A.BgtDeptSeq,            -- 예산부서            
               A.BgtCCtrSeq,            -- 예산활동센터            
               A.BgtSeq,                -- 예산과목코드            
               A.IsSet,                 -- 승인여부            
               CASE WHEN B.SMAccKind = 4018005 THEN (SELECT FSItemName FROM _TCOMFSFormTree WHERE CompanySeq = @CompanySeq
																							  AND FSItemTypeSeq = 2
																							  AND FSItemSeq = (SELECT UpperFSItemSeq FROM _TCOMFSFormTree WHERE CompanySeq = @CompanySeq
																																							AND A.AccSeq = FSItemSeq
																																							AND UpperFSItemTypeSeq = 2))
											   ELSE B.AccName
											    END AS AccName,               -- 계정과목
               CASE WHEN B.SMAccKind = 4018005 THEN B.AccName
											   ELSE ''
											    END AS AccName3,               -- 계정과목												            
               B.AccNo,                 -- 계정번호            
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrName, '') END      AS CurrName,            -- 통화코드  
               CASE WHEN A.CurrSeq = 0 OR A.CurrSeq = @NativeCurr THEN '' ELSE ISNULL(C.CurrUnit, '') END      AS CurrUnit,            -- 통화표시단위
               ISNULL(E.EvidName, '')       AS EvidName,            -- 증빙코드            
               ''    AS TaxKindName,         -- 세무구분코드            
               ISNULL(CAI.CashItemName, '') AS CashItemName,        -- 현금흐름표과목코드            
               CostKind.MinorName           AS SMCostItemKindName,  -- 원가항목유형            
               '' AS CostItemName,          -- 원가항목            
               ISNULL(D.DeptName, '')       AS BgtDeptName,         -- 예산부서            
               ISNULL(CC.CCtrName, '')      AS BgtCCtrName,         -- 예산활동센터            
               ISNULL(BG.BgtName, '')       AS BgtName,             -- 예산과목코드            
               CA.SMInOrOut,            
               CASE ISNULL(CA.SlipSeq, 0)            
                    WHEN 0 THEN '0'            
                    ELSE '1'            
               END AS IsCash,           -- 출납처리여부            
               CAO.CashDate,            -- 출납예정일            
               CAO.SMCashMethod,        -- 출납방법            
               CashOff.Serl                 AS CashOffSerl,         -- 출납지급정보 순번            
               SlipOff.OnSlipSeq            AS OnSlipSeq,            
               SlipOnRow.SlipID             AS OnSlipID,            
               B.SMDrOrCr                   AS SMAccDrOrCr,            
               B.IsAnti,            
               B.IsSlip,            
               B.IsLevel2,            
               B.IsZeroAllow,            
               B.IsEssForAmt,            
               B.SMIsEssEvid,            
               B.IsEssCost,            
               B.IsCostTrn,            
               B.SMIsUseRNP,            
               B.SMRNPMethod,            
               B.SMBgtType,            
               B.IsCash                     AS IsCashAcc,            
               B.SMCashItemKind,            
               B.IsFundSet,            
               B.IsAutoExec,            
               B.SMAccType,            
               B.SMAccKind,            
               B.OffRemSeq,            
               B.BgtRemSeq,            
               B.RemSeq1,            
               B.RemSeq2,            
               ISNULL((SELECT COUNT(*) FROM _TDAAccountCostType WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND AccSeq = A.AccSeq), 0)  AS CostTypeCount,            
               A.CoCustSeq                  AS CoCustSeq,    --관계회사코드            
               CoCust.CustName              AS CoCustName,    --관계회사            
               Cao.SMCashMethodName  , 
               CAST(0 AS DECIMAL(19,5)) AS SumDrAmt,  
               CAST(0 AS DECIMAL(19,5)) AS SumCrAmt,  
               CAST(0 AS DECIMAL(19,5)) AS DrSumFirstFage, -- 일단0 바로아래서update한다.  
               CAST(0 AS DECIMAL(19,5)) AS CrSumFirstFage, -- 일단0 바로아래서update한다.  
			   '' AS IsOnlyOnPage,	-- 일단 '' 바로 아래서 update한다.
               CASE WHEN Rem.RemSeq = 1017 AND 1017 IN (SELECT RemSeq FROM _TDAAccountSub WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND AccSeq = A.AccSeq)    -- 계정과목 수정 후 관리항목이 남아있어서 추가
                    THEN Rem.RemValSeq ELSE 0 END AS CustSeq, -- 거래처코드  , 출납정보에 거래처가 있을때 거래처 정보를 받기 위해 추가함.
               CASE WHEN B.SMAccType = 4002012 AND SlipOff.OnSlipSeq <> 0 THEN
                    ISNULL(SUnit.AccUnitName , '') ELSE '' END AS S_AccUnitName, -- 본지점계정이면서 반제전표(설정전표가 있는 경우)라면, 관리항목의 회계단위명도 보여주도록 수정
               CAST ('' AS NVARCHAR(200)) AS TopUserName,
               CASE WHEN CA.SlipSeq <> 0 AND ISNULL(ERem.RemSeq, 0) > 0 THEN ERem.RemValSeq ELSE 0 END AS EmpSeq -- 사원코드, 출납정보에 사원이 있는 경우의 처리를 위해
          INTO #TempFixedCol            
          FROM _TACSlipRow AS A WITH (NOLOCK)            
               LEFT JOIN _TDAAccount AS B WITH (NOLOCK)            
                  ON B.CompanySeq   = A.CompanySeq            
                     AND B.AccSeq       = A.AccSeq            
               LEFT JOIN _TDACurr AS C WITH (NOLOCK)            
                      ON C.CompanySeq   = A.CompanySeq            
                     AND C.CurrSeq      = A.CurrSeq            
               LEFT JOIN _TDAEvid AS E WITH (NOLOCK)            
                      ON E.CompanySeq   = A.CompanySeq            
                     AND E.EvidSeq      = A.EvidSeq            
               LEFT JOIN _TACDCashItem AS CAI WITH (NOLOCK)            
                      ON CAI.CompanySeq  = A.CompanySeq            
                     AND CAI.CashItemSeq = A.CashItemSeq            
               LEFT JOIN _TACBgtItem AS BG WITH (NOLOCK)            
                      ON BG.CompanySeq  = A.CompanySeq            
                     AND BG.BgtSeq      = A.BgtSeq            
               LEFT JOIN _TDADept AS D WITH (NOLOCK)            
                      ON D.CompanySeq   = A.CompanySeq            
                     AND D.DeptSeq      = A.BgtDeptSeq            
               LEFT JOIN _TDACCtr AS CC WITH (NOLOCK)            
                      ON CC.CompanySeq  = A.CompanySeq            
                     AND CC.CCtrSeq     = A.BgtCCtrSeq            
               LEFT JOIN #tempCash AS CA WITH (NOLOCK)            
                      ON CA.CompanySeq  = A.CompanySeq            
                     AND CA.SlipSeq     = A.SlipSeq             
               LEFT JOIN _TACSlipRem AS ERem WITH (NOLOCK)            
                      ON ERem.CompanySeq  = A.CompanySeq            
                     AND ERem.SlipSeq     = A.SlipSeq
                     AND ERem.RemSeq      = 1002
               LEFT JOIN _TDASMinor AS CostKind WITH (NOLOCK)            
                      ON CostKind.CompanySeq    = A.CompanySeq            
                     AND CostKind.MinorSeq      = A.SMCostItemKind            
                     AND CostKind.MajorSeq      = 5508 -- 원가항목 구분            
               LEFT JOIN (
                        SELECT A.SlipSeq, A.CashDate, A.SMCashMethod, SM1.MinorName AS SMCashMethodName    
                          FROM #tempCash AS A JOIN (
                                                    SELECT CAO.SlipSeq, MIN(CAO.Serl) AS Serl 
                                                      FROM #tempCash AS CAO WITH (NOLOCK)        
                                                          INNER JOIN _TACSlipRow AS ROW WITH (NOLOCK)        
                                                                  ON ROW.CompanySeq = CAO.CompanySeq        
                                                                 AND ROW.SlipSeq    = CAO.SlipSeq        
                                                                 AND (ROW.SlipMstSeq IN (SELECT SlipMstSeq FROM #Temp) )        
                                                     WHERE CAO.CompanySeq = @CompanySeq 
                                                     GROUP BY CAO.SlipSeq) AS B ON A.SlipSeq = B.SlipSeq AND A.Serl = B.Serl
                                              LEFT JOIN _TDAUMinor AS SM1 WITH(NOLOCK)
                                                     ON A.CompanySeq      = SM1.CompanySeq    
                                                    AND A.SMCashMethod    = SM1.MinorSeq    
                                                    AND SM1.MajorSeq        = 4008 
                          WHERE A.CompanySeq = @CompanySeq           
                         ) AS CAO ON CAO.SlipSeq = A.SlipSeq            
               LEFT JOIN _TACSlipOff AS SlipOff WITH (NOLOCK)            
                      ON SlipOff.CompanySeq = A.CompanySeq            
                     AND SlipOff.SlipSeq    = A.SlipSeq            
               LEFT JOIN #tempCashOff AS CashOff WITH (NOLOCK)            
                      ON CashOff.CompanySeq = A.CompanySeq            
                     AND CashOff.OffSlipSeq = A.SlipSeq            
               LEFT JOIN _TACSlipRow AS SlipOnRow WITH (NOLOCK)            
                      ON SlipOnRow.CompanySeq   = SlipOff.CompanySeq            
                     AND SlipOnRow.SlipSeq      = SlipOff.OnSlipSeq            
               LEFT JOIN _TDACust AS CoCust WITH (NOLOCK)       -- 관계회사            
                      ON CoCust.CompanySeq   = A.CompanySeq            
                     AND CoCust.CustSeq      = A.CoCustSeq
               LEFT OUTER JOIN _TDAAccUnit AS SUnit WITH(NOLOCK)
                      ON A.CompanySeq       = SUnit.CompanySeq
                     AND SlipOnRow.AccUnit  = SUnit.AccUnit
               LEFT OUTER JOIN _TACSlipRem AS Rem WITH(NOLOCK) 
                      ON A.CompanySeq       = Rem.CompanySeq 
                     AND CA.SlipSeq         = Rem.SlipSeq
                     AND Rem.RemSeq         = 1017          --거래처
         WHERE A.CompanySeq     = @CompanySeq   
           AND A.SlipMstSeq     IN (SELECT SlipMstSeq FROM #Temp)
         ORDER BY A.RowNo            
    --JOIN 하지 않고 따로 update하는것이 속도면에서 훨씬 빠름
    UPDATE A
       SET A.TopUserName = B.TopUserName
      FROM #TempFixedCol AS A JOIN _TCOMGroupWare AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                   AND B.WorkKind    = 'Slip'
   AND A.SlipMstSeq = B.TblKey

    -- 건별반제 계정이나, 출납계정 중 [반제전표]인 경우에도, CustSeq, EmpSeq에 값을 넣어,
    -- 거래처 지불계좌나, 사원 주계좌정보를 출력물에 포함할 수 있도록 수정함.
    -- 우선순위1. 건별반제/출납(잔액기준)
    UPDATE A
       SET CustSeq  = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TACSlipRow AS B WITH(NOLOCK)
                                ON B.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = B.SlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)
                                ON C.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = C.SlipSeq
                               AND C.RemSeq     = 1017 ------ 거래처 관리항목
     WHERE A.CustSeq    = 0
       AND ISNULL(A.OnSlipSeq, 0) <> 0

    UPDATE A
       SET EmpSeq = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TACSlipRow AS B WITH(NOLOCK)
                                ON B.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = B.SlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)
                                ON C.CompanySeq = @CompanySeq
                               AND A.OnSlipSeq  = C.SlipSeq
                               AND C.RemSeq     = 1002 ------ 사원 관리항목
     WHERE A.EmpSeq    = 0
       AND ISNULL(A.OnSlipSeq, 0) <> 0
    -- 우선순위2. 출납(통합)
    UPDATE A
       SET CustSeq = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TAPCashOff AS B WITH(NOLOCK)    -- 출납(통합) 반제
                                ON B.CompanySeq = @CompanySeq    
                               AND B.OffSlipSeq = A.SlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)
                                ON C.CompanySeq = @CompanySeq       -- 출납(통합) 발생의 거래처관리항목
                               AND C.SlipSeq    = B.SlipSeq
                               AND C.RemSeq     = 1017
     WHERE A.CustSeq = 0
    UPDATE A
       SET EmpSeq = ISNULL(C.RemValSeq, 0)
      FROM #TempFixedCol AS A JOIN _TAPCashOff AS B WITH(NOLOCK)    -- 출납(통합) 반제 
                                ON B.CompanySeq = @CompanySeq
                               AND B.OffSlipSeq = A.SlipSeq
                              JOIN _TACSlipRem AS C WITH(NOLOCK)    -- 출납(통합) 발생의 사원관리항목
                                ON C.CompanySeq = @CompanySeq
                               AND C.SlipSeq    = B.SlipSeq
                               AND C.RemSeq     = 1002
     WHERE A.EmpSeq = 0

    --================================================================================================================================            
    -- 원가항목조회      
    --================================================================================================================================          
    CREATE TABLE #tmp_SlipCostItemName
    (ID_Count       INT IDENTITY(1,1),
     SMCostItemKind INT, --원가항목구분
     CostItemSeq    INT, --원가항목코드
     CostItemName   NVARCHAR(400), --원가항목
     SlipSeq        INT
    )

    INSERT INTO #tmp_SlipCostItemName(SMCostItemKind, CostItemSeq, SlipSeq)
    SELECT SMCostItemKind, CostItemSeq, SlipSeq FROM #TempFixedCol WHERE SMCostItemKind > 0 
    EXEC _SESMBGetCostIemNameData @CompanySeq, @LanguageSeq,149, '#tmp_SlipCostItemName','CostItemName'
    --================================================================================================================================            
    -- 원가항목조회끝    
    --================================================================================================================================         
              
    --======================
    -- 비용배부
    --======================
        SELECT A.SlipSeq,            
               A.CostDeptSeq,            
               A.CostCCtrSeq,            
               CASE            
                    WHEN X.Cnt > 1 THEN D.DeptName + '◐' + CAST(X.Cnt AS NVARCHAR)            
 ELSE D.DeptName            
               END          AS CostDeptName,            
               CASE            
                    WHEN Y.Cnt > 1 THEN C.CCtrName + '◐' + CAST(Y.Cnt AS NVARCHAR)            
                    ELSE C.CCtrName
               END          AS CostCCtrName,            
               X.Cnt        AS SlipCostCnt            
          INTO #tmp2            
          FROM _TACSlipCost AS A            
               INNER JOIN (            
                            SELECT A.SlipSeq, MIN(A.Serl) AS Serl, COUNT(*) AS Cnt            
                              FROM _TACSlipCost AS A WITH(NOLOCK)           
                             WHERE A.CompanySeq = @CompanySeq            
                               AND EXISTS (SELECT * FROM #TempFixedCol WHERE SlipSeq = A.SlipSeq)            
                             GROUP BY A.SlipSeq            
                          ) AS X            
                       ON X.SlipSeq = A.SlipSeq
                      AND X.Serl    = A.Serl
               LEFT JOIN (            
                            SELECT A.SlipSeq, MIN(A.Serl) AS Serl, COUNT(*) AS Cnt            
                              FROM _TACSlipCost AS A WITH(NOLOCK)           
                             WHERE A.CompanySeq = @CompanySeq
                               AND CostCCtrSeq <> 0
                               AND EXISTS (SELECT * FROM #TempFixedCol WHERE SlipSeq = A.SlipSeq)            
                             GROUP BY A.SlipSeq            
                          ) AS Y            
                       ON Y.SlipSeq = A.SlipSeq
                      AND Y.Serl    = A.Serl
               LEFT JOIN _TDACCtr AS C WITH(NOLOCK)            
                      ON C.CompanySeq   = A.CompanySeq            
                     AND C.CCtrSeq      = A.CostCCtrSeq            
               LEFT JOIN _TDADept AS D WITH(NOLOCK)            
                      ON D.CompanySeq   = A.CompanySeq            
                     AND D.DeptSeq      = A.CostDeptSeq            
         WHERE A.CompanySeq = @CompanySeq            
                
                
                
          
        --================================================================================================================================              
        -- 변동컬럼값 조회(관리항목)            
        --================================================================================================================================            
        -- 코드헬프의 명칭을 가져오기 위한 임시테이블 생성            
        CREATE TABLE #tmp_SlipRemValue            
        (            
            SlipSeq         INT,            
            RemSeq          INT,            
            --RemName         NVARCHAR(100),            
            Seq             INT,            
            RemValText      NVARCHAR(100),            
            CellType        NVARCHAR(50),            
            IsDrEss         NCHAR(1),            
            IsCrEss         NCHAR(1),            
            Sort            INT,
            CustNo          NVARCHAR(200) --거래처번호          
        )     
        
        CREATE CLUSTERED INDEX IDX_#tmp_SlipRemValue ON #tmp_SlipRemValue(SlipSeq,Sort)         
                
        -- 임시테이블에 명칭을 가져오기 위한 키값을 넣어주고            
        INSERT INTO #tmp_SlipRemValue            
            SELECT A.SlipSeq,            
                   B.RemSeq,            
                   --D.RemName,            
                   B.RemValSeq,            
                   B.RemValText,            
                   CASE D.SMInputType            
                        WHEN 4016001 THEN 'enText'            
                        WHEN 4016002 THEN 'enCodeHelp'            
                        WHEN 4016003 THEN 'enFloat'            
                        WHEN 4016004 THEN 'enFloat'            
                        WHEN 4016005 THEN 'enDate'            
                        WHEN 4016006 THEN 'enText'            
                        WHEN 4016007 THEN 'enFloat'            
                        ELSE 'enText'            
                   END AS CellType,       -- 입력형태            
                   C.IsDrEss,            
                   C.IsCrEss,            
                   C.Sort, 
                   ''            
              FROM #TempFixedCol AS A            
                   INNER JOIN _TACSlipRem AS B WITH (NOLOCK)            
                           ON B.CompanySeq  = @CompanySeq            
                          AND B.SlipSeq     = A.SlipSeq            
                   INNER JOIN _TDAAccountSub AS C WITH (NOLOCK)            
                           ON C.CompanySeq  = B.CompanySeq            
                          AND C.AccSeq      = A.AccSeq            
                          AND C.RemSeq      = B.RemSeq 
--                          AND C.IsRpt       = '1'     -- 출력에 체크된것만       
                   INNER JOIN _TDAAccountRem AS D WITH (NOLOCK)            
                           ON D.CompanySeq  = B.CompanySeq            
                          AND D.RemSeq      = B.RemSeq            
                              
        -- 명칭을 가져온다.            
        -- 실행 후에는 ValueName 컬럼이 자동생성되어 진다.            
    
        EXEC _SUTACGetSlipRemData @CompanySeq, @LanguageSeq, '#tmp_SlipRemValue'   

    -- 날짜형식의 관리항목에 - 붙이기
    --UPDATE #tmp_SlipRemValue
    --   SET RemValue = CASE WHEN LEN(RTRIM(LTRIM(RemValue))) = 8 THEN 
    --                            LEFT(RemValue, 4) + '-' + SUBSTRING(RemValue, 5,2) + '-' + RIGHT(RemValue, 2)
    --                       WHEN LEN(RTRIM(LTRIM(RemValue))) = 6 THEN 
    --                            LEFT(RemValue, 4) + '-' + RIGHT(RemValue, 2)
    --                       ELSE RemValue END
    -- WHERE CellType = 'enDate'

    -- [관리항목] 기간 RemSeq 3013
    UPDATE #tmp_SlipRemValue
       SET RemValue = LEFT(RemValue, 8) + '-' + RIGHT(RemValue, 8)
     WHERE RemSeq = 3013  
       AND LEN(RemValue) = 16  
    -- [관리항목 입력형태] 기간 SMInputType 4016006
    UPDATE #tmp_SlipRemValue
       SET RemValue = LEFT(RemValue, 8) + '-' + RIGHT(RemValue, 8)
     WHERE RemSeq IN (SELECT RemSeq FROM _TDAAccountRem WITH (NOLOCK) WHERE SMInputType = 4016006 AND CompanySeq = @CompanySeq)
       AND LEN(RemValue) = 16
       
    ---- 부가세계정의 "공급가액" 금액 ","붙이는 FUNCTION사용 (_fnCOMCurrency)
    ---- 계정관리항목등록(시스템) 화면에서 숫자로 등록된 관리항목에도 "," 붙이는 FUNCTION 사용 (3120:부가세(구매카드), 3108:불공제세, 3125:수량(구매카드))
    --UPDATE #tmp_SlipRemValue
    --   SET RemValue     = dbo._fnCOMCurrency(RemValText,@KORDecimal)
    -- WHERE RemSeq IN (3002, 3003, 3009, 3107, 3120, 3108, 3125) -- 액면가액, 취득수량, 공급가액, 총비용, 부가세(구매카드), 불공제세, 수량(구매카드)
    
    -- [관리항목 입력형태] 금액 SMInputType 4016003
    UPDATE #tmp_SlipRemValue
       SET RemValue     = dbo._fnCOMCurrency(RemValText,@KORDecimal)
     WHERE RemSeq IN (SELECT RemSeq FROM _TDAAccountRem WITH (NOLOCK) WHERE SMInputType = 4016003 AND CompanySeq = @CompanySeq)  -- 금액을 사용하면 모두 자릿수 찍어주도록
     
    -- [관리항목] 외화공급가액 RemSeq 3113
    UPDATE #tmp_SlipRemValue
       SET RemValue     = dbo._fnCOMCurrency(RemValText,@FORDecimal)
     WHERE RemSeq IN (3113) -- 외화 공급가액
    -- [관리항목] 거래처
    UPDATE A
       SET A.CustNo = ISNULL(RTRIM(LTRIM(C.CustNo)),'')
      FROM #tmp_SlipRemValue AS A 
                JOIN _TACSlipRow AS B WITH(NOLOCK) 
                  ON B.CompanySeq = @CompanySeq
                 AND A.SlipSeq    = B.SlipSeq
     LEFT OUTER JOIN _TDACust    AS C WITH(NOLOCK)
                  ON C.CompanySeq = @CompanySeq
                 AND C.CustSeq    = A.Seq
     WHERE A.RemSeq = 1017    

    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- #tmp_SlipRemValue 의 RemValue 중 관리항목 사업자번호 (1013), 거래처(1017) 인 경우엔 이력에 따라 명칭을 가져올수 있도록 한다. 시작
    --------------------------------------------------------------------------------------------------------------------------------------------
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1013)
    BEGIN 
        UPDATE A
           SET A.RemValue    = CASE WHEN ISNULL(C.TaxNoAlias,'') = '' THEN A.RemValue    ELSE C.TaxNoAlias END,
               A.RemRefValue = CASE WHEN ISNULL(C.TaxNo     ,'') = '' THEN A.RemRefValue ELSE C.TaxNo      END
          FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow     AS B WITH(NOLOCK) 
                                        ON B.CompanySeq = @CompanySeq
                                       AND A.SlipSeq    = B.SlipSeq
                           LEFT OUTER JOIN _TDATaxUnitHist AS C WITH(NOLOCK) 
                                        ON C.CompanySeq = @CompanySeq
                                       AND C.TaxUnit    = A.Seq
                                       AND B.AccDate    BETWEEN C.FrDate AND C.ToDate       
         WHERE A.RemSeq = 1013
    END
       
    IF EXISTS ( SELECT 1 FROM #tmp_SlipRemValue WHERE RemSeq   = 1017)
    BEGIN
        UPDATE A
           SET A.RemValue    = CASE WHEN ISNULL(C.FullName,'') = '' THEN REPLACE(REPLACE(A.RemValue,'<','〈'),'>','〉') ELSE REPLACE(REPLACE(C.FullName,'<','〈'),'>','〉') END,
               A.RemRefValue = CASE WHEN ISNULL(C.BizNo   ,'') = '' THEN A.RemRefValue ELSE C.BizNo END
          FROM #tmp_SlipRemValue AS A JOIN _TACSlipRow     AS B WITH(NOLOCK)
                                        ON B.CompanySeq = @CompanySeq
                                       AND A.SlipSeq    = B.SlipSeq
                           LEFT OUTER JOIN _TDACustTaxHist AS C WITH(NOLOCK)
                                        ON C.CompanySeq = @CompanySeq
                                       AND C.CustSeq    = A.Seq
                                       AND B.AccDate    BETWEEN ISNULL(C.FrDate,'') AND ISNULL(C.ToDate,'29991231')                                                                  
         WHERE A.RemSeq = 1017    
    END 
    
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
    --------------------------------------------------------------------------------------------------------------------------------------------
    -- #tmp_SlipRemValue 의 RemValue 중 관리항목 사업자번호 (1013), 거래처(1017) 인 경우엔 이력에 따라 명칭을 가져올수 있도록 한다. 끝
    --------------------------------------------------------------------------------------------------------------------------------------------
    --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   
    
    -- 사업자번호에 '-' 넣기
    UPDATE #tmp_SlipRemValue    
       SET RemRefValue = dbo._FCOMMaskConv(@EnvValue,RemRefValue)
      FROM #tmp_SlipRemValue AS A    
                JOIN _TCACodeHelpData AS B WITH(NOLOCK) ON A.CodeHelpSeq = B.CodeHelpSeq    
     WHERE B.CompanySeq = 0    
       AND B.RefColumnName IN ('BizNo', 'TaxNo')    
       AND ISNULL(A.RemRefValue, '') <> ''    
	
	DECLARE @EnvValue4705	INT
	 -- [<분개전표>  전표 출력시 개인거래처의 주민등록번호 출력함] 환경설정의 EnvSeq = 4705, 해당 환경설정의 값을 불러와서 저장하기 위하여 선언한 변수. -- 2015.05.21 By sryoun
    SELECT @EnvValue4705 = ISNULL(CAST(EnvValue AS INT), 0) FROM _TCOMEnv WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND EnvSeq = 4705
	-- 해당 환경설정이 체크박스로 되어있는 경우 1의 값이 설정되어 있는 것과 코드도움으로 되어있어 Seq가 4576001로 설정된 것의 결과는 같으므로 번거로움을 피하기위해 변수의 값을 아래와 같이 설정해줌.  -- 2015.05.21 By sryoun
	IF @EnvValue4705 = 1
	BEGIN
		SET @EnvValue4705 = 4576001
	END
		
	IF @EnvValue4705 > 0
	BEGIN
    -- 환경설정에 '전표 출력시 개인거래처의 주민등록번호 출력함'이 체크 되어 있는 경우에만 주민번호 가져가기.  
           -- 사업자번호가 없다면 주민번호 가져오기  
        IF EXISTS (SELECT RemRefValue FROM #tmp_SlipRemValue WHERE RemSeq = 1017 AND RemRefValue = '')     
		BEGIN  
			UPDATE #tmp_SlipRemValue  
               SET RemRefValue = (CASE @EnvValue4705 WHEN 4576001 THEN dbo._FCOMMASKConv(@PersonId, dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq))	-- 환경설정에 입력된 코드도움 값의 Seq = 4576001인 것은 주민등록번호 전체를 보여주는 것이고,
													 WHEN 4576002 THEN RIGHT(dbo._FCOMMASKConv(@PersonId, dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq)), 6) + '-*******'	-- 코드도움 값의 Seq = 4576002인 것은 주민등록번호 앞자리만 보여주는 것 -- 2015.05.21 By sryoun
													 ELSE '' END)
			  FROM #tmp_SlipRemValue AS A JOIN _TDACust AS B WITH(NOLOCK) ON A.Seq = B.CustSeq
             WHERE B.CompanySeq = @CompanySeq  
               AND A.RemSeq = 1017      -- 거래처
			   AND A.RemRefValue = ''	-- 사업자번호가 존재하지 않는 것
        END  
	END

    -----------------------------------------------
    -- 페이지 관련 정보 처리 시작
    -----------------------------------------------
    SELECT @MaxCnt      = COUNT(*) FROM #Temp
    SELECT @Cnt         = 0
    WHILE (@Cnt < @MaxCnt)          
    BEGIN
			SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt
			UPDATE A
			   SET A.RowIDX = B.RowIDX
		     FROM #TempFixedCol AS A JOIN (SELECT ROW_NUMBER() OVER(ORDER BY RowIDX)-1 AS RowIDX, SlipMstSeq, SlipSeq
											 FROM  #TempFixedCol
											WHERE SlipMstSeq = @SlipMstSeq) AS B ON A.SlipMstSeq	= B.SlipMstSeq
																				AND A.SlipSeq		= B.SlipSeq
				
			UPDATE A
		       SET A.SumDrAmt = B.SumDrAmt,
				   A.SumCrAmt = B.SumCrAmt,
				   A.MaxIDX   = B.MaxIDX
		      FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt) AS SumDrAmt, 
												   SUM(CrAMt) AS SumCrAmt, 
												   MAX(RowIDX) AS MaxIDX,
												   SlipMstSeq
										      FROM #TempFixedCol
										     WHERE SlipMstSeq = @SlipMstSeq
										     GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq

			UPDATE A
		       SET A.DrSumFirstFage = B.DrSumFirstFage,
				   A.CrSumFirstFage = B.CrSumFirstFage
		      FROM #TempFixedCol AS A JOIN (SELECT SUM(DrAmt) AS DrSumFirstFage, 
												   SUM(CrAMt) AS CrSumFirstFage,
												   SlipMstSeq
										      FROM  #TempFixedCol
										     WHERE SlipMstSeq = @SlipMstSeq
										     AND CONVERT(INT, RIGHT(REPLACE(RTRIM(RowNo), '.', ''), 2)) < 10	-- 전표행번호에 다른 문자는 안들어가는데 '.'은 들어가고 있음, 우선 리플레이스 처리로 진행 2015.12.14. by shpark
										     GROUP BY SlipMstSeq) AS B ON A.SlipMstSeq = B.SlipMstSeq
					
			UPDATE A
		       SET A.IsOnlyOnPage = CASE WHEN B.TotCnt < 10 THEN '1' ELSE '0' END
		      FROM #TempFixedCol AS A JOIN (SELECT COUNT(*) AS TotCnt,
												    SlipMstSeq
										      FROM  #TempFixedCol
										     WHERE SlipMstSeq = @SlipMstSeq
										     GROUP BY SlipMstSeq
										     ) AS B ON A.SlipMstSeq = B.SlipMstSeq					
			
			SELECT @Cnt = @Cnt + 1
    END
    -- 페이지 관련 정보 처리 끝
    
	--거래처를 제외한 관리항목 순차적으로 담기
	SELECT *,RANK() OVER (PARTITION BY SlipSeq ORDER BY Sort) AS Sort2
	  INTO #tmp_SlipRemValue2
	  FROM #tmp_SlipRemValue
	 WHERE RemSeq NOT IN(1017,1013)

	--합계 한글화
	DECLARE @ABSHapAmt DECIMAL(19,5),
			@HanAmt NVARCHAR(100)

	SELECT @ABSHapAmt = ABS(SUM(CrAmt)) FROM #TempFixedCol

    EXEC _SDAGetAmtHan @ABSHapAmt , @HanAmt OUTPUT 


    -----------------------------
    -- #Temp_Detail
    -----------------------------
        SELECT A.MaxIDX,    
               A.RowIDX,    
               LEFT(RIGHT(MstSlip.AccDate, 4),2) +'/'+ RIGHT(RIGHT(MstSlip.AccDate, 4),2) AS AccDate, 
               LEFT(MstSlip.AccDate,4) + '.  ' + SUBSTRING(MstSlip.AccDate,5,2) + '.  ' + RIGHT(MstSlip.AccDate,2) + '.'  AS OrgAccDate,     
               @CurrDate AS CurrDate,    
               ISNULL(MstSlip.RegDeptName,'') AS RegDeptName,    
               ISNULL(MstSlip.RegEmpName,'') AS RegEmpName,          
               ISNULL(MstSlip.SetSlipNo,'') AS SetSlipNo,       
               A.SlipMstSeq,
               ISNULL(MstSlip.SlipKind, 0) AS SlipKind,    
               ISNULL(MstSlip.SlipKindName, '') AS SlipKindName,    
               ISNULL(MstSlip.RegEmpSeq,0) AS RegEmpSeq,    
               ISNULL(MstSlip.RegDeptSeq,0) AS RegDeptSeq,    
               ISNULL(REPLACE(REPLACE(MstSlip.Remark,'<','〈'),'>','〉'),'') AS Remark,           -- 적요            
               ISNULL(MstSlip.SMCurrStatus,0) AS SMCurrStatus,    
               ISNULL(MstSlip.AptDate,'')   AS AptDate,    
			   ISNULL(MstSlip.AptEmpSeq,0) AS AptEmpSeq,    
               ISNULL(MstSlip.AptDeptSeq,0) AS AptDeptSeq,    
               ISNULL(MstSlip.AptRemark,'') AS AptRemark,    
               ISNULL(MstSlip.SMCheckStatus,0) AS SMCheckStatus,    
               ISNULL(MstSlip.CheckOrigin,'') AS CheckOrigin,  
               ISNULL(MstSlip.SetEmpSeq,0)  AS SetEmpSeq,   
               ISNULL(MstSlip.SetDeptSeq,0) AS SetDeptSeq,    
               ISNULL(MstSlip.SlipUnitName,'') AS SlipUnitName,  
               ISNULL(MstSlip.SlipAppNo,'') AS SlipAppNo,
               ISNULL(MstSlip.SlipMstID,'') AS SlipMstID,
               CASE WHEN MstSlip.IsSet = '1' THEN MstSlip.AccDate ELSE '' END  AS AccDateFull,    -- 승인일
               A.RowIDX + 1 AS RowNum,            
               A.SlipSeq,               -- 전표코드            
               A.SlipID,                -- 전표기표번호            
               A.AccUnit,               -- 회계단위         
               ISNULL(Acc.AccUnitName,'') AS AccUnitName,         
               A.SlipUnit,              -- 전표관리단위            
               A.SlipNo,                -- 기표일련번호            
               A.RowNo,                 -- 행번호            
               A.RowSlipUnit,           -- 행별전표관리단위            
               A.AccSeq,                -- 계정코드            
               A.UMCostType,            -- 비용구분            
               A.SMDrOrCr,              -- 차대구분            
               A.DrAmt,                 -- 차변금액            
               A.CrAmt,                 -- 대변금액            
               A.DrForAmt,              -- 외화차변금액            
               A.CrForAmt,           -- 외화대변금액            
               A.CurrSeq,               -- 통화코드            
               A.ExRate,				-- 환율            
               A.DivExRate,             -- 나누기 환율            
               A.EvidSeq,               -- 증빙코드            
               A.TaxKindSeq,            -- 세무구분코드            
               A.NDVATAmt,              -- 불공제세액            
               A.CashItemSeq,           -- 현금흐름표과목코드            
               ISNULL(L.SMCostItemKind,0) AS SMCostItemKind,        -- 원가항목유형            
               ISNULL(L.CostItemSeq,0) AS CostItemSeq,           -- 원가항목            
               A.Summary,               -- 적요            
               ISNULL(A.BgtDeptSeq,0) AS BgtDeptSeq,            -- 예산부서            
               ISNULL(A.BgtCCtrSeq,0) AS BgtCCtrSeq,            -- 예산활동센터            
               ISNULL(A.BgtSeq,0) AS BgtSeq,                -- 예산과목코드            
               ISNULL(A.IsSet,'') AS IsSet,                 -- 승인여부            
               --ISNULL(A.AccName,'') AS AccName,        -- 계정과목            
               ISNULL(A.AccNo, '') AS AccNo,                 -- 계정번호            
               ISNULL(A.CurrName,'') AS CurrName,              -- 통화코드     
               ISNULL(A.CurrUnit,'') AS CurrUnit,              -- 통화표시단위         
               ISNULL(A.EvidName, '') AS EvidName,              -- 증빙코드            
               ISNULL(A.TaxKindName,'') AS TaxKindName,           -- 세무구분코드            
               ISNULL(A.CashItemName,'') AS CashItemName,         -- 현금흐름표과목코드            
               ISNULL(A.SMCostItemKindName,'') AS SMCostItemKindName,    -- 원가항목유형            
               ISNULL(L.CostItemName, '') AS CostItemName,          -- 원가항목            
               A.BgtDeptName,   -- 예산부서            
               A.BgtCCtrName,  -- 예산활동센터            
               A.BgtName,               -- 예산과목코드            
               ISNULL(A.SMInOrOut,0) AS SMInOrOut,            
               ISNULL(A.IsCash,'') AS IsCash,           -- 출납처리여부            
               ISNULL(A.CashDate,'') AS CashDate,            -- 출납예정일            
               ISNULL(A.SMCashMethod,0) AS SMCashMethod,        -- 출납방법            
               ISNULL(A.CashOffSerl,0) AS CashOffSerl,            
               ISNULL(A.OnSlipSeq,0) AS OnSlipSeq,            
               ISNULL(A.OnSlipID,'') AS OnSlipID,            
               A.SMAccDrOrCr,            
               A.IsAnti,            
               A.IsSlip,            
               A.IsLevel2,            
               A.IsZeroAllow,            
               A.IsEssForAmt,            
               A.SMIsEssEvid,            
               A.IsEssCost,            
               A.IsCostTrn,            
               A.SMIsUseRNP,            
               A.SMRNPMethod,            
               A.SMBgtType,            
               A.IsCashAcc,            
               A.SMCashItemKind,            
               A.IsFundSet,            
               A.IsAutoExec,            
               A.SMAccType,            
               A.SMAccKind,            
               A.OffRemSeq,            
               A.BgtRemSeq,            
               A.RemSeq1,            
               A.RemSeq2,            
               A.CostTypeCount,            
               ISNULL(X.LinkedKeyXMLData,'') AS LinkedKeyXMLData,            
               ISNULL(C.MinorName,'')  AS UMCostTypeName,            
               (            
                   SELECT *            
                    FROM _TACSlipCost            
                    WHERE CompanySeq    = @CompanySeq             
                      AND SlipSeq       = A.SlipSeq         
                      FOR XML AUTO, ELEMENTS            
               ) AS SlipCostXmlData,            
               ISNULL(B.CostDeptName,'') AS CostDeptName,
               ISNULL(REPLACE(REPLACE(B.CostCCtrName,'<','〈'),'>','〉'),'') AS CostCCtrName,
               B.CostDeptSeq,            
               B.CostCCtrSeq,            
               B.SlipCostCnt,            
               A.CoCustSeq,            
               ISNULL(REPLACE(REPLACE(A.CoCustName,'<','〈'),'>','〉'),'') AS CoCustName,
               G.RemValue,
               -- 거래처 관리항목의 경우 (사업자번호)도 출력될 수 있도록..    
               ISNULL(CASE WHEN D.RemSeq IN (1017, 1013) THEN RTRIM(D.RemValue) + (CASE WHEN ISNULL(D.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(D.RemRefValue),'<','〈'),'>','〉') + ')' END)     
                    ELSE REPLACE(REPLACE(ISNULL(D.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue1,        
               ISNULL(CASE WHEN E.RemSeq IN (1017, 1013) THEN RTRIM(E.RemValue) + (CASE WHEN ISNULL(E.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(E.RemRefValue),'<','〈'),'>','〉') + ')' END)         
                    ELSE REPLACE(REPLACE(ISNULL(E.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue2,        
               ISNULL(CASE WHEN F.RemSeq IN (1017, 1013) THEN RTRIM(F.RemValue) + (CASE WHEN ISNULL(F.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(F.RemRefValue),'<','〈'),'>','〉') + ')' END)     
                    ELSE REPLACE(REPLACE(ISNULL(F.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue3,        
               ISNULL(CASE WHEN G.RemSeq IN (1017, 1013) THEN RTRIM(G.RemValue) + (CASE WHEN ISNULL(G.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(G.RemRefValue),'<','〈'),'>','〉') + ')' END)     
                    ELSE REPLACE(REPLACE(ISNULL(G.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue4,     
               ISNULL(CASE WHEN H.RemSeq IN (1017, 1013) THEN RTRIM(H.RemValue) + (CASE WHEN ISNULL(H.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(H.RemRefValue),'<','〈'),'>','〉') + ')' END)     
                    ELSE REPLACE(REPLACE(ISNULL(H.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue5,    
               ISNULL(CASE WHEN I.RemSeq IN (1017, 1013) THEN RTRIM(I.RemValue) + (CASE WHEN ISNULL(I.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(I.RemRefValue),'<','〈'),'>','〉') + ')' END)     
                    ELSE REPLACE(REPLACE(ISNULL(I.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue6,    
               ISNULL(CASE WHEN J.RemSeq IN (1017, 1013) THEN RTRIM(J.RemValue) + (CASE WHEN ISNULL(J.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(J.RemRefValue),'<','〈'),'>','〉') + ')' END)    
                    ELSE REPLACE(REPLACE(ISNULL(J.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue7,    
               ISNULL(CASE WHEN K.RemSeq IN (1017, 1013) THEN RTRIM(K.RemValue) + (CASE WHEN ISNULL(K.RemRefValue, '') = '' THEN ''     
                                                                        ELSE ' (' + REPLACE(REPLACE(RTRIM(K.RemRefValue),'<','〈'),'>','〉') + ')' END)    
                    ELSE REPLACE(REPLACE(ISNULL(K.RemValue,''),'<','〈'),'>','〉') END,'') AS RemValue8,  
                    
               --ISNULL(CASE WHEN D.RemSeq IN (1017, 1001) THEN RTRIM(D.RemRefValue) ELSE '' END, '') AS RemValueNo1,        
               --ISNULL(CASE WHEN E.RemSeq IN (1017, 1001) THEN RTRIM(E.RemRefValue) ELSE '' END, '') AS RemValueNo2,          
               --ISNULL(CASE WHEN F.RemSeq IN (1017, 1001) THEN RTRIM(F.RemRefValue) ELSE '' END, '') AS RemValueNo3,                
               --ISNULL(CASE WHEN G.RemSeq IN (1017, 1001) THEN RTRIM(G.RemRefValue) ELSE '' END, '') AS RemValueNo4,          
               --ISNULL(CASE WHEN H.RemSeq IN (1017, 1001) THEN RTRIM(H.RemRefValue) ELSE '' END, '') AS RemValueNo5,         
               --ISNULL(CASE WHEN I.RemSeq IN (1017, 1001) THEN RTRIM(I.RemRefValue) ELSE '' END, '') AS RemValueNo6,        
               --ISNULL(CASE WHEN J.RemSeq IN (1017, 1001) THEN RTRIM(J.RemRefValue) ELSE '' END, '') AS RemValueNo7,        
               --ISNULL(CASE WHEN K.RemSeq IN (1017, 1001) THEN RTRIM(K.RemRefValue) ELSE '' END, '') AS RemValueNo8,                    
                    
                REPLACE(REPLACE(ISNULL(D.RemName,''),'<','〈'),'>','〉') AS RemName1,  
                REPLACE(REPLACE(ISNULL(E.RemName,''),'<','〈'),'>','〉') AS RemName2,
                REPLACE(REPLACE(ISNULL(F.RemName,''),'<','〈'),'>','〉') AS RemName3,
                REPLACE(REPLACE(ISNULL(G.RemName,''),'<','〈'),'>','〉') AS RemName4,
                REPLACE(REPLACE(ISNULL(H.RemName,''),'<','〈'),'>','〉') AS RemName5,
                REPLACE(REPLACE(ISNULL(I.RemName,''),'<','〈'),'>','〉') AS RemName6,
                REPLACE(REPLACE(ISNULL(J.RemName,''),'<','〈'),'>','〉') AS RemName7,
                REPLACE(REPLACE(ISNULL(K.RemName,''),'<','〈'),'>','〉') AS RemName8,
            CASE WHEN ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), '') = '' 
                 THEN (ISNULL(C3.PayBankName, '') + ' ' + CASE WHEN ISNULL(dbo._FCOMDecrypt(EmpBank.AccNo, '_THRBasEmpAccNo', 'AccNo', @CompanySeq), '') = '' THEN '' 
                                                               ELSE '(' + RTRIM(dbo._FCOMDecrypt(EmpBank.AccNo, '_THRBasEmpAccNo', 'AccNo', @CompanySeq)) + ')' 
                                                          END) -- _THRBasBank
                 ELSE ISNULL(C2.MinorName,'') + CASE WHEN ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), '') = '' THEN '' 
                                                     ELSE '('+RTRIM(ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), ''))+')' 
         END
            END AS CustInfo,            -- '출납거래처정보'
            ISNULL(A.SMCashMethodName,'') AS SMCashMethodName ,    
            A.SumDrAmt,    
            A.SUMCrAmt  ,
            A.SlipNo AS SlipNoOne,
            CASE WHEN CONVERT(INT, RIGHT(REPLACE(RTRIM(A.RowNo), '.', ''), 2)) < 10 THEN '1'	-- 전표행번호에 다른 문자는 안들어가는데 '.'은 들어가고 있음, 우선 리플레이스 처리로 진행 2015.12.14. by shpark
            ELSE '0' END IsFirstPage,
			A.DrSumFirstFage,
			A.CrSumFirstFage,
			A.IsOnlyOnPage,
            MstSlip.RTRegAccDate  AS RegDateTime, -- 전표 작성일
            MstSlip.RegAccDate                         AS RegDate    , -- 기표일    
            A.S_AccUnitName                            AS S_AccUnitName, -- 본지점 반제전표인 경우 발생전표의 회계단위명
            ISNULL(cctr.Remark, '')                                AS CCtrRemark,
			ISNULL(A.TopUserName,'') AS TopUserName,
            CASE WHEN ISNULL(C.MinorName, '') <> '' THEN A.AccName + '(' + RTRIM(ISNULL(C.MinorName, '')) + ')'
                 ELSE A.AccName
            END AS AccName2,
            ISNULL(MstSlip.SetEmpName,'') AS SetEmpName,
            CASE WHEN ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), '') = '' 
                    THEN (ISNULL(C4.PayBankName, '') + ' ' + CASE WHEN ISNULL(dbo._FCOMDecrypt(EmpBankFBS.AccNo, '_THRBasEmpAccNo', 'AccNo', @CompanySeq), '') = '' THEN '' 
                                                                  ELSE '(' + RTRIM(dbo._FCOMDecrypt(EmpBankFBS.AccNo, '_THRBasEmpAccNo', 'AccNo', @CompanySeq)) + ')' END) -- _THRBasBank
                 ELSE
                    ISNULL(C2.MinorName,'') + CASE WHEN ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), '') = '' THEN '' 
                                                   ELSE '('+RTRIM(ISNULL(dbo._FCOMDecrypt(Bank.BankAccNo, '_TDACustBankAcc', 'BankAccNo', @CompanySeq), ''))+')' END
            END AS CustInfoFBS,
            MstSlip.RegDateTime  AS FullRegDateTime,    --전표작성일시분초
            MstSlip.ApprovalDateTime AS ApprovalDateTime,   --실제승인일시분초
            MstSlip.RTSetAccDate     AS RTSetAccDate,       --8자리의 실제승인일자            
            CASE WHEN D.RemSeq = 1017 THEN D.CustNo
                 WHEN E.RemSeq = 1017 THEN E.CustNo
                 WHEN F.RemSeq = 1017 THEN F.CustNo
                 WHEN G.RemSeq = 1017 THEN G.CustNo
                 WHEN H.RemSeq = 1017 THEN H.CustNo
                 WHEN I.RemSeq = 1017 THEN I.CustNo
                 WHEN J.RemSeq = 1017 THEN J.CustNo
                 WHEN K.RemSeq = 1017 THEN K.CustNo END AS CustNo,    
            CASE WHEN D.RemSeq = 1013 THEN REPLACE(REPLACE(D.RemValue,'<','〈'),'>','〉')
                 WHEN E.RemSeq = 1013 THEN REPLACE(REPLACE(E.RemValue,'<','〈'),'>','〉')
                 WHEN F.RemSeq = 1013 THEN REPLACE(REPLACE(F.RemValue,'<','〈'),'>','〉')
                 WHEN G.RemSeq = 1013 THEN REPLACE(REPLACE(G.RemValue,'<','〈'),'>','〉')
                 WHEN H.RemSeq = 1013 THEN REPLACE(REPLACE(H.RemValue,'<','〈'),'>','〉')
                 WHEN I.RemSeq = 1013 THEN REPLACE(REPLACE(I.RemValue,'<','〈'),'>','〉')
                 WHEN J.RemSeq = 1013 THEN REPLACE(REPLACE(J.RemValue,'<','〈'),'>','〉')
                 WHEN K.RemSeq = 1013 THEN REPLACE(REPLACE(K.RemValue,'<','〈'),'>','〉') END AS TaxNoAlias,	-- 사업자번호명            
                 
                 REPLACE(REPLACE(O.RemRefValue,'<','〈'),'>','〉') AS RemEmpId,
                 REPLACE(REPLACE(M.RemRefValue,'<','〈'),'>','〉') AS RemBizNo,
                 REPLACE(REPLACE(O.RemValue   ,'<','〈'),'>','〉') AS RemEmpName,
                 REPLACE(REPLACE(M.RemValue   ,'<','〈'),'>','〉') AS RemCustName,
                 @KORDecimal    AS KoDec,       -- 환경설정에 설정된 자릿수에 따라 출력되도록 하기 위해 추가함. 2016.04.18 (서비스요청번호 : 201604160007) by sryoun.
                 @FORDecimal    AS ForDec,      -- 환경설정에 설정된 자릿수에 따라 출력되도록 하기 위해 추가함. 2016.04.18 (서비스요청번호 : 201604160007) by sryoun.
                 @ExraDecimal   AS ExDec        -- 환경설정에 설정된 자릿수에 따라 출력되도록 하기 위해 추가함. 2016.04.18 (서비스요청번호 : 201604160007) by sryoun.
				 ,CASE WHEN ISNULL(A.EvidSeq,0) <> 0 THEN ISNULL(A.EvidName, '')
				       ELSE (CASE WHEN ISNULL(A.OnSlipSeq,0) <> 0 THEN '발생전표 : ' + ISNULL(A.OnSlipID,0)
								  ELSE ''
								   END)
						END AS OnSlipID2
				 ,INI.Initial
				 ,ISNULL(A.AccName,'') AS AccName        -- 계정과목
				 ,ISNULL(A.AccName3,'') AS AccName3        -- 계정과목
				 ,D.RemSeq
               ,REPLACE(REPLACE(ISNULL(D1.RemValue,''),'<','〈'),'>','〉') AS RemValue12       
               ,REPLACE(REPLACE(ISNULL(E1.RemValue,''),'<','〈'),'>','〉') AS RemValue22      
               ,REPLACE(REPLACE(ISNULL(F1.RemValue,''),'<','〈'),'>','〉') AS RemValue32
			   ,@HanAmt AS HanAmt
               ,CASE WHEN ISNULL(A.AccName3,'') = '' THEN ISNULL(A.AccName,'') ELSE ISNULL(A.AccName3,'') END + 
                CASE WHEN ISNULL(C.MinorName,'') = '' THEN '' ELSE ' (' END  + 
                ISNULL(C.MinorName,'') + 
                CASE WHEN ISNULL(C.MinorName,'') = '' THEN '' ELSE ')' END AS AccUMCostName




          INTO #Temp_Detail 
          FROM #TempFixedCol AS A            
               LEFT JOIN #tmp2 AS B            
                      ON B.SlipSeq      = A.SlipSeq            
               LEFT JOIN _TACSlipLinkedData AS X WITH (NOLOCK)            
                      ON X.CompanySeq   = @CompanySeq            
                     AND X.SlipSeq      = A.SlipSeq            
               LEFT JOIN _TDAUMinor AS C WITH(NOLOCK)            
                      ON C.CompanySeq   = @CompanySeq            
                     AND C.MinorSeq     = A.UMCostType                  
               LEFT OUTER JOIN #Result_tmp AS MstSlip ON A.SlipMstSeq = MstSlip.SlipMstSeq          
               LEFT OUTER JOIN #tmp_SlipRemValue AS D ON A.SlipSeq = D.SlipSeq AND D.Sort = 1        
               LEFT OUTER JOIN #tmp_SlipRemValue AS E ON A.SlipSeq = E.SlipSeq AND E.Sort = 2        
               LEFT OUTER JOIN #tmp_SlipRemValue AS F ON A.SlipSeq = F.SlipSeq AND F.Sort = 3        
               LEFT OUTER JOIN #tmp_SlipRemValue AS G ON A.SlipSeq = G.SlipSeq AND G.Sort = 4        
               LEFT OUTER JOIN #tmp_SlipRemValue AS H ON A.SlipSeq = H.SlipSeq AND H.Sort = 5        
               LEFT OUTER JOIN #tmp_SlipRemValue AS I ON A.SlipSeq = I.SlipSeq AND I.Sort = 6        
               LEFT OUTER JOIN #tmp_SlipRemValue AS J ON A.SlipSeq = J.SlipSeq AND J.Sort = 7        
               LEFT OUTER JOIN #tmp_SlipRemValue AS K ON A.SlipSeq = K.SlipSeq AND K.Sort = 8               
               LEFT OUTER JOIN #tmp_SlipRemValue AS O ON A.SlipSeq = O.SlipSeq AND O.RemSeq = 1002      -- 사원
               LEFT OUTER JOIN #tmp_SlipRemValue AS M ON A.SlipSeq = M.SlipSeq AND M.RemSeq = 1017      -- 거래처
               LEFT OUTER JOIN #tmp_SlipCostItemName AS L ON A.SlipSeq = L.SlipSeq                                                  -- 원가항목
               LEFT OUTER JOIN _TDAAccUnit AS Acc WITH (NOLOCK) ON A.AccUnit = Acc.AccUnit AND Acc.CompanySeq = @CompanySeq         -- 회계단위      
               LEFT OUTER JOIN _TDACCtr    AS cctr WITH(NOLOCK) ON cctr.CompanySeq = @CompanySeq AND A.BgtCCtrSeq = cctr.CCtrSeq    -- 예산 활동센터
               -- 거래처 지급계좌  
               LEFT OUTER JOIN _TDACustBankAcc AS bank WITH(NOLOCK) ON bank.CompanySeq = @CompanySeq
                                                                   AND bank.CustSeq    = A.CustSeq
                                                                   AND bank.IsDefault  = '1' 
                                                                   AND bank.CustSeq   <> 0
               LEFT OUTER JOIN _TDAUMinor  AS C2 WITH(NOLOCK) ON bank.CompanySeq = C2.CompanySeq AND bank.UMBankHQ = C2.MinorSeq    -- 거래처 지급계좌의 금융기관
               -- 사원별계좌 (주계좌)
               LEFT OUTER JOIN _THRBasEmpAccNo AS EmpBank WITH(NOLOCK) ON EmpBank.CompanySeq = @CompanySeq      -- 사원별계좌(주계좌)
                                                                      AND EmpBank.EmpSeq     = A.EmpSeq
                                                                      AND EmpBank.UMAccNoType = 3098001 -- 주계좌
               LEFT OUTER JOIN _THRBasBank     AS C3      WITH(NOLOCK) ON C3.CompanySeq = @CompanySeq           -- 사원별계좌(주계좌)의 급여용 은행
                                                                      AND C3.PayBankSeq = EmpBank.PayBankSeq
               -- 사원별계좌 (이체전송설정계좌)
               LEFT OUTER JOIN _TCOMEnvAccFBS AS AccFBS WITH(NOLOCK) ON AccFBS.CompanySeq = @CompanySeq             -- 이체전송 - 사원등록계좌 - 계좌종류(주계좌/보조계좌/비용계좌)
                                                                    AND AccFBS.AccSeq     = A.AccSeq 
               LEFT OUTER JOIN _THRBasEmpAccNo AS EmpBankFBS WITH(NOLOCK) ON EmpBankFBS.CompanySeq  = @CompanySeq   -- 사원별계좌(이체전송설정계좌)
                           AND EmpBankFBS.EmpSeq      = A.EmpSeq
                                                                         AND EmpBankFBS.UMAccNoType = AccFBS.SMBankAccClass
               LEFT OUTER JOIN _THRBasBank     AS C4         WITH(NOLOCK) ON C4.CompanySeq = @CompanySeq            -- 사원별계좌(이체전송설정계좌)의 급여용은행
                                                                         AND C4.PayBankSeq = EmpBankFBS.PayBankSeq
			   LEFT OUTER JOIN _TCOMUnitInitial AS INI WITH(NOLOCK) ON INI.CompanySeq = @CompanySeq
																   AND MstSlip.RegDeptSeq = INI.Unit
																   AND INI.SMInitialUnit = 1033005
               LEFT OUTER JOIN #tmp_SlipRemValue2 AS D1 ON A.SlipSeq = D1.SlipSeq AND D1.Sort2 = 1        
               LEFT OUTER JOIN #tmp_SlipRemValue2 AS E1 ON A.SlipSeq = E1.SlipSeq AND E1.Sort2 = 2        
               LEFT OUTER JOIN #tmp_SlipRemValue2 AS F1 ON A.SlipSeq = F1.SlipSeq AND F1.Sort2 = 3   
         ORDER BY A.RowIDX   


    ---------------------------------------
    -- #Temp_DetailRepeat
    ---------------------------------------
    INSERT INTO #Temp_DetailRepeat(SlipMstSeq, DataBlock2)    
    SELECT  SlipMstSeq,
		    '<MaxIDX>' + ISNULL(CONVERT(NVARCHAR(20),MaxIDX),'') + '</MaxIDX>' +
            '<RowIDX>' + ISNULL(CONVERT(NVARCHAR(20),RowIDX),'') + '</RowIDX>' +
            '<AccDate>' + ISNULL(AccDate,'') + '</AccDate>' +    
            '<OrgAccDate>' + ISNULL(OrgAccDate,'') + '</OrgAccDate>' + 
            '<CurrDate>' + ISNULL(CurrDate,'') + '</CurrDate>' +    
            '<AccDatefull>' + ISNULL(AccDatefull,'') + '</AccDatefull>' + 
            '<RegDeptName>' + ISNULL(RegDeptName,'') + '</RegDeptName>' +     
            '<RegEmpName>' + ISNULL(RegEmpName,'') + '</RegEmpName>' +           
            '<SetSlipNo>' + ISNULL(SetSlipNo,'') + '</SetSlipNo>' +     
            '<SlipKindName>' + ISNULL(SlipKindName,'') + '</SlipKindName>' +   
            '<SlipKind>' + ISNULL(CONVERT(NVARCHAR(20),SlipKind),'') + '</SlipKind>' +   
            '<Remark>' + CONVERT(NVARCHAR(MAX), ISNULL(Remark,'')) + '</Remark>' +          -- 일정 길이 이상일 경우 + 시 4000으로 자동 짤림
            '<AptDate>' + ISNULL(AptDate,'') + '</AptDate>' +        
            '<AptRemark>' + ISNULL(AptRemark,'') + '</AptRemark>' +        
            '<IsSet>' + ISNULL(IsSet,'') + '</IsSet>' +      
            '<SetEmpName>' + ISNULL(SetEmpName,'') + '</SetEmpName>' +      
            '<SlipUnitName>' + ISNULL(SlipUnitName,'') + '</SlipUnitName>' +  
            '<SlipMstID>' + ISNULL(SlipMstID,'') + '</SlipMstID>' +  
            '<SlipAppNo>' + ISNULL(SlipAppNo,'') + '</SlipAppNo>' +             
            '<RowNum>' + ISNULL(CONVERT(NVARCHAR(20),RowNum),'') + '</RowNum>' +                   
            '<SlipID>' + ISNULL(SlipID,'') + '</SlipID>' +                    
            '<AccUnitName>' + ISNULL(AccUnitName,'') + '</AccUnitName>' +                         
            '<SlipNo>' + ISNULL(SlipNo,'') + '</SlipNo>' +                     
            '<RowNo>' + ISNULL(RowNo,'') + '</RowNo>' +                           
            '<DrAmt>' + ISNULL(CONVERT(NVARCHAR(20),DrAmt),'') + '</DrAmt>' +                  
            '<CrAmt>' + ISNULL(CONVERT(NVARCHAR(20),CrAmt),'') + '</CrAmt>' +                  
            '<DrForAmt>' + ISNULL(CONVERT(NVARCHAR(20),DrForAmt),'') + '</DrForAmt>' +                   
            '<CrForAmt>' + ISNULL(CONVERT(NVARCHAR(20),CrForAmt),'') + '</CrForAmt>' + 
            '<ExRate>' + ISNULL(CONVERT(NVARCHAR(20), dbo._fnCOMCurrency(ExRate,@Exradecimal)),'') + '</ExRate>' +               
            '<DivExRate>' + ISNULL(CONVERT(NVARCHAR(20),DivExRate),'') + '</DivExRate>' +   
            '<NDVATAmt>' + ISNULL(CONVERT(NVARCHAR(20),NDVATAmt),'') + '</NDVATAmt>' +               
            '<Summary>' + ISNULL(Summary,'') + '</Summary>' +              
            '<AccName>' + ISNULL(AccName,'') + '</AccName>' +                
            '<AccNo>' + ISNULL(AccNo,'') + '</AccNo>' +                  
            '<CurrName>' + ISNULL(CurrName,'') + '</CurrName>' +               
            '<CurrUnit>' + ISNULL(CurrUnit,'') + '</CurrUnit>' +
            '<EvidName>' + ISNULL(EvidName,'') + '</EvidName>' +               
            '<TaxKindName>' + ISNULL(TaxKindName,'') + '</TaxKindName>' +                
            '<CashItemName>' + ISNULL(CashItemName,'') + '</CashItemName>' +                 
            '<SMCostItemKindName>' + ISNULL(SMCostItemKindName,'') + '</SMCostItemKindName>' +         
            '<CostItemName>' + ISNULL(CostItemName,'') + '</CostItemName>' +           
            '<BgtDeptName>' + ISNULL(BgtDeptName,'') + '</BgtDeptName>' +    
            '<BgtCCtrName>' + ISNULL(BgtCCtrName,'') + '</BgtCCtrName>' +   
            '<BgtName>' + ISNULL(BgtName,'') + '</BgtName>' +                  
            '<IsCash>' + ISNULL(IsCash,'') + '</IsCash>' +            
            '<CashDate>' + ISNULL(CashDate,'') + '</CashDate>' +        
            '<OnSlipID>' + ISNULL(OnSlipID,'') + '</OnSlipID>' +                     
            '<IsAnti>' + ISNULL(IsAnti,'') + '</IsAnti>' +           
            '<IsSlip>' + ISNULL(IsSlip,'') + '</IsSlip>' +           
            '<IsLevel2>' + ISNULL(IsLevel2,'') + '</IsLevel2>' +           
            '<IsZeroAllow>' + ISNULL(IsZeroAllow,'') + '</IsZeroAllow>' +           
            '<IsEssForAmt>' + ISNULL(IsEssForAmt,'') + '</IsEssForAmt>' +             
            '<IsEssCost>' + ISNULL(IsEssCost,'') + '</IsEssCost>' +           
            '<IsCostTrn>' + ISNULL(IsCostTrn,'') + '</IsCostTrn>' +                   
            '<IsCashAcc>' + ISNULL(IsCashAcc,'') + '</IsCashAcc>' +                    
            '<IsFundSet>' + ISNULL(IsFundSet,'') + '</IsFundSet>' +           
            '<IsAutoExec>' + ISNULL(IsAutoExec,'') + '</IsAutoExec>' +                  
            '<UMCostTypeName>' + ISNULL(UMCostTypeName,'') + '</UMCostTypeName>' +           
            '<CostDeptName>' + REPLACE(REPLACE(ISNULL(CostDeptName,''),'<','〈'),'>','〉') + '</CostDeptName>' +           
            '<CostCCtrName>' + REPLACE(REPLACE(ISNULL(CostCCtrName,''),'<','〈'),'>','〉') + '</CostCCtrName>' +  
            '<CoCustName>' + ISNULL(CoCustName,'') + '</CoCustName>' +         
            '<RemValue1>' + REPLACE(REPLACE(ISNULL(RemValue1,''),'<','〈'),'>','〉')  + '</RemValue1>' +       
            '<RemValue2>' + REPLACE(REPLACE(ISNULL(RemValue2,''),'<','〈'),'>','〉')  + '</RemValue2>' +       
            '<RemValue3>' + REPLACE(REPLACE(ISNULL(RemValue3,''),'<','〈'),'>','〉')  + '</RemValue3>' +       
            '<RemValue4>' + REPLACE(REPLACE(ISNULL(RemValue4,''),'<','〈'),'>','〉')  + '</RemValue4>' +       
            '<RemValue5>' + REPLACE(REPLACE(ISNULL(RemValue5,''),'<','〈'),'>','〉')  + '</RemValue5>' +       
            '<RemValue6>' + REPLACE(REPLACE(ISNULL(RemValue6,''),'<','〈'),'>','〉')  + '</RemValue6>' +       
            '<RemValue7>' + REPLACE(REPLACE(ISNULL(RemValue7,''),'<','〈'),'>','〉')  + '</RemValue7>' +       
            '<RemValue8>' + REPLACE(REPLACE(ISNULL(RemValue8,''),'<','〈'),'>','〉')  + '</RemValue8>' +    
            '<RemName1>' + ISNULL(RemName1,'') + '</RemName1>' +       
            '<RemName2>' + ISNULL(RemName2,'') + '</RemName2>' +       
            '<RemName3>' + ISNULL(RemName3,'') + '</RemName3>' +       
            '<RemName4>' + ISNULL(RemName4,'') + '</RemName4>' +       
            '<RemName5>' + ISNULL(RemName5,'') + '</RemName5>' +       
            '<RemName6>' + ISNULL(RemName6,'') + '</RemName6>' +       
            '<RemName7>' + ISNULL(RemName7,'') + '</RemName7>' +       
            '<RemName8>' + ISNULL(RemName8,'') + '</RemName8>' +    
            '<SMCashMethodName>' + ISNULL(SMCashMethodName,'') + '</SMCashMethodName>' +    
            '<SumDrAmt>' + ISNULL(CONVERT(NVARCHAR(20),SumDrAmt),'') + '</SumDrAmt>' +    
            '<SUMCrAmt>' + ISNULL(CONVERT(NVARCHAR(20),SUMCrAmt),'') + '</SUMCrAmt>' +    
            '<SlipNoOne>' + ISNULL(SlipNoOne,'') + '</SlipNoOne>' +    
            '<IsFirstPage>' + ISNULL(IsFirstPage,'') + '</IsFirstPage>' +   
            '<DrSumFirstFage>' + ISNULL(CONVERT(NVARCHAR(20),DrSumFirstFage),'') + '</DrSumFirstFage>' +   
            '<CrSumFirstFage>' + ISNULL(CONVERT(NVARCHAR(20),CrSumFirstFage),'') + '</CrSumFirstFage>' +   
            '<IsOnlyOnPage>' + ISNULL(IsOnlyOnPage,'') + '</IsOnlyOnPage>' +   
            '<RegDateTime>' + ISNULL(RegDateTime,'') + '</RegDateTime>' +   
            '<RegDate>' + ISNULL(RegDate,'') + '</RegDate>' +   
            '<CustInfo>' + ISNULL(CustInfo,'') + '</CustInfo>' +
            '<S_AccUnitName>' + ISNULL(S_AccUnitName, '') + '</S_AccUnitName>'  +
            '<CCtrRemark>' + ISNULL(CCtrRemark, '') + '</CCtrRemark>' +  
            '<TopUserName>' + ISNULL(TopUserName, '') + '</TopUserName>' +
            '<AccName2>' + ISNULL(AccName2, '') + '</AccName2>' +
            '<CustInfoFBS>' + ISNULL(CustInfoFBS,'') + '</CustInfoFBS>' +
            '<FullRegDateTime>' + ISNULL(CONVERT(NVARCHAR(100),FullRegDateTime),'') + '</FullRegDateTime>' +              
            '<ApprovalDateTime>' + ISNULL(CONVERT(NVARCHAR(100),ApprovalDateTime),'') + '</ApprovalDateTime>' +  
            '<RTSetAccDate>' + ISNULL(RTSetAccDate,'') + '</RTSetAccDate>' + 
            '<CustNo>' + ISNULL(CONVERT(NVARCHAR(200),CustNo),'') + '</CustNo>' + 
		    '<TaxNoAlias>' + ISNULL(CONVERT(NVARCHAR(200),TaxNoAlias),'') + '</TaxNoAlias>' +
		    '<FullRegDate>' + CONVERT(NCHAR(8), ISNULL(FullRegDateTime, ''), 112) + '</FullRegDate> ' + 
		    '<RemEmpId>' + ISNULL(CONVERT(NVARCHAR(200),RemEmpId),'') + '</RemEmpId>' + 
		    '<RemBizNo>' + ISNULL(CONVERT(NVARCHAR(200),RemBizNo),'') + '</RemBizNo>' + 
		    '<RemEmpName>' + ISNULL(CONVERT(NVARCHAR(200),RemEmpName),'') + '</RemEmpName>' + 
		    '<RemCustName>' + REPLACE(REPLACE(ISNULL(CONVERT(NVARCHAR(200),RemCustName),''),'<','〈'),'>','〉') + '</RemCustName>' +
            '<KoDec>' + ISNULL(CONVERT(NVARCHAR(10),KoDec),'') + '</KoDec>' +   
            '<ForDec>' + ISNULL(CONVERT(NVARCHAR(10),ForDec),'') + '</ForDec>' +
            '<ExDec>' + ISNULL(CONVERT(NVARCHAR(10),ExDec),'') + '</ExDec>' 
            AS DataBlock2
           FROM #Temp_Detail    
          ORDER BY SlipMstSeq, RowNo     
            
    DECLARE @tempDataBlock2 NVARCHAR(Max)  
  
    CREATE TABLE #Temp_XML(  
            Cnt         INT IDENTITY (0,1),  
            SlipMstSeq  INT   
    )  
    INSERT INTO #Temp_XML(SlipMstSeq)  
    SELECT SlipMstSeq  
      FROM #Temp   
     GROUP BY SlipMstSeq  
     ORDER BY SlipMstSeq  
    SELECT @MaxCnt      = COUNT(*) FROM #Temp_XML
    SELECT @Cnt         = 0
    WHILE (@Cnt < @MaxCnt)          
    BEGIN
        --SELECT @SlipMstSeq   = SlipMstSeq   FROM #Temp WHERE Cnt    = @Cnt
        --SELECT @SubCnt      = MIN(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq
        --SELECT @IniCnt      = MIN(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq
        --SELECT @SubMaxCnt   = MAX(SubCnt) FROM #Temp_DetailRepeat WHERE SlipMstSeq = @SlipMstSeq
        --SELECT @XmlData = ''       
        
        SELECT @SlipMstSeq   = SlipMstSeq   FROM #Temp_XML WHERE Cnt    = @Cnt  
        SELECT @tempDataBlock2 = ''  
        
        SELECT @tempDataBlock2 = STUFF((SELECT '' + LTRIM(CONVERT(NVARCHAR(MAX), A.DataBlock2))  + '</DataBlock2><DataBlock2>' AS [text()]         
          FROM #Temp_DetailRepeat AS A WITH(NOLOCK)    
         WHERE 1=1   
           AND A.SlipMstSeq = @SlipMstSeq  
         ORDER BY A.SubCnt ASC  
           FOR XML path('')   ),1,1,'') 
        
        
        --IF @WorkingTag <> 'S' ------------ 그룹웨어 SP(_SCOMGroupWarePrint)에서 호출하는 경우 XML 데이터가 의미 없어 Pass함 (코미코 430건 전표 Select시 12초 소요)
        --WHILE (@SubCnt  <= @SubMaxCnt)
        --BEGIN
        --    SELECT @DataBlock2 = DataBlock2 FROM #Temp_DetailRepeat WHERE SubCnt  = @SubCnt AND SlipMstSeq = @SlipMstSeq
         
        --    IF (@IniCnt = @SubCnt) 
        --    BEGIN
        --        SELECT @XmlData     = @XmlData + @DataBlock2
        --    END
        --    ELSE
        --    BEGIN
        --        SELECT @XmlData     = @XmlData + + '</DataBlock2><DataBlock2>' + @DataBlock2
        --    END
        --    SELECT @SubCnt   = @SubCnt + 1
        --END
        --UPDATE #Temp
        --   SET DataBlock2 = @XmlData
        -- WHERE SlipMstSeq = @SlipMstSeq
        
          UPDATE #Temp  
             SET DataBlock2 =  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@tempDataBlock2 + '[!!XMLEND!!]', '&lt;', '<'), '&gt;', '>'), 'lt;', '<'), '&amp;','&'), '</DataBlock2><DataBlock2>[!!XMLEND!!]','') 
            FROM #Temp   
           WHERE SlipMstSeq =  @SlipMstSeq  
        SELECT @Cnt  = @Cnt + 1
    END
    -- 출력순서를 SlipMstID를 기준으로 출력되도록 수정 by.sykim. 2016.01.10
    SELECT A.SlipMstSeq, A.DataBlock2
      FROM #Temp    AS A 
      JOIN _TACSlip AS B WITH(NOLOCK) ON A.SlipMstSeq = B.SlipMstSeq 
                                     AND @CompanySeq  = B.CompanySeq
     ORDER BY B.SlipMstID
    -- 전표관련하여 그룹웨어에서 화면을 띄워줄때 사용하기 위해 서브쿼리로 변환 전의 데이터도 SELECT 한다.
    -- 출력순서를 SlipMstID를 기준으로 출력되도록 수정 by.sykim. 2016.01.10
    SELECT * FROM #Temp_Detail ORDER BY SlipMstID, RowNo
    IF ISNULL(@IsNotGW,'') = '1'
    BEGIN
	    -- 전표 출력시 계정별 합계표시 여부 
	    SELECT AccNo, AccName,   
		       SUM(DrAmt)       AS SumDrAmt,   
		       SUM(CrAmt)       AS SumCrAmt,   
		       SUM(DrForAmt)    AS SumDrForAmt,   
		       SUM(CrForAmt)    AS SumCrForAmt  
	      FROM #Temp_Detail   
	     GROUP BY AccNo, AccName  
	     ORDER BY AccNo
    END
 
     
    --=========================================================================================================================
    -- 출력회수 증가
    --=========================================================================================================================
    IF EXISTS (SELECT 1 FROM #Temp)
    BEGIN
        SELECT @Cnt = 0
        SELECT @MaxCnt = MAX(Cnt) FROM #Temp
        WHILE @Cnt <= @MaxCnt
        BEGIN
            SELECT @SlipMstSeq = SlipMstSeq FROM #Temp WHERE Cnt = @Cnt
            UPDATE _TACSlipPrintCount
               SET PrintCnt = PrintCnt + 1
             WHERE CompanySeq   = @CompanySeq
               AND SlipMstSeq   = @SlipMstSeq
            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO _TACSlipPrintCount (CompanySeq, SlipMstSeq, PrintCnt, LastUserSeq, LastDateTime)
                    SELECT @CompanySeq, @SlipMstSeq, 1, @UserSeq, GETDATE()
            END
            SELECT @Cnt = @Cnt + 1
        END
    END
    END            
              
            
    --> 최초 뜰때 실행계획을 다시 잡는 것 같아 별도 SUB SP로 분리함. ---> 대행사 끝나고 전표는 다시 정리해야 할 것임            
                                                                      
RETURN
