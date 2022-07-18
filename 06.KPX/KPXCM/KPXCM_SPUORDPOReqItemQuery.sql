IF OBJECT_ID('KPXCM_SPUORDPOReqItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOReqItemQuery
GO 

-- v2015.10.06 

-- 포장구분 추가 
/*************************************************************************************************  
  FORM NAME           -       FrmPUORDPOReq
  DESCRIPTION         -     구매요청 디테일 조회
  CREAE DATE          -       2008.10.21         CREATE BY: 김현
  LAST UPDATE  DATE   -       2008.10.21         UPDATE BY: 김현 
                              2010.04.08         UPDATE BY: 박소연 :: MEMO4/5/6 추가   
                              2010.04.09                    정동혁 :: UMinorSeq1/2/3 추가 (사용자정의코드용)
                              2010.05.25         UPDATE BY: 송경애 :: 발주예정일(PODueDate) 추가
                              2010.10.20         UPDATE BY: 천경민 :: 활동센터(CCtrName, CCtrSeq) 추가
                              2011. 1.11         UPDATE BY: 김현   :: SourceType = 6인 경우 생산계획 코드 넘겨준다
                              2011. 3. 3         UPDATE BY: 김현   :: SourceType 컬럼 추가 및 6인 경우 생산계획자재소요대상조회에서 점프해온 데이터로 처리한다.
         2013.01.23         UPDATE BY: 허승남 :: 기존 구매단가테이블을 이용해서 단가,통화,거래처정보를 가져오게 되어있는 부분을 사용하지 않아 조인절 주석처리
         2013.02.27         UPDATE BY: 김권우 :: 환경설정(구매발주비율 사용여부, 이전구매처 최근단가적용, 구매/자재 수량 소숫점 자리수) 값에 따라
                                                 데이터가 표기 되도록 수정
 *************************************************************************************************/  
 CREATE PROC KPXCM_SPUORDPOReqItemQuery  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     DECLARE @docHandle  INT,
             @POReqSerl  INT,
             @VATRate    INT,
             @Date       NVARCHAR(8),
             @CurrSeq    INT,
             @PUPORate   NCHAR(1),
             @LastCustPrice INT,
             @QtyPoint   INT
      -- 서비스 마스타 등록 생성    
     CREATE TABLE #TPUORDPOReqItem (WorkingTag NCHAR(1) NULL)    
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPUORDPOReqItem'   
      IF @@ERROR <> 0 RETURN    
      -- 기본 통화코드 가져오기
     EXEC dbo._SCOMEnv @CompanySeq,13,@UserSeq,@@PROCID,@CurrSeq OUTPUT
     -- 구매발주비율 사용여부 가져오기
     EXEC dbo._SCOMEnv @CompanySeq,6666,@UserSeq,@@PROCID,@PUPORate OUTPUT
     -- 이전구매처 최근단가적용 가져오기
     EXEC dbo._SCOMEnv @CompanySeq,6501,@UserSeq,@@PROCID,@LastCustPrice OUTPUT
     -- 구매/자재 수량 소숫점 자릿수 가져오기
     EXEC dbo._SCOMEnv @CompanySeq,5,@UserSeq,@@PROCID,@QtyPoint OUTPUT
      SELECT @POReqSerl = POReqSerl FROM #TPUORDPOReqItem
     
     SELECT @PUPORate = ISNULL(@PUPORate,0)  
     
     -- 부가세율 가져오기
     --SELECT @Date = CONVERT(NCHAR(8),GETDATE(),112)   
     SELECT @Date = A.ReqDate 
       FROM _TPUORDPOReq    AS A
      JOIN #TPUORDPOReqItem AS B ON A.POReqSeq = B.POReqSeq
   WHERE A.CompanySeq = @CompanySeq
        
     SELECT @VATRate = VATRate 
       FROM _TDAVatRate
      WHERE CompanySeq = @CompanySeq
        AND @Date BETWEEN SDate AND EDate
        AND SMVATType = 8028001
      SELECT A.POReqSeq    , 
            A.POReqSerl   , 
            A.ItemSeq     , 
            A.UnitSeq     , 
            
            CASE WHEN @WorkingTag = 'J' THEN Z.Qty  -- 구매발주비율 때문에 추가  ( 데이터서비스에서 Qty에 OutPut 체크)
                 ELSE   A.Qty
            END                AS Qty      ,
            A.MakerSeq    , 
            A.DelvDate    , 
            CASE WHEN @WorkingTag = 'J' THEN (CASE WHEN A.SMInOutType = 0 THEN 8008001    -- 품의로 점프시에 내외자구분이 저장 안된 경우 품의에서도 내외자구분이
                    ELSE A.SMInOutType END) -- 들어가지 않아 부가세가 0으로 나오는오류 수정 2010. 8. 18 hkim
             ELSE A.SMInOutType END AS SMInOutType , 
            CASE WHEN @WorkingTag = 'J' THEN (CASE WHEN A.SMInOutType = 0 THEN 8008001 
                    ELSE A.SMInOutType END) 
             ELSE A.SMInOutType END AS SMImpType , 
            A.Remark      , 
            A.STDUnitSeq  , 
            A.STDUnitQty  , 
            A.PJTSeq      , 
            B.ItemName    ,
            B.ItemNo      , 
            B.Spec        , 
            C.UnitName    , 
            J.UnitName    AS STDUnitName, --(SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = A.StdUnitSeq) AS StdUnitName,
            D.CustName    AS MakerName  ,
            E.PJTNo       , 
            E.PJTName     , 
            A.WBSSeq      , 
            F.WBSName     ,
            --CASE ISNULL(G.CurrSeq, 0) WHEN 0 THEN @CurrSeq ELSE G.CurrSeq END AS CurrSeq , 
      A.CurrSeq ,
            --CASE ISNULL(I.CurrName, '') WHEN '' THEN (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = @CurrSeq) ELSE I.CurrName END AS CurrName,
      (SELECT CurrName FROM _TDACurr WHERE CompanySeq = @CompanySeq AND CurrSeq = A.CurrSeq) AS CurrName,
            --CASE ISNULL(A.Price, 0) WHEN 0 THEN G.Price ELSE A.Price END AS Price       , 
            ISNULL(A.Price, 0) AS Price,
 --            G.CustSeq     , 
 --            H.CustName    , S
            CASE ISNULL(A.ExRate, 0) WHEN 0 THEN 1 ELSE A.ExRate END AS ExRate      , 
            --CASE ISNULL(A.CurAmt, 0) WHEN 0 THEN G.Price * A.Qty ELSE A.CurAmt END AS CurAmt     , 
            ISNULL(A.CurAmt, 0) AS CurAmt,
            ISNULL(A.CurVAT, 0) AS CurVAT,--WHEN 0 THEN ISNULL(G.Price, 0) * ISNULL(A.Qty, 0) / @VATRate ELSE A.CurVAT END AS CurVAT      , 
            --CASE ISNULL(A.DomPrice, 0) WHEN 0 THEN G.Price * 1 ELSE A.DomPrice END AS DomPrice    , 
            ISNULL(A.DomPrice, 0) AS DomPrice,
            --CASE ISNULL(A.DomAmt, 0) WHEN 0 THEN G.Price * A.Qty * 1 ELSE A.DomAmt END AS DomAmt     , --A.DomAmt      , 
            ISNULL(A.DomAmt, 0)  AS DomAmt,
            ISNULL(A.DomVAT, 0) AS DomVAT,--WHEN 0 THEN ISNULL(G.Price, 0) * ISNULL(A.Qty, 0) / @VATRate ELSE A.DomVAT END AS DomVAT      , --A.DomVAT      , 
            A.IsVAT       , 
 --            CASE ISNULL(A.IsVAT, '') WHEN '1' THEN ISNULL(G.Price, 0) * ISNULL(A.Qty, 0)--  + (ISNULL(G.Price, 0) * ISNULL(A.Qty, 0)/@VATRate) 
 --                 ELSE  (ISNULL(A.Price, 0) * ISNULL(A.Qty, 0)) +  (ISNULL(A.Price, 0) * ISNULL(A.Qty, 0)/@VATRate) END AS TotCurAmt,           
 --            CASE ISNULL(A.IsVAT, '') WHEN '1' THEN ISNULL(G.Price, 0) * ISNULL(A.Qty, 0) * ISNULL(A.ExRate, 0)
 --                 ELSE  (ISNULL(A.Price, 0) * ISNULL(A.Qty, 0)) * ISNULL(A.ExRate, 0) +  (ISNULL(A.Price, 0) * ISNULL(A.Qty, 0)/@VATRate) * ISNULL(A.ExRate, 0) END AS TotDomAmt,          
            ISNULL(A.CurAmt, 0) + ISNULL(A.CurVAT, 0) AS TotCurAmt, 
            ISNULL(A.DomAmt, 0) + ISNULL(A.DomVAT, 0) AS TotDomAmt,
            Z.IDX_NO   AS IDX_NO,
            P.BOMLevel AS BOMLevel,
            P.ISStd    AS ISStd,
            P.UMSupplyType AS UMSupplyType,
            P.UMRegType AS UMRegType,
            P1.MinorName AS UMSupplyTypeName,
            P2.MinorName AS UMRegTypeName,
            A.BOMSerl AS BOMSerl,
            CASE WHEN ISNULL(AP.PreLeadTime,0)+ISNULL(AP.LeadTime,0)+ISNULL(AP.PostLeadTime,0) = 0 THEN ISNULL(B1.DelvDay,0)  
                 ELSE ISNULL(AP.PreLeadTime,0)+ISNULL(AP.LeadTime,0)+ISNULL(AP.PostLeadTime,0) END AS LeadTime,
            A.DelvDate  AS ReqDelvDate,
            A.WHSeq     AS WHSeq,
            ISNULL(A.Memo1,'')     AS Memo1,
            ISNULL(A.Memo2,'')     AS Memo2,
            ISNULL(A.Memo3,'')     AS Memo3,
            ISNULL(A.Memo4,'')     AS Memo4, -- 20100408 박소연 추가
            CONVERT(INT,ISNULL(A.Memo5,''))     AS Memo5, -- 20100408 박소연 추가
            ISNULL(A.Memo6,'')     AS Memo6, -- 20100408 박소연 추가
            ISNULL(A.Memo7,0)      AS Memo7,
            ISNULL(A.Memo8,0)      AS Memo8,
            ISNULL(A.UMinorSeq1,0)     AS UMinorSeq1,
            ISNULL(A.UMinorSeq2,0)     AS UMinorSeq2,
            ISNULL(A.UMinorSeq3,0)     AS UMinorSeq3,
            K.WHName    AS WHName,
            P.BOMRev    AS BOMRev,
            CASE WHEN A.CustSeq > 0 THEN (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) ELSE '' END  AS CustName,
            A.CustSeq,
            A.PODueDate,
            CASE WHEN ISNULL(R.ValueText,'') <> '1' AND 
                      ISNULL(S.ValueText,'') <> '1' THEN (CASE V.SMVatKind WHEN 2003001 THEN ISNULL(Q.VatRate,0) ELSE 0 END)
                             ELSE @VATRate END AS VATRate,
            A.SourceSeq AS MRPDailySeq,
            --T.MRPDailyNo,
            CASE WHEN ISNULL(A.SourceType, '') = '9' THEN MRP.MRPMonthNo ELSE T.MRPDailyNo END AS MRPDailyNo,
             --MRP.MRPMonthNo AS MRPDailyNo,
            CASE WHEN ISNULL(A.SourceType, '') = '6' THEN A.SourceSeq ELSE T.ProdPlanSeq END ProdPlanSeq,
            CASE WHEN ISNULL(A.SourceType, '') = '6' THEN UP.ProdPlanNo ELSE U.ProdPlanNo END AS ProdPlanNo,
            ISNULL(A.CCtrSeq, 0)    AS CCtrSeq,
            ISNULL(CC.CCtrName, '') AS CCtrName,
            CASE WHEN ISNULL(A.SourceType, '') = '6' THEN A.SourceSeq ELSE ISNULL(U.ProdPlanSeq, 0) END AS SourceSeq,                                                                -- 생산계획 원천코드        2011. 1. 11 hkim
            CASE WHEN ISNULL(U.ProdPlanSeq, 0) <> 0  THEN '6' ELSE ISNULL(A.SourceType, '') END AS SourceType,      -- Sourcetype = 6 생산계획  2011. 1. 11 hkim
            G.MinorName AS Memo5Name 
       INTO #Temp_Data
    
       FROM #TPUORDPOReqItem                     AS Z WITH(NOLOCK)  
            JOIN _TPUORDPOReqItem                AS A WITH(NOLOCK) ON Z.POReqSeq   = A.POReqSeq   
                                                                  AND (@POReqSerl IS NULL OR Z.POReqSerl = A.POReqSerl)
            LEFT OUTER JOIN _TDAItem             AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq 
                                                                  AND A.ItemSeq    = B.ItemSeq
      LEFT OUTER JOIN _TDAItemSales  AS V WITH(NOLOCK) ON A.CompanySeq = V.CompanySeq
                  AND A.ItemSeq   = V.ItemSeq
            LEFT OUTER JOIN _TDAUnit             AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                  AND A.UnitSeq    = C.UnitSeq
            LEFT OUTER JOIN _TDACust             AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq 
                                                                  AND A.MakerSeq   = D.CustSeq
            --LEFT OUTER JOIN _TPUBASEBuyPriceItem AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq 
            --                                                      AND A.ItemSeq    = G.ItemSeq 
            --                                                      AND G.IsPrice    = '1'
            --LEFT OUTER JOIN _TDACust             AS H WITH(NOLOCK) ON G.CompanySeq = H.CompanySeq 
            --                                                      AND G.CustSeq    = H.CustSeq
            --LEFT OUTER JOIN _TDACurr             AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq 
            --                                                      AND G.CurrSeq    = I.CurrSeq
            LEFT OUTER JOIN _TPJTPRoject         AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq 
                                                                  AND A.PJTSeq     = E.PJTSeq       
            LEFT OUTER JOIN _TPJTWBS             AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq 
                                                                  AND A.PJTSeq     = F.PJTSeq 
                                                                  AND A.WBSSeq     = F.WBSSeq
            LEFT OUTER JOIN _TDAUnit             AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq 
                                                                  AND A.StdUnitSeq = J.UnitSeq
            LEFT OUTER JOIN _TDAWH               AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq 
                                                                  AND A.WHSeq      = K.WHSeq
            LEFT OUTER JOIN _TPJTBOM             AS P WITH(NOLOCK) ON A.CompanySeq = P.CompanySeq
                                                                  AND A.PJTSeq = P.PJTSeq
                                AND A.BOMSerl = P.BOMSerl   
            LEFT OUTER JOIN _TDAUMinor           AS P1 WITH(NOLOCK) ON A.CompanySeq = P1.CompanySeq AND P.UMSupplyType = P1.MinorSeq
            LEFT OUTER JOIN _TDAUMinor            AS P2 WITH(NOLOCK) ON A.CompanySeq = P2.CompanySeq AND P.UMRegType = P2.MinorSeq
            LEFT OUTER JOIN _TPUBASEBuyPriceItem AS AP WITH(NOLOCK) ON AP.CompanySeq = @CompanySeq  
                                                                       AND A.ItemSeq    = AP.ItemSeq      /** 대표단가여부에 체크가 되어 있고 **/  
                                                                       AND AP.IsPrice    = '1'            /** PreLeadTime + LeadTime + PostLeadTime 값이 있을경우 조달일수에 표시**/    
      LEFT OUTER JOIN _TDAItemPurchase     AS B1 WITH(NOLOCK) ON A.CompanySeq = B1.CompanySeq AND A.ItemSeq = B1.ItemSeq
            LEFT OUTER JOIN _TDAVATRate   AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq
                   AND V.SMVatType  = Q.SMVatType
                   AND @Date BETWEEN Q.SDate AND Q.EDate
            LEFT OUTER JOIN _TDASMinorValue  AS R  WITH(NOLOCK) ON R.CompanySeq = @CompanySeq
                                                          AND A.SMInOutType= R.MinorSeq   
                                                                   AND R.Serl       = 1002
            LEFT OUTER JOIN _TDASMinorValue  AS S  WITH(NOLOCK) ON S.CompanySeq = @CompanySeq
                                                                   AND A.SMInOutType= S.MinorSeq
                                                                   AND S.Serl       = 1002
            LEFT OUTER JOIN _TPDMRPDailyitem     AS T  WITH(NOLOCK) ON A.CompanySeq = T.CompanySeq
                                                                   AND A.UMPOReqType = 6501014
                                                                   AND A.SourceSeq   = T.MRPDailySeq
                                                                   AND A.SourceSerl  = T.Serl
            LEFT OUTER JOIN _TPDMPSDailyProdPlan AS U  WITH(NOLOCK) ON A.CompanySeq  = U.CompanySeq
                                                                   AND U.ProdPlanSeq = T.ProdPlanSeq
            LEFT OUTER JOIN _TDACCtr             AS CC WITH(NOLOCK) ON A.CompanySeq  = CC.CompanySeq
                                                                   AND A.CCtrSeq     = CC.CCtrSeq
            LEFT OUTER JOIN _TPDMPSDailyProdPlan AS UP WITH(NOLOCK) ON A.CompanySeq  = UP.CompanySeq
                                                                   AND A.SourceSeq   = UP.ProdPlanSeq
                                                                   AND A.SourceType  = '6'
            LEFT OUTER JOIN _TPDMRPMonth AS MRP WITH(NOLOCK) ON A.CompanySeq  = MRP.CompanySeq
                                                                   AND A.SourceSeq   = MRP.MRPMonthSeq
                                                                   AND A.SourceType  = '32' --생산계획간편
            LEFT OUTER JOIN _TDAUMinor  AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.Memo5 ) 
  
      WHERE A.CompanySeq = @CompanySeq
        AND (@WorkingTag <> 'J' OR (@WorkingTag = 'J' AND A.IsStop <> '1') )  -- 구매요청에서 품의로 점프시 중단건은 조회되지 않도록 추가 2011. 9. 15 hkim  
      ORDER BY A.POReqSeq    , A.POReqSerl
  IF @PUPORate IS NULL SELECT @PUPORate = 0
  IF(@LastCustPrice <> 6072001 OR @PUPORate = '0') OR @WorkingTag <> 'J'        --(PORate : 구매발주비율 사용여부 : 0:사용안함, 1:사용)
 BEGIN                                                                       --(@LastCustPrice : 이전구매처 최근단가적용 : 6072001:사용안함, 6072002:발주, 6072003:납품)
     SELECT * FROM #Temp_Data
 END
 ELSE IF(@LastCustPrice = 6072001 AND @PUPORate = '1') OR @WorkingTag = 'J'
 BEGIN
     --발주비율로 수량배분
     SELECT A.PoReqSeq AS PoReqSeq,
            A.PoReqSerl AS PoReqSerl,
            A.ItemSeq   AS ItemSeq,
            X.CustSeq   AS CustSeq,
            A.Qty       AS Qty, 
            ISNULL(ROUND(A.Qty * X.PORate/100,@QtyPoint,1)  ,0)  AS DIVQty,
            ROW_NUMBER() OVER(PARTITION BY A.poreqSeq,A.POReqSerl ORDER BY A.Qty * X.PORate/100  DESC) AS RowNUmber,
            CONVERT(DECIMAL(19,5) , 0 ) AS SUMDIVQty
     INTO #Temp_DIVData           
     FROM #Temp_Data AS  A
     LEFT OUTER JOIN _TPUBasePORate       AS B  WITH(NOLOCK) ON B.CompanySeq = @CompanySEq
   AND A.ItemSeq    = B.ItemSeq
                                                            AND @Date BETWEEN B.StartDate AND B.EndDate
     LEFT OUTER JOIN _TPUBasePORateItem   AS X  WITH(NOLOCK) ON X.CompanySeq = @CompanySEq
                                                            AND B.ItemSeq    = X.ItemSeq
     ORDER BY A.poreqSeq,A.POReqSerl,A.Qty * X.PORate/100  DESC
     
  
     --발주비율배분수량 SUM
     UPDATE #Temp_DIVData
        SET SUMDIVQty = B.SUMDIVQTy
       FROM #Temp_DIVData AS  A
            JOIN (SELECT POReqSeq ,POReqSerl, SUM(DIVQTy) AS SUMDIVQTy
                    FROM #Temp_DIVData 
                   GROUP BY POReqSeq ,POReqSerl
                 ) AS B ON A.POReqSeq= B.POReqSeq
                       AND A.POReqSerl = B.POReqSerl
  
     --보정작업
     UPDATE #Temp_DIVData
        SET DIVQTy = CASE WHEN DIVQTy = 0 THEN ISNULL(QTy,0) 
                          ELSE DIVQTy + ( Qty - SUMDIVQTy )
                     END
      WHERE ROwNumber = 1
  
      SELECT A.POReqSeq           AS POReqseq         ,
            A.POReqserl          AS POReqserl        ,
            A.ItemSeq            AS ItemSeq          , 
            A.UnitSeq            AS UnitSeq          ,
            B.DIVQTy             AS Qty              , 
            B.DIVQTy             AS PORateQty        ,
            A.MakerSeq           AS MakerSeq         , 
            A.DelvDate           AS DelvDate         , 
            A.SMInOutType        AS SMInOutType      , 
            A.SMInOutType        AS SMImpType        , 
            A.Remark             AS Remark           , 
            D.UnitSeq            AS STDUnitSeq       , 
            ISNULL( (E.ConvNum/E.ConvDen), 1) * B.DIVQTy AS   STDUnitQty,
            A.PJTSeq             AS PJTSeq           , 
            A.ItemName           AS ItemName         ,
            A.ItemNo             AS ItemNo           , 
            A.Spec               AS Spec             , 
            A.UnitName           AS UnitName         , 
            F.UnitName           AS STDUnitName      ,
            A.MakerName          AS MakerName        ,
            A.PJTNo              AS PJTNo            , 
            A.PJTName            AS PJTName          , 
            A.WBSSeq             AS WBSSeq           , 
            A.WBSName            AS WBSName          ,
            A.CurrSeq         AS CurrSeq          ,
            A.CurrName           AS CurrName         ,
            A.Price             AS Price            ,
            A.ExRate             AS ExRate           , 
            A.CurAmt             AS CurAmt           ,
            A.CurVAT             AS CurVAT           ,
            A.DomPrice         AS DomPrice         ,
            A.DomAmt          AS DomAmt           ,
            A.DomVAT             AS DomVAT           ,
            A.IsVAT              AS IsVAT            , 
            A.TotCurAmt          AS TotCurAmt        ,         
            A.TotDomAmt          AS TotDomAmt        ,
            A.IDX_NO             AS IDX_NO           ,
            A.BOMLevel           AS BOMLevel         ,
            A.ISStd              AS ISStd            ,
            A.UMSupplyType       AS UMSupplyType     ,
            A.UMRegType          AS UMRegType        ,
            A.UMSupplyTypeName   AS UMSupplyTypeName ,
            A.UMRegTypeName      AS UMRegTypeName    ,
            A.BOMSerl            AS BOMSerl          ,
            A.LeadTime           AS LeadTime         ,
            A.ReqDelvDate        AS ReqDelvDate      ,
            A.WHSeq              AS WHSeq            ,
            A.Memo1              AS Memo1            ,
            A.Memo2              AS Memo2            ,
            A.Memo3              AS Memo3            ,
            A.Memo4              AS Memo4            ,
            A.Memo5              AS Memo5            ,            
            A.Memo6              AS Memo6            ,
            A.Memo7              AS Memo7            ,    --2015.03.17 김소록 수정      
            A.Memo8              AS Memo8            ,    --2015.03.17 김소록 수정
            A.UMinorSeq1         AS UMinorSeq1       ,
            A.UMinorSeq2         AS UMinorSeq2       ,
            A.UMinorSeq3         AS UMinorSeq3       ,
            A.WHName             AS WHName           ,
            A.BOMRev             AS BOMRev           ,
            C.CustName           AS CustName         ,
            B.CustSeq            AS CustSeq          ,
            A.PODueDate          AS PODueDate        ,
            A.VATRate            AS VATRate          ,
            A.MRPDailySeq        AS MRPDailySeq      ,
            A.MRPDailyNo         AS MRPDailyNo       ,
            A.ProdPlanSeq        AS ProdPlanSeq      ,
            A.ProdPlanNo         AS ProdPlanNo       ,
            A.CCtrSeq            AS CCtrSeq          ,
            A.CCtrName           AS CCtrName         ,
            A.SourceSeq          AS SourceSeq        ,
            A.SourceType         AS SourceType       , 
            A.Memo5Name          AS Memo5Name        
      FROM #Temp_Data AS A
                      JOIN #Temp_DIVData AS B ON A.POReqSeq  = B.POReqSeq
                                             AND A.POReqSerl = B.POReqSerl
           LEFT OUTER JOIN _TDACust      AS C ON @CompanySeq = C.CompanySeq
                                             AND B.CustSeq   = C.CustSeq
           LEFT OUTER JOIN _TDAITem      AS  D ON D.CompanySeq = @CompanySeq
                                             AND A.ItemSeq    = D.ItemSeq                                            
                      JOIN _TDAItemUnit  AS E ON A.ItemSeq    = E.ItemSeq  
                                             AND A.UnitSeq    = E.UnitSeq  
                                             AND E.CompanySeq = @CompanySeq     
                      JOIN _TDAUnit     AS  F ON D.companySEq = F.CompanySEq
                                             AND D.UnitSeq    = F.UnitSeq                                            
                                              
 END
 RETURN
 /**************************************************************************************************/