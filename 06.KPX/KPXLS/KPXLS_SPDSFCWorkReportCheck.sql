IF OBJECT_ID('KPXLS_SPDSFCWorkReportCheck') IS NOT NULL 
    DROP PROC KPXLS_SPDSFCWorkReportCheck
GO 

-- v2015.12.03 

-- KPXLS 투입이 있을 경우 체크 by이재천 
/************************************************************  
설  명 - 생산실적체크  
작성일 - 2008년 10월 22일  
작성자 - 정동혁  
수정일 - 2010년 7월 26일  
수정자 - 김현(최종공정 여부가 누락되는 건이 간혹 발생하여(경동솔라) 공정 흐름 유형과 걸어서 해당 공정이 최종공정인지를 판단함  
UPDATE ::  10.10.25 김미송 (작업시작, 종료시간 체크)   
UPDATE ::  11.03.02 김세호 (해당 공정품이 제품별소요자재에 등록된 공정품과  일치 체크)   
UPDATE ::  11.04.28 김현   (생산실적진척관리사용시 전공정의 양품수량을 초과하여 등록할 수 없고, 전공정이 실적 저장되지 않으면 저장할 수 없음)  
       ::  11.12.19 hkim   (작업지시번호를 바꿔서 업데이트 할 경우 오류 체크)  
       ::  11.12.20 김세호 (프로젝트실적건은 자동생성되므로  변경 안되도록 수정 )  
       ::  11.12.22 hkim   (무검사로 자동입고 잡은 후에, 검사품으로 바꾼 후 삭제를 할 경우 입고 남고 실적 삭제되는 오류 체크)  
       ::  12.03.18 김세호 (최종공정이고 무검사품일경우 최종검사데이터 생성해주는데, QCSeq 채번 실적check상에서 이루어지도록  
                            - test_SPDSFCWorkReportSave 에서 QCSeq 채번될경우 트랜잭션으로 중복키 오류발생할수있으므로 )  
       ::  12.04.25 김세호 (입고진행여부 체크 추가 )  
       ::  14.03.31 김용현 환경설정 추가 <생산계획/생산실적>  마이너스 수량 허용 여부 추가하여 마이너스 허용 여부 Check  
       ::  14.07.02 임희진 생산실적에서 Update,Delete시 사내외주용역비 테이블 데이터 유무 체크  
       ::  14.11.18 김용현 환경설정 추가 <생산실적>  생산실적 저장 시 생산수량을 0 으로 저장 안되도록 함   
       ::  15.03.26 김용현 작업지시가 없는데, 생산실적이 저장 되는 경우가 생겨서 해당 부분에 대해 Check 할 수 있도록 작지 데이터 유무 파악 추가  
************************************************************/  
CREATE PROC KPXLS_SPDSFCWorkReportCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
  
