
IF OBJECT_ID('KPX_SLGInOutDailyCheck') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyCheck
GO

-- v2014.12.05 

-- 사이트테이블로 변경 by이재천 
    -- Ver.20140120  
  
-- 2012.03.29 by 김철웅  
-- 수정: 적송입고입력시 이동일자(출고일자)가 입고일자보다 작으면 오류 메시지 호출    
  
-- 수불저장체크, 2008.01 by 정수환   
-- 적송입고입력   
CREATE PROC KPX_SLGInOutDailyCheck    
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
            @TableSeq    INT,   
            @LGStartDate NCHAR(6)  
    
    
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #LGInOutDailyCheck (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#LGInOutDailyCheck'         
    IF @@ERROR <> 0 RETURN     
   
    IF @WorkingTag = 'D'       
    BEGIN      
        UPDATE #LGInOutDailyCheck      
           SET WorkingTag = 'D'      
    END      
      
    -- 창고재고실사등록에서 생성 된 건은 기타출고입력에서 삭제불가 :: 20140220 박성호 추가  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1167               , -- @1은(는) 삭제할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1167)      
                          @LanguageSeq       ,    
                          0, '창고재고실사등록에서 등록 된 데이터'  
    UPDATE #LGInOutDailyCheck      
       SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status  
      FROM #LGInOutDailyCheck      AS A  
     WHERE A.WorkingTag = 'D'  
       AND A.InOutType  = 30  
       AND @PgmSeq      = 1368  
       AND EXISTS ( SELECT 1 FROM _TLGWHStkReal WHERE InOutSeq = A.InOutSeq AND IsEtcOut = '1' AND CompanySeq = @CompanySeq )  
  
    -- 창고재고실사등록에서 생성 된 건은 필수 데이터에 대해 기타출고입력에서 수정불가 :: 20140220 박성호 추가  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          2012               , -- @1은(는) 수정 삭제 할 수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 2012)      
                          @LanguageSeq       ,    
                          0, '창고재고실사등록에서 등록 된 데이터의 필수데이터'  
    UPDATE #LGInOutDailyCheck      
       SET Result        = REPLACE(@Results, ' 삭제', '') ,  
           MessageType   = @MessageType                   ,  
           Status        = @Status  
      FROM #LGInOutDailyCheck  AS A  
           JOIN KPX_TPUMatOutEtcOut AS B ON @CompanySeq = B.CompanySeq  
                                   AND A.InOutSeq  = B.InOutSeq  
                                   AND A.InOutType = B.InOutType  
     WHERE B.CompanySeq = @CompanySeq  
       AND A.WorkingTag = 'U'         
       AND A.InOutType  = 30  
       AND @PgmSeq      = 1368  
       AND EXISTS ( SELECT 1 FROM _TLGWHStkReal WHERE InOutSeq = A.InOutSeq AND IsEtcOut = '1' AND CompanySeq = @CompanySeq )  
       AND (A.BizUnit   <> B.BizUnit   OR  
            A.InOutDate <> B.InOutDate OR  
            A.OutWHSeq  <> B.OutWHSeq   )  
  
    -- 체크1, SerialNo 반영여부체크   
      
    -- @2 @1(@3)가(이) 등록되어 수정/삭제 할 수 없습니다.  
 -- SerialNo가(이) 등록되어 수정/삭제 할 수 없습니다.  
 EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          8, -- select * from _TCAMessageLanguage where MessageSeq = 8  
                          @LanguageSeq,             
                          0,'SerialNo'  
   
   
 -- ※ 적송, 세트품목건을 생각할 필요가 없음, 두 단계로 된 건은 마지막 단계 진행되였을때만 SerialNo등록을 하니까...    
 UPDATE A  
      SET A.Result   = REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ),   
     A.MessageType = @MessageType,          
     A.Status   = @Status       
   FROM #LGInOutDailyCheck     AS A   
   --JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
   JOIN _TLGInOutSerialStock     AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )   
    AND A.Status = 0    
   
 -- 체크1, END   
   
 -- 체크2, 적송입고입력시 이동일자(출고일자)가 입고일자보다 작으면 오류 메시지 호출   
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          1200, -- select * from _TCAMessageLanguage where Message like '%큽니다%'  
                          @LanguageSeq,             
                          31997, N'이동일자', -- select * from _TCADictionary where Word like '이동일자'  
                       20881, N'입고일자'   
 UPDATE A  
    SET A.Result   = @Results,   
     A.MessageType = @MessageType,          
     A.Status   = @Status       
 --select A.InOutDate, A.CompleteDate   
   FROM #LGInOutDailyCheck             AS A   
   LEFT OUTER JOIN KPX_TPUMatOutEtcOutItemSub AS B ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq )  
  WHERE 1=1 --A.WorkingTag IN ( 'A', 'U' )   
    AND A.Status = 0    
    AND A.InOutType = 81   
    --AND ISNULL( A.CompleteDate, '' ) <> '' -- 입고일자가 없으면 적송입고입력으로 보기   
    AND B.CompanySeq IS NULL   
    AND A.InOutDate > A.CompleteDate  
      
 -- 체크2, END   
   
    --------------------------------------------------------------------------------------    
    -- 물류시작월 이전 데이터는 입력되지 않도록 한다.     
    --------------------------------------------------------------------------------------    
    EXEC dbo._SCOMEnv @CompanySeq, 1006, @UserSeq, @@PROCID, @LGStartDate OUTPUT    
      
    IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE InOutDate < @LGStartDate + '01')  
    BEGIN   
        EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                              @Status      OUTPUT,      
                              @Results     OUTPUT,      
                              1197               , -- @1이 @2보다 빠릅니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1197)      
                              @LanguageSeq       ,       
                              238,'',     -- SELECT * FROM _TCADictionary WHERE Word like '%처리일%'      
                              28610,''    -- SELECT * FROM _TCADictionary WHERE Word like '%물류시작%'      
        UPDATE #LGInOutDailyCheck      
           SET Result        = @Results    ,      
               MessageType   = @MessageType,      
               Status        = @Status      
          FROM #LGInOutDailyCheck     
            
    END  
  
    -- 적송인 경우 값을 업데이트(오공에서 값이 바뀌는 현상으로 추가)  
    UPDATE #LGInOutDailyCheck  
       SET IsTrans = '1'  
     WHERE Status = 0    
       AND InOutType IN (81,83)  
  
  
  
  
    -- 이동일 때, 입고창고/출고창고가 모두 있는지 체크  
    IF NOT EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
    BEGIN  
     EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                              @Status      OUTPUT,            
                              @Results     OUTPUT,            
                              133, -- select * from _TCAMessageLanguage where Message like '%누락%' and LanguageSeq = 1  
                              @LanguageSeq,             
                              0, N''  
     UPDATE A  
        SET A.Result   = CASE WHEN ISNULL(A.InWHSeq,0) = 0 THEN @Results + ' (' + (SELECT Word FROM _TCADictionary WHERE WordSeq = 584 AND LanguageSeq = @LanguageSeq) + ')'  
                                       WHEN ISNULL(A.OutWHSeq,0) = 0 THEN @Results + ' (' + (SELECT Word FROM _TCADictionary WHERE WordSeq = 626 AND LanguageSeq = @LanguageSeq) + ')'  
                                       ELSE @Results END,   
            A.MessageType = @MessageType,          
         A.Status   = @Status       
       FROM #LGInOutDailyCheck AS A  
      WHERE A.WorkingTag IN ( 'A', 'U' )   
        AND A.Status = 0  
        AND A.InOutType = 80  
           AND (ISNULL(A.InWHSeq,0) = 0 OR ISNULL(A.OutWHSeq,0) = 0)  
    END  
  
  
  
  
    -------------------------------------------      
    -- 중복여부체크      
    -------------------------------------------      
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,      
--                           @Status      OUTPUT,      
--                           @Results     OUTPUT,      
--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)      
--                           @LanguageSeq       ,       
--                           0,'입출고'        
--     UPDATE #LGInOutDailyCheck      
--        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),      
--            MessageType   = @MessageType,      
--            Status        = @Status      
--       FROM #LGInOutDailyCheck AS A JOIN ( SELECT S.InOutSeq  
--                                      FROM (      
--                                            SELECT A1.InOutSeq  
--                                              FROM #LGInOutDailyCheck AS A1      
--                                             WHERE A1.WorkingTag IN ('A','U')      
--                                               AND A1.Status = 0      
--                                            UNION ALL      
--                                            SELECT A1.InOutSeq   
--                                              FROM KPX_TPUMatOutEtcOut AS A1      
--                                             WHERE A1.InOutSeq   NOT IN (SELECT InOutSeq    
--                                                                           FROM #LGInOutDailyCheck       
--                                                                          WHERE WorkingTag IN ('U','D')       
--                                                                            AND Status = 0)      
--                                               AND A1.CompanySeq = @CompanySeq      
--                                           ) AS S      
--                                     GROUP BY S.InOutSeq   
--                                     HAVING COUNT(1) > 1      
--                                   ) AS B ON A.InOutSeq = B.InOutSeq      
     
      
    --ERR Message    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1130               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)      
                          @LanguageSeq       ,       
                          0,'배차건'   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'      
  
    UPDATE #LGInOutDailyCheck      
       SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #LGInOutDailyCheck   AS A      
           JOIN (SELECT Seq AS InOutSeq  
                   FROM _TLGTransCarPackingItem   
                  WHERE CompanySeq = @CompanySeq  
                    AND ServiceSeq IN (8039007, 8039009)  
                  GROUP BY Seq) AS B ON A.InOutSeq = B.InOutSeq  
  WHERE A.InOutType NOT IN (81) -- 적송제외   
    
 --select * from _TDASMinor where MajorSeq = 8042  
   
    --   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)      
                          @LanguageSeq       ,       
                          0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'      
  
    UPDATE #LGInOutDailyCheck      
         SET Result        = @Results    ,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #LGInOutDailyCheck   AS A      
           JOIN KPX_TPUMatOutEtcOut AS B ON B.CompanySeq = @CompanySeq  
                                   AND A.InOutType  = B.InOutType  
                                   AND A.InOutSeq   = B.InOutSeq  
     WHERE B.IsTrans = '1'   
       AND B.IsCompleted = '1'  
       AND A.IsInTrans = '1'  
  
  
    -- 적송에 따른 일자 Update  
    UPDATE #LGInOutDailyCheck  
       SET CompleteDate = ''  
     WHERE Status = 0    
       AND IsCompleted <> '1'  
  
  
    -------------------------------------------    
    -- 진행여부체크    
    -------------------------------------------    
    IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE WorkingTag IN ('U', 'D') )    
    BEGIN    
        -- 진행체크할 테이블값 테이블  
        CREATE TABLE #TMP_PROGRESSTABLE(IDOrder INT IDENTITY, TABLENAME   NVARCHAR(100))        
          
        -- 진행체크할 데이터 테이블  
        CREATE TABLE #Temp_InOutDaily(IDX_NO INT IDENTITY, InOutSeq INT, InOutSerl INT, InOutType INT, IsNext NCHAR(1), IsStop NCHAR(1))   
          
        -- 진행된 내역 테이블  
        CREATE TABLE #TCOMProgressTracking(IDX_NO   INT,            IDOrder INT,            Seq INT,           Serl INT,            SubSerl INT,  
                                           Qty      DECIMAL(19, 5), StdQty  DECIMAL(19,5) , Amt DECIMAL(19, 5),VAT DECIMAL(19,5))          
  
        SELECT @TableSeq = ProgTableSeq  
          FROM _TCOMProgTable WITH(NOLOCK)--진행대상테이블  
         WHERE ProgTableName = 'KPX_TPUMatOutEtcOutItem'  
  
        INSERT INTO #TMP_PROGRESSTABLE(TABLENAME)  
        SELECT B.ProgTableName  
          FROM (SELECT ToTableSeq FROM _TCOMProgRelativeTables WITH(NOLOCK) WHERE FromTableSeq = @TableSeq AND CompanySeq = @CompanySeq) AS A --진행테이블관계  
                JOIN _TCOMProgTable AS B WITH(NOLOCK) ON A.ToTableSeq = B.ProgTableSeq  
  
       INSERT INTO #Temp_InOutDaily(InOutSeq, InOutSerl, InOutType, IsNext, IsStop) -- IsNext=1(진행), 0(미진행)  
        SELECT  A.InOutSeq, B.InOutSerl, B.InOutType, '0', '0'  
          FROM #LGInOutDailyCheck     AS A WITH(NOLOCK)     
                JOIN KPX_TPUMatOutEtcOut AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                     AND A.InOutSeq   = C.InOutSeq  
                                                     AND A.InOutType  = C.InOutType  
                JOIN KPX_TPUMatOutEtcOutItem AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq    
                                                         AND A.InOutSeq     = B.InOutSeq  
                                                         AND A.InOutType    = B.InOutType  
         WHERE A.WorkingTag IN ('U', 'D')    
           AND A.Status = 0    
  
        EXEC _SCOMProgressTracking @CompanySeq, 'KPX_TPUMatOutEtcOutItem', '#Temp_InOutDaily', 'InOutSeq', 'InOutSerl', 'InOutType'     
    
        --진행여부 체크  
        UPDATE #Temp_InOutDaily     
          SET IsNext = '1'    
         FROM  #Temp_InOutDaily AS A    
                JOIN #TCOMProgressTracking AS B ON A.IDX_No = B.IDX_No    
  
        --ERR Message (진행)  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                              @Status      OUTPUT,    
                              @Results     OUTPUT,    
                              1044               , -- 다음 작업이 진행되어서 변경,삭제할 수 없습니다..(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1044)    
                              @LanguageSeq       ,     
                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%단위%'    
        UPDATE #LGInOutDailyCheck    
           SET Result        = @Results    ,    
               MessageType   = @MessageType,    
               Status        = @Status    
          FROM #LGInOutDailyCheck   AS A    
               JOIN #Temp_InOutDaily AS B ON A.InOutSeq = B.InOutSeq   
         WHERE B.IsNext = '1'   
                         
    END  
  
    -------------------------------------------      
    -- INSERT 번호부여(맨 마지막 처리)      
      -------------------------------------------      
    SELECT @Count = COUNT(1) FROM #LGInOutDailyCheck WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
    IF @Count > 0      
    BEGIN        
        SELECT @BizUnit = MAX(BizUnit),      
               @Date    = ISNULL(MAX(InOutDate),REPLACE(CONVERT(CHAR(10),GETDATE(),121),'-',''))      
          FROM #LGInOutDailyCheck WHERE WorkingTag = 'A' AND Status = 0      
    
  
        -- 키값생성코드부분 시작        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPUMatOutEtcOut', 'InOutSeq', @Count      
  
    print @Seq  
        -- Temp Talbe 에 생성된 키값 UPDATE      
        UPDATE #LGInOutDailyCheck      
           SET InOutSeq = @Seq + DataSeq      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
      
        -- 번호생성코드부분 시작        
        exec dbo._SCOMCreateNo 'LG', 'KPX_TPUMatOutEtcOut', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT      
        -- Temp Talbe 에 생성된 키값 UPDATE      
        UPDATE #LGInOutDailyCheck      
           SET InOutNo = @MaxNo      
         WHERE WorkingTag = 'A'      
           AND Status = 0      
  
  
    END        
      
    SELECT * FROM #LGInOutDailyCheck      
    
    RETURN        