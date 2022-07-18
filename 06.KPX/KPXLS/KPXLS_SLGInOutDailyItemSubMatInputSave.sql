
IF OBJECT_ID('KPXLS_SLGInOutDailyItemSubMatInputSave') IS NOT NULL 
    DROP PROC KPXLS_SLGInOutDailyItemSubMatInputSave
GO 

-- v2015.12.03 

-- KPXLS 포장재는 기타출고 처리, 일반 자재는 자재 투입으로 처리 by이재천 
/*************************************************************************************************    
 설  명 - 입출고품목 저장    
 작성일 - 2008.10 : CREATED BY 정수환       
CompanySeq
InOutSeq
InOutSerl
ItemSeq
InOutRemark
CCtrSeq
DVPlaceSeq
InWHSeq
OutWHSeq
UnitSeq
Qty
StdQty
Amt
EtcOutAmt
EtcOutVAT
InOutKind
InOutDetailKind
LotNo
SerialNo

수정일 - 2014.04.10 김용현 InOutType = 130 (생산실적 자재투입 일 경우에 수정)
*************************************************************************************************/    
CREATE PROC KPXLS_SLGInOutDailyItemSubMatInputSave
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
  
    -- 서비스 마스타 등록 생성    
    CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TLGInOutDailyItemSub'    
    
    --select * from #TLGInOutDailyItemSub 
    --return 
    
--    ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ---- 입출고일자
    ALTER TABLE #TLGInOutDailyItemSub ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsLot        NCHAR(1) ---- Lot관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsSerial     NCHAR(1) ---- 시리얼관리여부
    ALTER TABLE #TLGInOutDailyItemSub ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크
    ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD CustSeq    INT ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD LastUserSeq    INT ----  체크
    ALTER TABLE #TLGInOutDailyItemSub ADD LastDateTime   DATETIME ----  체크
    
    --select * from #TLGInOutDailyItemSub 
    --return 
    SELECT *
      INTO #TEMP_TLGInOutDailyItemSub
      FROM #TLGInOutDailyItemSub 
    
    SELECT A.*, InOutSerl AS ItemSerlSub, A.InOutSeq AS InOutSeqOld
      INTO #TLGItemOut 
      FROM #TLGInOutDailyItemSub    AS A 
      JOIN _TDAItem                 AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      JOIN _TDAItemAsset            AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
     WHERE C.SMAssetGrp = 6008009 
    
    DELETE A 
      FROM #TLGInOutDailyItemSub    AS A 
      JOIN _TDAItem                 AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      JOIN _TDAItemAsset            AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
     WHERE C.SMAssetGrp = 6008009 
    
    UPDATE A 
       SET DataSeq = B.DataSeq, 
           InOutType = 31, 
           InOutSerl = 1, 
           InOutDataSerl = 1
      FROM #TLGItemOut AS A 
      JOIN (
            SELECT IDX_NO, Row_Number() OVER(ORDER BY IDX_NO) AS DataSeq 
              FROM #TLGItemOut 
           )  AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    --select * from _TDASMinor where majorseq = 8042 and companyseq = 1 
    
    --select MAX(InOutSeq) From _TLGInOutDaily where inouttype = 30 
    
    --select * From #TLGInOutDailyItemSub
    --SELECT * FROM #TLGItemOut 
    
    --return 
    
    
    -- 적송입고에 한하여 원천이 없는 건은 임시 테이블에서 제외 
    DELETE A 
      FROM #TLGInOutDailyItemSub         AS A 
      LEFT OUTER JOIN _TLGInOutDailyItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl )
     WHERE A.InOutType IN(81,83)
       AND A.WorkingTag = 'A'
       AND B.CompanySeq IS NULL
    
    UPDATE A 
       SET A.InOutRemark     = B.InOutRemark,
           A.ItemSeq         = B.ItemSeq,
           A.UnitSeq         = B.UnitSeq,
           A.InWHSeq         = B.InWHSeq,
           A.OutWHSeq        = B.OutWHSeq,
           A.Qty             = B.Qty,
           A.InOutDetailKind = B.InOutDetailKind,
           A.LotNo = B.LotNo
      FROM #TLGInOutDailyItemSub    AS A 
      JOIN _TLGInOutDailyItem       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND A.InOutSerl = B.InOutSerl )
     WHERE A.InOutType IN(81,83)
       AND A.WorkingTag = 'A'

    -- 연산품인 경우 InOutSerl 값 제거
    UPDATE A 
       SET A.InOutSerl = 0
      FROM #TLGInOutDailyItemSub    AS A 
      JOIN _TPDSFCWorkReport        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.InOutSeq = B.WorkReportSeq )
     WHERE A.InOutType BETWEEN 130 AND 139
       AND ISNULL(B.ChainGoodsSeq,0) = 0

    
    CREATE TABLE #TLGInOutMinusCheck  
    (    
        WHSeq           INT,  
        FunctionWHSeq   INT,  
        ItemSeq         INT
    )  

    CREATE TABLE #TLGInOutMonth
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