AS  
  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @GoodInSeq   INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @EnvValue    NVARCHAR(100),  
            @PrevProcNo  INT,  
            @PrevOKQty   DECIMAL(19, 5),  
            @QCSeq       INT,                -- 12.03.18 김세호 추가  
            @QCNo        NCHAR(12)   ,       -- 12.03.18 김세호 추가  
            @Env6270     NCHAR(1)   ,  
            @Env6270Text NVARCHAR(500),  
            @Env6273     NCHAR(1),  
            @Env6273Text NVARCHAR(500),  
            @Env6213     NVARCHAR(100)  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkReport'  
    IF @@ERROR <> 0 RETURN  
    
    --===========================================--  
    -- LotNo 자동부여 체크 6068003 ( 자동생성 )  -- 2014.11.21 김용현 아래 있는 환경설정 부분을 위로 올림.  
    --===========================================--  
    EXEC dbo._SCOMEnv @CompanySeq,6213,@UserSeq,@@PROCID,@Env6213 OUTPUT  
      
    
    ------------------------------------------------------------------------------------------------------------
    -- 체크, 투입자재가 존재하여 삭제 할 수 없습니다. 투입자재 취소부터 진행하시기 바랍니다. 
    ------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '투입자재가 존재하여 삭제 할 수 없습니다. 투입자재 취소부터 진행하시기 바랍니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #TPDSFCWorkReport AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'D'
       AND EXISTS (SELECT 1 FROM _TPDSFCMatInPut WHERE CompanySeq = @CompanySeq AND WorkReportSeq = A.WorkReportSeq) 
    ------------------------------------------------------------------------------------------------------------
    -- 체크, END 
    ------------------------------------------------------------------------------------------------------------
    
    
    --=======================================================================================================--  
    ----- 2015.03.26 김용현 추가, 작업지시 데이터가 없는데, 생산실적을 저장 하려고 할 경우에 대해서 Check -----  
    --=======================================================================================================--  
    IF EXISTS ( SELECT 1   
                  FROM #TPDSFCWorkReport AS A  
                       LEFT OUTER JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                         AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                         AND B.CompanySeq    = @CompanySeq  
                 WHERE B.WorkOrderSeq IS NULL  
                   AND A.WorkingTag = 'A'  
                   AND A.Status = 0 )  
      
    BEGIN   
  
          EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                2027                 , -- @1이(가) 존재하지 않아 @2을(를) 할 수 없습니다.  
                                @LanguageSeq       ,   
        16926, '작업지시'   ,  
                                17053, '저장'  
  
          UPDATE #TPDSFCWorkReport  
             SET Result        = @Results,  
         MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TPDSFCWorkReport AS A  
                 LEFT OUTER JOIN _TPDSFCWorkOrder AS B WITH(NOLOCK) ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                   AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                   AND B.CompanySeq    = @CompanySeq  
           WHERE B.WorkOrderSeq IS NULL  
             AND A.WorkingTag = 'A'  
             AND A.Status = 0  
    END                                                                               
      
      
    --===================================================================================--  
    ---- <생산계획/생산실적> 마이너스 수량 허용 여부 추가하여 마이너스 허용 여부 Check ---- 2014.03.31 김용현 추가  
    --===================================================================================--  
    EXEC dbo._SCOMEnv @CompanySeq,6270,@UserSeq,@@PROCID,@Env6270 OUTPUT    
      
    SELECT @Env6270 = ISNULL(@Env6270,'')  
      
      
    SELECT @Env6270Text = ISNULL(Description,'')  
      FROM _TCOMEnv   
     WHERE EnvSeq = 6270  
       AND CompanySeq = @CompanySeq               
  
         
    IF @Env6270 = '1'  
    BEGIN  
          EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                1139                 , -- 환경설정기준(@1) 값이 일치하지 않습니다.  
                                @LanguageSeq       ,   
                                0, @Env6270Text               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
      
          UPDATE #TPDSFCWorkReport  
             SET Result        = @Results,  
                 MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TPDSFCWorkReport      AS A  
           WHERE Status = 0  
             AND A.WorkingTag IN ( 'A', 'U' )  
             AND ( A.ProdQty < 0 OR A.OKQty < 0 OR A.BadQty  < 0 )  
  
      
    END   
      
    --=================================================================================--  
    ---- <생산실적>  생산실적 저장 시 생산수량을 0 으로 저장 안되도록 함 환경설정 추가 -- 2014.11.18 김용현 추가  
    --=================================================================================--  
  
    EXEC dbo._SCOMEnv @CompanySeq,6273,@UserSeq,@@PROCID,@Env6273 OUTPUT    
      
    SELECT @Env6273 = ISNULL(@Env6273,'')  
      
      
    SELECT @Env6273Text = ISNULL(Description,'')  
      FROM _TCOMEnv   
     WHERE EnvSeq = 6273  
       AND CompanySeq = @CompanySeq  
       
    --======================================================================--  
    ---- 생산수량을 0을 넣고 저장 할 경우 저장이 안되도록 Check 로직 추가 ----   
    --======================================================================--  
      
    IF @Env6273 = '1'  
    BEGIN   
      
        IF EXISTS ( SELECT 1 FROM #TPDSFCWorkReport WHERE ProdQty = 0 AND WorkingTag IN ('A','U' ) AND Status = 0 )  
        BEGIN  
             
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1139                 , -- 환경설정기준(@1) 값이 일치하지 않습니다.  
                                  @LanguageSeq       ,   
                                  0, @Env6273Text               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
              
            UPDATE #TPDSFCWorkReport  
               SET Result        = @Results     ,  
                   MessageType   = @MessageType ,  
                   Status        = @Status  
              FROM #TPDSFCWorkReport AS A  
          WHERE A.WorkingTag IN ('A','U')  
               AND A.Status = 0  
               AND A.ProdQty = 0   
          
          
        END  
      
    END  
    --------------------------------------------------------------------  
    ---- 작업시작시간에 스페이스값이 들어가면 오류메세지 표기되도록 수정  
      --------------------------------------------------------------------  
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                        @Status      OUTPUT,  
    --                        @Results     OUTPUT,  
    --                        1363                 , -- @1에 숫자를 입력해 주십시요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1363)  
    --                        @LanguageSeq       ,   
    --                        8254, ''               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
    --  UPDATE #TPDSFCWorkReport  
    --     SET Result        = @Results,  
    --         MessageType   = @MessageType,  
    --         Status        = @Status  
    --    FROM #TPDSFCWorkReport      AS A  
    --   WHERE Status = 0  
    --     AND A.WorkStartTime LIKE ' ' + '%' + ' ' + '%' + ' '  
       
  
    --------------------------------------------------------------------  
    ---- 작업종료시간에 스페이스값이 들어가면 오류메세지 표기되도록 수정  
    --------------------------------------------------------------------  
    --  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                        @Status      OUTPUT,  
    --                        @Results     OUTPUT,  
    --                        1363                 , -- @1에 숫자를 입력해 주십시요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1363)  
    --                        @LanguageSeq       ,   
    --                        8276, ''               -- SELECT * FROM _TCADictionary WHERE Word like '%%'  
    --  UPDATE #TPDSFCWorkReport  
    --     SET Result        = @Results,  
    --         MessageType   = @MessageType,  
    --         Status        = @Status  
    --    FROM #TPDSFCWorkReport      AS A  
    --   WHERE Status = 0  
    --     AND A.WorkEndTime LIKE ' ' + '%' + ' ' + '%' + ' '  
  
  
    ---------------------------------------------------------------------------------------------------------------------------------  
    -- 생산실적진척관리사용시 전 공정의 양품수량을 초과할 수 없고, 전 공정의 실적이 저장되지 않으면 저장할 수 없음 2011. 4. 28 hkim  
    ---------------------------------------------------------------------------------------------------------------------------------  
    IF EXISTS (SELECT 1 FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 6230 AND EnvValue = '1')  
    BEGIN                                              
  
  
        -- 총 공정 수를 가져오기 위함  
        SELECT A.ProcNo   
          INTO #ProcNo  
          FROM _TPDSFCWorkOrder         AS A  
               JOIN #TPDSFCWorkReport   AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
         WHERE A.CompanySeq = @CompanySeq  
      GROUP BY A.ProcNo  
        
        IF (SELECT COUNT(*) FROM #ProcNo) > 1   
        BEGIN  
   
            --전 공정 번호 가져오기   
            UPDATE #TPDSFCWorkReport  
               SET PrevProcNo = (SELECT MAX(C.ProcNo) FROM _TPDSFCWorkOrder         AS B   
                                                           JOIN _TPDSFCWorkOrder    AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                                                        AND B.ProcNo        = C.ToProcNo  
                                                     WHERE B.WorkOrderSeq = A.WorkOrderSeq  
                                                       AND B.WorkOrderSerl = A.WorkOrderSerl   
                                                       AND C.ProcNo <> C.ToProcNo  
                                                       AND B.CompanySeq = @CompanySeq    
                                                       AND C.CompanySeq = @CompanySeq)  
              FROM #TPDSFCWorkReport        AS A  
                   JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                AND A.WorkOrderSerl = B.WorkOrderSerl  
                   JOIN _TPDSFCWorkOrder    AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                AND B.ProcNo        = C.ToProcNo  
             WHERE B.CompanySeq = @CompanySeq    
               AND C.CompanySeq = @CompanySeq  
  
            -- 전 공정 수량 가져오기  
              UPDATE #TPDSFCWorkReport  
               SET PrevOKQty = B.OKQty      
              FROM #TPDSFCWorkReport        AS A    
                   JOIN ( SELECT A.WorkOrderSeq, A.WorkOrderSerl, SUM(C.OKQty) AS OKQty  
                            FROM #TPDSFCWorkReport        AS A  
                                 JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                              AND A.PrevProcNo    = B.ProcNo  
                                 JOIN _TPDSFCWorkReport   AS C ON B.WorkOrderSeq  = C.WorkOrderSeq  
                                                              AND B.WorkOrderSerl = C.WorkOrderSerl                                              
                           WHERE B.CompanySeq = @CompanySeq  
                             AND C.CompanySeq = @CompanySeq  
                        GROUP BY A.WorkOrderSeq, A.WorkOrderSerl) AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                                      AND A.WorkOrderSerl = B.WorkOrderSerl  
                                                                    
            -- 전 공정이 있고 전 공정 수량이 없는 경우는 전 공정부터 등록하라고 메시지 처리  
            IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport       AS A  
                                     JOIN _TPDSFCWorkOrder AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                                AND A.PrevProcNo       = B.ProcNo  
                                     LEFT OUTER JOIN _TPDSFCWorkReport AS C ON B.CompanySeq    = C.CompanySeq  
                                                                           AND B.WorkOrderSeq  = C.WorkOrderSeq  
                                                                           AND B.WorkOrderSerl = C.WorkOrderSerl   
                               WHERE B.CompanySeq = @CompanySeq AND C.WorkReportSeq IS NULL)  
            BEGIN  
                EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                      @Status      OUTPUT,  
                                      @Results     OUTPUT,  
                                      1248                 ,   
                                      @LanguageSeq       ,  
                                      16497,'이전공정',  
                                      2180,'생산실적'  
                UPDATE #TPDSFCWorkReport  
                   SET Result       = @Results,  
                       MessageType  = @MessageType,  
                       Status       = @Status  
                  FROM #TPDSFCWorkReport                 AS A  
                                  JOIN _TPDSFCWorkOrder  AS B ON A.WorkOrderSeq = B.WorkOrderSeq  
                                                             AND A.PrevProcNo       = B.ProcNo  
                       LEFT OUTER JOIN _TPDSFCWorkReport AS C ON B.CompanySeq    = C.CompanySeq  
                                                             AND B.WorkOrderSeq  = C.WorkOrderSeq  
                                                             AND B.WorkOrderSerl = C.WorkOrderSerl   
                                                                    
                 WHERE A.WorkingTag IN ('A', 'U')  
                   AND A.Status = 0  
                   AND B.CompanySeq = @CompanySeq  
                   AND C.WorkReportSeq IS NULL    
            END       
                 
            -- 전 공정이 있고 전 공정 수량을 초과한 경우 오류 처리  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  106                 ,   
                                  @LanguageSeq       ,  
                                  7145,'양품수량',  
                                  16497,'이전공정',  
                                  7145,'양품수량'  
            UPDATE #TPDSFCWorkReport  
               SET Result       = @Results,  
                   MessageType  = @MessageType,  
                   Status       = @Status  
                FROM #TPDSFCWorkReport                      
             WHERE WorkingTag IN ('A', 'U')  
               AND Status = 0  
               AND PrevOKQty IS NOT NULL                 
               AND OKQty > PrevOKQty  
                 
            -- 다음 공정의 실적데이터가 있는데 실적 데이터를 삭제하려는 경우  
            EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                                  @Status      OUTPUT,  
                                  @Results     OUTPUT,  
                                  1006                 ,   
                                  @LanguageSeq       ,  
                                  19339,'후공정'  
            UPDATE #TPDSFCWorkReport  
               SET Result       = @Results,  
                   MessageType  = @MessageType,  
                   Status       = @Status  
              FROM #TPDSFCWorkReport        AS A  
                   JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq  
                                                AND A.WorkOrderSerl = B.WorkOrderSerl  
                   JOIN _TPDSFCWorkOrder    AS C ON B.CompanySeq    = C.CompanySeq  
                                                AND B.WorkOrderSeq  = C.WorkOrderSeq                                                  
                                                AND B.ToProcNo      = C.ProcNo  
                   LEFT OUTER JOIN _TPDSFCWorkReport AS D ON C.CompanySeq    = D.CompanySeq  
                                                         AND C.WorkOrderSeq  = D.WorkOrderSeq  
                                                         AND C.WorkOrderSerl = D.WorkOrderSerl  
             WHERE A.WorkingTag IN ('D')  
               AND B.ProcNo <> B.ToProcNo  
               AND D.WorkReportSeq IS NOT NULL  
               AND A.Status = 0                                                           
              
        END           
    END    
    ---------------------------------------------------------------------------------------------------------------------------------  
    -- 생산실적진척관리사용시 전 공정의 양품수량을 초과할 수 없고, 전 공정의 실적이 저장되지 않으면 저장할 수 없음 끝 2011. 4. 28 hkim  
    ---------------------------------------------------------------------------------------------------------------------------------  
      
    IF @Env6213 <> '6068003' -- 환경설정에서 Lot 생성이 자동생성 일 경우에는 아래 에서 Lot을 자동생성으로 따주기 때문에 Check 를 하지 않도록 한다.  
    BEGIN   
      
     -------------------------------------------  
     -- Lot관리시 Lot필수체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1171               , -- 해당품목은 Lot번호 관리 품목입니다. Lot번호를 필수로 입력하세요.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1006)  
                           @LanguageSeq          
  
    UPDATE #TPDSFCWorkReport  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #TPDSFCWorkReport AS A  
           INNER JOIN _TDAItemStock C ON C.CompanySeq = @CompanySeq AND C.ItemSeq = A.AssyItemSeq AND C.IsLotMng = '1'  
     WHERE ISNULL(A.RealLotNo, '') = ''  
       AND IsLastProc   = '1'  
      
    END  
      
     -------------------------------------------  
     -- 해당 공정품이 제품별소요자재에 등록된 공정품과  일치 하는지   -- 11.03.02 김세호 추가  
     -------------------------------------------  
  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1170               , -- @1에 @2이 등록되어 있지 않습니다.  
                           @LanguageSeq,  
                           11356,'제품별공정별소요자재',  
                           3970,'공정품'  
                                                     
  
    UPDATE #TPDSFCWorkReport  
       SET MessageType = @MessageType,  
           Result = @Results,  
           Status = @Status  
       FROM #TPDSFCWorkReport  AS A  
         JOIN _TPDROUItemProcMat AS B ON A.GoodItemSeq = B.ItemSeq                                      AND A.ItemBomRevName = B.BOMRev  
                                   AND A.ProcRev = B.ProcRev  
                                   AND A.ProcSeq = B.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.Status = 0  
          AND A.AssyItemSeq <> B.AssyItemSeq  
          AND A.WorkingTag IN ('A', 'U')            -- 2011. 8. 29 hkim 삭제시에는 체크가 필요없음   
  
    -------------------------------------------  
    -- 작업지시수량 초과여부체크  
    -------------------------------------------  
    EXEC dbo._SCOMEnv @CompanySeq,6218,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    IF  @EnvValue IN ('1','True')   -- 작업지시수량초과불가  
    BEGIN  
  
        CREATE TABLE #WRQty  
        (  
            WorkOrderSeq        INT,  
            WorkOrderSerl       INT,  
            Qty                 DECIMAL(19,5)  
        )  
  
        CREATE TABLE #WRQtySum  
        (  
            WorkOrderSeq        INT,  
            WorkOrderSerl       INT,  
            Qty                 DECIMAL(19,5),  
            OrdQty              DECIMAL(19,5)  
        )  
  
  
        INSERT #WRQty  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, A.OKQty  
          FROM _TPDSFCWorkReport    AS A WITH(NOLOCK)  
         WHERE A.CompanySeq = @CompanySeq  
           AND EXISTS(SELECT 1 FROM #TPDSFCWorkReport   
                              WHERE WorkingTag IN ('A','U')  
                                AND Status = 0  
                                AND WorkOrderSeq = A.WorkOrderSeq   
                                AND WorkOrderSerl = A.WorkOrderSerl   
                                AND WorkReportSeq <> A.WorkReportSeq)  
  
  
        INSERT #WRQty  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, A.OKQty  
          FROM #TPDSFCWorkReport    AS A   
         WHERE A.WorkingTag IN ('A','U')  
           AND A.Status = 0  
  
  
        INSERT #WRQtySum  
        SELECT A.WorkOrderSeq, A.WorkOrderSerl, SUM(A.Qty) , 0  
          FROM #WRQty       AS A   
         GROUP BY A.WorkOrderSeq, A.WorkOrderSerl  
  
  
  
        UPDATE A  
           SET OrdQty = W.OrderQty  
          FROM #WRQtySum            AS A   
            JOIN _TPDSFCWorkOrder   AS W ON A.WorkOrderSeq = W.WorkOrderSeq  
                                        AND A.WorkOrderSerl = W.WorkOrderSerl  
                                        AND W.CompanySeq = @CompanySeq  
  
    -- 2011. 4. 4 hkim 이 환경설정은 안쓰지만, 오래전에 진행중인 사이트에 대해서 해당 환경설정이 사용중인 경우 오류 메시지가 잘못 출력 될 수 있어서 추가  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1268               , -- @1에 @2이 등록되어 있지 않습니다.    
                           @LanguageSeq,    
                           25598,'생산실적수량',    
                           16930,'작업지시작업지시'    
  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport AS A  
         WHERE A.WorkingTag IN ('A','U')  
           AND A.Status = 0  
           AND EXISTS(SELECT 1 FROM #WRQtySum WHERE WorkOrderSeq = A.WorkOrderSeq AND WorkOrderSerl = A.WorkOrderSerl AND Qty > OrdQty)  
  
  
    END  
  
    -- 생산실적에서 워크센터 변경 되지 않도록 수정 2010. 12. 20 hkim (수불에 문제 생길수 있다)  
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport      AS A  
                             JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
                       WHERE A.WorkingTag IN ('U')  
                         AND A.Status = 0  
                         AND B.CompanySeq = @CompanySeq  
                         AND A.WorkCenterSeq <> B.WorkCenterSeq)  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                                @LanguageSeq       ,   
                              1059,''     
        UPDATE #TPDSFCWorkReport  
           SET Result       = REPLACE(@Results, '@2', (SELECT Word FROM _TCADictionary WHERE WordSeq = 282 AND LanguageSeq = @LanguageSeq)),  
               MessageType  = @MessageType,  
               Status       = @Status  
          FROM #TPDSFCWorkReport      AS A  
               JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
         WHERE A.WorkingTag IN ('U')  
           AND A.Status = 0  
           AND B.CompanySeq = @CompanySeq  
           AND A.WorkCenterSeq <> B.WorkCenterSeq  
    END           
  
    -------------------------------------------  
    -- 진행여부체크  
    -------------------------------------------  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다.  
                          @LanguageSeq  
      
    -- 환경설정값 가져오기 (최종공정 생산실적 작성시 자동입고처리 여부  
    EXEC dbo._SCOMEnv @CompanySeq,6202,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    IF  @EnvValue IN ('1','True','6069001','6069003') AND EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE IsLastProc = '1')  
     BEGIN  
        IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport AS A   
                                 JOIN _TPDBaseWorkCenter AS B ON A.WorkCenterSeq = B.WorkCenterSeq  
                           WHERE B.CompanySeq = @CompanySeq         -- 2011. 3. 7 hkim 법인코드 안걸려 있어서 수정  
                             AND B.ProdInWhSeq = 0)  
             AND NOT EXISTS (SELECT 1  FROM #TPDSFCWorkReport  AS A  -- 2011. 3. 8 hkim 동방 아그로 요청(자동입고시 품목별기본창고) 사용한다고 해서  
                                            JOIN _TDAItemStdWh AS B ON A.GoodItemSeq = B.ItemSeq  
                                      WHERE B.CompanySeq = @CompanySeq AND A.FactUnit = B.FactUnit AND  B.InWHSeq > 0)  
         BEGIN  
            EXEC dbo._SCOMMessage     @MessageType OUTPUT,          
                                      @Status      OUTPUT,          
                                      @Results     OUTPUT,          
                                      1170               , -- @1에 @2이 등록되어 있지 않습니다.        
                                      @LanguageSeq       ,           
                                      1059,'워크센터'    ,          
                                      6451,'생산입고창고'      
                      
             UPDATE A          
               SET A.Result        = @Results     ,          
                   A.MessageType   = @MessageType ,          
                   A.Status        = @Status          
              FROM #TPDSFCWorkReport AS A   
                   JOIN _TPDBaseWorkCenter AS B ON A.WorkCenterSeq = B.WorkCenterSeq  
              WHERE B.CompanySeq  = @CompanySeq   -- 2011. 3. 7 hkim 법인코드 안걸려 있어서 수정  
                AND B.ProdInWhSeq = 0    
      AND A.Status = 0     
                AND NOT EXISTS(SELECT 1 FROM _TDAItemStdWh WHERE ItemSeq = A.GoodItemSeq AND FactUnit = A.FactUnit AND  InWHSeq > 0 AND CompanySeq = @CompanySeq)  
  
  
         END         
     END  
  
  
    -------------------------------------------  
    -- 입고여부체크                     -- 12.04.25 BY 김세호  
    -------------------------------------------  
  
    IF @EnvValue  IN ('', '0',  '6069002', '6069003')  -- 입고여부 체크시 환경설정값 '0' 인경우도 추가      -- 12.06.18 BY 김세호  
                                                       -- (환경설정 이젠세팅값 그대로 사용할경우 '0'으로 가져오기때문에)  
     BEGIN  
  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다.  
                              @LanguageSeq      
  
  
        IF @EnvValue = '6069003'    -- 반제품만 자동입고 인 경우 반제품만 진행여부를 체크하지 않는다.   
        BEGIN   
            UPDATE A   
               SET Result        = @Results     ,  
