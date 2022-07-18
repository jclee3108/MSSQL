IF OBJECT_ID('KPXCM_SPDMMGetItemNeedQty') IS NOT NULL 
    DROP PROC KPXCM_SPDMMGetItemNeedQty
GO 

-- v2015.09.16 

-- 자재소요조회 시 반제품 Batch Size Formula 적용 by이재천 

/************************************************************
 설  명 - 소요자재구하기
 작성일 - 2008년 12월 19일
 작성자 - 정동혁
 수정일 - 2010년 04월 24일 UPDATEd BY 박소연 :: 임시테이블 인덱스 생성
 수정일 - 2010년 05월 06일 김현 / SMDelvType 6032003 인 것은 소요량 구하는 부분에서 뺀다 (BOM전개상세)
 수정일 = 2010년 06월 11일 정동혁 : 환경설정에  BOM전개상세품 MRP포함여부 추가
                                  : BOM전개상세는 자재불출 및 투입되는 품목이 아니지만 부방테크론 처럼 외주품을 구매로 처리하고 해당외주품의 사급자재도 함께 MRP를 풀어야 하는 경우도 있어서 추가.
 수정일 - 2010년 08월 09일 김일주 : 배합비(_TPDBOMBatchItem) 테이블에 overage 있는 경우 overage반영하여 출고요청수량 산출
                                  : 작업지시수량과 배합비(_TPDBOMBatchItem) 테이블에 배치사이즈와 수량이 다른 경우 둘 사이의 관계 고려하여 출고요청수량 산출
           2011년 10월 07일 김세호 : BOM단위로 환산후 소요량 구하도록 수정(제품별공정별소요자재등록  BOM단위 사용으로 변경되어어서)
          2015년  2월 27일 임희진 : 1. 제품별공정으로부터 자재소요구할 때, 공정이 있는 경우에서 소요량분모*공정품 소요량(분자)*공정품 소요량(분모) 계산식 수정
                                     (에스텍 파마 201502260421에서 산술 오버 플로우 오류 발생)
    
      CREATE TABLE #MatNeed_GoodItem
     (
         IDX_NO          INT IDENTITY(1,1),
         ItemSeq         INT,        -- 제품코드
         ProcRev         NCHAR(2),   -- 공정흐름차수
         BOMRev          NCHAR(2),   -- BOM차수
         ProcSeq         INT,        -- 공정코드
         AssyItemSeq     INT,        -- 공정품코드
         UnitSeq         INT,        -- 단위코드     (공정품코드가 있으면 공정품단위코드, 없으면 제품단위코드)
         Qty             DECIMAL,    -- 제품수량     (공정품코드가 있으면 공정품수량)
         ProdPlanSeq     INT,        -- 생산계획내부번호 (생산의뢰에서 추가된 옵션자재를 가져오기위해)
         WorkOrderSeq    INT,        -- 작업지시내부번호 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)
         WorkOrderSerl   INT,        -- 작업지시내부순번 (작업지시에서 추가자재로 등록된 자재를 가져오기위해)
         IsOut           NCHAR(1)    -- 로스율 적용에 사용 '1'이면 OutLossRate 적용
     )
      CREATE TABLE #MatNeed_MatItem_Result
     (
         IDX_NO          INT,            -- 제품코드
         MatItemSeq      INT,            -- 자재코드
         UnitSeq         INT,            -- 자재단위
         NeedQty         DECIMAL(19,5),  -- 소요량
         InputType       INT
     )
      --
  ************************************************************/
 CREATE PROC KPXCM_SPDMMGetItemNeedQty    
     @CompanySeq     INT = 1            ,    
     @SMDelvType     NCHAR(1) = '0'     ,    
     @IsMRP          NCHAR(1) = '0'      --MRP에서 소요자재를 구하는지 여부(BOM전개상세품 MRP포함여부 때문에추가)    
 AS    
     
     
     CREATE TABLE #MatNeed_MatItem    
     (    
         IDX_NO          INT,            -- 제품코드    
         MatItemSeq      INT,            -- 자재코드    
         UnitSeq         INT,            -- 자재단위    
         MatUnitSeq      INT,            -- 사용단위    
         NeedQty         DECIMAL(19,5),  -- 소요량    
         InputType       INT,    
         SMDelvType      INT    
     )    
     
     CREATE TABLE #TMP_SOURCETABLE    
     (    
         IDOrder INT,    
         TABLENAME   NVARCHAR(100)    
     )    
     
     CREATE TABLE #TCOMSourceTracking    
     (    
         IDX_NO      INT,    
         IDOrder     INT,    
         Seq         INT,    
         Serl        INT,    
         SubSerl     INT,    
         Qty         DECIMAL(19, 5),    
         STDQty      DECIMAL(19, 5),    
         Amt         DECIMAL(19, 5),    
         VAT         DECIMAL(19, 5)    
     )    
     
     
     DECLARE  @EnvValue   NVARCHAR(100)   -- BOM전개상세품 MRP포함여부    
             ,@IsInclude  NCHAR(1)    
     EXEC dbo._SCOMEnv @CompanySeq,6227  ,1,@@PROCID,@EnvValue OUTPUT    
     
     IF @IsMRP = '1' AND @EnvValue IN ('1','True')    
         SELECT @IsInclude = '1'    
     ELSE    
         SELECT @IsInclude = '0'    
     
     
     DECLARE @ProdModuleSeq    INT,    
             @BOMModuleSeq     INT    
     SELECT  @ProdModuleSeq = 1003003,    -- 생산단위 구분 코드    
             @BOMModuleSeq  = 1003004    -- BOM단위 구분 코드    
     
     IF EXISTS(SELECT 1 FROM #MatNeed_GoodItem WHERE ProdPlanSeq > 0)    
     BEGIN    
     
         INSERT #TMP_SOURCETABLE    
         SELECT 1,'_TPDMPSProdReqItem'    
         UNION    
         SELECT 2,'_TSLOrderItem'    
     
     
     
 EXEC _SCOMSourceTracking @CompanySeq, '_TPDMPSDailyProdPlan', '#MatNeed_GoodItem', 'ProdPlanSeq', '', ''    
     
   END    
     
     
 -- CREATE INDEX IX_#MatNeed_GoodItem ON #MatNeed_GoodItem (IDX_NO) -- 20100424 박소연 추가    
     
     
     -- 제품단위가 BOM단위와 다른경우    
     -- BOM단위로 환산 한다.    
     UPDATE #MatNeed_GoodItem      
        SET Qty = CASE WHEN US.ConvDen * UP.ConvNum * UP.ConvDen <> 0 THEN A.Qty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)      
                                                                 ELSE A.Qty      
                  END      
       FROM #MatNeed_GoodItem    AS A      
         JOIN _TDAItemDefUnit    AS B WITH(NOLOCK)  ON A.ItemSeq = B.ItemSeq      
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.ItemSeq = US.ItemSeq      
                                                    AND B.CompanySeq = US.CompanySeq      
                                                    AND A.UnitSeq = US.UnitSeq      
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.ItemSeq = UP.ItemSeq      
                                                    AND B.CompanySeq = UP.CompanySeq      
                                                    AND B.STDUnitSeq = UP.UnitSeq      
      WHERE A.AssyItemSeq = 0      
        AND B.CompanySeq = @CompanySeq      
        AND B.UMModuleSeq = @BOMModuleSeq      
        AND A.UnitSeq <> B.STDUnitSeq      
     
     
     
     -- 공정품 코드가 있는 경우    
     UPDATE #MatNeed_GoodItem      
        SET Qty = CASE WHEN US.ConvDen * UP.ConvNum * UP.ConvDen <> 0 THEN A.Qty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)      
                                                                      ELSE A.Qty      
                  END      
       FROM #MatNeed_GoodItem    AS A      
         JOIN _TDAItemDefUnit    AS B  WITH(NOLOCK)  ON A.AssyItemSeq = B.ItemSeq      
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.AssyItemSeq = US.ItemSeq      
                                                    AND B.CompanySeq = US.CompanySeq      
                                                    AND A.UnitSeq = US.UnitSeq      
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.AssyItemSeq = UP.ItemSeq      
                                                    AND B.CompanySeq = UP.CompanySeq      
                                                    AND B.STDUnitSeq = UP.UnitSeq      
      WHERE A.AssyItemSeq <> 0      
        AND B.CompanySeq = @CompanySeq      
        AND B.UMModuleSeq = @BOMModuleSeq      
        AND A.UnitSeq <> B.STDUnitSeq      
     
     
     
     -- 1. 제품별공정으로부터 자재소요구하기    
     -- 제품전체인 경우    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator) ELSE 1 END    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
             ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- 무상사급    
                                 WHEN 6032005    THEN 6042004    -- 사용후정산    
                                 ELSE                 6042002    -- 정상    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
                    JOIN _TPDROUItemProcMat      AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                   AND A.ProcRev     = M.ProcRev    
                                                                   AND A.BOMRev      = M.BOMRev    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                   AND M.MatItemSeq  = U.ItemSeq    
           AND U.UMModuleSeq = @ProdModuleSeq    
      WHERE A.ProcSeq = 0    
        AND M.CompanySeq = @CompanySeq    
     
     
     
     --  공정이 있는 경우    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
               --,CASE WHEN M.NeedQtyDenominator*M.AssyQtyNumerator*M.AssyQtyDenominator <> 0 THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator)))) -- 소수점이 너무 많아서 짤릴 우려가 있어 소수점 5자리로 수정    
             , CASE WHEN(M.NeedQtyDenominator <> 0 AND M.AssyQtyNumerator <> 0 AND M.AssyQtyDenominator <> 0) THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))           --case when 조건 수정 2015.02.27 hjlim
                    WHEN M.NeedQtyDenominator <> 0                                                            THEN A.Qty * (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                    ELSE A.Qty * 1 END   -- A.Qty가 공정품의 수량이면 공정소요량으로 나눠줘야한다.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
             ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- 무상사급    
                                 WHEN 6032005    THEN 6042004    -- 사용후정산    
                                 ELSE                 6042002    -- 정상    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
                    JOIN _TPDROUItemProcMat      AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                   AND A.ProcRev     = M.ProcRev    
                                                                   AND A.BOMRev      = M.BOMRev    
                                                                   AND A.ProcSeq     = M.ProcSeq    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                   AND M.MatItemSeq  = U.ItemSeq    
                                                                   AND U.UMModuleSeq = @ProdModuleSeq    
      WHERE A.ProcSeq > 0    
        AND M.CompanySeq = @CompanySeq    
            
     -- 생산계획별 공정별 소요자재에 따른 소요량 가져오기 추가 2011-01-03 송기연 추가    
                
     IF EXISTS (SELECT * FROM sysobjects where name = '_TPDMPSProdPlanProcMat')    
     BEGIN       
         UPDATE #MatNeed_GoodItem    
            SET ProdPlanSeq = B.ProdPlanSeq    
           FROM #MatNeed_GoodItem AS A JOIN _TPDSFCWorkOrder AS B ON A.WorkOrderSerl = B.WorkOrderSerl and B.CompanySeq = @CompanySeq    
          WHERE ISNULL(A.ProdPlanSeq,0) = 0    
          
          
         IF EXISTS(SELECT 1 FROM _TPDMPSProdPlanProcMat AS A JOIN #MatNeed_GoodItem AS B ON A.ProdPlanSeq = B.ProdPlanSeq AND A.CompanySeq = @CompanySeq)    
         BEGIN    
             DELETE #MatNeed_MatItem FROM #MatNeed_MatItem As A JOIN #MatNeed_GoodItem AS B ON A.IDX_NO = B.IDX_NO    
                                                                JOIN _TPDMPSProdPlanProcMat AS C On B.ProdPlanSeq = C.ProdPlanSeq AND C.CompanySeq = @CompanySeq    
                                                                    
                                                                                
             INSERT  #MatNeed_MatItem    
             SELECT   A.IDX_NO    
                     ,M.MatItemSeq    
                     ,M.UnitSeq    
                     ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
                     ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator) ELSE 1 END    
                             * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- 무상사급    
                                         WHEN 6032005    THEN 6042004    -- 사용후정산    
                                         ELSE                  6042002    -- 정상    
                      END    
                     ,M.SMDelvType    
               FROM #MatNeed_GoodItem                    AS A    
                            JOIN _TPDMPSProdPlanProcMat  AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                           AND A.ProcRev     = M.ProcRev    
                                                                           AND A.BOMRev      = M.BOMRev    
                                                                           AND A.ProdPlanSeq = M.ProdPlanSeq    
     LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                           AND M.MatItemSeq  = U.ItemSeq    
                                                                           AND U.UMModuleSeq = @ProdModuleSeq    
              WHERE A.ProcSeq = 0    
                AND M.CompanySeq = @CompanySeq    
     
     
     
             --  공정이 있는 경우    
             INSERT  #MatNeed_MatItem    
             SELECT   A.IDX_NO    
                     ,M.MatItemSeq    
                     ,M.UnitSeq    
                     ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
                     --,CASE WHEN M.NeedQtyDenominator*M.AssyQtyNumerator*M.AssyQtyDenominator <> 0 THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))     
                     ,CASE WHEN(M.NeedQtyDenominator <> 0 AND M.AssyQtyNumerator <> 0 AND M.AssyQtyDenominator <> 0) THEN CONVERT(DECIMAL(19,5), A.Qty * (CONVERT(DECIMAL(19,10),(M.NeedQtyNumerator / M.NeedQtyDenominator)) / CONVERT(DECIMAL(19,10), (M.AssyQtyNumerator / M.AssyQtyDenominator))))           --case when 조건 수정 2015.02.27 hjlim
                           WHEN M.NeedQtyDenominator <> 0                                         THEN A.Qty * (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                           ELSE A.Qty * 1 END   -- A.Qty가 공정품의 수량이면 공정소요량으로 나눠줘야한다.    
                             * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     ,CASE M.SMDelvType  WHEN 6032004    THEN 6042003    -- 무상사급    
                                         WHEN 6032005    THEN 6042004    -- 사용후정산    
                                         ELSE                 6042002    -- 정상    
                      END    
                     ,M.SMDelvType    
               FROM #MatNeed_GoodItem                    AS A    
                            JOIN _TPDMPSProdPlanProcMat  AS M  WITH(NOLOCK) ON A.ItemSeq     = M.ItemSeq    
                                                                           AND A.ProcRev     = M.ProcRev    
                                                                           AND A.BOMRev      = M.BOMRev    
                                                                           AND A.ProcSeq     = M.ProcSeq    
                                                                           AND A.ProdPlanSeq = M.ProdPlanSeq    
                 LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq  = U.CompanySeq    
                                                                           AND M.MatItemSeq  = U.ItemSeq    
                                                                           AND U.UMModuleSeq = @ProdModuleSeq    
              WHERE A.ProcSeq > 0    
                AND M.CompanySeq = @CompanySeq    
         END          
     END             
     
     
     -- 2. 생산의뢰에서 추가된 자재(옵션자재)      -->> 생산계획에서 확정시 작업지시번호와 순번이 입력됨.    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator)     
                            ELSE 1    
                       END   -- A.Qty가 공정품의 수량이면 공정소요량으로 나눠줘야한다.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100) ELSE (1 + M.InLossRate / 100) END    
                     * CASE M.SMAddType WHEN 6048002 THEN -1    
                                        ELSE 1    
                       END    
             ,CASE  --WHEN M.ReqType = '1'        THEN 6042005    -- 개별옵션    
                    WHEN M.SMDelvType = 6032004 THEN 6042003    -- 무상사급    
                    WHEN M.SMDelvType = 6032005 THEN 6042004    -- 사용후정산    
                    ELSE                             6042002    -- 정상    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A    
 --                   JOIN _TPDMPSDailyProdPlan    AS P  WITH(NOLOCK) ON A.ProdPlanSeq   = P.ProdPlanSeq    
                    JOIN #TCOMSourceTracking     AS T               ON A.IDX_NO        = T.IDX_NO    
                      JOIN _TPDROUItemProcMatAdd   AS M  WITH(NOLOCK) ON T.Seq           = M.ProdReqSeq    
                                                                   AND T.Serl          = M.ProdReqSerl    
                                                                   AND (A.ProcSeq = 0 OR  A.ProcSeq = M.ProcSeq)    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq    = U.CompanySeq    
                                                                   AND M.MatItemSeq    = U.ItemSeq    
                                                                   AND U.UMModuleSeq   = @ProdModuleSeq    
        WHERE A.ProdPlanSeq > 0    
        AND M.CompanySeq = @CompanySeq    
        AND (M.WorkOrderSeq = 0 OR M.WorkOrderSeq IS NULL)    
        AND T.IDOrder = 1    
     
     
     
     --UPDATE A    
     --   SET InputType = 6042005    
     --  FROM #MatNeed_MatItem             AS A    
     --    JOIN #TCOMSourceTracking        AS T                ON A.IDX_NO         = T.IDX_NO    
     --    JOIN _TSLOrderItemSpecOption    AS S WITH(NOLOCK)   ON T.Seq            = S.OrderSeq    
     --                                                       AND T.Serl           = S.OrderSerl    
     --    JOIN _TSLOption                 AS P WITH(NOLOCK)   ON S.OptionSeq      = P.OptionSeq    
     -- WHERE T.IDOrder = 2    
     --   AND S.CompanySeq = @CompanySeq    
     --   AND P.CompanySeq = @CompanySeq    
     --   AND P.SMOptionKind = 8020002    
     
     
     --3. 작업지시의 추가자재가 있는 경우    
     INSERT  #MatNeed_MatItem    
     SELECT   A.IDX_NO    
             ,M.MatItemSeq    
             ,M.UnitSeq    
             ,ISNULL(U.STDUnitSeq,M.UnitSeq)    
             ,A.Qty  * CASE WHEN M.NeedQtyNumerator * M.NeedQtyDenominator <> 0 THEN (M.NeedQtyNumerator / M.NeedQtyDenominator)    
                            ELSE 1    
                       END   -- A.Qty가 공정품의 수량이면 공정소요량으로 나눠줘야한다.    
                     * CASE WHEN A.IsOut = '1' THEN (1 + M.OutLossRate / 100.0) ELSE (1 + M.InLossRate / 100.0) END    
                     * CASE M.SMAddType WHEN 6048002 THEN -1    
                                        ELSE 1    
                       END    
             ,CASE  --WHEN M.ReqType = '1'        THEN 6042005    -- 개별옵션    
                    WHEN M.SMDelvType = 6032004 THEN 6042003    -- 무상사급    
                    WHEN M.SMDelvType = 6032005 THEN 6042004    -- 사용후정산    
                    ELSE                             6042002    -- 정상    
              END    
             ,M.SMDelvType    
       FROM #MatNeed_GoodItem                    AS A   
                    JOIN _TPDROUItemProcMatAdd   AS M  WITH(NOLOCK) ON A.WorkOrderSeq  = M.WorkOrderSeq    
                                                                   AND A.WorkOrderSerl = M.WorkOrderSerl    
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON M.CompanySeq    = U.CompanySeq    
                                                                   AND M.MatItemSeq    = U.ItemSeq    
                                                                   AND U.UMModuleSeq   = @ProdModuleSeq    
      WHERE A.WorkOrderSeq > 0    
        AND M.CompanySeq = @CompanySeq    
     
  -- 생산옵션품의 투입 구분은 생산옵션으로 변경  위쪽은 주석 처리하고 위치 변경 2012. 5. 21 hkim    
     UPDATE A    
        SET InputType = 6042005    
       FROM #MatNeed_MatItem             AS A    
         JOIN #TCOMSourceTracking        AS T                ON A.IDX_NO         = T.IDX_NO    
         JOIN _TSLOrderItemSpecOption    AS S WITH(NOLOCK)   ON T.Seq            = S.OrderSeq    
                                                            AND T.Serl           = S.OrderSerl    
                                                            AND A.MatItemSeq  = S.ItemSeq  -- 2012. 5. 21 ItemSeq 추가 hkim    
         JOIN _TSLOption                 AS P WITH(NOLOCK)   ON S.OptionSeq      = P.OptionSeq    
      WHERE T.IDOrder = 2    
        AND S.CompanySeq = @CompanySeq    
        AND P.CompanySeq = @CompanySeq    
        AND P.SMOptionKind = 8020002    
     
     

    
    -- 배합비에 등록되어 있으면 제외 
    DELETE A
      FROM #MatNeed_MatItem					 AS A WITH(NOLOCK)  
      LEFT OUTER JOIN #MatNeed_GoodItem		 AS B WITH(NOLOCK) ON ( A.IDX_NO = B.IDX_NO ) 
      LEFT OUTER JOIN _TPDSFCWorkReport		 AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND B.WorkOrderSeq = W.WorkOrderSeq AND B.WorkOrderSerl = W.WorkOrderSerl ) 
                 JOIN KPXCM_TPDBOMBatch      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq 
                                                                AND C.FactUnit = W.FactUnit 
                                                                AND C.ItemSeq = W.GoodItemSeq 
                                                                AND W.WorkDate BETWEEN C.DateFr AND C.DateTo 
                                                                  ) 
    -- 배합비에 등록되어 있으면 제외, END 
    
    --1-2. 배합비에 들어 있는 경우 (2009.09.29 추가) 
    INSERT  #MatNeed_MatItem    
    SELECT A.IDX_NO    
           ,I.ItemSeq    
           ,I.InputUnitSeq    
           ,ISNULL(U.STDUnitSeq,I.InputUnitSeq)    
           ,CASE WHEN I.NeedQtyNumerator * I.NeedQtyDenominator <> 0 
                 THEN (
                          CASE WHEN I.Overage > 0 
                               THEN ((W.ProdQty/C.BatchSize) * (I.NeedQtyNumerator / I.NeedQtyDenominator) * I.Overage / 100) * (CASE WHEN UP.ConvDen = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),ISNULL(UP.ConvNum,1) / ISNULL(UP.ConvDen,1)) END)
                               ELSE (W.ProdQty/C.BatchSize) * (I.NeedQtyNumerator / I.NeedQtyDenominator) * (CASE WHEN UP.ConvDen = 0 THEN 0 ELSE CONVERT(DECIMAL(19,5),ISNULL(UP.ConvNum,1) / ISNULL(UP.ConvDen,1)) END)
                               END
                      )    
                  ELSE 1    
            END     
            ,CASE I.SMDelvType WHEN 6032004    THEN 6042003    -- 무상사급    
                               WHEN 6032005    THEN 6042004    -- 사용후정산    
                               ELSE 6042002    -- 정상    
             END
            ,I.SMDelvType    
      FROM #MatNeed_GoodItem                     AS A    
                    JOIN _TPDSFCWorkReport       AS W  WITH(NOLOCK) ON A.WorkOrderSeq= W.WorkOrderSeq    
                                                                   AND A.WorkOrderSerl = W.WorkOrderSerl    
                                                                   AND W.CompanySeq    = @CompanySeq 
                    JOIN KPXCM_TPDBOMBatch       AS C  WITH(NOLOCK) ON C.CompanySeq  = W.CompanySeq
																   AND C.FactUnit    = W.FactUnit    
                                                                   AND C.ItemSeq  = W.AssyItemSeq 
                                                                   AND W.WorkDate BETWEEN C.DateFr AND C.DateTo 
                    JOIN KPXCM_TPDBOMBatchItem   AS I  WITH(NOLOCK) ON C.BatchSeq    = I.BatchSeq    
                                                                   AND C.CompanySeq  = I.CompanySeq    
                                                                   AND (ISNULL(I.ProcSeq, 0) = 0  OR W.ProcSeq  = I.ProcSeq) 
                                                                   AND W.WorkDate BETWEEN I.DateFr AND I.DateTo 
         LEFT OUTER JOIN _TDAItemDefUnit         AS U  WITH(NOLOCK) ON I.CompanySeq  = U.CompanySeq    
                                                                   AND I.ItemSeq     = U.ItemSeq    
                                                                   AND U.UMModuleSeq = @ProdModuleSeq 
         LEFT OUTER JOIN _TDAItemUnit			 AS UP WITH(NOLOCK) ON UP.CompanySeq  = I.CompanySeq	
																   AND UP.UnitSeq = I.InputUnitSeq		
                                                                   AND UP.ItemSeq = A.ItemSeq			
    
      CREATE INDEX IDX_MatNeed_MatItem1 ON #MatNeed_MatItem(MatItemSeq,UnitSeq )
      CREATE INDEX IDX_MatNeed_MatItem2 ON #MatNeed_MatItem(MatItemSeq,MatUnitSeq )
     
     -- 4. 생산단위와 등록된 자재단위가 다른 경우 단위환산을 해야한다.    
     UPDATE #MatNeed_MatItem    
        SET NeedQty = A.NeedQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen)    
       FROM #MatNeed_MatItem     AS A    
         JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON A.MatItemSeq = US.ItemSeq    
                                                    AND A.UnitSeq    = US.UnitSeq    
         JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON A.MatItemSeq = UP.ItemSeq    
                                                    AND A.MatUnitSeq = UP.UnitSeq    
    WHERE A.UnitSeq <> A.MatUnitSeq    
        AND US.CompanySeq = @CompanySeq    
        AND UP.CompanySeq = @CompanySeq    
        AND US.ConvDen <> 0    
        AND UP.ConvNum <> 0    
        AND UP.ConvDen <> 0    
     
     
     DECLARE @Dec        INT    
     
     
     -- 환경설정값 가져오기 (소수점 자리수 5)    
     EXEC dbo._SCOMEnv @CompanySeq,5,0,@@PROCID,@EnvValue OUTPUT -- 소수점자리수가 환경설정의 BOM 자리수를 가지고 와야해서 5에서 4로 바꿈  -- 4에서 5로 다시 바꿈 2012. 1. 9 hkim    
     
     SELECT @Dec = ISNULL(@EnvValue, 0) 
     
     CREATE INDEX IDX_MatNeed_MatItem3 ON #MatNeed_MatItem(MatUnitSeq)
     
     -- 5 품목별 집계    
     IF @SMDelvType = '1'    
     BEGIN    
         INSERT #MatNeed_MatItem_Result    
         SELECT IDX_NO, MatItemSeq, MatUnitSeq,    
                CASE WHEN B.SMDecPointSeq IN (1003001, 0) THEN ROUND(SUM(NeedQty), @Dec, 0)   -- 반올림    
                     WHEN B.SMDecPointSeq = 1003002 THEN ROUND(SUM(NeedQty), @Dec, -1)         -- 절사    
                     WHEN B.SMDecPointSeq = 1003003 THEN ROUND(SUM(NeedQty) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@Dec + 1)),@Dec, 0)       -- 올림    
                     ELSE ROUND(SUM(NeedQty), @Dec, 0)   -- 반올림    
     --                ELSE CEILING(SUM(NeedQty) * POWER(10,@Dec)) / POWER(10,@Dec)    -- 디폴트 : 소수점이하에서 올림.    
                END  ,    
                InputType     
                  --MAX(SMDelvType)  -- 추가재자입력시에는 이 데이터가 없다 그러므로 MAX값으로 처리한다. -- 2010. 12. 30 hkim 타 SP에서 호출시 오류 발생    
           FROM #MatNeed_MatItem     AS A    
             JOIN _TDAUnit           AS B ON A.MatUnitSeq = B.UnitSeq    
                                         AND B.CompanySeq = @CompanySeq    
       WHERE (@IsInclude = '1' OR A.SMDelvType <> 6032003)      -- 2010. 5. 6 김현 수정(BOM전개상세 제거)    
          GROUP BY IDX_NO, MatItemSeq, MatUnitSeq, InputType, B.SMDecPointSeq    
     END    
     ELSE    
     BEGIN    
         INSERT #MatNeed_MatItem_Result    
         SELECT IDX_NO, MatItemSeq, MatUnitSeq,    
                CASE WHEN B.SMDecPointSeq IN (1003001, 0) THEN ROUND(SUM(NeedQty), @Dec, 0)   -- 반올림    
                     WHEN B.SMDecPointSeq = 1003002 THEN ROUND(SUM(NeedQty), @Dec, -1)         -- 절사    
                     WHEN B.SMDecPointSeq = 1003003 THEN ROUND(SUM(NeedQty) + CAST(4 AS DECIMAL(19, 5)) / POWER(10, (@Dec + 1)),@Dec, 0)        -- 올림    
                     ELSE ROUND(SUM(NeedQty), @Dec, 0)   -- 반올림    
     --                ELSE CEILING(SUM(NeedQty) * POWER(10,@Dec)) / POWER(10,@Dec)    -- 디폴트 : 소수점이하에서 올림.    
                END  ,    
                InputType     
                --MAX(SMDelvType)  -- 추가재자입력시에는 이 데이터가 없다 그러므로 MAX값으로 처리한다. -- 2010. 12. 30 hkim 타 SP에서 호출시 오류 발생    
           FROM #MatNeed_MatItem     AS A    
             JOIN _TDAUnit           AS B ON A.MatUnitSeq = B.UnitSeq    
                                         AND B.CompanySeq = @CompanySeq    
       WHERE (@IsInclude = '1' OR A.SMDelvType <> 6032003)      -- 2010. 5. 6 김현 수정(BOM전개상세 제거)    
          GROUP BY IDX_NO, MatItemSeq, MatUnitSeq, InputType, B.SMDecPointSeq    
     END    
     
   RETURN