--     ALTER TABLE #TLGInOutDailyItemSub ADD InOutType   INT

--     UPDATE #TLGInOutDailyItemSub
--        SET InOutType = B.InOutType
--       FROM #TLGInOutDailyItemSub A
--   JOIN _TLGInOutDaily B ON B.CompanySeq = @CompanySeq
--                                  AND A.InOutSeq = B.InOutSeq
--                                  AND B.IsBatch <> '1'

    -- 로그 남기기
    DECLARE @TableColumns NVARCHAR(4000)
    
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDailyItemSub')
    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   '_TLGInOutDailyItemSub', -- 원테이블명    
                   '#TLGInOutDailyItemSub', -- 템프테이블명    
                   'InOutType,InOutSeq,InOutSerl, DataKind, InOutDataSerl' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   --'CompanySeq,InOutType,InOutSeq,InOutSerl, DataKind, InOutDataSerl, ItemSeq,InOutRemark,CCtrSeq,DVPlaceSeq,InWHSeq,OutWHSeq,UnitSeq,Qty,STDQty,Amt,EtcOutAmt,EtcOutVAT,InOutKind,InOutDetailKind,LotNo,SerialNo,LastUserSeq,LastDateTime'        
                   @TableColumns,'',@PgmSeq
    
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutLotSub')
    
    -- _S%Save 와 _S%Delete 두가지 SP에만 한해서 ... 
    EXEC _SCOMDeleteLog @CompanySeq,  
                        @UserSeq,  
                        '_TLGInOutLotSub', 
                        '#TLGInOutDailyItemSub', 
                        'InOutType, InOutSeq, InOutSerl, DataKind, InOutDataSerl', -- CompanySeq제외 한 키 
                        @TableColumns, '', @PgmSeq 
    


    UPDATE #TLGInOutDailyItemSub
       SET LastUserSeq  = @UserSeq,  
           LastDateTime = GETDATE()  