MessageType   = @MessageType ,  
                   Status        = @Status  
            FROM #TPDSFCWorkReport AS A   
            JOIN _TPDSFCGoodIn     AS B ON A.WorkReportSeq = B. WorkReportSeq  
                                       AND @CompanySeq = B.CompanySeq  
            JOIN _TDAItem           AS I ON A.GoodItemSeq = I.ItemSeq  
            JOIN _TDAItemAsset      AS S ON I.AssetSeq = S.AssetSeq  
                                        AND I.CompanySeq = S.CompanySeq                      
            WHERE Status = 0   
              AND WorkingTag IN ('U', 'D')  
              AND I.CompanySeq = @CompanySeq  
              AND S.SMAssetGrp <> 6008004  
        END  
  
        ELSE  
        BEGIN  
            UPDATE A   
               SET Result        = @Results     ,  
                   MessageType   = @MessageType ,  
                   Status        = @Status  
            FROM #TPDSFCWorkReport AS A   
            JOIN _TPDSFCGoodIn     AS B ON A.WorkReportSeq = B. WorkReportSeq  
                                       AND @CompanySeq = B.CompanySeq  
            WHERE Status = 0   
              AND WorkingTag IN ('U', 'D')  
  
        END  
  
  
  
     END  
  
  
--    IF  @EnvValue NOT IN ('1','True','6069001')   -- 최종공정 생산실적 작성시 자동입고처리 여부  
--    BEGIN  
--  
--        EXEC dbo._SCOMProgressCheck     @CompanySeq             ,  
--                                        '_TPDSFCWorkReport'      ,  
--                                        1                       ,  
--                                        '#TPDSFCWorkReport'      ,  
--                                        'WorkReportSeq'          ,  
--                                        ''         ,  
--                                        ''                      ,  
--                                        'Status'  
--  
--        IF @EnvValue = '6069003'    -- 반제품만 자동입고 인 경우 반제품만 진행여부를 체크하지 않는다.   
--        BEGIN   
--  
--            UPDATE #TPDSFCWorkReport  
--               SET Status        = 0  
--              FROM #TPDSFCWorkReport    AS A  
--                JOIN _TDAItem           AS I ON A.GoodItemSeq = I.ItemSeq  
--                JOIN _TDAItemAsset      AS S ON I.AssetSeq = S.AssetSeq  
--             WHERE A.WorkingTag IN ('U','D')  
--               AND A.Status = 1  
--               AND I.CompanySeq = @CompanySeq  
--               AND S.CompanySeq = @CompanySeq  
--               AND S.SMAssetGrp = 6008004  
--  
--  
--        END   
--  
--  
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport AS A  
--         WHERE A.WorkingTag IN ('U','D')  
--           AND A.Status = 1  
--  
--    END  
  
  
    -------------------------------------------  
    -- 검사여부체크 (검사가 진행연결이 안 된 관계로.)  
    -------------------------------------------  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
           JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
                      AND B.CompanySeq = @CompanySeq  
             AND B.SourceType IN ('3')   -- 3: 최종, 4: 공정검사  
                             JOIN _TPDBaseItemQCType AS C ON A.GoodItemSeq = C.ItemSeq  
                                                    AND C.CompanySeq = @CompanySeq  
     WHERE A.WorkingTag IN ('U','D')  
       AND A.Status = 0  
       AND A.IsLastProc = '1'   
       AND C.IsLastQc = '1')  
 BEGIN      
  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
         @Status      OUTPUT,  
         @Results     OUTPUT,  
         1006               , -- @1은(는) @2의 @3을(를) 초과할 수 없습니다.  
         @LanguageSeq,  
         9410 , '최종검사'  
  
  UPDATE #TPDSFCWorkReport  
     SET Result        = @Results     ,  
      MessageType   = @MessageType ,  
      Status        = @Status  
    FROM #TPDSFCWorkReport    AS A  
   JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
          AND B.CompanySeq = @CompanySeq  
          AND B.SourceType IN ('3')   -- 3: 최종, 4: 공정검사  
   WHERE A.WorkingTag IN ('U','D')  
     AND A.Status = 0  
 END       
  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
           JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
                      AND B.CompanySeq = @CompanySeq  
             AND B.SourceType IN ('4')   -- 3: 최종, 4: 공정검사  
     WHERE A.WorkingTag IN ('U','D')  
       AND A.Status = 0)  
 BEGIN  
  EXEC dbo._SCOMMessage @MessageType OUTPUT,  
         @Status      OUTPUT,  
         @Results     OUTPUT,  
         1006               , -- @1은(는) @2의 @3을(를) 초과할 수 없습니다.  
         @LanguageSeq,  
         3965 , '공정검사'  
  
  UPDATE #TPDSFCWorkReport  
     SET Result        = @Results     ,  
      MessageType   = @MessageType ,  
      Status        = @Status  
    FROM #TPDSFCWorkReport    AS A  
   JOIN _TPDQCTestReport   AS B ON A.WorkReportSeq = B.SourceSeq  
          AND B.CompanySeq = @CompanySeq  
          AND B.SourceType IN ('4')   -- 3: 최종, 4: 공정검사  
   WHERE A.WorkingTag IN ('U','D')  
     AND A.Status = 0  
 END       
  
  
  
  
 ------------------------------------------------------------------  
 -- 최종공정 여부 누락되는 것 때문에 체크로직 추가 2010. 7. 26 hkim  
 -- 해당 실적건의 공정흐름이나 제품별공정에 최종공정여부가 체크되어 있으나 저장 데이터는 체크 되어 있지 않을 경우  
 ------------------------------------------------------------------  
 -- 공정흐름유형 사용하는 경우  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
        JOIN _TPDROUItemProcRev AS B ON A.GoodItemSeq = B.ItemSeq  
               AND A.ProcRev   = B.ProcRev  
        JOIN _TPDProcTypeItem  AS C ON B.CompanySeq  = C.CompanySeq  
               AND B.ProcTypeSeq = C.ProcTypeSeq  
               AND A.ProcSeq   = C.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.IsLastProc <> '1'  
          AND C.IsLastProc = '1'  
          AND A.WorkingTag IN ('A', 'U')  
          AND A.Status   = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
                              @LanguageSeq,  
                              0 , '최종공정여부'  -- SELect * from _TCADictionary where Word like '외주%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport    AS A  
      JOIN _TPDROUItemProcRev AS B ON A.GoodItemSeq = B.ItemSeq  
           AND A.ProcRev   = B.ProcRev  
      JOIN _TPDProcTypeItem AS C ON B.CompanySeq  = C.CompanySeq  
           AND B.ProcTypeSeq = C.ProcTypeSeq  
           AND A.ProcSeq   = C.ProcSeq  
   WHERE B.CompanySeq = @CompanySeq  
     AND A.IsLastProc <> '1'  
     AND C.IsLastProc = '1'  
     AND A.WorkingTag IN ('A', 'U')  
     AND A.Status   = 0  
 END    
 -- 제품별 공정 사용하는 경우  
 ELSE IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport   AS A  
        JOIN _TPDROUItemProc  AS B ON A.GoodItemSeq = B.ItemSeq  
               AND A.ProcRev   = B.ProcRev  
               AND A.ProcSeq   = B.ProcSeq  
        WHERE B.CompanySeq = @CompanySeq  
          AND A.IsLastProc <> '1'  
          AND B.IsLastProc = '1'  
          AND A.WorkingTag IN ('A', 'U')  
          AND A.Status   = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1196               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
                              @LanguageSeq,  
                              0 , '최종공정여부'  -- SELect * from _TCADictionary where Word like '외주%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
        JOIN _TPDROUItemProc  AS B ON A.GoodItemSeq = B.ItemSeq  
           AND A.ProcRev   = B.ProcRev  
           AND A.ProcSeq   = B.ProcSeq  
   WHERE B.CompanySeq = @CompanySeq  
     AND A.IsLastProc <> '1'  
     AND B.IsLastProc = '1'  
     AND A.WorkingTag IN ('A', 'U')  
     AND A.Status   = 0  
 END                           
 ------------------------------------------------------------------  
 -- 최종공정 여부 누락되는 것 때문에 체크로직 추가 2010. 7. 26 hkim  
 -- 해당 실적건의 공정흐름에 최종공정여부가 체크되어 있으나 저장 데이터는 체크 되어 있지 않을 경우  
 -- 추가 로직 끝 --  
 ------------------------------------------------------------------  
  
  
    ------------------------------------------------------------------    
    -- 프로젝트건일경우(자동생성되는건임) 변경 불가하도록 추가       2011.12.20 BY 김세호   
    ------------------------------------------------------------------    
    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE IsPjt = '1' AND Status = 0)    
    BEGIN    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1307                , -- @1의 경우 @2을(를) 할 수 없습니다.  
                              @LanguageSeq,    
                              353 , '',          -- 프로젝트   
                              13823 , ''          -- 변경   
  
        UPDATE #TPDSFCWorkReport    
           SET Result        = @Results     ,    
               MessageType   = @MessageType ,    
               Status        = @Status    
          FROM #TPDSFCWorkReport    
        WHERE IsPjt = '1'   
          AND Status = 0  
          AND @PgmSeq IN (200125, 1015) -- 일자별재고원장조회 조회에서 프로젝트건 점프인시 '생산실적입력' 화면으로 점프되기때문에   
                                        -- 프로젝트건은 '생산실적입력' 화면상에서 수정 안되도록 막는다      -- 12.03.29 BY 김세호  
  
  
    END    
  
 ------------------------------------------------------------------  
 -- 간혹 부서, 사원이 누락되는 경우가 있어 체크로직 추가 2010. 10. 13 hkim  
 ------------------------------------------------------------------  
 IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE (DeptSeq = 0 OR DeptSeq IS NULL) AND WorkingTag IN ('A', 'U') AND Status = 0)  
 BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              133                , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
                              @LanguageSeq,  
                              0 , ''  -- SELect * from _TCADictionary where Word like '외주%'  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
   WHERE (A.DeptSeq = 0 OR A.DeptSeq IS NULL )  
     AND A.WorkingTag IN ('A', 'U')  
           AND A.Status = 0  
 END     
   
  
    -- #################################################################################################################################  
    -- 실적을 등록 후에, 작업지시번호를 코드도움으로 다른 작업지시로 바꿔서 업데이트 하는 경우도 있어서, 오류처리 추가 2011. 12. 19 hkim  
    IF EXISTS (SELECT 1 FROM _TPDSFCWorkReport      AS A  
                             JOIN #TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq  
                       WHERE A.CompanySeq = @CompanySeq  
                         AND B.WorkingTag IN ('U')  
                         AND B.Status = 0  
                         AND (A.WorkOrderSeq <> B.WorkOrderSeq OR (A.WorkOrderSeq = B.WorkOrderSeq AND A.WorkOrderSerl <> B.WorkOrderSerl) ) )  
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1307               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
                              @LanguageSeq,  
                                1985 , '작업지시번호' ,  -- SELect * from _TCADictionary where Word  like '작업지시번호%'  
                              13823 , '변경'   
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport  AS A  
               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
   WHERE A.WorkingTag IN ('U')  
     AND B.CompanySeq = @CompanySeq  
     AND A.Status = 0  
           AND (A.WorkOrderSeq <> B.WorkOrderSeq OR (A.WorkOrderSeq = B.WorkOrderSeq AND A.WorkOrderSerl <> B.WorkOrderSerl) )  
    END                           
                                                        
  
    -- #################################################################################################################################  
  
