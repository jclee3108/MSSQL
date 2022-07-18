
IF OBJECT_ID('KPX_SLGInOutDailyItemCheck') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyItemCheck
GO 

-- v2014.12.05 

-- 사이트테이블로 변경 by이재천

-- v2012.09.06
  /************************************************************        
 설  명 - 입출고품목 체크        
 작성일 - 2008년 10월          
 작성자 - 정수환        
 수정일 - 2010.06.12 정동혁 : 자재는 자재소수점 자리수 적용
    2011.05.11 by 김철웅
   1) IsBatch를 ISNULL()처리함 - 일부 사이트에서 IsBatch의 default값 constraint를 삭제하여 오류 발생
 ************************************************************/        
 CREATE PROC KPX_SLGInOutDailyItemCheck        
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
             @GoodQtyDecLength INT,
             @MatQtyDecLength  INT,
             @Results     NVARCHAR(250),
             @AssetCheck  INT
      EXEC @GoodQtyDecLength    = dbo._SCOMEnvR @CompanySeq, 8, @UserSeq, @@PROCID -- 판매/제품 소수점자리수
     EXEC @MatQtyDecLength     = dbo._SCOMEnvR @CompanySeq, 5, @UserSeq, @@PROCID -- 자재 소수점자리수
      CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)          
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDaily'
         
     -- 서비스 마스타 등록 생성          
     CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)          
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TLGInOutDailyItem'         
      IF @WorkingTag = 'D'
     BEGIN
         UPDATE #TLGInOutDailyItem
            SET WorkingTag = 'D'
     END 
  
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
    FROM #TLGInOutDailyItem     AS A 
    --JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )
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
    FROM #TLGInOutDailyItem AS A 
   WHERE A.WorkingTag IN ( 'A' ) 
     AND A.Status = 0  
     AND A.InOutType IN (81,83)
     AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = A.OutWHSeq AND SMWHKind = 8002008 )
     --select * from _TDASMinor where CompanySeq = 1 and MajorSeq = 8002 
     
     -- 체크2, END
     
  
  
     -- 체크3, 기타입고 시, LotNo존재 시, 해당 품목의 LotMaster가 등록되었는지
     
     EXEC dbo._SCOMMessage @MessageType OUTPUT,          
                          @Status      OUTPUT,          
                           @Results     OUTPUT,          
                           1170, -- select * from _TCAMessageLanguage where MessageSeq = 1170
                           @LanguageSeq,           
                           0, '', -- select * from _TCADictionary where Word like '%적송중%'
                           0, 'LotNo' -- select * from _TCADictionary where Word like '%적송중%'
   
  UPDATE A
     SET A.Result   = REPLACE(@Results,'@1', '(' + C.ItemName + ' / ' + C.ItemNo + ')'),
      A.MessageType = @MessageType,        
      A.Status   = @Status     
    FROM #TLGInOutDailyItem AS A 
            LEFT OUTER JOIN _TLGLotMaster AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo
            LEFT OUTER JOIN _TDAItem AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq
            LEFT OUTER JOIN _TDAItemStock AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq
   WHERE A.WorkingTag IN ( 'A', 'U' ) 
     AND A.Status = 0  
     AND A.InOutType = 40
        AND ISNULL(A.LotNo,'') <> ''
        AND ISNULL(D.IsLotMng,'') = '1'
        AND B.CompanySeq IS NULL
     
     -- 체크3, END
     
  
  
      -------------------------------------------    
     -- 세트품은 사업부문이동 금지 jhpark 2012.03.30   
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
          @Status      OUTPUT,  
          @Results     OUTPUT,  
          1345                  , -- @1은 @2@3만 @4할 수 있습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1345)  
          @LanguageSeq ,
          '',''              
     UPDATE #TLGInOutDailyItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TLGInOutDailyItem AS A   
            JOIN _TDAItemSales AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq
      WHERE A.WorkingTag IN ('A', 'U')  
        AND B.IsSet = '1'  
        AND A.Status = 0  
        AND EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE BizUnit <> ReqBizUnit)
     
     -------------------------------------------    
     -- 세트품은 기타입출고 금지 jhpark 2012.03.30   
     -------------------------------------------    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,  
          @Status      OUTPUT,  
          @Results     OUTPUT,  
          1081                  , -- @1는[은] @2에서등록가능합니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1081)  
          @LanguageSeq ,
          1615,'' , 48342, ''
     
     UPDATE #TLGInOutDailyItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TLGInOutDailyItem   AS A   
       JOIN _TDAItemSales        AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq  
      WHERE A.WorkingTag IN ('A', 'U')  
        AND B.IsSet = '1'  
        AND A.Status = 0  
        AND EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE ReqBizUnit IS NULL)
        AND A.InOutType <> 100   -- 수탁출고 제외
        AND A.InOutType <> 50    -- 위탁출고 제외 
        AND A.InOutType <> 51    -- 위탁반품 제외 
     
     -- # 위에서 수탁출고를 제외하는 원인은 아래와 같습니다. 
     -- 1. 영업에서 수탁출고 프로세스는 거래명세서 판매후 보관 밖에 없습니다. 
     -- 2. 세트품목 판매후 보관은 하위품목이 세금계산서 끊을때 발생하기 때문에 
     --    수탁출고입력시 별도로 필요하지 않습니다. 
     
     ---------------------------------------------------------------------------------
     -- 품목명 자산분류 와 대체품목명 자산분류 일치 확인 체크 
     ---------------------------------------------------------------------------------     
     -- 품목규격대체입력화면 체크
     IF (SELECT TOP 1 InOutType FROM #TLGInOutDailyItem)='90'
     BEGIN
   DECLARE @EnvValue NVARCHAR(500)
    SELECT @EnvValue = EnvValue FROM _TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 2
   IF @@ROWCOUNT = 0 OR ISNULL( @EnvValue, '' ) = '' SELECT @EnvValue = '' 
          CREATE TABLE #IDX_No (IDX_No INT)
         
     -- 대체품목이 기존 품목과 같으면 에러발생
         IF 0 < (SELECT COUNT(1) FROM #TLGInOutDailyItem WHERE ItemSeq = OriItemSeq) AND @EnvValue <> 'DHE' -- 대한은박지 체크제외 
         BEGIN
             
             INSERT  INTO #IDX_No(IDX_No)
             SELECT IDX_NO FROM #TLGInOutDailyItem WHERE ItemSeq = OriItemSeq
              EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                   @Status      OUTPUT,    
                                   @Results     OUTPUT,      
                                   1289               ,  -- 같은 품명은 대체가 불가능 합니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%품명%')      
                                   @LanguageSeq       ,       
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
               
             UPDATE #TLGInOutDailyItem 
                SET  Result        = @Results,                  
                     MessageType   = @MessageType,                  
                     Status        = @Status  
               FROM #TLGInOutDailyItem AS A JOIN #IDX_No B ON A.IDX_No=B.IDX_No     
              WHERE  A.WorkingTag IN ('A','U')
         END
         
         TRUNCATE TABLE #IDX_No
         
         -- 품목 자산 분류가 동일하지 않으면 에러발생        
         INSERT INTO #IDX_No(IDX_No)   
         SELECT IDX_NO FROM #TLGInOutDailyItem A 
                                    LEFT OUTER JOIN _TDAItem B            ON B.CompanySeq = @CompanySeq 
                                                                         AND A.ItemSeq    = B.ItemSeq
                                    LEFT OUTER JOIN _TDAItem C            ON C.CompanySeq = @CompanySeq 
                                                                         AND A.OriItemSeq = C.ItemSeq
                                            WHERE ISNULL(B.AssetSeq,'') <> ISNULL(C.AssetSeq,'')
         
         IF @@RowCount > 0 AND @EnvValue <> 'FINE' -- 화인산업 체크제외 
         BEGIN
             EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                                   @Status      OUTPUT,      
                                   @Results     OUTPUT,      
                                   1288               ,  -- 품목 자산 분류가 동일해야 등록이 가능합니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%품목%')      
                                   @LanguageSeq       ,       
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'      
               
             UPDATE #TLGInOutDailyItem      
                SET  Result        = @Results,                  
                     MessageType   = @MessageType,                  
                     Status        = @Status  
               FROM #TLGInOutDailyItem AS A JOIN #IDX_No B ON A.IDX_No=b.IDX_No  
              WHERE  A.WorkingTag IN ('A','U')           
                      
         END
         DROP TABLE #IDX_No
     END
       -------------------------------------------        
      -- Lot관리시 Lot필수체크체크        
      -------------------------------------------        
      EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                            @Status      OUTPUT,        
                            @Results     OUTPUT,        
                            1171               , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessage WHERE MessageSeq = 1171)        
                            @LanguageSeq       ,         
                            0,'입출고'     
       UPDATE #TLGInOutDailyItem        
         SET Result        = @Results,        
             MessageType   = @MessageType,        
             Status        = @Status        
       FROM  #TLGInOutDailyItem A
             JOIN (SELECT  X.InOutType, X.InOutSeq, X.InOutSerl
                     FROM  #TLGInOutDailyItem X
                           LEFT OUTER JOIN _TLGInOutLotSub Y WITH(NOLOCK) ON Y.CompanySeq = @CompanySeq
                                                    AND X.InOutType  = Y.InOutType
                                                    AND X.InOutSeq   = Y.InOutSeq
                                                    AND X.InOutSerl  = Y.InOutSerl
                                                    AND X.InOutDataSerl = 0
                   GROUP BY X.InOutType, X.InOutSeq, X.InOutSerl) B ON B.InOutType  = A.InOutType
                                                                   AND B.InOutSeq   = A.InOutSeq
                                                                   AND B.InOutSerl  = A.InOutSerl
             JOIN  _TDAItemStock C ON C.CompanySeq = @CompanySeq AND A.ItemSeq = C.ItemSeq AND C.IsLotMng = '1'
      WHERE  (A.InOutType <> '310' AND ISNULL(A.LotNo, '') = '')
         OR  (A.InOutType = '310' AND ISNULL(A.ORILotNo, '') = '')
    
 --     UPDATE #TLGInOutDailyItem          
 --        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InOutSeq)),          
 --            MessageType   = @MessageType,          
 --            Status        = @Status          
 --       FROM #TLGInOutDailyItem AS A JOIN ( SELECT S.InOutSeq, S.InOutSerl        
 --                                      FROM (          
 --                                            SELECT A1.InOutSeq, A1.InOutSerl        
 --                                              FROM #TLGInOutDailyItem AS A1          
 --                                             WHERE A1.WorkingTag IN ('U')          
 --                                               AND A1.Status = 0          
 --                                            UNION ALL          
 --                                            SELECT A1.InOutSeq, A1.InOutSerl        
 --                                              FROM KPX_TPUMatOutEtcOutItem AS A1 JOIN KPX_TPUMatOutEtcOut AS A10          
 --                                                     ON A1.CompanySeq = A10.CompanySeq    
 --                                                    AND A1.InOutSeq   = A10.InOutSeq    
 --                                                    AND A10.IsBatch <> '1'    
 --          WHERE A1.InOutSeq  NOT IN (SELECT InOutSeq          
 --                                                                            FROM #TLGInOutDailyItem           
 --                                                                           WHERE WorkingTag IN ('U','D')           
 --                                                                             AND Status = 0)          
 --                                               AND A1.InOutSerl  NOT IN (SELECT InOutSerl          
 --                                                                             FROM #TLGInOutDailyItem           
 --                                                                            WHERE WorkingTag IN ('U','D')           
 --                                                                              AND Status = 0)          
 --                                               AND A1.CompanySeq = @CompanySeq          
 --                                           ) AS S          
 --                                     GROUP BY S.InOutSeq, S.InOutSerl        
 --                                     HAVING COUNT(1) > 1          
 --                                   ) AS B ON A.InOutSeq  = B.InOutSeq          
 --                                         AND A.InOutSerl = B.InOutSerl          
   /***************** 기준단위 체크 ************************************/  
  /***************** 기준단위 체크 ************************************/  
      EXEC dbo._SCOMMessage @MessageType OUTPUT,
                            @Status      OUTPUT,
                            @Results     OUTPUT,
                            1008         , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '기준단위%' )
                            @LanguageSeq , 
                            2474,''   -- SELECT * FROM _TCADictionary WHERE Word like '%기준단위%'
      -- 기준단위수량
      UPDATE #TLGInOutDailyItem          
         SET Result       = @Results,          
             MessageType   = @MessageType,          
             Status        = @Status          
       FROM  #TLGInOutDailyItem AS A
             JOIN _TDAItemStock AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                 AND A.ItemSeq    = B.ItemSeq     
      WHERE A.Status = 0    
        AND ISNULL(B.IsQtyChange,'') <> '1'    
        AND ISNULL(A.Qty,0) <> 0
        AND ISNULL(A.STDQty,0) = 0
  
      EXEC dbo._SCOMMessage @MessageType OUTPUT,
                            @Status      OUTPUT,
                            @Results     OUTPUT,
                            1008         , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '기준단위%' )
                            @LanguageSeq       , 
                            7,''   -- SELECT * FROM _TCADictionary WHERE Word like '%기준단위%'
      -- 품목
      UPDATE #TLGInOutDailyItem          
         SET Result        = @Results,          
             MessageType   = @MessageType,          
             Status        = @Status          
       FROM  #TLGInOutDailyItem  
      WHERE Status = 0    
        AND ISNULL(ItemSeq,0) = 0
   /***************** 기준단위 체크 ************************************/  
  /***************** 기준단위 체크 ************************************/  
     UPDATE #TLGInOutDailyItem
        SET STDQty = CASE T.MinorValue WHEN '0' THEN ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END), @GoodQtyDecLength)
                                                ELSE ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END), @MatQtyDecLength)
                     END
       FROM #TLGInOutDailyItem AS A
            JOIN _TDAItemUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                               AND A.ItemSeq    = B.ItemSeq
                                               AND A.UnitSeq    = B.UnitSeq
            JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq
                                                AND A.ItemSeq    = C.ItemSeq
            JOIN _TDAItem      AS I WITH(NOLOCK) ON A.ItemSeq   = I.ItemSeq
                                                AND I.CompanySeq = @CompanySeq
            JOIN _TDAItemAsset AS S WITH(NOLOCK) ON I.AssetSeq   = S.AssetSeq
                                                AND S.CompanySeq = @CompanySeq
            JOIN _TDASMinor    AS T WITH(NOLOCK) ON S.SMAssetGrp = T.MinorSeq
                                                AND T.CompanySeq = @CompanySeq
      WHERE A.Status = 0
        AND ISNULL(A.Qty,0) <> 0
        AND ISNULL(C.IsQtyChange,'') <> '1'
  
           
     SELECT @Count = COUNT(1) FROM #TLGInOutDailyItem WHERE WorkingTag = 'A' AND Status = 0          
              
     IF @Count > 0          
     BEGIN            
         -- 키값생성코드부분 시작            
         SELECT @Seq = ISNULL((SELECT MAX(A.InOutSerl)          
                                 FROM KPX_TPUMatOutEtcOutItem AS A WITH(NOLOCK) JOIN KPX_TPUMatOutEtcOut AS A10  WITH(NOLOCK)         
                                                     ON A.CompanySeq = A10.CompanySeq    
                                                    AND A.InOutSeq   = A10.InOutSeq    
                                                    AND ISNULL( A10.IsBatch, '0' ) <> '1'    -- 20110511 
                                WHERE A.CompanySeq = @CompanySeq          
                                  AND A.InOutSeq  IN (SELECT InOutSeq        
                                                        FROM #TLGInOutDailyItem          
                                                       WHERE InOutSeq = A.InOutSeq)),0)          
           
         -- Temp Talbe 에 생성된 키값 UPDATE          
         UPDATE #TLGInOutDailyItem          
            SET InOutSerl   = @Seq + A.DataSeq      
           FROM #TLGInOutDailyItem AS A         
          WHERE A.WorkingTag = 'A'          
            AND A.Status = 0          
     END            
  
     SELECT * FROM #TLGInOutDailyItem          
  
  RETURN