IF OBJECT_ID('hye_SPUDelvGetPrice') IS NOT NULL 
    DROP PROC hye_SPUDelvGetPrice
GO 

-- v2016.12.19 

-- 구매단가 가져오기(구매단가등록_hye 적용) by이재천 
/**********************************************************************************************
    코드헬프시 품목별 구매정보 가져오기
    작성자     - 노영진
    수정자     - 김현
    수정일     - 2010. 6. 21 -- 커서 없애고 업데이트 방식으로 수정  
    수정내역   - 2011. 3. 18 -- hkim ( 최근구매거래처를 가져올 때 통화가 자국 통화만 걸리던 부분을 수정해서 적용)  
               - 2011. 6. 20 -- 김서진(창고가져오는 우선순위 로직변경 - 1순위 의뢰부서별 소분류별 구매기본창고 추가)  
               - 2011. 7. 15 -- 김세호(구매반품입력화면에서 통제값(6518반품기본단가 설정기준) 에따라 단가 세팅로직 추가 )  
               - 2012.01. 02 -- 김세호(구매발주에서 납품창고가져올때- 품목별기본창고 가져오는 로직 수정
                                      ::로그인유저 사업부문의 창고를 가져오고 없으면 사업부문0으로 걸려있는 창고 가져오도록, 중복으로있을경우 창고가져오지않음)  
               - 2014.06.25  -- 김용현 구매품의 시트에서 해당 품목의 구매단가등록에 등록된 데이터가 없다면, 거래처를 빈 값으로 끌고오는데,
                                       자재등록의 구매정보 탭의 기본구매처를 끌고 오도록 수정
               - 2014.06.30  -- 임희진 ( 대표단가여부에 체크가 되어 있고 같은 품목과 거래처로 등록된 내용이 있으면서 PreLeadTime + LeadTime + PostLeadTime 값이 있을경우 조달일수에 표시 )                                                                        
               - 2015.04.03  -- 김준모 ( 구매요청에서 품의Jump시 직수입인 경우는 요청의 통화를 끌고 오도록 추가되어 있는 부분때문에 대표단가의 통화를 끌고오지 못하고 있었음
                                         이 부분을 직수입인 경우 요청의 통화가 자국통화가 아닌 경우 업데이트 하도록 수정) 
               - 2015.04.10  -- 임희진 (구매품의에서 구매거래처를 다시 셋팅 시 직수입일 경우 통화가 업데이트 되어 해당구문을 주석처리 하려 했으나, 
                                        이전에 추가된 이유를 알 수 없어 거래처가 0 일 경우의 조건 추가) - 프로텍  201504090167 
               - 2015.08.31  -- 임희진 (상기 로직이 추가된 if문에 구매단가등록 데이터가 존재하지 않을 때 해당 구문 실행하도록 조건 추가
                                        -> _SPUBaseGetPriceSub에서 구매단가등록의 통화가 UPDATE 되었음에도 불구하고 상기 로직이 또 적용되고 있었음) - 티씨케이 201508270042                                                                    
               - 2015.10.08  -- 박수영 (최초 Temp테이블 내 창고내부코드 넣어주고 로직 시작하도록 수정 - KPX그린케미칼
               - 2015.10.21  -- 박수영 (동일 품목에 대하여 다른 사업부문에서 납품처리 후 창고가져오기 로직에 의한 창고 가져올 때, 사업부문까지 걸어 가져올 수 있도록 수정 -송원
               - 2016.05.10  -- 박수영 (내외자구분 가져올 때, 화면에서 수집한 정보가 있다면, 품목마스터까지 내외자구분 값이 없을 경우, 화면에서 수집한 정보로 세팅)
			   - 2016.11.10  -- 임희진 (Maker정보 가져오는 우선 순위 적용
			                           1. 화면상에서 들어온 값 / 2. 구매단가등록(해당 품목,거래처,통화가 일치하는 Maker정보) / 3. 자재등록-구매정보-Maker)
***********************************************************************************************/
CREATE PROC dbo.hye_SPUDelvGetPrice 
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= 0,         
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0
AS
    SET NOCOUNT ON

    
    DECLARE @docHandle      INT,        
            @PUType         NVARCHAR(200),        
            @GetPriceType   INT,        
            @BizUnit        INT,       
            @pDate          NCHAR(8) ,          
            @xKorCurrSeq    INT,      
            @xForCurrSeq    INT,      
            @MaxRow         INT,      
            @Count          INT,      
            @wItemSeq       INT,      
            @wCustSeq2      INT,  
            @CurrSeq        INT,         -- 2011. 3. 18 hkim (최근거래처 가져올 때 통화도 걸어주기 위함)  
            @WHSeq   INT,  
            @GetReturnPriceType INT,      -- 2011. 7. 15 김세호 (구매반품입력화면에서 단가가져오는 통제값)   
            @CostEnv        INT,            -- 사용원가 환경설정            -- 11.07.15 김세호 추가 (전월 재고단가 가져오기위함)  
            @IFRSEnv        INT,            -- IFRS 사용 여부 환경설정      -- 11.07.15 김세호 추가 (전월 재고단가 가져오기위함)  
            @SMCostMng      INT,  
            @MatPriceEnv    INT,            -- 자재단가계산단위             -- 11.07.15 김세호 추가 (전월 재고단가 가져오기위함)  
            @GoodsPriceEnv  INT             -- 상품단가계산단위             -- 11.07.15 김세호 추가 (전월 재고단가 가져오기위함)  
   
  
    -- 서비스 마스타 등록 생성(구매품의 일괄생성일 경우에는 임시테이블 생성 X        
    IF @WorkingTag <> 'AUTO'        
    BEGIN        
        CREATE TABLE #TPUBaseGetPrice (WorkingTag NCHAR(1) NULL)        
        EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUBaseGetPrice'    
    END  
    IF @@ERROR <> 0 RETURN        
    
    
    --select * from #TPUBaseGetPrice 
    --return 
    CREATE TABLE #TPUSheetData       
    (      
        IDX_NO    INT    ,   
        ComPanySeq INT,     
        ItemSeq   INT    ,      
        AssetSeq  INT    ,      
        CustSeq   INT    ,      
        MakerSeq  INT    ,      
        CurrSeq   INT    ,      
        STDUnitSeq  INT    ,      
        ImpType   INT    NULL,      
        Price   DECIMAL(19,5) ,      
        StdUnitQty  DECIMAL(19,5) ,      
        MinQty   DECIMAL(19,5) ,      
        StepQty   DECIMAL(19,5) ,      
        QCType   INT    ,      
        PUStatus  NVARCHAR(10) NULL,      
        PUResults  NVARCHAR(100) NULL,      
        WHSeq   INT    NULL,      
        HSNo   NVARCHAR(40) NULL,      
        ExRate   DECIMAL(19,5) ,      
        LeadTime  DECIMAL(19,5),  
        DeptSeq   INT  ,
        UnitSeq     INT,
        GetImpType  INT,         --2016.05.10 박수영 ::화면에서 받은 내외자구분값 (기존 ImpType 을 쓰면 아래 로직을 제대로 타지 못함)
        UMDVGroupSeq    INT
    )     
   
     
    -- 구매단가 등록 화면에서 호출시        
    IF EXISTS (SELECT 1 FROM #TPUBaseGetPrice WHERE PUType = 'PUBasePrice')        
        GOTO PUBasePrice_Proc   
              
    SELECT @PUType = (SELECT TOP 1 PUType FROM #TPUBaseGetPrice)        
                   
    -- 통제값 가져오기(최근 구매단가 사용 여부)        
    EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@GetPriceType OUTPUT    
    
    
     
    -- 통화 가져오기        
    EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT        
    EXEC dbo._SCOMEnv @CompanySeq,12,@UserSeq,@@PROCID,@xForCurrSeq OUTPUT        

    -- 일자 가져오기
    SELECT @pDate = ISNULL(DATE, CONVERT(NCHAR(8),GETDATE(),112)) FROM #TPUBaseGetPrice        

    -- 사업부분 가져오기
    SELECT @BizUnit = ISNULL(BizUnit, 0) FROM #TPUBaseGetPrice   

    INSERT INTO #TPUSheetData(IDX_NO, CompanySeq,ItemSeq , MakerSeq , STDUnitSeq , AssetSeq , LeadTime ,      
                              CustSeq , QCType , ExRate  , StdUnitQty, CurrSeq ,      
                              MinQty , StepQty , Price , DeptSeq, UnitSeq, WHSeq, GetImpType, UMDVGroupSeq)      
    SELECT A.IDX_NO, @CompanySeq, A.ItemSeq , ISNULL(A.MakerSeq,0) , ISNULL(D.STDUnitSeq, 0) , B.AssetSeq , 
           CASE WHEN ISNULL(E.PreLeadTime,0)+ISNULL(E.LeadTime,0)+ISNULL(E.PostLeadTime,0) = 0 THEN ISNULL(C.DelvDay,0)
           ELSE ISNULL(E.PreLeadTime,0)+ISNULL(E.LeadTime,0)+ISNULL(E.PostLeadTime,0) END AS LeadTime ,         --조달 일수 수정 2014.06.30 임희진  
           ISNULL(A.CustSeq, 0), 6035001, A.ExRate, ISNULL(A.StdUnitQty, 1), ISNULL(A.CurrSeq, 0),      
           ISNULL(C.MinQty, 1)  , ISNULL(C.StepQty, 1), 0 , A.DeptSeq    , A.UnitSeq , A.WHSeq, ISNULL(A.SMImpType,0), CONVERT(INT,A.Memo2)
      FROM #TPUBaseGetPrice                 AS A
           JOIN _TDAItem                    AS B ON A.ItemSeq   = B.ItemSeq
           LEFT OUTER JOIN _TDAItemPurchase AS C ON B.CompanySeq  = C.ComPanySeq    
                                                AND B.ItemSeq   = C.ItemSeq
           LEFT OUTER JOIN _TDAItemDefUnit  AS D ON B.CompanySeq  = D.ComPanySeq
                                                AND B.ItemSeq   = D.ItemSeq
                                                AND D.UMModuleSeq = '1003001'
           LEFT OUTER JOIN _TPUBASEBuyPriceItem  AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq
                                                                  AND A.ItemSeq    = E.ItemSeq      /** 대표단가여부에 체크가 되어 있고 **/
                                                                  AND E.IsPrice    = '1'            /** PreLeadTime + LeadTime + PostLeadTime 값이 있을경우
                                                                                                        조달일수에 표시 2014.06.30 임희진 추가**/
     WHERE B.CompanySeq = @CompanySeq
    ORDER BY A.IDX_NO

    -- 구매품의에서 단가등록 안된건들은 그냥 입력 값 보여주도록 추가 2011. 1. 10 hkim  
    IF @GetPriceType = '6072001' AND @PUType = 'PUORDApprovalReq' AND NOT EXISTS (SELECT 1 FROM #TPUBaseGetPrice          AS A   
                                                          JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq  
                                                   WHERE  B.CompanySeq = @CompanySeq   
                                                     AND  @pDate BETWEEN B.StartDate AND B.EndDate)  
    BEGIN   
        -- 구매단가등록이 되어 있지 않을 때 내외자구분 가져오지 못해서 추가 2011. 4. 8 hkim  
        UPDATE #TPUBaseGetPrice      
           SET SMImpType = CASE ISNULL(SMInOutKind, 0) WHEN 8007001 THEN 8008001 WHEN 0 THEN 8008001 ELSE 8008004 END         
          FROM #TPUBaseGetPrice AS A      
               JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq        
         WHERE B.CompanySeq = @CompanySeq      
           AND A.SMImpType IS NULL OR A.SMImpType = 0          
        
        UPDATE #TPUBaseGetPrice
           SET CurrSeq = B.CurrSeq
          FROM #TPUBaseGetPrice AS A
               JOIN _TDACurr    AS B ON B.CompanySeq = @CompanySeq
                                    AND B.CurrName   = 'USD'    -- 2014.06.25 김용현 셋팅 내외자구분이 외자 인경우에 
                                                                -- Default 값으로 USD 통화로 뿌려지도록 CurrSeq 업데이트 작업
         WHERE A.SMImpType = 8008004
        
        -- 통화가 0인 건은 기본 통화  
        UPDATE #TPUBaseGetPrice  
          SET CurrSeq  = @xKorCurrSeq   ,  
              CurrName = (SELECT TOP 1 CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = @xKorCurrSeq )  
         WHERE CurrSeq = 0 OR CurrSeq IS NULL  
            -- 환율이 0인 건은 기본 통화  
         UPDATE #TPUBaseGetPrice  
           SET ExRate = 1  
         WHERE ExRate = 0 OR ExRate IS NULL  
        
        
        -- 거래처가 구매단가등록에 등록 되어 있지 않은 경우에 자재등록 - 구매정보 탭의 기본구매처로 가져오도록 수정 2014.06.25 김용현
        UPDATE #TPUBaseGetPrice
           SET CustSeq = ISNULL(B.PurCustSeq,0)
          FROM #TPUBaseGetPrice AS A
               JOIN _TDAItemPurchase AS B ON A.ItemSeq = B.ItemSeq
         WHERE B.CompanySeq = @CompanySeq                                         
           AND A.CustSeq    = 0   
                 
                   
            /**품목을 여러건을 한번에 처리하기 위해 바로 Return 하는 부분 주석처리 2012.06.19 by 허승남 **/    
            --SELECT  * FROM #TPUBaseGetPrice  
            --RETURN  
    END                                                           
                                 
 -- 코드헬프 후 데이터 가져올 품목이 없으면 중단   
 IF NOT EXISTS (SELECT 1 FROM #TPUSheetData)  
 BEGIN  
  SELECT * FROM #TPUSheetData  
  RETURN        
 END  
  



  
    IF @GetPriceType = '6072001' OR  @PUType = 'PUReturn'  -- 최근구매단가 사용 안할 경우 거래처 가져오기      
    BEGIN      
        IF @PUType IN ('ImportBargain', 'LCAdd', 'PUORDPO', 'Delivery', 'PUORDApprovalReq', 'PUReturn')      
        BEGIN      
            UPDATE #TPUSheetData      
               SET CustSeq = ISNULL(B.CustSeq, 0)      
              FROM #TPUSheetData    AS A      
                   JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq      
               AND @pDate BETWEEN B.StartDate AND B.EndDate      
               AND B.IsPrice = '1'       
               AND A.CustSeq = 0      
                  
            UPDATE #TPUSheetData      
               SET CustSeq = ISNULL(B.CustSeq, 0)      
              FROM #TPUSheetData    AS A      
                   JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq      
               AND @pDate BETWEEN B.StartDate AND B.EndDate      
               AND A.CustSeq = 0            
        END      
    END      
    ELSE IF @GetPriceType = '6072002'  -- 최근단가(발주) 사용시 거래처 가져오기      
    BEGIN      
        IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE CustSeq = 0) AND @PUType IN ('PUORDApprovalReq')      
        BEGIN      
            SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData      
            SELECT @Count  = 0      
              
            WHILE( 1 = 1 )      
            BEGIN      
                IF @Count > @MaxRow BREAK      
              
                IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE IDX_NO = @Count AND CustSeq = 0)       
                BEGIN       
                    SELECT @wItemSeq = ItemSeq FROM #TPUSheetData WHERE IDX_NO = @Count      
                    SELECT @CurrSeq  = CurrSeq FROM #TPUSheetData WHERE IDX_NO = @Count       -- 2011. 3. 18 hkim 통화 걸어서 거래처 가져오도록   
           
                    SELECT @wCustSeq2 = ISNULL(B.CustSeq, 0)        
                      FROM _TPUORDPOItem  AS A        
                           JOIN _TPUORDPO AS B ON A.CompanySeq = B.CompanySeq        
                                              AND A.POSeq      = B.POSeq        
                     WHERE A.CompanySeq = @CompanySeq        
                       AND A.ItemSeq    = @wItemSeq        
                       AND B.CurrSeq    = @CurrSeq        
                       AND A.POSeq      = ( SELECT TOP 1 ISNULL(B.POSeq, 0) FROM _TPUORDPOItem  AS A        
                                                                                 JOIN _TPUORDPO AS B ON A.CompanySeq = B.CompanySeq        
                                                                                                    AND A.POSeq      = B.POSeq        
                                                                           WHERE A.CompanySeq = @CompanySeq        
                                                                             AND A.ItemSeq    = @wItemSeq        
                                                                             AND B.CurrSeq    = @CurrSeq        
                                                                             AND B.PONo       = (SELECT TOP 1 ISNULL(MAX(B.PONo), '0') FROM _TPUORDPOItem  AS A        
                                                                                                                                            JOIN _TPUORDPO AS B ON A.CompanySeq  = B.CompanySeq        
                                                                                                                                                               AND A.POSeq     = B.POSeq        
                                                                                                                                      WHERE A.CompanySeq = @CompanySeq        
                                                                                                                                        AND @wItemSeq IN (A.ItemSeq)        
                                                                                                                                        AND B.CurrSeq    = @CurrSeq) )       
                    UPDATE #TPUSheetData                                                                                                         
                       SET CustSeq = @wCustSeq2      
                      FROM #TPUSheetData      
                     WHERE IDX_NO = @Count    
                END      
              
            SELECT @Count = @Count + 1                   
            SELECT @wCustSeq2 = 0           -- 0 으로 초기화   
              
            END      
        END    
    END    
    ELSE IF @GetPriceType = '6072003'  -- 최근단가(납품) 사용시 거래처 가져오기      
    BEGIN      
        IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE CustSeq = 0) AND @PUType IN ('PUORDApprovalReq')      
        BEGIN      
            SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData      
            SELECT @Count  = 0      
            WHILE( 1 = 1 )      
            BEGIN      
                IF @Count > @MaxRow BREAK      
          
                IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE IDX_NO = @Count AND CustSeq = 0)       
                BEGIN       
                    SELECT @wItemSeq = ItemSeq FROM #TPUSheetData WHERE IDX_NO = @Count      
                    SELECT @CurrSeq  = CurrSeq FROM #TPUSheetData WHERE IDX_NO = @Count       -- 2011. 3. 18 hkim 통화 걸어서 거래처 가져오도록   
         
                    SELECT @wCustSeq2 = ISNULL(B.CustSeq, 0)        
                      FROM _TPUDelvItem  AS A        
                           JOIN _TPUDelv AS B ON A.CompanySeq = B.CompanySeq        
                           AND A.DelvSeq   = B.DelvSeq        
                     WHERE A.CompanySeq = @CompanySeq        
                       AND A.ItemSeq    = @wItemSeq        
                       AND B.CurrSeq    = @CurrSeq        
                       AND A.DelvSeq    = ( SELECT TOP 1 ISNULL(B.DelvSeq, 0) FROM _TPUDelvItem  AS A        
                                   JOIN _TPUDelv AS B ON A.CompanySeq = B.CompanySeq        
                                         AND A.DelvSeq    = B.DelvSeq        
                                                                             WHERE A.CompanySeq = @CompanySeq        
                                                                               AND A.ItemSeq    = @wItemSeq        
                                                                               AND B.CurrSeq    = @CurrSeq        
                                                                               AND B.DelvNo       = (SELECT TOP 1 ISNULL(MAX(B.DelvNo), '0') FROM _TPUDelvItem  AS A        
                                                                                         JOIN _TPUDelv AS B ON A.CompanySeq  = B.CompanySeq        
                                                                                                 AND A.DelvSeq     = B.DelvSeq        
                                                                                         WHERE A.CompanySeq = @CompanySeq        
                                                                                        AND @wItemSeq IN (A.ItemSeq)        
                                                                                        AND B.CurrSeq    = @CurrSeq) )       
                    UPDATE #TPUSheetData                                                                                                         
                       SET CustSeq = @wCustSeq2      
                      FROM #TPUSheetData      
                    WHERE IDX_NO = @Count      
                END      
          
                SELECT @Count = @Count + 1    
                SELECT @wCustSeq2 = 0       -- 0 으로 초기화   

            END
        END
    END

    -- 내외자구분 가져오기(1, 대표단가 2. 대표단가 체크 안된것 중 3. 품목등록에 등록 된 것      
    UPDATE #TPUSheetData      
       SET ImpType = ISNULL(B.ImpType, 0)      
      FROM #TPUSheetData    AS A      
           JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
     WHERE B.CompanySeq = @CompanySeq      
       AND @pDate BETWEEN B.StartDate AND B.EndDate      
       AND B.IsPrice = '1'      
       AND A.ImpType IS NULL OR A.ImpType = 0      
  
    UPDATE #TPUSheetData      
       SET ImpType = ISNULL(B.ImpType, 0)       
      FROM #TPUSheetData    AS A      
           JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
     WHERE B.CompanySeq = @CompanySeq      
       AND @pDate BETWEEN B.StartDate AND B.EndDate      
       AND A.ImpType IS NULL OR A.ImpType = 0        


    --2016.05.10 박수영 ::품목마스터의 내외자구분이 공백일 경우는 제외하고, 내/외자구분 만 적용되도록 수정
    UPDATE #TPUSheetData
       SET ImpType = CASE ISNULL(SMInOutKind, 0) WHEN 8007001 THEN 8008001 
                                                 WHEN 8007002 THEN 8008004 
                                                 ELSE 0
                     END
      FROM #TPUSheetData AS A
           JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq
     WHERE B.CompanySeq = @CompanySeq
       AND A.ImpType IS NULL OR A.ImpType = 0
       

    --2016.05.10 박수영 ::품목마스터에도 내외자구분이 세팅 안된 경우, 화면에서 수집한 내외자구분, 그것도 없으면 내수
    UPDATE #TPUSheetData
       SET ImpType = CASE WHEN ISNULL(GetImpType, 0) <> 0 THEN GetImpType ELSE 8008001 END
      FROM #TPUSheetData AS A
     WHERE A.ImpType IS NULL OR A.ImpType = 0
       
    -- 내외자구분 가져오기 끝      
       
    ------------------------------------------------------
    -- 창고가져오기
    ------------------------------------------------------
        -- 1. 의뢰부서별 소분류별 구매기본창고  
        SELECT TOP 1 @WHSeq = C.WHSeq  
          FROM #TPUSheetData AS A   
               JOIN _TDAItemClass AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
               JOIN _TPUReqDeptBasicWH AS C ON A.CompanySeq = C.CompanySeq AND A.DeptSeq = C.DeptSeq AND B.UMItemClass = C.UMItemClass  
     IF @WHSeq IS NULL OR @WHSeq = 0  
      BEGIN  
         SELECT TOP 1 @WHSeq = B.WHSeq   
           FROM #TPUSheetData AS A  
                JOIN _TPUReqDeptBasicWH AS B ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq AND B.UMItemClass = 0  
      END  
             IF @WHSeq IS NULL OR @WHSeq = 0  
             BEGIN  
                SELECT TOP 1 @WHSeq = C.WHSeq  
                  FROM #TPUSheetData AS A   
                       JOIN _TDAItemClass AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
                       JOIN _TPUReqDeptBasicWH AS C ON A.CompanySeq = C.CompanySeq AND B.UMItemClass = C.UMItemClass AND C.DeptSeq = 0  
             END  
                    IF @WHSeq IS NULL OR @WHSeq = 0  
                    BEGIN  
                       SELECT TOP 1 @WHSeq = B.WHSeq   
                         FROM #TPUSheetData AS A  
                              JOIN _TPUReqDeptBasicWH AS B ON A.CompanySeq = B.CompanySeq AND B.DeptSeq = 0 AND B.UMItemClass = 0  
                     END  
       

         UPDATE #TPUSheetData  
            SET WHSeq = @WHSeq  
          WHERE WHSeq IS NULL OR WHSeq = 0  



        -- 2. 품목별 기본창고       

        IF @PUType = 'PUORDPO'   
         BEGIN

        -- 로그인유저 사업부문의 창고를 가져오고 없으면 사업부문0으로 걸려있는 창고 가져오도록, 중복으로있을경우 창고가져오지않음
        
            UPDATE #TPUSheetData
             SET WHSeq = CASE (SELECT COUNT(1) FROM _TDAItemStdWH WHERE ItemSeq = A.ItemSeq AND CompanySeq = @CompanySeq AND (@BIzUnit = 0 OR BizUnit = @BIzUnit)) WHEN 1 THEN InWHSeq ELSE 0 END 
             FROM #TPUSheetData  AS A      
                   JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq            
               AND (@BIzUnit = 0 OR B.BizUnit = @BizUnit)
               AND (A.WHSeq IS NULL OR A.WHSeq = 0)

            UPDATE #TPUSheetData
             SET WHSeq = CASE (SELECT COUNT(1) FROM _TDAItemStdWH WHERE ItemSeq = A.ItemSeq AND CompanySeq = @CompanySeq AND BizUnit = 0) WHEN 1 THEN InWHSeq ELSE 0 END 
             FROM #TPUSheetData  AS A      
                   JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
             WHERE B.CompanySeq = @CompanySeq            
               AND B.BizUnit = 0  
               AND (A.WHSeq IS NULL OR A.WHSeq = 0)
         END


      ELSE 
       BEGIN
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.InWHSeq)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAItemStdWH AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq            
           AND (@BIzUnit = 0 OR B.BizUnit = @BizUnit)
           AND A.WHSeq IS NULL OR A.WHSeq = 0  
       END
        -- 3. 창고별품목      
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.WHSeq)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAWHItem  AS B ON A.ItemSeq = B.ItemSeq          
         WHERE B.CompanySeq = @CompanySeq  
           AND A.WHSeq IS NULL OR A.WHSeq = 0  
      
        -- 4. 구매단가등록의 창고      
        UPDATE #TPUSheetData      
           SET WHSeq = (SELECT TOP 1 B.WHSeq)      
         FROM #TPUSheetData    AS A      
              JOIN _TPUBaseBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq          
        WHERE B.CompanySeq = @CompanySeq            
          AND @pDate BETWEEN B.StartDate AND B.EndDate      
          AND B.IsPrice = '1'  
          AND A.WHSeq IS NULL OR A.WHSeq = 0  
      
        -- 5. 이전 품목별 납품창고      
       UPDATE #TPUSheetData      
          SET WHSeq = G.WHSeq      
         FROM #TPUSheetData  AS A      
              JOIN (SELECT B.DelvSeq AS DelvSeq, E.ItemSeq AS ItemSeq FROM _TPUDelv AS B      
                                                                           JOIN (SELECT MAX(C.DelvNo) AS DelvNo, D.ItemSeq AS ItemSeq      
                                                                                   FROM _TPUDelv            AS C      
                                                                                        JOIN _TPUDelvItem   AS D ON C.CompanySeq = D.CompanySeq      
                                                                                                                AND C.DelvSeq = D.DelvSeq      
                                                                                        JOIN #TPUSheetData  AS E ON D.ItemSeq = E.ItemSeq      
                                                                                  WHERE C.CompanySeq = @CompanySeq
                                                                                    AND (@BizUnit = 0 OR C.BizUnit = @BizUnit)  -- 동일 품목에 대하여 다른 사업부문에서 납품처리되었을때 사업부문까지 걸어 가져올 수 있도록 수정 2015.10.21 박수영
                                                                                    AND ISNULL(C.IsReturn, '0') <> '1'   -- 반품건 제외 12.02.14 김세호 추가
                                                                               GROUP BY D.ItemSeq)          AS E ON B.DelvNo = E.DelvNo AND B.CompanySeq = @CompanySeq) AS F ON A.ItemSeq = F.ItemSeq      
              JOIN _TPUDelvItem AS G ON F.DelvSeq = G.DelvSeq AND G.CompanySeq = @CompanySeq
        WHERE A.WHSeq IS NULL OR A.WHSeq = 0

        --창고를 가져오지 못했다면 화면에서 받은 창고 20110307 이재혁  
        --1=1 로 조인이 걸려있어, 제대로 연결이 안됨, IDX_NO 로 JOIN   20150824 박수영
        UPDATE  #TPUSheetData  
           SET  WHSeq = B.WHSeq  
          FROM  #TPUSheetData AS A JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO
         WHERE  A.WHSeq = 0  
                OR A.WHSeq = ''  
                OR A.WHSeq IS NULL OR A.WHSeq = 0  
    --####################################################################################################이재혁
        UPDATE #TPUSheetData  -- 창고가 사용안함이면 비워준다 
        SET WHSeq = 0
       FROM #TPUSheetData AS A JOIN _TDAWH AS B ON B.CompanySeq = @CompanySeq 
                                               AND A.WHSeq = B.WHSeq 
      WHERE B.CompanySeq = @CompanySeq 
      AND B.IsNotUse = 1 
    --####################################################################################################  
    -------------------------------------
    -- 창고 가져오기 끝      
    -------------------------------------
    

  
    /*****************************************************************************/      
    /**** 화폐 구매단위 메이커, 단가최소구매수량구매단위수량 가져오기  ***********/      
    /*****************************************************************************/      
    -- 화폐      
    EXEC _SPUBaseGetPriceSub 'CurrSeq',@CompanySeq, @pDate, @PUType, @UserSeq      
    -- 구매단위코드        
    EXEC _SPUBaseGetPriceSub 'StdUnitSeq',@CompanySeq, @pDate, @PUType, @UserSeq      
    -- 메이커코드        
    EXEC _SPUBaseGetPriceSub 'MakerSeq',@CompanySeq, @pDate, @PUType, @UserSeq     
    -- 단가, 최소수량, 구매 단위수량        
    EXEC hye_SPUDelvGetPriceSub 'Price',@CompanySeq, @pDate, @PUType, @UserSeq      
    /*****************************************************************************/      
    /**** 화폐 구매단위 메이커, 단가최소구매수량구매단위수량 가져끝    ***********/      
    /*****************************************************************************/      
    