-- 무검사품으로 최종공정 실적 생성시 최종검사데이터 자동으로 생성해주면서 하기 체크 로직 주석처리       -- 12.03.19 BY 김세호  
--    -- #################################################################################################################################  
--    --무검사품으로 자동입고 진행 한 후에 검사품으로 실적 삭제시 입고데이터 남고 실적 삭제되는 오류 체크 2011. 12. 22 hkim  
--    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
--                                        JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq AND D.IsLastQC = '1'  
--                             LEFT OUTER JOIN _TPDSFCGoodIn      AS B ON A.WorkReportSeq = B.WorkReportSeq AND B.CompanySeq = @CompanySeq  
--                             LEFT OUTER JOIN _TPDQCTestReport   AS C ON A.WorkReportSeq = C.SourceSeq AND C.SourceType = '3' AND C.CompanySeq = @CompanySeq  
--                       WHERE A.WorkingTag IN ('D')  
--                         AND A.Status = 0  
--                         AND B.GoodInSeq IS NOT NULL   
--                         AND C.QCSeq IS NULL)   
--        AND @EnvValue IN ('1','True','6069001','6069003')    
--    BEGIN  
--        DECLARE @ResultLast NVARCHAR(MAX)  
--        SELECT @ResultLast = ''  
--          
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              1330               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
--                              @LanguageSeq,  
--                              0 , ''   -- SELect * from _TCADictionary where Word like '검사%'  
--          
--        --SELECT @ResultLast = @ResultLast +  @Results  
--                                       
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results, --'자동입고이고, 검사품으로 최종검사데이터 없이, 입고데이터가 있으므로 삭제할 수 없습니다.'     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport  AS A  
--               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
--   WHERE A.WorkingTag IN ('D')  
--     AND B.CompanySeq = @CompanySeq  
--     AND A.Status = 0  
--   
--    END   
--    --#################################################################################################################################  
  
