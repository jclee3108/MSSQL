IF OBJECT_ID('KPX_SESMCCostSlipGetEtcDataQuery') IS NOT NULL 
    DROP PROC KPX_SESMCCostSlipGetEtcDataQuery
GO 

-- v2015.12.21 

-- Æ÷Àå¿ë±â ÇÏµåÄÚµù -> Ãß°¡Á¤º¸¼³Á¤°ªÀ¸·Î º¯°æ byÀÌÀçÃµ 
/************************************************************    
 ¼³  ¸í - D-¿ø°¡°á»êÀüÇ¥Ã³¸® : ±âÅ¸ÀÔÃâµ¥ÀÌÅÍ°¡Á®¿À±â    
 ÀÛ¼ºÀÏ - 20090413    
 ÀÛ¼ºÀÚ - ÀÌÁöÇØ    
 ³»¿ë   - ¹°·ùÀÇ ±âÅ¸Ãâ°í, ±âÅ¸ÀÔ°íµÈ ³»¿ªÀÇ ÀüÇ¥Ã³¸®¸¦ ÇÏ´Â spÀÓ (ÀÚÀç,»óÇ°,Á¦Ç°)
          Á¦Ç°ÀÇ °æ¿ì ¿ø°¡°è»êÀü°ú ÈÄ°¡ ÀÖ´Âµ¥ ÀüÀº Á¦Á¶¿ø°¡ºñ¿ëÀ¸·Î Ãâ°íµÈ Ç°¸ñÀ» Ã³¸®ÇÏ°í
          ÈÄ´Â Á¦Ç°ÀÇ ±âÅ¸ÀÔ°í Á¦Á¶¿ø°¡ºñ¿ëÀÌ ¾Æ´Ñ ±âÅ¸Ãâ°í°Ç, 
               Á¦Á¶¿ø°¡ºñ¿ëÀ¸·Î ¸¸µé¾îÁø °Í°ú Àç°íºñ¿ëÀÇ Â÷ÀÌ°¡ Ãâ°í°ÇÀÌ ¾øÀ» °æ¿ì º¸Á¤Ã³¸® µÇ´Â ºÎºÐÀÌ ³ª¿À°Ô µÈ´Ù.
 Ãß°¡Á¤º¸ - ±âÅ¸ÀÔ°í±¸ºÐ, ±âÅ¸Ãâ°í±¸ºÐÀÇ °èÁ¤.ºñ¿ë±¸ºÐÀ» »ç¿ëÇÔ.
            ±âÅ¸ÀÔ°í±¸ºÐ(1001	°èÁ¤°ú¸ñ,1002	ºñ¿ë±¸ºÐ)
            ±âÅ¸Ãâ°í±¸ºÐ(2003	°èÁ¤°ú¸ñ,2004	ºñ¿ë±¸ºÐ)
¼öÁ¤ÀÏ - 2011.06.30 ÁöÇØ 1) ±âÅ¸ÀÔÃâ°í ÀüÇ¥Ã³¸®¿¡¼­ ºÎ¼­·Î ¸»°í °Å·¡Ã³·Î Áý°è °¡´ÉÇÏµµ·Ï ¿É¼Ç Ãß°¡ 
                            => ÇöÀç½ÃÁ¡ÀÌÈÄ¿¡ Àû¿ëµÉ °æ¿ì _TESMGINOutstockÀÇ  custseq¿¡ ±âÅ¸Ãâ°í¿¡ ´ëÇÑ µ¥ÀÌÅÍµµ Áý°è °¡´ÉÇÏµµ·Ï ¼öÁ¤Ã³¸®ÇÔ.
ALTER TABLE _TESMCProdSlipD ADD UMRealDetilKind    INT
************************************************************/    
CREATE PROCEDURE KPX_SESMCCostSlipGetEtcDataQuery
    @xmlDocument    NVARCHAR(MAX),                
    @xmlFlags       INT = 0,                
    @ServiceSeq     INT = 0,                
    @WorkingTag     NVARCHAR(10)= '',                
    @CompanySeq     INT = 1,                
    @LanguageSeq    INT = 1,                
    @UserSeq        INT = 0,                
    @PgmSeq         INT = 0                
              
AS                  
              
DECLARE	@docHandle      INT,          
        @MessageType    INT,              
        @Status         INT,              
        @Results        NVARCHAR(250),            
        @CostUnit       INT,    
        @CostYM         CHAR(6)      ,            
        @RptUnit        INT,    
        @SMCostMng      INT,    
        @CostMngAmdSeq  INT,    
        @PlanYear       NCHAR(4),    
        @SMSlipKind     INT,
        @IsDivideCCtrItem INT,
        @YAVGAdjTransType INT 
             
    -- ¼­ºñ½º ¸¶½ºÅ¸ µî·Ï »ý¼º              
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
           
	SELECT	@CostUnit         = ISNULL(CostUnit       ,0),          
			@RptUnit          = ISNULL(RptUnit        ,0),    
			@SMCostMng        = ISNULL(SMCostMng      ,0),    
			@CostMngAmdSeq    = ISNULL(CostMngAmdSeq  ,0),    
			@SMSlipKind       = ISNULL(SMSlipKind     ,0),      
			@CostYM           = ISNULL(CostYM         ,''),      
			@PlanYear         = ISNULL(PlanYear       ,'')        
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)          
	  WITH (CostUnit          INT , RptUnit           INT ,      
			SMCostMng         INT , CostMngAmdSeq     INT ,    
			SMSlipKind        INT , CostYM            NCHAR(6),    
			PlanYear          NCHAR(4))          

    CREATE TABLE #AssetSeq 
    (AssetSeq INT)

DECLARE @CostKeySeq             INT,
		@cTRANsAdjAccSeq        INT,
		@cTRANsAdjUMcostTypeSeq INT,
		@MatPriceUnit           INT    
    
	EXEC @CostKeySeq = dbo._SESMDCostKeySeq @CompanySeq,@CostYM ,@RptUnit,@SMCostMng,@CostMngAmdSeq,@PlanYear,@PgmSeq    

 
 CREATE TABLE #Slip (WorkingTag NCHAR(1) NULL)  
 EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Slip'  
 IF @@ERROR <> 0 RETURN  

    --¹ÝÁ¦Ç° Àç°øÀ¸·Î Ã³¸® ¿É¼Ç
    DECLARE @BanToProc INT 
    EXEC dbo._SCOMEnv @CompanySeq,5547,0  /*@UserSeq*/,@@PROCID,@BanToProc OUTPUT
    
    
    DECLARE @FSDomainSeq INT           
    --SELECT @FSDomainSeq = 11  --ÃßÈÄº¯°æÇØ¾ßÇÔ.   
    
 ----Á¦Ç°´Ü°¡°è»ê¿¡ µû¶ó SubÈ£ÃâÀ» ¿¬ÃÑÆò±Õ, ¼±ÀÔ¼±Ãâ, ¿ùÃÑÆò±ÕÀ¸·Î ³ª´µ¾î¼­ Ã³¸®ÇØ¾ßÇÑ´Ù.     
    
      
   IF @SMCostMng IN (5512001 , 5512004 )     --5512001/°ü¸®È¸°è          , 5512004/±âº»¿ø°¡                 
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'GAAPFS'           
   ELSE IF @SMCostMng IN (5512005 , 5512006) --5512005/IFRS(°ü¸®È¸°è)    , 5512006/IFRS(±âº»¿ø°¡)           
      SELECT @FSDomainSeq =  FSDomainSeq FROM _TCOMFSDomain WITH(NOLOCK) WHERE CompanySeq =@CompanySeq AND FSDomainNo = 'IFRSFS'           
   ELSE IF @SMCostMng IN (5512007 , 5512008) --5512007/º¸°í°á»ê(°ü¸®È¸°è) , 5512008/º¸°í°á»ê(±âº»¿ø°¡)     
    BEGIN       
       SELECT @FSDomainSeq = FSDomainSeq FROM _TCRRptUnit WITH(NOLOCK) WHERE RptUnit = @RptUnit AND CompanySeq = @CompanySeq       
    END        
          



--    1)´ç¿ùÃ³¸®µÈ ³»¿ª»èÁ¦    
--    ÀÌ¹Ì ÀüÇ¥ Ã³¸®µÈ ³»¿ªÀº ±âÁ¸ µ¥ÀÌÅÍ ºÒ·¯´Ù º¸¿©ÁÖ±â
 

    IF EXISTS (SELECT 1 FROM KPX_TESMCProdSlipM A 
                WHERE A.CompanySeq     = @CompanySeq    
                  AND A.CostUnit       = @CostUnit    
                  AND A.CostKeySeq     = @CostKeySeq
                  AND A.SMSlipKind     = @SMSlipKind     
                  AND A.SlipSeq        > 0)
    BEGIN
        
--        -------------------------------------------  
--        -- ÀüÇ¥Ã³¸® ¿©ºÎ 
--        -------------------------------------------  
--        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
--                              @Status      OUTPUT,  
--                              @Results     OUTPUT,  
--                              15                  , -- Áßº¹µÈ @1 @2°¡(ÀÌ) ÀÔ·ÂµÇ¾ú½À´Ï´Ù.(SELECT * FROM _TCAMessageLanguage WHERE languageseq = 1 and messageDefault like '%ÀüÇ¥%' MessageSeq = 6)  
--                              @LanguageSeq       ,   
--                              0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%°üÁ¡%'  
--
--
--       UPDATE #Slip    
--           SET Result        =@Results,    
--               MessageType   = @MessageType,    
--               Status        = @Status    
--        SELECT * FROM #Slip
--        RETURN 

        GOTO Proc_Query
    END 
    ELSE 
    BEGIN
		DELETE KPX_TESMCProdSlipD    
          FROM KPX_TESMCProdSlipM      AS A     
          JOIN KPX_TESMCProdSlipD AS B ON A.CompanySeq = B.CompanySeq    
                                   AND A.TransSeq   = B.TransSeq    
         WHERE A.CompanySeq = @CompanySeq    
           AND A.CostUnit   = @CostUnit    
           AND A.CostKeySeq = @CostKeySeq
           AND A.SMSlipKind = @SMSlipKind    
    END

    --Ã³¸® µ¥ÀÌÅÍ µé¾î°¡´Â µ¥ÀÌÆ²
    CREATE TABLE #TempInOut    
    (    
        SMSlipKind         INT ,     --ÀüÇ¥±¸ºÐ    
        INOutDetailKind    INT ,     --ÀÔÃâ°í±¸ºÐ    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- Àç°íÀÚ»êºÐ·ù    
        DrAccSeq           INT ,     -- °èÁ¤ÄÚµå    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- Àç°íÀÚ»ê°èÁ¤ÄÚµå    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- ±Ý¾×    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --¸ÅÃâ°Å·¡Ã³/±âÅ¸Ãâ°í °Å·¡Ã³.
        GoodItemSeq        INT ,      --ÅõÀÔÁ¦Ç°
        ISSum              INT NULL , --2011.06.30 °Å·¡Ã³, ºÎ¼­ÀÇ Áý°è¸¦ À§ÇÏ¿© Ãß°¡
        UMRealDetilKind    INT NULL  --2011.09.02 ±âÅ¸ÀÔÃâ°í ±¸ºÐº° Áý°è¸¦ À§ÇÏ¿© Ãß°¡
            )    
            
--###############¿¬ÃÑÆò±Õ¿ë ½ÃÀÛ #################################################################--
            
      --Ã³¸® µ¥ÀÌÅÍ µé¾î°¡´Â µ¥ÀÌÅÍ(Å¸°èÁ¤À» À§ÇÑ ÀÓ½ÃÁý°è Å×ÀÌºí)
    CREATE TABLE #TempInOut_Garbege    
    (    
        SMSlipKind         INT ,     --ÀüÇ¥±¸ºÐ    
        INOutDetailKind    INT ,     --ÀÔÃâ°í±¸ºÐ    
        Remark             NVARCHAR(100),     
        AssetSeq           INT ,     -- Àç°íÀÚ»êºÐ·ù    
        DrAccSeq           INT ,     -- °èÁ¤ÄÚµå    
        DrUMCostType       INT ,                
        CrAccSeq           INT ,     -- Àç°íÀÚ»ê°èÁ¤ÄÚµå    
        CrUMCostType       INT ,    
        Amt                DECIMAL(19,5),  -- ±Ý¾×    
        ShowOrder          INT ,     
        DeptSeq            INT ,    
        CCtrSeq            INT ,
        CustSeq            INT ,     --¸ÅÃâ°Å·¡Ã³/±âÅ¸Ãâ°í °Å·¡Ã³.
        GoodItemSeq        INT ,      --ÅõÀÔÁ¦Ç°
        UMRealDetilKind    INT NULL,  --2011.09.02 ±âÅ¸ÀÔÃâ°í ±¸ºÐº° Áý°è¸¦ À§ÇÏ¿© Ãß°¡
        IsFromOtherAcc     NCHAR(1) NULL
            )   
            
    --Å¸°èÁ¤À¸·Î ´ëÃ¼ÀÇ °èÁ¤
    CREATE TABLE #OtherAcc(
        AssetSeq   INT,
        IsFromOtherAcc NCHAR(1),
        DrAccSeq     INT,
