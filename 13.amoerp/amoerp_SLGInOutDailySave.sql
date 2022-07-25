
IF OBJECT_ID('amoerp_SLGInOutDailySave') IS NOT NULL 
    DROP PROC  amoerp_SLGInOutDailySave
GO
 
-- v2013.11.26 

-- ��Ź����Է�_amoerp by����õ
/*************************************************************************************************              
 ��  �� - �����Master ����              
 �ۼ��� - 2008.10 : CREATED BY ����ȯ       
 ������ - 2011.07.11 by ��ö��   
  1) �����Է�-���â������� _TLGInOutStock�� ���â�� �����ǿ��� ��  - ���� - ���   
    2011.09.21 by ��ö��  
  1) ����ó��, ��������ó���� ���Ͽ� ���â������� _TLGInOutStock�� �ݿ��� �ǿ��� ��  
  - ������ �԰�ó������ _TLGInOutStock�� +, - ������� ���â�� ��   
*************************************************************************************************/              
CREATE PROC amoerp_SLGInOutDailySave  
    @xmlDocument    NVARCHAR(MAX),              
    @xmlFlags       INT = 0,              
    @ServiceSeq     INT = 0,              
    @WorkingTag     NVARCHAR(10)= '',              
    @CompanySeq     INT = 1,              
    @LanguageSeq    INT = 1,              
    @UserSeq        INT = 0,              
    @PgmSeq         INT = 0              