--    ALTER TABLE #TLGInOutDailyItemSub ADD IsWHStockCheck     NCHAR(1) ---- 창고기준재고 체크
    CREATE TABLE #TLGInOutStock(
        InOutType int,  
        InOutSeq	int,
        InOutSerl	int,
        DataKind	int,
        InOutDataSerl	int,
        InOutSubSerl	int,
        InOut	int,
        InOutYM	nchar(6),
        InOutDate	nchar(8),
        WHSeq	int,
        FunctionWHSeq	int,
        ItemSeq	int,
        UnitSeq	int,
        Qty	decimal(19,5),
        StdQty	decimal(19,5),
        Amt	decimal(19,5),
        InOutKind	int,
        InOutDetailKind	int
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
	DECLARE @MessageType	INT,
			@Status			INT,
			@Results		NVARCHAR(300)
			
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
	   SET A.Result			= REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ), 
		   A.MessageType	= @MessageType,        
		   A.Status			= @Status     
	  FROM #TLGInOutDailyItemSub AS A 
	  JOIN _TLGInOutSerialSub	 AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )
	 WHERE A.WorkingTag IN ( 'U', 'D' ) 
	   AND A.Status = 0  
    */
    
    UPDATE  #TLGInOutDailyItemSub
       SET  IsStockQty          = IsNULL(C.IsQty, '0'),
            IsStockAmt          = IsNULL(C.IsAmt, '0'),
            IsItemStockCheck    = IsNULL(C.IsMinus, '0')
      FROM  #TLGInOutDailyItemSub A
            LEFT OUTER JOIN _TDAItem B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq
            LEFT OUTER JOIN _TDAItemAsset C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq
                                                        AND B.AssetSeq   = C.AssetSeq
     WHERE  B.CompanySeq = @CompanySeq

    UPDATE  #TLGInOutDailyItemSub
       SET  IsLot               = IsNULL(B.IsLotMng, '0'),
            IsSerial            = IsNULL(B.IsSerialMng, '0')
      FROM  #TLGInOutDailyItemSub A
            LEFT OUTER JOIN _TDAItemStock B WITH(NOLOCK) ON A.ItemSeq = B.ItemSeq
     WHERE  B.CompanySeq = @CompanySeq

    UPDATE  #TLGInOutDailyItemSub
       SET  InOutDate               = CASE ISNULL(B.CompleteDate, '') WHEN '' THEN B.InOutDate ELSE B.CompleteDate END,
            CustSeq                 = B.CustSeq,
            OutWHSeq                = Case A.OutWHSeq when 0 then B.OutWHSeq else A.OutWHSeq end,
            InWHSeq                 = Case A.InWHSeq when 0 then B.InWHSeq else A.InWHSeq end
      FROM  #TLGInOutDailyItemSub A
            JOIN _TLGInOutDaily B WITH(NOLOCK) ON A.InOutSeq = B.InOutSeq
                                              AND A.InOutType = B.InOutType
     WHERE  B.CompanySeq = @CompanySeq
	
	-- DELETE      
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'D' AND Status = 0  )    
    BEGIN    
		/*
        -- SERIAL 관련
        INSERT INTO #TLGInOutSerialSub
        SELECT B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl, B.InOutSerialSerl, B.SerialNo, B.ItemSeq, 0, '', 0
          FROM #TLGInOutDailyItemSub AS A
                JOIN _TLGInOutSerialSub AS B ON B.CompanySeq = @CompanySeq
                                            AND A.InOutType  = B.InOutType
                                            AND A.InOutSeq   = B.InOutSeq
                                            AND A.InOutSerl  = B.InOutSerl
                                            AND A.DataKind   = B.DataKind  
                                            AND A.InOutDataSerl = B.InOutDataSerl  
         WHERE A.WorkingTag = 'D' AND A.Status = 0   

        IF EXISTS (SELECT 1 FROM #TLGInOutSerialSub)
        BEGIN
            -- SERIAL 재고삭제        
            EXEC  _SLGCreateDataForInOutSerialStockBatch @CompanySeq, 'D'  

            UPDATE #TLGInOutDailyItemSub    
               SET Result        = B.Result     ,        
                   MessageType   = B.MessageType,        
                   Status        = B.Status        
              FROM #TLGInOutDailyItemSub AS A     
                   JOIN #TLGInOutSerialSub AS B ON A.InOutType = B.InOutType    
                                               AND A.InOutSeq  = B.InOutSeq
                                               AND A.InOutSerl  = B.InOutSerl
                                               AND A.DataKind   = B.DataKind  
                                               AND A.InOutDataSerl  = B.InOutDataSerl  
             WHERE B.Status <> 0     


            -- SerialSub DELETE
            DELETE _TLGInOutSerialSub  
              FROM #TLGInOutDailyItemSub AS A  
                   JOIN _TLGInOutSerialSub AS B ON B.CompanySeq = @CompanySeq
                                               AND A.InOutType  = B.InOutType
                                               AND A.InOutSeq   = B.InOutSeq
                                               AND A.InOutSerl  = B.InOutSerl
                                               AND A.DataKind   = B.DataKind  
                                               AND A.InOutDataSerl  = B.InOutDataSerl  
             WHERE A.WorkingTag = 'D' AND A.Status = 0   

            IF @@ERROR <> 0    
            BEGIN    
                RETURN    
            END  
        END      
		*/
		
		
        INSERT #TLGInOutMonth  
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,  
                       ADD_DEL)  
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,  
                       -1  
          FROM #TLGInOutDailyItemSub AS A      
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                     AND B.InOutType  = A.InOutType      
                                                     AND B.InOutSeq   = A.InOutSeq      
                                                     AND B.InOutSerl  = A.InOutSerl    
                                                     AND B.DataKind   = A.DataKind  
                                                     AND B.InOutSubSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'D' AND A.Status = 0       

         INSERT #TLGInOutMonthLot  
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,  LotNo,  
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                       ADD_DEL)    
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,  B.LotNo,  
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                       -1    
          FROM #TLGInOutDailyItemSub AS A        
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                        AND B.InOutType  = A.InOutType        
                                                        AND B.InOutSeq   = A.InOutSeq        
                                                        AND B.InOutSerl  = A.InOutSerl      
                                                        AND B.DataKind   = A.DataKind    
                                                        AND B.InOutSubSerl  = A.InOutDataSerl    
         WHERE A.WorkingTag = 'D' AND A.Status = 0         

        -- LOT 재고 DELETE      
        DELETE _TLGInOutLotStock        
          FROM #TLGInOutDailyItemSub AS A        
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq        
                                                        AND B.InOutType   = A.InOutType    
                                                        AND B.InOutSeq    = A.InOutSeq        
                                                        AND B.InOutSerl   = A.InOutSerl      
                                                        AND B.DataKind   = A.DataKind    
                          AND B.InOutSubSerl  = A.InOutDataSerl    
         WHERE A.WorkingTag = 'D' AND A.Status = 0         
      
        IF @@ERROR <> 0          
        BEGIN          
            RETURN          
        END        
  
        -- LOT 입출고 DELETE      
        DELETE _TLGInOutLotSub        
          FROM #TLGInOutDailyItemSub AS A        
               JOIN _TLGInOutDailyItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                            AND B.InOutType   = A.InOutType      
                                                            AND B.InOutSeq   = A.InOutSeq      
                                                            AND B.InOutSerl   = A.InOutSerl      
                                                            AND B.DataKind   = A.DataKind    
                                                            AND B.InOutDataSerl  = A.InOutDataSerl    
               JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq      
                                                            AND C.InOutType  = B.InOutType      
                                                            AND C.InOutSeq   = B.InOutSeq        
                                                            AND C.InOutSerl  = B.InOutSerl 
                                                            AND C.DataKind   = B.DataKind    
                                                            AND C.InOutDataSerl  = B.InOutDataSerl    
         WHERE  B.LotNo > ''     
           AND  A.WorkingTag = 'D' AND A.Status = 0         
      
        IF @@ERROR <> 0          
        BEGIN          
            RETURN          
        END        
        
            
        DELETE _TLGInOutStock   
          FROM #TLGInOutDailyItemSub AS A    
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND A.InOutType = B.InOutType
                                                    AND B.InOutSeq   = A.InOutSeq    
                                                    AND B.InOutSerl  = A.InOutSerl  
                                                    AND B.DataKind   = A.DataKind  
                                                    AND B.InOutSubSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'D' AND A.Status = 0     
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
        
        
        DELETE _TLGInOutDailyItemSub    
          FROM #TLGInOutDailyItemSub AS A    
               JOIN _TLGInOutDailyItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND A.InOutType = B.InOutType
                                                    AND B.InOutSeq   = A.InOutSeq    
                                                    AND B.InOutSerl  = A.InOutSerl  
                                                    AND B.DataKind   = A.DataKind  
                                                    AND B.InOutDataSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'D' AND A.Status = 0     
  
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
    END    
  
    -- Update      
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'U' AND Status = 0  )    
    BEGIN     
        
        EXEC  _SLGCreateDataForInOutSubStock @CompanySeq, 'U'
  
        /*
            _TLGInOutLotSub에서 분할 되지 않은 데이터는 삭제한다.
            아래 _SLGCreateDataForInOutLotStock에서 다시 인써트 함
        */ 
        DELETE  _TLGInOutLotSub 
        FROM    _TLGInOutLotSub X 
                JOIN (
                SELECT  B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                  FROM  #TLGInOutDailyItemSub A
                        JOIN  _TLGInOutLotSub B ON B.CompanySeq = @CompanySeq        
                                               AND B.InOutType   = A.InOutType        
                                               AND B.InOutSeq   = A.InOutSeq        
                                               AND B.InOutSerl  = A.InOutSerl 
                                               AND B.DataKind   = A.DataKind    
                                               AND B.InOutDataSerl  = A.InOutDataSerl    
--                 WHERE  B.InOutDataSerl = 0
                GROUP BY B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                HAVING COUNT(1) = 1) Y ON X.CompanySeq = Y.CompanySeq
                                      AND X.InOutType = Y.InOutType
                                      AND X.InOutSeq = Y.InOutSeq
                                      AND X.InOutSerl = Y.InOutSerl
                                      AND X.DataKind = Y.DataKind
                                      AND X.InOutDataSerl = Y.InOutDataSerl
        
        ---- 생산실적 자재투입일 경우 (InOutType = 130) Serl 값이 아닌 InOutSubSerl로 관리 하기 때문에 InOutSerl 값 제거 2014.04.10 김용현 추가
        DELETE  _TLGInOutLotSub 
        FROM    _TLGInOutLotSub X 
                JOIN (
                SELECT  B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                  FROM  #TLGInOutDailyItemSub A
                        JOIN  _TLGInOutLotSub B ON B.CompanySeq = @CompanySeq        
                                               AND B.InOutType   = A.InOutType        
                                               AND B.InOutSeq   = A.InOutSeq        
                                               --AND B.InOutSerl  = A.InOutSerl 
                                               AND B.DataKind   = A.DataKind    
                                               AND B.InOutDataSerl  = A.InOutDataSerl    
--                 WHERE  B.InOutDataSerl = 0
                GROUP BY B.CompanySeq, B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl
                HAVING COUNT(1) = 1) Y ON X.CompanySeq = Y.CompanySeq
                                      AND X.InOutType = Y.InOutType
                                      AND X.InOutSeq = Y.InOutSeq
                                      --AND X.InOutSerl = Y.InOutSerl
                                      AND X.DataKind = Y.DataKind
                                      AND X.InOutDataSerl = Y.InOutDataSerl
        WHERE X.InOutType = 130
        
        
        UPDATE _TLGInOutDailyItemSub    
           SET  ItemSeq = ISNULL(A.ItemSeq,0),
                InOutRemark = ISNULL(A.Remark,''),
                CCtrSeq = ISNULL(A.CCtrSeq,0),
                DVPlaceSeq = ISNULL(A.DVPlaceSeq,0),
                InWHSeq = ISNULL(A.InWHSeq,0),
                OutWHSeq = ISNULL(A.OutWHSeq,0),
                UnitSeq = ISNULL(A.UnitSeq,0),
                Qty = ISNULL(A.Qty,0),
                STDQty = ISNULL(A.STDQty,0),
                Amt = ISNULL(A.Amt,0),
                EtcOutAmt = ISNULL(A.EtcOutAmt,0),
                EtcOutVAT = ISNULL(A.EtcOutVAT,0),
                InOutKind = ISNULL(A.InOutKind,0),
                InOutDetailKind = ISNULL(A.InOutDetailKind,0),
                LotNo = ISNULL(A.LotNo,''),
                SerialNo = ISNULL(A.SerialNo,''),
                LastUserSeq  = @UserSeq,  
                LastDateTime = GETDATE(),
                PgmSeq = @PgmSeq
          FROM #TLGInOutDailyItemSub AS A    
               JOIN _TLGInOutDailyItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND A.InOutType = B.InOutType
                                                    AND B.InOutSeq   = A.InOutSeq    
                                                    AND B.InOutSerl  = A.InOutSerl  
                                                    AND B.DataKind   = A.DataKind  
                                                AND B.InOutDataSerl  = A.InOutDataSerl  
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
          FROM #TLGInOutDailyItemSub AS A      
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq      
                                                     AND B.InOutType  = A.InOutType      
                                                     AND B.InOutSeq   = A.InOutSeq      
                                                     AND B.InOutSerl  = A.InOutSerl    
                                                     AND B.DataKind   = A.DataKind  
                                                     AND B.InOutSubSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'U' AND A.Status = 0       
  
  
        ---- 생산실적 자재투입일 경우 (InOutType = 130) Serl 값이 아닌 InOutSubSerl로 관리 하기 때문에 InOutSerl 값 제거 2014.04.10 김용현 추가
        DELETE _TLGInOutStock   
          FROM #TLGInOutDailyItemSub AS A    
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND B.InOutType  = A.InOutType      
                                                    AND B.InOutSeq   = A.InOutSeq    
                                                    --AND B.InOutSerl  = A.InOutSerl  
                                                    AND B.DataKind   = A.DataKind  
                                                    AND B.InOutSubSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'U' AND A.Status = 0   
           AND B.InOutType = 130
        
        
        
        DELETE _TLGInOutStock   
          FROM #TLGInOutDailyItemSub AS A    
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                    AND B.InOutType  = A.InOutType      
                                                    AND B.InOutSeq   = A.InOutSeq    
                                                    AND B.InOutSerl  = A.InOutSerl  
                                                    AND B.DataKind   = A.DataKind  
                                                    AND B.InOutSubSerl  = A.InOutDataSerl  
         WHERE A.WorkingTag = 'U' AND A.Status = 0     

        
        IF @@ERROR <> 0      
        BEGIN      
            RETURN      
        END    
