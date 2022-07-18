
IF OBJECT_ID('DTI_SSLInvoiceItemCheck') IS NOT NULL
    DROP PROC DTI_SSLInvoiceItemCheck 

GO
-- v2013.06.18   
  
/*********************************************************************************************************************    
    화면명 : 거래명세서_세부체크    
    SP Name: _SSLInvoiceItemCheck    
    작성일 : 2008.08.13 : CREATEd by 정혜영        
    수정일 :     
********************************************************************************************************************/    
CREATE PROC DTI_SSLInvoiceItemCheck      
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS        
    DECLARE @Count            INT,    
            @InvoiceSeq       INT,    
            @BizUnit         INT,     
            @MaxInvoiceSerl   INT,    
            @MessageType      INT,    
            @Status           INT,    
            @GoodQtyDecLength INT,  
            @Results          NVARCHAR(250)    
  
    EXEC @GoodQtyDecLength = dbo._SCOMEnvR @CompanySeq, 8, @UserSeq, @@PROCID -- 판매/제품 소수점자리수  
      
    -- 서비스 마스타 등록 생성      
    CREATE TABLE #TSLInvoiceItem (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLInvoiceItem'     
      
    CREATE TABLE #TSLInvoice (WorkingTag NCHAR(1) NULL)  -- 사업부문에 해당하는 창고인지 비교하기위해 추가 2011.03.24 hyjung    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TSLInvoice'      
   
    -- 체크 0, 원천코드가 있는 전제하에서 .. 원천-수주 혹은 출하의뢰가 없으면 오류호출   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            1365               , -- @1(이)가 존재하지 않습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%존재하지%')  
                            @LanguageSeq       ,  
                            2451, N'원천'  
    
    DECLARE @WORD1 NVARCHAR(50), @WORD2 NVARCHAR(50), @WORD3 NVARCHAR(50)  
      
    SELECT @WORD1 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 25275  
    IF @@ROWCOUNT = 0 SELECT @WORD1 = N'출하의뢰'   
      
    SELECT @WORD2 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 23642  
    IF @@ROWCOUNT = 0 SELECT @WORD2 = N'수주'   
      
    SELECT @WORD3 = Word FROM _TCADictionary WITH(NOLOCK) WHERE LanguageSeq = @LanguageSeq AND WordSeq = 607  
    IF @@ROWCOUNT = 0 SELECT @WORD3 = N'확정'   
      
    -- SELECT * FROM _TCADictionary WITH(NOLOCK) WHERE Word like '확정'  
    --select * from _TCOMProgTable where ProgTableName = '_TSLDVReqItem' -- 16  
      
    UPDATE A  
       SET A.Result        = '('+@WORD3+')'+@WORD1+' '+@Results,   
     A.MessageType   = @MessageType,   
     A.Status        = @Status  
    --select B.* --FromTableSeq, FromSeq, FromSerl, FromSubSerl   
      FROM #TSLInvoiceItem              AS A   
      LEFT OUTER JOIN _TSLDVReqItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.FromSeq = B.DVReqSeq AND A.FromSerl = B.DVReqSerl )  
      LEFT OUTER JOIN _TSLDVReq_Confirm AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND C.CfmSecuSeq = 6304 AND B.DVReqSeq = C.CfmSeq )  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0   
       AND ISNULL(A.FromTableSeq,0) = 16 -- 출하의뢰   
       AND ISNULL(A.FromSeq,0) <> 0 -- 원천코드가 있는 전제하에서 ..  
       AND (B.DVReqSeq IS NULL OR ISNULL(C.CfmCode,'0') <> '1') -- 원천이 없거나, 확정처리 되지 않으면 ...  
      
    IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
      
    UPDATE A  
       SET A.Result        = '('+@WORD3+')'+@WORD2+' '+@Results,   
     A.MessageType   = @MessageType,   
     A.Status        = @Status  
    --select B.* --FromTableSeq, FromSeq, FromSerl, FromSubSerl   
      FROM #TSLInvoiceItem              AS A   
        LEFT OUTER JOIN _TSLOrderItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.FromSeq = B.OrderSeq AND A.FromSerl = B.OrderSerl  )  
      LEFT OUTER JOIN _TSLOrder_Confirm AS C WITH(NOLOCK) ON ( B.CompanySeq = C.CompanySeq AND C.CfmSecuSeq = 6303 AND B.OrderSeq = C.CfmSeq )  
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0   
       AND ISNULL(A.FromTableSeq,0) = 19 -- 수주   
       AND ISNULL(A.FromSeq,0) <> 0 -- 원천코드가 있는 전제하에서 ..  
       AND (B.OrderSeq IS NULL OR ISNULL(C.CfmCode,'0') <> '1') -- 원천이 없거나, 확정처리 되지 않으면 ...  
      
    IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
      
    -- 체크 0, END   
      
 -- 체크1, 재고수량관리하는 품목에 한하여 매출대기창고가 없는 창고일때 매출이 발생하지 못하게 막기   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- 에 해당하는 @1를 찾을수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%없습니다%')  
                            @LanguageSeq       ,   
                            23906,'매출대기창고'   -- SELECT * FROM _TCADictionary WHERE Word like '%매출대기창고%'          
   
 UPDATE C  
       SET C.Result        = (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = C.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
 --select *   
   FROM #TSLInvoiceItem as C       
   JOIN _TDAItem   as D with(nolock) on ( D.CompanySeq = @CompanySeq and C.ItemSeq = D.ItemSeq )  
   JOIN _TDAItemAsset as E with(nolock) on ( E.CompanySeq = @CompanySeq and D.AssetSeq = E.AssetSeq and E.IsQty = '0' )  
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = C.WHSeq and SMWHKind = 8002009 and IsUse = '1')  
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- 체크1 end   
 
   
 -- 체크2, 재고수량관리하는 품목에 한하여 판매후 보관이면 수탁창고가 없는 창고일때 매출이 발생하지 못하게 막기   
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- 에 해당하는 @1를 찾을수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%없습니다%')  
                            @LanguageSeq       ,   
                            780,'수탁창고'   -- SELECT * FROM _TCADictionary WHERE Word like '%수탁창고%'          
   
 UPDATE C  
       SET C.Result        = (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = C.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem as C       
   JOIN _TDAItem   as D with(nolock) on ( D.CompanySeq = @CompanySeq and C.ItemSeq = D.ItemSeq )  
   JOIN _TDAItemAsset as E with(nolock) on ( E.CompanySeq = @CompanySeq and D.AssetSeq = E.AssetSeq and E.IsQty = '0' )  
   JOIN #TSLInvoice  as F     on ( C.InvoiceSeq = F.InvoiceSeq )  
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (select 1 from _TDAWHSub where CompanySeq = @CompanySeq and UpWHSeq = C.WHSeq and SMWHKind = 8002004 and TrustCustSeq = F.CustSeq and IsUse = '1')  
    AND F.IsStockSales = '1'  
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- 체크2 end   
   
 -- 체크3, 세트품목일때 해당 창고와 같은 사업부문에 있는 사업부문공통창고에 세트기능창고가 있는지 체크   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- 에 해당하는 @1를 찾을수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%없습니다%')  
                            @LanguageSeq       ,   
                            22670,'사업부문공통창고'   -- SELECT * FROM _TCADictionary WHERE Word like '%사업부문공통%'          
   
 UPDATE C  
       SET C.Result        = (select BizUnitName from _TDABizUnit where CompanySeq = @CompanySeq and BizUnit = F.BizUnit)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem AS C       
   JOIN _TDAItemSales AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND C.ItemSeq = E.ItemSeq AND E.IsSet = '1' )  
     JOIN _TDAWH   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND C.WHSeq =  F.WHSeq )   
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TDAWH WHERE CompanySeq = F.CompanySeq AND BizUnit = F.BizUnit AND SMWHKind = 8002013 AND IsNotUse = '0' ) -- 사업부문공통창고   
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            125                , -- 에 해당하는 @1를 찾을수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%없습니다%')  
                            @LanguageSeq       ,   
                            23908,'세트구성품창고'   -- SELECT * FROM _TCADictionary WHERE Word like '%세트%창고%'          
   
 UPDATE C  
       SET C.Result        = '['+(select BizUnitName from _TDABizUnit where CompanySeq = @CompanySeq and BizUnit = F.BizUnit)+'] '  
         + (select WHName from _TDAWH where CompanySeq = @CompanySeq and WHSeq = G.WHSeq)+@Results,  
     C.MessageType   = @MessageType,  
     C.Status        = @Status  
   FROM #TSLInvoiceItem AS C       
   JOIN _TDAItemSales AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND C.ItemSeq = E.ItemSeq AND E.IsSet = '1' )  
   JOIN _TDAWH   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND C.WHSeq = F.WHSeq )   
   JOIN _TDAWH   AS G WITH(NOLOCK) ON ( F.CompanySeq = G.CompanySeq AND F.BizUnit = G.BizUnit AND G.SMWHKind = 8002013 ) -- 사업부문공통창고   
  WHERE C.WorkingTag IN ( 'A', 'U' )  
    AND C.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TDAWHSub WHERE CompanySeq = G.CompanySeq AND UpWHSeq = G.WHSeq AND SMWHKind = 8002011 AND IsUse = '1') -- 세트기능창고   
   
 IF @@ROWCOUNT <> 0 BEGIN SELECT * FROM #TSLInvoiceItem RETURN END  
   
 -- 체크3 end   
 

    EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                          @Status      OUTPUT,        
                          @Results     OUTPUT,        
                          1001                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault LIKE '%없습니다%')        
                          @LanguageSeq       ,         
                          0, '납품정보에 해당 LotNo'   -- SELECT * FROM _TCADictionary WHERE Word like '%전표%'                
    UPDATE #TSLInvoiceItem        
       SET Result        = @Results,        
           MessageType   = @MessageType,        
           Status        = @Status      
      FROM #TSLInvoiceItem    AS A
      LEFT OUTER JOIN #TSLInvoice AS C ON ( C.InvoiceSeq = A.InvoiceSeq )
      LEFT OUTER JOIN (SELECT A.CompanySeq, B.Memo1 AS CustSeq, B.Memo2 AS EndUserSeq, A.EmpSeq, B.ItemSeq, B.LotNo    
                         FROM _TPUDelv AS A LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq
                      ) AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = C.EmpSeq AND B.ItemSeq = A.ItemSeq AND B.CustSeq = C.CustSeq 
                                  AND (B.EndUserSeq = C.BKCustSeq OR B.EndUserSeq IN (SELECT EnvValue FROM DTI_TCOMEnv WHERE EnvSeq IN (2,3)))
                                ) 
     WHERE A.WorkingTag IN ('A','U')
       AND B.LotNo <> A.LotNo
  
    -------------------------------------------    
    -- 세트품의 구성품이 없을경우 저장안돼도록 체크  
    -------------------------------------------  
 EXEC dbo._SCOMMessage @MessageType OUTPUT,  
       @Status      OUTPUT,  
       @Results     OUTPUT,  
                            1009               , -- 에 해당하는 @1를 찾을수 없습니다. (SELECT * FROM _TCAMessageLanguage WHERE Message like '%후%')  
                            @LanguageSeq       ,   
                            4219,'구성품'   -- SELECT * FROM _TCADictionary WHERE Word like '%구성품%'          
   
 UPDATE #TSLInvoiceItem  
       SET Result        = @Results,  
     MessageType   = @MessageType,  
     Status        = @Status   
   FROM #TSLInvoiceItem   AS A  
        JOIN _TDAItemSales AS B ON B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq AND B.IsSet = '1'  
  WHERE A.WorkingTag IN ( 'A', 'U' )  
    AND A.Status = 0   
    AND NOT EXISTS (SELECT 1 FROM _TSLSetItem WHERE CompanySeq = @CompanySeq AND SetItemSeq = A.ItemSeq) -- 세트구성품여부   
  
  
    SELECT @InvoiceSeq = InvoiceSeq    
      FROM #TSLInvoiceItem    
          
    SELECT @BizUnit = BizUnit    
      FROM #TSLInvoice     
   
    -- 품목코드가 없는 데이터는 지워준다.  
    
     -------------------------------------------    
     -- 필수데이터체크    
     -------------------------------------------    
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                               @LanguageSeq       ,     
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%담보%'            
     
         UPDATE #TSLInvoiceItem    
            SET Result        = @Results,    
                MessageType   = @MessageType,    
                Status        = @Status    
          WHERE InvoiceSeq IS NULL    
  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               1                  , -- 필수입력 데이타를 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)    
                                 @LanguageSeq       ,     
                               7,''   -- SELECT * FROM _TCADictionary WHERE Word like '품목%'            
     
         UPDATE #TSLInvoiceItem    
            SET Result        = @Results,    
                MessageType   = @MessageType,    
                Status        = @Status    
          WHERE ItemSeq IS NULL    
             OR ItemSeq = 0  
  
     --------------------------------------------------------------------------------------  
     -- 데이터 유무 체크 : UPDATE, DELETE 시 데이터 존해하지 않으면 에러처리  
     --------------------------------------------------------------------------------------  
     IF NOT EXISTS (SELECT 1   
                      FROM #TSLInvoiceItem AS A   
                            JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.InvoiceSeq = B.InvoiceSeq AND A.InvoiceSerl = B.InvoiceSerl  
                     WHERE A.WorkingTag IN ('U', 'D'))  
     BEGIN  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                               @Status      OUTPUT,  
                               @Results     OUTPUT,  
                               7                  , -- 자료가 등록되어 있지 않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                               @LanguageSeq       ,   
                               '',''   -- SELECT * FROM _TCADictionary WHERE Word like '%%'          
  
         UPDATE #TSLInvoiceItem  
            SET Result        = @Results,  
                MessageType   = @MessageType,  
                Status        = @Status  
          WHERE WorkingTag IN ('U','D')  
    END     
    
     -------------------------------------------    
     -- 중복여부체크     
     -------------------------------------------    
