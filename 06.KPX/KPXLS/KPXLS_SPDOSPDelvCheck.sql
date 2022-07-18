IF OBJECT_ID('KPXLS_SPDOSPDelvCheck') IS NOT NULL 
    DROP PROC KPXLS_SPDOSPDelvCheck
GO 

-- v2016.02.22 

-- 수입검사의뢰 데이터가 있을 경우 수정삭제 불가 추가 by이재천 
/************************************************************
설  명 - 구매견적체크
작성일 - 2008년 8월 20일 
작성자 - 노영진
수정내용

-- 2011.03.03   외주창고 없는경우 에러체크  UPDATE BY 김세호
-- 2011.11.03   생산외주창고체크시 창고사용여부 조건 추가  UPDATE BY 김세호
************************************************************/

CREATE PROC KPXLS_SPDOSPDelvCheck
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10) = '',    
    @CompanySeq     INT = 0,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    
    
    -- 변수 선언    
    DECLARE @Count       INT,      
            @DataSeq     INT,      
            @OSPDelvSeq  INT,       
            @OSPDelvNo   NVARCHAR(12),      
            @BaseDate    NVARCHAR(8),      
            @MaxNo       NVARCHAR(12),      
            @BizUnit     INT,      
            @MaxQutoRev  INT,
            @MessageType INT,      
            @Status      INT,      
            @Results     NVARCHAR(250)            

  
    -- 임시 테이블 생성  _TPDOSPDelv    
    CREATE TABLE #TPDOSPDelv (WorkingTag NCHAR(1) NULL)    
    -- 임시 테이블에 지정된 컬럼을 추가하고, xml로부터의 값을 insert한다.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDOSPDelv'       

    CREATE TABLE #TPDOSPDelvIn (WorkingTag NCHAR(1) NULL)    
    -- 임시 테이블에 지정된 컬럼을 추가하고, xml로부터의 값을 insert한다.    
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2979, 'DataBlock1', '#TPDOSPDelvIn'       
    
    
    -- 체크1, 수입검사의뢰 데이터가 존재하여 수정/삭제 할 수 없습니다. 
    UPDATE A
       SET Result = '수입검사의뢰 데이터가 존재하여 수정/삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPDOSPDelv AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0  
       AND EXISTS (SELECT 1 FROM KPXLS_TQCRequest WHERE CompanySeq = @CompanySeq AND FromPgmSeq = 1028274 AND SourceSeq = A.OSPDelvSeq)
    -- 체크1, END 
    
    
    SELECT TOP 1 @OSPDelvSeq = ISNULL(OSPDelvSeq, 0)   
      FROM #TPDOSPDelv  



     -------------------------------------------  
     -- 필수데이터체크  
     -------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                           @LanguageSeq       ,   
                           0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'          
     UPDATE #TPDOSPDelv  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
      WHERE OSPDelvDate = ''  
         OR OSPDelvDate IS NULL  

    
    -------------------------------------------
    -- 진행여부체크
    -------------------------------------------
    DECLARE @EnvValue   NVARCHAR(100)   -- 최종공정 생산실적 작성시 자동입고처리 여부

    -- 환경설정값 가져오기 외주품목 자동입고여부
    EXEC dbo._SCOMEnv @CompanySeq,6503,@UserSeq,@@PROCID,@EnvValue OUTPUT


    IF  @EnvValue NOT IN ('1','True') -- 외주품목 자동입고여부
       AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0)
    BEGIN 

        EXEC dbo._SCOMProgressCheck     @CompanySeq             ,
                                        '_TPDOSPDelvItem'      ,
                                        1                       ,
                                        '#TPDOSPDelv'      ,
                                        'OSPDelvSeq'          ,
                                        ''         ,
                                        ''                      ,
                                        'Status'

        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다.
                              @LanguageSeq

        UPDATE #TPDOSPDelv 
           SET Result        = @Results     ,
               MessageType   = @MessageType ,
               Status        = @Status
          FROM #TPDOSPDelv AS A
         WHERE A.WorkingTag IN ('U','D')
           AND A.Status = 1

    END 

    -- 자동입고여부와 상관없이 검사품 검사진행여부를 체크한다. 
    -- 시트삭제 아닐경우만 체크(무검사품/검사품을 한건으로 납품잡았을경우 무검사품 시트삭제시 /'하기 체크타면 안되므로,
    --                               시트삭제시 에는 품목체크SP 에서 하기 체크되도록 처리)           -- 12.11.15 BY 김세호
    IF  @WorkingTag <> 'SC' AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0)
    BEGIN 

        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              102               , -- @1 데이터가 존재합니다.  
                              @LanguageSeq  ,  
                              7908, ''  

        UPDATE #TPDOSPDelv 
           SET Result        = @Results     ,
               MessageType   = @MessageType ,
               Status        = @Status
          FROM #TPDOSPDelv AS A JOIN _TPDQCTestReport AS B ON A.OSPDelvSeq = B.SourceSeq and B.CompanySeq = @CompanySeq
                                                          AND B.SourceType = '2'
         WHERE A.WorkingTag IN ('U', 'D')
           AND A.Status = 0

    END 


    -- 자동입고이지만 전표까지 진행된 건은 수정되어서는 안된다(신규건 말고 수정건만 처리한다)
    IF @EnvValue IN ('1', 'True') AND EXISTS (SELECT 1 FROM #TPDOSPDelv WHERE WorkingTag IN ('U', 'D') AND Status = 0) AND @WorkingTag <> 'SC'  
    BEGIN
----------------------------------------------------------------------------
                            --입고진행여부-----
----------------------------------------------------------------------------
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT, TABLENAME   NVARCHAR(100))    
    
        CREATE TABLE #TCOMProgressTracking(IDX_NO INT, IDOrder INT, Seq INT,Serl INT, SubSerl INT,Qty DECIMAL(19, 5), StdQty DECIMAL(19,5) , Amt    DECIMAL(19, 5),VAT DECIMAL(19,5))      
    
        CREATE TABLE #OrderTracking(IDX_NO INT, Qty DECIMAL(19,5), POCurAmt DECIMAL(19,5))
    
        INSERT #TMP_PROGRESSTABLE     
        SELECT 1, '_TPDOSPDelvInItem'               -- 외주입고
        
        EXEC _SCOMProgressTracking @CompanySeq, '_TPDOSPDelvItem', '#TPDOSPDelv', 'OSPDelvSeq', '', ''    
        
        IF EXISTS (SELECT 1 FROM #TCOMProgressTracking)
        BEGIN
            UPDATE #TPDOSPDelvIn
               SET OSPDelvInSeq   = (SELECT TOP 1 Seq FROM #TCOMProgressTracking),
                   OSPDelvInDate  = (SELECT TOP 1 OSPDelvDate FROM #TPDOSPDelv),
                   WorkingTag     = (SELECT TOP 1 WorkingTag FROM #TPDOSPDelv)
            -- 체크
            EXEC _SPDOSPDelvInCheck     @xmlDocument    = N''           ,
                                        @xmlFlags       = @xmlFlags     ,
                                        @ServiceSeq     = 2979   ,
                                        @WorkingTag     = 'AUTO'  ,
                                        @CompanySeq     = @CompanySeq   ,
                                        @LanguageSeq    = @LanguageSeq  ,
                                        @UserSeq        = @UserSeq      ,
                                        @PgmSeq         = @PgmSeq
            IF @@ERROR <> 0 RETURN    
            
            UPDATE #TPDOSPDelv
               SET Status      = A.Status     ,
                   MessageType = A.MessageType,
                   Result      = A.Result
              FROM #TPDOSPDelvIn AS A
        END
    END


----------------------------------------------------------------------------
                           ----거래처 창고 체크-----                    -- 11.03.03 김세호 추가
----------------------------------------------------------------------------

  -- 생산사업장과 엮여있는 사업부문 코드 가져오기
  SELECT @BizUnit = B.BizUnit
    FROM #TPDOSPDelv AS A
      JOIN _TDAFactUnit   AS B ON A.FactUnit   = B.FactUnit
   WHERE B.CompanySeq = @CompanySeq


-- 해당 사업부문, 외주처에 걸린 생산외주창고가 없을경우     --11.10.19 김세호 수정

EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         1293         , 
         @LanguageSeq       , 
         21676, '',    
         14881, ''  

UPDATE #TPDOSPDelv                 
   SET MessageType = @MessageType,
       Status      = @Status,
       Result       = @Results
   FROM #TPDOSPDelv AS C
   WHERE  C.Status = 0 
      AND C.WorkingTag IN ('A', 'U')
      AND NOT EXISTS (SELECT 1
           FROM #TPDOSPDelv AS A
           JOIN _TDAWH      AS B ON A.CustSeq = B.CommissionCustSeq 
                                AND @BizUnit  = B.BizUnit
                                AND B.IsNotUse <> '1'
           WHERE @CompanySeq = B.CompanySeq
             AND B.SMWHKind  = 8002024)




-- 해당 사업부문, 사업장, 외주처에 걸린 생산외주창고가 2개 이상일 경우     --12.01.06 김세호 수정

EXEC dbo._SCOMMessage @MessageType OUTPUT,    
         @Status      OUTPUT,    
         @Results     OUTPUT,    
         1204                  , 
         @LanguageSeq       ,     
         14881, '생산외주창고'  


UPDATE #TPDOSPDelv                    
   SET MessageType = @MessageType,  
       Status      = @Status,  
       Result       = LEFT(REPLACE(@Results, '@2', '2개이상'), 23)  
   FROM #TPDOSPDelv AS C  
   WHERE  C.Status = 0   
      AND C.WorkingTag IN ('A', 'U')  
      AND EXISTS  (SELECT 1         
                       FROM #TPDOSPDelv AS A  
                       JOIN _TDAWH      AS B ON  A.CustSeq = B.CommissionCustSeq   
                                            AND @BizUnit  = B.BizUnit  
                                            AND B.IsNotUse <> '1'  
                       WHERE @CompanySeq = B.CompanySeq  
                         AND B.SMWHKind  = 8002024
                    GROUP BY B.BizUnit, B.FactUnit, B.CommissionCustSeq, B.SMWHKind
                     HAVING COUNT(1) > 1)  



       -- 순번update---------------------------------------------------------------------------------------------------------------      
    SELECT   @DataSeq = 0      
    
    WHILE ( 1 = 1 )       
    BEGIN      
        SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = OSPDelvDate      
          FROM #TPDOSPDelv      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
           AND DataSeq > @DataSeq      
         ORDER BY DataSeq      
          
        IF @@ROWCOUNT = 0 BREAK      
      
        -- OSPDelvNo 생성      
        EXEC _SCOMCreateNo 'PD', '_TPDOSPDelv', @CompanySeq, '', @BaseDate, @OSPDelvNo OUTPUT      
      

  
        SELECT @count = COUNT(*)        
          FROM #TPDOSPDelv        
         WHERE WorkingTag = 'A' AND Status = 0          
          
        IF @count > 0      
        BEGIN      
            -- OSPDelvSeq 생성      
            EXEC @OSPDelvSeq = _SCOMCreateSeq @CompanySeq, '_TPDOSPDelv', 'OSPDelvSeq', @count       
        END      
      
        UPDATE #TPDOSPDelv      
           SET OSPDelvSeq = @OSPDelvSeq + 1,       
               OSPDelvNo  = @OSPDelvNo      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
           AND DataSeq = @DataSeq      
    END      
     
  
   
    SELECT * FROM #TPDOSPDelv      
        
    
RETURN
GO