DrUMCostType INT,
        CrAccSeq     INT,
        CrUMCostType INT,
        DrOrCr       int)
    
    INSERT INTO #OtherAcc --Â÷º¯ Å¸°èÁ¤À¸·Î 
    SELECT A.AssetSeq,A.IsFromOtherAcc, B.AccSeq,  B.UMCostType,0,0,-1
     FROM _TDAItemAsset AS A 
         JOIN _TDAItemAssetAcc AS B ON A.CompanySeq = B.CompanySeq
                                   AND A.AssetSEq   = B.AssetSeq
    WHERE A.Companyseq = @CompanySeq       
      AND AssetAccKindSeq = 21 --Å¸°èÁ¤À¸·Î 
      AND A.IsFromOtherAcc = '1'
      
    INSERT INTO #OtherAcc  --´ëº¯ Å¸°èÁ¤À¸·Î 
    SELECT AssetSeq,IsFromOtherAcc,0,0,DrAccSeq,DrUMCostType,1
      FROM #OtherAcc
      

      
     INSERT INTO #AssetSeq  
     SELECT  E.AssetSeq   
      FROM  _TDAItemAsset  AS E WITH(NOLOCK)  
                    JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                             AND E.AssetSeq         = N.AssetSeq       
                                                             AND  N.AssetAccKindSeq  = 23 --¸ÅÃâº¸Á¤°èÁ¤  
                    JOIN _TDAItemAssetAcc    AS O WITH(NOLOCK) ON E.CompanySeq       = O.CompanySeq      
                                                             AND E.AssetSeq         = O.AssetSeq       
                                                             AND  O.AssetAccKindSeq  = 24 --±âÅ¸º¸Á¤°èÁ¤  
                    JOIN _TDAItemAssetAcc    AS M WITH(NOLOCK) ON E.CompanySeq       = M.CompanySeq      
                                                             AND E.AssetSeq         = M.AssetSeq      
                                                             AND M.AssetAccKindSeq  = 6 --¸ÅÃâ¿ø°¡°èÁ¤   
       WHERE E.CompanySeq = @CompanySeq            
        AND ( @BanToProc <> '1' OR (@BanToProc = '1' AND E.SMAssetGrp <> 6008004)) --¹ÝÁ¦Ç° Àç°øÀ¸·Î ¿É¼Ç »ç¿ë½Ã Å¸°èÁ¤ ³ª¿È
    --5555:¿¬ÃÑÆò±Õº¸Á¤ÀüÇ¥ ¸ÅÃâ¿ø°¡/±âÅ¸Ãâ°í º¸Á¤°Ç È°µ¿¼¾ÅÍº° Ç°¸ñº° Áý°è¿©ºÎ 
    --¿¬ÃÑÆò±Õº¸Á¤ÀüÇ¥ ¸ÅÃâ¿ø°¡/±âÅ¸Ãâ°í º¸Á¤°Ç È°µ¿¼¾ÅÍº° Ç°¸ñº° Áý°èÇÏ¿© ³»¿ªÁ¶È¸°¡ µÊ.
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    
    --5551:¿¬ÃÑÆò±Õ Ãâ°í±Ý¾× º¸Á¤ Á¶°Ç
    --¿¬ÃÑÆò±Õ½Ã Ãâ°í±Ý¾×ÀÇ º¸Á¤°Ç ¹ß»ýÇÏ¸é º¸Á¤¹æ¹ýÀ» ¼±ÅÃÇÕ´Ï´Ù.(¿øÃµµ¥ÀÌÅÍº°º¸Á¤/Ãâ°í±¸ºÐº° º¸Á¤)
    EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
     --@YAVGAdjTransType
     ----¿øÃµµ¥ÀÌÅÍº° º¸Á¤	    5536001
     ----Ãâ°í±¸ºÐº° º¸Á¤		5536002


      
--###############¿¬ÃÑÆò±Õ¿ë ³¡ #################################################################--
DECLARE	@ItemPriceUnit  INT ,
        @GoodPriceUnit  INT ,
        @FGoodPriceUnit INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5521,@UserSeq,@@PROCID,@ItemPriceUnit OUTPUT   --ÀÚÀç´Ü°¡°è»ê´ÜÀ§ 

    EXEC dbo._SCOMEnv @CompanySeq, 5522,@UserSeq,@@PROCID,@GoodPriceUnit OUTPUT   --»óÇ°´Ü°¡°è»ê´ÜÀ§ 

    EXEC dbo._SCOMEnv @CompanySeq, 5523,@UserSeq,@@PROCID,@FGoodPriceUnit OUTPUT  --Á¦Ç°´Ü°¡°è»ê´ÜÀ§ 

--5535001 5535 ¿¬ÃÑÆò±Õ ¸ÅÃâ¿ø°¡Á¶Á¤  
--5535002 5535 ¿¬ÃÑÆò±Õ ÅõÀÔ±Ý¾×Á¶Á¤  
--5535003 5535 ¿¬ÃÑÆò±Õ ±âÅ¸Ãâ°í±Ý¾× Á¶Á¤  
  
    EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
    

---------------Á¦Ç°ÀÏ°æ¿ì »ç¿ëÇÏ´Â Ç×¸ñ-----------------------------------------------------
--    IF @SMSlipKind IN (5522007,5522006,5522012)
--    BEGIN
		--»ç¿ë°¡´ÉÇÑ ¿ø°¡°èÁ¤°¡Á®¿À±â    
		--Àç·áºñ,³ë¹«ºñ,°æºñ    
		CREATE TABLE  #ESMAccount ( SMCostKind INT ,SMCostDiv INT , CostAccSeq INT , AccSeq INT  , BgtSeq INT , UMCostType INT )      

        EXEC _SESMBAccountScopeQuery @CompanySeq , @FSDomainSeq , 5507001 ,  0        
           
        CREATE TABLE #ESMProdAcc( AccSeq INT ,UMCostType INT)
    
        CREATE TABLE #ESMMatAcc( AccSeq INT ,UMCostType INT)

		INSERT INTO #ESMProdAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostDiv = 5507001   --Á¦Á¶¿ø°¡°èÁ¤ È®ÀÎÇÏ´Âµ¥ ¾´´Ù.
    
		INSERT INTO #ESMMatAcc
		SELECT DISTINCT ACCSEQ ,UMCostType FROM #ESMAccount WHERE SMCostKind = 5519001   --Àç·áºñ °èÁ¤ È®ÀÎ¿¡ »ç¿ë

   
--    END


	IF @SMSlipKind = 5522007        --5522007 ±âÅ¸ÀÔÃâ°íÀüÇ¥_Á¦Ç°¿ø°¡°è»êÀü    
		GOTO PROC_PreProd
	ELSE IF @SMSlipKind = 5522006   --5522006  ±âÅ¸ÀÔÃâ°íÀüÇ¥_Á¦Ç°    
		GOTO PROC_AfterProd
	ELSE IF @SMSlipKind = 5522005   --5522005  ±âÅ¸ÀÔÃâ°íÀüÇ¥_»óÇ°    
		GOTO PROC_Goods
	ELSE IF @SMSlipKind = 5522004   --5522004  ±âÅ¸ÀÔÃâ°íÀüÇ¥_ÀÚÀç    
		GOTO Proc_Mat
	ELSE IF @SMSlipKind = 5522012   --5522012  ¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_Á¦Ç°   
		GOTO AVG_Prod
	ELSE IF @SMSlipKind = 5522014   --5522014  ¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_»óÇ°    
		GOTO AVG_Goods
	ELSE IF @SMSlipKind = 5522013   --5522013  ¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_ÀÚÀç    
		GOTO AVG_Mat
	ELSE IF @SMSlipKind = 5522015	--5522015 ±âÅ¸ÀÔÃâ°íÀüÇ¥_Á¦Ç°(Ç°¸ñº°)
		GOTO Proc_ItemAfterProd
	ELSE 
		GOTO Proc_Query
	RETURN 

/*****************************************************************************************/
PROC_PreProd:  --5522007 ±âÅ¸ÀÔÃâ°íÀüÇ¥_Á¦Ç°¿ø°¡°è»êÀü    

    --2) ¿î¿µÈ¯°æ°ü¸®°ª °¡Á®¿À±â    
    DECLARE @SMGoodSetPrice    INT        
    -- Á¦Ç°±âÅ¸Ãâ°í½Ã Àû¿ë´Ü°¡    
    EXEC dbo._SCOMEnv @CompanySeq, 5539,@UserSeq,@@PROCID,@SMGoodSetPrice OUTPUT    
    --5523001  Àü¿ù Àç°í´Ü°¡    
    --5523002  Ç¥ÁØ Àç°í´Ü°¡    
    --5523003  Ç¥ÁØ¿ø°¡    
   
    CREATE TABLE #GoodPrice    
    (ItemSeq    INT,    
     StkPrice   DECIMAL(19,5))    
    

 
    IF @SMGoodSetPrice = 5523001 --Àü¿ùÀç°í´Ü°¡    
    BEGIN    
       -- Àü¿ù Å°¸¦ °¡Áö°í ¿Â´Ù.    

        DECLARE @PreCostKeySeq   INT    
                
        SELECT TOP 1 @PreCostKeySeq = CostKeySeq    
          FROM _TESMDCostKey  AS A     
         WHERE A.CompanySeq    = @CompanySeq    
           AND A.CostYM        < @CostYM    
           AND A.RptUnit       = @RptUnit    
           AND A.SMCostMng     = @SMCostMng    
           AND A.CostMngAmdSeq = @CostMngAmdSeq    
           AND A.PlanYear      = @PlanYear    
         ORDER BY A.CostYM DESC    
        
        --Àü¿ù Àç°í´Ü°¡ÀÇ ±Ý¾×À» °¡Áö°í ¿Â´Ù.     
        INSERT INTO #GoodPrice (ItemSeq, StkPrice)    
        SELECT A.itemSeq, ISNULL(C.Price,0)    
          FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
                     JOIN _TDAItem           AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                              AND A.ItemSeq    = D.ItemSeq    
                     JOIN _TDAItemAsset      AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                              AND D.AssetSeq   = E.AssetSeq     
                     JOIN _TDASMInor         AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                              AND E.SMAssetGrp = F.MinorSeq    
          LEFT OUTER JOIN _TESMCProdStkPrice AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq    
                                                              AND A.ItemSeq    = C.ItemSeq    
                                                              AND C.CostUnit   = A.CostUnit     
                                                              AND C.CostKeySeq = @PreCostKeySeq     
         WHERE A.CompanySeq = @CompanySeq 
		   AND A.CostKeySeq = @CostKeySeq   
           AND F.MinorValue = '0'    --Á¦Ç°/»óÇ°    
           AND A.InOutDate  LIKE @CostYM + '%'    
           AND A.InOutKind  = 8023003
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )

           AND F.MinorSeq <> 6008001 -- »óÇ°Á¦¿Ü    
           --±âÅ¸Ãâ°í °èÁ¤¿¡ ¼³Á¤µÈ °èÁ¤ ¹üÀ§ ÇÑÁ¤½ÃÅ°±â.    
    
    
		-- Àü¿ù Àç°í´Ü°¡°¡ ¾øÀ» °æ¿ì Ç¥ÁØÀç°í´Ü°¡¸¦ »ç¿ëÇÑ´Ù.     
		UPDATE #GoodPrice    
		   SET StkPrice = ISNULL(B.Price,0)    
		  FROM  #GoodPrice AS A     
		  JOIN _TESMBItemStdPrice AS B ON B.CompanySeq = @CompanySeq
									  AND A.ItemSeq    = B.ItemSeq 
          LEFT OUTER JOIN _TESMCProdStkPrice AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    --2011.02.01  ÁöÇØ: Àü¿ùÀç°í´Ü°¡¾ø´Â°æ¿ì Ãß°¡.¤Ð,.¤Ð
                                                              AND B.ItemSeq    = C.ItemSeq    
                                                              AND B.CostUnit   = C.CostUnit     
                                                              AND C.CostKeySeq = @PreCostKeySeq   
		 WHERE B.CostUnit = @CostUnit    
           AND C.Price IS NULL 
	     

		--Ãâ°í±Ý¾× Update     
		UPDATE _TESMGInOutStock    
		   SET Amt      = Round(ISNULL(C.StkPrice, 0) * A.Qty,0)    
		  FROM _TESMGInOutStock           AS A WITH(NOLOCK)    
					 JOIN _TDAItem        AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
															AND A.ItemSeq    = D.ItemSeq    
					 JOIN _TDAItemAsset   AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
															AND D.AssetSeq   = E.AssetSeq     
					 JOIN _TDASMInor      AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
															AND E.SMAssetGrp = F.MinorSeq    
		  LEFT OUTER JOIN #GoodPrice      AS C WITH(NOLOCK) ON A.ItemSeq     = C.ItemSeq        
		  LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq  = J.CompanySeq    
														   AND A.InOutDetailKind = J.MinorSeq    
														   AND J.ValueSeq    > 0    
														   AND J.Serl        = '2003'      -- °èÁ¤°ú¸ñ 
		  LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq  = K.CompanySeq    
														   AND A.InOutDetailKind = K.MinorSeq    
														   AND K.Serl            = '2004'      -- ºñ¿ë±¸ºÐ  
					 JOIN #ESMProdAcc     AS Z              ON J.ValueSeq        = Z.AccSeq    
                                                           AND K.ValueSeq        = Z.UMCostType                                                         
		 WHERE A.CompanySeq = @CompanySeq    
		   AND A.CostKeySeq = @CostKeySeq
		   AND F.MinorValue  = '0'    
		   AND F.MinorSeq <> 6008001 -- »óÇ°Á¦¿Ü    
		   AND A.InOutDate LIKE @CostYM + '%'    
		   AND A.InOutKind = 8023003
		   AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
			  OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.StkPrice <> 0     --ÀÌ·¸°Ô ÇØµÎ¸é Àü¿ùÀÌ³ª Ç¥ÁØÀç°í´Ü°¡°ªÀÌ ¾ø¾îÁ³À»¶§ 0À¸·Î µÇ¾î¾ß ÇÏ´Âµ¥ ¾÷µ¥ÀÌÆ®¾ÈµÇ°í ±×´ë·Î ³²°ÔµÊ. 
 

	 
	END    
    ELSE IF  @SMGoodSetPrice = 5523002 --Ç¥ÁØÀç°í´Ü°¡    
    BEGIN 
		UPDATE _TESMGInOutStock    
           SET Amt      = Round(ISNULL(C.Price,0) * A.Qty,0)    
          FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
                     JOIN _TDAItem           AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
                                                              AND A.ItemSeq     = D.ItemSeq    
                     JOIN _TDAItemAsset      AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                              AND D.AssetSeq    = E.AssetSeq     
                     JOIN _TDASMInor         AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
                                                              AND E.SMAssetGrp  = F.MinorSeq    
          LEFT OUTER JOIN _TESMBItemStdPrice AS C WITH(NOLOCK) ON A.CompanySeq  = C.CompanySeq
														      AND A.ItemSeq     = C.ItemSeq                                                                       
                                                              AND C.CostUnit    = @CostUnit    
                                                              AND C.CostUnitKind     = @FGoodPriceUnit     
          LEFT OUTER JOIN _TDAUMinorValue    AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                              AND A.InOutDetailKind  = J.MinorSeq    
                                                              AND J.ValueSeq         > 0    
                                                              AND J.Serl             = '2003'     -- °èÁ¤°ú¸ñ    
          LEFT OUTER JOIN _TDAUMinorValue    AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                              AND A.InOutDetailKind  = K.MinorSeq    
                                                              AND K.Serl             = '2004'     -- ºñ¿ë±¸ºÐ    
                   JOIN #ESMProdAcc          AS Z              ON J.ValueSeq = Z.AccSeq               
                                                              AND K.ValueSeq        = Z.UMCostType
         WHERE A.CompanySeq = @CompanySeq 
           AND A.CostKeySeq = @CostKeySeq   
           AND F.MinorValue  = '0'    
           AND F.MinorSeq <> 6008001 -- »óÇ°Á¦¿Ü    
           AND A.InOutDate LIKE @CostYM + '%'    
           AND A.InOutKind = 8023003 
           AND ( (@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
              OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ) )