----------------------------------------------------------------------------------------------------------  
--   구매반품입력에서의 단가가져오기 --통제값(6518반품기본단가 설정기준)--          -- 11.07.15 김세호 추가    
----------------------------------------------------------------------------------------------------------  
  
    IF @PUType = 'PUReturn'   
     BEGIN   
  
        EXEC dbo._SCOMEnv @CompanySeq,6518,@UserSeq,@@PROCID,@GetReturnPriceType OUTPUT  -- 구매반품단가 적용 통제값  
  
        -- 직접입력  
        IF @GetReturnPriceType = '6215001'  
         BEGIN   
            UPDATE #TPUSheetData  
               SET Price = 0  
              FROM #TPUSheetData    AS A  
              JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO  
          END  
        -- 구매기본단가 (대표단가)  
        ELSE IF @GetReturnPriceType = '6215002'  
         BEGIN   
            UPDATE #TPUSheetData  
               SET Price = ISNULL(Price, 0)  
         END  
        -- 전월 재고단가   
        ELSE  
         BEGIN  
  
            EXEC dbo._SCOMEnv @CompanySeq,5531,@UserSeq,@@PROCID,@CostEnv OUTPUT   -- 사용원가선택  
            EXEC dbo._SCOMEnv @CompanySeq,5563,@UserSeq,@@PROCID,@IFRSEnv OUTPUT   -- IFRS로만 결산처리 진행여부     
          
            IF @CostEnv = 5518001 AND ISNULL(@IFRSEnv, 0) = 0          -- 기본원가 사용    
            BEGIN    
                SELECT @SMCostMng = 5512004    
            END    
            ELSE IF @CostEnv = 5518001 AND @IFRSEnv = 1     -- 기본원가, IFRS 사용    
            BEGIN    
                SELECT @SMCostMng = 5512006    
            END    
            ELSE IF @CostEnv = 5518002 AND ISNULL(@IFRSEnv, 0) = 0     -- 활동기준원가 사용    
            BEGIN    
                SELECT @SMCostMng = 5512001    
            END    
            ELSE IF @CostEnv = 5518002 AND @IFRSEnv = 1     -- 활동기준원가, IFRS 사용    
            BEGIN       
                SELECT @SMCostMng = 5512005    
            END    
  
            ALTER TABLE #TPUSheetData  ADD EnvValue INT  
  
  
            -- 자산분류에 따른 환경설정값 가져오기   
            EXEC dbo._SCOMEnv @CompanySeq,5521,@UserSeq,@@PROCID,@MatPriceEnv OUTPUT   -- 자재단가계산단위  
            EXEC dbo._SCOMEnv @CompanySeq,5522,@UserSeq,@@PROCID,@GoodsPriceEnv OUTPUT   -- 상품단가계산단위  
  
  
            UPDATE #TPUSheetData   
               SET EnvValue = CASE WHEN ISNULL(B.SMAssetGrp, 0) = 6008001 THEN @GoodsPriceEnv ELSE @MatPriceEnv END  
             FROM  #TPUSheetData            AS A  
            LEFT OUTER JOIN  _TDAItemAsset  AS B ON @CompanySeq = B.CompanySeq  
                                                AND A.AssetSeq  = B.AssetSeq  
            UPDATE #TPUSheetData  
               SET EnvValue = CASE A.EnvValue WHEN 5502002 THEN ISNULL(B.AccUnit, 0) ELSE ISNULL(B.BizUnit, 0) END  
              FROM #TPUSheetData          AS A   
              LEFT OUTER JOIN _TDABizUnit AS B ON @CompanySeq = B.CompanySeq  
                                              AND (@BIzUnit = 0 OR @BizUnit = B.BizUnit)
  
  
  
            -- 전월재고단가 가져오기  
            UPDATE #TPUSheetData  
               SET Price = (SELECT TOP 1 ISNULL(B.Price, ISNULL(A.Price, 0))  
                             FROM #TPUSheetData                 AS A   
                             JOIN _TESMCProdStkPrice            AS B ON @CompanySeq  = B.CompanySeq  
                                                                    AND A.ItemSeq    = B.ItemSeq  
                                                                    AND A.EnvValue    = B.CostUnit   
                             JOIN _TESMDCostKey                 AS C ON B.CompanySeq = C.CompanySeq   
                                                                    AND B.CostKeySeq = C.CostKeySeq   
                                                                    AND C.RptUnit     = 0  
                                                                    AND C.PlanYear   = ''  
                                                                    AND C.CostMngAmdSeq   = 0  
  
                            WHERE @SMCostMng = C.SMCostMng                                 
                            ORDER BY CostYM DESC)  
  
         END  
     END  
