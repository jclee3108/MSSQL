
IF OBJECT_ID('KPX_SESMGWorkReport') IS NOT NULL 
    DROP PROC KPX_SESMGWorkReport
GO 

/************************************************************      
 설  명 - _SESMGWorkReport           
 작성일 - 2008년 11월 13일      
 작성자 - 김은영  
   
 수정. -- 자재단가계산은 원가계산전 집계를 한후 처리되면 안되기 때문에 자재단가계산시   
 실적집계도 같이 되도록 한다. 단가계산은 사업부문, 회계단위이므로 이와 연결된 사업장으로  
 생산실적집계가 같이 되도록 변경한다. 09.05. Eykim   
 수정. -- 공정품별 대표공정으로 실적집계 11.03.11 sjjin
 수정. -- 손실비용처리 수량을 반영하여 손실 비용을 구하는 로직을 추가한다. 
          11.12.05 Jihlee
 수정. -- 대표공정을 사용하고, 원가계산단위가 회계단위이나  회계단위:생산사업장이 1대N일 경우, #CostUnit가 복수행이 select 되며
          이때 #CostUnit과 원가테이블(대표적으로 _TESMCProdFGoodCostResult)가 Join시 데이터 중복 집계 됨.
          그러므로 전월 _TESMCProdFGoodCostResult 데이터를 삭제하고, 다시 생성 시 돌릴때마다 데이터가 더블되는 문제가 발생함.
          원가테이블은 #CostUnit 과 Join하지 않고, Where절에 CostUnit    = @CostUnit  추가함. 2014.04.24 by khkim2
          (LOT전용 쪽의 Join은 향후 데이터 확인이 필요할 것 같아 수정하지 않은 상태임.)
 ************************************************************/      
 CREATE PROC KPX_SESMGWorkReport      
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10) = '',      
     @CompanySeq     INT = 0,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
 AS      
      -- 변수 선언      
     DECLARE @docHandle      INT,      
             @CostYM         NCHAR(6),       
             @MessageType    NVARCHAR(100) ,       
             @Status         INT ,       
             @Result         NVARCHAR(100),        
             @CostUnit       INT ,        
             @RptUnit        INT ,              
             @SMCostMng      INT ,        
             @CostMngAmdSeq  INT ,        
             @SMCostDiv      INT ,      
             @CostKeySeq     INT ,  
             @FrDate         NCHAR(8) ,   
             @ToDate         NCHAR(8) ,
             @PlanYear       NCHAR(4)
       
       
     CREATE TABLE #WorkReport (WorkingTag NCHAR(1) NULL)          
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#WorkReport'             
     IF @@ERROR <> 0 RETURN          
    
    
    -- 공수 계산 추가 by이재천
    IF @PgmSeq = 3565 
    BEGIN 
        UPDATE A
           SET A.ProcHour = A.WorkHour * ( CASE WHEN B.NeedQtyDenominator = 0 THEN 1 ELSE (B.NeedQtyNumerator/ B.NeedQtyDenominator) END )
          FROM _TPDSFCWorkReport AS A 
          LEFT OUTER JOIN KPX_TPDWorkCenterRate AS B ON ( B.CompanySeq = @CompanySeq and B.WorkCenterSeq = A.WorkCenterSeq )
         WHERE A.companyseq = @CompanySeq 
           AND LEFT(A.WorkDate,6) = (SELECT TOP 1 CostYM FROM #WorkReport)
    END 
    
    -- 공수 계산 추가, END 
    
    SELECT @CostUnit   = A.CostUnit   ,      
           @CostYM     = A.CostYM      ,      
           @CostKeySeq = A.CostKeySeq  ,       
           @SMCostMng  = A.SMCostMng   ,  
           @RptUnit    = B.RptUnit     ,
           @CostMngAmdSeq = B.CostMngAmdSeq,
           @PlanYear      = B.PlanYear
       FROM #WorkReport AS A left outer JOIN _TESMDCostKey AS B WITH(NOLOCK) ON A.CostKeySeq = B.CostKeySeq AND B.CompanySeq = @CompanySeq          
      WHERE Status = 0         
      IF @RptUnit <> 0 --보고결산이다. 보고결산을 감안해서 CostYm이 아닌 시작일, 종료일로 집계되도록한다.            
         SELECT @FrDate = FrDate ,      
                @ToDate = ToDate      
           FROM _TCRDate       
          WHERE CompanySeq = @CompanySeq       
            AND RptUnit    = @RptUnit        
            AND AccPD      = @CostYM                    
     ELSE
         SELECT @FrDate = @CostYM + '01' ,       
                @ToDate = @CostYM + '31'
     
        
     --투입중 상품이 투입되는 경우도 있으므로 상품은 삭제대상에서 제해야 함.     
     
     CREATE TABLE #Item    
     ( ItemSeq INT )     
     
     INSERT INTO #Item     
         SELECT ItemSeq     
           FROM _TDAItem AS A WITH(NOLOCK) 
                        JOIN _TDAItemAsset AS B WITH(NOLOCK) ON A.AssetSeq = B.AssetSeq     
                                                            AND A.CompanySeq = B.CompanySeq     
          WHERE A.CompanySeq = @CompanySeq      
            AND B.SMAssetGrp IN (6008001  )      
      
     
     --원가단위를 담도록 변경. 03.03      
        
     DECLARE  @ItemPriceUnit INT , @GoodPriceUnit INT , @FGoodPriceUnit INT , @FGoodCostUnit INT     ,  
              @UseCostType   INT   
        
     EXEC dbo._SCOMEnv @CompanySeq,5521,@UserSeq,@@PROCID,@ItemPriceUnit OUTPUT     --자재단가계산단위    
     EXEC dbo._SCOMEnv @CompanySeq,5523,@UserSeq,@@PROCID,@FGoodPriceUnit OUTPUT    --제품단가계산단위    
     EXEC dbo._SCOMEnv @CompanySeq,5524,@UserSeq,@@PROCID,@FGoodCostUnit OUTPUT     --제조원가계산단위      
      
      DECLARE @IsLotCost NCHAR(1) ,
             @FGoodPricType INT
        EXEC dbo._SCOMEnv @CompanySeq,5508,@UserSeq,@@PROCID,@IsLotCost OUTPUT       --개별원가사용여부
        EXEC dbo._SCOMEnv @CompanySeq,5505,@UserSeq,@@PROCID,@FGoodPricType OUTPUT     --제품단가계산설정
        
        --환경설정에서 불량수량원가처리기준 가져오기 
     DECLARE @BadCostType INT 
     EXEC dbo._SCOMEnv @CompanySeq,6233,0  /*@UserSeq*/,@@PROCID,@BadCostType OUTPUT    
      EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@UseCostType OUTPUT     --사용원가   
   
 --    SELECT 5518001 --기본원가  
   
      CREATE TABLE #CostUnit   
      ( AccUnit INT , FactUnit INT ,BizUnit INT , CostUnit INT )   
      
 --5502001 5502 생산사업장  
 --5502002 5502 회계단위  
 --5502003 5502 사업부문  
    
      IF @ItemPriceUnit = 5502003 AND @FGoodCostUnit = 5502002 --자재단가는 사업부문, 원가단가는 회계단위 일경우.   
     BEGIN   
     
         INSERT INTO #CostUnit ( AccUnit , FactUnit , BizUnit , CostUnit )    
             SELECT A.AccUnit , B.FactUnit , B.BizUnit ,  CASE @FGoodCostUnit WHEN  5502001 THEN B.FactUnit      
                                                                              WHEN  5502002 THEN A.AccUnit       
                                                                              WHEN  5502003 THEN B.BizUnit END   
               FROM _TDABizUnit AS A JOIN _TDAFactUnit AS B ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit  
              WHERE A.BizUnit    = @CostUnit   
                AND A.CompanySeq = @CompanySeq   
  
  
     END   
     ELSE IF @ItemPriceUnit = 5502003 AND @FGoodCostUnit = 5502001 --자재단가는 사업부문 , 원가단가는 사업장   
     BEGIN   
   
         INSERT INTO #CostUnit ( AccUnit , FactUnit  , BizUnit , CostUnit )    
             SELECT B.AccUnit , A.FactUnit , B.BizUnit  , CASE @FGoodCostUnit WHEN  5502001 THEN A.FactUnit      
                                                                              WHEN  5502002 THEN B.AccUnit       
                                                                              WHEN  5502003 THEN B.BizUnit END   
               FROM _TDAFactUnit AS A JOIN _TDABizUnit AS B ON A.BizUnit = B.BizUnit AND A.CompanySeq = B.CompanySeq   
              WHERE A.BizUnit = @CostUnit   
                AND A.CompanySeq = @CompanySeq   
   
     END   
     ELSE IF @ItemPriceUnit = 5502002 AND @FGoodCostUnit = 5502002 --자재단가는 회계단위 , 원가단가는 회계단위  
     BEGIN   
   
         INSERT INTO #CostUnit ( AccUnit , FactUnit , BizUnit , CostUnit  )   
             SELECT A.AccUnit , B.FactUnit , B.BizUnit , CASE @FGoodCostUnit  WHEN  5502001 THEN B.FactUnit      
                                                                              WHEN  5502002 THEN A.AccUnit       
                                                                              WHEN  5502003 THEN B.BizUnit END   
               FROM _TDABizUnit  AS A JOIN _TDAFactUnit AS B ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit   
              WHERE A.AccUnit = @CostUnit   
                AND A.CompanySeq = @CompanySeq   
   
   
     END   
     ELSE IF @ItemPriceUnit = 5502002 AND @FGoodCostUnit = 5502001 --자재단가는 회계단위 , 원가단가는 사업부문  
     BEGIN   
   
         INSERT INTO #CostUnit ( AccUnit , FactUnit, BizUnit , CostUnit )     
             SELECT A.AccUnit , B.FactUnit  , B.BizUnit  , CASE @FGoodCostUnit WHEN  5502001 THEN B.FactUnit      
                                                                               WHEN  5502002 THEN A.AccUnit       
                                                                               WHEN  5502003 THEN B.BizUnit END   
               FROM _TDABizUnit  AS A JOIN _TDAFactUnit AS B ON A.CompanySeq = B.CompanySeq AND A.BizUnit = B.BizUnit  
              WHERE A.AccUnit = @CostUnit   
                AND A.CompanySeq = @CompanySeq   
   
     END   
     
 -- 기존 데이터 삭제처리.   #CostUnit에 따라 삭제되어야한다.        
       
   DELETE _TESMGWorkReport   
       FROM _TESMGWorkReport AS A JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
        
      DELETE _TESMGMatInput     
       FROM _TESMGMatInput  AS A JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit    
             LEFT OUTER JOIN #Item AS C ON A.ItemSeq = C.ItemSeq   
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq      
         AND ISNULL(C.ItemSeq , '') = ''     
      DELETE _TESMGWorkOrderNo    
       FROM _TESMGWorkOrderNo AS A  JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit           
      WHERE A.CompanySeq   = @CompanySeq      
        AND A.CostYM       = @CostYM       
      
      DELETE _TESMGOSPDelvInItem      
        FROM _TESMGOSPDelvInItem AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit     
             LEFT OUTER JOIN #Item AS C     
                          ON A.ItemSeq = C.ItemSeq      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
         AND ISNULL(C.ItemSeq , '') = ''    
       DELETE _TESMGOSPDelvInMatInput      
        FROM _TESMGOSPDelvInMatInput AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
             LEFT OUTER JOIN #Item AS C  ON A.ItemSeq = C.ItemSeq      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
         AND ISNULL(C.ItemSeq , '') = ''     
     
     
      DELETE _TESMGGoodInSum    
        FROM _TESMGGoodInSum   AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
         
      DELETE _TESMGLotConvert    
        FROM _TESMGLotConvert   AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
        
     DELETE _TESMGWorkReportLotConv    
        FROM _TESMGWorkReportLotConv   AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq      
   
   
     DELETE _TESMGMatInputLovConv    
        FROM _TESMGMatInputLovConv   AS A   JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit      
             LEFT OUTER JOIN #Item AS C     
                          ON A.ItemSeq = C.ItemSeq      
       WHERE A.CompanySeq = @CompanySeq            
         AND A.CostKeySeq = @CostKeySeq       
         AND ISNULL(C.ItemSeq , '') = ''     
    
     DELETE _TESMCProdFProcStock        --재공수량,금액     
       FROM _TESMCProdFProcStock AS A  --JOIN #CostUnit AS B ON A.CostUnit = B.CostUnit  
      WHERE A.CostKeySeq = @CostKeySeq               
        AND A.CompanySeq = @CompanySeq   
        AND A.CostUnit = @CostUnit             
        AND A.InOutKind  = 8023032   --LOT전용건 삭제.  
      DELETE _TESMCProdFProcStockAmt        --재공수량,금액     
       FROM _TESMCProdFProcStockAmt AS A  --JOIN #CostUnit AS B ON A.CostUnit = B.CostUnit  
      WHERE A.CostKeySeq = @CostKeySeq               
        AND A.CompanySeq = @CompanySeq
        AND A.CostUnit = @CostUnit                 
        AND A.InOutKind  = 8023032   --LOT전용건 삭제.  
          
  
   /*    
  
     DELETE _TESMGWorkReport      
       WHERE CompanySeq = 14            
         AND CostKeySeq = 22        
       
     DELETE _TESMGMatInput      
       WHERE CompanySeq = 14            
         AND CostKeySeq = 22         
          
     DELETE _TESMGWorkOrderNo       
      WHERE CompanySeq   = 14      
        AND CostYM       = '200907'       
      DELETE _TESMGOSPDelvInItem      
       WHERE CompanySeq = 14            
         AND CostKeySeq = 22        
      DELETE _TESMGOSPDelvInMatInput       
       WHERE CompanySeq = 14            
         AND CostKeySeq = 22        
      DELETE _TESMGGoodInSum      
       WHERE CompanySeq = 14            
         AND CostKeySeq = 22      
     
     
 exec _SESMGWorkReport @xmlDocument=N'<ROOT><DataBlock1 WorkingTag="P" IDX_NO="6" DataSeq="1" Selected="1" Status="0" CostUnit="2" RptUnit="0" CostYM="200904" SMCostMng="5512001" CostMngAmdSeq="0" CostKeySeq="5" WorkSeq="52" StartTime="2009-04-15 11:40:33"
   
  PlanYear="    "> </DataBlock1></ROOT>',@xmlFlags=0,@ServiceSeq=3071,@WorkingTag=N'',@CompanySeq=11,@LanguageSeq=1,@UserSeq=1000,@PgmSeq=3600    
     
 */    
     
     IF @@ERROR <> 0         
     BEGIN        
        
         EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                               @Status      OUTPUT,        
                               @Result     OUTPUT,        
                               1055                  , --처리작업중 에러가 발생했습니다. 다시 처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)        
                               @LanguageSeq       ,         
                               0,''         
              
         UPDATE #WorkReport          
            SET Result        = @Result,          
                MessageType   = @MessageType,          
                Status        = @Status          
            
         SELECT * FROM #WorkReport        
           
         RETURN        
       
     END        
      DECLARE @InitYM         CHAR(6)  
     DECLARE @FrSttlYM       NCHAR(6)           
     DECLARE @StartYM        NCHAR(6)    
     DECLARE @InOutKindPre   INT , 
             @EnvValue       NVARCHAR(20),
             @PreSttlYM      NCHAR(6)    , 
             @PreYM          NCHAR(6), 
             @PreCostKeySeq  INT   
  
        --대표공정 사용여부
      DECLARE @IsFinalProcUse INT 
       EXEC dbo._SCOMEnv @CompanySeq,5567,0  /*@UserSeq*/,@@PROCID,@IsFinalProcUse OUTPUT    
         
       
     -- 환경설정에서 '물류시작월' 가져오기      
     EXEC dbo._SCOMEnv @CompanySeq,1006,0  /*@UserSeq*/,@@PROCID,@StartYM OUTPUT    
     
     SELECT  @InitYM = FrSttlYM       
       FROM  _TDAAccFiscal       
      WHERE  CompanySeq = @CompanySeq      
        AND  @StartYM BETWEEN FrSttlYM AND ToSttlYM      
      
  
     ---- 회기시작월 찾기      
     SELECT  @FrSttlYM = FrSttlYM       
       FROM  _TDAAccFiscal       
      WHERE  CompanySeq = @CompanySeq      
        AND  @CostYM BETWEEN FrSttlYM AND ToSttlYM          
  
  
     SELECT @PreYM  = CONVERT(CHAR(6),DATEADD(Month,-1, @CostYM  +'01'),112)    
     
     IF @InitYM = @FrSttlYM --처음 회계시작월이 같은경우    
     BEGIN    
      
         IF @InitYM <> @StartYM    
         BEGIN    
                 IF @CostYM = @StartYM   
                 BEGIN   
                     SELECT @PreSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,@StartYM+'01'),112)    
                     SELECT @InOutKindPre =   8023022  --기말재공        
                   
                 END   
                 ELSE   
                 BEGIN  
                     SELECT @PreSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1, @CostYM +'01'),112)    
                     SELECT @InOutKindPre =   8023022  --기말재공        
                       
                 END   
         END    
         ELSE  
         BEGIN  
             IF @CostYM = @StartYM   
             BEGIN   
                 SELECT @PreSttlYM = @InitYM  
                 SELECT @InOutKindPre =   8023000  --기말재공        
                   
             END   
             ELSE   
             BEGIN  
                 SELECT @PreSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1, @CostYM +'01'),112)    
                 SELECT @InOutKindPre =   8023022  --기말재공        
                       
             END   
         END    
             
     END     
     ELSE -- 다음 회계월일경우    
     BEGIN            
          SELECT @InOutKindPre  =  8023000     
         IF @CostYM <> @FrSttlYM   
         BEGIN  
             SELECT @PreSttlYM = CONVERT(CHAR(6),DATEADD(Month,-1,@CostYM+'01'),112)    
             SELECT @InOutKindPre =   8023022  --기말재공              
         END   
         ELSE 
         BEGIN 
             SELECT @PreSttlYM = @CostYM  
            SELECT @InOutKindPre =   8023000  --기말재공        
          END 
         
     END     
      
      SELECT @PreCostKeySeq = B.CostKeySeq  --이전월 키값.       
       FROM _TESMDCostKey AS B  WITH(NOLOCK)         
      WHERE B.CompanySeq = @CompanySeq       
        AND B.CostYM     = @PreSttlYM         
        AND B.RptUnit    = @RptUnit      
        AND B.SMCostMng  = @SMCostMng      
        AND B.CostMngAmdSeq = ISNULL(@CostMngAmdSeq , 0)      
     
     IF @IsFinalProcUse = '1' --대표공정을 사용하는 경우 
     BEGIN 
   
 -----공정품별 대표공정을 가져오기 위해 생산실적테이블에서 가져온다.(전월원가)---------------------------------------------              
     --DECLARE @PreCostYM      NCHAR(6),
     --        @PreCostKeySeq  INT
      --SELECT @PreCostYM = CONVERT(NCHAR(6), DATEADD(MONTH, -1, CONVERT(DATETIME, @CostYM + '01')), 112)
     --EXEC @PreCostKeySeq = dbo._SESMDCostKeySeq @CompanySeq,@PreCostYM ,@RptUnit,@SMCostMng,@CostMngAmdSeq,@PlanYear,@PgmSeq 
     
     SELECT A.ItemSeq, A.AssyItemSeq, A.ProcSeq, COUNT(*) AS CNT
         INTO #TESMCProdFGoodCostResult
       FROM _TESMCProdFGoodCostResult        AS A WITH(NOLOCK)
                   -- JOIN #CostUnit           AS C WITH(NOLOCK) ON A.CostUnit    = C.CostUnit
         LEFT OUTER JOIN _TESMBStdProcAsItem AS D WITH(NOLOCK) ON A.ItemSeq     = D.ItemSeq
                                                              AND A.AssyItemSeq = D.AssyItemSeq
                                                              AND A.CompanySeq  = D.CompanySeq
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.CompanySeq = @CompanySeq
        AND A.CostUnit = @CostUnit
        AND D.ItemSeq    IS NULL
      GROUP BY A.ItemSeq, A.AssyItemSeq, A.ProcSeq
      ORDER BY A.ItemSeq, A.AssyItemSeq, A.ProcSeq, COUNT(*) DESC
      ALTER TABLE #TESMCProdFGoodCostResult ADD IDX INT IDENTITY(1,1)
      IF EXISTS (SELECT 1 FROM #TESMCProdFGoodCostResult GROUP BY ItemSeq, AssyItemSeq HAVING COUNT(*) > 1)
     BEGIN 
         DELETE #TESMCProdFGoodCostResult
           FROM #TESMCProdFGoodCostResult AS A 
                 LEFT OUTER JOIN (
                                     SELECT ItemSeq, AssyItemSeq, MIN(IDX) AS IDX
                                       FROM #TESMCProdFGoodCostResult
                                      GROUP BY ItemSeq, AssyItemSeq
                                 ) AS B ON A.ItemSeq     = B.ItemSeq 
                                       AND A.AssyItemSeq = B.AssyItemSeq
          WHERE A.IDX <> B.IDX
     END
     INSERT INTO _TESMBStdProcAsItem ( CompanySeq    ,ItemSeq       ,AssyItemSeq   ,ProcSeq       ,StdCostYM     ,
                                       SMRegType     ,LastUserSeq   ,LastDateTime  ) 
         SELECT @CompanySeq, ItemSeq, AssyItemSeq, ProcSeq, @PreYM, 5029001/*원가결과테이블*/, 0, GETDATE()
           FROM #TESMCProdFGoodCostResult
 ------------------------------------------------------------------------------------------------------------------------------------
  -----공정품별 대표공정을 가져오기 위해 생산실적테이블에서 가져온다.(당월실적)---------------------------------------------  
      SELECT A.ItemSeq, A.AssyItemSeq, A.ProcSeq, SUM(CNT) AS CNT
         INTO #WorkOrder
       FROM (
                 SELECT F.GoodItemSeq AS ItemSeq, F.AssyItemSeq, F.ProcSeq, COUNT(*) AS CNT
                  FROM _TPDSFCWorkReport AS F WITH(NOLOCK)
                                JOIN #CostUnit           AS E              ON F.FactUnit      = E.FactUnit      
                                --JOIN _TPDSFCWorkReport   AS F              ON A.CompanySeq    = F.CompanySeq
                                --                                          AND A.WorkOrderSeq  = F.WorkOrderSeq   
                                --                                          AND A.WorkOrderSerl = F.WorkOrderSerl  
                     LEFT OUTER JOIN _TESMBStdProcAsItem AS D WITH(NOLOCK) ON F.GoodItemSeq   = D.ItemSeq
                    AND F.AssyItemSeq   = D.AssyItemSeq
                                                                          AND F.CompanySeq    = D.CompanySeq 
                     --LEFT OUTER JOIN _TESMGWorkOrderNo   AS G WITH(NOLOCK) ON F.WorkOrderSeq  = G.WorkOrderSeq
                     --                                                     AND F.CompanySeq    = G.CompanySeq  -- 2011. 07. 18 sjjin 수정 작업지시가 없어도 실적은 등록될 수 있으므로 주석처리
                  WHERE D.ItemSeq      IS NULL    
  AND F.WorkDate     BETWEEN @FrDate AND @ToDate     
                    --AND G.WorkOrderSeq IS NULL
                    --AND A.WorkOrderSeq NOT IN (SELECT WorkOrderSeq FROM _TESMGWorkOrderNo WHERE CompanySeq = @CompanySeq  )  
                    AND F.CompanySeq   = @CompanySeq    
                  GROUP BY F.GoodItemSeq, F.AssyItemSeq, F.ProcSeq
                 UNION ALL
                 SELECT F.ItemSeq AS ItemSeq, F.OSPAssySeq AS AssyItemSeq, F.ProcSeq, COUNT(*) AS CNT
                   FROM _TPDOSPDelvInItem AS F WITH(NOLOCK)           
                                JOIN _TPDOSPDelvIn       AS C WITH(NOLOCK) ON F.CompanySeq    = @CompanySeq 
                                                                          AND F.OSPDelvInSeq  = C.OSPDelvInSeq  
                                JOIN #CostUnit           AS E              ON C.FactUnit      = E.FactUnit      
                                --JOIN _TPDOSPDelvInItem   AS F WITH(NOLOCK) ON F.CompanySeq    = A.CompanySeq 
                                --                                          AND A.WorkOrderSeq  = F.WorkOrderSeq   
                                --                                          AND A.WorkOrderSerl = F.WorkOrderSerl    
                     LEFT OUTER JOIN _TESMBStdProcAsItem AS D WITH(NOLOCK) ON F.ItemSeq       = D.ItemSeq
                                                                          AND F.OSPAssySeq    = D.AssyItemSeq
                                                                          AND F.CompanySeq    = D.CompanySeq
                     --LEFT OUTER JOIN _TESMGWorkOrderNo   AS G WITH(NOLOCK) ON A.WorkOrderSeq  = G.WorkOrderSeq
                     --                                                     AND A.CompanySeq    = G.CompanySeq -- 2011. 07. 18 sjjin 수정 작업지시가 없어도 실적은 등록될 수 있으므로 주석처리
                  WHERE F.CompanySeq    = @CompanySeq    
                    AND C.OSPDelvInDate BETWEEN @FrDate AND @ToDate 
                    AND D.ItemSeq       IS NULL  
                    --AND G.WorkOrderSeq  IS NULL
                    --AND A.WorkOrderSeq  NOT IN (SELECT WorkOrderSeq FROM _TESMGWorkOrderNo WHERE CompanySeq = @CompanySeq  )
                 GROUP BY F.ItemSeq, F.OSPAssySeq, F.ProcSeq
             ) AS A
      GROUP BY A.ItemSeq, A.AssyItemSeq, A.ProcSeq
      ORDER BY A.ItemSeq, A.AssyItemSeq, A.ProcSeq
      --중복데이터 삭제
     ALTER TABLE #WorkOrder ADD IDX INT IDENTITY(1,1)
     IF EXISTS (SELECT 1 FROM #WorkOrder GROUP BY ItemSeq, AssyItemSeq HAVING COUNT(*) > 1)
     BEGIN 
         DELETE #WorkOrder
           FROM #WorkOrder AS A 
                 LEFT OUTER JOIN (
                                     SELECT ItemSeq, AssyItemSeq, MIN(IDX) AS IDX
                                       FROM #WorkOrder
                                      GROUP BY ItemSeq, AssyItemSeq
                                 ) AS B ON A.ItemSeq     = B.ItemSeq 
                                       AND A.AssyItemSeq = B.AssyItemSeq
          WHERE A.IDX <> B.IDX
     END
     
     --공정품별 대표공정테이블에 담는다
     INSERT INTO _TESMBStdProcAsItem ( CompanySeq    ,ItemSeq       ,AssyItemSeq   ,ProcSeq       ,StdCostYM     ,
                                       SMRegType     ,LastUserSeq   ,LastDateTime  ) 
         SELECT @CompanySeq, ItemSeq, AssyItemSeq, ProcSeq, @CostYM, 5029002/*생산실적테이블*/, @UserSeq, GETDATE()
           FROM #WorkOrder AS A
        
 -----------------------------------------------------------------------------------------------------------------------
  
 -----전월데이터 업데이트 처리-----------------------------------------------------------------------------------------  
     --백업
     DECLARE @TableName  NVARCHAR(50),
             @SQL        NVARCHAR(MAX)
              
     --SET @TableName = 'BAK'+CONVERT(NCHAR(8), GETDATE(), 112) + '_TESMCProdFProcStock'
     SET @TableName = 'BAK20110731_TESMCProdFProcStock' -- 2011.07.18 처음 돌릴때만 들어가야 하므로 임의의 날짜로 박는다.
     IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(@TableName) AND sysstat & 0xf = 3)
     BEGIN 
      SET @SQL = 'SELECT A.* INTO ' + @TableName + CHAR(13)
                  + '  FROM _TESMCProdFProcStock AS A' + CHAR(13)
                  + '        JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit' + CHAR(13)
                  + ' WHERE A.CompanySeq = @CompanySeq'    + CHAR(13)
                  + '   AND A.CostKeySeq = @PreCostKeySeq '
     
         EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq
     END
     ELSE
     BEGIN
         SET @SQL = 'IF NOT EXISTS(SELECT TOP 1 1 FROM ' + @TableName + ' AS A ' + CHAR(13)
                  + '                    JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit' + CHAR(13)
                  + '               WHERE A.CompanySeq = @CompanySeq AND A.CostKeySeq = @PreCostKeySeq)' + CHAR(13)
                  + 'BEGIN' + CHAR(13)
                  + 'INSERT INTO ' + @TableName +  CHAR(13)
                  + '(CompanySeq  ,CostKeySeq  ,CostUnit    ,ItemSeq     ,WorkOrderSeq,ProcSeq     ,AssyItemSeq ,'+ CHAR(13)
                  + 'InOutKind   ,InOut       ,Qty         ,Amt         ,DisUseQty , DisUseCost)' + CHAR(13)
                  + '    SELECT A.CompanySeq  ,A.CostKeySeq  ,A.CostUnit    ,A.ItemSeq     ,A.WorkOrderSeq,A.ProcSeq     ,A.AssyItemSeq ,'+ CHAR(13)
                  + '           A.InOutKind   ,A.InOut       ,A.Qty         ,A.Amt         ,A.DisUseQty   ,A.DisUseCost ' + CHAR(13)
                  + '      FROM _TESMCProdFProcStock AS A' + CHAR(13)
                  + '            JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit' + CHAR(13)
                  + '     WHERE A.CompanySeq = @CompanySeq' + CHAR(13)
                  + '       AND A.CostKeySeq = @PreCostKeySeq ' + CHAR(13)
                  + 'END'
          EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq
     END
     --SET @TableName = 'BAK'+CONVERT(NCHAR(8), GETDATE(), 112) + '_TESMCProdFGoodCostResult'
     SET @TableName = 'BAK20110731_TESMCProdFGoodCostResult' -- 2011.07.18 처음 돌릴때만 들어가야 하므로 임의의 날짜로 박는다.
     IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(@TableName) AND sysstat & 0xf = 3)
     BEGIN 
         SET @SQL = 'SELECT A.* INTO ' + @TableName + CHAR(13)
                  + '  FROM _TESMCProdFGoodCostResult AS A'    + CHAR(13)
                  + '        JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit'    + CHAR(13)
                  + ' WHERE A.CompanySeq = @CompanySeq' + CHAR(13)
                  + '   AND A.CostKeySeq = @PreCostKeySeq '
   
         EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq    
     END
     ELSE
     BEGIN
         SET @SQL = 'IF NOT EXISTS(SELECT TOP 1 1 FROM ' + @TableName + ' AS A ' + CHAR(13)
                  + '                    JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit' + CHAR(13)
                  + '               WHERE A.CompanySeq = @CompanySeq AND A.CostKeySeq = @PreCostKeySeq)' + CHAR(13)
                  + 'BEGIN' + CHAR(13)
                  + 'INSERT INTO ' + @TableName + '( CompanySeq  , CostUnit    , CostKeySeq  , ItemSeq     , WorkOrderSeq, AssyItemSeq , ProcSeq     , CostAccSeq  , ' + CHAR(13)
                  + '                                PreQty      , PreCost     , ProdQty     , InputCost   , RevCost     , ProdCost    , SendQty     , SendCost    , ' + CHAR(13)
                + '                                ProcQty     , ProcCost    , InQty       , RevProcCost , DisUseQty   , DisUseCost  , LotConvQty  , LotConvCost , RevDisUseCost)' + CHAR(13)
                  + '    SELECT  A.CompanySeq  , A.CostUnit    , A.CostKeySeq  , A.ItemSeq     , A.WorkOrderSeq, A.AssyItemSeq , A.ProcSeq     , A.CostAccSeq  , ' + CHAR(13)
                  + '            A.PreQty      , A.PreCost     , A.ProdQty     , A.InputCost   , A.RevCost     , A.ProdCost    , A.SendQty     , A.SendCost    , ' + CHAR(13)
                  + '            A.ProcQty     , A.ProcCost    , A.InQty       , A.RevProcCost , A.DisUseQty   , A.DisUseCost  , A.LotConvQty  , A.LotConvCost,A.RevDisUseCost ' + CHAR(13)
                  + '      FROM _TESMCProdFGoodCostResult AS A'    + CHAR(13)
                  + '            JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit'    + CHAR(13)
                  + '     WHERE A.CompanySeq = @CompanySeq' + CHAR(13)
                  + '       AND A.CostKeySeq = @PreCostKeySeq ' + CHAR(13)
                  + 'END'
          EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq    
     END
      
     --SET @TableName = 'BAK'+CONVERT(NCHAR(8), GETDATE(), 112) + '_TESMCProdFProcStockAmt'
     SET @TableName = 'BAK20110731_TESMCProdFProcStockAmt' -- 2011.07.18 처음 돌릴때만 들어가야 하므로 임의의 날짜로 박는다.
     IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(@TableName) AND sysstat & 0xf = 3)
     BEGIN 
         SET @SQL = 'SELECT A.* INTO ' + @TableName + CHAR(13)
                  + '  FROM _TESMCProdFProcStockAmt AS A'    + CHAR(13)
                  + '        JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit'    + CHAR(13)
                  + ' WHERE A.CompanySeq = @CompanySeq'    + CHAR(13)
                  + '   AND A.CostKeySeq = @PreCostKeySeq '
        
         EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq   
     END
     ELSE
     BEGIN
         SET @SQL = 'IF NOT EXISTS(SELECT TOP 1 1 FROM ' + @TableName + ' AS A ' + CHAR(13)
                  + '                    JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit' + CHAR(13)
                  + '               WHERE A.CompanySeq = @CompanySeq AND A.CostKeySeq = @PreCostKeySeq)' + CHAR(13)
                  + 'BEGIN' + CHAR(13)
                  + 'INSERT INTO ' + @TableName + '( CompanySeq  , CostKeySeq  , CostUnit    , ItemSeq     , WorkOrderSeq, AssyItemSeq , ' + CHAR(13)
                  + '                                ProcSeq     , CostAccSeq  , InOutKind   , InOut       , Qty         , Amt        ,DisUseQty,DisUseCost )' + CHAR(13)
                  + '    SELECT  A.CompanySeq  , A.CostKeySeq  , A.CostUnit    , A.ItemSeq     , A.WorkOrderSeq, A.AssyItemSeq ,' + CHAR(13)
                  + '            A.ProcSeq     , A.CostAccSeq  , A.InOutKind   , A.InOut       , A.Qty         , A.Amt        ,A.DisUseQty ,A.DisUseCost ' + CHAR(13)
                  + '      FROM _TESMCProdFProcStockAmt AS A'    + CHAR(13)
                  + '            JOIN #CostUnit AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit'    + CHAR(13)
                  + '     WHERE A.CompanySeq = @CompanySeq'    + CHAR(13)
                  + '       AND A.CostKeySeq = @PreCostKeySeq ' + CHAR(13)
                  + 'END'
          
         EXEC SP_EXECUTESQL @SQL, N'@CompanySeq INT,@PreCostKeySeq INT', @CompanySeq, @PreCostKeySeq   
     END
      
     --대표공정별로 전월재고, 재공 가져와 temp에 담기
     SELECT A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq) AS ProcSeq, A.InOut,
            SUM(A.Qty) AS Qty, SUM(A.Amt) AS Amt,ISNULL(A.DisUseQty,0) AS DisUseQty,ISNULL(SUM(A.DisUseCost),0) AS DisUseCost
       INTO #TESMCProdFProcStock
       FROM _TESMCProdFProcStock AS A WITH(NOLOCK)
                    -- JOIN #CostUnit           AS C WITH(NOLOCK) ON A.CostUnit    = C.CostUnit
          LEFT OUTER JOIN _TESMBStdProcAsItem AS B WITH(NOLOCK) ON A.ItemSeq     = B.ItemSeq
                                                               AND A.AssyItemSeq = B.AssyItemSeq
                                                               AND A.CompanySeq  = B.CompanySeq
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.InOutKind  = @InOutKindPre
        AND A.CompanySeq = @CompanySeq
        AND A.CostUnit = @CostUnit
      GROUP BY A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq), A.InOut, ISNULL(A.DisUseQty,0)
     
     SELECT A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq) AS ProcSeq, A.CostAccSeq, A.InOut,
          ISNULL(D.Qty, 0) AS Qty, SUM(A.Amt) AS Amt,ISNULL(D.DisUseQty,0) AS DisUseQty,ISNULL(SUM(D.DisUseCost),0) AS DisUseCost
       INTO #TESMCProdFProcStockAmt
       FROM _TESMCProdFProcStockAmt AS A WITH(NOLOCK)
                    -- JOIN #CostUnit            AS C WITH(NOLOCK) ON A.CostUnit     = C.CostUnit
          LEFT OUTER JOIN _TESMBStdProcAsItem  AS B WITH(NOLOCK) ON A.ItemSeq      = B.ItemSeq
                                                                AND A.AssyItemSeq  = B.AssyItemSeq
                                                                AND A.CompanySeq   = B.CompanySeq
          LEFT OUTER JOIN #TESMCProdFProcStock AS D WITH(NOLOCK) ON D.ItemSeq      = A.ItemSeq
                                                                AND D.AssyItemSeq  = A.AssyItemSeq
                                                                AND D.ProcSeq      = ISNULL(B.ProcSeq, A.ProcSeq)
                                                                AND D.CostUnit     = A.CostUnit
                                                                AND D.WorkOrderSeq = A.WorkOrderSeq
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.InOutKind  = @InOutKindPre
        AND A.CompanySeq = @CompanySeq
        AND A.CostUnit = @CostUnit
      GROUP BY A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq), A.CostAccSeq, A.InOut, D.Qty, ISNULL(D.DisUseQty,0)
      SELECT A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq) AS ProcSeq, A.CostAccSeq, 
            ISNULL(SUM(PreQty)   , 0) AS PreQty   , ISNULL(SUM(PreCost)   , 0) AS PreCost   , ISNULL(SUM(ProdQty)   , 0) AS ProdQty   , ISNULL(SUM(InputCost)  , 0) AS InputCost  , 
            ISNULL(SUM(RevCost)  , 0) AS RevCost  , ISNULL(SUM(ProdCost)  , 0) AS ProdCost  , ISNULL(SUM(SendQty)   , 0) AS SendQty   , ISNULL(SUM(SendCost)   , 0) AS SendCost   , 
            ISNULL(SUM(ProcQty)  , 0) AS ProcQty  , ISNULL(SUM(ProcCost)  , 0) AS ProcCost  , ISNULL(SUM(InQty)     , 0) AS InQty     , ISNULL(SUM(RevProcCost), 0) AS RevProcCost, 
            ISNULL(SUM(DisUseQty), 0) AS DisUseQty, ISNULL(SUM(DisUseCost), 0) AS DisUseCost, ISNULL(SUM(LotConvQty), 0) AS LotConvQty, ISNULL(SUM(LotConvCost), 0) AS LotConvCost,
            ISNULL(SUM(RevDisUseCost), 0) AS RevDisUseCost
       INTO #TESMCProdFGoodCostResult_Pre
       FROM _TESMCProdFGoodCostResult AS A WITH(NOLOCK)
                    -- JOIN #CostUnit            AS C WITH(NOLOCK) ON A.CostUnit     = C.CostUnit
          LEFT OUTER JOIN _TESMBStdProcAsItem  AS B WITH(NOLOCK) ON A.ItemSeq      = B.ItemSeq
                                                                AND A.AssyItemSeq  = B.AssyItemSeq
                                                                AND A.CompanySeq   = B.CompanySeq
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.CompanySeq = @CompanySeq
        AND A.CostUnit = @CostUnit
      GROUP BY A.CostUnit, A.ItemSeq, A.WorkOrderSeq, A.AssyItemSeq, ISNULL(B.ProcSeq, A.ProcSeq), A.CostAccSeq
      --전월데이터 삭제하기
     DELETE _TESMCProdFProcStock
       FROM _TESMCProdFProcStock AS A
                    -- JOIN #CostUnit            AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.InOutKind  = @InOutKindPre
        AND A.CompanySeq  = @CompanySeq
        AND A.CostUnit = @CostUnit
        
     DELETE _TESMCProdFProcStockAmt
       FROM _TESMCProdFProcStockAmt AS A
                   --  JOIN #CostUnit            AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.InOutKind  = @InOutKindPre
        AND A.CompanySeq  = @CompanySeq
        AND A.CostUnit = @CostUnit
      DELETE _TESMCProdFGoodCostResult
       FROM _TESMCProdFGoodCostResult AS A
                   --  JOIN #CostUnit            AS C WITH(NOLOCK) ON A.CostUnit = C.CostUnit
      WHERE A.CostKeySeq = @PreCostKeySeq
        AND A.CompanySeq  = @CompanySeq
        AND A.CostUnit = @CostUnit
     --대표공정으로 다시 넣어준다.
     INSERT INTO _TESMCProdFProcStock( CompanySeq    , CostKeySeq    , CostUnit      , ItemSeq       , WorkOrderSeq  , ProcSeq       ,
                                       AssyItemSeq   , InOutKind     , InOut         , Qty           , Amt          ,DisUseQty       ,DisUseCost  )
         SELECT @CompanySeq   , @PreCostKeySeq, CostUnit      , ItemSeq       , WorkOrderSeq  , ProcSeq       ,
                AssyItemSeq   , @InOutKindPre , InOut         , Qty           , Amt           , DisUseQty     , DisUseCost
           FROM #TESMCProdFProcStock
           
     INSERT INTO _TESMCProdFProcStockAmt( CompanySeq    , CostKeySeq    , CostUnit      , ItemSeq       , WorkOrderSeq  , AssyItemSeq   ,
                                          ProcSeq       , CostAccSeq    , InOutKind     , InOut         , Qty           , Amt          ,DisUseQty       ,DisUseCost )
         SELECT @CompanySeq   , @PreCostKeySeq, CostUnit      , ItemSeq       , WorkOrderSeq  , AssyItemSeq   ,
                ProcSeq       , CostAccSeq    , @InOutKindPre , InOut         , Qty           , Amt           , DisUseQty     , DisUseCost 
           FROM #TESMCProdFProcStockAmt
      INSERT INTO _TESMCProdFGoodCostResult( CompanySeq    , CostUnit      , CostKeySeq    , ItemSeq       , WorkOrderSeq  , AssyItemSeq   ,
                                            ProcSeq       , CostAccSeq    , PreQty        , PreCost       , ProdQty       , InputCost     ,
                                            RevCost       , ProdCost      , SendQty       , SendCost      , ProcQty       , ProcCost      ,
                                            InQty         , RevProcCost   , DisUseQty     , DisUseCost    , LotConvQty    , LotConvCost   ,
                                            RevDisUseCost )
         SELECT @CompanySeq   , CostUnit      , @PreCostKeySeq, ItemSeq       , WorkOrderSeq  , AssyItemSeq   ,
                ProcSeq       , CostAccSeq    , PreQty        , PreCost       , ProdQty       , InputCost     ,
                RevCost       , ProdCost      , SendQty       , SendCost      , ProcQty       , ProcCost      ,
                InQty         , RevProcCost   , DisUseQty     , DisUseCost    , LotConvQty    , LotConvCost    ,
                RevDisUseCost 
           FROM #TESMCProdFGoodCostResult_Pre
 -------------------------------------------------------------------------------------------------------------------------
 END 
 -----생산실적-----------------------------------------------------------------------------------------      
       
     CREATE TABLE #DeptCCtr      
     (  DeptSeq INT ,       
        CCtrSeq INT       
     )       
         
     IF @UseCostType = 5518001  
         INSERT INTO #DeptCCtr       --이런식으로 하면 부서에 여러 활동센터가 묶이는 경우 문제가 됨.(차후 수정)  
             SELECT DeptSeq, CCtrSeq       
               FROM _THROrgDeptCCtr  
              WHERE CompanySeq = @CompanySeq   
                AND (@CostYM BETWEEN BegYm AND EndYm)  
                AND IsLast = '1'  
           
 ---------------------------------------------------------------------------------------      
       
 ----작업지시번호-----------------------------------------------------------------------------------------------------      
    
     INSERT INTO _TESMGWorkOrderNo  
         (      
             WorkOrderSeq  ,   WorkOrderNo,  CompanySeq, CostYm , PJTSeq  , FactUnit , CostUnit ,  
             IsJobOrderEnd ,   JobOrderEndDate   
         )      
         SELECT DISTINCT   A.WorkOrderSeq, A.WorkOrderNo, @CompanySeq, @CostYM , A.PJTSeq   , E.FactUnit ,  
                           CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                               WHEN  5502002 THEN E.AccUnit       
                                               WHEN  5502003 THEN E.BizUnit       
                           END ,ISNULL(A.IsJobOrderEnd,'0') , ISNULL(A.JobOrderEndDate   ,'')  
           FROM _TPDSFCWorkOrder AS A    
                        JOIN #CostUnit          AS E ON A.FactUnit      = E.FactUnit      
                        JOIN _TPDSFCWorkReport  AS F ON A.CompanySeq    = F.CompanySeq
                                                    AND A.WorkOrderSeq  = F.WorkOrderSeq   
                                                    AND A.WorkOrderSerl = F.WorkOrderSerl   
          WHERE A.CompanySeq   = @CompanySeq    
            AND F.WorkDate     BETWEEN @FrDate AND @ToDate     
            AND A.WorkOrderSeq NOT IN (SELECT WorkOrderSeq FROM _TESMGWorkOrderNo WHERE CompanySeq = @CompanySeq  )      
           
   
    
     INSERT INTO _TESMGWorkOrderNo      
         (      
             WorkOrderSeq  ,   WorkOrderNo,  CompanySeq, CostYm , PJTSeq  , FactUnit , CostUnit ,  
             IsJobOrderEnd ,   JobOrderEndDate   
         )      
         SELECT DISTINCT   A.WorkOrderSeq, A.WorkOrderNo, @CompanySeq, @CostYM , A.PJTSeq   , E.FactUnit ,  
                           CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                               WHEN  5502002 THEN E.AccUnit       
                                               WHEN  5502003 THEN E.BizUnit       
                           END , ISNULL(A.IsJobOrderEnd,'0') , ISNULL(A.JobOrderEndDate   ,'')  
           FROM _TPDSFCWorkOrder AS A    JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit      
                                    JOIN _TPDOSPDelvInItem  AS F ON F.CompanySeq = A.CompanySeq 
                                                                AND A.WorkOrderSeq = F.WorkOrderSeq   
                                                                AND A.WorkOrderSerl = F.WorkOrderSerl   
                                    JOIN _TPDOSPDelvIn      AS C ON F.CompanySeq = @CompanySeq 
                                                                AND F.OSPDelvInSeq = C.OSPDelvInSeq       
          WHERE A.CompanySeq    = @CompanySeq    
            AND C.OSPDelvInDate BETWEEN @FrDate AND @ToDate     
            AND A.WorkOrderSeq  NOT IN (SELECT WorkOrderSeq FROM _TESMGWorkOrderNo WHERE CompanySeq = @CompanySeq  )      
    
  --동성진흥 : 기초입력 되었는데 당월 생산이 없어서 누락되는 작업지시번호가 있음 2014.3.28 정연아
      INSERT INTO _TESMGWorkOrderNo      
          (      
              WorkOrderSeq  ,   WorkOrderNo,  CompanySeq, CostYm , PJTSeq  , FactUnit , CostUnit ,  
              IsJobOrderEnd ,   JobOrderEndDate   
          )      
          SELECT DISTINCT  A.WorkOrderSeq, A.WorkOrderNo, @CompanySeq, @CostYM , A.PJTSeq   , E.FactUnit ,  
                            CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                WHEN  5502002 THEN E.AccUnit       
                WHEN  5502003 THEN E.BizUnit       
                            END , ISNULL(A.IsJobOrderEnd,'0') , ISNULL(A.JobOrderEndDate   ,'')  
            FROM _TPDSFCWorkOrder AS A    JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit      
                                     JOIN _TESMCProdFProcStock  AS F ON F.CompanySeq = A.CompanySeq 
                                                                 AND A.WorkOrderSeq = F.WorkOrderSeq 
                                                                 AND F.CostKeySeq = @CostKeySeq                 
            --JOIN _TPDSFCWorkOrder  AS G ON G.CompanySeq = A.CompanySeq 
                                     --                            AND F.WorkOrderSeq = G.WorkOrderSeq   
           WHERE A.CompanySeq    = @CompanySeq    
             AND A.WorkOrderSeq  NOT IN (SELECT WorkOrderSeq FROM _TESMGWorkOrderNo WHERE CompanySeq = @CompanySeq  )   
 ----LOT전용건 정리 -----------------------------------------------------------------------------------------------------------  
     
     CREATE TABLE #_TESMGLotConvert  
     ( CompanySeq    INT NOT NULL ,   
       ConvertSeq    INT NOT NULL ,   
       CostKeySeq    INT NOT NULL ,   
       CostUnit      INT NOT NULL ,   
       ItemSeq       INT NOT NULL ,   
       WorkOrderSeq  INT NOT NULL ,   
       WorkOrderSerl INT NOT NULL ,   
       AssyItemSeq   INT NOT NULL ,  
       ProcSeq       INT NOT NULL ,  
       ConvItemSeq    INT NOT NULL ,  
       ConvWorkOrderSeq  INT NOT NULL ,  
       ConvWorkOrderSerl INT NOT NULL ,  
       ConvAssyItemSeq  INT NOT NULL ,   
       ConvProcSeq      INT NOT NULL ,   
       ConvQty          INT NOT NULL ,  
       FactUnit         INT NOT NULL ,  
       WorkReportSeq    INT NOT NULL ,   
       ConvWorkReportSeq    INT NOT NULL ,   
       IsDirConvert      NCHAR(1) ,  
       Seq              INT IDENTITY, 
       IsPreProc         NCHAR(1)  
     )     
  
     ---1. 당월실적 LOT전용건. 
  
     INSERT INTO #_TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                   AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                   ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert , 
                                   IsPreProc )   
     SELECT @CompanySeq  , 0  , @CostKeySeq ,  CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                   WHEN  5502002 THEN E.AccUnit       
                                                                   WHEN  5502003 THEN E.BizUnit      END ,    
            B.GoodItemSeq  , B.WorkOrderSeq , B.WorkOrderSerl ,    
            B.AssyItemSeq  , B.ProcSeq      , C.GoodItemSeq , C.WorkOrderSeq , C.WorkOrderSerl , C.AssyItemSeq ,  
            C.ProcSeq      , A.ConvQty      , A.FactUnit    ,   
             --CASE WHEN A.WorkReportSeq <> 0 THEN A.WorkReportSeq ELSE   F.WorkReportSeq END ,   
            F.WorkReportSeq,   
            G.WorkReportSeq,     
     --       CASE WHEN A.WorkReportSeq <> 0 THEN  '1' ELSE '0' END , --★ 05.14 지해 : 원천 대체 건의 표시를 바꾼다.
            CASE WHEN H.ConvertSeq IS NULL THEN '0' ELSE '1' END ,
            '0'   
       FROM _TPDSFCLotConv AS A 
                    JOIN _TPDSFCWorkOrder     AS B ON A.WorkOrderSeq      = B.WorkOrderSeq   
                                                  AND A.WorkOrderSerl     = B.WorkOrderSerl   
                                                  AND A.CompanySeq        = B.CompanySeq   
                    JOIN _TPDSFCWorkOrder     AS C ON A.ConvWorkOrderSeq  = C.WorkOrderSeq   
                                                  AND A.ConvWorkOrderSerl = C.WorkOrderSerl   
                                                  AND A.CompanySeq        = C.CompanySeq   
                    JOIN _TESMGWorkOrderNo    AS D ON A.WorkOrderSeq      = D.WorkOrderSeq   
                                                  AND A.CompanySeq        = D.CompanySeq   
                    JOIN #CostUnit            AS E ON A.FactUnit          = E.FactUnit         
                    JOIN ( SELECT   A.WorkOrderSeq , A.WorkOrderSerl , MAX(  A.WorkReportSeq  ) AS WorkReportSeq    
                             FROM _TPDSFCWorkReport AS A  JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit       
                                                          JOIN _TPDSFCLotConv     AS B ON A.CompanySeq = B.CompanySeq
                                                                              AND A.WorkOrderSeq = B.WorkOrderSeq   
                                                                                      AND A.WorkOrderSerl = B.WorkOrderSerl  
                            WHERE A.CompanySeq = @CompanySeq      
                              AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                              AND A.ChainGoodsSeq = 0      
                            GROUP BY  A.WorkOrderSeq , A.WorkOrderSerl    
                          ) AS F ON A.WorkOrderSeq = f.WorkOrderSeq AND A.WorkOrderSerl = F.WorkOrderSerl     
                    JOIN ( SELECT   A.WorkOrderSeq , A.WorkOrderSerl , MAX(A.WorkReportSeq ) AS WorkReportSeq    
                           FROM _TPDSFCWorkReport AS A  JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit       
                                                        JOIN _TPDSFCLotConv     AS B ON  A.CompanySeq = B.CompanySeq
                                                                                    AND A.WorkOrderSeq = B.ConvWorkOrderSeq   
                                                                                    AND A.WorkOrderSerl = B.ConvWorkOrderSerl  
                           WHERE A.CompanySeq = @CompanySeq      
                             AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                             AND A.ChainGoodsSeq = 0      
                           GROUP BY  A.WorkOrderSeq , A.WorkOrderSerl    
                         ) AS G                    ON C.WorkOrderSeq      = G.WorkOrderSeq 
                                                  AND C.WorkOrderSerl     = G.WorkOrderSerl     
          LEFT OUTER JOIN _TPDSFCLotConv      AS H ON A.CompanySeq        = H.CompanySeq    
                                                  AND A.ConvertSeq        = H.ConvertSeq
                                                  AND H.ConvertSeq        = H.UpperConvSeq      
         WHERE A.CompanySeq = @CompanySeq    
           AND A.ConvDate BETWEEN @FrDate AND @ToDate     
  
      ---2. 실적생성 화면에서 당월건 기준이 되는 
      INSERT INTO #_TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                    AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                    ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert ,
                                    IsPreProc  ) 
         SELECT @CompanySeq ,  0 , @CostKeySeq  , CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                      WHEN  5502002 THEN E.AccUnit       
                                                                      WHEN  5502003 THEN E.BizUnit   END ,  
                A.ItemSeq      , A.WorkOrderSeq , 0 , A.AssyItemSeq  , A.ProcSeq      , 
                A.ConvItemSeq  , A.ConvWorkOrderSeq , 0              , 
                A.ConvAssyItemSeq , A.ProcSeq       , A.ConvQty      , A.FactUnit     ,      
                0, 0, '2', '1'   
           FROM _TESMCLotChangeSub AS A WITH(NOLOCK) 
                               JOIN #CostUnit         AS E              ON A.FactUnit          = E.FactUnit   
          WHERE A.ConvDate BETWEEN @FrDate AND @ToDate    
            AND A.CompanySeq= @CompanySeq  
            AND A.IsPreProc ='1'   --전월건이 투입된것만. 
                  
  
  
     ---2. 전월재공 LOT전용건 
      INSERT INTO #_TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                   AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                   ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert ,
                                   IsPreProc  
           )   
         SELECT @CompanySeq  , 0  , @CostKeySeq ,  CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                       WHEN  5502002 THEN E.AccUnit       
                                                                       WHEN  5502003 THEN E.BizUnit      END ,    
                B.GoodItemSeq  , B.WorkOrderSeq , B.WorkOrderSerl ,    
                B.AssyItemSeq  , B.ProcSeq      , C.GoodItemSeq , C.WorkOrderSeq , C.WorkOrderSerl , C.AssyItemSeq ,  
                C.ProcSeq      , A.ConvQty      , A.FactUnit    ,      
                0,   --전월이므로 F.WorkReportSeq는 0임. 
                G.WorkReportSeq,     
         --       CASE WHEN A.WorkReportSeq <> 0 THEN  '1' ELSE '0' END , --★ 05.14 지해 : 원천 대체 건의 표시를 바꾼다.
                 CASE WHEN H.ConvertSeq IS NULL THEN '0' ELSE '1' END ,
                '1'   
           FROM _TPDSFCLotConv AS A 
                        JOIN _TPDSFCWorkOrder   AS B ON A.WorkOrderSeq  = B.WorkOrderSeq   
                                             AND A.WorkOrderSerl = B.WorkOrderSerl   
                                                    AND A.CompanySeq    = B.CompanySeq   
                        JOIN _TPDSFCWorkOrder   AS C ON A.ConvWorkOrderSeq  = C.WorkOrderSeq   
                                                    AND A.ConvWorkOrderSerl = C.WorkOrderSerl   
                                                    AND A.CompanySeq        = C.CompanySeq   
                        JOIN _TESMGWorkOrderNo  AS D ON A.WorkOrderSeq  = D.WorkOrderSeq   
                                                    AND A.CompanySeq    = D.CompanySeq   
                        JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
           
                        JOIN ( SELECT   A.WorkOrderSeq , A.WorkOrderSerl , MAX(A.WorkReportSeq ) AS WorkReportSeq    
                               FROM _TPDSFCWorkReport AS A  JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit       
                                                            JOIN _TPDSFCLotConv     AS B ON A.CompanySeq = B.CompanySeq
                                                                                        AND A.WorkOrderSeq = B.ConvWorkOrderSeq   
                                                                                        AND A.WorkOrderSerl = B.ConvWorkOrderSerl  
                               WHERE A.CompanySeq = @CompanySeq      
                                 AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                                 AND A.ChainGoodsSeq = 0      
                               GROUP BY  A.WorkOrderSeq , A.WorkOrderSerl    
                             ) AS G ON C.WorkOrderSeq = G.WorkOrderSeq AND C.WorkOrderSerl = G.WorkOrderSerl     
             LEFT OUTER JOIN ( SELECT   A.WorkOrderSeq , A.WorkOrderSerl , MAX(  A.WorkReportSeq  ) AS WorkReportSeq    
                                 FROM _TPDSFCWorkReport AS A  JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit       
                                                              JOIN _TPDSFCLotConv     AS B ON A.CompanySeq = B.CompanySeq
                                                                                          AND A.WorkOrderSeq = B.WorkOrderSeq   
                                                                                          AND A.WorkOrderSerl = B.WorkOrderSerl  
                                 WHERE A.CompanySeq = @CompanySeq      
                                   AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                                   AND A.ChainGoodsSeq = 0      
                                 GROUP BY  A.WorkOrderSeq , A.WorkOrderSerl    
                              ) AS F ON A.WorkOrderSeq = f.WorkOrderSeq AND A.WorkOrderSerl = F.WorkOrderSerl     
             LEFT OUTER JOIN _TPDSFCLotConv     AS H ON H.ConvertSeq = H.UpperConvSeq                            
         AND A.ConvertSeq = H.ConvertSeq
                                                    AND A.CompanySeq = H.CompanySeq 
             WHERE A.CompanySeq = @CompanySeq    
               AND A.ConvDate BETWEEN @FrDate AND @ToDate     
               AND ISNULL(F.WorkOrderSeq , 0) = 0  --당월이 아닌경우. 
    
      --3. 생산Lot전용_실적생성에서 전월여부가 '1' 인 것 담기 2010.11.09 sjjin 추가
      IF EXISTS(SELECT 1 FROM _TESMCLotChangeConfirm AS A WITH(NOLOCK)
                         JOIN #CostUnit AS B ON A.FactUnit = B.FactUnit   
                WHERE A.ConvertYM = @CostYM AND A.CompanySeq = @CompanySeq AND IsConFirm = '1')
     BEGIN
         INSERT INTO #_TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                   AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                   ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert ,
                                   IsPreProc  
                                 )    
             SELECT @CompanySeq    , 0              , @CostKeySeq     , CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                                            WHEN  5502002 THEN E.AccUnit       
                                                                                            WHEN  5502003 THEN E.BizUnit   END ,  
                    B.GoodItemSeq  , B.WorkOrderSeq , B.WorkOrderSerl , B.AssyItemSeq  , B.ProcSeq      , 
                    C.GoodItemSeq  , C.WorkOrderSeq , C.WorkOrderSerl , 
                    CASE WHEN B.AssyItemSeq <> C.AssyItemSeq THEN B.AssyItemSeq ELSE C.AssyItemSeq END , C.ProcSeq      , A.ConvQty       , A.FactUnit     ,      
                    0, 0, '0', '1'   
               FROM _TESMCLotChange AS A WITH(NOLOCK) 
                              JOIN _TPDSFCWorkOrder  AS B WITH(NOLOCK) ON A.WorkOrderSeq      = B.WorkOrderSeq   
                                                                      AND A.WorkOrderSerl     = B.WorkOrderSerl   
                                                                      AND A.CompanySeq        = B.CompanySeq   
                              JOIN _TPDSFCWorkOrder  AS C WITH(NOLOCK) ON A.ConvWorkOrderSeq  = C.WorkOrderSeq   
                                                                      AND A.ConvWorkOrderSerl = C.WorkOrderSerl   
                                                                      AND A.CompanySeq        = C.CompanySeq   
                              JOIN _TESMGWorkOrderNo AS D WITH(NOLOCK) ON A.WorkOrderSeq      = D.WorkOrderSeq   
                                                                      AND A.CompanySeq        = D.CompanySeq  
                              JOIN #CostUnit         AS E              ON A.FactUnit          = E.FactUnit   
              WHERE A.ConvDate BETWEEN @FrDate AND @ToDate   
                AND A.IsPreProc = '1' 
                AND A.CompanySeq= @CompanySeq  
                AND ( B.GoodItemSeq <> C.GoodItemSeq  OR B.AssyItemSeq <> C.AssyItemSeq OR B.ProcSeq <> C.ProcSeq  )
     END   
  
      --4. 기초재공전용등록에서 등록한 것들중 확정처리가 된 것 담기 2010.11.09 sjjin 추가
     INSERT INTO #_TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                    AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                    ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert ,
                                    IsPreProc  
                                  )    
         SELECT @CompanySeq    , 0              , @CostKeySeq     , CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                                        WHEN  5502002 THEN E.AccUnit       
                                                                                        WHEN  5502003 THEN E.BizUnit   END ,  
                A.ItemSeq      , 0              , 0               , A.AssyItemSeq  , A.ProcSeq      , C.GoodItemSeq , C.WorkOrderSeq , MAX(C.WorkOrderSerl) , 
                 CASE WHEN A.AssyItemSeq <> C.AssyItemSeq THEN A.AssyItemSeq ELSE C.AssyItemSeq END 
              , C.ProcSeq      , A.TransQty      , E.FactUnit     ,      
                0, 0, '0', '1'   
           FROM _TESMCProdPreAssyTrans AS A WITH(NOLOCK) 
                          JOIN _TPDSFCWorkOrder  AS C WITH(NOLOCK) ON A.TransInWorkOrderSeq  = C.WorkOrderSeq   
                                                                  AND A.TransInItemSeq       = C.GoodItemSeq   
                                                                  AND A.TransInAssyItemSeq   = C.AssyItemSeq   
                                                                  AND A.TransInProcSeq       = C.ProcSeq   
                                                                  AND A.ProcRev              = C.ProcRev   
                AND A.CompanySeq           = C.CompanySeq   
                          JOIN #CostUnit         AS E              ON A.CostUnit             = E.CostUnit   
          WHERE A.CostKeySeq = @CostKeySeq
            AND A.IsConfirm  = '1' 
            AND A.CompanySeq = @CompanySeq  
            AND (  A.ItemSeq <> C.GoodItemSeq  OR A.AssyItemSeq <> C.AssyItemSeq OR A.ProcSeq <> C.ProcSeq  )
          GROUP BY CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit WHEN  5502002 THEN E.AccUnit  WHEN  5502003 THEN E.BizUnit   END ,  
                        A.ItemSeq , A.AssyItemSeq, A.ProcSeq, C.GoodItemSeq , C.WorkOrderSeq , C.ProcSeq, A.TransQty, E.FactUnit , C.AssyItemSeq
   
      DECLARE @Count INT , @Seq INT   
    
    
     SELECT @Count = COUNT(1) FROM #_TESMGLotConvert   
     IF @Count > 0  
     BEGIN    
   
         -- 키값생성코드부분 시작    
         EXEC @Seq = dbo._SCOMCreateSeq 1, '_TESMGLotConvert', 'ConvertSeq', @Count  
   
         -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #_TESMGLotConvert  
            SET ConvertSeq = @Seq + Seq  
   
     
   
     END     
  
 /*
 select * into ##_TESMGLotConvert From #_TESMGLotConvert 
  select * From _TESMGLotConvert where    costkeyseq = 188 
 and itemseq = 9472 and 
 assyitemseq = 19701 and costkeyseq = 188
  
 select * From ##_TESMGLotConvert 
 order by itemseq 
 a join ##_TESMGLotConvert b on a.itemseq = b.itemseq and a.assy
 */
  
  
  
         INSERT INTO _TESMGLotConvert( CompanySeq , ConvertSeq , CostKeySeq , CostUnit , ItemSeq , WorkOrderSeq , WorkOrderSerl ,   
                                       AssyItemSeq , ProcSeq , ConvItemSeq , ConvWorkOrderSeq , ConvWorkOrderSerl, ConvAssyItemSeq ,  
                                       ConvProcSeq , ConvQty , FactUnit    , WorkReportSeq    , ConvWorkReportSeq, IsDirConvert ,
                                       IsPreProc  
                                     )   
         SELECT A.CompanySeq , A.ConvertSeq , A.CostKeySeq , A.CostUnit , A.ItemSeq , A.WorkOrderSeq , A.WorkOrderSerl ,   
                               A.AssyItemSeq , ISNULL(Y.ProcSeq, A.ProcSeq) , A.ConvItemSeq , A.ConvWorkOrderSeq , A.ConvWorkOrderSerl, A.ConvAssyItemSeq ,  
                               ISNULL(Z.ProcSeq, A.ConvProcSeq) , A.ConvQty , A.FactUnit    , A.WorkReportSeq    , A.ConvWorkReportSeq , IsDirConvert   ,
                               A.IsPreProc 
          FROM #_TESMGLotConvert AS A
                        LEFT OUTER JOIN _TESMBStdProcAsItem AS Y WITH(NOLOCK) ON A.ItemSeq         = Y.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                             AND A.AssyItemSeq     = Y.AssyItemSeq
                                                                             AND A.CompanySeq      = Y.CompanySeq   
                    LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.ConvItemSeq     = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                             AND A.ConvAssyItemSeq = Z.AssyItemSeq
                                                                             AND A.CompanySeq      = Z.CompanySeq   
    
  
  
 --INSERT INTO _TESMGWorkReport      
 --          (      
 --                   CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
 --                   WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
 --                   ProdQty, OKQty,  BadQty,        
 --                   ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
 --                   ProcSeq , BizUnit , CostUnit    , IsLotConvert   
 --           )       
 --    SELECT  @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
 --            A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
 --            C.CCtrSeq ,        
 --            A.StdUnitProdQty,  A.StdUnitOKQty,A.StdUnitBadQty,       
 --            A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
 --            A.ProcSeq , E.BizUnit ,       
 --               CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
 --                                   WHEN  5502002 THEN E.AccUnit       
 --                                   WHEN  5502003 THEN E.BizUnit       
 --               END   , '0'                                    
 --      FROM _TPDSFCWorkReport AS A  JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq and C.CompanySeq = @CompanySeq      
 --                                  JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
 --                                  LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq      
 --      WHERE A.CompanySeq = @CompanySeq      
 --        AND A.WorkDate BETWEEN @FrDate AND @ToDate   
 --        AND A.ChainGoodsSeq = 0      
 --         
   
 --LOT전용으로 인해 실적 -   
   
 --Alter TAble _TESMGWorkReport   
 --ADD IsLotConvert NCHAR(1)   
   
   
 --SELECT * INTO ##CostUnit  
 --FROM #CostUnit   
 --  
 --SELECT * INTO _TESMGWorkReportLotConv  
 ----FROM _TESMGWorkReport  
 --WHERE IsLotConvert = '1'   
      
 --  
 --SELECT * fROM _TESMGWorkReportLotConv WHERE ITEMSEQ = 12 AND ASSYITEMSEQ = 603  
 --SELECT * fROM _TESMGLotConvert WHERE CONVITEMSEQ = 12   
   
    
 --LOT전용으로 인한 원천 데이터 , 그리고 - 데이터, + 데이터를 담아둔다.   
   
     --1. Lot전용전 원천데이터  
     --ALTER TABLE _TESMGWorkReportLotConv   
     --ADD IsDirConvert NCHAR(1)   
    
     
     INSERT INTO _TESMGWorkReportLotConv      
               (      
                        CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
                        WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
                        ProdQty, OKQty,  BadQty,        
                        ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
                        ProcSeq , BizUnit , CostUnit , DataKind  , IsDirConvert      
                )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                 A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
                 C.CCtrSeq ,        
                 A.StdUnitProdQty   ,   A.StdUnitOKQty   ,  A.StdUnitBadQty ,              
                 A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
                 ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                 CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                       WHEN  5502002 THEN E.AccUnit       
                                     WHEN  5502003 THEN E.BizUnit       
                 END , '0' , --원천데이터   
                 B.IsDirConvert    
           FROM _TPDSFCWorkReport AS A  JOIN ( SELECT B.WorkReportSeq , SUM(B.ConvQty )  as ConvQty, B.IsDirConvert  
                                                 FROM _TESMGLotConvert AS  B  JOIN #CostUnit AS E ON B.FactUnit = E.FactUnit   
                                                  WHERE B.CompanySeq= @CompanySeq  
                                                    AND B.CostKeySeq= @CostKeySeq   
                                                    AND ISNULL(B.IsPreProc , '0')  = '0'  
                                                 GROUP BY B.WorkReportSeq , B.IsDirConvert  
                                             ) AS B ON A.WorkReportSeq = B.WorkReportSeq    
                                       JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq and C.CompanySeq = @CompanySeq      
                                       JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                            LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq  
                            LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                                 AND A.AssyItemSeq = Z.AssyItemSeq
                                                                                 AND A.CompanySeq = Z.CompanySeq      
           WHERE A.CompanySeq = @CompanySeq      
             AND A.WorkDate BETWEEN @FrDate AND @ToDate   
             AND A.ChainGoodsSeq = 0      
   
  
     ---Lot전용실적생성에서 당월건일 경우 
      INSERT INTO _TESMGWorkReportLotConv      
               (      
                        CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
                        WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
                        ProdQty, OKQty,  BadQty,        
                        ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
                        ProcSeq , BizUnit , CostUnit , DataKind  , IsDirConvert      
                )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                 A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
                 C.CCtrSeq ,        
                 A.StdUnitProdQty   ,   A.StdUnitOKQty   ,  A.StdUnitBadQty ,              
                 A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
                 ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                 CASE @FGoodCostUnit    WHEN  5502001 THEN E.FactUnit      
                                        WHEN  5502002 THEN E.AccUnit       
                                        WHEN  5502003 THEN E.BizUnit       
                 END , '0' , --원천데이터   
                 B.IsDirConvert    
           FROM _TPDSFCWorkReport AS A  JOIN ( SELECT B.WorkReportSeq , SUM(B.ConvQty )  as ConvQty, B.IsDirConvert  
                                                 FROM _TESMGLotConvert AS  B  JOIN #CostUnit AS E ON B.FactUnit = E.FactUnit   
                                                  WHERE B.CompanySeq= @CompanySeq  
                                                    AND B.CostKeySeq= @CostKeySeq   
                                                    AND ISNULL(B.IsPreProc , '0')  = '0'  
                                                 GROUP BY B.WorkReportSeq , B.IsDirConvert  
                                             ) AS B ON A.WorkReportSeq = B.WorkReportSeq    
                                       JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq and C.CompanySeq = @CompanySeq      
                                       JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                            LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq     
                            LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                                 AND A.AssyItemSeq = Z.AssyItemSeq
                                                                                 AND A.CompanySeq = Z.CompanySeq       
           WHERE A.CompanySeq = @CompanySeq      
             AND A.WorkDate BETWEEN @FrDate AND @ToDate   
             AND A.ChainGoodsSeq = 0      
                 
      --2. Lot전용으로 인한 - 실적 
      --1) 당월실적이 있는경우.  
      
     INSERT INTO _TESMGWorkReportLotConv      
         (      
             CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
             WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
             ProdQty, OKQty,  BadQty,        
             ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
             ProcSeq , BizUnit , CostUnit , DataKind  , IsDirConvert , IsPreProc   
          )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                 A.WorkCenterSeq, A.ItemSeq, A.ProcRev , A.AssyItemSeq,       
                 A.CCtrSeq ,        
                 B.ConvQty* -1 ,  B.ConvQty * -1 , 0 ,       
                 A.ManHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
                 ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                 A.CostUnit, '1' , -- LOT 전용 -    
                 B.IsDirConvert   , '0'  
           FROM _TESMGWorkReportLotConv AS A  JOIN ( SELECT B.WorkReportSeq , SUM(B.ConvQty ) as ConvQty , B.IsDirConvert  
                                                       FROM _TESMGLotConvert AS  B  
                                                            JOIN #CostUnit   AS E ON B.FactUnit = E.FactUnit   
                                                      WHERE B.CompanySeq= @CompanySeq  
                                                        AND B.CostKeySeq= @CostKeySeq   
                                                      GROUP BY B.WorkReportSeq , B.IsDirConvert   
                                             ) AS B ON A.WorkReportSeq = B.WorkReportSeq    
                                       JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                            LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.ItemSeq     = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                                 AND A.AssyItemSeq = Z.AssyItemSeq
                                                                                 AND A.CompanySeq  = Z.CompanySeq    
            WHERE A.CompanySeq = @CompanySeq      
             AND A.CostKeySeq = @CostKeySeq   
   
   
     --2) 당월실적이 아닌 전월의 재공에서 -인경우. 
         --전월재공에서 - 처리 
  
      CREATE TABLE #LotConvert
     ( CostUnit INT , 
       ItemSeq INT , 
       WorkOrderSeq INT , 
       ProcSeq INT , 
       AssyItemSeq INT , 
       ConvQty DECIMAL(19, 5) 
     )
      INSERT INTO  #LotConvert
         SELECT CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                    WHEN  5502002 THEN E.AccUnit       
                                    WHEN  5502003 THEN E.BizUnit END ,
                ItemSeq , 0 , ProcSeq , AssyItemSeq , SUM(ConvQty) 
           FROM _TESMGLotConvert A JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit 
                                      
          WHERE A.CompanySeq = @CompanySeq      
            AND A.CostKeySeq = @CostKeySeq   
            AND ISNULL(A.IsPreProc , '0')  = '1'  
          GROUP BY  ItemSeq ,   ProcSeq , AssyItemSeq , E.FactUnit , E.AccUnit, E.BizUnit
  
   
  
     --전월재공수량에서 LOT전용 건 -  
     INSERT INTO _TESMCProdFProcStock      
         (      
             CompanySeq, CostKeySeq ,  CostUnit, ItemSeq  , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             InOutKind , InOut , Qty , Amt     , DisUseQty, DisUseCost
         )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , A.CostUnit ,  
                 A.ItemSeq , 0 /*A.WorkOrderSeq */ , A.ProcSeq , A.AssyItemSeq , 8023032 , -1 , SUM(A.ConvQty)   , 0  , 0, 0
           FROM #LotConvert AS A  
                        JOIN _TESMCProdFProcStock AS B ON B.CompanySeq  = @CompanySeq 
                                                      AND A.ItemSeq     = B.ItemSeq 
                                                      AND A.AssyItemSeq = B.AssyItemSeq 
                                                      AND A.ProcSeq     = B.ProcSeq 
                                                      AND B.CostKeySeq  = @PreCostKeySeq
                                                      AND B.InOutKind   = @InOutKindPre
          GROUP BY A.ItemSeq, A.ProcSeq, A.AssyItemSeq ,A.CostUnit
    
      --전월재공수량금액에서 LOT전용 건 - 
      --select * From _TESMCProdFProcStockAmt where inoutkind =8023000 and costkeyseq =190 
   
     INSERT INTO _TESMCProdFProcStockAmt      
         (      
             CompanySeq , CostKeySeq ,  CostUnit, ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             CostAccSeq , InOutKind , InOut , Qty , Amt   , DisUseQty    , DisUseCost
         )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , A.CostUnit ,  
                 A.ItemSeq , 0 /*A.WorkOrderSeq */ , A.ProcSeq , A.AssyItemSeq , 
                 B.CostAccSeq , 8023032 , -1 ,  (A.ConvQty)   , CASE WHEN  (A.ConvQty) = B.Qty THEN B.Amt 
                                                                     ELSE ROUND((B.Amt /B.Qty) *  (A.ConvQty) , 0)
                                                                END  ,
                 0 , 0
           FROM #LotConvert AS A  
                        JOIN _TESMCProdFProcStockAmt AS B ON B.CompanySeq  = @CompanySeq 
                                                         AND A.ItemSeq     = B.ItemSeq 
                                                         AND A.AssyItemSeq = B.AssyItemSeq 
                                                         AND A.ProcSeq     = B.ProcSeq 
                                                         AND B.CostKeySeq  = @PreCostKeySeq
                                                         AND B.InOutKind   = @InOutKindPre
          WHERE B.Qty <> 0 
    ---전용 +건 
  
 -- drop index _TESMCProdFProcStock.IDXTemp_TESMCProdFProcStock
 -- alter table _TESMCProdFProcStock add constraint TPK_TESMCProdFProcStock primary key(CompanySeq, CostKeySeq, CostUnit, ItemSeq, WorkOrderSeq, ProcSeq, AssyItemSeq, InOutKind, InOut)   
  
     TRUNCATE TABLE #LotConvert
      INSERT INTO  #LotConvert
         SELECT CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                    WHEN  5502002 THEN E.AccUnit       
                                    WHEN  5502003 THEN E.BizUnit END ,
               ConvItemSeq , 0 , ConvProcSeq , ConvAssyItemSeq , SUM(ConvQty) 
           FROM _TESMGLotConvert A JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit 
                                      
          WHERE A.CompanySeq = @CompanySeq      
            AND A.CostKeySeq = @CostKeySeq   
            AND ISNULL(A.IsPreProc , '0')  = '1'  
          GROUP BY  ConvItemSeq ,  ConvProcSeq , ConvAssyItemSeq , E.FactUnit , E.AccUnit, E.BizUnit
  --SELECT * fROM #LotConvert WHERE ITEMSEQ = 9506
 --SELECT * fROM _TESMCProdFProcStock T WHERE ITEMSEQ = 9506 AND t.procseq = 19 and t.AssyItemSeq = 18255  
 --SELECT * fROM _TDASMINOR WHERE MINORSEQ =8023014
  --전월재공수량에서 LOT전용 건 + 
     INSERT INTO _TESMCProdFProcStock      
         (      
             CompanySeq, CostKeySeq ,  CostUnit, ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             InOutKind , InOut , Qty , Amt  , DisUseQty , DisUseCost
         )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , A.CostUnit,  
                 A.ItemSeq , 0 /*A.WorkOrderSeq */ , A.ProcSeq , A.AssyItemSeq , 8023032 ,  1 ,  (A.ConvQty)   , 0  ,0,0
           FROM #LotConvert AS A   
  
     CREATE TABLE #ProcStockAmt
     ( CostUnit INT , ItemSeq INT , WorkOrderSeq INT ,ProcSeq INT , AssyItemSeq INT , CostAccSeq INT , 
       Qty DECIMAL(19,5) , Amt DECIMaL(19, 5) , Serl INT IDENTITY(1,1) , IsSUM NCHAR(1) , OriItemSeq  INT,
       OriProcSeq INT , OriAssyItemSeq INT   ) 
  
     INSERT INTO #ProcStockAmt      
         (      
             CostUnit ,  ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             CostAccSeq , Qty    ,   Amt  , OriItemSeq , OriProcSeq , OriAssyItemSeq 
         )       
     SELECT  CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                                                     WHEN  5502002 THEN E.AccUnit       
                                                                     WHEN  5502003 THEN E.BizUnit END ,  
             A.ConvItemSeq , 0 /*A.WorkOrderSeq */ , A.ConvProcSeq , A.ConvAssyItemSeq , 
             B.CostAccSeq ,  0,   CASE WHEN SUM(A.ConvQty) = B.Qty THEN B.Amt 
                                                              ELSE ROUND((B.Amt /B.Qty) * SUM(A.ConvQty) , 0)
                                                              END  ,
             A.ItemSeq , A.ProcSeq , A.AssyItemSeq 
       FROM _TESMGLotConvert AS A  
                    JOIN #CostUnit               AS E ON A.FactUnit    = E.FactUnit 
                    JOIN _TESMCProdFProcStockAmt AS B ON A.CompanySeq  = B.CompanySeq  
                                                     AND A.ItemSeq     = B.ItemSeq 
                                                     AND A.AssyItemSeq = B.AssyItemSeq 
                                                     AND A.ProcSeq     = B.ProcSeq 
                                                     AND B.CostKeySeq  = @PreCostKeySeq
                                                     AND B.InOutKind   = @InOutKindPre
   
      WHERE A.CompanySeq = @CompanySeq      
        AND A.CostKeySeq = @CostKeySeq   
        AND ISNULL(A.IsPreProc , '0')  = '1' 
        AND B.Qty <>0 
      GROUP BY A.ConvItemSeq, A.ConvProcSeq, A.ConvAssyItemSeq, E.FactUnit , E.AccUnit, E.BizUnit , B.Amt , B.Qty , B.CostAccSeq,
               A.ItemSeq , A.ProcSeq , A.AssyItemSeq 
      --단수보정이 들어가야함. 
   
      CREATE TABLE #DiffAmt 
     ( ItemSeq INT , ProcSeq INT , AssyItemSeq INT , DiffAmt DECIMAL(19, 5) , IsSUM NCHAR(1) ) 
      INSERT INTO #DiffAmt (ItemSeq , ProcSeq , AssyItemSeq , DiffAmt ) 
         SELECT A.ItemSeq , A.ProcSeq , A.AssyItemSeq , SUM(A.Amt)  
           FROM _TESMCProdFProcStockAmt AS A 
          WHERE A.CostKeySeq = @CostKeySEq 
            AND A.CompanySeq = @CompanySeq 
            AND A.InOutKind  = 8023032 
            AND A.InOut      = -1 
            AND A.CostUnit   = @CostUnit 
          GROUP BY  A.ItemSeq , A.ProcSeq , A.AssyItemSeq
  
  --select * From #DiffAmt where assyitemseq = 18110 
 --select sum(amt) From _TESMCProdFProcStockAmt where InoutKind = 8023032 and itemseq = 10582 and costkeyseq = 189
 --70751.00000
  --drop table ##ProcStockAmt
 --
 --select * into ##ProcStockAmt
 --from #ProcStockAmt
 -- 
      INSERT INTO #DiffAmt (ItemSeq , ProcSeq , AssyItemSeq , DiffAmt ) 
         SELECT A.OriItemSeq ,  A.OriProcSeq ,  A.OriAssyItemSeq , -1*SUM(A.Amt) 
           FROM #ProcStockAmt A
          GROUP BY OriItemSeq ,  A.OriProcSeq ,  A.OriAssyItemSeq 
    
 --select * From #DiffAmt where assyitemseq = 18110 
  --
 --select * into ##CostUnit
 --from #CostUnit
  
     INSERT INTO   #DiffAmt (ItemSeq , ProcSeq , AssyItemSeq , DiffAmt , IsSUM  )    
         SELECT ItemSeq , ProcSeq , AssyItemSeq , SUM(DiffAmt) , '1' 
           FROM #DiffAmt
          GROUP BY  ItemSeq , ProcSeq , AssyItemSeq 
         HAVING SUM(DiffAmt) <> 0 
  
     DELETE #DiffAmt WHERE IsSUM IS NULL 
  
 --drop table ##ProcStockAmt
 --drop table ##CostUnit
 --drop table ##DiffAmt
 --
 ----select * From #DiffAmt where assyitemseq = 19136 
 --select * into ##ProcStockAmt from #ProcStockAmt 
 --select * into ##CostUnit from #CostUnit 
 --select * into ##DiffAmt from #DiffAmt 
      INSERT INTO #ProcStockAmt      
           (      
                    CostUnit ,  ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
                    CostAccSeq , Qty    ,   Amt  
            )       
         SELECT A.CostUnit , A.ItemSeq , 0,   A.ProcSeq , A.AssyItemSeq ,
                A.CostAccSeq , 0  ,   B.DiffAmt
           FROM #ProcStockAmt AS A 
                        JOIN  ( SELECT a.ItemSeq , A.ProcSeq , a.AssyItemSeq , F.DiffAmt,  MAX(B.Serl)AS Serl 
                                  FROM _TESMGLotConvert AS a  
                                                JOIN #CostUnit          AS E ON a.FactUnit        = E.FactUnit 
                                                JOIN #DiffAmt           AS F ON a.ItemSeq         = F.ItemSeq
                                                                            AND a.ProcSeq         = F.ProcSeq 
                                                                            AND a.AssyItemSeq     = F.AssyItemSeq   
                                                JOIN #ProcStockAmt      AS B ON a.ConvItemSeq     = B.ItemSeq 
                                                                            AND a.ConvProcSeq     = B.ProcSeq  
                                                                            AND a.ConvAssyItemSeq = B.AssyItemSeq 
                                                                                          
                                 WHERE a.CompanySeq = @CompanySeq     
                                   AND a.CostKeySeq = @CostKeySEq   
                                   AND ISNULL(a.IsPreProc , '0')  = '1'  
                                 GROUP BY  a.ItemSeq , a.ProcSeq , a.AssyItemSeq , F.DiffAmt
                               ) AS B ON A.Serl = B.Serl 
 /*
 select A.ItemSeq , A.AssyItemSeq , A.ProcSeq , Max(Serl) 
  select * From ##ProcStockAmt
        SELECT B.CostUnit , A.ItemSeq , A.ProcSeq , A.AssyItemSeq , F.DiffAmt, MAX(B.Serl)
  FROM _TESMGLotConvert AS a  JOIN ##CostUnit          AS E ON A.FactUnit = E.FactUnit 
                                   JOIN ##DiffAmt AS F ON a.ItemSeq = F.ItemSeq
                                                                AND a.ProcSeq     = F.ProcSeq 
                                                                AND a.AssyItemSeq = F.AssyItemSeq   
                                   JOIN ##ProcStockAmt AS B ON A.ConvItemSeq = B.ItemSeq 
                                                          AND A.ConvProcSeq = B.ProcSeq  
                                                          AND A.ConvAssyItemSeq   = B.AssyItemSeq  
                                                          AND B.Serl = (SELECT Max(Serl) 
                                                                          FROM ##ProcStockAmt 
                                                                         WHERE ItemSeq = B.ItemSeq 
                                                                           AND ProcSeq = B.ProcSeq 
                                                                           AND AssyItemSeq = B.AssyItemSeq ) 
       WHERE a.CompanySeq = 3     
        AND a.CostKeySeq = 190   
        AND ISNULL(a.IsPreProc , '0')  = '1'  
 and a.ConvAssyItemSeq =  19136
     GROUP BY B.CostUnit , A.ItemSeq , A.ProcSeq , A.AssyItemSeq , F.DiffAmt
  select * From ##DiffAmt
  
        SELECT A.CostUnit , A.ItemSeq , 0,   A.ProcSeq , A.AssyItemSeq ,
              A.CostAccSeq , 0  ,   b.dIFFAmt
       FROM ##ProcStockAmt AS A JOIN  ( SELECT A.ItemSeq , A.ProcSeq , A.AssyItemSeq , F.DiffAmt,  MAX(B.Serl)AS Serl 
                                       FROM _TESMGLotConvert AS a  JOIN ##CostUnit          AS E ON A.FactUnit = E.FactUnit 
                                                                   JOIN ##DiffAmt AS F ON a.ItemSeq = F.ItemSeq
                                                                                                AND a.ProcSeq     = F.ProcSeq 
                                                                                                AND a.AssyItemSeq = F.AssyItemSeq   
                                                                   JOIN ##ProcStockAmt AS B ON A.ConvItemSeq = B.ItemSeq 
                                                                                          AND A.ConvProcSeq = B.ProcSeq  
                                                                                          AND A.ConvAssyItemSeq   = B.AssyItemSeq 
                                                                                          
                                      WHERE a.CompanySeq = 3     
                                        AND a.CostKeySeq = 190   
                                        AND ISNULL(a.IsPreProc , '0')  = '1'  
                                     GROUP BY  A.ItemSeq , A.ProcSeq , A.AssyItemSeq , F.DiffAmt
                                         ) AS B ON A.Serl = B.Serl 
 WHERE A.ASSYITEMSEQ = 19136
  
 10605
 select * From ##DiffAmt where assyitemseq = 19136 
 --select * From ##ProcStockAmt where assyitemseq = 19136 and assyitemseq = 19136
  select * 
  FROM _TESMGLotConvert  
 where costkeyseq = 190 and assyitemseq = 19136 
      
 */ 
     
     INSERT INTO #ProcStockAmt      
         (      
             CostUnit ,  ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             CostAccSeq , Qty    ,   Amt  , IsSUM 
         )       
         SELECT      CostUnit ,  ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
                     CostAccSeq , Qty    ,   SUM(Amt), '1'
           FROM   #ProcStockAmt
          GROUP BY  CostUnit ,  ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
                    CostAccSeq , Qty 
   
     DELETE #ProcStockAmt WHERE IsSUM IS NULL  
  
  
     INSERT INTO _TESMCProdFProcStockAmt      
         (      
             CompanySeq , CostKeySeq ,  CostUnit, ItemSeq , WorkOrderSeq , ProcSeq , AssyItemSeq , 
             CostAccSeq , InOutKind , InOut , Qty , Amt  ,DisUseQty   , DisUseCost
         )       
         SELECT  DISTINCT @CompanySeq   , @CostKeySeq , A.CostUnit, A.ItemSeq , A.WorkOrderSeq , A.ProcSeq , A.AssyItemSeq , 
                          A.CostAccSeq  , 8023032     , 1 ,  (B.ConvQty) , SUM(A.Amt)     , 0 , 0
           FROM #ProcStockAmt AS A 
                        JOIN ( SELECT a.ConvItemSeq , a.ConvAssyItemSeq , a.ConvProcSeq , 
                                             SUM(a.ConvQty) AS ConvQty  
                                 FROM _TESMGLotConvert AS a  
                                                JOIN #CostUnit  AS E ON a.FactUnit = E.FactUnit 
                                WHERE a.CompanySeq = @CompanySeq      
                                  AND a.CostKeySeq = @CostKeySeq   
                                  AND ISNULL(a.IsPreProc , '0')  = '1'  
                                      GROUP BY  a.ConvItemSeq , a.ConvAssyItemSeq , a.ConvProcSeq  
                             ) AS B ON A.ItemSeq = B.ConvItemSeq AND A.ProcSeq = B.ConvProcSeq AND A.AssyItemSeq = B.ConvAssyItemSeq   
          GROUP BY  A.CostUnit, A.ItemSeq , A.WorkOrderSeq , A.ProcSeq , A.AssyItemSeq , 
                    A.CostAccSeq ,B.ConvQty
     
  /*
 select sum(amt*inout) From _TESMCProdFProcStockAmt where inoutkind =8023032 
 and costkeyseq =190
   
  19913
         select sum(qty) from     _TESMCProdFProcStock                      where costkeyseq = 190 and inout = 1 and inoutkind = 8023032 
      select distinct itemseq ,  (qty) from     _TESMCProdFProcStockamt   where costkeyseq = 190 and inout = 1 and inoutkind = 8023032 
         select sum(amt*inout) from     _TESMCProdFProcStockamt                      where costkeyseq = 190   and inoutkind = 8023032 
          select assyitemseq , sum(amt*inout) from     _TESMCProdFProcStockamt  where costkeyseq = 190   and inoutkind = 8023032 
          group by assyitemseq 
          select sum(lotconvcost) from     _TESMCProdFGoodCostResult                      where costkeyseq = 190 
         select sum(lotconvqty) from     _TESMCProdFGoodCostResult                      where costkeyseq = 190 
         select sum(lotconvqty) from     _TESMCProdFProcStockamt                      where costkeyseq = 190 
  */
  
 --select '3'   
     INSERT INTO _TESMGWorkReportLotConv      
         (      
             CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
             WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
             ProdQty, OKQty,  BadQty,        
             ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
             ProcSeq , BizUnit , CostUnit   , DataKind  , IsDirConvert     
         )       
         SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                 A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
                 C.CCtrSeq ,        
                 B.ConvQty  ,  B.ConvQty   , 0 ,       
                 A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
                 ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                    CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                        WHEN  5502002 THEN E.AccUnit       
                                        WHEN  5502003 THEN E.BizUnit       
                    END  , '2' , -- LOT 전용 +    
                 B.IsDirConvert   
           FROM _TPDSFCWorkReport AS A  JOIN (SELECT B.ConvWorkReportSeq AS WorkReportSeq , SUM(B.ConvQty ) as ConvQty , B.IsDirConvert   
                                                FROM _TESMGLotConvert AS  B  JOIN #CostUnit AS E ON B.FactUnit = E.FactUnit   
                                               WHERE B.CompanySeq= @CompanySeq  
                                                 AND B.CostKeySeq= @CostKeySeq   
                                                 AND ISNULL(B.IsPreProc , '0') = '0' 
                                              GROUP BY B.ConvWorkReportSeq, B.IsDirConvert   
                                              ) AS B ON  A.WorkReportSeq= B.WorkReportSeq  
                                       JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq and C.CompanySeq = @CompanySeq      
                                       JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                            LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq    
                            LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                                 AND A.AssyItemSeq = Z.AssyItemSeq
                                                                                 AND A.CompanySeq = Z.CompanySeq      
           WHERE A.CompanySeq = @CompanySeq      
             AND A.WorkDate BETWEEN @FrDate AND @ToDate   
             AND A.ChainGoodsSeq = 0      
    
 --전월재공에서 LOT전용한건은 당월재공을 +로 처리. 
 --
 --select * From _TESMCProdFProcStock where inoutkind = 8023032
  
 -- LOT전용을 감안한 생산실적을 담는다.   
 --  select * From _TESMGWorkReportLotConv               
 --  select * From _TESMGWorkReport where itemseq = 19403
   
     DECLARE @OutTransType NCHAR(1), @BadQtyType INT
     -- 환경설정에서 '외주용역비 정산기준' 가져오기      
     EXEC dbo._SCOMEnv @CompanySeq,6513,0  /*@UserSeq*/,@@PROCID,@OutTransType OUTPUT    
     EXEC dbo._SCOMEnv @CompanySeq,6233,0  /*@UserSeq*/,@@PROCID,@BadQtyType OUTPUT    
  
     IF @OutTransType = '0' 
     BEGIN 
          INSERT INTO _TESMGWorkReport      
                   (      
                            CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
                            WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
                            ProdQty, OKQty,  BadQty,        
                            ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
                            ProcSeq , BizUnit , CostUnit   , IsLotConvert  , OSPAccSeq , OSPUMCostType , OSPCost , ProcHour   ,RealLotNo, DisUseType  
                    )       
             SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                     A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
                     C.CCtrSeq ,        
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE A.StdUnitProdQty + ISNULL(B.ConvQty, 0)* -1 + ISNULL(D.ConvQty, 0) END ,   
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE A.StdUnitOKQty + ISNULL(B.ConvQty, 0 ) * -1 + ISNULL(D.ConvQty, 0) END ,   
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE CASE @BadQtyType WHEN 6078001 THEN ISNULL(A.StdUnitBadQty,0) 
                          ELSE ISNULL(A.StdUnitLossCostQty,0) END END ,       
                     --A.StdUnitProdQty + ISNULL(B.ConvQty, 0)* -1 + ISNULL(D.ConvQty, 0)  ,   A.StdUnitOKQty + ISNULL(B.ConvQty, 0 ) * -1 + ISNULL(D.ConvQty, 0) ,   
     --ISNULL(A.StdUnitLossCostQty,0) ,   
                     A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
                     ISNULL(Z.ProcSeq, A.ProcSeq), E.BizUnit ,       
                        CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                            WHEN  5502002 THEN E.AccUnit       
                                            WHEN  5502003 THEN E.BizUnit       
                        END   ,   
                     CASE WHEN ISNULL(B.WorkReportSeq , '0') = '1' OR  ISNULL(D.WorkReportSeq , '0') = '1' THEN '1'    
                          ELSE '0' END  ,
                      ISNULL(H.ProcAccSeq , 0) , CASE WHEN ISNULL(H.ProcAccSeq , 0) <> 0 THEN 4001001 ELSE 0 END /*UMCostType*/ , ISNULL(H.DomAmt , 0), --사내외주가공비
                      ISNULL(F.WorkHour , 0) , CASE WHEN @FGoodPricType = 5503005 THEN  ISNULL(A.RealLotNo,'') ELSE '' END,
                      ISNULL(A.DisUseType,0)
               FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
                 LEFT OUTER JOIN   ( SELECT B.WorkReportSeq , SUM(B.ConvQty ) as ConvQty 
                                       FROM _TESMGLotConvert AS  B  
                                                        JOIN #CostUnit          AS E ON B.FactUnit = E.FactUnit   
                                      WHERE B.CompanySeq= @CompanySeq  
                                        AND B.CostKeySeq= @CostKeySeq 
                                        AND ISNULL(B.IsPreProc , '0') = '0'   
                                      GROUP BY B.WorkReportSeq  
                                    ) AS B ON  A.WorkReportSeq= B.WorkReportSeq  
                 LEFT OUTER JOIN   ( SELECT B.ConvWorkReportSeq AS WorkReportSeq , SUM(B.ConvQty ) as ConvQty 
                                       FROM _TESMGLotConvert AS  B  
                                                    JOIN #CostUnit          AS E ON B.FactUnit = E.FactUnit   
                                      WHERE B.CompanySeq= @CompanySeq  
                                        AND B.CostKeySeq= @CostKeySeq   
                                       AND ISNULL(B.IsPreProc , '0') = '0' 
                                      GROUP BY B.ConvWorkReportSeq  
                                    ) AS D ON  A.WorkReportSeq= D.WorkReportSeq   
                                  JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq and C.CompanySeq = @CompanySeq      
                            JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                 LEFT OUTER JOIN _TPDSFCOutsourcingCostItem AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq 
                                                                             AND A.WorkReportSeq = H.WorkReportSeq
                 LEFT OUTER JOIN ( SELECT A.WorkReportSeq , SUM(F.WorkHour) AS WorkHour
                                     FROM _TPDSFCToolUse AS F WITH(NOLOCK) 
                                                    JOIN _TPDSFCWorkReport AS A WITH(NOLOCK) ON A.CompanySeq    = F.CompanySeq 
                                                                                            AND A.WorkReportSeq = F.WorkReportSeq
                                    WHERE A.CompanySeq = @CompanySeq      
                                      AND A.WorkDate   BETWEEN @FrDate AND @ToDate   
                                      AND A.ChainGoodsSeq = 0  
                                    GROUP BY A.WorkReportSeq  
                                 ) AS F ON A.WorkReportSeq = F.WorkReportSeq 
                 LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq  
                 LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                      AND A.AssyItemSeq = Z.AssyItemSeq
                                                                      AND A.CompanySeq = Z.CompanySeq
     LEFT OUTER JOIN _TPDSFCWorkOrder AS W ON A.CompanySeq    = W.CompanySeq   
               AND A.WorkOrderSeq  = W.WorkOrderSeq
               AND A.WorkOrderSerl = W.WorkOrderSerl
           WHERE A.CompanySeq = @CompanySeq      
             AND A.WorkDate BETWEEN @FrDate AND @ToDate   
             AND A.ChainGoodsSeq = 0       
     END      
     ELSE --입고기준이면 생산실적에 사내외주가 담기지 않는다. 
     BEGIN  
          INSERT INTO _TESMGWorkReport      
             (      
                 CompanySeq, CostKeySeq ,  WorkReportSeq, WorkSerl,    FactUnit, AccUnit,  WorkDate,  DeptSeq, PJTSeq ,       
                 WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
                 ProdQty, OKQty,  BadQty,        
                 ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
                 ProcSeq , BizUnit , CostUnit   , IsLotConvert  , OSPAccSeq , OSPUMCostType , OSPCost , ProcHour, RealLotNo, DisUseType      
             )       
             SELECT  DISTINCT @CompanySeq, @CostKeySeq , a.WorkReportSeq, 0,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, A.PJTSeq ,       
                     A.WorkCenterSeq, A.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
                     C.CCtrSeq , 
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE A.StdUnitProdQty + ISNULL(B.ConvQty, 0)* -1 + ISNULL(D.ConvQty, 0) END ,   
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE A.StdUnitOKQty + ISNULL(B.ConvQty, 0 ) * -1 + ISNULL(D.ConvQty, 0) END ,   
                     CASE W.WorkType WHEN 6041010 THEN 0 ELSE CASE @BadQtyType WHEN 6078001 THEN ISNULL(A.StdUnitBadQty,0) 
                          ELSE ISNULL(A.StdUnitLossCostQty,0) END END ,       
                     --A.StdUnitProdQty + ISNULL(B.ConvQty, 0)* -1 + ISNULL(D.ConvQty, 0)  ,   A.StdUnitOKQty + ISNULL(B.ConvQty, 0 ) * -1 + ISNULL(D.ConvQty, 0) ,   
                     --ISNULL(A.StdUnitLossCostQty,0) ,       
                     A.ProcHour, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /*Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end*/,      
          ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                        CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                            WHEN  5502002 THEN E.AccUnit       
                                            WHEN  5502003 THEN E.BizUnit       
                        END   ,   
                     CASE WHEN ISNULL(B.WorkReportSeq , '0') = '1' OR  ISNULL(D.WorkReportSeq , '0') = '1' THEN '1'    
                          ELSE '0' END  ,
                     0 , 0 /*UMCostType*/ ,0, --사내외주가공비
                     ISNULL(F.WorkHour , 0), CASE WHEN @FGoodPricType = 5503005 THEN  ISNULL(A.RealLotNo,'') ELSE '' END,
                     ISNULL(A.DisUseType, 0)
               FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
                 LEFT OUTER JOIN   ( SELECT B.WorkReportSeq , SUM(B.ConvQty ) as ConvQty 
                                       FROM _TESMGLotConvert AS  B  
                                                    JOIN #CostUnit          AS E ON B.FactUnit = E.FactUnit   
                                      WHERE B.CompanySeq= @CompanySeq  
                                        AND B.CostKeySeq= @CostKeySeq 
                                        AND ISNULL(B.IsPreProc , '0') = '0'   
                                      GROUP BY B.WorkReportSeq  
                                    ) AS B ON  A.WorkReportSeq= B.WorkReportSeq  
                 LEFT OUTER JOIN   ( SELECT B.ConvWorkReportSeq AS WorkReportSeq , SUM(B.ConvQty ) as ConvQty 
                                       FROM _TESMGLotConvert AS  B  
                                                    JOIN #CostUnit          AS E ON B.FactUnit = E.FactUnit   
                                      WHERE B.CompanySeq= @CompanySeq  
                                        AND B.CostKeySeq= @CostKeySeq   
                                        AND ISNULL(B.IsPreProc , '0') = '0' 
                                    GROUP BY B.ConvWorkReportSeq  
                                    ) AS D ON  A.WorkReportSeq= D.WorkReportSeq   
           
                            JOIN _TPDBaseWorkCenter AS C ON A.WorkCEnterSeq = C.WorkCenterSeq 
                                                        AND C.CompanySeq    = @CompanySeq      
                            JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit   
                 LEFT OUTER JOIN ( SELECT A.WorkReportSeq , SUM(F.WorkHour) AS WorkHour
                                     FROM _TPDSFCToolUse AS F WITH(NOLOCK) 
                                                    JOIN _TPDSFCWorkReport AS A WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq 
                                                                                            AND A.WorkReportSeq = F.WorkReportSeq
                                    WHERE A.CompanySeq = @CompanySeq      
                                      AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                                      AND A.ChainGoodsSeq = 0  
                                    GROUP BY A.WorkReportSeq  
                                 ) AS F ON A.WorkReportSeq = F.WorkReportSeq 
                 LEFT OUTER JOIN #DeptCCtr AS G ON A.DeptSeq = G.DeptSeq  
                 LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                      AND A.AssyItemSeq = Z.AssyItemSeq
                                                                      AND A.CompanySeq  = Z.CompanySeq
     LEFT OUTER JOIN _TPDSFCWorkOrder AS W ON A.CompanySeq    = W.CompanySeq   
               AND A.WorkOrderSeq  = W.WorkOrderSeq
               AND A.WorkOrderSerl = W.WorkOrderSerl
               WHERE A.CompanySeq = @CompanySeq       
                 AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                 AND A.ChainGoodsSeq = 0      
   
  
  
     END 
  
 -- 연산품      
   
  
      INSERT INTO _TESMGWorkReport      
         (      
             CompanySeq, CostKeySeq ,  WorkReportSeq,  WorkSerl ,   FactUnit, AccUnit,  WorkDate,  DeptSeq,PJTSeq ,       
             WorkCenterSeq, ItemSeq,  ProcRev,  AssyItemSeq,   CCtrSeq,       
             ProdQty, OKQty,  BadQty,        
             ManHour, WorkOrderSeq,  IsLastProc, WorkHour,       
             ProcSeq , BizUnit , CostUnit    , IsLotConvert ,  OSPAccSeq , OSPUMCostType , OSPCost , ProcHour, DisUseType     
         )       
         SELECT  @CompanySeq, @CostKeySeq , a.WorkReportSeq, H.WorkSerl,  A.FactUnit, E.AccUnit, A.WorkDate, A.DeptSeq, 0,       
                 A.WorkCenterSeq, H.GoodItemSeq, A.ProcRev , A.AssyItemSeq,       
     --          CASE @SMCostMng WHEN 5512004 THEN ISNULL(G.CCtrSeq, 0) ELSE C.CCtrSeq END,      
                 C.CCtrSeq  ,       
                 H.StdQty,  H.StdQty, 0,       
                 H.ProcHours, A.WorkOrderSeq, A.IsLastProc , A.WorkHour /* Case When isnull(A.WorkHour,0) = 0 then 0 else isnull(A.WorkHour,0) /60 end */,      
                 ISNULL(Z.ProcSeq, A.ProcSeq) , E.BizUnit ,       
                 CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit    
                                     WHEN  5502002 THEN E.AccUnit       
                                     WHEN  5502003 THEN E.BizUnit       
                 END    , '0'  , 0, 0, 0 , ISNULL(F.WorkHour , 0),   --연산품은 사내외주없음  
                 ISNULL(A.DisUseType, 0 )
           FROM _TPDSFCWorkReport AS A WITH(NOLOCK) -- JOIN _TPDSFCWorkOrder   AS B ON A.WorkOrderSeq = B.WorkOrderSeq and B.CompanySeq = @CompanySeq /*컨버젼이안된것같음우선제외*/      
                            JOIN _TPDSFCWorkReportChainGoods  AS H WITH(NOLOCK) ON A.WorkReportSeq = H.WorkReportSeq 
                                                                               AND H.CompanySeq    = @CompanySeq        
                            JOIN _TPDBaseWorkCenter           AS C WITH(NOLOCK) ON A.WorkCEnterSeq = C.WorkCenterSeq 
                                                                              AND C.CompanySeq    = @CompanySeq      
                            JOIN #CostUnit                    AS E              ON A.FactUnit      = E.FactUnit     
                 LEFT OUTER JOIN ( SELECT  A.WorkReportSeq , SUM(F.WorkHour) AS WorkHour
                                     FROM _TPDSFCToolUse AS F WITH(NOLOCK) 
                                                    JOIN _TPDSFCWorkReport AS A WITH(NOLOCK) ON A.CompanySeq    = F.CompanySeq 
                                                                                            AND A.WorkReportSeq = F.WorkReportSeq
                                    WHERE A.CompanySeq = @CompanySeq      
                                      AND A.WorkDate BETWEEN @FrDate AND @ToDate   
                                      AND A.ChainGoodsSeq > 0   
                                    GROUP BY A.WorkReportSeq  
                                 ) AS F ON A.WorkReportSeq = F.WorkReportSeq 
                 LEFT OUTER JOIN #DeptCCtr                    AS G ON A.DeptSeq = G.DeptSeq  
                 LEFT OUTER JOIN _TESMBStdProcAsItem          AS Z WITH(NOLOCK) ON H.GoodItemSeq = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                               AND A.AssyItemSeq = Z.AssyItemSeq
                                                                               AND A.CompanySeq  = Z.CompanySeq
          WHERE A.CompanySeq = @CompanySeq     
            AND A.WorkDate BETWEEN @FrDate AND @ToDate   
            AND A.ChainGoodsSeq > 0   
      
      -- 최종검사불량 수량 빼주기 2010.06.22 정동혁 추가. 
  
     SELECT Q.SourceSeq, SUM(CASE WHEN ISNULL(Q.StdUnitRejectQty, 0) <> 0 THEN Q.StdUnitRejectQty
                                  WHEN ISNULL(Q.StdUnitRejectQty, 0) = 0  THEN ISNULL(Q.RejectQty, 0)  * (B.ConvNum / B.ConvDen) END) AS RejectQty--  ,sum(ReqQty) as ReqQty,SUM(PassedQty) AS PassedQty ,QCSeq ,itemseq,SUM(Q.RejectQty) AS RejectQty 
     , Q.DisUseType                                 
       INTO #RejectQty
       FROM _TPDQCTestReport     AS Q WITH(NOLOCK)
     JOIN _TPDSFCWorkReport AS A WITH(NOLOCK) ON Q.CompanySeq = A.CompanySeq
                                             AND Q.SourceSeq = A.WorkReportSeq
     JOIN _TDAItemUnit          AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                             AND A.GoodItemSeq    = B.ItemSeq
                                             AND A.ProdUnitSeq  = B.UnitSeq
    
      WHERE Q.CompanySeq  = @CompanySeq
        AND Q.SourceType = '3'
        AND (ISNULL(Q.StdUnitRejectQty, 0)  <> 0 OR ISNULL(Q.RejectQty, 0)  <> 0)
        AND EXISTS(SELECT 1 FROM _TESMGWorkReport WHERE CompanySeq = @CompanySeq AND CostKeySeq = @CostKeySeq AND WorkReportSeq = Q.SourceSeq )
      GROUP BY Q.SourceSeq, Q.DisUseType--,ItemSeq,QCSeq
  
   
   
     --SELECT Q.SourceSeq, SUM(Q.RejectQty) AS RejectQty    
     --  INTO #RejectQty    
     --  FROM _TPDQCTestReport     AS Q WITH(NOLOCK)    
     -- WHERE Q.CompanySeq  = @CompanySeq    
     --   AND SourceType = '3'    
     --   AND RejectQty  <> 0     
     --   AND EXISTS(SELECT 1 FROM _TESMGWorkReport WHERE CompanySeq = @CompanySeq AND CostKeySeq = @CostKeySeq AND WorkReportSeq = Q.SourceSeq )    
     -- GROUP BY Q.SourceSeq    
     
     --UPDATE A    
     --   SET RejectQty = A.RejectQty * U.ConvNum / U.ConvDen    
     --  FROM #RejectQty           AS A     
     --    JOIN _TPDSFCWorkReport  AS W ON A.SourceSeq = W.WorkReportSeq    
     --    JOIN _TDAItemUnit       AS U ON W.AssyItemSeq = U.ItemSeq    
     --                                AND W.ProdUnitSeq = U.UnitSeq    
     -- WHERE W.CompanySeq = @CompanySeq    
     --   AND U.ConvDen    <> 0     
  
  --DECLARE @FGoodDec INT
  --   EXEC dbo._SCOMEnv @CompanySeq,8,@UserSeq,@@PROCID,@FGoodDec OUTPUT     --자재단가계산단위 
         
  ----2012.04.18 제품 환산시 소수점 자리수 처리 
  --   UPDATE A
  --      SET RejectQty = ROUND(A.ReqQty * U.ConvNum / U.ConvDen,@FGoodDec) - StdProdQty
  --     FROM #RejectQty           AS A 
  --       JOIN _TPDSFCWorkReport  AS W ON A.SourceSeq = W.WorkReportSeq
  --       JOIN _TPDSFCGoodIn      AS H ON A.QCSeq = H.QCSeq 
  --           AND W.WorkReportSeq = H.WorkReportSeq
  --           AND W.CompanySeq = H.CompanySeq
  --       JOIN _TDAItemUnit       AS U ON W.AssyItemSeq = U.ItemSeq
  --                                   AND W.ProdUnitSeq = U.UnitSeq
  --    WHERE W.CompanySeq = @CompanySeq
  --      AND U.ConvDen    <> 0 
 --drop table ##RejectQty
 --select * into ##RejectQty  from #RejectQty 
      UPDATE A
        SET OKQty    = A.OKQty - B.RejectQty
           ,BadQty   = A.BadQty + B.RejectQty
           ,DisUseType = CASE WHEN B.DisUseType = 0 THEN A.DisUseType ELSE B.DisUsetype END       
       FROM _TESMGWorkReport     AS A 
         JOIN #RejectQty AS B ON A.WorkReportSeq = B.SourceSeq
      WHERE A.CompanySeq = @CompanySeq
        AND A.CostKeySeq = @CostKeySeq
    
    
    ----최종검사불량해체작업인 경우 생산수량이 0으로 집계되도록 수정. 2013.5.24 정연아    
    -- UPDATE A 
    --    SET OKQty    = 0
    --       ,BadQty   = 0
    --   FROM _TESMGWorkReport     AS A 
    --     JOIN _TPDSFCWorkOrder AS B ON A.CompanySeq    = B.CompanySeq   
    --       AND A.WorkOrderSeq = B.WorkOrderSeq
    --       AND A.WorkOrderSerl = B.WorkOrderSerl
    --  WHERE A.CompanySeq = @CompanySeq
    --    AND A.CostKeySeq = @CostKeySeq
    --    AND B.WorkType = 6041010
  
 ----- 투입실적------------------------------------------------------------------------------------------      
    
  
     INSERT INTO _TESMGMatInput          
         (          
             CompanySeq, CostKeySeq,   ItemSerl, WorkReportSeq, WorkSerl,  RealLotNo,  InputDate, ItemSeq, Qty,          
             ProcSeq, AssyYn,  Amt, AccUnit, FactUnit, InputType,  PJTSeq, IsProject   , BizUnit , CostUnit  , IsReinput       
         )          
         SELECT  @CompanySeq, @CostKeySeq , A.ItemSerl, A.WorkreportSeq, 0, A.RealLOtNo,      A.InputDate, A.MatItemSeq,       A.StdUnitQty /*- ISNULL(X.ConvQty, 0)+ ISNULL(Y.ConvQty, 0)*/ ,          
                 0/*A.ProcSeq 이건의미없다.이젠.*/  , A.AssyYn, 0 /*amt*/, E.AccUnit, B.FactUnit, A.InputType,     A.PjtSeq, A.IsPjt   , E.BizUnit ,            
                 CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit          
                                     WHEN  5502002 THEN E.AccUnit           
                                     WHEN  5502003 THEN E.BizUnit           
                 END , '0'         
           FROM _TPDSFCMatinput AS A   
                        JOIN _TPDSFCWorkReport  AS B ON A.WorkReportSeq = B.WorkReportSeq 
                                                    AND B.CompanySeq    = @CompanySeq          
                        JOIN #CostUnit          AS E ON B.FactUnit      = E.FactUnit         
             LEFT OUTER JOIN #Item              AS C ON A.MatItemSeq    = C.ItemSeq         
          WHERE A.CompanySeq = @CompanySeq        
            AND A.InputDate BETWEEN @FrDate AND @ToDate        
            AND ((A.InputType = 6042002) OR (A.InputType = 6042006) OR (A.InputType = 6042004 AND Ispaid = '1')      
                  OR (A.InputType = 6042007) ) -- 정상, AS, 사용후정산          
            AND B.ChainGoodsSeq = 0           
            AND ISNULL(C.ItemSeq , 0) =0        
   
     
   
     INSERT INTO _TESMGMatInput      
         (      
             CompanySeq, CostKeySeq,   ItemSerl, WorkReportSeq, WorkSerl, RealLotNo,  InputDate, ItemSeq, Qty,      
             ProcSeq, AssyYn,  Amt, AccUnit, FactUnit, InputType,  PJTSeq, IsProject   , BizUnit , CostUnit  ,IsReinput       
         )      
         SELECT  @CompanySeq, @CostKeySeq , A.ItemSerl, A.WorkreportSeq, G.WorkSerl , A.RealLOtNo, A.InputDate, A.MatItemSeq,       A.StdUnitQty,      
                 0/* A.ProcSeq*/ , A.AssyYn, 0 /*amt*/, E.AccUnit, B.FactUnit, A.InputType,  A.PjtSeq, A.IsPjt   , E.BizUnit ,      
                 CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
                                     WHEN  5502002  THEN E.AccUnit       
                                     WHEN  5502003 THEN E.BizUnit       
                 END , '0'    
           FROM _TPDSFCMatinput AS A   
                        JOIN _TPDSFCWorkReport           AS B              ON A.WorkReportSeq = B.WorkReportSeq 
                                                                          AND B.CompanySeq    = @CompanySeq      
                        JOIN #CostUnit                   AS E              ON B.FactUnit      = E.FactUnit     
                        JOIN _TPDSFCWorkReportChainGoods AS G WITH(NOLOCK) ON A.CompanySeq    = G.CompanySeq
                                                                          AND A.WorkReportSeq = G.WorkReportSeq        
                                                                          AND A.GoodItemSeq   = G.GoodItemSeq      
             LEFT OUTER JOIN #Item                       AS C  ON A.MatItemSeq = C.ItemSeq      
          WHERE A.CompanySeq = @CompanySeq      
            AND A.InputDate BETWEEN @FrDate AND @ToDate    
            AND ((A.InputType = 6042002) OR (A.InputType = 6042006) OR (A.InputType = 6042004 AND Ispaid = '1')  
                  OR (A.InputType = 6042007) ) -- 정상, AS, 사용후정산      
            AND B.ChainGoodsSeq > 0       
            AND ISNULL(C.ItemSeq , 0) = 0    
  
  
  --★05.14 지해 - Lot전용에 등록된 작업지시건에서 해당 재공이 투입되는 곳이 많을 경우 , 어느곳에다가 투입을 더 잡아야될지 모르게 된다 따라서 ItemSerl을 max로 수정하였다.
     INSERT INTO _TESMGMatInputLovConv       
         (      
             CompanySeq, CostKeySeq,   ItemSerl, WorkReportSeq , WorkSerl, RealLotNo,  InputDate, ItemSeq, Qty,      
             ProcSeq, AssyYn,  Amt, AccUnit, FactUnit, InputType,  PJTSeq, IsProject   , BizUnit , CostUnit  , DataKind       
         )      
         SELECT DISTINCT  A.CompanySeq, A.CostKeySeq,   MAX(A.ItemSerl), MAX(A.WorkReportSeq), A.WorkSerl, A.RealLotNo,  MAX(A.InputDate), X.ConvAssyItemSeq, X.ConvQty,      
                          A.ProcSeq   , A.AssyYn,  A.Amt, A.AccUnit, A.FactUnit, A.InputType,  A.PJTSeq, A.IsProject   , A.BizUnit , A.CostUnit ,    
                          X.DataKind   --기존투입분에서 투입자재가 LOT전용된건으로 넣어줌.     
           FROM _TESMGMatInput AS A 
                         JOIN _TESMGWorkReport AS B ON A.CompanySeq = B.CompanySeq   
                                                                    AND A.CostKeySeq = B.CostKeySeq   
                                                                    AND A.WorkReportSeq = B.WorkReportSeq   
                                                                    AND A.WorkSerl      = B.WorkSerl  
                         JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit     
                         JOIN (  SELECT B.WorkOrderSeq , B.ItemSeq  AS ConvItemSeq , B.WorkDate, B.AssyItemSeq AS ConvAssyItemSeq , SUM(B.OKQty ) as ConvQty , B.DataKind ,
                                        F.ItemSeq , F.AssyItemSeq        
                                   FROM _TESMGWorkReportLotConv AS  B  
                                                 JOIN #CostUnit        AS E ON B.FactUnit   = E.FactUnit   
                                                 JOIN _TESMGLotConvert AS F ON B.CompanySeq = F.CompanySeq 
                                                                           AND B.CostKeySeq = F.CostKeySeq  
                                                                           --★05.14 지해 원천의 하위 품목은 생산 - , 투입 - 가 되어야 한다. 
                                                                           --AND B.WorkReportSeq = F.ConvWorkReportSeq
                                                                           AND ((B.DataKind = '2' AND B.WorkReportSeq = F.ConvWorkReportSeq  )
                                                                             OR (B.DataKind = '1' AND B.WorkReportSeq = F.WorkReportSeq  )
                                                                                ) 
  
                                     WHERE B.CompanySeq= @CompanySeq   
         AND B.CostKeySeq= @CostKeySeq   
                                       AND B.DataKind IN ( '1' , '2')    
                                       AND B.IsDirConvert = '0' --투입을 보정해줘야할것들만 뽑음. 
                                       AND ISNULL(F.IsPreProc, '0') = '0'  
                                    GROUP BY B.WorkOrderSeq ,  B.ItemSeq , B.AssyItemSeq  , B.DataKind, B.WorkDate  ,
                                             F.ItemSeq , F.AssyItemSeq  
                                  ) AS X ON  B.WorkOrderSeq= X.WorkOrderSeq AND B.ItemSeq = X.ConvItemSeq 
                                        AND A.ItemSeq  = X.AssyItemSeq  
          WHERE A.CompanySeq = @CompanySeq    
            AND A.CostKeySeq = @CostKeySeq   
          GROUP BY  A.CompanySeq, A.CostKeySeq,     A.WorkSerl, A.RealLotNo, X.ConvAssyItemSeq, X.ConvQty,      
                    A.ProcSeq   , A.AssyYn,  A.Amt, A.AccUnit, A.FactUnit, A.InputType,  A.PJTSeq, A.IsProject   , A.BizUnit , A.CostUnit ,    
                    X.DataKind  
  
  --   INSERT INTO _TESMGMatInputLovConv       --확인해야함. 은영. 10.11.11
 --          (      
 --                   CompanySeq, CostKeySeq,   ItemSerl, WorkReportSeq , WorkSerl, RealLotNo,  InputDate, ItemSeq, Qty,      
 --                   ProcSeq, AssyYn,  Amt, AccUnit, FactUnit, InputType,  PJTSeq, IsProject   , BizUnit , CostUnit  , DataKind       )      
 --       SELECT DISTINCT  A.CompanySeq, A.CostKeySeq,   A.ItemSerl, MAX(A.WorkReportSeq), A.WorkSerl, A.RealLotNo,  MAX(A.InputDate), X.ConvAssyItemSeq, X.ConvQty,      
 --                A.ProcSeq   , A.AssyYn,  A.Amt, A.AccUnit, A.FactUnit, A.InputType,  A.PJTSeq, A.IsProject   , A.BizUnit , A.CostUnit ,    
 --                '2'   --기존투입분에서 투입자재가 LOT전용된건으로 넣어줌.     
 --        FROM _TESMGMatInput AS A JOIN _TESMGWorkReport AS B ON A.CompanySeq = B.CompanySeq   
 --                                                                   AND A.CostKeySeq = B.CostKeySeq   
 --                                                                   AND A.WorkReportSeq = B.WorkReportSeq   
 --                                                                   AND A.WorkSerl      = B.WorkSerl  
 --                           JOIN #CostUnit          AS E ON A.FactUnit = E.FactUnit     
 --                           JOIN (  SELECT F.ConvWorkOrderSeq , F.ConvItemSeq  AS ConvItemSeq , F.ConvAssyItemSeq AS ConvAssyItemSeq , 
 --                                          SUM(F.ConvQty) as ConvQty ,  F.ItemSeq , F.AssyItemSeq        
 --                                     FROM _TESMGLotConvert AS F  JOIN #CostUnit AS E ON F.FactUnit = F.FactUnit    
 --                                    WHERE F.CompanySeq= @CompanySeq   
 --                                      AND F.CostKeySeq= @CostKeySeq     
 --                                      AND ISNULL(F.IsPreProc, '0') = '1'  --전월재공인건. 
 --                                   GROUP BY F.ConvWorkOrderSeq , F.ConvItemSeq  , F.ConvAssyItemSeq   , 
 --                                            F.ItemSeq , F.AssyItemSeq  
 --                                 ) AS X ON  B.WorkOrderSeq= X.ConvWorkOrderSeq AND B.ItemSeq = X.ConvItemSeq 
 --                                        AND A.ItemSeq  = X.AssyItemSeq  --실 투입은 전용할 품목이므로. 
 --         where A.CompanySeq = @CompanySeq    
 --           AND A.CostKeySeq = @CostKeySeq   
 --      GROUP BY  A.CompanySeq, A.CostKeySeq,   A.ItemSerl,   A.WorkSerl, A.RealLotNo, X.ConvAssyItemSeq, X.ConvQty,      
 --                A.ProcSeq   , A.AssyYn,  A.Amt, A.AccUnit, A.FactUnit, A.InputType,  A.PJTSeq, A.IsProject   , A.BizUnit , A.CostUnit  
  
     INSERT INTO _TESMGMatInputLovConv       
         (      
             CompanySeq, CostKeySeq,   ItemSerl, WorkReportSeq, WorkSerl, RealLotNo,  InputDate, ItemSeq, Qty,      
             ProcSeq, AssyYn,  Amt, AccUnit, FactUnit, InputType,  PJTSeq, IsProject   , BizUnit , CostUnit  , DataKind       
         )      
         SELECT DISTINCT  A.CompanySeq, A.CostKeySeq,   A.ItemSerl, A.WorkReportSeq, A.WorkSerl, A.RealLotNo,  A.InputDate, A.ItemSeq, A.Qty,      
                          A.ProcSeq   , A.AssyYn,  A.Amt, A.AccUnit, A.FactUnit, A.InputType,  A.PJTSeq, A.IsProject   , A.BizUnit , A.CostUnit ,    
                          '0'  
           FROM _TESMGMatInput AS A 
                         JOIN _TESMGMatInputLovConv AS B ON A.CompanySeq    = B.CompanySeq   
                                                        AND A.CostKeySeq    = B.CostKeySeq   
                                                        AND A.ItemSerl      = B.ItemSerl   
                                                        AND A.WorkReportSeq = B.WorkReportSeq  
                                                        AND A.WorkSerl      = B.WorkSerl  
                         JOIN #CostUnit AS E ON A.FactUnit = E.FactUnit     
          WHERE A.CompanySeq = @CompanySeq    
            AND A.CostKeySeq = @CostKeySeq   
      
      --투입자재코드가 같다면 수량만 업데이트하면 된다.  
     UPDATE _TESMGMatInput  
         SET  Qty = A.Qty + B.Qty  
       FROM _TESMGMatInput AS A 
                     JOIN _TESMGMatInputLovConv AS B ON A.CompanySeq    = B.CompanySeq   
                                                    AND A.CostKeySeq    = B.CostKeySeq   
                                                    AND A.ItemSerl      = B.ItemSerl  
                                                    AND A.WorkReportSeq = B.WorkReportSeq  
                                                    AND A.WorkSerl      = B.WorkSerl   
                     JOIN #CostUnit             AS E ON A.FactUnit      = E.FactUnit       
      WHERE A.CompanySeq = @CompanySeq    
        AND A.CostKeySeq = @CostKeySeq   
        AND B.DataKind IN ('1' , '2' )  
        AND A.ItemSeq = B.ItemSeq  
     
  
   UPDATE _TESMGMatInput  
         SET   ItemSeq = B.ItemSeq  
       FROM _TESMGMatInput AS A 
                     JOIN _TESMGMatInputLovConv AS B ON A.CompanySeq    = B.CompanySeq   
                                                    AND A.CostKeySeq    = B.CostKeySeq   
                                                    AND A.ItemSerl      = B.ItemSerl  
                                                    AND A.WorkReportSeq = B.WorkReportSeq  
                                                    AND A.WorkSerl      = B.WorkSerl   
                     JOIN #CostUnit             AS E ON A.FactUnit      = E.FactUnit     
   
          where A.CompanySeq = @CompanySeq    
            AND A.CostKeySeq = @CostKeySeq   
            AND B.DataKind   IN ('1' , '2' )  
            AND A.ItemSeq    <> B.ItemSeq  
   
 -------외주입고실적---------------------------------------------------------------------------------------------------      
          
 --처음엔 외주정산테이블에서 외주입고실적을 읽어가도록 했으나 변경. 외주는 입고 = 외주정산과 같다. 구매는 구매입고가 구매입고정산과  
 --다를수 있기 때문에 구매입고대기가 있으나 외주는 외주입고되면 그대로 실적으로 잡히도록 한다. 외주입고와 매입정산에 같이 insert되도록  
 --되어있다.   
 --따라서, 외주입고는 분할해서 외주정산할수 없으며 우리쪽에서도 외주입고테이블의 금액을 외주가공비금액으로 가져간다. Gysong과 결정. 09.09.15 Eykim   
     
   
   --관리회계쪽집계테이블임.     
     INSERT INTO _TESMGOSPDelvInItem   
         (    CompanySeq, CostKeySeq ,  OSPDelvInSeq, OSPDelvInSerl, AccUnit,  FactUnit, InDate, ItemSeq/*제품코드*/,      
              ProcRev , ProcSeq, AssySeq/*외주품목*/,  Qty, Amt,  AccSeq/*외주정산계정*/,  UMCostType/*외주정산비용구분*/,        
              WorkOrderSeq,  ProdDeptSeq, ProdAmt, IsFinalProc, CCtrSeq , BizUnit , CostUnit , PJTSeq , B.WorkCenterSeq   
         )      
         SELECT  @CompanySeq, @CostKeySeq ,  A.OSPDelvInSeq, A.OSPDelvInSerl, E.Accunit, C.FactUnit, C.OSPDelvInDate, A.ItemSeq,       
                 A.ProcRev , ISNULL(Z.ProcSeq, A.ProcSeq) , A.OSPAssySeq, M.StdUnitQty, A.DomAmt, M.AccSeq, 4001001 /*UMCostType*/ , A.WorkOrderSeq, A.ProdDeptSeq, 0/*ProdAmt*/,        
                 CASE WHEN A.WorkOrderSeq = 0 THEN CASE WHEN  A.ItemSeq =A.OSPAssySeq THEN '1' ELSE '0' END  
       ELSE CASE WHEN A.ItemSeq =A.OSPAssySeq THEN '1' ELSE ISNULL(B.IsLastProc, '0') END END ,
 --                ISNULL(H.CCtrSeq, ISNULL(M.CCtrSeq,0))  /*A.CCtrSeq*직접실적테이블에서가져오는것이좋을듯한데..*/ ,      
                 --2011.07.18 지해 : 외주발주에서 외주거래처를 변경한 후 외주정산처리에서 활동센터를 변경하는 경우 발생 
                 -- 따라서 외주정산 기준으로 하고 없으면 외주작업지시의 활동센터를 사용한다.
                 CASE WHEN ISNULL(M.CCtrSeq,0) = 0 THEN ISNULL(H.CCtrSeq,0) 
                      ELSE M.CCtrSeq 
                 END AS CCtrSeq ,
                 E.BizUnit  ,        
                 CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit    
                                     WHEN  5502002 THEN E.AccUnit       
                                     WHEN  5502003 THEN E.BizUnit       
                 END ,    
                 A.PJTSeq ,  ISNULL(B.WorkCEnterSeq      , 0)
           FROM _TPDOSPDelvInItem AS A   
                        JOIN  _TPUBuyingAcc      AS M ON M.CompanySeq    = A.CompanySeq         
                                                     AND M.SourceSeq      = A.OSPDelvInSeq         
                                                     AND M.SourceSerl     = A.OSPDelvInSerl         
                                                     AND M.SourceType     = '2'      
             LEFT OUTER JOIN _TPDSFCWorkOrder    AS B ON A.WorkOrderSeq  = B.WorkOrderSeq 
                                                     AND B.CompanySeq    = @CompanySeq       
                                                     AND A.WorkOrderSerl = B.WorkOrderSerl       
                        JOIN _TPDOSPDelvIn       AS C ON A.OSPDelvInSeq  = C.OSPDelvInSeq 
                                                     AND C.CompanySeq    = @CompanySeq       
                        JOIN #CostUnit           AS E ON C.FactUnit      = E.FactUnit     
             LEFT OUTER JOIN _TPDBaseWorkCenter  AS H ON B.WorkCEnterSeq = H.WorkCenterSeq 
                                                     AND H.CompanySeq    = @CompanySeq        
             --LEFT OUTER JOIN #DeptCCtr AS I ON A.ProdDeptSeq = I.DeptSeq   --외주에 실적부서가 제뉴인엔 없음. 워크센터등록에서 등록된 활동센터로 집계토록 수정. 2010.04.05 eykim   
             LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.ItemSeq     = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                                                                  AND A.OSPAssySeq  = Z.AssyItemSeq
                                                                  AND A.CompanySeq = Z.CompanySeq  
        WHERE A.CompanySeq    = @CompanySeq      
          AND C.OSPDelvInDate BETWEEN @FrDate AND @ToDate    
 --        AND ISNULL(BuyingAccSeq , 0) <> 0     --이조건은 이제 의미없다. 09.15.Eykim  
   
 ---------외주투입실적---------------------------------------------------------------------------------------------      
        
     INSERT INTO  _TESMGOSPDelvInMatInput      
         (      
             CompanySeq, CostKeySeq,  OSPDelvInSeq,  OSPDelvInSerl , OSPDelvInSubSerl,  FactUnit,  AccUnit,      
             InputDate, ItemSeq,  Qty,  Amt , BizUnit , CostUnit , PJTSeq   ,RealLotNo    
         )      
                  
         SELECT  @CompanySeq, @CostKeySeq,    A.OSPDelvInSeq, A.OSPDelvInSerl , A.OSPDelvInSubSerl , C.FactUnit, E.AccUnit,      
                 A.OSPDelvInDate, A.ItemSeq, A.StdUnitQty, 0 , E.BizUnit ,       
                    CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit    
                                        WHEN  5502002 THEN E.AccUnit       
                                        WHEN  5502003 THEN E.BizUnit       
                    END ,    
                  0 AS PJTSeq ,A.LotNoInput    --외주투입은 프로젝트가 없다고함. 생산팀. gysong.   
           FROM _TPUBuyingAcc AS M 
                        JOIN _TPDOSPDelvInItemMat AS A  ON M.SourceSeq    = A.OSPDelvInSeq       
                                                       AND M.SourceSerl   = A.OSPDelvInSerl       
                                                       AND M.SourceType   = '2'       
                                                       AND M.CompanySeq   = A.CompanySeq        
                        JOIN _TPDOSPDelvIn        AS C  ON A.OSPDelvInSeq = C.OSPDelvInSeq      
                                                       AND C.CompanySeq   = @CompanySeq 
                                                       AND A.CompanySeq   = C.CompanySeq       
                        JOIN #CostUnit            AS E  ON C.FactUnit     = E.FactUnit     
             LEFT OUTER JOIN #Item                AS C1 ON A.ItemSeq      = C1.ItemSeq      
                                              
          WHERE A.CompanySeq    = @CompanySeq      
            AND A.OSPDelvInDate BETWEEN @FrDate AND @ToDate      
            AND ISNULL(C1.ItemSeq , 0) =0    
       
       
    
 -----생산입고실적 -------------------------------------------------------------------------------------------------      
        
   
      IF @OutTransType = '0' --생산실적이 외주용역기준일때 
     BEGIN 
    IF @FGoodPricType = 5503005 --개별법
    INSERT INTO _TESMGGoodInSum      
     (      
      CompanySeq, CostKeySeq , GoodInSeq, FactUnit,  AccUnit, InDate,   ItemSeq, Qty,  UnitPrice,      
      Amt, WorkOrderSeq , BizUnit , ProcSeq , DeptSeq  ,CostUnit , PJTSeq    ,CCtrSeq  ,--20100311cctr추가  
      OSPAccSeq ,  OSPUMCostType , OSPCost, RealLotNo 
     )      
     SELECT @CompanySeq, @CostKeySeq , A.GoodInSeq, A.FactUnit, E.AccUnit ,  A.InDate, A.goodItemSeq, A.StdProdQty, A.UnitPrice,      
         A.Amt, A.WorkOrderSeq  , E.BizUnit ,   ISNULL(Z.ProcSeq, G.ProcSeq)  ,  G.DeptSeq ,      
         CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
              WHEN  5502002 THEN E.AccUnit       
              WHEN  5502003 THEN E.BizUnit       
         END, 
         A.PJTSeq     , H.CCtrSeq,
         0, 0, 0, --A.RealLotNo   
         CASE WHEN D.IsLotMng ='1' THEN A.RealLotNo ELSE '' END --개별법인 경우 LOTNO 관리하는 품목만 LotNO를 넣어준다. 정연아
       FROM _TPDSFCGoodIn AS A      
           JOIN #CostUnit          AS E               ON A.FactUnit      = E.FactUnit     
           JOIN _TPDSFCWorkReport  AS G               ON A.WorkReportSeq = G.WorkReportSeq  
                    AND A.CompanySeq    = G.CompanySeq       
           JOIN _TPDBaseWorkCenter AS H               ON G.WorkCEnterSeq = H.WorkCenterSeq 
                    AND G.CompanySeq    = H.CompanySeq      
  --                LEFT OUTER JOIN #DeptCCtr AS I ON G.DeptSeq = I.DeptSeq    
      LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq   = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                    AND A.GoodItemSeq   = Z.AssyItemSeq
                    AND A.CompanySeq   = Z.CompanySeq  
           JOIN _TDAItemStock AS D ON A.goodItemSeq = D.ItemSeq AND D.CompanySeq = @CompanySeq                 
      WHERE A.CompanySeq = @CompanySeq      --연산품도 같은 공정을 이용하므로 WorkReport만 걸어주면 된다.       
        AND A.InDate  BETWEEN @FrDate AND @ToDate   
   ELSE  
    INSERT INTO _TESMGGoodInSum      
     (      
      CompanySeq, CostKeySeq , GoodInSeq, FactUnit,  AccUnit, InDate,   ItemSeq, Qty,  UnitPrice,      
      Amt, WorkOrderSeq , BizUnit , ProcSeq , DeptSeq  ,CostUnit , PJTSeq    ,CCtrSeq  ,--20100311cctr추가  
      OSPAccSeq ,  OSPUMCostType , OSPCost, RealLotNo 
     )      
     SELECT @CompanySeq, @CostKeySeq , A.GoodInSeq, A.FactUnit, E.AccUnit ,  A.InDate, A.goodItemSeq, A.StdProdQty, A.UnitPrice,      
         A.Amt, A.WorkOrderSeq  , E.BizUnit ,   ISNULL(Z.ProcSeq, G.ProcSeq)  ,  G.DeptSeq ,      
         CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
              WHEN  5502002 THEN E.AccUnit       
              WHEN  5502003 THEN E.BizUnit       
         END, 
         A.PJTSeq     , H.CCtrSeq,
         0, 0, 0, --A.RealLotNo   
         '' --LOTNO 관리하는 품목만 LotNO를 넣어준다. 정연아
       FROM _TPDSFCGoodIn AS A      
           JOIN #CostUnit          AS E               ON A.FactUnit      = E.FactUnit     
           JOIN _TPDSFCWorkReport  AS G               ON A.WorkReportSeq = G.WorkReportSeq  
                    AND A.CompanySeq    = G.CompanySeq       
           JOIN _TPDBaseWorkCenter AS H               ON G.WorkCEnterSeq = H.WorkCenterSeq 
                    AND G.CompanySeq    = H.CompanySeq      
  --                LEFT OUTER JOIN #DeptCCtr AS I ON G.DeptSeq = I.DeptSeq    
      LEFT OUTER JOIN _TESMBStdProcAsItem AS Z WITH(NOLOCK) ON A.GoodItemSeq   = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                    AND A.GoodItemSeq   = Z.AssyItemSeq
                    AND A.CompanySeq   = Z.CompanySeq  
         
      WHERE A.CompanySeq = @CompanySeq      --연산품도 같은 공정을 이용하므로 WorkReport만 걸어주면 된다.       
        AND A.InDate  BETWEEN @FrDate AND @ToDate  
     END 
     ELSE  --입고가 외주용역비 기준일때 
     BEGIN 
   IF @FGoodPricType = 5503005 --개별법
    INSERT INTO _TESMGGoodInSum      
     (      
      CompanySeq, CostKeySeq , GoodInSeq, FactUnit,  AccUnit, InDate,   ItemSeq, Qty,  UnitPrice,      
      Amt, WorkOrderSeq , BizUnit , ProcSeq , DeptSeq  ,CostUnit , PJTSeq    ,CCtrSeq , --20100311cctr추가  
      OSPAccSeq ,  OSPUMCostType , OSPCost, RealLotNo   
     )      
     SELECT @CompanySeq, @CostKeySeq , A.GoodInSeq, A.FactUnit, E.AccUnit ,  A.InDate, A.goodItemSeq, A.StdProdQty, A.UnitPrice,      
         A.Amt, A.WorkOrderSeq  , E.BizUnit ,   ISNULL(Z.ProcSeq, G.ProcSeq)   ,  G.DeptSeq ,      
         CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
              WHEN  5502002 THEN E.AccUnit       
              WHEN  5502003 THEN E.BizUnit       
         END,
         A.PJTSeq     ,H.CCtrSeq,
         ISNULL(R.ProcAccSeq , 0) , CASE WHEN ISNULL(R.ProcAccSeq , 0) <> 0 THEN 4001001 ELSE 0 END/*UMCostType*/ , ISNULL(R.DomAmt , 0)  --사내외주가공비
         , CASE WHEN D.IsLotMng ='1' THEN A.RealLotNo ELSE '' END ---A.RealLotNo
       FROM _TPDSFCGoodIn AS A      
            JOIN #CostUnit                 AS E              ON A.FactUnit      = E.FactUnit     
            JOIN _TPDSFCWorkReport          AS G              ON A.WorkReportSeq = G.WorkReportSeq  
                      AND A.CompanySeq    = G.CompanySeq       
            JOIN _TPDBaseWorkCenter         AS H              ON G.WorkCEnterSeq = H.WorkCenterSeq 
                      AND G.CompanySeq    = H.CompanySeq      
  --                                   LEFT OUTER JOIN #DeptCCtr AS I ON G.DeptSeq = I.DeptSeq  
       LEFT OUTER JOIN _TPDSFCOutsourcingCostItem AS R WITH(NOLOCK) ON A.CompanySeq    = R.CompanySeq 
                      AND A.GoodInSeq     = R.WorkReportSeq
       LEFT OUTER JOIN _TESMBStdProcAsItem        AS Z WITH(NOLOCK) ON A.GoodItemSeq   = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                      AND A.GoodItemSeq   = Z.AssyItemSeq
                      AND A.CompanySeq   = Z.CompanySeq 
          JOIN _TDAItemStock AS D ON A.goodItemSeq = D.ItemSeq AND D.CompanySeq = @CompanySeq  
      WHERE A.CompanySeq = @CompanySeq      --연산품도 같은 공정을 이용하므로 WorkReport만 걸어주면 된다.       
        AND A.InDate     BETWEEN @FrDate AND @ToDate      
   ELSE
    INSERT INTO _TESMGGoodInSum      
     (      
      CompanySeq, CostKeySeq , GoodInSeq, FactUnit,  AccUnit, InDate,   ItemSeq, Qty,  UnitPrice,      
      Amt, WorkOrderSeq , BizUnit , ProcSeq , DeptSeq  ,CostUnit , PJTSeq    ,CCtrSeq , --20100311cctr추가  
      OSPAccSeq ,  OSPUMCostType , OSPCost, RealLotNo   
     )      
     SELECT @CompanySeq, @CostKeySeq , A.GoodInSeq, A.FactUnit, E.AccUnit ,  A.InDate, A.goodItemSeq, A.StdProdQty, A.UnitPrice,      
         A.Amt, A.WorkOrderSeq  , E.BizUnit ,   ISNULL(Z.ProcSeq, G.ProcSeq)   ,  G.DeptSeq ,      
         CASE @FGoodCostUnit WHEN  5502001 THEN E.FactUnit      
              WHEN  5502002 THEN E.AccUnit       
              WHEN  5502003 THEN E.BizUnit       
         END,
         A.PJTSeq     ,H.CCtrSeq,
         ISNULL(R.ProcAccSeq , 0) , CASE WHEN ISNULL(R.ProcAccSeq , 0) <> 0 THEN 4001001 ELSE 0 END/*UMCostType*/ , ISNULL(R.DomAmt , 0)  --사내외주가공비
         , '' ---A.RealLotNo
       FROM _TPDSFCGoodIn AS A      
            JOIN #CostUnit                  AS E              ON A.FactUnit      = E.FactUnit     
            JOIN _TPDSFCWorkReport          AS G              ON A.WorkReportSeq = G.WorkReportSeq  
                      AND A.CompanySeq    = G.CompanySeq       
            JOIN _TPDBaseWorkCenter         AS H               ON G.WorkCEnterSeq = H.WorkCenterSeq 
                      AND G.CompanySeq    = H.CompanySeq      
  --                                   LEFT OUTER JOIN #DeptCCtr AS I ON G.DeptSeq = I.DeptSeq  
       LEFT OUTER JOIN _TPDSFCOutsourcingCostItem AS R WITH(NOLOCK) ON A.CompanySeq    = R.CompanySeq 
                      AND A.GoodInSeq     = R.WorkReportSeq
       LEFT OUTER JOIN _TESMBStdProcAsItem        AS Z WITH(NOLOCK) ON A.GoodItemSeq   = Z.ItemSeq    --대표공정으로 집계하도록 수정 2011.03.14 sjjin 수정
                      AND A.GoodItemSeq   = Z.AssyItemSeq
                      AND A.CompanySeq   = Z.CompanySeq 
      WHERE A.CompanySeq = @CompanySeq      --연산품도 같은 공정을 이용하므로 WorkReport만 걸어주면 된다.       
        AND A.InDate     BETWEEN @FrDate AND @ToDate  
      END 
     
  ---------------------------------------------------------------------------------------------------------------------      
        
  
   
     IF @@ERROR <> 0         
     BEGIN        
        
         EXEC dbo._SCOMMessage @MessageType OUTPUT,        
                               @Status      OUTPUT,        
                               @Result     OUTPUT,        
                               1055                  , --처리작업중 에러가 발생했습니다. 다시 처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)        
                               @LanguageSeq       ,         
                               0,''         
          
         UPDATE #WorkReport          
             SET Result        = @Result,         
                 MessageType   = @MessageType,          
                 Status        = @Status          
           FROM #WorkReport  
     END       
       
    ------------------------------------------------------------------------
   --개별원가일 경우 WorkOrderSeq 와 RealLotNo연결은 1:1 또는 1:N 이어야 한다. 즉, WorkOrderSeq가 같은 RealLotNo는 허용한다.   
  --그러나 WorkOrderSeq 다른데 RealLotNO가 같을순 없다. 투입Lot과  WorkOrderSeq가 연결되어야 하기 때문이다. 계산순서를 정하기 위해서.   
  --입고테이블의 WorkOrderSeq와 RealLotNo를 기준으로 연결데이터를 생성한다.   
  
  IF @IsLotCost = '1' 
  BEGIN 
       DELETE _TESMGWorkOrderLinkLotNo  
          WHERE CompanySeq = @CompanySeq       
            AND CostKeySeq  = @CostKeySeq          
         
  
   INSERT INTO _TESMGWorkOrderLinkLotNo (CompanySeq , CostKeySeq, CostUnit, ItemSeq , WorkOrderSeq ,RealLotNo, CreateDate)   
     SELECT DISTINCT @CompanySeq , @CostKeySeq , A.CostUnit , A.ItemSeq , A.WorkOrderSeq ,CASE WHEN @FGoodPricType = 5503005 THEN  ISNULL(A.RealLotNo,'') ELSE '' END  , MAX(A.WorkDate)  
       FROM _TESMGWorkReport AS A JOIN #CostUnit  AS E  ON A.FactUnit      = E.FactUnit      
      WHERE A.CompanySeq = @CompanySeq       
        AND A.CostKeySeq = @CostKeySeq      
   AND A.ItemSeq = A.AssyItemSeq    
        group by   A.CostUnit , A.ItemSeq , A.WorkOrderSeq , ISNULL(A.RealLotNo,'')  
             
     UNION   
     SELECT DISTINCT @CompanySeq , @CostKeySeq , A.CostUnit , A.ItemSeq , A.WorkOrderSeq , CASE WHEN @FGoodPricType = 5503005 THEN  ISNULL(A.RealLotNo,'') ELSE '' END , MAX(A.InDate)  
       FROM _TESMGOSPDelvInItem AS A JOIN #CostUnit  AS E  ON A.FactUnit      = E.FactUnit         
      WHERE A.CompanySeq = @CompanySeq       
        AND A.CostKeySeq = @CostKeySeq      
        AND A.ItemSeq = A.AssySeq    
      group by   A.CostUnit , A.ItemSeq , A.WorkOrderSeq , ISNULL(A.RealLotNo,'') 
   
  END 
        
     -------------------------------------------------------------------------
       
     UPDATE #WorkReport        
        SET EndTime      = GETDATE(),        
            UserName     = (SELECT TOP 1  UserName         
                              FROM _TCAUser      
                             WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq)        
      WHERE Status = 0          
       
        
     SELECT * FROM #WorkReport       
        
         
     RETURN     
GO 

begin tran 

    


exec KPX_SESMGWorkReport @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <RptUnit>0</RptUnit>
    <CostYM>201503</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <CostMngAmdSeq>0</CostMngAmdSeq>
    <CostKeySeq>51</CostKeySeq>
    <CostUnit>2</CostUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=3071,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3565
rollback 