--		   AND C.Price <> 0     
 

 

    END    
    ELSE --Ç¥ÁØ¿ø°¡    
    BEGIN    
		UPDATE _TESMGInOutStock    
           SET Amt      = Round(ISNULL(C.CostStdPrice,0) * A.Qty,0)    
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                     JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq    
                                                             AND A.ItemSeq     = D.ItemSeq    
                     JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                             AND D.AssetSeq    = E.AssetSeq     
                     JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq  = F.CompanySeq    
                                                             AND E.SMAssetGrp  = F.MinorSeq    
          LEFT OUTER JOIN _TESMSItemStdCost AS C WITH(NOLOCK) ON A.CompanySeq  = C.CompanySeq 
															 AND A.ItemSeq     = C.ItemSeq                                                                       
                                                             AND A.CostUnit    = C.CostUnit    
          LEFT OUTER JOIN _TDAUMinorValue   AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                             AND A.InOutDetailKind  = J.MinorSeq    
                                                             AND J.ValueSeq         > 0    
                                                             AND J.Serl             = '2003'   -- °èÁ¤°ú¸ñ      
           LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                             AND A.InOutDetailKind  = K.MinorSeq    
                                                             AND K.Serl             = '2004'   -- ºñ¿ë±¸ºÐ    
                   JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq                 
                                                             AND K.ValueSeq        = Z.UMCostType
            WHERE A.CompanySeq = @CompanySeq 
              AND A.CostKeySeq = @CostKeySeq    
              AND F.MinorValue  = '0'    
              AND F.MinorSeq <> 6008001 -- »óÇ°Á¦¿Ü    
              AND A.InOutDate LIKE @CostYM + '%'    
              AND A.InOutKind = 8023003     
              AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
                   OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--              AND C.CostStdPrice <> 0     
    END    
    
    --ÀÚ»ê°èÁ¤/±âÅ¸Ãâ°íÀÇÃ³¸®°èÁ¤    
    --Á¦Ç°    

    --±âÅ¸ÀÔ°í     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0),
           ISNULL(A.CustSeq       , 0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
          JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq             , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq
                 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark     , AssetSeq  , DrAccSeq,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0), --Â÷º¯°èÁ¤    
 ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq= Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq         = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq            , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   ,
           ISNULL(A.CustSeq ,0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq      ,
           A.CustSeq         
 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq  , 0) , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)  ,              
           ISNULL(A.CustSeq , 0)  

      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq           
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- °èÁ¤°ú¸ñ      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ºñ¿ë±¸ºÐ    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt       , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq  , 0) , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)    ,            
           ISNULL(A.CustSeq , 0)    
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
--               JOIN _TDAUMinorValue  AS M WITH(NOLOCK) ON G.CompanySeq  = M.CompanySeq    
--                                                      AND G.MinorSeq    = M.MinorSeq    
--                                                      AND M.ValueText   <> '1'     
--                                                      AND M.Serl        = '2003'    --ºÎ°¡¼¼½Å°í´ë»óÁ¦¿Ü?? ÇÊ¿äÇÑÁö ¾Ë¾Æ¿À±â    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- °èÁ¤°ú¸ñ      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ºñ¿ë±¸ºÐ    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
 AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq          ,
           A.CustSeq        
    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ     
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­    
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
--               JOIN _TDAUMinorValue  AS M WITH(NOLOCK) ON G.CompanySeq  = M.CompanySeq    
--                                                      AND G.MinorSeq    = M.MinorSeq    
--                                                      AND M.ValueText   <> '1'     
--                                                      AND M.Serl        = '2003'    --ºÎ°¡¼¼½Å°í´ë»óÁ¦¿Ü?? ÇÊ¿äÇÑÁö ¾Ë¾Æ¿À±â    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'        -- °èÁ¤°ú¸ñ      
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'        -- ºñ¿ë±¸ºÐ    
               --LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
               --                                          AND E.AssetSeq         = L.AssetSeq    
               --                                AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
--     AND A.CostUnit  = @CostUnit
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ   
           A.DeptSeq            ,    
           A.CCtrSeq        ,
           A.CustSeq

    IF @BanToProc = 1  --¹ÝÁ¦Ç° Àç°øÀ¸·Î Ã³¸®
    BEGIN

    --±âÅ¸ÀÔ°í  ( Å¸°èÁ¤¿¡¼­ ´ëÃ¼ /  ÀâÀÌÀÍ ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType,0), --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,   
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType

  
--Àç°øÇ°-Àç°ø¿¡¼­ Å¸°èÁ¤À¸·Î´ëÃ¼
--Å¸°èÁ¤¿¡¼­ °èÁ¤ : 17
--Å¸°èÁ¤À¸·Î °èÁ¤ : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --¹ÝÁ¦Ç° 
  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq        


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)  , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
       AND K.Serl             = '1002'    

               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                    AND K.ValueSeq         = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq           , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq        ,
           A.CustSeq     

 
END
   ELSE --¹ÝÁ¦Ç°À» Àç°øÀ¸·Î Ã³¸®ÇÏÁö ¾ÊÀ»¶§ 
   BEGIN 

    --±âÅ¸ÀÔ°í    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq , CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,   
           ISNULL(A.CustSeq     , 0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                               AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq          

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq            , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,
           ISNULL(A.CustSeq     ,0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												        AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                        AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼ 
               JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.Valueseq   = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq ,
           A.CustSeq   
		   
END
         
    GOTO Proc_Query

 

RETURN 
/**************************************************************************************************************/
PROC_AfterProd: --¿ø°¡°è»ê ÈÄ

   

    ---Á¦Ç°ÀÇ ±âÅ¸ÀÔ°í, ±âÅ¸Ãâ°í 

    --±âÅ¸ÀÔ°í     
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   , 
           ISNULL(A.CustSeq     , 0)   
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType

   WHERE A.CompanySeq = @CompanySeq 
     AND A.CostKeySeq = @CostKeySeq    
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) 
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq  ,
           A.CustSeq       

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     ,0) 
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq  = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq         = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
    AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq            , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq    
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     , 0)    
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq   
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'     

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
                LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType


   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL 
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq          
    --±âÅ¸Ãâ°í(Á¦Á¶°èÁ¤ Á¦¿Ü)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç°  
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
          
    INSERT INTO #TempInOut(    
           SMSlipKind  ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
           ISNULL(A.CustSeq , 0)       
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                            AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  

   WHERE A.CompanySeq = @CompanySeq  
     AND A.CostKeySeq = @CostKeySeq   
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç°  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq        
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,               
           ISNULL(A.CustSeq , 0) 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
           JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit  = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç°  
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq             
    /*****************************************************/    
    --Àû¼Ûº¸Á¤±Ý¾×Ã³¸®    
    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
    /*****************************************************/    
    