--    -- #################################################################################################################################  
--    --검사품으로 자동입고 진행 한 후에 무검사품으로 실적 삭제시 검사데이터 남고 실적,입고 삭제되는 오류 체크 2011. 12. 22 hkim  
--    IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
--                                        JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq AND D.IsLastQC = '0'  
--                             LEFT OUTER JOIN _TPDSFCGoodIn      AS B ON A.WorkReportSeq = B.WorkReportSeq AND B.CompanySeq = @CompanySeq  
--                             LEFT OUTER JOIN _TPDQCTestReport   AS C ON A.WorkReportSeq = C.SourceSeq AND C.SourceType = '3' AND C.CompanySeq = @CompanySeq  
--                       WHERE A.WorkingTag IN ('D')  
  --                          AND A.Status = 0  
--                         AND B.GoodInSeq IS NOT NULL   
--                         AND C.QCSeq IS NOT NULL)   
--        AND @EnvValue IN ('1','True','6069001','6069003')    
--    BEGIN  
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              1331               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
--                              @LanguageSeq,  
--                              0 , ''   -- SELect * from _TCADictionary where Word like '검사%'  
--          
--        --SELECT @ResultLast = @ResultLast +  @Results  
--                                       
--        UPDATE #TPDSFCWorkReport  
--           SET Result        = @Results, --'자동입고이고, 최종검사 데이터 있는데, 무검사품으로 변경했으므로 삭제할 수 없습니다.'     ,  
--               MessageType   = @MessageType ,  
--               Status        = @Status  
--          FROM #TPDSFCWorkReport  AS A  
--               JOIN _TPDSFCWorkReport   AS B ON A.WorkReportSeq = B.WorkReportSeq  
--   WHERE A.WorkingTag IN ('D')  
--     AND B.CompanySeq = @CompanySeq  
--     AND A.Status = 0  
--   
--    END   
--    --#################################################################################################################################  
  
      
--    -------------------------------------------  
--    -- 다음공정에 투입된 공정품은 수정삭제를 할 수 없다.   
--    -------------------------------------------  
--  
--  
--    UPDATE #TPDSFCWorkReport  
--       SET Result        = @Results     ,  
--           MessageType   = @MessageType ,  
--           Status        = @Status  
--      FROM #TPDSFCWorkReport AS A  
--     WHERE A.WorkingTag IN ('U','D')  
--       AND A.Status = 0  
--       AND EXISTS (SELECT 1 FROM _TPDSFCMatinput    AS M WITH(NOLOCK)  
--                            JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON M.CompanySeq = R.CompanySeq  
--                                                                     AND M.WorkReportSeq = R.WorkReportSeq  
--                       WHERE M.CompanySeq   = @CompanySeq   
--                             AND R.WorkOrderSeq = A.WorkOrderSeq  
--                             AND M.MatItemSeq   = A.AssyItemSeq )  
  
  
    ----======================================================================--  
    ------ 생산수량을 0을 넣고 저장 할 경우 저장이 안되도록 Check 로직 추가 ---- 2014.01.10 김용현 추가  
    ----======================================================================--  
      
    --IF EXISTS ( SELECT 1 FROM #TPDSFCWorkReport WHERE ProdQty = 0 AND WorkingTag IN ('A','U' ) AND Status = 0 )  
    --BEGIN  
         
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1331               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수   
    --                          @LanguageSeq,  
    --                          0 , ''   --   
          
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = '생산수량을 0 으로 입력 할 수 없습니다. 생산수량을 확인하세요.'     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport AS A  
    --     WHERE A.WorkingTag IN ('A','U')  
    --       AND A.Status = 0  
    --       AND A.ProdQty = 0   
      
      
    --END  
  
    -------------------------------------------  
    -- LotNo 자동부여 체크 6068003    
    -------------------------------------------  
  
    DECLARE @DataSeq    INT ,  
            @Date       NCHAR(8),  
            @FactUnit   INT ,  
            @MaxNo      NVARCHAR(20)  
    IF @Env6213 = '6068003'  
    BEGIN  
        SELECT @DataSeq = 0  
  
        WHILE (1=1)  
        BEGIN  
  
            SELECT TOP 1 @DataSeq = DataSeq,  
                         @Date = WorkDate,  
                         @FactUnit = FactUnit  
              FROM #TPDSFCWorkReport   
               WHERE  DataSeq      > @DataSeq  
               AND WorkingTag   = 'A'  
               AND Status       = 0  
               AND RealLotNo    = ''  
             ORDER BY DataSeq  
  
            IF @@ROWCOUNT = 0   
                BREAK  
  
            EXEC   dbo._SCOMCreateNo    'PD'                , -- 생산(HR/AC/SL/PD/ESM/PMS/SI/SITE)  
                                        '_TPDSFCWorkReport' , -- 테이블  
                                        @CompanySeq         , -- 법인코드  
                                        @FactUnit           , -- 부문코드  
                                        @Date               ,  -- 취득일  
                                        @MaxNo OUTPUT  
  
            UPDATE #TPDSFCWorkReport  
               SET RealLotNo = @MaxNo  
             WHERE DataSeq = @DataSeq  
  
        END  
    END   
  
    -------------------------------------------  
    -- 공정흐름유형차수가 없는 경우 디폴트 '00' (관리 안하는 곳도 많기 때문)  
    -------------------------------------------  
    UPDATE #TPDSFCWorkReport  
       SET ProcRev = '00'  
     WHERE ProcRev = ''  
  
    -------------------------------------------  
    -- 외주용역비 전표 생성 여부  
    -------------------------------------------  
--    DECLARE @EnvValue NCHAR(1)  
--    SELECT @EnvValue = EnvValue from _TCOMEnv where EnvSeq = 6513 AND CompanySeq = @CompanySeq  
    EXEC dbo._SCOMEnv @CompanySeq,6513,@UserSeq,@@PROCID,@EnvValue OUTPUT  
  
    -- '1' 생산입고기준, '0' 생산실적기준  
    IF @EnvValue = '0'   
    BEGIN  
  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1109               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'  
                              @LanguageSeq,  
                              0 , '외주용역비전표'  -- SELect * from _TCADictionary where Word like '외주%'  
  
        UPDATE #TPDSFCWorkReport  
           SET Result        = @Results     ,  
               MessageType   = @MessageType ,  
               Status        = @Status  
          FROM #TPDSFCWorkReport    AS A  
            JOIN _TPDSFCOutsourcingCostItem   AS B ON A.WorkReportSeq = B.WorkReportSeq  
                                                  AND B.CompanySeq = @CompanySeq  
                                                  AND B.SlipSeq > 0  
                                          
         WHERE A.WorkingTag IN ('U','D')  
           AND A.Status = 0  
    END  
      
    -------------------------------------------    
    -- 생산실적에서 Update,Delete시 사내외주용역비 테이블 데이터 유무 체크         --2014.07.02 hjlim 추가  
    -------------------------------------------    
    -- '1' 생산입고기준, '0' 생산실적기준    
    IF @EnvValue = '0'     
    BEGIN    
    
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1109               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%수정%'    
                              @LanguageSeq,    
                              1165, '테이블'  -- SELect * from _TCADictionary where Word like '%테이블%'    
    
        UPDATE #TPDSFCWorkReport    
           SET Result        = @Results     ,    
               MessageType   = @MessageType ,    
               Status        = @Status    
          FROM #TPDSFCWorkReport    AS A                                       
         WHERE A.WorkingTag IN ('U','D')    
           AND A.Status = 0    
           AND EXISTS ( SELECT 1 FROM _TPDSFCOutsourcingCostItem WHERE CompanySeq    = @CompanySeq   
                                                                   AND WorkReportSeq = A.WorkReportSeq  
                                                                   AND SlipSeq       = 0 )  
    END    
  
    ---------------------------------------------  
    ---- 비정상적인 시간 체크(00:00~24:00 가능)  
    ---------------------------------------------  
  
      --    --작업시작시간 에러!      --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1196               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%확인%'  
    --                          @LanguageSeq,  
    --                          8254 , '작업시작시간'  -- SELect * from _TCADictionary where Word like '작업%시간'  
  
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = @Results     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport    AS A  
                                          
    --     WHERE A.WorkingTag IN ('U','D','A')  
    --       AND A.Status = 0  
    --       AND (LEFT(CONVERT(INT, WorkStartTime), 2) >= 24 OR RIGHT(CONVERT(INT, WorkStartTime), 2) >= 60)  
          
    --    --작업종료시간 에러!      
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                          @Status      OUTPUT,  
    --                          @Results     OUTPUT,  
    --                          1196               , -- @1에 적용된 내역이 있으므로 수정/삭제할 수 없습니다. SELECT * FROM _TCAMessageLanguage WHERE Message like '%확인%'  
    --                          @LanguageSeq,  
    --                          8276 , '작업종료시간'  -- SELect * from _TCADictionary where Word like '작업%시간'  
  
    --    UPDATE #TPDSFCWorkReport  
    --       SET Result        = @Results     ,  
    --           MessageType   = @MessageType ,  
    --           Status        = @Status  
    --      FROM #TPDSFCWorkReport    AS A  
                                          
    --     WHERE A.WorkingTag IN ('U','D','A')  
    --       AND A.Status = 0  
   --       AND (LEFT(CONVERT(INT, WorkEndTime), 2) >= 24 OR RIGHT(CONVERT(INT, WorkEndTime), 2) >= 60)  
  
  
  
--    -------------------------------------------  
--    -- 최종공정이고, 무검사품이면 실적저장시 QC데이터 생성해주는데,   
--    -- 검사Seq, No 실적체크SP상에서 채번해준다(test_SPDSFCWorkReportSave에서 채번할경우 트랜잭션문제때문에)     -- 12.03.14 BY 김세호  
--    -------------------------------------------  
--  
--    IF EXISTS( SELECT 1 FROM #TPDSFCWorkReport  AS A  
--                        JOIN _TPDBaseItemQCType AS B ON A.GoodItemSeq = B.ItemSeq  
--                                                    AND B.CompanySeq = @CompanySeq  
--                        WHERE A.IsLastProc = '1' AND B.IsLastQc <> '1' AND A.Status = 0 AND A.WorkingTag = 'A')  
--      BEGIN  
--  
--  
--      END  
    -------------------------------------------  
    -- INSERT 번호부여(맨 마지막 처리)  
    -------------------------------------------  
    SELECT @Count = COUNT(1) FROM #TPDSFCWorkReport WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCWorkReport', 'WorkReportSeq', @Count  
  
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #TPDSFCWorkReport  
           SET WorkReportSeq   = @Seq + DataSeq  
         WHERE WorkingTag   = 'A'  
           AND Status       = 0  
  
        -- 자동입고를 설정해서 사용할 경우 GoodInSeq를 test_SPDSFCWorkReportSave 안에 _SPDSFCGoodInCheck에서 채번되지 않도록 하기 위해서 여기서부터 채번해준다 2011. 8. 2. hkim  
        --IF EXISTS (SELECT 1 FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 6202 AND EnvValue IN (6069001, 6069003) )  
        --BEGIN --코미코 MES연동때문에 해당 환경설정 값에 따라서 채번 되는 부분 제외  
            EXEC @GoodInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDSFCGoodIn', 'GoodInSeq', @Count  
              
             UPDATE #TPDSFCWorkReport  
               SET GoodInSeq   = @GoodInSeq + DataSeq  
             WHERE WorkingTag   = 'A'  
               AND Status       = 0   
        --END  
  
  
        -- 최종공정 무검사품일경우, 최종검사데이터 생성해주는데, QCSeq 실적체크 SP상에서 해주기위해 추가      -- 12.03.18 김세호 추가  
        IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport                  AS A  
                              LEFT OUTER JOIN _TPDBaseItemQCType AS D ON A.GoodItemSeq   = D.ItemSeq AND D.CompanySeq = @CompanySeq    
                            WHERE A.WorkingTag = 'A'  
                            AND A.Status = 0  
                            AND A.IsLastProc = '1'  
                            AND ISNULL(D.IsLastQC, '0') = '0')  
         BEGIN  
  
              SELECT @DataSeq = 0  
              SELECT TOP 1 @Date = WorkDate FROM #TPDSFCWorkReport   
              
              EXEC @QCSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPDQCTestReport', 'QCSeq', @Count     
  
              -- 생산실적입력시 무검사품- 최종공정 건이 여러건일 수 있으므로 loop돌면서 채번   
              WHILE( 1 > 0)     
              BEGIN    
                   SELECT TOP 1 @DataSeq = DataSeq        
                    FROM #TPDSFCWorkReport            
                    WHERE  WorkingTag = 'A'            
                       AND Status = 0            
                       AND DataSeq > @DataSeq            
                     ORDER BY DataSeq            
            
                      IF @@ROWCOUNT = 0 BREAK          
  
                   EXEC dbo._SCOMCreateNo 'PD', '_TPDQCTestReport', @CompanySeq, '', @Date, @QCNo OUTPUT    
  
                   UPDATE #TPDSFCWorkReport    
                      SET QCSeq = @QCSeq + DataSeq, -- 여러건이 들어올 경우 While을 돌면서 한건식 처리하기 때문에 1을 더해줌    
                       QCNo  = @QCNo    
                    WHERE WorkingTag = 'A'    
                      AND Status  = 0    
                      AND DataSeq = @DataSeq     
                      
              END   
          END  
  
    END  
      
  
  
    SELECT * FROM #TPDSFCWorkReport  
    RETURN  