--     EXEC dbo._SCOMMessage @MessageType OUTPUT,        
--                           @Status      OUTPUT,        
--                           @Results     OUTPUT,        
--                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)        
--                           @LanguageSeq       ,         
--                           0,'거래명세서'          
--     UPDATE #TSLInvoiceItem        
--        SET Result        = REPLACE(@Results,'@2',RTRIM(B.InvoiceSeq)),        
--            MessageType   = @MessageType,        
--            Status        = @Status        
--       FROM #TSLInvoiceItem AS A JOIN ( SELECT S.InvoiceSeq, S.InvoiceSerl      
--                                      FROM (        
--                                            SELECT A1.InvoiceSeq, A1.InvoiceSerl      
--                                              FROM #TSLInvoiceItem AS A1        
--                                             WHERE A1.WorkingTag IN ('U')        
--                                               AND A1.Status = 0        
--                                            UNION ALL        
--                                            SELECT A1.InvoiceSeq, A1.InvoiceSerl      
--                                              FROM _TSLInvoiceItem AS A1        
--                                             WHERE A1.InvoiceSeq  NOT IN (SELECT InvoiceSeq        
--                                                                            FROM #TSLInvoiceItem         
--                                                                           WHERE WorkingTag IN ('U','D')         
--                                                                             AND Status = 0)        
--                                               AND A1.InvoiceSerl  NOT IN (SELECT InvoiceSerl        
--                                                                             FROM #TSLInvoiceItem         
--                                                                            WHERE WorkingTag IN ('U','D')         
--                                                                              AND Status = 0)        
--                                               AND A1.CompanySeq = @CompanySeq        
  --                                            ) AS S        
