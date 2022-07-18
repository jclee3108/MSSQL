IF OBJECT_ID('KPXLS_SSLImpDelvMasterCheck') IS NOT NULL 
    DROP PROC KPXLS_SSLImpDelvMasterCheck
GO 

-- v2015.12.22 

/*********************************************************************************************************************    
     화면명 : 수입면장 마스터체크
     SP Name: _SSLImpDelvMasterCheck    
     작성일 : 2009년 03월 19일
     수정일 :     
 ********************************************************************************************************************/    
 CREATE PROCEDURE KPXLS_SSLImpDelvMasterCheck
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
             @DataSeq     INT,    
             @DelvSeq       INT,     
             @DelvNo        NVARCHAR(12),
             @BaseDate    NVARCHAR(8),
             @MaxNo       NVARCHAR(12),
             @BizUnit     INT,     
             @MessageType INT,    
             @Status      INT,    
             @Results     NVARCHAR(250)    ,
             @MinorSeq    INT, 
             @TableSeq    INT
   

     -- 서비스 마스타 등록 생성      
     CREATE TABLE #TUIImpDelv (WorkingTag NCHAR(1) NULL)      
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpDelv'
    
    
    ------------------------------------------------------------------------------------------------------------
    -- 체크1, 검사의뢰가 생성되어있어 수정/삭제를 할 수 없습니다. 
    ------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '검사의뢰가 생성되어있어 수정/삭제를 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #TUIImpDelv AS A 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
       AND EXISTS (SELECT 1 FROM KPXLS_TQCRequest WHERE CompanySeq = @CompanySeq AND SMSourceType = 1000522007 AND SourceSeq = A.DelvSeq) 
    ------------------------------------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------------------------------------
    
       -------------------------------------------
      -- 필수데이터체크    
      -------------------------------------------
          EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                                @Status      OUTPUT,    
                                @Results     OUTPUT,    
                                1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                @LanguageSeq       ,     
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'            
      
          -- 사업부문 체크
          UPDATE #TUIImpDelv    
             SET Result        = REPLACE(@Results,'@1','사업부문'),    
                 MessageType   = @MessageType,    
                 Status        = @Status    
           WHERE BizUnit   = ''
           -- B/L Date
          UPDATE #TUIImpDelv    
             SET Result        = REPLACE(@Results,'@1','입고일자'),    
                 MessageType   = @MessageType,    
                 Status        = @Status    
           WHERE BizUnit   = ''
              OR DelvDate       = ''
       --------------------------------------------------------------------------------------
      -- 데이터유무체크: UPDATE, DELETE 시데이터존해하지않으면에러처리
      --------------------------------------------------------------------------------------
      IF NOT EXISTS (SELECT 1 
                       FROM #TUIImpDelv AS A 
                             JOIN _TUIImpDelv AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.DelvSeq = B.DelvSeq
                      WHERE A.WorkingTag IN ('U', 'D'))
      BEGIN
          EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                @Status      OUTPUT,
                                @Results     OUTPUT,
                                7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)
                                @LanguageSeq       , 
                                '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'        
           UPDATE #TUIImpDelv
             SET Result        = @Results,
                 MessageType   = @MessageType,
                 Status        = @Status
           WHERE WorkingTag IN ('U','D')
     END
       -------------------------------------------  
      -- 비용데이터체크  
      -------------------------------------------  
          SELECT @MinorSeq = ISNULL(MinorSeq, 0)
           FROM _TDAUMinorValue WITH (NOLOCK)
          WHERE CompanySeq = @CompanySeq
            AND MajorSeq   = 8212
            AND Serl       = 1003
            AND ValueText  = '1'
           EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                                @Results     OUTPUT,  
                                102                , -- @1 데이터가 존재합니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                                @LanguageSeq       ,   
                                0,'비용처리'   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'          
    
          UPDATE #TUIImpDelv  
             SET Result        = @Results,  
                 MessageType   = @MessageType,  
                 Status        = @Status  
            FROM #TUIImpDelv AS A
                 JOIN _TSLExpExpense AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND B.SMSourceType = 8215006
                                                       AND A.DelvSeq   = B.SourceSeq
                 JOIN _TSLExpExpenseDesc AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq
                                                           AND B.ExpenseSeq = C.ExpenseSeq
           WHERE ((A.WorkingTag = 'D')
              OR (A.WorkingTag = 'U' AND C.UMExpenseItem = @MinorSeq))
             AND  A.Status = 0
     
 -- select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8215
       -------------------------------------------    
      -- 중복여부체크                                
      -------------------------------------------    
 --     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
 --                           @Status      OUTPUT,        
 --                           @Results     OUTPUT,        
 --                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)        
 --                           @LanguageSeq       ,         
 --                           0,'거래명세서'          
 --     UPDATE #TUIImpDelv        
 --        SET Result        = REPLACE(@Results,'@2',RTRIM(B.DelvSeq)),        
 --            MessageType   = @MessageType,        
 --            Status        = @Status        
 --       FROM #TUIImpDelv AS A JOIN ( SELECT S.DelvSeq    
 --                                      FROM (        
 --                                            SELECT A1.DelvSeq    
 --                                              FROM #TUIImpDelv AS A1        
 --                                             WHERE A1.WorkingTag IN ('A','U')        
 --                                               AND A1.Status = 0        
 --                                            UNION ALL        
 --                                            SELECT A1.DelvSeq    
 --                                              FROM _TUIImpDelv AS A1        
 --                                             WHERE A1.CompanySeq  = @CompanySeq    
 --                                               AND A1.DelvSeq NOT IN (SELECT DelvSeq      
 --                                                                         FROM #TUIImpDelv         
 --                                                                        WHERE WorkingTag IN ('U','D')    
 --                                                                          AND Status = 0)   
 --                                               AND A1.CompanySeq = @CompanySeq        
 --                                           ) AS S        
 --                                     GROUP BY S.DelvSeq    
 --           HAVING COUNT(1) > 1        
 --                                   ) AS B ON A.DelvSeq = B.DelvSeq      
 --     
 --    
 --    
 --    
 --    
 --                                           SELECT A1.DelvSeq    
 --                                             FROM #TUIImpDelv AS A1        
 --                                            WHERE A1.WorkingTag IN ('A','U')        
 --                                              AND A1.Status = 0        
 --                      UNION ALL        
 --                                           SELECT A1.DelvSeq    
 --                                             FROM _TUIImpDelv AS A1         
 --                                            WHERE A1.CompanySeq  = @CompanySeq    
 --                                              AND A1.DelvSeq NOT IN (SELECT DelvSeq      
 --                                                                        FROM #TUIImpDelv         
 --                                                                       WHERE WorkingTag IN ('U','D')    
 --                                                                         AND Status = 0)        
 --                                              AND A1.CompanySeq = @CompanySeq
       -------------------------------------------    
      -- 수정여부체크                                
      -------------------------------------------   
      EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                            @Status      OUTPUT,  
                            @Results     OUTPUT,  
                            5                , -- 이미 @1가(이) 완료된 @2입니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 102)  
                            @LanguageSeq       ,   
                            0,'미착정산'   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'          
       UPDATE #TUIImpDelv  
         SET Result        = REPLACE(@Results,'@2','입고'),  
             MessageType   = @MessageType,  
             Status        = @Status  
        FROM #TUIImpDelv AS A
             JOIN _TUIImpDelvCostDiv AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                       AND A.DelvSeq    = B.DelvSeq
       WHERE A.WorkingTag IN ('A','U','D')
         AND ISNULL(B.SlipSeq,0) <> 0
         AND A.Status = 0
     ----------------------------------------------------
     -- 수입입고 후 검사로 진행 여부 체크 2010. 7. 5 hkim
     ----------------------------------------------------
  IF EXISTS (SELECT 1 FROM _TPDQCTestReport AS A
         JOIN #TUIImpDelv AS B ON A.SourceSeq = B.DelvSeq
         WHERE A.CompanySeq = @CompanySeq 
           AND B.WorkingTag IN ('U', 'D') AND B.Status = 0
           AND A.SourceType = '9')
  BEGIN
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               18                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                               @LanguageSeq       ,     
                               0, '수입입고후검사로 진행된 건'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'            
          UPDATE #TUIImpDelv    
             SET Result        = @Results,    
                 MessageType   = @MessageType,    
                 Status        = @Status  
           FROM  #TUIImpDelv            AS A 
                 JOIN _TPDQCTestReport  AS B ON A.DelvSeq = B.SourceSeq
           WHERE A.WorkingTag IN ('U', 'D')
             AND A.Status     = 0
             AND B.CompanySeq = @CompanySeq
             AND B.SourceType = '9'
   
  END                  
     -------------------------------------------------------
     -- 수입입고 후 검사로 진행 여부 체크 끝 2010. 7. 5 hkim
     -------------------------------------------------------
     IF EXISTS (SELECT 1 FROM #TUIImpDelv WHERE WorkingTag IN ('U', 'D') )  
     BEGIN  
         -- 진행체크할 테이블값 테이블
         CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))      
         
         -- 진행체크할 데이터 테이블
         CREATE TABLE #Temp_ImpDelv(IDX_NO INT IDENTITY, DelvSeq INT, DelvSerl INT, IsNext NCHAR(1)) 
         
         -- 진행된 내역 테이블
         CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,
                                            Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))
       
         SELECT @TableSeq = ProgTableSeq
           FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블
          WHERE ProgTableName = '_TUIImpDelvItem'
          INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)
         SELECT B.ProgTableName
           FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --진행테이블관계
                 JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq
  
         
         INSERT INTO #Temp_ImpDelv(DelvSeq, DelvSerl, IsNext) -- IsNext=1(진행), 0(미진행)
         SELECT  A.DelvSeq, B.DelvSerl, '0'
           FROM #TUIImpDelv     AS A WITH(NOLOCK)       
                 JOIN _TUIImpDelvItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq  
                                                     AND A.DelvSeq     = B.DelvSeq
          WHERE A.WorkingTag IN ('U', 'D')  
            AND A.Status = 0  
   
         EXEC _SCOMProgressTracking @CompanySeq, '_TUIImpDelvItem', '#Temp_ImpDelv', 'DelvSeq', 'DelvSerl', ''    
   
   
         UPDATE #Temp_ImpDelv   
           SET IsNext = '1'  
          FROM  #Temp_ImpDelv AS A  
                 JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No  
   
         --ERR Message
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1045)  
                               @LanguageSeq       ,   
                               0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'  
         UPDATE #TUIImpDelv  
            SET Result        = @Results    ,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #TUIImpDelv   AS A  
                JOIN #Temp_ImpDelv AS B ON A.DelvSeq = B.DelvSeq  
          WHERE B.IsNext = '1' 
     END  
     -- 순번update---------------------------------------------------------------------------------------------------------------    
     SELECT   @DataSeq = 0    
      WHILE ( 1 = 1 )     
     BEGIN    
         SELECT TOP 1 @DataSeq = DataSeq, @BaseDate = DelvDate, @DelvNo = DelvNo
           FROM #TUIImpDelv
          WHERE WorkingTag = 'A'    
            AND Status = 0    
            AND DataSeq > @DataSeq
          ORDER BY DataSeq
         
         IF @@ROWCOUNT = 0 BREAK
     
         -- DelvNo 생성
         EXEC _SCOMCreateNo 'SL', '_TUIImpDelv', @CompanySeq, '', @BaseDate, @DelvNo OUTPUT    
  
         SELECT @count = COUNT(*)
           FROM #TUIImpDelv      
          WHERE WorkingTag = 'A' AND Status = 0        
         
         IF @count > 0    
         BEGIN    
             -- DelvSeq 생성    
             EXEC @DelvSeq = _SCOMCreateSeq @CompanySeq, '_TUIImpDelv', 'DelvSeq', @Count
         END
     
         UPDATE #TUIImpDelv
            SET DelvSeq = @DelvSeq + DataSeq,     
                DelvNo  = @DelvNo    
          WHERE WorkingTag = 'A'
            AND Status = 0    
            AND DataSeq = @DataSeq    
     END    
     
 --    --매출출고구분 값
 --    UPDATE #TUIImpDelv  
 --       SET IsSalesWith = M.ValueText  
 --      FROM #TUIImpDelv AS A  
 --            LEFT OUTER JOIN _TDAUMinorValue AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq  
 --                                                             AND A.UMOutKind  = M.MinorSeq  
 --                                                             AND M.Serl = 2001  
     -------------------------------------------  
     -- 내부코드0값일시에러발생
     -------------------------------------------      
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)    
                           @LanguageSeq       
      UPDATE #TUIImpDelv                               
        SET Result        = @Results     ,    
            MessageType   = @MessageType ,    
            Status        = @Status    
       FROM #TUIImpDelv
      WHERE Status = 0
        AND (DelvSeq = 0 OR DelvSeq IS NULL)
      SELECT * FROM #TUIImpDelv    
     
     RETURN

GO


