
IF OBJECT_ID('yw_SSLOrderChgListQuery') IS NOT NULL
    DROP PROC yw_SSLOrderChgListQuery
GO

-- v2013.07.11

-- 수주변경이력_YM(조회) by 이재천
CREATE PROC yw_SSLOrderChgListQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10) = '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle       INT, 
            @EmpSeq          INT, 
            @Orderstatus     INT, 
            @ItemName        NVARCHAR(200), 
            @OrderItemNo     NVARCHAR(200), 
            @ExportKind      INT, 
            @ExportKindName  NVARCHAR(100), 
            @ItemNo          NVARCHAR(100), 
            @OrderNo         NVARCHAR(20), 
            @RevDateTo       NCHAR(8), 
            @CustName        NVARCHAR(100), 
            @OrderDateFr     NCHAR(8), 
            @OrderDateTo     NCHAR(8), 
            @DeptSeq         INT, 
            @RevDateFr       NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @EmpSeq          = EmpSeq, 
           @Orderstatus     = Orderstatus, 
           @ItemName        = ItemName, 
           @OrderItemNo     = OrderItemNo, 
           @ExportKind      = ExportKind, 
           @ExPortKindName  = ExportKindName,
           @ItemNo          = ItemNo, 
           @OrderNo         = OrderNo, 
           @RevDateTo       = RevDateTo, 
           @CustName        = CustName, 
           @OrderDateFr     = OrderDateFr, 
           @OrderDateTo     = OrderDateTo, 
           @DeptSeq         = DeptSeq, 
           @RevDateFr       = RevDateFr        
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            EmpSeq           INT, 
            Orderstatus      INT, 
            ItemName         NVARCHAR(200), 
            OrderItemNo      NVARCHAR(200), 
            ExportKind       INT, 
            ExportKindName   NVARCHAR(100), 
            ItemNo           NVARCHAR(100), 
            OrderNo          NVARCHAR(20), 
            RevDateTo        NCHAR(8), 
            CustName         NVARCHAR(100), 
            OrderDateFr      NCHAR(8), 
            OrderDateTo      NCHAR(8), 
            DeptSeq          INT, 
            RevDateFr        NCHAR(8) 
           )

    IF @OrderDateFr = '' SELECT @OrderDateFr = '10000101'
    IF @OrderDateTo = '' SELECT @OrderDateTo = '99991231'

    -- 수주진행 Table    
    CREATE TABLE #Tmp_OrderItemSLProg(IDX_NO INT IDENTITY, OrderSeq INT, OrderSerl INT, OrderSubSerl INT, CompleteCHECK INT, SMProgressType INT NULL, IsStop NCHAR(1), SMConfirm INT)    
    
    ---------------------- 조직도 연결 여부    
    DECLARE @SMOrgSortSeq INT, @OrgStdDate NCHAR(8)    
    
    IF @OrderDateTo = '99991231'    
        SELECT @OrgStdDate = CONVERT(NCHAR(8), GETDATE(), 112)    
    ELSE 
        SELECT @OrgStdDate = @OrderDateTo    
    
    SELECT @SMOrgSortSeq = 0    
    SELECT @SMOrgSortSeq = SMOrgSortSeq    
      FROM _TCOMOrgLinkMng 
     WHERE CompanySeq = @CompanySeq 
       AND PgmSeq = @PgmSeq 
    
    DECLARE @DeptTable Table    
        ( DeptSeq INT)    
    
    INSERT @DeptTable    
    SELECT DISTINCT DeptSeq    
      FROM dbo._fnOrgDept(@CompanySeq, @SMOrgSortSeq, @DeptSeq, @OrgStdDate)    

    ---------------------- 조직도 연결 여부    
      
    INSERT INTO #Tmp_OrderItemSLProg(OrderSeq, OrderSerl, OrderSubSerl, CompleteCHECK, IsStop)    
    SELECT A.OrderSeq, B.OrderSerl, B.OrderSubSerl, -1, B.IsStop    
      FROM _TSLOrder     AS A WITH(NOLOCK)     
      JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.OrderSeq = B.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND A.SMExpKind = C.MinorSeq AND C.Serl = 1001 ) 
    
     WHERE A.CompanySeq = @CompanySeq      
       AND A.OrderDate BETWEEN @RevDateFr AND @RevDateTo
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')

    ---------------------------------------------------------------------------------------------------------  
    -- 진행상태 구하기 (영업)
    ---------------------------------------------------------------------------------------------------------  
      
    EXEC _SCOMProgStatus @CompanySeq, '_TSLOrderItem', 1036001, '#Tmp_OrderItemSLProg',    
                         'OrderSeq', 'OrderSerl', 'OrderSubSerl', '', '', '', '', '',    
                         'CompleteCHECK', 1, 'Qty', 'STDQty', 'CurAmt', 'CurVAT',    
                         'OrderSeq', 'OrderSerl', '', '_TSLOrder' , @PgmSeq      
    
    UPDATE #Tmp_OrderItemSLProg     
       SET SMProgressType = (SELECT CASE WHEN A.IsStop = '1' AND B.MinorSeq = 1037006 THEN 1037007 --진행중단    
                                         WHEN B.MinorSeq = 1037009 THEN 1037009 -- 완료    
                                         WHEN A.IsStop = '1' THEN 1037005 -- 중단    
                                         ELSE B.MinorSeq END)    
      FROM #Tmp_OrderItemSLProg AS A    
      LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON ( B.MajorSeq = 1037 AND A.CompleteCHECK = B.Minorvalue ) 
    
    -- 내수/수출구분 조회하기 위해서 담기
    CREATE TABLE #ExpKind 
        (
         OrderSeq   INT,
         OrderSerl  INT,
         OrderRev   INT,
         ExportKind INT,
         ItemSeq    INT
        )
        
    INSERT INTO #ExpKind (OrderSeq, OrderSerl, OrderRev, ExportKind,ItemSeq)
    
    SELECT A.OrderSeq, B.OrderSerl, A.OrderRev, CASE WHEN C.ValueText = '1' THEN 8918001 ELSE 8918002 END AS ExportKind, B.ItemSeq
      FROM _TSLOrder AS A
      LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMExpKind AND C.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.OrderDate BETWEEN @RevDateFr AND @RevDateTo 
    
    UNION ALL
    
    SELECT A.OrderSeq, A.OrderSerl, A.OrderRev, CASE WHEN C.ValueText = '1' THEN 8918001 ELSE 8918002 END AS ExportKind, A.ItemSeq
      FROM _TSLOrderItemRev           AS A 
      LEFT OUTER JOIN _TSLOrderRev    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TSLOrder       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.SMExpKind AND C.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.OrderRevDate BETWEEN @RevDateFr AND @RevDateTo 

    -- 최종조회
    
    SELECT CASE WHEN N.ValueText = '1' THEN '내수' ELSE '수출' END AS ExportKindName, -- 내수/수출 구분 
           A.OrderSeq, 
           B.OrderSerl,
           A.OrderRev, -- Amd차수
           CASE WHEN A.OrderRevDate = '' THEN A.OrderDate ELSE A.OrderRevDate END AS OrderRevDate, -- 차수일자
           A.OrderDate, -- 수주일자
           A.OrderNo, -- 수주번호
           A.PONo,
           D.CustName,
           A.CustSeq,
           E.DeptName,
           A.DeptSeq,
           F.EmpName,
           A.EmpSeq,
           -- 변경사유
           A.Remark, 
           G.ItemClasLName, -- 품목대분류
           G.ItemClassLSeq, -- 품목대분류코드
           C.ItemName, 
           B.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           I.CustItemNo, -- 거래처품번
           B.Dummy1   AS OrderItemNo, -- 주문관리번호
           J.UnitName AS STDUnitName, -- 기준단위
           B.Price, -- 판매단가
           O.CustName AS DVPlaceName, -- 납품처
           B.DVPlaceSeq, 
           CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END AS Qty,
           CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END AS DiscountPrice, -- 단가
           (
            SELECT (Qty - B.Qty) * Price
              FROM _TSLOrderItemRev 
             WHERE CompanySeq = @CompanySeq AND OrderSeq = B.OrderSeq AND OrderSerl = B.OrderSerl AND OrderRev = (B.OrderRev - 1) AND UMEtcOutKind = 0
           ) AS CancleAmt, -- 취소금액
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN B.Price - R.DiscountPrice ELSE B.Price END) AS CurAmt, -- 판매금액
           B.CurVAT,
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END) + B.CurVAT AS TotCurAmt, -- 판매금액계
           (CASE WHEN B.UMEtcOutKind <> 0 THEN B.Qty ELSE 0 END) AS ExtraQty, -- 여유분 수량
           
           -- 추가정보 기본정보(HID) --
           I.CustItemName, -- 거래처품명
           I.CustItemSpec, -- 거래처품목규격
           S.UnitName, -- 판매단위
           B.ItemPrice, -- 정가
           B.CustPrice, -- 판매기준가
           T.WHName, -- 창고
           B.IsInclusedVAT, -- 부가세포함여부
           B.VATRate, -- 부가세율
           B.DomAmt, -- 원화판매금액
           B.DomVAT, -- 원화부가세
           B.DomAmt + B.DomVAT AS DomAmtTotal, -- 원화판매금액계
           B.STDQty, -- 기준단위수량
           B.DVDate, -- 납기일
           B.DVTime, -- 납품시분
           B.Remark AS SheetRemark, -- Item 비고
           U.CCtrName -- 활동센터                      
      
      FROM _TSLOrderRev AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TSLOrderItemRev  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq AND B.OrderRev = A.OrderRev ) 
      LEFT OUTER JOIN _TSLOrder         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TSLOrderItem     AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.OrderSeq = B.OrderSeq AND L.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _fdagetitemclass(@CompanySeq ,0) AS G ON ( G.ItemSeq = B.ItemSeq )
      LEFT OUTER JOIN _TDACust          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TSLCustItem      AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq AND I.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.UnitSeq = B.STDUnitSeq ) 
      LEFT OUTER JOIN _TSLExpOrder      AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = H.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = H.SMExpKind AND N.Serl = 1001 )
      LEFT OUTER JOIN _TDACust          AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = B.DVPlaceSeq ) 
      LEFT OUTER JOIN #Tmp_OrderItemSLProg AS P ON ( P.OrderSeq = B.OrderSeq AND P.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN #ExpKind          AS Q ON ( Q.OrderSeq = B.OrderSeq AND Q.OrderSerl = B.OrderSerl AND Q.OrderRev = B.OrderRev ) 
      LEFT OUTER JOIN _TSLCustItemPrice AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = A.CustSeq AND R.ItemSeq = B.ItemSeq AND R.SMPriceKind = 8011002 ) 
      LEFT OUTER JOIN _TDAUnit          AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAWH            AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.WHSeq = B.WHSeq ) 
      LEFT OUTER JOIN _TDACCtr          AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.CCtrSeq = B.CCtrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq
       AND (CASE WHEN A.OrderRevDate = '' THEN A.OrderDate
                                          ELSE A.OrderRevDate
                                          END
           )  BETWEEN @RevDateFr AND @RevDateTo 
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')
       AND (@CustName = '' OR D.CustName LIKE @CustName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@OrderItemNo = '' OR B.Dummy1 LIKE @OrderItemNo + '%')
       AND A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo
       AND (@Orderstatus = 0 OR P.SMProgressType = @Orderstatus)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@ExportKind = 0 OR Q.ExportKind = @ExportKind)