----------------------------------------------------------------------------------------------------------  
--   구매반품입력에서의 단가가져오기 끝   
----------------------------------------------------------------------------------------------------------  
  

  
    --기타 데이터 가져오기      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitSeq = 0)  -- 기준단위 코드 없는 품목      
    BEGIN      
        UPDATE #TPUSheetData      
           SET StdUnitSeq = B.UnitSeq      
          FROM #TPUSheetData AS A      
               JOIN _TDAItem AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq        
               AND A.StdUnitSeq = 0          
    END      
      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitSeq = 0 OR CurrSeq = 0)  -- 통화 없는 품목      
    BEGIN      
        UPDATE #TPUSheetData      
           SET CurrSeq = CASE ImpType WHEN 8008001 THEN @xKorCurrSeq      
                                                   ELSE @xForCurrSeq END      
         WHERE CurrSeq = 0        
    END      
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE StdUnitQty = 0)  -- 기준단위 수량 없는 품목      
    BEGIN       
        UPDATE #TPUSheetData      
           SET StdUnitQty = ISNULL((B.ConvNum /B.ConvDen),1)      
          FROM #TPUSheetData  AS A      
               JOIN _TDAItemUnit AS B ON A.ItemSeq = B.ItemSeq AND A.StdUnitSeq = B.UnitSeq      
         WHERE B.CompanySeq = @CompanySeq      
           AND A.StdUnitQty = 0        
    END        
    IF EXISTS (SELECT 1 FROM #TPUSheetData WHERE ExRate = 0 OR ExRate IS NULL)    -- 환율 없는 품목      
    BEGIN      
        UPDATE #TPUSheetData      
           SET ExRate = 1      
          FROM #TPUSheetData AS A      
         WHERE ExRate = 0 OR ExRate IS NULL          
    END       
    IF EXISTS (SELECT 1 FROM #TPUSheetData    AS A         -- 검사품이 있을 경우      
                             JOIN _TPDBaseItemQCType AS B ON A.ItemSeq = B.ItemSeq       
                       WHERE B.CompanySeq = @CompanySeq AND B.IsInQC = '1')      
    BEGIN      
        UPDATE #TPUSheetData      
           SET QCType = 6035002      
          FROM #TPUSheetData   AS A      
               JOIN _TPDBaseItemQCType AS B ON A.ItemSeq = B.ItemSeq      
         WHERE B.CompanySeq = @CompanySeq AND B.IsInQC = '1'      
    END       
  
    -- 구매품의에서 입력 단가는 있고, 가져온 단가가 0인 경우에는 입력된 단가가 출력 되도록   
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.Price = 0)  
    BEGIN  
        UPDATE #TPUSheetData  
           SET Price = B.Price  
          FROM #TPUSheetData         AS A  
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO  
         WHERE B.Price <> 0 AND A.Price = 0                 
        
    END   
    
    -- 구매품의에서 구매단가등록에 해당하는 거래처가 없을 경우에, 자재등록 - 구매정보 의 기본구매처로 셋팅 되도록 2014.06.25 김용현 추가
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.CustSeq = 0 )    
    BEGIN    
    
        UPDATE #TPUSheetData    
           SET CustSeq = B.CustSeq   
          FROM #TPUSheetData         AS A    
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO    
         WHERE B.CustSeq <> 0 AND A.CustSeq = 0                   
          
    END  

    
    IF @PUType = 'PUORDApprovalReq' AND EXISTS ( SELECT 1 FROM #TPUBaseGetPrice AS A WHERE A.SMImpType = 8008004 AND ISNULL(A.CustSeq,0) = 0 )
                                    AND NOT EXISTS (SELECT 1 FROM #TPUBaseGetPrice          AS A   
                                                                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq  
                                                            WHERE B.CompanySeq = @CompanySeq   
                                                              AND @pDate BETWEEN B.StartDate AND B.EndDate)    
    BEGIN     
        UPDATE #TPUSheetData      
           SET CurrSeq = B.CurrSeq     
          FROM #TPUSheetData         AS A      
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO      
         WHERE B.SMImpType = 8008004            
           AND B.CurrSeq <> 0   
           AND B.CurrSeq <> @xKorCurrSeq 
           AND ISNULL(B.CustSeq,0) = 0         --20150410 임희진 :: 구매요청에서 점프해 온 것으로 인식
    END                                                                                                                                
    
    IF @PUType = 'PUORDApprovalReq' AND EXISTS (SELECT 1 FROM #TPUSheetData AS A WHERE A.MakerSeq = 0 )   
    BEGIN    
		--  자재등록-구매정보-Maker (1,2번 둘 다 없을 때) 16.11.10 임희진 추가
		UPDATE #TPUSheetData    
           SET MakerSeq = C.MkCustSeq   
          FROM #TPUSheetData         AS A    
               JOIN #TPUBaseGetPrice AS B ON A.IDX_NO = B.IDX_NO
			   JOIN _TDAItemPurchase AS C ON A.ItemSeq = C.ItemSeq    
										 AND C.CompanySeq = @CompanySeq
         WHERE ISNULL(B.MakerSeq,0) = 0 
		   AND ISNULL(A.MakerSeq,0) = 0 
	END
       
          
    IF @WorkingTag <> 'AUTO'      
    BEGIN      
    SELECT A.IDX_NO   AS IDX_NO  ,      
           A.CustSeq  AS CustSeq  ,      
           B.CustName  AS CustName  ,      
           A.MakerSeq  AS MakerSeq  ,      
           C.CustName  AS MakerName ,      
           A.ImpType  AS SMImpType ,       
           A.ImpType  AS SMImpTypeName,       
           A.ImpType  AS SMInOutType ,      
           A.ImpType  AS SMInOutTypeName,      
           A.CurrSeq  AS CurrSeq  ,      
           D.CurrName  AS CurrName  ,      
           A.Price   AS Price  ,      
           A.StdUnitQty  AS STDUnitQty ,      
           A.StdUnitQty  AS StdConvQty ,      
           A.MinQty   AS MinQty  ,      
           A.StepQty  AS StepQty  ,      
           A.QCType    AS SMQcType  ,       
           E.MinorName  AS SMQcTypeName ,       
           A.WHSeq   AS WHSeq  ,      
           F.WHName   AS WHName  ,      
           A.ExRate   AS ExRate  ,      
           A.AssetSeq  AS AssetSeq  ,      
           A.LeadTime  AS LeadTime  ,      
           A.StdUnitSeq  AS PUUnitSeq ,      
           CASE WHEN ISNULL(A.UnitSeq,0) = 0 THEN A.STDUnitSeq ELSE A.UnitSeq END  AS UnitSeq  ,      
           G.UnitName  AS PUUnitName ,      
           CASE WHEN ISNULL(U.UnitName,'') = '' THEN G.UnitName ELSE U.UnitName END  AS UnitName,
           CASE WHEN ISNULL(H.UnitSeq,0) = 0 THEN A.STDUnitSeq ELSE H.UnitSeq END  AS ReqUnitSeq       
      FROM #TPUSheetData    AS A      
           LEFT OUTER JOIN _TDACust      AS B ON B.CompanySeq = @CompanySeq      
                                             AND A.CustSeq  = B.CustSeq      
           LEFT OUTER JOIN _TDACust      AS C ON C.CompanySeq = @CompanySeq      
                                             AND A.MakerSeq  = C.CustSeq      
           LEFT OUTER JOIN _TDACurr      AS D ON D.CompanySeq = @CompanySeq      
                                             AND A.CurrSeq  = D.CurrSeq             
           LEFT OUTER JOIN _TDASMinor    AS E ON E.CompanySeq = @CompanySeq      
                                             AND A.QCType  = E.MinorSeq      
           LEFT OUTER JOIN _TDAWH        AS F ON F.CompanySeq = @CompanySeq      
                                             AND A.WHSeq   = F.WHSeq      
           LEFT OUTER JOIN _TDAUnit      AS G ON G.CompanySeq = @CompanySeq      
                                             AND A.StdUnitSeq = G.UnitSeq  
           LEFT OUTER JOIN _TDAUnit      AS U ON A.UnitSeq    = U.UnitSeq
                                             AND U.CompanySeq = @CompanySeq                                                
           --LEFT OUTER JOIN #TPUBaseGetPrice AS H ON A.ItemSeq = H.ItemSeq   
           LEFT OUTER JOIN #TPUBaseGetPrice AS H ON A.IDX_No = H.IDX_No
  ORDER BY A.IDX_NO      
    
    END         
    ELSE   -- 구매품의 일괄 생성일 경우 임시테이블을 업데이트 해줌      
    BEGIN      
        UPDATE #TPUBaseGetPrice        
           SET CustSeq   = B.CustSeq ,         
               MakerSeq  = B.MakerSeq   ,        
               SMImpType = ISNULL(B.ImpType, 0) ,        
               CurrSeq   = B.CurrSeq ,        
               UnitSeq   = B.StdUnitSeq ,      
               Price  = ISNULL(B.Price           ,  0)   ,        
               StdConvQty= ISNULL(B.StdUnitQty      ,  1)   ,        
               MinQty  = ISNULL(B.MinQty          ,  1)   ,        
               StepQty  = ISNULL(B.StepQty         ,  1)   ,        
               ExRate  = ISNULL(B.ExRate          ,  1)   ,        
               PUUnitSeq= ISNULL(B.StdUnitSeq  ,  0)   ,        
               STDUnitQty= ISNULL(B.StdUnitQty      ,  1)        
          FROM #TPUBaseGetPrice   AS A        
               JOIN #TPUSheetData AS B ON A.IDX_NO = B.IDX_NO        
    END      
RETURN        
/*************************구매단가 등록 화면에서 호출시********************************************/        
PUBasePrice_Proc:       

    -- 내외자 구분 및 기준단위 가져오기      
    INSERT INTO #TPUSheetData(ItemSeq, ImpType , STDUnitSeq)      
    SELECT A.ItemSeq, CASE ISNULL(B.SMInOutKind, 0) WHEN 8007001 THEN 8008001 WHEN 0 THEN 8008001 ELSE 8008004 END,      
           C.STDUnitSeq      
      FROM #TPUBaseGetPrice                AS A      
           JOIN _TDAItem                   AS B ON A.ItemSeq = B.ItemSeq      
           LEFT OUTER JOIN _TDAItemDefUnit AS C ON B.CompanySeq = C.CompanySeq      
                                               AND B.ItemSeq = C.ItemSeq      
     WHERE B.CompanySeq = @CompanySeq           
       AND C.UMModuleSeq= 1003001      
  ORDER BY A.IDX_No          
    -- 내외자구분에 따른 통화 업데이트      
    -- 기준 통화 가져오기        
    EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT        
    EXEC dbo._SCOMEnv @CompanySeq,12,@UserSeq,@@PROCID,@xForCurrSeq OUTPUT        
       
    UPDATE #TPUSheetData      
       SET CurrSeq = @xForCurrSeq      
     WHERE ImpType = 8008004      
      
    UPDATE #TPUSheetData      
       SET CurrSeq = @xKorCurrSeq      
     WHERE ImpType <> 8008004      
      
    SELECT A.ImpType  AS SMImpType ,      
           B.MinorName  AS SMImpTypeName,      
           A.STDUnitSeq  AS UnitSeq  ,      
           C.UnitName  AS UnitName  ,      
           A.CurrSeq  AS CurrSeq  ,      
           D.CurrName  AS CurrName      
      FROM #TPUSheetData AS A      
           LEFT OUTER JOIN _TDASMinor AS B ON B.CompanySeq = @CompanySeq      
                                          AND A.ImpType    = B.MinorSeq      
           LEFT OUTER JOIN _TDAUnit   AS C ON C.CompanySeq = @CompanySeq      
                                          AND A.STDUnitSeq = C.UnitSeq                  
           LEFT OUTER JOIN _TDACurr   AS D ON D.CompanySeq = @CompanySeq      
                                          AND A.CurrSeq    = D.CurrSeq      
  ORDER BY IDX_NO      
        
RETURN        

go
begin tran 
exec hye_SPUDelvGetPrice @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BizUnit>1</BizUnit>
    <UnitName>EA</UnitName>
    <MakerName />
    <MakerSeq>0</MakerSeq>
    <Price>20000</Price>
    <WHName>양산자재창고</WHName>
    <WHSeq>45</WHSeq>
    <STDUnitQty>10</STDUnitQty>
    <ItemSeq>18</ItemSeq>
    <UnitSeq>1</UnitSeq>
    <Memo2>1013554001</Memo2>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <CustSeq />
    <CurrSeq>3</CurrSeq>
    <PUType>Delivery</PUType>
    <Date>20161219</Date>
    <DeptSeq>3</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730170,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730012
rollback 
