drop proc test_SPDSFCWorkReportMatSave
go 
/************************************************************      
 설  명 - 생산실적자재투입      
 작성일 - 2008년 10월 22일       
 작성자 - 정동혁      
 UPDATE ::  '전공정양품수량 가져오기' 사용하면서, 재공품 투입 처리 및 취소시 (수정은 화면단에서 막음) , 전공정 현장창고와 현공정 현장창고 다를경우,  
             이동 데이터 생성해준다( 전공정 현장창고 -> 현 공정 현장창고)      -- 12.12.28 BY 김세호  
    2013.04.15 허승남 :: 해체작업의 경우 자동불출이 필요없으므로 불출데이터 생성을 제외시켜줌.  
 ************************************************************/   
 CREATE PROC dbo.test_SPDSFCWorkReportMatSave  
     @xmlDocument    NVARCHAR(MAX),        
     @xmlFlags       INT = 0,        
     @ServiceSeq     INT = 0,        
     @WorkingTag     NVARCHAR(10)= '',        
     @CompanySeq     INT = 1,        
     @LanguageSeq    INT = 1,        
     @UserSeq        INT = 0,        
     @PgmSeq         INT = 0        
 AS          
     DECLARE @MatItemPoint   INT,    
             @Env6217        NCHAR(2),  
             @Env6201        NCHAR(2),  
             @WorkOrderSeq   INT,  
             @WorkOrderSerl  INT,  
             @WorkReportSeq  INT,      
             @EmpSeq         INT,  
             @XmlData        NVARCHAR(MAX)  
      -- 서비스 마스타 등록 생성      
     CREATE TABLE #TPDSFCMatinput (WorkingTag NCHAR(1) NULL)        
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPDSFCMatinput'           
     IF @@ERROR <> 0 RETURN          
       
    
  -- PgmSeq 작업 2014년 07월 20일 일괄 작업합니다. (추후 안정화 되면 삭제예정)   
  IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDSFCMatinput' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDSFCMatinput ADD PgmSeq INT NULL  
  END   
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDSFCMatinputLog' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDSFCMatinputLog ADD PgmSeq INT NULL  
  END    
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMMOutM' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDMMOutM ADD PgmSeq INT NULL  
  END   
   IF NOT EXISTS (SELECT * FROM Sysobjects AS A JOIN syscolumns AS B ON A.id = B.id where A.Name = '_TPDMMOutItem' AND A.xtype = 'U' AND B.Name = 'PgmSeq')  
  BEGIN  
    ALTER TABLE _TPDMMOutItem ADD PgmSeq INT NULL  
  END     

     -- 재고반영        
     Create Table #TLGInOutMinusCheck        
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
       
     CREATE TABLE #TLGInOutDailyBatch        
     (        
         InOutType       INT,        
         InOutSeq        INT,      
         MessageType     INT,      
         Result          NVARCHAR(250),      
         Status          INT      
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
       
     EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@MatItemPoint OUTPUT       
     
  
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)      
 --    EXEC _SCOMInsertColumnList '_TPDSFCMatinput'      
       
     EXEC _SCOMLog  @CompanySeq,      
                    @UserSeq,      
                    '_TPDSFCMatinput',      
          '#TPDSFCMatinput',      
                    'WorkReportSeq, ItemSerl',      
                    'CompanySeq,WorkReportSeq,ItemSerl,InputDate,MatItemSeq,MatUnitSeq,Qty,StdUnitQty,RealLotNo,SerialNoFrom,ProcSeq,AssyYn,IsConsign,GoodItemSeq,InputType,IsPaid,IsPjt,PjtSeq,WBSSeq,LastUserSeq,LastDateTime,Remark,ProdWRSeq,PgmSeq',  
        '',@PgmSeq      
       