--SELECT * FROM #TLGInOutStock
--SELECT * FROM _TLGInOutStock
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

        EXEC    _SLGCreateDataForInOutLotSubStock @CompanySeq, 'U'    

        INSERT #TLGInOutMonthLot    
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,   LotNo, 
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,    
                       ADD_DEL)    
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,   B.LotNo,
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,    
                       -1    
          FROM  #TLGInOutDailyItemSub AS A        
                JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                     AND B.InOutType  = A.InOutType        
                                                     AND B.InOutSeq   = A.InOutSeq        
                                                     AND B.InOutSerl  = A.InOutSerl      
                                                     AND B.DataKind   = A.DataKind    
                                                     AND B.InOutSubSerl  = A.InOutDataSerl    
         WHERE  A.WorkingTag = 'U' AND A.Status = 0         
        
        
        
        ---- 생산실적 자재투입일 경우 (InOutType = 130) Serl 값이 아닌 InOutSubSerl로 관리 하기 때문에 InOutSerl 값 제거 2014.04.10 김용현 추가
        DELETE _TLGInOutLotStock       
          FROM #TLGInOutDailyItemSub AS A        
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                    AND B.InOutType   = A.InOutType        
                                                    AND B.InOutSeq   = A.InOutSeq        
                                                    --AND B.InOutSerl  = A.InOutSerl    
                                                    AND B.DataKind   = A.DataKind    
                                                    AND B.InOutSubSerl  = A.InOutDataSerl    
         WHERE A.WorkingTag = 'U' AND A.Status = 0  
           AND B.InOutType = 130
        
      
      
      
        DELETE _TLGInOutLotStock       
          FROM #TLGInOutDailyItemSub AS A        
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        
                                                    AND B.InOutType   = A.InOutType        
                                                    AND B.InOutSeq   = A.InOutSeq        
                                                    AND B.InOutSerl  = A.InOutSerl    
                                                    AND B.DataKind   = A.DataKind    
                                                    AND B.InOutSubSerl  = A.InOutDataSerl    
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
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        TRUNCATE TABLE #TLGInOutStock  
        TRUNCATE TABLE #TLGInOutLotStock    

        EXEC  _SLGCreateDataForInOutSubStock @CompanySeq, 'A'  

        INSERT INTO _TLGInOutDailyItemSub(    
                CompanySeq,
                InOutType,
                InOutSeq,
                InOutSerl,
                DataKind,
                InOutDataSerl,
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
                LastUserSeq,
                LastDateTime,
                PgmSeq)  
        SELECT  @CompanySeq, 
                ISNULL(InOutType ,0),
                ISNULL(InOutSeq,0),
                ISNULL(InOutSerl,0),
                ISNULL(DataKind,0),
                ISNULL(InOutDataSerl,0),
                ISNULL(ItemSeq,0),
                ISNULL(Remark,''),
                ISNULL(CCtrSeq,0),
                ISNULL(DVPlaceSeq,0),
                ISNULL(InWHSeq,0),
                ISNULL(OutWHSeq,0),
                ISNULL(UnitSeq,0),
                ISNULL(Qty,0),
                ISNULL(STDQty,0),
                ISNULL(Amt,0),
                ISNULL(EtcOutAmt,0),
                ISNULL(EtcOutVAT,0),
                ISNULL(InOutKind,0),
                ISNULL(InOutDetailKind,0),
                ISNULL(LotNo,''),
                ISNULL(SerialNo,''),
                @UserSeq,  
                GETDATE(),
                @PgmSeq
          FROM #TLGInOutDailyItemSub A    
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

        EXEC  _SLGCreateDataForInOutLotSubStock @CompanySeq, 'A'    -- 2011. 1. 26 hkim 생산실적 자재투입 처리시에 정상적으로 테이블에 반영되지 않아서 SP 호출 위치 변경

        INSERT  _TLGInOutLotStock    
        SELECT  @CompanySeq, *    
          FROM  #TLGInOutLotStock    
  
        --EXEC  _SLGCreateDataForInOutLotSubStock @CompanySeq, 'A'    
  
        INSERT  #TLGInOutMonthLot                
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,                
                       ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,     LotNo    ,      
                       ADD_DEL)                
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,                
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,     LotNo    ,      
                       1                
          FROM  #TLGInOutLotStock   B                   
   
    END        
      
    EXEC _SLGWHStockUPDATE @CompanySeq  
    EXEC _SLGLOTStockUPDATE @CompanySeq  

    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyItemSub', @LanguageSeq
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyItemSub', @LanguageSeq
    
    
    --select * from #TLGItemOut 
    
    
    
    --return 
    
    ---------------------------------------------------------------
    -- 포장재 기타출고 처리 
    ---------------------------------------------------------------
    
    DECLARE @XmlData    NVARCHAR(MAX), 
            @InOutSeq   INT 
    
    
    SELECT @InOutSeq = (SELECT MAX(InOutSeq) FROM _TLGInOutDaily WHERE CompanySeq = @CompanySeq AND InOutType = 31) 
    
    INSERT INTO KPXLS_TPDSFCMatInputRelation ( CompanySeq, WorkReportSeq, ItemSerl, InOutType, InOutSeq, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq, A.InOutSeq, A.ItemSerlSub, A.InOutType, ISNULL(@InOutSeq,0) + DataSeq, @UserSeq, GETDATE()
      FROM #TLGItemOut AS A 
     WHERE A.WorkingTag = 'A' 
       AND NOT EXISTS (SELECT 1 FROM KPXLS_TPDSFCMatInputRelation WHERE CompanySeq = @CompanySeq AND WorkReportSeq = A.InOutSeq)
    
    
    UPDATE A 
       SET InOutSeq = ISNULL(@InOutSeq,0) + DataSeq
      FROM #TLGItemOut AS A 
     WHERE A.WorkingTag = 'A' 
    
    UPDATE A 
       SET InOutSeq = E.InOutSeq 
      FROM #TLGItemOut AS A 
      JOIN KPXLS_TPDSFCMatInputRelation AS E ON ( E.CompanySeq = @CompanySeq AND E.WorkReportSeq = A.InOutSeq AND E.ItemSerl = A.ItemSerlSub ) 
     WHERE A.WorkingTag IN ( 'U', 'D' ) 
    
    

    
    --select * From #TLGItemOut 
    --return 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                SELECT A.WorkingTag, 
                                                       A.IDX_NO, 
                                                       A.DataSeq, 
                                                       A.Selected, 
                                                       0 AS Status, 
                                                       A.InOutSeq, 
                                                       C.BizUnit, 
                                                       D.WorkOrderNo AS InOutNo, 
                                                       B.DeptSeq,
                                                       B.EmpSeq, 
                                                       B.WorkDate AS InOutDate, 
                                                       0 AS CustSeq, 
                                                       A.OutWHSeq AS OutWHSeq, 
                                                       0 AS DVPlaceSeq, 
                                                       A.InOutType, 
                                                       '생산실적 포장재 기타출고' AS Remark, 
                                                       '' AS Memo, 
                                                       0 AS UseDeptSeq 
                                                  FROM #TLGItemOut                  AS A 
                                                  JOIN KPXLS_TPDSFCMatInputRelation AS E ON ( E.CompanySeq = @CompanySeq AND E.InOutSeq = A.InOutSeq ) 
                                                  JOIN _TPDSFCWorkReport            AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = E.WorkReportSeq ) 
                                                  OUTER APPLY ( SELECT TOP 1 BizUnit 
                                                                  FROM _TDAFactUnit AS Z 
                                                                 WHERE Z.CompanySeq = @CompanySeq 
                                                                   AND Z.FactUnit = B.FactUnit 
                                                              ) AS C 
                                                  LEFT OUTER JOIN _TPDSFCWorkOrder AS D ON ( D.CompanySeq = @CompanySeq AND D.WorkOrderSeq = B.WorkOrderSeq AND D.WorkOrderSerl = B.WorkOrderSerl ) 
                                                 ORDER BY A.DataSeq 
                                                FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS    
                                                  
                                             )  
                             )   
    
    -- 서비스 마스타 등록 생성            
    CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)            
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDaily'      
    
    INSERT INTO #TLGInOutDaily 
    EXEC _SLGInOutDailySave @xmlDocument = @XmlData,
                            @xmlFlags = 2, 
                            @ServiceSeq = 2619, 
                            @WorkingTag = N'', 
                            @CompanySeq = @CompanySeq, 
                            @LanguageSeq = 1, 
                            @UserSeq = @UserSeq, 
                            @PgmSeq = @PgmSeq 
    --select * from #TLGInOutDaily
    --return 
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( 
                                                    SELECT WorkingTag, 
                                                           IDX_NO, 
                                                           DataSeq, 
                                                           Selected, 
                                                           0 AS Status, 
                                                           'DataBlock2' AS TABLE_NAME, 
                                                           InOutSeq, 
                                                           InOutSerl, 
                                                           InOutType, 
                                                           ItemSeq, 
                                                           '생산실적 포장재 기타출고' AS InOutRemark, 
                                                           0 AS CCtrSeq, 
                                                           0 AS DVPlaceSeq, 
                                                           0 AS InWHSeq, 
                                                           OutWHSeq AS OutWHSeq, 
                                                           UnitSeq, 
                                                           Qty, 
                                                           STDQty, 
                                                           0 AS Amt, 
                                                           0 AS EtcOutAmt, 
                                                           0 AS EtcOutVAT, 
                                                           8023003 AS InOutKind, 
                                                           8025047 AS InOutDetailKind, 
                                                           LotNo, 
                                                           '' AS SerialNo 
                                                      FROM #TLGItemOut 
                                                    FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS    
                                                  
                                             )  
                             )   
    -- 서비스 마스타 등록 생성      
    CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)      
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2619, 'DataBlock2', '#TLGInOutDailyItem'     
    
    
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
    
    INSERT INTO #TLGInOutDailyItem 
    EXEC _SLGInOutDailyItemSave @xmlDocument = @XmlData,
                                @xmlFlags = 2, 
                                @ServiceSeq = 2619, 
                                @WorkingTag = N'', 
                                @CompanySeq = @CompanySeq, 
                                @LanguageSeq = 1, 
                                @UserSeq = @UserSeq, 
                                @PgmSeq = @PgmSeq 
    
    DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'
    
    DELETE A 
      FROM KPXLS_TPDSFCMatInputRelation AS A 
      JOIN #TLGItemOut                  AS E ON ( E.InOutSeqOld = A.WorkReportSeq AND E.ItemSerlSub = A.ItemSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND E.WorkingTag = 'D'
       
    ---------------------------------------------------------------
    -- 포장재 기타출고 처리, END 
    ---------------------------------------------------------------
    
    TRUNCATE TABLE #TLGInOutDailyItemSub 
    
    INSERT INTO #TLGInOutDailyItemSub
    SELECT * FROM #TEMP_TLGInOutDailyItemSub

    
    SELECT * FROM #TLGInOutDailyItemSub    

    RETURN
