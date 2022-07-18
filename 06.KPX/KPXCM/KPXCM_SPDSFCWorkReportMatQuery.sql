IF OBJECT_ID('KPXCM_SPDSFCWorkReportMatQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDSFCWorkReportMatQuery
GO 

-- v2015.09.16 

-- 자재소요조회하는 서브SP 대체서비스 by이재천 

/************************************************************      
 설  명 - 생산실적자재투입조회      
 작성일 - 2008년 10월 22일      
 작성자 - 정동혁      
 수정일 - 2010년 01월 25일 BY 박소연 :: 현재창고의 재고 가져오기 추가      
          2010년 01월 26일 BY 박소연 :: 출고자재가져오기에서 반품 수량 제외      
          2010년 12월 13일 BY SYPARK :: 출고자재가져오기에서 기투입수량 제외, 분할출고시 중복으로 조회되지않게 GROUP BY     
          2012년 01월 30일 BY 김세호 :: 수탁여부, 불출구분 조회 추가     
          2012년 02월 14일 BY SYPARK :: 이전공정가져올때 작업일은 현재실적의 작업일자로   
          2012년 05월 08일 BY 김세호 :: '출고자재가져오기' 시에도 현장재고 조회되도록 수정           
          2012년 05월 17일 BY 김세호 :: '소요자재조회' 시 수탁자재일경우 현장창고의 해당 수탁처 기능창고재고 조회되도록 
          2012년 05월 18일 BY 김세호 :: 전공정 양품수량 가져올때, 창고코드는 해당 실적의 현장 창고코드로 가져오도록 수정
          2012년 05월 30일 BY 김세호 :: 전공정 양품수량 가져올때, 공정코드는 해당 실적의 공정코드로 가져오도록 수정
          2012년 06월 05일 BY 김세호 :: 소요자재가져올때 내/외부 로스율 계산하기위해 IsOut 칼럼 가져가는데, 
                                        해당 워크센터가 '자체생산' 이면 '0'으로 가져가도록 (내부로스율로 계산되도록)
          2013년 10월 27일 BY 김권우 :: 생산 불출, 투입 단위 환경설정 값을 받아와서 환경설정값에 따라 생산단위orBOM단위로 수량 표기 되도록 수정
          2014년  7월 18일 BY 임희진 :: 창고명 추가
          2015년  2월 16일 BY 임희진 :: (출고자재가져오기) 기 투입수량 차감 시 조건에 단위, LotNo 추가
 ************************************************************/      
 CREATE PROC KPXCM_SPDSFCWorkReportMatQuery    
     @xmlDocument    NVARCHAR(MAX) ,      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10)= '',      
     @CompanySeq     INT = 1,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
       
 AS      
     
      DECLARE @docHandle      INT,        
             @WorkReportSeq  INT,        
             @FactUnit       INT,        
             @CurrDate       NCHAR(8),        
             @WorkDate       NCHAR(8),        
             @StkDate        NCHAR(8),      
             @WorkOrderSeq   INT     ,   -- 11.03.09 김세호 추가        
             @WorkOrderSerl  INT         -- 11.03.09 김세호 추가        
         
      SELECT @CurrDate = CONVERT(NCHAR(8),GETDATE(),112)        
         
         
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
         IsOut           NCHAR(1),   -- 로스율 적용에 사용 '1'이면 OutLossRate 적용        
         WorkReportSeq   INT        
     )        
         
     CREATE TABLE #MatNeed_MatItem_Result        
     (        
         IDX_NO          INT,            -- 제품코드        
         MatItemSeq      INT,            -- 자재코드        
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
         
     -- 20100125 박소연 추가        
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
         
    -- 20100125 박소연 추가        
    CREATE TABLE #GetInOutItem        
    (        
   ItemSeq    INT        
    )        
         
         
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
         
         
     SELECT  @WorkReportSeq   = ISNULL(WorkReportSeq    ,0),        
             @FactUnit        = ISNULL(FactUnit         ,0),   -- 20100125 박소연 추가       
             @WorkOrderSeq   = ISNULL(WorkOrderSeq    ,0),     -- 11.03.09 김세호 추가       
          @WorkOrderSerl   = ISNULL(WorkOrderSerl    ,0)    -- 11.03.09 김세호 추가      
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)        
       WITH (WorkReportSeq    INT,        
             FactUnit         INT,                             -- 20100125 박소연 추가       
             WorkOrderSeq     INT,                             -- 11.03.09 김세호 추가      
               WorkOrderSerl    INT)                              -- 11.03.09 김세호 추가      
         
         
     SELECT @WorkDate = LEFT(WorkDate,6)+'01' FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq        
         
 --★★ 환경설정 값(생산불출, 투입단위) 불러오기  
 DECLARE @BaseProdUnit INT  
 EXEC dbo._SCOMEnv @CompanySeq,6259,@UserSeq,@@PROCID,@BaseProdUnit OUTPUT   
       
 --    -- 생산일자 말일 기준으로 현장재고 가져오기 20100305 송기연        
 --    SELECT @StkDate = CONVERT(NCHAR(8),DATEADD(DD,-1, CONVERT(DATETIME, CONVERT(NCHAR(8),DATEADD(MM,1, CONVERT(DATETIME, @WorkDate)),112))),112)        
           
     -- 현재일자 기준으로 현장재고 가져오기 20100318 송기연 마이너스재고체크가 해당월의 말일자기준의 재고와 현재일기준의 재고를 모두 체크함        
     SELECT @StkDate = @CurrDate        
 --select @WorkDate, @StkDate        
     IF @WorkingTag IN ('','Q')        
         GOTO Qry_MatNeed        
     ELSE IF @WorkingTag = 'S'   -- 소요자재조회        
         GOTO Qry_MatNeed        
 ELSE IF @WorkingTag = 'G'   -- 출고자재가져오기        
         GOTO Qry_GetItem        
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_Proc:   -- 투입자재조회        
      
     DELETE  #GetInOutItem  -- 20100125 박소연 추가        
     DELETE  #GetInOutStock -- 20100125 박소연 추가        
         
     SELECT        
              A.WorkReportSeq        
             ,A.ItemSerl        
             ,A.InputDate        
             ,A.MatItemSeq        
             ,A.MatUnitSeq        
             ,N.NeedQty        
             ,CASE WHEN R.WorkType = 6041010 THEN ABS(A.Qty)        
       WHEN R.WorkType = 6041004 THEN ABS(A.Qty) ELSE A.Qty END AS Qty        
             ,CASE WHEN R.WorkType = 6041010 THEN ABS(A.StdUnitQty)        
       WHEN R.WorkType = 6041004 THEN ABS(A.StdUnitQty) ELSE A.StdUnitQty END AS StdUnitQty        
             ,A.RealLotNo        
             ,A.SerialNoFrom        
             ,A.ProcSeq        
             ,A.AssyYn        
             ,A.IsConsign        
             ,A.GoodItemSeq        
             ,A.InputType        
             ,A.IsPaid        
             ,A.IsPjt        
             ,A.PjtSeq        
             ,A.WBSSeq        
             ,A.Remark        
             ,I.ItemName         AS MatItemName        
             ,I.ItemNo           AS MatItemNo        
             ,I.Spec             AS MatItemSpec        
             ,U.UnitName         AS MatUnitName        
             ,W.FieldWHSeq       AS WHSeq  
             ,Z.AssetName  AS AssetName
             ,WH.WHName    AS WHName       --20140718 임희진 추가
       INTO  #TEM_MatinputInfo  -- 20100125 박소연 추가        
       FROM  _TPDSFCMatinput                AS A WITH(NOLOCK)        
         LEFT  OUTER JOIN _TDAItem           AS I WITH(NOLOCK) ON A.CompanySeq    = I.CompanySeq        
                                                             AND A.MatItemSeq    = I.ItemSeq        
         LEFT OUTER JOIN _TDAUnit           AS U WITH(NOLOCK) ON A.CompanySeq    = U.CompanySeq        
                                                   AND A.MatUnitSeq    = U.UnitSeq        
         LEFT OUTER JOIN #NeedMatSUM        AS N              ON A.MatItemSeq    = N.MatItemSeq  
                                                             --AND A.ProcSeq       = N.ProcSeq  
         LEFT OUTER JOIN _TPDSFCWorkReport  AS R WITH(NOLOCK) ON A.CompanySeq    = R.CompanySeq        
                                                             AND A.WorkReportSeq = R.WorkReportSeq        
         LEFT OUTER JOIN _TPDBaseWorkCenter AS W WITH(NOLOCK) ON R.CompanySeq    = W.CompanySeq        
                                                             AND R.WorkcenterSeq = W.WorkcenterSeq
         LEFT OUTER JOIN _TDAWH             AS WH WITH(NOLOCK) ON W.CompanySeq = WH.CompanySeq   
                                                             AND W.FieldWhSeq = WH.WHSeq               --20140718 임희진 추가                                             
         LEFT OUTER JOIN _TDAItemAsset    AS Z WITH(NOLOCK) ON I.CompanySeq    = Z.CompanySeq  
                AND I.AssetSeq      = Z.AssetSeq      
      WHERE  A.CompanySeq  = @CompanySeq        
        AND  A.WorkReportSeq   = @WorkReportSeq        
      ORDER BY N.BOMSerl, MatItemNo        
         
  ---현장창고 재고를 가져오기위해 Item담기 20100125 박소연 추가        
     INSERT INTO #GetInOutItem        
     SELECT MatItemSeq        
       FROM #TEM_MatinputInfo        
      GROUP BY MatItemSeq        
         
    /**************현장창고재고가져오기 20100125 박소연 추가**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- 법인코드        
            @BizUnit       = 0,           -- 사업부문        
            @FactUnit      = @FactUnit,   -- 생산사업장        
            @DateFr        = @StkDate,   -- 조회기간Fr        
            @DateTo        = @StkDate,   -- 조회기간To         
            @WHSeq         = 0,           -- 창고지정        
            @SMWHKind      = 0,           -- 창고구분별 조회        
            @CustSeq       = 0,           -- 수탁거래처        
            @IsSubDisplay  = '',          -- 기능창고 조회        
            @IsUnitQry      = '',          -- 단위별 조회        
            @QryType       = 'S'          -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고        
         
  /**************현장창고재고가져오기 끝**************************************************************/        
     
     SELECT   A.*        
             ,ISNULL(B.STDStockQty, 0) AS STDStockQty -- 20100125 박소연 추가        
             ,M.MinorName              AS SMOutKind   -- 12.01.30 김세호 추가     
             ,ISNULL(ST.IsLotMng,'')   AS IsLotMng  
       FROM #TEM_MatinputInfo AS A        
            LEFT OUTER JOIN #GetInOutStock  AS B  ON A.MatItemSeq = B.ItemSeq   
                                                 AND A.WHSeq      = B.WHSeq  -- 20100125 박소연 추가       
            LEFT OUTER JOIN _TDAItemProduct AS P  WITH(NOLOCK) ON @CompanySeq   = P.CompanySeq    
                                                               AND A.MatItemSeq = P.ItemSeq     
            LEFT OUTER JOIN _TDASMinor      AS M  WITH(NOLOCK) ON P.CompanySeq  = M.CompanySeq    
                                                               AND P.SMOutKind  = M.MinorSeq  
            LEFT OUTER JOIN _TDAItemStock   AS ST WITH(NOLOCK) ON @CompanySeq   = ST.CompanySeq  
                                                              AND A.MatItemSeq  = ST.ItemSeq              
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_MatNeed:   -- 소요자재조회        
   
     DECLARE @InputDate      NCHAR(8),        
 --            @WorkOrderSeq   INT,        
             @GoodItemSeq    INT,        
             @IsPjt          NCHAR(1),        
             @AssyYn         NCHAR(1),        
             @PjtSeq         INT,        
             @WBSSeq         INT,        
             @ExistsYn       NCHAR(1),        
             @FieldWHSeq     INT,
             @WHName         NVARCHAR(100)        
         
     SELECT  @WorkOrderSeq    = W.WorkOrderSeq        
            ,@GoodItemSeq     = W.GoodItemSeq        
            ,@InputDate       = W.WorkDate        
            ,@AssyYn          = CASE WHEN W.GoodItemSeq = W.AssyItemSeq THEN '0'        
                                       WHEN W.IsLastProc  = '1'            THEN '0'        
                                     ELSE '1'        
                                END      -- 공정품여부        
            ,@IsPjt           = W.IsPjt        
            ,@PjtSeq          = W.PjtSeq        
            ,@WBSSeq          = W.WBSSeq        
       FROM _TPDSFCWorkReport        AS W        
      WHERE W.CompanySeq  = @CompanySeq        
        AND W.WorkReportSeq = @WorkReportSeq        
         
     SELECT @ExistsYn = '1'        
       FROM _TPDSFCMatinput  WITH(NOLOCK)        
      WHERE CompanySeq  = @CompanySeq        
        AND WorkReportSeq = @WorkReportSeq        
         
     SELECT @ExistsYn  = ISNULL(@ExistsYn, '0')        
   
   
     -- 소요량계산 을 위한 품목담기.        
     INSERT #MatNeed_GoodItem (ItemSeq,ProcRev,BOMRev,ProcSeq,AssyItemSeq,UnitSeq,Qty,ProdPlanSeq,WorkOrderSeq,WorkOrderSerl,IsOut,WorkReportSeq)        
     SELECT W.GoodItemSeq, W.ProcRev, W.ItemBomRev, W.ProcSeq, W.AssyItemSeq, W.ProdUnitSeq,        
            --W.ProdQty * (CASE WHEN W.WorkType = 6041004 THEN (-1) ELSE 1 END),  -- 해체(재생)작업이면 (-),        
            W.ProdQty,   -- 양수로 조회되고 저장시에만 음수로 저장되게 하기 위해서 수정 2010. 7. 15 hkim        
            O.ProdPlanSeq, W.WorkOrderSeq, W.WorkOrderSerl,      -- ProdPlanSeq가 원래 0이었지만 작업지시의 ProdPlanSeq 가져오도록 수정 2012. 5. 21 hkim  
            CASE WHEN C.SMWorkCenterType = 6011003 THEN '1' ELSE '0' END , WorkReportSeq        
       FROM _TPDSFCWorkReport     AS W        
            JOIN _TPDBaseWorkCenter AS C ON W.CompanySeq    = C.CompanySeq        
                                        AND W.WorkCenterSeq = C.WorkCenterSeq      
      LEFT OUTER JOIN _TPDSFCWorkOrder AS O ON W.CompanySeq = O.CompanySeq   -- 생산옵션품 추적을 위해 추가 2012. 5. 21 hkim  
             AND W.WorkOrderSeq = O.WorkOrderSeq  
             AND W.WorkOrderSerl = O.WorkOrderSerl                                           
      WHERE W.CompanySeq    = @CompanySeq        
        AND W.WorkReportSeq = @WorkReportSeq        
         
     -- 소요자재 가져오기        
       EXEC KPXCM_SPDMMGetItemNeedQty @CompanySeq         
         
     
     -------------------------------        
     -- 소요량 집계 ----------------        
     INSERT #NeedMatSUM (ProcSeq,MatItemSeq,UnitSeq,NeedQty,InputQty,InputType, ItemSeq, BOMRev, AssyItemSeq,BOMSerl) -- 소요량        
     SELECT A.ProcSeq, B.MatItemSeq, B.UnitSeq, B.NeedQty, B.NeedQty, B.InputType, A.ItemSeq, A.BOMRev, A.AssyItemSeq, 9999        
       FROM #MatNeed_GoodItem            AS A        
            JOIN #MatNeed_MatItem_Result AS B ON A.IDX_NO = B.IDX_NO        
      
    DECLARE @BomLevel INT        
     SELECT @BomLevel = 1        
         
     SELECT ItemSeq, BOMRev, ItemSeq AS SubItemSeq, BOMRev AS SubBOMRev, @BomLevel AS BOMLevel, 0 AS UserSeq        
       INTO #BOM        
       FROM #NeedMatSUM        
   
   
   
     WHILE(1=1)        
     BEGIN        
         
         SELECT @BomLevel = @BomLevel + 1        
         
         INSERT #BOM        
         SELECT A.ItemSeq, A.ItemBomRev, A.SubItemSeq, A.SubItemBomRev, @BomLevel, A.UserSeq        
           FROM _TPDBOM     AS A        
                JOIN #BOM   AS B ON A.ItemSeq = B.SubItemSeq        
                                AND A.ItemBomRev  = B.SubBOMRev        
            WHERE A.CompanySeq = @CompanySeq        
            AND B.BOMLevel = @BomLevel - 1        
  
         IF @@ROWCOUNT = 0        
             BREAK        
         
     END        
     
      -- BOM순서표시        
     UPDATE A        
        SET BOMSerl = UserSeq        
       FROM #NeedMatSUM      AS A        
            JOIN #BOM        AS B WITH(NOLOCK) ON A.AssyItemSeq = B.ItemSeq        
                                              AND A.MatItemSeq  = B.SubItemSeq        
      WHERE B.UserSeq > 0        
         
     -----------------------------------        
     IF @WorkingTag IN ('','Q')        
         GOTO Qry_Proc        
     -----------------------------------        
       
         
     -- 기투입된 자재수량반영        
         
     UPDATE #NeedMatSUM        
        SET InputQty = A.InputQty - B.Qty        
         FROM #NeedMatSUM               AS A        
         JOIN (SELECT MatItemSeq, SUM(Qty) AS Qty        
                 FROM _TPDSFCMatinput WITH(NOLOCK)        
                WHERE CompanySeq     = @CompanySeq        
                  AND WorkReportSeq  = @WorkReportSeq        
                GROUP BY MatItemSeq) AS B ON A.MatItemSeq = B.MatItemSeq        
      -- 현장창고 가져오기       
     SELECT @FieldWHSeq = B.FieldWHSeq,
            @WHName     = W.WHName                 --20140718 임희진 추가
       FROM _TPDSFCWorkReport                  AS A WITH(NOLOCK)        
            LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq        
                                                                AND A.WorkcenterSeq = B.WorkcenterSeq
            LEFT OUTER JOIN _TDAWH             AS W WITH(NOLOCK) ON @CompanySeq = W.CompanySeq   
                                                                AND B.FieldWhSeq = W.WHSeq            --20140718 임희진 추가                                                                                          
      WHERE A.CompanySeq    = @CompanySeq        
        AND A.WorkReportSeq = @WorkReportSeq        
   
     DELETE #GetInOutItem  -- 20100125 박소연 추가        
     DELETE #GetInOutStock -- 20100125 박소연 추가        
         
   ---현장창고 재고를 가져오기위해 Item담기 20100125 박소연 추가        
     INSERT INTO #GetInOutItem        
     SELECT MatItemSeq        
       FROM #NeedMatSUM        
      GROUP BY MatItemSeq        
         
   
     ALTER TABLE #NeedMatSUM ADD STDStockQty DECIMAL (19, 5) -- 현장창고 재고  
   
 /**************현장창고재고가져오기 20100125 박소연 추가**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- 법인코드        
            @BizUnit       = 0,           -- 사업부문        
            @FactUnit      = @FactUnit,   -- 생산사업장        
            @DateFr        = @StkDate,   -- 조회기간Fr        
            @DateTo        = @StkDate,   -- 조회기간To        
            @WHSeq         = @FieldWHSeq, -- 창고지정        
            @SMWHKind      = 0,           -- 창고구분별 조회        
            @CustSeq       = 0,           -- 수탁거래처        
            @IsSubDisplay  = '',          -- 기능창고 조회        
            @IsUnitQry     = '',          -- 단위별 조회        
            @QryType       = 'S'          -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고        
         
   
     UPDATE N  
        SET STDStockQty = ISNULL(V.STDStockQty, 0)  
       FROM #NeedMatSUM          AS N             
         LEFT OUTER JOIN #GetInOutStock  AS V WITH(NOLOCK) ON N.MatItemSeq   = V.ItemSeq  -- 20100125 박소연 추가        
                                                          AND V.WHSeq        = @FieldWHSeq    
   
  /**************현장창고재고가져오기 끝**************************************************************/        
       
   
   
 /**************현장창고의 수탁창고 재고 가져오기 20120517 김세호 추가**********************************************/        
     IF EXISTS(SELECT 1 FROM #NeedMatSUM WHERE InputType = 6042003)  
      BEGIN  
         DELETE #GetInOutStock   
   
         DECLARE @CustSeq    INT  
         SELECT @CustSeq = (SELECT ISNULL(CustSeq, 0) FROM _TPDSFCWorkReport WHERE WorkReportSeq = @WorkReportSeq AND CompanySeq = @CompanySeq)  
   
   
          EXEC _SLGGetInOutStock  @CompanySeq   = @CompanySeq,   -- 법인코드  
                                  @BizUnit      = 0,             -- 사업부문  
                                  @FactUnit     = @FactUnit,     -- 생산사업장  
                                  @DateFr       = @StkDate,      -- 조회기간Fr  
                                  @DateTo       = @StkDate,      -- 조회기간To  
                                  @WHSeq        = @FieldWHSeq,   -- 창고지정  
                                  @SMWHKind     = 0,             -- 창고구분별 조회  
                                  @CustSeq      = @CustSeq,      -- 수탁거래처  
                                  @IsTrustCust  = '1',           -- 수탁여부  
                                  @IsSubDisplay = '1',           -- 기능창고 조회  
                                  @IsUnitQry    = '' ,           -- 단위별 조회  
                                  @QryType      = ''            -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고  
   
         UPDATE N  
            SET STDStockQty = ISNULL(V.STDStockQty, 0)  
           FROM #NeedMatSUM          AS N             
             LEFT OUTER JOIN #GetInOutStock  AS V WITH(NOLOCK) ON N.MatItemSeq   = V.ItemSeq  -- 20100125 박소연 추가        
                                                  AND V.WHSeq        = @FieldWHSeq    
          WHERE N.InputType = 6042003  
      END  
  /**************현장창고의 수탁창고 재고 가져오기  끝**************************************************************/        
   
     SELECT          
              @WorkReportSeq     AS WorkReportSeq          
             ,@InputDate         AS InputDate          
             ,N.MatItemSeq       AS MatItemSeq   
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.UnitSeq ELSE DU.STDUnitSeq END AS MatUnitSeq  
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.NeedQty ELSE N.NeedQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) END AS NeedQty  
             ,CASE WHEN @BaseProdUnit = 6105001 THEN N.InputQty ELSE N.InputQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) END AS Qty  
             --,N.UnitSeq          AS MatUnitSeq  
             --,N.NeedQty          AS NeedQty  
             --,N.InputQty         AS Qty  
             ,N.ProcSeq          AS ProcSeq          
             ,@AssyYn            AS AssyYn          
             ,@GoodItemSeq       AS GoodItemSeq          
             ,InputType          AS InputType          
             ,@IsPjt             AS IsPjt          
             ,@PjtSeq            AS PjtSeq          
             ,@WBSSeq            AS WBSSeq          
             ,I.ItemName         AS MatItemName          
             ,I.ItemNo           AS MatItemNo          
             ,I.Spec             AS MatItemSpec          
             ,CASE WHEN @BaseProdUnit = 6105001 THEN U.UnitName ELSE Z.UnitName END AS MatUnitName  
             --,U.UnitName         AS MatUnitName  
             ,@ExistsYn          AS ExistsYn          
             ,@FieldWHSeq        AS WHSeq          
             ,CASE WHEN @BaseProdUnit = 6105001 THEN ISNULL((N.InputQty * (SELECT ConvNum / ConvDen          
                                                                             FROM _TDAItemUnit          
                                                                            WHERE CompanySeq = @CompanySeq          
                                                                              AND ItemSeq = N.MatItemSeq          
                                                                              AND UnitSeq = N.UnitSeq          
                                  AND ConvDen <> 0 )),0 )   
                                                ELSE ISNULL((N.InputQty * (US.ConvNum / US.ConvDen) / (UP.ConvNum / UP.ConvDen) * (SELECT ConvNum / ConvDen          
                                                                                                                                     FROM _TDAItemUnit          
           WHERE CompanySeq = @CompanySeq          
                                                                                                                                      AND ItemSeq = N.MatItemSeq          
                                                                                                                                      AND UnitSeq = DU.STDUnitSeq          
                                                                                                                                      AND ConvDen <> 0 )),0 ) END   AS StdUnitQty          
             ,N.STDStockQty      AS STDStockQty -- 20100125 박소연 추가  
             ,M.MinorName        AS SMOutKind                                    -- 12.01.30 김세호 추가  
             ,CASE N.InputType WHEN 6042003 THEN '1' ELSE '0' END  AS IsConsign  -- 12.01.30 김세호 추가  
             ,ISNULL(ST.IsLotMng,'') AS IsLotMng
             ,@WHName            AS WHName                                         --20140718 임희진 추가
       FROM #NeedMatSUM          AS N          
         LEFT OUTER JOIN _TDAItem        AS I WITH(NOLOCK) ON N.MatItemSeq   = I.ItemSeq                
         LEFT OUTER JOIN _TDAUnit        AS U WITH(NOLOCK) ON I.CompanySeq   = U.CompanySeq          
                                 AND N.UnitSeq      = U.UnitSeq              
         LEFT OUTER JOIN _TDAItemProduct AS P WITH(NOLOCK) ON I.CompanySeq   = P.CompanySeq      
                                                          AND I.ItemSeq      = P.ItemSeq       
         LEFT OUTER JOIN _TDASMinor      AS M WITH(NOLOCK) ON P.CompanySeq   = M.CompanySeq      
                                                          AND P.SMOutKind    = M.MinorSeq   
          LEFT OUTER JOIN _TDAItemDefUnit AS DU ON @CompanySeq = DU.CompanySeq  
                                         AND N.MatItemSeq = DU.ItemSeq  
                                         AND DU.UMModuleSeq = 1003004  
         LEFT OUTER JOIN _TDAUnit        AS Z WITH(NOLOCK) ON Z.CompanySeq   = DU.CompanySeq          
                                                          AND Z.UnitSeq      = DU.STDUnitSeq  
         LEFT OUTER JOIN _TDAItemUnit       AS US WITH(NOLOCK)  ON @CompanySeq = US.CompanySeq  
                                                               AND N.MatItemSeq = US.ItemSeq          
                                                               AND N.UnitSeq    = US.UnitSeq          
         LEFT OUTER JOIN _TDAItemUnit       AS UP WITH(NOLOCK)  ON @CompanySeq = UP.CompanySeq  
                                                               AND N.MatItemSeq = UP.ItemSeq          
                                                               AND DU.STDUnitSeq = UP.UnitSeq          
         LEFT OUTER JOIN _TDAItemStock      AS ST WITH(NOLOCK) ON @CompanySeq = ST.CompanySeq  
                                                              AND N.MatItemSeq = ST.ItemSeq  
      WHERE I.CompanySeq  = @CompanySeq          
        AND N.InputQty <> 0          
      ORDER BY N.BOMSerl, MatItemNo        
   
         
 RETURN        
 /***************************************************************************************************************/        
 Qry_GetItem:   -- 출고자재가져오기        
         
     SELECT        
              R.WorkReportSeq        
             ,R.WorkDate         AS InputDate        
             ,O.ItemSeq          AS MatItemSeq        
             ,O.UnitSeq          AS MatUnitSeq      
             ,SUM(O.Qty)         AS Qty        
             ,R.ProcSeq          AS ProcSeq        
             ,CASE WHEN R.IsLastProc = '1' THEN '0'        
                   ELSE '1'        
              END                AS AssyYn        
             ,R.GoodItemSeq      AS GoodItemSeq        
             ,CASE WHEN ISNULL(O.ConsgnmtCustSeq,0) = 0 THEN 6042002 ELSE 6042003 END AS InputType -- 수탁자재인 경우 투입구분 수탁으로 수정 송기연 201010616        
             ,R.IsPjt        
             ,R.PjtSeq        
             ,R.WBSSeq        
             ,I.ItemName         AS MatItemName        
             ,I.ItemNo           AS MatItemNo        
             ,I.Spec             AS MatItemSpec        
             ,U.UnitName         AS MatUnitName        
             ,''                 AS MatOutNo        
             ,0                  AS MatOutSeq        
             ,O.ItemLotNo  AS RealLotNo        
             ,WC.FieldWHSeq      AS WHSeq        
             ,W.ProcNo           AS ProcNo        
             ,O.WorkOrderSeq     AS WorkOrderSeq        
             ,O.WorkOrderSerl    AS WorkOrderSerl
             ,WH.WHName          AS WHName
       INTO #OutItem       
       FROM _TPDMMOutItem        AS O        
           JOIN _TPDMMOutM         AS M ON O.CompanySeq    = M.CompanySeq        
                                     AND O.MatOutSeq     = M.MatOutSeq        
         JOIN _TPDSFCWorkReport  AS R ON O.CompanySeq    = R.CompanySeq        
                                     AND O.WorkOrderSeq  = R.WorkOrderSeq        
                                     AND O.WorkOrderSerl = R.WorkOrderSerl        
         JOIN _TPDSFCWorkOrder   AS W ON O.CompanySeq    = W.CompanySeq        
                                     AND O.WorkOrderSeq  = W.WorkOrderSeq        
                                     AND O.WorkOrderSerl = W.WorkOrderSerl        
         JOIN _TDAItem            AS I ON O.CompanySeq    = I.CompanySeq        
                                     AND O.ItemSeq       = I.ItemSeq        
         JOIN _TDAUnit           AS U ON O.CompanySeq    = U.CompanySeq        
                                     AND O.UnitSeq       = U.UnitSeq        
         LEFT OUTER JOIN _TPDBaseWorkcenter AS WC ON W.CompanySeq    = WC.CompanySeq        
                                                 AND W.WorkcenterSeq = WC.WorkcenterSeq
         LEFT OUTER JOIN _TDAWH             AS WH WITH(NOLOCK) ON WC.CompanySeq = WH.CompanySeq   
                                                              AND WC.FieldWhSeq = WH.WHSeq                --20140718 임희진 추가                                                                                          
      WHERE O.CompanySeq     = @CompanySeq        
        AND R.WorkReportSeq  = @WorkReportSeq        
        AND M.UseType        NOT IN (6044006, 6044007) -- 20100126 박소연 수정 반품도 제외        
      GROUP BY R.WorkReportSeq, R.WorkDate, O.ItemSeq, O.UnitSeq, R.ProcSeq, R.IsLastProc, R.GoodItemSeq, O.ConsgnmtCustSeq, R.IsPjt, R.PjtSeq, R.WBSSeq ,        
               I.ItemName, I.ItemNo, I.Spec, U.UnitName, O.ItemLotNo, WC.FieldWHSeq, W.ProcNo, O.WorkOrderSeq,O.WorkOrderSerl ,WH.WHName       
       
     
 ------------------------------------------------------------------------------------------    
     -- 현장창고에서 자재반품이 있는 경우 그 수량 만큼 출고된 자재에서 차감해준다.        
 ------------------------------------------------------------------------------------------    
     SELECT B.ItemSeq, B.UnitSeq, B.ItemLotNo, SUM(B.Qty) AS Qty        
       INTO #OutItemReturn        
       FROM _TPDSFCWorkReport AS A WITH(NOLOCK)        
            INNER JOIN _TPDMMOutItem AS B WITH(NOLOCK)        
                    ON B.WorkOrderSeq    = A.WorkOrderSeq        
                   AND B.WorkOrderSerl   = A.WorkOrderSerl        
                   AND B.CompanySeq      = A.CompanySeq        
                     AND EXISTS (        
                                 SELECT *        
                           FROM #OutItem        
                                  WHERE MatItemSeq   = B.ItemSeq        
                                    AND RealLotNo    = B.ItemLotNo        
                             )        
            INNER JOIN _TPDMMOutM AS C WITH(NOLOCK)        
                    ON C.MatOutSeq       = B.MatOutSeq        
                   AND C.CompanySeq      = B.CompanySeq        
                   AND C.UseType         IN (6044007, 6044010)   -- 자재반품        
      WHERE A.WorkReportSeq  = @WorkReportSeq        
        AND A.CompanySeq     = @CompanySeq        
      GROUP BY B.ItemSeq, B.UnitSeq, B.ItemLotNo        
         
         
     UPDATE #OutItem        
        SET Qty  = A.Qty - B.Qty        
       FROM #OutItem AS A        
            INNER JOIN #OutItemReturn AS B        
                    ON B.ItemSeq     = A.MatItemSeq        
                   AND B.UnitSeq     = A.MatUnitSeq         
                   AND B.ItemLotNo   = A.RealLotNo              
 ------------------------------------------------------------------------------------------       
         
         
     SELECT A.MatItemSeq, A.MatUnitSeq, A.RealLotNo, SUM(A.Qty) AS Qty        
       INTO #Input        
       FROM _TPDSFCMatInput          AS A WITH(NOLOCK)        
      WHERE A.CompanySeq         = @CompanySeq        
        AND EXISTS(SELECT 1 FROM _TPDSFCWorkReport   AS R WITH(NOLOCK)        
                             JOIN #OutItem           AS I ON R.WorkOrderSeq = I.WorkOrderSeq        
                                                         AND R.WorkOrderSerl = I.WorkOrderSerl        
                           WHERE R.CompanySeq = @CompanySeq        
                             AND R.WorkReportSeq = A.WorkReportSeq     )        
      GROUP BY A.MatItemSeq, A.MatUnitSeq, A.RealLotNo                                --2015.02.16 임희진 수정        
         
         
   ------------------------------------------------------------------------------------------        
     -- 기 투입된 자재수량 차감.        
 ------------------------------------------------------------------------------------------    
     UPDATE A        
        SET Qty  = A.Qty - ISNULL(B.Qty,0)        
       FROM #OutItem             AS A        
         JOIN #Input             AS B ON A.MatItemSeq  = B.MatItemSeq
                                     AND A.MatUnitSeq  = B.MatUnitSeq        
                                     AND A.RealLotNo   = B.RealLotNo                  --2015.02.16 임희진 수정 
     
 ------------------------------------------------------------------------------------------    
     
      
   ------------------------------------------------------------------------------------------        
  --==== 전공정 공정품 가져오기 ----===                    -- 11.03.09 김세호 추가      
  ------------------------------------------------------------------------------------------    
      
     DECLARE @EnvValue   NVARCHAR(100)   -- 6217           
     EXEC dbo._SCOMEnv @CompanySeq,6217,@UserSeq,@@PROCID,@EnvValue OUTPUT        
         
   IF  (@EnvValue IN ('1','True')  AND @WorkReportSeq <> 0 )          
      BEGIN      
       
        INSERT             
        INTO #OutItem      
         SELECT       
   
                  @WorkReportSeq      
                 ,(SELECT WorkDate FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq) AS InputDate      
                 ,I.ItemSeq          AS MatItemSeq      
                 ,U.UnitSeq          AS MatUnitSeq      
                 ,R.OKQty            AS Qty      
                  --전공정 양품수량 가져올때, 공정코드는 해당 실적의 공정코드로 가져오도록 수정 -- 12.05.30   BY 김세호  
                 ,(SELECT ProcSeq FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq) AS ProcSeq   
                 ,CASE WHEN R.IsLastProc = '1' THEN '0'      
                       ELSE '1'      
                  END                AS AssyYn      
        ,R.GoodItemSeq      AS GoodItemSeq      
                 ,6042002            AS InputType       
                 ,R.IsPjt      
                 ,R.PjtSeq      
                 ,R.WBSSeq      
                 ,I.ItemName         AS MatItemName      
                 ,I.ItemNo           AS MatItemNo      
                 ,I.Spec             AS MatItemSpec      
                 ,U.UnitName         AS MatUnitName      
                 ,''                 AS MatOutNo      
                 ,0                  AS MatOutSeq      
                 ,R.RealLotNo        AS RealLotNo      
                 -- 전공정 양품수량 가져올때, 창고코드는 해당 실적의 현장 창고코드로 가져오도록 수정         -- 12.05.18 BY 김세호  
                 ,(SELECT FieldWhSeq FROM _TPDSFCWorkReport WHERE CompanySeq = @CompanySeq AND WorkReportSeq = @WorkReportSeq)   AS WHSeq      
                 ,W.ProcNo           AS ProcNo      
                 ,W.WorkOrderSeq     AS WorkOrderSeq      
                 ,W.WorkOrderSerl    AS WorkOrderSerl      
                 ,WH.WHName          AS WHName
           FROM   _TPDSFCWorkReport  AS R       
             JOIN _TPDSFCWorkOrder   AS W ON R.WorkOrderSeq  = W.WorkOrderSeq      
                                         AND R.WorkOrderSerl = W.WorkOrderSerl      
                                         AND R.CompanySeq    = W.CompanySeq      -- 법인 조건 추가   12.10.29 BY 김세호  
             JOIN _TDAItem           AS I ON R.CompanySeq    = I.CompanySeq      
                                         AND W.AssyItemSeq       = I.ItemSeq      
             JOIN _TDAUnit           AS U ON R.CompanySeq    = U.CompanySeq      
                                         AND I.UnitSeq       = U.UnitSeq      
             JOIN _TDAWH             AS WH ON R.CompanySeq = WH.CompanySeq
                                          AND R.FieldWhSeq = WH.WHSeq
          WHERE R.CompanySeq     = @CompanySeq      
            AND W.WorkOrderSeq   = @WorkOrderSeq      
            AND W.IsLastProc     <> 1      
            AND W.ToProcNo IN (SELECT A.ProcNo      
                                    FROM _TPDSFCWorkOrder   AS A      
                                     WHERE  @CompanySeq    = A.CompanySeq      
                                        AND @WorkOrderSeq   = A.WorkOrderSeq      
                                        AND @WorkOrderSerl  = A.WorkOrderSerl)      
       
        END        
 ------------------------------------------------------------------------------------------------------------    
      -- 현장창고 가져오기    -- 12.05.08 김세호 추가          
     SELECT @FieldWHSeq = B.FieldWHSeq
           
       FROM _TPDSFCWorkReport                  AS A WITH(NOLOCK)        
            LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq        
                                                                AND A.WorkcenterSeq = B.WorkcenterSeq
                                                                                           
      WHERE A.CompanySeq    = @CompanySeq        
        AND A.WorkReportSeq = @WorkReportSeq  
        
     DELETE #GetInOutItem  -- 20100125 박소연 추가        
     DELETE #GetInOutStock -- 20100125 박소연 추가        
         
     ---현장창고 재고를 가져오기위해 Item담기 20100125 박소연 추가        
     INSERT INTO #GetInOutItem        
     SELECT DISTINCT MatItemSeq        
       FROM #OutItem        
      GROUP BY MatItemSeq        
         
     
     /**************현장창고재고가져오기 20100125 박소연 추가**********************************************/        
         
       EXEC _SLGGetInOutStock        
            @CompanySeq    = @CompanySeq, -- 법인코드        
            @BizUnit       = 0,           -- 사업부문        
            @FactUnit      = @FactUnit,   -- 생산사업장        
            @DateFr        = @StkDate,   -- 조회기간Fr        
            @DateTo        = @StkDate,   -- 조회기간To        
            @WHSeq         = @FieldWHSeq, -- 창고지정        
            @SMWHKind      = 0,                 -- 창고구분별 조회(8002002 : 현장창고)     
            @CustSeq       = 0,           -- 수탁거래처        
            @IsSubDisplay  = '',          -- 기능창고 조회        
            @IsUnitQry     = '',          -- 단위별 조회        
            @QryType       = 'S'          -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고        
         
     /**************현장창고재고가져오기 끝**************************************************************/        
     
   --select * from #GetInOutStock  
     
     DECLARE @MatItemPoint INT  
       
     ---- 구매/자재 소수점 자리수 가져오기 ---- 2014.07.17 김용현 추가  
     EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@MatItemPoint OUTPUT    
     
     SELECT A.*,        
            (CASE WHEN V.SMDecPointSeq = 1003001 THEN ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0)   -- 반올림      
                  WHEN V.SMDecPointSeq = 1003002 THEN ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, -1)  -- 절사      
                  WHEN V.SMDecPointSeq = 1003003 THEN ROUND((CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ) * A.Qty + CAST(4 AS DECIMAL(19, 5)) / POWER(10,(@MatItemPoint + 1)), @MatItemPoint)   -- 올림      
                  ELSE ROUND(A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END ), @MatItemPoint, 0) END) -- 2014.07.17 김용현 자재출고와 동일한 로직으로 수정  
            AS StdUnitQty,      
                                    
            ISNULL(B.STDStockQty, 0) AS STDStockQty -- 20100125 박소연 추가    
              
             ,M.MinorName        AS SMOutKind                        -- 12.01.30 김세호 추가     
             ,CASE A.InputType WHEN 6042003 THEN '1' ELSE '0' END  AS IsConsign          -- 12.01.30 김세호 추가     
             ,ISNULL(ST.IsLotMng,'') AS IsLotMng
            
       FROM #OutItem     AS A        
             LEFT OUTER JOIN #GetInOutStock AS B ON A.MatItemSeq = B.ItemSeq AND A.WHSeq = B.WHSeq       
             LEFT OUTER JOIN _TDAItemProduct AS P WITH(NOLOCK) ON @CompanySeq   = P.CompanySeq    
                                                              AND A.MatItemSeq      = P.ItemSeq     
             LEFT OUTER JOIN _TDASMinor      AS M WITH(NOLOCK) ON P.CompanySeq   = M.CompanySeq    
                                                              AND P.SMOutKind    = M.MinorSeq  
             LEFT OUTER JOIN _TDAItemStock   AS ST WITH(NOLOCK) ON @CompanySeq = ST.CompanySeq  
                                                               AND A.MatItemSeq = ST.ItemSeq       
                        JOIN _TDAItemUnit   AS U ON A.MatItemSeq = U.ItemSeq        
                                                AND A.MatUnitSeq = U.UnitSeq    
                                                AND U.CompanySeq = @CompanySeq      
                        JOIN _TDAUnit       AS V ON A.MatUnitSeq = V.UnitSeq   
                                                AND U.CompanySeq = V.CompanySeq 
                                       
                                                 
      WHERE A.Qty > 0        
         
         
         
 RETURN        
 /***************************************************************************************************************/