/*******************************************************************************************************************/
GO

begin tran
exec KPXLS_SPDSFCWorkReportCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemBomRevName>00</ItemBomRevName>
    <ProdQty>999999</ProdQty>
    <OKQty>999999</OKQty>
    <BadQty>0</BadQty>
    <ReOrderQty>0</ReOrderQty>
    <LossCostQty>0</LossCostQty>
    <DisuseQty>0</DisuseQty>
    <WorkStartTime />
    <WorkEndTime />
    <WorkHour>0</WorkHour>
    <ProcHour>0</ProcHour>
    <WorkerQty>0</WorkerQty>
    <RealLotNo>신희범</RealLotNo>
    <SerialNoFrom />
    <SerialNoTo />
    <WorkCondition1>20151130</WorkCondition1>
    <WorkCondition2 />
    <WorkCondition3 />
    <WorkCondition4>0</WorkCondition4>
    <WorkCondition5>0</WorkCondition5>
    <WorkCondition6>0</WorkCondition6>
    <StdUnitReOrderQty>0</StdUnitReOrderQty>
    <StdUnitLossCostQty>0</StdUnitLossCostQty>
    <StdUnitDisuseQty>0</StdUnitDisuseQty>
    <Remark />
    <ProcRev>00</ProcRev>
    <WorkReportSeq>31</WorkReportSeq>
    <WorkOrderSeq>45</WorkOrderSeq>
    <WorkCenterSeq>38</WorkCenterSeq>
    <GoodItemSeq>4808</GoodItemSeq>
    <AssyItemSeq>4808</AssyItemSeq>
    <ProcSeq>13</ProcSeq>
    <ProdUnitSeq>1</ProdUnitSeq>
    <ChainGoodsSeq>0</ChainGoodsSeq>
    <EmpSeq>0</EmpSeq>
    <WorkOrderSerl>46</WorkOrderSerl>
    <IsProcQC>0</IsProcQC>
    <IsLastProc>1</IsLastProc>
    <IsPjt>0</IsPjt>
    <PJTSeq>0</PJTSeq>
    <WBSSeq>0</WBSSeq>
    <SubEtcInSeq>0</SubEtcInSeq>
    <WorkTimeGroup>0</WorkTimeGroup>
    <QCSeq>0</QCSeq>
    <QCNo />
    <PreProdWRSeq>0</PreProdWRSeq>
    <PreAssySeq>0</PreAssySeq>
    <PreAssyQty>0</PreAssyQty>
    <PreLotNo />
    <PreUnitSeq>0</PreUnitSeq>
    <FactUnit>1</FactUnit>
    <CustSeq>0</CustSeq>
    <WorkType>6041007</WorkType>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkDate>20151130</WorkDate>
    <DeptSeq>3</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033535,@WorkingTag=N'D',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015
rollback 