
IF OBJECT_ID('KPX_SDAItemUnitCheck') IS NOT NULL 
    DROP PROC KPX_SDAItemUnitCheck
GO 

-- v2014.11.04 

-- 품목단위환산체크 by이재천
/************************************************************  
설  명 - 품목단위환산 체크  
작성일 - 2008년 7월    
작성자 - 김준모  
************************************************************/  
CREATE PROC KPX_SDAItemUnitCheck  
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
            @StkUnitSeq  INT -- 기준단위  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #KPX_TDAItemUnit (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#KPX_TDAItemUnit'       
    IF @@ERROR <> 0 RETURN   
    
    -- 품목등록은 서비스호출단에서 비즈니스를 여러번 호출하기에 아래와 같이 단위환산 등록여부를 체크해도 품목정보는 저장이 되는 상황임   
    --IF NOT EXISTS ( SELECT 1 FROM #KPX_TDAItemUnit )  
    --BEGIN  
    --    EXEC dbo._SCOMMessage @MessageType OUTPUT,    
    --                          @Status      OUTPUT,    
    --                          @Results     OUTPUT,    
    --                          1001                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%없습니다%')    
    --                          @LanguageSeq       ,     
    --                          3117,'단위환산/속성정보'   -- SELECT * FROM _TCADictionary WHERE Word like '%환산%'    
                                
    --    SELECT @Status AS Status, @Results AS Result, @MessageType AS MessageType  
    --    RETURN  
    --END  
  
    -------------------------------------------  
    -- 중복여부체크  
    -------------------------------------------  
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                           @Status      OUTPUT,  
--                           @Results     OUTPUT,  
--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
--                           @LanguageSeq       ,   
--                           0,'환산단위'    
--   
--   
--   
--     UPDATE #KPX_TDAItemUnit  
--        SET Result        = REPLACE(@Results,'@2', C.UnitName),  
--            MessageType   = @MessageType,  
--            Status        = @Status  
--       FROM #KPX_TDAItemUnit AS A JOIN ( SELECT S.ItemSeq, S.UnitSeq  
--                                      FROM (  
--                                            SELECT A1.ItemSeq, A1.UnitSeq  
--                                              FROM #KPX_TDAItemUnit AS A1  
--                                             WHERE A1.WorkingTag IN ('A', 'U')  
--                                               AND A1.Status = 0  
--                                             GROUP BY A1.ItemSeq, A1.UnitSeq  
--                                            UNION ALL  
--                                            SELECT A1.ItemSeq, A1.UnitSeq  
--                                              FROM _TDAItemUnit AS A1 LEFT OUTER JOIN (SELECT ItemSeq, UnitSeq   
--                                                                            FROM #KPX_TDAItemUnit   
--                                                                           WHERE WorkingTag NOT IN ('D')   
--                                                                             AND Status = 0) AS A2  
--                                                                    ON A1.CompanySeq = @CompanySeq  
--                                                                   AND A1.ItemSeq    = A2.ItemSeq  
--                                                                   AND A1.UnitSeq    = A2.UnitSeq  
--                                             WHERE ISNULL(A2.UnitSeq, 0) = 0  
--                                           ) AS S  
--                                     GROUP BY S.ItemSeq, S.UnitSeq  
  --                                     HAVING COUNT(1) > 1  
--                                   ) AS B ON A.ItemSeq = B.ItemSeq  
--                                         AND A.UnitSeq = B.UnitSeq  
--                           JOIN _TDAUnit AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
--                                                           AND B.UnitSeq    = C.UnitSeq  
    -------------------------------------------  
    -- 사용여부체크  
    -------------------------------------------  
    
    -------------------------------------------    
    -- 단위수정여부체크   
    -------------------------------------------    
    IF EXISTS (SELECT 1   
                 FROM #KPX_TDAItemUnit AS A  
                      JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                          AND A.ItemSeq    = B.ItemSeq  
                                                          AND A.UnitSeqOld = B.UnitSeq  
                WHERE A.WorkingTag IN ('U','D')  
                  AND A.Status = 0  
                  AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D'))  
    BEGIN  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'사용된 단위'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','수정/삭제'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TLGInOutStock AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                    AND B.ItemSeq    = C.ItemSeq  
                                                                                    AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
  
  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'사용된 단위'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','수정/삭제'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                                JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TPDBOM AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                             AND B.ItemSeq    = C.ItemSeq  
                                                                             AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              19                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'사용된 단위'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','수정/삭제'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT C.ItemSeq, C.UnitSeq  
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItemUnit AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                                  AND A.ItemSeq    = B.ItemSeq  
                                                                                  AND A.UnitSeqOld = B.UnitSeq  
                                              JOIN _TSLItemUnitPrice AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                                                       AND B.ItemSeq    = C.ItemSeq  
                                                                                       AND B.UnitSeq    = C.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> B.UnitSeq OR A.WorkingTag = 'D')  
                                        GROUP BY C.ItemSeq, C.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
    END  
  
    -------------------------------------------    
    -- 기준단위수정여부체크   
    -------------------------------------------    
    IF EXISTS (SELECT 1   
                 FROM #KPX_TDAItemUnit AS A  
                      JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND A.ItemSeq    = B.ItemSeq  
                                                      AND A.UnitSeqOld = B.UnitSeq  
                WHERE A.WorkingTag IN ('U','D')  
                  AND A.Status = 0  
                  AND (A.UnitSeq <> A.UnitSeqOld OR A.WorkingTag = 'D'))  
    BEGIN  
        -------------------------------------------  
        -------------------------------------------  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                                19                   , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                              @LanguageSeq       ,   
                              0,'기준단위'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'  
        UPDATE #KPX_TDAItemUnit  
           SET Result        = REPLACE(@Results,'@2','수정/삭제'),  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS X JOIN (SELECT B.ItemSeq, B.UnitSeq   
                                         FROM #KPX_TDAItemUnit AS A  
                                              JOIN KPX_TDAItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                                              AND A.ItemSeq    = B.ItemSeq  
                                                                              AND A.UnitSeqOld = B.UnitSeq  
                                        WHERE A.WorkingTag IN ('U','D')  
                                          AND A.Status = 0  
                                          AND (A.UnitSeq <> A.UnitSeqOld OR A.WorkingTag = 'D')  
                                        GROUP BY B.ItemSeq, B.UnitSeq  
                                          ) AS Y ON (X.ItemSeq = Y.ItemSeq)  
                                                AND (X.UnitSeqOld = Y.UnitSeq)  
    END  
  
    -------------------------------------------------------------------------------------------------------------------------  
    -- 분자 분모 체크 : 기준단위와 환산단위가 같은 경우 분자, 분모는 다른 숫자로 입력 할 수 없다. 2010.12.24 by 정혜영  
    -------------------------------------------------------------------------------------------------------------------------  
    SELECT @StkUnitSeq = B.UnitSeq  
      FROM #KPX_TDAItemUnit AS A   
            LEFT OUTER JOIN KPX_TDAItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                      AND A.ItemSeq    = B.ItemSeq  
                                                            
    IF EXISTS(SELECT 1 FROM #KPX_TDAItemUnit WHERE UnitSeq = @StkUnitSeq)  
    BEGIN                                                            
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              1273               , -- 기준단위와 환산단위가 같으면 환산량분자와 환산량분자도 같아야 합니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1273)  
                              @LanguageSeq       ,   
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'     
        UPDATE A  
           SET Result        = @Results,  
               MessageType   = @MessageType,  
               Status        = @Status  
          FROM #KPX_TDAItemUnit AS A  
                JOIN #KPX_TDAItemUnit AS B ON A.UnitSeq = B.UnitSeq  
                                      AND A.ConvNum <> B.ConvDen  
         WHERE A.UnitSeq = @StkUnitSeq  
    END  
  
    -------------------------------------------  
    -- 마감여부체크  
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
    -------------------------------------------  
    -- 진행여부체크  
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
    -------------------------------------------  
    -- 확정여부체크   
    -------------------------------------------  
    -- 공통 SP Call 예정  
  
   
    SELECT * FROM #KPX_TDAItemUnit     
    RETURN      
GO 
exec KPX_SDAItemUnitCheck @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1025582,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021310