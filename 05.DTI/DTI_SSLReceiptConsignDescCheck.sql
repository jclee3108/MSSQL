
IF OBJECT_ID('DTI_SSLReceiptConsignDescCheck') IS NOT NULL 
    DROP PROC DTI_SSLReceiptConsignDescCheck
GO 

-- v2014.05.21 

-- 위수탁입금입력_DTI(위수탁세부체크) by이재천 
CREATE PROC DTI_SSLReceiptConsignDescCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS 
    
    DECLARE @Count           INT,
            @ReceiptSeq      INT, 
            @MessageType     INT,
            @Status          INT,
            @Results         NVARCHAR(250)
    
    CREATE TABLE #DTI_TSLReceiptConsign(WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLReceiptConsign'  
        
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #DTI_TSLReceiptConsignDesc(WorkingTag NCHAR(1) NULL)  
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#DTI_TSLReceiptConsignDesc'  
    
    CREATE TABLE #AtmDiff(ReceiptSeq INT, ReceiptSerl INT, Notifyseq INT, NotifySerl INT, DiffAmt DECIMAL(19,5))
    CREATE TABLE #Tmp_SumAmt(ReceiptSeq INT, TempDomAmt DECIMAL(19,5), OriDomAmt DECIMAL(19,5), DiffAmt DECIMAL(19,5))
    
    -- 자국통화이고 외화금액이 0이 아닌 상태에서 외화금액 <> 원화금액이면 오류 띄우기 
    -- 2012.05.29 by 김철웅 
    DECLARE @EnvValue INT, @Word NVARCHAR(200)
    
    SELECT @EnvValue = CONVERT( INT, EnvValue ) FROM _TCOMEnv WHERE CompanySeq = @CompanySeq and EnvSeq = 13
    IF @@ROWCOUNT <> 0 SELECT @EnvValue = 1 
    
    SELECT @Word = Word FROM _TCADictionary WHERE LanguageSeq = @LanguageSeq and WordSeq = 7648
    IF @@ROWCOUNT <> 0 SELECT @Word = N'원화입금액' 
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1102, -- @1이(가) 일치하지 않습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%일치%')
                          @LanguageSeq, 
                          7489, N'외화입금액' -- SELECT * FROM _TCADictionary WHERE Word like '%외화입금액%'        
    UPDATE A
       SET A.Result        = @Word+', '+@Results,
           A.MessageType   = @MessageType,
           A.Status        = @Status
      FROM #DTI_TSLReceiptConsignDesc AS A 
      JOIN #DTI_TSLReceiptConsign     AS B ON ( A.ReceiptSeq = B.ReceiptSeq AND B.CurrSeq = @EnvValue )
     WHERE A.Status = 0 
       AND ISNULL(A.CurAmt,0) <> 0 
       AND A.CurAmt <> A.DomAmt
    
    -------------------------------------------
    -- 필수데이터체크
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)
                          @LanguageSeq       , 
                          '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'        
    UPDATE #DTI_TSLReceiptConsignDesc
       SET Result        = @Results,
           MessageType   = @MessageType,
           Status        = @Status
     WHERE ReceiptSeq = 0
        OR ReceiptSeq IS NULL
    
    --------------------------------------------------------------------------------------
    -- 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존해하지 않으면 에러처리
    --------------------------------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 
                     FROM #DTI_TSLReceiptConsignDesc AS A 
                     JOIN DTI_TSLReceiptConsignDesc AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq AND A.ReceiptSerl = B.ReceiptSerl ) 
                    WHERE A.WorkingTag IN ('U', 'D'))
    BEGIN
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                              @Status      OUTPUT,
                              @Results     OUTPUT,
                              7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                              @LanguageSeq       , 
                              '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
        UPDATE #DTI_TSLReceiptConsignDesc
           SET Result        = @Results,
               MessageType   = @MessageType,
               Status        = @Status
         WHERE WorkingTag IN ('U','D')
    END 
    /*
    -------------------------------------------
    -- 전표여부체크                            
    -------------------------------------------
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          8                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1562)    
                          @LanguageSeq       ,
                          1562, '', 0, ' '
    
    UPDATE #DTI_TSLReceiptConsignDesc    
       SET Result        = REPLACE(@Results,'@3',A2.PreOffNo),    
           MessageType   = @MessageType,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignDesc      AS A 
      JOIN _TSLPreReceiptItem   AS A1 ON ( A1.CompanySeq = @CompanySeq AND A.ReceiptSeq = A1.ReceiptSeq ) 
      JOIN _TSLPreReceipt       AS A2 ON ( A2.CompanySeq = @CompanySeq AND A1.PreOffSeq = A2.PreOffSeq ) 
     WHERE A.WorkingTag IN ('A','U','D')
       AND A.Status = 0
    
     -------------------------------------------
     -- 입금통보잔액체크                        
     -------------------------------------------
     INSERT INTO #AtmDiff(ReceiptSeq, ReceiptSerl, Notifyseq, NotifySerl, DiffAmt)
     SELECT A.ReceiptSeq, A.ReceiptSerl, ISNULL(E.Notifyseq, 0), ISNULL(E.NotifySerl, 0), CASE ISNULL(E.CurAmt, 0) WHEN 0 THEN ISNULL(A.CurAmt, 0) ELSE ISNULL(E.CurAmt, 0) - ISNULL(A.CurAmt, 0) END
       FROM #DTI_TSLReceiptConsignDesc AS A 
             LEFT OUTER JOIN (SELECT B.NotifySeq AS NotifySeq, B.NotifySerl AS NotifySerl, ISNULL(C.ForAmt, 0) - ISNULL(D.CurAmt, 0) AS CurAmt
                                FROM #DTI_TSLReceiptConsignDesc AS B
                                     LEFT OUTER JOIN _TSLReceiptDesc AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq
                                                                                      AND B.NotifySeq  = D.NotifySeq
                                                                                      AND B.NotifySerl = D.NotifySerl
                                                                                      AND NOT(B.ReceiptSeq = D.ReceiptSeq AND B.ReceiptSerl = D.ReceiptSerl) --- 20101118 by 정수환
                                     LEFT OUTER JOIN _TACRevNotifyDesc AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                                                        AND B.NotifySeq     = C.Notifyseq 
                                                                                        AND B.NotifySerl    = C.Serl ) AS E ON A.NotifySeq  = E.NotifySeq
                                                                                                                           AND A.NotifySerl = E.NotifySerl    
      WHERE A.NotifySeq <> 0                                                                                                                                                                                                                          
      EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           106                  , -- @1은(는) @2의 @3을(를) 초과할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 106)    
                           @LanguageSeq       ,
         1923, '', 
         11348, '', 
         11349, ''
     
     UPDATE #DTI_TSLReceiptConsignDesc    
        SET Result        = @Results,    
            MessageType   = @MessageType,    
            Status        = @Status    
       FROM #DTI_TSLReceiptConsignDesc AS A
             LEFT OUTER JOIN #AtmDiff AS B ON A.ReceiptSeq  = B.ReceiptSeq
                                          AND A.ReceiptSerl = B.ReceiptSerl
      WHERE A.WorkingTag IN ('A','U')
        AND A.Status = 0
        AND B.DiffAmt < 0 
    */
     -------------------------------------------
     -- 삭제시 합계금액 체크              
     -- 행삭제하려는 행은 0으로 하여 합계금액을 맞춘 후에 저장하도록 한다. 
     -- 2010.12.20 해당 기능 삭제 by 정혜영
     -------------------------------------------
     --EXEC dbo._SCOMMessage @MessageType OUTPUT,    
     --                      @Status      OUTPUT,    
     --                      @Results     OUTPUT,    
     --                      105               , -- @1은(는) @2 이어야 합니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 105)    
     --                      @LanguageSeq      ,
     --    290, '',            -- (SELECT * from _TCADictionary WHERE LanguageSEq = 1 AND Word Like '%0%')
     --                      '', '0'
     --UPDATE #DTI_TSLReceiptConsignDesc    
     --   SET Result        = @Results,    
     --       MessageType   = @MessageType,    
     --       Status        = @Status    
     --  FROM #DTI_TSLReceiptConsignDesc AS A
     -- WHERE A.WorkingTag = 'D'
     --   AND A.Status = 0
     --   AND A.DomAmt <> 0      
        
      -- 순번update---------------------------------------------------------------------------------------------------------------
     /* 입금다중입력이 가능하므로 한번에 여러개의 ReceiptSeq가 들어올 수 있으므로 Seq마다 Serl을 따주도록 한다. */
    UPDATE #DTI_TSLReceiptConsignDesc  
       SET ReceiptSerl = D.Serl  
      FROM #DTI_TSLReceiptConsignDesc AS C  
      JOIN (SELECT A.IDX_NO, ISNULL(B.MaxSerl, 0) + ROW_NUMBER() OVER(PARTITION BY A.ReceiptSeq ORDER BY A.IDX_NO) AS Serl  
              FROM #DTI_TSLReceiptConsignDesc AS A  
              LEFT OUTER JOIN (SELECT CompanySeq, ReceiptSeq, MAX(ReceiptSerl) AS MaxSerl  
                                 FROM _TSLReceiptDesc  
                                GROUP BY CompanySeq, ReceiptSeq  
                              ) AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptSeq = B.ReceiptSeq ) 
             WHERE A.WorkingTag = 'A'   
               AND A.Status = 0  
           ) AS D ON C.IDX_NO = D.IDX_NO  
    
    --차대구분값이 0으로 들어가는 것 체크
    IF EXISTS (SELECT 1 FROM #DTI_TSLReceiptConsignDesc WHERE SMDrOrCr = 0)
    BEGIN
    UPDATE #DTI_TSLReceiptConsignDesc
       SET SMDrOrCr = ISNULL(B.ValueSeq,'1')
      FROM  #DTI_TSLReceiptConsignDesc AS A    
      LEFT OUTER JOIN _TDAUMinorValue AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.UMReceiptKind = B.MinorSeq AND B.Serl = 1002 ) 
     WHERE A.SMDrOrCr = 0
    END
    
    -------------------------------------------  
    -- 내부코드 0값일시 에러 발생
    -------------------------------------------      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          1055               , -- 처리작업중 에러가 발생했습니다. 다시 처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                          @LanguageSeq       
    UPDATE #DTI_TSLReceiptConsignDesc                               
       SET Result        = @Results     ,    
           MessageType   = @MessageType ,    
           Status        = @Status    
      FROM #DTI_TSLReceiptConsignDesc
     WHERE Status = 0
       AND (ReceiptSerl = 0 OR ReceiptSerl IS NULL)
    
    SELECT * FROM #DTI_TSLReceiptConsignDesc
    
    RETURN