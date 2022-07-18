                      
IF OBJECT_ID('DTI_SSLOrderJumpItemQuery3') IS NOT NULL
    DROP PROC DTI_SSLOrderJumpItemQuery3

GO

--v2013.06.17

--구매품의_DTI 점프조회(EndUser추가) By이재천
CREATE PROC DTI_SSLOrderJumpItemQuery3                            
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
              @CustItemName   NVARCHAR(100),             
              @CustItemNo     NVARCHAR(100),             
              @CustSpec       NVARCHAR(100)            
              
    -- 서비스 마스타 등록 생성              
    CREATE TABLE #TSLOrderItem (WorkingTag NCHAR(1) NULL)              
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLOrderItem'             
            
    SELECT @OrderSeq = OrderSeq,        
           @OrderSerl = OrderSerl,            
           @OrderSubSerl = OrderSubSerl            
      FROM #TSLOrderItem            
                  
    SELECT @CustSeq = B.CustSeq            
      FROM #TSLOrderItem AS A            
            LEFT OUTER JOIN _TSLOrder AS B ON B.CompanySeq = @CompanySeq            
                                          AND A.OrderSeq   = B.OrderSeq        
      
    -----------------2010.06.29--------수주순번을 맞추기------------------        
    CREATE TABLE #Temp_DTI_TSLOrderPuPrice         
                 (CompanySeq INT,                     
                  OrderSeq INT,                    
                  OrderSerl INT ,         
                  OrderSerl_Temp INT IDENTITY,        
                  StdPuPrice DECIMAL(19, 5),                   
                  PuPrice  DECIMAL(19, 5))           
    INSERT INTO #Temp_DTI_TSLOrderPuPrice(CompanySeq, OrderSeq, OrderSerl, StdPuPrice, PuPrice)        
             SELECT @CompanySeq AS CompanySeq,        
                  OrderSeq,         
                  OrderSerl,        
                  StdPuPrice,        
                  PuPrice         
              FROM DTI_TSLOrderPuPrice WITH (NOLOCK)         
              WHERE OrderSeq = @OrderSeq        
                AND CompanySeq = @CompanySeq                    
    ----------------------------------------------------------------------          
            
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
            -------------------정수환님 업무정의 2010.06.29------------------------------------------------------------------------------          
            S.PuPrice            AS ItemPrice,              
            S.PuPrice            AS CustPrice,              
            --CASE WHEN ISNULL(A.Qty, 0) = 0 THEN 0 ELSE ISNULL(A.DomAmt, 0)/A.Qty END AS Price,--구매품의로 점프 시 단가 나오지 않는 문제로 OrderItem에서 단가 가져오도록 수정    
              S.PuPrice            AS Price,             
            S.PuPrice            AS DomPrice,             
            A.Qty                  AS Qty,              
            A.IsInclusedVAT        AS IsInclusedVAT,              
            A.VATRate              AS VATRate,           
            (S.PuPrice * A.Qty) AS CurAmt,              
            ROUND((S.PuPrice * A.Qty *(A.VATRate/100)),2)  AS CurVAT,              
            (S.PuPrice * A.Qty) + ROUND((S.PuPrice * A.Qty * (A.VATRate/100)),2) AS CurAmtTotal, -- 판매금액계  (A.VATRate/100)        
            (S.PuPrice * A.Qty)   AS DomAmt,              
            ROUND((S.PuPrice * A.Qty * (A.VATRate/100)),2) AS DomVAT,              
            (S.PuPrice * A.Qty) + ROUND((S.PuPrice * A.Qty * (A.VATRate/100)),2)    AS DomAmtTotal, -- 원화판매금액계             
            ----------------------------------------------------------------------------------------------------------------------------          
            CASE WHEN ISNULL(A.DVDate, '') = '' THEN ISNULL(O.DVDate, '') ELSE ISNULL(A.DVDate, '') END AS DVDate,            
            A.DVTime               AS DVTime,            
            CASE WHEN ISNULL(A.STDUnitSeq,0) = 0 THEN '' ELSE (SELECT ISNULL(UnitName,'') FROM _TDAUnit WITH (NOLOCK)             
                                                                WHERE CompanySeq = @CompanySeq AND UnitSeq = A.STDUnitSeq) END AS STDUnitName,            
            A.STDUnitSeq           AS STDUnitSeq,            
            A.STDQty               AS STDQty,            
            (SELECT WHName         FROM _TDAWH WHERE CompanySeq = @CompanySeq AND WHSeq = A.WHSeq)     AS WHName,            
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
            ISNULL(E.ItemSeq, 0)    AS STDItemSeq,            
            ISNULL(J.ItemName,'')   AS STDItemName,            
            ISNULL(J.ItemNo,'')     AS STDItemNo,            
            ISNULL((SELECT CCtrName FROM _TDACCtr WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND CCtrSeq = A.CCtrSeq), '') AS CCtrName,            
            A.CCtrSeq               AS CCtrSeq,            
            A.OptionSeq             AS OptionSeq,             
            O.CustSeq               AS CustSeq,             
            K.CustName              AS CustName,            
            X.IDX_NO                AS IDX_NO,            
            A.PJTSeq                AS PJTSeq,            
            A.WBSSeq                AS WBSSeq,            
            L.PJTName               AS PJTName,            
            L.PJTNo                 AS PJTNo,             
            ISNULL(CASE ISNULL(F.CustItemName, '')             
                   WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)             
                           ELSE ISNULL(F.CustItemName, '') END, '')  AS CustItemName, -- 거래처품명            
            ISNULL(CASE ISNULL(F.CustItemNo, '')             
                   WHEN '' THEN (SELECT CI.CustItemNo FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)             
                           ELSE ISNULL(F.CustItemNo, '') END, '')        AS CustItemNo,   -- 거래처품번            
            ISNULL(CASE ISNULL(F.CustItemSpec, '')             
                   WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = @CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)             
                   ELSE ISNULL(F.CustItemSpec, '') END, '')  AS CustItemSpec,   -- 거래처품목규격            
            A.BKCustSeq AS BKCustSeq,   -- EndUser코드
            Z.CustName  AS BKCustName   -- EndUser
                   
     FROM #TSLOrderItem AS X             
          JOIN _TSLOrderItem AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq            
                                               AND X.OrderSeq    = A.OrderSeq            
                                               AND (@OrderSerl is null OR X.OrderSerl = A.OrderSerl)            
                                               AND (@OrderSubSerl is null OR X.OrderSubSerl = A.OrderSubSerl)            
                                               AND A.IsStop <> '1'   -- 중단품목건은 빼고 넘긴다.            
                                               AND NOT EXISTS ( SELECT OrderSeq FROM DTI_TLGLotOrderConnect WHERE CompanySeq = @CompanySeq AND OrderSeq =A.OrderSeq AND OrderSerl = A.OrderSerl )  --할당된 수주껀은 제외하고.2010.05.26          
          JOIN _TSLOrder AS O WITH (NOLOCK) ON A.CompanySeq = O.CompanySeq            
                                           AND A.OrderSeq   = O.OrderSeq          
          ---------------------------------------------------------------------------------------------2010.06.29 수주GP에 있는 단가로         
          LEFT OUTER JOIN #Temp_DTI_TSLOrderPuPrice AS S WITH (NOLOCK)  ON S.CompanySeq = @CompanySeq            
                                                                       AND X.OrderSeq   = S.OrderSeq            
                                                                       AND X.OrderSerl  = S.OrderSerl           
          ---------------------------------------------------------------------------------------------         
          LEFT OUTER JOIN _TDAModel     AS B WITH (NOLOCK) ON A.CompanySeq  = B.CompanySeq            
                                                          AND A.ModelSeq    = B.ModelSeq            
          LEFT OUTER JOIN _TDAItem      AS C WITH (NOLOCK) ON A.CompanySeq  = C.CompanySeq            
                                                          AND A.ItemSeq     = C.ItemSeq            
              LEFT OUTER JOIN _TDAItemSales AS D WITH (NOLOCK) ON A.CompanySeq   = D.CompanySeq            
                                                          AND A.ItemSeq     = D.ItemSeq            
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
          LEFT OUTER JOIN _TDACust      AS K WITH(NOLOCK) ON O.CompanySeq = K.CompanySeq            
                                                         AND O.CustSeq    = K.CustSeq            
          LEFT OUTER JOIN _TPJTProject AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq            
                                                        AND A.PJTSeq = L.PJTSeq            
          LEFT OUTER JOIN _TDACurr AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq            
                                                       AND O.CurrSeq    = M.CurrSeq            
          LEFT OUTER JOIN _TSLCustItem AS F WITH(NOLOCK) ON F.CompanySeq = @CompanySeq            
                                                        AND F.CustSeq    = @CustSeq            
                                                        AND F.ItemSeq    = A.ItemSeq            
                                                        AND F.UnitSeq    = A.UnitSeq   
          LEFT OUTER JOIN _TDACust    AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND Z.CustSeq = A.BKCustSeq )          
    WHERE A.CompanySeq  = @CompanySeq            
    ORDER BY A.OrderSerl          
        
    DROP TABLE #Temp_DTI_TSLOrderPuPrice          
        
  RETURN               

GO
exec DTI_SSLOrderJumpItemQuery3 @xmlDocument=N'<ROOT>
  <DataBlock2>
    <OrderSeq>90228</OrderSeq>
    <OrderSerl>1</OrderSerl>
    <OrderSubSerl>0</OrderSubSerl>
    <IDX_NO>1</IDX_NO>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016041,@WorkingTag=N'POReq',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001652