/*
        
     -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT      
       
       
     -- DELETE          
     IF EXISTS (SELECT TOP 1 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'D' AND Status = 0)        
     BEGIN        
          -- 삭제 투입건의 실제 수량을 UPDATE (이후 마이너스 이동데이터 생성시 사용)  
         UPDATE #TPDSFCMatinput   
            SET Qty = B.Qty,  
                StdUnitQty  = B.StdUnitQty  
           FROM #TPDSFCMatinput  AS A  
           JOIN _TPDSFCMatInput  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl   
          WHERE A.WorkingTag = 'D'       
            AND A.Status = 0      
            AND B.CompanySeq  = @CompanySeq    
             
         DELETE _TPDSFCMatinput      
           FROM _TPDSFCMatinput   AS A       
             JOIN #TPDSFCMatinput AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl      
          WHERE B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND A.CompanySeq  = @CompanySeq      
         IF @@ERROR <> 0  RETURN      
       
         -- 삭제시는 _TLGInOutLotSub 삭제  2011. 3. 15 hkim    
         DELETE _TLGInOutLotSub    
           FROM _TLGInOutLotSub      AS A    
                JOIN #TPDSFCMatinput AS B ON A.InOutSeq   = B.WorkReportSeq    
                JOIN _TDAItemStock   AS C ON B.MatItemSeq = C.ItemSeq    
          WHERE A.InOutType     = 130    
            AND C.IsLotMng      = '1'    
            AND A.LotNo         = B.RealLotNo    
            AND A.InOutDataSerl = B.ItemSerl    
            AND B.WorkingTag    = 'D'    
            AND B.Status        = 0    
            AND A.CompanySeq    = @CompanySeq    
          IF @@ERROR <> 0  RETURN      
            
         -- 2010.01.19. 정동혁 투입취소시 자동출고가 삭제되지 않는 오류가 있어서 추가.       
         INSERT INTO #TLGInOutDailyBatch        
         SELECT DISTINCT 180, A.MatOutSeq, 0, '', 0      
           FROM _TPDMMOutM               AS A       
             JOIN #TPDSFCMatinput        AS B ON A.WorkReportSeq = B.WorkReportSeq        
          WHERE B.WorkingTag = 'D'       
            AND B.Status     = 0      
            AND A.CompanySeq = @CompanySeq      
            AND B.WorkReportSeq <> 0    
            AND A.UseType = 6044006    
       
         IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch )      
         BEGIN      
             EXEC _SLGInOutDailyDELETE @CompanySeq      
 --      
 --            EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
 --      
 --            UPDATE A      
 --               SET Result        = B.Result     ,          
 --                   MessageType   = B.MessageType,          
 --                   Status        = B.Status          
 --              FROM #TPDSFCMatinput          AS A       
 --        JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
 --                JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
 --             WHERE B.Status <> 0       
 --               AND A.WorkingTag = 'D'       
 --               AND A.Status     = 0      
 --                     
 --            TRUNCATE TABLE #TLGInOutDailyBatch      
         END      
       
       
         -- 기 저장된 자동출고삭제 (투입취소분)      
         DELETE _TPDMMOutItem      
           FROM _TPDMMOutItem        AS A       
             JOIN _TPDMMOutM         AS M ON A.MatOutSeq = M.MatOutSeq      
  
       AND A.CompanySeq = M.CompanySeq      
             JOIN #TPDSFCMatinput    AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE A.CompanySeq  = @CompanySeq      
            AND B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND M.UseType = 6044006      
            AND B.WorkReportSeq <> 0      
         IF @@ERROR <> 0  RETURN      
    
         -- 마스터도 삭제       
         DELETE _TPDMMOutM      
           FROM _TPDMMOutM           AS M       
             JOIN #TPDSFCMatinput    AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE M.CompanySeq  = @CompanySeq      
            AND B.WorkingTag = 'D'       
            AND B.Status = 0      
            AND NOT EXISTS (SELECT 1 FROM _TPDMMOutItem WHERE CompanySeq = M.CompanySeq AND MatOutSeq = M.MatOutSeq)      
            AND M.UseType = 6044006      
            AND B.WorkReportSeq <> 0      
         IF @@ERROR <> 0  RETURN      
       
     END        
       
       
     -- 기준단위수량 적용      
     UPDATE T      
        --SET StdUnitQty = T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END )      
        SET StdUnitQty = (CASE WHEN V.SMDecPointSeq = 1003001 THEN ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0)   -- 반올림    
                               WHEN V.SMDecPointSeq = 1003002 THEN ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, -1)  -- 절사    
                               WHEN V.SMDecPointSeq = 1003003 THEN ROUND((CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ) * T.Qty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@MatItemPoint + 1)), @MatItemPoint)   -- 올림    
                               ELSE ROUND(T.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0) END)  -- 기본은 반올림으로 수정 2011. 3. 3. hkim    
       FROM #TPDSFCMatinput  AS T      
         JOIN _TDAItemUnit   AS U ON T.MatItemSeq = U.ItemSeq      
                                 AND T.MatUnitSeq = U.UnitSeq      
         JOIN _TDAUnit       AS V ON T.MatUnitSeq = V.UnitSeq     
      WHERE U.CompanySeq = @CompanySeq    
        AND V.CompanySeq = @CompanySeq          
    
    
        
     -- 투입일      
     UPDATE #TPDSFCMatinput      
        SET InputDate = B.WorkDate      
       FROM #TPDSFCMatinput      AS A       
         JOIN _TPDSFCWorkReport  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                     AND B.CompanySeq  = @CompanySeq        
      WHERE InputDate = ''      
       
       
    -- 현장창고      
     UPDATE #TPDSFCMatinput      
        SET WHSeq = B.FieldWhSeq      
       FROM #TPDSFCMatinput      AS A       
         JOIN _TPDSFCWorkReport  AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                     AND B.CompanySeq  = @CompanySeq        
       
       
     -- 투입구분 - 화면에서는 입력된 자재는 정상으로 처리한다.       
     UPDATE #TPDSFCMatinput      
        SET InputType = 6042002      
      WHERE InputType = 0      
       
 --------------------------------------------------------------------------------------------------------------------------------------------------------------      
     -- 추가투입자재가 수탁인경우 투입구분 수탁으로 수정      
       
       
     CREATE TABLE #MatNeed_GoodItem      
     (      
         IDX_NO          INT IDENTITY(1,1),      
         ItemSeq         INT,        -- 제품코드      
         ProcRev         NCHAR(2),   -- 공정흐름차수      
         BOMRev          NCHAR(2),   -- BOM차수      
         ProcSeq         INT,        -- 공정코드      
         AssyItemSeq     INT,        -- 공정품코드      
         UnitSeq         INT,        -- 단위코드     (공정품코드가 있으면 공정품단위코드, 없으면 제품단위코드)      
         Qty             DECIMAL(19,5),    -- 제품수량     (공정품코드가 있으면 공정품수량)      
         ProdPlanSeq     INT,        -- 생산계획내부번호 (생산의뢰에서 추가된 옵션자재를 가져오기위해)      
         WorkOrderSeq    INT,        -- 작업지시내부번호 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)      
         WorkOrderSerl   INT,        -- 작업지시내부순번 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)      
  
         IsOut            NCHAR(1),   -- 로스율 적용에 사용 '1'이면 OutLossRate 적용      
         WorkReportSeq   INT      
     )      
            
     CREATE TABLE #MatNeed_MatItem_Result      
     (      
         IDX_NO          INT,            -- 제품코드      
         MatItemSeq    INT,            -- 자재코드      
         UnitSeq         INT,            -- 자재단위      
         NeedQty         DECIMAL(19,5),  -- 소요량      
         InputType       INT      
     )      
       
       
           
     CREATE TABLE #NeedMatSUM      
     (      
         ProcSeq         INT,      
         MatItemSeq      INT,      
         UnitSeq         INT,      
         NeedQty         NUMERIC(19,5),      
         InputQty        NUMERIC(19,5),      
         InputType       INT,      
         ItemSeq         INT,        -- 제품코드      
         BOMRev          NCHAR(2),   -- BOM차수      
         AssyItemSeq     INT,        -- 공정품코드      
         BOMSerl         INT      
     )      
       
     DECLARE @WorkReportSeqQry INT       
       
     SELECT TOP 1 @WorkReportSeqQry = WorkReportSeq FROM #TPDSFCMatinput      
       
     -- 소요량계산 을 위한 품목담기.      
     INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkReportSeq)      
     SELECT W.GoodItemSeq, W.ProcRev, W.ItemBomRev, W.ProcSeq, W.AssyItemSeq, W.ProdUnitSeq,       
            W.ProdQty * (CASE WHEN W.WorkType = 6041004 THEN (-1)       
         WHEN W.WorkType = 6041010 THEN (-1) ELSE 1 END),  -- 해체(재생)작업이면 (-),       
            O.ProdPlanSeq, W.WorkOrderSeq, W.WorkOrderSerl,  -- 2012. 5. 21 hkim ProdPlanSeq 추가    
            '0' , WorkReportSeq      
       FROM _TPDSFCWorkReport    AS W       
      LEFT OUTER JOIN _TPDSFCWorkOrder AS O ON W.CompanySeq = O.CompanySeq   -- 2012. 5. 21 hkim ProdPlanSeq 추가 위해 작업지시 join     
             AND W.WorkOrderSeq = O.WorkOrderSeq    
             AND W.WorkOrderSerl = O.WorkOrderSerl    
      WHERE W.CompanySeq    = @CompanySeq      
        AND W.WorkReportSeq = @WorkReportSeqQry      
       
       
     -- 소요자재 가져오기      
     EXEC dbo._SPDMMGetItemNeedQty @CompanySeq       
       
 --select * from #MatNeed_GoodItem      
 -- select * from #MatNeed_MatItem_Result      
     -------------------------------      
     -- 소요량 집계 ----------------      
     INSERT #NeedMatSUM (ProcSeq,MatItemSeq,UnitSeq,NeedQty,InputQty,InputType, ItemSeq, BOMRev, AssyItemSeq,BOMSerl) -- 소요량      
     SELECT A.ProcSeq, B.MatItemSeq, B.UnitSeq, B.NeedQty, B.NeedQty, B.InputType, A.ItemSeq, A.BOMRev, A.AssyItemSeq, 9999      
       FROM #MatNeed_GoodItem            AS A      
            JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO      
       
       
       
     UPDATE #TPDSFCMatinput      
        SET InputType = B.InputType      
         FROM #TPDSFCMatinput AS A JOIN #NeedMatSUM  AS B ON A.MatItemSeq = B.MatItemSeq      
        
  -- 자재투입 수량조정에서 처리되는 건은 투입구분을 수량조정으로 업데이트 해준다 2010. 8. 18 hkim      
  IF @PgmSeq = 1023  -- 자재투입수량조정 화면에서 처리된 경우      
  BEGIN      
   UPDATE #TPDSFCMatinput      
      SET InputType = 6042007      
  END      
    
 -------------------------------------------------------------------------------------------------------------------------------------------------------------      
 -- 최종검사 재생작업(해체작업인경우 수량 - 투입으로 처리)      
  IF EXISTS (SELECt 1 FROM #TPDSFCMatinput  AS A      
         JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
         WHERE B.CompanySeq = @CompanySeq       
           AND B.WorkType   IN (6041004, 6041010) )      
  BEGIN      
   UPDATE #TPDSFCMatinput      
      SET Qty     = -Qty,      
       StdUnitQty = -StdUnitQty      
     FROM #TPDSFCMatinput  AS A      
       JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
    WHERE B.CompanySeq = @CompanySeq       
      AND B.WorkType IN (6041004, 6041010)      
  END                
       
       
     -- UPDATE          
     IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'U' AND Status = 0)        
  
     BEGIN       
       
    
         UPDATE _TPDSFCMatinput      
            SET  InputDate           = ( SELECT TOP 1 WorkDate FROM _TPDSFCWorkReport WHERE WorkReportSeq = B.WorkReportSeq  -- 2014.11.14 김용현 변경  
                                                                                        AND CompanySeq    = @CompanySeq)  ,  --B.InputDate             
                 MatItemSeq          = B.MatItemSeq          ,      
                 MatUnitSeq          = B.MatUnitSeq          ,      
                 Qty                 = B.Qty                 ,      
                 StdUnitQty          = B.StdUnitQty          ,      
                 RealLotNo           = B.RealLotNo           ,      
                 SerialNoFrom         = B.SerialNoFrom        ,      
                 ProcSeq             = B.ProcSeq             ,      
                 AssyYn              = B.AssyYn              ,      
                 IsConsign           = B.IsConsign           ,      
                 GoodItemSeq         = B.GoodItemSeq         ,      
                 InputType           = B.InputType           ,      
                 IsPaid              = B.IsPaid              ,      
                 IsPjt               = B.IsPjt               ,      
                 PjtSeq              = ISNULL(B.PjtSeq,0)    ,      
                 WBSSeq              = B.WBSSeq              ,      
                 LastUserSeq         = @UserSeq              ,      
                 LastDateTime        = GETDATE()             ,      
                 Remark              = B.Remark              ,  
     PgmSeq              = @PgmSeq  
           FROM _TPDSFCMatinput   AS A       
             JOIN #TPDSFCMatinput AS B ON A.WorkReportSeq = B.WorkReportSeq      
                                          AND A.ItemSerl = B.ItemSerl      
          WHERE B.WorkingTag = 'U'       
            AND B.Status = 0          
            AND A.CompanySeq  = @CompanySeq        
         IF @@ERROR <> 0  RETURN      
     END         
       
       
     -- INSERT      
     IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'A' AND Status = 0)        
     BEGIN        
         INSERT INTO _TPDSFCMatinput       
                    (CompanySeq      , WorkReportSeq     , ItemSerl          , InputDate             , MatItemSeq        ,       
                     MatUnitSeq      , Qty               , StdUnitQty        , RealLotNo             , SerialNoFrom      ,       
                     ProcSeq         , AssyYn            , IsConsign         , GoodItemSeq       ,       
                     InputType       , IsPaid            , IsPjt             , PjtSeq                , WBSSeq            ,      
                     LastUserSeq     , LastDateTime      , Remark            , ProdWRSeq             , PgmSeq)      
             SELECT @CompanySeq        ,A.WorkReportSeq      ,A.ItemSerl           ,( SELECT TOP 1 WorkDate FROM _TPDSFCWorkReport WHERE WorkReportSeq = A.WorkReportSeq   
                                                                                                                                     AND CompanySeq    = @CompanySeq) ,A.MatItemSeq       ,      
                     A.MatUnitSeq      , A.Qty               , A.StdUnitQty        , A.RealLotNo             , A.SerialNoFrom      ,       
                     A.ProcSeq         , A.AssyYn            , A.IsConsign         , A.GoodItemSeq       ,       
                     A.InputType       , A.IsPaid            , A.IsPjt             , ISNULL(A.PjtSeq,0)                , A.WBSSeq            ,      
                     @UserSeq           ,GETDATE()           , A.Remark            , A.ProdWRSeq              , @PgmSeq  
               FROM #TPDSFCMatinput AS A         
              WHERE A.WorkingTag = 'A' AND A.Status = 0          
         IF @@ERROR <> 0 RETURN      
     END         
    */
  -- 저장 후 수량 양수로 보여주기 위해서  수불처리시 양수로 넘어가서 주석처리      
  --UPDATE #TPDSFCMatinput      
  --   SET Qty    = ABS(Qty),      
  
  --    StdUnitQty = ABS(StdUnitQty)      
       
       
     /************ 자동출고 품목의 처리 ********************************/      
     -- 보통의 경우 자동출고를 사용할 때는 자동투입을 사용한다.       
     -- 그러나 항상 예외가 있기 때문에 수동투입에서도 자동출고가 가능해야한다.       
     -- 수불의 반영은 생산실적의 수불과 함께 처리된다.       
       
     -- #TPDSFCMatinput 에서 변경된 건만 적용하려고 했더니 자동출고품목<-> 비자동출고품목으로 변경한 경우 복잡해진다.       
     -- 그래서 투입된 전품목을 그냥 다시 만들어준다. 어차피 작업도 한번에 처리되고 수불반영도 한꺼번에 이루어지므로 이게 간편하다.       
       
     -- 프로젝트출고의 경우 자동출고품목이어도 아래 루틴을 타지 않아야한다.(2010.08.25)      
    
    

