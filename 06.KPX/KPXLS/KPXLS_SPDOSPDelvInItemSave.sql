IF OBJECT_ID('KPXLS_SPDOSPDelvInItemSave') IS NOT NULL 
    DROP PROC KPXLS_SPDOSPDelvInItemSave
GO 

-- v2016.02.02 

-- LotMaster 데이터 업데이트추가 by 이재천 
/************************************************************  
설  명 - 외주입고 상세 저장
작성일 - 2008년 8월 20일   
작성자 - 노영진  
수정일 - 2010년 5월 4일 UPDATEd BY 박소연 :: 출납방법 추가
************************************************************/  
CREATE PROC KPXLS_SPDOSPDelvInItemSave 
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
  
AS          
    
    DECLARE @SlipAutoEnvSeq    INT,
            @AccSeq            INT,
            @AntiAccSeq        INT,
            @VatAccSeq         INT  
  
    IF @WorkingTag <> 'AUTO'
    BEGIN 
        -- 서비스 마스타 등록 생성  
        CREATE TABLE #TPDOSPDelvInItem (WorkingTag NCHAR(1) NULL)    
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPDOSPDelvInItem'

		-- 출납방법/ 지불일자 가져오기
		DECLARE @SMRNPMethod INT, @PayDate NCHAR(8), @CustSeq INT, @DelvInDate NCHAR(8)
		ALTER TABLE #TPDOSPDelvInItem ADD SMRNPMethod INT, PayDate NCHAR(8)

		SELECT @CustSeq = CustSeq, 
		       @DelvInDate = OSPDelvInDate
		  FROM #TPDOSPDelvInItem 

		SELECT @SMRNPMethod = SMRNPMethod,
               @PayDate     = PayDate
          FROM dbo._FPDGetSMRNPMethod(@CompanySeq, 4012, @CustSeq, @DelvInDate)

		UPDATE A
           SET A.SMRNPMethod = ISNULL(@SMRNPMethod, 0)
               ,A.PayDate    = ISNULL(@PayDate, '')
          FROM #TPDOSPDelvInItem AS A
       
        IF @@ERROR <> 0 RETURN      
    END
    