--    --Àû¼ÛÁ¶Á¤°èÁ¤    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    
     --´Ü¼öÁ¶Á¤°èÁ¤    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    


    -- ±âÅ¸­x°íÀÇ ¿ø°¡°è»ê ÈÄ    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               --@cTRANsAdjAccSeq       , --´ëº¯°èÁ¤(Àû¼ÛÁ¶Á¤°èÁ¤)    
               --0, --´ëº¯ºñ¿ë±¸ºÐ(Àû¼ÛÁ¶Á¤°èÁ¤ ºñ¿ë±¸ºÐ)    
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ    
               ISNULL(L.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0        ,
               0  
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- Å¸°èÁ¤À¸·Î´ëÃ¼   
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í   
          AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç°  
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ    
                 L.AccSeq,L.UMCostType

 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               @cTRANsAdjAccSeq       , --´ëº¯°èÁ¤(Àû¼ÛÁ¶Á¤°èÁ¤)    
               0, --´ëº¯ºñ¿ë±¸ºÐ(Àû¼ÛÁ¶Á¤°èÁ¤ ºñ¿ë±¸ºÐ)     
               ISNULL(L.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0        ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21 --Å¸°èÁ¤À¸·Î´ëÃ¼
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤    
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í   
          AND E.SMAssetGrp <>  6008004 --¹ÝÁ¦Ç°  
          AND E.IsFromOtherAcc = '1' 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,  
                 L.AccSeq,L.UMCostType
 

    IF @BanToProc = 1  --¹ÝÁ¦Ç° Àç°øÀ¸·Î Ã³¸®
    BEGIN

    --±âÅ¸ÀÔ°í  ( Å¸°èÁ¤¿¡¼­ ´ëÃ¼ /  ÀâÀÌÀÍ ) 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType,0), --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)   ,
           ISNULL(A.CustSeq    ,0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                 AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                                    AND K.ValueSeq        = Z.UMCostType

  
--Àç°øÇ°-Àç°ø¿¡¼­ Å¸°èÁ¤À¸·Î´ëÃ¼
--Å¸°èÁ¤¿¡¼­ °èÁ¤ : 17
--Å¸°èÁ¤À¸·Î °èÁ¤ : 21  

   WHERE A.CompanySeq = @CompanySeq    
     AND A.CostKeySeq = @CostKeySeq 
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp  = 6008004 --¹ÝÁ¦Ç° 
     AND Z.AccSeq  IS NULL
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq     

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)  , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)    ,
           ISNULL(A.CustSeq     ,0)
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    )) 
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq           , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq         ,
           A.CustSeq

 
    --±âÅ¸Ãâ°í(Á¦Á¶°èÁ¤ Á¦¿Ü)  Å¸°èÁ¤À¸·Î´ëÃ¼/ Àç°øÇ°
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           ISNULL(L.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,          
           ISNULL(A.CustSeq , 0)
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
 JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq         = Z.AccSeq     
            AND K.ValueSeq        = Z.UMCostType

		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
           A.CustSeq    

    --±âÅ¸Ãâ°í(Á¦Á¶°èÁ¤ Á¦¿Ü) ÆÇ°üºñ/Å¸°èÁ¤À¸·Î´ëÃ¼ 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
           ISNULL(A.CustSeq , 0)              
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq   
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq

        
    /*****************************************************/    
    --Àû¼Ûº¸Á¤±Ý¾×Ã³¸®    
    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
    /*****************************************************/    
    
    --Àû¼ÛÁ¶Á¤°èÁ¤    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- ±âÅ¸­x°íÀÇ ¿ø°¡°è»ê ÈÄ  (  Å¸°èÁ¤À¸·Î ´ëÃ¼    /Àç°øÇ°  
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               ISNULL(N.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               ISNULL(N.UMCostType,0)          , --Â÷º¯ºñ¿ë±¸ºÐ    
               ISNULL(L.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               ISNULL(L.UMCostType,0)          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í    
          AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType , N.AccSeq,N.UMCostType     
    
  

    -- ±âÅ¸­x°íÀÇ ¿ø°¡°è»ê ÈÄ  ( Á¶Á¤°èÁ¤ / Å¸°èÁ¤À¸·Î ´ëÃ¼)   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               @cTRANsAdjAccSeq       , --´ëº¯°èÁ¤(Àû¼ÛÁ¶Á¤°èÁ¤)    
               0, --´ëº¯ºñ¿ë±¸ºÐ(Àû¼ÛÁ¶Á¤°èÁ¤ ºñ¿ë±¸ºÐ)    
               ISNULL(N.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               ISNULL(N.UMCostType,0)          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0        ,0
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤   
    AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit      = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í    
          AND E.SMAssetGrp   = 6008004  --¹ÝÁ¦Ç° 
        GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, N.AccSeq,N.UMCostType   

 

   END 
   ELSE --¹ÝÁ¦Ç°À» Àç°øÀ¸·Î Ã³¸®ÇÏÁö ¾ÊÀ»¶§ 
   BEGIN 

    --±âÅ¸ÀÔ°í    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0)  ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
    AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq    ,
           A.CustSeq    

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0) ,  
           ISNULL(A.CustSeq     , 0)     
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
           AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'   
               LEFT OUTER  JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    

		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               LEFT OUTER JOIN #ESMProdAcc         AS Z              ON J.ValueSeq = Z.AccSeq          --Á¦Á¶¿ø°¡ °è»ê´ë»óÀÎ Ç×¸ñ 
                                                         AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq            , --Â÷º¯°èÁ¤    
           N.UMCostType            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
           A.CustSeq 
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq     , 0),  
           ISNULL(A.CustSeq     , 0)   
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq   
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq      
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                        AND K.Serl             = '1002'    
		       LEFT OUTER  JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                        AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												        AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													    AND A.InOutDetailKind = M.minorseq 
													    AND M.ValueText <> 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                          AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsToOtherAcc = '1'
     AND Z.AccSeq IS NULL
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq            ,
           A.CustSeq  
		   
    --±âÅ¸Ãâ°í(Á¦Á¶°èÁ¤ Á¦¿Ü)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)    ,  
           ISNULL(A.CustSeq     , 0)              
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
      AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
  GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq    ,
           A.CustSeq 
           
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)               
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'  
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq   ,
           A.CustSeq
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq , 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
   ISNULL(A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)                 
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN #ESMProdAcc AS Z           ON J.ValueSeq = Z.AccSeq     
                                                          AND K.ValueSeq        = Z.UMCostType

		        LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText <> 1   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                      AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001  
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND Z.AccSeq IS NULL
      AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
     AND E.IsFromOtherAcc = '1'
  GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq            ,
           A.CustSeq          
    /*****************************************************/    
    --Àû¼Ûº¸Á¤±Ý¾×Ã³¸®    
    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
    /*****************************************************/    
    
    --Àû¼ÛÁ¶Á¤°èÁ¤    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
    
    
    -- ±âÅ¸­x°íÀÇ ¿ø°¡°è»ê ÈÄ    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
          DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               --@cTRANsAdjAccSeq       , --´ëº¯°èÁ¤(Àû¼ÛÁ¶Á¤°èÁ¤)    
               --0, --´ëº¯ºñ¿ë±¸ºÐ(Àû¼ÛÁ¶Á¤°èÁ¤ ºñ¿ë±¸ºÐ)  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
               CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ      
               ISNULL(L.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0     ,0   
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤   
                   LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                         AND D.Companyseq = O.CompanySeq      
                                                         AND O.AssetAccKindSeq = 21-- Å¸°èÁ¤À¸·Î´ëÃ¼    
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í    
          AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind,
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
                 CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ    
                 L.AccSeq,L.UMCostType
                 
                 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
        SELECT @SMSlipKind,    
               A.SMAdjustKind , --±âÅ¸Ãâ°íÀ¯Çü    
               A.InOutKind , --ÀÔÃâ°íÀ¯Çü    
               E.AssetSeq             , --Àç°íÀÚ»êºÐ·ù    
               @cTRANsAdjAccSeq       , --´ëº¯°èÁ¤(Àû¼ÛÁ¶Á¤°èÁ¤)    
               0, --´ëº¯ºñ¿ë±¸ºÐ(Àû¼ÛÁ¶Á¤°èÁ¤ ºñ¿ë±¸ºÐ)    
               ISNULL(L.AccSeq, 0)    , --Â÷º¯°èÁ¤    
               L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
               SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
               1                     , --¼ø¼­    
               A.DeptSeq             ,    
               0                     ,0 
          FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
                   JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                          AND A.ItemSeq    = D.ItemSeq    
                   JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq    
                                                          AND D.AssetSeq    = E.AssetSeq      
                   LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                         AND E.AssetSeq     = L.AssetSeq    
                                                         AND L.AssetAccKindSeq = 21-- Å¸°èÁ¤À¸·Î´ëÃ¼  
        WHERE A.CompanySeq = @CompanySeq 
          AND A.CostKeySeq = @CostKeySeq
          AND A.SMAdjustKind = 5513001 -- Á¦Ç°´Ü°¡º¸Á¤   
          AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
               OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
          AND A.CostKeySeq   = @CostKeySeq    
          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í    
          AND E.SMAssetGrp = 6008004 --¹ÝÁ¦Ç° 
          AND E.IsFromOtherAcc = '1' 
   GROUP BY E.AssetSeq ,A.InOutKind , A.DeptSeq , 
                 A.SMAdjustKind, L.AccSeq,L.UMCostType  


   END 



    /******************************************************************/    
    --´ëÃ¼Ãâ°í :¿ì¼± Á¦¿Ü(±âÅ¸ÀÔÃâ°í¸¦ ½á¶ó)    
    /******************************************************************/    
     

    GOTO Proc_Query
   
RETURN 

/*****************************************************************************************/
PROC_GoodS: --»óÇ°
    
    --±âÅ¸ÀÔ°í    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)  ,  
           ISNULL(A.CustSeq     , 0)                      
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                   AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND ( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL) --Å¸°èÁ¤¿¡¼­ ´ëÃ¼°¡ ¾Æ´Ñ°æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind   ,
           A.CustSeq
        
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq   ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq) 
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤    
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ
           ISNULL(N.AccSeq, 0) , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ        
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)                       
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28  
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í   
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --Å¸°èÁ¤¿¡¼­ ´ëÃ¼ÀÎ °æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü  
           L.AccSeq             , --´ëº¯°èÁ¤    
           L.UMCostType         ,       
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         , --Â÷º¯ºñ¿ë±¸ºÐ   
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind     ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq    ) 
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(J.ValueSeq, 0)   , --Â÷º¯°èÁ¤    
           K.ValueSeq          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
      1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)    ,  
           ISNULL(A.CustSeq     , 0)                    
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28  
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1' --Å¸°èÁ¤¿¡¼­ ´ëÃ¼ÀÎ °æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           N.AccSeq             , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           J.ValueSeq             , --Â÷º¯°èÁ¤    
           K.ValueSeq         ,    
           A.DeptSeq            ,    
           A.CCtrSeq       ,  
           A.InOutKind      ,
           A.CustSeq
           
           
    --±âÅ¸Ãâ°í   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤    
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0)                        
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--              LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                  ON C.DeptSeq    = P.DeptSeq      
--                                                 AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
                  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )--Å¸°èÁ¤À¸·Î ´ëÃ¼°¡ ¾Æ´Ñ °æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           j.ValueSeq          , --Â÷º¯°èÁ¤    
           K.ValueSeq          , --Â÷º¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --´ëº¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq
           
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤    
L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)  ,  
           ISNULL(A.CustSeq     , 0)                      
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --Å¸°èÁ¤À¸·Î ´ëÃ¼°¡ ¾Æ´Ñ °æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           N.AccSeq          , --Â÷º¯°èÁ¤    
           N.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --´ëº¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(J.ValueSeq, 0)   , --Â÷º¯°èÁ¤    
   K.ValueSeq          , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq            ,    
         ISNULL(A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)                     
      FROM _TESMGInOutStock          AS A WITH(NOLOCK)    
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                               AND E.SMAssetGrp    = F.MinorSeq     
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               --LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
               --                                      AND E.AssetSeq     = L.AssetSeq    
               --                                      AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1' --Å¸°èÁ¤À¸·Î ´ëÃ¼°¡ ¾Æ´Ñ °æ¿ì
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           J.ValueSeq             , --Â÷º¯°èÁ¤    
           K.ValueSeq         ,    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           A.DeptSeq              ,    
           A.CCtrSeq       ,  
           A.InOutKind    ,
           A.CustSeq

--    /*****************************************************/    
--    --´Ü¼öº¸Á¤±Ý¾×Ã³¸®    
--    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
--    /*****************************************************/    
--    
    --´Ü¼öÁ¶Á¤°èÁ¤    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%º¸Á¤%'
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt     , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --±âÅ¸Ãâ°íÀ¯Çü    
           5513003           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --´ëº¯°èÁ¤    
           --ISNULL(0, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ   
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0)   ,  
           ISNULL(A.CustSeq     , 0)         
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 1 -- ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  
                                                     AND D.Companyseq = O.CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- Å¸°èÁ¤À¸·Î´ëÃ¼   
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/  
     --AND F.MinorValue  = '1'    --ÀÚÀç    
     --AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í 
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @GoodPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @GoodPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
--     AND E.IsFromOtherAcc = '1'
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END,--´ëº¯ºñ¿ë±¸ºÐ   
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq 
           
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq)    
    SELECT  @SMSlipKind,    
           0      , --±âÅ¸Ãâ°íÀ¯Çü    
           5513003           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(@cTRANsAdjAccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(0, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
             AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
 
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorSeq IN (6008001) --6008001»óÇ°/  
     --AND F.MinorValue  = '1'    --ÀÚÀç    
     --AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í 
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND A.SMAdjustKind = 5513003 
--     AND A.CostUnit = @CostUnit    
     AND ((@GoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
          OR (@GoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq
--    /*****************************************************/    
--    --Àû¼Ûº¸Á¤±Ý¾×Ã³¸®    
--    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
--    /*****************************************************/    
--    
--    --Àû¼ÛÁ¶Á¤°èÁ¤    
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--        
--    EXEC dbo._SCOMEnv @CompanySeq, 5506,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    --´Ü¼ö±Ý¾× º¸Á¤    
--    UPDATE #TempInOut     
--       SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--              AND A.SMAdjustKind = 5513003 -- ÀÚÀç´Ü°¡º¸Á¤    
--              AND A.CostUnit     = @CostUnit     
--              AND A.CostKeySeq   = @CostKeySeq    
--              AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í     
--              ),0)    
--      FROM #TempInOut     
--    /******************************************************************/    
--    --´ëÃ¼Ãâ°í :¿ì¼± Á¦¿Ü(±âÅ¸ÀÔÃâ°í¸¦ ½á¶ó)    
--    /******************************************************************/    
    
    GOTO Proc_Query
        
RETURN 
/*********************************************************************************************************/  
PROC_Mat: --±âÅ¸ÀÔÃâ°í ÀÚÀç


    --±âÅ¸ÀÔ°í    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType           , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0)  , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0)  , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)            
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤     
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			    LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
                   
   WHERE A.CompanySeq = @CompanySeq     
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )     
    AND (( E.IsToOtherAcc = '0' OR E.IsToOtherAcc IS NULL)  
        OR (O.AccSeq IS NOT NULL ))
		 AND (A.InOutDetailKind IN (SELECT MinorSeq 
                                      FROM _TDAUMinorValue AS A 
                                     WHERE A.CompanySeq = @CompanySeq 
                                       AND A.MajorSeq = 8025
                                       AND A.Serl = 1000005 
                                       AND A.ValueText = '1' 
                                   ) 
             )		-- µå·³Æ÷Àå
	 AND (AA.InOutType=31) 

     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü   
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ     
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind          ,
           A.CustSeq ,
		   AB.ItemSeq
	
	
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind, 
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType           , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0)  , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)
	  --SELECT A.InOutDetailKind,A.InOutSeq, A.InOutSerl, AA.InOutSeq, AA.InOutSerl            
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
      )     
    AND E.IsToOtherAcc = '1' AND O.AccSeq IS NULL 
	AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	AND (AA.InOutType=31)

  --    Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
   --  AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq,
		   AB.ItemSeq
  
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType           , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0)  , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0)  , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0) ,
		   ISNULL(AB.ItemSeq,0)          
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '1001'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '1002'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 17 -- Å¸°èÁ¤¿¡¼­ ´ëÃ¼  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			    LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit   
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )     
    AND E.IsToOtherAcc = '1'  AND O.AccSeq IS NULL
	AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå 
	AND (AA.InOutType=31)
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü   
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ     
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq	,
           AB.ItemSeq 


     --±âÅ¸Ãâ°í 
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)        
	  --SELECT AA.InOutType,A.*    
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                               AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                   --  AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl

   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND (( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
         OR (O.AccSeq IS NOT NULL))
	 AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	-- AND (AA.InOutType=31) 
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
          A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq,
		   AB.ItemSeq
   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
        LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK)ON E.CompanySeq   = L.CompanySeq    
                                                     AND E.AssetSeq     = L.AssetSeq    
                                                     AND L.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1' AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	 AND (AA.InOutType=31) 
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
          A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           N.AccSeq         , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq  ,
		   AB.ItemSeq
           

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0),  
           ISNULL(A.CustSeq     , 0)  ,
		   ISNULL(AB.ItemSeq,0)          
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq    
--               LEFT OUTER JOIN _FnAdmEmpCCtr(@CompanySeq , @CostYM ) AS P    
--                                                      ON C.DeptSeq    = P.DeptSeq      
--                                                     AND C.EmpSeq     = P.EmpSeq         
               JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq   = I.CompanySeq  --Áö¿ì¸®    
                                                     AND A.InOutDetailKind = I.MinorSeq    
                                                     --AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue AS J WITH(NOLOCK) ON A.CompanySeq   = J.CompanySeq    
                                                     AND A.InOutDetailKind = J.MinorSeq    
                                                     AND J.ValueSeq    > 0    
                                                     AND J.Serl         = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON A.CompanySeq   = K.CompanySeq    
                                                     AND A.InOutDetailKind = K.MinorSeq    
                                                     AND K.Serl         = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
               LEFT OUTER JOIN #ESMMatAcc   AS O ON j.ValueSeq = O.AccSeq  AND K.ValueSeq = O.UMCostType
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl
                   
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )  
     AND E.IsFromOtherAcc = '1'AND O.AccSeq IS NULL 
	 AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	 AND (AA.InOutType=31) 
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
          A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind    ,
           A.CustSeq,
		   AB.ItemSeq
