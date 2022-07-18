IF OBJECT_ID('KPXLS_SPUDelvInItemSave') IS NOT NULL 
    DROP PROC KPXLS_SPUDelvInItemSave
GO 

-- v2016.01.12 

-- 구매입고입력 LotMaster 입고일자 upd력te 로직 추가 by 이재천 
/************************************************************      
설  명 - 구매입고    
작성일 - 2008년 8월 20일       
작성자 - 노영진      
수정일 - 2009년 7월 15일    
수정자 - 김현    
수정일 - 2010년 5월 4일 UPDATEd BY 박소연 :: 출납방법 추가    
         2010년10월20일 UPDATEd BY 천경민 :: 구매요청에서 입력한 활동센터가 있으면 해당 활동센터를 입고정산테이블에 저장    
         2011년4월  7일 UPDATEd BY 윤삼혁 :: 프로젝트일 경우 프로젝트의 활동센터로   
         2011년11월16일 UPDATED BY 김세호 :: 프로젝트 부가세계정 가져올때 PgmSeq 프로젝트구매납품(200107) 일경우 추가 (자동입고일 경우 대비)  
         2012년01월10일 UPDATED BY 김세호 :: UPDATE 시 _TPUBuyingAcc 에 통화, 환율 반영안되도록 (구매입고마스터 저장(_SPUDelvInSave)에서 처리) 
         2012년03월09일 UPDATED BY 김세호 :: 프로젝트 입고건일경우 전표유형 '프로젝트구매외주매입정산'에서 계정 가져오도록 수정
************************************************************/      
CREATE PROC KPXLS_SPUDelvInItemSave
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS          
    DECLARE @AccSeq         INT,    
            @AntiAccSeq     INT,    
            @VatAccSeq      INT,    
            @SlipAutoEnvSeq INT,    
            @SMImpType      INT,    
            @SlipType  INT    
    
IF @WorkingTag <> 'AUTO'    
BEGIN    
    -- 서비스 마스타 등록 생성      
    CREATE TABLE #TPUDelvInItem (WorkingTag NCHAR(1) NULL)        
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUDelvInItem'     
    
    -- 출납방법/ 지불일자 가져오기 20100504 박소연 추가    
 DECLARE @SMRNPMethod INT, @PayDate NCHAR(8), @CustSeq INT, @DelvInDate NCHAR(8), @SMPayMethod INT    
 ALTER TABLE #TPUDelvInItem ADD SMRNPMethod INT, PayDate NCHAR(8)    
    
    SELECT @CustSeq    = CustSeq,     
           @DelvInDate = DelvInDate    
      FROM #TPUDelvInItem     
    
    SELECT @SMRNPMethod = SMRNPMethod,    
           @PayDate     = PayDate,    
           @SMPayMethod = SMPayMethod    
      FROM dbo._FPDGetSMRNPMethod(@CompanySeq, 4012, @CustSeq, @DelvInDate)    
    
 UPDATE A    
       SET A.SMRNPMethod = ISNULL(@SMRNPMethod, 0)    
           ,A.PayDate    = ISNULL(@PayDate, '')    
           ,A.SMPayType  = ISNULL(@SMPayMethod, '')    
      FROM #TPUDelvInItem AS A          
    
    IF @@ERROR <> 0 RETURN          
