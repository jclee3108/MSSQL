IF OBJECT_ID('KPXCM_SLGReInOutStockCheck') IS NOT NULL 
    DROP PROC KPXCM_SLGReInOutStockCheck
GO 

-- v2015.11.11 

-- KPX 용 2015.08월까지 재고재집계 되지 않도록 체크 추가 
  /************************************************************
  설  명 - 재고재집계 전 체크
  작성일 - 2011.03.31
  작성자 - 김대용
  수정내용 :  사업부문별 전표체크
 ************************************************************/
  -- 재고재집계 - 조회 
 CREATE PROC KPXCM_SLGReInOutStockCheck
     @xmlDocument       NVARCHAR(MAX) ,
     @xmlFlags          INT  = 0,
     @ServiceSeq        INT  = 0,
     @WorkingTag        NVARCHAR(10)= '',
     @CompanySeq        INT  = 1,
     @LanguageSeq       INT  = 1,
     @UserSeq           INT  = 0,
     @PgmSeq            INT  = 0
 AS
      DECLARE @MessageType INT,
              @Status      INT,
              @Results     NVARCHAR(250),
              @SMCostMng   INT,
              @UseCost     INT  ,
              @IsUseIFRS   INT
       -- 서비스 마스터 등록 생성
      CREATE TABLE #TLGStockReSumCheck (WorkingTag NCHAR(1) NULL)
      EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGStockReSumCheck'
    
    
    --------------------------------------------------------------------------------
    -- KPX 용 2015.08월까지 재고재집계 되지 않도록 체크 추가 
    --------------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '2015년 9월 이전 재고는 재집계 할 수 없습니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #TLGStockReSumCheck AS A 
     WHERE A.Status = 0 
       AND A.InOutYM <= '201508'
    
    --------------------------------------------------------------------------------
    -- KPX 용 2015.08월까지 재고재집계 되지 않도록 체크 추가 
    --------------------------------------------------------------------------------
      -- 원가사용단위 가져오기
      DECLARE @ItemPriceUnit      INT,
              @GoodPriceUnit      INT,
              @FGoodPriceUnit     INT,
              @ProfCostUnitKind   INT,
              @CostUnitKind       INT
       SELECT @CostUnitKind     = EnvValue FROM _TComEnv WHERE EnvSeq = 5524  AND CompanySeq = @CompanySeq --제조원가계산단위(생산사업장 or 회계단위)
      SELECT @ProfCostUnitKind = EnvValue FROM _TComEnv WHERE EnvSeq = 5518  AND CompanySeq = @CompanySeq --총원가계산단위  (회계단위 or사업부문)--프로젝트 전표에서..
      SELECT @ItemPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5521  AND CompanySeq = @CompanySeq --자재단가계산단위(회계단위 or사업부문)
      SELECT @GoodPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5522  AND CompanySeq = @CompanySeq --상품단가계산단위(회계단위 or사업부문)
      SELECT @FGoodPriceUnit   = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  AND CompanySeq = @CompanySeq --제품단가계산단위(회계단위 or사업부문)
  
      -- 환경설정에서 '사용원가선택' 가져오기
      EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@UseCost OUTPUT
  
      -- IFRS로만 결산처리 진행여부
      EXEC dbo._SCOMEnv @CompanySeq,5563,@UserSeq,@@PROCID,@IsUseIFRS OUTPUT
       IF @UseCost = 5518001 -- 기본원가
         IF @IsUseIFRS = '1'
         SELECT @SMCostMng = 5512006
         ELSE
         SELECT @SMCostMng = 5512004
      ELSE -- 활동기준원가
         IF @IsUseIFRS = '1'
         SELECT @SMCostMng = 5512005
         ELSE
         SELECT @SMCostMng = 5512001
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                             @Status      OUTPUT,
                             @Results     OUTPUT,
                             1173               , -- @1된 자료는 @2@3할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE  LanguageSeq = 1 and MessageSeq = 1285)
                             @LanguageSeq     ,
                             28676 , '',  -- 원가계산처리후
                             0,'',
                             17036,''
       IF '' = ISNULL((SELECT tOP 1 BizUnit FROM #TLGStockReSumCheck),''  ) --사업부문이 존재안하면
      BEGIN
         UPDATE #TLGStockReSumCheck
            SET Result        = REPLACE(@Results,'@2','')+'('+ C.MinorName +')',
                MessageType   = @MessageType,
                Status        = @Status
           FROM _TESMCProdSlipM AS A
                              JOIN (  SELECT A.TransSeq ,
                                             C.InOutYM
                                        FROM _TESMCProdSlipM   AS A WITH(NOLOCK)
                                        JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq
                                                                                AND B.SMCostMng     = @SMCostMng
                                                                                AND B.RptUnit       = 0
                                                                                AND B.CostMngAmdSeq = 0
                                                                                AND B.PlanYear      = ''
          AND A.CompanySeq    = B.Companyseq
                                        JOIN #TLGStockReSumCheck AS C ON B.CostYM = C.InOutYM
               WHERE A.CompanySeq = @CompanySeq
                                         AND A.SlipSeq <> 0
                                       GROUP BY A.TransSeq, C.InOutYM
                                   )  AS B ON A.TransSeq = B.TransSeq
           LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON A.SMSlipKind = C.MinorSeq AND A.CompanySeq = C.CompanySeq
           JOIN #TLGStockReSumCheck   AS D ON B.InOutYM  = D.InOutYM
          WHERE Status = 0
            AND A.CompanySeq = @CompanySeq
     END
     ELSE
     BEGIN
          CREATE TABLE  #CostUnitList
          (
              AccUnit INT,
              AccUnitName NVARCHAR(100),
              BizUnit INT,
              BizUnitName NVARCHAR(100),
              FactUnit INT,
              FactUnitName NVARCHAR(50)
          )
          INSERT #CostUnitList
          SELECT A.AccUnit, ISNULL(A.AccUnitName, '') AS AccUnitName,
                 ISNULL(B.BizUnit, 0) AS BizUnit, ISNULL(B.BizUnitName, '') AS BizUnitName,
                 ISNULL(C.FactUnit, 0) AS FactUnit, ISNULL(C.FactUnitName, '') AS FactUnitName
            FROM _TDAAccUnit AS A WITH(NOLOCK)
                      LEFT OUTER JOIN _TDABizUnit AS  B WITH(NOLOCK) ON A.AccUnit = B.AccUnit AND A.CompanySeq = B.CompanySeq
                      LEFT OUTER JOIN _TDAFactUnit AS C WITH(NOLOCK) ON B.BizUnit = C.BizUnit AND B.CompanySeq = C.CompanySeq
           WHERE A.CompanySeq = @CompanySeq
          UPDATE #TLGStockReSumCheck
             SET Result        = REPLACE(REPLACE(REPLACE(@Results,'@1',''),'@2',''), '@3', ISNULL(D.MinorName,'')),  --CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' +
                 MessageType   = @MessageType,
                 Status        = @Status
            FROM #TLGStockReSumCheck AS A
              JOIN (
              SELECT D.BizUnit ,
                     A.TransSeq ,
                     A.CostKeySeq
                FROM _TESMCProdSlipM   AS A WITH(NOLOCK)
                              JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq
                                                                      AND B.SMCostMng     = @SMCostMng
                                                                      AND B.RptUnit       = 0
                                                                      AND B.CostMngAmdSeq = 0
                                                                      AND B.PlanYear      = ''
                                                                      AND A.CompanySeq    = B.Companyseq
                              JOIN #CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --제조원가계산단위로 등록된 전표일 경우
                                                                                                      THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522004,5522013,5522017)                   --자재단가계산단위로 등록된 전표일 경우
                                                                                                      THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522005,5522014)                   --상품단가계산단위로 등록된 전표일 경우
                                                                                                      THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --제품단가계산단위로 등록된 전표일 경우
                                                                    THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --프로젝트전표처리일 경우 총원가계산단위...
                                                                                                      THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                 WHEN A.SMSlipKind IN (5522008)       --적송전표처리(회계단위로...)
                                                                                                      THEN C.AccUnit
                                               ELSE 0 END
                              JOIN #TLGStockReSumCheck AS D WITH(NOLOCK) ON  C.BizUnit = D.BizUnit AND D.Status  = 0 AND B.CostYM = D.InOutYM
               WHERE A.CompanySeq = @CompanySeq
                 AND A.SlipSeq <> 0
               GROUP BY D.BizUnit , A.TransSeq,A.CostKeySeq
                                   ) AS B ON A.BizUnit = B.BizUnit
                              JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
                   LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
           WHERE A.Status = 0
  
     END
      /*
     AND D.PriceCalcKind IN (5515002) --자재일경우
     AND A.SMSlipKind NOT IN (5522005,5522006,5522007,5522012,5522014,5522015,5522016)
     AND D.PriceCalcKind IN (5515003) --상품
     AND A.SMSlipKind NOT IN (5522004,5522013)
     AND D.PriceCalcKind IN (5515001) --제품일경우
     AND A.SMSlipKind NOT IN (5522004,5522005,5522007,5522012,5522013,5522014,5522015,5522016,5522017)
     AND ISNULL(D.PriceCalcKind,0)  = 0  --제품원가
     AND A.SMSlipKind NOT IN (5522004,5522005,5522007,5522013,5522014,5522015,5522016,5522017)
     */
     
     INSERT INTO _TLGReInOutStockHist
     (   
         CompanySeq,
         InOutYM,
         SMInOutType,
         LastUserSeq,
         LastDateTime,
         BizUnit,
         PgmSeq 
     )
     SELECT @CompanySeq,
            A.InOutYM,
            A.SMInOutType,
            @UserSeq,
            GETDATE(),
            BizUnit,
            @PgmSeq 
       FROM #TLGStockReSumCheck AS A
      WHERE A.Status = 0
     
     SELECT * FROM #TLGStockReSumCheck
     
     RETURN