GO
begin tran 
exec _SPDSFCWorkReportMatSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsPjt>0</IsPjt>
    <WBSSeq>0</WBSSeq>
    <WorkReportSeq>47960</WorkReportSeq>
    <ItemSerl>1</ItemSerl>
    <InputDate>20151202</InputDate>
    <MatItemSeq>166</MatItemSeq>
    <MatUnitSeq>3</MatUnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>200.00000</Qty>
    <StdUnitQty>200.00000</StdUnitQty>
    <RealLotNo>기초2015001</RealLotNo>
    <SerialNoFrom />
    <ProcSeq>0</ProcSeq>
    <AssyYn>0</AssyYn>
    <IsConsign>0</IsConsign>
    <GoodItemSeq>309</GoodItemSeq>
    <InputType>0</InputType>
    <IsPaid>0</IsPaid>
    <Remark />
    <WHSeq>1109</WHSeq>
    <ProdWRSeq>0</ProdWRSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsPjt>0</IsPjt>
    <WBSSeq>0</WBSSeq>
    <WorkReportSeq>47960</WorkReportSeq>
    <ItemSerl>2</ItemSerl>
    <InputDate>20151202</InputDate>
    <MatItemSeq>4824</MatItemSeq>
    <MatUnitSeq>1</MatUnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>20.00000</Qty>
    <StdUnitQty>20.00000</StdUnitQty>
    <RealLotNo />
    <SerialNoFrom />
    <ProcSeq>0</ProcSeq>
    <AssyYn>0</AssyYn>
    <IsConsign>0</IsConsign>
    <GoodItemSeq>309</GoodItemSeq>
    <InputType>0</InputType>
    <IsPaid>0</IsPaid>
    <Remark />
    <WHSeq>1109</WHSeq>
    <ProdWRSeq>0</ProdWRSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2909,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015