END    

    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)      
    EXEC _SCOMLog  @CompanySeq,    
                   @UserSeq,    
                   '_TPUDelvInItem',     
                   '#TPUDelvInItem',    
                   'DelvInSeq, DelvInSerl',    
                   'CompanySeq,DelvInSeq,DelvInSerl,SMImpType,SMDelvType,SMStkType,ItemSeq,UnitSeq,Price,DomPrice,Qty,CurAmt,DomAmt,StdUnitSeq,StdUnitQty,IsVAT,CurVAT,DomVAT,WHSeq,SalesCustSeq,DelvCustSeq,LOTNo,FromSerial,ToSerial,SMPayType,AccSeq,AntiAccSeq,IsFiction,FicRateNum,FicRateDen,EvidSeq,PJTSeq,WBSSeq,Remark,IsReturn,SlipSeq,TaxDate,PayDate,SourceType,SourceSeq,SourceSerl,LastUserSeq,LastDateTime'    

    
    -- 원천 테이블    
    CREATE TABLE #TMP_SOURCETABLE    
    (    
        IDOrder     INT,    
        TABLENAME   NVARCHAR(100)    
    )    
              
    -- 원천 데이터 테이블    
    CREATE TABLE #TCOMSourceTracking    
    (    
        IDX_NO      INT,    
        IDOrder     INT,    
        Seq         INT,    
        Serl        INT,    
        SubSerl     INT,    
        Qty         DECIMAL(19,5),    
        STDQty      DECIMAL(19,5),    
        Amt         DECIMAL(19,5),    
        VAT         DECIMAL(19,5)    
    )    
    
 -- 폼세부정보분개 방식인지 테이블 방식인지 가져오기    
 SELECT @SlipType = JourMethod     
   FROM _TACSlipKind    
  WHERE CompanySeq = @CompanySeq    
    AND SlipKindNo = 'FrmPUBuyingAcc'    
    
    
    
    
 IF @SlipType = 4030002 -- 폼정보자동분개    
 BEGIN    
  --자동전표코드 가져오기    
  SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
    FROM _TACSlipKind                    AS A WITH(NOLOCK)     
      LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                AND A.SlipKindNo = B.SlipKindNo    
   WHERE A.CompanySeq = @CompanySeq    
     AND A.SlipKindNo = 'FrmPUBuyingAcc'     
    
  -- 부가세계정 가져오기    
  SELECT @VatAccSeq = B.AccSeq    
   FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)    
        JOIN _TDAAccount  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
              AND A.AccSeq    = B.AccSeq      
              AND B.SMAccType  = 4002009    
  WHERE A.companyseq     = @CompanySeq      
    AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
    
    IF EXISTS(SELECT 1 FROM #TPUDelvInItem AS A
                       JOIN _TPUDelvIn     AS B ON A.DelvInSeq = B.DelvInSeq
                                               AND @CompanySeq = B.CompanySeq
                      WHERE ISNULL(B.IsPJT, '0') = '1')     -- 프로젝트 입고건일경우 전표유형 '프로젝트구매외주매입정산'에서 계정 가져오도록 수정 -12 .03.09 BY 김세호
    BEGIN   
        SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq    
          FROM _TACSlipKind                    AS A WITH(NOLOCK)     
            LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                      AND A.SlipKindNo = B.SlipKindNo    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.SlipKindNo = 'FrmPUBuyingAcc_PMSPur'     
        
        -- 부가세계정 가져오기    
        SELECT @VatAccSeq = B.AccSeq    
         FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)    
           JOIN _TDAAccount  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
                    AND A.AccSeq    = B.AccSeq      
                    AND B.SMAccType  = 4002009    
        WHERE A.companyseq     = @CompanySeq      
          AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq     
        
   END     
  
 END    
  
  
 ELSE IF @SlipType = 4030003 -- 테이블정보자동분개    
 BEGIN    
  SELECT @VatAccSeq = B.AccSeq    
       FROM _TACSlipRowAutoEnvTable AS A WITH(NOLOCK)     
      JOIN _TDAAccount     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq     
              AND A.AccSeq  = B.AccSeq      
              AND B.SMAccType  = 4002009    
   WHERE A.Companyseq = @CompanySeq     
     AND A.SlipKindNo = 'FrmPUBuyingAcc'    
 END     
     
    -- 구매반품건은 - 수량으로 저장     
    UPDATE #TPUDelvInItem    
       SET Price      = Price ,    
           DomPrice   = DomPrice,    
           Qty        = - Qty   ,    
           CurAmt     = - CurAmt,    
           DomAmt     = - DomAmt,    
           CurVAT     = - CurVAT,    
           DomVAT     = - DomVAT,    
           StdUnitQty = - StdUnitQty     
     WHERE ISNULL(IsReturn, '') = '1'    
         
    -- 구매반품건은 입고 마스터에 반품 여부 체크    
    UPDATE _TPUDelvIn    
       SET IsReturn = '1'    
      FROM _TPUDelvIn          AS A    
           JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq                                       
     WHERE A.CompanySeq = @CompanySeq    
       AND ISNULL(B.IsReturn, '') = '1'    
    
    -- 마스터의 내외자구분 가져오기    
    SELECT @SMImpType = MAX(A.SMImpType)    
      FROM _TPUDelvIn          AS A WITH(NOLOCK)     
           JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq    
     WHERE A.CompanySeq = @CompanySeq    
    
    
    -- DELETE          
    IF EXISTS (SELECT TOP 1 1 FROM #TPUDelvInItem WHERE WorkingTag = 'D' AND Status = 0)        
    BEGIN        
        DELETE _TPUDelvInItem      
          FROM _TPUDelvInItem      AS A     
               JOIN #TPUDelvInItem AS B ON A.DelvInSeq  = B.DelvInSeq       
                                       AND A.DelvInSerl = B.DelvInSerl      
         WHERE B.WorkingTag = 'D'     
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq      
    
        IF @@ERROR <> 0  RETURN      
    
        DELETE _TPUBuyingAcc      
          FROM _TPUBuyingAcc AS A     
               JOIN #TPUDelvInItem AS B ON A.CompanySeq = @CompanySeq    
                                       AND A.SourceSeq  = B.DelvInSeq    
                                       AND A.SourceSerl = B.DelvINSerl    
                                       AND A.SourceType = '1'     
         WHERE B.WorkingTag = 'D'     
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq      
    
        IF @@ERROR <> 0  RETURN      
    END      
      
    -- UPDATE          
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE WorkingTag = 'U' AND Status = 0)        
    BEGIN      
        UPDATE _TPUDelvInItem      
           SET        
                SMImpType    = @SMImpType     ,    
                SMDelvType   = B.SMDelvType   ,    
                SMStkType    = B.SMStkType    ,    
                ItemSeq      = B.ItemSeq      ,    
           UnitSeq      = B.UnitSeq      ,    
                Price        = B.Price        ,    
                DomPrice     = B.DomPrice     ,    
                Qty          = B.Qty          ,    
                CurAmt       = B.CurAmt       ,    
                DomAmt       = B.DomAmt       ,    
                StdUnitSeq   = B.StdUnitSeq   ,    
                StdUnitQty   = B.StdUnitQty   ,    
                IsVAT        = B.IsVAT        ,    
                CurVAT       = B.CurVAT       ,    
                DomVAT       = B.DomVAT       ,    
                WHSeq        = B.WHSeq        ,    
                SalesCustSeq = B.SalesCustSeq ,    
                DelvCustSeq  = B.DelvCustSeq  ,    
                LOTNo        = B.LotNo        ,    
                FromSerial   = B.FromSerial   ,    
                ToSerial     = B.ToSerial     ,    
                SMPayType    = B.SMPayType    ,       
                IsFiction    = B.IsFiction    ,    
                FicRateNum   = B.FicRateNum   ,    
                FicRateDen   = B.FicRateDen   ,    
                EvidSeq      = B.EvidSeq      ,    
                PJTSeq       = B.PJTSeq       ,    
                WBSSeq       = B.WBSSeq       ,     
                Remark       = B.Remark       ,    
                IsReturn     = B.IsReturn     ,    
                LastUserSeq      = @UserSeq,      
                LastDateTime     = GETDATE(),
                SMPriceType  = B.SMPriceType       
          FROM _TPUDelvInItem      AS A     
               JOIN #TPUDelvInItem AS B ON A.DelvInSeq = B.DelvInSeq       
                                       AND A.DelvInSerl = B.DelvInSerl      
         WHERE B.WorkingTag = 'U'       
           AND B.Status = 0          
           AND A.CompanySeq  = @CompanySeq        
    
        IF @@ERROR <> 0  RETURN      
    END         
    
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE  WorkingTag = 'U' AND Status = 0)        
    BEGIN        
        UPDATE _TPUBuyingAcc    
           SET        
                ItemSeq       = B.ItemSeq        ,    
                UnitSeq       = B.UnitSeq        ,    
