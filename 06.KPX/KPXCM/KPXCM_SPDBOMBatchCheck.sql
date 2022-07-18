IF OBJECT_ID('KPXCM_SPDBOMBatchCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchCheck
GO 

-- v2015.09.16

/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatch
  DESCRIPTION         -     배합비 체크 
  CREAE DATE          -       2008.07.01      CREATE BY: 김현
  LAST UPDATE  DATE   -       2008.09.01         UPDATE BY: 김현
  LAST UPDATE  DATE   -       2014.05.22         UPDATE BY: 김용현 자재중복 허용 관련 환경설정 먹도록 추가
 *************************************************************************************************/ 
 CREATE PROC KPXCM_SPDBOMBatchCheck
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
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250),
             @BatchSeq    INT,
             @EnvValue    NCHAR(1)
  
     -- 서비스 마스타 등록 생성
     CREATE TABLE #KPXCM_TPDBOMBatch (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDBOMBatch' 
    
     IF @@ERROR <> 0 RETURN   
     
     --- BOM 자재중복 허용 환경설정 ---
     EXEC dbo._SCOMEnv @CompanySeq,6206,0,@@PROCID,@EnvValue OUTPUT      
  
     IF @EnvValue = '0'  -- 2014.05.22 김용현 자재중복 허용 하지 않을 경우 ( 미체크 ) 아래 Check 로직 발동
    BEGIN
    
    IF EXISTS (SELECT 1 FROM KPXCM_TPDBOMBatch AS A JOIN #KPXCM_TPDBOMBatch AS B ON A.ItemSeq = B.ItemSeq AND A.BatchSize = B.BatchSize ANd A.FactUnit = B.FactUnit   
                       WHERE A.CompanySeq = @CompanySeq AND B.WorkingTag in('A', 'U') AND B.Status = 0)  
    BEGIN
         -------------------------------------------
         -- 중복여부체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'배합비'   -- SELECT * FROM _TCADictionary WHERE Word like '%배합비%'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = REPLACE(@Results,'@2',B.BatchSize),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch AS A JOIN ( SELECT S.BatchSize
                                          FROM (
                                                SELECT A1.BatchSize
                                                  FROM #KPXCM_TPDBOMBatch AS A1
                                                 WHERE A1.WorkingTag IN ('A','U')
                                                   AND A1.Status = 0
                                                UNION ALL
                                                SELECT A1.BatchSize
                                                  FROM KPXCM_TPDBOMBatch AS A1
                                                 WHERE A1.ItemSeq IN (SELECT ItemSeq 
                                                                                FROM #KPXCM_TPDBOMBatch 
                                                                               WHERE WorkingTag NOT IN ('U','D') 
                                                                                 AND Status = 0)
                                                   AND A1.CompanySeq = @CompanySeq
                                               ) AS S
                                         GROUP BY S.BatchSize
                                         HAVING COUNT(1) > 1
                                       ) AS B ON (A.BatchSize = B.BatchSize)
          WHERE A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
     END
     
     
     
     
     IF EXISTS (SELECT 1 FROM #KPXCM_TPDBOMBatch WHERE DateFr >= DateTo AND Status = 0 AND WorkingTag IN ('A', 'U'))
     BEGIN
         -------------------------------------------
         -- 일자 체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               31                 , -- @1이 @2 보다 커야 합니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%합니%' AND LanguageSeq = 1)
                               @LanguageSeq       , 
                               232, '종료일'      , -- SELECT * FROM _TCADictionary WHERE Word like '%시작일%'
                               191, '시작일'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch 
          WHERE DateFr     >= DateTo
            AND Status     = 0
            AND WorkingTag IN ('A', 'U')
     END
     
     -- 시작일과 종료일이 중복되면 안된다.
     IF EXISTS (SELECT 1 
                  FROM #KPXCM_TPDBOMBatch      AS A
                       JOIN KPXCM_TPDBOMBatch AS B ON A.ItemSeq  = B.ItemSeq 
                                             AND A.BatchSeq <> B.BatchSeq
          WHERE (B.DateFr BETWEEN A.DateFr AND A.DateTo OR B.DateTo BETWEEN A.DateFr AND A.DateTo)
            AND A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
            AND B.CompanySeq = @CompanySeq)
     BEGIN
         -------------------------------------------
         -- 중복된 일자 체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1107               , -- 해당 @1가(이) 기존에 등록된 @2와(과) 중복됩니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%없습%' AND LanguageSeq = 1)
                               @LanguageSeq       , 
                               222, '적용일'      , -- SELECT * FROM _TCADictionary WHERE Word like '%적용일%'
                               222, '적용일'
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = @Results,
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch      AS A
                JOIN KPXCM_TPDBOMBatch AS B ON A.ItemSeq     = B.ItemSeq 
                                      AND A.BatchSeq    <> B.BatchSeq
                                      AND A.FactUnit    = B.FactUnit
                                      AND A.ProcTypeSeq = B.ProcTypeSeq
          WHERE (B.DateFr BETWEEN A.DateFr AND A.DateTo OR B.DateTo BETWEEN A.DateFr AND A.DateTo)
            AND A.Status     = 0
            AND A.WorkingTag IN ('A', 'U')
            AND B.CompanySeq = @CompanySeq
     END
     
     
     -- 생산계획으로 진행된 데이터가 존재하면 삭제 불가
     IF EXISTS (SELECT 1 
                  FROM #KPXCM_TPDBOMBatch          AS A
                       JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq <> B.BatchSeq
          WHERE A.Status     = 0
            AND A.WorkingTag = 'D'
            AND B.CompanySeq = @CompanySeq)
     BEGIN
         -------------------------------------------
         -- 중복된 일자 체크
         -------------------------------------------
         EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message LIKE '%없습%' AND LanguageSeq = 1)
                               @LanguageSeq       
                               
         UPDATE #KPXCM_TPDBOMBatch
            SET Result        = REPLACE(@Results, '변경,', ''),
                MessageType   = @MessageType,
                Status        = @Status
           FROM #KPXCM_TPDBOMBatch          AS A
                JOIN _TPDMPSWorkOrder AS B ON A.BatchSeq    = B.BatchSeq
          WHERE A.Status     = 0
            AND A.WorkingTag = 'D'
            AND B.CompanySeq = @CompanySeq
     END
     
     END
        
        
        
        
 -- MAX UnitSeq
     SELECT @Count = COUNT(*) FROM #KPXCM_TPDBOMBatch WHERE WorkingTag = 'A' AND Status = 0 
     IF @Count > 0
     BEGIN   
         EXEC @BatchSeq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TPDBOMBatch', 'BatchSeq', @Count
         UPDATE #KPXCM_TPDBOMBatch
            SET BatchSeq   = @BatchSeq + DataSeq
          WHERE WorkingTag = 'A'
            AND Status     = 0
     END  
      SELECT * FROM #KPXCM_TPDBOMBatch
  RETURN    
 /*******************************************************************************************************************/