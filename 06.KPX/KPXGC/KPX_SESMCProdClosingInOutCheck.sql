IF OBJECT_ID('KPX_SESMCProdClosingInOutCheck') IS NOT NULL 
    DROP PROC KPX_SESMCProdClosingInOutCheck
GO 

-- v2015.07.27 

-- 마이너스재고가 있을경우 체크 by이재천 
/************************************************************
  설  명 - D-제조원가마감 : 제조원가마감확인(수불업무마감화면에서 체크)
  작성일 - 2010.10.11
  작성자 - 진선주
  수정일 - 2011.01.10 지해 : 상품과 자재의 마감체크시 사용하는 전표 구분함. 
  전표구분코드 전표구분          자재 상품/제품
 5522001 제조원가 재료비대체          V V
 5522002 제조원가 전표처리             V V
 5522003 매출원가 전표처리             V V
 5522004 기타입출고전표_자재             V 
 5522005 기타입출고전표_상품              V
 5522006 기타입출고전표_제품              V
 5522007 기타입출고전표_제품원가계산전  V
 5522008 적송 전표처리                 V V
 5522009 프로젝트 재료비 대체 전표처리 V V
 5522010 프로젝트 전표처리             V V
 5522011 프로젝트 매출 대체 전표처리     V V
 5522012 연총평균 보정전표_제품          V
 5522013 연총평균 보정전표_자재         V 
 5522014 연총평균 보정전표_상품          V
 5522015 기타입출고전표_제품(품목별)      V
 5522016 재공폐기전표처리          V   V
  
 ************************************************************/
 CREATE PROC dbo.KPX_SESMCProdClosingInOutCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
  AS  
     DECLARE @MessageType        INT,
             @Status             INT,
             @Results            NVARCHAR(250),
             @CostUnitKind       INT,
             @EnvValue           INT,
             @SMCostMng          INT,
             @ItemPriceUnit      INT,
             @GoodPriceUnit      INT,
             @FGoodPriceUnit     INT,
             @ProfCostUnitKind   INT
      -- 서비스 마스타 등록 생성
     CREATE TABLE #TESMCProdClosing (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TESMCProdClosing'     
     IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #TSMCostMng
    (
        SMCostMng INT
    ) 

    --select * from _TESMDCostKey
    --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 5512  
    
    SELECT @EnvValue = EnvValue FROM _TComEnv WHERE EnvSeq = 5531  AND CompanySeq = @CompanySeq --사용원가선택(기본원가 5518001, 활동기준원가 5518002)  
    
    IF @EnvValue = 5518001
    BEGIN
        INSERT #TSMCostMng
        SELECT 5512004
        
        INSERT #TSMCostMng
        SELECT 5512006
    END
    ELSE IF @EnvValue = 5518002
    BEGIN
        INSERT #TSMCostMng
        SELECT 5512001
        
        INSERT #TSMCostMng
        SELECT 5512005
    END
  
    IF NOT EXISTS (SELECT * FROM #TSMCostMng) --원가설정안되어 있을 경우 return
    BEGIN
        SELECT * FROM #TESMCProdClosing
        RETURN
    END
    
    SELECT @CostUnitKind     = EnvValue FROM _TComEnv WHERE EnvSeq = 5524  AND CompanySeq = @CompanySeq --제조원가계산단위(생산사업장 or 회계단위)
    SELECT @ProfCostUnitKind = EnvValue FROM _TComEnv WHERE EnvSeq = 5518  AND CompanySeq = @CompanySeq --총원가계산단위  (회계단위 or사업부문)--프로젝트 전표에서..
    SELECT @ItemPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5521  AND CompanySeq = @CompanySeq --자재단가계산단위(회계단위 or사업부문)    
    SELECT @GoodPriceUnit    = EnvValue FROM _TComEnv WHERE EnvSeq = 5522  AND CompanySeq = @CompanySeq --상품단가계산단위(회계단위 or사업부문)            
    SELECT @FGoodPriceUnit   = EnvValue FROM _TComEnv WHERE EnvSeq = 5523  AND CompanySeq = @CompanySeq --제품단가계산단위(회계단위 or사업부문) 
    
    --CostUnit별로 담기
    DECLARE @CostUnitList TABLE
    (
        AccUnit INT,
        AccUnitName NVARCHAR(100),
        BizUnit INT,
        BizUnitName NVARCHAR(100),
        FactUnit INT,
        FactUnitName NVARCHAR(50)
    )
    INSERT @CostUnitList
    SELECT A.AccUnit, ISNULL(A.AccUnitName, '') AS AccUnitName, ISNULL(B.BizUnit, 0) AS BizUnit, ISNULL(B.BizUnitName, '') AS BizUnitName, ISNULL(C.FactUnit, 0) AS FactUnit, ISNULL(C.FactUnitName, '') AS FactUnitName
         
      FROM _TDAAccUnit AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TDABizUnit AS  B WITH(NOLOCK) ON A.AccUnit = B.AccUnit AND A.CompanySeq = B.CompanySeq 
      LEFT OUTER JOIN _TDAFactUnit AS C WITH(NOLOCK) ON B.BizUnit = C.BizUnit AND B.CompanySeq = C.CompanySeq 
     WHERE A.CompanySeq = @CompanySeq
    
    -------------------------------------------
    -- 중복여부체크
    -------------------------------------------                          
     
     
    /*마감을 풀어야 전표도 삭제할 수 있으니까 원가마감부터 체크하자. */
    -------------------------------------------
    -- 마감여부체크
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1249               , -- @3(@2) 의 제조원가가 마감되어 취소할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1249)  
                          @LanguageSeq         -- ex)안성공장(생산사업장) 의 제조원가가 마감되어 취소할 수 없습니다.
                                
    SELECT @Results = REPLACE(@Results, '@2', Word) FROM _TCADictionary where WordSeq=2074 AND LanguageSeq = @LanguageSeq --#제조원가단위(회계단위/생산사업장)
    
    --원가마감은 제조원가계산단위별로 한다. 
    UPDATE #TESMCProdClosing  
       SET Result = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' 
                    + REPLACE(@Results, '@3', ISNULL(CASE @CostUnitKind WHEN 5502001 THEN C.FactUnitName ELSE C.AccUnitName END,'')),  
           MessageType = @MessageType,  
           Status = @Status  
      FROM #TESMCProdClosing AS A 
      JOIN (
                SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, MAX(A.CostUnit) AS CostUnit
                  FROM _TESMCProdClosing    AS A WITH(NOLOCK) 
                  JOIN _TESMDCostKey        AS B WITH(NOLOCK) ON A.CostKeySeq = B.CostKeySeq 
                                                             AND B.RptUnit       = 0 
                                                             AND B.CostMngAmdSeq = 0 
                                                             AND B.PlanYear      = '' 
                                                             AND A.CompanySeq    = B.Companyseq
                  JOIN @CostUnitList        AS C              ON A.CostUnit = CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                  JOIN #TESMCProdClosing    AS D WITH(NOLOCK) ON D.UnitSeq = C.BizUnit 
                                                             AND D.ClosingSeq    = 69
                                                             AND D.IsClose       = '0' 
                                                             AND D.Status        = 0
                  LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM = D.ClosingYM
                                                                     AND E.UnitSeq = D.UnitSeq
                                                                     AND E.DtlUnitSeq = D.DtlUnitSeq
                                                                     AND E.ClosingSeq = 69
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.IsClosing = '1'
                   AND D.IsClose <> ISNULL(E.IsClose, '0')
                   AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                 GROUP BY C.BizUnit, D.DtlUnitSeq
           ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --수불마감을 풀려고 하는 월보다 원가마감한 월이 더 큰 건이나 같은 건이 있으면 마감 못푼다
      LEFT OUTER JOIN @CostUnitList AS C ON B.CostUnit      = CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
     WHERE A.Status = 0
    
    -- 공통 SP Call 예정
    
    -------------------------------------------
    -- 전표처리여부체크
    -------------------------------------------
    --5522001 제조원가 재료비대체
    --5522002 제조원가 전표처리
    --5522003 매출원가 전표처리
    --5522004 기타입출고전표_자재
    --5522005 기타입출고전표_상품
    --5522006 기타입출고전표_제품
    --5522007 기타입출고전표_제품원가계산전
    --5522008 적송 전표처리
    --5522009 프로젝트 재료비 대체 전표처리
    --5522010 프로젝트 전표처리
    --5522011 프로젝트 매출 대체 전표처리
    --5522012 연총평균 보정전표_제품
    --5522013 연총평균 보정전표_자재
    --5522014 연총평균 보정전표_상품
    --5522015 기타입출고전표_제품(품목별)
    --5522016 재공폐기전표처리
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1250               , -- 전표처리(@3)된 데이터가 존재하여 수불마감을 취소할 수 없습니다(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1250)  
                          @LanguageSeq       
    
    UPDATE #TESMCProdClosing  
       SET Result        = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' + REPLACE(@Results, '@3', ISNULL(D.MinorName,'')),  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #TESMCProdClosing AS A 
                         JOIN (
                                 SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, 
                                        A.TransSeq
 --                                        (SELECT TOP 1 TransSeq FROM _TESMCProdSlipM WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CostKeySeq = MAX(B.CostKeySeq) ORDER BY LastDateTime DESC) AS TransSeq
                                   FROM _TESMCProdSlipM   AS A WITH(NOLOCK) 
                                                 JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq 
                                                                                         AND B.RptUnit       = 0 
                                                                                         AND B.CostMngAmdSeq = 0 
                                                                                         AND B.PlanYear      = '' 
                                                                                         AND A.CompanySeq    = B.Companyseq
                                                 JOIN @CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --제조원가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522004,5522013)                   --자재단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522005,5522014)                   --상품단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --제품단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --프로젝트전표처리일 경우 총원가계산단위...  
                                               THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522008)                           --적송전표처리(회계단위로...)
                                                                                                                         THEN C.AccUnit
                                                                                                                    ELSE 0 END
                                                 JOIN #TESMCProdClosing AS D WITH(NOLOCK) ON D.UnitSeq       = C.BizUnit 
                                                                                         AND D.ClosingSeq    = 69
                                                                                         AND D.IsClose       = '0' 
                                                                                         AND D.Status        = 0
                                      LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM     = D.ClosingYM
                                                                                         AND E.UnitSeq       = D.UnitSeq
                                                                                         AND E.DtlUnitSeq    = D.DtlUnitSeq
                                                                                         AND E.ClosingSeq    = 69                                                                                        
                                                 --JOIN _TACSlipRow       AS F WITH(NOLOCK) ON A.SlipSeq       = F.SlipSeq
                                                 --                                        AND A.CompanySeq    = F.CompanySeq
                                                 --JOIN _TACSlip          AS G WITH(NOLOCK) ON F.SlipMstSeq    = G.SlipMstSeq
                                                 --                                        AND F.CompanySeq    = G.CompanySeq select * from _TDASminor where Majorseq = 5522 and companySeq=1
                                  WHERE A.CompanySeq = @CompanySeq 
                                    AND A.SlipSeq <> 0
                                    --AND G.IsSet = '1' -- 전표승인된건?
                                    AND D.IsClose <> ISNULL(E.IsClose, '0')
                                    AND D.DtlUnitSeq = 1 --자재일경우 
                                    AND A.SMSlipKind NOT IN (5522005,5522006,5522007,5522012,5522014,5522015,5522016)
                                    AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                                  GROUP BY C.BizUnit, D.DtlUnitSeq, A.TransSeq
                              ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --수불마감을 풀려고 하는 월보다 원가전표처리된 월이 더 큰 건이나 같은 건 있으면 마감 못푼다
                         JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
              LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
      WHERE A.Status = 0  
     UPDATE #TESMCProdClosing  
        SET Result        = CONVERT(NVARCHAR(7) , CONVERT(DATETIME, B.ClosingYM+'01'), 120) + ' ' + REPLACE(@Results, '@3', ISNULL(D.MinorName,'')),  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TESMCProdClosing AS A 
                         JOIN (
                                 SELECT C.BizUnit AS UnitSeq, D.DtlUnitSeq, MAX(B.CostYM) AS ClosingYM, 
                                        A.TransSeq
 --                                        (SELECT TOP 1 TransSeq FROM _TESMCProdSlipM WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND CostKeySeq = MAX(B.CostKeySeq) ORDER BY LastDateTime DESC) AS TransSeq
                                   FROM _TESMCProdSlipM   AS A WITH(NOLOCK) 
                                                 JOIN _TESMDCostKey     AS B WITH(NOLOCK) ON A.CostKeySeq    = B.CostKeySeq  
                                                                                         AND B.RptUnit       = 0 
                                                                                         AND B.CostMngAmdSeq = 0 
                                                                                         AND B.PlanYear      = '' 
                                                                                         AND A.CompanySeq    = B.Companyseq
                                                 JOIN @CostUnitList     AS C              ON A.CostUnit      = CASE WHEN A.SMSlipKind IN (5522001,5522002,5522003,5522016)   --제조원가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @CostUnitKind WHEN 5502001 THEN C.FactUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522004,5522013)                   --자재단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @ItemPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522005,5522014)                   --상품단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @GoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522006,5522007,5522012,5522015)   --제품단가계산단위로 등록된 전표일 경우     
                                                                                                                         THEN CASE @FGoodPriceUnit WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522009,5522010,5522011)           --프로젝트전표처리일 경우 총원가계산단위...  
                                                                                                                         THEN CASE @ProfCostUnitKind WHEN 5502003 THEN C.BizUnit ELSE C.AccUnit END
                                                                                                                    WHEN A.SMSlipKind IN (5522008)                           --적송전표처리(회계단위로...)
                                                                                                                         THEN C.AccUnit
                                                                                                                    ELSE 0 END
                                                 JOIN #TESMCProdClosing AS D WITH(NOLOCK) ON D.UnitSeq       = C.BizUnit 
                                                                                         AND D.ClosingSeq    = 69
                                                                                         AND D.IsClose       = '0' 
                                                                                         AND D.Status        = 0
                                      LEFT OUTER JOIN _TCOMClosingYM    AS E WITH(NOLOCK) ON E.ClosingYM     = D.ClosingYM
                                                                                         AND E.UnitSeq       = D.UnitSeq
                                                                                         AND E.DtlUnitSeq    = D.DtlUnitSeq
                                                                                         AND E.ClosingSeq    = 69                                                                              
                                                 --JOIN _TACSlipRow       AS F WITH(NOLOCK) ON A.SlipSeq       = F.SlipSeq
                                                 --                                        AND A.CompanySeq    = F.CompanySeq
     --JOIN _TACSlip          AS G WITH(NOLOCK) ON F.SlipMstSeq    = G.SlipMstSeq
                                                 --                                        AND F.CompanySeq    = G.CompanySeq select * from _TDASminor where Majorseq = 5522 and companySeq=1
                                  WHERE A.CompanySeq = @CompanySeq 
                                    AND A.SlipSeq <> 0
                                    --AND G.IsSet = '1' -- 전표승인된건?
                                    AND D.IsClose <> ISNULL(E.IsClose, '0')
                                     AND D.DtlUnitSeq = 2 --제품/상품일경우 
                                     AND A.SMSlipKind NOT IN (5522004,5522013)
                                     AND B.SMCostMng     IN(SELECT SMCostMng FROM #TSMCostMng) 
                                  GROUP BY C.BizUnit, D.DtlUnitSeq, A.TransSeq
                              ) AS B ON A.UnitSeq = B.UnitSeq AND A.DtlUnitSeq = B.DtlUnitSeq AND A.ClosingYM <= B.ClosingYM --수불마감을 풀려고 하는 월보다 원가전표처리된 월이 더 큰 건이나 같은 건 있으면 마감 못푼다
                         JOIN _TESMCProdSlipM AS C WITH(NOLOCK) ON C.TransSeq = B.TransSeq AND C.CompanySeq = @CompanySeq
              LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON C.SMSlipKind = D.MinorSeq AND C.CompanySeq = D.CompanySeq
      WHERE A.Status = 0   
     
     -------------------------------------------
     -- 진행여부체크
     -------------------------------------------
     -- 공통 SP Call 예정
      -------------------------------------------
     -- 확정여부체크
     -------------------------------------------
      -------------------------------------------
     -- INSERT 번호부여(맨 마지막 처리)
     ------------------------------------------- 
    
    SELECT * FROM #TESMCProdClosing 
    
    RETURN 
    
    
    
    
    
    
    
     
     
      SELECT * FROM #TESMCProdClosing   
 RETURN
 /**********************************************************************************************************/
 go
 exec KPX_SESMCProdClosingInOutCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <ClosingYM>201510</ClosingYM>
    <IsClose>0</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>9</ROW_IDX>
    <ClosingYM>201510</ClosingYM>
    <IsClose>0</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <ClosingYM>201511</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>10</ROW_IDX>
    <ClosingYM>201511</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <ClosingYM>201512</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>1</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ROW_IDX>11</ROW_IDX>
    <ClosingYM>201512</ClosingYM>
    <IsClose>1</IsClose>
    <DtlUnitSeq>2</DtlUnitSeq>
    <UnitSeq>3</UnitSeq>
    <ClosingSeq>69</ClosingSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=6561,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=200857