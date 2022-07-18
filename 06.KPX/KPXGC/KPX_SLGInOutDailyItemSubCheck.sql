  
IF OBJECT_ID('KPX_SLGInOutDailyItemSubCheck') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyItemSubCheck
GO 

-- v2014.12.05 

-- 사이트테이블로 변경 by이재천 

-- v2013.01.04  
  
/************************************************************        
설  명 - 입출고품목 체크        
작성일 - 2008년 10월          
작성자 - 정수환        
_SSLOrderItemCheck      
************************************************************/        
CREATE PROC KPX_SLGInOutDailyItemSubCheck        
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
            @Results     NVARCHAR(250)          
        
    -- 서비스 마스타 등록 생성          
    CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)          
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TLGInOutDailyItemSub'          
      
    -- 체크1, serial등록여부   
      
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
   FROM #TLGInOutDailyItemSub AS A   
   --JOIN _TLGInOutSerialSub  AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
   JOIN _TLGInOutSerialStock     AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )   
    AND A.Status = 0    
   
 -- 체크1, END  
      
    -- 체크2, 적송중창고 존재여부   
      
    EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          1001, -- select * from _TCAMessageLanguage where MessageSeq = 1001  
                          @LanguageSeq,             
                          23905, N'적송중창고' -- select * from _TCADictionary where Word like '%적송중%'  
    
 UPDATE A  
    SET A.Result   = A.OutWHName + '-' + @Results,  
     A.MessageType = @MessageType,          
     A.Status   = @Status       
   FROM #TLGInOutDailyItemSub AS A   
  WHERE A.WorkingTag IN ( 'A' )   
    AND A.Status = 0    
    AND A.InOutType = 81   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = A.OutWHSeq AND SMWHKind = 8002008 )  
      
    --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8002   
      
    -- 체크2, END  
      
    DECLARE @InOutSeq INT--, @clock datetime   
    --select @clock = getdate()  
      
    SELECT TOP 1 @InOutSeq = InOutSeq FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0    
      
    -- 체크3, 적송입력수량 <> 적송입고입력수량   
    IF ( (SELECT COUNT(1) FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0)   
         <>   
         (SELECT COUNT(1) FROM KPX_TPUMatOutEtcOutItem WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND InOutType IN(81,83) AND InOutSeq = @InOutSeq)  
       )   
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                              @Status      OUTPUT,            
                              @Results     OUTPUT,            
                              1292, -- select * from _TCAMessageLanguage where Message like '%와%'  
                              @LanguageSeq,             
              48675, N'적송입력수량', -- select * from _TCADictionary where Word like '%적송입고입력%'  
                              48676, N'적송입고입력수량'  
          
        UPDATE A  
        SET A.Result   = @Results,  
         A.MessageType = @MessageType,          
         A.Status   = @Status       
       FROM #TLGInOutDailyItemSub AS A   
      WHERE A.WorkingTag IN ( 'A' )   
        AND A.Status = 0    
          
    END  
      
    --select datediff( ms, @clock, getdate() )   
      
    -- 체크3, END  
      
     -------------------------------------------          
     -- Lot관리시 Lot필수체크체크          
     -------------------------------------------          
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                           @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1171               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1171)          
                           @LanguageSeq       ,           
                           0,'입출고'       
  
     UPDATE #TLGInOutDailyItemSub          
        SET Result        = @Results,          
            MessageType   = @MessageType,          
            Status        = @Status          
      FROM  #TLGInOutDailyItemSub A  
            JOIN (SELECT  X.InOutType, X.InOutSeq, X.InOutSerl, X.DataKind, X.InOutDataSerl  
                    FROM  #TLGInOutDailyItemSub X  
                          LEFT OUTER JOIN _TLGInOutLotSub Y WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq  
                                                   AND X.InOutType  = Y.InOutType  
                                                   AND X.InOutSeq   = Y.InOutSeq  
                                                   AND X.InOutSerl  = Y.InOutSerl  
                                                   AND X.DataKind  = Y.DataKind  
                                                   AND X.InOutDataSerl  = Y.InOutDataSerl  
                  GROUP BY X.InOutType, X.InOutSeq, X.InOutSerl, X.DataKind, X.InOutDataSerl  
                  HAVING COUNT(1) = 1 ) B ON B.InOutType  = A.InOutType  
                                         AND B.InOutSeq   = A.InOutSeq  
                                         AND B.InOutSerl  = A.InOutSerl  
                                         AND B.DataKind  = A.DataKind  
                                         AND B.InOutDataSerl  = A.InOutDataSerl  
            JOIN  _TDAItemStock C ON A.ItemSeq = C.ItemSeq AND C.IsLotMng = '1'  
     WHERE  ISNULL(A.LotNo, '') = ''  
  
    -------------------------------------------    
    -- 적송기타여부체크                                
    -------------------------------------------    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                          @Status      OUTPUT,        
                          @Results     OUTPUT,        
                          15                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 15)        
                          @LanguageSeq, 3043, ''  
  
    
    UPDATE #TLGInOutDailyItemSub        
       SET Result        = Replace(Replace(@Results, '@2', ''), '(@3)', ''),  
           MessageType   = @MessageType,        
           Status        = @Status        
      FROM #TLGInOutDailyItemSub AS A   
           JOIN KPX_TPUMatOutEtcOutItemSub AS A1 WITH(NOLOCK) ON A1.CompanySeq = @CompanySeq    
                                           AND A.InOutType  = A1.InOutType    
                                           AND A.InOutSeq  = A1.InOutSeq    
                                           AND A.InOutSerl  = A1.InOutSerl    
     WHERE A.WorkingTag IN ('D')    
       AND A.Status = 0    
       AND A.InOutType IN (81,83)  
       AND (A.DataKind = 1 AND A1.DataKind = 2)  
  
    -------------------------------------------          
    -- 존재여부체크          
    -------------------------------------------          
    EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                            @Status      OUTPUT,           
                          @Results     OUTPUT,          
                          5                  , -- 이미 @1가(이) 완료된 @2입니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 5)          
                          @LanguageSeq       ,           
                          0,'입고처리',0,'자료'            
    UPDATE #TLGInOutDailyItemSub          
       SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),          
           MessageType   = @MessageType,          
           Status        = @Status          
      FROM #TLGInOutDailyItemSub AS A JOIN ( SELECT S.InOutSeq, S.InOutSerl, S.InOutType      
                                     FROM (          
                                           SELECT A1.InOutSeq, A1.InOutSerl, A1.InOutType        
                                             FROM #TLGInOutDailyItemSub AS A1          
                                            WHERE A1.WorkingTag IN ('A')          
                                              AND A1.Status = 0          
                                           UNION ALL          
                                           SELECT A1.InOutSeq, A1.InOutSerl, A1.InOutType        
                                             FROM KPX_TPUMatOutEtcOutItemSub AS A1          
                                            WHERE A1.InOutSeq  NOT IN (SELECT InOutSeq          
                                                                           FROM #TLGInOutDailyItemSub           
                                                                          WHERE WorkingTag IN ('U','D')           
                                                                            AND Status = 0)          
                                              AND A1.InOutSerl  NOT IN (SELECT InOutSerl          
                                                                            FROM #TLGInOutDailyItemSub           
                                                                           WHERE WorkingTag IN ('U','D')           
                                                                             AND Status = 0)          
                                              AND A1.CompanySeq = @CompanySeq          
                                          ) AS S          
                                    GROUP BY S.InOutSeq, S.InOutSerl, S.InOutType       
                                    HAVING COUNT(1) > 1          
                                  ) AS B ON A.InOutSeq  = B.InOutSeq          
                                        AND A.InOutSerl = B.InOutSerl     
                                        AND A.InOutType = B.InOutType     --InoutType도 조건에추가 20120105 jhpark  
          
          
    SELECT @Count = COUNT(1) FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
             
    IF @Count > 0          
    BEGIN            
        -- 키값생성코드부분 시작            