--                                     GROUP BY S.InvoiceSeq, S.InvoiceSerl      
--                                     HAVING COUNT(1) > 1        
--                                   ) AS B ON A.InvoiceSeq  = B.InvoiceSeq        
--                                         AND A.InvoiceSerl = B.InvoiceSerl       
  
    -------------------------------------------      
    -- 사업부문에 따른 창고가 맞는지 체크      
    ---------------------------------------------      
    IF @BizUnit <> 0    
    BEGIN     
        SELECT A.WHSeq    
          INTO #TmpBizWH    
          FROM _TDAWH AS A WITH(NOLOCK)     
         WHERE A.CompanySeq = @CompanySeq    
           AND A.IsNotUse <> '1'     
           AND A.BizUnit = @BizUnit    
  
        -- 사업부문에 따른 변경된 품목창고 체크          
        EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                              @Status      OUTPUT,      
                              @Results     OUTPUT,      
                              11               , -- 해당 @1의  @2 가 아닙니다.(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 11)      
                              @LanguageSeq       ,       
                              2,'',   -- SELECT * FROM _TCADictionary WHERE Word like '%사업부문%'      
                              783,''  -- SELECT * FROM _TCADictionary WHERE Word like '%창고%'      
    
        UPDATE #TSLInvoiceItem                                 
           SET Result        = @Results     ,      
               MessageType   = @MessageType ,      
               Status        = @Status      
          FROM #TSLInvoiceItem AS A      
                LEFT OUTER JOIN #TmpBizWH AS B ON A.WHSeq    = B.WHSeq    
         WHERE A.WorkingTag IN ('A','U')      
           AND B.WHSeq IS NULL    
           AND (A.WHSeq IS NOT NULL AND A.WHSeq <> 0 )    
                                      
    END   
  
  
  
    --기준단위수량 계산 2010.02.05 by 허승남  
    UPDATE #TSLInvoiceItem    
       SET STDQty = ROUND((CASE WHEN ISNULL(B.ConvDen,0) = 0 THEN 0 ELSE ISNULL(A.Qty,0) * ISNULL(B.ConvNum,0) / ISNULL(B.ConvDen,0) END),@GoodQtyDecLength)    
      FROM #TSLInvoiceItem AS A    
           JOIN _TDAItemUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                              AND A.ItemSeq    = B.ItemSeq    
                                              AND A.UnitSeq    = B.UnitSeq    
           JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                               AND A.ItemSeq    = C.ItemSeq    
     WHERE A.Status = 0    
       AND ISNULL(A.Qty,0) <> 0    
       AND ISNULL(C.IsQtyChange,'') <> '1'    
    
    
    
    -- 순번update---------------------------------------------------------------------------------------------------------------    
    SELECT @MaxInvoiceSerl = ISNULL(MAX(InvoiceSerl), 0)    
      FROM _TSLInvoiceItem     
     WHERE CompanySeq = @CompanySeq  
       AND InvoiceSeq = @InvoiceSeq    
    
    UPDATE #TSLInvoiceItem    
       SET InvoiceSerl = @MaxInvoiceSerl + IDX_NO    
      FROM #TSLInvoiceItem    
     WHERE WorkingTag = 'A'     
       AND Status = 0    
               
  
    IF @WorkingTag = 'D'    
        UPDATE #TSLInvoiceItem    
           SET WorkingTag = 'D'    
  
  
    -------------------------------------------    
    -- 내부코드 0값일시 에러 발생  
    -------------------------------------------        
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중 에러가 발생했습니다. 다시 처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE LanguageSeq = 1 and MessageSeq = 1055)      
                          @LanguageSeq         
  
    UPDATE #TSLInvoiceItem                                 
       SET Result        = @Results     ,      
           MessageType   = @MessageType ,      
           Status        = @Status      
      FROM #TSLInvoiceItem  
     WHERE Status = 0  
         AND (InvoiceSerl = 0 OR InvoiceSerl IS NULL)  
  
            
    SELECT * FROM #TSLInvoiceItem    
    
    RETURN      

GO
