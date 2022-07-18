IF OBJECT_ID('yw_SSLOrderRevCheck') IS NOT NULL 
    DROP PROC yw_SSLOrderRevCheck
GO 

-- v2014.02.28 
/************************************************************
 설  명 - 수주차수증가 체크
 작성일 - 2008년 7월  
 작성자 - 김준모
 ************************************************************/
 CREATE PROC yw_SSLOrderRevCheck
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
             @BizUnit     INT,  
             @Date        NVARCHAR(8),  
             @MaxNo       NVARCHAR(50),
             @OrderSeq INT,
             @OrderRev INT
  
      -- 서비스 마스타 등록 생성
     CREATE TABLE #TSLOrder (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLOrder'     
     IF @@ERROR <> 0 RETURN 
      SELECT TOP 1 @OrderSeq = ISNULL(OrderSeq, 0) 
       FROM #TSLOrder
  
     IF @WorkingTag = 'D'   
     BEGIN  
         UPDATE #TSLOrder  
            SET WorkingTag = 'D'  
          UPDATE #TSLOrder
            SET OrderRev = ISNULL((SELECT MAX(B.OrderRev)
                                     FROM #TSLOrder A 
                                          JOIN _TSLOrderRev AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq
                                                                             AND A.OrderSeq   = B.OrderSeq
                                    WHERE A.WorkingTag = 'D' AND A.Status = 0), 0)
     END 
      --------------------------------------------------------------------------------------  
     -- 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존해하지 않으면 에러처리  
     --------------------------------------------------------------------------------------  
     IF NOT EXISTS (SELECT 1   
                      FROM #TSLOrder AS A   
                            JOIN _TSLOrder AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.OrderSeq = B.OrderSeq  
                     WHERE A.WorkingTag IN ('U', 'D'))  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
          UPDATE #TSLOrder  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
          WHERE WorkingTag IN ('U','D')
     END 
  
     --------------------------------------------------------------------------------------  
     -- 확정 확인 : 확정되지 않은 건은 차수 생성을 할 수 없다. 
     --------------------------------------------------------------------------------------  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           1209               , -- @1한 @2가 아닙니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 1209)    
                           @LanguageSeq       ,     
                           607,'',       -- SELECT * FROM _TCADictionary WHERE WordSeq like '607'    확정
                           23642, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '23642'    수주    
      UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder_Confirm AS B ON B.CompanySeq = @CompanySeq
                                        AND A.OrderSeq   = B.CfmSeq   
                             AND B.CfmSerl    = 0                                                  
WHERE B.CfmCode = '0' -- 미확정
        AND A.WorkingTag = 'U' -- 차수생성은 U 와 D 만 존재
      --------------------------------------------------------------------------------------  
     -- 확정 확인 : 확정사용시 확정된 건은 수정, 삭제 할 수 없다. 
     --------------------------------------------------------------------------------------  
     IF EXISTS(SELECT TOP 1 1  
                 FROM _TCOMConfirmDef A  
                      JOIN _TCOMConfirmPGM B ON A.CompanySeq = B.CompanySeq  
                                            AND A.ConfirmSeq = B.ConfirmSeq  
                WHERE A.CompanySeq = @CompanySeq  
                  AND B.PGMSeq = @PgmSeq  
                  AND A.IsNotUsed <> '1')     
     BEGIN                  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1083               , -- 확정(승인)된 자료는 수정/삭제할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 1083)    
                               @LanguageSeq                         
          UPDATE #TSLOrder    
            SET Result        = @Results    ,    
                MessageType   = @MessageType,    
                Status        = @Status   
           FROM #TSLOrder AS A
                 JOIN _TSLOrder_Confirm AS B ON B.CompanySeq = @CompanySeq
                                            AND A.OrderSeq   = B.CfmSeq                                       
          WHERE B.CfmCode = '1' -- 확정
            AND A.WorkingTag = 'D'   
     END                
      
     --------------------------------------------------------------------------------------  
     -- 필수값 변경 : 변경되지 말아야 할 데이터가 변경되었을경우 메시지처리  
     --------------------------------------------------------------------------------------  
     -- 거래처 변경시
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1는(은) @2(을)를 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           6,'',       -- SELECT * FROM _TCADictionary WHERE WordSeq like '2524'    거래처
                           13823, ''   -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    변경
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.CustSeq <> B.CustSeq
     
     -- 사업부문 변경시
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1는(은) @2(을)를 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           2,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '2'    사업부문
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    변경
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.BizUnit <> B.BizUnit
      
     -- 위탁구분 변경시
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,  
                           @Results     OUTPUT,    
                           19               , -- @1는(은) @2(을)를 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq =  1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           11263,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '11263'    위탁구분
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    변경
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.SMConsignKind <> B.SMConsignKind
      /*
     -- 수주구분 변경시
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1는(은) @2(을)를 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           630,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '630'    수주구분
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    변경
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.UMOrderKind <> B.UMOrderKind    
      */
     -- local구분 변경시
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           19               , -- @1는(은) @2(을)를 할 수 없습니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 MessageSeq = 19)    
                           @LanguageSeq       ,     
                           14037,'',         -- SELECT * FROM _TCADictionary WHERE WordSeq like '14037'    local구분
                           13823, ''     -- SELECT * FROM _TCADictionary WHERE WordSeq like '13823'    변경
                           
     UPDATE #TSLOrder    
        SET Result        = @Results    ,    
            MessageType   = @MessageType,    
            Status        = @Status   
       FROM #TSLOrder AS A
             JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq
                                AND A.OrderSeq   = B.OrderSeq
      WHERE A.SMExpKind <> B.SMExpKind       
  
     -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #TSLOrder WHERE WorkingTag = 'U' AND Status = 0  
     IF @Count > 0  
     BEGIN    
         SELECT @OrderRev = MAX(ISNULL(OrderRev, 0))
           FROM _TSLOrder 
          WHERE CompanySeq  = @CompanySeq
            AND OrderSeq = @OrderSeq
          -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #TSLOrder  
            SET OrderRevOLD = ISNULL(OrderRev,0),
                OrderRev = ISNULL(@OrderRev,0) + 1
          WHERE WorkingTag = 'U'  
            AND Status = 0  
     END    
   
     SELECT * FROM #TSLOrder  
      RETURN    
 /*******************************************************************************************************************/