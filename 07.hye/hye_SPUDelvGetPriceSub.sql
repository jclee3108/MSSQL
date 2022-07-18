IF OBJECT_ID('hye_SPUDelvGetPriceSub') IS NOT NULL 
    DROP PROC hye_SPUDelvGetPriceSub
GO 

-- v2016.12.19 

-- 품목별 구매정보 가져오기(구매단가등록_hye적용) by이재천
/**********************************************************************************************  
    코드헬프시 품목별 구매정보 가져오기 Sub SP  
    작성자     - 노영진  
      
    [****변경 이력****]  
    [수정자]    [수정일]   [수정내용]  
 김현  2010. 6. 21   커서 도는 방식에서 업데이트 방식으로 수정  
    이정숙  2010.11.09   최근단가를 가져오는 로직을 PONo, DelvNo의 Max값을 가져오는 부분을   
         일자(PODate, DelvDate)로 변경   
    송기연      2011.01.15          단가가져오기가 사이트마다 다를 경우 사이트 SP를 사용할수 있도록 추가 수정  
                2012.06.04          통화, 단위, Maker 가져올떄 업데이트 순서 수정  
                                    (동일조건으로 대표단가가 아닌건을 먼저 UPDATE후, 대표단가인건 UPDATE 되도록)  
    김용현      2014.04.15          최근 거래처 단가 가져오기의 경우 에서 JOIN 조건이 제대로 안걸려 있어서,  
                                    문제 되는 부분 수정함.   
    조성환(2014) 2014.09.26         최근 거래처 단가 가져오기의 경우 에서 JOIN 조건 수정   
                                    (기존로직에서 같은날짜에 A품목을 A,B 거래처에서 동시에 구매 진행하였을 경우 문제발생됨)       
***********************************************************************************************/     
CREATE PROCEDURE hye_SPUDelvGetPriceSub    
 @Tag  NVARCHAR(20),    
 @CompanySeq INT   ,    
 @Date  NCHAR(8) ,    
 @PUType  NVARCHAR(100),    
 @UserSeq INT         