--                CurrSeq       = B.CurrSeq        ,    
--                ExRate        = B.ExRate         ,    
                Price         = B.Price          ,    
                DomPrice      = B.DomPrice       ,    
                Qty           = B.Qty            ,    
                PriceUnitSeq  = B.UnitSeq        ,    
                PriceQty      = B.Qty            ,    
                CurAmt        = B.CurAmt         ,    
                CurVAT        = B.CurVAT         ,    
                DomAmt        = B.DomAmt         ,    
                DomVAT        = B.DomVAT         ,    
                StdUnitSeq    = B.StdUnitSeq     ,    
                StdUnitQty    = B.StdUnitQty     ,    
                IsVAT         = B.IsVAT          ,    
                SMImpType     = B.SMImpType      ,    
                WHSeq         = B.WHSeq          ,    
                DelvCustSeq   = B.DelvCustSeq    ,    
                SMPayType     = B.SMPayType      ,       
                IsFiction     = B.IsFiction      ,    
                FicRateNum    = B.FicRateNum     ,    
                FicRateDen    = B.FicRateDen     ,    
                EvidSeq       = B.EvidSeq        ,    
                PjtSeq        = B.PjtSeq         ,    
                WBSSeq        = B.WBSSeq         ,    
                Remark        = B.Remark         ,    
                LastUserSeq   = @UserSeq         ,    
                LastDateTime  = GETDATE()        ,    
                PayDate       = B.PayDate        ,    
                SMRNPMethod   = B.SMRNPMethod        
         FROM _TPUBuyingAcc       AS A     
              JOIN #TPUDelvInItem AS B ON A.SourceSeq  = B.DelvInSeq    
            AND A.SourceSerl = B.DelvINSerl    
                                      AND A.SourceType = '1'    
     WHERE A.CompanySeq = @CompanySeq    
              
        IF @@ERROR <> 0  RETURN      
    
        -- 활동센터 추가 2010.05.11 by bgKeum    
        UPDATE _TPUBuyingAcc    
           SET CCtrSeq      = ISNULL(CC.CCtrSeq, 0)    
          FROM _TPUBuyingAcc AS A JOIN #TPUDelvInItem AS B    
                                    ON A.SourceSeq  = B.DelvInSeq    
                                   AND A.SourceSerl = B.DelvINSerl    
                                   AND A.SourceType = '1'    
                                  JOIN dbo._FnAdmEmpCCtr(@CompanySeq, @DelvInDate) AS CC     
                  ON A.EmpSeq = CC.EmpSeq       
         WHERE A.CompanySeq = @CompanySeq    
           AND (A.CCtrSeq   = 0 OR A.CCtrSeq IS NULL)    
    
        IF @@ERROR <> 0  RETURN     
    
    END    
    
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #TPUDelvInItem WHERE WorkingTag = 'A' AND Status = 0)        
    BEGIN        
        INSERT INTO _TPUDelvInItem(CompanySeq   ,DelvInSeq    ,DelvInSerl   ,SMImpType     ,SMDelvType   ,    
                                    SMStkType    ,ItemSeq      ,UnitSeq      ,--CurrSeq      ,ExRate       ,    
                                    Price        ,Qty          ,CurAmt       ,DomAmt       ,StdUnitSeq   ,    
                                    StdUnitQty   ,CurVAT     ,WHSeq        ,SalesCustSeq ,DelvCustSeq  ,    
                                    LOTNo        ,FromSerial   ,ToSerial     ,SMPayType    ,    
                                    AccSeq   ,    
                                    AntiAccSeq   ,    
                                    IsFiction    ,FicRateNum   ,FicRateDen   ,EvidSeq      ,    
                                    PJTSeq       ,WBSSeq       ,Remark       ,IsReturn     ,LastUserSeq  ,    
                                    DomPrice     ,DomVAT       ,IsVAT        ,    
                                    LastDateTime ,SupplyAmt	   ,SupplyVAT    ,SMPriceType)      
    
        SELECT  @CompanySeq    ,A.DelvInSeq    ,A.DelvInSerl   ,A.SMImpType      ,A.SMDelvType   ,    
                A.SMStkType    ,A.ItemSeq      ,A.UnitSeq      ,--A.CurrSeq        ,A.ExRate       ,    
                A.Price        ,A.Qty          ,A.CurAmt       ,A.DomAmt         ,A.StdUnitSeq   ,    
                A.StdUnitQty   ,A.CurVAT       ,A.WHSeq        ,A.SalesCustSeq   ,A.DelvCustSeq  ,    
                A.LotNo        ,A.FromSerial   ,A.ToSerial     ,A.SMPayType      ,    
                CASE ISNULL(A.AccSeq, 0)     WHEN 0 THEN T.AccSeq  ELSE ISNULL(A.AccSeq, 0)     END AS AccSeq,    