--        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPUMatOutEtcOutItemSub', 'TransReqSerl', @Count          
        SELECT @Seq = ISNULL((SELECT MAX(A.InOutDataSerl)          
                                FROM KPX_TPUMatOutEtcOutItemSub AS A WITH(NOLOCK)   JOIN KPX_TPUMatOutEtcOut AS A10 WITH(NOLOCK)       
                                                          ON A.CompanySeq = A10.CompanySeq  
                                                         AND A.InOutSeq   = A10.InOutSeq  
                                                         AND A10.IsBatch <> '1'        
                               WHERE A.CompanySeq = @CompanySeq          
                                 AND A.InOutSeq  IN (SELECT InOutSeq        
                                                       FROM #TLGInOutDailyItemSub          
                                                      WHERE InOutSeq = A.InOutSeq          
                                                        AND InOutSerl = A.InOutSerl)),0)          
          
        -- Temp Talbe 에 생성된 키값 UPDATE          
        UPDATE #TLGInOutDailyItemSub          
      SET InOutDataSerl   = @Seq + A.DataSeq      
          FROM #TLGInOutDailyItemSub AS A         
         WHERE A.WorkingTag = 'A'          
           AND A.Status = 0          
    END            
          
    SELECT * FROM #TLGInOutDailyItemSub          
      
    RETURN          
  