delete A
      From _TPDMMOutItem as a 
      join _TPDMMOutM as b on ( b.CompanySeq = a.CompanySeq and b.MatOutSeq = a.MatOutSeq ) 
     where a.CompanySeq = @CompanySeq 
       AND B.FactUnit = 3
       and left(b.MatOutDate,6) = '201604'
    
    
    delete From _TPDMMOutM where CompanySeq = @CompanySeq and  left(MatOutDate,6) = '201604' AND FactUnit = 3

     SELECT A.*      
       INTO #MatAutoOut      
       FROM _TPDSFCMatinput      AS A       
         JOIN _TDAItemProduct    AS P WITH(NOLOCK) ON A.MatItemSeq = P.ItemSeq      
                                                  AND A.CompanySeq  = P.CompanySeq      
         JOIN _TDAItem           AS I WITH(NOLOCK) ON A.MatItemSeq = I.ItemSeq                                                        
                                                  AND A.CompanySeq  = I.CompanySeq      
         JOIN _TDAItemAsset      AS S WITH(NOLOCK) ON A.CompanySeq = S.CompanySeq      
                                                  AND I.AssetSeq      = S.AssetSeq     
         JOIN _TPDSFCWorkReport  AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                  AND A.WorkReportSeq  = B.WorkReportSeq
      WHERE P.SMOutKind = 6005002        
        AND A.CompanySeq = @CompanySeq        
        --AND EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkReportSeq = A.WorkReportSeq)        
        AND S.SMAssetGrp <> 6008005        
        AND A.ISPJT <> '1'      
        AND B.FactUnit  = 3
        and left(A.InputDate ,6) = '201604'
    
    
    --select * from #MatAutoOut 
    --return 
    
     IF EXISTS(SELECT 1 FROM #MatAutoOut)
     BEGIN      
               
         DECLARE @MaxNo          NVARCHAR(50)    ,      
                 @FactUnit       INT             ,      
                 @Seq            INT             ,      
                 @Date           NVARCHAR(8)     ,      
                 @WorkCenterSeq  INT             ,      
                 @MatOutWHSeq    INT             ,      
                 @FieldWhSeq     INT      
       
         SELECT @EmpSeq = EmpSeq      
           FROM _TCAUser       
          WHERE CompanySeq = @CompanySeq      
            AND UserSeq = @UserSeq      
       
         SELECT @EmpSeq = ISNULL(@EmpSeq, 0 )      
       
         -- 생산실적에서 저장되면 WorkReportSeq는 하나 뿐이다.       
         -- 그러나 여러 실적건의 자재가 동시에 저장될 경우를 대비해서 Cursor를 이용한다.       
       
         DECLARE CUR_Mat CURSOR FOR      
         SELECT DISTINCT A.WorkReportSeq       
           FROM #MatAutoOut   AS A JOIN _TPDSFCWorkReport AS B ON B.CompanySeq = @CompanySeq   
                    AND A.WorkReportSeq = B.WorkReportSeq  
         -- WHERE B.WorkType NOT IN ( 6041004,6041010)  --해체작업의 경우 자동출고 데이터 생성하지 않기위해 제외시켜줌.   
       
         OPEN CUR_Mat      
       
         FETCH NEXT FROM CUR_Mat INTO @WorkReportSeq      
           WHILE (@@FETCH_STATUS = 0)      
         BEGIN      
       
             -- 자동출고품목이 있는데 출고마스터가 없으면 생성시켜줘야한다.       
             IF NOT EXISTS (SELECT 1 FROM _TPDMMOutM WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq)      
             BEGIN      
       
                 -- 키값생성코드부분 시작        
                 EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDMMOutM', 'MatOutSeq', 1      
       
                 SELECT @Seq = @Seq + 1       
       
                 SELECT  @FactUnit       = FactUnit      ,      
                         @Date           = WorkDate      ,      
                         @WorkCenterSeq  = WorkCenterSeq ,      
                         @FieldWhSeq     = FieldWhSeq      
                   FROM _TPDSFCWorkReport WITH(NOLOCK)      
                  WHERE CompanySeq = @CompanySeq      
                    AND WorkReportSeq = @WorkReportSeq      
       
       
                 SELECT @MatOutWHSeq = MatOutWhSeq      
                   FROM _TPDBaseWorkCenter WITH(NOLOCK)      
                  WHERE CompanySeq = @CompanySeq      
                    AND WorkCenterSeq = @WorkCenterSeq      
       
       
                 EXEC   dbo._SCOMCreateNo    'PD'                , -- 생산(HR/AC/SL/PD/ESM/PMS/SI/SITE)      
                                             '_TPDMMOutM'        , -- 테이블      
  
            @CompanySeq         , -- 법인코드      
                                             @FactUnit           , -- 부문코드      
                                             @Date               , -- 취득일      
                                             @MaxNo OUTPUT      
       
       
                 INSERT INTO _TPDMMOutM       
                            (CompanySeq      , MatOutSeq         , FactUnit          , MatOutNo          , MatOutDate            ,       
               UseType         , MatOutType        , IsOutSide         , OutWHSeq          , InWHSeq               ,       
                             EmpSeq          , Remark            , WorkReportSeq     , LastUserSeq       , LastDateTime          ,  
        PgmSeq)      
                     SELECT @CompanySeq      , @Seq              , @FactUnit         , @MaxNo            , @Date                 ,      
                            6044006          , 0                 , '0'               , @MatOutWHSeq      , @FieldWhSeq           ,       
                           @EmpSeq          , ''                , @WorkReportSeq    , @UserSeq          , GETDATE()             ,  
          @PgmSeq  
       
                 IF @@ERROR <> 0 RETURN      
       
             END      
       
             FETCH NEXT FROM CUR_Mat INTO @WorkReportSeq      
         END      
       
         DEALLOCATE CUR_Mat      
        
        
         -- 기 저장된 자동출고삭제      
         DELETE _TPDMMOutItem      
           FROM _TPDMMOutItem   AS A       
             JOIN _TPDMMOutM    AS M ON A.MatOutSeq = M.MatOutSeq      
                                    AND A.CompanySeq = M.CompanySeq      
             JOIN #MatAutoOut   AS B ON M.WorkReportSeq = B.WorkReportSeq      
          WHERE A.CompanySeq  = @CompanySeq      
            AND B.WorkReportSeq <> 0    
            AND M.UseType = 6044006    
                
         IF @@ERROR <> 0  RETURN      
       
       --select * from _TDASMinor where companyseq = 2 and MajorSeq = 8042 
       
         TRUNCATE TABLE #TLGInOutDailyBatch      
       
         -- 수불삭제      
         INSERT INTO #TLGInOutDailyBatch        
         SELECT DISTINCT 180, D.MatOutSeq, 0, '', 0      
           FROM _TPDMMOutM       AS D      
             JOIN #MatAutoOut    AS A ON D.WorkReportSeq = A.WorkReportSeq      
          WHERE D.CompanySeq = @CompanySeq      
            AND A.WorkReportSeq <> 0    
            AND D.UseType = 6044006    
       
         EXEC _SLGInOutDailyDELETE @CompanySeq      
       
 --        IF EXISTS(SELECT 1 FROM #TLGInOutDailyBatch)      
 --            EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
       
         UPDATE A      
            SET Result        = B.Result     ,          
                MessageType   = B.MessageType,          
                Status        = B.Status          
           FROM #TPDSFCMatinput          AS A       
             JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
             JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
          WHERE B.Status <> 0       
            AND M.CompanySeq = @CompanySeq    
       
         -- 자동출고 생성      
       
         -- Default 출고창고      
         -- : 1. 창고별 품목에 등록되어 있는 품목은 해당창고에서 가져온다.       
         -- : 2. 워크센터의 기본출고창고에서 자재를 가져온다.       
        
        
        -- 품목별 기본창고 아니면 워크센터의 출고창고.      
        CREATE TABLE #ItemWH 
        (
            WorkReportSeq   INT, 
            ItemSeq         INT, 
            OutWHSeq        INT, 
            FactUnit        INT, 
            AssetSeq        INT 
        )
        INSERT INTO #ItemWH ( WorkReportSeq, ItemSeq, OutWHSeq, FactUnit, AssetSeq ) 
        SELECT DISTINCT A.WorkReportSeq, A.MatItemSeq AS ItemSeq, ISNULL(B.OutWHSeq, M.OutWHSeq) AS OutWHSeq, M.FactUnit, D.AssetSeq 
          FROM #MatAutoOut                 AS A 
                     JOIN _TPDMMOutM       AS M ON ( A.WorkReportSeq = M.WorkReportSeq ) 
          LEFT OUTER JOIN _TDAItemStdWh    AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.MatItemSeq AND B.FactUnit = M.FactUnit ) 
          LEFT OUTER JOIN _TDAItem         AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.MatItemSeq ) 


        -- KPXCM용 사용자정의코드 불출창고 셋팅 
        UPDATE A
           SET OutWHSeq = Y.OutWHSeq 
          FROM #ItemWH AS A 
          JOIN ( 
                SELECT A.ValueSeq AS OutWHSeq, B.ValueSeq AS FactUnit, C.ValueSeq AS AssetSeq 
                  FROM _TDAUMinorValue AS A 
                  JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
                  JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = A.CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.Serl = 1000003 
                   AND A.MajorSeq = 1012905
               ) AS Y ON ( Y.AssetSeq = A.AssetSeq AND Y.FactUnit = A.FactUnit ) 


        
         INSERT INTO  _TPDMMOutItem      
                    (CompanySeq      ,MatOutSeq          ,OutItemSerl       ,ItemSeq            ,OutWHSeq           ,      
                     InWHSeq         ,UnitSeq            ,Qty                ,StdUnitQty         ,Price              ,      
                     Amt             ,ItemLotNo          ,SerialNoFrom       ,WorkOrderSeq       ,WorkOrderSerl      ,ConsgnmtCustSeq    ,      
                     Remark          ,OutReqSeq          ,OutReqItemSerl     ,PJTSeq             ,WBSSeq             ,      
                     LastUserSeq     ,LastDateTime       ,PgmSeq)      
             SELECT @CompanySeq      ,M.MatOutSeq        ,A.ItemSerl         ,A.MatItemSeq       ,ISNULL(W.OutWHSeq, 0), 
                     M.InWHSeq       ,A.MatUnitSeq       ,A.Qty              ,A.StdUnitQty       ,0                  ,      
                     0               ,A.RealLotNo        ,''                 ,R.WorkOrderSeq     ,R.WorkOrderSerl      ,0              ,  -- RealLotNo가 ''로 들어가 있어서 수정 2011. 2. 11 hkim    
                     ''              ,0                  ,0                  ,R.PjtSeq           ,R.WBSSeq                  ,      
                     @UserSeq           ,GETDATE()       ,@PgmSeq   
               FROM #MatAutoOut          AS A         
                 JOIN _TPDMMOutM         AS M ON A.WorkReportSeq = M.WorkReportSeq      
                 JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON A.WorkReportSeq = R.WorkReportSeq      
                 LEFT OUTER JOIN #ItemWH AS W ON ( W.WorkReportSeq = A.WorkReportSeq AND W.ItemSeq = A.MatItemSeq )    
             AND M.CompanySeq = R.CompanySeq      
              WHERE M.CompanySeq = @CompanySeq      
       
         EXEC _SLGInOutDailyINSERT @CompanySeq      
     END      
       
     EXEC _SLGWHStockUPDATE @CompanySeq          
     EXEC _SLGLOTStockUPDATE @CompanySeq          
       
    /*
     -- 투입취소 (WorkignTag ='D')일경우 다음 수불일괄처리 (_SLGInOutDailyBatch) 에서    
     -- 불출 창고와 현장창고 에대해서 모두 마이너스 재고체크를 하므로  여기서는 주석처리                                 -- 12.07.18 BY 김세호    
     -- (투입취소시 , 자동불출 수불발생후 여기서 마이너스재고체크를 할경우 투입수량때문에 계속 마이너스재고체크걸리므로)  
  -- 해체작업의 경우 수량을 - 출고처리하기때문에 마이너스재고체크를 제외시켜줌.  마이너스재고체크할 경우 체크에 걸리게 됨.  
     IF NOT EXISTS (SELECT 1 FROM #TPDSFCMatinput AS A JOIN _TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq      
                     WHERE B.CompanySeq = @CompanySeq       
                       AND (B.WorkType IN (6041004, 6041010)  AND A.Qty < 0  )  
                       OR  A.WorkingTag = 'D' )         
      BEGIN    
         EXEC _SLGInOutMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
         EXEC _SLGInOutLotMinusCheck @CompanySeq, '#TLGInOutDailyBatch'      
      END    
     
     UPDATE A      
        SET Result        = B.Result     ,          
            MessageType   = B.MessageType,          
            Status        = B.Status        
       FROM #TPDSFCMatinput          AS A       
         JOIN _TPDMMOutM             AS M ON A.WorkReportSeq = M.WorkReportSeq      
         JOIN #TLGInOutDailyBatch    AS B ON M.MatOutSeq = B.InOutSeq      
      WHERE B.Status <> 0       
        AND M.CompanySeq = @CompanySeq    
       
       
     ----------------------------------------------------------------------------------------------------------------------------------------  
     -- '전공정양품수량 가져오기' 사용하면서, 재공품 투입 처리 및 취소시 (수정은 화면단에서 막음) , 전공정 현장창고와 현공정 현장창고 다를경우,  
     --  이동 데이터 생성해준다( 전공정 현장창고 -> 현 공정 현장창고)       
     -- 자동투입 사용할 경우는 제외 (자동투입 사용할 경우 투입처리시 이동데이터도 안 만들어주므로)    -- 12.12.28 BY 김세호  
     ----------------------------------------------------------------------------------------------------------------------------------------  
     EXEC dbo._SCOMEnv @CompanySeq,6217,@UserSeq,@@PROCID,@Env6217 OUTPUT    -- 전공정품 가져오기 여부   
     EXEC dbo._SCOMEnv @CompanySeq,6201,@UserSeq,@@PROCID,@Env6201 OUTPUT    -- 자동투입 여부   
       
     -- '전공정양품수량', 사용하면 재공품 투입 처리 및 취소시  
     IF @Env6217  = '1' AND  
        @Env6201 <> '1' AND  
         EXISTS( SELECT 1  
                   FROM #TPDSFCMatinput AS A  
                   JOIN _TDAItem        AS B ON A.MatItemSeq = B.ItemSeq  
                                             AND B.CompanySeq = @CompanySeq  
                   JOIN _TDAItemAsset    AS C ON B.COmpanySeq = C.CompanySeq  
                                             AND B.AssetSeq = C.AssetSeq  
                  WHERE A.WorkingTag IN ('A', 'D') AND C.SMAssetGrp  = 6008005 AND A.Status = 0)  
      BEGIN  
         -- 현공정 실적 코드 가져오기          
         SELECT TOP 1 @WorkOrderSeq = R.WorkOrderSeq,   
                      @WorkOrderSerl= R.WorkOrderSerl,  
                      @WorkReportSeq = R.WorkReportSeq   
           FROM #TPDSFCMatinput      AS B  
             JOIN _TPDSFCWorkReport  AS R ON @CompanySeq     = R.CompanySeq  
                                         AND B.WorkReportSeq = R.WorkReportSeq  
          
         SELECT @EmpSeq = ISNULL(EmpSeq, 0)  
           FROM _TCAUser       
          WHERE CompanySeq = @CompanySeq      
            AND UserSeq = @UserSeq      
    
         -- 전공정 재공품  데이터 담기  
         SELECT R.AssyItemSeq                AS ItemSeq,  
                R.FieldWHSeq                 AS FieldWHSeq              
           INTO #TMP_PreProcInfo  
           FROM   _TPDSFCWorkReport  AS R   
             JOIN _TPDSFCWorkOrder   AS W ON R.WorkOrderSeq  = W.WorkOrderSeq        
                                         AND R.WorkOrderSerl = W.WorkOrderSerl        
                                         AND R.CompanySeq    = W.CompanySeq      
          WHERE R.CompanySeq     = @CompanySeq        
            AND W.WorkOrderSeq   = @WorkOrderSeq        
            AND W.IsLastProc     <> 1        
            AND W.ToProcNo IN (SELECT A.ProcNo        
                                FROM _TPDSFCWorkOrder   AS A        
                                     WHERE  @CompanySeq    = A.CompanySeq        
                                        AND @WorkOrderSeq   = A.WorkOrderSeq        
                                        AND @WorkOrderSerl  = A.WorkOrderSerl)  
          GROUP BY R.AssyItemSeq, R.FieldWHSeq  
    
         -- 이동 Sheet 데이터 담기  
         SELECT  IDENTITY(INT, 1, 1)          AS IDX_NO,                  
                 'A'                          AS WorkingTag,  
                 0                            AS Status,  
                 0                            AS Selected,  
                 0                            AS InOutSeq,  
                 0                            AS InOutSerl,  
                 80                           AS InOutType,  
                 8023008                      AS InOutKind,  
                 8012001                      AS InOutDetailKind,  
                 'DataBlock2'                 AS TABLE_NAME,  
                 A.MatItemSeq                 AS ItemSeq ,  
                 CASE WHEN A.WorkingTag = 'A' THEN A.Qty ELSE A.Qty * -1 END AS Qty,    
                 CASE WHEN A.WorkingTag = 'A' THEN A.StdUnitQty ELSE A.StdUnitQty * -1 END AS STDQty,    
                 A.MatUnitSeq                 AS UnitSeq,  
                 C.FieldWHSeq                 AS InWHSeq,  
                 B.FieldWHSeq                 AS OutWHSeq,  
                 A.InputDate                  AS Date,  
                 F.BizUnit                    AS BizUnit,  
                 C.DeptSeq                    AS DeptSeq,  
                 @EmpSeq                      AS EmpSeq,  
                 0                            AS Amt  
           INTO #TMP_TLGInOutDailyItem                   
           FROM #TPDSFCMatinput      AS A   
           JOIN #TMP_PreProcInfo     AS B ON A.MatItemSeq = B.ItemSeq  
           JOIN _TPDSFCWorkReport    AS C ON A.WorkReportSeq = C.WorkReportSeq  
                                         AND C.COmpanySeq = @CompanySeq  
           JOIN _TDAFactUnit        AS F ON C.CompanySeq    = F.CompanySeq  
                                        AND C.FactUnit = F.FactUnit  
           JOIN _TDAItem             AS I ON A.MatItemSeq   = I.ItemSeq  
                                         AND I.CompanySeq = @CompanySeq  
           JOIN _TDAItemAsset        AS S ON I.Companyseq = S.CompanySeq  
                                         AND I.AssetSeq = S.AssetSeq  
                                         AND S.SMAssetGrp = 6008005  
         WHERE A.WorkingTag IN ('A', 'D')  
           AND C.FieldWHSeq <> B.FieldWHSeq  
    
         IF @@ROWCOUNT = 0     
         BEGIN    
  
             SELECT * FROM #TPDSFCMatinput         
             RETURN      
         END    
          ELSE  
         BEGIN  
              -- 삭제일 경우 투입 삭제 수불부터 먼저 발생시킨다.  
              IF EXISTS (SELECT 1 FROM #TPDSFCMatinput WHERE WorkingTag = 'D')  
              BEGIN   
                  SELECT  A.WorkingTag            AS WorkingTag,  
                         IDENTITY(INT, 1, 1)     AS IDX_NO,  
                         0                       AS Selected,                                          
                         0                       AS Status,  
                         'DataBlock3'            AS TABLE_NAME,  
          130                     AS InOutType,  
                         8023015                 AS InOutKind,  
                         0                       AS InOutSerl,  
                         0                       AS DataKind,  
                         0                       AS InWHSeq,  
                         A.WorkReportSeq         AS InOutSeq,  
                         A.ItemSerl              AS InOutDataSerl,  
                         A.MatItemSeq            AS ItemSeq,  
                         A.MatUnitSeq            AS UnitSeq,  
                         I.UnitSeq               AS StdUnitSeq,  
                         A.QTy                   AS Qty,  
                         A.StdUnitQty            AS STDQty,  
                         6042002                 AS InOutDetailKind,  
                         B.FieldWHSeq            AS OutWHSeq                          
                   INTO #TMP_TPDSFCMatinput                                                                    
                   FROM #TPDSFCMatinput      AS A  
                   JOIN _TPDSFCWorkReport    AS B ON A.WorkReportSeq = B.WorkReportSeq  
                                                 AND B.COmpanySeq = @CompanySeq  
                   JOIN _TDAItem             AS I ON A.MatItemSeq   = I.ItemSeq  
                                                 AND I.CompanySeq = @CompanySeq  
                   JOIN _TDAItemAsset        AS S ON I.Companyseq = S.CompanySeq  
                                                 AND I.AssetSeq = S.AssetSeq  
                                                 AND S.SMAssetGrp = 6008005  
                 WHERE A.WorkingTag = 'D'  
                    
          
                 SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                             SELECT IDX_NO AS DataSeq, *       
                                                               FROM #TMP_TPDSFCMatinput      
                                                                FOR XML RAW ('DataBlock3'), ROOT('ROOT'), ELEMENTS      
                                                         ))      
    
                 CREATE TABLE #TLGInOutDailyItemSub (WorkingTag NCHAR(1) NULL)        
                 EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock3', '#TLGInOutDailyItemSub'           
                  ALTER TABLE #TLGInOutDailyItemSub ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsLot        NCHAR(1) ---- Lot관리여부    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsSerial     NCHAR(1) ---- 시리얼관리여부    
                 ALTER TABLE #TLGInOutDailyItemSub ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크    
                 ALTER TABLE #TLGInOutDailyItemSub ADD InOutDate    NCHAR(8) ----  체크    
                 ALTER TABLE #TLGInOutDailyItemSub ADD CustSeq    INT ----  체크    
                 ALTER TABLE #TLGInOutDailyItemSub ADD LastUserSeq    INT ----  체크    
                 ALTER TABLE #TLGInOutDailyItemSub ADD LastDateTime   DATETIME ----  체크    
                  INSERT INTO #TLGInOutDailyItemSub  
                 EXEC _SLGInOutDailyItemSubSave       
                      @xmlDocument  = @XmlData,      
  
                      @xmlFlags     = 2,       
                      @ServiceSeq   = 2619,      
                      @WorkingTag   = '',      
                      @CompanySeq   = @CompanySeq,      
                      @LanguageSeq  = @LanguageSeq,      
                      @UserSeq      = @UserSeq,      
                      @PgmSeq       = 1015      
                       IF @@ERROR <> 0 RETURN   
                  IF EXISTS (SELECT 1 FROM #TLGInOutDailyItemSub WHERE Status <> 0)  
                  BEGIN  
                     UPDATE #TPDSFCMatinput  
                         SET Result        = B.Result     ,    
                             MessageType   = B.MessageType,    
  Status        = B.Status  
                       FROM #TPDSFCMatinput  AS A  
                       JOIN #TLGInOutDailyItemSub AS B ON A.MatItemSeq = B.ItemSeq  
                      WHERE ISNULL(B.Status, 0) <> 0                    
                      SELECT * FROM #TPDSFCMatinput   
                     RETURN  
                  END  
               END   
               
              -- 이동 Master 데이터 담기  
             SELECT  TOP 1   'A'                          AS WorkingTag,  
                             IDENTITY(INT, 1, 1)          AS IDX_NO,                                                 
                             0                            AS Status,  
                             'DataBlock1'                 AS TABLE_NAME,               
                             1                            AS Selected,     
                             '1'                          AS IsChangedMst,       
                             0                            AS InOutSeq,  
                             A.BizUnit                    AS ReqBizUnit,  
                             ''                           AS InOutNo,  
                             80                           AS InOutType,  
                             0                            AS InOutDetailType,  
                             A.BizUnit                    AS BizUnit,  
                             '0'                          AS IsTrans,  
                             '1'                          AS IsCompleted,  
                             A.DeptSeq                    AS CompleteDeptSeq,  
                             A.EmpSeq                     AS CompleteEmpSeq,  
                             A.Date                       AS CompleteDate,  
                             A.InWHSeq                    AS InWHSeq,  
                             A.OutWHSeq                   AS OutWHSeq,  
                             A.Date                       AS InOutDate,  
                             A.DeptSeq                    AS DeptSeq,  
                             A.EmpSeq                     AS EmpSeq  
                INTO #TMP_TLGInOutDaily  
               FROM #TMP_TLGInOutDailyItem           AS A  
              ------------------------------      
             -- 이동 master XML      
             ------------------------------      
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT IDX_NO AS DataSeq, *       
                                                           FROM #TMP_TLGInOutDaily      
                                                            FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS      
                                                     ))      
    
             CREATE TABLE #LGInOutDailyCheck (WorkingTag NCHAR(1) NULL)        
             EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#LGInOutDailyCheck'           
    
             ------------------------------      
             -- 이동 master Check SP      
             ------------------------------   
             INSERT INTO #LGInOutDailyCheck  
             EXEC _SLGInOutDailyCheck       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
  
              @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317      
                   IF @@ERROR <> 0 RETURN   
              IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TMP_TLGInOutDailyItem  AS C ON A.MatItemSeq = C.ItemSeq  
                   JOIN #LGInOutDailyCheck AS B ON 1=1                    
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             -- 입출고코드 UPDATE  
             UPDATE #TMP_TLGInOutDailyItem  
                SET InOutSeq = (SELECT TOP 1 InOutSeq FROM #LGInOutDailyCheck WHERE Status = 0)  
               FROM #TMP_TLGInOutDailyItem  
              ------------------------------      
             -- 이동 Sheet XML      
             ------------------------------      
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT IDX_NO AS DataSeq, *       
                                                           FROM #TMP_TLGInOutDailyItem     
                                                            FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS      
            ))        
    
              CREATE TABLE #TLGInOutDaily (WorkingTag NCHAR(1) NULL)              
             ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDaily'    
              CREATE TABLE #TLGInOutDailyItem (WorkingTag NCHAR(1) NULL)        
             EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock2', '#TLGInOutDailyItem'   
    
             ------------------------------      
             -- 이동 Sheet Check SP      
             ------------------------------   
             INSERT INTO #TLGInOutDailyItem  
             EXEC _SLGInOutDailyItemCheck     
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317      
                   IF @@ERROR <> 0 RETURN   
    
             IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TLGInOutDailyItem AS B ON A.MatItemSeq = B.ItemSeq  
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             ------------------------------      
             -- 이동 Master Save SP      
             ------------------------------   
              SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT *       
                                                           FROM #LGInOutDailyCheck      
                                                            FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS      
                                                     ))     
    
             DELETE FROM #LGInOutDailyCheck  
              INSERT INTO #LGInOutDailyCheck  
             EXEC _SLGInOutDailySave       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317     
    
                  IF @@ERROR <> 0 RETURN             
                
             IF EXISTS (SELECT 1 FROM #LGInOutDailyCheck WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
  Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TMP_TLGInOutDailyItem  AS C ON A.MatItemSeq = C.ItemSeq  
                   JOIN #LGInOutDailyCheck AS B ON 1=1                    
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
             ------------------------------      
             -- 이동 Sheet Save SP      
             ------------------------------   
             SELECT @XmlData = CONVERT(NVARCHAR(MAX),(      
                                                         SELECT *       
                                                           FROM #TLGInOutDailyItem                                                              
                                                            FOR XML RAW ('DataBlock2'), ROOT('ROOT'), ELEMENTS      
                                                     ))     
              DELETE FROM #TLGInOutDailyItem  
              -- 입출고 Sheet저장SP 내에서 ADD해주는 칼럼 ADD 해줌   
           ALTER TABLE #TLGInOutDailyItem ADD IsStockQty   NCHAR(1) ---- 재고수량관리여부      
             ALTER TABLE #TLGInOutDailyItem ADD IsStockAmt   NCHAR(1) ---- 재고금액관리여부      
             ALTER TABLE #TLGInOutDailyItem ADD IsLot        NCHAR(1) ---- Lot관리여부      
             ALTER TABLE #TLGInOutDailyItem ADD IsSerial     NCHAR(1) ---- 시리얼관리여부      
             ALTER TABLE #TLGInOutDailyItem ADD IsItemStockCheck   NCHAR(1) ---- 품목기준재고 체크      
             ALTER TABLE #TLGInOutDailyItem ADD InOutDate    NCHAR(8) ----  체크      
             ALTER TABLE #TLGInOutDailyItem ADD CustSeq    INT ----  체크      
             ALTER TABLE #TLGInOutDailyItem ADD SalesCustSeq    INT ----  체크      
             ALTER TABLE #TLGInOutDailyItem ADD IsTrans    NCHAR(1) ----  체크   
    
             INSERT INTO #TLGInOutDailyItem  
             EXEC _SLGInOutDailyItemSave       
                  @xmlDocument  = @XmlData,      
                  @xmlFlags     = 2,      
                  @ServiceSeq   = 2619,      
                  @WorkingTag   = '',      
                  @CompanySeq   = @CompanySeq,      
                  @LanguageSeq  = @LanguageSeq,      
                  @UserSeq      = @UserSeq,      
                  @PgmSeq       = 1317     
                   IF @@ERROR <> 0 RETURN   
    
             IF EXISTS (SELECT 1 FROM #TLGInOutDailyItem WHERE Status <> 0)  
              BEGIN  
                 UPDATE #TPDSFCMatinput  
                     SET Result        = B.Result     ,    
                         MessageType   = B.MessageType,    
                         Status        = B.Status  
                   FROM #TPDSFCMatinput  AS A  
                   JOIN #TLGInOutDailyItem AS B ON A.MatItemSeq = B.ItemSeq  
                  WHERE ISNULL(B.Status, 0) <> 0                    
                       
                 SELECT * FROM #TPDSFCMatinput   
                 RETURN  
              END  
    
         END  
       
      END  
    */
     SELECT * FROM #TPDSFCMatinput         
  
     RETURN
     go
--begin tran 

exec test_SPDSFCWorkReportMatSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsPjt>0</IsPjt>
    <WBSSeq>0</WBSSeq>
    <WorkReportSeq>45334</WorkReportSeq>
    <ItemSerl>12</ItemSerl>
    <InputDate>20160430</InputDate>
    <MatItemSeq>617</MatItemSeq>
    <MatUnitSeq>9</MatUnitSeq>
    <StdUnitSeq>0</StdUnitSeq>
    <Qty>210.00000</Qty>
    <StdUnitQty>210.00000</StdUnitQty>
    <RealLotNo>1111010070</RealLotNo>
    <SerialNoFrom />
    <ProcSeq>26</ProcSeq>
    <AssyYn>0</AssyYn>
    <IsConsign>0</IsConsign>
    <GoodItemSeq>547</GoodItemSeq>
    <InputType>6042002</InputType>
    <IsPaid>0</IsPaid>
    <Remark>연동생성 투입건(투입연동)</Remark>
    <WHSeq>13</WHSeq>
    <ProdWRSeq>0</ProdWRSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2909,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1015
--rollback 