--                 CASE ISNULL(A.AntiAccSeq, 0) WHEN 0 THEN TT.AccSeq ELSE ISNULL(A.AntiAccSeq, 0) END AS AntiAccSeq,    
                CASE WHEN @SMImpType = 8008001 THEN ISNULL(TT.AccSeq, 0) ELSE ISNULL(TTT.AccSeq, 0) END AS AntiAccSeq,    
                A.IsFiction    ,A.FicRateNum   ,A.FicRateDen   ,A.EvidSeq        ,    
                A.PJTSeq       ,A.WBSSeq      ,A.Remark       ,A.IsReturn       ,@UserSeq     ,    
                A.DomPrice     ,A.DomVAT       ,A.IsVAT        ,     
                GETDATE()	   ,A.DomAmt	   ,0              ,SMPriceType--A.DomVAT		-- 2012. 5. 22 공급가액 컬럼 추가 hkim
          FROM #TPUDelvInItem AS A         
                LEFT OUTER JOIN _TDAItem         AS B ON B.CompanySeq  = @CompanySeq    
                                                     AND A.ItemSeq     = B.ItemSeq    
                LEFT OUTER JOIN _TDAItemAssetAcc AS S WITH(NOLOCK) ON B.CompanySeq  = S.CompanySeq     --      
                                                                  AND B.AssetSeq    = S.AssetSeq     
                                                                  AND S.AssetAccKindSeq = 1    
                LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON S.CompanySeq = T.CompanySeq    
                                                               AND S.AccSeq   = T.AccSeq      
                LEFT OUTER JOIN _TDAItemAssetAcc AS SS WITH(NOLOCK) ON B.CompanySeq  = SS.CompanySeq     --      
                                                       AND B.AssetSeq    = SS.AssetSeq     
                                                                  AND SS.AssetAccKindSeq = 9    
                LEFT OUTER JOIN _TDAAccount      AS TT WITH(NOLOCK) ON SS.CompanySeq = TT.CompanySeq    
                                                               AND SS.AccSeq   = TT.AccSeq      
                LEFT OUTER JOIN _TDAItemAssetAcc AS SSS WITH(NOLOCK) ON B.CompanySeq  = SSS.CompanySeq     --  Local 채무계정이 들어가도록 수정    
                                                                  AND B.AssetSeq    = SSS.AssetSeq     
                                                                  AND SSS.AssetAccKindSeq = 12    
                LEFT OUTER JOIN _TDAAccount      AS TTT WITH(NOLOCK) ON SSS.CompanySeq = TTT.CompanySeq    
                                                                  AND SSS.AccSeq   = TTT.AccSeq      
         WHERE A.WorkingTag = 'A' AND A.Status = 0          
    
        IF @@ERROR <> 0 RETURN      
    
        -------------------------    
        -- 입고정산 데이터 생성--    
        -------------------------    
        DECLARE @DataSeq INT,    
                @BuyingAccSeq INT,    
                @count INT    
    
        SELECT  @DataSeq = 0    
              
        WHILE ( 1 = 1 )             
        BEGIN            
            SELECT TOP 1 @DataSeq = DataSeq        
            FROM #TPUDelvInItem            
             WHERE WorkingTag = 'A'            
               AND Status = 0            
               AND DataSeq > @DataSeq            
             ORDER BY DataSeq            
    
            IF @@ROWCOUNT = 0 BREAK         
    
            SELECT @count = COUNT(*)              
       FROM #TPUDelvInItem              
             WHERE WorkingTag = 'A' AND Status = 0                
                      
            IF @count > 0            
            BEGIN            
                EXEC @BuyingAccSeq = _SCOMCreateSeq @CompanySeq, '_TPUBuyingAcc', 'BuyingAccSeq', 1             
            END            
    
            UPDATE #TPUDelvInItem            
               SET BuyingAccSeq = @BuyingAccSeq + 1    
             WHERE WorkingTag = 'A'            
               AND Status = 0            
               AND DataSeq = @DataSeq           
    
            IF @WorkingTag = 'D'    
                UPDATE #TPUBuyingAcc          
                   SET WorkingTag = 'D'          
        END    
    
        -- 구매요청 원천 데이터 가져오기(구매납품코드로 구매요청의 활동센터 가져오기 위함) 추가 by 천경민    
        INSERT #TMP_SOURCETABLE    
        SELECT 1, '_TPUORDPOReqItem'   -- 구매요청품목    
    
    
        IF @WorkingTag <> 'AUTO'    
            EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvInItem', 'FromSeq', 'FromSerl', ''    
        ELSE  -- 구매납품에서 자동입고시 납품내부코드명 다르게    
            EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#TPUDelvInItem', 'SourceSeq', 'SourceSerl', ''    
    
    
        SELECT DISTINCT A.IDX_NO, B.CCtrSeq -- 중복 저장 오류 발생해서 수정 2011. 1. 21 hkim    
          INTO #CCtrSeq    
          FROM #TCOMSourceTracking   AS A    
               JOIN _TPUORDPOReqItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                      AND A.Seq        = B.POReqSeq    
                                                      AND A.Serl       = B.POReqSerl    
               JOIN _TPUORDPOReq     AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq    
                                                      AND B.POReqSeq   = C.POReqSeq    
    
    