--    /*****************************************************/    
--    --´Ü¼öº¸Á¤±Ý¾×Ã³¸®    
--    --Àû¼Û°ÇÀÌ ÀÖ°Å³ª ´ç¿ù Ãâ°í°¡ ±âÅ¸Ãâ°í(¿ø°¡°è»êÀü)¸¸ ¹ß»ýÇÑ°æ¿ìÀÇ º¸Á¤Ã³¸®ÀÌ´Ù.                       
--    /*****************************************************/    
--    
    --´Ü¼öÁ¶Á¤°èÁ¤    
    EXEC dbo._SCOMEnv @CompanySeq, 5507,@UserSeq,@@PROCID,@cTRANsAdjAccSeq OUTPUT    
--    --Àû¼ÛÁ¶Á¤ °èÁ¤ÀÇ ºñ¿ë±¸ºÐ    
--    EXEC dbo._SCOMEnv @CompanySeq, 5540,@UserSeq,@@PROCID,@cTRANsAdjUMcostTypeSeq OUTPUT    
--    select * from _TDASMinor where minorname like '%º¸Á¤%'


    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           0      , --±âÅ¸Ãâ°íÀ¯Çü    
           5513002           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           --ISNULL(@cTRANsAdjAccSeq, 0) , --´ëº¯°èÁ¤  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤  
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                     , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0) ,
		   ISNULL(AB.ItemSeq,0)        
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 1 --ÀÚ»êÃ³¸®°èÁ¤
               LEFT OUTER JOIN _TDAItemAssetAcc AS O WITH(NOLOCK) ON D.AssetSeq  = O.AssetSeq  AND O.Companyseq = @CompanySeq      
                                                     AND O.AssetAccKindSeq = 21-- Å¸°èÁ¤À¸·Î´ëÃ¼   
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND A.SMAdjustKind = 5513002 
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         )
	 AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	 AND (AA.InOutType=31)   
--     AND E.IsFromOtherAcc = '1'
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.AccSeq, 0) ELSE ISNULL(@cTRANsAdjAccSeq, 0) END, --´ëº¯°èÁ¤ 
           CASE WHEN E.IsFromOtherAcc = '1' THEN ISNULL(O.UMCostType, 0) ELSE ISNULL(0, 0) END, --´ëº¯ºñ¿ë±¸ºÐ     
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind  ,
           A.CustSeq  ,
		   AB.ItemSeq
         
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq    ,CustSeq, GoodItemSeq)    
    SELECT  @SMSlipKind,    
           0   , --±âÅ¸Ãâ°íÀ¯Çü    
           5513002           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(@cTRANsAdjAccSeq, 0) , --´ëº¯°èÁ¤  
           ISNULL(0, 0), --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType  , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1              , --¼ø¼­    
           A.DeptSeq             ,    
          ISNULL( A.CCtrSeq , 0) ,  
           ISNULL(A.CustSeq     , 0),
		   ISNULL(AB.ItemSeq,0)           
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)     
               JOIN _TDAItem         AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                      AND A.ItemSeq       = D.ItemSeq    
               JOIN _TDAItemAsset    AS E WITH(NOLOCK) ON D.CompanySeq    = E.CompanySeq    
                                                      AND D.AssetSeq      = E.AssetSeq     
               JOIN _TDASMInor       AS F WITH(NOLOCK) ON E.CompanySeq    = F.CompanySeq    
                                                      AND E.SMAssetGrp    = F.MinorSeq     
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                     AND N.AssetAccKindSeq = 21 --Å¸°èÁ¤À¸·Î´ëÃ¼
                LEFT OUTER JOIN KPX_TPDSFCProdPackReportRelation AS AA WITH(NOLOCK) ON A.CompanySeq    = AA.CompanySeq
																				  AND A.InOutSeq      = AA.InOutSeq
																				  AND A.InOutSerl     = AA.InOutSerl
			   LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem     AS AB WITH(NOLOCK) ON AA.CompanySeq   = AB.CompanySeq
																				  AND AA.WorkOrderSeq = AB.PackOrderSeq
																				  AND AA.WorkOrderSerl= AB.PackOrderSerl    
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '1'    --ÀÚÀç    
     AND F.MinorSeq    <> 6008005   --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í    
     AND A.InOutKind IN (8023003)  --±âÅ¸ÀÔ°í/±âÅ¸Ãâ°í    
     AND A.SMAdjustKind = 5513002 
     AND E.IsFromOtherAcc = '1'
--     AND A.CostUnit = @CostUnit    
     AND  (   ( @ItemPriceUnit = 5502002 AND A.AccUnit = @CostUnit )  
         OR ( @ItemPriceUnit = 5502003 AND A.BizUnit = @CostUnit )  
         ) 
	 AND (A.InOutDetailKind IN (8025007) )		-- µå·³Æ÷Àå
	 AND (AA.InOutType=31)  
--     AND E.IsFromOtherAcc = '1'
     -- Àç°í°ü¸® ¾ÈÇÏ´Â°Í Àç¿Ü, ¿ÜÁÖ°¡¾Æ´Ñ°Í, µî..    
     --AND  a.EtcInNo Not in  (SELECT EtcInNO FROM TTMCostInSlipM) --ÀÌ¹Ì µî·ÏµÈ ³»¿ë Á¦¿Ü    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq              ,    
           A.CCtrSeq     ,    
           A.InOutKind   ,
           A.CustSeq,
		   AB.ItemSeq
----´Ü¼ö±Ý¾× º¸Á¤    
--UPDATE #TempInOut     
--   SET Amt  = AMt + ISNULL((SELECT SUM(Amt) FROM _TESMGInOutStock  A  WHERE A.CompanySeq   = @CompanySeq    
--          AND A.SMAdjustKind = 5513002 -- ÀÚÀç´Ü°¡º¸Á¤    
--          AND A.CostUnit     = @CostUnit     
--          AND A.CostKeySeq   = @CostKeySeq    
--          AND A.InOutKind    = 8023003  --±âÅ¸Ãâ°í     
--          ),0)    
--  FROM #TempInOut     
  
    GOTO Proc_Query
RETURN 
/**************************************************************************************************************/
AVG_Prod: 
    --¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_Á¦Ç°(Á¦Á¶°èÁ¤ Á¦¿Ü)

--  _TDAItemAssetAcc : 
--         AssetAccKindSeq 22 : ³âÃÑÆò±Õ ÅõÀÔº¸Á¤°èÁ¤
--         AssetAccKindSeq 23 : ³âÃÑÆò±Õ ¸ÅÃâº¸Á¤°èÁ¤
--         AssetAccKindSeq 24 : ³âÃÑÆò±Õ ±âÅ¸º¸Á¤°èÁ¤
-- 
--select * From _TDADefineItemAssetAcc
--where companyseq = 1 
--¿¬ÃÑÆò±Õ º¸Á¤°èÁ¤Àº ÀÚ»êºÐ·ùº° °èÁ¤¼¼ÆÃ¿¡¼­ °¡Á®¿Àµµ·Ï ÇÑ´Ù. 
--È°µ¿¼¾ÅÍº°, Ç°¸ñº°·Î ÀüÇ¥¹ßÇàÀº È¯°æ¼³Á¤À» µû¸¥´Ù. ¸ÅÃâ¿ø°¡¸¦ °Çº°·Î º¸Á¤ÇÏ´Â°ÍÀº 
--¼öÀÍ¼ºÀ» À§ÇØ ÇÊ¿äÇÏ³ª ÀüÇ¥±îÁö °Çº°·Î ¹ßÇàÇÒ ÇÊ¿ä´Â ¾ø½¿. 

  
--- ¸ÅÃâ¿ø°¡ ÀüÇ¥Ã³¸®¿¡ È°µ¿¼¾ÅÍ, ÆÇ¸ÅºÎ¼­º°·Î ¸ÅÃâ¿ø°¡¸¦ ³ª´²¼­ ³»¿ªÁ¶È¸¸¦ ÇÏ´Â°ÍÀº È¯°æ¼³Á¤ °ª¿¡ µû¸¥´Ù.   
--- 5538 ¸ÅÃâ¿ø°¡ÀüÇ¥ È°µ¿¼¾ÅÍ(or ºÎ¼­)º° ·Î Áý°è ¿©ºÎ  
  

--Á¦Ç°¸ÅÃâ¿ø°¡ º¸Á¤½Ã Å¸°èÁ¤À¸·Î ÀüÇ¥´Â ¹ßÇàÇÒ ÇÊ¿ä°¡ ¾ø´Ù. º» °èÁ¤À¸·Î °¡´Â °èÁ¤ÀÌ¹Ç·Î Å¸°èÁ¤À¸·Î´Â 
--»©µµ·Ï ÇÏ±âÀ§ÇØ º¸Á¤°èÁ¤ÀÌ º»°èÁ¤°ú °°Àº ¸ÅÃâ¿ø°¡ °èÁ¤ÀÎ °æ¿ì¿¡´Â ±× Àç°íÀÚ»êºÐ·ù¿¡´Â Å¸°èÁ¤ÀüÇ¥´Â 
--¹ßÇàÇÏÁö ¾Êµµ·Ï ÇØ¾ßÇÑ´Ù.  
                                      
-- 
--5535001	5535	¿¬ÃÑÆò±Õ ¸ÅÃâ¿ø°¡Á¶Á¤
--5535002	5535	¿¬ÃÑÆò±Õ ÅõÀÔ±Ý¾×Á¶Á¤
--5535003	5535	¿¬ÃÑÆò±Õ ±âÅ¸Ãâ°í±Ý¾× Á¶Á¤

    INSERT INTO #TempInOut_Garbege(    
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc )    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤    
           L.UMCostType  , --´ëº¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³ 
           CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --ÅõÀÔÁ¦Ç°   
           0,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS NULL  THEN '1'  
                ELSE '0'  
           END      
       FROM _TESMGInOutStock             AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq    
                                                         AND E.AssetSeq         = N.AssetSeq    
                                                         AND (   (( A.InOutDetailKind = 5535002 )
                                                                   AND  N.AssetAccKindSeq  = 22 --ÅõÀÔº¸Á¤°èÁ¤
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535001 )
                                                                   AND  N.AssetAccKindSeq  = 23 --¸ÅÃâº¸Á¤°èÁ¤
                                                                  )   
                                                              OR (( A.InOutDetailKind = 5535003 )
                                                                   AND  N.AssetAccKindSeq  = 24 --±âÅ¸º¸Á¤°èÁ¤
                                                                 )
                                                             )   
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'   
     AND A.SMAdjustKind = 5513004 --Á¦Ç°±Ý¾×º¸Á¤_¿¬ÃÑÆò±Õ 
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003       --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001     
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     --AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--¿øÃµ±¸ºÐº° º¸Á¤ÀÌ ¾Æ´Ò °æ¿ì ¸ÅÃâ±âÅ¸º¸Á¤ »ç¿ë  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq             ,    
           N.UMCostType         ,  
           L.AccSeq             ,  
           L.UMCostType         ,    
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,    
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,    
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³ 
           CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END,     --ÅõÀÔÁ¦Ç°   
           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS NULL  THEN '1'  
                ELSE '0'  
           END     
   ORDER BY A.InOutDetailKind , E.AssetSeq 


    --Á¦Ç°ÀÇ °æ¿ì  ÅõÀÔÀÌ º¸Á¤ µÇ´Â °æ¿ì¿Í ±âÅ¸Ãâ°í°¡ º¸Á¤µÇ´Â °æ¿ì¸¦ ºÐ¸®ÇÏ±â ¾î·Á¿ò
    
