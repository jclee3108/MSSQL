IF OBJECT_ID('KPXCM_SPUDelvInCheck') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvInCheck
GO 

-- v2015.10.01 

-- MES연동 체크 추가 by이재천 
/************************************************************  
 설  명 - 구매입고체크
 작성일 - 2008년 8월 20일   
 작성자 - 노영진  
 수정일 - 2009년 9월 9일
 수정자 - 김현
 ************************************************************/    
 CREATE PROC KPXCM_SPUDelvInCheck    
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
             @DelvInSeq   INT,         
             @DelvInNo    NVARCHAR(12),        
             @BaseDate    NVARCHAR(8),        
             @MaxNo       NVARCHAR(12), 
             @DelvInDate  NCHAR(8),       
             @BizUnit     INT,        
             @MaxQutoRev  INT,  
             @MessageType INT,        
             @Status      INT,        
             @Results     NVARCHAR(250),
             @QCAutoIn    NCHAR(1)              
    
    IF @WorkingTag <> 'AUTO'        -- 자동입고시에는 임시 테이블 생성 X
    BEGIN    
    -- 임시 테이블 생성  
    CREATE TABLE #TPUDelvIn (WorkingTag NCHAR(1) NULL)      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUDelvIn'         
    END
    IF @@ERROR <> 0 RETURN   
    -- 환경설정값 가져오기  # 무검사품 자동입고 여부
    EXEC dbo._SCOMEnv @CompanySeq,6500,@UserSeq,@@PROCID,@QCAutoIn OUTPUT  
    

    
     -- 자동입고건은 삭제 X
     IF @QCAutoIn = '1'
     BEGIN
         -------------------
         --납품번호 추적 ---
         -------------------
         CREATE TABLE #TMP_SOURCETABLE          
         (          
             IDOrder INT,          
             TABLENAME   NVARCHAR(100)          
         )   
         CREATE TABLE #TCOMSourceTracking          
         (           
             IDX_NO      INT,          
             IDOrder     INT,          
             Seq         INT,          
             Serl        INT,          
             SubSerl     INT,          
             Qty         DECIMAL(19, 5),          
             STDQty      DECIMAL(19, 5),          
             Amt         DECIMAL(19, 5),          
             VAT         DECIMAL(19, 5)          
         )   
         CREATE TABLE #TMP_SOURCEITEM    
         (          
             IDX_NO     INT IDENTITY,          
             SourceSeq  INT,          
             SourceSerl INT,          
             Qty        DECIMAL(19, 5)    
         )
         CREATE TABLE #TMP_EXPENSE    
         (          
             IDX_NO     INT,          
             SourceSeq  INT,          
             SourceSerl INT,          
             ExpenseSeq INT    
         ) 
         INSERT #TMP_SOURCETABLE    
         SELECT '','_TPUDelvItem'    
     
         INSERT #TMP_SOURCETABLE    
         SELECT '','_TPUDelvInItem'
     
         INSERT #TMP_SOURCEITEM
              ( SourceSeq    , SourceSerl    , Qty)
         SELECT A.DelvInSeq    , B.DelvInSerl    , B.Qty
           FROM #TPUDelvIn          AS A
                JOIN _TPUDelvInItem AS B ON B.CompanySeq  = @CompanySeq
                                        AND A.DelvInSeq   = B.DelvInSeq
         WHERE A.WorkingTag IN ('U', 'D')
            AND A.Status    = 0
          EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvInItem', '#TMP_SOURCEITEM', 'SourceSeq', 'SourceSerl', ''          
          IF EXISTS (SELECT 1 FROM #TCOMSourceTracking)           -- 입고입력 화면에서 입력한 건은 제외     
             IF  EXISTS (SELECT 1 FROM _TPUDelvItem AS A
                                          JOIN #TCOMSourceTracking AS B ON A.DelvSeq  = B.Seq
                                                                       AND A.DelvSerl = B.Serl            
                                    WHERE A.CompanySeq = @CompanySeq) 
             BEGIN
                 EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                       @Status      OUTPUT,    
     @Results     OUTPUT,    
                                       18                 , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 18)    
                                       @LanguageSeq       ,     
                                       0,'자동입고건'   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'            
                 UPDATE #TPUDelvIn    
                    SET Result        = @Results,
                        MessageType   = @MessageType,    
                        Status        = @Status   
                   FROM #TPUDelvIn  AS A
         JOIN _TPUDelvIn  AS B ON B.CompanySeq = @CompanySeq
            AND A.DelvInSeq  = B.DelvInSeq
         LEFT OUTER JOIN _TPUDelvInItem AS C ON B.CompanySeq = C.CompanySeq
                 AND B.DelvInSeq  = C.DelvInSeq 
         LEFT OUTER JOIN _TPDBaseItemQCType AS D ON C.CompanySeq = D.CompanySeq 
                  AND C.ItemSeq    = D.ItemSeq                       
                  WHERE A.WorkingTag IN ('U', 'D')
                    AND ISNULL(B.IsReturn, '')  <> '1'
                    AND @WorkingTag <> 'AUTO'
                    AND ISNULL(D.IsNotAutoIn, '0') <> '1'   -- 자동입고 미사용 품목은 삭제가 되도록 수정 2010. 5. 28 Hkim
             END     
         -------------------
         --납품번호 추적 끝  ----
         -------------------  
     END    
     
    
    ------------------------------------------------------------------------
    -- 체크, MES 연동으로 입고 된 내역은 삭제 할 수 없습니다. 
    ------------------------------------------------------------------------
    TRUNCATE TABLE #TMP_SourceTable 
    TRUNCATE TABLE #TCOMSourceTracking 
    
    CREATE TABLE #BaseData 
    (
        IDX_NO      INT IDENTITY, 
        DelvInSeq   INT, 
        DelvInSerl  INT, 
        POSeq       INT, 
        POSerl      INT 
    )
    INSERT INTO #BaseData ( DelvInSeq, DelvInSerl, POSeq, POSerl ) 
    SELECT B.DelvInSeq, B.DelvInSerl, 0, 0 
      FROM #TPUDelvIn      AS A 
      JOIN _TPUDelvInItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
     WHERE A.WorkingTag = 'D' 
       AND A.Status = 0 
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TPUORDPOItem'   -- 찾을 데이터의 테이블
    
    EXEC _SCOMSourceTracking @CompanySeq = @CompanySeq, 
                             @TableName = '_TPUDelvInItem',  -- 기준 테이블
                             @TempTableName = '#BaseData',  -- 기준템프테이블
                             @TempSeqColumnName = 'DelvInSeq',  -- 템프테이블 Seq
                             @TempSerlColumnName = 'DelvInSerl',  -- 템프테이블 Serl
                             @TempSubSerlColumnName = '' 
    
    UPDATE A 
       SET POSeq = B.Seq, 
           POSerl = B.Serl 
      FROM #BaseData            AS A 
      JOIN #TCOMSourceTracking  AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    UPDATE A 
       SET Result = 'MES 연동으로 입고 된 내역은 삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TPUDelvIn  AS A 
      JOIN #BaseData    AS B ON ( B.DelvInSeq = A.DelvInSeq ) 
     WHERE EXISTS (SELECT 1 FROM IF_PUInQCResult_MES WHERE CompanySeq = @CompanySeq AND ImpType = 0 AND POSeq = B.POSeq AND POSerl = B.POSerl) 
       AND A.Status = 0 
       AND A.WorkingTag = 'D' 
    ------------------------------------------------------------------------
    -- 체크, END 
    ------------------------------------------------------------------------
     
     
      -------------------------------------------    
      -- 필수데이터체크    D 검사된 것인지 체크(구매수입검사)  
      -------------------------------------------    
      -------------------------------------------    
      -- 필수데이터체크    D 반품확인(반품건이 있으면 삭제되면 안 된다.)  
      -------------------------------------------    
      -------------------------------------------    
      -- 필수데이터체크    
      -------------------------------------------    
      EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                            @Status      OUTPUT,    
                            @Results     OUTPUT,    
                            1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                            @LanguageSeq       ,     
                            0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'            
      UPDATE #TPUDelvIn    
         SET Result        = @Results,    
             MessageType   = @MessageType,    
             Status        = @Status    
       WHERE DelvInDate = ''    
          OR DelvInDate IS NULL    
      -------------------------------------------    
      -- 전표처리 체크
      -------------------------------------------    
      --EXEC dbo._SCOMMessage @MessageType OUTPUT,    
      --                      @Status      OUTPUT,    
      --                      @Results     OUTPUT,    
      --                      18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
      --                      @LanguageSeq       ,     
      --                      0,'전표처리 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'            
      --UPDATE #TPUDelvIn    
      --   SET Result        = @Results,    
      --       MessageType   = @MessageType,    
      --       Status        = @Status  
      -- FROM   #TPUDelvIn AS A JOIN _TPUBuyingAcc AS B ON B.CompanySeq = @CompanySeq
      --                                               AND A.DelvInSeq  = B.SourceSeq
      --                                               AND B.SourceType = '1'
      -- WHERE A.WorkingTag IN ('U', 'D')
      --   AND  ISNULL(B.SlipSeq,0) > 0
      --## 구매입고 후 검사가 처리 된 건은 수정/삭제가 되지 않도록 추가 ##
     IF EXISTS (SELECT 1 FROM #TPUDelvIn WHERE WorkingTag IN ('U', 'D') AND Status = 0)
     BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
     18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                               @LanguageSeq       ,     
                               0, '구매입고후검사로  진행된 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'            
          UPDATE #TPUDelvIn    
             SET Result        = @Results,    
                 MessageType   = @MessageType,    
                 Status        = @Status  
           FROM  #TPUDelvIn            AS A 
                 JOIN _TPDQCTestReport AS B ON A.DelvInSeq = B.SourceSeq
           WHERE A.WorkingTag IN ('U', 'D')
             AND A.Status     = 0
             AND B.CompanySeq = @CompanySeq
             AND B.SourceType = '7'
     END
  
  -- 자동입고일경우 건별로 DelvInSeq, DelvInNo 생성 위해(검사일괄처리는 여러건, 일반 자동입고는 한건)
  IF @WorkingTag = 'AUTO'
  BEGIN
   SELECT @DataSeq = 0
   
   WHILE( 1 > 0) 
   BEGIN
             SELECT TOP 1 @DataSeq = DataSeq    
             FROM #TPUDelvIn        
              WHERE WorkingTag = 'A'        
                AND Status = 0        
                AND DataSeq > @DataSeq        
              ORDER BY DataSeq        
              IF @@ROWCOUNT = 0 BREAK     
    
    SELECT @DelvInDate = DelvInDate FROM #TPUDelvIn WHERE DataSeq = @DataSeq
    EXEC @DelvInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUDelvIn', 'DelvInSeq', 1  
    EXEC dbo._SCOMCreateNo 'PU', '_TPUDelvIn', @CompanySeq, '', @DelvInDate, @DelvInNo OUTPUT
    
    UPDATE #TPUDelvIn
       SET DelvInSeq = @DelvInSeq + 1, -- 여러건이 들어올 경우 While을 돌면서 한건식 처리하기 때문에 1을 더해줌
        DelvInNo  = @DelvInNo
     WHERE WorkingTag = 'A'
       AND Status  = 0
       AND DataSeq = @DataSeq
   END
  END
  -- 자동입고가 아닐 경우
  ELSE
  BEGIN
   -- MAX POSeq Seq
   SELECT @Count = COUNT(*) FROM #TPUDelvIn WHERE WorkingTag = 'A' AND Status = 0 
   IF @Count > 0
   BEGIN   
    SELECT @DelvInDate = DelvInDate FROM #TPUDelvIn
    EXEC dbo._SCOMCreateNo 'PU', '_TPUDelvIn', @CompanySeq, '', @DelvInDate, @DelvInNo OUTPUT
    EXEC @DelvInSeq = dbo._SCOMCreateSeq @CompanySeq, '_TPUDelvIn', 'DelvInSeq', @Count     
    UPDATE #TPUDelvIn
       SET DelvInSeq = @DelvInSeq + DataSeq , 
        DelvInNo  = @DelvInNo
     WHERE WorkingTag = 'A'
       AND Status = 0
   END  
  END    
  
 --     IF @WorkingTag <> 'AUTO'
 --     BEGIN
 --         UPDATE #TPUDelvIn
 --            SET SMImpType = 8008001
 --          WHERE ISNULL(SMIMPType,0) = 0
 --     END
            
     
     IF @WorkingTag <> 'AUTO'
     BEGIN     
         SELECT * FROM #TPUDelvIn        
     END
           
       
 RETURN