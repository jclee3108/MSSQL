IF OBJECT_ID('mnpt_STAXVATEdiCREATEFile') IS NOT NULL 
    DROP PROC mnpt_STAXVATEdiCREATEFile
GO 

-- v2018.02.08 

-- 사업자별로 법인번호 적용 by이재천
/************************************************************    
설  명 - 전자신고파일생성    
작성일 - 2009. 10. 16         
작성자 -     
    I104400     사업장현황명세서
    I103400     신용카드매출전표발행금액등 집계표 
    I105800     영세율첨부서류제출명세서
    I102300     의제매입세액공제신고서
    M116300     재활용폐자원등 및 중고자동차매입세액공제신고서
    I103600     부동산임대공가가액 명세서
    I102800     대손세액공제(변제)신고서
    I104500     사업장별 부가가치세 과세표준 및 납부세액(환급세액)신고명세서 
    I103800     건물등 감가상각자산 취득명세서 
    I103300     공제받지 못할 매입세액 명세서
    M200100     월별판매액합계표
    M118000     매입자발행세금계산서합계표
    I104300     건물관리명세서
    I103900    사업자단위과세의사업장별부가가치세과세표준및납부세액(환급세액)신고명세서    
    I103700     현금매출명세서
    I105600     내국신용장 / 구매확인서 전자발급명세서
    I104000     영세율매출명세서
    M202300     외국인관광객 면세물품 판매 및 환급실적명세서
    M125200     구리스크랩등 매입세액공제신고서
    I102600     과세사업전환 감가상각자산신고서        2017년 1기 예정 추가 by dhkim3
    I402100     외화획득명세서
    I106900     외국인관광객 즉시환급 물품 판매 실적명세서
    I401500     관세환급금등 명세서 2016년 2기 예정 추가 by dhkim3
-----------------------------------
전자세금계산서 발급세액공제신고서   -- 2016년 1기부터 서식 폐기 / _TTAXEBillTaxDeductCard
************************************************************/     
CREATE PROCEDURE mnpt_STAXVATEdiCREATEFile                           
    @xmlDocument    NVARCHAR(MAX) ,                      
    @xmlFlags       INT = 0,                      
    @ServiceSeq     INT = 0,                      
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,                      
    @LanguageSeq    INT = 1,                      
    @UserSeq        INT = 0,                      
    @PgmSeq         INT = 0
AS    
  
    DECLARE @SaleCnt            INT,  
            @SupAmt             DECIMAL(19,5),  
            @TaxAmt             DECIMAL(19,5),  
            @Count_A            INT,  
            @Count_B            INT,  
            @Cnt                INT,  
            @MaxCnt             INT,  
            @BuildingSeq        INT,            
            @CustCntBiz         INT,  
            @CustCntPer         INT,  
            @TotCntBiz          INT,  
            @TotCntPer          INT,  
            @SAmtBiz            DECIMAL(19,5),  
            @SAmtPer            DECIMAL(19,5),  
            @VAmtBiz            DECIMAL(19,5),  
            @VAmtPer            DECIMAL(19,5),  
            @CurrDate           VARCHAR(8)
    DECLARE @docHandle          INT
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                       
    DECLARE @TaxTermSeq         INT,    
            @TaxUnit            INT,    
            @RptDate            NVARCHAR(08)                 
    -- WorkingTag 중요 : 전자신고는 ''(A로넘어오고 아래서 ''으로 변경),   
    --디스켓신고 : 세금계산서 합계표 'K',   
                -- 계산서합계표 'H',   
                -- 수출실적명세서 'A',   
                -- 신용카드매출전표수취명세서(갑,을) 'J',      
                -- 사업장별 부가가치세 과세표준및납부세액(환급세액)신고명세 'M'  
                -- 사업자단위과세의 사업장별부가가치세과세표준및납부세액 'U'
                
    SELECT @TaxTermSeq      = ISNULL(TaxTermSeq     ,  0),    
           @TaxUnit         = ISNULL(TaxUnit        ,  0),    
           @RptDate         = ISNULL(RptDate        , ''),    
           @WorkingTag      = ISNULL(WorkingTag     , '')
    FROM OPENXML (@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (  TaxTermSeq      INT,    
            TaxUnit         INT,    
            RptDate         NVARCHAR(08),    
            WorkingTag      NVARCHAR(10) )   
    IF ISNULL(@RptDate, '') = ''
        SELECT @RptDate = CONVERT(NVARCHAR(8), GETDATE(), 112)

    -----------------------------------------------------
    -- 환경설정
    -----------------------------------------------------
    DECLARE @IsESERO        NCHAR(1),  
            @Env4728        NCHAR(1),
            @Env4735        NCHAR(1),
            @Env4016        INT,
            @Env4017        NVARCHAR(8),
            @Env4501        NVARCHAR(10),
            @V166Cfm        CHAR(7),
            @KorCurrNo      VARCHAR(03),    -- 원화화폐코드      
            @StkCurrCd      VARCHAR(03),    -- 자국통화    
            @StkCurrSeq     INT
    --DECLARE @CompanySeq INT =1,
    --        @UserSeq INT = 1
    EXEC dbo._SCOMEnv @CompanySeq, 4509 , @UserSeq , @@PROCID , @IsESERO OUTPUT         -- [환경설정4509] 홈택스데이터로 전자세금계산서 건수/금액 신고함
    EXEC dbo._SCOMEnv @CompanySeq, 4728 , @UserSeq , @@PROCID , @Env4728 OUTPUT         -- [환경설정4728] 홈택스데이터로 전자계산서 건수/금액 신고함
    EXEC dbo._SCOMEnv @CompanySeq, 4735 , @UserSeq , @@PROCID , @Env4735 OUTPUT         -- [환경설정4735] 수출실적명세서 금액을 외화획득명세서 금액으로 자동집계 안함
    EXEC dbo._SCOMEnv @CompanySeq, 4016 , @UserSeq , @@PROCID , @Env4016 OUTPUT         -- [환경설정4016] <세무회계>  부가세신고방법
    EXEC dbo._SCOMEnv @CompanySeq, 4017 , @UserSeq , @@PROCID , @Env4017 OUTPUT         -- [환경설정4017] <세무회계>  사업자단위과세제도 적용일자
    EXEC dbo._SCOMEnv @CompanySeq, 4501 , @UserSeq , @@PROCID , @Env4501 OUTPUT         -- [환경설정4501] <세무회계>  사업자단위과세 승인번호
    EXEC dbo._SCOMEnv @CompanySeq, 13   , @UserSeq , @@PROCID , @StkCurrSeq OUTPUT      -- [환경설정13]   <운영공통>  자국 통화
    SELECT @IsESERO = ISNULL(@IsESERO, '0')
    SELECT @Env4728 = ISNULL(@Env4728, '0')
    SELECT @Env4735 = ISNULL(@Env4735, '0')
    SELECT @Env4016 = ISNULL(@Env4016, 0)
    SELECT @Env4017 = ISNULL(@Env4017, '29991231')
    SELECT @V166Cfm = REPLACE(ISNULL(@Env4501, ''), '-', '') 
    SELECT @StkCurrSeq = ISNULL(@StkCurrSeq, 0)
    SELECT @KorCurrNo   = 'KRW'
    SELECT @StkCurrCd = ISNULL(CurrNo, '') FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrSeq = @StkCurrSeq
    IF @@ROWCOUNT = 0 OR ISNULL(@StkCurrCd, '') = ''    
    BEGIN    
        SELECT @StkCurrCd = CurrNo, @StkCurrSeq = CurrSeq FROM _TDACurr WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CurrNo = @KorCurrNo    
    END    
    -----------------------------------------------------
    -- 환경설정 END
    -----------------------------------------------------
    
    DECLARE @CompanyNo          CHAR(13),   -- 법인등록번호      
            -- 과세기간
            @TaxFrDate          CHAR(8),    -- 시작일자      
            @TaxToDate          CHAR(8),    -- 종료일자      
            @BillFrDate         CHAR(8),    -- 계산서집계 시작일자
            @BillToDate         CHAR(8),    -- 계산서집계 종료일자
            @Term_SMTaxationType    INT,
            -- 사업자
            @CashSaleKind       NCHAR(2),
            @Addr1              VARCHAR(70),    -- 사업장주소(길이 70용)      
            @Addr2              VARCHAR(45),    -- 사업장주소(길이 45용)    
            @TaxBizTypeNo       CHAR(7),        -- 주업종코드      
            @TaxSumPaymentNo    CHAR(7),        -- 총괄납부승인번호      
            @TaxNo              VARCHAR(10),
            @BizCancelDate      CHAR(8),
            @Unit_SMTaxationType    INT,
            @OverDate           CHAR(8)
    
    --------------------------      
    --시작일자 및 종료일자      
    --------------------------     
    SELECT @TaxFrDate   = TaxFrDate     ,
           @TaxToDate   = TaxToDate     ,
           @BillFrDate  = BillSumFrDate ,  
           @BillToDate  = BillSumToDate ,
           @Term_SMTaxationType = SMTaxationType    -- 신고구분(예정 4090001 / 확정 4090002 / 영세율 등 조기환급 4090006 / 일반 4090004)
      FROM _TTAXTerm WITH (NOLOCK)    
     WHERE CompanySeq   = @CompanySeq  
       AND TaxTermSeq   = @TaxTermSeq  
    SELECT @CurrDate = CONVERT(VARCHAR(8), GETDATE(), 112)      -- 현재일 / 제출일자
    IF @PgmSeq = 480        -- FrmTAXVatRptEdi
    BEGIN  
        SELECT @WorkingTag = ''  
    END
    -- 사업자단위과세인 경우 WorkingTag변경  
    -- 사업장별 부가가치세 과세표준및납부세액(환급세액)신고명세 'M'
    -- => 사업자단위과세의 사업장별부가가치세과세표준및납부세액 'U'
    IF @WorkingTag = 'M' AND (@Env4016 = 4125002 AND @TaxFrDate >= @Env4017)
    BEGIN  
        SELECT @WorkingTag = 'U'  
    END
    -----------------------------------------------------------------------------
    -- 사업자정보 이력 가져오기
    -----------------------------------------------------------------------------
    DECLARE @MaxUnitIDX     INT,
            @UnitIDX        INT,
            @IDX_TaxUnit    INT,
            @HistCnt        INT
    CREATE TABLE #TaxUnitAll ( IDX INT IDENTITY(1,1), TaxUnit INT )
    CREATE TABLE #TDATaxUnit (
	    CompanySeq	        INT	, 
	    TaxUnit	            INT	, 
	    TaxNo	            NVARCHAR(50)	, 
	    TaxName	            NVARCHAR(100)	, 
	    Owner	            NVARCHAR(100)	, 
	    BizType	            NVARCHAR(50)	, 
	    ResidID	            NVARCHAR(200)	, 
	    BizItem	            NVARCHAR(50)	, 
	    Zip	                NVARCHAR(10)	, 
	    Addr1	            NVARCHAR(100)	, 
	    Addr2	            NVARCHAR(100)	, 
	    Addr3	            NVARCHAR(100)	, 
	    TelNo	            NVARCHAR(30)	, 
	    CellPhone	        NVARCHAR(30)	, 
	    EMail	            NVARCHAR(100)	, 
	    VATRptAddr	        NVARCHAR(200)	, 	
	    BizCancelDate	    NCHAR(8)	    , 
	    HomeTaxID	        NVARCHAR(100)	, 	
	    TaxOfficeNo	        NCHAR(3)	    , 
	    TaxBizTypeNo	    NVARCHAR(10)	, 
	    liquorWholeSaleNo	NVARCHAR(10)	, 
	    liquorRetailSaleNo	NVARCHAR(10)	, 
	    SMTaxationType	    INT	            , 
	    BillTaxName	        NVARCHAR(100)	, 
	    TaxSumPaymentNo	    NVARCHAR(20)	, 
	    TaxNoSerl	        NVARCHAR(20)	, 
	    CashSaleKind	    NCHAR(2)	    , 
	    RoadAddr	        NVARCHAR(200)	  ) 
    CREATE TABLE #TaxUnitHist(
        TaxUnit         INT,
        SMTaxationType  INT,
        TaxNoSerl       NVARCHAR(20)
    )

    INSERT INTO #TaxUnitAll(TaxUnit)
    SELECT TaxUnit
      FROM _TDATaxUnit WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
    SELECT @UnitIDX    = 1,
           @MaxUnitIDX = (SELECT MAX(IDX) FROM #TaxUnitAll)
    WHILE(@UnitIDX <= @MaxUnitIDX)
    BEGIN
        SELECT @IDX_TaxUnit = (SELECT TaxUnit FROM #TaxUnitAll WHERE IDX = @UnitIDX)
        INSERT INTO #TDATaxUnit(CompanySeq      , TaxUnit       , TaxNo         , TaxName           , Owner         ,
                                BizType         , ResidID       , BizItem       , Zip               , Addr1         ,
                                Addr2           , Addr3         , TelNo         , CellPhone         , EMail         ,
                                VATRptAddr      , BizCancelDate , HomeTaxID     , TaxOfficeNo       , TaxBizTypeNo  ,
                                SMTaxationType  , BillTaxName   , TaxSumPaymentNo,TaxNoSerl         , CashSaleKind  ,
                                RoadAddr        , liquorWholeSaleNo             ,liquorRetailSaleNo )
        SELECT T.CompanySeq      , T.TaxUnit       , T.TaxNo            , T.TaxName           , T.Owner         ,
                T.BizType         , T.ResidID       , T.BizItem          , T.Zip               , T.Addr1         ,
                T.Addr2           , T.Addr3         , T.TelNo            , T.CellPhone         , T.EMail         ,
                T.VATRptAddr      , T.BizCancelDate , T.HomeTaxID        , T.TaxOfficeNo       , T.TaxBizTypeNo  ,
                T.SMTaxationType  , T.BillTaxName   , T.TaxSumPaymentNo  , T.TaxNoSerl         , T.CashSaleKind  ,
                T.RoadAddr        , T.liquorWholeSaleNo                  , T.liquorRetailSaleNo 
            FROM _TDATaxUnit AS T WITH(NOLOCK)
        WHERE T.CompanySeq = @CompanySeq 
            AND T.TaxUnit    = @IDX_TaxUnit

        SELECT @HistCnt = COUNT(Y.TaxNoAlias)
          FROM _TTAXTerm AS X WITH(NOLOCK)
                    LEFT JOIN _TDATaxUnitHist AS Y WITH(NOLOCK)
                           ON X.CompanySeq = Y.CompanySeq                     
                          AND X.TaxToDate <= Y.ToDate
         WHERE X.CompanySeq = @CompanySeq  
           AND X.TaxTermSeq = @TaxTermSeq  
           AND Y.TaxUnit    = @IDX_TaxUnit
        IF @HistCnt <> 0 -- 사업자등록 이력이 있는 경우        
        BEGIN
            INSERT INTO #TaxUnitHist(TaxUnit, SMTaxationType, TaxNoSerl)
            SELECT T.TaxUnit, T.SMTaxationType, T.TaxNoSerl
              FROM _TTAXTerm AS B WITH(NOLOCK)
                        JOIN _TDATaxUnitHist AS T WITH(NOLOCK)
                          ON B.CompanySeq = T.CompanySeq
                         AND B.TaxToDate <= T.ToDate
             WHERE  B.CompanySeq = @CompanySeq
               AND  B.TaxTermSeq = @TaxTermSeq
               AND  T.TaxUnit    = @IDX_TaxUnit
             ORDER BY T.Serl
            
            -- 일반과세자구분 / 종사업자일련번호만 Hist 관리 by shkim1
            -- 총괄납부/일반사업자 -> 사업자단위과세 변경 시 이전 이력으로 신고하기 위해
            UPDATE #TDATaxUnit
               SET SMTaxationType = T.SMTaxationType,
                   TaxNoSerl      = T.TaxNoSerl
              FROM #TDATaxUnit AS A
                        JOIN #TaxUnitHist AS T ON T.TaxUnit = A.TaxUnit
             WHERE A.TaxUnit = @IDX_TaxUnit
        END
        SELECT @UnitIDX = @UnitIDX + 1
    END

    -----------------------------------------------------------------------------
    -- 사업자정보 이력 가져오기 END
    -----------------------------------------------------------------------------
    --------------------------------
    -- 사업자 정보
    --------------------------------
    SELECT @CashSaleKind    = ISNULL(CashSaleKind,''),
           @Addr1           = ISNULL(SUBSTRING(LTRIM(RTRIM(VATRptAddr)), 1, 70), SPACE(70)),    
           @Addr2           = ISNULL(SUBSTRING(LTRIM(RTRIM(VATRptAddr)), 1, 45), SPACE(45)),    
           @TaxBizTypeNo    = ISNULL(TaxBizTypeNo   , ''),    
           @TaxSumPaymentNo = CASE WHEN SMTaxationType = 4128002 THEN ISNULL(TaxSumPaymentNo, '') ELSE '' END,
           @TaxNo           = CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')),
           @BizCancelDate   = ISNULL(BizCancelDate, '') ,
           @Unit_SMTaxationType = SMTaxationType
      FROM #TDATaxUnit
     WHERE CompanySeq = @CompanySeq
       AND TaxUnit    = @TaxUnit
    
    --========================================================================  
    -- 체크로직
    --======================================================================== 
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250),
            @Word1          NVARCHAR(200)
    EXEC @Word1    = _FCOMGetWord @LanguageSeq , 14542   , N'사업자'
      
    IF (SELECT TelNo FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
    BEGIN
    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1008               , -- @1을(를) 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%')  
                              @LanguageSeq       ,
                              1396  ,   '전화번호'
        
        SELECT -1 AS tmp_Seq, @Word1 + ' ' + @Results AS tmp_file
        RETURN
    END
    
    IF @WorkingTag = ''
    BEGIN                        
        -- 사업자등록 - 전자신고ID 누락 체크
        IF ( SELECT HomeTaxID FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
        BEGIN
            
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1008               , -- @1을(를) 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%')  
                                  @LanguageSeq       ,
                                  2159  ,   '전자신고ID'
                                  
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- 사업자등록 - 주업종코드 누락 체크
        IF ( SELECT TaxBizTypeNo FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
        BEGIN
            
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1008               , -- @1을(를) 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%')  
                                  @LanguageSeq       ,
                                  1334  ,   '주업종코드'	
                                  
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- 업종코드 중복 체크
        IF EXISTS(SELECT BizTypeSeq 
                    FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                   WHERE A.CompanySeq = @CompanySeq
                     AND A.TaxTermSeq = @TaxTermSeq 
                     AND A.TaxUnit    = @TaxUnit  
                     AND A.RptNo      IN ('3010', '3020', '3030')
                     AND A.SpplyAmt  <> 0
                   GROUP BY BizTypeSeq
                   HAVING COUNT(B.BizTypeSeq) > 1)
        OR EXISTS( SELECT BizTypeSeq 
                     FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                   WHERE A.CompanySeq = @CompanySeq
                     AND A.TaxTermSeq = @TaxTermSeq 
                     AND A.TaxUnit    = @TaxUnit  
                     AND A.RptNo      IN ('7010', '7020')
                     AND A.SpplyAmt  <> 0  
                   GROUP BY BizTypeSeq
                   HAVING COUNT(B.BizTypeSeq) > 1)
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  6                  , -- 중복된 @1 @2가(이) 입력되었습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%중복%')  
                                  @LanguageSeq       ,
                                  7196  ,  '업종코드'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%업종코드%'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- 업종코드 누락 체크
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                            JOIN _TTAXBizKind AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                               AND A.TaxUnit    = B.TaxUnit 
                                                               AND A.BizKindSeq = B.BizKindSeq
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('3010','3020','3030','7010','7020', '7025')
                      AND A.SpplyAmt  <> 0
                      AND (B.BizTypeSeq = '0' OR B.BizTypeSeq = ''))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1005               , -- @1를 먼저 입력하셔야 합니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7196  ,  '업종코드'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%업종코드%'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
        
        -- 과세표준명세 - 수입금액제외 업종구분 미등록 체크
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('3040')
                      AND A.SpplyAmt  <> 0)
          AND (SELECT COUNT(*) FROM _TTAXBizKind AS B WITH(NOLOCK)
                WHERE B.CompanySeq = @CompanySeq
                  AND B.TaxUnit    = @TaxUnit
                  AND B.RptSort    = '3040') <> 1
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  7                  , -- @1가(이) 등록되어 있지 않습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%등록%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7194  ,  '업종구분명'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%업종구분%'
            SELECT -1 AS tmp_Seq, '부가세신고서-과세표준명세 수입금액제외의 ' + @Results AS tmp_file
            RETURN
        END
        
        -- 면세사업 - 수입금액제외 업종구분 미등록 체크
        IF EXISTS (SELECT 1 FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                    WHERE A.CompanySeq = @CompanySeq
                      AND A.TaxTermSeq = @TaxTermSeq
                      AND A.TaxUnit    = @TaxUnit  
                      AND A.RptNo      IN ('7025')
                      AND A.SpplyAmt  <> 0)
          AND (SELECT COUNT(*) FROM _TTAXBizKind AS B WITH(NOLOCK)
                WHERE B.CompanySeq = @CompanySeq
                  AND B.TaxUnit    = @TaxUnit
                  AND B.RptSort    = '7025') <> 1
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  7                  , -- @1가(이) 등록되어 있지 않습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%등록%' AND LanguageSeq = 1)  
                                  @LanguageSeq       ,
                                  7194  ,  '업종구분명'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '%업종구분%'
            SELECT -1 AS tmp_Seq, '부가세신고서-면세사업 수입금액제외의 ' + @Results AS tmp_file
            RETURN
        END
        
        
        -- 현금매출명세구분코드는 등록되어 있지 않으나 현금매출명세서가 작성된 경우 체크
        --IF @CashSaleKind = ''
        --  AND (EXISTS (SELECT 1 FROM _TTAXBizStdSumV167 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        --    OR EXISTS (SELECT 1 FROM _TTAXBizStdSumV167M WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))  
        --BEGIN
        --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
        --                          @Status      OUTPUT,  
        --                          @Results     OUTPUT,  
        --                          7                  , -- @1가(이) 등록되어 있지 않습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7 AND LanguageSeq = 1)  
        --                          @LanguageSeq       ,
        --                          28742  ,  N'현금매출명세구분코드'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '현금매출명세구분%'
        --    SELECT -1 AS tmp_Seq, '[사업자등록] ' + @Results AS tmp_file
        --    RETURN
        --END
        
        -- 사업장현황 체크
        IF (@Term_SMTaxationType <> 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXBizPlace WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1345               , -- @1은 @2@3만 @4할 수 있습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1345)
                                  @LanguageSeq       ,
                                  14965     , N'서식', -- SELECT * FROM _TCADictionary WHERE Word LIKE '%서식%' AND LanguageSeq = 1
                                  607       , N'확정', -- SELECT * FROM _TCADictionary WHERE Word LIKE '확정' AND LanguageSeq = 1
                                  25241     , N'신고', -- SELECT * FROM _TCADictionary WHERE Word LIKE '신고' AND LanguageSeq = 1
                                  25241     , N'신고'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '등록' AND LanguageSeq = 1
            SELECT -1 AS tmp_Seq, '[사업장현황명세서] ' + @Results AS tmp_file
            RETURN        
        END
        -- 대손세액공제(변제)신고서 체크
        IF (@Term_SMTaxationType <> 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXBadDebt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  1345               , -- @1은 @2@3만 @4할 수 있습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 AND MessageSeq = 1345)
                                  @LanguageSeq       ,
                                  14965     , N'서식', -- SELECT * FROM _TCADictionary WHERE Word LIKE '%서식%' AND LanguageSeq = 1
                                  607       , N'확정', -- SELECT * FROM _TCADictionary WHERE Word LIKE '확정' AND LanguageSeq = 1
                                  25241     , N'신고', -- SELECT * FROM _TCADictionary WHERE Word LIKE '신고' AND LanguageSeq = 1
                                  25241     , N'신고'  -- SELECT * FROM _TCADictionary WHERE Word LIKE '등록' AND LanguageSeq = 1
            SELECT -1 AS tmp_Seq, '[대손세액공제(변제)신고서] ' + @Results AS tmp_file
            RETURN        
        END
        -- 스크랩등매입세액공제신고서 체크
        IF (@Term_SMTaxationType = 4090002 )
          AND( EXISTS (SELECT * FROM _TTAXCuDeductScrap WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit))
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                  @Status      OUTPUT,
                                  @Results     OUTPUT,
                                  19                  , -- @1는(은) @2(을)를 할 수 없습니다.
                                  @LanguageSeq       ,
                                  19221,    N'확정신고',
                                  29061,    N'제출'
            SELECT -1 AS tmp_Seq, '[스크랩등매입세액공제신고서] ' + @Results AS tmp_file
            RETURN        
        END
        
    END
 
    IF @WorkingTag IN('Z', 'E', 'M', 'U', 'L')   -- 영세율(Z), 부동산임대(E), 사업장별부가가치세(M), 사업자단위(U), 내국신용장(L)
        AND (SELECT ResidID FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND TaxUnit = @TaxUnit ) = ''
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1008               , -- @1을(를) 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%')  
                              @LanguageSeq       ,
                              13066  ,  '대표자 주민등록번호'
                      
      
        SELECT -1 AS tmp_Seq, @Results AS tmp_file
        RETURN
    END
    
    --========================================================================================
    -- 체크 로직 END
    --========================================================================================
    --------------------------      
    --과세기간 종료일 다음달 11일
    --------------------------    
    SELECT @OverDate = OverDate
      FROM _TTAXOverTerm WITH(NOLOCK)
     WHERE YearMonth = LEFT(@TaxToDate,6)
  
    /*
    --------------------------      
    --법인등록번호      
    --------------------------      
    SELECT @CompanyNo   = ISNULL(LTRIM(RTRIM(CompanyNo)), SPACE(13))
      FROM _TCACompany WITH (NOLOCK)    
     WHERE CompanySeq   = @CompanySeq  
    */
    
    -------------------------------------------------------
    -- 사업자별 법인번호 Setting, 2018.02.08
    -------------------------------------------------------
    SELECT @CompanyNo = ISNULL(LTRIM(RTRIM(REPLACE(SemuNo,'-',''))), SPACE(13))
      FROM _TDATaxUnit 
     WHERE CompanySeq = @CompanySeq 
       AND TaxUnit = @TaxUnit 
    

    IF EXISTS (SELECT 1 FROM #TDATaxUnit WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND (CHARINDEX(CHAR(10), BizType) <> 0 OR CHARINDEX(CHAR(10), BizItem) <> 0 ))  
    BEGIN  
        UPDATE #TDATaxUnit  
           SET BizType  = REPLACE(BizType, CHAR(10), ''),  
               BizItem  = REPLACE(BizItem, CHAR(10), '')  
         WHERE CompanySeq   = @CompanySeq  
           AND TaxUnit      = @TaxUnit  
    END  
  
  
    CREATE TABLE #TTAXVATRptAmt (    
        TaxTermSeq          INT,    
        TaxUnit             INT,    
        Amt01             DECIMAL(19, 5),         Amt02             DECIMAL(19, 5),         Amt03             DECIMAL(19, 5),     
        Amt04             DECIMAL(19, 5),         Amt05             DECIMAL(19, 5),         Amt06             DECIMAL(19, 5), 
        Amt08             DECIMAL(19, 5),         Amt09             DECIMAL(19, 5),         Amt10             DECIMAL(19, 5),         
        Amt12             DECIMAL(19, 5),         Amt14             DECIMAL(19, 5),         Amt21             DECIMAL(19, 5),         
        Amt22             DECIMAL(19, 5),         Amt23             DECIMAL(19, 5),         Amt24             DECIMAL(19, 5),         
        Amt26             DECIMAL(19, 5),         Amt27             DECIMAL(19, 5),         Amt28             DECIMAL(19, 5),         
        Amt29             DECIMAL(19, 5),         Amt31             DECIMAL(19, 5),         Amt32             DECIMAL(19, 5),         
        Amt33             DECIMAL(19, 5),         Amt37             DECIMAL(19, 5),         Amt38             DECIMAL(19, 5),        
        Amt39             DECIMAL(19, 5),         Amt41             DECIMAL(19, 5),         Amt42             DECIMAL(19, 5),         
        Amt43             DECIMAL(19, 5),         Amt44             DECIMAL(19, 5),         Amt46             DECIMAL(19, 5),         
        Amt47             DECIMAL(19, 5),         Amt48             DECIMAL(19, 5),         Amt49             DECIMAL(19, 5),         
        Amt50             DECIMAL(19, 5),         Amt52             DECIMAL(19, 5),         Amt53             DECIMAL(19, 5),         
        Amt55             DECIMAL(19, 5),         Amt56             DECIMAL(19, 5),         Amt57             DECIMAL(19, 5),         
        Amt58             DECIMAL(19, 5),         Amt59             DECIMAL(19, 5),         Amt16             DECIMAL(19, 5),         
        Amt43_1           DECIMAL(19, 5),         Amt32_1           DECIMAL(19, 5),         Amt46_1           DECIMAL(19, 5),         
        Amt116            DECIMAL(19, 5),         Amt118            DECIMAL(19, 5),         Amt121            DECIMAL(19, 5),         
        Amt123            DECIMAL(19, 5),         Amt07             DECIMAL(19, 5),         Amt11             DECIMAL(19, 5),         
        Amt13             DECIMAL(19, 5),         Amt25             DECIMAL(19, 5),         Amt30             DECIMAL(19, 5),         
        Amt36             DECIMAL(19, 5),         Amt40             DECIMAL(19, 5),         Amt45             DECIMAL(19, 5),         
        Amt54             DECIMAL(19, 5),         Amt60             DECIMAL(19, 5),         Amt124            DECIMAL(19, 5),         
        Amt126            DECIMAL(19, 5),         Amt128            DECIMAL(19, 5),         Amt129            DECIMAL(19, 5),
        -- 130,131 2012년1기예정 신고 추가
        Amt130            DECIMAL(19, 5),         Amt131            DECIMAL(19, 5),             
        -- 2013년 1기 예정
        Amt47_1           DECIMAL(19, 5),         Amt48_1           DECIMAL(19, 5),         Amt48_2           DECIMAL(19, 5),         
        Amt48_3           DECIMAL(19, 5),     Amt48_4           DECIMAL(19, 5),         Amt61             DECIMAL(19, 5),
        Amt132            DECIMAL(19, 5),         Amt133            DECIMAL(19, 5),         Amt64             DECIMAL(19, 5),
        Amt65             DECIMAL(19, 5),         Amt51             DECIMAL(19, 5) )
  
    CREATE TABLE #TTAXVATRptTax (    
        TaxTermSeq          INT,    
        TaxUnit             INT,               
        Tax01             DECIMAL(19, 5),        Tax02             DECIMAL(19, 5),        Tax05             DECIMAL(19, 5),        
        Tax06             DECIMAL(19, 5),        Tax08             DECIMAL(19, 5),        Tax08_1           DECIMAL(19, 5),
        Tax09             DECIMAL(19, 5),        
        Tax10             DECIMAL(19, 5),        Tax12             DECIMAL(19, 5),        Tax14             DECIMAL(19, 5),    
        Tax15             DECIMAL(19, 5),        Tax16             DECIMAL(19, 5),        Tax17             DECIMAL(19, 5),    
        Tax19             DECIMAL(19, 5),        Tax26             DECIMAL(19, 5),        Tax27             DECIMAL(19, 5),    
        Tax31             DECIMAL(19, 5),        Tax32             DECIMAL(19, 5),        Tax33             DECIMAL(19, 5),    
        Tax34             DECIMAL(19, 5),        Tax35             DECIMAL(19, 5),        Tax37             DECIMAL(19, 5),    
        Tax38             DECIMAL(19, 5),        Tax39             DECIMAL(19, 5),        Tax41             DECIMAL(19, 5),    
        Tax42             DECIMAL(19, 5),        Tax43             DECIMAL(19, 5),        Tax44             DECIMAL(19, 5),    
        Tax46             DECIMAL(19, 5),        Tax47             DECIMAL(19, 5),        Tax48             DECIMAL(19, 5),    
        Tax49             DECIMAL(19, 5),        Tax50             DECIMAL(19, 5),        Tax57             DECIMAL(19, 5),    
        Tax58             DECIMAL(19, 5),        Tax59             DECIMAL(19, 5),        PaymentTax        DECIMAL(19, 5),    
        Tax43_1           DECIMAL(19, 5),        Tax32_1           DECIMAL(19, 5),        Tax46_1           DECIMAL(19, 5),    
        Tax15_1           DECIMAL(19, 5),        Tax117            DECIMAL(19, 5),        Tax119            DECIMAL(19, 5),    
        Tax120            DECIMAL(19, 5),        Tax122            DECIMAL(19, 5),        Tax07             DECIMAL(19, 5),  
        Tax11             DECIMAL(19, 5),        Tax13             DECIMAL(19, 5),        Tax18             DECIMAL(19, 5),  
        Tax20             DECIMAL(19, 5),        Tax30             DECIMAL(19, 5),        Tax36             DECIMAL(19, 5),  
        Tax40             DECIMAL(19, 5),        Tax45             DECIMAL(19, 5),        Tax51             DECIMAL(19, 5),  
        Tax60             DECIMAL(19, 5),        TaxDa             DECIMAL(19, 5),        Tax125            DECIMAL(19, 5),
        Tax127            DECIMAL(19, 5),        Tax128            DECIMAL(19, 5),        Tax129            DECIMAL(19, 5),
        -- 130,131 2012년1기예정 신고 추가
        Tax130            DECIMAL(19, 5),        Tax131            DECIMAL(19, 5),
        -- 2013년 1기 예정
        Tax47_1           DECIMAL(19, 5),         Tax48_1           DECIMAL(19, 5),         Tax48_2           DECIMAL(19, 5),         
        Tax48_3           DECIMAL(19, 5),         Tax48_4           DECIMAL(19, 5),         Tax61             DECIMAL(19, 5),
        Tax132            DECIMAL(19, 5),         Tax133            DECIMAL(19, 5),         Tax62             DECIMAL(19, 5),
        Tax63             DECIMAL(19, 5),         Tax64             DECIMAL(19, 5),         Tax65             DECIMAL(19, 5))
    
    INSERT INTO #TTAXVATRptAmt (TaxTermSeq , TaxUnit ,    
                                Amt01    , Amt02    , Amt03    , Amt04    , Amt05    , Amt06    , 
                                Amt08    , Amt09    , Amt10    , Amt12    , Amt14    , Amt21    , 
                                Amt22    , Amt23    , Amt24    , Amt26    , Amt27    , Amt28    , 
                                Amt29    , Amt31    , Amt32    , Amt33    , Amt37    , Amt38    , 
                                Amt39    , Amt41    , Amt42    , Amt43    , Amt44    , Amt46    , 
                                Amt47    , Amt48    , Amt49    , Amt50    , Amt52    , Amt53    , 
                                Amt55    , Amt56    , Amt57    , Amt58    , Amt59    , Amt16    , 
                                Amt43_1  , Amt32_1  , Amt46_1  , Amt116   , Amt118   , Amt121   , 
                                Amt123   , Amt07    , Amt11    , Amt13    , Amt25    , Amt30    , 
                                Amt36    , Amt40    , Amt45    , Amt54    , Amt60    , Amt124   , 
                                Amt126   , Amt128   , Amt129   , Amt130   , Amt131   , Amt47_1  , 
                                Amt48_1  , Amt48_2  , Amt48_3  , Amt48_4  , Amt61    , Amt132   ,
                                Amt133   , Amt64    , Amt65    , Amt51 )
        SELECT    
        @TaxTermSeq, @TaxUnit,    
        -- Amt01    , Amt02  , Amt03 ,    Amt04    , Amt05  , Amt06   , Amt08 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1040'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1050'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1060'), 0),   
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1070'), 0),         
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1090'), 0),    
        -- Amt09    , Amt10  , Amt12 ,    Amt14    , Amt21  , Amt22 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1100'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1130'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1150'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1220'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3020'), 0),    
        -- Amt23    , Amt24  , Amt26 ,    Amt27    , Amt28  , Amt29 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3040'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5030'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5040'), 0),    
        -- Amt31    , Amt32  , Amt33 ,    Amt37    , Amt38  , Amt39 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5090'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5100'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5110'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5170'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5180'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0),    
        -- Amt41    , Amt42  , Amt43 ,    Amt44    , Amt46  , Amt47 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5220'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5210'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5230'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5240'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5260'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5280'), 0),    
        -- Amt48    , Amt49  , Amt50 ,    Amt52    , Amt53  , Amt55 ,    
        ISNULL((SELECT SUM(ISNULL(SpplyAmt, 0)) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo IN ('5290', '5291', '5292', '5293')), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5300'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5310'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7010'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '8010'), 0),    
        -- Amt56    , Amt57  , Amt58 ,    Amt59    , Amt16  , Amt43_1 ,    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '8020'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1110'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5060'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5070'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0), -- ????    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0), -- ????    
        -- Amt32_1    , Amt46_1 , Amt116 ,    Amt118    , Amt121  , Amt123 )    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5120'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1025'), 0),    
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5095'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5276'), 0),   
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7025'), 0),   
        -- Amt07    , Amt11   , Amt13  ,   Amt25    , Amt30   , Amt36   ,  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),            
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1140'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3050'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5050'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5160'), 0),  
        -- Amt40    , Amt45   , Amt54  ,   Amt60
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5200'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5250'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptBizAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '7030'), 0),  
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5080'), 0),            
        -- Amt124   , Amt126  , Amt128  , Amt129
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5277'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5275'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5320'), 0),
        -- Amt130   , Amt131  , Amt47_1 , Amt48_1
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5225'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5273'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5281'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5290'), 0),        
        -- Amt48_2  , Amt48_3 , Amt48_4 , Amt61
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5291'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5292'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5293'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5321'), 0),
        -- Amt132, Amt133   , Amt64    , Amt65    , Amt51
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1020'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1120'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5325'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5327'), 0),
        ISNULL((SELECT ISNULL(SpplyAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0)
    INSERT INTO #TTAXVATRptTax (TaxTermSeq, TaxUnit  ,    
                                Tax01   , Tax02    , Tax05     , Tax06     , Tax08   , Tax08_1    , Tax09      ,    -- Tax08_1 : 2016.2기확정 :   수출기업 수입분 납부유예 (10-1) 추가 : dhkim3 2016.06.27   
                                Tax10   , Tax12    , Tax14     , Tax15     , Tax16   , Tax17      ,    
                                Tax19   , Tax26    , Tax27     , Tax31     , Tax32   , Tax33      ,    
                                Tax34   , Tax35    , Tax37     , Tax38     , Tax39   , Tax41  ,    
                                Tax42   , Tax43    , Tax44     , Tax46     , Tax47   , Tax48      ,    
                                Tax49   , Tax50    , Tax57     , Tax58     , Tax59   , PaymentTax ,    
                                Tax43_1 , Tax32_1  , Tax46_1   , Tax15_1   , Tax117  , Tax119     ,    
                                Tax120  , Tax122   , Tax07     , Tax11     , Tax13   , Tax18      ,  
                                Tax20   , Tax30    , Tax36     , Tax40     , Tax45   , Tax51      ,  
                                Tax60   , TaxDa    , Tax125    , Tax127    , Tax128  , Tax129     ,
                                Tax130  , Tax131   , Tax47_1   , Tax48_1   , Tax48_2 , Tax48_3    ,
                                Tax48_4 , Tax61    , Tax132    , Tax133    , Tax62   , Tax63      ,
                                Tax64   , Tax65)
        SELECT    
        @TaxTermSeq, @TaxUnit,    
        -- Tax01   , Tax02  , Tax05     , Tax06       , Tax08  , Tax08_1, Tax09     ,     
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1010'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1030'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1060'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1070'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1090'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1095'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1100'), 0),    
        -- Tax10   , Tax12  , Tax14     , Tax15       , Tax16  , Tax17     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1130'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1150'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1220'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1210'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1190'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1180'), 0),    
        -- Tax19   , Tax26  , Tax27     , Tax31       , Tax32  , Tax33     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1240'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5010'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5020'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5090'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5100'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5110'), 0),    
        -- Tax34   , Tax35  , Tax37     , Tax38       , Tax39  , Tax41     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5140'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5150'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5170'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5180'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5190'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5220'), 0),    
        -- Tax42   , Tax43  , Tax44     , Tax46       , Tax47  , Tax48     ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5210'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5230'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5240'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5260'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5280'), 0),    
        ISNULL((SELECT SUM(ISNULL(VATAmt, 0)) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo IN ('5290', '5291', '5292', '5293')), 0),    
        -- Tax49   , Tax50  , Tax57     , Tax58       , Tax59  , PaymentTax ,    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5300'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5310'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1110'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5060'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5070'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1260'), 0),    
        -- Tax43_1   , Tax32_1  , Tax46_1     , Tax15_1   , Tax117  , Tax119     ,    
   ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = 'XXXX'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5120'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1230'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1025'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5095'), 0),    
        -- Tax120   , Tax122  )    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5215'), 0),    
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5276'), 0),  
        -- Tax07     , Tax11     , Tax13   , Tax18      ,  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1080'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1140'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1160'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1200'), 0),  
        -- Tax20   , Tax30    , Tax36     , Tax40     , Tax45   , Tax51      ,  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1250'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5050'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5160'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5200'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5250'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5330'), 0),  
        -- Tax60   , TaxDa  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5080'), 0),  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1170'), 0),  
        -- Tax125   , Tax127,   Tax128,  Tax129
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5277'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5270'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5275'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5320'), 0),
        -- Tax130   , Tax131,   Tax47_1,  Tax48_1
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5225'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5273'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5281'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5290'), 0),                     
        -- Tax48_2  , Tax48_3,  Tax48_4,  Tax61  
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5291'), 0),        
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5292'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5293'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5321'), 0),
        -- Tax132    , Tax133    , Tax62   , Tax63      ,Tax64   , Tax65
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1020'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1120'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '1225'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5155'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5325'), 0),
        ISNULL((SELECT ISNULL(VATAmt, 0) FROM _TTAXVATRptAmt WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '5327'), 0)
        
    DECLARE @TermKind           CHAR(1),        -- 기수구분         '1', '2' (기수)
            @ProOrFix           CHAR(1),        -- 예정, 확정 구분  '1', '2' (1:예정, 2:확정)
            @TermKind_Bill      CHAR(1),        -- 계산서 기수구분
            @ProOrFix_Bill      CHAR(1),        -- 계산서 예정, 확정 구분
            @YearHalfMM         CHAR(1),        -- 반기내월
            @MinPaymentTax      DECIMAL(19,5),  -- (26) 차감.가감하여 납부할 세액(환급받을 세액)
            @BankCode           CHAR(3),        -- 은행코드
            @BankName           VARCHAR(30),    -- 은행명
            @BankAccNo          VARCHAR(20),    -- 계좌번호
            @BankHQName         NVARCHAR(100),  -- 금융기관
            @RtnTaxKind         CHAR(2),        -- 74. 환급구분
            @CloseDate          CHAR(8),        -- 79. 폐업일자
            @TaxationType       CHAR(1),        -- 83. 일반과세자구분
            @RtnTaxType         CHAR(1)         -- 84. 조기환급취소구분
    ---------------------------------------------------------------      
    --기수 및 예정, 확정 구분 / (계산서합계표는 별도로 값이 필요)          
    ---------------------------------------------------------------      
    IF      (SUBSTRING(@TaxFrDate, 5, 2) >= '01' AND SUBSTRING(@TaxFrDate, 5, 2) <= '03')   SELECT @TermKind = '1', @ProOrFix = '1' -- 1기 예정
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '04' AND SUBSTRING(@TaxFrDate, 5, 2) <= '06')   SELECT @TermKind = '1', @ProOrFix = '2' -- 1기 확정
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '07' AND SUBSTRING(@TaxFrDate, 5, 2) <= '09')   SELECT @TermKind = '2', @ProOrFix = '1' -- 2기 예정
    ELSE IF (SUBSTRING(@TaxFrDate, 5, 2) >= '10' AND SUBSTRING(@TaxFrDate, 5, 2) <= '12')   SELECT @TermKind = '2', @ProOrFix = '2' -- 2기 학정
  
    IF      (SUBSTRING(@BillToDate, 5, 2) >= '01' AND SUBSTRING(@BillToDate, 5, 2) <= '03') SELECT @TermKind_Bill = '1', @ProOrFix_Bill = '1' -- 1기 예정
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '04' AND SUBSTRING(@BillToDate, 5, 2) <= '06') SELECT @TermKind_Bill = '1', @ProOrFix_Bill = '2' -- 1기 확정
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '07' AND SUBSTRING(@BillToDate, 5, 2) <= '09') SELECT @TermKind_Bill = '2', @ProOrFix_Bill = '1' -- 2기 예정
    ELSE IF (SUBSTRING(@BillToDate, 5, 2) >= '10' AND SUBSTRING(@BillToDate, 5, 2) <= '12') SELECT @TermKind_Bill = '2', @ProOrFix_Bill = '2' -- 2기 학정
  
    ---------------------------------------------------------------
    -- 폐업신고를 하는 사업자의 경우 신고구분(@ProOrFix) : 확정(2)
    ---------------------------------------------------------------
    IF @BizCancelDate <> ''    
    BEGIN    
        SELECT @ProOrFix = '2', @ProOrFix_Bill = '2'
        SELECT @TaxToDate = @BizCancelDate
    END
    ----------------------------------------------------      
    -- 반기내 월순번 : 1/2/3/4/5/6 (단, 예정 3, 확정 6)
    ----------------------------------------------------
    IF DATEDIFF(mm, @TaxFrDate, @TaxToDate) <= 2 AND (SUBSTRING(@TaxToDate, 5, 2) NOT IN ('06', '12') ) -- 확정신고가 아닌 경우
    BEGIN  
        SELECT @YearHalfMM = ( CASE WHEN CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2)) <= 6
                                    THEN CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2))
                                    ELSE CONVERT(INT, SUBSTRING(@TaxToDate, 5, 2)) - 6 END )    
    END  
    ELSE    
    BEGIN  
        SELECT @YearHalfMM = CASE WHEN @Term_SMTaxationType = 4090001 THEN '3' ELSE '6' END      --  예정 3 , 확정 6
    END  
    SELECT @YearHalfMM = ISNULL(@YearHalfMM,'')
      
    -----------------------      
    --부가세환급 은행정보      
    -----------------------      
    SELECT @BankCode    = CONVERT(CHAR(3), ISNULL(MV.ValueText, ''))        , -- 은행코드    
           @BankName    = CONVERT(VARCHAR(30), ISNULL(B.BankName   , ''))   , -- 은행명
           @BankHQName  = ISNULL(M.MinorName, '')                           , -- 금융기관명
           @BankAccNo   = dbo._FCOMDecrypt(C.BankAccNo, '_TDABankAcc', 'BankAccNo', @CompanySeq)  -- 환급계좌
      FROM _TTAXVatRpt AS A WITH(NOLOCK)
                            LEFT OUTER JOIN _TDABank AS B WITH(NOLOCK)
                              ON A.CompanySeq   = B.CompanySeq    
                             AND A.BankSeq      = B.BankSeq    
                            LEFT OUTER JOIN _TDABankAcc AS C WITH(NOLOCK)
                              ON A.CompanySeq   = C.CompanySeq    
                             AND A.AccNoSeq     = C.BankAccSeq    
                            LEFT OUTER JOIN _TDAUMinor AS M WITH(NOLOCK)
                              ON A.CompanySeq   = M.CompanySeq    
                             AND B.BankHQ       = M.MinorSeq    
                             AND M.MajorSeq     = 4003    
                            LEFT OUTER JOIN _TDAUMinorValue AS MV WITH(NOLOCK)
                              ON A.CompanySeq   = MV.CompanySeq    
                             AND M.MinorSeq     = MV.MinorSeq    
                             AND MV.MajorSeq    = 4003    
                             AND MV.Serl        = 1001 --- 은행코드
     WHERE A.CompanySeq     = @CompanySeq    
    AND A.TaxTermSeq     = @TaxTermSeq    
       AND A.TaxUnit        = @TaxUnit
    SELECT @BankCode    = ISNULL(@BankCode      , ''),    
           @BankName    = ISNULL(@BankName      , ''),    
           @BankAccNo   = ISNULL(@BankAccNo     , '')        
       
    -- 하나은행/외환은행 통합에 따른 하나은행코드 대체
    IF ISNULL(@BankCode, '') = '005'    
        SELECT @BankCode = '081'    -- 하나은행
    IF @WorkingTag = ''
    BEGIN
        IF (@BankAccNo <> '' AND @BankName > '' AND @BankCode = '')
        BEGIN
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1248               , -- @1의 @2을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%입력%')  
                                  @LanguageSeq       ,
                                  0     ,   '@1'     ,          -- SELECT * FROM _TCADictionary WHERE Word LIKE '%거래은행%'
                                  31498 ,   '은행코드(FBS)'     -- SELECT * FROM _TCADictionary WHERE Word LIKE '%은행코드%'        
            SELECT -1 AS tmp_Seq, '부가세신고서-거래은행의 금융기관 ' + REPLACE(@Results, '@1', '[' + @BankHQName + ']') AS tmp_file
            RETURN
        
        END
    
        IF (NOT(@BankCode = '' AND @BankAccNo = '')) AND (NOT(@BankCode <> '' AND @BankAccNo <> ''))  
        BEGIN  
            SELECT @Results = '부가세신고서의 거래은행과 계좌번호가 모두 있거나 모두 없어야 합니다.'
            SELECT -1 AS tmp_Seq, @Results AS tmp_file
            RETURN
        END
    END
      
    --===========================================================================================
    -- 83. 일반과세자구분  
    -- 0 : 사업자단위신고.납부자가 아닌 일반 사업자
    -- 2 : 총괄납부사업자의 주사업자    
    -- 3 : 총괄납부사업자의 종사업자
    -- 5 : 사업자단위과세적용사업자    
    --===========================================================================================  
    IF @Env4016 = 4125002 AND (LEFT(@TaxFrDate, 6) + '01') >= @Env4017  -- 사업자단위신고
    BEGIN    
        SELECT @TaxationType = '5'    
    END
    ELSE
    BEGIN
        SELECT @TaxationType = CASE @Unit_SMTaxationType    -- 일반과세자구분
                                    WHEN 4128001 THEN '0'       -- 일반사업자
                                    WHEN 4128002 THEN '2'       -- 총괄납부 주사업자
                                    WHEN 4128003 THEN '3'       -- 총괄납부 종사업자
                                                 ELSE '0' END   -- 일반사업자
    END
    --===========================================================================================
    -- 74. 환급구분코드
    -- 일반환급                     [10] : 영세율환급/시설투자환급에 해당되지 않는 경우
    -- 영세율환급                   [20]     : (5,6) 영세율 매출이 있는 경우
    -- 시설투자환급                 [30] : (5,6) 영세율 매출은 없고 (11)고정자산 매입이 있는 경우
    -- 총괄납부주사업자환급         [40] : 총괄납부환급세액이 0 이상 & (26) 차가감납부할세액이 0 미만
    -- 총괄납부주사업자일반환급     [41] : 총괄납부환급세액이 0 미만 & 조기환급(영세율 및 시설투자환급)이 아닌 경우
    -- 총괄납부주사업자영세율환급   [42] : 총괄납부환급세액이 0 미만 & 영세율 환급
    -- 총괄납부주사업자시설투자환급 [43] : 총괄납부환급세액이 0 미만 & 시설투자환급
    -- 84. 조기환급취소구분
    -- 시설투자환급(30)에 해당되지만 환급받지 않을 경우 일반환급(10) & 조기환급취소(1)
    -- 총괄납부시설투자환급(43)인 경우 총괄일반환급(41) & 조기환급취소(1)
    -- 단, 영세율환급(20) 조기환급취소 불가
    --===========================================================================================
    SELECT @RtnTaxKind  = CASE ISNULL(SMRtnKind, 0)         -- 환급구분
                            WHEN 0       THEN '  '        -- 환급안함    
                            WHEN 4112001 THEN '  '        -- 환급안함    
                            WHEN 4112002 THEN '10'        -- 일반환급    
                            WHEN 4112003 THEN '20'        -- 영세율환급  
                            WHEN 4112004 THEN '30' END,   -- 시설투자환급            
           @RtnTaxType  = CASE WHEN ISNULL(IsNotEarlyRefund, '') = '' THEN '0'
                               ELSE ISNULL(IsNotEarlyRefund, '')
                          END,                              -- 조기환급취소구분(default '0')
           @CloseDate   = ISNULL(CloseDate  , '')           -- 폐업일자
      FROM _TTAXVatRpt WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq    
       AND TaxTermSeq   = @TaxTermSeq    
       AND TaxUnit      = @TaxUnit    
    -----------------------------------
    -- 총괄납부 주사업자인 경우
    -----------------------------------
    IF @TaxationType = '2'
    BEGIN
        -------------------------------------------------
        -- (26) 차감.가감하여 납부할 세액(환급받을 세액)
        -------------------------------------------------    
        SELECT @MinPaymentTax = Tax20
          FROM #TTAXVATRptTax
         WHERE TaxTermSeq   = @TaxTermSeq
           AND TaxUnit      = @TaxUnit
        SELECT @RtnTaxKind = CASE WHEN @RtnTaxKind =  '  ' 
                                   AND @MinPaymentTax < 0  THEN '40'  -- 총괄납부주사업자환급 (총괄납부세액 > 0 & (26) 차가감납부할세액 < 0)
                                  WHEN @RtnTaxKind =  '10' THEN '41'  -- 총괄납부주사업자일반환급
                                  WHEN @RtnTaxKind =  '20' THEN '42'  -- 총괄납부주사업자영세율환급
                                  WHEN @RtnTaxKind =  '30' THEN '43'  -- 총괄납부주사업자시설투자환급
                             ELSE @RtnTaxKind END
    END
    

    CREATE TABLE #CREATEFile_tmp (      
        tmp_seq     INT IDENTITY,      
        tmp_file    VARCHAR(3000),      
        tmp_size    INT )  
  
/***************************************************************************************************************************    
1. 부가가치세 Header    
    
01. 자료구분(2) : 11(일반)    
02. 서식코드(4) : I103200 / V101(일반과세자 부가세 신고서)
03. 납세자ID(13) : 사업자등록번호    
04. 세목코드(2) : 41(FIX)    
05. 신고구분코드(2)         -- 폐업신고를 하는 경우에는 예정기간도 확정신고로 신고한다.    
06. 신고구분상세코드(2)
07. 과세기간_년기(월)(6)    
08. 신고서종류코드(3)
09. 사용자ID(20)    
10. 납세자번호(13) : 주민등록번호(개인) 또는 법인등록번호(법인)    
11. 세무대리인성명(30)    
12. 세무대리인전화번호(4) - 지역번호    
13. 세무대리인전화번호(5) - 국번    
14. 세무대리인전화번호(5) - 나머지 번호    
15. 상호(법인명)(30)    
16. 성명(대표자명)(30)    
17. 사업장소재지(70)    
18. 사업장전화번호(14)    
19. 사업장주소(70)    
20. 사업자전화번호(14)    
21. 업태명(30)    
22. 업종명(50)    
23. 업종코드(7)    
24. 과세기간(8) : 시작일    
25. 과세기간(8) : 종료일    
26. 작성일자(8)    
27. 보정신고구분(1)    
28. 사업자휴대번호(14)    
29. 세무프로그램코드(4)    
30. 세무대리인사업자번호(13)    
31. 전자메일주소(50)    
32. 공란(65)    
*****************************************************************************************************************************/   
IF @WorkingTag = ''  
BEGIN  
    INSERT INTO #CREATEFile_tmp (tmp_File, tmp_size)  
    SELECT '11'  
          + 'I103200'                                                   --02. 서식코드(FIX)    
          + CONVERT(VARCHAR(13), REPLACE(TaxNo, '-', '')) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(TaxNo, '-', ''))))   --03. 납세자ID    
          + '41'                                                        --04. 세무구분코드(FIX)    
          + CASE WHEN @ProOrFix = '1' THEN '03' ELSE '01' END           --05. 신고구분
          + '01'                                                        --06. 신고구분상세코드 
          + SUBSTRING(@TaxToDate, 1, 4) + RIGHT('00' + @TermKind, 2)    --07. 과세기간_년기 
          + CASE WHEN @CloseDate > ''                THEN 'C07'      -- 폐업신고시 C07 (간이는 C03)
                 WHEN @Term_SMTaxationType = 4090001 THEN 'C17'      -- 예정 일반 신고
                 WHEN @Term_SMTaxationType = 4090002 THEN 'C07'      -- 확정 일반 신고
                 WHEN @Term_SMTaxationType = 4090004 THEN 'C07'      -- 확정 일반 신고
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) = '03' THEN 'C17'           -- 예정 일반 신고
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) = '12' THEN 'C07'           -- 확정 일반 신고
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('01', '07') THEN 'C15'  -- 예정 1,7월 조기 신고
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('02', '08') THEN 'C16'  -- 예정 2,8월 조기 신고
             WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('04', '10') THEN 'C05'  -- 확정 4,10월 조기 신고
                 WHEN @Term_SMTaxationType = 4090003 AND SUBSTRING(@TaxToDate, 5, 2) IN ('05', '11') THEN 'C06'  -- 확정 5,11월 조기 신고                 
                 ELSE SPACE(3)
            END      --8.신고서종류코드
          + CONVERT(VARCHAR(20), LTRIM(RTRIM(HomeTaxID))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(HomeTaxID))))) --9. 사용자ID    
          + CONVERT(VARCHAR(13), @CompanyNo) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), @CompanyNo)))             --10. 납세자번호    
          + SPACE(30)                                                   --11. 세무대리인성명    
          + SPACE(14)                                                   --12.13.14. 세무대리인전화번호    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM( CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END  )))    
                    + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM( CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END  )))))   --15. 상호(계산서상호로 출력) 2009.04.03 by 박근수    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner )))))   --16. 성명(대표자명)    
          + CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1))) + SPACE(70 - DATALENGTH(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))   --17. 사업장소재지    
          + CONVERT(VARCHAR(14), LTRIM(RTRIM(dbo._FnTaxTelChk(TelNo))))   + SPACE(14 - DATALENGTH(CONVERT(VARCHAR(14), LTRIM(RTRIM(dbo._FnTaxTelChk(TelNo))))))   --18. 전화번호    [전화번호]항목은 숫자,공란외의 문자는 입력못함. (,-등의 특수문자는 기재할 수 없음.    
          + SPACE(70)		                                --19. 사업자 주소    
          + SPACE(14)                                       --20. 사업자전화번호    
          + CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))))) --21. 업태명    
          + CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))))) --22. 종목명    
          + CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))) + SPACE(7  - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))))) --23. 주업종코드    
          + CONVERT(VARCHAR(8), @TaxFrDate) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @TaxFrDate)))    --24. 과세기간(시작일)    
          + CONVERT(VARCHAR(8), @TaxToDate) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @TaxToDate)))    --25. 과세기간(종료일)    
          + CONVERT(VARCHAR(8), @RptDate  ) + SPACE(8 - DATALENGTH(CONVERT(VARCHAR(8), @RptDate  )))    --26. 작성일자    
          + 'N'                 --27. 보정신고구분(Fix)
          + CONVERT(VARCHAR(14), LTRIM(RTRIM(ISNULL(CellPhone,'')))) + SPACE(14 - DATALENGTH(CONVERT(VARCHAR(14), LTRIM(RTRIM(ISNULL(CellPhone,'')))))) --28. 사업자휴대전화    
          + '9000'              --29. 세무프로그램코드    
          + SPACE(13)           --30. 세무대리인사업자번호    
          + CONVERT(VARCHAR(50), LTRIM(RTRIM(EMail)))     + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(EMail)))))  --31. 전자메일주소    
          + SPACE(65)           --32. 공란  
          , 600    
      FROM #TDATaxUnit WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq  
       AND TaxUnit    = @TaxUnit  
END        
  
/***************************************************************************************************************************    
2. 부가가치세_일반신고서    
01. 자료구분    (02)
02. 서식코드    (07)
03. 매출과세세금계산서발급금액   (15)
04. 매출과세세금계산서발급세액   (13)
05. 매출과세매입자발행세금계산서금액    (13)
06. 매출과세매입자발행세금계산서세액    (13)
07. 매출과세카드현금발행금액    (15)
08. 매출과세카드현금발행세액    (15)
09. 매출과세기타금액    (13)
10. 매출과세기타세액    (13)
11. 매출영세율세금계산서발급금액  (13)
12. 매출영세율기타금액   (15)
13. 매출예정누락합계금액  (13)
14. 매출예정누락합계세액  (13)
15. 예정누락매출세금계산서금액   (13)
16. 예정누락매출세금계산서세액   (13)
17. 예정누락매출과세기타금액    (13)
18. 예정누락매출과세기타세액    (13)
19. 예정누락매출영세율세금계산서금액    (13)
20. 예정누락매출영세율기타금액   (13)
21. 예정누락매출명세합계금액    (13)
22. 예정누락매출명세합계세액    (13)
23. 매출대손세액가감세액  (13)
24. 과세표준금액  (15)
25. 산출세액    (15)
26. 매입세금계산서수취일반금액   (15)
27. 매입세금계산서수취일반세액   (13)
28. 매입세금계산서수취고정자산금액 (13)
29. 매입세금계산서수취고정자산세액 (13)
30. 매입예정누락합계금액  (13)
31. 매입예정누락합계세액  (13)
32. 예정누락매입신고세금계산서금액 (13)
33. 예정누락매입신고세금계산서세액 (13)
34. 예정누락매입기타공제금액    (13)
35. 예정누락매입기타공제세액    (13)
36. 예정누락매입명세합계금액    (13)
37. 예정누락매입명세합계세액    (13)
38. 매입자발행세금계산서매입금액  (13)
39. 매입자발행세금계산서매입세액  (13)
40. 매입기타공제매입금액  (13)
41. 매입기타공제매입세액  (13)
42. 그밖의공제매입명세합계금액   (13)
43. 그밖의공제매입명세합계세액   (13)
44. 매입세액합계금액    (15)
45. 매입세액합계세액    (13)
46. 공제받지못할매입합계금액    (13)
47. 공제받지못할매입합계세액    (13)
48. 공제받지못할매입금액  (13)
49. 공제받지못할매입세액  (13)
50. 공제받지못할공통매입면세사업금액    (13)
51. 공제받지못할공통매입면세사업세액    (13)
52. 공제받지못할대손처분금액    (13)
53. 공제받지못할대손처분세액    (13)
54. 공제받지못할매입명세합계금액  (13)
55. 공제받지못할매입명세합계세액  (13)
56. 차감합계금액  (15)
57. 차감합계세액  (13)
58. 납부(환급)세액    (13)
59. 그밖의경감공제세액   (15)
60. 그밖의경감공제명세합계세액   (15)
61. 경감공제합계세액    (13)
62. 예정신고미환급세액   (13)
63. 예정고지세액  (13)
64. 사업양수자의대리납부기납부세액 (13)
65. 매입자납부특례기납부세액    (13)
66. 가산세액계   (13)
67. 차감납부할세액 (15)
68. 과세표준명세수입금액제외금액  (13)
69. 과세표준명세합계수입금액    (15)
70. 면세사업수입금액제외금액    (13)
71. 면세사업합계수입금액  (15)
72. 계산서교부금액 (15)
73. 계산서수취금액 (15)
74. 환급구분코드  (02)
75. 은행코드(국세환급금) (03)
76. 계좌번호(국세환급금) (20)
77. 총괄납부승인번호    (09)
78. 은행지점명   (30)
79. 폐업일자    (08)
80. 폐업사유    (03)
81. 기한후(과세표준)여부 (01)
82. 실차감납부할세액    (15)
83. 일반과세자구분 (01)
84. 조기환급취소구분    (01)
85. 수출기업 수입 납부유예 (15)
86. 공란  (28)
*****************************************************************************************************************************/   
  
IF @WorkingTag = ''  
BEGIN   
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
    SELECT '17'    
          + 'I103200'    
          + CASE WHEN Amt.Amt01 >= 0 THEN    
                  RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt01)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt01))), 15), 1, 1, '-')    
             END  --03. 과표신고 과세세금계산서금액    
          + CASE WHEN Tax.Tax01 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax01)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax01))), 13), 1, 1, '-')    
             END  --04. 과표신고 과세세금계산서세액
------------------------------------------------------------------------------------------------------
		  + CASE WHEN ISNULL(Amt.Amt132,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt132)), 13)
              ELSE
                 STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt132))), 13), 1, 1, '-')
              END   --05. 매출과세매입자발행세금계산서금액
          + CASE WHEN ISNULL(Tax.Tax132,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax132)), 13)            
             ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax132))), 13), 1, 1, '-')
             END    --06. 매출과세매입자발행세금계산서세액
------------------------------------------------------------------------------------------------------             
          + dbo._FnVATIntChg(ISNULL(Amt.Amt116,0),15,0,1)            --07.매출과세카드현금발행금액
          + dbo._FnVATIntChg(ISNULL(Tax.Tax117,0),15,0,1)            --08.매출과세카드현금발행세액 
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt02 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt02)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt02))), 13), 1, 1, '-')    
             END  --09. 매출과세기타금액        
          + CASE WHEN Tax.Tax02 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax02)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax02))), 13), 1, 1, '-')    
             END  --10. 매출과세기타세액
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt03 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt03)), 13)    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt03))), 13), 1, 1, '-')    
             END  --11. 매출영세율세금계산서발급금액 
          + CASE WHEN Amt.Amt04 >= 0 THEN    
                  RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt04)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt04))), 15), 1, 1, '-')    
             END  --12. 매출영세율기타금액
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt05 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt05)), 13)   
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt05))), 13), 1, 1, '-')    
             END  --13. 매출예정누락합계금액   
          + CASE WHEN Tax.Tax05 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax05)), 13)            
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax05))), 13), 1, 1, '-')    
             END  --14, 매출예정누락합계세액                    
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt26 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt26)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt26))), 13), 1, 1, '-')    
             END  --15. 예정누락매출세금계산서금액 
          + CASE WHEN Tax.Tax26 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax26)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax26))), 13), 1, 1, '-')    
             END  --16. 예정누락매출세금계산서세액      
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt27 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt27)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt27))), 13), 1, 1, '-')    
             END  --17. 예정누락매출과세기타금액
          + CASE WHEN Tax.Tax27 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax27)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax27))), 13), 1, 1, '-')    
             END  --18. 예정누락매출과세기타세액    
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt28 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt28)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt28))), 13), 1, 1, '-')    
             END  --19. 예정누락매출영세율세금계산서금액 
          + CASE WHEN Amt.Amt29 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt29)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt29))), 13), 1, 1, '-')    
             END  --20. 예정누락매출영세율기타금액
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29)), 13)        
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt26 + Amt.Amt27 + Amt.Amt28 + Amt.Amt29))), 13), 1, 1, '-')    
             END  --21. 예정누락매출명세합계금액
          + CASE WHEN Tax.Tax26 + Tax.Tax27 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax26 + Tax.Tax27)), 13)             
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax26 + Tax.Tax27))), 13), 1, 1, '-')    
             END  --22. 예정누락매출명세합계세액
------------------------------------------------------------------------------------------------------                    
          + CASE WHEN Tax.Tax06 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax06)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax06))), 13), 1, 1, '-')    
             END   --23. 매출대손세액가감세액 
          + CASE WHEN FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0)) >= 0 THEN    
                    RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0))), 15)     
             ELSE    
                    STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt01 + Amt.Amt02 + Amt.Amt03 + Amt.Amt04 + Amt.Amt05 + ISNULL(Amt116,0) + ISNULL(Amt132, 0)))), 15), 1, 1, '-')    
             END   --24. 과세표준금액   
          + CASE WHEN Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0)>= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0))), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax01 + Tax.Tax02 + Tax.Tax05 + Tax.Tax06 + ISNULL(Tax.Tax117,0) + ISNULL(Tax.Tax132,0)))), 15), 1, 1, '-')    
             END   --25. 산출세액 2008년2기 예정 by 박근수 : 음수 처리로 변경                               
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt08) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08))), 15), 1, 1, '-')    
             END   --26. 매입세금계산서수취일반금액          
          + CASE WHEN FLOOR(Tax.Tax08) >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08))), 13), 1, 1, '-')    
             END  --27. 매입세금계산서수취일반세액     
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt09 >= 0 THEN    
                  RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt09)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt09))), 13), 1, 1, '-')    
             END  --28. 매입세금계산서수취고정자산금액    
          + CASE WHEN Tax.Tax09 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax09)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax09))), 13), 1, 1, '-')    
             END  --29. 매입세금계산서수취고정자산세액 
------------------------------------------------------------------------------------------------------
		  + CASE WHEN Amt.Amt57 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt57)), 13)            --30. 매입예정누락합계금액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt57))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax57 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax57)), 13)            --31. 매입예정누락합계세액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax57))), 13), 1, 1, '-')    
             END                     
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt58 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt58)), 13)            --32. 예정누락매입신고세금계산서금액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt58))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax58 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax58)), 13)            --33. 예정누락매입신고세금계산서세액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax58))), 13), 1, 1, '-')    
             END                 
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt59 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt59)), 13)            --34. 예정누락매입기타공제금액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt59))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax59 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax59)), 13)            --35. 예정누락매입기타공제세액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax59))), 13), 1, 1, '-')    
             END                 
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt58 + Amt.Amt59) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt58 + Amt.Amt59)), 13)         --36. 예정누락매입명세합계금액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt58 + Amt.Amt59))), 13), 1, 1, '-')    
             END    
          + CASE WHEN FLOOR(Tax.Tax58 + Tax.Tax59) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax58 + Tax.Tax59)), 13)            --37. 예정누락매입명세합계세액    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax58 + Tax.Tax59))), 13), 1, 1, '-')    
             END                                   
------------------------------------------------------------------------------------------------------
          + CASE WHEN isnull(Amt.Amt133,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt133)), 13)            --38.매입자발행세금계산서매입금액
              ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt133))), 13), 1, 1, '-')
              END
           + CASE WHEN isnull(Tax.Tax133,0) >= 0 THEN
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax133)), 13)            --39.매입자발행세금계산서매입세액
              ELSE
               STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax133))), 13), 1, 1, '-')
              END  
------------------------------------------------------------------------------------------------------
          + CASE WHEN Amt.Amt10 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt10)), 13)            --40. 매입기타공제매입금액    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt10))), 13), 1, 1, '-')    
             END    
          + CASE WHEN Tax.Tax10 >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax10)), 13)            --41. 매입기타공제매입세액    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax10))), 13), 1, 1, '-')    
             END                   
------------------------------------------------------------------------------------------------------  
          + CASE WHEN FLOOR(Amt.Amt31 + Amt.Amt118 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0)) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt31 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0))), 13)       
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt31 + Amt.Amt32 + Amt.Amt33 +  ISNULL(Amt.Amt118,0)))), 13), 1, 1, '-')    
             END  --42. 기타공제매입명세합계금액       
          + CASE WHEN FLOOR(Tax.Tax31 + Tax.Tax119 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0)) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax31 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0))), 13) 
    
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax31 + Tax.Tax32 + Tax.Tax33 + Tax.Tax34 + Tax.Tax35 + Tax.Tax63 + ISNULL(Tax.Tax119,0)))), 13), 1, 1, '-')    
             END  --43. 기타공제매입명세합계세액   
------------------------------------------------------------------------------------------------------                                                
          + CASE WHEN FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133))), 15), 1, 1, '-')    
             END                      --44. 매입세액합계금액    
          + CASE WHEN FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133))), 13), 1, 1, '-')    
             END                      --45. 매입세액합계세액                 
------------------------------------------------------------------------------------------------------ 
          + CASE WHEN FLOOR(Amt.Amt12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt12))), 13), 1, 1, '-')    
             END                           --46. 공제받지못할매입합계금액    
          + CASE WHEN FLOOR(Tax.Tax12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax12))), 13), 1, 1, '-')    
             END                           --47. 공제받지못할매입합계세액      
------------------------------------------------------------------------------------------------------               
          + CASE WHEN FLOOR(Amt.Amt37) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt37)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt37))), 13), 1, 1, '-')    
             END                           --48. 공제받지못할매입금액    
          + CASE WHEN FLOOR(Tax.Tax37) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax37)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax37))), 13), 1, 1, '-')    
             END                           --49. 공제받지못할매입세액    
------------------------------------------------------------------------------------------------------              
          + CASE WHEN FLOOR(Amt.Amt38) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt38)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt38))), 13), 1, 1, '-')    
             END                           --50. 공제받지못할공통매입면세사업금액    
          + CASE WHEN FLOOR(Tax.Tax38) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax38)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax38))), 13), 1, 1, '-')    
             END                           --51. 공제받지못할공통매입면세사업세액 
------------------------------------------------------------------------------------------------------
          + CASE WHEN FLOOR(Amt.Amt51) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt51)), 13)    
             ELSE                          --52. 공제받지못할대손처분금액                
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt51))), 13), 1, 1, '-')    
             END                                     
          + CASE WHEN FLOOR(Tax.Tax39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax39))), 13), 1, 1, '-')    
             END                           --53. 공제받지못할대손처분세액         
------------------------------------------------------------------------------------------------------           
          + CASE WHEN FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt37 + Amt.Amt38 + Amt.Amt39))), 13), 1, 1, '-')    
             END                           --54. 공제받지못할매입명세합계금액    
          + CASE WHEN FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax37 + Tax.Tax38 + Tax.Tax39))), 13), 1, 1, '-')    
             END                           --55. 공제받지못할매입명세합계세액         
------------------------------------------------------------------------------------------------------          
          + CASE WHEN (Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt08 + Amt.Amt09 + Amt.Amt57 + Amt.Amt10 + Amt.Amt133 - Amt12))), 15), 1, 1, '-')    
             END                           --56. 차감합계금액
          + CASE WHEN (Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax08 - Tax.Tax08_1 + Tax.Tax09 + Tax.Tax57 + Tax.Tax10 + Tax.Tax133 - Tax12))), 13), 1, 1, '-')    
             END                           --57. 차감합계세액       
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.TaxDa >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.TaxDa)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.TaxDa))), 13), 1, 1, '-')    
             END                           --58. 납부(환급)세액          
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.Tax17 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax17)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax17))), 15), 1, 1, '-')    
             END                            --59. 기타경감공제세액      
          + CASE WHEN Tax.Tax45 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax45)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax45))), 15), 1, 1, '-')    
             END							--60. 기타경감공제명세합계세액                   
          + CASE WHEN FLOOR(Tax.Tax16 + Tax.Tax17) >= 0 THEN    
                    RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax16 + Tax.Tax17)), 13)         
             ELSE    
                    STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax16 + Tax.Tax17))), 13), 1, 1, '-')    
             END                            --61. 경감공제합계세액      
------------------------------------------------------------------------------------------------------
          + CASE WHEN Tax.Tax15 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax15)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax15))), 13), 1, 1, '-')    
             END                           --62. 예정신고미환급세액          
          + CASE WHEN Tax.Tax14 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax14)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax14))), 13), 1, 1, '-')    
             END                           --63. 예정고지세액                  
------------------------------------------------------------------------------------------------------
          + CASE WHEN isnull(Tax.Tax62,0) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax62)), 13)            
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax62))), 13), 1, 1, '-')    
             END                           -- 64.사업양수자의대리납부기납부세액
          + CASE WHEN isnull(Tax.Tax15_1,0) >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax15_1)), 13)            
             ELSE    
              STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Tax.Tax15_1))), 13), 1, 1, '-')    
             END                           --65.매입자납부특례기납부세액
------------------------------------------------------------------------------------------------------
		  + RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Tax.Tax19)), 13)           --66. 가산세액계                     
------------------------------------------------------------------------------------------------------
          + CASE WHEN (Tax.Tax20) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax20)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax20))), 15), 1, 1, '-')    
             END                           --67. 차감납부할세액    
------------------------------------------------------------------------------------------------------                
          + CASE WHEN Amt.Amt24 >= 0 THEN    
                   RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(Amt.Amt24)), 13)    
             ELSE    
                   STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(Amt.Amt24))), 13), 1, 1, '-')    
             END                     --68. 기타수입금액합계-> 과세수입금액제외금액으로 명칭 바뀜     
          + CASE WHEN (Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24) >= 0 THEN    
							RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt21 + Amt.Amt22 + Amt.Amt23 + Amt.Amt24))), 15), 1, 1, '-')    
             END                           --69. 과세표준명세합계수입금액
          + dbo._FnVATIntChg(isnull(Amt.Amt123,0),13,0,1)            --70.면세사업수입금액제외금액
          + CASE WHEN (Amt.Amt52 + Amt.Amt53 + Amt.Amt123) >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt52 + Amt.Amt53 + ISNULL(Amt.Amt123,0))), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt52 + Amt.Amt53 + ISNULL(Amt.Amt123,0)))), 15), 1, 1, '-')    
             END                           --71. 면세사업합계수입금액         
------------------------------------------------------------------------------------------------------       
          + CASE WHEN Amt.Amt55 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt55)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt55))), 15), 1, 1, '-')    
             END                            --72. 계산서교부금액    
          + CASE WHEN Amt.Amt56 >= 0 THEN    
                   RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Amt.Amt56)), 15)    
             ELSE    
                   STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Amt.Amt56))), 15), 1, 1, '-')    
             END                            --73. 계산서수취금액   
------------------------------------------------------------------------------------------------------
		  + CONVERT(CHAR(2), @RtnTaxKind)   --74. 환급구분코드 
		  + LTRIM(RTRIM(@BankCode       )) + SPACE(3  - DATALENGTH(LTRIM(RTRIM(@BankCode       )))) --75. 은행코드(국세환급금)
		  + LTRIM(RTRIM(@BankAccNo      )) + SPACE(20 - DATALENGTH(LTRIM(RTRIM(@BankAccNo      )))) --76. 계좌번호(국세환급금)
		  + LTRIM(RTRIM(@TaxSumPaymentNo)) + SPACE(9  - DATALENGTH(LTRIM(RTRIM(@TaxSumPaymentNo)))) --77. 총괄납부승인번호
          + LTRIM(RTRIM(@BankName       )) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(@BankName       )))) --78. 은행지점명     
          + LTRIM(RTRIM(@CloseDate      )) + SPACE(8  - DATALENGTH(LTRIM(RTRIM(@CloseDate      )))) --79. 폐업일자
          + SPACE(3)                --80. 폐업사유(전자신고는 공란으로만)    
          + 'N'                     --81. 기한후(과세표준)여부, 'N'으로 Fix    
          + CASE @TaxationType
                WHEN '3' THEN '000000000000000'                             -- 총괄납부 종사업자   0을 기재    
                WHEN '2' THEN CASE WHEN ISNULL(Tax.PaymentTax, 0) >= 0      -- 총괄납부 주사업자만 총괄납부할세액(환급받을 세액) 입력
                                   THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(ISNULL(Tax.PaymentTax, 0))) , 15)    
                                   ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(ISNULL(Tax.PaymentTax, 0)))), 15), 1, 1, '-')
                              END
                         ELSE CASE WHEN (Tax.Tax20) >= 0                    -- 그 외사업자는 (67) 차감납부할 세액 입력
                                   THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(Tax.Tax20)) , 15)    
                                   ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax20))), 15), 1, 1, '-')    
                              END
            END                     --82. 실차감납부할세액
		   + @TaxationType          --83. 일반과세자구분 
		   + @RtnTaxType            --84. 조기환급취소구분  
           + CASE WHEN FLOOR(Tax.Tax08_1) >= 0 
                  THEN       RIGHT('000000000000000' + CONVERT(VARCHAR(15),     FLOOR(Tax.Tax08_1)) , 15)    
                  ELSE STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax08_1))), 15), 1, 1, '-')    
             END                    --85.수출기업 수입 납부유예 
           + SPACE(28)              --85.공란
           , 1100
    FROM #TTAXVATRptAmt Amt JOIN #TTAXVATRptTax Tax  
                              ON Amt.TaxTermSeq     = Tax.TaxTermSeq  
                             AND Amt.TaxUnit        = Tax.TaxUnit  
    WHERE Amt.TaxTermSeq    = @TaxTermSeq  
      AND Amt.TaxUnit       = @TaxUnit  
END
/***************************************************************************************************************************    
부가가치세 - 수입금액 등      
01. 자료구분(2) : 15    
02. 서식코드(7) : I103200
03. 수입금액종류구분(2) : 업종별수입금액 '01', 수입금액제외 '02', 신용카드발행공제세액 '04',
                          기타수입금액   '07', 면세수입금액 '08', 면세수입금액제외     '14'
04. 업태명(30)    
05. 종목명(50)    
06. 업종코드(7)    
07. 수입금액(15)    
08. 공란(37)    
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
    BEGIN  
    ---------------------------    
    -- 1. 과세표준명세    
    ---------------------------    
    IF (SELECT Amt21 + Amt22 + Amt23 FROM #TTAXVATRptAmt WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) = 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'        --01. 자료구분    
               + 'I103200'  --02. 서식코드    
               + '01'       --03. 수입금액종류구분    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(BizType     )))))    --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(BizItem     )))))    --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(TaxBizTypeNo)))))    --06. 주업종코드    
               + '000000000000000'                 --07. 수입금액    
               + SPACE(37)    
               , 150    
         FROM #TDATaxUnit WITH(NOLOCK)
         WHERE CompanySeq   = @CompanySeq  
           AND TaxUnit      = @TaxUnit  
    END    
    ELSE    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. 자료구분    
               + 'I103200'      --02. 서식코드    
               + '01'           --03. 수입금액종류구분    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, '')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, ''))))))   --06. 업종코드    
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. 수입금액    
               + SPACE(37)    
               , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit 
             AND A.SpplyAmt         <> 0
             AND A.RptNo            IN ('3010', '3020', '3030')
           ORDER BY A.RptNo
    END    
  
    ---------------------------    
    -- 2. 수입금액제외    
    ---------------------------    
    IF (SELECT SpplyAmt FROM _TTAXVATRptBizAmt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND RptNo = '3040') <> 0  
    BEGIN  
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'        --01. 자료구분    
               + 'I103200'  --02. 서식코드    
               + '02'       --03. 수입금액종류구분    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM('수입금액제외'       ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM('수입금액제외'       )))))   --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType, '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType, ''))))))   --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(@TaxBizTypeNo        ))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(@TaxBizTypeNo        )))))   --06. 업종코드 (주업종코드)   
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. 수입금액    
               + SPACE(37)    
               , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.RptNo        = B.RptSort  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            = '3040'  
    END  
  
    ---------------------------    
    -- 4. 신용카드발행공제세액등    
    ---------------------------    
    IF (SELECT Tax16 FROM #TTAXVATRptTax WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0  
    BEGIN  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
         SELECT '15'                --01. 자료구분    
               + 'I103200'      --02. 서식코드    
               + '04'           --03. 신용카드발행공제세액    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     )))))   --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     )))))   --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo)))))   --06. 업종코드    
               + CASE WHEN Tax.Tax16 >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax16)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax16))), 15), 1, 1, '-')    
                  END         --07. 수입금액    
               + SPACE(37)    
               , 150    
         FROM #TTAXVATRptTax AS Tax JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                      ON ComInfo.CompanySeq = @CompanySeq  
                                     AND Tax.TaxUnit        = ComInfo.TaxUnit  
        WHERE Tax.TaxTermSeq    = @TaxTermSeq  
          AND Tax.TaxUnit       = @TaxUnit  
    END  
  
    ---------------------------    
    -- 7. 기타경감, 공제세액    
    ---------------------------    
    IF (SELECT Tax17 FROM #TTAXVATRptTax WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. 자료구분    
               + 'I103200'  --02. 서식코드    
               + '07'       --03. 신용카드발행공제세액    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.BizType     )))))   --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     ))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ComInfo.BizItem     )))))   --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ComInfo.TaxBizTypeNo)))))   --06. 업종코드    
               + CASE WHEN Tax.Tax17 >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Tax.Tax17)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Tax.Tax17))), 15), 1, 1, '-')    
                  END         --07. 수입금액    
               + SPACE(37)    
               , 150    
         FROM #TTAXVATRptTax AS Tax JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                      ON ComInfo.CompanySeq = @CompanySeq  
                                     AND Tax.TaxUnit        = ComInfo.TaxUnit  
        WHERE Tax.TaxTermSeq    = @TaxTermSeq  
          AND Tax.TaxUnit       = @TaxUnit  
    END    
  
  
    ---------------------------    
    -- 8. 면세사업수입금액    
    ---------------------------    
    IF (SELECT Amt52 + Amt53 + Amt123 FROM #TTAXVATRptAmt WHERE TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit) <> 0    
    BEGIN    
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '15'            --01. 자료구분    
                   + 'I103200'  --02. 서식코드    
                   + '08'       --03. 수입금액종류구분    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. 업태명    
                   + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. 종목명    
                   + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, '')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(B.BizTypeSeq, ''))))))   --06. 업종코드    
                   + CASE WHEN A.SpplyAmt >= 0 THEN    
                           RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                      ELSE    
                           STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                      END         --07. 수입금액    
                   + SPACE(37)    
                   , 150  
            FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                             AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            IN ('7010', '7020') 
             AND A.SpplyAmt        <> 0  
         UNION  
         SELECT '15'            --01. 자료구분    
               + 'I103200'  --02. 서식코드    
               + '14'       --03. 수입금액종류구분    
               + CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , '')))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ISNULL(B.BizCond   , ''))))))   --04. 업태명    
               + CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , '')))) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), LTRIM(RTRIM(ISNULL(B.BizType   , ''))))))   --05. 종목명    
               + CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(@TaxBizTypeNo,'')))) + SPACE(07 - DATALENGTH(CONVERT(VARCHAR(07), LTRIM(RTRIM(ISNULL(@TaxBizTypeNo,''))))))   --06. 업종코드(주업종코드)
               + CASE WHEN A.SpplyAmt >= 0 THEN    
                       RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.SpplyAmt)), 15)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.SpplyAmt))), 15), 1, 1, '-')    
                  END         --07. 수입금액    
               + SPACE(37)    
               , 150  
       FROM _TTAXVATRptBizAmt AS A WITH(NOLOCK)
                                        JOIN _TTAXBizKind AS B WITH(NOLOCK)
                                          ON A.CompanySeq   = B.CompanySeq  
                                         AND A.TaxUnit      = B.TaxUnit  
                                         AND A.BizKindSeq   = B.BizKindSeq  
           WHERE A.CompanySeq       = @CompanySeq  
             AND A.TaxTermSeq       = @TaxTermSeq  
             AND A.TaxUnit          = @TaxUnit  
             AND A.RptNo            = '7025'  
             AND A.SpplyAmt        <> 0  
    END  
END  
/***************************************************************************************************************************    
부가가치세 - 공제감면 신고서    
01. 자료구분(2) : 14    
02. 서식코드(7) : I103200
03. 공제감면코드(3)
04. 등록일련번호(12) : "1" FIX
05. 공제감면금액
06. 공제감면세액
07. 공란
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '14'             -- 01. 자료구분
        + 'I103200'     -- 02. 서식코드
        + CASE RptNo WHEN '5090' THEN '211'         -- 신용카드 매출전표등 수령명세서 제출분 일반매입
                     WHEN '5095' THEN '212'         -- 신용카드 매출전표등 수령명세서 제출분 고정자산매입
                     WHEN '5100' THEN '230'         -- 의제매입세액
                     WHEN '5110' THEN '270'         -- 재활용 폐자원등 매입세액
                     WHEN '5130' THEN '291'         -- 과세사업전환 매입세액
                     WHEN '5140' THEN '292'         -- 재고매입세액
                     WHEN '5150' THEN '293'         -- 변제대손세액
                     WHEN '5155' THEN '294'         -- 외국인 관광객에 대한 환급세액
                     WHEN '5210' THEN '310'         -- 전자신고 세액 공제
                     WHEN '5215' THEN '321'         -- 전자세금계산서 발급세액
                     WHEN '5220' THEN '331'         -- 택시운송사업자경감세액
                     WHEN '5230' THEN '351'         -- 현금영수증 사업자 세액
                     WHEN '5240' THEN '361'         -- 기타공제
                     WHEN '1190' THEN '410'         -- 신용카드 매출전표등 발행공제 등
                     ELSE SPACE(3) END                      -- 03. 공제감면코드
        + '000000000001'                                    -- 04. 등록일련번호 (Fix "1")
        + dbo._FnVATIntChg(ISNULL(A.SpplyAmt,0),15,0,1)     -- 05. 공제감면금액
        + dbo._FnVATIntChg(ISNULL(A.VATAmt  ,0),15,0,1)     -- 06. 공제감면세액 
        + SPACE(46)                                         -- 07. 공란
        ,100                                   
       FROM _TTAXVATRptAmt AS A WITH(NOLOCK)
      WHERE CompanySeq    = @CompanySeq  
        AND TaxTermSeq    = @TaxTermSeq  
        AND TaxUnit       = @TaxUnit
        AND (A.SpplyAmt   <> 0 OR A.VATAmt     <> 0)        -- 감면세액만 있는 항목도 존재
        AND RptNo IN ('5090','5095','5100','5110','5130','5140',
                      '5150','5155','5210','5215','5220','5230',
                      '5240','1190')
END
/***************************************************************************************************************************    
부가가치세 - 가산세 신고서     
01. 자료구분(2) : 13    
02. 서식코드(7) : I103200
03. 가산세코드(10)
04. 등록일련번호(12) : "1" FIX
05. 가산세금액
06. 가산세액
07. 공란
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '13'             -- 01. 자료구분
            + 'I103200'     -- 02. 서식코드
            + CASE RptNo WHEN '5260' THEN 'B1100'       -- 사업자미등록
                         WHEN '5270' THEN 'B3100'       -- 세금계산서지연발급
                         WHEN '5273' THEN 'B3200'       -- 세금계산서지연수취
                         WHEN '5275' THEN 'B3400'       -- 세금계산서미발급
                         WHEN '5276' THEN 'B4300'       -- 전자세금계산서지연전송
                         WHEN '5277' THEN 'B4100'       -- 전자세금계산서미전송
                         WHEN '5280' THEN 'B5100'       -- 세금계산서제출불성실
                         WHEN '5281' THEN 'B5300'       -- 세금계산서지연제출
                         WHEN '5290' THEN 'A2110'       -- 신고불성실무신고일반
                         WHEN '5291' THEN 'A2210'       -- 신고불성실무신고부당                        
                         WHEN '5292' THEN 'A3110'       -- 신고불성실과소,초과환급신고일반
                         WHEN '5293' THEN 'A3210'       -- 신고부성싱과소,초과환급신고부당
                         WHEN '5300' THEN 'A7100'       -- 납부불성실
                         WHEN '5310' THEN 'A4200'       -- 영세율과세표준신고불성실
                         WHEN '5320' THEN 'B7100'       -- 현금매출명세서불성실
                         WHEN '5321' THEN 'B7200'       -- 부동산임대공급가액명세서불성실
                         WHEN '5325' THEN 'B9100'       -- 매입자납부특례거래계좌미사용
                         WHEN '5327' THEN 'B9200'       -- 매입자납부특례거래계좌지연입금
                         ELSE SPACE(5) END + SPACE(5)           -- 03. 가산세코드
            + '000000000001'                                    -- 04. 등록일련번호 (Fix "1")
            + dbo._FnVATIntChg(ISNULL(A.SpplyAmt,0),15,0,1)     -- 05. 가산세금액
            + dbo._FnVATIntChg(ISNULL(A.VATAmt  ,0),15,0,1)     -- 06. 가산세액
            + SPACE(39)                                         -- 07. 공란
            ,100
       FROM _TTAXVATRptAmt AS A WITH(NOLOCK)
      WHERE CompanySeq    = @CompanySeq  
        AND TaxTermSeq    = @TaxTermSeq  
        AND TaxUnit       = @TaxUnit
        AND (A.SpplyAmt   <> 0 OR A.VATAmt     <> 0)            -- 감면세액만 있는 항목도 존재
        AND RptNo IN ('5260','5270','5273','5275','5276','5277',
                      '5280','5281','5290','5291','5292','5293',
                      '5300','5310','5320','5321','5325','5327')
END
    
  
/***************************************************************************************************************************    
사업장현황명세서    
    
01. 자료구분(2) : 14    
02. 서식코드(7) : I104400 / V142
03. 자_타가 구분(2) : '01' 자가, '02' 타가    
04. 사업장대지(7)    
05. 사업장건물_지하(3)    
06. 사업장건물_지상(3)    
07. 사업장건물 바닥면적(7)    
08. 사업장건물 연면적(7)    
09. 객실수(7)    
10. 탁자수(7)    
11. 의자수(7)    
12. 주차장 유·무(1) : 'Y' 유, 'N' 무    
13. 종업원수(7)    
14. 차량수(승용차)(7)    
15. 차량수(화물차)(7)    
16. 월기준(2) : 타가인 경우 '06' 6월기준, '12' 12월기준    
17. 보증금(9)    
18. 월세(11)    
19. 전기_가스료(9)    
20. 수도료(9)    
21. 인건비(9)    
22. 기타경비(9)    
23. 월기본경비계(9)    
24. 공란(52)    
*****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXBizPlace WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT    '14'                --01.자료구분    
                    + 'I104400'          --02. 서식코드    
                    + CASE WHEN SMIsOwner = 4097001 THEN '01' ELSE '02' END              --03. 자_타가구분    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizGround))       , 7) --04.사업장대지    
                    + RIGHT('000'     + CONVERT(VARCHAR(3), FLOOR(BizBuildingDown)) , 3) --05.사업장건물_지하층수    
                    + RIGHT('000'     + CONVERT(VARCHAR(3), FLOOR(BizBuildingUp))   , 3) --06.사업장건물_지상층수    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizBuildingSize1)), 7) --07.사업장건물 바닥면적    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(BizBuildingSize2)), 7) --08.사업장건물 연면적    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(RoomCnt))         , 7) --09.객실수    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(TableCnt))        , 7) --10.탁자수    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(ChairCnt))        , 7) --11.의자수    
                    + CASE IsParking    
                            WHEN '1' THEN 'Y'    
                            WHEN '0' THEN 'N'    
                            ELSE SPACE(1)    
                       END --12.주차장 유무    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(EmpCnt)) , 7) --13.종업원수    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(CarCnt1)), 7) --14.차량수(승용차)    
                    + RIGHT('0000000' + CONVERT(VARCHAR(7), FLOOR(CarCnt2)), 7) --15.차량수(화물차)
                    + CASE SMBaseCostKind    
                            WHEN 4098001 THEN '06'    
                            WHEN 4098002 THEN '12'    
                            ELSE SPACE(2)    
                       END --16.월기준    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9) , FLOOR(Deposit))  , 9) --17.보증금    
                    + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(MonAmt)) ,11) --18.월세    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9) , FLOOR(ElectAmt)) , 9) --19.전기_가스료    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(WaterAmt))  , 9) --20.수도료    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(PayAmt))    , 9) --21.인건비    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(EtcAmt))    , 9) --22.기타경비    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), FLOOR(MonSumAmt)) , 9) --24.월기본경비계    
                    + SPACE(52)    
                    , 200    
                FROM _TTAXBizPlace WITH(NOLOCK)
                WHERE CompanySeq    = @CompanySeq  
                  AND TaxTermSeq    = @TaxTermSeq  
                  AND TaxUnit       = @TaxUnit  
    END    
END  
  
/***************************************************************************************************************************    
신용카드매출전표발행금액등 집계표    
    
    
01. 자료구분(2) : 17    
02. 서식코드(7) : I103400 / V117
03. 전체발행금액_합계(15) : 4.신용카드등발행금액_합계 + 5.현금영수증발행금액_합계    
04. 신용카드발행금액_합계(13)    
05. 현금영수증발행금액_합계(13)    
06. 발행금액합계_과세매출분(13) : 7.신용카드등발행금액_과세매출 + 8.현금영수증발행금액_과세매출분    
07. 신용카드등발행금액_과세매출(13)    
08. 현금영수증발행금액_과세매출(13)    
09. 발행금액합계_면세매출(13) : 10.신용카드등발행금액_면세매출 + 11.현금영수증발행금액_면세매출분    
10. 신용카드등발행금액_면세매출(13)    
11. 현금영수증발행금액_면세매출(13)    
12. 발행금액합계_봉사료(13) : 13.신용카드등발행금액_봉사료 + 14.현금영수증발행금액_봉사료    
13. 신용카드등발행금액_봉사료(13)    
14. 현금영수증발행금액_봉사료(13)    
15. 세금계산서교부금액(집계표)(13)    
16. 계산서교부금액(집계표)(13)    
17. 공란(10)    
*****************************************************************************************************************************/    
DECLARE @A_Amt  DECIMAL(19,5),  @B_Amt  DECIMAL(19,5),  @C_Amt  DECIMAL(19,5),  
        @D_Amt  DECIMAL(19,5),  @E_Amt  DECIMAL(19,5),  @F_Amt  DECIMAL(19,5),  
        @G_Amt  DECIMAL(19,5),  @H_Amt  DECIMAL(19,5),  @I_Amt  DECIMAL(19,5),  
        @J_Amt  DECIMAL(19,5),  @K_Amt  DECIMAL(19,5)
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXCardBillDraw WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        SELECT @A_Amt = FLOOR(SUM(SupplyAmt + VATAmt)) ,                                                 -- 전체발행금액_합계
               @B_Amt = FLOOR(SUM(CASE WHEN B.IsCard = '1'                                   THEN SupplyAmt + VATAmt ELSE 0 END)), -- 신용카드발행금액_합계
               @C_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind = 4115003                           THEN SupplyAmt + VATAmt ELSE 0 END)), -- 현금영수증발행금액_합계
               @D_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001                            THEN SupplyAmt + VATAmt ELSE 0 END)), -- 발행금액합계_과세매출분
               @E_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001 AND B.IsCard = '1'         THEN SupplyAmt + VATAmt ELSE 0 END)), -- 신용카드등발행금액_과세매출분
               @F_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114001 AND B.SMEvidKind = 4115003 THEN SupplyAmt + VATAmt ELSE 0 END)), -- 현금영수증발행금액_과세매출분
               @G_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002                            THEN SupplyAmt + VATAmt ELSE 0 END)), -- 발행금액합계_면세매출분
               @H_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002 AND B.IsCard = '1'         THEN SupplyAmt + VATAmt ELSE 0 END)), -- 신용카드등발행금액_면세매출분
               @I_Amt = FLOOR(SUM(CASE WHEN B.SMTaxKind = 4114002 AND B.SMEvidKind = 4115003 THEN SupplyAmt + VATAmt ELSE 0 END)), -- 현금영수증발행금액_면세매출분
               @J_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind IN (4115001, 4115006) AND B.IsBuyerBill <> '1' THEN SupplyAmt + VATAmt ELSE 0 END)),  -- 세금계산서교부금액
               @K_Amt = FLOOR(SUM(CASE WHEN B.SMEvidKind = 4115002                           THEN SupplyAmt + VATAmt ELSE 0 END ))  -- 계산서교부금액
          FROM _TTAXCardBillDraw AS A WITH(NOLOCK)
                    JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                   AND A.EvidSeq    = B.EvidSeq
         WHERE A.CompanySeq     = @CompanySeq
           AND A.TaxTermSeq     = @TaxTermSeq
           AND A.TaxUnit        = @TaxUnit

        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
        SELECT '17'         --01. 자료구분
             + 'I103400'  --02. 서식코드
             + dbo._FnVATIntChg(ISNULL(@A_Amt,0) , 15, 0, 1)  --03. 전체발행금액_합계           (15)
             + dbo._FnVATIntChg(ISNULL(@B_Amt,0) , 13, 0, 1)  --04. 신용카드발행금액_합계       (13)
             + dbo._FnVATIntChg(ISNULL(@C_Amt,0) , 13, 0, 1)  --05. 현금영수증발행금액_합계     (13)
             + dbo._FnVATIntChg(ISNULL(@D_Amt,0) , 13, 0, 1)  --06. 발행금액합계_과세매출분     (13)
             + dbo._FnVATIntChg(ISNULL(@E_Amt,0) , 13, 0, 1)  --07. 신용카드등발행금액_과세매출 (13)
             + dbo._FnVATIntChg(ISNULL(@F_Amt,0) , 13, 0, 1)  --08. 현금영수증발행금액_과세매출 (13)
             + dbo._FnVATIntChg(ISNULL(@G_Amt,0) , 13, 0, 1)  --09. 발행금액합계_면세매출       (13)
             + dbo._FnVATIntChg(ISNULL(@H_Amt,0) , 13, 0, 1)  --10. 신용카드등발행금액_면세매출 (13)
             + dbo._FnVATIntChg(ISNULL(@I_Amt,0) , 13, 0, 1)  --11. 현금영수증발행금액_면세매출 (13)
             + '0000000000000'                                --12. 발행금액합계_봉사료         (13)
             + '0000000000000'                                --13. 신용카드등발행금액_봉사료   (13)
             + '0000000000000'                                --14. 현금영수증발행금액_봉사료   (13)
             + dbo._FnVATIntChg(ISNULL(@J_Amt,0) , 13, 0, 1)  --15. 세금계산서교부금액(집계표)  (13)
             + dbo._FnVATIntChg(ISNULL(@K_Amt,0) , 13, 0, 1)  --16. 계산서교부금액(집계표)      (13)
             + SPACE(7)                   --17. 공란                        (10)
            , 200 
    END    
END  
/***************************************************************************************************************************    
영세율첨부서류제출명세서    
    
01. 자료구분(2) : 17    
02. 서식코드(7) : I105800 / V106
03. 제출사유코드(2) : 01 - 특별소비세 과세표준신고서와 함께 제출  02 - 전산디스켓 또는 테이프로 제출    -- 20070409 2007_1th by Him    
04. 제출사유(60) : "특별소비세 과세표준신고서와 함께 제출" 또는 "전산디스켓 또는 테이프로 제출"    
05. 일련번호(6)    
06. 서류명(40) : 수출신고필증    
07. 발급자(20)    
08. 발급일자(8)    
09. 선적일자(8)    
10. 수출통화코드(3)    
11. 환율(9, 4)    
12. 당기제출금액(외화)(15, 2)    
13. 당기제출금액(원화)(15)    
14. 당기신고해당분(외화)(15, 2)    
15. 당기신고해당분(원화)(15)    
16. 공란(25)    
****************************************************************************************************************************/    
IF @WorkingTag IN ('', 'Z')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXZero WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
        IF @WorkingTag = 'Z' ------- 디스켓신고 (영세율첨부서류)  
        BEGIN  
            --=============================================================================  
            -- 제출자 인적사항(HEAD RECORD)    
            --=============================================================================  
            --번호  항목                        형태  길이  누적길이  비고  
            --1   레코드구분                    문자  2     2         ZH  
            --2   귀속년도                      문자  4     6         YYYY　  
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기  
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6  
            --5   수취자(제출자)사업자등록번호  문자  10    18  
            --6   상호(법인명)                  문자  60    78  
            --7   성명(대표자)                  문자  30    108  
            --8   주민(법인)등록번호            문자  13    121  
            --9   제출일자                      문자  8     129  
            --10  수취자(제출자)전화번호        문자  12    141  
            --11  공란                          문자  59    200       SPACE              
            
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZH'                         -- 레코드구분    
                    +  LEFT(@TaxFrDate, 4)          -- 귀속년도    
                    +  @TermKind                    -- 반기구분    
                    +  @YearHalfMM                  -- 반기내 월 순번    
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- 수취자(제출자)사업자등록번호  
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- 상호(법인명)  
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- 성명(대표자)      
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                                         + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- 주민(법인)등록번호  
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- 제출일자  
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- 수취자(제출자)전화번호  
                    + SPACE(59)    -- 공란  
                    , 200  
               FROM #TDATaxUnit WITH(NOLOCK)
              WHERE CompanySeq  = @CompanySeq  
                AND TaxUnit     = @TaxUnit  
  
            --=============================================================================  
            -- 영세율첨부서류제출명세서(DATA RECORD)    
            --=============================================================================  
            --번호  항목                        형태  길이  누적길이  비고  
            --1   레코드구분                    문자  2     2         ZD  
            --2   귀속년도                      문자  4     6         YYYY　  
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기  
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6  
            --5   수취자(제출자)사업자등록번호  문자  10    18  
            --6   제출사유코드                  문자  2     20        01,02  
            --7   일련번호                      문자  6     26        SEQ  
            --8   서류명                        문자  40    66  
            --9   발급자                        문자  20    86  
            --10  발급일자                      문자  8     94  
            --11  선적일자                      문자  8     102  
            --12  수출통화코드                  문자  3     105       MONEY CD,영문자  
            --13  환율                          숫자  9,4   114  
            --14  당기제출금액(외화)            숫자  15,2  129  
            --15  당기제출금액(원화)            숫자  15    144  
            --16  당기신고해당분(외화)          숫자  15,2  159  
            --17  당기신고해당분(원화)          숫자  15    174  
            --18  공란                          문자  26    200       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZD'                         -- 레코드구분    
                    +  LEFT(@TaxFrDate, 4)          -- 귀속년도    
                    +  @TermKind                    -- 반기구분    
                    +  @YearHalfMM                  -- 반기내 월 순번    
                    +  dbo._FnVATCHARChg(convert(VARCHAR(10), @TaxNo)       ,10,1)                  -- 수취자(제출자)사업자등록번호    
                    + ( CASE A.SMRptRemType WHEN 4130001 THEN '01' ELSE '02' END )                  -- 제출사유코드  
                    +  RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Seq)), 6)   -- 일련번호  
                    +  CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName   ))) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName   ))))) -- 서류명  
                    +  CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm   ))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm   )))))   -- 발급자  
                    +  CASE WHEN ISNULL(A.ExpermitDate, '') = '' THEN SPACE(8) ELSE A.ExpermitDate END       -- 발급일자  
                    +  CASE WHEN ISNULL(A.ShippingDate, '') = '' THEN SPACE(8) ELSE A.ShippingDate END       -- 선적일자  
                    + CASE WHEN ISNULL(A.CurrSeq, 0) = 0 THEN SPACE(3) ELSE ( CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END ) END -- 수출통화코드  
                    + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(NUMERIC(19, 4), A.ExRate)), '.', ''), 9)   -- 환율  
                    +  dbo._FnVATIntChg(CONVERT(NUMERIC(19,2),ForAmt1)       ,15,2,1)    -- 당기제출금액(외화)  
                    +  dbo._FnVATIntChg(KoAmt1                               ,15,0,1)    -- 당기제출금액(원화)  
                    +  dbo._FnVATIntChg(CONVERT(NUMERIC(19,2),ForAmt2)       ,15,2,1)    -- 당기신고해당분(외화)  
                    +  dbo._FnVATIntChg(KoAmt2                               ,15,0,1)    -- 당기신고해당분(원화)  
                    +  SPACE(26)                    -- 공란    
                    ,  200                          -- 누적길이    
                 FROM _TTAXZero AS A WITH(NOLOCK)
                                      LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                       ON A.CompanySeq  = B.CompanySeq  
                                      AND A.CurrSeq     = B.CurrSeq  
                 WHERE A.CompanySeq     = @CompanySeq  
                   AND A.TaxTermSeq     = @TaxTermSeq  
                   AND A.TaxUnit        = @TaxUnit  
  
            --=============================================================================  
            -- 영세율첨부서류제출명세서 합계(TAIL RECORD)    
            --=============================================================================  
            --번호  항목                        형태  길이  누적길이  비고  
            --1   레코드구분                    문자  2     2         ZT  
            --2   귀속년도                      문자  4     6         YYYY　　  
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기  
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6  
            --5   수취자(제출자)사업자등록번호  문자  10    18  
            --6   DATA 건수                     숫자  7     25  
            --7   당기제출금액(원화)_합계       숫자  15    40  
            --8   당기신고해당분(원화)_합계     숫자  15    55  
            --9   공란                          문자  145   200  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'ZT'                         -- 레코드구분    
                    +  LEFT(@TaxFrDate, 4)          -- 귀속년도    
                    +  @TermKind                    -- 반기구분    
                    +  @YearHalfMM                  -- 반기내 월 순번    
                    +  dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo)    ,10,1)    -- 수취자(제출자)사업자등록번호    
                    +  dbo._FnVATIntChg(COUNT(Seq)                       , 7,0,1)  -- DATA건수      
                    +  dbo._FnVATIntChg(SUM(KoAmt1)                      ,15,0,1)  -- 당기제출금액(원화)_합계  
                    +  dbo._FnVATIntChg(SUM(KoAmt2)                      ,15,0,1)  -- 당기신고해당분(원화)_합계  
                    +  SPACE(145)                   -- 공란    
                    ,  200                          -- 누적길이    
                  FROM _TTAXZero AS A WITH(NOLOCK)
                 WHERE A.CompanySeq     = @CompanySeq  
                   AND A.TaxTermSeq     = @TaxTermSeq  
                   AND A.TaxUnit        = @TaxUnit  
        END  
        ELSE ---------------------- 전자신고  (영세율첨부서류)  
        BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'  --01. 자료구분    
                       + 'I105800' --02. 서식코드    
                       + ( CASE A.SMRptRemType WHEN 4130001 THEN '01' ELSE '02' END ) -- 03. 제출사유코드
                       + CONVERT(VARCHAR(60), LTRIM(RTRIM(A.Remark     ))) + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(A.Remark     )))))   --04. 제출사유    
                       + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Seq)), 6) -- 05. 일련번호    
                       + CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName ))) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(A.ReportName )))))   --06. 서류명    
                       + CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm ))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(A.ExpermitNm )))))   --07. 발급자    
                       + CASE WHEN ISNULL(A.ExpermitDate, '') = '' THEN SPACE(8) ELSE A.ExpermitDate END       --08. 발급일자    
                       + CASE WHEN ISNULL(A.ShippingDate, '') = '' THEN SPACE(8) ELSE A.ShippingDate END       --09. 선적일자    
                       + CASE WHEN ISNULL(A.CurrSeq, 0) = 0 THEN SPACE(3) ELSE ( CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END ) END      --10. 수출통화코드
                       + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(NUMERIC(19, 4), CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE A.ExRate/B.BasicAmt END)), '.', ''), 9)   --11. 환율    
                       + CASE WHEN A.ForAmt1 >= 0 THEN    
                               RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.ForAmt1)), '.', ''), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), ABS(CONVERT(NUMERIC(19, 2), A.ForAmt1))), '.', ''), 15), 1, 1, '-')    
                          END             --12. 당기제출금액(외화)    
                       + CASE WHEN A.KoAmt1 >= 0 THEN    
                               RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.KoAmt1)), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.KoAmt1))), 15), 1, 1, '-')    
                          END            --13. 당기제출금액(원화)    
                       + CASE WHEN A.ForAmt2 >= 0 THEN    
                               RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.ForAmt2)), '.', ''), 15)    
                          ELSE    
                               STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), ABS(CONVERT(NUMERIC(19, 2), A.ForAmt2))), '.', ''), 15), 1, 1, '-')    
                          END             --14. 당기신고해당분(외화)    
                       + CASE WHEN A.KoAmt2 >= 0 THEN    
                               RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.KoAmt2)), 15)
                          ELSE    
                               STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.KoAmt2))), 15), 1, 1, '-')    
                          END            --15. 당기신고해당분(원화)    
                       + SPACE(25)       --16. 공란    
                       , 250  
             FROM _TTAXZero AS A WITH(NOLOCK)
                                 LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                   ON A.CompanySeq  = B.CompanySeq  
                                  AND A.CurrSeq     = B.CurrSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSeq  
               AND A.TaxUnit        = @TaxUnit  
        END  
    END    
END  
-- /***************************************************************************************************************************    
-- 의제매입세액공제신고서
-- ****************************************************************************************************************************/      
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXFictionSum WITH(NOLOCK) WHERE CompanySeq = @CompanySEq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT    '17'     --01. 자료구분    
                       + 'I102300'    --02. 서식코드    
                       + RIGHT('0000000' + CONVERT(VARCHAR(7), SUM(ISNULL(BillCustCnt,0)+ISNULL(CardCustCnt,0)+ISNULL(FarmCustCnt,0))),  7) --03.거래처수_합계    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(BillCnt,0)+ISNULL(CardCnt,0)+ISNULL(FarmCnt,0)))), 11) --04.매입건수_합계    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillSpplyAmt,0)+ISNULL(CardSpplyAmt,0)+ISNULL(FarmSpplyAmt,0)))), 15) --05.매입금액_합계    
                       + CASE WHEN SMSumDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMSumDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMSumDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMSumDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMSumDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMSumDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMSumDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMSumDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMSumDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMSumDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMSumDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END -- 06.공제율구분_합계    
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(ISNULL(BillVATAmt,0)+ISNULL(CardVATAmt,0)+ISNULL(FarmVATAmt,0)))), 13) --07.매입의제매입세액_합계
                       -- 계산서
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(BillCustCnt,0))), 6)                    --08.거래처수_계산서    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(BillCnt,0)))), 11)          --09.매입건수_계산서    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillSpplyAmt,0)))), 15) --10.매입금액_계산서    
                       + CASE WHEN SMBillDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMBillDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMBillDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMBillDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMBillDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMBillDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMBillDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMBillDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMBillDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMBillDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMBillDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END                                                                  --11.공제율구분_계산서    
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(BillVATAmt,0)))), 13)     --12.매입의제매입세액_계산서
                       -- 신용카드
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(CardCustCnt,0))), 6)                    --13.거래처수_신용카드    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(SUM(ISNULL(CardCnt,0)))), 11)          --14.매입건수_신용카드    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(CardSpplyAmt,0)))), 15) --15.매입금액_신용카드    
                       + CASE WHEN SMCardDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMCardDeductRate = 4143002 THEN '6' -- 6/106  
                              WHEN SMCardDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMCardDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMCardDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMCardDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMCardDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMCardDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMCardDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMCardDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMCardDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END                                                                  --16.공제율구분_신용카드  
                       + RIGHT('0000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(CardVATAmt,0)))), 13)     --17.매입의제매입세액_신용카드
                       -- 농어민
                       + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(ISNULL(FarmCustCnt,0))), 6)                    --18.거래처수_농어민    
                       + RIGHT('00000000000' + CONVERT(VARCHAR(6), FLOOR(SUM(ISNULL(FarmCnt,0)))), 11)           --19.매입건수_농어민    
                       + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(FarmSpplyAmt,0)))), 15) --20.매입금액_농어민    
                       + CASE WHEN SMFarmDeductRate = 4143001 THEN '2' -- 2/102  
                              WHEN SMFarmDeductRate = 4143002 THEN '6' -- 6/106  
                          WHEN SMFarmDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106  
                              WHEN SMFarmDeductRate = 4143004 THEN '8' -- 8/108  
                              WHEN SMFarmDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108  
                              WHEN SMFarmDeductRate = 4143006 THEN '4' -- 4/104  
                              WHEN SMFarmDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104  
                              WHEN SMFarmDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106  
                              WHEN SMFarmDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108  
                              WHEN SMFarmDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106  
                              WHEN SMFarmDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108  
                              ELSE SPACE(1) END --21.공제율구분_농어민  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(FarmVATAmt   ,0))), 13, 0, 1)    --22.매입a_농어민                           
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(PlanAmt      ,0))), 15, 0, 1)    --23.과세표준_예정분  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(FinalAmt     ,0))), 15, 0, 1)    --24.과세표준_확정분  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(SumTaxAmt    ,0))), 15, 0, 1)    --25.과세표준_합계  
                       + ISNULL( MAX( CASE WHEN SMLimitRate = '9' THEN '3'      --35/100인 경우 기존 30/100과 구별하기 위해 저장은 9로 되나 신고코드는 '3'
                                           WHEN SMLimitRate IN ('', '0') THEN SPACE(1)
                                           ELSE SMLimitRate END ),SPACE(1))                 --26.대상액한도계산_한도율
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(LimitAmt     ,0))), 15, 0, 1)    --27.대상액한도계산_한도액  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(BuyingAmt    ,0))), 15, 0, 1)    --28.당기매입액  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductAmt    ,0))), 15, 0, 1)    --29.공제대상금액
                       + CASE WHEN SMDeductRate = 4143001 THEN '2' -- 2/102    
                              WHEN SMDeductRate = 4143002 THEN '6' -- 6/106    
                              WHEN SMDeductRate = 4143003 THEN '9' -- 2/102 OR 6/106    
                              WHEN SMDeductRate = 4143004 THEN '8' -- 8/108    
                              WHEN SMDeductRate = 4143005 THEN '0' -- 2/102 Or 8/108    
                              WHEN SMDeductRate = 4143006 THEN '4' -- 4/104    
                              WHEN SMDeductRate = 4143007 THEN 'A' -- 2/102 Or 4/104    
                              WHEN SMDeductRate = 4143008 THEN 'B' -- 4/104 Or 6/106    
                              WHEN SMDeductRate = 4143009 THEN 'C' -- 4/104 Or 8/108    
                              WHEN SMDeductRate = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106    
                              WHEN SMDeductRate = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108    
                              ELSE SPACE(1) END --30.공제대상세액_공제율
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductCompTax    ,0))), 13, 0, 1)        --31.공제대상세액_공제대상세액
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(PlandeductedTax  ,0))), 13, 0, 1)        --32.이미공제받은세액_예정신고분
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(MondeductedTax   ,0))), 13, 0, 1)        --33.이미공제받은세액_월별조기분  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(SumdeductedTax   ,0))), 13, 0, 1)        --34.이미공제받은세액_합계  
                       + dbo.fnVATIntChg( FLOOR(SUM(ISNULL(DeductTax        ,0))), 13, 0, 1)        --35.공제(납부)할세액
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt1,0))),   15,0,1)     --36.제1기_과세표준(제조업)                    (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt2,0))),   15,0,1)     --37.제2기_과세표준(제조업)                    (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.StdSumTaxAmt,0))),    15,0,1)     --38.1역년과세표준합계(제조업)                 (15)
                       + CONVERT(CHAR(1), ISNULL(MAX(CASE WHEN Fic.SMLimitrate4 = '9' THEN '3'          --35/100인 경우 기존 30/100과 구별하기 위해 저장은 9로 되나 신고코드는 '3'
                                                          WHEN Fic.SMLimitrate4 IN ('', '0') THEN SPACE(1)
                                                          ELSE Fic.SMLimitrate4 END),SPACE(1))) --39.대상액한도계산_한도율(제조업)             (1)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.LimitAmt4,0)))    ,   15,0,1)     --40.대상액한도계산_한도액(제조업)             (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt1,0))),   15,0,1)     --41.제1기_매입액(제조업)                      (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt2,0))),   15,0,1)     --42.제2기_매입액(제조업)                      (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.BuySumTaxAmt,0))),    15,0,1)     --43.1역년매입액합계(제조업)                   (15)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductAmt4,0))),      15,0,1)     --44.공제대상금액(제조업)                      (15)
                       + MAX( CASE WHEN SMDeductRate4 = 4143001 THEN '2' -- 2/102    
                                   WHEN SMDeductRate4 = 4143002 THEN '6' -- 6/106    
                                   WHEN SMDeductRate4 = 4143003 THEN '9' -- 2/102 OR 6/106    
                                   WHEN SMDeductRate4 = 4143004 THEN '8' -- 8/108    
                                   WHEN SMDeductRate4 = 4143005 THEN '0' -- 2/102 Or 8/108    
                                   WHEN SMDeductRate4 = 4143006 THEN '4' -- 4/104    
                                   WHEN SMDeductRate4 = 4143007 THEN 'A' -- 2/102 Or 4/104    
                                   WHEN SMDeductRate4 = 4143008 THEN 'B' -- 4/104 Or 6/106    
                                   WHEN SMDeductRate4 = 4143009 THEN 'C' -- 4/104 Or 8/108    
                                   WHEN SMDeductRate4 = 4143010 THEN 'D' -- 2/102 Or 4/104 Or 6/106    
                                   WHEN SMDeductRate4 = 4143011 THEN 'E' -- 2/102 Or 4/104 Or 8/108    
                                   ELSE SPACE(1) END )                               --45.공제대상세액_공제율(제조업)               (1)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductCompTax4,0))),  13,0,1)     --46.공제대상세액(제조업)                      (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax1,0))),   13,0,1)     --47.제1기_이미공제받은세액(제조업)            (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotPlanTax,0))),      13,0,1)     --48.제2기_이미공제받은세액_예정분(제조업)     (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotMonTax,0))),       13,0,1)     --49.제2기_이미공제받은세액_월별조기분(제조업) (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax2,0))),   13,0,1)     --50.제2기_이미공제받은세액_합계(제조업)       (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.TotDeductTax,0))),    13,0,1)     --51.이미공제받은세액_총합계(제조업)           (13)
                       + dbo.fnVATIntChg(FLOOR(SUM(ISNULL(Fic.DeductTax4,0))),      13,0,1)     --52.공제(납부)할세액(제조업)                  (13)
                       + SPACE(36)                                                              --53.공란                                      (36)
                       , 600 
              FROM _TTAXFictionSum AS Fic WITH(NOLOCK)
             WHERE Fic.CompanySeq   = @CompanySeq  
               AND Fic.TaxTermSeq   = @TaxTermSeq  
               AND Fic.TaxUnit      = @TaxUnit  
               AND ( Fic.BillCustCnt <> 0 OR Fic.BillSpplyAmt <> 0 OR Fic.BillVATAmt <> 0 OR Fic.CardCustCnt <> 0 OR Fic.CardCnt <> 0   
                  OR Fic.CardSpplyAmt <> 0 OR Fic.CardVATAmt <> 0 OR Fic.FarmCustCnt <> 0 OR Fic.FarmCnt <> 0 OR Fic.FarmSpplyAmt <> 0  
                  OR Fic.FarmVATAmt <> 0)  
             GROUP BY SMSumDeductRate, SMBillDeductRate, SMCardDeductRate, SMFarmDeductRate, SMDeductRate
    END   
    
    IF EXISTS (SELECT 1 FROM _TTAXFictionDetail WITH(NOLOCK) WHERE CompanySeq = @CompanySEq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND IsFF = 1)    
    BEGIN     
              INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
               SELECT    '18'     --01. 자료구분    
                        + 'I102300'    --02. 서식코드        
                        + RIGHT('000000' + CONVERT(NVARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.CustSeq)), 6)        -- 03. 일련번호(6)
                        + dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonId', @CompanySeq)          -- 04. 주민등록번호(13)
                        + dbo._FnVATCHARChg(B.Owner, 30, 1)         -- 05. 성명(30) 
                        + dbo._FnVATIntChg(COUNT(*), 11, 0, 1)      -- 06. 매입건수(11)
                        + dbo._FnVATCHARChg(C.ItemName, 30, 1)      -- 07. 품명(30)
                        + dbo._FnVATIntChg(SUM(A.OrgQty), 20, 0, 1) -- 08. 매입수량(20)
                        + dbo._FnVATIntChg(SUM(A.OrgAmt), 13, 0, 1) -- 09. 매입금액(13)
                        + SPACE(68)    -- 10 공란 (71)
                        , 200
                  FROM _TTAXFictionDetail AS A WITH(NOLOCK)
                                            JOIN _TDACust AS B WITH (NOLOCK)
                                              ON A.CompanySeq = B.CompanySeq
                                             AND A.CustSeq    = B.CustSeq
                                            JOIN _TDAItem AS C WITH (NOLOCK)
                                              ON A.CompanySeq = C.CompanySeq
                                             AND A.ItemSeq    = C.ItemSeq
                 WHERE A.CompanySeq = @CompanySeq
                   and A.TaxTermSeq  = @TaxTermSeq
                   AND A.TaxUnit      = @TaxUnit
                   AND A.IsFF = '1'
                 GROUP BY A.CustSeq, B.PersonID, B.Owner, C.ItemName
                  
              
     
    END 
         
END      

/***************************************************************************************************************************    
        재활용폐자원등 및 중고자동차매입세액공제신고서_합계  
****************************************************************************************************************************/    
IF @WorkingTag = ''
BEGIN
  
    IF EXISTS (SELECT * FROM _TTAXRecycleSet WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'     --01. 자료구분    
                   + 'M116300'    --02. 서식코드    
                   + RIGHT('0000000'     + CONVERT(VARCHAR(7) , SUM(ISNULL(ReceiptCustCnt,0)+ISNULL(BillCustCnt,0))), 7) --03.매입처수 합계    
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(ReceiptCnt,0)+ISNULL(BillCnt,0))), 11)        --04.매입건수_합계
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptAmt,0)+ISNULL(BillAmt,0)))           , 15, 0, 1) --05.매입금액_합계 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptVATAmt,0)+ISNULL(BillVATAmt,0)))     , 15, 0, 1) --06.매입세액공제액_합계
                   + RIGHT('000000'      + CONVERT(VARCHAR(6) , SUM(ISNULL(ReceiptCustCnt,0))), 6)  --07.매입처수_영수증  
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(ReceiptCnt,0)))    ,11)  --08.매입건수_영수증
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptAmt      ,0)))   , 15, 0, 1)     --09.매입금액_영수증  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReceiptVATAmt   ,0)))   , 15, 0, 1)     --10.매입의제매입세액_영수증
                   + RIGHT('000000'      + CONVERT(VARCHAR(6) , SUM(ISNULL(BillCustCnt,0))), 6) --11.매입처수_계산서
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(ISNULL(BillCnt,0)))    ,11) --12.매입건수_계산서
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillAmt         ,0)))   , 15, 0, 1)     --13.매입금액_계산서
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillVATAmt      ,0)))   , 15, 0, 1)     --14.매입세액공제_계산서  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumSalesAmt     ,0)))   , 15, 0, 1)     --15.합계 매출액  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(PlanAmt         ,0)))   , 15, 0, 1)     --16.예정분 매출액  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(FinalAmt        ,0)))   , 15, 0, 1)     --17.확정분매출액
                   + '00080'                                                                    --18.한도율  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(LimitAmt        ,0)))   , 15, 0, 1)     --19.대상액한도계산_한도액 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumBuyingAmt    ,0)))   , 15, 0, 1)     --20.합계당기매입액 
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(BillBuyingAmt   ,0)))   , 15, 0, 1)     --21.합계당기매입액_세금계산서  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(ReciptBuyingAmt ,0)))   , 15, 0, 1)     --22.합계당기매입액_영수증
                   + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(ISNULL(DeductibleAmt  ,0)))), 15) --23.공제가능한금액                     
                   + CASE WHEN MAX(Recycle.SMDeductRate) = '1' THEN RIGHT('00000' + CONVERT(VARCHAR(5), '00005'), 5)
                                                               ELSE RIGHT('00000' + CONVERT(VARCHAR(5), '00003'), 5) END    --24.공제율 분자  
                   + CASE WHEN MAX(Recycle.SMDeductRate) = '1' THEN RIGHT('00000' + CONVERT(VARCHAR(5), '00105'), 5) 
                                                               ELSE RIGHT('00000' + CONVERT(VARCHAR(5), '00103'), 5) END    --25.공제율 분모
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductAmt       ,0)))   , 15, 0, 1)     --26.공제대상금액  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductCompTax   ,0)))   , 13, 0, 1)     --27.공제대상세액  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(SumdeductedTax  ,0)))   , 13, 0, 1)     --28.이미공제받은세액_합계  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(PlandeductedTax ,0)))   , 13, 0, 1)     --29.이미공제받은세액_예정신고분  
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(MondeductedTax  ,0)))   , 13, 0, 1)     --30.이미공제받은세액_월별조기분   
                   + dbo._FnVATIntChg( FLOOR(SUM(ISNULL(DeductTax       ,0)))   , 13, 0, 1)     --31.공제(납부)할세액                                      
                   + SPACE(34)    
                   , 400    
         FROM _TTAXRecycleSet AS Recycle WITH (NOLOCK)    
         WHERE CompanySeq = @CompanySeq 
           AND TaxTermSeq = @TaxTermSeq 
           AND TaxUnit = @TaxUnit
           
       CREATE TABLE #TATRecycleTaxDeduc  
        (Seq                INT IDENTITY(1,1),  
         PersonId_TelexNo   NVARCHAR(200) NULL,  
         CustNm             NVARCHAR(200) NULL,  
         Cnt                NUMERIC(19,5) NULL,  
         ItemNm             NVARCHAR(30)  NOT NULL,  
         Qty                NUMERIC(19,5) NOT NULL,  
         GainAmt            NUMERIC(19,5) NOT NULL,  
         CarNumber          CHAR(20)      NOT NULL,  
         CarIDNumber        CHAR(20)      NOT NULL )  
  
      INSERT INTO #TATRecycleTaxDeduc(PersonId_TelexNo, CustNm, Cnt, ItemNm, Qty, GainAmt,CarNumber,CarIDNumber)  
         SELECT CASE WHEN ISNULL(B.PersonId,'') <> ''   
                     THEN dbo._FCOMDecrypt(PersonId, '_TDACust', 'PersonId', @CompanySeq)  
                     ELSE ISNULL(B.BizNo,'')
                END,  
                B.CustName,A.Cnt,C.ItemName,A.Qty, A.GainAmt, A.CarNumber, A.CarIDNumber  
           FROM _TTAXRecycleSetDetail AS A WITH (NOLOCK)  
                    JOIN _TDACust AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq
                    JOIN _TDAItem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.ItemSeq = C.ItemSeq
          WHERE A.CompanySeq = @CompanySeq
        AND A.SupplyDate BETWEEN @TaxFrDate AND @TaxToDate    
            AND A.TaxUnit       = @TaxUnit  
  
/***************************************************************************************************************************    
        재활용폐자원등 및 중고자동차매입세액공제신고서_명세  
****************************************************************************************************************************/  
           INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)   
                 SELECT '18'                                                            -- 01. 자료구분  
                       + 'M116300'                                                      -- 02. 서식코드  
                       + RIGHT('000000' + CONVERT(VARCHAR(6), Seq), 6)                  -- 03. 일련번호  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(60), CustNm), 60, 1)          -- 04. 공급자성명_상호  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(13), PersonId_TelexNo),13,1)  -- 05. 공급자주민(사업자)번호  
                       + dbo.fnVATIntChg(ISNULL(Cnt,0),11,0,1)                          -- 06. 건수  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(30), ItemNm), 30, 1)          -- 07. 품명  
                       + dbo.fnVATIntChg(ISNULL(Qty,0),11,0,1)                          -- 08. 수량  
                       + dbo.fnVATIntChg(ISNULL(GainAmt,0),13,0,1)                      -- 09. 취득금액  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(20), CarNumber),20,1)         -- 10. 차량번호  
                       + dbo.fnVATCHARChg(CONVERT(VARCHAR(17), CarIDNumber),17,1)       -- 11. 차대번호  
                       + SPACE(10)    
                        , 200    
                   FROM #TATRecycleTaxDeduc  
        END
END
  

  
/***************************************************************************************************************************    
부동산임대공가가액 명세서    
  
01. 자료구분(2) : 17    
02. 서식코드(7) : I103600 / V120
03. 일련번호구분(6) : 000001 Fix    
04. 부동산소재지(70)    
05. 임대계약내용 보증금합계(15)    
06. 임대계약내용 월세등합계(15)    
07. 임대료 수입금액합계(15)    
08. 임대료 수입보증금이자합계(15)    
09. 임대표 수입월세등합계(15)    
10. 임대인사업자등록번호(10)    
11. 임대건수(6)    
12. 종사업자일련번호(4)    
13. 공란(70)    
****************************************************************************************************************************/   
/***************************************************************************************************************************    
부동산임대공급가액명세서 세부내용    
    
01. 자료구분(2) : 18    
02. 서식코드(7) : I103600 / V120
03. 일련번호구분(6)    
04. 일련번호(6)    
05. 층(10)
06. 동(30)    
07. 호수(10)    
08. 면적(10)    
09. 임차인상호(성명)(30)    
10. 임차인 사업자등록번호(13)    
11. 임대계약 입주일(8)    
12. 임대계약 퇴거일(8)    
13. 임대계약내용 보증금(13)    
14. 임대계약내용월임대료(13)    
15. 임대료 수입금애계(과표)(13)    
16. 임대료 보증금이자(13)    
17. 임대료수입금액월임대료(13)    
18. 종사업자일련번호(4)    
19. 임대차내역변경일자(8)
20. 공란(33)    
****************************************************************************************************************************/     
IF @WorkingTag IN ('','E')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXLandLease WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq)  -- 주사업자에 등록 안되어 있는 Case도 존재하여 @TaxUnit 제거   
    BEGIN  
        IF @WorkingTag  = 'E' -- 디스켓신고(부동산임대)
        BEGIN  
            --=============================================================================    
            -- 제출자 인적사항(HEAD RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         EH    
            --2   귀속년도                      문자  4     6         YYYY　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   상호(법인명)                  문자  60    78    
            --7   성명(대표자)                  문자  30    108    
            --8   주민(법인)등록번호            문자  13    121    
            --9   제출일자                      문자  8     129    
            --10  수취자(제출자)전화번호        문자  12    141    
            --11  공란                          문자  109   250       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'EH'                         -- 레코드구분      
                    +  LEFT(@TaxFrDate, 4)          -- 귀속년도      
                    +  @TermKind                    -- 반기구분      
                    +  @YearHalfMM                  -- 반기내 월 순번      
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- 수취자(제출자)사업자등록번호    
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- 상호(법인명)    
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- 성명(대표자)        
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                       + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- 주민(법인)등록번호    
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- 제출일자    
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- 수취자(제출자)전화번호    
                    + SPACE(109)    -- 공란    
                    , 250    
                FROM #TDATaxUnit WITH(NOLOCK)
                WHERE CompanySeq  = @CompanySeq    
                  AND TaxUnit     = @TaxUnit    
            --=============================================================================    
            -- 부동산임대공급가액명세서(DATA RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         ED    
            --2   귀속년도                      문자  4     6         YYYY　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   일련번호구분                  문자  6     24        SEQ    
            --7   일련번호                      문자  6     30        SEQ    
            --8   층                            문자  10    40    
            --9   호수                          문자  10    50    
            --10  면적                          문자  10    60    
            --11  임차인상호(성명)              문자  30    90    
            --12  임차인사업자등록번호          문자  13    103       MONEY CD,영문자    
            --13  임대계약입주일                문자  8     111 
            --14  임대계약퇴거일                문자  8     119   
            --15  임대계약내용보증금            숫자  13    132    
            --16  임대계약내용월임대료          숫자  13    145    
            --17  임대료수입금액계(과세표준)    숫자  13    158    
            --18  임대료보증금이자              숫자  13    171
            --19  임대료수입금액월임대료        숫자  13    184
            --20  지하여부[삭제]                문자  1     185       SPACE
            --21  종사업자일련번호              문자  4     189
            --22  동                            문자  20    209
            --23  갱신일                        문자  8     217                        
            --24  공란                          문자  33    250       SPACE 
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)   
                SELECT 'ED'                         -- 1.레코드구분      
                    +  LEFT(@TaxFrDate, 4)          -- 2.귀속년도      
                    +  @TermKind                    -- 3.반기구분      
                    +  @YearHalfMM                  -- 4.반기내 월 순번      
                    +  dbo._FnVATCHARChg(convert(VARCHAR(10), @TaxNo)       ,10,1)                  -- 5.수취자(제출자)사업자등록번호      
                    + '000001'                      -- 6.일련번호구분    
                    + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Land.LandSerl)), 6) --7.일련번호    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --8.층    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     )))))   --9.호수    
                    + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(FLOOR(CASE WHEN Land.LandSize = '' THEN '0' ELSE REPLACE(Land.LandSize, ',', '') END)))), 10) --10.면적, 콤마가 들어간 경우 오류발생하여 리플레이스 함수 추가 2016.01.25. by shpark          
                    + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --11.임차인상호(성명)    
                    + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                            LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                            + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                       ELSE    
                            LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                       END --12.임차인 사업자등록번호    
                    + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --13.임대계약 입주일    
                    + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --14.임대계약 퇴거일    
                    + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --15.임대계약내용 보증금
                    + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --16.임대료수입금액월임대료
                    + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --17.임대료수입금액계(과세표준)
                    + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --18.임대료 보증금이자
                    + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --19.임대료수입금액월임대료
                    + SPACE(1)  --20.지하여부[삭제]    
                    + '0000'  --21.종사업자일련번호  
                    + LTRIM(RTRIM(CONVERT(VARCHAR(20), ISNULL(Land.Dong   , '')))) + SPACE(20 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(20), ISNULL(Land.Dong   , '')))))) --19.동    
                    + LTRIM(RTRIM(CONVERT(VARCHAR(8) , ISNULL(Land.ModDate, '')))) + SPACE(8  - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8) , ISNULL(Land.ModDate, '')))))) --20.갱신일    
                    + SPACE(33)    
                    , 250    
                FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                               JOIN _TTAXLandLease AS Dtl WITH(NOLOCK)
                                                 ON Land.CompanySeq = Dtl.CompanySeq  
                                                AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                                AND Land.TaxUnit    = Dtl.TaxUnit   
                                                AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                               LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                              ON Land.CompanySeq = Cust.CompanySeq  
                                                AND Land.CustSeq    = Cust.CustSeq  
                WHERE Land.CompanySeq  = @CompanySeq  
                  AND Land.TaxTermSeq  = @TaxTermSeq  
                  AND Land.TaxUnit     = @TaxUnit  

            --=============================================================================    
            -- 부동산임대공급가액명세서  합계(TAIL RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         ET    
            --2   귀속년도                      문자  4     6         YYYY　　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   DATA 건수                     문자  7     25  
            --7   일련번호구분                  문자  6     31  
            --8   부동산소재지                  문자  70    101
            --9   임대계약내용보증금합계        숫자  15    116
            --10  임대계약내용월세등합계        숫자  15    131
            --11  임대료수입금액합계            숫자  15    146
            --12  임대료수입보증금이자합계      숫자  15    161
            --13  임대료수입월세등합계          숫자  15    176  
            --14  임대건수                      숫자  6     182    
            --15  종사업자일련번호              문자  4     186    
            --16  공란                          문자  64    250    
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'ET'                         -- 1.레코드구분      
                    +  LEFT(@TaxFrDate, 4)          -- 2.귀속년도      
                    +  @TermKind                    -- 3.반기구분      
                    +  @YearHalfMM                  -- 4.반기내 월 순번      
                    +  dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo)    ,10,1)    -- 5.수취자(제출자)사업자등록번호      
                    +  dbo._FnVATIntChg(COUNT(B.LandSerl)  , 7,0,1)  -- 6.DATA건수        
                    + '000001'           -- 7.일련번호구분    
                    + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --8.부동산소재지
                    + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --09.임대계약내용 보증금합계
                    + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --10.임대계약내용 월세등합계
                    + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --11.임대료 수입금액합계
                    + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --12.임대료 수입보증금이자합계
                    + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --13.임대료 수입월세등합계
                    + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(A.TaxUnit)), 6) --14.임대건수    
                    + '0000'    --15.종사업자일련번호추가    
                    + SPACE(64) --16.공란    
                    , 250    
                FROM _TTAXLandLease AS A WITH(NOLOCK)
                                         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                                           ON A.CompanySeq      = B.CompanySeq  
                                          AND A.TaxTermSeq      = B.TaxTermSeq  
                                          AND A.TaxUnit         = B.TaxUnit  
                                          AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                           ON A.CompanySeq      = C.CompanySeq  
                                          AND A.TaxUnit         = C.TaxUnit  
                WHERE A.CompanySeq  = @CompanySeq  
                  AND A.TaxTermSeq  = @TaxTermSeq  
                  AND A.TaxUnit     = @TaxUnit  
                GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo  
           END
           ELSE        -- 전자신고 (부동산임대)
           BEGIN
            IF @Env4016 = 4125002     -- 사업자단위과세
				AND EXISTS (SELECT 1 FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq)
                AND @TaxFrDate >= @Env4017
				AND @Unit_SMTaxationType = 4128002  -- 주사업자
			BEGIN 
				
				CREATE TABLE #LandData (  
					Cnt         INT IDENTITY,  
					TaxNo       VARCHAR(15),  
					TaxNoSerl   NVARCHAR(15),  
					OrgTaxNo    VARCHAR(15))  
				CREATE TABLE #LandTmp (  
					Cnt         INT IDENTITY, --- 중요!!  
					TaxNo       VARCHAR(15),  
					Seq         CHAR(6))  
				CREATE TABLE #LandDataSerl (  
					Cnt         INT,         ---- IDENTITY 아님  
					TaxNo       VARCHAR(15),  
					Seq         CHAR(6))
					
				INSERT INTO #LandData (TaxNo, TaxNoSerl, OrgTaxNo)  
					SELECT DISTINCT @TaxUnit, CASE WHEN B.SMTaxationType = 4128002 THEN '0000' ELSE B.TaxNoSerl END AS TaxNoSerl, A.TaxUnit  
					  FROM _TTAXLandLeaseDtl AS A WITH(NOLOCK)
					                            JOIN #TDATaxUnit AS B WITH(NOLOCK)
												  ON A.CompanySeq      = B.CompanySeq
												 AND A.TaxUnit         = B.TaxUnit  
                                                 AND B.SMTaxationType <> 4128001
					 WHERE A.CompanySeq  = @CompanySeq 
					   AND A.TaxTermSeq  = @TaxTermSeq  
				     --ORDER BY B.TaxNoSerl 
				     
				IF NOT EXISTS (SELECT 1 FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq  = @TaxTermSeq AND TaxUnit = @TaxUnit)  
				BEGIN  
				    INSERT INTO #LandData (TaxNo, TaxNoSerl, OrgTaxNo) SELECT @TaxUnit, '0000', @TaxUnit  
				END  
					
				
				DECLARE @TempTaxUnit INT
				
				SELECT @Cnt = 1  
				SELECT @MaxCnt = COUNT(*) FROM #LandData
				  
				WHILE  @Cnt <= @MaxCnt  
				BEGIN  
					SELECT @TempTaxUnit = OrgTaxNo FROM #LandData WHERE Cnt = @Cnt  
  
				    INSERT INTO #LandTmp (TaxNo, Seq)  
					    SELECT DISTINCT A.TaxUnit, A.LandSerl  
					      FROM _TTAXLandLeaseDtl AS A WITH(NOLOCK)
					     WHERE A.CompanySeq	= @CompanySeq
					       AND A.TaxTermSeq = @TaxTermSeq  
					       AND A.TaxUnit	= @TempTaxUnit  
      
				    INSERT INTO #LandDataSerl (Cnt, TaxNo, Seq)  
					    SELECT Cnt, TaxNo, Seq  
					      FROM #LandTmp                                  
                     		
				    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                     SELECT    '17'                 --01.자료구분    
                             + 'I103600'            --02.서식코드    
                             + RIGHT('000000' + CONVERT(VARCHAR(6), D.Cnt), 6) -- 03.일련번호   
                             + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --04.부동산소재지
                             + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --05.임대계약내용 보증금합계
                             + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --06.임대계약내용 월세등합계
                             + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --07.임대계약내용 수입금액합계
                             + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --08.임대계약내용 수입보증금이자합계
                             + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --09.임대계약내용 수입월세등합계
                             + LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))) 
                                + SPACE(10 - DATALENGTH(LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))))) --10.임대인사업자등록번호    
                             + dbo.fnVATIntChg( COUNT(A.TaxUnit)    , 6,0,1)        --11.임대건수
                             + dbo.fnVATCHARChg(CONVERT(VARCHAR(4), D.TaxNoSerl) ,4, 1)             --13.종사업자일련번호추가    
                             + SPACE(70) --12.공란    
                             , 250
                     FROM #LandData AS D JOIN _TTAXLandLease AS A WITH(NOLOCK)
											    ON A.TaxUnit		 = D.OrgTaxNo	
								         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                                                ON A.CompanySeq      = B.CompanySeq  
                                               AND A.TaxTermSeq      = B.TaxTermSeq  
                                               AND A.TaxUnit         = B.TaxUnit  
                                               AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                                ON A.CompanySeq      = C.CompanySeq  
                                               AND D.TaxNo         = C.TaxUnit  
                     WHERE A.CompanySeq  = @CompanySeq 
                       AND D.OrgTaxNo	 = @TempTaxUnit 
                       AND A.TaxTermSeq  = @TaxTermSeq  
                       --AND A.TaxUnit     = @TaxUnit  
                     GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo,D.Cnt ,D.TaxNoSerl

                      INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                      SELECT    '18'                    --01.자료구분    
                              + 'I103600'              --02.서식코드    
                              + RIGHT('000000' + CONVERT(VARCHAR(6), D.Cnt), 6) --03.일련번호구분
                              + RIGHT('000000' + CONVERT(VARCHAR(6), C.Cnt), 6) --04.일련번호     
                              + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --05.층 
                              + LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))))) --06.동   
                              + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum     )))))   --07.호수    
                              + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(CONVERT(DECIMAL(19,2),REPLACE((CASE WHEN Land.LandSize = '' THEN '0' ELSE Land.LandSize END),',',''))))), 10) --08.면적
                              + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --09.임차인상호(성명)    
                              + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                                      LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                                      + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                                 ELSE    
                                      LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                                 END --10.임차인 사업자등록번호    
                              + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --11.임대계약 입주일    
                              + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --12.임대계약 퇴거일    
                              + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --13.임대계약내용 보증금 
                              + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --14.임대계약내용 월세등
                              + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --15.임대료 수입금액계(과표)
                              + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --16.임대료 보증금이자
                              + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --17.임대료 수입금액월세등
                              + CASE WHEN LAND.TaxUnit = @TaxUnit THEN '0000'  
                                     ELSE dbo.fnVATCHARChg(CONVERT(VARCHAR(4), D.TaxNoSerl) ,4, 1) END  --18.종사업자일련번호추가    
                              + LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))))) --19.갱신일
                              + SPACE(33)    
                              , 250     
                        FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                                JOIN _TTAXLandLease AS Dtl WITH(NOLOCK) 
                                                  ON Land.CompanySeq = Dtl.CompanySeq  
                                                 AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                                 AND Land.TaxUnit    = Dtl.TaxUnit   
                                                 AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                     LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                                  ON Land.CompanySeq = Cust.CompanySeq  
                                                 AND Land.CustSeq    = Cust.CustSeq 
                                                JOIN #LandData AS D ON Land.TaxUnit = D.OrgTaxNo 
                                                JOIN #LandDataSerl AS C  
                                                  ON LAND.TaxUnit     = C.TaxNo  
                                                 AND LAND.LandSerl    = C.Seq
                       WHERE Land.CompanySeq  = @CompanySeq  
                         AND Land.TaxTermSeq  = @TaxTermSeq 
                         AND D.OrgTaxNo = @TempTaxUnit 
                       --AND Land.TaxUnit     = @TaxUnit  	
                     ORDER BY D.Cnt,C.Cnt  
                 
                    SELECT @Cnt = @Cnt +1 
                END -- WHILE END
             
			END 
			ELSE IF EXISTS (SELECT * FROM _TTAXLandLeaseDtl WITH(NOLOCK) WHERE CompanySeq  = @CompanySeq and TaxTermSeq = @TaxTermSeq  AND TaxUnit = @TaxUnit ) -- 사업자단위과세가 아닌 경우
			BEGIN
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '17'              --01.자료구분    
                        + 'I103600'         --02.서식코드    
                        + '000001'          --03.일련번호    
                        + dbo.fnVATCHARChg(CONVERT(VARCHAR(70), A.LandPlace)                   ,70,  1)    --04.부동산소재지
                        + dbo.fnVATIntChg( FLOOR(SUM(B.Deposit))                               ,15,0,1)    --05.임대계약내용 보증금합계
                        + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRent))                           ,15,0,1)    --05.임대계약내용 월세등합계
                        + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest + B.MonthlyRentTot))    ,15,0,1)    --05.임대계약내용 수입금액합계
                        + dbo.fnVATIntChg( FLOOR(SUM(B.DepositInterest))                       ,15,0,1)    --05.임대계약내용 수입보증금이자합계
                        + dbo.fnVATIntChg( FLOOR(SUM(B.MonthlyRentTot))                        ,15,0,1)    --05.임대계약내용 수입월세등합계
                        + LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))) + SPACE(10 - DATALENGTH(LTRIM(RTRIM(REPLACE(CONVERT(VARCHAR(10), C.TaxNo), '-', ''))))) --10.임대인사업자등록번호    
                        + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(A.TaxUnit)), 6) --11.임대건수    
                        + '0000'    --13.종사업자일련번호추가    
                        + SPACE(70) --12.공란    
                        , 250    
                FROM _TTAXLandLease AS A WITH(NOLOCK)
                                         JOIN _TTAXLandLeaseDtl AS B WITH(NOLOCK)
                  ON A.CompanySeq      = B.CompanySeq  
                                          AND A.TaxTermSeq      = B.TaxTermSeq  
                                          AND A.TaxUnit         = B.TaxUnit  
                                          AND A.LandPlaceSeq    = B.LandPlaceSeq  
                                         JOIN #TDATaxUnit AS C WITH(NOLOCK)
                                           ON A.CompanySeq      = C.CompanySeq  
                                          AND A.TaxUnit         = C.TaxUnit  
                WHERE A.CompanySeq  = @CompanySeq  
                  AND A.TaxTermSeq  = @TaxTermSeq  
                  AND A.TaxUnit     = @TaxUnit  
                GROUP BY A.TaxUnit, A.LandPlace, C.TaxNo  
  

                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '18'                    --01.자료구분    
                        + 'I103600'              --02.서식코드    
                        + '000001'           --03.일련번호구분    
                        + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Land.LandSerl)), 6) --04.일련번호    
                        + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.FloorNum   )))))   --05.층    
                        + LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), ISNULL(Land.Dong, '')))))) --06.동                                
                        + CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum      ))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(Land.RegNum      )))))   --07.호수    
                        + RIGHT('0000000000' + CONVERT(VARCHAR(10), LTRIM(RTRIM(CONVERT(DECIMAL(19,2),REPLACE((CASE WHEN Land.LandSize = '' THEN '0' ELSE Land.LandSize END),',',''))))), 10) --08.면적
                        + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))))) --08.임차인상호(성명)    
                        + CASE WHEN ISNULL(REPLACE(Cust.BizNo, '-', ''), '') = '' THEN    
                                LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))) 
                                + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''))))))    
                           ELSE    
                                LTRIM(RTRIM(REPLACE(Cust.BizNo, '-', ''))) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),REPLACE(Cust.BizNo, '-', ''))))))    
                           END --09.임차인 사업자등록번호    
                        + LTRIM(RTRIM(Land.FrDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.FrDate))))) --10.임대계약 입주일    
                        + LTRIM(RTRIM(Land.ToDate)) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8),Land.ToDate))))) --11.임대계약 퇴거일    
                        + dbo.fnVATIntChg( FLOOR(Land.Deposit)                                ,13,0,1)    --13.임대계약내용 보증금 
                        + dbo.fnVATIntChg( FLOOR(Land.MonthlyRent)                            ,13,0,1)    --14.임대계약내용 월세등
                        + dbo.fnVATIntChg( FLOOR(Land.DepositInterest + Land.MonthlyRentTot)  ,13,0,1)    --15.임대료 수입금액계(과표)
                        + dbo.fnVATIntChg( FLOOR(Land.DepositInterest)                        ,13,0,1)    --16.임대료 보증금이자
                        + dbo.fnVATIntChg( FLOOR(Land.MonthlyRentTot)                         ,13,0,1)    --17.임대료 수입금액월세등                            
                        + '0000'    
                        + LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), ISNULL(Land.ModDate, '')))))) --20.갱신일    
                        + SPACE(33)    
                        , 250    
                  FROM _TTAXLandLeaseDtl AS Land WITH(NOLOCK)
                                           JOIN _TTAXLandLease AS Dtl WITH(NOLOCK)
                                             ON Land.CompanySeq = Dtl.CompanySeq  
                                            AND Land.TaxTermSeq = Dtl.TaxTermSeq  
                                            AND Land.TaxUnit    = Dtl.TaxUnit   
                                            AND Land.LandPlaceSeq = Dtl.LandPlaceSeq  
                                LEFT OUTER JOIN _TDACust AS Cust WITH(NOLOCK)
                                             ON Land.CompanySeq = Cust.CompanySeq  
                                            AND Land.CustSeq    = Cust.CustSeq  
                 WHERE Land.CompanySeq  = @CompanySeq  
                   AND Land.TaxTermSeq  = @TaxTermSeq  
                   AND Land.TaxUnit     = @TaxUnit
                   
            END  -- 사업자단위과세가 아닌 경우 END
        END -- 전자신고 END
    END -- 부동산임대공가가액 END
END  
  
/***************************************************************************************************************************    
대손세액공제(변제)신고서
01. 자료구분(1) : 17    
02. 서식코드(7) : I102800 / V112
03. 대손변제구분(2) : 대손 '01', 변제 '02'    
04. 일련번호(6)    
05. 대손변제일(8)    
06. 대손변제금액(13)    
07. 대손변제세액(13)    
08. 법인명(상호)(30)    
09. 성명(대표자)(30)    
10. 거래처납세자ID(13) : 거래처사업자등록번호    
11. 대손변제사유(30)    
13. 공란(46)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXBadDebt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '17'            --01. 자료구분    
                   + 'I102800'      --02. 서식코드    
                   + CASE WHEN A.SMDebtKind = 4044001 THEN '01' ELSE '02' END                       --03. 대손변제구분    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Seq)), 6)   --04. 일련번호
                   + CONVERT(VARCHAR(8), A.CfmDate)                                                 --05. 대손변제일    
                   + dbo.fnVATIntChg( FLOOR(A.SupplyAmt)  ,13,0,1)                                  --06. 대손변제금액
                   + dbo.fnVATIntChg( FLOOR(A.VATAmt)     ,13,0,1)                                  --07. 대손변제세액
                   + LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName))) + SPACE(30 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(30), Cust.FullName)))))  --08. 거래자상호    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(Cust.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Cust.Owner      )))))  --09. 성명(대표자)    
                   + CONVERT(VARCHAR(13), LTRIM(RTRIM( ( CASE ISNULL(REPLACE(Cust.BizNo,'-',''),'') WHEN '' 
                                                              THEN ISNULL(REPLACE(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'-',''),'') 
                                                              ELSE ISNULL(REPLACE(Cust.BizNo,'-',''),'') END ) )))    
                     + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), LTRIM(RTRIM(( CASE ISNULL(REPLACE(Cust.BizNo,'-',''),'') WHEN '' 
                                                                                     THEN ISNULL(dbo._FCOMDecrypt(Cust.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') 
                                                                                     ELSE ISNULL(REPLACE(Cust.BizNo,'-',''),'') END ) )))))   --10. 거래처납세자ID     
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(A.Remark  ))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(A.Remark        )))))  --11. 대손변제사유    
                   + SPACE(46)    
                   , 200    
             FROM _TTAXBadDebt AS A WITH(NOLOCK)
                                    JOIN _TDACust AS Cust WITH(NOLOCK)
                                      ON A.CompanySeq   = Cust.CompanySeq  
                                     AND A.CustSeq      = Cust.CustSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSeq  
               AND A.TaxUnit        = @TaxUnit  
    END    
END  
  
/***************************************************************************************************************************   
사업장별부가가치세과세표준 및 납부세액(환급세액)신고
****************************************************************************************************************************/    
IF @WorkingTag IN ('','M')  
BEGIN  
  
    -- 사업자단위과세가 아닐 경우만 출력  
    IF NOT (@Env4016 <> 4125001 AND @TaxFrDate >= @Env4017) 
    BEGIN  
        --==================================================================================================================================================  
        -- 사업장별부가가치세과세표준및납부세액(환급세액)신고명세 디스켓 작성    
        --==================================================================================================================================================  
        IF @WorkingTag = 'M' AND @Unit_SMTaxationType = 4128002 -- 주사업자
        BEGIN  
            -- 제출자 인적사항(HEAD RECORD)    
            /*    
            번호 항  목 형태 길이 누적길이 비고    
            1 레코드구분 문자 2 2 MH    
            2 귀속년도 문자 4 6 YYYY　    
            3 반기구분 문자 1 7 1: 1기, 2: 2기    
            4 반기내 월 순번 문자 1 8 1/2/3/4/5/6    
            5 수취자(제출자)사업자등록번호 문자 10 18 　    
            6 총괄납부승인번호 문자 7 25      
            7 상호(법인명) 문자 60 85 　    
            8 성명(대표자) 문자 30 115 　    
            9 주민(법인)등록번호 문자 13 128 　    
            10 제출일자 문자 8 136 　    
            11 수취자(제출자)전화번호 문자 12 148      
            12 공란 문자 152 300 SPACE    
            */    
  
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT 'MH'                             -- 레코드구분  
                        + LEFT(@TaxFrDate, 4)           -- 귀속년도  
                        + @TermKind                     -- 반기구분  
                        + @YearHalfMM                   -- 반기내 월 순번  
                        + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- 수취자(제출자)사업자등록번호  
                        + CONVERT(VARCHAR(07), TaxSumPaymentNo         + SPACE( 7 - DATALENGTH(CONVERT(VARCHAR( 7), TaxSumPaymentNo         )))) -- 총괄납부승인번호  
                        + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- 상호(법인명)  
                        + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- 성명(대표자)      
                        + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                            + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- 주민(법인)등록번호  
                        + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- 제출일자  
                        + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- 수취자(제출자)전화번호  
                        + SPACE(152)    -- 공란  
                        , 300  
                   FROM #TDATaxUnit WITH(NOLOCK)
                  WHERE CompanySeq  = @CompanySeq  
                    AND TaxUnit     = @TaxUnit  
  
            -- 사업장별부가가치세과세표준및납부세액(환급세액)신고명세(DATA RECORD)    
            /*    
            번호 항  목 형태 길이 누적길이 비고    
            1 레코드구분 문자 2 2 MD    
            2 귀속년도 문자 4 6 YYYY　    
            3 반기구분 문자 1 7 1: 1기, 2: 2기    
            4 반기내 월 순번 문자 1 8 1/2/3/4/5/6    
            5 수취자(제출자)사업자등록번호 문자 10 18 　    
            6 사업자등록번호 문자 10 28      
            7 사업장소재지 문자 70 98 　    
            8 매출과세금액 숫자 15 113 　    
            9 매출과세세액 숫자 13 126 　    
            10 매출영세금액 숫자 15 141      
            11 매출영세세액 숫자 13 154 　    
            12 매입과세금액 숫자 15 169 　    
            13 매입과세세액 숫자 13 182 0으로 기재    
            14 매입의제금액 숫자 15 197      
            15 매입의제세액 숫자 13 210      
            16 가산세 숫자 13 223      
            17 공제세액 숫자 15 238      
            18 납부(환급)세액 숫자 15 253      
            19 내부거래(판매목적)반출액 숫자 15 268      
            20 내부거래(판매목적)반입액 숫자 15 283      
            21 공란 문자 17 300      
            */    
  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'MD'                         -- 레코드구분    
                        +  LEFT(@TaxFrDate,4)           -- 귀속년도    
                        +  @TermKind                    -- 반기구분    
                        +  @YearHalfMM                  -- 반기내 월 순번    
                        + dbo._FnVATCHARChg(@TaxNo,10,1) --05.수취자(제출자)사업자등록번호 문자 10 18 　  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1) --06.사업자등록번호  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(70),Tax.VATRptAddr),70,1)            --07.사업장소재지  
                        + dbo._FnVATIntChg(Rpt.SaleSupplyAmt  ,  15, 0, 1)    --08.매출과세금액  
                        + dbo._FnVATIntChg(Rpt.SaleVATAmt     ,  13, 0, 1)    --09.매출과세세액  
                        + dbo._FnVATIntChg(Rpt.SaleZeroVATAmt ,  15, 0, 1)    --10.매출영세금액  
                        + '0000000000000'                                     --11.매출영세세액  
                        + dbo._FnVATIntChg(Rpt.BuySupplyAmt   ,  15, 0, 1)    --12.매입과세금액  
                        + dbo._FnVATIntChg(Rpt.BuyVATAmt      ,  13, 0, 1)    --13.매입과세세액  
                        + dbo._FnVATIntChg(Rpt.BuyEtcAmt      ,  15, 0, 1)    --14.매입의제금액  
                        + dbo._FnVATIntChg(Rpt.BuyEtcVATAmt   ,  13, 0, 1)    --15.매입의제세액  
                        + dbo._FnVATIntChg(Rpt.AddVATAmt      ,  13, 0, 1)    --16.가산세  
                        + dbo._FnVATIntChg(Rpt.DeducVATAmt    ,  15, 0, 1)    --17.공제세액  
                        + dbo._FnVATIntChg(Rpt.PayAmt         ,  15, 0, 1)    --18.납부(환급)세액  
                        + dbo._FnVATIntChg(Rpt.OutAmt         ,  15, 0, 1)    --19.내부거래(판매목적)반출액  
                        + dbo._FnVATIntChg(Rpt.InAmt          ,  15, 0, 1)    --20.내부거래(판매목적)반입액  
                        + SPACE(17)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
            -- 사업장별부가가치세과세표준및납부세액(환급세액)신고명세 합계(TAIL RECORD)    
            /*    
            번호 항  목 형태 길이 누적길이 비고    
            1 레코드구분 문자 2 2 MT    
            2 귀속년도 문자 4 6 YYYY　　    
            3 반기구분 문자 1 7 1: 1기, 2: 2기    
            4 반기내 월 순번 문자 1 8 1/2/3/4/5/6    
            5 수취자(제출자)사업자등록번호 문자 10 18 　    
            6 DATA 건수 숫자 7 25      
            7 매출과세금액합계 숫자 15 40      
            8 매출과세세액합계 숫자 15 55      
            9 매출영세금액합계 숫자 15 70      
            10 매출영세세액합계 숫자 15 85 0으로 기재    
            11 매입과세금액합계 숫자 15 100      
            12 매입과세세액합계 숫자 15 115      
            13 매입의제금액합계 숫자 15 130      
            14 매입의제세액합계 숫자 15 145      
            15 가산세합계 숫자 15 160      
            16 공제세액합계 숫자 15 175      
            17 납부(환급)세액합계 숫자 15 190      
            18 내부거래(판매목저)반출액합계 숫자 15 205      
            19 내부거래(판매목저)반입액합계 숫자 15 220      
            20 공란 문자 80 300      
            */    
  INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)    
                SELECT 'MT'                         -- 1 레코드구분 문자 2 2 MT    
                        +  LEFT(@TaxFrDate,4)           -- 2 귀속년도 문자 4 6 YYYY　　      
                        +  @TermKind                    -- 3 반기구분 문자 1 7 1: 1기, 2: 2기      
                        +  @YearHalfMM                  -- 4 반기내 월 순번 문자 1 8 1/2/3/4/5/6    
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(@TaxNo,'-','')),10,1) --5 수취자(제출자)사업자등록번호 문자 10 18    
                        + dbo._FnVATIntChg(COUNT(*), 7, 0, 1)                                 --6 DATA 건수 숫자 7 25      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleSupplyAmt  ), 0),  15, 0, 1)    --7 매출과세금액합계 숫자 15 40      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleVATAmt     ), 0),  15, 0, 1)    --8 매출과세세액합계 숫자 15 55      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.SaleZeroVATAmt ), 0),  15, 0, 1)    --9 매출영세금액합계 숫자 15 70      
                        + '000000000000000'                                                   --10 매출영세세액합계 숫자 15 85 0으로 기재    
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuySupplyAmt   ), 0),  15, 0, 1)    --11 매입과세금액합계 숫자 15 100      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyVATAmt      ), 0),  15, 0, 1)    --12 매입과세세액합계 숫자 15 115      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyEtcAmt      ), 0),  15, 0, 1)    --13 매입의제금액합계 숫자 15 130      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.BuyEtcVATAmt   ), 0),  15, 0, 1)    --14 매입의제세액합계 숫자 15 145      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.AddVATAmt      ), 0),  15, 0, 1)    --15 가산세합계 숫자 15 160      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.DeducVATAmt    ), 0),  15, 0, 1)    --16 공제세액합계 숫자 15 175      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.PayAmt         ), 0),  15, 0, 1)    --17 납부(환급)세액합계 숫자 15 190      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.OutAmt         ), 0),  15, 0, 1)    --18 내부거래(판매목저)반출액합계 숫자 15 205      
                        + dbo._FnVATIntChg(ISNULL(SUM(Rpt.InAmt          ), 0),  15, 0, 1)    --19 내부거래(판매목저)반입액합계 숫자 15 220      
                        + SPACE(80)                                                           --20 공란 문자 80 300      
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
        END  
        ELSE        -- 전자신고
        BEGIN   
            /***************************************************************************************************************************  
            사업장별 부가가치세 과세표준 및 납부세액(환급세액)신고명세서  
  
            01. 자료구분(2) : 17  
            02. 서식코드(7) : I104500 / V115
            03. 매출과세금액합계(15)  
            04. 매출가세세액합계(15)  
            05. 매출영세금액합계(15)  
            06. 매출영세세액합계(15)  
            07. 매입과세금액합계(15)  
            08. 매입과세세액합계(15)  
            09. 매입의제금액합계(15)  
            10. 매입의제세액합계(15)  
            11. 가산세합계(15)  
            12. 공제세액합계(15)  
            13. 납부(환급)세액합계(15)  
            14. 내부거래(판매목적)반출액합계(15)  
            15. 내부거래(판매목적)반입액합계(15)  
            16. 공란(96)  
            ****************************************************************************************************************************/  
            IF EXISTS (SELECT * FROM _TTAXBizStdSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
            BEGIN  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT    '17'         --01.자료구분  
                        + 'I104500'       --02.서식코드  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleSupplyAmt)  ,  15, 0, 1)    --03.매출과세금액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleVATAmt)     ,  15, 0, 1)    --04.매출과세세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.SaleZeroVATAmt) ,  15, 0, 1)    --05.매출영세금액합계  
                        + '000000000000000'                                        --06.매출영세세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.BuySupplyAmt)   ,  15, 0, 1)    --07.매입과세금액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyVATAmt)      ,  15, 0, 1)    --08.매입과세세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyEtcAmt)      ,  15, 0, 1)    --09.매입의제금액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.BuyEtcVATAmt)   ,  15, 0, 1)    --10.매입의제세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.AddVATAmt)      ,  15, 0, 1)    --11.가산세합계  
                        + dbo._FnVATIntChg(SUM(Rpt.DeducVATAmt)    ,  15, 0, 1)    --12.공제세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.PayAmt)         ,  15, 0, 1)    --13.납부(환급)세액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.OutAmt)         ,  15, 0, 1)    --14.내부거래(판매목적)반출액합계  
                        + dbo._FnVATIntChg(SUM(Rpt.InAmt)          ,  15, 0, 1)    --15.내부거래(판매목적)반입액합계  
                        + SPACE(96)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
  
                /***************************************************************************************************************************  
                사업장별 부가가치세 과세표준 및 납부세액(환급세액)신고명세서 세부내용  
  
                01. 자료구분(2) : 18  
                02. 서식코드(7) : I104500 / V115
                03. 사업자등록번호(10)  
                04. 사업장소재지(70)  
                05. 매출과세금액(15)  
                06. 매출과세세액(13)  
                07. 매출영세금액(15)  
                08. 매출영세세액(13)  
                09. 매입과세금액(15)  
                10. 매입과세세액(13)  
                11. 매입의제금액(15)  
                12. 매입의제세액(13)  
                13. 가산세(13)  
                14. 공제세액(15)  
                15. 납부(환급)세액(15)  
                16. 내부거래(판매목적)반출액(15)  
                17. 내부거래(판매목적)반입액(15)  
                18. 공란(26)  
                ****************************************************************************************************************************/  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                SELECT    '18'                --01.자료구분  
                        + 'I104500'          --02.서식코드  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1) --03.사업자등록번호  
                        + dbo._FnVATCHARChg(CONVERT(VARCHAR(70),Tax.VATRptAddr),70,1)            --04.사업장소재지  
                        + dbo._FnVATIntChg(Rpt.SaleSupplyAmt  ,  15, 0, 1)    --03.매출과세금액  
                        + dbo._FnVATIntChg(Rpt.SaleVATAmt     ,  13, 0, 1)    --04.매출과세세액  
                        + dbo._FnVATIntChg(Rpt.SaleZeroVATAmt ,  15, 0, 1)    --05.매출영세금액  
                        + '0000000000000'                                     --06.매출영세세액  
                        + dbo._FnVATIntChg(Rpt.BuySupplyAmt   ,  15, 0, 1)    --07.매입과세금액  
                        + dbo._FnVATIntChg(Rpt.BuyVATAmt      ,  13, 0, 1)    --08.매입과세세액  
                        + dbo._FnVATIntChg(Rpt.BuyEtcAmt      ,  15, 0, 1)    --09.매입의제금액  
                        + dbo._FnVATIntChg(Rpt.BuyEtcVATAmt   ,  13, 0, 1)    --10.매입의제세액  
                        + dbo._FnVATIntChg(Rpt.AddVATAmt      ,  13, 0, 1)    --11.가산세  
                        + dbo._FnVATIntChg(Rpt.DeducVATAmt    ,  15, 0, 1)    --12.공제세액  
                        + dbo._FnVATIntChg(Rpt.PayAmt         ,  15, 0, 1)    --13.납부(환급)세액  
                        + dbo._FnVATIntChg(Rpt.OutAmt         ,  15, 0, 1)    --14.내부거래(판매목적)반출액  
                        + dbo._FnVATIntChg(Rpt.InAmt          ,  15, 0, 1)    --15.내부거래(판매목적)반입액  
                        + SPACE(26)  
                        , 300  
                  FROM _TTAXBizStdSum AS Rpt WITH(NOLOCK)
                    LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK) ON Rpt.CompanySeq = Tax.CompanySeq AND Rpt.RptTaxUnit = Tax.TaxUnit  
                 WHERE Rpt.CompanySeq = @CompanySeq   
                   AND Rpt.TaxTermSeq = @TaxTermSeq   
                   AND Rpt.TaxUnit    = @TaxUnit  
  
            END  
        END  -- 전자신고 END
    END  
END  

/***************************************************************************************************************************    
건물등 감가상각자산 취득명세서    
    
01. 자료구분(2) : 17    
02. 서석코드(7) : I103800 / V149
03. 건수합계_고정자산(11)    
04. 공급가액합계_고정자산(13)    
05. 세액합계_고정자산(13)    
06. 건수_건물, 구축물(11)    
07. 공급가액_건물, 구축물(13)    
08. 세액_건물, 구축물(13)    
09. 건수_기계장치(11)    
10. 공급가액_기계장치(13)    
11. 세액_기계장치(13)    
12. 건수_차량운반구(11)    
13. 공급가액_차량운반구(13)    
14. 세액_차량운반구(13)    
15. 건수_기타감가상각자산(11)    
16. 공급가액_기타감가상각자산(13)    
17. 세액_기타감가상각자산(13)    
18. 공란(6)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXAsstPur WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (Cnt <> 0 OR SupplyAmt <> 0 OR VATAmt <> 0))  
    BEGIN  
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17'      --01 자료구분    
               + 'I103800'     --02. 서식코드    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(Cnt)), 11)            --03. 건수합계_고정자산    
               + CASE WHEN SUM(SupplyAmt) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(SupplyAmt))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(SupplyAmt)))), 13), 1, 1, '-')    
                  END --04. 공급가액합계_고정자산    
               + CASE WHEN SUM(VATAmt) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(VATAmt))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(VATAmt)))), 13), 1, 1, '-')    
                  END --05. 세액합계_고정자산    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110001 THEN Cnt ELSE 0 END)), 11)    --06. 건수_건물, 구축물    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --07. 공급가액_건물, 구축물    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110001 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --08. 세액_건물, 구축물    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110002 THEN Cnt ELSE 0 END)), 11)    --09. 건수_기계장치    
          + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --10. 공급가액_기계장치    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110002 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --11. 세액_기계장치    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110003 THEN Cnt ELSE 0 END)), 11)    --12. 건수_차량운반구    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --13. 공급가액_차량운반구    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110003 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --14. 세액_차량운반구    
               + RIGHT('00000000000' + CONVERT(VARCHAR(11), SUM(CASE WHEN SMAsstKind = 4110004 THEN Cnt ELSE 0 END)), 11)    --15. 건수_기타감가상각자산    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END) >= 0 THEN    
                 RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN SupplyAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --16. 공급가액_차량운반구    
               + CASE WHEN SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END) >= 0 THEN    
                       RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END))), 13)    
                  ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM(CASE WHEN SMAsstKind = 4110004 THEN VATAmt ELSE 0 END)))), 13), 1, 1, '-')    
                  END --17. 세액_차량운반구    
               + SPACE(6)    
               , 200    
         FROM _TTAXAsstPur WITH(NOLOCK)
         WHERE CompanySeq   = @CompanySeq  
           AND TaxTermSeq   = @TaxTermSeq  
           AND TaxUnit      = @TaxUnit  
    END    
END  
/***************************************************************************************************************************    
공제받지 못할 매입세액 명세서
    
01. 자료구분(2) : 17    
02. 서식코드(7) : I103300 / V153
03. 매수합계_세금계산서(11)    
04. 공급가액합계_세금계산서(15)    
05. 매입세액합계_세금계산서(15)
06. 공통매입공급가액합계_안분계산(15)    
07. 공통매입세액합계_안분계산(15)    
08. 불공제매입세액합계_안분계산(15)    
09. 불공제매입세액총액합계_정산내역(15)    
10. 기불공제매입세액합계_정산내역(15)    
11. 가산, 공제매입세액합계_정산내역(15)    
12. 가산, 공제매입세액합계_납부재계산(15)    
13. 공란(45)    
****************************************************************************************************************************/    
  
    DECLARE @NotDeducNum    DECIMAL(19,5) ,    
            @NotDeducAmt    DECIMAL(19,5) ,    
            @NotDeducTaxAmt DECIMAL(19,5) ,    
            @Amt19V153_09   DECIMAL(19,4) ,    
            @Amt19V153_10   DECIMAL(19,4) ,    
            @Amt19V153_13   DECIMAL(19,4) ,    
            @Amt20V153_16   DECIMAL(19,4) ,    
            @Amt20V153_17   DECIMAL(19,4) ,    
            @Amt20V153_18   DECIMAL(19,4) ,    
            @Amt21V153_22   DECIMAL(19,4)    
  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0) )  
         --OR EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
         --                                                            AND ( Amt19V153_09 <> 0 OR Amt19V153_10 <> 0 OR Amt19V153_11 <> 0 OR Amt19V153_12 <> 0 OR Amt19V153_13 <> 0 ) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt20V153_14 <> 0 OR Amt20V153_15 <> 0 OR Amt20V153_17 <> 0) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt21V153_19 <> 0 OR Amt21V153_20 <> 0 OR Amt21V153_21 <> 0) )  
    BEGIN  
        SELECT @NotDeducNum = SUM( ISNULL( NotDeduc.Cnt ,0) ) ,         --03. 세금계산서매수    
               @NotDeducAmt = SUM( ISNULL( NotDeduc.SupplyAmt ,0) ) ,   --04. 세금계산서 공급가액    
               @NotDeducTaxAmt = SUM( ISNULL( NotDeduc.VATAmt ,0) )     --05. 세금계산서 매입세액    
            FROM _TTAXNotDeductSum AS NotDeduc WITH(NOLOCK)
            WHERE NotDeduc.CompanySeq   = @CompanySeq  
              AND NotDeduc.TaxTermSeq   = @TaxTermSeq  
              AND NotDeduc.TaxUnit      = @TaxUnit  
              AND (NotDeduc.Cnt <> 0 OR NotDeduc.SupplyAmt <> 0 OR NotDeduc.VATAmt <> 0 )  
  
        SELECT @Amt19V153_09 = SUM( ISNULL( CVat.Amt19V153_09 ,0) ) ,   --06.공통매입공급가액합계_안분계산    
               @Amt19V153_10 = SUM( ISNULL( CVat.Amt19V153_10 ,0) ) ,   --07.공통매입세액합계_안분계산    
               @Amt19V153_13 = SUM( ISNULL( CVat.Amt19V153_13 ,0) )     --08.불공제매입세액합계_안분계산
            FROM _TTAXNotDeduct19Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
  
        SELECT @Amt20V153_16 = SUM( ISNULL(CVat.Amt20V153_16, 0) ) ,    --09.불공제매입세액총액합계_정산내역
               @Amt20V153_17 = SUM( ISNULL(CVat.Amt20V153_17 ,0) ) ,    --10.기불공제매입세액합계_정산내역    
               @Amt20V153_18 = SUM( ISNULL(CVat.Amt20V153_16, 0) ) - SUM( ISNULL(CVat.Amt20V153_17, 0) ) --11.가산, 공제매입세액합계_정산내역 
            FROM _TTAXNotDeduct20Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
        -- 합계 후 절사되어 명세 내역과 차이 발생하여 절사 후 합계하도록 수정
        SELECT @Amt21V153_22 = SUM( FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0)) )      --12.가산, 공제매입세액합계_납부재계산    
            FROM _TTAXNotDeduct21Sum AS CVat WITH(NOLOCK)
            WHERE CVat.CompanySeq   = @CompanySeq  
              AND CVat.TaxTermSeq   = @TaxTermSeq  
              AND CVat.TaxUnit      = @TaxUnit  
        
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17' --01.자료구분    
              + 'I103300' --02.서식코드    
              + RIGHT('00000000000'     + CONVERT(VARCHAR(11), FLOOR( ISNULL(@NotDeducNum,0) )), 11)       --03. 세금계산서매수    
              + CASE WHEN FLOOR( ISNULL(@NotDeducAmt,0) ) >= 0 THEN                                                                     --04. 세금계산서 공급가액    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@NotDeducAmt,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@NotDeducAmt,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@NotDeducTaxAmt,0) ) >= 0 THEN                                                                  --05. 세금계산서 매입세액    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@NotDeducTaxAmt,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@NotDeducTaxAmt,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_09,0) ) >= 0 THEN                                                                    --06.공통매입공급가액합계_안분계산    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_09,0) )), 15)    
                 ELSE    
                  STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_09,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_10,0) ) >= 0 THEN                                                                    --07.공통매입세액합계_안분계산    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_10,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_10,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt19V153_13,0) ) >= 0 THEN                                                                    --08.불공제매입세액합계_안분계산    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt19V153_13,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt19V153_13,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_16,0) ) >= 0 THEN                                                                    --09.불공제매입세액총액합계_정산내역    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_16,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_16,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_17,0) ) >= 0 THEN                                                                    --10.기불공제매입세액합계_정산내역    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_17,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_17,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt20V153_18,0) ) >= 0 THEN                                                                    --11.가산, 공제매입세액합계_정산내역    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt20V153_18,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt20V153_18,0) ))), 15), 1, 1, '-')    
                 END    
              + CASE WHEN FLOOR( ISNULL(@Amt21V153_22,0) ) >= 0 THEN                                                                    --12.가산, 공제매입세액합계_납부재계산    
                      RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR( ISNULL(@Amt21V153_22,0) )), 15)    
                 ELSE    
                       STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR( ISNULL(@Amt21V153_22,0) ))), 15), 1, 1, '-')    
                 END    
              + SPACE(45)    
              , 200    
    END    
END    
/***************************************************************************************************************************    
공제받지 못할 매입세액 명세서_명세              불공제사유구분
01. 자료구분        (2) : 18                    [01] 필요적기재사항누락
02. 서식코드        (7) : I103300 / V153        [02] 사업과 직접관련 없는 지출
03. 불공제사유구분  (2) :                       [03] 비영업용 소형승용차 구입 및 유지
04. 세금계산서매수  (11)                        [04] 접대비 및 이와 유사한 비용 관련
05. 공급가액        (13)                        [05] 면세사업관련
06. 매입세액        (13)                        [06] 토지의 자본적지출관련
07. 공란            (52)                        [07] 사업자등록 전 매입세액
                                                [08] 금,구리스크랩 거래계좌 미사용 관련 매입세액
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0))  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '18'   --01. 자료구분    
                   + 'I103300'  --02. 서식코드    
                   + RIGHT('00' + CONVERT(VARCHAR(2), NotDeduc.SMNotDeductKind - 4109000), 2)   --03. 불공제항목번호    
                   + RIGHT('00000000000' + CONVERT(VARCHAR(11), FLOOR(NotDeduc.Cnt)), 11)       --04. 세금계산서매수    
                   + CASE WHEN FLOOR(NotDeduc.SupplyAmt) >= 0 THEN                              --05. 세금계산서 공급가액    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(NotDeduc.SupplyAmt)), 13)    
                     ELSE    
                           STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(NotDeduc.SupplyAmt))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR(NotDeduc.VATAmt) >= 0 THEN                                 --06. 세금계산서 매입세액    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR(NotDeduc.VATAmt)), 13)    
                     ELSE    
                           STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(NotDeduc.VATAmt))), 13), 1, 1, '-')    
                     END    
                   + SPACE(52)    
                   , 100    
             FROM _TTAXNotDeductSum AS NotDeduc WITH(NOLOCK)
             WHERE NotDeduc.CompanySeq  = @CompanySeq  
               AND NotDeduc.TaxTermSeq  = @TaxTermSeq  
               AND NotDeduc.TaxUnit     = @TaxUnit  
               AND ( NotDeduc.Cnt <> 0 OR NotDeduc.SupplyAmt <> 0 OR NotDeduc.VATAmt <> 0)  
             ORDER BY NotDeduc.SMNotDeductKind   
        
    END    
END      
/***************************************************************************************************************************    
공제받지 못할 매입세액 명세서_공통매입세액안분계산내역          2006.03.17 <신규서식>        -- 20060708 by Him    
    
01. 자료구분(2) : 19    
02. 서식코드(7) : I103300 / V153
03. 일련번호(6) : 000001 부터 순차적으로 부여    
04. 공통매입공급가액(13)    :    
05. 공통매입세액(13)        :    
06. 총공급가액등(15,2)        :    
07. 면세공급가액등(15,2)    
08. 불공제매입세액(13)      : 05.공통매입세액 * ( 07.면세공급가액등 / 06.총공급가액등 ) , ( 07.면세공급가액등 / 06.총공급가액등 ) 계산값은 소수 6자리    
09. 공란(19)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXNotDeductSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND (SupplyAmt <> 0 OR VATAmt <> 0) )  
         --OR EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
         --                                                            AND ( Amt19V153_09 <> 0 OR Amt19V153_10 <> 0 OR Amt19V153_11 <> 0 OR Amt19V153_12 <> 0 OR Amt19V153_13 <> 0 ) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt20V153_14 <> 0 OR Amt20V153_15 <> 0 OR Amt20V153_17 <> 0) )  
         OR EXISTS (SELECT 1 FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit  
                                                                     AND ( Amt21V153_19 <> 0 OR Amt21V153_20 <> 0 OR Amt21V153_21 <> 0) )
                                                                     
        AND EXISTS (SELECT 1 FROM _TTAXNotDeduct19Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '19'   --01. 자료구분    
                   + 'I103300'  --02. 서식코드    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6) --03. 일련번호    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_09 ,0) ) >= 0 THEN                                                    --04. 공통매입 공급가액(9)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_09 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_09 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_10 ,0) ) >= 0 THEN                                                    --05. 공통매입 세액(10)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_10 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_10 ,0) ))), 13), 1, 1, '-')    
                     END    
                   +  dbo._FnVATIntChg((ISNULL(CVat.Amt19V153_11   , 0)), 15, 2, 1)
                   --+ CASE WHEN CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_11 ,0) ) >= 0 THEN                                   --06. 총공급가액 등 (11)    
                   --       RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_11 ,0) )), '.', ''), 15)    
                   --  ELSE    
                   --       STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ABS(ISNULL( CVat.Amt19V153_11 ,0)) )), '.', ''), 15), 1, 1, '-')    
                   --  END    
                   + dbo._FnVATIntChg((ISNULL(CVat.Amt19V153_12   , 0)), 15, 2, 1)
                   --+ CASE WHEN CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_12 ,0) ) >= 0 THEN                                   --07. 면세공급가액 등 (12)    
                   --       RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ISNULL( CVat.Amt19V153_12 ,0) )), '.', ''), 15)    
                   --  ELSE    
                   --       STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 0), ABS(ISNULL( CVat.Amt19V153_12 ,0)) )), '.', ''), 15), 1, 1, '-')    
                   --  END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt19V153_13 ,0) ) >= 0 THEN                                                    --08. 불공제매입세액(13) = 10 * (12/11)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt19V153_13 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt19V153_13 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + SPACE(16)    
                   , 100    
             FROM _TTAXNotDeduct19Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt19V153_09 <> 0 OR CVat.Amt19V153_10 <> 0 OR CVat.Amt19V153_11 <> 0 OR CVat.Amt19V153_12 <> 0 OR CVat.Amt19V153_13 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
공제받지 못할 매입세액 명세서_공통매입세액정산내역
    
01. 자료구분(2) : 20    
02. 서식코드(7) : I103300 / V153
03. 일련번호(6) : 000001 부터 순차적으로 부여    
04. 총공통매입세액(13)    :    
05. 면세사업확정비율(11,6)        :    
06. 불공제매입세액총액(13)    
07. 기불공제매입세액(13)    
08. 가산/공제매입세액(13)    
09. 공란(22)    
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXNotDeduct20Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '20'   --01. 자료구분    
                   + 'I103300'  --02. 서식코드    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6) --03. 일련번호    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_14 ,0) ) >= 0 THEN                                     --04. 총공통매입세액(14)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_14 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_14 ,0) ))), 13), 1, 1, '-')    
                     END    
                   + CASE WHEN CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) ) >= 0 THEN                    --05. 면세사업확정비율(15)    
                          RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) )), '.', ''), 11)    
                     ELSE    
                          STUFF(RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), ABS(CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt20V153_15  ,0) ))), '.', ''), 11), 1, 1, '-')    
                     END
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_16 ,0) ) >= 0 THEN                                     --06. 불공제 매입세액총액(16) = (14 * 15)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_16 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_16 ,0) ))), 13) , 1, 1, '-')    
                     END   
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt20V153_17 ,0) ) >= 0 THEN                                     --07. 기불공제매입세액(17)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt20V153_17 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt20V153_17 ,0) ))), 13), 1, 1, '-')    
                     END
                   + CASE WHEN FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) ) >= 0 THEN --08. 가산 또는 공제되는 매입세액 (18) = (16-17)
                                RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) )), 13)    
                     ELSE    
                            STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS( FLOOR( ( ISNULL( CVat.Amt20V153_16 ,0) ) - ISNULL( CVat.Amt20V153_17 ,0) ))), 13), 1, 1, '-')    
                     END  
                   + SPACE(22)    
                   , 100    
             FROM _TTAXNotDeduct20Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt20V153_14 <> 0 OR CVat.Amt20V153_15 <> 0 OR CVat.Amt20V153_17 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
공제받지 못할 매입세액 명세서_납부세액_환급세액재계산내역
    
01. 자료구분(2) : 20    
02. 서식코드(7) : I103300 / V153
03. 일련번호(6) : 000001 부터 순차적으로 부여    
04. 재화매입세액(13)    
05. 경감률_납부재계산(7,4)    
06. 증가/감소면세비율(11,6)    
07. 가산/공제매입세액(13)    
08. 공란(41)    
****************************************************************************************************************************/   
IF @WorkingTag = ''  
BEGIN   
    IF EXISTS (SELECT * FROM _TTAXNotDeduct21Sum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT '21'   --01. 자료구분    
                   + 'I103300'  --02. 서식코드    
                   + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR( ISNULL( CVat.Serl ,0) )), 6)           --03. 일련번호    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_19 ,0) ) >= 0 THEN                         --04. 해당 재화의 매입세액(19)    
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt21V153_19 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt21V153_19 ,0) ))), 13) , 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_20 ,0) ) >= 0 THEN                         --05. 경감률[1-(5/100) 또는 25/100 * 경과된 과세기간의 수)](20)    
                          RIGHT('0000000' + REPLACE(CONVERT(VARCHAR(13), CONVERT(NUMERIC(15, 4), ISNULL( CVat.Amt21V153_20 ,0) )), '.', ''), 7)    
                     ELSE    
                          STUFF(RIGHT('0000000' + REPLACE(CONVERT(VARCHAR(13), ABS(CONVERT(NUMERIC(15, 4), ISNULL( CVat.Amt21V153_20 ,0) ))), '.', ''), 7) , 1, 1, '-')    
                     END    
                   + CASE WHEN FLOOR( ISNULL( CVat.Amt21V153_21 ,0) ) >= 0 THEN                         --06. 증가 또는 감소된 면세공급가액(사용면적)비율(21)    
                          RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt21V153_21 ,0) )), '.', ''), 11)    
                     ELSE    
                          STUFF(RIGHT('00000000000' + REPLACE(CONVERT(VARCHAR(11), ABS(CONVERT(NUMERIC(15, 6), ISNULL( CVat.Amt21V153_21 ,0) ))), '.', ''), 11) , 1, 1, '-')    
                     END    
                   + CASE WHEN ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0)  >= 0 THEN    --07. 가산 또는 공제되는 매입세액(22) = (19*20*21)
                          RIGHT('0000000000000' + CONVERT(VARCHAR(13), FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0) )), 13)    
                     ELSE    
                          STUFF(RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR( ISNULL( CVat.Amt21V153_19 ,0)  * ISNULL( CVat.Amt21V153_20 ,0) * ISNULL( CVat.Amt21V153_21 ,0) ))), 13) , 1, 1, '-')    
                     END
                   + SPACE(41)    
                   , 100    
              FROM _TTAXNotDeduct21Sum AS CVat WITH(NOLOCK)
             WHERE CVat.CompanySeq  = @CompanySeq  
               AND CVat.TaxTermSeq  = @TaxTermSeq  
               AND CVat.TaxUnit     = @TaxUnit  
               AND (CVat.Amt21V153_19 <> 0 OR CVat.Amt21V153_20 <> 0 OR CVat.Amt21V153_21 <> 0)  
             ORDER BY CVat.Serl    
    END    
END      
/***************************************************************************************************************************    
월별판매액합계표(농.축산.임.어업기자재)    
    
01. 자료구분(2) : 17    
02. 서식코드(7) : M200100 / V148
03. 월별(06) : YYYYMM
04. 품명(30) : NULL허용, 월별 판매 품목
05. 판매수량(20) : NOT NULL, CHARACTER입력가능 
06. 판매가액(13)
07. 판매가액_합계(15)
08. 월별판매합계표제출구분코드(2) : 01 장애인용보장구, 02 농축임어업용기자재
09. 공란(9)
****************************************************************************************************************************/    
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXMonSalesSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND IsSUM = 0 )  
    BEGIN
        DECLARE @MonSalesSum DECIMAL(19,5)
        
        SELECT @MonSalesSum = ISNULL((SELECT SUM(SalesAmt)
                                        FROM _TTAXMonSalesSum WITH(NOLOCK) 
                                       WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq 
                                         AND TaxUnit = @TaxUnit       AND IsSUM = 0),0)
      
         INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
         SELECT '17'                                                -- 01. 자료구분    
              + 'M200100'                                           -- 02. 서식코드    
			  + dbo._FnVATIntChg(ISNULL(A.YM,''),6,0,1)             -- 03. 월별			
			  + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), MAX(ISNULL(B.ItemName,''))), 30, 1)	-- 04. 품명
			  + CASE WHEN ISNULL(A.UMReportKind, 0) = 4110002 
			         THEN dbo._FnVATIntChg(0                    , 20, 0, 1)     -- 장애인용보장구 일 경우 0으로 기재
			         ELSE dbo._FnVATIntChg(SUM(ISNULL(A.Qty ,0)), 20, 0, 1)
			    END                                                         -- 05. 판매수량
			  + dbo._FnVATIntChg(SUM(ISNULL(A.SalesAmt   , 0)), 13, 0, 1)	-- 06. 판매가액
			  + dbo._FnVATIntChg(SUM(ISNULL(@MonSalesSum , 0)), 15, 0, 1)	-- 07. 판매가액_합계
			  + CASE WHEN ISNULL(A.UMReportKind, 0) = 4110001 THEN '02' -- 08. 월별판매합계표제출구분코드 : (기본 농축임)
			         WHEN ISNULL(A.UMReportKind, 0) = 4110002 THEN '01' -- [01] 장애인용보장구,
			         ELSE '02'  END                                     -- [02] 농축임어업용기자재
			  + SPACE(55)		                                    -- 09. 공란
			  , 150   
          FROM _TTAXMonSalesSum AS A WITH(NOLOCK) LEFT OUTER JOIN _TDAItem AS B WITH(NOLOCK) 
                                                   ON A.CompanySeq  = B.CompanySeq 
                                                  AND A.ItemSeq     = B.ItemSeq
         WHERE A.CompanySeq   = @CompanySeq  
           AND A.TaxTermSeq   = @TaxTermSeq  
           AND A.TaxUnit      = @TaxUnit  
           AND A.IsSUM        <> 1
         GROUP BY ISNULL(A.YM,'') , A.UMReportKind, A.ItemSeq
    END    
END   

/***************************************************************************************************************************
매입자발행세금계산서합계표_합계
01. 자료구분                     2
02. 서식코드                     7
03. 매입처수                     7
04. 세금계산서매수_합계          7
05. 공급가액_합계               15
06. 세액_합계                   15
07. 공란                        47
****************************************************************************************************************************/
IF @WorkingTag = ''
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXTaxBillBuySum AS A WITH (NOLOCK) WHERE A.CompanySeq = @CompanySeq AND A.TaxTermSeq = @TaxTermSeq AND A.TaxUnit = @TaxUnit)
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '17'
      /*02*/ + 'M118000'
      /*03*/ + RIGHT('0000000' + CONVERT(VARCHAR(7), COUNT(A.CustSeq)), 7)
      /*04*/ + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(A.CustSeq, 0) <> 0 THEN A.BillCnt ELSE 0 END), 7, 0, 1)
      /*05*/ + dbo._FnVATIntChg(SUM(A.SupplyAmt), 15, 0, 1)
      /*06*/ + dbo._FnVATIntChg(SUM(A.VATAmt)   , 15, 0, 1)
      /*07*/ + SPACE(47)
             , 100
          FROM _TTAXTaxBillBuySum AS A WITH(NOLOCK)
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    /***************************************************************************************************************************
    매입자발행세금계산서합계표_세부내용
    01. 자료구분                     2
    02. 서식코드                     7
    03. 일련번호                     6
    04. 거래자등록번호              10
    05. 거래자상호                  30
    06. 세금계산서매수               7
    07. 공급가액                    13
    08. 세액                        13
    09. 공란                        12
    ****************************************************************************************************************************/
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'
      /*02*/ + 'M118000'
      /*03*/ + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY B.CustName)), 6)
      /*04*/ + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), B.BizNo)   , 10, 1)
      /*05*/ + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), B.FullName), 30, 1)
      /*06*/ + dbo._FnVATIntChg(CASE WHEN ISNULL(A.CustSeq, 0) <> 0 THEN A.BillCnt ELSE 0 END, 7, 0, 1)
      /*07*/ + dbo._FnVATIntChg(A.SupplyAmt , 13, 0, 1)
      /*08*/ + dbo._FnVATIntChg(A.VATAmt    , 13, 0, 1)
      /*09*/ + SPACE(12)
             , 100
          FROM _TTAXTaxBillBuySum   AS A WITH(NOLOCK)
               JOIN _TDACust        AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                     AND A.CustSeq    = B.CustSeq
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    END
END
-- 2017년 1기 예정 추가
/***************************************************************************************************************************
첨부서류17. 과세사업전환감가상각자산신고서
-- 과세사업전환감가상각자산신고서_면세사업자인적사항
01. 자료구분                    (2)     : 17
02. 서식코드                    (7)     : I102600
03. 과세사업사용_소비시기       (8)
04. 상호_면세사업자             (30)
05. 사업자등록번호_면세사업자   (10)
06. 사업장소재지_면세사업자     (70)
07. 전화번호_면세사업자         (14)
08. 공란                        (9)
-- 과세사업전환감가상각자산신고서 감가상각자산신고서
01. 자료구분            (2)
02. 서식코드            (7)
03. 일련번호            (6)
04. 감가상각자산_구분   (2) : 01 - 건축/구축물, 02 - 기타
05. 수량                (11)
06. 취득일              (8)
07. 면세불공제세액      (13)
08. 과세공제매입세액    (13)
09. 보관장소            (70)
10. 공란                (18)
**************************************************************************************************************************/
IF @WorkingTag = ''
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                        JOIN _TTAXBizChangeAssetsDtl AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                      AND A.TaxTermSeq = B.TaxTermSeq
                                                                      AND A.TaxUnit    = B.TaxUnit
        WHERE A.CompanySeq = @CompanySeq
          AND A.TaxTermSeq = @TaxTermSeq
          AND A.TaxUnit    = @TaxUnit )
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '17'         --01. 자료구분
             + 'I102600'    --02. 서식코드
             + CONVERT(VARCHAR(8), A.UseDate)   --03. 과세사업사용_소비시기
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(B.TaxName  ,'')), 30, 1)   --04. 상호_면세사업자
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), ISNULL(B.TaxNo    ,'')), 10, 1)   --05. 사업자등록번호_면세사업자
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(70), ISNULL(@Addr1     ,'')), 70, 1)   --06. 사업장소재지_면세사업자
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(14), ISNULL(B.TelNo    ,'')), 14, 1)   --07. 전화번호_면세사업자
             + SPACE(9)     --08. 공란
            , 150
          FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                    JOIN _TDATaxUnit AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.TaxUnit= B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'         --01. 자료구분
             + 'I102600'    --02. 서식코드
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY SMAsstKind)), 6)    --03. 일련번호
             + CASE WHEN B.SMAsstKind = 4572001 THEN '01' ELSE '02' END --04.  감가상각자산_구분 : 01 - 건축/구축물, 02 - 기타
             + dbo._FnVATIntChg( B.AsstQty            , 11, 0, 1)       --05. 수량
             + CONVERT(VARCHAR(8), B.GainDate)                          --06. 취득일
             + dbo._FnVATIntChg( B.NDVATAmt           , 13, 0, 1)       --07. 면세불공제세액
             + dbo._FnVATIntChg( B.DeducVATAmt        , 13, 0, 1)       --08. 과세공제매입세액
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(70), ISNULL(B.StoragePlace, '')), 70, 1)  --09. 보관장소
             + SPACE(18)                                                --10. 공란
             , 150
          FROM _TTAXBizChangeAssets AS A WITH (NOLOCK)
                JOIN _TTAXBizChangeAssetsDtl AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                              AND A.TaxTermSeq = B.TaxTermSeq
                                                              AND A.TaxUnit    = B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
    END
END
/***************************************************************************************************************************    
건물관리명세서  
01. 자료구분        (2)
02. 서식코드        (7)
03. 일련번호구분    (6)
04. 법정동코드      (10)  
05. 법정동명        (50)  
06. 산번지          (4)   
07. 번지            (4)   
08. 번지호          (4)   
09. 블록            (80)
10. 동              (12)
11. 동호            (6) 
12. 통              (4) 
13. 반              (4) 
14. 건물명          (60)
15. 건물동명        (40)
16. 관리비합계      (15)
17. 건물소재지      (200)
18. 관리건수        (6)
19. 도로명코드      (12) 
20. 도로명          (50) 
21. 지하만있는 건물구분 (1)  
22. 건물번호(본번)  (5)  
23. 건물번호(부번)  (5)
24. 공란            (13)
***************************************************************************************************************************/  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXBuildingManage WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        CREATE TABLE #Temp_Bld (  
            Cnt             INT IDENTITY,  
            BuildingSeq     INT,  
            CountNUM        VARCHAR(6))  
  
        INSERT INTO #Temp_Bld (BuildingSeq, CountNUM)  
            SELECT BuildingSeq, RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY BuildingSeq)), 6)
              FROM _TTAXBuildingManage WITH(NOLOCK)
             WHERE CompanySeq       = @CompanySeq  
               AND TaxTermSeq       = @TaxTermSeq  
               AND TaxUnit          = @TaxUnit  
  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '17'             --01. 자료구분
                    + 'I104300'     --02. 서식코드
                    + T.CountNUM    --03. 일련번호구분
                    + CONVERT(VARCHAR(10), A.CourtSecCode ) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), A.CourtSecCode ))) --04. 법정동코드
                    + CONVERT(VARCHAR(50), A.CourtSecName ) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), A.CourtSecName ))) --05. 법정동명
                    + CONVERT(VARCHAR(04), A.MountStreetNo) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.MountStreetNo))) --06. 산번지
      + CONVERT(VARCHAR(04), A.StreetNo     ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.StreetNo  )))    -- 07. 번지
                    + CONVERT(VARCHAR(04), A.StreetNoHo   ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.StreetNoHo)))    -- 08. 번지호
                    + CONVERT(VARCHAR(80), A.Block   ) + SPACE(80 - DATALENGTH(CONVERT(VARCHAR(80), A.Block   )))           -- 09. 블록
                    + CONVERT(VARCHAR(12), A.Sector  ) + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), A.Sector  )))           -- 10. 동
                    + CONVERT(VARCHAR(06), A.SectorNo) + SPACE(6  - DATALENGTH(CONVERT(VARCHAR(06), A.SectorNo)))           -- 11. 동호
                    + CONVERT(VARCHAR(04), A.Tong    ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.Tong    )))           -- 12. 통
                    + CONVERT(VARCHAR(04), A.Ban     ) + SPACE(4  - DATALENGTH(CONVERT(VARCHAR(04), A.Ban     )))           -- 13. 반
                    + CONVERT(VARCHAR(60), A.BuildingName   ) + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), A.BuildingName   ))) -- 14. 건물명
                    + CONVERT(VARCHAR(40), A.BuildingSecName) + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), A.BuildingSecName))) -- 15. 건물동명
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Sub.TotAmt)), 15)                                -- 16. 관리비합계
                    + CONVERT(VARCHAR(200), A.BuildingLoc) + SPACE(200 - DATALENGTH(CONVERT(VARCHAR(200), A.BuildingLoc)))  -- 17. 건물소재지
                    + RIGHT('000000' + CONVERT(VARCHAR(6), FLOOR(Sub.Cnt)), 6)                                              -- 18. 관리건수
                    + CONVERT(VARCHAR(12), A.RoadSecCode) + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), A.RoadSecCode)))     -- 19. 도로명코드
                    + CONVERT(VARCHAR(50), A.RoadSecName) + SPACE(50 - DATALENGTH(CONVERT(VARCHAR(50), A.RoadSecName)))     -- 20. 도로명
                    + CASE WHEN ISNULL(A.IsOnlyUnder, '') = '1' THEN '1'
                           ELSE SPACE(1) END                                                                        -- 21. 지하만있는건물구분
                    + CASE WHEN ISNULL(A.BuildingNo, 0) = 0 THEN SPACE(5)
                           ELSE RIGHT('000000000000000' + CONVERT(VARCHAR(5), CONVERT(INT,A.BuildingNo )), 5) END   -- 22. 건물번호(본번)
                    + CASE WHEN ISNULL(A.BuildingNo2, 0) = 0 THEN SPACE(5)
                           ELSE RIGHT('000000000000000' + CONVERT(VARCHAR(5), CONVERT(INT,A.BuildingNo2)), 5) END   -- 23. 건물번호(부번)
                    + SPACE(13)
                    , 600   
              FROM _TTAXBuildingManage AS A WITH(NOLOCK)
                                            JOIN (SELECT CompanySeq, TaxTermSeq, TaxUnit, BuildingSeq, SUM(ManageAmt) AS TotAmt, COUNT(*) AS Cnt  
                                                    FROM _TTaxBuildingManageDtl WITH(NOLOCK)
                                                   WHERE CompanySeq = @CompanySeq  
                                                     AND TaxTermSeq = @TaxTermSeq  
                                                     AND TaxUnit    = @TaxUnit  
                                                   GROUP BY CompanySeq, TaxTermSeq, TaxUnit, BuildingSeq) AS Sub  
                                              ON A.CompanySeq   = Sub.CompanySeq  
                                             AND A.TaxTermSeq   = Sub.TaxTermSeq  
                                             AND A.TaxUnit      = Sub.TaxUnit  
                                             AND A.BuildingSeq  = Sub.BuildingSeq  
                                            JOIN #Temp_Bld AS T  
                                              ON A.BuildingSeq  = T.BuildingSeq  
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TaxTermSeq     = @TaxTermSEq  
               AND A.TaxUnit        = @TaxUnit  

    /***************************************************************************************************************************    
    건물관리명세서 세부     
    01. 자료구분        (2)
    02. 서식코드        (7)
    03. 일련번호구분    (6)
    04. 일련번호        (6)
    05. 층구분          (2)
    06. 층              (4) 
    07. 호실명          (30)
    08. 호번호          (4) 
    09. 면적            (9,1)
    10. 사업자등록번호  (13)
    11. 상호(성명)       (30)
    12. 입주일          (8)
    13. 퇴거일          (8)
    14. 관리비          (13)
    15. 공란            (58)
    ***************************************************************************************************************************/  
        CREATE TABLE #Temp_Bld2 (  
            BuildingSeq     INT,  
            BuildingSerl    INT,  
            SubCountNUM     VARCHAR(6))  
  
        SELECT @Cnt = 1  
        SELECT @MaxCnt = COUNT(*) FROM #Temp_Bld  
        WHILE @Cnt <= @MaxCnt  
        BEGIN  
            SELECT @BuildingSeq = BuildingSeq FROM #Temp_Bld WHERE Cnt = @Cnt  
  
            INSERT INTO #Temp_Bld2 (BuildingSeq, BuildingSerl, SubCountNUM)  
                SELECT BuildingSeq, BuildingSerl, RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY BuildingSerl)), 6)  
                  FROM _TTaxBuildingManageDtl WITH(NOLOCK)
                 WHERE CompanySeq       = @CompanySeq  
                   AND TaxTermSeq       = @TaxTermSeq  
                   AND TaxUnit          = @TaxUnit  
                   AND BuildingSeq      = @BuildingSeq  
  
            SELECT @Cnt = @Cnt + 1  
        END  
  
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '18'  
                    + 'I104300'  
                    + T1.CountNUM                                       -- 03. 일련번호구분
                    + T2.SubCountNUM                                    -- 04. 일련번호
                    + '0' + CASE A.FloorKind WHEN ''  THEN SPACE(1)
                                             WHEN 'A' THEN '1'
                                             WHEN 'C' THEN '2'
                                             WHEN 'E' THEN '3'
                                             WHEN 'G' THEN '4'
                                             WHEN 'I' THEN '5'
                                             ELSE A.FLoorKind END       -- 05. 집단상가층
                    + RIGHT('0000' + CONVERT(VARCHAR(4), A.Floor), 4)   -- 06. 층
                    + CONVERT(VARCHAR(30), A.HoName) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), A.HoName)))   -- 07. 호실명
                    + RIGHT('0000' + CONVERT(VARCHAR(4), A.HoNo), 4)                                            -- 08. 호번호
                    + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DECIMAL(9, 1), ROUND(Area, 1))), '.', ''), 9)   -- 09. 면적
                    + CONVERT(VARCHAR(13), REPLACE(A.ManageTaxNo, '-', '')) + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(A.ManageTaxNo, '-', '')))) -- 10. 사업자등록번호
                    + CONVERT(VARCHAR(30), A.ManageTaxName) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), A.ManageTaxName)))    -- 11. 상호(성명)
                    + CONVERT(VARCHAR(08), A.MoveInDate   ) + SPACE(8  - DATALENGTH(CONVERT(VARCHAR(08), A.MoveInDate   )))    -- 12. 입주일
                    + CONVERT(VARCHAR(08), A.EvictionDate ) + SPACE(8  - DATALENGTH(CONVERT(VARCHAR(08), A.EvictionDate )))    -- 13. 퇴거일
                    + dbo._FnVATIntChg(A.ManageAmt    , 13, 0, 1)                                                              -- 14. 관리비
                    + SPACE(58)
                    , 200  
               FROM _TTaxBuildingManageDtl AS A WITH(NOLOCK)
                                                JOIN #Temp_Bld AS T1  
                                                  ON A.BuildingSeq  = T1.BuildingSeq  
                                                JOIN #Temp_Bld2 AS T2  
                                                  ON A.BuildingSeq  = T2.BuildingSeq  
                                                 AND A.BuildingSerl = T2.BuildingSerl  
              WHERE A.CompanySeq    = @CompanySeq  
                AND A.TaxTermSeq    = @TaxTermSeq  
                AND A.TaxUnit       = @TaxUnit  
                
    END  
END  

/***************************************************************************************************************************    
사업자단위과세의사업장별부가가치세과세표준및납부세액(환급세액)신고명세서    
***************************************************************************************************************************/
IF @WorkingTag IN ('', 'U')  
BEGIN  
    -- 사업자단위과세일 경우만 출력    
    IF @Env4016 = 4125002  --사업자단위과세  
        AND (@TaxFrDate + '01') >= @Env4017 -- 사업자단위과세제도적용일자  
    BEGIN  
    
        IF @WorkingTag = 'U' --- 디스켓파일  
        BEGIN  
            -- 제출자 인적사항(HEAD RECORD)  
            --번호  항목                          형태  길이  누적길이  비고  
            --1     레코드구분                    문자  2     2         UH  
            --2     귀속년도                      문자  4     6         YYYY　  
            --3     반기구분                      문자  1     7         1: 1기, 2: 2기  
            --4     반기내 월 순번                문자  1     8         1/2/3/4/5/6  
            --5     수취자(제출자)사업자등록번호  문자  10    18  　  
            --6     사업자단위과세승인번호        숫자  7     25  
            --7     상호(법인명)                  문자  60    85  　  
            --8     성명(대표자)                  문자  30    115 　  
            --9     주민(법인)등록번호            문자  13    128 　  
            --10    제출일자                      문자  8     136 　  
            --11    수취자(제출자)전화번호        문자  12    148  
            --12    공란                          문자  252   400       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UH'                         -- 레코드구분  
                    +  LEFT(@TaxFrDate,4)             -- 귀속년도  
                    +  @TermKind                   -- 반기구분  
                    +  @YearHalfMM                       -- 반기내 월 순번  
                    +  CONVERT(VARCHAR( 10), REPLACE(TaxNo, '-', '')   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), REPLACE(TaxNo, '-', '')  ))))  -- 수취자(제출자)사업자등록번호  
                    +  CONVERT(VARCHAR(  7), @V166Cfm  + SPACE(  7 - DATALENGTH(CONVERT(VARCHAR(  7), @V166Cfm ))))  -- 사업자단위과세승인번호  
                    +  CONVERT(VARCHAR( 60), TaxName   + SPACE( 60 - DATALENGTH(CONVERT(VARCHAR( 60), TaxName  ))))  -- 상호(법인명)  
                    +  CONVERT(VARCHAR( 30), Owner     + SPACE( 30 - DATALENGTH(CONVERT(VARCHAR( 30), Owner    ))))  -- 성명(대표자)  
                    +  CONVERT(VARCHAR( 13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','')   
                        + SPACE( 13 - DATALENGTH(CONVERT(VARCHAR( 13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','')  ))))  -- 주민(법인)등록번호  
                    +  CONVERT(VARCHAR(  8), @CurrDate + SPACE(  8 - DATALENGTH(CONVERT(VARCHAR(  8), @CurrDate))))  -- 제출일자  
                    +  CONVERT(VARCHAR( 12), TelNo     + SPACE( 12 - DATALENGTH(CONVERT(VARCHAR( 12), TelNo    ))))  -- 수취자(제출자)전화번호  
                    +  space(252)                   -- 공란  
                    ,  400                          -- 누적길이  
               FROM #TDATaxUnit WITH(NOLOCK)
              WHERE CompanySeq  = @CompanySeq  
                AND TaxUnit     = @TaxUnit  
  
            -- 사업자단위과세의 사업장별부가가치세과세표준및납부세액(환급세액)신고명세(DATA RECORD)  
            --번호  항목                          형태  길이  누적길이  비고  
            --1     레코드구분                    문자  2     2         UD  
            --2     귀속년도                      문자  4     6         YYYY　  
            --3     반기구분                      문자  1     7         1: 1기, 2: 2기  
            --4     반기내 월 순번                문자  1     8         1/2/3/4/5/6  
            --5     수취자(제출자)사업자등록번호  문자  10    18  　  
            --6     단위사업장적용번호            숫자  4     22  
            --7     상호(법인명)  문자  60    82  
            --8     사업장소재지                  문자  70    152 　  
            --9     매출과세세금계산서과표        숫자  15    167 　  
            --10    매출과세세금계산서세액        숫자  15    182 　  
            --11    매출과세기타과표              숫자  15    197  
            --12    매출과세기타세액              숫자  15    212 　  
            --13    매출영세세금계산서과표        숫자  15    227 　  
            --14    매출영세기타과표              숫자  15    242  
            --15    과세표준                      숫자  15    257  
            --16    매입과세표준                  숫자  15    272  
            --17    매입과세세액                  숫자  15    287  
            --18    매입의제표준                  숫자  15    302  
            --19    매입의제매입세액              숫자  15    317  
            --20    가산세                        숫자  15    332  
            --21    공제세액                      숫자  15    347  
            --22    차감납부할세액                숫자  15    362
            --23    사업장소재지_도로명주소       문자 200    562
            --23    공란                          문자  38    600  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UD'                         -- 레코드구분  
                    +  LEFT(@TaxFrDate,4)             -- 귀속년도  
                    +  @TermKind                   -- 반기구분  
                    +  @YearHalfMM                       -- 반기내 월 순번  
                    +  CONVERT(VARCHAR( 10), @TaxNo   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), @TaxNo  ))))  -- 수취자(제출자)사업자등록번호  
                    +  CASE WHEN A.TaxUnit = A.RptTaxUnit THEN  
                            '0000'  
                            ELSE CONVERT(VARCHAR(4), ISNULL(B.TaxNoSerl, LEFT(REPLACE(B.TaxNo, '-', ''), 4))   
                                + SPACE(4 - DATALENGTH(CONVERT(VARCHAR(4), ISNULL(B.TaxNoSerl, LEFT(REPLACE(B.TaxNo, '-', ''), 4))))) )  
                            END                                                                                          -- 단위사업장적용번호  
                    +  CONVERT(VARCHAR( 60), B.TaxName   + SPACE( 60 - DATALENGTH(CONVERT(VARCHAR( 60), B.TaxName  ))))  -- 상호(법인명)  
                    +  CONVERT(VARCHAR( 70), ( LTRIM(RTRIM(B.VATRptAddr)) ) + SPACE(70))        -- 사업장소재지
                    + dbo.fnVATIntChg(SUM(A.SaleSupplyAmt       ),15,0,1)  -- 매출과세 세금계산서과표  
                    + dbo.fnVATIntChg(SUM(A.SaleVATAmt          ),15,0,1)  -- 매출과세 세금계산서세액  
                    + dbo.fnVATIntChg(SUM(A.SaleEtcTaxAmt       ),15,0,1)  -- 매출과세 기타과표  
                    + dbo.fnVATIntChg(SUM(A.SaleEtcTaxVATAmt    ),15,0,1)  -- 매출기타 세액  
                    + dbo.fnVATIntChg(SUM(A.SaleZeroTaxAmt      ),15,0,1)  -- 매출영세 세금계산서과표  
                    + dbo.fnVATIntChg(SUM(A.SaleZeroTaxEtcAmt   ),15,0,1)  -- 매출영세 가타과표  
                    + dbo.fnVATIntChg(SUM(A.TaxationStd         ),15,0,1)  -- 과세표준  
                    + dbo.fnVATIntChg(SUM(A.BuySupplyAmt        ),15,0,1)  -- 매입과세 금액  
                    + dbo.fnVATIntChg(SUM(A.BuyVATAmt           ),15,0,1)  -- 매입과세 세액  
                    + dbo.fnVATIntChg(SUM(A.BuyEtcAmt           ),15,0,1)  -- 매입의제 금액  
                    + dbo.fnVATIntChg(SUM(A.BuyEtcVATAmt        ),15,0,1)  -- 매입의제 세액  
                    + dbo.fnVATIntChg(SUM(A.AddVATAmt           ),15,0,1)  -- 가산세  
                    + dbo.fnVATIntChg(SUM(A.DeducVATAmt         ),15,0,1)  -- 공제세액  
                    + dbo.fnVATIntChg(SUM(A.DeBusVATAmt         ),15,0,1)  -- 차감납부할 세액  
                    + space(200)                                      -- 사업장소재지_도로명주소 (우선 공백처리) : 사업장소재지와 도로명주소 둘 중 하나만 기재(둘 다 기재 시 오류)
                    + space(38)                                       -- 공란  
                    , 600                                             -- 누적길이  
                FROM _TTAXBizStdSumV166 AS A WITH(NOLOCK)
                                             JOIN #TDATaxUnit AS B WITH(NOLOCK)
                                               ON A.CompanySeq  = B.CompanySeq  
                                              AND A.TaxUnit     = B.TaxUnit  
               WHERE A.CompanySeq     = @CompanySeq  
                 AND A.TaxTermSeq     = @TaxTermSeq  
                 AND A.RptTaxUnit     = @TaxUnit  
               GROUP BY A.TaxUnit, A.RptTaxUnit, B.TaxNoSerl, B.TaxNo, B.TaxName, B.VATRptAddr
  
            ---- 사업자단위과세의 사업장별부가가치세과세표준및납부세액(환급세액)신고명세 합계(TAIL RECORD)  
            --번호 항목                         형태 길이 누적길이 비고  
            --1     레코드구분                     문자 2     2         UT  
            --2     귀속년도                     문자 4     6        YYYY　　  
            --3     반기구분                     문자 1     7         1: 1기, 2: 2기  
            --4     반기내 월 순번                 문자 1     8         1/2/3/4/5/6  
            --5     수취자(제출자)사업자등록번호 문자 10     18 　  
            --6     DATA 건수                     숫자 7     25    
            --7     매출과세세금계산서과표합계     숫자 15     40    
            --8     매출과세세금계산서세액합계     숫자 15     55    
            --9     매출과세기타과표합계         숫자 15     70    
            --10 매출기타세액합계             숫자 15     85    
            --11 매출영세세금계산서과표합계     숫자 15     100    
            --12 매출영세기타과표합계         숫자 15     115    
            --13 과세표준합계                 숫자 15     130    
            --14 매입과세금액합계             숫자 15     145    
            --15 매입과세세액합계             숫자 15     160    
            --16 매입의제금액합계             숫자 15     175    
            --17 매입의제세액합계             숫자 15     190    
            --18 가산세액계                     숫자 15     205    
            --19 공제세액합계                 숫자 15     220    
            --20 차감납부할세액합계             숫자 15     235    
            --21 공란                         문자 165     400    
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
                SELECT 'UT'                         -- 레코드구분  
                    +  LEFT(@TaxFrDate,4)           -- 귀속년도  
                    +  @TermKind                    -- 반기구분  
                    +  @YearHalfMM                  -- 반기내 월 순번  
                    +  CONVERT(VARCHAR( 10), @TaxNo   + SPACE( 10 - DATALENGTH(CONVERT(VARCHAR( 10), @TaxNo  ))))  -- 수취자(제출자)사업자등록번호  
                    + dbo.fnVATIntChg(COUNT(*)                           , 7,0,1)  -- DATA건수    
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleSupplyAmt     ,0))  ,15,0,1)  -- 매출과세 세금계산서과표합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleVATAmt        ,0))  ,15,0,1)  -- 매출과세 세금계산서세액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleEtcTaxAmt     ,0))  ,15,0,1)  -- 매출과세 기타과표합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleEtcTaxVATAmt  ,0))  ,15,0,1)  -- 매출기타 세액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleZeroTaxAmt    ,0))  ,15,0,1)  -- 매출영세 세금계산서과표합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(SaleZeroTaxEtcAmt ,0))  ,15,0,1)  -- 매출영세 가타과표합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(TaxationStd       ,0))  ,15,0,1)  -- 과세표준 합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuySupplyAmt      ,0))  ,15,0,1)  -- 매입과세 금액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyVATAmt         ,0))  ,15,0,1)  -- 매입과세 세액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyEtcAmt         ,0))  ,15,0,1)  -- 매입의제 금액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(BuyEtcVATAmt      ,0))  ,15,0,1)  -- 매입의제 세액합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(AddVATAmt         ,0))  ,15,0,1)  -- 내부거래(판매목적)반출액  
                    + dbo.fnVATIntChg(SUM(ISNULL(DeducVATAmt       ,0))  ,15,0,1)  -- 공제세액 합계  
                    + dbo.fnVATIntChg(SUM(ISNULL(DeBusVATAmt       ,0))  ,15,0,1)  -- 차감납부할 세액합계  
                    + SPACE(165)                            -- 공란  
                    , 400                                   -- 누적길이  
                FROM _TTAXBizStdSumV166 AS A WITH(NOLOCK)
               WHERE CompanySeq     = @CompanySeq  
       AND TaxTermSeq     = @TaxTermSeq  
                 AND A.RptTaxUnit        = @TaxUnit  
        END  
        ELSE    -- 전자신고파일   
        BEGIN  
            /***************************************************************************************************************************    
            사업자단위과세의사업장별부가가치세과세표준및납부세액(환급세액)신고명세서    
            01. 자료구분(2) : 17    
            02. 서식코드(7) : I103900 / V166
            03. 사업자단위과세승인번호(7)    
            04. 매출과세세금계산서과표합계(15)    
            05. 매출과세세금계산서세액합계(15)    
            06. 매출과세기타과표합계(15)    
            07. 매출과세기타세액합계(15)    
            08. 매출영세세금계산서과표합계(15)    
            09. 매출영세기타과표합계(15)    
            10. 과세표준합계(15)    
            11. 매입과세표준합계(15)    
            12. 매입과세세액합계(15)    
            13. 매입의제표준합계(15)    
            14. 매입의제매입세액합계(15)    
            15. 가산세합계(15)    
            16. 공제세액합계(15)    
            17. 차감납부할세액합계(15)    
            18. 공란(174)    
            ****************************************************************************************************************************/    
            IF EXISTS (SELECT * FROM _TTAXBizStdSumV166 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND RptTaxUnit = @TaxUnit)    
            BEGIN    
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '17'                  --01.자료구분    
                        + 'I103900'             --02.서식코드                        
                        + SPACE(7)              --03.사업자단위과세승인번호(사용안함)
                        + CASE WHEN Sum(Std.SaleSupplyAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleSupplyAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleSupplyAmt)))), 15), 1, 1, '-')    
                           END --04.매출과세세금계산서과표    
                        + CASE WHEN Sum(Std.SaleVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleVATAmt)))), 15), 1, 1, '-')    
                           END --05.매출과세세금계산서세액    
                        + CASE WHEN Sum(Std.SaleEtcTaxAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleEtcTaxAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleEtcTaxAmt)))), 15), 1, 1, '-')    
                           END --06.매출과세기타과표    
                        + CASE WHEN Sum(Std.SaleEtcTaxVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleEtcTaxVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleEtcTaxVATAmt)))), 15), 1, 1, '-')    
                           END --07.매출과세기타세액    
                        + CASE WHEN Sum(Std.SaleZeroTaxAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleZeroTaxAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleZeroTaxAmt)))), 15), 1, 1, '-')    
                           END --08.매출영세세금계산서과표    
                        + CASE WHEN Sum(Std.SaleZeroTaxEtcAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.SaleZeroTaxEtcAmt))), 15)    
                           ELSE    
          STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.SaleZeroTaxEtcAmt)))), 15), 1, 1, '-')    
                           END --09.매출영세기타과표    
                        + CASE WHEN Sum(Std.TaxationStd) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.TaxationStd))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.TaxationStd)))), 15), 1, 1, '-')    
                           END --10.과세표준    
                        + CASE WHEN Sum(Std.BuySupplyAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuySupplyAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuySupplyAmt)))), 15), 1, 1, '-')    
                           END --11.매입과세표준    
                        + CASE WHEN Sum(Std.BuyVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyVATAmt)))), 15), 1, 1, '-')    
                           END --12.매입과세세액    
                        + CASE WHEN Sum(Std.BuyEtcAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyEtcAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyEtcAmt)))), 15), 1, 1, '-')    
                           END --13.매입의제표준    
                        + CASE WHEN Sum(Std.BuyEtcVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.BuyEtcVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.BuyEtcVATAmt)))), 15), 1, 1, '-')    
                           END --14.매입의제매입세액    
                        + CASE WHEN Sum(Std.AddVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.AddVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.AddVATAmt)))), 15), 1, 1, '-')    
                           END --15.가산세    
                        + CASE WHEN Sum(Std.DeducVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.DeducVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.DeducVATAmt)))), 15), 1, 1, '-')    
                           END --16.공제세액    
                        + CASE WHEN Sum(Std.DeBusVATAmt) >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(Std.DeBusVATAmt))), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(SUM(Std.DeBusVATAmt)))), 15), 1, 1, '-')    
                           END --17.차감납부할세액    
                        + SPACE(174)    -- 18.공란    
                        , 400    
                    FROM _TTAXBizStdSumV166 AS Std  WITH(NOLOCK)
                   WHERE CompanySeq     = @CompanySeq  
                     AND TaxTermSeq     = @TaxTermSeq  
                     AND Std.RptTaxUnit = @TaxUnit  
            
                /***************************************************************************************************************************    
                사업자단위과세의사업장별부가가치세과세표준및납부세액(환급세액)신고명세서_명세(세부내용)    
                01. 자료구분(2) : 18    
                02. 서식코드(7) : I103900 / V166
                03. 단위사업장적용번호(4)    
                04. 상호(법인명)(60)    
                05. 사업장소재지(70)    
                06. 매출과세세금계산서과표(15)    
                07. 매출과세세금계산서세액(15)    
                08. 매출과세기타과표(15)    
                09. 매출과세기타세액(15)    
                10. 매출영세세금계산서과표(15)    
                11. 매출영세기타과표(15)    
                12. 과세표준(15)    
                13. 매입과세표준(15)    
                14. 매입과세세액(15)    
                15. 매입의제표준(15)    
                16. 매입의제매입세액(15)    
                17. 가산세(15)    
                18. 공제세액(15)    
                19. 차감납부할세액(15)
                20. 사업장소재지_도로명주소(200) 
                21. 공란(47)    
                ****************************************************************************************************************************/    
  
                INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                SELECT    '18'                --01.자료구분    
                        + 'I103900'          --02.서식코드    
                        + RIGHT('0000' + LTRIM(RTRIM(( CASE ISNULL(Tax.SMTaxationType, 0) WHEN 4128002 THEN '0000' ELSE Tax.TaxNoSerl END ))),4)        --03.단위사업장적용번호    
                        + CONVERT(VARCHAR(60),LTRIM(RTRIM(CASE WHEN ISNULL(Tax.BillTaxName,'') <> '' THEN Tax.BillTaxName ELSE Tax.TaxName END)))    
                                  + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(Tax.BillTaxName,'') <> '' THEN Tax.BillTaxName ELSE Tax.TaxName END))))) --04.상호(법인명)    
                        + CONVERT(VARCHAR(70), RTRIM(ISNULL(Tax.Addr1,''))+' '+RTRIM(ISNULL(Tax.Addr2,''))) +    
                                SPACE(70 - DATALENGTH(CONVERT(VARCHAR(70), RTRIM(ISNULL(Tax.Addr1,''))+' '+RTRIM(ISNULL(Tax.Addr2,''))))) --05.사업장소재지    
                        + CASE WHEN Std.SaleSupplyAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleSupplyAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleSupplyAmt))), 15), 1, 1, '-')    
                           END --06.매출과세세금계산서과표    
                        + CASE WHEN Std.SaleVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleVATAmt))), 15), 1, 1, '-')    
                           END --07.매출과세세금계산서세액    
                        + CASE WHEN Std.SaleEtcTaxAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleEtcTaxAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleEtcTaxAmt))), 15), 1, 1, '-')    
                           END --08.매출과세기타과표    
                        + CASE WHEN Std.SaleEtcTaxVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleEtcTaxVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleEtcTaxVATAmt))), 15), 1, 1, '-')    
                           END --09.매출과세기타세액    
                        + CASE WHEN Std.SaleZeroTaxAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleZeroTaxAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleZeroTaxAmt))), 15), 1, 1, '-')    
                           END --10.매출영세세금계산서과표    
                        + CASE WHEN Std.SaleZeroTaxEtcAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.SaleZeroTaxEtcAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.SaleZeroTaxEtcAmt))), 15), 1, 1, '-')    
                           END --11.매출영세기타과표    
                        + CASE WHEN Std.TaxationStd >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.TaxationStd)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.TaxationStd))), 15), 1, 1, '-')    
                           END --12.과세표준    
                        + CASE WHEN Std.BuySupplyAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuySupplyAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuySupplyAmt))), 15), 1, 1, '-')    
                           END --13.매입과세표준    
                        + CASE WHEN Std.BuyVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyVATAmt))), 15), 1, 1, '-')    
                           END --14.매입과세세액    
                        + CASE WHEN Std.BuyEtcAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyEtcAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyEtcAmt))), 15), 1, 1, '-')    
                           END --15.매입의제표준    
                        + CASE WHEN Std.BuyEtcVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.BuyEtcVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.BuyEtcVATAmt))), 15), 1, 1, '-')    
                           END --16.매입의제매입세액    
                        + CASE WHEN Std.AddVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.AddVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.AddVATAmt))), 15), 1, 1, '-')    
                           END --17.가산세    
                        + CASE WHEN Std.DeducVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.DeducVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.DeducVATAmt))), 15), 1, 1, '-')    
                           END --18.공제세액    
                        + CASE WHEN Std.DeBusVATAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(Std.DeBusVATAmt)), 15)    
                           ELSE    
                                STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(Std.DeBusVATAmt))), 15), 1, 1, '-')    
                           END --19.차감납부할세액    
                        + CONVERT(VARCHAR(200), ISNULL(Tax.RoadAddr,'')) + SPACE(200 - DATALENGTH(CONVERT(VARCHAR(200), ISNULL(Tax.RoadAddr,''))))                                   
                        + SPACE(47)    -- 20.공란    
                        , 600    
                     FROM _TTAXBizStdSumV166 AS Std WITH(NOLOCK)
              JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                      ON Std.CompanySeq = Tax.CompanySeq  
                                                     AND Std.TaxUnit = Tax.TaxUnit  
                    WHERE Std.CompanySeq    = @CompanySeq  
                      AND Std.TaxTermSeq    = @TaxTermSeq  
                      AND Std.RptTaxUnit    = @TaxUnit  
                   
                      
            END    
        END  
    END    
END  

/***************************************************************************************************************************    
현금매출명세서   
01. 자료구분            2
02. 서식코드            7
03. 현금매출명세구분    2
04. 합계건수            11
05. 합계금액            15
06. 건수_세금계산서     11
07. 금액_세금계산서     15
08. 건수_신용카드       11
09. 금액_신용카드       15
10. 건수_현금영수증     11
11. 금액_현금영수증     15
12. 건수_현금매출       11
13. 금액_현금매출       15
14. 공급대가합계금액    15
15. 부가세합계금액      15
16. 공란                79
***************************************************************************************************************************  
현금매출명세서_세부내용
01. 자료구분                        2  
02. 서식코드                        4  
03. 일련번호                        6  
04. 의뢰인주미번호 또는 사업자번호  13 
05. 의뢰인 상호 또는 성명           30 
06. 거래일자                        8  
07. 공급대가                        13 
08. 공급가액                        13 
09. 부가세                          13 
10. 공란                            145
***************************************************************************************************************************/  
IF @WorkingTag = ''  
BEGIN  
    IF EXISTS (SELECT 1 FROM _TTAXBizStdSumV167 WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
     OR EXISTS (SELECT 1 FROM _TTAXBizStdSumV167M WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN
        DECLARE @CashSumCnt         INT,    
                @CashSumAmt         DECIMAL(19,5),
                @SumDomSumAmt       DECIMAL(19,5),
                @SumDomVatAmt       DECIMAL(19,5)
        SELECT @CashSumCnt      = COUNT(*)          ,
               @CashSumAmt      = SUM(DomAmt)       ,
               @SumDomSumAmt    = SUM(DomSumAmt)    ,
               @SumDomVatAmt    = SUM(DomVatAmt)
          FROM _TTAXBizStdSumV167 AS A WITH(NOLOCK)
         WHERE A.CompanySeq     = @CompanySeq
           AND A.TaxTermSeq     = @TaxTermSeq
           AND A.TaxUnit        = @TaxUnit
        IF ISNULL(@CashSumCnt   , 0) = 0 SELECT @CashSumCnt     = 0
        IF ISNULL(@CashSumAmt   , 0) = 0 SELECT @CashSumAmt     = 0
        IF ISNULL(@SumDomSumAmt , 0) = 0 SELECT @SumDomSumAmt   = 0
        IF ISNULL(@SumDomVatAmt , 0) = 0 SELECT @SumDomVatAmt   = 0
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '17'                                                     -- 01. 자료구분
                    + 'I103700'                                             -- 02. 서식코드
                    + SPACE(2)  -- 2016.07 사용안함으로 변경 --dbo._FnVATCharChg(CONVERT(VARCHAR(2), ISNULL(@CashSaleKind, '')), 2, 1)   -- 03. 현금매출명세구분
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillCnt, 0) + ISNULL(B.CardCnt, 0) + ISNULL(B.CashBillCnt, 0) + ISNULL(@CashSumCnt, 0), 11, 0, 1)    -- 04. 합계건수
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillAmt, 0) + ISNULL(B.CardAmt, 0) + ISNULL(B.CashBillAmt, 0) + ISNULL(@CashSumAmt, 0), 15, 0, 1)    -- 05. 합계금액
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillCnt, 0), 11, 0, 1)   -- 06. 건수_세금계산서
                    + dbo._FnVATIntChg(ISNULL(B.TaxBillAmt, 0), 15, 0, 1)   -- 07. 금액_세금계산서
                    + dbo._FnVATIntChg(ISNULL(B.CardCnt   , 0), 11, 0, 1)   -- 08. 건수_신용카드
                    + dbo._FnVATIntChg(ISNULL(B.CardAmt   , 0), 15, 0, 1)   -- 09. 금액_신용카드
                    + dbo._FnVATIntChg(ISNULL(B.CashBillCnt,0), 11, 0, 1)   -- 10. 건수_현금영수증
                    + dbo._FnVATIntChg(ISNULL(B.CashBillAmt,0), 15, 0, 1)   -- 11. 금액_현금영수증
                    + dbo._FnVATIntChg(ISNULL(@CashSumCnt , 0), 11, 0, 1)   -- 12. 건수_현금매출
                    + dbo._FnVATIntChg(ISNULL(@CashSumAmt , 0), 15, 0, 1)   -- 13. 금액_현금매출
                    + dbo._FnVATIntChg(ISNULL(@SumDomSumAmt,0), 15, 0, 1)   -- 14. 공급대가합계금액
                    + dbo._FnVATIntChg(ISNULL(@SumDomVatAmt,0), 15, 0, 1)   -- 15. 부가세합계금액
                    + SPACE(79)                                             -- 16. 공란
                    , 250
               FROM _TTAXBizStdSumV167M AS B WITH(NOLOCK)
              WHERE B.CompanySeq = @CompanySeq
                AND B.TaxUnit    = @TaxUnit
                AND B.TaxTermSeq = @TaxTermSeq
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT '18'                                                     -- 01. 자료구분
                    + 'I103700'                                             -- 02. 서식코드
                    + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Serl)), 6)   -- 03. 일련번호
                    + dbo._FnVATCharChg(ISNULL(REPLACE(A.BizNo, '-', ''), ''), 13, 1)   -- 04. 의뢰인주민번호 또는 사업자번호
                    + dbo._FnVATCharChg(CONVERT(VARCHAR(30), A.CustName), 30, 1)        -- 05. 의뢰인 상호 또는 성명
                    + dbo._FnVATCharChg(CONVERT(VARCHAR(8) , A.VatDate) ,  8, 1)        -- 06. 거래일자             
                    + dbo._FnVATIntChg(ISNULL(A.DomSumAmt   , 0), 13, 0, 1)             -- 07. 공급대가             
                    + dbo._FnVATIntChg(ISNULL(A.DomAmt      , 0), 13, 0, 1)             -- 08. 공급가액             
                    + dbo._FnVATIntChg(ISNULL(A.DomVatAmt   , 0), 13, 0, 1)             -- 09. 부가세               
                    + SPACE(145)                                                        -- 10. 공란                 
                    , 250
               FROM _TTAXBizStdSumV167 AS A WITH(NOLOCK)
              WHERE A.CompanySeq    = @CompanySeq
                AND A.TaxTermSeq    = @TaxTermSeq
                AND A.TaxUnit       = @TaxUnit
    END  
END  
/***************************************************************************************************************************    
내국신용장 / 구매확인서 전자발급명세서(합계)
01. 자료구분                (02)
02. 서식코드                (07) I105600 / V174
03. 건수_합계               (07) 
04. 해당금액_합계           (15) 
05. 내국신용장_건수_합계    (07) 
06. 내국신용장_금액_합계    (15) 
07. 구매확인서_건수_합계    (07) 
08. 구매확인서_금액_합계    (15) 
09. 공란                    (25)
*************************************************************************************************************************** 
내국신용장 / 구매확인서 전자발급명세서(명세)
01. 자료구분                (02)
02. 서식코드                (07) I105600 / V174
03. 일련번호                (06) 
04. 서류구분                (01) 
05. 서류번호                (35) 
06. 발급일자                (08) 
07. 공급받는자 사업자번호   (10) 
08. 금액                    (15) 
09. 공란                    (16) 
***************************************************************************************************************************/  
DECLARE @T_Cnt      INT,            @A_Cnt      INT,            @B_Cnt      INT,
        @T_CurAmt   DECIMAL(19,5),  @A_CurAmt   DECIMAL(19,5),  @B_CurAmt   DECIMAL(19,5),  
        @T_DomAmt   DECIMAL(19,5),  @A_DomAmt   DECIMAL(19,5),  @B_DomAmt   DECIMAL(19,5)
IF @WorkingTag IN ('','L')
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXPurCfm WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
    BEGIN
        CREATE TABLE #PurCfm (
            Seq         INT IDENTITY,
            DocKind     NVARCHAR(1),
            DocNo       NVARCHAR(35),
            CfmDate     NVARCHAR(8),
            BizNo       NVARCHAR(10),
            Amt         DECIMAL(19,5))
        INSERT INTO #PurCfm (DocKind, DocNo, CfmDate, BizNo, Amt)
            SELECT CASE WHEN A.SMDocKind = 4534001 THEN 'L' 
                        WHEN A.SMDocKind = 4534002 THEN 'A' ELSE ' ' END    ,
                   A.DocNo                                                  ,
                   A.CfmDate                                                ,
                   REPLACE(B.BizNo, '-', '')                                , 
                   A.Amt                                                    
              FROM _TTAXPurCfm AS A WITH(NOLOCK)
                                    JOIN _TDACust AS B WITH(NOLOCK)
                                      ON A.CompanySeq   = B.CompanySeq
                                     AND A.CustSeq      = B.CustSeq
             WHERE A.CompanySeq     = @CompanySeq
               AND A.TaxTermSeq     = @TaxTermSeq
               AND A.TaxUnit        = @TaxUnit
               AND A.SMDocKind     <> 0
             ORDER BY A.SMDocKind, A.CfmDate, A.DocNo
        SELECT @T_Cnt           = COUNT(*),
               @T_CurAmt        = SUM(Amt)
          FROM #PurCfm
        SELECT @A_Cnt           = COUNT(*),
               @A_CurAmt        = SUM(Amt)
          FROM #PurCfm
         WHERE DocKind          = 'L'   -- 내국신용장(L)
        SELECT @B_Cnt           = COUNT(*),
               @B_CurAmt        = SUM(Amt)
          FROM #PurCfm
         WHERE DocKind          = 'A'   -- 구매확인서(A)
         
        IF @WorkingTag  = 'L'   --디스켓신고(내국신용장)
        BEGIN
            --=============================================================================    
            -- 제출자 인적사항(HEAD RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         LH    
            --2   귀속년도                      문자  4     6         YYYY　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   상호(법인명)                  문자  60    78    
            --7   성명(대표자)                  문자  30    108    
            --8   주민(법인)등록번호            문자  13    121    
            --9   제출일자                      문자  8     129    
            --10  수취자(제출자)전화번호        문자  12    141    
            --11  공란                          문자  59    200       SPACE  
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LH'                         -- 레코드구분      
                    +  LEFT(@TaxFrDate, 4)          -- 귀속년도      
                    +  @TermKind                    -- 반기구분      
                    +  @YearHalfMM                  -- 반기내 월 순번      
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '') )))) -- 수취자(제출자)사업자등록번호    
                    + CONVERT(VARCHAR(60), TaxName                 + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), TaxName                 )))) -- 상호(법인명)    
                    + CONVERT(VARCHAR(30), Owner                   + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), Owner                   )))) -- 성명(대표자)        
                    + CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') 
                        + SPACE(13 - DATALENGTH(CONVERT(VARCHAR(13), REPLACE(dbo._FCOMDecrypt(ResidID, '_TDATaxUnit', 'ResidID', @CompanySeq),'-','') )))) -- 주민(법인)등록번호    
                    + CONVERT(VARCHAR( 8), @CurrDate               + SPACE( 8 - DATALENGTH(CONVERT(VARCHAR( 8), @CurrDate               )))) -- 제출일자    
                    + CONVERT(VARCHAR(12), TelNo                   + SPACE(12 - DATALENGTH(CONVERT(VARCHAR(12), TelNo                   )))) -- 수취자(제출자)전화번호    
+ SPACE(59)    -- 공란    
                    , 200    
                FROM #TDATaxUnit WITH(NOLOCK)   
                WHERE CompanySeq  = @CompanySeq    
                  AND TaxUnit     = @TaxUnit  
            --=============================================================================    
            -- 내국신용장 / 구매확인서 전자발급명세서(DATA RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         LD    
            --2   귀속년도                      문자  4     6         YYYY　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   서류구분                      문자  1     19        SEQ    
            --7   일련번호                      문자  6     25        SEQ    
            --8   서류번호                      문자  35    60          
            --9   발급일자                      문자  8     68          
            --10  공급받는자사업자등록번호      문자  10    78
            --11  금액                          숫자  15    93                                
            --12  공란                          문자  107   200       SPACE 
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LD'                         -- 01.레코드구분      
                    +  LEFT(@TaxFrDate, 4)          -- 02.귀속년도      
                    +  @TermKind                    -- 03.반기구분      
                    +  @YearHalfMM                  -- 04.반기내 월 순번      
                    + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo),10,1)  -- 05.수취자(제출자)사업자등록번호          
                    + dbo._FnVATCharChg(ISNULL(A.DocKind, ''), 1, 1)        -- 06. 서류구분
                    + RIGHT('000000' + CONVERT(VARCHAR(6), A.Seq), 6)       -- 07. 일련번호
                    + dbo._FnVATCharChg(ISNULL(A.DocNo, ''), 35, 1)         -- 08. 서류번호
                    + dbo._FnVATCharChg(ISNULL(A.CfmDate, ''), 8, 1)        -- 09. 발급일자
                    + dbo._FnVATCharChg(ISNULL(A.BizNo, ''), 10, 1)         -- 10. 공급받는자 사업자번호
                    + dbo._FnVATIntChg(ISNULL(A.Amt, 0), 15, 0, 1)          -- 11. 금액
                    + SPACE(107)                                            -- 12. 공란
                    , 200
               FROM #PurCfm AS A
              ORDER BY A.Seq
            --=============================================================================    
            -- 내국신용장 / 구매확인서 전자발급명세서(TAIL RECORD)      
            --=============================================================================    
            --번호  항목                        형태  길이  누적길이  비고    
            --1   레코드구분                    문자  2     2         LT    
            --2   귀속년도                      문자  4     6         YYYY　　    
            --3   반기구분                      문자  1     7         1: 1기, 2: 2기    
            --4   반기내 월 순번                문자  1     8         1/2/3/4/5/6    
            --5   수취자(제출자)사업자등록번호  문자  10    18    
            --6   DATA 건수                     숫자  7     25  
            --7   건수_합계                     숫자  7     32  
            --8   해당금액_합계                 숫자  15    47
            --9   내국신용장_건수_합계          숫자  7     54
            --10  내국신용장_금액_합계          숫자  15    69
            --11  구매확인서_건수_합계          숫자  7     76
            --12  구매확인서_금액_합계          숫자  15    91 
            --13  공란                          문자  109   200   
            INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)      
                SELECT 'LT'                         -- 01.레코드구분      
                    + LEFT(@TaxFrDate, 4)          -- 02.귀속년도      
                    + @TermKind                    -- 03.반기구분      
                    + @YearHalfMM                  -- 04.반기내 월 순번      
                    + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNo) ,10,1)    -- 05.수취자(제출자)사업자등록번호   
                    + dbo._FnVATIntChg(COUNT(Seq) , 7,0,1)  -- 06.DATA건수  
                    + dbo._FnVATIntChg(ISNULL(@T_Cnt        , 0),  7, 0, 1) -- 07. 건수_합계
                    + dbo._FnVATIntChg(ISNULL(@T_CurAmt     , 0), 15, 0, 1) -- 08. 해당금액_합계
                    + dbo._FnVATIntChg(ISNULL(@A_Cnt        , 0),  7, 0, 1) -- 09. 내국신용장_건수_합계
                    + dbo._FnVATIntChg(ISNULL(@A_CurAmt     , 0), 15, 0, 1) -- 10. 내국신용장_금액_합계
                    + dbo._FnVATIntChg(ISNULL(@B_Cnt        , 0),  7, 0, 1) -- 11. 구매확인서_건수_합계
                    + dbo._FnVATIntChg(ISNULL(@B_CurAmt     , 0), 15, 0, 1) -- 12. 구매확인서_금액_합계
                    + SPACE(109)                                            -- 13. 공란
                    , 200
                FROM _TTAXPurCfm WITH(NOLOCK)
                WHERE CompanySeq = @CompanySeq 
                  AND TaxTermSeq = @TaxTermSeq
                  AND TaxUnit    = @TaxUnit  
           END
           ELSE     --전자신고(내국신용장)
           BEGIN
                INSERT INTO #CREATEFile_tmp (tmp_file, tmp_size)
                    SELECT  '17'                                                    -- 01. 자료구분
                            + 'I105600'                                             -- 02. 서식코드
                            + dbo._FnVATIntChg(ISNULL(@T_Cnt        , 0),  7, 0, 1) -- 03. 건수_합계
                            + dbo._FnVATIntChg(ISNULL(@T_CurAmt     , 0), 15, 0, 1) -- 04. 해당금액_합계
                            + dbo._FnVATIntChg(ISNULL(@A_Cnt        , 0),  7, 0, 1) -- 05. 내국신용장_건수_합계
                            + dbo._FnVATIntChg(ISNULL(@A_CurAmt     , 0), 15, 0, 1) -- 06. 내국신용장_금액_합계
                            + dbo._FnVATIntChg(ISNULL(@B_Cnt        , 0),  7, 0, 1) -- 07. 구매확인서_건수_합계
                            + dbo._FnVATIntChg(ISNULL(@B_CurAmt     , 0), 15, 0, 1) -- 08. 구매확인서_금액_합계
                            + SPACE(25)                                             -- 09. 공란
                            , 100
                INSERT INTO #CREATEFile_tmp (tmp_file, tmp_size)
                    SELECT  '18'                                                    -- 01. 자료구분
                            + 'I105600'                                             -- 02. 서식코드
                            + RIGHT('000000' + CONVERT(VARCHAR(6), A.Seq), 6)       -- 03. 일련번호
                            + dbo._FnVATCharChg(ISNULL(A.DocKind, ''),  1, 1)       -- 04. 서류구분
                            + dbo._FnVATCharChg(ISNULL(A.DocNo  , ''), 35, 1)       -- 05. 서류번호
                            + dbo._FnVATCharChg(ISNULL(A.CfmDate, ''),  8, 1)       -- 06. 발급일자
                            + dbo._FnVATCharChg(ISNULL(A.BizNo  , ''), 10, 1)       -- 07. 공급받는자 사업자번호
                            + dbo._FnVATIntChg(ISNULL(A.Amt, 0), 15, 0, 1)          -- 08. 금액
                            + SPACE(16)                                             -- 09. 공란
                            , 100
                       FROM #PurCfm AS A
                      ORDER BY A.Seq
        END
    END
END

/***************************************************************************************************************************        
첨부서류30. 영세율매출명세서
 01. 자료구분
 02. 서식코드
 03. 직접수출(대행수출 포함)  
 04. 중계무역·위탁판매·외국인도 또는 위탁가공무역 방식의 수출  
 05. 내국신용장·구매확인서에 의하여 공급하는 재화  
 06. 한국국제협력단 및 한국국제보건의료재단에 공급하는 해외반출용 재화  
 07. 수탁가공무역 수출용으로 공급하는 재화  
 08. 국외에서 제공하는 용역  
 09. 선박·항공기에 의한 외국항행용역  
 10. 국제복합운송계약에 의한 외국항행용역  
 11. 국내에서 비거주자·외국법인에게 공급되는 재화 또는 용역  
 12. 수출재화임가공용역  
 13. 외국항행 선박·항공기 등에 공급하는 재화 또는 용역  
 14. 국내 주재 외교공관, 영사기관, 국제연합과 이에 준하는 국제기구, 국제연합군 또는 미국군에게 공급하는 재화 또는 용역  
 15. 「관광진흥법」에 따른 일반여행업자 또는 외국인전용 관광기념품 판매업자가 외국인관광객에게 고급하는 관광알선용역 또는 관광기념품  
 16. 외국인전용판매장 또는 주한외국군인 등의 전용 유흥음식점에서 공급하는 재화 또는 용역  
 17. 외교관 등에게 공급하는 재화 또는 용역  
 18. 외국인환자 유치용역  
 19. 방위산업물자 및 군부대 등에 공급하는 석유류  
 20. 도시철도건설용역  
 21. 국가·지방자치단체에 공급하는 사회기반시설 등  
 22. 장애인용 보장구 및 장애인용 정보통신기기 등  
 23. 농·어민 등에게 공급하는 농업용·축산업용·임업용 또는 어업용기자재  
 24. 외국인관광객 등에게 공급하는 재화  
 25. 제주특별자치도 면세품판매장에서 판매하거나 제주특별자치도 면세품판매장에 공급하는 물품  
 26. 부가가치세법에 따른 영세율 적용 공급실적  
 27. 조세특례제한법 및 그 밖의 법률에 따른 영세율 적용 공급실적  
 28. 영세율 적용 공급실적 총 합계  
 29. 군부대공급석유류
 30. 어민에게공급하는어업용기자재
 31. 공란
***************************************************************************************************************************/    
IF @WorkingTag = ''      
BEGIN    
    IF EXISTS (SELECT 1 FROM _TTAXZeroSaleRpt WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN    
       INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
        SELECT '17'     
        + 'I104000'    
        + dbo._FnVATIntChg(ISNULL(ZeroSale03, 0), 15, 0, 1)  -- 03. 직접수출(대행수출 포함)   
        + dbo._FnVATIntChg(ISNULL(ZeroSale04, 0), 15, 0, 1)  -- 04. 중계무역·위탁판매·외국인도 또는 위탁가공무역 방식의 수출  
        + dbo._FnVATIntChg(ISNULL(ZeroSale05, 0), 15, 0, 1)  -- 05. 내국신용장·구매확인서에 의하여 공급하는  재화  
        + dbo._FnVATIntChg(ISNULL(ZeroSale06, 0), 15, 0, 1)  -- 06. 한국국제협력단 및 한국국제보건의료재단에 공급하는 해외반출용 재화  
        + dbo._FnVATIntChg(ISNULL(ZeroSale07, 0), 15, 0, 1)  -- 07. 수탁가공무역 수출용으로 공급하는 재화  
        + dbo._FnVATIntChg(ISNULL(ZeroSale08, 0), 15, 0, 1)  -- 08. 국외에서 제공하는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale09, 0), 15, 0, 1)  -- 09. 선박·항공기에 의한 외국항행용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale10, 0), 15, 0, 1)  -- 10. 국제복합운송계약에 의한 외국항행용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale11, 0), 15, 0, 1)  -- 11. 국내에서 비거주자·외국법인에게 공급되는 재화 또는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale12, 0), 15, 0, 1)  -- 12. 수출재화임가공용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale13, 0), 15, 0, 1)  -- 13. 외국항행 선박·항공기 등에 공급하는 재화 또는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale14, 0), 15, 0, 1)  -- 14. 국내 주재 외교공관, 영사기관, 국제연합과 이에 준하는 국제기구, 국제연합군 또는 미국군에게 공급하는 재화 또는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale15, 0), 15, 0, 1)  -- 15. 「관광진흥법」에 따른 일반여행업자 또는 외국인전용 관광기념품 판매업자가 외국인관광객에게 고급하는 관광알선용역 또는 관광기념품  
        + dbo._FnVATIntChg(ISNULL(ZeroSale16, 0), 15, 0, 1)  -- 16. 외국인전용판매장 또는 주한외국군인 등의 전용 유흥음식점에서 공급하는 재화 또는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale17, 0), 15, 0, 1)  -- 17. 외교관 등에게 공급하는 재화 또는 용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale18, 0), 15, 0, 1)  -- 18. 외국인환자 유치용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale19, 0), 15, 0, 1)  -- 19. 부가가치세법에 따른 영세율 적용 공급실적  
        + dbo._FnVATIntChg(ISNULL(ZeroSale20, 0), 15, 0, 1)  -- 20. 도시철도건설용역  
        + dbo._FnVATIntChg(ISNULL(ZeroSale21, 0), 15, 0, 1)  -- 21. 국가·지방자치단체에 공급하는 사회기반시설 등  
        + dbo._FnVATIntChg(ISNULL(ZeroSale22, 0), 15, 0, 1)  -- 22. 장애인용 보장구 및 장애인용 정보통신기기 등  
        + dbo._FnVATIntChg(ISNULL(ZeroSale23, 0), 15, 0, 1)  -- 23. 농·어민 등에게 공급하는 농업용·축산업용·임업용 또는 어업용기자재  
        + dbo._FnVATIntChg(ISNULL(ZeroSale24, 0), 15, 0, 1)  -- 24. 외국인관광객 등에게 공급하는 재화  
        + dbo._FnVATIntChg(ISNULL(ZeroSale25, 0), 15, 0, 1)  -- 25. 제주특별자치도 면세품판매장에서 판매하거나 제주특별자치도 면세품판매장에 공급하는 물품  
        + dbo._FnVATIntChg(ISNULL(ZeroSale26, 0), 15, 0, 1)  -- 26. 방위산업물자 및 군부대 등에 공급하는 석유류  
        + dbo._FnVATIntChg(ISNULL(ZeroSale27, 0), 15, 0, 1)  -- 27. 조세특례제한법 및 그 밖의 법률에 따른 영세율 적용 공급실적  
        + dbo._FnVATIntChg(ISNULL(ZeroSale28, 0), 15, 0, 1)  -- 28. 영세율 적용 공급실적 총 합계   
        + dbo._FnVATIntChg(ISNULL(ZeroSale29, 0), 15, 0, 1)  -- 29. 군부대공급석유류  
        + dbo._FnVATIntChg(ISNULL(ZeroSale30, 0), 15, 0, 1)  -- 30. 어민에게공급하는어업용기자재
        + SPACE(21)                                          -- 31. 공란    
        , 450    
        FROM _TTAXZeroSaleRpt WITH(NOLOCK)
       WHERE CompanySeq = @CompanySeq     
         AND TaxTermSeq = @TaxTermSeq     
         AND TaxUnit = @TaxUnit    
      
    END     
END    
    
/***************************************************************************************************************************        
   외국인관광객 면세물품 판매 및 환급실적명세서    
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
 
	DECLARE @SUMCnt INT,          
	        @SUMPurAmt INT,
	        @SUMVatAmt INT,
	        @SUMIndAmt INT,
	        @SUMEduAmt INT,
	        @SUMFarmAmt INT,
	        @PurPlaceNo NVARCHAR(100),
	        @TaxNoSerl  NVARCHAR(20)
	        
    CREATE TABLE #Temp_TourItem (  
        Cnt            INT IDENTITY,  
        PurPlaceNo     NVARCHAR(100))  
  
    INSERT INTO #Temp_TourItem (PurPlaceNo)  
        SELECT DISTINCT PurPlaceNo 
            FROM _TTAXTourItemReturn WITH(NOLOCK)  
            WHERE CompanySeq       = @CompanySeq  
            AND TaxTermSeq       = @TaxTermSeq  
            AND TaxUnit          = @TaxUnit 
	        
                    
	SELECT @Cnt = 1  
	SELECT @MaxCnt = COUNT(*) FROM #Temp_TourItem  
	WHILE  @Cnt <= @MaxCnt 			 
    BEGIN                
		SELECT @SUMCnt = COUNT(*), @SUMPurAmt = SUM(PurAmt), @SUMVatAmt = SUM(VatAmt), @SUMIndAmt =SUM(IndAmt), 
			   @SUMEduAmt = SUM(EduAmt), @SUMFarmAmt = SUM(FarmAmt), @PurPlaceNo = MAX(A.PurPlaceNo), @TaxNoSerl = MAX(TaxNoSerl)
		  FROM _TTAXTourItemReturn   AS A WITH(NOLOCK)
					           JOIN #Temp_TourItem AS B ON A.PurPlaceNo = B.PurPlaceNo AND Cnt = @Cnt
					LEFT OUTER JOIN #TDATaxUnit    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DTaxUnit = C.TaxUnit
		 WHERE A.CompanySeq = @CompanySeq
		   AND A.TaxTermSeq = @TaxTermSeq
		   AND A.TaxUnit = @TaxUnit
		   
	    IF ISNULL(@TaxNoSerl, '') = ''
	    BEGIN
			SELECT @TaxNoSerl = '0000'
	    END		   

		IF EXISTS (SELECT 1 FROM _TTAXTourItemReturn WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
		BEGIN    
			INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
			SELECT '17'     
			+ 'M202300'    
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNoSerl ), 4, 1) -- 03. 종사업자일련번호 
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @PurPlaceNo), 8, 1) -- 04. 면세판매장지정번호 
			+ dbo._FnVATIntChg(ISNULL(@SUMCnt    , 0), 11, 0, 1)  -- 05. 합계_건수
			+ dbo._FnVATIntChg(ISNULL(@SUMPurAmt , 0), 15, 0, 1)  -- 06. 합계_판매금액
			+ dbo._FnVATIntChg(ISNULL(@SUMVatAmt , 0), 15, 0, 1)  -- 07. 합계_부가가치세 
			+ dbo._FnVATIntChg(ISNULL(@SUMIndAmt , 0), 15, 0, 1)  -- 08. 합계_개별소비세
			+ dbo._FnVATIntChg(ISNULL(@SUMEduAmt , 0), 15, 0, 1)  -- 09. 합계_교육세
			+ dbo._FnVATIntChg(ISNULL(@SUMFarmAmt, 0), 15, 0, 1)  -- 10. 합계_농어촌특별세
			+ SPACE(43)  -- 11. 공란    
			, 150    
		 
			INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
			SELECT '18'     
			+ 'M202300'    
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @TaxNoSerl), 4, 1)                                   -- 03. 종사업자일련번호
			+ RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.PurPlaceNo, A.Serl)), 4) -- 04. 일련번호 
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), PurSerl    ), 20, 1)   -- 05. 구매일련번호
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), PurDate    ),  8, 1)   -- 06. 판매일자
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), ReturnDate ),  8, 1)   -- 07. 반출일자
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), CASE WHEN ReturnNo = '0' THEN '00000000000000000000' ELSE ReturnNo END   ), 20, 1)   -- 08. 반출승인번호
			+ dbo._FnVATCHARChg(CONVERT(VARCHAR(10), GetAmtDate ),  8, 1)   -- 09. 환급(송금)일자
			+ dbo._FnVATIntChg(ISNULL(GetAmt , 0), 15, 0, 1)  -- 10. 환급액
			+ dbo._FnVATIntChg(ISNULL(PurAmt , 0), 15, 0, 1)  -- 11. 합계_판매금액
			+ dbo._FnVATIntChg(ISNULL(VatAmt , 0), 15, 0, 1)  -- 12. 합계_부가가치세
			+ dbo._FnVATIntChg(ISNULL(IndAmt , 0), 15, 0, 1)  -- 13. 합계_개별소비세
			+ dbo._FnVATIntChg(ISNULL(EduAmt , 0), 15, 0, 1)  -- 14. 합계_교육세
			+ dbo._FnVATIntChg(ISNULL(FarmAmt, 0), 15, 0, 1)  -- 15. 합계_농어촌특별세
			+ SPACE(29)  -- 16. 공란    
			, 200    
			FROM  _TTAXTourItemReturn AS A WITH(NOLOCK)
					JOIN #Temp_TourItem AS B ON A.PurPlaceNo = B.PurPlaceNo AND B.Cnt = @Cnt      
           WHERE CompanySeq = @CompanySeq     
			 AND TaxTermSeq = @TaxTermSeq     
			 AND TaxUnit = @TaxUnit		    
	      
		END
		SELECT @Cnt = @Cnt + 1
	END     
END      
  
/***************************************************************************************************************************    
구리스크랩등 매입세액공제신고서_합계 (2014년1기예정)    
(01) 자료구분             CHAR    2
(02) 서식코드             CHAR    7  M125200 / V179
(03) 매입처수_합계        NUMBER  7
(04) 건수_합계            NUMBER 11
(05) 수량_합계            NUMBER 11
(06) 취득금액_합계        NUMBER 15
(07) 의제매입세액_합계    NUMBER 15
(08) 매입처수_영수증      NUMBER  6
(09) 건수_영수증          NUMBER 11
(10) 수량_영수증          NUMBER 11
(11) 취득금액_영수증      NUMBER 15
(12) 의제매입세액_영수증  NUMBER 15
(13) 매입처수_계산서      NUMBER  6
(14) 건수_계산서          NUMBER 11
(15) 수량_계산서          NUMBER 11
(16) 취득금액_계산서      NUMBER 15
(17) 의제매입세액_계산서  NUMBER 15
(18) 공란                 NUMBER 1
****************************************************************************************************************************/    
IF @WorkingTag = ''      
BEGIN
    IF EXISTS (SELECT 1 FROM _TTAXCuDeductScrap WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
        -- 구리 스크랩 등 매입 합계  
        DECLARE @TotalCustCnt        INT,               @TotalCnt            INT,  
                @TotalQty            NUMERIC(19,5),     @TotalAmt            NUMERIC(19,5),     @TotalDeductAmt      NUMERIC(19,5),  
                @CustCnt1            INT,               @SumCnt1             INT,  
                @SumQty1             NUMERIC(19,5),     @SumAmt1             NUMERIC(19,5),     @SumDeductAmt1       NUMERIC(19,5),  
                @CustCnt2            INT,               @SumCnt2             INT,
                @SumQty2             NUMERIC(19,5),     @SumAmt2             NUMERIC(19,5),     @SumDeductAmt2       NUMERIC(19,5)  
                
        CREATE TABLE #tmp17V179(
            CustSeq             INT,
            SMCuDeductScrap     INT,
            SumCnt              INT,
            SumQty              INT,
            SUmAmt              DECIMAL(19,5),
            SumDeductAmt        DECIMAL(19,5)   )
            
            INSERT INTO #tmp17V179(CustSeq, SMCuDeductScrap, SumCnt, SumQty, SumAmt, SumDeductAmt)
            SELECT A.CustSeq, B.SMCuDeductScrap, SUM(Cnt) AS SumCnt, SUM(Qty) AS SumQty, SUM(Amt) AS SumAmt, SUM(DeductAmt) AS SumDeductAmt  
              FROM _TTAXCuDeductScrap AS A WITH(NOLOCK)
                        JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                       AND A.EvidSeq    = B.EvidSeq  
                                                       AND ISNULL(B.SMCuDeductScrap,0) IN (4561001, 4561002)
             WHERE A.CompanySeq = @CompanySeq
               AND A.TaxTermSeq = @TaxTermSeq
               AND A.TaxUnit    = @TaxUnit
             GROUP BY A.TaxUnit, A.TaxTermSeq , A.CustSeq, B.SMCuDeductScrap  
      
            SELECT @TotalCustCnt   = ISNULL(COUNT( DISTINCT CustSeq ),0),  
                   @TotalCnt       = ISNULL(SUM(SumCnt),0),  
                   @TotalQty       = ISNULL(SUM(SumQty),0),  
                   @TotalAmt       = ISNULL(SUM(SumAmt),0),   
                   @TotalDeductAmt = ISNULL(SUM(SumDeductAmt),0)  
              FROM #tmp17V179  
                
            SELECT @CustCnt1      = ISNULL(COUNT( DISTINCT CustSeq ),0),  
                   @SumCnt1       = ISNULL(SUM(SumCnt),0),  
                   @SumQty1       = ISNULL(SUM(SumQty),0),  
                   @SumAmt1       = ISNULL(SUM(SumAmt),0),   
                   @SumDeductAmt1 = ISNULL(SUM(SumDeductAmt),0)  
              FROM #tmp17V179
             WHERE SMCuDeductScrap = 4561001    -- 영수증수취분
                
            SELECT @CustCnt2      = ISNULL(COUNT( DISTINCT CustSeq ),0),
                   @SumCnt2       = ISNULL(SUM(SumCnt),0),
                   @SumQty2       = ISNULL(SUM(SumQty),0),
                   @SumAmt2       = ISNULL(SUM(SumAmt),0),
                   @SumDeductAmt2 = ISNULL(SUM(SumDeductAmt),0)
              FROM #tmp17V179  
             WHERE SMCuDeductScrap = 4561002    -- 계산서수취분
               
               
          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '17'            
                    +  'M125200'  
                    + dbo.FnVATIntChg(ISNULL(@TotalCustCnt,     0), 7, 0, 1) --(03) 매입처수_합계  
                    + dbo.FnVATIntChg(ISNULL(@TotalCnt,         0),11, 0, 1) --(04) 건수_합계             
                    + dbo.FnVATIntChg(ISNULL(@TotalQty,         0),11, 0, 1) --(05) 수량_합계            
                    + dbo.FnVATIntChg(ISNULL(@TotalAmt,         0),15, 0, 1) --(06) 취득금액_합계         
                    + dbo.FnVATIntChg(ISNULL(@TotalDeductAmt,   0),15, 0, 1) --(07) 의제매입세액_합계    
                    + dbo.FnVATIntChg(ISNULL(@CustCnt1,         0), 6, 0, 1) --(08) 매입처수_영수증      
                    + dbo.FnVATIntChg(ISNULL(@SumCnt1,          0),11, 0, 1) --(09) 건수_영수증          
                    + dbo.FnVATIntChg(ISNULL(@SumQty1,          0),11, 0, 1) --(10) 수량_영수증           
                    + dbo.FnVATIntChg(ISNULL(@SumAmt1,          0),15, 0, 1) --(11) 취득금액_영수증       
                    + dbo.FnVATIntChg(ISNULL(@SumDeductAmt1,    0),15, 0, 1) --(12) 의제매입세액_영수증  
                    + dbo.FnVATIntChg(ISNULL(@CustCnt2,         0), 6, 0, 1) --(13) 매입처수_계산서       
                    + dbo.FnVATIntChg(ISNULL(@SumCnt2,          0),11, 0, 1) --(14) 건수_계산서          
                    + dbo.FnVATIntChg(ISNULL(@SumQty2,          0),11, 0, 1) --(15) 수량_계산서           
                    + dbo.FnVATIntChg(ISNULL(@SumAmt2,          0),15, 0, 1) --(16) 취득금액_계산서      
                    + dbo.FnVATIntChg(ISNULL(@SumDeductAmt2,    0),15, 0, 1) --(17) 의제매입세액_계산서   
                    + SPACE(16)                                              --(18) 공란                  
                   , 200  

  
/***************************************************************************************************************************    
구리스크랩등 매입세액공제신고서_명세 (2014년1기예정)    
(01) 자료구분                CHAR    2
(02) 서식코드                CHAR    7
(03) 일련번호                CHAR    6
(04) 공급자성명_상호         CHAR   60
(05) 공급자주민(사업자)번호  CHAR   13
(06) 건수                    NUMBER 11
(07) 품명                    CHAR   30
(08) 수량                    NUMBER 11
(09) 취득금액                NUMBER 13
(10) 의제매입세액            NUMBER 13
(11) 공란                    NUMBER 34
****************************************************************************************************************************/    
        CREATE TABLE #Tmp_TTAXCuDeductScrap  
        (  
            Serl        INT IDENTITY(1,1),  
            CustSeq     INT,
            Cnt         INT,   
            ItemSeq     INT,
            Qty         NUMERIC(19,5),  
            Amt         NUMERIC(19,5),  
            DeductAmt   NUMERIC(19,5)
        )  
          
        INSERT INTO #Tmp_TTAXCuDeductScrap (CustSeq, Cnt, ItemSeq, Qty, Amt, DeductAmt)  
        SELECT A.CustSeq, SUM(Cnt) AS Cnt, A.ItemSeq, SUM(Qty) AS Qty, SUM(Amt) AS Amt, SUM(DeductAmt) AS DeductAmt  
          FROM _TTAXCuDeductScrap AS A WITH(NOLOCK)
                        JOIN _TDAEvid AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                       AND A.EvidSeq    = B.EvidSeq  
                                                       AND ISNULL(B.SMCuDeductScrap,0) = 4561001 --  영수증 
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
         GROUP BY A.CustSeq, A.ItemSeq  
         ORDER BY CustSeq, ItemSeq  
      
      
   
          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '18'            
                    +  'M125200'  
                    + dbo.FnVATIntChg(ISNULL(Serl,       0), 6, 0, 1)           -- (03) 일련번호   
                    + dbo.FnVATCHARChg(CONVERT(VARCHAR(60), C.CustName), 60, 1) -- (04) 공급자성명_상호  
                    + CASE WHEN ISNULL(C.BizNo, '') = '' 
                           THEN LTRIM(RTRIM(dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq)))   
                                + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),dbo._FCOMDecrypt(C.PersonId, '_TDACust', 'PersonId', @CompanySeq))))))  
                           ELSE LTRIM(RTRIM(C.BizNo)) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(13),C.BizNo)))))  
                      END                                                       -- (05) 공급자주민(사업자)번호  
                    + dbo.FnVATIntChg(ISNULL(Cnt,       0), 11, 0, 1)           -- (06) 건수  
                    + dbo.FnVATCHARChg(CONVERT(VARCHAR(30), I.ItemName), 30, 1) -- (07) 품명       
                    + dbo.FnVATIntChg(ISNULL(Qty,       0), 11, 0, 1)           -- (08) 수량   
                    + dbo.FnVATIntChg(ISNULL(Amt,       0), 13, 0, 1)           -- (09) 취득금액  
                    + dbo.FnVATIntChg(ISNULL(DeductAmt, 0), 13, 0, 1)           -- (10) 의제매입세액  
                    + SPACE(34)  
                    , 200  
              FROM #Tmp_TTAXCuDeductScrap AS A WITH (NOLOCK)  
                        JOIN _TDACust AS C WITH (NOLOCK) ON A.CustSeq = C.CustSeq AND C.CompanySeq = @CompanySeq
                        JOIN _TDAItem AS I WITH (NOLOCK) ON A.ItemSeq = I.ItemSeq AND I.CompanySeq = @CompanySeq
             ORDER BY Serl  
      
    END
END

/***************************************************************************************************************************    
첨부서류38. 외화획득명세서
-- 외화획득명세서 합계
01. 자료구분                (2)  : 17
02. 서식코드                (7)  : I402100
03. 영세율적용근거          (30)
04. 법정제출서류명          (50)
05. 법정서식제출불능사유    (50)
06. 법정서식제출가능일자    (8)
07. 공란                    (53)
-- 외화획득명세서 명세
01. 자료구분                (2)  : 18
02. 서식코드                (7)  : I402100
03. 일련번호                (6)
04. 공급일자                (8)
05. 공급받는자_상호(성명)   (30)
06. 공급받는자_국가코드     (2)
07. 공급내용_구분           (2)
08. 공급내용_명칭           (30)
09. 공급내용_금액(원화)     (13)
10. 금액(외화)              (15,2)
11. 공란                    (35)
***************************************************************************************************************************/
IF @WorkingTag = ''      
BEGIN
    IF EXISTS(SELECT 1 FROM _TTaxForAmtReceiptList WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMComboKind <> 4116003)
    BEGIN
        
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT TOP 1 '17'                                 -- 01. 자료구분
             + 'I402100'                            -- 02. 서식코드
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(Basis  ,''))   , 30, 1)   -- 03. 영세율적용근거
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(50), ISNULL(Doc    ,''))   , 50, 1)   -- 04. 제출서류명
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(50), ISNULL(Reason ,''))   , 50, 1)   -- 05. 법정서식제출불능사유
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(8) , ISNULL(IsAble ,''))   ,  8, 1)   -- 06. 법정서식제출가능일자
             + SPACE(53)
             , 200
          FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
        SELECT '18'                                                                             -- 01. 자료구분
             + 'I402100'                                                                        -- 02. 서식코드
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY VATDate)) , 6)  -- 03. 일련번호
             + CONVERT(VARCHAR(8), VATDate)                                                     -- 04. 공급일자
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(A.CustName     ,'')), 30, 1)       -- 05. 공급받는자_상호(성명)
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(02), ISNULL(C.ValueText    ,'')),  2, 1)       -- 06. 공급받는자_국가코드
             + CASE SMComboKind WHEN 4116001 THEN '01'  -- 재화
                                WHEN 4116002 THEN '02'  -- 용역
                                ELSE SPACE(2) END                                               -- 07. 공급내용_구분
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(ItemName       ,'')), 30, 1)       -- 08. 공급내용_명칭
             + dbo._FnVATIntChg(SupplyAmt    , 13, 0, 1)                                        -- 09. 공급내용_금액(원화)
             + dbo._FnVATIntChg(ForSupplyAmt , 15, 2, 1)                                        -- 10. 공급내용_금액(외화)
             + SPACE(35)
             , 150
        FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
                LEFT OUTER JOIN _TDAUMinor      AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                                 AND A.UMNationSeq = B.MinorSeq
                                                                 AND B.MajorSeq    = 1002       -- 국가
                LEFT OUTER JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                                 AND B.MinorSeq   = C.MinorSeq
                                                                 AND C.MajorSeq   = 1002
                                                                 AND C.Serl       = 2011        -- ISO국가코드-2
        WHERE A.CompanySeq = @CompanySeq
          AND A.TaxTermSeq = @TaxTermSeq
          AND A.TaxUnit    = @TaxUnit
          AND A.SMComboKind <> 4116003
    END
END
/***************************************************************************************************************************        
첨부서류 41. 외국인관광객즉시환급물품판매실적명세서
-- 외국인관광객즉시환급물품판매실적명세서 합계
01. 자료구분                (2)  : 17
02. 서식코드                (7)  : I106900
03. 종사업자일련번호          (4)
04. 면세판매장지정번호        (8)
05. 합계_건수               (11)
06. 합계_세금포함판매가격      (15)
07. 합계_부가가치세           (15)
08. 합계_즉시환급상당액        (15)
09. 환급창구운영사업자등록번호  (10)
10. 공란                    (63)

-- 외국인관광객즉시환급물품판매실적명세서 명세
01. 자료구분                (2)  : 18
02. 서식코드                (7)  : I106900
03. 종사업자일련번호          (4)
04. 일련번호                (4)
05. 구매일련번호             (20)
06. 판매일자                (8)
07. 반출승인번호             (20)
08. 세금포함판매가격          (15)
09. 부가가치세               (15)
10. 즉시환급상당액            (15)
11. 구입자성명               (30)
12. 구입자국적               (50)
13. 공란                    (10)
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
    IF EXISTS (SELECT 1 FROM _TTAXTourItemReturnImme WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)      
    BEGIN
	    DECLARE @SUMImmeCnt     INT,          
	            @SUMSalesAmt    INT,
	            @SUMImmeVatAmt  INT,
	            @SUMImmeAmt     INT,
	            @ImmePurPlaceNo NVARCHAR(100),
                @ImmeTaxUnitNo  NVARCHAR(100),
	            @ImmeTaxNoSerl  NVARCHAR(20)
	            
        CREATE TABLE #Temp_ReturnImme (  
            Cnt            INT IDENTITY,  
            PurPlaceNo     NVARCHAR(100))  
  
        INSERT INTO #Temp_ReturnImme (PurPlaceNo)  
        SELECT DISTINCT PurPlaceNo 
          FROM _TTAXTourItemReturnImme WITH(NOLOCK)  
         WHERE CompanySeq       = @CompanySeq  
           AND TaxTermSeq       = @TaxTermSeq  
           AND TaxUnit          = @TaxUnit 
	            
              
	    SELECT @Cnt = 1  
	    SELECT @MaxCnt = COUNT(*) FROM #Temp_ReturnImme  
	    WHILE  @Cnt <= @MaxCnt 			 
        BEGIN                
	    	SELECT @SUMImmeCnt = COUNT(*), @SUMSalesAmt = SUM(SalesAmt), @SUMImmeVatAmt = SUM(VatAmt), @SUMImmeAmt =SUM(ImmeAmt), 
	    		   @ImmePurPlaceNo = MAX(A.PurPlaceNo), @ImmeTaxUnitNo = MAX(A.ImmeTaxUnitNo), @ImmeTaxNoSerl = MAX(TaxNoSerl)
	    	  FROM _TTAXTourItemReturnImme   AS A WITH(NOLOCK)
	    				           JOIN #Temp_ReturnImme    AS B ON A.PurPlaceNo = B.PurPlaceNo AND Cnt = @Cnt
	    				LEFT OUTER JOIN #TDATaxUnit         AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.DTaxUnit = C.TaxUnit
	    	 WHERE A.CompanySeq = @CompanySeq
	    	   AND A.TaxTermSeq = @TaxTermSeq
	    	   AND A.TaxUnit = @TaxUnit
	    	   
	        IF ISNULL(@TaxNoSerl, '') = ''
	        BEGIN
	    		SELECT @TaxNoSerl = '0000'
	        END		   
	    	 
	    		INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
	    		SELECT '17'     
	    		+ 'I106900'    
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(4), @ImmeTaxNoSerl ), 4, 1) -- 03. 종사업자일련번호 
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(8), @ImmePurPlaceNo), 8, 1) -- 04. 면세판매장지정번호 
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeCnt   , 0), 11, 0, 1)  -- 05. 합계_건수
	    		+ dbo._FnVATIntChg(ISNULL(@SUMSalesAmt  , 0), 15, 0, 1)  -- 06. 합계_세금포함판매가격
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeVatAmt, 0), 15, 0, 1)  -- 07. 합계_부가가치세
	    		+ dbo._FnVATIntChg(ISNULL(@SUMImmeAmt   , 0), 15, 0, 1)  -- 08. 합계_즉시환급상당액
                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), @ImmeTaxUnitNo), 10, 1) -- 09. 환급창구운영사업자등록번호
	    		+ SPACE(63)  -- 11. 공란    
	    		, 150    

	    		INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)      
	    		SELECT '18'     
	    		+ 'I106900'    
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(4), @ImmeTaxNoSerl), 4, 1)                                   -- 03. 종사업자일련번호
	    		+ RIGHT('000000' + CONVERT(VARCHAR(4), ROW_NUMBER() OVER (ORDER BY A.PurPlaceNo, A.Serl)), 4) -- 04. 일련번호 
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), PurSerl    ), 20, 1)   -- 05. 구매일련번호
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(8), SalesDate  ),  8, 1)   -- 06. 판매일자
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(20), CASE WHEN ReturnNo = '0' THEN '00000000000000000000' ELSE ReturnNo END   ), 20, 1)   -- 07. 반출승인번호
	    		+ dbo._FnVATIntChg(ISNULL(SalesAMt, 0), 15, 0, 1)  -- 08. 세금포함판매가격
	    		+ dbo._FnVATIntChg(ISNULL(VatAmt  , 0), 15, 0, 1)  -- 09. 부가가치세
	    		+ dbo._FnVATIntChg(ISNULL(ImmeAmt , 0), 15, 0, 1)  -- 10. 즉시환급상당액
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(30), BuyName    ), 30, 1)   -- 11. 구입자성명
	    		+ dbo._FnVATCHARChg(CONVERT(VARCHAR(50), BuyNation  ), 50, 1)   -- 12. 구입자국적
                + SPACE(10)  -- 13. 공란    
	    		, 200    
	    		FROM  _TTAXTourItemReturnImme AS A WITH(NOLOCK)
	    				JOIN #Temp_ReturnImme AS B ON A.PurPlaceNo = B.PurPlaceNo AND B.Cnt = @Cnt      
               WHERE CompanySeq = @CompanySeq     
	    		 AND TaxTermSeq = @TaxTermSeq     
	    		 AND TaxUnit = @TaxUnit		    
	          
	    	
	    	  SELECT @Cnt = @Cnt + 1
        END
	END     
END  
/***************************************************************************************************************************        
첨부서류 33. 관세환급금등 명세서
01. 자료구분                (2)  : 17
02. 서식코드                (7)  : I401500
03. 일련번호                (6)  : 순차적으로 부여
04. 공급일자                (8)
05. 관세환급금액            (13)
06. 상호(법인명)            (30)
07. 사업자등록번호          (10)
08. 내국신용장번호          (30)
09. 공란                    (44)
***************************************************************************************************************************/    
 IF @WorkingTag = ''      
 BEGIN 
    IF EXISTS(SELECT * FROM _TTAXCustomsRefund WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
    BEGIN
        INSERT INTO #CREATEFile_tmp(tmp_file,tmp_size)  
        SELECT '17'                 -- 01. 자료구분     
             + 'I401500'            -- 02. 서식코드  
             + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY A.Serl)), 6)    -- 03. 일련번호
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(8),  ISNULL(A.SupplyDate   , '')),  8, 1)      -- 04. 공급일자
             + dbo._FnVATIntChg(ISNULL(A.RefundAmt, 0), 13, 0, 1)                               -- 05. 관세환급금액
             + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), ISNULL(C.CustName     , '')), 30, 1)      -- 06. 상호(법인명)
             + dbo._FnVATCharChg(CONVERT(VARCHAR(10), ISNULL(C.BizNo        , '')), 10, 1)      -- 07. 사업자등록번호
             + dbo._FnVATCharChg(CONVERT(VARCHAR(30), ISNULL(A.DomesticLCNo , '')), 30, 1)      -- 08. 내국신용장번호
             + SPACE(44)            -- 07. 공란
             , 150 
        FROM _TTAXCustomsRefund     AS A WITH(NOLOCK)
                    JOIN _TDACust   AS C WITH (NOLOCK) ON A.CustSeq = C.CustSeq AND C.CompanySeq = @CompanySeq
       WHERE A.CompanySeq = @CompanySeq 
         AND A.TaxTermSeq = @TaxTermSeq 
         AND A.TaxUnit    = @TaxUnit
    END
END  
  
/***************************************************************************************************************************  
세금계산서 합계표 - 표지(Head Record)  
  
01. 자료구분(1) : 7  
02. 보고자등록번호(10)  
03. 보고자상호(30)  
04. 보고자성명(15)  
05. 보고자사업장소재지(45)  
06. 보고자업태(17) : 삭제항목으로 SPACE로 입력  
07. 보고자종목(25) : 삭제항목으로 SPACE로 입력  
08. 거래기간(12) : 신고기간의 첫날과 마지막날 수록(040501040731)  
09. 작성일자(6) : 거래기간에 마지막 부분과 동일(040731)  
10. 공란(9)  
****************************************************************************************************************************/  
IF @WorkingTag IN ('', 'K')  
BEGIN  
    IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)
      OR (@IsESERO = '1')
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
             SELECT '7'                        --01. 자료구분  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(TaxNo,'-','')),10,1)         --02. 보고자등록번호  
                   + CASE WHEN ISNULL(BillTaxName,'') <> '' 
                          THEN dbo._FnVATCHARChg(CONVERT(VARCHAR(30),BillTaxName),30,1)  
                          ELSE dbo._FnVATCHARChg(CONVERT(VARCHAR(30),TaxName),30,1) END --03. 보고자상호  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(15),Owner)       ,15,1)          --04. 보고자성명  
                   + dbo._FnVATCHARChg(CONVERT(VARCHAR(45),VATRptAddr ) ,45,1)          --05. 사업장소재지  
                   + SPACE(17)                                      --06. 보고자업태  
                   + SPACE(25)                                      --07. 보고자종목  
                   + RIGHT(@TaxFrDate, 6) + RIGHT(@TaxToDate, 6)    --08. 거래기간  
                   + RIGHT(@TaxToDate, 6)                           --09. 작성일자  
                   + SPACE(9)  
                   , 170  
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq = @CompanySeq  
               AND TaxUnit    = @TaxUnit   
  
                --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
                ------------------------------------------------------------------------------------------------------------------------------------------
                -- 세금계산서 출력 및 조회 로직과 동일하게 수정 TempTable에 담은 뒤 TempTable에서 결과 생성 2010.10.22 by bgKeum
                ------------------------------------------------------------------------------------------------------------------------------------------
                --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
                CREATE TABLE #TTAXTaxBillSum (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1))
                CREATE TABLE #TTAXTaxBillSum2 (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1))
                INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') ELSE '' END, '' AS CustName, '' AS BizKind, '' AS BizType,
                           SUM(A.BillCnt), SUM(A.SupplyAmt), SUM(A.VATAmt), A.IsEBill, ISNULL(A.IsDelayBill, '')
                      FROM _TTAXTaxBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACust AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl       = 0 ---------------------------------------- Hist내역이 없는 거래처만
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                              CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACust', 'PersonId', @CompanySeq),'') ELSE '' END, A.IsEBill, A.IsDelayBill
                INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACustTaxHist', 'PersonId', @CompanySeq),'') ELSE '' END, '' AS CustName, '' AS BizKind, '' AS BizType,
                           SUM(A.BillCnt), SUM(A.SupplyAmt), SUM(A.VATAmt), A.IsEBill, ISNULL(A.IsDelayBill, '')
                      FROM _TTAXTaxBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                                                 AND A.CustSerl     = B.HistSerl
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl      <> 0 ---------------------------------------- Hist내역
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                              CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonId, '_TDACustTaxHist', 'PersonId', @CompanySeq),'') ELSE '' END, A.IsEBill, A.IsDelayBill
                --==================================================================================================================================
                -- E-Sero신고시 전자세금계산서 내역 삭제 + Upload내역 INSERT 
                --==================================================================================================================================
                IF @IsESERO = '1'
                BEGIN
                    DELETE #TTAXTaxBillSum 
                     WHERE IsEBill = '1' 
                    INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo,
                                                 PersonID, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit, A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                               '', '', COUNT(DISTINCT A.SetNo), SUM(A.SupplyAmt), SUM(A.VATAmt), 
                               '1', CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                          FROM _TTAXEBillUpload AS A WITH(NOLOCK)
                                                     LEFT OUTER JOIN _TTAXOverTerm AS B WITH(NOLOCK)
                                                       ON B.YearMonth   = LEFT(A.BillDate, 6)
                         WHERE A.CompanySeq     = @CompanySeq
                           AND (@TaxUnit = 0 OR A.TaxUnit = @TaxUnit)     
                           AND A.BillDate BETWEEN @TaxFrDate  AND @TaxToDate  
                         GROUP BY A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                                  CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                    -- 전자세금계산서 예정신고누락분은 집계.. ㅠㅠ
                    INSERT INTO #TTAXTaxBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo,
                                                 PersonID, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit, A.SMBuyOrSale, A.BizNo,
                               dbo._FCOMDecrypt(A.CustPersonId, '_TTAXSlipSum', 'CustPersonId', @CompanySeq), '', COUNT(*), SUM(A.SupplyAmt), SUM(A.VATAmt), '1', '0'
                          FROM _TTAXSlipSum AS A WITH(NOLOCK)
                                                 JOIN _TDAEvid AS B WITH(NOLOCK)
                                                   ON A.CompanySeq  = B.CompanySeq
                                                  AND A.EvidSeq     = B.EvidSeq
                                                 JOIN _TACProvDeclar AS C WITH(NOLOCK)
                                                   ON A.CompanySeq  = C.CompanySeq
                                                  AND A.TaxTermSeq  = C.TaxTermSeq
                                                  AND A.SlipSeq     = C.SlipSeq
                         WHERE A.CompanySeq     = @CompanySeq
                           AND A.TaxTermSeq     = @TaxTermSeq
                           AND (@TaxUnit = 0 OR A.TaxUnit   = @TaxUnit)
                           AND B.IsElec         = '1' -- 전자세금계산서의 예정신고 누락분은 신고 되어야 함...
                           AND B.IsBuyerBill   <> '1'
                         GROUP BY A.SMBuyOrSale, A.BizNo, dbo._FCOMDecrypt(A.CustPersonId, '_TTAXSlipSum', 'CustPersonId', @CompanySeq), A.CustName
      UPDATE #TTAXTaxBillSum SET IsEBill = '0', IsDelayBill = '0' WHERE IsEBill = '1' AND IsDelayBill = '1'

                    INSERT INTO #TTAXTaxBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, REPLACE(BizNo, '-', ''), PersonId, '', '', '', SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill
                          FROM #TTAXTaxBillSum
                         GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, REPLACE(BizNo, '-', ''), PersonId, IsEBill, IsDelayBill
                    UPDATE #TTAXTaxBillSum2
                       SET CustName     = B.CustName,
                           BizKind      = '',
                           BizType      = ''
                      FROM #TTAXTaxBillSum2 AS A JOIN _TDACust AS B
                                                   ON B.CompanySeq  = @CompanySeq
                                                  AND A.BizNo       = REPLACE(B.BizNo, '-', '')
                                                  AND B.BizNo       <> ''
                END
                ELSE
                BEGIN
                    INSERT INTO #TTAXTaxBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill)
                        SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill
                          FROM #TTAXTaxBillSum
                         GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BizKind, BizType, IsEBill, IsDelayBill
                END
                
                UPDATE #TTAXTaxBillSum2
				   SET BizNo = CASE WHEN LEN(BizNo) = 10 THEN BizNo ELSE '' END,
				       PersonID = CASE WHEN LEN(PersonID) = 13 THEN PersonID ELSE '' END

                ------------------------------------------------------------------------------------------------------------------------------
                -- 2011년1기확정 과세기간 종료일 다음달 15일 이후 전자세금계산서 전송분 ===> 종이 세금계산서와 같이 신고    --- START
                -- 이 부분 때문에, 아래 신고 파일은 수정할 필요 없음
                ------------------------------------------------------------------------------------------------------------------------------
                UPDATE #TTAXTaxBillSum2
                   SET IsEBill      = '0'
                 WHERE IsEBill      = '1'   -- 전자세금계산서
                   AND IsDelayBill  = '1'   -- 과세기간 종료일 다음달 15일 이후 전송분
                ------------------------------------------------------------------------------------------------------------------------------
                -- 2011년1기확정 과세기간 종료일 다음달 15일 이후 전자세금계산서 전송분 ===> 종이 세금계산서와 같이 신고    --- END
                ------------------------------------------------------------------------------------------------------------------------------
                UPDATE #TTAXTaxBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXTaxBillSum2 AS A JOIN _TDACust AS B WITH(NOLOCK)
                                               ON A.BizNo   = B.BizNo
                                              AND B.CompanySeq = @CompanySeq
                                              AND B.BizNo   <> ''
                UPDATE #TTAXTaxBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXTaxBillSum2 AS A JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                    ON A.BizNo   = B.BizNo
                                              AND B.CompanySeq = @CompanySeq
                                              AND B.BizNo   <> ''
                 WHERE CustName     = ''
            --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
            ------------------------------------------------------------------------------------------------------------------------------------------
            -- 세금계산서 출력 및 조회 로직과 동일하게 수정 TempTable에 담은 뒤 TempTable에서 결과 생성 2010.10.22 by bgKeum
            ------------------------------------------------------------------------------------------------------------------------------------------
            --▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

    -- [매출]자료신고(4099002)  
            IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq   
                                                                    AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)
               OR (@IsESERO = '1')
            BEGIN  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매출자료(전자세금계산서 이외분)  
  
    01. 자료구분(1) : 1  
    02. 보고자등록번호(10)  
    03. 일련번호(4)  
    04. 거래자등록번호(10)  
    05. 거래자상호(30)  
    06. 거래자업태(17) : 삭제항목으로 SPACE로 입력  
    07. 거래자종목(25) : 삭제항목으로 SPACE로 입력  
    08. 세금계산서매수(7)  
    09. 공란수(2) : 삭제항목으로 0으로 입력  
    10. 공급가액(14)  
    11. 세액(13)  
    12. 신고자주류코드(도매)(1) : 보고자가 주류제조업자 또는 주류도매업자인 경우에만 수록하고 기타 업종인 경우에는 0을 수록함  
    13. 주류코드(소매)(1) : 보고자가 주류제조업자 또는 주류도매업자인 경우에만 수록하고 기타 업종인 경우에는 0을 수록함  
    14. 권번호(4) : 전자신고 7501을 수록  
    15. 제출서(3) : 보고자의 관할 세무서의 코드  
    16. 공란(28)  
  
    ※ 주민등록번호 기재분은 별도의 자료레코드를 작성하면 안됨  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT * 
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099002   -- 매출자료(4099002)  
                              AND BizNo      <> ''
                              AND ISNULL(IsEBill,'0') <> '1' )         -- 전자세금계산서 이외분
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '1'                                                                            --01. 자료구분  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1)        --02. 보고자 등록번호 
                            + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY Tax.TaxNo) AS VARCHAR), 4)    --03. 일련번호  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), TaxBill.BizNo),10,1)                   --04. 거래자 등록번호
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), TaxBill.CustName),30,1)                --05. 거래자상호
                            + SPACE(17)                                                                     --06. 거래자업태
                            + SPACE(25)                                                                     --07. 거래자종목
                            + dbo._FnVATIntChg(ISNULL(TaxBill.BillCnt, 0), 7, 0, 1)                         --08. 세금계산서 매수  
                            + '00'                                                                          --09. 공란수  
                            + dbo._FnVATIntChg(ISNULL(TaxBill.SupplyAmt, 0),  14, 0, 2)                     --10. 공급가액  
                            + dbo._FnVATIntChg(ISNULL(TaxBill.VATAmt   , 0),  13, 0, 2)                     --11. 세액  
                            + CASE WHEN RIGHT('0' + CONVERT(VARCHAR(1),LTRIM(RTRIM(ISNULL(Tax.liquorWholeSaleNo ,'0')))),1) IN ('0', '') THEN '0'
                                   ELSE '1' END   --12. 신고자주류코드(도매) 
                            + SPACE(1)   --13. 주류코드(소매)  
                            + '7501'                                                                        --14. 권번호  
                            + Tax.TaxOfficeNo                                                               --15. 제출서  
                            + SPACE(28)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq   = Tax.CompanySeq  
                                                        AND TaxBill.TaxUnit      = Tax.TaxUnit 
                     WHERE TaxBill.SMBuyOrSale = 4099002   -- 매출자료(4099002)  
                       AND TaxBill.BizNo      <> ''
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'         -- 전자세금계산서 이외분   
                END --세금계산서 합계표 - 매출자료(전자세금계산서 이외분)끝  
  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매출합계(전자세금계산서 이외분)  
  
    01. 자료구분(1) : 3  
    02. 보고자등록번호(10)  
    --합계분  
    03. 거래처수(7)         : 사업자등록번호 발행분 거래처수 + 주민등록번호 발행분 거래처수  
    04. 세금계산서 매수(7)  : 사업자등록번호 발행분 매수 + 주민등록번호 발행분 매수  
    05. 공급가액(15)        : 사업자등록번호 발행분 공급가액 + 주민등록번호 발행분 공급가액  
    06. 세액(14)            : 사업자등록번호 발행분 세액 + 주민등록번호 발행분 세액  
    --사업자번호발행분  
    07. 거래처수(7)         : 사업자등록번호 발행분 거래처수  
    08. 세금계산서매수(7)   : 사업자등록번호 발행분 매수  
    09. 공급가액(15)        : 사업자등록번호 발행분 공급가액  
    10. 세액(14)            : 사업자등록번호 발행분 세액  
    --주민번호발행분  
    11.거래처수(7)          : 주민등록번호 발행분 거래처수  
    12. 세금계산서매수(7)   : 주민등록번호 발행분 매수  
    13. 공급가액(15)        : 주민등록번호 발행분 공급가액  
    14. 세액(14)            : 주민등록번호 발행분 세액  
    15. 공란(30)  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1 
                             FROM #TTAXTaxBillSum2 AS A
                            WHERE A.SMBuyOrSale = 4099002       -- 매출자료(4099002) 
                              AND ISNULL(A.IsEBill,'0') <> '1') -- 전자세금계산서 이외분  
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '3'                          --01. 자료구분  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10),REPLACE(Tax.TaxNo,'-','')),10,1)          --02. 보고자등록번호  
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1     -- 사업자등록발행분
                                                        WHEN ISNULL(TaxBill.BizNo, '') = ''  THEN 1     -- 주민등록발행분
                                                        ELSE 0 END), 7, 0, 1)                 --03. 거래처수
                            + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)               --04. 세금계산서 매수  
                            + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)               --05. 공급가액 합계  
                            + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)               --06. 세액 합계  
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END),  7, 0, 1)                   --07. 거래처수 (사업자등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)                   --08. 세금계산서 매수(사업자등록발행분) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)                  --09. 공급가액       (사업자등록발행분) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)                  --10. 세액           (사업자등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END),  7, 0, 1)                   --11. 거래처수       (주민등록발행분) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)                   --12. 세금계산서 매수(주민등록발행분) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)                  --13. 공급가액       (주민등록발행분) 
                            + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)                  --14. 세액           (주민등록발행분)
                            + SPACE(30)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq      = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit         = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099002        -- 매출자료(4099002)  
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'   -- 전자세금계산서 이외분   
                     GROUP BY Tax.TaxNo
                END-- 세금계산서 합계표 - 매출합계(전자세금계산서 이외분)끝  
  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매출합계(전자세금계산서분)  
  
    01. 자료구분(1) : 5  
    02. 보고자등록번호(10)  
    --합계분  
    03. 거래처수(7)         : 사업자등록번호 발행분 거래처수 + 주민등록번호 발행분 거래처수  
    04. 세금계산서 매수(7)  : 사업자등록번호 발행분 매수 + 주민등록번호 발행분 매수  
    05. 공급가액(15)        : 사업자등록번호 발행분 공급가액 + 주민등록번호 발행분 공급가액  
    06. 세액(14)            : 사업자등록번호 발행분 세액 + 주민등록번호 발행분 세액  
    --사업자번호발행분  
    07. 거래처수(7)         : 사업자등록번호 발행분 거래처수  
    08. 세금계산서매수(7)   : 사업자등록번호 발행분 매수  
    09. 공급가액(15)        : 사업자등록번호 발행분 공급가액  
    10. 세액(14)            : 사업자등록번호 발행분 세액  
    --주민번호발행분  
    11.거래처수(7)          : 주민등록번호 발행분 거래처수  
    12. 세금계산서매수(7)   : 주민등록번호 발행분 매수  
    13. 공급가액(15)        : 주민등록번호 발행분 공급가액  
    14. 세액(14)            : 주민등록번호 발행분 세액  
    15. 공란(30)  
    ****************************************************************************************************************************/  
                IF @IsESERO = '1' AND EXISTS (SELECT 1 FROM _TTAXEBillUpload WITH(NOLOCK)
                                                    WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002   
                                                      AND BillDate BETWEEN @TaxFrDate AND @TaxToDate
                                                      AND TransDate < @OverDate)  
                BEGIN  
                    -- 사업자번호발행분  
                    SELECT @CustCntBiz = COUNT(DISTINCT R_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate    -- 과세기간종료일 다음달 15일 이전데이터만...
  
                    SELECT @TotCntBiz   = COUNT(*)                      ,  
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate    -- 과세기간종료일 다음달 15일 이전데이터만...
  
                    -- 주민번호 발행분  
                    SELECT @CustCntPer = COUNT(DISTINCT R_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate    -- 과세기간종료일 다음달 15일 이전데이터만...
  
                    SELECT @TotCntPer   = COUNT(*)                      ,  
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099002  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(R_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate    -- 과세기간종료일 다음달 15일 이전데이터만...
  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '5'                         --01. 자료구분  
                            + dbo._FnVATCHARChg(@TaxNo ,10,1)                       --02. 보고자등록번호  
                            + dbo._FnVATIntChg(@CustCntBiz + @CustCntPer, 7, 0, 1)  --03. 거래처수  
                            + dbo._FnVATIntChg(@TotCntBiz  + @TotCntPer , 7, 0, 1)  --04. 세금계산서 매수  
                            + dbo._FnVATIntChg(@SAmtBiz    + @SAmtPer   ,15, 0, 2)  --05. 공급가액 합계  
                            + dbo._FnVATIntChg(@VAmtBiz    + @VAmtPer   ,14, 0, 2)  --06. 세액 합계  
                            + dbo._FnVATIntChg(@CustCntBiz  , 7, 0, 1)              --07. 거래처수       (사업자등록발행분)  
                            + dbo._FnVATIntChg(@TotCntBiz   , 7, 0, 1)              --08. 세금계산서 매수(사업자등록발행분)  
                            + dbo._FnVATIntChg(@SAmtBiz     ,15, 0, 2)              --09. 공급가액       (사업자등록발행분)  
                            + dbo._FnVATIntChg(@VAmtBiz     ,14, 0, 2)              --10. 세액           (사업자등록발행분)  
                            + dbo._FnVATIntChg(@CustCntPer  , 7, 0, 1)              --11. 거래처수       (주민등록발행분)  
                            + dbo._FnVATIntChg(@TotCntPer   , 7, 0, 1)              --12. 세금계산서 매수(주민등록발행분)  
                            + dbo._FnVATIntChg(@SAmtPer     ,15, 0, 2)              --13. 공급가액       (주민등록발행분)  
                            + dbo._FnVATIntChg(@VAmtPer     ,14, 0, 2)              --14. 세액           (주민등록발행분)  
                            + SPACE(30)  
                            , 170  
                END  
                ELSE  
                BEGIN  
                    IF EXISTS (SELECT 1
                                 FROM #TTAXTaxBillSum2
                                WHERE SMBuyOrSale = 4099002     -- 매출자료(4099002)  
                                  AND ISNULL(IsEBill,'0') = '1' ) -- 전자세금계산서분  
                    BEGIN  
                        
                        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                          SELECT '5'                          --01. 자료구분  
                                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)          --02. 보고자등록번호  
                                + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' OR TaxBill.BizNo = '' THEN 1 ELSE 0 END), 7, 0, 1) --03. 거래처수  
                                + dbo._FnVATIntChg(SUM(TaxBill.BillCnt), 7, 0, 1)                 --04. 세금계산서 매수  
                                + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)               --05. 공급가액 합계  
                                + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)               --06. 세액 합계  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END),  7, 0, 1)  --07. 거래처수       (사업자등록발행분) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)  --08. 세금계산서 매수(사업자등록발행분) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)  --09. 공급가액       (사업자등록발행분) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)  --10. 세액           (사업자등록발행분)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END),  7, 0, 1)  --11. 거래처수       (주민등록발행분)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END),  7, 0, 1)  --12. 세금계산서 매수(주민등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END), 15, 0, 2)  --13. 공급가액       (주민등록발행분) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END), 14, 0, 2)  --14. 세액           (주민등록발행분)
                                + SPACE(30)  
                                , 170  
                          FROM #TTAXTaxBillSum2 AS TaxBill WITH(NOLOCK)
                                                           LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                             ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                            AND TaxBill.TaxUnit     = Tax.TaxUnit
                         WHERE 1 = 1
                           AND TaxBill.SMBuyOrSale = 4099002   -- 매출자료(4099002)  
                           AND ISNULL(TaxBill.IsEBill,'0') = '1'    -- 전자세금계산서분  
                         GROUP BY Tax.TaxNo   
                    END-- 세금계산서 합계표 - 매출합계(전자세금계산서분)끝  
                END  
            END  
    -- [매출]집계종료  
           
  
    -- [매입]자료신고  
            IF EXISTS (SELECT * FROM _TTAXTaxBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq   
                                                                    AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)  
            BEGIN  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매입자료(전자세금계산서 이외분)  
  
    01. 자료구분(1) : 2  
    02. 보고자등록번호(10)  
    03. 일련번호(4)  
    04. 거래자등록번호(10)  
    05. 거래자상호(30)  
    06. 거래자업태(17) : 삭제항목으로 SPACE로 입력  
    07. 거래자종목(25) : 삭제항목으로 SPACE로 입력  
    08. 세금계산서매수(7)  
    09. 공란수(2) : 삭제항목으로 0으로 입력  
    10. 공급가액(14)  
    11. 세액(13)  
    12. 신고자주류코드(도매)(1) : 보고자가 주류제조업자 또는 주류도매업자인 경우에만 수록하고 기타 업종인 경우에는 0을 수록함  
    13. 주류코드(소매)(1) : 보고자가 주류제조업자 또는 주류도매업자인 경우에만 수록하고 기타 업종인 경우에는 0을 수록함  
    14. 권번호(4) : 전자신고 8501을 수록  
    15. 제출서(3) : 보고자의 관할 세무서의 코드  
    16. 공란(28)  
  
    ※ 주민등록번호 기재분은 별도의 자료레코드를 작성하면 안됨  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1 
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099001   -- 매입자료(4099001) 
                              AND BizNo        <> ''
                              AND ISNULL(IsEBill,'0') <> '1')  -- 전자세금계산서 이외분
                BEGIN  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '2'                                                                            --01. 자료구분  
                          + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)       --02. 보고자 등록번호  
                            + RIGHT('0000' + CAST(ROW_NUMBER() OVER (ORDER BY Tax.TaxNo) AS VARCHAR), 4)    --03. 일련번호  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), TaxBill.BizNo), 10, 1)                 --04. 거래자 등록번호 
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(30), TaxBill.CustName), 30, 1)              --05. 거래자상호
                            + SPACE(17)                                                                     --06. 거래자업태  
                            + SPACE(25)                                                                     --07. 거래자종목  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.BillCnt), 0), 7, 0, 1)                    --08. 세금계산서 매수  
                            + '00'                                                                          --09. 공란수  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.SupplyAmt), 0),  14, 0, 2)                --10. 공급가액  
                            + dbo._FnVATIntChg(ISNULL(SUM(TaxBill.VATAmt   ), 0),  13, 0, 2)                --11. 세액     
                            + CASE WHEN RIGHT('0' + CONVERT(VARCHAR(1),LTRIM(RTRIM(ISNULL(Tax.liquorWholeSaleNo ,'0')))),1) IN ('0', '') THEN '0'
                                   ELSE '1' END      --12. 신고자주류코드(도매)    
                            + SPACE(1)              --13. 주류코드(소매)
                            + '8501'                                                                        --14. 권번호  
                            + Tax.TaxOfficeNo                                                               --15. 제출서  
                            + SPACE(28)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit     = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099001   -- 매입자료(4099001) 
                       AND TaxBill.BizNo        <> ''
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'  -- 전자세금계산서 이외분
                     GROUP BY Tax.TaxNo, TaxBill.BizNo, TaxBill.CustName, Tax.liquorWholeSaleNo, Tax.liquorRetailSaleNo, Tax.TaxOfficeNo, ISDelayBill
                END --세금계산서 합계표 - 매입자료(전자세금계산서 이외분)끝  
  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매입합계(전자세금계산서 이외분)  
  
    01. 자료구분(1) : 4  
    02. 보고자등록번호(10)  
    --합계분  
    03. 거래처수(7)         : 사업자등록번호 발행분 거래처수 + 주민등록번호 발행분 거래처수  
    04. 세금계산서 매수(7)  : 사업자등록번호 발행분 매수 + 주민등록번호 발행분 매수  
    05. 공급가액(15)        : 사업자등록번호 발행분 공급가액 + 주민등록번호 발행분 공급가액  
    06. 세액(14)            : 사업자등록번호 발행분 세액 + 주민등록번호 발행분 세액  
    --사업자번호발행분  
    07. 거래처수(7)         : 사업자등록번호 발행분 거래처수  
    08. 세금계산서매수(7)   : 사업자등록번호 발행분 매수  
    09. 공급가액(15)        : 사업자등록번호 발행분 공급가액  
    10. 세액(14)            : 사업자등록번호 발행분 세액  
    --주민번호발행분  
    11.거래처수(7)          : 주민등록번호 발행분 거래처수  
    12. 세금계산서매수(7)   : 주민등록번호 발행분 매수  
    13. 공급가액(15)        : 주민등록번호 발행분 공급가액  
    14. 세액(14)            : 주민등록번호 발행분 세액  
    15. 공란(30)  
    ****************************************************************************************************************************/  
                IF EXISTS (SELECT 1
                             FROM #TTAXTaxBillSum2
                            WHERE SMBuyOrSale = 4099001        -- 매입자료(4099001)  
                              AND ISNULL(IsEBill,'0') <> '1')   -- 전자세금계산서 이외분
                BEGIN  
                    SELECT @Count_A = COUNT(BizNo)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale = 4099001       -- 매입자료(4099001) 
                       AND ISNULL(IsEBill,'0') <> '1'   -- 전자세금계산서 이외분
                       AND BizNo        > ''            -- 사업자등록발행분
                    SELECT @Count_B = COUNT(PersonID)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale  = 4099001       -- 매입자료(4099001) 
                       AND ISNULL(IsEBill,'0') <> '1'   -- 전자세금계산서 이외분
                       AND BizNo        = ''            -- 주민등록발행분

                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '4'                          --01. 자료구분  
                            + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)          --02. 보고자등록번호  
                            + dbo._FnVATIntChg(@Count_A + @Count_B, 7, 0, 1)                            --03. 거래처수   
                            + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)                         --04. 세금계산서 매수  
                            + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)                         --05. 공급가액 합계  
                            + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)                         --06. 세액 합계  
                            + dbo._FnVATIntChg(ISNULL(@Count_A, 0), 7, 0, 1)                                                    --07. 거래처수       (사업자등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --08. 세금계산서 매수(사업자등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --09. 공급가액       (사업자등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo <> '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --10. 세액           (사업자등록발행분)
                            + dbo._FnVATIntChg(ISNULL(@Count_B, 0), 7, 0, 1)                                                    --11. 거래처수       (주민등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.BillCnt    ELSE 0 END), 7, 0, 1)   --12. 세금계산서 매수(주민등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.SupplyAmt  ELSE 0 END),15, 0, 2)   --13. 공급가액       (주민등록발행분)
                            + dbo._FnVATIntChg(SUM(CASE WHEN TaxBill.BizNo = '' THEN TaxBill.VATAmt     ELSE 0 END),14, 0, 2)   --14. 세액           (주민등록발행분)
                            + SPACE(30)  
                            , 170  
                      FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                         ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                        AND TaxBill.TaxUnit     = Tax.TaxUnit
                     WHERE TaxBill.SMBuyOrSale = 4099001        -- 매입자료(4099001)  
                       AND ISNULL(TaxBill.IsEBill,'0') <> '1'   -- 전자세금계산서 이외분
                     GROUP BY Tax.TaxNo 
               END-- 세금계산서 합계표 - 매입합계(전자세금계산서 이외분)끝  
    /***************************************************************************************************************************  
    세금계산서 합계표 - 매입합계(전자세금계산서분)  
  
    01. 자료구분(1) : 6  
    02. 보고자등록번호(10)  
    --합계분  
    03. 거래처수(7)         : 사업자등록번호 발행분 거래처수 + 주민등록번호 발행분 거래처수  
    04. 세금계산서 매수(7)  : 사업자등록번호 발행분 매수 + 주민등록번호 발행분 매수  
    05. 공급가액(15)        : 사업자등록번호 발행분 공급가액 + 주민등록번호 발행분 공급가액  
    06. 세액(14)            : 사업자등록번호 발행분 세액 + 주민등록번호 발행분 세액  
    --사업자번호발행분  
    07. 거래처수(7)         : 사업자등록번호 발행분 거래처수  
    08. 세금계산서매수(7)   : 사업자등록번호 발행분 매수  
    09. 공급가액(15)        : 사업자등록번호 발행분 공급가액  
    10. 세액(14)            : 사업자등록번호 발행분 세액  
    --주민번호발행분  
    11.거래처수(7)          : 주민등록번호 발행분 거래처수  
    12. 세금계산서매수(7)   : 주민등록번호 발행분 매수  
    13. 공급가액(15)        : 주민등록번호 발행분 공급가액  
    14. 세액(14)            : 주민등록번호 발행분 세액  
    15. 공란(30)  
    ****************************************************************************************************************************/  
                IF @IsESERO = '1' AND EXISTS (SELECT 1 FROM _TTAXEBillUpload WITH(NOLOCK)
                                                    WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001  
                                                      AND BillDate BETWEEN @TaxFrDate AND @TaxToDate
                                                      AND TransDate < @OverDate)  -- [전송일이 과세기간종료일다음달 15일] 이전
                BEGIN  
                    -- 사업자번호발행분  
                    SELECT @CustCntBiz = COUNT(DISTINCT S_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate -- [전송일이 과세기간종료일다음달 15일] 이전
                    -- !!!!!!!!!!!!!!
                    SELECT @CustCntBiz = COUNT(DISTINCT BizNo)
                      FROM #TTAXTaxBillSum2
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND BizNo        > ''
                       AND IsEBill      = '1'
  
                    SELECT @TotCntBiz   = COUNT(*)                      ,  
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) < 13  
                       AND TransDate    < @OverDate -- [전송일이 과세기간종료일다음달 15일] 이전
                    -- !!!!!!!!!!!!!!
                    SELECT @TotCntBiz   = ISNULL(SUM(BillCnt    ), 0)   ,
                           @SAmtBiz     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtBiz     = ISNULL(SUM(VATAmt     ), 0)                                
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND BizNo        > ''
                       AND IsEBill      = '1'
  
                    -- 주민번호 발행분  
                    SELECT @CustCntPer = COUNT(DISTINCT S_TaxNo)  
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
                       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate -- [전송일이 과세기간종료일다음달 15일] 이전
                    -- !!!!!!!!!!!!!!
                    SELECT @CustCntPer = COUNT(DISTINCT BizNo)
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND PersonID     > ''
                       AND IsEBill      = '1'
  
                    SELECT @TotCntPer   = COUNT(*)                      ,  
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)     
                      FROM _TTAXEBillUpload WITH(NOLOCK)
                     WHERE CompanySeq   = @CompanySeq  
       AND TaxUnit      = @TaxUnit  
                       AND SMBuyOrSale  = 4099001  
                       AND BillDate BETWEEN @TaxFrDate AND @TaxToDate  
                       AND LEN(REPLACE(S_TaxNo, '-', '')) = 13  
                       AND TransDate    < @OverDate -- [전송일이 과세기간종료일다음달 15일] 이전
                    -- !!!!!!!!!!!!!!
                    SELECT @TotCntPer   = ISNULL(SUM(BillCnt    ), 0)   ,
                           @SAmtPer     = ISNULL(SUM(SupplyAmt  ), 0)   ,  
                           @VAmtPer     = ISNULL(SUM(VATAmt     ), 0)                                
                      FROM #TTAXTaxBillSum2 
                     WHERE SMBuyOrSale  = 4099001  
                       AND TaxUnit      = @TaxUnit 
                       AND PersonID     > ''
                       AND IsEBill      = '1'
  
                    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                      SELECT '6'             --01. 자료구분  
                            + dbo._FnVATCHARChg(@TaxNo,10,1)      --02. 보고자등록번호  
                            + dbo._FnVATIntChg(@CustCntBiz + @CustCntPer, 7, 0, 1)  --03. 거래처수   
                            + dbo._FnVATIntChg(@TotCntBiz + @TotCntPer, 7, 0, 1)    --04. 세금계산서 매수  
                            + dbo._FnVATIntChg(@SAmtBiz + @SAmtPer,15, 0, 2)        --05. 공급가액 합계  
                            + dbo._FnVATIntChg(@VAmtBiz + @VAmtPer,14, 0, 2)        --06. 세액 합계  
                            + dbo._FnVATIntChg(@CustCntBiz  , 7, 0, 1)              --07. 거래처수  
                            + dbo._FnVATIntChg(@TotCntBiz   , 7, 0, 1)              --08. 세금계산서 매수(사업자등록발행분)  
                            + dbo._FnVATIntChg(@SAmtBiz     ,15, 0, 2)              --09. 공급가액       (사업자등록발행분)  
                            + dbo._FnVATIntChg(@VAmtBiz     ,14, 0, 2)              --10. 세액           (사업자등록발행분)  
                            + dbo._FnVATIntChg(@CustCntPer  , 7, 0, 1)              --07. 거래처수  
                            + dbo._FnVATIntChg(@TotCntPer   , 7, 0, 1)              --08. 세금계산서 매수(주민등록발행분)  
                            + dbo._FnVATIntChg(@SAmtPer     ,15, 0, 2)              --09. 공급가액       (주민등록발행분)  
                            + dbo._FnVATIntChg(@VAmtPer     ,14, 0, 2)              --10. 세액           (주민등록발행분)  
                            + SPACE(30)  
                            , 170  
                END  
                ELSE  
                BEGIN  
                    IF EXISTS (SELECT 1 
                                 FROM #TTAXTaxBillSum2 
                                 WHERE SMBuyOrSale = 4099001        -- 매입자료(4099001)  
                                   AND ISNULL(IsEBill,'0') = '1')    -- 전자세금계산서
                    BEGIN  
                        
                        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
                          SELECT '6'                          --01. 자료구분  
                                + dbo._FnVATCHARChg(CONVERT(VARCHAR(10), REPLACE(Tax.TaxNo,'-','')),10,1)           --02. 보고자등록번호  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' OR ISNULL(TaxBill.BizNo, '')  = '' THEN 1 ELSE 0 END), 7, 0, 1) --03. 거래처수
                                + dbo._FnVATIntChg(SUM(TaxBill.BillCnt)  , 7, 0, 1)                                 --04. 세금계산서 매수
                                + dbo._FnVATIntChg(SUM(TaxBill.SupplyAmt),15, 0, 2)                                 --05. 공급가액 합계  
                                + dbo._FnVATIntChg(SUM(TaxBill.VATAmt)   ,14, 0, 2)                                 --06. 세액 합계  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN 1                 ELSE 0 END), 7, 0, 1)   --07. 거래처수       (사업자등록발행분)
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --08. 세금계산서 매수(사업자등록발행분) 
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --09. 공급가액       (사업자등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '') <> '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --10. 세액           (사업자등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN 1                 ELSE 0 END), 7, 0, 1)   --11. 거래처수       (주민등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.BillCnt   ELSE 0 END), 7, 0, 1)   --12. 세금계산서 매수(주민등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.SupplyAmt ELSE 0 END),15, 0, 2)   --13. 공급가액       (주민등록발행분)  
                                + dbo._FnVATIntChg(SUM(CASE WHEN ISNULL(TaxBill.BizNo, '')  = '' THEN TaxBill.VATAmt    ELSE 0 END),14, 0, 2)   --14. 세액           (주민등록발행분)  
                                + SPACE(30)  
                                , 170  
                          FROM #TTAXTaxBillSum2 AS TaxBill LEFT OUTER JOIN #TDATaxUnit AS Tax WITH(NOLOCK)
                                                             ON TaxBill.CompanySeq  = Tax.CompanySeq
                                                            AND TaxBill.TaxUnit     = Tax.TaxUnit
                         WHERE TaxBill.SMBuyOrSale = 4099001   -- 매입자료(4099001)  
                           AND ISNULL(TaxBill.IsEBill,'0') = '1'       -- 전자세금계산서
                         GROUP BY Tax.TaxNo   
                    END  
                END-- 세금계산서 합계표 - 매입합계(전자세금계산서분)끝  
            END-- [매입]집계종료  
    END--세금계산서 집계 종료  
END  
/***************************************************************************************************************************    
계산서 합계표 -제출자    
    
01. 레코드구분(1) : A    
02. 세무서(3)    
03. 제출년월일(8)    
04. 제출자구분(1) : '1'  세무대리인, '2' 법인, '3' 개인    
05. 세무대리인관리번호(6)    
06. 사업자등록번호(10)    
07. 법인명(상호)(40)    
08. 주민(법인)등록번호(13)  09. 대표자(30)    
10. 소재지(우편번호) 법정동코드(10)    
11. 소재지(주소)(70)    
12. 전화번호(15)    
13. 제출건수계(5)    
14. 사용한한글코드종류(3) : 전자신고는 '101'    
15. 공란(15)    
****************************************************************************************************************************/    
IF @WorkingTag IN ('', 'H')  
BEGIN  
    IF @Env4728 = '1'
        OR EXISTS (SELECT * FROM _TTAXBillSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)    
    BEGIN    
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'A'  --01. 자료구분    
                   + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END  --02. 세무서코드    
                   + CONVERT(VARCHAR(8), GETDATE(), 112)              --03. 제출년월일    
                   + '2'                        --04. 제출자구분(법인)    
                   + SPACE(6)                   --05. 세무대리인관리번호    
                   + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))                    --06. 사업자등록번호    
                   + CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE ComInfo.TaxName END)))    
                             + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END)))))  --07. 법인명(상호)    
                   + @CompanyNo                 --08.법인등록번호    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))))) --09.대표자    
                   + CASE WHEN ISNULL(ComInfo.Zip, '') = '' THEN SPACE(10)    
                          ELSE CONVERT(VARCHAR(10), LTRIM(RTRIM(ComInfo.Zip))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(ComInfo.Zip)))))  
                     END                        --10.우편번호    
                   + LTRIM(RTRIM(@Addr1)) + SPACE(70 - DataLength(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))      --11. 사업장소재지    
                   + CONVERT(VARCHAR(15), LTRIM(RTRIM(dbo._FnTaxTelChk( ComInfo.TelNo )))) +  SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), LTRIM(RTRIM(dbo._FnTaxTelChk( ComInfo.TelNo ))))))  --12. 전화번호    
                   + '00001'                    --13. 제출건수계    
                   + '101'                      --14. 사용한한글코드종류    
                   + SPACE(15)    
                   , 230    
             FROM #TDATaxUnit AS ComInfo WITH(NOLOCK)    
             WHERE ComInfo.CompanySeq   = @CompanySeq  
               AND ComInfo.TaxUnit      = @TaxUnit    
       
    /***************************************************************************************************************************    
    계산서 합계표 - 제출의무자인적사항    
        
    01. 레코드구분(1) : B    
    02. 세무서(3)    
    03. 일련번호(6)    
    04. 사업자등록번호(10)    
    05. 법인명(상호)(40)    
    06. 대표자(성명)(30)    
    07. 사업장(우편번호)법정동코드(10)    
    08. 사업장소재지(주소)(70)    
    09. 공란(60)    
    ****************************************************************************************************************************/    
                 INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                 SELECT 'B'  --01. 자료구분    
                       + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --02. 세무서코드    
                       + '000001'                     --03. 일련번호    
                       + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))                   --04. 사업자등록번호    
                       + CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END )))    
                            + SPACE(40 - DATALENGTH(CONVERT(VARCHAR(40), LTRIM(RTRIM(CASE WHEN ISNULL(ComInfo.BillTaxName,'') <> '' THEN ComInfo.BillTaxName ELSE TaxName END )))))  --05. 법인명(상호)    
                       + CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(ComInfo.Owner))))) --06. 대표자    
                       + CASE WHEN ISNULL(ComInfo.Zip, '') = '' THEN SPACE(10)    
                              ELSE CONVERT(VARCHAR(10), ComInfo.Zip) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), ComInfo.Zip)))  
                         END                      --07.우편번호    
                       + LTRIM(RTRIM(@Addr1)) + SPACE(70 - DataLength(CONVERT(VARCHAR(70), LTRIM(RTRIM(@Addr1)))))      --08. 사업장소재지    
                       + SPACE(60)    
                       , 230    
                   FROM #TDATaxUnit AS ComInfo WITH(NOLOCK)   
                  WHERE ComInfo.CompanySeq   = @CompanySeq  
                    AND ComInfo.TaxUnit      = @TaxUnit  
    /****************************************************************************************************************************/    
                --계산서합계표 관련 처리
                CREATE TABLE #TTAXBillSum (
                    CompanySeq          INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BillCnt             INT,
                    SupplyAmt           DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1),
                    CustSeq             INT)
                CREATE TABLE #TTAXBillSum2 (
                    CompanySeq      INT,
                    TaxTermSeq          INT,
                    TaxUnit             INT,
                    SMBuyOrSale         INT,
                    BizNo               NVARCHAR(200),
                    PersonId            NVARCHAR(200),
                    CustName            NVARCHAR(100),
                    BizKind             NVARCHAR(60),
                    BizType             NVARCHAR(60),                    
                    BillCnt             INT,
                    Amt                 DECIMAL(19,5),
                    VATAmt              DECIMAL(19,5),
                    IsEBill             NCHAR(1),
                    IsDelayBill         NCHAR(1),
                    CustSeq             INT)    
    
                --계산서합계표
                INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill,CustSeq)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonID', @CompanySeq),'') ELSE '' END,  
                           '' AS CustName, 
                           SUM(A.BillCnt), SUM(A.Amt), 0, 
                           ISNULL(A.IsEBill, '0'),
                           A.IsDelayBill, 
                           B.CustSeq
                       FROM _TTAXBillSum AS A WITH(NOLOCK)
                                 LEFT OUTER JOIN _TDACust  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                                            AND A.CustSeq = B.CustSeq
                                                                            AND A.CustSerl = 0
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl       = 0 ---------------------------------------- Hist내역이 없는 거래처만
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACust', 'PersonID', @CompanySeq),'') ELSE '' END,
                           A.IsEBill, A.IsDelayBill, B.CustSeq

                INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, SupplyAmt, VATAmt, IsEBill, IsDelayBill,CustSeq)
                    SELECT A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACustTaxHist', 'PersonID', @CompanySeq),'') ELSE '' END,  
                           '' AS CustName, 
                           SUM(A.BillCnt), SUM(A.Amt), 0, 
                           ISNULL(A.IsEBill, '0'),
                           A.IsDelayBill,
                           B.CustSeq
                      FROM _TTAXBillSum AS A WITH(NOLOCK)
                                                JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                                  ON A.CompanySeq   = B.CompanySeq
                                                 AND A.CustSeq      = B.CustSeq
                                                 AND A.CustSerl     = B.HistSerl
                     WHERE A.CompanySeq     = @CompanySeq
                       AND A.TaxTermSeq     = @TaxTermSeq
                       AND A.TaxUnit        = @TaxUnit
                       AND A.CustSerl      <> 0 ---------------------------------------- Hist내역
                     GROUP BY A.CompanySeq, A.TaxTermSeq, A.TaxUnit, A.SMBuyOrSale, 
                           REPLACE(ISNULL(B.BizNo,''), '-', ''), 
                           CASE WHEN ISNULL(B.BizNo, '') = '' THEN ISNULL(dbo._FCOMDecrypt(B.PersonID, '_TDACustTaxHist', 'PersonID', @CompanySeq),'') ELSE '' END, 
                           A.IsEBill, A.IsDelayBill,B.CustSeq
                --==================================================================================================================================
                -- E-Sero신고시 전자계산서 내역 삭제 + Upload내역 INSERT 
                --==================================================================================================================================
                IF @Env4728 = '1'
                BEGIN
                    -- 전표기준 내역 삭제
                    DELETE #TTAXBillSum WHERE IsEBill = '1'
                    
                    INSERT INTO #TTAXBillSum (CompanySeq, TaxTermSeq    , TaxUnit, SMBuyOrSale  , BizNo, 
                                              PersonId  , CustName      , BillCnt, SupplyAmt    , VATAmt,
                                              IsEBill   , IsDelayBill   , CustSeq)
                        SELECT @CompanySeq, @TaxTermSeq, @TaxUnit               , A.SMBuyOrSale     , CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                               ''         , ''         , COUNT(DISTINCT A.SetNo), SUM(A.SupplyAmt)  , SUM(A.VATAmt), 
                               '1'        , CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END, 0        -- CustSeq 0
                          FROM _TTAXElectronicBillUpload AS A WITH(NOLOCK)
                                    LEFT OUTER JOIN _TTAXOverTerm AS B WITH(NOLOCK) ON B.YearMonth   = LEFT(A.BillDate, 6)
                         WHERE A.CompanySeq     = @CompanySeq
                           AND (@TaxUnit = 0 OR A.TaxUnit = @TaxUnit)     
                           AND A.BillDate BETWEEN @BillFrDate AND @BillToDate
                         GROUP BY A.SMBuyOrSale, CASE WHEN A.SMBuyOrSale = 4099001 THEN REPLACE(A.S_TaxNo, '-', '') ELSE REPLACE(A.R_TaxNo, '-', '') END,
                                  CASE WHEN A.TransDate >= B.OverDate THEN '1' ELSE '0' END
                    -- 기한후전송 일반계산서 처리
                    UPDATE #TTAXBillSum SET IsEBill = '0', IsDelayBill = '0' WHERE IsEBill = '1' AND IsDelayBill = '1'
                    
                
                END
                
                INSERT INTO #TTAXBillSum2 (CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, BillCnt, Amt, VATAmt, IsEBill, IsDelayBill, CustSeq)
                    SELECT CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, SUM(BillCnt), SUM(SupplyAmt), SUM(VATAmt), IsEBill, IsDelayBill, MAX(CustSeq)
                      FROM #TTAXBillSum
                     GROUP BY CompanySeq, TaxTermSeq, TaxUnit, SMBuyOrSale, BizNo, PersonId, CustName, IsEBill, IsDelayBill
                --------------------------------------------
                -- 전자계산서 11일 이후 전송분 
                --------------------------------------------
                UPDATE #TTAXBillSum2
                   SET IsEBill      = '0'
                 WHERE IsEBill      = '1'   -- 전자계산서
                   AND IsDelayBill  = '1'   -- 과세기간 종료일 다음달 11일 이후 전송분
                
                UPDATE #TTAXBillSum2
                   SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXBillSum2 AS A JOIN _TDACust AS B WITH(NOLOCK)
                                            ON A.BizNo      = B.BizNo
                                           AND B.CompanySeq = @CompanySeq
                                           AND B.BizNo   <> ''
                UPDATE #TTAXBillSum2
           SET CustName     = ISNULL(B.FullName        , ''),
                       BizKind      = ISNULL(B.BizKind         , ''),
                       BizType      = ISNULL(B.BizType         , '')
                  FROM #TTAXBillSum2 AS A JOIN _TDACustTaxHist AS B WITH(NOLOCK)
                                            ON A.BizNo      = B.BizNo
                                           AND B.CompanySeq = @CompanySeq
                                           AND B.BizNo   <> ''
                 WHERE CustName     = ''

  
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서 외 제출의무자별집계레코드(매출) 
        
    01. 레코드구분(1) : C    
    02. 자료구분(2) : 17    
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 사업자등록번호(10)    
    08. 귀속년도(4)    
    09. 거래기간시작년월일(8)    
    10. 거래기간종료년월일(8)    
    11. 작성일자(8)    
    12. 매출처수합계(6) : 16.사업자등록번호발행분매출처수 + 20.주민등록번호발행분매출처수    
    13. 계산서매수합계(6) : 17.사업자등록번호발행분계산서매수 + 21.주민등록번호발행분계산서매수    
    14. 매출(수입)금액합계음수표시(1) : 매출금액이 양수인 경우 '0', 음수인 경우 '1'    
    15. 매출(수입)금액합계(14) : 19.사업자등록번호발행분매출(수입)금액 + 23.주민등록번호발행분매출(수입)금액    
    16. 사업자등록번호발행분매출처수(6)    
    17. 사업자등록번호발행분계산서매수(6)    
    18. 사업자등록번호발행분매출(수입)금액음수표시(1) : 매출금액이 양수인 경우 '0', 음수인 경우 '1'    
    19. 사업자등록번호발행분매출(수입)금액(14)    
    20. 주민등록번호발행분매출처수(6)    
    21. 주민등록번호발행분계산서매수(6)    
    22. 주민등록번호발행분매출(수입)금액양음수표시(1) : 매출금액이 양수인 경우 '0', 음수인 경우 '1'    
    23. 주민등록번호발행분매출(수입)금액    
    24. 공란(97)    
    ****************************************************************************************************************************/
    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)  
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'C'                --01. 레코드구분    
                                + '17'              --02. 자료구분    
                                + @TermKind_Bill    --03. 기구분
                                + @ProOrFix_Bill    --04. 신고구분
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. 세무서코드    
                                + '000001'          --06. 일련번호    
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))     --07. 사업자등록번호    
                                + SUBSTRING(@BillFrDate, 1, 4)      --08. 귀속년도    
                                + @BillFrDate                       --09. 거래기간시작년월일    
                                + @BillToDate                       --10. 거래기간종료년월일    
                                + @RptDate                          --11. 제출년월일    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.BizNo)), 6) --12. 매출처수합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ISNULL(SUM(Bill.BillCnt), 0)), 6)          --13. 계산서 매수합계    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END           --14. 매출(수입)금액합계음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14)      --15. 매출(수입)금액합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN 1            ELSE 0 END)), 6)    --16. 사업자등록번호발행분매출처수    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.BillCnt ELSE 0 END)), 6)    --17. 사업자등록번호발행분계산서매수    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --18. 사업자등록번호발행분매출(수입)금액음수표시    
                             + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt  ELSE 0 END)))), 14) --19. 사업자등록번호발행분매출(수입)금액    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN 1             ELSE 0 END)), 6)    --20. 주민등록번호발행분매출처수    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN Bill.BillCnt  ELSE 0 END)), 6)    --21. 주민등록번호발행분계산서매수    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   ELSE 0 END) >= 0 THEN '0' ELSE '1' END            --22. 주민등록번호발행분매출(수입)금액음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   ELSE 0 END)))), 14) --23. 주민등록번호발행분매출(수입)금액    
                                + SPACE(97)    
                                , 230  
                          FROM   #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                        ON Bill.CompanySeq  = ComInfo.CompanySeq  
                                                       AND Bill.TaxUnit     = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002  
                            AND Bill.IsEBill       <> '1'  -- 전자계산서 이외분
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo  
  
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서 외 매출처별거래명세레코드    
        
    01. 레코드구분(1) : D    
    02. 자료구분(2) : 17    
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 사업자등록번호(10)    
    08. 매출처사업자등록번호(10)    
    09. 매출처법인명(상호)(40)    
    10. 계산서 매수(5)    
    11. 매출(수입)금액음수표시(1)    
    12. 매출(수입)금액    
    13. 공란(136)    
    ****************************************************************************************************************************/    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'D'     --01. 레코드구분    
                                + '17'    --02. 자료구분    
                                + @TermKind_Bill  --03. 기구분
                                + @ProOrFix_Bill  --04. 신고구분
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) 
                                       ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END   --05. 세무서코드    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6) --06. 일련번호    
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-','')) --07. 사업자등록번호    
                                + CONVERT(VARCHAR(10), Bill.BizNo)  
                                      + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), Bill.BizNo))) --08. 매출처사업자등록번호    
                                + LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName) )))   
                                      + SPACE(40 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))))     --09. 거래자상호    
                                + RIGHT('00000' + CONVERT(VARCHAR(5), Bill.BillCnt), 5)                     --10. 계산서 매수    
                                + CASE WHEN Bill.Amt >= 0 THEN '0' ELSE '1' END                             --11. 매출(수입)금액음수표시    
                                + RIGHT('0000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(Bill.Amt))), 14)   --12. 매출(수입)금액    
                                + SPACE(136)    
 , 230  
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002       -- 매출
                            AND Bill.BizNo         <> ''            -- 사업자등록번호발행분
                            AND Bill.ISEBill       <> '1'           -- 전자계산서 이외분
                
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서분 제출의무자별 (매출)계산서 집계 1
        
    01. 레코드구분(1) : E    
    02. 자료구분(2) : 17 (매출)
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 제출의무자(사업자)사업자등록번호(10)
    08. 귀속년도(4)
    09. 거래기간시작월일(8)
    10. 거리시작종료월일(8)
    11. 작성일자(8)
    -- /*합계분*/
    12. 매출처수(6)
    13. 계산서매수(6)
    14. 매출(수입)금액 음수표시(1)
    15. 매출(수입)금액(14)
    -- /*사업자등록번호 발급분*/
    16. 매출처수(6)
    17. 계산서매수(6)
    18. 매출(수입)금액 음수표시(1)
    19. 매출(수입)금액(14)
    -- /*주민등록번호 발급분*/
    20. 매출처수(6)
    21. 계산서매수(6)
    22. 매출(수입)금액 음수표시(1)
    23. 매출(수입)금액(14)
    24. 공란(97)   
    ****************************************************************************************************************************/                    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099002)  
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'E'                --01. 레코드구분    
                                + '17'              --02. 자료구분    
                                + @TermKind_Bill    --03. 기구분  @cTermKind    
                                + @ProOrFix_Bill    --04. 신고구분  @cProOrFix    
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END --05. 세무서코드    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6)        --06. 일련번호                                          
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo, '-', ''))     --07. 사업자등록번호    
                                + SUBSTRING(@BillFrDate, 1, 4)   --08. 귀속년월    
                                + @BillFrDate                    --09. 거래기간시작년월일    
                                + @BillToDate                    --10. 거래기간종료년월일    
                                + @RptDate                       --11. 작성일자                                       
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.BizNo)), 6)                   --12. 매출처수합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ISNULL(SUM(Bill.BillCnt), 0)), 6)        --13. 계산서 매수합계    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                             --14. 매출(수입)금액합계음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14) --15. 매출(수입)금액합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN 1  
                                                                           ELSE 0 END)), 6)                         --16. 사업자등록번호발행분매출처수    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.BillCnt   
                                                                           ELSE 0 END)), 6)                         --17. 사업자등록번호발행분계산서매수    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt   
                                                                 ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --18. 사업자등록번호발행분매출(수입)금액음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo <> '' THEN Bill.Amt   
                                                                                              ELSE 0 END)))), 14)   --19. 사업자등록번호발행분매출(수입)금액    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN 1   
                                                                                ELSE 0 END)), 6)        --20. 주민등록번호발행분매출처수    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(CASE WHEN Bill.BizNo = '' THEN Bill.BillCnt   
                                                                                ELSE 0 END)), 6)        --21. 주민등록번호발행분계산서매수    
                                + CASE WHEN SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   
                                                     ELSE 0 END) >= 0 THEN '0' ELSE '1' END             --22. 주민등록번호발행분매출(수입)금액음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(CASE WHEN Bill.BizNo = '' THEN Bill.Amt   
                                                                                                   ELSE 0 END)))), 14) --23. 주민등록번호발행분매출(수입)금액    
                                + SPACE(97)                       --24 공란
                                , 230  
                          FROM   #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                        ON Bill.CompanySeq  = ComInfo.CompanySeq  
                                                       AND Bill.TaxUnit     = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099002       -- 매출
                            AND Bill.IsEBill        = '1'           -- 전자계산서 분
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit  
                END                          
            
            END--매출계산서 집계                 
                  
        
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서 외 제출의무자별집계레코드(매입)    
        
    01. 레코드구분(1) : C    
    02. 자료구분(2) : 18    
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 사업자등록번호(10)    
    08. 귀속년도(4)    
    09. 거래기간시작년월일(8)    
    10. 거래기간종료년월일(8)    
    11. 작성일자(8)    
    12. 매입처수합계(6)    
    13. 계산서매수합계(6)    
    14. 매입금액합계음표시(1)    
    15. 매입금액합계(14)    
    16. 공란(151)    
    ****************************************************************************************************************************/    
                 IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)    
                 BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'C'     --01. 레코드구분    
                                + '18'    --02. 자료구분    
                                + @TermKind_Bill  --03. 기구분
                                + @ProOrFix_Bill  --04. 신고구분
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. 세무서코드    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER(ORDER BY Bill.TaxUnit)), 6)    --06. 일련번호                                            
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))                                   --07. 사업자등록번호    
                                + SUBSTRING(@BillFrDate, 1, 4)  --08. 귀속년월    
                                + @BillFrDate                   --09. 거래기간시작년월일    
                                + @BillToDate                   --10. 거래기간종료년월일    
                                + @RptDate                      --11. 작성일자    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.CustSeq)), 6)     --12. 매입처수합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(Bill.BillCnt)), 6)       --13. 계산서 매수합계    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                 --14. 매입금액합계음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14)     --15. 매입금액합계    
                                + SPACE(151)    
                                , 230    
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                         WHERE Bill.CompanySeq  = @CompanySeq  
                           AND Bill.TaxTermSeq  = @TaxTermSeq  
                           AND Bill.TaxUnit     = @TaxUnit
                           AND Bill.SMBuyOrSale = 4099001       -- 매입
                           AND Bill.BizNo      <> ''            -- 사업자등록번호발행분                           
                           AND Bill.ISEBill    <> '1'           -- 전자계산서 외
                          GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit  
        
        
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서 외 매입처별거래명세레코드    
        
    01. 레코드구분(1) : D    
    02. 자료구분(2) : 18    
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 사업자등록번호(10)    
    08. 매입처사업자등록번호(10)    
    09. 매입처법인명(상호)(40)    
    10. 계산서 매수(5)    
    11. 매입금액음수표시(1)    
    12. 매입금액    
    13. 공란(136)    
    ****************************************************************************************************************************/    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'D'     --01. 레코드구분    
                                + '18'    --02. 자료구분    
                                + @TermKind_Bill  --03. 기구분
                                + @ProOrFix_Bill  --04. 신고구분
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE CONVERT(VARCHAR(3), ComInfo.TaxOfficeNo) END --05. 세무서코드    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Bill.TaxUnit)), 6)   --06. 일련번호                                          
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-','')) 
                                  + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))))         --07. 사업자등록번호
                                + CONVERT(VARCHAR(10), Bill.BizNo)
                                  + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), Bill.BizNo)) )          --08. 매입처사업자등록번호
                                + CASE WHEN Bill.CustSeq = 0 THEN SPACE(40)
                                       ELSE LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))   
                                            + SPACE(40 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(40), RTRIM(Bill.CustName))))))
                                  END                                                                       --09. 매입처법인명(상호)    
                                + RIGHT('00000' + CONVERT(VARCHAR(5), Bill.BillCnt), 5)                     --10. 계산서 매수    
                                + CASE WHEN Bill.Amt >= 0 THEN '0' ELSE '1' END                             --11. 매입금액음수표시    
                                + RIGHT('0000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(Bill.Amt))), 14)   --12. 매입금액    
                                + SPACE(136)    
                                , 230    
                          FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK) 
                                                       ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                      AND Bill.TaxUnit       = ComInfo.TaxUnit  
                          WHERE Bill.CompanySeq     = @CompanySeq  
                            AND Bill.TaxTermSeq     = @TaxTermSeq  
                            AND Bill.TaxUnit        = @TaxUnit  
                            AND Bill.SMBuyOrSale    = 4099001           -- 매입분
                            AND Bill.BizNo         <> ''                -- 사업자등록번호발행분                            
                            AND Bill.ISEBill       <> '1'               -- 전자계산서 외
 
    /***************************************************************************************************************************    
    계산서 합계표 - 전자계산서분 제출의무자별 (매입)계산서 집계 2
        
    01. 레코드구분(1) : E    
    02. 자료구분(2) : 18  (매입)    
    03. 기구분(1) : 1기이면 '1', 2기이면 '2'    
    04. 신고구분(1) : 예정이면 '1', 확정이면 '2'    
    05. 세무서(3)    
    06. 일련번호(6)    
    07. 제출의무자(사업자)사업자등록번호(10)
    08. 귀속년도
    09. 거래기간시작월일
    10. 거리시작종료월일
    11. 작성일자
    -- /*합계분*/
    12. 매입처수
    13. 계산서매수
    14. 매입금액 음수표시
    15. 매입금액
    16. 공란(151)   
    ****************************************************************************************************************************/  
                    IF EXISTS (SELECT 1 FROM #TTAXBillSum2 WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit AND SMBuyOrSale = 4099001)    
                    BEGIN    
                          INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                          SELECT 'E'              --01. 레코드구분    
                                + '18'            --02. 자료구분    
                                + @TermKind_Bill  --03. 기구분
                                + @ProOrFix_Bill  --04. 신고구분
                                + CASE WHEN ISNULL(ComInfo.TaxOfficeNo, '') = '' THEN SPACE(3) ELSE ComInfo.TaxOfficeNo END  --05. 세무서코드    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), ROW_NUMBER() OVER (ORDER BY Bill.TaxUnit)), 6) --06. 일련번호   
                                + CONVERT(VARCHAR(10), REPLACE(ComInfo.TaxNo,'-',''))               --07. 사업자등록번호    
                                + SUBSTRING(@BillFrDate, 1, 4)   --08. 귀속년월    
                                + @BillFrDate                    --09. 거래기간시작년월일    
                                + @BillToDate                    --10. 거래기간종료년월일    
                                + @RptDate                       --11. 작성일자    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), COUNT(Bill.CustSeq)), 6)     --12. 매입처수합계    
                                + RIGHT('000000' + CONVERT(VARCHAR(6), SUM(Bill.BillCnt)), 6)       --13. 계산서 매수합계    
                                + CASE WHEN SUM(Bill.Amt) > 0 THEN '0' ELSE '1' END                 --14. 매입금액합계음수표시    
                                + RIGHT('00000000000000' + CONVERT(VARCHAR(14), ABS(FLOOR(SUM(Bill.Amt)))), 14) --15. 매입금액합계    
                                + SPACE(151)    
                                , 230    
                            FROM #TTAXBillSum2 AS Bill JOIN #TDATaxUnit AS ComInfo WITH(NOLOCK)
                                                      ON Bill.CompanySeq    = ComInfo.CompanySeq  
                                                     AND Bill.TaxUnit       = ComInfo.TaxUnit  
                           WHERE Bill.CompanySeq  = @CompanySeq  
                             AND Bill.TaxTermSeq  = @TaxTermSeq  
                             AND Bill.TaxUnit     = @TaxUnit
                             AND Bill.SMBuyOrSale = 4099001     -- 매입
                             AND Bill.BizNo      <> ''          -- 사업자등록번호발행분
                             AND Bill.ISEBill     = '1'         -- 전자계산서
                           GROUP BY ComInfo.TaxOfficeNo, ComInfo.TaxNo, Bill.TaxUnit
                    END                   
            END--매입계산서 집계    
    END--계산서 집계    
END    
/***************************************************************************************************************************    
수출실적명세서 A레코드    
    
01. 자료구분_표지(1) : A    
02. 귀속년월(6)    
03. 신고구분(1)    
04. 사업자등록번호(10)    
05. 법인명(30)    
06. 대표자명(15)    
07. 사업장소재지(45)    
08. 업태명(17)    
09. 종목명(25)    
10. 거래기간(16)    
11. 작성일자(8)    
12. 공란(6)    
****************************************************************************************************************************/    
    -- 1순위 기타영세율 집계테이블 (_TTAXExpSalesSumEtc) by shkim1 2017.06 신규 추가
    -- 2순위 환경설정 4735 설정 : 0
    -- 3순위 외화획득명세서 기타분
    -- 4순위 기타영세율 증빙
DECLARE @EtcCnt         INT,  
        @EtcForAmt      DECIMAL(19,5),
        @EtcKorAmt      DECIMAL(19,5)
    IF EXISTS (SELECT TOP 1 1 FROM _TTAXExpSalesSumEtc WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND TaxTermSeq = @TaxTermSeq)
    BEGIN
        SELECT @EtcCnt    = ISNULL(EtcCnt       , 0),
               @EtcForAmt = ISNULL(EtcForAmt    , 0),
               @EtcKorAmt = ISNULL(EtcKorAmt    , 0)
          FROM _TTAXExpSalesSumEtc AS A WITH(NOLOCK)
         WHERE CompanySeq = @CompanySeq
           AND TaxTermseq = @TaxTermSeq
           AND TaxUnit    = @TaxUnit
    END
    ELSE IF @Env4735 = '1'  -- [환경설정4735] 수출실적명세서 금액을 외화획득명세서 금액으로 자동집계 안함
    BEGIN
        SELECT @EtcCnt      = 0,
               @EtcForAmt   = 0,
               @EtcKorAmt   = 0
    END    
    ELSE IF EXISTS ( SELECT 1 FROM _TTaxForAmtReceiptList WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxUnit = @TaxUnit AND TaxTermSeq = @TaxTermSeq AND SMComboKind = 4116003 AND @Env4735 <> '1')
    BEGIN
        --외화획득명세서에서 수동으로 값을 입력하는 경우, 해당 데이터를 기준으로 기타영세율 금액을 계산하도록 한다.
        -- (이전방식)
        SELECT  @EtcCnt         = COUNT(*),
                @EtcForAmt      = SUM(ISNULL(A.ForSupplyAmt,0)),
                @EtcKorAmt      = SUM(A.SupplyAmt)
          FROM _TTaxForAmtReceiptList AS A WITH(NOLOCK)
         WHERE A.CompanySeq   = @CompanySeq
           AND A.TaxTermseq   = @TaxTermSeq
           AND A.TaxUnit      = @TaxUnit   
           AND A.SMComboKind = 4116003      --기타인것만
    END
    ELSE        -- 기타영세율 증빙 기준
    BEGIN  
        -- 기타영세율 건수, 외화, 원화  
        -- 제뉴인 환경설정 4727 / _TTAXUpload 미사용
        SELECT  @EtcCnt         = COUNT(*),  
                @EtcForAmt      = SUM(ISNULL(CONVERT(MONEY, R.RemValText), 0)) ,
                @EtcKorAmt      = SUM(A.SupplyAmt)  
          FROM _TTAXSlipSum AS A WITH(NOLOCK)
                                 JOIN _TDAEvid AS B WITH(NOLOCK)
                                   ON B.CompanySeq  = A.CompanySeq 
                                  AND B.EvidSeq     = A.EvidSeq   
                                  AND B.IsVATRpt    = '1'       -- 부가세신고  
                                  AND B.SMTaxKind   = 4114004   -- 기타영세율
                                  AND B.SMEvidKind <> 4115001   -- 세금계산서 X
                             AND B.IsNDVAT    <> '1'       -- 불공제     X
                                  AND B.IsAsstBuy  <> '1'       -- 고정자산매입분 X
                                 JOIN _TDAAccount AS C WITH(NOLOCK) 
                                   ON C.CompanySeq  = A.CompanySeq
                                  AND C.AccSeq      = A.AccSeq
                                  AND C.SMAccKind   = 4018002   --부채계정(부가세예수금)
                      LEFT OUTER JOIN _TACSlipRem AS R WITH(NOLOCK)
                                   ON R.CompanySeq  = A.CompanySeq      
                                  AND R.SlipSeq     = A.SlipSeq        
                                  AND R.RemSeq      = 3113 
         WHERE A.CompanySeq     = @CompanySeq  
           AND A.TaxTermSeq     = @TaxTermSeq  
           AND A.TaxUnit        = @TaxUnit  
   END
   
    SELECT @EtcCnt      = ISNULL(@EtcCnt        , 0),  
           @EtcForAmt   = ISNULL(@EtcForAmt     , 0),  
           @EtcKorAmt   = ISNULL(@EtcKorAmt     , 0)  
             
IF @WorkingTag IN ('', 'A')  
BEGIN  
    IF ISNULL(@EtcCnt, 0) <> 0 OR EXISTS (SELECT 1 FROM _TSLExpSalesSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
    BEGIN  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'A'       --01. 자료구분    
                   + LEFT(@TaxToDate, 6)    --02.귀속년월    
                   + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1개월, 2:2개월, 3:3개월, 4:4~6개월    
                          WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                      END                                   --03. 신고구분
                   + REPLACE(RTRIM(A.TaxNo), '-', '')       --04. 사업자등록번호    
                   + CONVERT(VARCHAR(30), LTRIM(RTRIM(CASE WHEN ISNULL(A.BillTaxName,'') <> '' THEN A.BillTaxName ELSE A.TaxName END )))    
                             + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(CASE WHEN ISNULL(A.BillTaxName,'') <> '' THEN A.BillTaxName ELSE A.TaxName END )))))  --05. 상호    
                   + CONVERT(VARCHAR(15), LTRIM(RTRIM(A.Owner))) + SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), LTRIM(RTRIM(A.Owner)))))              --06. 대표자    
                   + CONVERT(VARCHAR(45), LTRIM(RTRIM(A.VATRptAddr))) + SPACE(45 - DATALENGTH(CONVERT(VARCHAR(45), LTRIM(RTRIM(A.VATRptAddr)))))    --07. 사업장소재지    
                   + CONVERT(VARCHAR(17), LTRIM(RTRIM(A.BizType   ))) + SPACE(17 - DATALENGTH(CONVERT(VARCHAR(17), LTRIM(RTRIM(A.BizType   )))))    --08. 업태명    
                   + CONVERT(VARCHAR(24), LTRIM(RTRIM(A.BizItem   ))) + SPACE(25 - DATALENGTH(CONVERT(VARCHAR(24), LTRIM(RTRIM(A.BizItem   )))))    --09. 종목명    
                   + @TaxFrDate + @TaxToDate                --10. 거래기간    
                   + @RptDate                               --11. 작성일자    
                   + SPACE(6)    
                   , 180    
            FROM #TDATaxUnit A WITH(NOLOCK)
            WHERE A.CompanySeq  = @CompanySeq  
              AND A.TaxUnit     = @TaxUnit  
  
    /***************************************************************************************************************************    
    수출실적명세서 B레코드    
        
    01. 자료구분_합계(1) : B    
    02. 귀속년월(6)    
    03. 신고구분(1)    
    04. 사업자등록번호(10)    
    05. 건수합계(7)    
    06. 외화금액합계(15, 2) : Multi-Key+실수점검   
    07. 원화금액합계(15) : Multi-Key+실수점검   
    08. 건수_재화(7)    
    09. 외화금액합계_재화(15, 2) : Multi-Key+실수점검   
    10. 원화금액합계_재화(15) : Multi-Key+실수점검   
    11. 건수_기타(7)    
    12. 외화금액합계_기타(15, 2) : Multi-Key+실수점검   
    13. 원화금액합계_기타(15) : Multi-Key+실수점검   
    14. 공란(51)    
    ****************************************************************************************************************************/    
  
             CREATE TABLE #ExpSalesSum (  
                SourceRefNo         NVARCHAR(30),  
                ExpDate             NCHAR(8),  
                CurrSeq             INT,  
                ExRate              DECIMAL(19,5),  
                CurAmt              DECIMAL(19,5),  
                DomAmt              DECIMAL(19,5),  
                SMSalesType         INT)  
  
             INSERT INTO #ExpSalesSum ( SourceRefNo, ExpDate, CurrSeq, ExRate, CurAmt, DomAmt, SMSalesType)  
                SELECT A.SourceRefNo, A.ExpDate, A.CurrSeq,   
                       CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE ROUND(A.ExRate / B.BasicAmt, 5) END AS ExRate,
                       SUM(ROUND(A.CurAmt,2)), SUM(A.DomAmt),   
                       CASE WHEN ISNULL(A.SMSalesType, 0) = 0 THEN 4116001 ELSE SMSalesType END  
                  FROM _TSLExpSalesSum AS A WITH(NOLOCK) 
                                            JOIN _TDACurr AS B WITH(NOLOCK) 
                                              ON A.CompanySeq   = B.CompanySeq  
                                             AND A.CurrSeq      = B.CurrSeq  
                 WHERE A.CompanySeq   = @CompanySeq  
                   AND A.TaxTermSeq   = @TaxTermSeq  
                   AND A.TaxUnit      = @TaxUnit  
                 GROUP BY A.SourceRefNo, A.ExpDate, A.CurrSeq, A.SMSalesType,   
                          CASE WHEN ISNULL(B.BasicAmt, 0) = 0 THEN A.ExRate ELSE ROUND(A.ExRate / B.BasicAmt, 5) END
  
             SELECT @T_Cnt = COUNT(*), @T_CurAmt = ROUND(SUM(CurAmt), 2), @T_DomAmt = SUM(DomAmt)   --------------- 전체  
               FROM #ExpSalesSum   
              WHERE SMSalesType    IN (4116001, 4116002) -- 재화/기타  
  
             SELECT @A_Cnt = COUNT(*), @A_CurAmt = ROUND(SUM(CurAmt), 2), @A_DomAmt = SUM(DomAmt)   --------------- 재화  
               FROM #ExpSalesSum   
              WHERE SMSalesType     = 4116001 -- 재화  
  
    --         SELECT @B_Cnt = COUNT(*), @B_CurAmt = SUM(CurAmt), @B_DomAmt = SUM(DomAmt)   --------------- 기타  
    --           FROM #ExpSalesSum   
    --          WHERE SMSalesType     = 4116003 -- 기타  
  
            -- 아래와 같이 수정함 : 출력물의 기타영세율과 동일한 로직으로 기타영세율 집계  
            SELECT @B_Cnt = ISNULL(@EtcCnt, 0), @B_CurAmt = ROUND(ISNULL(@EtcForAmt, 0), 2), @B_DomAmt = ISNULL(@EtcKorAmt, 0)  
  
  
            SELECT @T_Cnt = ISNULL(@T_Cnt, 0), @T_CurAmt = ISNULL(@T_CurAmt, 0), @T_DomAmt = ISNULL(@T_DomAmt, 0),  
                   @A_Cnt = ISNULL(@A_Cnt, 0), @A_CurAmt = ISNULL(@A_CurAmt, 0), @A_DomAmt = ISNULL(@A_DomAmt, 0),  
                   @B_Cnt = ISNULL(@B_Cnt, 0), @B_CurAmt = ISNULL(@B_CurAmt, 0), @B_DomAmt = ISNULL(@B_DomAmt, 0)  
  
             INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
             SELECT 'B'       --01. 자료구분    
                   + LEFT(@TaxToDate, 6)    --02.귀속년월    
                   + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1개월, 2:2개월, 3:3개월, 4:4~6개월    
                          WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                     END                                -- 03. 신고구분     
                   + REPLACE(RTRIM(@TaxNo), '-', '')    -- 04. 사업자등록번호
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @T_Cnt + @B_Cnt), 7) --05. 건수합계    
                   + CASE WHEN @T_CurAmt + @B_CurAmt >= 0 THEN  
                                RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(DECIMAL(19,2), @T_CurAmt + @B_CurAmt)), '.', ''), 15)  
                          ELSE   
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@T_CurAmt + @B_CurAmt))), '.', ''), 15), 15, 1, 'R')   
                            END    
                      END                            --06. 외화금액합계    
                   + CASE WHEN @T_DomAmt + @B_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@T_DomAmt + @B_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@T_DomAmt + @B_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@T_DomAmt + @B_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --07. 원화금액합계    
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @A_Cnt), 7)        --08. 건수_재화    
                   + CASE WHEN @A_CurAmt >= 0 THEN    
                            RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), @A_CurAmt)), '.', ''), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                   WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@A_CurAmt))), '.', ''), 15), 15, 1, 'R')    
                            END    
                      END                            --09. 외화금액합계_재화    
                   + CASE WHEN @A_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@A_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@A_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@A_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --10. 원화금액합계_재화    
                   + RIGHT('0000000' + CONVERT(VARCHAR(7), @B_Cnt), 7)        --11. 건수_기타    
                   + CASE WHEN @B_CurAmt >= 0 THEN    
                            RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), @B_CurAmt)), '.', ''), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(@B_CurAmt))), '.', ''), 15), 15, 1, 'R')    
                            END    
                      END                            --12. 외화금액합계_기타    
                   + CASE WHEN @B_DomAmt >= 0 THEN    
                            RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(@B_DomAmt)), 15)    
                      ELSE    
                            CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(@B_DomAmt)), 1)    
                                 WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, '}')    
                                 WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'J')    
                                 WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'K')    
                                 WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'L')    
                                 WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'M')    
                                 WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'N')    
                                 WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'O')    
                                 WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'P')    
                                 WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'Q')    
                                 WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(@B_DomAmt))), 15), 15, 1, 'R')    
                            END    
                      END                            --13 원화금액합계_기타    
                   + SPACE(51)    
                   , 180    
        
    /***************************************************************************************************************************    
    수출실적명세서 C레코드    
        
    01. 자료구분_자료(1) : C    
    02. 귀속년월(6)    
    03. 신고구분(1)    
    04. 사업자등록번호(10)    
    05. 수출일련번호(7)    
    06. 수출신고번호(15)    
    07. 선적일자(8)    
    08. 수출통화코드(3)    
    09. 환율(9, 4)    
    10. 외화금액(15, 2)    
    11. 원화금액(15)    
    12. 공란(90)    
    ****************************************************************************************************************************/    
  
                 INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
                 SELECT 'C'       --01. 자료구분    
                       + LEFT(@TaxToDate, 6)    --02.귀속년월    
                       + CASE WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <  3 THEN CONVERT(VARCHAR(1), DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) + 1) -- 1:1개월, 2:2개월, 3:3개월, 4:4~6개월    
                              WHEN DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) >= 3 OR DATEDIFF(MONTH, @TaxFrDate, @TaxToDate) <= 6 THEN '4'    
                          END                           --03. 신고구분
                       + REPLACE(@TaxNo, '-', '')       --04. 사업자번호
                       + RIGHT('0000000' + CONVERT(VARCHAR(7), ROW_NUMBER() OVER (ORDER BY A.SourceRefNo)), 7)  
                       + CONVERT(VARCHAR(15), REPLACE(RTRIM(A.SourceRefNo), '-', '')) + SPACE(15 - DATALENGTH(CONVERT(VARCHAR(15), REPLACE(RTRIM(A.SourceRefNo), '-', '')))) --06. 수출신고번호    
                       + CASE WHEN A.ExpDate = '' THEN SPACE(8) ELSE A.ExpDate END              --07. 선적일자    
                       + CASE A.CurrSeq WHEN @StkCurrSeq THEN @KorCurrNo ELSE B.CurrName END    --08. 수출통화코드
                       + RIGHT('000000000' + REPLACE(CONVERT(VARCHAR(9), CONVERT(NUMERIC(19, 4), A.ExRate)), '.', ''), 9) --09. 환율    
                       + CASE WHEN A.CurAmt >= 0 THEN    
                                RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), A.CurAmt)), '.', ''), 15)    
                          ELSE    
                                CASE RIGHT(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), 1)    
                                     WHEN '0' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, '}')    
                                     WHEN '1' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'J')    
                                     WHEN '2' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'K')    
                                     WHEN '3' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'L')    
                                     WHEN '4' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'M')    
                                     WHEN '5' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'N')    
                                     WHEN '6' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'O')    
                                     WHEN '7' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'P')    
                                     WHEN '8' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'Q')    
                                     WHEN '9' THEN STUFF(RIGHT('000000000000000' + REPLACE(CONVERT(VARCHAR(15), CONVERT(NUMERIC(19, 2), ABS(A.CurAmt))), '.', ''), 15), 15, 1, 'R')    
                                END    
                          END                      --10. 외화금액합계    
                       + CASE WHEN A.DomAmt >= 0 THEN    
                                RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(A.DomAmt)), 15)    
                          ELSE    
                                CASE RIGHT(CONVERT(VARCHAR(15), FLOOR(A.DomAmt)), 1)    
                                     WHEN '0' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, '}')    
                                     WHEN '1' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'J')    
                                     WHEN '2' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'K')    
                                     WHEN '3' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'L')    
                                     WHEN '4' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'M')    
                                     WHEN '5' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'N')    
                                     WHEN '6' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'O')    
                                     WHEN '7' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'P')    
                                     WHEN '8' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'Q')    
                                     WHEN '9' THEN STUFF(RIGHT('000000000000000' + CONVERT(VARCHAR(15), ABS(FLOOR(A.DomAmt))), 15), 15, 1, 'R')    
                                END    
                          END                      --11. 원화금액합계    
                       + SPACE(90)    
                       , 180  
                 FROM  #ExpSalesSum  AS A LEFT OUTER JOIN _TDACurr AS B WITH(NOLOCK)
                                            ON B.CompanySeq = @CompanySeq  
                                           AND A.CurrSeq    = B.CurrSeq  
                WHERE A.SMSalesType = 4116001   
    END  
END  
  
  

/***************************************************************************************************************************    
신용카드매출전표등수취명세서_Header        SATCardDisket도 같이 수정해야함    
    
01. 레코드구분(2) : HL    
02. 귀속년도(4)    
03. 반기구분(1) : '1' 1기, '2' 2기    
04. 반기내월순번(1) : 1,2,3,4,5,6    단, 예정신고는 '3', 확정신고는 '6'    
05. 수쉬자(제출자)사업자등록번호(10)    
06. 상호(법인명)(60)    
07. 성명(대표자)(30)    
08. 법인등록번호(13)    
09. 제출일자(8)    
10. 공란(11)    
****************************************************************************************************************************/    
----------------------------------------------------------------------------------------    
-- 20080123 by Him    
-- ////4. 사업용 신용카드에 의한 매입세액공제 간소화(2007.2기 확정신고부터)    
-- //// ▶ 개인사업자가 사업용 신용카드를 현금영수증 홈페이지에 등록하고 사용하면 사업과 관련하여 신용카드로 결제분에 대한 매입세액 공제를 위한 
-- //// ▶ “신용카드매출전표 등 수취명세서” 작성시 거래처별 명세를 작성하지 아니하고 전체 공제대상금액만을 기재하여 신고    
-- //// ▶  법인명의로 신용카드를 발급받은 법인사업자는 별도의 등록절차 없이 적용    
-- //// ▶  신고방법 : 현금영수증 홈페이지에서 신용카드 사용내역을 조회하여 공제 및 불공제를  선택한 후 공제받을 금액의 합계액을 
-- //// ▶  "신용카드 매출전표 등 수취명세서" ⑦화물운전자 복지카드란에 기재하여 신고함(서식 추후 개정예정)    
-- //// → 신고기간 별 거래건수 1,000건 이상자는 관할세무서 법인세과에서 확인하여야 함    
    
-- 20080407 by kspark    
-- ////5. 신용카드매출전표 등 수취명세서 서식 변경(규칙 제13호 서식, 입법예고 중)    
-- //// ▶ 신용카드 등 매입내역 수취명세서 작성대상에 4.사업용신용카드 추가    
-- //// ▶ 2008년 1기 예정신고하는 분부터 적용    
  
    SELECT @SaleCnt = ISNULl(SaleCnt    , 0),  
           @SupAmt  = ISNULL(SupAmt     , 0),  
           @TaxAmt  = ISNULL(TaxAmt     , 0)  
      FROM _TTAXGetCardList WITH(NOLOCK)
     WHERE CompanySeq   = @CompanySeq  
       AND TaxTermSeq   = @TaxTermSeq  
       AND TaxUnit      = @TaxUnit  
  
    SELECT @SaleCnt = ISNULL(@SaleCnt   , 0),  
           @SupAmt  = ISNULL(@SupAmt    , 0),  
           @TaxAmt  = ISNULL(@TaxAmt    , 0)  
  
----------------------------------------------------------------------------------------    
IF @WorkingTag IN ('','J')  
BEGIN  
    -- 내역이 있을때만 신고 데이터 생성    
    IF EXISTS (SELECT 1 FROM _TTAXReceiptCardSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        OR (ISNULL(@SaleCnt, 0) > 0)   -- 신용카드 내역외 화물운송복지카드    
    BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'HL'                                 --01.레코드구분    
                    + SUBSTRING(@TaxFrDate, 1, 4)       --02. 귀속년도    
                    + @TermKind                         --03.반기구분    
                    + @YearHalfMM                       --04.반기내월순번    
                    + CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(TaxNo, '-', '')))) --05.수취자(제출자)사업자등록번호    
                    + CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END)))  
                              + SPACE(60 - DATALENGTH(CONVERT(VARCHAR(60), LTRIM(RTRIM(CASE WHEN ISNULL(BillTaxName,'') <> '' THEN BillTaxName ELSE TaxName END)))))   --06.상호(법인명)    
                    + CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner))) + SPACE(30 - DATALENGTH(CONVERT(VARCHAR(30), LTRIM(RTRIM(Owner)))))     --07.성명(대표자)    
                    + LTRIM(RTRIM(@CompanyNo)) + SPACE(13 - DATALENGTH(LTRIM(RTRIM(@CompanyNo))))                                       --08.법인등록번호    
                    + LTRIM(RTRIM(CONVERT(VARCHAR(8), @RptDate))) + SPACE(8 - DATALENGTH(LTRIM(RTRIM(CONVERT(VARCHAR(8), @RptDate)))))  --09.제출일자    
                    + SPACE(11)                                                                                                         --10.공란    
                    , 140  
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq   = @CompanySeq  
               AND TaxUnit      = @TaxUnit  
        
    /***************************************************************************************************************************    
    신용,직불카드 및 기명식 선불카드 매출전표 수취명세    SATCardDisket도 같이 수정해야함    
        
    01. 레코드구분(2) : DL    
    02. 귀속년도(4)    
    03. 반기구분(1) : '1' 1기, '2' 2기    
    04. 반기내월순번(1) : 1,2,3,4,5,6    단, 예정신고는 '3', 확정신고는 '6'    
    05. 수취자(제출자)사업자등록번호(10)    
    06. 카드구분(1)    *** 신용카드 및 직불카드 = '1' , 현금영수증 = '2' , 화물운송복지카드 = '3' , 사업용신용카드 = '4'    
    07. 카드회원번호(20)    
    08. 공급자 사업자등록번호(10)    
    09. 거래건수(9)    *** 카드구분 '1' = 귀속기간내 같은 신용카드 및 직불카등의 카드번호로 같은 공급자와 거래한 거래건수를 카드번호별,공급자사업자등록번호 별 기재    
                           카드구분 '2' = 현금영수증으로 거래한 전체 거래 건수를 기재    
                           카드구분 '3' = 화물운송복지카드로 거래한 전체거래건수를 기재    
                           카드구분 '4' = 사업용신용카드로 거래한 전체거래건수를 기재    
        
    10. 공급가액_음수표시(1)    
    11. 공급가액(13)    
    12. 세액_음수표시(1)    
    13. 세액(13)    
    14. 공란(54)    
    ****************************************************************************************************************************/    
    -- 신용카드 내역    
        DECLARE @DLCnt INT    -- TL의 DL 레코드 수 06. DATA건수    
  
    ------------------------------------
    -- 제외건수처리
    ------------------------------------
    DECLARE @MinusCashCnt   INT,
            @MinusBizCnt    INT,
            @MinusCardCnt   INT,
            @MinusEntryCnt  INT
    -- 수취 명세 제외건수 (거래처별, 카드별 집계)
    CREATE TABLE #CardMinus(
        CustSeq     INT,
        CardSeq     INT,
        MinusCnt    INT
    )
    SELECT @MinusCardCnt  = SUM( CASE WHEN SMCardType = 4590001 THEN MinusCnt ELSE 0 END ), -- 신용카드 및 직불카드
           @MinusCashCnt  = SUM( CASE WHEN SMCardType = 4590002 THEN MinusCnt ELSE 0 END ), -- 현금영수증
           @MinusEntryCnt = SUM( CASE WHEN SMCardType = 4590003 THEN MinusCnt ELSE 0 END ), -- 화물운송복지카드
           @MinusBizCnt   = SUM( CASE WHEN SMCardType = 4590004 THEN MinusCnt ELSE 0 END )  -- 사업용신용카드
      FROM _TTAXCardMinusCnt AS A WITH(NOLOCK)
     WHERE A.CompanySeq = @CompanySeq
       AND A.TaxUnit    = @TaxUnit
       AND A.TaxTermSeq = @TaxTermSeq
    SELECT @MinusCardCnt  = ISNULL(@MinusCardCnt  , 0),
           @MinusCashCnt  = ISNULL(@MinusCashCnt  , 0),
           @MinusEntryCnt = ISNULL(@MinusEntryCnt , 0),
           @MinusBizCnt   = ISNULL(@MinusBizCnt   , 0)
    INSERT INTO #CardMinus(CustSeq, CardSeq, MinusCnt)
    SELECT CustSeq, CardSeq, SUM(MinusCnt)
      FROM _TTAXCardMinusCnt AS A WITH(NOLOCK)
     WHERE A.CompanySeq = @CompanySeq
       AND A.TaxUnit    = @TaxUnit
       AND A.TaxTermSeq = @TaxTermSeq
       AND A.SMCardType = 4590001       -- 신용카드 및 직불카드
     GROUP BY CustSeq, CardSeq
    ------------------------------------
    -- 제외건수처리 END
    ------------------------------------
    ------------------------------------------
    -- 카드구분 : 신용카드 및 직불카드(1)
    ------------------------------------------
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
        SELECT 'DL'                                     --01.레코드구분    
                + SUBSTRING(@TaxFrDate, 1, 4)           --02.귀속년도    
                + @TermKind                             --03.반기구분    
                + @YearHalfMM                           --04.반기내월순번    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(T.TaxNo, '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(T.TaxNo, '-', '')))))) --05.수취자(제출자)사업자등록번호    
                + '1'                                   -- 06.카드구분 (신용카드 및 직불카드)
                + CONVERT(VARCHAR(20), LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(A.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq), '-', '')))) + SPACE(20 - DATALENGTH(CONVERT(VARCHAR(20), LTRIM(RTRIM(REPLACE(dbo._FCOMDecrypt(A.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq), '-', ''))))))   --07. 카드회원번호    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(C.BizNo , '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(C.BizNo , '-', ''))))))   --08. 공급자(가맹점) 사업자등록번호    
                + RIGHT('000000000' + CONVERT(VARCHAR(9), (COUNT(A.SlipSeq) - ISNULL(M.MinusCnt, 0)) ), 9)   --09.거래건수    
                + CASE WHEN SUM( A.SupplyAmt  ) >= 0 THEN ' ' ELSE '-' END                                   --10.공급가액 음수표시(양수 Space/음수 -)    
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.SupplyAmt )))), 13)          --11.공급가액    
                + CASE WHEN SUM( A.VATAmt     ) >= 0 THEN ' ' ELSE '-' END                                   --12.세액 음수표시    (양수 Space/음수 -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.VATAmt    )))), 13)          --13.세액    
                + SPACE(54)    
                , 140    
          FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
                        JOIN _TDACust    AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.CustSeq = C.CustSeq  
                        JOIN #TDATaxUnit AS T WITH(NOLOCK) ON A.CompanySeq = T.CompanySeq AND A.TaxUnit = T.TaxUnit  
                   LEFT JOIN #CardMinus  AS M              ON A.CardSeq    = M.CardSeq    AND A.CustSeq = M.CustSeq
         WHERE A.CompanySeq  = @CompanySeq  
           AND A.TaxTermSeq  = @TaxTermSeq  
           AND A.TaxUnit     = @TaxUnit  
           AND A.IsCard      = '1'  
         GROUP BY A.IsCard, T.TaxNo, A.CardNo, C.BizNo, ISNULL(M.MinusCnt, 0)  
         ORDER BY A.IsCard, T.TaxNo, A.CardNo, C.BizNo  

        -- TL의 DL 레코드 수 06. DATA건수    
        SELECT @DLCnt = isnull(COUNT(*),0)
            FROM ( SELECT Card.IsCard, dbo._FCOMDecrypt(Card.CardNo, '_TTAXReceiptCardSum', 'CardNo', @CompanySeq) AS CardNo, Cust.BizNo    
                 FROM _TTAXReceiptCardSum AS Card WITH(NOLOCK)
                                               JOIN _TDACust AS Cust WITH(NOLOCK)
                                                 ON Card.CompanySeq = Cust.CompanySeq  
                                                AND Card.CustSeq    = Cust.CustSeq  
                WHERE Card.CompanySeq   = @CompanySeq  
                  AND Card.TaxTermSeq   = @TaxTermSeq  
                  AND Card.TaxUnit      = @TaxUnit  
                  AND Card.IsCard       = '1' -- 신용카드 내역   
                GROUP BY Card.IsCard, Card.CardNo , Cust.BizNo) AS A  
                
        
    ------------------------------------------
    -- 카드구분 : 현금영수증(2)
    ------------------------------------------
        INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
        SELECT 'DL'                                 --01.레코드구분    
                + SUBSTRING(@TaxFrDate, 1, 4)       --02.귀속년도    
                + @TermKind                         --03.반기구분    
                + @YearHalfMM                       --04.반기내월순번    
                + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(B.TaxNo, '-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(B.TaxNo, '-', '')))))) --05.수취자(제출자)사업자등록번호
                + '2'                               --06.카드구분 (현금영수증)
                + SPACE(20)                         --07.카드회원번호    
                + SPACE(10)                         --08.공급자(가맹점) 사업자등록번호    
                + RIGHT('000000000' + CONVERT(VARCHAR(9), COUNT(A.SlipSeq) - @MinusCashCnt), 9)      --09.거래건수    
                + CASE WHEN SUM( A.SupplyAmt ) >= 0 THEN ' ' ELSE '-' END                            --10.공급가액 음수표시(양수 Space/음수 -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.SupplyAmt )))), 13)  --11.공급가액
                + CASE WHEN SUM( A.VATAmt    ) >= 0 THEN ' ' ELSE '-' END                            --12.세액 음수표시    (양수 Space/음수 -)
                + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(SUM( A.VATAmt    )))), 13)  --13.세액
                + SPACE(54)
                , 140    
          FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
                        JOIN #TDATaxUnit AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.TaxUnit    = B.TaxUnit
         WHERE A.CompanySeq = @CompanySeq
           AND A.TaxTermSeq = @TaxTermSeq
           AND A.TaxUnit    = @TaxUnit
           AND A.IsCard     <> '1' -- 신용카드 내역 외
         GROUP BY B.TaxNo, A.IsCard
         ORDER BY B.TaxNo, A.IsCard

        
        SELECT @DLCnt = ISNULL(@DLCnt,0) + COUNT(*)
            FROM ( SELECT Card.IsCard    
                     FROM _TTAXReceiptCardSum AS Card WITH(NOLOCK)
                     WHERE Card.CompanySeq  = @CompanySeq  
                       AND Card.TaxTermSeq  = @TaxTermSeq  
                       AND Card.TaxUnit     = @TaxUnit  
                       AND Card.IsCard     <> '1' -- 신용카드 내역 외   
                     GROUP BY Card.IsCard ) AS A    
  
    ------------------------------------------
    -- 카드구분 : 사업용신용카드(4)
    ------------------------------------------
        IF @SaleCnt > 0    
        BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'DL' --01.레코드구분    
                    + SUBSTRING(@TaxFrDate, 1, 4) --02.귀속년도    
                    + @TermKind     --03.반기구분    
     + @YearHalfMM   --04.반기내월순번    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(TaxNo,'-', '')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(TaxNo,'-', '')))))) --05.수취자(제출자)사업자등록번호    
                    +'4'            --06.카드구분(사업용신용카드)
                    + SPACE(20)     --07.카드회원번호    
                    + SPACE(10)     --08.공급자(가맹점) 사업자등록번호    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), @SaleCnt - @MinusBizCnt), 9)     -- 09. 거래건수    
                    + CASE WHEN ISNULL(@SupAmt,0) >= 0 THEN ' ' ELSE '-' END    --10.공급가액 음수표시    양수 Space 음수 -    
                    + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(ISNULL(@SupAmt,0)))), 13) --11.공급가액    
                    + CASE WHEN ISNULL(@TaxAmt,0) >= 0 THEN ' ' ELSE '-' END    --12.세액 음수표시        양수 Space 음수 -    
                    + RIGHT('0000000000000' + CONVERT(VARCHAR(13), ABS(FLOOR(ISNULL(@TaxAmt,0)))), 13) --13.세액    
                    + SPACE(54)    
                    , 140    
              FROM #TDATaxUnit WITH(NOLOCK)
             WHERE CompanySeq   = @CompanySeq  
               AND TaxUnit      = @TaxUnit  
       
            -- 신용카드 내역외 화물운송복지카드    
            SELECT @DLCnt = ISNULL(@DLCnt,0) + ( CASE WHEN @SaleCnt  > 0 THEN 1 ELSE 0 END )     
        END    
  
        
    /***************************************************************************************************************************    
    신용카드매출전표등수취명세서_Tail
        
    01. 레코드구분(2) : TL    
    02. 귀속년도(4)    
    03. 반기구분(1) : '1' 1기, '2' 2기    
    04. 반기내월순번(1) : 1,2,3,4,5,6    단, 예정신고는 '3', 확정신고는 '6'    
    05. 수쉬자(제출자)사업자등록번호(10)    
    06. DATA건수(7)    
    07. 총거래건수(9)    
    08. 총공급가액_음수표시(1)    
    09. 총공급가액(15)    
    10. 총세액_음수표시(1)    
    11. 총세액(15)    
    12. 공란(74)    
    ****************************************************************************************************************************/    
    -- 신용카드 내역외 화물운송복지카드    
        IF NOT EXISTS (SELECT 1 FROM _TTAXReceiptCardSum WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND TaxTermSeq = @TaxTermSeq AND TaxUnit = @TaxUnit)  
        BEGIN  
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)  
            SELECT 'TL'                             --01.레코드구분    
                    + SUBSTRING(@TaxFrDate, 1, 4)   --02.귀속년도    
                    + @TermKind                     --03.반기구분    
                    + @YearHalfMM                   --04.반기내월순번    
                    + CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(@TaxNo,'-','')))) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), LTRIM(RTRIM(REPLACE(@TaxNo,'-','')))))) --05.수취자(제출자)사업자등록번호    
                    + RIGHT('0000000'   + CONVERT(VARCHAR(7), @DLCnt), 7)                               --06. DATA건수    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), (ISNULL(@SaleCnt,0) - @MinusCardCnt - @MinusCashCnt - @MinusEntryCnt - @MinusBizCnt )), 9)              --07. 거래건수 합계    
                    + CASE WHEN ISNULL(@SupAmt,0) >= 0 THEN ' ' ELSE '-' END                            --08. 총공급가액_음수표시(양수Space/음수-)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(ISNULL(@SupAmt,0) )), 15)    --09. 총공급가액 합계
                    + CASE WHEN ISNULL(@TaxAmt,0) >= 0 THEN ' ' ELSE '-' END                            --10. 총세액_음수표시    (양수Space/음수-)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(ISNULL(@TaxAmt,0) )), 15)    --11. 총세액 합계
                    + SPACE(74)    
                    , 140
        END    
        ELSE    
        BEGIN    
            INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)    
            SELECT 'TL'                             --01.레코드구분    
                    + SUBSTRING(@TaxFrDate, 1, 4)   --02.귀속년도    
                    + @TermKind                     --03.반기구분    
                    + @YearHalfMM  --04.반기내월순번    
                    + CONVERT(VARCHAR(10), REPLACE(LTRIM(RTRIM(@TaxNo)),'-','')) + SPACE(10 - DATALENGTH(CONVERT(VARCHAR(10), REPLACE(LTRIM(RTRIM(@TaxNo)),'-','')))) --05.수취자(제출자)사업자등록번호    
                    + RIGHT('0000000'   + CONVERT(VARCHAR(7), @DLCnt), 7)                                               --06. DATA건수    
                    + RIGHT('000000000' + CONVERT(VARCHAR(9), COUNT(SlipSeq)+ISNULL(@SaleCnt,0) - @MinusCardCnt - @MinusCashCnt - @MinusEntryCnt - @MinusBizCnt), 9)   --07. 거래건수 합계    
                    + CASE WHEN SUM(SupplyAmt) >= 0 THEN ' ' ELSE '-' END                                               --08. 총공급가액_음수표시(양수 Space/음수 -)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(SupplyAmt)+ISNULL(@SupAmt,0))), 15)      --09. 총공급가액 합계    
                    + CASE WHEN SUM(VATAmt)    >= 0 THEN ' ' ELSE '-' END                                               --10. 총세액_음수표시    (양수 Space/음수 -)
                    + RIGHT('000000000000000' + CONVERT(VARCHAR(15), FLOOR(SUM(VATAmt   )+ISNULL(@TaxAmt,0))), 15)      --11. 총세액 합계    
                    + SPACE(74)    
                    , 140    
             FROM _TTAXReceiptCardSum AS A WITH(NOLOCK)
             WHERE A.CompanySeq = @CompanySeq  
               AND A.TaxTermSeq = @TaxTermSeq  
               AND A.TaxUnit    = @TaxUnit
        END    
    END    
END  
    
    -- 최종라인 빈줄 추가       
    INSERT INTO #CREATEFile_tmp(tmp_file, tmp_size)
    SELECT '', 1
  
    SELECT tmp_seq, ISNULL(tmp_file, '') AS tmp_file, tmp_size, DATALENGTH(tmp_file) AS FileLen   
      FROM #CREATEFile_tmp    
    ORDER BY tmp_seq  
    
RETURN    
--**********************************************************************************************************************************************