--    INSERT INTO #TempInOut_Garbege(    
--           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,    
--           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,    
--           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind , IsFromOtherAcc )    
--    SELECT @SMSlipKind           ,    
--           5513004    , --±âÅ¸Ãâ°íÀ¯Çü    
--           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
--           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
--           ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤        
--           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ  
--           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤    
--           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
--           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
--           1                    , --¼ø¼­
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          , 
--           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
--           0,   --¸ÅÃâ°Å·¡Ã³ 
--           0 ,    --ÅõÀÔÁ¦Ç°   
--           A.InOutDetailKind AS UMRealDetilKind,            
--           CASE WHEN  E.IsFromOtherAcc = '1' AND M.AssetSeq IS NULL  THEN '1'  
--                ELSE '0'  
--           END      
--       FROM _TESMGInOutStock_YAVGAdj             AS A WITH(NOLOCK)    
--               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
--                                                         AND A.ItemSeq    = D.ItemSeq    
--               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
--                                                         AND D.AssetSeq   = E.AssetSeq     
--               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
--                                                         AND E.SMAssetGrp = F.MinorSeq    
--               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
--                                                         AND E.AssetSeq         = L.AssetSeq    
--                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
--               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq        
--                                                                 AND A.InOutDetailKind  = J.MinorSeq        
--                                                                 AND J.ValueSeq         > 0        
--                                                                 AND J.Serl             = '2003'        
--               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq        
--                                                                 AND A.InOutDetailKind  = K.MinorSeq        
--                                                                 AND K.Serl             = '2004'       
--               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
--   WHERE A.CompanySeq = @CompanySeq         
--     AND A.AdjCostKeySeq = @CostKeySeq
--     --AND A.InOutDate LIKE @CostYM + '%'   
--     --AND A.SMAdjustKind = 5513004 --Á¦Ç°±Ý¾×º¸Á¤_¿¬ÃÑÆò±Õ 
--     AND F.MinorValue  = '0'    
--     AND A.InOutKind = 8023003       --±âÅ¸Ãâ°í
--     AND F.MinorSeq <> 6008001     
--     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
--       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
--     AND (@YAVGAdjTransType = 5536001 ) --¿øÃµ±¸ºÐº°ÀÌ°í ±âÅ¸º¸Á¤ °èÁ¤ÀÏ °æ¿ì ¿øÃµº°·Î º¸Á¤ÇÔ  
--    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
--           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
--           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
--           ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤        
--           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ  
--           L.AccSeq             ,  
--           L.UMCostType         ,    
--           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,    
----           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,    
--           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,         
--           A.InOutDetailKind,
--           CASE WHEN  E.IsFromOtherAcc = '1' AND  M.AssetSeq IS  NULL  THEN '1'  
--                ELSE '0'  
--           END            
--   ORDER BY A.InOutDetailKind , E.AssetSeq 
 
     INSERT INTO #TempInOut(        
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,        
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,        
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)            
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   ,   
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,  
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,  
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,  
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,  
           Amt        , ShowOrder ,        
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,'1'  
     FROM #TempInOut_Garbege AS A   
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc  

    GOTO Proc_Query
 
   
RETURN 
/*****************************************************************************************/
AVG_GoodS: --¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_»óÇ°
     
--Á¦Ç°¸ÅÃâ¿ø°¡ º¸Á¤½Ã Å¸°èÁ¤À¸·Î ÀüÇ¥´Â ¹ßÇàÇÒ ÇÊ¿ä°¡ ¾ø´Ù. º» °èÁ¤À¸·Î °¡´Â °èÁ¤ÀÌ¹Ç·Î Å¸°èÁ¤À¸·Î´Â   
--»©µµ·Ï ÇÏ±âÀ§ÇØ º¸Á¤°èÁ¤ÀÌ º»°èÁ¤°ú °°Àº ¸ÅÃâ¿ø°¡ °èÁ¤ÀÎ °æ¿ì¿¡´Â ±× Àç°íÀÚ»êºÐ·ù¿¡´Â Å¸°èÁ¤ÀüÇ¥´Â   
--¹ßÇàÇÏÁö ¾Êµµ·Ï ÇØ¾ßÇÑ´Ù.   

--5535001 5535 ¿¬ÃÑÆò±Õ ¸ÅÃâ¿ø°¡Á¶Á¤  
--5535002 5535 ¿¬ÃÑÆò±Õ ÅõÀÔ±Ý¾×Á¶Á¤  
--5535003 5535 ¿¬ÃÑÆò±Õ ±âÅ¸Ãâ°í±Ý¾× Á¶Á¤   
 
    
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü      
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù      
           ISNULL(N.AccSeq, 0) , --Â÷º¯°èÁ¤      
           ISNULL(N.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ      
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤      
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ      
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×      
           1                    , --¼ø¼­  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³   
           --CASE WHEN ( @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 ) ) THEN 0 ELSE   A.GoodItemSeq   END     --ÅõÀÔÁ¦Ç°     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ÅõÀÔÀÏ °æ¿ì´Â ¿¬ÃÑº¸Á¤¿¡¼­ ¿øÃµ±¸ºÐº° º¸Á¤ÀÏ °æ¿ì´Â ¿ø°¡Ç×¸ñ¿¡ ÅõÀÔµÈ Á¦Ç°À» Á¶È¸½ÃÄÑ¾ß ÇÑ´Ù. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --ÅõÀÔÁ¦Ç°     
		   0,
           CASE WHEN  E.IsFromOtherAcc = '1'  AND M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   
					 
       FROM _TESMGInOutStock             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --ÅõÀÔº¸Á¤°èÁ¤  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --¸ÅÃâº¸Á¤°èÁ¤  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --±âÅ¸º¸Á¤°èÁ¤  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq   
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513006 --»óÇ°±Ý¾×º¸Á¤_ ¿¬ÃÑÆò±Õ  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --±âÅ¸Ãâ°í  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--¿øÃµ±¸ºÐº° º¸Á¤ÀÌ ¾Æ´Ò °æ¿ì ¸ÅÃâ±âÅ¸º¸Á¤ »ç¿ë  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù      
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³   
           --CASE WHEN @IsDivideCCtrItem = '0' AND ( A.InOutDetailKind <> 5535002 )  THEN 0 ELSE   A.GoodItemSeq   END     --ÅõÀÔÁ¦Ç°     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ÅõÀÔÀÏ °æ¿ì´Â ¿¬ÃÑº¸Á¤¿¡¼­ ¿øÃµ±¸ºÐº° º¸Á¤ÀÏ °æ¿ì´Â ¿ø°¡Ç×¸ñ¿¡ ÅõÀÔµÈ Á¦Ç°À» Á¶È¸½ÃÄÑ¾ß ÇÑ´Ù. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END,     --ÅõÀÔÁ¦Ç°     
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   
   ORDER BY A.InOutDetailKind , E.AssetSeq   
   
   
     
    INSERT INTO #TempInOut_Garbege (      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind, IsFromOtherAcc)    
    SELECT @SMSlipKind           ,      
           5513006               , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü      
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù      
           ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤        
           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ     
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤      
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ      
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×      
           1                    , --¼ø¼­  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END         ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           0,     --¸ÅÃâ°Å·¡Ã³   
           0,     --ÅõÀÔÁ¦Ç°     
           A.InOutDetailKind AS UMRealDetilKind, 					 
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   					 
       FROM _TESMGInOutStock_YAVGAdj             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq        
                                                                 AND A.InOutDetailKind  = J.MinorSeq        
                                                                 AND J.ValueSeq         > 0        
                                                                 AND J.Serl             = '2003'        
               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq        
                                                                 AND A.InOutDetailKind  = K.MinorSeq        
                                                                 AND K.Serl             = '2004'    
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq   
   WHERE A.CompanySeq = @CompanySeq           
     AND A.AdjCostKeySeq = @CostKeySeq  
     --AND A.InOutDate LIKE @CostYM + '%'     
     --AND A.SMAdjustKind = 5513006 --»óÇ°±Ý¾×º¸Á¤_ ¿¬ÃÑÆò±Õ  
     AND F.MinorValue  = '0'      
     AND A.InOutKind = 8023003       --±âÅ¸Ãâ°í  
     AND F.MinorSeq  = 6008001       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --¿øÃµ±¸ºÐº°ÀÌ°í ±âÅ¸º¸Á¤ °èÁ¤ÀÏ °æ¿ì ¿øÃµº°·Î º¸Á¤ÇÔ  
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù      
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü      
      ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤        
           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ   
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0'  AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN  E.IsFromOtherAcc = '1' AND   M.AssetSeq IS NULL THEN '1'  
                ELSE '0'  
           END   ,A.InOutDetailKind 
   ORDER BY A.InOutDetailKind , E.AssetSeq   
   

   INSERT INTO #TempInOut(        
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,        
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,        
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)            
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   ,   
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,  
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,  
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,  
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,  
           Amt        , ShowOrder ,        
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,'1'  
     FROM #TempInOut_Garbege AS A   
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc  

    GOTO Proc_Query  
RETURN 
/*********************************************************************************************************/  
AVG_Mat: --¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥_ÀÚÀç

--2011.05.25 ÁöÇØ
--ÀÚÀçÀÇ º¸Á¤ÀüÇ¥ÀÌ±â ¶§¹®¿¡ Àç·áºñ·Î ´ëÃ¼°¡ µÇ´Â °èÁ¤Àº Å¸°èÁ¤À» »ý¼ºÇÏÁö ¾Êµµ·Ï ÇÑ´Ù.
-- #ESMMatAcc »ç¿ë