UNION ALL

    SELECT CASE WHEN N.ValueText = '1' THEN '내수' ELSE '수출' END AS ExportKindName, -- 내수/수출 구분 
           A.OrderSeq, 
           B.OrderSerl,
           A.OrderRev, -- Amd차수
           A.OrderRevDate, -- 차수일자
           A.OrderDate, -- 수주일자
           A.OrderNo, -- 수주번호
           A.PONo,
           D.CustName,
           A.CustSeq,
           E.DeptName,
           A.DeptSeq,
           F.EmpName,
           A.EmpSeq,
           -- 변경사유
           A.Remark, 
           G.ItemClasLName, -- 품목대분류
           G.ItemClassLSeq, -- 품목대분류코드
           C.ItemName, 
           B.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           I.CustItemNo, -- 거래처품번
           B.Dummy1   AS OrderItemNo, -- 주문관리번호
           J.UnitName AS STDUnitName, -- 기준단위
           B.Price, -- 판매단가
           O.CustName AS DVPlaceName, -- 납품처
           B.DVPlaceSeq, 
           CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END AS Qty,
           CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END AS DiscountPrice, -- 단가
           (
            SELECT (Qty - B.Qty) * Price
              FROM _TSLOrderItemRev AS A 
             WHERE CompanySeq = @CompanySeq
               AND OrderSeq = B.OrderSeq AND OrderSerl = B.OrderSerl AND UMEtcOutKind = 0 
               AND OrderRev = (SELECT MAX(OrderRev) 
                                 FROM _TSLOrderItemRev 
                                WHERE CompanySeq = @CompanySeq AND OrderSeq = A.OrderSeq AND OrderSerl = A.OrderSerl
                              )
           ) AS CancleAmt, -- 취소금액
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN B.Price - R.DiscountPrice ELSE B.Price END) AS CurAmt, -- 판매금액
           B.CurVAT,
           (CASE WHEN B.UMEtcOutKind = 0 THEN B.Qty ELSE 0 END * 
            CASE WHEN R.DiscountPrice <> 0 THEN R.DiscountPrice ELSE B.Price END) + B.CurVAT AS TotCurAmt, -- 판매금액계
           (CASE WHEN B.UMEtcOutKind <> 0 THEN B.Qty ELSE 0 END) AS ExtraQty, -- 여유분 수량
          
           -- 추가정보 기본정보(HID) --
           I.CustItemName, -- 거래처품명
           I.CustItemSpec, -- 거래처품목규격
           S.UnitName, -- 판매단위
           B.ItemPrice, -- 정가
           B.CustPrice, -- 판매기준가
           T.WHName, -- 창고
           B.IsInclusedVAT, -- 부가세포함여부
           B.VATRate, -- 부가세율
           B.DomAmt, -- 원화판매금액
           B.DomVAT, -- 원화부가세
           B.DomAmt + B.DomVAT AS DomAmtTotal, -- 원화판매금액계
           B.STDQty, -- 기준단위수량
           B.DVDate, -- 납기일
           B.DVTime, -- 납품시분
           B.Remark AS SheetRemark, -- Item 비고
           U.CCtrName -- 활동센터
              
      FROM _TSLOrder AS A
      LEFT OUTER JOIN _TSLOrderItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq )
      LEFT OUTER JOIN _TDAItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _fdagetitemclass(@CompanySeq ,0) AS G ON ( G.ItemSeq = B.ItemSeq )
      LEFT OUTER JOIN _TDACust          AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDADept          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TSLCustItem      AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = A.CustSeq AND I.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.UnitSeq = B.STDUnitSeq ) 
      LEFT OUTER JOIN _TSLExpOrder      AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.OrderSeq = A.OrderSeq ) 
      LEFT OUTER JOIN _TDASMinorValue   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.SMExpKind AND N.Serl = 1001 )
      LEFT OUTER JOIN _TDACust          AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = B.DVPlaceSeq ) 
      LEFT OUTER JOIN #Tmp_OrderItemSLProg AS P ON ( P.OrderSeq = B.OrderSeq AND P.OrderSerl = B.OrderSerl ) 
      LEFT OUTER JOIN #ExpKind          AS Q ON ( Q.OrderSeq = B.OrderSeq AND Q.OrderSerl = B.OrderSerl AND Q.OrderRev = A.OrderRev ) 
      LEFT OUTER JOIN _TSLCustItemPrice AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.CustSeq = A.CustSeq AND R.ItemSeq = B.ItemSeq AND R.SMPriceKind = 8011002 ) 
      LEFT OUTER JOIN _TDAUnit          AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAWH            AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.WHSeq = B.WHSeq ) 
      LEFT OUTER JOIN _TDACCtr          AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.CCtrSeq = B.CCtrSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq
       AND (CASE WHEN A.OrderRevDate = '' THEN A.OrderDate
                                          ELSE A.OrderRevDate
                                          END
           )  BETWEEN @RevDateFr AND @RevDateTo 
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%')
       AND (@CustName = '' OR D.CustName LIKE @CustName + '%')
       AND (@ItemNo = '' OR C.ItemNo LIKE @ItemNo + '%')
       AND (@ItemName = '' OR C.ItemName LIKE @ItemName + '%')
       AND (@OrderItemNo = '' OR B.Dummy1 LIKE @OrderItemNo + '%')
       AND A.OrderDate BETWEEN @OrderDateFr AND @OrderDateTo
       AND (@Orderstatus = 0 OR P.SMProgressType = @Orderstatus)
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq)
       AND (@ExportKind = 0 OR Q.ExportKind = @ExportKind)
     ORDER BY A.OrderSeq, B.ItemSeq, A.OrderRev, B.OrderSerl
 
    RETURN
GO
exec yw_SSLOrderChgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RevDateFr>99991231</RevDateFr>
    <RevDateTo>99991231</RevDateTo>
    <OrderNo />
    <CustName />
    <ItemNo />
    <ItemName />
    <OrderItemNo></OrderItemNo>
    <OrderDateFr />
    <OrderDateTo />
    <Orderstatus />
    <OrderstatusName />
    <DeptSeq />
    <DeptName />
    <EmpSeq />
    <EmpName />
    <ExportKind />
    <ExportKindName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016510,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014109