go
exec KPXLS_SLGInOutDailyItemSubMatInputSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <InOutType>130</InOutType>
    <InOutKind>8023015</InOutKind>
    <InOutSerl>1</InOutSerl>
    <DataKind>0</DataKind>
    <InWHSeq>0</InWHSeq>
    <InOutSeq>47960</InOutSeq>
    <InOutDataSerl>1</InOutDataSerl>
    <ItemSeq>166</ItemSeq>
    <UnitSeq>3</UnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>200.00000</Qty>
    <STDQty>200.00000</STDQty>
    <LotNo>기초2015001</LotNo>
    <InOutDetailKind>6042002</InOutDetailKind>
    <Remark />
    <OutWHSeq>1109</OutWHSeq>
  </DataBlock3>
  <DataBlock3>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <InOutType>130</InOutType>
    <InOutKind>8023015</InOutKind>
    <InOutSerl>2</InOutSerl>
    <DataKind>0</DataKind>
    <InWHSeq>0</InWHSeq>
    <InOutSeq>47960</InOutSeq>
    <InOutDataSerl>2</InOutDataSerl>
    <ItemSeq>4824</ItemSeq>
    <UnitSeq>1</UnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>20.00000</Qty>
    <STDQty>20.00000</STDQty>
    <LotNo />
    <InOutDetailKind>6042002</InOutDetailKind>
    <Remark />
    <OutWHSeq>1109</OutWHSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033517,@WorkingTag=N'',@CompanySeq=3,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015


rollback 