--5535001 5535 ¿¬ÃÑÆò±Õ ¸ÅÃâ¿ø°¡Á¶Á¤  
--5535002 5535 ¿¬ÃÑÆò±Õ ÅõÀÔ±Ý¾×Á¶Á¤  
--5535003 5535 ¿¬ÃÑÆò±Õ ±âÅ¸Ãâ°í±Ý¾× Á¶Á¤  
    
 --   EXEC dbo._SCOMEnv @CompanySeq,5555 ,0  /*@UserSeq*/,@@PROCID,@IsDivideCCtrItem OUTPUT    
 --   EXEC dbo._SCOMEnv @CompanySeq,5551 ,0  /*@UserSeq*/,@@PROCID,@YAVGAdjTransType OUTPUT    
 ----@YAVGAdjTransType
 ----¿øÃµµ¥ÀÌÅÍº° º¸Á¤	5536001
 ----Ãâ°í±¸ºÐº° º¸Á¤		5536002

   ---#################[±âÅ¸ÀÔÃâ°íÀÇ ¿øÃµµ¥ÀÌÅÍº° º¸Á¤ÀÏ °æ¿ì ±âÅ¸Ãâ°í±¸ºÐº°·Î °¡´ÉÇÏ°Ô ¼öÁ¤ÇÔ] ###################################
   
    
    INSERT INTO #TempInOut_Garbege(      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind ,IsFromOtherAcc)      
    SELECT @SMSlipKind           ,      
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü      
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù      
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤      
           ISNULL(N.UMCostType, 0) , --Â÷º¯ºñ¿ë±¸ºÐ      
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤      
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ      
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×      
           1                    , --¼ø¼­  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³   
           --CASE WHEN ( @IsDivideCCtrItem = '0' /*AND ( A.InOutDetailKind <> 5535002 )*/ ) THEN 0 ELSE   A.GoodItemSeq   END     --ÅõÀÔÁ¦Ç°     
           CASE WHEN ( @IsDivideCCtrItem = '0'  --eykim. 110701. ÅõÀÔÀÏ °æ¿ì´Â ¿¬ÃÑº¸Á¤¿¡¼­ ¿øÃµ±¸ºÐº° º¸Á¤ÀÏ °æ¿ì´Â ¿ø°¡Ç×¸ñ¿¡ ÅõÀÔµÈ Á¦Ç°À» Á¶È¸½ÃÄÑ¾ß ÇÑ´Ù. 
					 AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 ) ) ) THEN 0 ELSE   A.GoodItemSeq   END ,    --ÅõÀÔÁ¦Ç°     
		   0 ,
           CASE WHEN  E.IsFromOtherAcc = '1' AND A.InOutDetailKind  IN ( 5535001)            AND M.AssetSeq IS NOT NULL 	THEN '1'
                WHEN  E.IsFromOtherAcc = '1' AND  A.InOutDetailKind IN ( 5535002 , 5535003)  AND O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 
        FROM _TESMGInOutStock             AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                         AND E.AssetSeq         = L.AssetSeq      
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAItemAssetAcc    AS N WITH(NOLOCK) ON E.CompanySeq       = N.CompanySeq      
                                                         AND E.AssetSeq         = N.AssetSeq      
                                                         AND (   (( A.InOutDetailKind = 5535002 )  
                                                                   AND  N.AssetAccKindSeq  = 22 --ÅõÀÔº¸Á¤°èÁ¤  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535001 )  
                                                                   AND  N.AssetAccKindSeq  = 23 --¸ÅÃâº¸Á¤°èÁ¤  
                                                                  )     
                                                              OR (( A.InOutDetailKind = 5535003 )  
                                                                   AND  N.AssetAccKindSeq  = 24 --±âÅ¸º¸Á¤°èÁ¤  
                                                                 )  
                                                             )     
               LEFT OUTER JOIN #AssetSeq    AS M WITH(NOLOCK) ON E.AssetSeq = M.AssetSeq 
               LEFT OUTER JOIN #ESMMatAcc   AS O ON  N.AccSeq = O.AccSeq  AND N.UMCostType = O.UMCostType
   WHERE A.CompanySeq = @CompanySeq           
     AND A.CostKeySeq = @CostKeySeq  
     AND A.InOutDate LIKE @CostYM + '%'     
     AND A.SMAdjustKind = 5513005 --ÀÚÀç±Ý¾×º¸Á¤_¿¬ÃÑÆò±Õ  
     AND F.MinorValue  = '1'      
     AND A.InOutKind = 8023003       --±âÅ¸Ãâ°í  
     AND F.MinorSeq  <> 6008005       
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536002  OR (@YAVGAdjTransType = 5536001 AND  A.InOutDetailKind <> 5535003))--¿øÃµ±¸ºÐº° º¸Á¤ÀÌ ¾Æ´Ò °æ¿ì ¸ÅÃâ±âÅ¸º¸Á¤ »ç¿ë

    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù      
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü      
           N.AccSeq             ,      
           N.UMCostType         ,    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE  A.CustSeq   END          ,   --¸ÅÃâ°Å·¡Ã³   
           CASE WHEN ( @IsDivideCCtrItem = '0' 
			    AND ( ( A.InOutDetailKind <> 5535002 ) OR ( A.InOutDetailKind = 5535002 AND @YAVGAdjTransType = 5536002 )  )) THEN 0 ELSE   A.GoodItemSeq   END     --ÅõÀÔÁ¦Ç°     
           ,CASE WHEN  E.IsFromOtherAcc = '1' AND A.InOutDetailKind IN( 5535001)            AND M.AssetSeq IS NOT NULL 	THEN '1'
                WHEN  E.IsFromOtherAcc = '1' AND  A.InOutDetailKind IN( 5535002 , 5535003) AND O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 
   ORDER BY A.InOutDetailKind , E.AssetSeq   


   
    INSERT INTO #TempInOut_Garbege(      
           SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
           DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,IsFromOtherAcc)      
    SELECT @SMSlipKind           ,      
           5535003               , --±âÅ¸Ãâ°íÀ¯Çü      
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü      
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù      
           ISNULL(j.ValueSeq, 0) , --Â÷º¯°èÁ¤      
           ISNULL(K.ValueSeq, 0) , --Â÷º¯ºñ¿ë±¸ºÐ      
           ISNULL(L.AccSeq, 0)   , --´ëº¯°èÁ¤      
           L.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ      
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×      
           1                    , --¼ø¼­  
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0)   END          ,      
           0         ,  
           0         ,
           A.InOutDetailKind AS UMRealDetilKind,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 			 
           
        FROM _TESMGInOutStock_YAVGAdj   AS A WITH(NOLOCK)      
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq      
                                                         AND A.ItemSeq    = D.ItemSeq      
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq      
                                                         AND D.AssetSeq   = E.AssetSeq       
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq      
                                                         AND E.SMAssetGrp = F.MinorSeq      
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq        = I.CompanySeq  --Áö¿ì¸®      
                                                         AND A.InOutDetailKind   = I.MinorSeq      
                                                         AND I.IsUse             ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28                                                            
               LEFT OUTER JOIN _TDAItemAssetAcc AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq      
                                                                 AND E.AssetSeq         = L.AssetSeq      
                                                                 AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤   
               LEFT OUTER JOIN _TDAUMinorValue  AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq      
                                                                 AND A.InOutDetailKind  = J.MinorSeq      
                                                                 AND J.ValueSeq         > 0      
                                                                 AND J.Serl             = '2003'      
               LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq      
                                                                 AND A.InOutDetailKind  = K.MinorSeq      
        AND K.Serl             = '2004'     
               LEFT OUTER JOIN #ESMMatAcc       AS O              ON j.ValueSeq         = O.AccSeq  
                                                                 AND K.ValueSeq         = O.UMCostType  
                                                                 
   WHERE A.CompanySeq  = @CompanySeq           
     AND A.AdjCostKeySeq    = @CostKeySeq  
     --AND A.InOutDate        LIKE @CostYM + '%'     
     --AND A.SMAdjustKind     = 5513005 --ÀÚÀç±Ý¾×º¸Á¤_¿¬ÃÑÆò±Õ  
     AND F.MinorValue       = '1'      --ÀÚÀç
     AND F.MinorSeq         <> 6008005       --Àç°øÇ°ÀÌ ¾Æ´Ñ°Í 
     AND A.InOutKind        = 8023003       --±âÅ¸Ãâ°í  
     AND ((@FGoodPriceUnit  = 5502003 AND A.BizUnit   = @CostUnit    )  
       OR (@FGoodPriceUnit  = 5502002 AND A.AccUnit   = @CostUnit    ))  
     AND (@YAVGAdjTransType = 5536001 ) --¿øÃµ±¸ºÐº°ÀÌ°í ±âÅ¸º¸Á¤ °èÁ¤ÀÏ °æ¿ì ¿øÃµº°·Î º¸Á¤ÇÔ
    
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù          
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü      
           ISNULL(j.ValueSeq, 0),      
           ISNULL(K.ValueSeq, 0),    
           L.AccSeq             ,    
           L.UMCostType         ,      
           CASE WHEN @IsDivideCCtrItem = '0' THEN 0 ELSE A.DeptSeq   END          ,      
           CASE WHEN @IsDivideCCtrItem = '0' AND A.InOutDetailKind <> 5535002 THEN 0 ELSE ISNULL(A.CCtrSeq , 0) END          ,      
            A.InOutDetailKind,
           CASE WHEN  E.IsFromOtherAcc = '1' AND  O.AccSeq IS NULL	THEN '1'
                ELSE '0'
           END 	          
   ORDER BY A.InOutDetailKind , E.AssetSeq   

   INSERT INTO #TempInOut(      
       SMSlipKind   ,INOutDetailKind,Remark      ,AssetSeq   , DrAccSeq  ,      
       DrUMCostType ,CrAccSeq       ,CrUMCostType,Amt        , ShowOrder ,      
       DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind,ISSUM)          
   SELECT SMSlipKind   ,INOutDetailKind,Remark      ,A.AssetSeq   , 
          CASE WHEN ISNULL(B.DrAccSeq    ,0) = 0 THEN A.DrAccSeq ELSE B.DrAccSeq END    ,
          CASE WHEN ISNULL(B.DrUMCostType,0) = 0 THEN A.DrUMCostType  ELSE B.DrUMCostType END  ,
          CASE WHEN ISNULL(B.CrAccSeq    ,0) = 0 THEN A.CrAccSeq     ELSE B.CrAccSeq END     ,
          CASE WHEN ISNULL(B.CrUMCostType,0) = 0 THEN A.CrUMCostType  ELSE B.CrUMCostType END  ,
           Amt        , ShowOrder ,      
           DeptSeq      ,CCtrSeq        ,CustSeq     ,GoodItemSeq, UMRealDetilKind, '1'
     FROM #TempInOut_Garbege AS A 
          LEFT OUTER JOIN #OtherAcc AS B ON A.AssetSeq = B.AssetSeq AND A.IsFromOtherAcc = B.isFromOtherAcc
          
   
   GOTO Proc_Query  