/*    
활동센터 세팅 순서    
IF 프로젝트    
 무조건 프로젝트의 활동센터    
ELSE    
 1. 구매요청의 활동센터    
 2. 구매입고부서의 활동센터    
*/    
    
        INSERT INTO _TPUBuyingAcc(CompanySeq         ,BuyingAccSeq     ,SourceType       ,SourceSeq        ,SourceSerl       ,    
                                    BizUnit          ,FactUnit         ,BuyingAccDate    ,DelvInNo         ,DelvInDate       ,    
                                    ItemSeq          ,CustSeq          ,EmpSeq           ,DeptSeq         ,UnitSeq          ,    
                                    CurrSeq          ,ExRate           ,Price            ,DomPrice         ,Qty              ,    
                                    PriceUnitSeq     ,PriceQty         ,CurAmt           ,CurVAT           ,DomAmt           ,    
                                    DomVAT           ,StdUnitSeq       ,StdUnitQty       ,IsVAT            ,SMImpType        ,    
                                    WHSeq            ,DelvCustSeq      ,SMPayType        ,AccSeq           ,MatAccSeq        ,    
                                    AntiAccSeq       ,VatAccSeq        ,IsFiction        ,FicRateNum       ,FicRateDen       ,    
                                    EvidSeq          ,PjtSeq           ,WBSSeq           ,Remark           ,IsReturn         ,    
                                    SlipSeq          ,TaxDate          ,PayDate          ,ImpDomAmt        ,ImpCurAmt        ,    
								    LastUserSeq      ,LastDateTime     ,SMRNPMethod      ,CCtrSeq		   ,SupplyAmt		 ,SupplyVAT) -- 활동센터 추가 2010.05.11 by bgKeum    
        SELECT A.CompanySeq ,C.BuyingAccSeq ,'1'            ,A.DelvInSeq            ,A.DelvInSerl       ,    
               B.BizUnit    ,0              ,B.DelvInDate   ,B.DelvInNo             ,B.DelvInDate       ,    
               A.ItemSeq    ,B.CustSeq      ,B.EmpSeq       ,B.DeptSeq              ,A.UnitSeq          ,    
               B.CurrSeq    ,B.ExRate       ,A.Price        ,A.DomPrice             ,A.Qty              ,                 
               A.UnitSEq    ,A.Qty          ,A.CurAmt       ,A.CurVAT               ,A.DomAmt           ,    
               A.DomVAT     ,A.StdUnitSeq   ,A.StdUnitQty   ,A.IsVAT                ,A.SMImpType        ,    
               A.WHSeq      ,A.DelvCustSeq  ,A.SMPayType    ,A.AccSeq               ,0                  ,    
               A.AntiAccSeq ,@VatAccSeq     ,A.IsFiction    ,A.FicRateNum           ,A.FicRateDen       ,    
               A.EvidSeq    ,A.PjtSeq       ,A.WBSSeq       ,A.Remark               , ''                ,    
               0            ,''             ,C.PayDate      ,0                      ,0                  ,     
               --@UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) -- 활동센터 추가 2010.05.11 by bgKeum    
               @UserSeq     ,GETDATE()      ,C.SMRNPMethod  ,    
               CASE WHEN A.PJTSeq <> 0 THEN P.CCTRSeq     
									   ELSE ISNULL(D.CCtrSeq, ISNULL(CC.CCtrSeq, 0)) END, -- 20110407 윤삼혁 프로젝트 활동센터    
			   A.DomAmt		,0--A.DomVAT			-- 2012. 5. 22 hkim 공급가액 컬럼 추가 
          FROM _TPUDelvInItem      AS A WITH(NOLOCK)      
               JOIN _TPUDelvIn     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                    AND A.DelvInSeq  = B.DelvInSeq    
               JOIN #TPUDelvInItem AS C              ON A.DelvInSeq  = C.DelvInSeq    
                                                    AND A.DelvInSerl = C.DelvInSerl    
      -- 20110407 윤삼혁 프로젝트 활동센터    
      LEFT OUTER JOIN _TPJTProject   AS P              ON A.CompanySeq = P.CompanySeq    
             AND A.PJTSeq  = P.PJTSeq    
               LEFT OUTER JOIN dbo._FnAdmEmpCCtr(@CompanySeq, @DelvInDate) AS CC ON B.EmpSeq = CC.EmpSeq -- 활동센터 추가 2010.05.11 by bgKeum    
               LEFT OUTER JOIN #CCtrSeq AS D ON C.IDX_NO = D.IDX_NO  -- 우선 구매요청의 활동센터 먼저 저장 by 천경민    
         WHERE C.WorkingTag = 'A'     
           AND C.Status     = 0          
           AND A.CompanySeq = @CompanySeq    
    END    
        
    -- 진행관리를 위해서 주석처리 2010. 1. 14 김현    
    -- 구매반품건은 -수량 환원(화면에 보여주기 위해)    