AS              
    DECLARE @docHandle        INT,  
            @IsChg            NCHAR(1)  
            
    -- ���� ����Ÿ ��� ����              
    CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)              
    ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDaily'              
    --return
    -- �α� �����  
    DECLARE @TableColumns NVARCHAR(4000)  
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDaily')  
      
    EXEC _SCOMLog @CompanySeq,    
                  @UserSeq,    
                  '_TLGInOutDaily',   
                  '#TLGInOutDaily',   
                  'InOutType, InOutSeq', -- CompanySeq���� �� Ű   
                  @TableColumns, '', @PgmSeq   
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDailyItem')  
      
    -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ...   
    EXEC _SCOMDeleteLog @CompanySeq,    
                        @UserSeq,    
                        '_TLGInOutDailyItem',   
                        '#TLGInOutDaily',   
                        'InOutType, InOutSeq', -- CompanySeq���� �� Ű   
                        @TableColumns, '', @PgmSeq   
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutDailyItemSub')  
      
    -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ...   
    EXEC _SCOMDeleteLog @CompanySeq,    
                        @UserSeq,    
                        '_TLGInOutDailyItemSub',   
                        '#TLGInOutDaily',   
                        'InOutType, InOutSeq', -- CompanySeq���� �� Ű   
                        @TableColumns, '', @PgmSeq   
      
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TLGInOutLotSub')  
      
    -- _S%Save �� _S%Delete �ΰ��� SP���� ���ؼ� ...   
    EXEC _SCOMDeleteLog @CompanySeq,    
                        @UserSeq,    
                        '_TLGInOutLotSub',   
                        '#TLGInOutDaily',   
                        'InOutType, InOutSeq', -- CompanySeq���� �� Ű   
                        @TableColumns, '', @PgmSeq   
      
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
            
    Create Table #TLGInOutMinusCheck    
    (      
        WHSeq           INT,    
        FunctionWHSeq   INT,    
        ItemSeq         INT  
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
   
   /*  -- 2012.02.29 by ��ö��, serial�� ������ ���� ����   
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
   
 /*  
 DECLARE @MessageType INT,  
   @Status   INT,  
   @Results  NVARCHAR(300)  
   
 -- @2 @1(@3)��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.  
 -- SerialNo��(��) ��ϵǾ� ����/���� �� �� �����ϴ�.  
 EXEC dbo._SCOMMessage @MessageType OUTPUT,            
                          @Status      OUTPUT,            
                          @Results     OUTPUT,            
                          8, -- select * from _TCAMessageLanguage where MessageSeq = 8  
                          @LanguageSeq,             
                          0,'SerialNo'  
   
 --select REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' )  
   
 -- �� ����, ��Ʈǰ����� ������ �ʿ䰡 ����, �� �ܰ�� �� ���� ������ �ܰ� ����ǿ������� SerialNo����� �ϴϱ�...    
 UPDATE A  
    SET A.Result   = REPLACE( REPLACE( @Results, '@2', '' ), '(@3)', '' ),          
     A.MessageType = @MessageType,          
     A.Status   = @Status       
   FROM #TLGInOutDaily  AS A   
   JOIN _TLGInOutSerialSub AS B WITH(NOLOCK) ON ( A.InOutType = B.InOutType AND A.InOutSeq = B.InOutSeq AND B.CompanySeq = @CompanySeq )  
  WHERE A.WorkingTag IN ( 'U', 'D' )   
    AND A.Status = 0    
    */  
      
    -- DELETE                
    IF EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE WorkingTag = 'D' AND Status = 0  )              
    BEGIN      
  /*  
        INSERT INTO #TLGInOutSerialSub  
        SELECT B.InOutType, B.InOutSeq, B.InOutSerl, B.DataKind, B.InOutDataSerl, B.InOutSerialSerl, B.SerialNo, B.ItemSeq, 0, '', 0  
          FROM #TLGInOutDaily AS A  
                JOIN _TLGInOutSerialSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq        -- WITH (NOLOCK) �߰� 2011. 9. 1 hkim  
                                                          AND A.InOutType  = B.InOutType  
                                                          AND A.InOutSeq   = B.InOutSeq  
         WHERE A.WorkingTag = 'D' AND A.Status = 0     
  
        IF EXISTS (SELECT 1 FROM #TLGInOutSerialSub)  
        BEGIN  
            -- SERIAL ������          
            EXEC  _SLGCreateDataForInOutSerialStockBatch @CompanySeq, 'D'    
  
            UPDATE #TLGInOutDaily      
               SET Result        = B.Result     ,          
                   MessageType   = B.MessageType,          
                   Status        = B.Status          
              FROM #TLGInOutDaily          AS A       
                   JOIN #TLGInOutSerialSub AS B WITH (NOLOCK) ON A.InOutType = B.InOutType    -- WITH (NOLOCK) �߰� 2011. 9. 1 hkim  
                                                             AND A.InOutSeq  = B.InOutSeq  
             WHERE B.Status <> 0       
  
  
            -- SerialSub DELETE  
            DELETE _TLGInOutSerialSub    
              FROM #TLGInOutDaily AS A    
                   JOIN _TLGInOutSerialSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq     -- WITH (NOLOCK) �߰� 2011. 9. 1 hkim  
                                                             AND A.InOutType  = B.InOutType  
                                                             AND A.InOutSeq   = B.InOutSeq  
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
          SELECT     B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,          
                       B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,          
                       -1          
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq              
                                                     AND B.InOutType  = A.InOutType              
                                                     AND B.InOutSeq   = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0               
        
        
        DELETE _TLGInOutStock            
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutStock AS B WITH (NOLOCK) ON  B.CompanySeq  = @CompanySeq            
                                                      AND B.InOutType   = A.InOutType          
                                                      AND B.InOutSeq    = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0               
            
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END              
          
        INSERT #TLGInOutMonthLot        
        (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,        
                       LotNo           ,        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,        
                       ADD_DEL)        
        SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,        
                       B.LotNo         ,        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,        
                       -1        
          FROM #TLGInOutDaily AS A            
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq            
                                                          AND B.InOutType   = A.InOutType            
                                                          AND B.InOutSeq    = A.InOutSeq            
         WHERE A.WorkingTag = 'D' AND A.Status = 0            
      
        DELETE _TLGInOutLotStock            
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON  B.CompanySeq  = @CompanySeq            
                                                      AND B.InOutType   = A.InOutType          
                                                      AND B.InOutSeq    = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0               
            
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END              
         
         -- LOT ����� DELETE            
        DELETE _TLGInOutLotSub              
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutDailyItem AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq            
                                                            AND B.InOutType   = A.InOutType            
                                                            AND B.InOutSeq   = A.InOutSeq            
               JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq            
                                                            AND C.InOutType  = B.InOutType            
                                                            AND C.InOutSeq   = B.InOutSeq              
                                                            AND C.InOutSerl  = B.InOutSerl       
         WHERE  B.LotNo > ''           
           AND  A.WorkingTag = 'D' AND A.Status = 0               
            
        IF @@ERROR <> 0        
        BEGIN                
            RETURN                
        END              
         
        DELETE _TLGInOutDailyItemSub              
            FROM #TLGInOutDaily AS A              
           JOIN _TLGInOutDailyItemSub AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq              
              AND B.InOutType   = A.InOutType          
                                                        AND B.InOutSeq   = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0               
            
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END              
            
      
        -- �����Item DELETE            
        DELETE _TLGInOutDailyItem            
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutDailyItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                            AND B.InOutType   = A.InOutType          
                                                            AND B.InOutSeq    = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0  

        DELETE amoerp_TLGInOutDailyItemMerge           
          FROM #TLGInOutDaily AS A              
               JOIN amoerp_TLGInOutDailyItemMerge AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                                    AND B.InOutType   = A.InOutType          
                                                                    AND B.InOutSeq    = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0    
    
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END              
          
        -- �����Master DELETE            
        DELETE _TLGInOutDaily              
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutDaily AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                     AND B.InOutType   = A.InOutType          
                                                     AND B.InOutSeq = A.InOutSeq              
         WHERE A.WorkingTag = 'D' AND A.Status = 0               
            
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END              
    
        DELETE FROM _TCOMSourceDaily 
         WHERE CompanySeq = @CompanySeq 
           AND ToTableSeq = 14 
           AND ToSeq = (SELECT TOP 1 InOutSeq FROM #TLGInOutDaily) 
        
        DELETE FROM amoerp_TLGInOutDailyItemMergeSub 
         WHERE CompanySeq = @CompanySeq 
           AND InOutSeq = (SELECT TOP 1 InOutSeq FROM #TLGInOutDaily)
        
    END              
              
    -- Update                
    IF EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE WorkingTag = 'U' AND Status = 0  )              
    BEGIN               
        IF EXISTS (SELECT 1   
                     FROM #TLGInOutDaily      AS A              
                          JOIN _TLGInOutDaily AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                                AND B.InOutType   = A.InOutType          
                                                                AND B.InOutSeq    = A.InOutSeq            
                    WHERE A.BizUnit   <> B.BizUnit  
                       OR A.FactUnit  <> B.FactUnit  
                       OR A.InOutDate <> B.InOutDate  
                       OR A.OutWHSeq  <> B.OutWHSeq  
                       OR A.InWHSeq   <> B.InWHSeq)  
        BEGIN  
            SELECT @IsChg = '1'  
        END  
  
        UPDATE _TLGInOutDaily              
           SET  BizUnit        = ISNULL(A.BizUnit,0),        
                InOutNo        = ISNULL(A.InOutNo,''),        
                FactUnit       = ISNULL(A.FactUnit,0),        
                ReqBizUnit     = ISNULL(A.ReqBizUnit,0),        
                DeptSeq        = ISNULL(A.DeptSeq,0),        
                EmpSeq         = ISNULL(A.EmpSeq,0),        
                InOutDate      = ISNULL(A.InOutDate,''),        
                WCSeq          = ISNULL(A.WCSeq,0),        
                ProcSeq        = ISNULL(A.ProcSeq,0),          
                CustSeq        = ISNULL(A.CustSeq,0),          
                OutWHSeq       = ISNULL(A.OutWHSeq,0),          
                InWHSeq        = ISNULL(A.InWHSeq,0),          
                DVPlaceSeq     = ISNULL(A.DVPlaceSeq,0),          
--                IsTrans        = ISNULL(A.IsTrans,''),          
                IsCompleted     = ISNULL(A.IsCompleted,  ''),        
                CompleteDeptSeq = ISNULL(A.CompleteDeptSeq,0),          
                CompleteEmpSeq  = ISNULL(A.CompleteEmpSeq,0),          
                CompleteDate    = ISNULL(A.CompleteDate,''),          
--                InOutType     = A.InOutType,          
                  InOutDetailType = ISNULL(A.InOutDetailType,0),          
                Remark          = ISNULL(A.Remark,''),          
                Memo            = ISNULL(A.Memo,''),          
                LastUserSeq     = @UserSeq,          
                LastDateTime = Getdate(),  
                UseDeptSeq      = ISNULL(A.UseDeptSeq,''),  
                PgmSeq = @PgmSeq          
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutDaily AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                     AND B.InOutType   = A.InOutType          
                                                     AND B.InOutSeq = A.InOutSeq              
         WHERE A.WorkingTag = 'U' AND A.Status = 0            
               
        IF @@ERROR <> 0                
        BEGIN               
            RETURN                
        END              
  
        UPDATE _TLGInOutDailyItem              
           SET  OutWHSeq       = CASE WHEN ISNULL(A.OutWHSeq,0) = 0 THEN B.OutWHSeq ELSE A.OutWHSeq END,          
                InWHSeq        = CASE WHEN ISNULL(A.InWHSeq,0) = 0 THEN B.InWHSeq ELSE A.InWHSeq END,  
                PgmSeq = @PgmSeq  
          FROM #TLGInOutDaily AS A              
               JOIN _TLGInOutDailyItem AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq              
                                                         AND B.InOutType   = A.InOutType          
                                                         AND B.InOutSeq = A.InOutSeq              
         WHERE A.WorkingTag = 'U' AND A.Status = 0            
               
        IF @@ERROR <> 0                
        BEGIN               
            RETURN                
        END         
  
        -- ���Ұ��� ������� �����ϸ�  
        IF @IsChg = '1'  
        BEGIN  
             -- LOT ����� DELETE            
            UPDATE _TLGInOutLotSub              
               SET  OutWHSeq       = CASE WHEN ISNULL(A.OutWHSeq,0) = 0 THEN C.OutWHSeq ELSE A.OutWHSeq END,          
                    InWHSeq        = CASE WHEN ISNULL(A.InWHSeq,0) = 0 THEN C.InWHSeq ELSE A.InWHSeq END,  
                    PgmSeq = @PgmSeq  
              FROM #TLGInOutDaily AS A              
                   JOIN _TLGInOutLotSub AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq            
                                                          AND C.InOutType  = A.InOutType            
                                                          AND C.InOutSeq   = A.InOutSeq              
             WHERE  C.LotNo > ''           
               AND  A.WorkingTag = 'U' AND A.Status = 0               
                
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
              FROM #TLGInOutDaily AS A              
                   JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq              
                                                         AND B.InOutType  = A.InOutType              
                                                         AND B.InOutSeq   = A.InOutSeq              
             WHERE A.WorkingTag = 'U' AND A.Status = 0               
            
   -- â�� _TLGInOutStock�� �ݿ��ϱ� ( ����ó��,��������ó�� ���� )  
            UPDATE _TLGInOutStock   
                 SET WHSeq = (CASE B.InOut WHEN 1 THEN A.InWHSeq WHEN -1 THEN A.OutWHSeq ELSE 0 END)  
              FROM #TLGInOutDaily AS A              
              JOIN _TLGInOutStock AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutType = A.InOutType AND B.InOutSeq = A.InOutSeq )   
             WHERE A.WorkingTag = 'U' AND A.Status = 0          
               AND A.InOutType NOT IN (81, 83)  
     
            IF @@ERROR <> 0 RETURN   
     
   -- â�� _TLGInOutStock�� �ݿ��ϱ� ( ����ó��,��������ó������ ���Ͽ� ) - 2011.09.21 by ��ö��, 1)   
            UPDATE _TLGInOutStock   
               SET WHSeq = (CASE B.InOut WHEN 1 THEN A.OutWHSeq WHEN -1 THEN A.OutWHSeq ELSE 0 END)  
              FROM #TLGInOutDaily AS A              
              JOIN _TLGInOutStock AS B WITH (NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutType = A.InOutType AND B.InOutSeq = A.InOutSeq )   
             WHERE A.WorkingTag = 'U' AND A.Status = 0          
               AND A.InOutType IN (81, 83)  
     
            IF @@ERROR <> 0 RETURN   
              
            UPDATE  _TLGInOutStock   
               SET  InOutDate = (CASE WHEN ISNULL(A.InOutDate,'') = '' THEN B.InOutDate ELSE A.InOutDate END),  
                    InOutYM = (CASE WHEN ISNULL(A.InOutDate,'') = '' THEN B.InOutYM ELSE LEFT(A.InOutDate, 6) END)  
              FROM  #TLGInOutDaily AS A              
                    JOIN _TLGInOutStock AS B WITH (NOLOCK) ON  B.CompanySeq  = @CompanySeq            
                                                          AND B.InOutType   = A.InOutType          
                                                          AND B.InOutSeq    = A.InOutSeq    
             WHERE A.WorkingTag = 'U' AND A.Status = 0          
               AND A.InOutDate <> B.InOutDate  
  
            IF @@ERROR <> 0                
            BEGIN                
                RETURN                
            END              
  
            INSERT #TLGInOutMonth          
            (              InOut           ,        InOutYM           
                  ,        WHSeq           ,        FunctionWHSeq   ,          
                           ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,          
                           ADD_DEL)          
            SELECT         B.InOut         ,        B.InOutYM ,  
                           B.WHSeq         ,        B.FunctionWHSeq ,          
                           B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,          
                           1          
              FROM #TLGInOutDaily AS A              
                   JOIN _TLGInOutStock AS B WITH (NOLOCK) ON B.CompanySeq = @CompanySeq              
                                                         AND B.InOutType  = A.InOutType              
                                                         AND B.InOutSeq   = A.InOutSeq              
             WHERE A.WorkingTag = 'U' AND A.Status = 0               
  
  
            INSERT #TLGInOutMonthLot        
            (              InOut           ,        InOutYM         ,        WHSeq           ,        FunctionWHSeq   ,        
                           LotNo           ,        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,        
                           ADD_DEL)        
            SELECT         B.InOut         ,        B.InOutYM       ,        B.WHSeq         ,        B.FunctionWHSeq ,        
                           B.LotNo         ,        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,        
                           -1        
              FROM #TLGInOutDaily AS A            
                   JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq            
                                                              AND B.InOutType   = A.InOutType            
                                                                AND B.InOutSeq    = A.InOutSeq             
             WHERE A.WorkingTag = 'U' AND A.Status = 0            
          
             UPDATE  _TLGInOutLotStock   
               SET  WHSeq = (CASE B.InOut WHEN 1 THEN A.InWHSeq WHEN -1 THEN A.OutWHSeq ELSE 0 END)  
              FROM  #TLGInOutDaily AS A              
                    JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON  B.CompanySeq  = @CompanySeq            
                                                          AND B.InOutType   = A.InOutType          
                                                          AND B.InOutSeq    = A.InOutSeq    
             WHERE A.WorkingTag = 'U' AND A.Status = 0          
               AND A.InOutType NOT IN (81, 83)  
                
            IF @@ERROR <> 0                
            BEGIN                
                RETURN                
            END              
  
            INSERT #TLGInOutMonthLot        
            (              InOut           ,        InOutYM         ,          
                           WHSeq           ,        FunctionWHSeq   ,        
                           LotNo           ,        ItemSeq         ,        UnitSeq         ,        Qty             ,        StdQty          ,        
                           ADD_DEL)        
            SELECT         B.InOut         ,        B.InOutYM,  
                           B.WHSeq         ,        B.FunctionWHSeq ,        
                           B.LotNo         ,        B.ItemSeq       ,        B.UnitSeq       ,        B.Qty           ,        B.StdQty        ,        
                           1        
              FROM #TLGInOutDaily AS A            
                   JOIN _TLGInOutLotStock AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq            
                                                              AND B.InOutType   = A.InOutType            
                                                              AND B.InOutSeq    = A.InOutSeq            
             WHERE A.WorkingTag = 'U' AND A.Status = 0            
        END  
    END              
                 
    -- INSERT                
    IF EXISTS (SELECT 1 FROM #TLGInOutDaily WHERE WorkingTag = 'A' AND Status = 0 )              
    BEGIN              
            
        INSERT INTO _TLGInOutDaily(              
                CompanySeq,          
                InOutType,          
                InOutSeq,          
                BizUnit,          
                InOutNo,          
                FactUnit,          
                ReqBizUnit,          
                DeptSeq,          
                EmpSeq,          
                InOutDate,          
                WCSeq,          
                ProcSeq,          
                CustSeq,          
                OutWHSeq,          
                InWHSeq,          
                DVPlaceSeq,          
                IsTrans,          
                IsCompleted,          
                CompleteDeptSeq,          
                CompleteEmpSeq,          
                CompleteDate,          
                InOutDetailType,          
                Remark,        
                Memo,          
                LastUserSeq,          
                LastDateTime,  
                UseDeptSeq,  
                PgmSeq)            
        SELECT  @CompanySeq,            
                ISNULL(InOutType,0),        
                ISNULL(InOutSeq,0),          
                ISNULL(BizUnit,0),          
                ISNULL(InOutNo,''),          
                ISNULL(FactUnit,0),          
                ISNULL(ReqBizUnit,0),          
                ISNULL(DeptSeq,0),          
                ISNULL(EmpSeq,0),          
                ISNULL(InOutDate,''),          
                ISNULL(WCSeq,0),          
                ISNULL(ProcSeq,0),          
                ISNULL(CustSeq,0),          
                ISNULL(OutWHSeq,0),          
                ISNULL(InWHSeq,0),          
                ISNULL(DVPlaceSeq,0),          
                  ISNULL(IsTrans,''),           
                ISNULL(IsCompleted,''),          
                ISNULL(CompleteDeptSeq,0),          
                ISNULL(CompleteEmpSeq,0),          
                ISNULL(CompleteDate,''),          
                ISNULL(InOutDetailType,0),          
                ISNULL(Remark,''),          
                ISNULL(Memo,''),          
                @UserSeq,            
                GETDATE(),  
                ISNULL(UseDeptSeq,0),  
                @PgmSeq            
          FROM #TLGInOutDaily A              
         WHERE WorkingTag = 'A' AND Status = 0            
              
        IF @@ERROR <> 0                
        BEGIN                
            RETURN                
        END                 
    END                  
  
    EXEC _SLGWHStockUPDATE @CompanySeq          
    EXEC _SLGLOTStockUPDATE @CompanySeq          
  
    EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDaily', @LanguageSeq  
    EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDaily', @LanguageSeq  
                
    SELECT * FROM #TLGInOutDaily              
            
 RETURN              
GO
begin tran
exec amoerp_SLGInOutDailySave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <InOutSeq>1001291</InOutSeq>
    <BizUnit>1</BizUnit>
    <InOutNo>201311260002        </InOutNo>
    <DeptSeq>135</DeptSeq>
    <EmpSeq>1863</EmpSeq>
    <InOutDate>20131126</InOutDate>
    <OutWHSeq>2</OutWHSeq>
    <InWHSeq>6</InWHSeq>
    <DVPlaceSeq>0</DVPlaceSeq>
    <InOutType>50</InOutType>
    <Remark />
    <Memo />
    <BizUnitName>�ƻ����</BizUnitName>
    <DeptName>��������</DeptName>
    <EmpName>��â��</EmpName>
    <OutWHName>��Ȳ���</OutWHName>
    <InWHName>PLASSON UK</InWHName>
    <DVPlaceName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426
rollback