--select * from #TPDOSPDelvInItem 
--return 
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq,
                   @UserSeq,
                   '_TPDOSPDelvInItem',
                   '#TPDOSPDelvInItem',
                   'OSPDelvInSeq, OSPDelvInSerl',
                   'companySeq,OSPDelvInSeq,OSPDelvInSerl,WorkOrderSeq,WorkOrderSerl,ItemSeq,ItemBomRev,ProcSeq,ProcRev,OSPAssySeq,UnitSeq,StdUnitSeq,Qty,StdUnitQty,
                    PriceUnitSeq,PriceQty,ProcPrice,ProcCurAmt,ProcCurVAT,ProcDomPrice,ProcDomAmt,ProcDomVAT,MatPrice,MatCurAmt,MatCurVAT,MatDomPrice,
                    MatDomAmt,MatDomVAT,Price,CurAmt,CurVAT,DomPrice,DomAmt,DomVAT,VATRate,ProdDeptSeq,WhSeq,Remark,SerialFrom,RealLotNo,VAT,CCtrSeq,
                    ImpDomAmt,ImpCurAmt,CurrSeq,ExRate,DirectDelvType,PJTSeq,WBSSeq,LastUserSeq,LastDateTime,IsReturn,SourceType,SourceSeq,SourceSerl,
                    Memo1,Memo2,Memo3,Memo4,Memo5,Memo6,Memo7,Memo8'  

	

    --자동전표코드 가져오기
    SELECT @SlipAutoEnvSeq = B.SlipAutoEnvSeq
      FROM _TACSlipKind                    AS A WITH(NOLOCK) 
           LEFT OUTER JOIN _TACSlipAutoEnv AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                            AND A.SlipKindNo = B.SlipKindNo
     WHERE A.CompanySeq = @CompanySeq
       AND A.SlipKindNo = 'FrmPUBuyingAcc' 

    --외주계정 
    SELECT  @AccSeq= AccSeq
      FROM _TACSlipAutoEnvRow 
     WHERE  CompanySeq = @CompanySeq  
       AND SlipAutoEnvSeq = @SlipAutoEnvSeq  
       AND IsDftAcc = 1 
       AND SMDrOrCr = 1

    -- 외주상대계정
    SELECT  @AntiAccSeq = AccSeq
     FROM _TACSlipAutoEnvRow 
    WHERE  companyseq = @CompanySeq  
      AND SlipAutoEnvSeq = @SlipAutoEnvSeq  
      AND IsAnti = 1  --AND SMDrOrCr = -1

    -- 부가세계정
    SELECT @VatAccSeq = A.AccSeq
     FROM _TACSlipAutoEnvRow AS A WITH(NOLOCK)
          JOIN _TDAAccount   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                              AND A.AccSeq     = B.AccSeq  
                                              AND B.SMAccType = 4002009
    WHERE  A.companyseq    = @CompanySeq  
      AND A.SlipAutoEnvSeq = @SlipAutoEnvSeq  


  
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS (SELECT TOP 1 1 FROM #TPDOSPDelvInItem WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN    
        DELETE _TPDOSPDelvInItem  
          FROM _TPDOSPDelvInItem A JOIN #TPDOSPDelvInItem B ON A.OSPDelvInSeq = B.OSPDelvInSeq   
                                                       AND A.OSPDelvInSerl = B.OSPDelvInSerl  
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  
  
  
        DELETE _TPDOSPDelvInItemMat  
          FROM _TPDOSPDelvInItemMat A JOIN #TPDOSPDelvInItem B ON A.OSPDelvInSeq = B.OSPDelvInSeq   
                                                       AND A.OSPDelvInSerl = B.OSPDelvInSerl  
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  


        DELETE _TPUBuyingAcc
         FROM _TPUBuyingAcc AS A  JOIN #TPDOSPDelvInItem B ON A.SourceSeq = B.OSPDelvInSeq   
                                                          AND A.SourceSerl = B.OSPDelvInSerl  
                                                          AND A.SourceType = '2'
         WHERE B.WorkingTag = 'D' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq  
        IF @@ERROR <> 0  RETURN  

  
  
    END    
  
  
    -- UPDATE      
    IF EXISTS (SELECT 1 FROM #TPDOSPDelvInItem WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE _TPDOSPDelvInItem  
           SET  WorkOrderSeq     = B.WorkOrderSeq     ,
                WorkOrderSerl    = B.WorkOrderSerl    ,
                ItemSeq          = B.ItemSeq          ,
                ItemBomRev       = B.ItemBomRev       ,
                ProcSeq          = B.ProcSeq          ,
                ProcRev          = B.ProcRev          ,
                OSPAssySeq       = B.OSPAssySeq       ,
                UnitSeq          = B.UnitSeq          ,
                StdUnitSeq       = B.StdUnitSeq       ,
                Qty              = B.Qty              ,
                StdUnitQty       = B.StdUnitQty       ,
                PriceUnitSeq     = B.PriceUnitSeq     ,
                PriceQty         = B.PriceQty         ,
--                ProcPrice        = B.ProcPrice        ,
--                ProcCurAmt       = B.ProcCurAmt       ,
--                ProcCurVAT       = B.ProcCurVAT       ,
--                ProcDomPrice     = B.ProcDomPrice     ,
--                ProcDomAmt       = B.ProcDomAmt       ,
--                ProcDomVAT       = B.ProcDomVAT       ,
--                MatPrice         = B.MatPrice         ,
--                MatCurAmt        = B.MatCurAmt        ,
--                MatCurVAT        = B.MatCurVAT        ,
--                MatDomPrice      = B.MatDomPrice      ,
--                MatDomAmt        = B.MatDomAmt        ,
--                MatDomVAT        = B.MatDomVAT        ,
                Price            = B.Price            ,
                CurAmt           = B.CurAmt           ,
                CurVAT           = B.CurVAT           ,
                DomPrice         = B.DomPrice         ,
                DomAmt           = B.DomAmt           ,
                DomVAT           = B.DomVAT           ,
                VATRate          = B.VATRate          ,
                ProdDeptSeq      = B.ProdDeptSeq      ,
                WhSeq            = B.WhSeq            ,
                Remark           = B.Remark           ,
                SerialFrom       = B.SerialFrom       ,
                RealLotNo        = B.RealLotNo        ,
                CCtrSeq          = B.CCtrSeq          ,
                ImpDomAmt        = B.ImpDomAmt        ,
                ImpCurAmt        = B.ImpCurAmt        ,
                CurrSeq          = B.CurrSeq          ,
                ExRate           = B.ExRate           ,
                DirectDelvType   = B.DirectDelvType   ,
                PJTSeq           = B.PJTSeq           ,
                WBSSeq           = B.WBSSeq           ,
                Memo1            = B.Memo1            ,
                Memo2            = B.Memo2            ,
                Memo3            = B.Memo3            ,
                Memo4            = B.Memo4            ,
                Memo5            = B.Memo5            ,
                Memo6            = B.Memo6            ,
                Memo7            = B.Memo7            ,
                Memo8            = B.Memo8            ,
                LastUserSeq     = @UserSeq,  
                LastDateTime    = GETDATE()   
          FROM _TPDOSPDelvInItem AS A JOIN #TPDOSPDelvInItem AS B ON A.OSPDelvInSeq = B.OSPDelvInSeq   
                                                         AND A.OSPDelvInSerl = B.OSPDelvInSerl  
         WHERE B.WorkingTag = 'U' AND B.Status = 0      
           AND A.CompanySeq  = @CompanySeq    
        IF @@ERROR <> 0  RETURN  


        --------------------------------------
        ---------입고정산---------------------
        --------------------------------------
        UPDATE _TPUBuyingAcc
        SET FactUnit        = C.FactUnit        ,
            BuyingAccDate   = C.OSPDelvInDate      ,
            DelvInNo        = C.OSPDelvInNo        ,
            DelvInDate      = C.OSPDelvInDate      ,
            ItemSeq         = B.OSPAssySeq         ,
            CustSeq         = C.CustSeq         ,
            EmpSeq          = C.EmpSeq          ,
            DeptSeq         = C.DeptSeq         ,
            UnitSeq         = B.UnitSeq         ,
            CurrSeq         = B.CurrSeq         ,
            ExRate          = B.ExRate          ,
            Price           = B.Price           ,
            DomPrice        = B.DomPrice        ,
            Qty             = B.Qty             ,
            PriceUnitSeq    = B.PriceUnitSeq    ,
            PriceQty        = B.PriceQty        ,
            CurAmt          = B.CurAmt          ,
            CurVAT          = B.CurVAT          ,
            DomAmt          = B.DomAmt          ,
            DomVAT          = B.DomVAT          ,
            StdUnitSeq      = B.StdUnitSeq      ,
            StdUnitQty      = B.StdUnitQty      ,
            IsVAT           = ''                ,
            WHSeq           = B.WHSeq           ,
            AccSeq          = @AccSeq           ,
            AntiAccSeq      = @AntiAccSeq       ,
            VatAccSeq       = @VatAccSeq, --CASE WHEN ISNULL(B.CurVAT,0) >0 OR ISNULL(B.DomVAT,0) >= 0 THEN @VatAccSeq ELSE 0 END , --부가세 0 이하여도 부가세계정 들어가도록   12.05.17 BY 김세호
            PjtSeq          = B.PjtSeq          ,
            WBSSeq          = B.WBSSeq          ,
            Remark          = B.Remark          ,
--          IsReturn        = B.IsReturn        ,
--          SlipSeq         = B.SlipSeq         ,
--          TaxDate         = B.TaxDate         ,
--          PayDate         = B.PayDate         ,
            ImpDomAmt       = B.ImpDomAmt       ,
            ImpCurAmt       = B.ImpCurAmt       ,
            LastUserSeq     = @UserSeq          ,     
            LastDateTime    = GETDATE()         ,
            PayDate         = M.PayDate         ,
            SMRNPMethod     = M.SMRNPMethod
         FROM  _TPUBuyingAcc AS  A JOIN #TPDOSPDelvInItem AS M ON A.CompanySeq = @CompanySeq
                                                              AND A.SourceSeq  = M.OSPDelvInSeq
                                                              AND A.SourceSerl = M.OSPDelvInSerl
                                                              AND A.SourceType = '2'
                                   JOIN _TPDOSPDelvInItem AS B ON B.CompanySeq    = @CompanySeq
                                                              AND M.OSPDelvInSeq  = B.OSPDelvInSeq
                                                              AND M.OSPDelvInSerl = B.OSPDelvInSerl
                                   JOIN _TPDOSPDelvIn     AS C ON B.CompanySeq    = C.CompanySeq
                                                              AND B.OSPDelvInSeq  = C.OSPDelvInSeq
         WHERE M.WorkingTag = 'U' AND M.Status = 0      
           AND A.CompanySeq  = @CompanySeq    
        IF @@ERROR <> 0  RETURN  



    END     
  
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #TPDOSPDelvInItem WHERE WorkingTag = 'A' AND Status = 0)    
    BEGIN    
        INSERT INTO _TPDOSPDelvInItem(  companySeq       , OSPDelvInSeq     , OSPDelvInSerl    , WorkOrderSeq     , WorkOrderSerl    , 
                                        ItemSeq          , ItemBomRev       , ProcSeq          , ProcRev          , OSPAssySeq       , 
                                        UnitSeq          , StdUnitSeq       , Qty              , StdUnitQty       , PriceUnitSeq     , 
                                        PriceQty         , ProcPrice        , ProcCurAmt       , ProcCurVAT       , ProcDomPrice     , 
                                        ProcDomAmt       , ProcDomVAT       , MatPrice         , MatCurAmt        , MatCurVAT        , 
                                        MatDomPrice      , MatDomAmt        , MatDomVAT        , Price            , CurAmt           , 
                                        CurVAT           , DomPrice         , DomAmt           , DomVAT           , VATRate          , 
                                        ProdDeptSeq      , WhSeq            , Remark           , SerialFrom       , RealLotNo        , 
                                        VAT              , CCtrSeq          , ImpDomAmt        , ImpCurAmt        , CurrSeq          , 
                                        ExRate           , DirectDelvType   , PJTSeq           , WBSSeq           , LastUserSeq      ,
                                        LastDateTime     , ProgFromSeq      , ProgFromSerl     , ProgFromTableSeq , Memo1            ,
                                        Memo2            , Memo3            , Memo4            , Memo5            , Memo6            ,
                                        Memo7            , Memo8
                                    )  
        SELECT  @CompanySeq   ,OSPDelvInSeq     , OSPDelvInSerl    , WorkOrderSeq     , WorkOrderSerl    , 
                ItemSeq          , ItemBomRev       , ProcSeq          , ProcRev          , OSPAssySeq       , 
                UnitSeq          , StdUnitSeq       , Qty              , StdUnitQty       , PriceUnitSeq     , 
                PriceQty         , ISNULL(ProcPrice,0) , ISNULL(ProcCurAmt,0) , ISNULL(ProcCurVAT, 0) , ISNULL(ProcDomPrice, 0)     , 
                ISNULL(ProcDomAmt, 0) , ISNULL(ProcDomVAT, 0) , ISNULL(MatPrice, 0) , ISNULL(MatCurAmt, 0) , ISNULL(MatCurVAT,0)        , 
                ISNULL(MatDomPrice,0) , ISNULL(MatDomAmt,0)   , ISNULL(MatDomVAT,0) , ISNULL(Price, 0)     , ISNULL(CurAmt,0)           , 
                CurVAT           , DomPrice         , DomAmt           , DomVAT           , VATRate          , 
                ProdDeptSeq      , WhSeq            , Remark           , SerialFrom       , RealLotNo        , 
                0                , CCtrSeq          , ImpDomAmt        , ImpCurAmt        , CurrSeq          , 
                ExRate           , DirectDelvType   , PJTSeq           , WBSSeq           , @UserSeq         ,
                GETDATE()        , ProgFromSeq      , ProgFromSerl     , ProgFromTableSeq , Memo1            ,
                Memo2            , Memo3            , Memo4            , Memo5            , Memo6            ,
                Memo7            , Memo8
          FROM #TPDOSPDelvInItem AS A     
         WHERE A.WorkingTag = 'A' AND A.Status = 0      
        IF @@ERROR <> 0 RETURN  

        --------------------------------------
        ---------입고정산---------------------
        --------------------------------------
        DECLARE @DataSeq INT,
                @BuyingAccSeq INT,
                @count INT

        SELECT   @DataSeq = 0        
          
        WHILE ( 1 = 1 )         
        BEGIN        
            SELECT TOP 1 @DataSeq = DataSeq    
            FROM #TPDOSPDelvInItem        
             WHERE WorkingTag = 'A'        
               AND Status = 0        
               AND DataSeq > @DataSeq        
             ORDER BY DataSeq        
                

            IF @@ROWCOUNT = 0 BREAK     

                SELECT @count = COUNT(*)          
                  FROM #TPDOSPDelvInItem          
                 WHERE WorkingTag = 'A' AND Status = 0            
     
                IF @count > 0        
                BEGIN        
                    EXEC @BuyingAccSeq = _SCOMCreateSeq @CompanySeq, '_TPUBuyingAcc', 'BuyingAccSeq', 1         
                END        

                UPDATE #TPDOSPDelvInItem        
                   SET BuyingAccSeq = @BuyingAccSeq + 1
                 WHERE WorkingTag = 'A'        
                   AND Status = 0        
                   AND DataSeq = @DataSeq       

            IF @WorkingTag = 'D'      
                UPDATE #TPUBuyingAcc      
                   SET WorkingTag = 'D'      
        END


        INSERT INTO _TPUBuyingAcc(CompanySeq      ,BuyingAccSeq  ,SourceType    ,SourceSeq     ,SourceSerl    ,
                                    BizUnit       ,FactUnit      ,BuyingAccDate ,DelvInNo      ,DelvInDate    ,
                                    ItemSeq       ,CustSeq       ,EmpSeq        ,DeptSeq       ,UnitSeq       ,
                                    CurrSeq       ,ExRate        ,Price         ,DomPrice      ,Qty           ,
                                    PriceUnitSeq  ,PriceQty      ,CurAmt        ,CurVAT        ,DomAmt        ,
                                    DomVAT        ,StdUnitSeq    ,StdUnitQty    ,IsVAT         ,SMImpType     ,
                                    WHSeq         ,DelvCustSeq   ,SMPayType     ,AccSeq        ,MatAccSeq     ,
                                    AntiAccSeq    ,VatAccSeq     ,
                                    IsFiction     ,FicRateNum    ,FicRateDen    ,
                                    EvidSeq       ,PjtSeq        ,WBSSeq        ,Remark        ,IsReturn      ,
                                    SlipSeq       ,TaxDate       ,PayDate       ,ImpDomAmt     ,ImpCurAmt     ,
                                    LastUserSeq   ,LastDateTime  ,SMRNPMethod	,SupplyAmt	   ,SupplyVAT)
          SELECT @CompanySeq    ,A.BuyingAccSeq ,'2'                ,B.OSPDelvInSeq     ,B.OSPDelvInSerl        ,
                 0   /*BizUnit*/,C.FactUnit     ,C.OSPDelvInDate    ,C.OSPDelvInNo      ,C.OSPDelvInDate        ,
                 B.OSPAssySeq   ,C.CustSeq      ,C.EmpSeq           ,C.DeptSeq          ,B.UnitSeq              ,
                 B.CurrSeq      ,B.ExRate       ,B.Price            ,B.DomPrice         ,B.Qty                  ,
                 B.PriceUnitSeq ,B.PriceQty     ,B.CurAmt           ,B.CurVAT           ,B.DomAmt               ,
                 B.DomVAT       ,B.StdUnitSeq   ,B.StdUnitQty       ,''                 ,8008001                ,
                 B.WHSeq        ,0              ,0                  ,@AccSeq            ,0                      ,
                 @AntiAccSeq    ,@VatAccSeq     ,--CASE WHEN ISNULL(B.CurVAT,0) >0 OR ISNULL(B.DomVAT,0) >=0 THEN @VatAccSeq ELSE 0 END,--부가세 0 이하여도 부가세계정 들어가도록   12.05.17 BY 김세호
                ''              ,0              ,0                  ,
                0               ,B.PJTSeq       ,B.WBSSeq           ,''                 ,''                     ,
                0               ,''             ,A.PayDate          ,B.ImpDomAmt        ,B.ImpCurAmt            ,
                @UserSeq        ,GETDATE()      ,A.SMRNPMethod		,B.DomAmt			,0			-- 불공제세가 아닌 건은 불공제세액이 0으로 들어가야 한다 불공제세 일괄 변경화면에서 세액 들어가도록 변경 2012. 5. 31. hkim
           FROM  #TPDOSPDelvInItem AS A JOIN _TPDOSPDelvInItem AS B ON B.CompanySeq    = @CompanySeq
                                                                   AND A.OSPDelvInSeq  = B.OSPDelvInSeq
                                                                   AND A.OSPDelvInSerl = B.OSPDelvInSerl
                                        JOIN _TPDOSPDelvIn     AS C ON B.CompanySeq    = C.CompanySeq
                                                                   AND B.OSPDelvInSeq  = C.OSPDelvInSeq
            WHERE A.WorkingTag = 'A' AND A.Status = 0      
                    IF @@ERROR <> 0 RETURN  


    END 
    

    
    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가 
    ------------------------------------------------------------------------------------------
    --=======================================================================================================================
    -- 진행을 통한 납품의 제조일자, 유효일자 가져오기 -- START
    --=======================================================================================================================
    CREATE TABLE #Temp 
    (
        IDX_NO          INT IDENTITY, 
        OSPDelvInSeq    INT, 
        OSPDelvInSerl   INT, 
        OSPDelvSeq      INT, 
        OSPDelvSerl     INT, 
        CreateDate      NCHAR(8), 
        ValiDate        NCHAR(8) 
    )
    INSERT INTO #Temp ( OSPDelvInSeq, OSPDelvInSerl ) 
    SELECT OSPDelvInSeq, OSPDelvInSerl 
      FROM #TPDOSPDelvInItem 


    
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  

    INSERT #TMP_SOURCETABLE          
    SELECT 1, '_TPDOSPDelvItem'            -- 납품 
    
    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 

    EXEC _SCOMSourceTracking  @CompanySeq, '_TPDOSPDelvInItem', '#Temp','OSPDelvInSeq', 'OSPDelvInSerl',''      
    
    UPDATE A
       SET OSPDelvSeq    = B.Seq,
           OSPDelvSerl   = B.Serl,
           CreateDate = C.Memo2,
           ValiDate   = C.Memo3
      FROM #Temp AS A
           JOIN #TCOMSourceTracking     AS B ON A.IDX_NO = B.IDX_NO AND B.IDOrder = 1
           JOIN _TPDOSPDelvItem         AS C ON C.CompanySeq = @CompanySeq AND B.Seq = C.OSPDelvSeq AND B.Serl = C.OSPDelvSerl
           
    --=======================================================================================================================
    -- 진행을 통한 납품의 제조일자, 유효일자 가져오기 -- END
    --=======================================================================================================================
    
     UPDATE A 
        SET RegDate     = B.OSPDelvInDate ,
            CreateDate  = ISNULL(C.CreateDate, ''),
            ValiDate    = ISNULL(C.ValiDate, '')
       FROM _TLGLotMaster           AS A 
       JOIN #TPDOSPDelvInItem       AS B ON ( B.ItemSeq = A.ItemSeq AND B.RealLotNo = A.LotNo ) 
       JOIN #Temp                   AS C ON ( B.OSPDelvInSeq = C.OSPDelvInSeq AND B.OSPDelvInSerl = C.OSPDelvInSerl )
      WHERE A.CompanySeq = @CompanySeq 
        AND B.WorkingTag IN ( 'A' , 'U' ) 

    ------------------------------------------------------------------------------------------
    -- LotNo Master 입고일자 Update 로직 추가,END 
    ------------------------------------------------------------------------------------------
    
    IF @WorkingTag <> 'AUTO'        -- 외주자동입고에서 외주자재자동정산을 따로 호출하므로 자동입고 아닌경우만 실행해야함. 
    BEGIN 

        DECLARE @EnvValue NVARCHAR(100)

        -- 외주품목 입고 시 외주자재 자동정산여부
        EXEC dbo._SCOMEnv @CompanySeq,6502,@UserSeq,@@PROCID,@EnvValue OUTPUT

        IF  @EnvValue IN ('1','True')
        BEGIN 
        

            CREATE TABLE #TPUOSPDelvMat (WorkingTag NCHAR(1) NULL)      
            ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, 2979, 'DataBlock3', '#TPUOSPDelvMat'     

            INSERT #TPUOSPDelvMat (IDX_NO, WorkingTag, OSPDelvInSeq,OSPDelvInSerl)
            SELECT IDX_NO, WorkingTag, OSPDelvInSeq,OSPDelvInSerl 
              FROM #TPDOSPDelvInItem
             WHERE WorkingTag <> 'D'
               AND Status = 0 


            IF EXISTS (SELECT 1 FROM #TPUOSPDelvMat) 
            BEGIN 

                -- 외주자재자동정산
                EXEC _SPDOSPDelvInInMatItemQuery    @xmlDocument    = N''           ,
                                                    @xmlFlags       = @xmlFlags     ,
                                                    @ServiceSeq     = 2979   ,
                                                    @WorkingTag     = 'AUTO'  ,
                                                    @CompanySeq     = @CompanySeq   ,
                                                    @LanguageSeq    = @LanguageSeq  ,
                                                    @UserSeq        = @UserSeq      ,
                                                    @PgmSeq         = @PgmSeq
                                                
            END
            
            IF @@ERROR <> 0 RETURN    
        END
        
        SELECT * FROM #TPDOSPDelvInItem     
    END

    RETURN      
/*******************************************************************************************************************/
GO

begin tran 
exec KPXLS_SPDOSPDelvInItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <OSPDelvInSerl>1</OSPDelvInSerl>
    <WorkOrderSeq>1000135</WorkOrderSeq>
    <WorkOrderSerl>1</WorkOrderSerl>
    <WorkOrderNo>201512280003</WorkOrderNo>
    <PJTName />
    <PJTNo />
    <PJTSeq>0</PJTSeq>
    <WBSName />
    <WBSSeq>0</WBSSeq>
    <ItemName>1717차 제품</ItemName>
    <ItemNo>1717차 제품번호</ItemNo>
    <ItemBomRev xml:space="preserve">  </ItemBomRev>
    <ItemBomRevName xml:space="preserve">  </ItemBomRevName>
    <ProcSeq>1</ProcSeq>
    <ProcName>후세정</ProcName>
    <ProcRev xml:space="preserve">  </ProcRev>
    <OSPAssyName>1717차 제품</OSPAssyName>
    <OSPAssyNo>1717차 제품번호</OSPAssyNo>
    <OSPAssySpec />
    <OSPUnitName>Kg</OSPUnitName>
    <OSPAssySeq>1052513</OSPAssySeq>
    <Qty>49</Qty>
    <PriceUnitName>Kg</PriceUnitName>
    <PriceUnitSeq>2</PriceUnitSeq>
    <PriceQty>49</PriceQty>
    <WHName>케이비엠d</WHName>
    <WHSeq>1</WHSeq>
    <Remark />
    <RealLotNo />
    <SerialFrom />
    <StdUnitName>Kg</StdUnitName>
    <UnitSeq>2</UnitSeq>
    <StdUnitSeq>2</StdUnitSeq>
    <StdUnitQty>49</StdUnitQty>
    <Price>1000</Price>
    <CurAmt>49000</CurAmt>
    <CurVAT>4900</CurVAT>
    <TotCurAmt>53900</TotCurAmt>
    <DomPrice>1000</DomPrice>
    <DomAmt>49000</DomAmt>
    <DomVAT>4900</DomVAT>
    <TotDomAmt>53900</TotDomAmt>
    <VATRate>10</VATRate>
    <DirectDelvType>0</DirectDelvType>
    <OSPAccSeq>0</OSPAccSeq>
    <VATAccSeq>0</VATAccSeq>
    <ProcAccSeq>0</ProcAccSeq>
    <MatAccSeq>0</MatAccSeq>
    <CCtrSeq>0</CCtrSeq>
    <CCtrName />
    <ImpDomAmt>0</ImpDomAmt>
    <ImpCurAmt>0</ImpCurAmt>
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1.000</ExRate>
    <FromTableSeq>3</FromTableSeq>
    <FromSeq>1000134</FromSeq>
    <FromSerl>1</FromSerl>
    <FromSubSerl>0</FromSubSerl>
    <ToTableSeq>2</ToTableSeq>
    <FromQty>50</FromQty>
    <FromSTDQty>50</FromSTDQty>
    <FromAmt>0</FromAmt>
    <FromVAT>0</FromVAT>
    <PrevFromTableSeq>4</PrevFromTableSeq>
    <FromPgmSeq>0</FromPgmSeq>
    <ToPgmSeq>0</ToPgmSeq>
    <ItemSeqOLD>1052513</ItemSeqOLD>
    <LotNoOLD />
    <ProgFromTableSeq>0</ProgFromTableSeq>
    <ProgFromSeq>0</ProgFromSeq>
    <ProgFromSerl>0</ProgFromSerl>
    <Memo1 />
    <Memo2 />
    <Memo3 />
    <Memo4 />
    <Memo5 />
    <Memo6 />
    <Memo7>0</Memo7>
    <Memo8>0</Memo8>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ProdDeptSeq>1261</ProdDeptSeq>
    <OSPDelvInDate>20151228</OSPDelvInDate>
    <ItemSeq>1052513</ItemSeq>
    <FactUnit>71</FactUnit>
    <OSPDelvInSeq>1000130</OSPDelvInSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=2979,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1101
rollback 