
IF OBJECT_ID('KPX_SLGInOutDailyItemSave') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyItemSave
GO 

-- v2014.12.05 

-- 사이트테이블로 변경 by이재천 
CREATE PROC KPX_SLGInOutDailyItemSave  
    @xmlDocument    NVARCHAR(MAX),          
    @xmlFlags       INT = 0,          
    @ServiceSeq     INT = 0,          
    @WorkingTag     NVARCHAR(10)= '',          
    @CompanySeq     INT = 1,          
    @LanguageSeq    INT = 1,          
    @UserSeq        INT = 0,          
    @PgmSeq         INT = 0          
AS          
    DECLARE @docHandle        INT        
    
    
    IF @WorkingTag <> 'AUTO'        -- 2010.04.24 (정동혁) : 데이터입출고 서비스를     
    BEGIN    
        -- 서비스 마스타 등록 생성          
        CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)          
        ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TLGInOutDailyItem'         
    END    
    
    
--      
--     ALTER TABLE #TLGInOutDailyItem ADD InOutType   INT    
    
--     UPDATE #TLGInOutDailyItem    
--        SET InOutType = B.InOutType    
--       FROM #TLGInOutDailyItem A    
--             JOIN KPX_TPUMatOutEtcOut B ON B.CompanySeq = @CompanySeq    
--                                  AND A.InOutSeq = B.InOutSeq    
--                                  AND B.IsBatch <> '1'    
    Create Table #TLGInOutMinusCheck      
    (        
        WHSeq           INT,      
        FunctionWHSeq   INT,      
        ItemSeq         INT    
    )      
    
    Create Table #TLGInOutMonth    
    (      
        InOut           INT,    
        InOutYM         NCHAR(6),    
        WHSeq           INT,    
        FunctionWHSeq   INT,    
        ItemSeq         INT,    
        UnitSeq         INT,    
        Qty             DECIMAL(19, 5),    
        StdQty          DECIMAL(19, 5),          
        ADD_DEL         INT          
    )    
    
    Create Table #TLGInOutMonthLot    
    (      
        InOut           INT,    
        InOutYM         NCHAR(6),    
        WHSeq           INT,    
        FunctionWHSeq   INT,    
        LotNo           NVARCHAR(30),    
        ItemSeq         INT,    
        UnitSeq         INT,    
        Qty             DECIMAL(19, 5),    
        StdQty          DECIMAL(19, 5),          
        ADD_DEL         INT          
    )    
     
 /*    
    Create Table #TLGInOutSerialSub    
    (    
        InOutType   INT,    
        InOutSeq    INT,    
        InOutSerl   INT,        
        DataKind    INT,    
        InOutDataSerl   INT,    
        InOutSerialSerl INT,    
        SerialNo    NVARCHAR(30),    
        ItemSeq     INT,    
        MessageType INT,        
        Result      NVARCHAR(250),    
        Status      INT     
    )     
 */    
     
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
        
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUMatOutEtcOutItem')    
          
    EXEC _SCOMLog  @CompanySeq   ,          
                   @UserSeq      ,          
                   'KPX_TPUMatOutEtcOutItem', -- 원테이블명          
                   '#TLGInOutDailyItem', -- 템프테이블명          
                   'InOutType,InOutSeq,InOutSerl' , -- 키가 여러개일 경우는 , 로 연결한다.           
                   --'CompanySeq,InOutType,InOutSeq,InOutSerl,ItemSeq,InOutRemark,CCtrSeq,DVPlaceSeq,InWHSeq,OutWHSeq,UnitSeq,Qty,STDQty,Amt,EtcOutAmt,EtcOutVAT,InOutKind,    
                   -- InOutDetailKind,LotNo,SerialNo,IsStockSales,OriUnitSeq,OriItemSeq,OriQty,OriSTDQty, OriLotNo, LastUserSeq,LastDateTime'              
                   @TableColumns, '', @PgmSeq     
        
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUMatOutEtcOutItemSub')    
        
      -- _S%Save 와 _S%Delete 두가지 SP에만 한해서 ...     
    EXEC _SCOMDeleteLog @CompanySeq,      
                        @UserSeq,      
                        'KPX_TPUMatOutEtcOutItemSub',     
                        '#TLGInOutDailyItem',     
                        'InOutType, InOutSeq, InOutSerl', -- CompanySeq제외 한 키     
                        @TableColumns, '', @PgmSeq     
        
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutLotSub')    
        
    -- _S%Save 와 _S%Delete 두가지 SP에만 한해서 ...     
      EXEC _SCOMDeleteLog @CompanySeq,      
                        @UserSeq,      
                        '_TLGInOutLotSub',     
                        '#TLGInOutDailyItem',     
                        'InOutType, InOutSeq, InOutSerl', -- CompanySeq제외 한 키     
                        @TableColumns, '', @PgmSeq     
        
    IF @WorkingTag <> 'AUTO'        -- 2010.04.24 (김병관) : 데이터입출고 서비스를     
    BEGIN    
