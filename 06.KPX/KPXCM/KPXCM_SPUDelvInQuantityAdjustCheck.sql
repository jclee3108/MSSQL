IF OBJECT_ID('KPXCM_SPUDelvInQuantityAdjustCheck') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvInQuantityAdjustCheck
GO 
    
/************************************************************
 설  명 - 데이터-입고량조정등록 : Check
 작성일 - 20141215
 작성자 - 오정환
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SPUDelvInQuantityAdjustCheck
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS   

    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
  
    CREATE TABLE #KPX_TPUDelvInQuantityAdjust (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TPUDelvInQuantityAdjust'

----===============--
---- 필수입력 체크 --
----===============--

---- 필수입력 Message 받아오기
    EXEC dbo._SCOMMessage @MessageType OUTPUT,
                          @Status      OUTPUT,
                          @Results     OUTPUT,
                          1038               , -- 필수입력 항목을 입력하지 않았습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%필수%')
                          @LanguageSeq       , 
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'

    -- 필수입력 Check 
      UPDATE #KPX_TPUDelvInQuantityAdjust
         SET Result        = @Results,
             MessageType   = @MessageType,
             Status        = @Status
        FROM #KPX_TPUDelvInQuantityAdjust AS A
       WHERE A.WorkingTag IN ('A','U')
         AND A.Status = 0
      -- guide : 이곳에 필수입력 체크 할 항목을 조건으로 넣으세요.
      -- e.g.   :
         AND (A.Qty         = 0
          OR  A.DelvInSeq   = 0
          OR  A.DelvInSerl  = 0)

--==================================================================================--  
------ 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존재하지 않으면 에러처리 ----------
--==================================================================================--  
    IF  EXISTS (SELECT 1   
                  FROM #KPX_TPUDelvInQuantityAdjust AS A   
                       LEFT OUTER JOIN KPX_TPUDelvInQuantityAdjust AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                                                    AND ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                                    AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                                    AND ( A.DelvInSerl    = B.DelvInSerl ) 
                          
                 WHERE A.WorkingTag IN ('U', 'D')
                   AND B.AdjustSeq IS NULL )  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
         UPDATE #KPX_TPUDelvInQuantityAdjust  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
           FROM #KPX_TPUDelvInQuantityAdjust AS A   
                LEFT OUTER  JOIN KPX_TPUDelvInQuantityAdjust AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq 
                                                                         AND ( A.AdjustSeq     = B.AdjustSeq ) 
                                                                         AND ( A.DelvInSeq     = B.DelvInSeq ) 
                                                                         AND ( A.DelvInSerl    = B.DelvInSerl ) 
                          
          WHERE A.WorkingTag IN ('U', 'D')
            AND b.AdjustSeq IS NULL 
    END   
    
    ------------------------------------------------------------------------------------
    -- 체크, 전표 처리 된 데이터는 수정/삭제 할 수 없습니다. 
    ------------------------------------------------------------------------------------
    
    UPDATE A 
       SET Result = '전표 처리 된 데이터는 수정/삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPX_TPUDelvInQuantityAdjust AS A 
      JOIN _TPUBuyingAcc                AS B ON ( B.CompanySeq = @CompanySeq AND B.SourceType = 1 AND B.SourceSeq = A.DelvInSeq AND B.SourceSerl = A.DelvInSerl AND B.SlipSeq <> 0 ) 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
    
    ------------------------------------------------------------------------------------
    -- 체크, END 
    ------------------------------------------------------------------------------------
    
    
    --select * From _TUIImpDelv where delvseq = 1000123
    
    
----=========================================================================--
---- 삭제코드  체크:마스터 성 테이블일 경우 삭제시 사용 테이블 체크 sp입니다.
----=========================================================================--        
    --EXEC dbo._SCOMCodeDeleteCheck  @CompanySeq,@UserSeq,@LanguageSeq,'KPX_TPUDelvInQuantityAdjust', '#KPX_TPUDelvInQuantityAdjust','키값'  

----=============================================--
---- 중복여부 체크 (하나의 중복값을 체크 할 경우)--
----=============================================--  
---- 중복체크 Message 받아오기    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                          @Status      OUTPUT,    
                          @Results     OUTPUT,    
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                          @LanguageSeq       ,     
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'    
      
----====================================--
---- 중복여부체크(키값이 2개 이상일 경우)
----====================================-- 
    ---- 중복체크Message 받아오기   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              6                  , -- 중복된@1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                              @LanguageSeq       ,     
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'    
    ---- 중복여부Check --
    
    --========================================--
    -- 이미저장된시트에서중복되는것있는지확인 --
    --========================================--
    UPDATE #KPX_TPUDelvInQuantityAdjust     
       SET Result        = @Results     ,     
           MessageType   = @MessageType ,     
           Status        = @Status      
      FROM #KPX_TPUDelvInQuantityAdjust      AS A JOIN KPX_TPUDelvInQuantityAdjust AS B ON A.DelvInSeq   = B.DelvInSeq    
                                                                                       AND A.DelvInSerl  = B.DelvInSerl

     WHERE A.WorkingTag  IN ('A')   
       AND A.Status      = 0    
       AND B.CompanySeq = @CompanySeq    
    --========================================--   
    -- 같은저장시트에서중복되는것이있는지확인 --
    --========================================--     
    UPDATE A      
       SET Result        = @Results      ,     
           MessageType   = @MessageType  ,     
           Status        = @Status    
      FROM #KPX_TPUDelvInQuantityAdjust AS A    JOIN #KPX_TPUDelvInQuantityAdjust AS B ON A.DelvInSeq   = B.DelvInSeq  -- 중복 컬럼이 추가 될수록 똑같이 조건 넣어주기
                                                                                      AND A.DelvInSerl  = B.DelvInSerl       
                                                                                      AND A.IDX_NO     <> B.IDX_NO       
     WHERE A.WorkingTag IN ('A')   
       AND A.Status      = 0     

    
    
-- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
--guide : '마스터 키 생성' --------------------------
    DECLARE @MaxSeq INT,
            @Count  INT 
    SELECT @Count = Count(1) FROM #KPX_TPUDelvInQuantityAdjust WHERE WorkingTag = 'A' AND Status = 0
    if @Count >0 
    BEGIN
    EXEC @MaxSeq = _SCOMCreateSeq @CompanySeq, 'KPX_TPUDelvInQuantityAdjust','AdjustSeq',@Count --rowcount  
          UPDATE #KPX_TPUDelvInQuantityAdjust             
             SET AdjustSeq  = @MaxSeq + 1
           WHERE WorkingTag = 'A'            
             AND Status = 0 
    END  

                           
    SELECT * FROM #KPX_TPUDelvInQuantityAdjust 
RETURN
GO