--     UPDATE #TPUDelvInItem    
--        SET Price      = Price ,    
--            DomPrice   = DomPrice,    
--            Qty        = -Qty   ,    
--            CurAmt     = -CurAmt,    
--            DomAmt     = -DomAmt,    
--            CurVAT     = -CurVAT,    
--            DomVAT     = -DomVAT,    
--            StdUnitQty = -StdUnitQty     
--      WHERE IsReturn = '1'    

    
    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가 
    ------------------------------------------------------------------------------------------
    --=======================================================================================================================
    -- 진행을 통한 납품의 제조일자, 유효일자 가져오기 -- START
    --=======================================================================================================================
    CREATE TABLE #TEMP_DelvInItem    
    (    
        IDX_NO     INT IDENTITY(1,1) ,
        DelvSeq    INT NULL,    
        DelvSerl   INT NULL,
        DelvInSeq  INT,    
        DelvInSerl INT,    
        CreateDate NCHAR(8) NULL, -- 제조일자
        ValiDate   NCHAR(8) NULL  -- 유효일자
    )      

    INSERT INTO #TEMP_DelvInItem (DelvSeq, DelvSerl, DelvInSeq, DelvInSerl)
        SELECT 0, 0, A.DelvInSeq, A.DelvInSerl
          FROM #TPUDelvInItem AS A 
         WHERE A.WorkingTag IN ('A', 'U')
           AND A.Status      = 0
    
    TRUNCATE TABLE #TMP_SOURCETABLE
    TRUNCATE TABLE #TCOMSourceTracking
    
    INSERT #TMP_SOURCETABLE          
    SELECT 1, '_TPUDelvItem'            -- 납품 
      
    EXEC _SCOMSourceTracking  @CompanySeq, '_TPUDelvInItem', '#TEMP_DelvInItem','DelvInSeq', 'DelvInSerl',''      
    
    
    
    UPDATE #TEMP_DelvInItem 
       SET DelvSeq    = B.Seq,
           DelvSerl   = B.Serl,
           CreateDate = D.CreateDate,
           ValiDate   = D.ValiDate
      FROM #TEMP_DelvInItem AS A
           JOIN #TCOMSourceTracking    AS B ON ( A.IDX_NO = B.IDX_NO AND B.IDOrder = 1 ) 
           JOIN KPXLS_TPUDelvItemAdd   AS D ON ( D.CompanySeq = @CompanySeq AND B.Seq = D.DelvSeq AND B.Serl = D.DelvSerl ) 
    --=======================================================================================================================
    -- 진행을 통한 납품의 제조일자, 유효일자 가져오기 -- END
    --=======================================================================================================================
    
    
    UPDATE A 
       SET RegDate = B.DelvInDate, 
           CreateDate  = ISNULL(C.CreateDate, ''),
           ValiDate    = ISNULL(C.ValiDate, '')
      FROM _TLGLotMaster            AS A 
      JOIN #TPUDelvInItem           AS B ON ( B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo ) 
      JOIN #TEMP_DelvInItem         AS C ON ( B.DelvInSeq = C.DelvInSeq AND B.DelvInSerl = C.DelvInSerl )
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkingTag IN ( 'A' , 'U' ) 
    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가,END 
    ------------------------------------------------------------------------------------------
    
    IF @WorkingTag <> 'AUTO' 
    SELECT * FROM #TPUDelvInItem 
    
    RETURN          
