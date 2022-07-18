
IF OBJECT_ID('DTI_SSLOrderItemQuery') IS NOT NULL
    DROP PROC DTI_SSLOrderItemQuery

GO
/*************************************************************************************************        
  설  명 - 수주품목 조회    
  작성일 - 2008.7 : CREATED BY 김준모    
  수정일 - 2009.09.21 Modify By 송경애  
          :: 할증여부 추가  
     2010. 03.19 Modify By 전경만 -- 활동센터 추가  
           2010. 08.27 Modify By 허승남   
          :: 환경설정에 추가된 임박품창고를 이용해 임박품 여부 추가  
           2010. 09.27 Modify By 허승남  
          :: LotNo 컬럼추가  
          2010.12.09 by 정혜영 - 대표품목코드 가져오는 부분 수정  
 *************************************************************************************************/        
 CREATE PROC DTI_SSLOrderItemQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE   @docHandle      INT,  
               @OrderSeq       INT,  
               @OrderSerl      INT,  
               @OrderSubSerl   INT,  
               @OrderNo        NVARCHAR(20),   
               @CustSeq        INT,  
               @ApproachWHSeq  INT   --임박품창고  
     
     -- 서비스 마스타 등록 생성    
     CREATE TABLE #TSLOrderItem (WorkingTag NCHAR(1) NULL)    
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLOrderItem'   
      SELECT @OrderSerl = OrderSerl,  
            @OrderSubSerl = OrderSubSerl  
       FROM #TSLOrderItem  
      -- 거래처품목명칭을 가져오기위해 거래처코드 조회  
     SELECT @CustSeq = B.CustSeq  
       FROM #TSLOrderItem AS A   
             LEFT OUTER JOIN _TSLOrder AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                        AND A.OrderSeq   = B.OrderSeq  
    
      --임박품 창고값을 가져옴  
       
     SELECT @ApproachWHSeq = ISNULL(EnvValue,0)   
       FROM _TCOMEnv   
      WHERE CompanySeq = @CompanySeq   
        AND EnvSeq = 8053  
    
      SELECT  A.OrderSeq             AS OrderSeq,  
             A.OrderSerl            AS OrderSerl,  
             A.OrderSubSerl         AS OrderSubSerl,  
             C.ItemName             AS ItemName,  
             C.ItemNo               AS ItemNo,  
             C.Spec                 AS Spec,  
             A.ItemSeq              AS ItemSeq,  
             A.UnitSeq              AS UnitSeq,  
             CASE WHEN ISNULL(A.UnitSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK)   
                                                              WHERE CompanySeq = @CompanySeq AND UnitSeq = A.UnitSeq) END AS UnitName,  
             A.ItemPrice            AS ItemPrice,  
             A.CustPrice            AS CustPrice,  
             CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0)  
                                                                                        ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) END) END AS Price,  
             CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN (CASE WHEN ISNULL(M.BasicAmt,0) = 0 THEN (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0) * ISNULL(O.ExRate,0)  
                                                                                                                                 ELSE (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0) * ISNULL(O.ExRate,0) / ISNULL(M.BasicAmt, 0) END)  
                                                                                        ELSE (CASE WHEN ISNULL(M.BasicAmt,0) = 0 THEN ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) * ISNULL(O.ExRate,0)  
                                                                                                                                 ELSE ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0) * ISNULL(O.ExRate,0) / ISNULL(M.BasicAmt, 0) END) END) END AS DomPrice,  
             A.Qty                  AS Qty,  
               A.IsInclusedVAT        AS IsInclusedVAT,  
             A.VATRate              AS VATRate,  
             A.CurAmt               AS CurAmt,  
             A.CurVAT               AS CurVAT,  
           A.CurAmt + A.CurVAT    AS CurAmtTotal, -- 판매금액계  
             A.DomAmt               AS DomAmt,  
             A.DomVAT               AS DomVAT,  
             A.DomAmt + A.DomVAT    AS DomAmtTotal, -- 원화판매금액계  
             CASE WHEN ISNULL(A.DVDate, '') = '' THEN ISNULL(O.DVDate, '') ELSE ISNULL(A.DVDate, '') END AS DVDate,  
             A.DVTime               AS DVTime,  
             CASE WHEN ISNULL(A.STDUnitSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK)   
                                                                 WHERE CompanySeq = @CompanySeq AND UnitSeq = A.STDUnitSeq) END AS STDUnitName,  
             A.STDUnitSeq           AS STDUnitSeq,  
             A.STDQty               AS STDQty,  
             F.WHName               AS WHName,  
             A.WHSeq                AS WHSeq,  
             CASE WHEN ISNULL(A.DVPlaceSeq,0) = 0 THEN '' ELSE (SELECT DVPlaceName FROM _TSLDeliveryCust WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND DVPlaceSeq = A.DVPlaceSeq) END AS DVPlaceName,  
             A.DVPlaceSeq           AS DVPlaceSeq,  
             A.Remark               AS Remark,  
             B.ModelName            AS ModelName,  
             B.ModelNo              AS ModelNo,  
             B.ModelSpec            AS ModelSpec,  
             A.ModelSeq             AS ModelSeq,  
             B.SMModelKind          AS SMModelKind,  
             CASE WHEN ISNULL(A.OrderSubSerl,0) = 0 AND ISNULL(D.IsOption,'0') = '1' THEN '1' ELSE '0' END AS IsOptionItem,  
             CASE WHEN ISNULL(G.OrderSeq, 0) = 0 THEN '0' ELSE '1' END AS  IsExistSalesOption,  
             CASE WHEN ISNULL(H.OrderSeq,0) = 0 THEN '0' ELSE '1' END AS  IsExistSpecOption,  
             CASE WHEN ISNULL(A.ItemSeq,0)  = 0 THEN '0' ELSE (SELECT ISNULL(IsQtyChange,'0') FROM _TDAItemStock WITH (NOLOCK)  
                                                                WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq) END AS IsQtyChange, -- 기준단위수량변경  
             A.ItemPrice - ISNULL(H.Amt,0) AS ItemPriceORG,  
             A.CustPrice - ISNULL(H.Amt,0) AS CustPriceORG,  
             CASE WHEN ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN ((ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / ISNULL(A.Qty,0)) - ISNULL(H.Amt,0)  
                                                                                        ELSE (ISNULL(A.CurAmt,0) / ISNULL(A.Qty,0)) END) - ISNULL(H.Amt,0) END AS PriceORG,  
             ISNULL(A.IsStop, '0')  AS IsStop,  
             ISNULL(A.StopEmpSeq,0) AS StopEmpSeq,  
             CASE WHEN ISNULL(A.StopEmpSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(EmpName,'') FROM _TDAEmp WHERE CompanySeq = @CompanySeq AND EmpSeq = A.StopEmpSeq) END AS StopEmpName,  
             ISNULL(A.StopDate, '') AS StopDate,  
             '' AS OptionTypeName,  
             ISNULL(A.UMEtcOutKind, 0) AS UMEtcOutKind,  
             CASE WHEN ISNULL(A.UMEtcOutKind,0) = 0 THEN '' ELSE (SELECT ISNULL(MinorName,'') FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMEtcOutKind) END AS EtcOutKindName,  
             CASE WHEN ISNULL(E.ItemSeq, 0) = 0 THEN A.ItemSeq ELSE ISNULL(E.ItemSeq, 0) END    AS STDItemSeq,  
             ISNULL(J.ItemName,'')   AS STDItemName,  
             ISNULL(J.ItemNo,'')     AS STDItemNo,  
             A.OptionSeq             AS OptionSeq,   
             ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq), '') AS CCtrName,  
             A.CCtrSeq               AS CCtrSeq,  
             X.IDX_NO                AS IDX_NO,  
             A.IsGift                AS IsGift,   -- 할증여부  
               CASE WHEN ISNULL(A.CustPrice,0) = 0 OR ISNULL(A.Qty,0) = 0 THEN 0 ELSE (CASE WHEN A.IsInclusedVAT = '1' THEN ROUND(100 - (ISNULL(A.CurAmt,0) + ISNULL(A.CurVat,0)) / (ISNULL(A.CustPrice,0) * ISNULL(A.Qty,0)) * 100,0)  
                                    ELSE ROUND(100 - (ISNULL(A.CurAmt,0) / (ISNULL(A.CustPrice,0) * ISNULL(A.Qty,0))) * 100,0) END) END AS DiscountRate,                                                                     
             ISNULL(CASE ISNULL(I.CustItemName, '')  
                    WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                            ELSE ISNULL(I.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명  
             ISNULL(CASE ISNULL(I.CustItemNo, '')   
                    WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                            ELSE ISNULL(I.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번  
             ISNULL(CASE ISNULL(I.CustItemSpec, '')   
                    WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)   
                    ELSE ISNULL(I.CustItemSpec, '') END, '')  AS CustItemSpec,  -- 거래처품목규격  
             A.PJTSeq                    AS PJTSeq,  
             A.WBSSeq                    AS WBSSeq,  
             A.Dummy1                    AS Dummy1,  
             A.Dummy2                    AS Dummy2,  
             A.Dummy3                    AS Dummy3,  
             A.Dummy4                    AS Dummy4,  
             A.Dummy5                    AS Dummy5,  
             A.Dummy6                    AS Dummy6,  
             A.Dummy7                    AS Dummy7,              
             A.Dummy8                    AS Dummy8,  
             A.Dummy9                    AS Dummy9,  
             A.Dummy10                   AS Dummy10,  
             A.BKCustSeq                 AS BKCustSeq,  
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.BKCustSeq) AS BKCustName,  
             K.PJTName     AS PJTName,   
             K.PJTNo      AS PJTNo,  
             A.CCtrSeq     AS CCtrSeq,  
    ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq), '') AS CCtrName,  
             CASE WHEN @ApproachWHSeq <> 0 THEN (CASE WHEN A.WHSeq = @ApproachWHSeq  THEN '1' ELSE '' END) ELSE '' END AS IsApproach, --임박품 여부(제약에서 사용)  
             A.LotNo                     AS LotNo  
      FROM #TSLOrderItem AS X   
           JOIN _TSLOrderItem AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq  
                                                AND X.OrderSeq    = A.OrderSeq  
                                                AND (@OrderSerl is null OR X.OrderSerl = A.OrderSerl)  
                                                AND (@OrderSubSerl is null OR X.OrderSubSerl = A.OrderSubSerl)  
           JOIN _TSLOrder AS O WITH (NOLOCK) ON A.CompanySeq = O.CompanySeq  
                                            AND A.OrderSeq   = O.OrderSeq  
           LEFT OUTER JOIN _TDAModel     AS B WITH (NOLOCK) ON A.CompanySeq  = B.CompanySeq  
                                                           AND A.ModelSeq    = B.ModelSeq  
           LEFT OUTER JOIN _TDAItem      AS C WITH (NOLOCK) ON A.CompanySeq  = C.CompanySeq  
                                                           AND A.ItemSeq     = C.ItemSeq  
           LEFT OUTER JOIN _TDAItemSales AS D WITH (NOLOCK) ON A.CompanySeq  = D.CompanySeq  
                                                           AND A.ItemSeq     = D.ItemSeq  
           LEFT OUTER JOIN _TDAWH        AS F WITH (NOLOCK) ON A.CompanySeq  = F.CompanySeq  
                                                           AND A.WHSeq       = F.WHSeq  
           LEFT OUTER JOIN _TDAModelItem AS E WITH (NOLOCK) ON A.CompanySeq  = E.CompanySeq  
                                                             AND A.ModelSeq    = E.ModelSeq  
                                                           AND E.IsStandard  = '1'  
           LEFT OUTER JOIN (SELECT X.OrderSeq, X.OrderSerl   
                              FROM _TSLOrderItem AS X WITH (NOLOCK)   
                                   JOIN #TSLOrderItem AS Y ON X.CompanySeq = @CompanySeq  
                                                          AND X.OrderSeq   = Y.OrderSeq  
       AND (@OrderSerl is null OR X.OrderSerl = Y.OrderSerl)  
                                                          AND (@OrderSubSerl is null OR X.OrderSubSerl = Y.OrderSubSerl)  
                             WHERE X.OrderSubSerl > 0  
                             GROUP BY X.OrderSeq, X.OrderSerl) AS G ON A.OrderSeq  = G.OrderSeq  
                                                               AND A.OrderSerl = G.OrderSerl  
           LEFT OUTER JOIN (SELECT X.OrderSeq, X.OrderSerl, SUM(X.Amt) AS Amt  
                              FROM _TSLOrderItemSpecOption AS X WITH (NOLOCK)  
                                   JOIN #TSLOrderItem AS Y ON X.CompanySeq = @CompanySeq  
                                                          AND X.OrderSeq   = Y.OrderSeq  
                                                          AND (@OrderSerl is null OR X.OrderSerl = Y.OrderSerl)  
                             GROUP BY X.OrderSeq, X.OrderSerl) AS H ON A.OrderSeq  = H.OrderSeq  
                                                               AND A.OrderSerl = H.OrderSerl  
           LEFT OUTER JOIN _TDAItem      AS J WITH (NOLOCK) ON E.CompanySeq  = J.CompanySeq  
                                                           AND E.ItemSeq     = J.ItemSeq  
           LEFT OUTER JOIN _TSLCustItem  AS I WITH(NOLOCK) ON A.CompanySeq = I.CompanySeq  
                                                          AND A.ItemSeq    = I.ItemSeq  
                                                          AND I.CustSeq    = @CustSeq  
                                                          AND A.UnitSeq = I.UnitSeq  
                                                          --AND (CASE WHEN A.UnitSeq = I.UnitSeq THEN A.UnitSeq ELSE 0 END) = I.UnitSeq   
                                                          --AND (A.UnitSeq   = I.UnitSeq OR (I.UnitSeq = 0 AND A.UnitSeq IS NOT NULL))  
           LEFT OUTER JOIN _TPJTProject AS K WITH(NOLOCK) ON A.CompanySeq = K.CompanySeq  
                                                         AND A.PJTSeq = K.PJTSeq  
           LEFT OUTER JOIN _TDACurr AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq  
                                                        AND O.CurrSeq    = M.CurrSeq  
     WHERE A.CompanySeq  = @CompanySeq  
     ORDER BY A.OrderSerl  
RETURN  
Go
exec DTI_SSLOrderItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <OrderSeq>90220</OrderSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016041,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001696