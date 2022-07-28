
IF OBJECT_ID('_SSEChemicalsWkMngListQueryCHE') IS NOT NULL 
    DROP PROC _SSEChemicalsWkMngListQueryCHE
GO 

-- v2015.02.17 

/************************************************************  
  설  명 - 데이터-화학물질관리대장_capro : 조회  
  작성일 - 20110603  
  작성자 - 박헌기  
 ************************************************************/  
 CREATE PROC dbo._SSEChemicalsWkMngListQueryCHE  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT             = 0,  
     @ServiceSeq     INT             = 0,  
     @WorkingTag     NVARCHAR(10)    = '',  
     @CompanySeq     INT             = 1,  
     @LanguageSeq    INT             = 1,  
     @UserSeq        INT             = 0,  
     @PgmSeq         INT             = 0  
 AS    
     --조회조건    
     DECLARE @docHandle     INT ,    
             @ChmcSeq       INT ,           
             @InOutWkType   INT ,    
             @RetYearMonth  NCHAR(6),  
             @FactUnit      INT  
                 
     --SP사용변수            
     DECLARE @DD            NVARCHAR(2)  ,--일자생성용    
             @LastDate      INT          ,--해당월의 총일수    
             @RowNum        INT          ,    
             @CreatDate     NCHAR(8)     ,--생성일자    
             @InWkType      INT          ,--구매작업내역코드    
             @InWkTypeName  NVARCHAR(100),--구매작업내역    
             @OutWkType     INT          ,--출고작업내역코드    
             @OutWkTypeName NVARCHAR(100) --출고작업내역    
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
     
     SELECT  @ChmcSeq       = ChmcSeq        ,    
             @InOutWkType   = InOutWkType    ,    
             @RetYearMonth  = RetYearMonth       
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
       WITH  (ChmcSeq        INT ,    
              InOutWkType    INT ,    
              RetYearMonth   NCHAR(6) )   
   
   
   
     --DataBlock1 최종 조회용 테이블    
     CREATE TABLE #_TSEChemicalsWkListCHE    
     (    
         Seq               INT IDENTITY  ,      
         RetDate           NCHAR(8)      , -- 년월일             
         ItemSeq           INT           , -- 품명코드         
         PrintName         NVARCHAR(100) , -- 품명(출력명)     
         ItemNo            NVARCHAR(100) , -- 품번             
         ToxicName         NVARCHAR(400) , -- 유독품명         
         MainPurpose       NVARCHAR(400) , -- 주요용도         
         Content           NVARCHAR(400) , -- 함량             
         UnitSeq           INT           , -- 단위코드         
         UnitName          NVARCHAR(100) , -- 단위                
         PreQty            DECIMAL(19,5 ), -- 이월량                
         InWkType          INT           , -- 입고구분코드          
         InWkTypeName      NVARCHAR(100) , -- 입고구분              
         InQty             DECIMAL(19,5) , -- 입고수량              
         InCustSeq         INT           , -- 입고상호코드          
         InCustName        NVARCHAR(100) , -- 입고상호명            
         InOwner           NVARCHAR(100) , -- 입고대표자성명        
         InBizNo           NVARCHAR(100) , -- 입고사업자등록번호    
         InBizAddr         NVARCHAR(100) , -- 입고상호주소          
         InTelNo           NVARCHAR(100) , -- 입고상호전화번호      
         OutWkType         INT           , -- 출고구분코드          
         OutWkTypeName     NVARCHAR(100) , -- 출고구분              
         OutQty            DECIMAL(19,5) , -- 출고수량              
         OutCustSeq        INT           , -- 출고상호코드          
         OutCustName       NVARCHAR(100) , -- 출고상호명            
         OutOwner          NVARCHAR(100) , -- 입고대표자성명        
         OutBizNo          NVARCHAR(100) , -- 출고사업자등록번호    
         OutBizAddr        NVARCHAR(100) , -- 출고상호주소          
         OutTelNo          NVARCHAR(100) , -- 출고상호전화번호      
         StockQty          DECIMAL(19,5) , -- 재고량                
         ReMark            NVARCHAR(100) , -- 비고    
         InPutDesc         NVARCHAR(400) , -- 구입내역의 마킹    
         OutPutDesc        NVARCHAR(400)   -- 출고내역의 마킹    
     )            
      
     -- 조회용 품목    
     CREATE TABLE #GetInOutItem    
     (    
         ItemSeq    INT    
     )    
     -- 재고 수량 템프    
     CREATE TABLE #GetInOutStock    
     (    
         WHSeq           INT,    
         FunctionWHSeq   INT,    
         ItemSeq         INT,    
         UnitSeq         INT,    
         PrevQty         DECIMAL(19,5),    
         InQty           DECIMAL(19,5),    
         OutQty          DECIMAL(19,5),    
         StockQty        DECIMAL(19,5),    
         STDPrevQty      DECIMAL(19,5),    
         STDInQty        DECIMAL(19,5),    
         STDOutQty       DECIMAL(19,5),    
         STDStockQty     DECIMAL(19,5)    
     )    
     
     --Item 구하기    
     INSERT INTO #GetInOutItem    
     SELECT DISTINCT A.ItemSeq    
       FROM _TSEChemicalsListCHE AS A WITH(NOLOCK)    
      WHERE A.CompanySeq = @CompanySeq    
        AND (@ChmcSeq = 0 or A.ChmcSeq = @ChmcSeq)    
   
   
     --마지막일           
     SELECT @LastDate = CONVERT(INT, DAY(DATEADD(D, -1, DATEADD(M, 1, @RetYearMonth+'01'))))    
     
     SELECT @RowNum = 0    
     --조회월의 일수생성 / 이월량 / 재고량 생성/    
     WHILE @RowNum < @LastDate    
     BEGIN    
             SELECT @RowNum = @RowNum + 1    
             SELECT @DD = CONVERT(NVARCHAR(2),@RowNum,112)    
             SELECT @CreatDate = @RetYearMonth + (CASE WHEN LEN(@DD) = 1 THEN '0'+@DD ELSE @DD END)    
                 
             --재고 테이블 삭제    
             DELETE FROM #GetInOutStock    
                 
             -- 창고재고 가져오기    
             EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,    -- 법인코드    
                                     @BizUnit      = 0          ,    -- 사업부문    
                                     @FactUnit     = 0          ,    -- 생산사업장    
                                     @DateFr       = @CreatDate ,    -- 조회기간Fr    
                                     @DateTo       = @CreatDate ,    -- 조회기간To    
                                     @WHSeq        = 0          ,    -- 창고지정    
                                     @SMWHKind     = 0          ,    -- 창고구분별 조회    
                                     @CustSeq      = 0          ,    -- 수탁거래처    
                                     @IsTrustCust  = ''         ,    -- 수탁여부    
                                     @IsSubDisplay = ''         ,    -- 기능창고 조회    
                                     @IsUnitQry    = ''         ,    -- 단위별 조회    
                                     @QryType      = 'S'             -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고               
                
             INSERT #_TSEChemicalsWkListCHE    
                   ( RetDate       , -- 년월일                  
                     ItemSeq       , -- 품명코드                
                     PrintName     , -- 품명(출력명)            
                     ItemNo        , -- 품번                    
                     ToxicName     , -- 유독품명                
                     MainPurpose   , -- 주요용도                
                     Content       , -- 함량                    
                     UnitSeq       , -- 단위코드                
                     UnitName      , -- 단위                    
                     PreQty        , -- 이월량                  
                     InWkType      , -- 입고구분코드            
                     InWkTypeName  , -- 입고구분                
                     InQty         , -- 입고수량                
                     InCustSeq     , -- 입고상호코드            
                     InCustName    , -- 입고상호명              
                     InOwner       , -- 입고대표자성명          
                     InBizNo       , -- 입고사업자등록번호      
                     InBizAddr     , -- 입고상호주소            
                     InTelNo       , -- 입고상호전화번호        
                     OutWkType     , -- 출고구분코드            
                     OutWkTypeName , -- 출고구분                
                     OutQty        , -- 출고수량                
                     OutCustSeq    , -- 출고상호코드            
                     OutCustName   , -- 출고상호명              
                     OutOwner      , -- 입고대표자성명      
                     OutBizNo      , -- 출고사업자등록번호      
                     OutBizAddr    , -- 출고상호주소            
                     OutTelNo      , -- 출고상호전화번호         
                     StockQty      , -- 재고량                  
                     ReMark        ) -- 비고                  
               SELECT  @RetYearMonth +  (CASE WHEN LEN(@DD) = 1 THEN '0'+@DD ELSE @DD END), --일자    
                     0      , -- 품명코드                
                     ''     , -- 품명(출력명)            
                     ''     , -- 품번                    
                     ''     , -- 유독품명                
                       ''     , -- 주요용도                 
                     ''     , -- 함량                    
                     0      , -- 단위코드                
                     ''     , -- 단위                    
                     0      , -- 이월량                  
                     0      , -- 입고구분코드            
                     ''     , -- 입고구분                
                     0      , -- 입고수량                
                     0      , -- 입고상호코드            
                     ''     , -- 입고상호명              
                     ''     , -- 입고대표자성명          
                     ''     , -- 입고사업자등록번호      
                     ''     , -- 입고상호주소            
                     ''     , -- 입고상호전화번호        
                     0      , -- 출고구분코드            
                     ''     , -- 출고구분                
                     0      , -- 출고수량                
                     0      , -- 출고상호코드            
                     ''     , -- 출고상호명              
                     ''     , -- 입고대표자성명          
                     ''     , -- 출고사업자등록번호      
                     ''     , -- 출고상호주소            
                     ''     , -- 출고상호전화번호        
                     ISNULL((SELECT SUM(STDStockQty) FROM #GetInOutStock),0), -- 재고량                  
                     ''         -- 비고            
                 
             --이월량 생성           
             IF @DD = '1'    
             BEGIN    
                 --재고 테이블 삭제    
                 DELETE FROM #GetInOutStock    
                 SELECT @CreatDate = CONVERT(CHAR(8),dateadd(DAY,-1,@CreatDate),112)      
                     
                 -- 창고재고 가져오기    
                 EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,   -- 법인코드    
                                         @BizUnit      = 0          ,   -- 사업부문    
                                         @FactUnit     = 0          ,   -- 생산사업장    
                                         @DateFr       = @CreatDate ,   -- 조회기간Fr    
                                         @DateTo       = @CreatDate ,   -- 조회기간To    
                                         @WHSeq        = 0          ,   -- 창고지정    
                                         @SMWHKind     = 0          ,   -- 창고구분별 조회    
                                         @CustSeq      = 0          ,   -- 수탁거래처    
                                         @IsTrustCust  = ''         ,   -- 수탁여부    
                                         @IsSubDisplay = ''         ,   -- 기능창고 조회    
                                         @IsUnitQry    = ''         ,   -- 단위별 조회    
                                         @QryType      = 'S'            -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고      
                     
                     
                UPDATE #_TSEChemicalsWkListCHE    
                   SET PreQty = ISNULL((SELECT SUM(STDStockQty) FROM #GetInOutStock),0) --이월량 생성    
                 WHERE Seq = 1    
                  --SELECT * FROM #GetInOutStock   
             END    
                        
     END    
         
     -- 공통정보 등록    
     UPDATE #_TSEChemicalsWkListCHE    
        SET ItemSeq    = A.ItemSeq     ,  -- 품번코드                       
            PrintName  = A.PrintName   ,  -- 출력명      
            ItemNo     = B.ItemNo      ,  -- 품번        
            ToxicName  = A.ToxicName   ,  -- 유독물명    
            MainPurpose= A.MainPurpose ,  -- 주요용도    
            Content    = A.Content     ,  -- 함량        
            UnitSeq    = B.UnitSeq     ,  -- 단위코드    
            UnitName   = C.UnitName       -- 단위                
      FROM  _TSEChemicalsListCHE   AS A WITH (NOLOCK)    
            JOIN _TDAItem            AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                         AND A.ItemSeq    = B.ItemSeq    
            LEFT OUTER JOIN _TDAUnit AS C WITH (NOLOCK) ON B.CompanySeq = C.CompanySeq    
                                                       AND B.UnitSeq    = C.UnitSeq    
     WHERE  A.CompanySeq = @CompanySeq    
       AND  (@ChmcSeq = 0 or A.ChmcSeq    = @ChmcSeq)                  
   
   
   
     -- 작업구분에 해당하는 입고/출고내역 가져오기      
     SELECT @InWkType     = ISNULL(A.InWkType,0),    
            @InWkTypeName = B.MinorName,              
            @OutWkType    = ISNULL(A.OutWkType,0),    
            @OutWkTypeName= C.MinorName    
       FROM _TSEChemicalsWkListCHE   AS A    
            LEFT OUTER JOIN _TDASMinor AS B ON A.CompanySeq = B.CompanySeq    
                                           AND A.InWkType   = B.MinorSeq    
            LEFT OUTER JOIN _TDASMinor AS C ON A.CompanySeq = C.CompanySeq    
                                           AND A.OutWkType  = C.MinorSeq                                            
      WHERE A.CompanySeq  = @CompanySeq  
        AND A.ChmcSeq     = @ChmcSeq    
        AND A.InOutWkType = @InOutWkType    
   
   
      -- 작업구분 등록          
      UPDATE #_TSEChemicalsWkListCHE    
         SET InWkType      = ISNULL(@InWkType,0)      ,    
             InWkTypeName  = @InWkTypeName  ,    
             OutWkType     = ISNULL(@OutWkType,0)     ,    
             OutWkTypeName = @OutWkTypeName      
   
      -- 출력물에 사용될 마킹 등록(황산일때)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET InPutDesc     = CASE WHEN InWkType = 0 THEN OutWkTypeName + '이후의 사용 및 재고량 현황은 '+CHAR(10)+PrintName+ ' 입고량(제조) 관리대장 참조' ELSE '' END, --출력물에 사용될 마킹(구입내역란이 공란일때)    
             OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '이후의 사용 및 재고량 현황은 '+CHAR(10)+PrintName+ ' 입고량(제조) 관리대장 참조' ELSE '' END, --출력물에 사용될 마킹(출고내역란이 공란일때)     
             StockQty      = CASE WHEN @InOutWkType = 6121005 THEN 0 ELSE StockQty END,
             PreQty        = CASE WHEN @InOutWkType = 6121005 THEN 0 ELSE PreQty END
       WHERE ItemNo = 'PD03'  
   
   
      -- 출력물에 사용될 마킹 등록(벤젠일때)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET InPutDesc     = CASE WHEN InWkType = 0 THEN '나머지는 화학물질 사용 관리대장 참조' ELSE '' END, --출력물에 사용될 마킹(출고내역란이 공란일때)     
             OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '이후의 사용 및 재고량 현황은 '+CHAR(10)+PrintName+ ' 입고량(구입) 관리대장 참조' ELSE '' END, --출력물에 사용될 마킹(구입내역란이 공란일때)    
             StockQty      = CASE WHEN @InOutWkType = 6121005 OR @InOutWkType = 6121004 THEN 0 ELSE StockQty END,
             PreQty        = CASE WHEN @InOutWkType = 6121005 OR @InOutWkType = 6121004 THEN 0 ELSE PreQty END
       WHERE ItemNo = '405-0000-001-0'            
   
      -- 출력물에 사용될 마킹 등록(황산일때)    
      UPDATE #_TSEChemicalsWkListCHE    
         SET OutPutDesc    = CASE WHEN OutWkType = 0 THEN InWkTypeName + '이후의 사용 및 재고량 현황은 '+CHAR(10)+PrintName+ ' 입고량(구입) 관리대장 참조' ELSE '' END , --출력물에 사용될 마킹(구입내역란이 공란일때)    
             StockQty      = CASE WHEN OutWkType = 0 THEN 0 ELSE StockQty END
       WHERE ItemNo = '411-0000-001-0'  
   
     -- 입고내역    
     CREATE TABLE #GetInQty    
     (    
         RetDate           NCHAR(8)      ,    
         InCustCd          INT           ,    
         InQty             DECIMAL(19,5) ,    
     )         
     
     --출고내역    
     CREATE TABLE #GetOutQty    
     (    
         RetDate           NCHAR(8)      ,    
         OutCustCd         INT           ,    
         OutQty            DECIMAL(19,5) 
     )    
     ----------------------------------------------------------------------입고내역    
     IF @InWkType      = 6122001 --제조(생산실적)-완성품명    
     BEGIN    
         INSERT #GetInQty  
               (RetDate ,  
                InCustCd,  
                InQty     )  
         SELECT A.WorkDate,  
                0         ,  
        CASE WHEN @ChmcSeq = 9 THEN A.StdUnitOKQty * 1.28 ELSE A.StdUnitOKQty END  
           FROM _TPDSFCWorkReport  AS A  
                JOIN #GetInOutItem AS B ON A.GoodItemSeq = B.ItemSeq  
          WHERE A.CompanySeq = @CompanySeq  
            AND CONVERT(CHAR(6),A.WorkDate,112) = @RetYearMonth  
            AND A.FactUnit = CASE WHEN @ChmcSeq = 9 THEN 3 ELSE A.FactUnit END -- 하이드록실아민포스페이트(용융락탐)의 경우 3공장 데이터를 집계하기 위해  
             
     END    
     ELSE IF @InWkType = 6122002 --구입(구매입고-내수)    
     BEGIN    
             
         INSERT #GetInQty    
               (RetDate ,    
                InCustCd,    
                InQty     )    
         SELECT A.DelvInDate,    
                A.CustSeq   ,    
                B.StdUnitQty    
           FROM _TPUDelvIn AS A    
                JOIN _TPUDelvInItem AS B ON A.CompanySeq = B.CompanySeq     
                                        AND A.DelvInSeq  = B.DelvInSeq    
                JOIN #GetInOutItem  AS C ON B.ItemSeq    = C.ItemSeq    
          WHERE A.CompanySeq = @CompanySeq    
              AND B.SMImpType   = 8008001  -- 내수       
            AND CONVERT(CHAR(6),A.DelvInDate,112) = @RetYearMonth                
                   
                   
     END    
     ELSE IF @InWkType = 6122003 --수입(구매입고-내수제외)    
     BEGIN    
         INSERT #GetInQty    
               (RetDate ,    
                InCustCd,    
                InQty     )    
         SELECT A.DelvInDate,    
                A.CustSeq   ,    
                B.StdUnitQty    
           FROM _TPUDelvIn AS A    
                JOIN _TPUDelvInItem AS B ON A.CompanySeq = B.CompanySeq     
                                        AND A.DelvInSeq  = B.DelvInSeq    
                JOIN #GetInOutItem  AS C ON B.ItemSeq    = C.ItemSeq    
          WHERE A.CompanySeq = @CompanySeq    
            AND B.SMImpType  <> 8008001  -- 내수제외    
            AND CONVERT(CHAR(6),A.DelvInDate,112) = @RetYearMonth      
     END    
   
      ----------------------------------------------------------------------출고내역         
      IF @OutWkType      = 6123001 --판매(거래명세표)    
      BEGIN    
         INSERT #GetOutQty    
               (RetDate  ,    
                OutCustCd,    
                OutQty     )  
         SELECT A.InvoiceDate,    
                A.CustSeq    ,    
                B.STDQty    
          FROM _TSLInvoice          AS A WITH(NOLOCK)      
               JOIN _TSLInvoiceItem AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq      
                                                     AND A.InvoiceSeq  = B.InvoiceSeq      
               JOIN #GetInOutItem                AS C ON B.ItemSeq     = C.ItemSeq                                          
         WHERE A.CompanySeq = @CompanySeq    
           AND CONVERT(CHAR(6),A.InvoiceDate,112) = @RetYearMonth  
           AND A.IsDelvCfm = '1'  
      END    
      ELSE IF @OutWkType = 6123002 --사용(생산투입)    
      BEGIN    
         INSERT #GetOutQty    
               (RetDate  ,    
                OutCustCd,    
                OutQty     )    
         SELECT A.InputDate,    
                0          ,    
                A.StdUnitQty  
           FROM _TPDSFCMatinput AS A WITH(NOLOCK)  
                JOIN #GetInOutItem AS C ON A.MatItemSeq = C.ItemSeq     
          WHERE A.CompanySeq = @CompanySeq    
            AND CONVERT(CHAR(6),A.InputDate,112) = @RetYearMonth  
             
      END         
          
      IF EXISTS (SELECT 1 FROM #GetInQty)    
      BEGIN    
          --입고 수량 등록    
          UPDATE #_TSEChemicalsWkListCHE    
             SET InQty = B.InQty    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (SELECT L1.RetDate, SUM(L1.InQty) InQty    
                         FROM #GetInQty AS L1    
                        GROUP BY L1.RetDate)    AS B ON A.RetDate = B.RetDate    
              
              
          --입고 관련 업체 정보 등록    
          UPDATE #_TSEChemicalsWkListCHE    
             SET InCustSeq   =  B.InCustCd,    
                 InCustName  =  B.CustName,    
                 InOwner     =  B.Owner,    
                 InBizNo     =  B.BizNo,    
                 InBizAddr   =  B.BizAddr,    
                 InTelNo     =  B.TelNo    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (   SELECT A.InCustCd ,    
                                 A.CustName ,    
                                 A.Owner    ,    
                                 A.BizNo    ,    
                                 A.BizAddr  ,    
                                 A.TelNo    ,    
                                 RANK() OVER (ORDER BY A.InCustCd) Seq    
                            FROM (SELECT DISTINCT     
                                         A.InCustCd ,    
                                         B.CustName ,    
                                         B.Owner    ,    
                                         B.BizNo    ,    
                                         B.BizAddr  ,    
                                         B.TelNo    
                                    FROM #GetInQty     AS A    
                                         JOIN _TDACust AS B ON A.InCustCd = B.CustSeq    
                            WHERE B.CompanySeq = @CompanySeq) AS A ) AS B ON A.Seq = B.Seq    
                
      END    
          
      IF EXISTS (SELECT 1 FROM #GetOutQty)        
      BEGIN              
          --출고 수량 등록    
          UPDATE #_TSEChemicalsWkListCHE    
             SET OutQty = B.OutQty    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (SELECT L1.RetDate, SUM(L1.OutQty) OutQty    
                         FROM #GetOutQty AS L1    
                        GROUP BY L1.RetDate)    AS B ON A.RetDate = B.RetDate     
                            
          --출고 관련 업체 정보 등록    
          UPDATE #_TSEChemicalsWkListCHE    
             SET OutCustSeq   =  B.OutCustCd,    
                 OutCustName  =  B.CustName,    
                 OutOwner     =  B.Owner,    
                 OutBizNo     =  B.BizNo,    
                 OutBizAddr   =  B.BizAddr,    
                 OutTelNo     =  B.TelNo    
            FROM #_TSEChemicalsWkListCHE AS A    
                 JOIN (   SELECT A.OutCustCd ,    
                                 A.CustName ,    
                                   A.Owner    ,    
                                 A.BizNo    ,    
                                 A.BizAddr  ,    
                                 A.TelNo    ,    
                                 RANK() OVER (ORDER BY A.OutCustCd) Seq    
                            FROM (SELECT DISTINCT     
                                         A.OutCustCd ,    
                                         B.CustName ,    
                                         B.Owner    ,    
                                         B.BizNo    ,    
                                         B.BizAddr  ,    
                                         B.TelNo    
                                    FROM #GeTOutQty     AS A    
                                         JOIN _TDACust AS B ON A.OutCustCd = B.CustSeq    
                                   WHERE B.CompanySeq = @CompanySeq) AS A ) AS B ON A.Seq = B.Seq                                             
      END    
          
   
     IF @WorkingTag = 'P'  
     BEGIN  
         --출력 물용 수정내용    
         --작업구분 등록 출력용    
         IF @InWkType > 0 --구입내역존재시    
         BEGIN    
              --작업구분 '' 처리    
              UPDATE #_TSEChemicalsWkListCHE    
             SET InWkType      = @InWkType      ,    
                     InWkTypeName  = (CASE WHEN  @InWkType > 0 AND Seq =1 THEN @InWkTypeName ELSE '"' END)    
                         
              --입고업체 관련 정보 '' 처리           
              IF EXISTS (SELECT 1 FROM #_TSEChemicalsWkListCHE WHERE Seq =1 AND InCustSeq > 0)    
              BEGIN    
                  UPDATE #_TSEChemicalsWkListCHE    
                     SET InCustName   = '"', -- 입고상호명             
                         InOwner      = '"', -- 입고대표자성명         
                    InBizNo      = '"', -- 입고사업자등록번호     
                         InBizAddr    = '"', -- 입고상호주소           
                         InTelNo      = '"'  -- 입고상호전화번호       
                   WHERE ISNULL(InCustSeq,0) = 0    
              END            
         END    
   
         IF @OutWkType > 0 --출고내역 존재시    
         BEGIN    
              --작업구분 '' 처리    
              UPDATE #_TSEChemicalsWkListCHE    
                 SET OutWkType     = @OutWkType     ,    
                     OutWkTypeName = (CASE WHEN  @OutWkType > 0 AND Seq =1 THEN @OutWkTypeName ELSE '"' END)            
                     
              --출고업체 관련 정보 '' 처리           
              IF EXISTS (SELECT 1 FROM #_TSEChemicalsWkListCHE WHERE Seq =1 AND OutCustSeq > 0)    
              BEGIN    
                  UPDATE #_TSEChemicalsWkListCHE    
                     SET OutCustName = '"', -- 출고상호명             
                         OutOwner    = '"', -- 입고대표자성명         
                         OutBizNo    = '"', -- 출고사업자등록번호     
                         OutBizAddr  = '"', -- 출고상호주소           
                         OutTelNo    = '"'  -- 출고상호전화번호      
                   WHERE ISNULL(OutCustSeq,0) = 0    
                END                  
         END  
   
   
         SELECT Seq           ,      
                SubString(RetDate,1,4) RetYear,    
                SubString(RetDate,5,2)+'/'+CONVERT(VARCHAR(2),CONVERT(INT,SubString(RetDate,7,2)),112)  AS RetDate, -- 년월일      
                @InOutWkType  AS InOutWkType,           
                ItemSeq       , -- 품명코드         
                PrintName     , -- 품명(출력명)     
                ItemNo        , -- 품번             
                ToxicName     , -- 유독품명         
                MainPurpose   , -- 주요용도         
                Content       , -- 함량             
                UnitSeq       , -- 단위코드         
                UnitName      , -- 단위                
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE PreQty END AS PreQty, -- 이월량(하이드록실아민포스페이트(용융락탐)의 경우 이월량 표시 안함)  
                InWkType      , -- 입고구분코드          
                InWkTypeName  , -- 입고구분              
                InQty         , -- 입고수량              
                InCustSeq     , -- 입고상호코드          
                InCustName    , -- 입고상호명            
                InOwner       , -- 입고대표자성명        
                InBizNo       , -- 입고사업자등록번호    
                InBizAddr     , -- 입고상호주소          
                InTelNo       , -- 입고상호전화번호      
                OutWkType     , -- 출고구분코드          
                OutWkTypeName , -- 출고구분              
                CASE WHEN @ChmcSeq = 9 THEN InQty ELSE OutQty END AS OutQty, -- 출고수량(하이드록실아민포스페이트(용융락탐)의 경우 입고량=출고량 같게 표시)          
                OutCustSeq    , -- 출고상호코드          
                OutCustName   , -- 출고상호명            
                OutOwner      , -- 입고대표자성명        
                OutBizNo      , -- 출고사업자등록번호    
                OutBizAddr    , -- 출고상호주소          
                OutTelNo      , -- 출고상호전화번호      
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE StockQty END AS StockQty, -- 재고량(하이드록실아민포스페이트(용융락탐)의 경우 재고량 표시 안함)  
                ReMark        , -- 비고    
                InPutDesc     , -- 구입내역의 마킹    
                OutPutDesc      -- 출고내역의 마킹    
           FROM #_TSEChemicalsWkListCHE  
          WHERE @InWkType > 0 OR @OutWkType > 0  
     END  
     ELSE  
     BEGIN  
         --DataBlock1    
         SELECT Seq           ,  
                RetDate       ,  
                ItemSeq       ,  
                PrintName     ,  
                ItemNo        ,  
                ToxicName     ,  
                MainPurpose   ,  
                Content       ,  
                UnitSeq       ,  
                UnitName      ,  
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE PreQty END AS PreQty, -- 이월량(하이드록실아민포스페이트(용융락탐)의 경우 이월량 표시 안함)  
                InWkType      ,  
                InWkTypeName  ,  
                InQty         ,  
                InCustSeq     ,  
                InCustName    ,  
                InOwner       ,  
                InBizNo       ,  
                InBizAddr     ,  
                InTelNo       ,  
                OutWkType     ,  
                OutWkTypeName ,  
                CASE WHEN @ChmcSeq = 9 THEN InQty ELSE OutQty END AS OutQty, -- 출고수량(하이드록실아민포스페이트(용융락탐)의 경우 입고량=출고량 같게 표시)          
                OutCustSeq    ,  
                OutCustName   ,  
                OutOwner      ,  
                OutBizNo      ,  
                OutBizAddr    ,  
                OutTelNo      ,  
                CASE WHEN @ChmcSeq = 9 THEN 0 ELSE StockQty END AS StockQty, -- 재고량(하이드록실아민포스페이트(용융락탐)의 경우 재고량 표시 안함)  
                ReMark        ,  
                InPutDesc     ,  
                OutPutDesc      
           FROM #_TSEChemicalsWkListCHE  
          WHERE @InWkType > 0 OR @OutWkType > 0  
   
         --DataBlock2    
         SELECT A.InCustCd  AS InCustSeq ,    
                A.CustName  AS InCustName,    
                A.Owner     AS InOwner   ,    
                A.BizNo     AS InBizNo   ,    
                A.BizAddr   AS InBizAddr ,    
                A.TelNo     AS InTelNo   ,    
                RANK() OVER (ORDER BY A.InCustCd) Seq    
           FROM (SELECT DISTINCT     
                          A.InCustCd ,    
                        B.CustName ,    
                        B.Owner    ,    
                        B.BizNo    ,    
                        B.BizAddr  ,    
                        B.TelNo    
                   FROM #GetInQty     AS A    
                        JOIN _TDACust AS B ON A.InCustCd = B.CustSeq    
                  WHERE B.CompanySeq = @CompanySeq) AS A    
          WHERE @InWkType > 0 OR @OutWkType > 0  
   
         --DataBlock3    
         SELECT A.OutCustCd AS OutCustSeq ,    
                A.CustName  AS OutCustName,    
                A.Owner     AS OutOwner   ,    
                A.BizNo     AS OutBizNo   ,    
                A.BizAddr   AS OutBizAddr ,    
                A.TelNo     AS OutTelNo   ,       
                RANK() OVER (ORDER BY A.OutCustCd) Seq    
           FROM (SELECT DISTINCT     
                        A.OutCustCd ,    
                        B.CustName ,    
                        B.Owner    ,    
                        B.BizNo    ,    
                        B.BizAddr  ,    
                        B.TelNo    
                   FROM #GeTOutQty     AS A    
                   LEFT OUTER JOIN _TDACust AS B ON B.CompanySeq = @CompanySeq AND A.OutCustCd = B.CustSeq    
                  WHERE B.CompanySeq = @CompanySeq) AS A  
          WHERE @InWkType > 0 OR @OutWkType > 0  
     END  
   
     RETURN