/*******************************************************************************************************************/
GO


begin tran
exec KPXLS_SPUDelvInItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Memo1 />
    <Memo2 />
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <CustSeq>357</CustSeq>
    <DelvInSeq>100000863</DelvInSeq>
    <DelvInSerl>1</DelvInSerl>
    <SMImpType>8008001</SMImpType>
    <ItemName>GON_원자재1</ItemName>
    <ItemNo>GON0001</ItemNo>
    <Spec>GON0001</Spec>
    <UnitName>Kg</UnitName>
    <Price>0.00000</Price>
    <Qty>7.00000</Qty>
    <CurAmt>0.00000</CurAmt>
    <DomPrice>0.00000</DomPrice>
    <DomAmt>0.00000</DomAmt>
    <WHSeq>1222</WHSeq>
    <WHName>영림산업테크</WHName>
    <DelvCustName />
    <DelvCustSeq>0</DelvCustSeq>
    <SalesCustName />
    <SalesCustSeq>0</SalesCustSeq>
    <STDUnitName>Kg</STDUnitName>
    <STDUnitQty>7.00000</STDUnitQty>
    <StdConvQty>1.00000</StdConvQty>
    <STDUnitSeq>2</STDUnitSeq>
    <SMPayType>0</SMPayType>
    <SMPayTypeName />
    <SMDelvType>0</SMDelvType>
    <SMDelvTypeName />
    <SMStkType>0</SMStkType>
    <SMStkTypeName />
    <ItemSeq>25292</ItemSeq>
    <UnitSeq>2</UnitSeq>
    <LotNo />
    <FromSerial />
    <ToSerial />
    <Remark />
    <LotMngYN>0</LotMngYN>
    <AccSeq>86</AccSeq>
    <AccName>원재료</AccName>
    <AntiAccSeq>209</AntiAccSeq>
    <AntiAccName>외상매입금</AntiAccName>
    <IsFiction>0</IsFiction>
    <FicRateNum>0.00000</FicRateNum>
    <FicRateDen>0.00000</FicRateDen>
    <EvidSeq>0</EvidSeq>
    <EvidName />
    <IsReturn xml:space="preserve"> </IsReturn>
    <DelvInDate>20160108</DelvInDate>
    <CurVAT>0.00000</CurVAT>
    <DomVAT>0.00000</DomVAT>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <IsVAT>0</IsVAT>
    <FromSeq>0</FromSeq>
    <FromSerl>0</FromSerl>
    <ItemSeqOLD>25292</ItemSeqOLD>
    <LotNoOLD />
    <SMPriceType>0</SMPriceType>
    <SMPriceTypeName />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2608,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=200109
rollback 