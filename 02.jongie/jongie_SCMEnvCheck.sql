
IF OBJECT_ID('jongie_SCMEnvCheck') IS NOT NULL
    DROP PROC jongie_SCMEnvCheck
GO
    
-- v2013.08.07   
  
-- (종이나라) 추가개발 Mapping정보 설정_jongie-체크 by 김철웅 (copy 이재천)
CREATE PROC jongie_SCMEnvCheck        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT     = 0,        
    @ServiceSeq     INT     = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT     = 1,        
    @LanguageSeq    INT     = 1,        
    @UserSeq        INT     = 0,        
    @PgmSeq         INT     = 0        
AS        
        
    DECLARE @PriceUnitEnvSeq    INT,        
            @Word               NVARCHAR(100),        
            @MessageType        INT,        
            @Status             INT,        
            @Results            NVARCHAR(250)        
        
    CREATE TABLE #TCOMEnv (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TCOMEnv'        
    IF @@ERROR <> 0 RETURN        
          
    SELECT @PriceUnitEnvSeq = EnvSeq FROM #TCOMEnv        
            
    --환경설정에서 자재단가계산단위, 상품단가계산단위, 제품단가계산단위 등의 데이터를 수정 시 초기 입력된 데이터가 이상이 발생하는 경우가 존재함.        
    --이를 제한하기 위하여 해당 속성 수정 시 초기금액입력 화면에 데이터가 존재하면 이미 초기에 등록된 자료가 존재하여 수정할 수 없다는 메시지 처리        
    CREATE TABLE #TempAsset (SMAssetGrp INT)         
        
    IF @PriceUnitEnvSeq =5521          
    BEGIN        
        INSERT INTO #TempAsset        
        SELECT MinorSeq          
          FROM _TDASMinor         
         WHERE MinorValue = '1' --자재         
           AND MinorSeq <> '6008005' --재공품         
           AND MajorSeq = 6008        
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 1968 AND LanguageSeq = @LanguageSeq        
    END        
    ELSE IF @PriceUnitEnvSeq =5522 --상품         
    BEGIN        
        INSERT INTO #TempAsset        
        SELECT MinorSeq         
          FROM _TDASMinor          
         WHERE  MinorSeq = 6008001        
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 3069 AND LanguageSeq = @LanguageSeq        
    END        
    ELSE IF @PriceUnitEnvSeq =5523 --제품         
    BEGIN         
        INSERT INTO #TempAsset        
        SELECT MinorSeq         
          FROM _TDASMinor          
         WHERE  MinorSeq IN ( 6008002 , 6008004 )         
           AND CompanySeq = @CompanySeq         
        SELECT @Word = Word FROM _TCADictionary WHERE WordSeq = 2031 AND LanguageSeq = @LanguageSeq        
        SELECT @Word = @Word + '(' + Word + ')' FROM _TCADictionary WHERE WordSeq = 8731 AND LanguageSeq = @LanguageSeq        
    END        
        
    IF EXISTS (        
                SELECT TOP 1 1        
                  FROM _TESMGMonthlyStockAmt    AS A WITH(NOLOCK)        
                  JOIN _TDAItem      AS C WITH(NOLOCK) ON A.ItemSeq      = C.ItemSeq        
                                                      AND A.CompanySeq   = C.CompanySeq        
                  JOIN _TDAItemAsset AS E WITH(NOLOCK) ON C.CompanySeq   = E.CompanySeq        
                                                      AND C.AssetSeq     = E.AssetSeq        
                  JOIN #TempAsset    AS F WITH(NOLOCK) ON E.SMAssetGrp   = F.SMAssetGrp         
                 WHERE A.CompanySeq   = @CompanySeq        
                   AND A.InOutKind    = 8023000        
                )        
    BEGIN        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              8                  , -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%등록%'        
                              @LanguageSeq       ,         
                              9357,''            ,        
                              0, @Word           ,        
                              8316,''               -- SELECT * FROM _TCADictionary WHERE Word like '%제품%'        
          UPDATE #TCOMEnv        
           SET Result        = @Results,        
               MessageType   = @MessageType,        
               Status        = @Status        
          FROM #TCOMEnv AS A        
         WHERE  A.WorkingTag IN ('A','U')        
              AND A.Status = 0        
    END        
        
    --환경설정값이 설명에 해당 하는 데이터가 아닐 경우 오류 메시지 처리함        
    IF @PriceUnitEnvSeq IN (5518,5521,5522,5523)        
    BEGIN        
        IF (SELECT EnvValue FROM #TCOMEnv) NOT IN (5502002,5502003)        
        BEGIN        
            EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                  @Status      OUTPUT,        
                                  @Results     OUTPUT,        
                                  1139               , -- 환경설정기준(@1) 값이 일치하지 않습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%환경설정%'        
                                  @LanguageSeq       ,         
                                  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
            UPDATE #TCOMEnv        
               SET Result        = REPLACE(@Results,'@1',EnvValueName),        
                   MessageType   = @MessageType,        
                   Status        = @Status        
              FROM #TCOMEnv AS A        
             WHERE  A.WorkingTag IN ('A','U')        
                AND A.Status = 0        
        END        
    END        
    ELSE IF @PriceUnitEnvSeq = 5524        
    BEGIN        
        IF (SELECT EnvValue FROM #TCOMEnv) NOT IN (5502001,5502002)        
        BEGIN        
            EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                                  @Status      OUTPUT,        
                                  @Results     OUTPUT,        
                                  1139               , -- 환경설정기준(@1) 값이 일치하지 않습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%환경설정%'        
                                  @LanguageSeq       ,         
                                  0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
            UPDATE #TCOMEnv        
               SET Result        = REPLACE(@Results,'@1',EnvValueName),        
                   MessageType   = @MessageType,        
                   Status        = @Status        
              FROM #TCOMEnv AS A        
             WHERE  A.WorkingTag IN ('A','U')        
                AND A.Status = 0        
        END        
    END        
        
---------------------------------------------------------------------------------------------------------------        
    --필수입력(사원, 사용자ID, 회사)        
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,        
    --                      @Status      OUTPUT,        
    --                      @Results     OUTPUT,        
    --                      1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')        
    --                      @LanguageSeq       ,         
    --                      0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        
    --UPDATE #TCOMEnv        
    --   SET Result        = '[환경설정명]'+@Results,        
    --       MessageType   = @MessageType,        
    --       Status        = @Status        
    --  FROM #TCOMEnv AS A        
    -- WHERE  A.WorkingTag IN ('A','U')        
    --    AND A.Status = 0        
    --    AND A.EnvName = ''        
          
    -- 체크박스일때는 1,0으로 저장        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84006' AND Status = 0)        
    BEGIN        
        UPDATE #TCOMEnv        
           SET EnvValue = '1'        
          FROM #TCOMEnv AS A        
         WHERE  A.WorkingTag IN ('A','U')        
            AND A.Status = 0        
            AND A.SMControlType = '84006'        
            AND A.EnvValue = 'True'        
        UPDATE #TCOMEnv        
           SET EnvValue = '0'        
            FROM #TCOMEnv AS A         
         WHERE  A.WorkingTag IN ('A','U')        
            AND A.Status = 0        
            AND A.SMControlType = '84006'        
            AND A.EnvValue = 'False'        
    END        
        
        
        
    -- Float타입인경우 ,를 ''로 저장        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0)        
    BEGIN        
        UPDATE #TCOMEnv        
           SET EnvValue = REPLACE(EnvValue, ',', '')        
          FROM #TCOMEnv        
         WHERE  WorkingTag IN ('A','U')        
            AND Status = 0        
            AND SMControlType = '84002'        
    END        
        
        
    -- 소숫점 자릿수 5이상으로 입력했을경우 이재혁 추가 소수점 관리하는 부분을 어느 코드로 구분하는지 몰라서 라이크로 함        
    --IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0 AND DecLength > 5)          
  IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND SMControlType = '84002' AND Status = 0 AND CONVERT(DECIMAL(19,5),EnvValue) > 5 AND (EnvName LIKE '%소수점%' OR EnvName LIKE '%소숫점%'))        
    BEGIN        
        
  UPDATE #TCOMEnv        
     SET Result  = N'소숫점자릿수는 0~5 로만 설정할 수 있습니다.',        
      MessageType = -1,        
      Status       = 9999        
   WHERE WorkingTag IN ('A','U')        
     AND Status = 0        
     AND SMControlType = '84002'        
    END        
        
    -- 사내외주비정산시 생산입고기준으로 사용은 데이터가 있을 경우 변경하면 키 값이 꼬인다. 그래서 데이터가 있을 경우에는 변경을 하지 못하도록 한다 2012. 1. 11 hkim        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE EnvSeq = 6513 AND Status = 0 AND WorkingTag IN ('U') ) AND EXISTS (SELECT 1 FROM _TPDSFCOutsourcingCostItem WHERE CompanySeq = @CompanySeq)        
    BEGIN        
        EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                              @Status      OUTPUT,        
                              @Results     OUTPUT,        
                              1310               , -- 환경설정기준(@1) 값이 일치하지 않습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%환경설정%'        
                              @LanguageSeq       ,         
                              25334,'사내외주',   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
                              355,'데이터',   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
                              13823,'변경'   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #TCOMEnv        
           SET Result        = @Results,        
               MessageType   = @MessageType,        
               Status        = @Status        
          FROM #TCOMEnv AS A        
         WHERE A.WorkingTag IN ('A','U')        
           AND A.Status = 0        
        
    END        
        
    -- AddCheck 추가체크SP가 있을경우        
    IF EXISTS (SELECT 1 FROM #TCOMEnv WHERE WorkingTag IN ('A','U') AND Status = 0 AND ISNULL(AddCheckScript, '') <> '')        
    BEGIN        
        DECLARE @EnvSeq         INT,        
                @AddCheckScript NVARCHAR(100),        
                @EnvValue       NVARCHAR(50)        
        
        DECLARE Check_cursor CURSOR FOR        
            SELECT EnvSeq, AddCheckScript,EnvValue        
              FROM #TCOMEnv        
             WHERE  WorkingTag IN ('A','U')        
                AND Status = 0        
                AND ISNULL(AddCheckScript, '') <> ''        
             ORDER BY EnvSeq        
        OPEN Check_cursor        
        FETCH NEXT FROM Check_cursor INTO @EnvSeq, @AddCheckScript,@EnvValue        
        WHILE @@FETCH_STATUS = 0        
        BEGIN        
        
            EXEC @AddCheckScript @EnvSeq, @CompanySeq, @LanguageSeq, @UserSeq, @PgmSeq,@EnvValue        
        
            FETCH NEXT FROM Check_cursor        
            INTO @EnvSeq, @AddCheckScript,@EnvValue        
        END        
        Deallocate Check_cursor        
    END        
        
    SELECT * FROM #TCOMEnv        
      
    RETURN        