RETURN 
/*****************************************************************************************/
Proc_ItemAfterProd:	--5522015 ±âÅ¸ÀÔÃâ°íÀüÇ¥_Á¦Ç°(Ç°¸ñº°)


    --±âÅ¸ÀÔ°í    
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                        AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- °èÁ¤°ú¸ñ
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- ºñ¿ë±¸ºÐ
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤    


		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												      AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND ( E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL )
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq       , --´ëº¯°èÁ¤    
           L.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq    ,
           A.CustSeq 

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq,CustSeq )    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(L.AccSeq, 0)  , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(N.UMCostType, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
               JOIN _TDAUMinor     AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												         AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
     AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           L.AccSeq             , --´ëº¯°èÁ¤    
           L.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			,
		   A.DeptSeq            ,
		   A.ItemSeq            ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind, Remark    , AssetSeq  , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq   ,CustSeq)    
    SELECT @SMSlipKind          ,    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind          , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq           , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0)  , --´ëº¯°èÁ¤    
           N.UMCostType         , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(j.ValueSeq, 0), --Â÷º¯°èÁ¤    
           ISNULL(K.ValueSeq, 0), --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )          , --±âÅ¸Ãâ°í±Ý¾×    
           1                    , --¼ø¼­    
           A.DeptSeq            ,
           ISNULL(A.CCtrSeq , 0),
		   A.ItemSeq    ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock             AS A WITH(NOLOCK)     
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq
              JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
                                                         AND I.IsUse ='1' --»ç¿ë¿©ºÎÃ¼ Ã¼Å©µÈ°Í¸¸ °¡Á®¿Í¾ßÇÔ. eykim 10.04.28 
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                       AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '1001'    -- °èÁ¤°ú¸ñ
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '1002'    -- ºñ¿ë±¸ºÐ
		       LEFT OUTER JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8025			-- ±âÅ¸ÀÔ°í
												         AND M.Serl     = 2009	        -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND F.MinorSeq  <> 6008001    
     AND A.InOutKind IN (8023004)  --±âÅ¸ÀÔ°í 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
    AND E.IsToOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind,    
           N.AccSeq       , --´ëº¯°èÁ¤    
           N.UMCostType           , --´ëº¯ºñ¿ë±¸ºÐ    
           j.ValueSeq            , --Â÷º¯°èÁ¤    
           K.ValueSeq            , --Â÷º¯ºñ¿ë±¸ºÐ  
           A.CCtrSeq			 ,
		   A.DeptSeq   ,
		   A.ItemSeq  ,
           A.CustSeq   

    --±âÅ¸Ãâ°í(Á¦Á¶°èÁ¤ Á¦¿Ü)
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq           ,  
           ISNULL(A.CustSeq     , 0)       
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                     AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- ±âÅ¸Ãâ°í
												      AND M.Serl     = 1005		    -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
     
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND (E.IsFromOtherAcc = '0' OR E.IsFromOtherAcc IS NULL)
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq     ,
           A.CustSeq

    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(N.AccSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(N.UMCostType, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(L.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           L.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq     ,  
           ISNULL(A.CustSeq     , 0)             
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAItemAssetAcc    AS L WITH(NOLOCK) ON E.CompanySeq       = L.CompanySeq    
                                                         AND E.AssetSeq         = L.AssetSeq    
                                                         AND L.AssetAccKindSeq  = 1 --ÀÚ»êÃ³¸®°èÁ¤ 

		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                         AND M.MajorSeq = 8026			-- ±âÅ¸Ãâ°í
												         AND M.Serl     = 1005		    -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													     AND A.InOutDetailKind = M.minorseq 
													     AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq      
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           N.AccSeq          , --´ëº¯°èÁ¤    
           N.UMCostType          , --´ëº¯ºñ¿ë±¸ºÐ    
           L.AccSeq             , --Â÷º¯°èÁ¤    
           L.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq   ,
           A.CustSeq
		   
    INSERT INTO #TempInOut(    
           SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
           DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
           DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq)    
    SELECT @SMSlipKind           ,    
           A.InOutDetailKind     , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           E.AssetSeq            , --Àç°íÀÚ»êºÐ·ù    
           ISNULL(j.ValueSeq, 0) , --´ëº¯°èÁ¤    
           ISNULL(K.ValueSeq, 0) , --´ëº¯ºñ¿ë±¸ºÐ    
           ISNULL(N.AccSeq, 0)   , --Â÷º¯°èÁ¤    
           N.UMCostType          , --Â÷º¯ºñ¿ë±¸ºÐ    
           SUM(A.Amt )           , --±âÅ¸Ãâ°í±Ý¾×    
           5                     , --¼ø¼­
           A.DeptSeq             ,    
           ISNULL(A.CCtrSeq , 0) ,
		   A.ItemSeq        ,  
           ISNULL(A.CustSeq     , 0)  
      FROM _TESMGInOutStock              AS A WITH(NOLOCK)    
               JOIN _TDAItem            AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq    
                                                         AND A.ItemSeq    = D.ItemSeq    
               JOIN _TDAItemAsset       AS E WITH(NOLOCK) ON D.CompanySeq = E.CompanySeq    
                                                         AND D.AssetSeq   = E.AssetSeq     
               JOIN _TDASMInor          AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq    
                                                         AND E.SMAssetGrp = F.MinorSeq    
               JOIN _TDAUMinor          AS I WITH(NOLOCK) ON A.CompanySeq       = I.CompanySeq  --Áö¿ì¸®    
                                                         AND A.InOutDetailKind  = I.MinorSeq    
               LEFT OUTER JOIN _TDAUMinorValue     AS J WITH(NOLOCK) ON A.CompanySeq       = J.CompanySeq    
                                                         AND A.InOutDetailKind  = J.MinorSeq    
                                                         AND J.ValueSeq         > 0    
                                                         AND J.Serl             = '2003'    
               LEFT OUTER JOIN _TDAUMinorValue     AS K WITH(NOLOCK) ON A.CompanySeq       = K.CompanySeq    
                                                         AND A.InOutDetailKind  = K.MinorSeq    
                                                         AND K.Serl             = '2004'    
		       JOIN _TDAUMinorValue AS M WITH (NOLOCK) ON A.CompanySeq = M.CompanySeq 
                                                      AND M.MajorSeq = 8026			-- ±âÅ¸Ãâ°í
												      AND M.Serl     = 1005		    -- Ç°¸ñº°ÀüÇ¥Ã³¸®¿©ºÎ
													  AND A.InOutDetailKind = M.minorseq 
													  AND M.ValueText = 1
               LEFT OUTER JOIN _TDAItemAssetAcc AS N WITH(NOLOCK) ON D.AssetSeq  = N.AssetSeq  AND N.Companyseq = @CompanySeq     
                                                         AND N.AssetAccKindSeq = 21 -- Å¸°èÁ¤À¸·Î´ëÃ¼  
   WHERE A.CompanySeq = @CompanySeq         
     AND A.CostKeySeq = @CostKeySeq
     AND A.InOutDate LIKE @CostYM + '%'    
     AND F.MinorValue  = '0'    
     AND A.InOutKind = 8023003    --±âÅ¸Ãâ°í
     AND F.MinorSeq <> 6008001 
      AND ((@FGoodPriceUnit = 5502003 AND A.BizUnit   = @CostUnit    )
           OR (@FGoodPriceUnit = 5502002 AND A.AccUnit   = @CostUnit    ))
     AND E.IsFromOtherAcc = '1'
    GROUP BY E.AssetSeq         , --Àç°íÀÚ»êºÐ·ù    
           A.InOutDetailKind    , --±âÅ¸Ãâ°íÀ¯Çü    
           A.InOutKind           , --ÀÔÃâ°íÀ¯Çü    
           j.ValueSeq          , --´ëº¯°èÁ¤    
           K.ValueSeq          , --´ëº¯ºñ¿ë±¸ºÐ    
           N.AccSeq             , --Â÷º¯°èÁ¤    
           N.UMCostType         ,    
           A.DeptSeq            ,    
           A.CCtrSeq  ,
		   A.ItemSeq  ,
           A.CustSeq  
    GOTO Proc_Query
RETURN 
/******************************************************************************************************/
Proc_Query: --Á¶È¸

    IF EXISTS (SELECT 1 FROM KPX_TESMCProdSlipM  A   
                WHERE A.CompanySeq     = @CompanySeq    
                  AND A.CostUnit       = @CostUnit    
                  AND A.CostKeySeq     = @CostKeySeq
                  AND A.SMSlipKind     = @SMSlipKind     
                  AND A.SlipSeq        > 0
				)
    BEGIN 
		  
           SELECT  B.TransSeq      ,
                    B.TransSerl     ,
                    B.Remark        ,
                    ISNULL(B.InOutDetailKind   , 0)  AS InOutDetailKind,
--                    ISNULL(I.MinorName , 0) AS InOutDetailKindName,
                     CASE WHEN I.MinorName IS NULL THEN 
                         CASE WHEN L.MinorName IS NULL THEN '' ELSE '¡Ø'+L.MinorName END --2011.02.17 ÁöÇØ :º¸Á¤µ¥ÀÌÅÍ Ç¥½Ã (ÀÔÃâ°í±¸ºÐ¿¡.)
                         ELSE ISNULL(I.MinorName,'')
                     END AS InOutDetailKindName,
                    B.CCtrSeq       ,
                    ISNULL(H.CCtrName, '')  AS CCtrName    ,
                    B.DeptSeq       ,
                    E.DeptName      ,
                    B.CrAccSeq   ,
                    ISNULL(G.AccName , '') AS CrAccName,
                    B.DrAccSeq     ,
                    ISNULL(D.AccName , '') AS DrAccName  ,
                    B.CrAmt      ,
                    B.DrAmt        ,
                    B.AssetSeq      ,
                    ISNULL(C.AssetName  , '') AS AssetName  ,
                    B.IsVat                     ,
                    B.CrUMCostType              , 
                    B.DrUMCostType              ,
                    ISNULL(J.MinorName , '') AS CrUMCostTypeName,
                    ISNULL(K.MinorName , '') AS DrUMCostTypeName,
                    N.CustSeq           AS CustSeq,
                    N.CustName          AS CustName,
                    B.GoodItemSeq       AS GoodItemSeq,
                    M2.ItemName         AS GoodItemName,
					M.ItemName, M.ItemNo, M.Spec,
					ISNULL(O.MinorName,'')         AS UMRealDetilKindName,
					ISNULL(B.UMRealDetilKind ,0)   AS UMRealDetilKind
             FROM  KPX_TESMCProdSlipM                 AS A WITH(NOLOCK)
                              JOIN KPX_TESMCProdSlipD AS b WITH(NOLOCK) ON a.CompanySeq = b.CompanySeq AND a.TransSeq   = b.TransSeq       
                   LEFT OUTER JOIN _TDAAccount     AS g WITH(NOLOCK) ON b.CrAccSeq   = g.AccSeq     AND a.CompanySeq = G.CompanySeq          
                   LEFT OUTER JOIN _TDAItemAsset   AS c WITH(NOLOCK) ON b.AssetSeq   = c.AssetSeq   AND B.CompanySeq = C.CompanySeq                           
                   LEFT OUTER JOIN _TDAAccount     AS d WITH(NOLOCK) ON b.DrAccSeq   = d.AccSeq     AND a.CompanySeq = D.CompanySeq              
                   LEFT OUTER JOIN _TDADept        AS e WITH(NOLOCK) ON B.DeptSeq    = E.DeptSeq    AND B.CompanySeq = E.CompanySeq            
                   LEFT OUTER JOIN _TDACCtr AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq AND B.CCtrSeq    = H.CCtrSeq
                   LEFT OUTER JOIN _TDAUMinor      AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq AND B.InOutDetailKind = I.MInorSeq
                   LEFT OUTER JOIN _TDAUMinor      AS J WITH(NOLOCK) ON B.CompanySeq = J.CompanySeq AND B.CrUMCostType = J.MInorSeq
                   LEFT OUTER JOIN _TDAUMinor      AS K WITH(NOLOCK) ON B.CompanySeq = K.CompanySeq AND B.DrUMCostType = K.MInorSeq

			       LEFT OUTER JOIN _TDAItem        AS M WITH (NOLOCK) ON B.CompanySeq = M.CompanySeq 
																	 AND B.ItemSeq    = M.ItemSeq
                   LEFT OUTER JOIN _TDASMInor   AS L WITH(NOLOCK) ON @CompanySeq    = L.CompanySeq AND B.INOutDetailKind     = L.MinorSeq AND L.MajorSeq IN (5513,5535)
                   LEFT OUTER JOIN _TDACust        AS N WITH(NOLOCK) ON @CompanySeq    = N.CompanySeq AND B.CustSeq         = N.CustSeq  
                   LEFT OUTER JOIN _TDAUMInor   AS O WITH(NOLOCK) ON @CompanySeq    = O.CompanySeq AND B.UMRealDetilKind     = O.MinorSeq 
				   LEFT OUTER JOIN _TDAItem		AS M2 WITH(NOLOCK) ON B.CompanySeq = M2.CompanySeq AND B.GoodItemSeq = M2.ItemSeq

                   
           WHERE A.CompanySeq     = @CompanySeq    
              AND A.CostUnit       = @CostUnit    
              AND A.CostKeySeq     = @CostKeySeq
              AND A.SMSlipKind     = @SMSlipKind 
             ORDER BY B.TransSerl



    END 
    ELSE 
    BEGIN 



    --±âÅ¸ÀÔÃâ°íÀüÇ¥Ã³¸®½ÃÁý°è±¸ºÐ¼±ÅÃ(ºÎ¼­/°Å·¡Ã³)
    DECLARE	@EtcGroupType  INT 

    EXEC dbo._SCOMEnv @CompanySeq, 5910,@UserSeq,@@PROCID,@EtcGroupType OUTPUT   --ÀÚÀç´Ü°¡°è»ê´ÜÀ§ 


    IF @SMSlipKind NOT IN (5522012,5522013,5522014) --¿¬ÃÑÆò±Õ º¸Á¤ÀüÇ¥°¡ ¾Æ´Ò¶§ 
    BEGIN 
	  
      IF @EtcGroupType =  5544001 --ºÎ¼­·Î Áý°è
		
        INSERT INTO #TempInOut(    
               SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq,IsSum , UMRealDetilKind)    
        SELECT  SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,SUM(Amt)        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,0,'1',UMRealDetilKind
          FROM #TempInOut
        GROUP BY SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq,UMRealDetilKind


      ELSE  --°Å·¡Ã³·Î Áý°è
        INSERT INTO #TempInOut(    
               SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,Amt        , ShowOrder ,    
               DeptSeq      ,CCtrSeq, GoodItemSeq ,CustSeq,IsSum,UMRealDetilKind)    
        SELECT  SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,SUM(Amt)        , ShowOrder ,    
               0      ,CCtrSeq, GoodItemSeq, CustSeq,'1',UMRealDetilKind
          FROM #TempInOut
        GROUP BY SMSlipKind   ,INOutDetailKind,Remark     ,AssetSeq   , DrAccSeq,    
               DrUMCostType,CrAccSeq    ,CrUMCostType,ShowOrder ,    
               CCtrSeq, CustSeq, GoodItemSeq,UMRealDetilKind


        DELETE #TempInOut WHERE IsSum IS NULL 
    END 
			

            SELECT  A.SMSlipKind        AS SMSlipKind,    
                    A.InOutDetailKind   AS InOutDetailKind, 
--           CASE WHEN A.InOutDetailKind = 5535002 THEN 'ÅõÀÔ±Ý¾×º¸Á¤'
--                WHEN A.InOutDetailKind = 5535001 THEN '¸ÅÃâ¿ø°¡º¸Á¤'  
--                WHEN A.InOutDetailKind = 5535003 THEN '±âÅ¸Ãâ°íº¸Á¤'  
--                ELSE  B.MinorName        END  AS InOutDetailKindName ,    
                     CASE WHEN B.MinorName IS NULL THEN 
                         CASE WHEN M.MinorName IS NULL THEN '' ELSE '¡Ø'+M.MinorName END --2011.02.17 ÁöÇØ :º¸Á¤µ¥ÀÌÅÍ Ç¥½Ã (ÀÔÃâ°í±¸ºÐ¿¡.)
              ELSE ISNULL(B.MinorName,'')
                     END AS InOutDetailKindName,
                    A.AssetSeq          AS AssetSeq,    
                    F.AssetName         AS AssetName ,    
                    A.DrAccSeq          AS DrAccSeq,    
                    D.AccName           AS DrAccName,    
                    A.DrUMCostType      AS DrUMCostType,    
                    E.MinorName         AS DrUMCostTypeName,     
                    A.CrAccSeq          AS CrAccSeq ,    
                    G.AccName           AS CrAccName  ,    
                    A.CrUMCostType      AS CrUMCostType,    
                    H.MinorName         AS CrUMCostTypeName ,    
                    A.Amt               AS DrAmt      ,     
                    A.Amt               AS CrAmt      ,     
                    A.ShowOrder         AS ShowOrder,    
                    CASE WHEN ISNULL(A.DeptSeq,0) = 0 THEN 8  ELSE A.DeptSeq END   AS DeptSeq      ,    
                    CASE WHEN ISNULL(A.CCtrSeq,0) = 0 THEN 22 ELSE A.CCtrSeq END   AS CCtrSeq,    
                    C.MinorName         AS Remark,    
                    I.DeptName          AS DeptName,    
                    J.CCtrName          AS CCtrName,
                    A.CustSeq           AS CustSeq,
                    K.CustName          AS CustName,
                    A.GoodItemSeq       AS GoodItemSeq,
                    L.ItemName          AS GoodItemName,
			        L.ItemNO			AS GoodItemNo,
					L.Spec				AS Spec,
					ISNULL(N.MinorName,'')         AS UMRealDetilKindName,
					ISNULL(A.UMRealDetilKind ,0)   AS UMRealDetilKind
              FROM #TempInOut AS A     
                   LEFT OUTER JOIN _TDAUMinor   AS B WITH(NOLOCK) ON @CompanySeq    = B.CompanySeq AND A.INOutDetailKind = B.MinorSeq 
                   LEFT OUTER JOIN _TDASMInor   AS C WITH(NOLOCK) ON @CompanySeq    = C.CompanySeq AND A.Remark          = C.MinorSeq    
                   LEFT OUTER JOIN _TDAAccount  AS D WITH(NOLOCK) ON @CompanySeq    = D.CompanySeq AND A.DrAccSeq        = D.AccSeq    
                   LEFT OUTER JOIN _TDAUMinor   AS E WITH(NOLOCK) ON @CompanySeq    = E.CompanySeq AND A.DrUMCostType    = E.MInorSeq    
                   LEFT OUTER JOIN _TDAItemAsset AS F WITH(NOLOCK) ON @CompanySeq   = F.CompanySeq AND A.AssetSeq        = F.AssetSeq    
                   LEFT OUTER JOIN _TDAAccount  AS G WITH(NOLOCK) ON @CompanySeq    = G.CompanySeq AND A.CrAccSeq        = G.AccSeq    
                   LEFT OUTER JOIN _TDAUMinor   AS H WITH(NOLOCK) ON @CompanySeq    = H.CompanySeq AND A.CrUMCostType    = H.MinorSeq    
                   LEFT OUTER JOIN _TDADept     AS I WITH(NOLOCK) ON @CompanySeq    = I.CompanySeq AND CASE WHEN ISNULL(A.DeptSeq,0) = 0 THEN 8  ELSE A.DeptSeq END        = I.DeptSeq    
                   LEFT OUTER JOIN _TDACCtr     AS J WITH(NOLOCK) ON @CompanySeq    = J.CompanySeq AND CASE WHEN ISNULL(A.CCtrSeq,0) = 0 THEN 22 ELSE A.CCtrSeq END        = J.CCtrSeq  
                   LEFT OUTER JOIN _TDACust     AS K WITH(NOLOCK) ON @CompanySeq    = K.CompanySeq AND A.CustSeq         = K.CustSeq  
                   LEFT OUTER JOIN _TDAItem     AS L WITH(NOLOCK) ON @CompanySeq    = L.CompanySeq AND A.GoodItemSeq     = L.ItemSeq 
                   LEFT OUTER JOIN _TDASMInor   AS M WITH(NOLOCK) ON @CompanySeq    = M.CompanySeq AND A.INOutDetailKind     = M.MinorSeq AND M.MajorSeq IN (5513,5535)
                   LEFT OUTER JOIN _TDAUMInor   AS N WITH(NOLOCK) ON @CompanySeq    = N.CompanySeq AND A.UMRealDetilKind     = N.MinorSeq 
			
            ORDER BY A.ShowOrder , InOutDetailKindName , A.AssetSeq  


    END 

  
RETURN


GO