--    ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ---- 입출고일자      
        ALTER TABLE #TLGInOutDailyItem ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부      
        ALTER TABLE #TLGInOutDailyItem ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부      
        ALTER TABLE #TLGInOutDailyItem ADD IsLot        NCHAR(1) ---- Lot관리여부      
        ALTER TABLE #TLGInOutDailyItem ADD IsSerial     NCHAR(1) ---- 시리얼관리여부      
        ALTER TABLE #TLGInOutDailyItem ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크      
        ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ----  체크      
        ALTER TABLE #TLGInOutDailyItem ADD CustSeq    INT ----  체크      
        ALTER TABLE #TLGInOutDailyItem ADD SalesCustSeq    INT ----  체크      
        ALTER TABLE #TLGInOutDailyItem ADD IsTrans    NCHAR(1) ----  체크      
--    ALTER TABLE #TLGInOutDailyItem ADD IsWHStockCheck     NCHAR(1) ---- 창고기준재고 체크      
    END    
    
    CREATE TABLE #TLGInOutStock(      
        InOutType int,      
        InOutSeq int,      
        InOutSerl int,      
        DataKind int default 0,      
        InOutDataSerl int default 0,      
        InOutSubSerl int,      
        InOut int,      
        InOutYM nchar(6),      
        InOutDate nchar(8),      
        WHSeq int,      
        FunctionWHSeq int,      
        ItemSeq int,      
        UnitSeq int,      
        Qty decimal(19,5),      
        StdQty decimal(19,5),      
        Amt decimal(19,5),      
        InOutKind int,      
        InOutDetailKind int      
    )      
    
    CREATE TABLE #TLGInOutLotStock(                  
        InOutType int,                  
        InOutSeq int,                  
        InOutSerl int,                  
        DataKind int default 0,                  
        InOutDataSerl int default 0,                  
        InOutSubSerl int,                  
        InOutLotSerl int,                  
        InOut int,                  
        InOutYM nchar(6),                  
        InOutDate nchar(8),                  
        WHSeq int,                  
        FunctionWHSeq int,      
        LotNo   NVARCHAR(30),                
        ItemSeq int,                  
        UnitSeq int,                  
        Qty decimal(19,5),                  
        StdQty decimal(19,5),                  
        InOutKind int,                  
        InOutDetailKind int ,                  
        Amt decimal(19,5)                 
    )               
     
 /*    
 DECLARE @MessageType INT,    
   @Status   INT,    
   @Results  NVARCHAR(300)    
       
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
   FROM #TLGInOutDailyItem AS A     
     JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )    
  WHERE A.WorkingTag IN ( 'U', 'D' )     
    AND A.Status = 0      
 */    
     
    UPDATE  #TLGInOutDailyItem      
       SET  IsStockQty          = IsNULL(C.IsQty, '0'),      
              IsStockAmt           = IsNULL(C.IsAmt, '0'),      
            IsItemStockCheck    = IsNULL(C.IsMinus, '0')      
      FROM  #TLGInOutDailyItem A      
            LEFT OUTER JOIN _TDAItem B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq      
            LEFT OUTER JOIN _TDAItemAsset C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq      
                                                        AND B.AssetSeq   = C.AssetSeq      
     WHERE  B.CompanySeq = @CompanySeq      
      
    UPDATE  #TLGInOutDailyItem      
       SET  IsLot               = IsNULL(B.IsLotMng, '0'),      
            IsSerial            = IsNULL(B.IsSerialMng, '0')      
      FROM  #TLGInOutDailyItem A      
            LEFT OUTER JOIN _TDAItemStock B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq      
     WHERE  B.CompanySeq = @CompanySeq      
      
    UPDATE  #TLGInOutDailyItem      
       SET  InOutDate               = B.InOutDate,      
            CustSeq                 = B.CustSeq,      
            OutWHSeq                = Case A.OutWHSeq when 0 then B.OutWHSeq else A.OutWHSeq end,      
            InWHSeq                 = Case A.InWHSeq when 0 then B.InWHSeq else A.InWHSeq end  ,      
            IsTrans                 = B.IsTrans      
      FROM  #TLGInOutDailyItem A      
            JOIN KPX_TPUMatOutEtcOut B WITH(NOLOCK) ON A.InOutType = B.InOutType  AND  A.InOutSeq = B.InOutSeq      
     WHERE  B.CompanySeq = @CompanySeq      
      
   -- DELETE            
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'D' AND Status = 0  )          
    BEGIN          
  /*    
        -- SERIAL 관련    
        INSERT INTO #TLGInOutSerialSub    
        SELECT B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl, B.InOutSerialSerl, B.SerialNo, B.ItemSeq, 0, '', 0    
          FROM #TLGInOutDailyItem AS A    
                JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  -- WITH(NOLOCK) 추가 2011. 9. 1 hkim    
                                                         AND A.InOutType  = B.InOutType    
                                                         AND A.InOutSeq   = B.InOutSeq    
                                                         AND A.InOutSerl  = B.InOutSerl    
         WHERE A.WorkingTag = 'D' AND A.Status = 0       
    
        IF EXISTS (SELECT 1 FROM #TLGInOutSerialSub)    
        BEGIN    
            -- SERIAL 재고삭제            
            EXEC  _SLGCreateDataForInOutSerialStockBatch @CompanySeq, 'D'      
    
            UPDATE #TLGInOutDailyItem        
               SET Result        = B.Result     ,            
                   MessageType   = B.MessageType,            
                   Status        = B.Status            
              FROM #TLGInOutDailyItem AS A         
                   JOIN #TLGInOutSerialSub AS B ON A.InOutType = B.InOutType        
                                               AND A.InOutSeq  = B.InOutSeq    
                                               AND A.InOutSerl  = B.InOutSerl    
             WHERE B.Status <> 0         
    
    
            -- SerialSub DELETE    
            DELETE _TLGInOutSerialSub      
              FROM #TLGInOutDailyItem AS A      
                   JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq -- WITH(NOLOCK) 추가 2011. 9. 1 hkim    
                                                            AND A.InOutType  = B.InOutType    
                                                            AND A.InOutSeq   = B.InOutSeq    
                                                            AND A.InOutSerl  = B.InOutSerl    
             WHERE A.WorkingTag = 'D' AND A.Status = 0       
    
            IF @@ERROR <> 0        
            BEGIN        
                RETURN        
            END      
        END          
  */    
      
        INSERT #TLGInOutMonth      
          (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,      
                         ItemSeq         ,        UnitSeq         ,        Qty              ,        StdQty          ,      
                       ADD_DEL)      
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,      
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,      
                       -1      
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                     AND B.InOutType  = A.InOutType          
                                                     AND B.InOutSeq   = A.InOutSeq          
                                                     AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
    
         INSERT #TLGInOutMonthLot      
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,      
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,        
                       ADD_DEL)        
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,      
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,        
                       -1        
          FROM #TLGInOutDailyItem AS A            
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq            
                                                        AND B.InOutType  = A.InOutType            
                                                        AND B.InOutSeq   = A.InOutSeq            
                                                        AND B.InOutSerl  = A.InOutSerl          
         WHERE A.WorkingTag = 'D' AND A.Status = 0             
      
      
        -- LOT 재고 DELETE          
        DELETE _TLGInOutLotStock            
          FROM #TLGInOutDailyItem AS A            
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq            
                                                        AND B.InOutType   = A.InOutType        
                                                        AND B.InOutSeq    = A.InOutSeq            
                                                        AND B.InOutSerl   = A.InOutSerl          
         WHERE A.WorkingTag = 'D' AND A.Status = 0             
          
        IF @@ERROR <> 0              
        BEGIN              
            RETURN              
        END            
      
        -- LOT 입출고 DELETE          
        DELETE _TLGInOutLotSub            
          FROM #TLGInOutDailyItem AS A            
               JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq          
                                                            AND C.InOutType  = A.InOutType          
                                                            AND C.InOutSeq   = A.InOutSeq            
                                                            AND C.InOutSerl  = A.InOutSerl     
         WHERE  A.WorkingTag = 'D' AND A.Status = 0             
          
        IF @@ERROR <> 0              
        BEGIN              
            RETURN              
        END          
    
    
        DELETE _TLGInOutStock         
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                    AND B.InOutType   = A.InOutType          
                                                    AND B.InOutSeq   = A.InOutSeq          
                                                    AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
        
        IF @@ERROR <> 0            
          BEGIN             
              RETURN             
        END          
      
      
        DELETE KPX_TPUMatOutEtcOutItem          
          FROM #TLGInOutDailyItem AS A          
               JOIN KPX_TPUMatOutEtcOutItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                    AND B.InOutType  = A.InOutType          
                                                    AND B.InOutSeq   = A.InOutSeq          
                                                    AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
        
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
        DELETE KPX_TPUMatOutEtcOutItemSub          
          FROM #TLGInOutDailyItem AS A          
               JOIN KPX_TPUMatOutEtcOutItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                    AND B.InOutType   = A.InOutType          
                                                    AND B.InOutSeq   = A.InOutSeq          
                                                    AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'D' AND A.Status = 0           
        
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
    
    END          
        
    -- Update            
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'U' AND Status = 0  )          
    BEGIN           
      
        EXEC  _SLGCreateDataForInOutStock @CompanySeq, 'U'      
        /*    
            _TLGInOutLotSub에서 분할 되지 않은 데이터는 삭제한다.    
            아래 _SLGCreateDataForInOutLotStock에서 다시 인써트 함    
        */     
        DELETE  _TLGInOutLotSub     
        FROM    _TLGInOutLotSub X     
                JOIN (    
                SELECT  B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl    
                  FROM  #TLGInOutDailyItem A    
                        JOIN  _TLGInOutLotSub B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      -- WITH(NOLOCK) 추가 2011. 9. 1 hkim         
                                                            AND B.InOutType   = A.InOutType            
                                                            AND B.InOutSeq   = A.InOutSeq            
                                                            AND B.InOutSerl  = A.InOutSerl     
                GROUP BY B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl    
                HAVING COUNT(1) = 1) Y ON X.CompanySeq = Y.CompanySeq    
                                      AND X.InOutType = Y.InOutType    
                                      AND X.InOutSeq = Y.InOutSeq    
                                      AND X.InOutSerl = Y.InOutSerl    
                                          
        UPDATE KPX_TPUMatOutEtcOutItem          
           SET  ItemSeq = A.ItemSeq,      
                InOutRemark = A.InOutRemark,      
                CCtrSeq = A.CCtrSeq,      
                DVPlaceSeq = A.DVPlaceSeq,      
                InWHSeq = A.InWHSeq,      
                OutWHSeq = A.OutWHSeq,      
                UnitSeq = A.UnitSeq,      
                Qty = A.Qty,      
                STDQty = A.STDQty,      
                Amt = A.Amt,      
                EtcOutAmt = A.EtcOutAmt,      
                EtcOutVAT = A.EtcOutVAT,      
                InOutKind = A.InOutKind,      
                InOutDetailKind = A.InOutDetailKind,      
                LotNo = A.LotNo,      
                SerialNo = A.SerialNo,      
                IsStockSales = A.IsStockSales,      
                OriUnitSeq = A.OriUnitSeq,    
                OriItemSeq = A.OriItemSeq,      
                OriQty = A.OriQty,      
                OriSTDQty = A.OriSTDQty,      
                OriLotNo = A.OriLotNo,      
                LastUserSeq  = @UserSeq,        
                LastDateTime = GETDATE(),    
                PJTSeq = A.PJTSeq,    
                PgmSeq = @PgmSeq    
            FROM #TLGInOutDailyItem AS A           
               JOIN KPX_TPUMatOutEtcOutItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                    AND B.InOutType   = A.InOutType          
                                                    AND B.InOutSeq   = A.InOutSeq          
                                                    AND B.InOutSerl  = A.InOutSerl        
          WHERE A.WorkingTag = 'U' AND A.Status = 0        
           
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
    
    
        INSERT #TLGInOutMonth      
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,      
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,      
                       ADD_DEL)      
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,      
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,      
                       -1      
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                     AND B.InOutType  = A.InOutType          
                                                     AND B.InOutSeq   = A.InOutSeq          
                                                     AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'U' AND A.Status = 0           
    
        
        DELETE _TLGInOutStock         
          FROM #TLGInOutDailyItem AS A          
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq          
                                                    AND B.InOutType   = A.InOutType          
                                                    AND B.InOutSeq   = A.InOutSeq          
                                                    AND B.InOutSerl  = A.InOutSerl      
         WHERE A.WorkingTag = 'U' AND A.Status = 0           
        
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
        INSERT  _TLGInOutStock      
        SELECT  @CompanySeq, *      
          FROM  #TLGInOutStock      
    
    
        INSERT  #TLGInOutMonth                  
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,                  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                  
                       ADD_DEL)                  
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,                  
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                  
                       1                  
          FROM  #TLGInOutStock   B                  
    
        EXEC    _SLGCreateDataForInOutLotStock @CompanySeq, 'U', @LanguageSeq, @PgmSeq        
    
        INSERT #TLGInOutMonthLot        
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,   LotNo,     
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,        
                       ADD_DEL)        
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,   B.LotNo,    
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,        
                       -1        
          FROM  #TLGInOutDailyItem AS A            
                JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq            
     AND B.InOutType  = A.InOutType            
                                                     AND B.InOutSeq   = A.InOutSeq            
                                                     AND B.InOutSerl  = A.InOutSerl          
      WHERE  A.WorkingTag = 'U' AND A.Status = 0             
      
          
        DELETE _TLGInOutLotStock           
          FROM #TLGInOutDailyItem AS A            
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq            
                                                    AND B.InOutType   = A.InOutType            
                                                    AND B.InOutSeq   = A.InOutSeq            
                                                    AND B.InOutSerl  = A.InOutSerl        
         WHERE A.WorkingTag = 'U' AND A.Status = 0             
          
        IF @@ERROR <> 0              
        BEGIN              
            RETURN              
        END            
        INSERT  _TLGInOutLotStock        
        SELECT  @CompanySeq, *        
          FROM  #TLGInOutLotStock        
      
      
        INSERT  #TLGInOutMonthLot                    
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,                  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                    
                       ADD_DEL)                    
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,                 
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                    
                       1                    
          FROM  #TLGInOutLotStock   B                          
    END          
             
    -- INSERT            
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE WorkingTag = 'A' AND Status = 0 )          
    BEGIN          
        TRUNCATE TABLE #TLGInOutStock        
        TRUNCATE TABLE #TLGInOutLotStock        
    
        EXEC  _SLGCreateDataForInOutStock @CompanySeq, 'A'        
        INSERT INTO KPX_TPUMatOutEtcOutItem(          
                CompanySeq,      
                InOutType,      
                InOutSeq,      
                InOutSerl,      
                ItemSeq,      
                InOutRemark,      
                CCtrSeq,      
                DVPlaceSeq,      
                InWHSeq,      
                OutWHSeq,      
                UnitSeq,      
                Qty,      
                STDQty,      
                Amt,      
                EtcOutAmt,      
                EtcOutVAT,      
                InOutKind,      
                InOutDetailKind,      
                LotNo,      
                SerialNo,      
                IsStockSales,      
                OriUnitSeq,      
                OriItemSeq,      
                OriQty,      
                OriSTDQty,  OriLotNo,    
                LastUserSeq,      
                LastDateTime,    
                PJTSeq,    
                PgmSeq)        
        SELECT  @CompanySeq,        
                InOutType,      
                InOutSeq,      
                InOutSerl,      
                ItemSeq,      
                InOutRemark,      
                CCtrSeq,      
                DVPlaceSeq,      
                InWHSeq,      
                OutWHSeq,      
                UnitSeq,      
                Qty,      
                STDQty,      
                Amt,      
                EtcOutAmt,      
                EtcOutVAT,      
                InOutKind,      
                InOutDetailKind,      
                LotNo,      
                SerialNo,      
                IsStockSales,      
                OriUnitSeq,      
                OriItemSeq,      
                OriQty,      
                OriSTDQty,  OriLotNo,    
                @UserSeq,        
          GETDATE(),    
                PJTSeq,    
                @PgmSeq        
          FROM #TLGInOutDailyItem A          
         WHERE WorkingTag = 'A' AND Status = 0        
          
        IF @@ERROR <> 0            
        BEGIN            
            RETURN            
        END          
      
        INSERT  _TLGInOutStock      
        SELECT  @CompanySeq, *      
          FROM  #TLGInOutStock      
    
    
          INSERT  #TLGInOutMonth                  
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,                  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                  
                       ADD_DEL)                  
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,                  
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                  
                       1                  
          FROM  #TLGInOutStock   B                  
            
        -- 여기서 _TLGInOutLotSub에 값을 넣어준다     
        EXEC  _SLGCreateDataForInOutLotStock @CompanySeq, 'A', @LanguageSeq, @PgmSeq     
    
        INSERT  _TLGInOutLotStock        
        SELECT  @CompanySeq, *        
          FROM  #TLGInOutLotStock        
      
      
        INSERT  #TLGInOutMonthLot                    
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LOTNO,                  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,                    
                       ADD_DEL)                    
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,                
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,                    
                       1                    
          FROM  #TLGInOutLotStock   B                         
    END              
    
    EXEC _SLGWHStockUPDATE @CompanySeq      
    
    EXEC _SLGLOTStockUPDATE @CompanySeq      
    
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq    
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyItem', @LanguageSeq    
    
    IF @WorkingTag <> 'AUTO'        -- 2010.04.24 (김병관) : 데이터입출고 서비스를     
    BEGIN    
        SELECT * FROM #TLGInOutDailyItem    
    END    
    
RETURN  