AS          

      
DECLARE @xKorCurrSeq    INT,        
        @GetPriceType   INT,      
  @MaxRow   INT,    
  @Count   INT    
            
 -- 자국 통화 가져오기    
 EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@xKorCurrSeq OUTPUT      
     
 IF @Tag = 'CurrSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice') AND EXISTS (SELECT 1 FROM #TPUSheetData WHERE CurrSeq IS NULL)    
  BEGIN    
          
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
  
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
  
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq')    
  BEGIN    
   -- 내자    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND A.ImpType = 8008001      
  
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND A.ImpType = 8008001    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
         JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND B.IsPrice = '1'    
      AND A.ImpType = 8008001    
           
  
          
   
    
   -- 외자    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND A.ImpType = 8008004    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND A.ImpType = 8008004    
          
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq <> @xKorCurrSeq    
      AND B.IsPrice = '1'    
      AND A.ImpType = 8008004    
           
  
    
   -- 내수 수입건이 아닐 경우    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.ImpType NOT IN (8008001, 8008004)    
  
    
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.ImpType NOT IN (8008001, 8008004)    
    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'          
      AND A.ImpType NOT IN (8008001, 8008004)    
  
  END    
  ELSE IF @PUType IN ('Delivery', 'PUORDPO', 'PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
  
   UPDATE #TPUSheetData    
      SET CurrSeq = B.CurrSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq     
             AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.CurrSeq = @xKorCurrSeq    
      AND B.IsPrice = '1'    
           
  
  END      
 END       
 ELSE IF @Tag = 'StdUnitSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate   
  
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
        AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
   
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq', 'Delivery', 'PUORDPO', 'PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.CurrSeq = B.CurrSeq    
  
   UPDATE #TPUSheetData    
      SET StdUnitSeq = B.UnitSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND A.CurrSeq = B.CurrSeq    
      AND B.IsPrice = '1'    
          
  
  END    
 END      
 ELSE IF @Tag = 'MakerSeq'    
 BEGIN    
  IF @PUType IN ('ItemBuyPrice')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
    
  END    
  ELSE IF @PUType IN ('PUORDPOReq', 'PUORDApprovalReq', 'Delivery', 'PUORDPO','PUReturn')    
  BEGIN    
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq     
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate     
  
   UPDATE #TPUSheetData    
      SET MakerSeq = B.MakerSeq    
     FROM #TPUSheetData    AS A    
       JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
    WHERE B.CompanySeq = @CompanySeq    
      AND @Date BETWEEN B.StartDate AND B.EndDate    
      AND B.IsPrice = '1'    
          
  
  END    
 END      
 ELSE IF @Tag = 'Price'    
    BEGIN    
        -- 통제값 가져오기(최근 구매단가 사용 여부)      
        EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@GetPriceType OUTPUT    

        -- 구매단가등록에서 단가 가져오기      
        IF @GetPriceType = '6072001'  -- 구매단가등록에서 가져오기    
        BEGIN    
            IF @PUType IN ('PUORDPOReq')     
            BEGIN    
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0           
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            ELSE IF @PUType IN ('PUORDApprovalReq')     
            BEGIN    
     
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                 JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq  AND A.UnitSeq = B.UnitSeq  -- 단위변경시 수정 될 수 있도록 추가
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0     
                
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq  -- 품의에도 통화조건 추가  12.04.23 BY 김세호  
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0         
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq   -- 품의에도 통화조건 추가  12.04.23 BY 김세호    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            ELSE IF @PUType IN ('Delivery', 'PUORDPO', 'ImportBargain', 'LCAdd', 'PUReturn')     
            BEGIN    
     
                ---- 단위를 변경 할 경우에 기준단가여부에 체크된 금액만 가져오는데, 같은 거래처에 같은 품목에 단위가 다른 경우에는 똑같은 단가를 가져오므로,----  
                ---- 문제가 됨, 하여, 화면상의 단위가 변경 될 경우 그에 맞는 단가를 가져오도록 함 ---- 2014.04.21 김용현 추가  
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq   
                                                AND A.CustSeq = B.CustSeq   
                                                AND A.CurrSeq = B.CurrSeq   
                                                AND A.UnitSeq = B.UnitSeq   
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   --AND B.IsPrice = '1'     
                   AND A.Price = 0    
                
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND B.IsPrice = '1'     
                   AND A.Price = 0         
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq AND A.CurrSeq = B.CurrSeq    
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
      
                UPDATE #TPUSheetData    
                   SET Price = B.Price ,    
                       MinQty = B.MinQty ,    
                       StepQty  = B.StepQty    
                  FROM #TPUSheetData    AS A    
                  JOIN _TPUBASEBuyPriceItem AS B ON A.ItemSeq = B.ItemSeq AND A.CustSeq = B.CustSeq      
                 WHERE B.CompanySeq = @CompanySeq     
                   AND @Date BETWEEN B.StartDate AND B.EndDate    
                   AND A.Price = 0    
            END    
            
            -- 구매단가등록_hye 적용 by이재천 
            DECLARE @SKCustSeq INT 
            SELECT @SKCustSeq = (SELECT TOP 1 EnvValue FROM hye_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 5) 

            UPDATE A
               SET Price = B.YSSPrice 
              from #TPUSheetData AS A 
              JOIN hye_TPUBaseBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq 
                                                 AND B.ItemSeq = A.ItemSeq 
                                                 AND B.UnitSeq = A.UnitSeq 
                                                 AND B.CurrSeq = A.CurrSeq 
                                                 AND B.UMDVGroupSeq = A.UMDVGroupSeq 
                                                    ) 
              LEFT OUTER JOIN _TDAItemPurchase  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
              LEFT OUTER JOIN _TDAItemUserDefine AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = B.ItemSeq AND D.MngSerl = 1000005 )     
             WHERE @Date BETWEEN B.SrtDate AND B.EndDate 
               AND C.PurCustSeq = @SKCustSeq 
               AND ISNULL(C.PurCustSeq,0) <> 0 
               AND (D.MngValText = '1' OR D.MngValText = 'True')
            -- 구매단가등록_hye 적용, END 
           
        END    
        ELSE IF @GetPriceType = '6072002'   -- 이전 구매처 최근 단가 적용(발주)  
        BEGIN      
            IF @PUType IN ('PUORDPOReq')    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
                
                WHILE ( 1 = 1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
            
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData  AS A    
                      JOIN _TPUORDPOItem AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUORDPO  AS C ON B.CompanySeq = C.CompanySeq AND B.POSeq = C.POSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq  
                       AND C.PONo= (SELECT MAx(PONo) 
                                      FROM _TPUORDPO AS A   
                                      JOIN _TPUORDPOITem AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq            
                                      JOIN ( SELECT ISNULL(MAX(B.PODate), 0) PODate, A.ItemSeq AS ItemSeq, B.CustSeq as CustSeq  
                                               FROM _TPUORDPOItem AS A    
                                               JOIN _TPUORDPO  AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq    
                                               JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq  -- 2014.04.15 김용현 거래처가 안걸려 있어서 걸어줌   
                                               WHERE A.CompanySeq = @CompanySeq    
                                                 AND C.IDX_NO  = @Count    
                                                 AND B.CurrSeq = C.CurrSeq  
                                                 AND A.Price <> 0 
                                               Group by A.ItemSeq, B.CustSeq
                                           ) AS C ON A.PODate = C.PODate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- 거래처 조회조건 추가 : 20140926 조성환2014      
                                     WHERE A.CompanySeq = @CompanySeq ) -- CompanySeq 도 역시나 한번 더 걸어야 된다( 다른 법인 것을 가져올 경우가 있음 )   
                
                    SELECT @Count = @Count + 1    
                END -- while end   
            END  -- @PUType end 
            ELSE    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData    
                
                WHILE ( 1 = 1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
  
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData AS A    
                      JOIN _TPUORDPOItem AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUORDPO  AS C ON B.CompanySeq = C.CompanySeq AND B.POSeq = C.POSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq    
                       AND A.CustSeq = C.CustSeq    
                       AND C.PONo = (SELECT MAx(PONo) 
                                       FROM _TPUORDPO AS A   
                                       JOIN _TPUORDPOITem AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq            
                                       JOIN ( SELECT ISNULL(MAX(B.PODate), 0) PODate, A.ItemSeq AS ItemSeq, B.CustSeq AS CustSeq  
                                                FROM _TPUORDPOItem AS A    
                                                JOIN _TPUORDPO  AS B ON A.CompanySeq = B.CompanySeq AND A.POSeq = B.POSeq    
                                                JOIN #TPUSheetData AS C ON A.ItemSeq  = C.ItemSeq AND B.CustSeq = C.CustSeq   -- 2014.04.15 김용현 거래처가 안걸려 있어서 걸어줌   
                                               WHERE A.CompanySeq = @CompanySeq    
                                                 AND C.IDX_NO  = @Count    
                                                 AND B.CurrSeq = C.CurrSeq  
                                                 AND A.Price <> 0 
                                               Group by A.ItemSeq, B.CustSeq
                                            ) AS C ON A.PODate = C.PODate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- 거래처 조회조건 추가 : 20140926 조성환2014       
                                      WHERE A.CompanySeq = @CompanySeq   ) -- CompanySeq 도 역시나 한번 더 걸어야 된다( 다른 법인 것을 가져올 경우가 있음 )   
                
                    SELECT @Count = @Count + 1    
                END -- while end 
            END    
        END  
        ELSE IF @GetPriceType = '6072003'   -- 이전 구매처 최근 단가 적용(납품)  
        BEGIN    
            IF @PUType IN ('PUORDPOReq')    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
                
                WHILE ( 1 = 1)    
                BEGIN    
                    
                    IF @Count > @MaxRow BREAK    
            
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData    AS A    
                      JOIN _TPUDelvItem     AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUDelv         AS C ON B.CompanySeq = C.CompanySeq AND B.DelvSeq = C.DelvSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq  
                       AND C.DelvNo= (SELECT MAx(DelvNo) 
                                        FROM _TPUDelv AS A   
                                        JOIN _TPUDelvItem AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq            
                                        JOIN ( SELECT ISNULL(MAX(B.DelvDate), 0) DelvDate, A.ItemSeq AS ItemSeq, B.CustSeq as CustSeq  
                                                 FROM _TPUDelvItem AS A    
                                                 JOIN _TPUDelv  AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq    
                                                 JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq   -- 2014.04.15 김용현 추가    
                                                WHERE A.CompanySeq = @CompanySeq    
                                                  AND C.IDX_NO  = @Count    
                                                  AND B.CurrSeq = C.CurrSeq  
                                                  AND A.Price <> 0 
                                                Group by A.ItemSeq, B.CustSeq
                                             ) AS C ON A.DelvDate = C.DelvDate AND B.ItemSeq = C.ItemSeq AND A.Custseq = C.Custseq -- 거래처 조회조건 추가 : 20140926 조성환2014      
                                       WHERE A.CompanySeq = @CompanySeq) -- CompanySeq 도 역시나 한번 더 걸어야 된다( 다른 법인 것을 가져올 경우가 있음 )        
                  
                    SELECT @Count = @Count + 1    
                END -- while end 
            END -- @PUType end 
            ELSE    
            BEGIN    
                SELECT @MaxRow = MAX(IDX_NO) FROM #TPUSheetData    
                SELECT @Count  = MIN(IDX_NO) FROM #TPUSheetData   
      
                WHILE ( 1 =  1)    
                BEGIN    
                    IF @Count > @MaxRow BREAK    
             
                    UPDATE #TPUSheetData    
                       SET Price = B.Price    
                      FROM #TPUSheetData AS A    
                      JOIN _TPUDelvItem  AS B ON A.ItemSeq = B.ItemSeq    
                      JOIN _TPUDelv  AS C ON B.CompanySeq = C.CompanySeq AND B.DelvSeq = C.DelvSeq    
                     WHERE B.CompanySeq = @CompanySeq           
                       AND A.IDX_NO  = @Count         
                       AND A.CurrSeq = C.CurrSeq    
                       AND A.CustSeq = C.CustSeq    
                       AND C.DelvNo= (SELECT MAx(DelvNo) 
                                        FROM _TPUDelv AS A   
                                        JOIN _TPUDelvItem AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq            
                                        JOIN ( SELECT ISNULL(MAX(B.DelvDate), 0) DelvDate, A.ItemSeq AS ItemSeq, B.CustSeq as Custseq  
                                                 FROM _TPUDelvItem AS A    
                                                 JOIN _TPUDelv  AS B ON A.CompanySeq = B.CompanySeq AND A.DelvSeq = B.DelvSeq    
                                                 JOIN #TPUSheetData AS C ON A.ItemSeq = C.ItemSeq AND B.CustSeq = C.CustSeq  -- 2014.04.15 김용현 추가   
                                                WHERE A.CompanySeq = @CompanySeq    
                                                  AND C.IDX_NO  = @Count    
                                                  AND B.CurrSeq = C.CurrSeq  
                                                  AND A.Price <> 0 
                                                Group by A.ItemSeq, B.CustSeq
                                             ) AS C ON A.DelvDate = C.DelvDate AND B.ItemSeq = C.ItemSeq AND A.CustSeq = C.CustSeq -- 거래처 조회조건 추가 : 20140926 조성환2014     
                                       WHERE A.CompanySeq = @CompanySeq ) -- CompanySeq 도 역시나 한번 더 걸어야 된다( 다른 법인 것을 가져올 경우가 있음 )         
    
                    SELECT @Count = @Count + 1    
                END -- while end 
            END -- else end 
        END  -- @GetPriceType 
    END -- @Tag
    
RETURN


go 