IF OBJECT_ID('KPXLS_SPDOSPPOSubItemQuery') IS NOT NULL 
    DROP PROC KPXLS_SPDOSPPOSubItemQuery
GO 

-- v2016.05.23 

/*************************************************************************************************      
 설  명 - 외주발주 
 작성일 - 2008.10.20 : CREATEd by 노영진
 수정일 - 2012.04.05 : Modify by snheo  
          외주처재고 가져오는 로직 추가
		  2013.03.08 : Modify by snheo
		  자재단위를 가져오는 부분에서 실제 단위가 아닌 기준단위를 표시하고 있어서 수정
		  2014.02.12 : Modify by yhkim
		  외주처재고 단위를 기준단위에 맞게 가져오도록 수정
 수정일 - 2014.04.04 : Modify By 문학문: 창고등록에서 사업장별로 생산외주창고를 등록하도록 수정하게 되어서, 외주처재고 가져올때도 사업장을 체크
        - 2015.05.22 : Modify By 임희진: Order by 추가   
*************************************************************************************************/      
CREATE PROCEDURE KPXLS_SPDOSPPOSubItemQuery
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS         
    DECLARE   @docHandle   INT,      
              @BizUnit     INT,
              @OSPPOSeq    INT,
              @OSPMatSerl  INT,
              @OSPRev      INT,
              @ItemSeq     INT,
              @ItemNo      NVARCHAR(100),
              @CustSeq     INT,
              @FRDate      NCHAR(8),
              @TODate      NCHAR(8),
              @pItemType   INT,
              @pLast       INT,
              @FactUnit    INT, 
              @WHSeq       INT,
              @CurrDate      NCHAR(8)   
 
    --EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
    
    --SELECT 
    --        @OSPPOSeq   = ISNULL(OSPPOSeq,0)
    --FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)         
    --WITH ( OSPPOSeq INT)        
    
    -- 서비스 마스타 등록 생성
    CREATE TABLE #TPDOSPPOItemMat (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TPDOSPPOItemMat'     
    IF @@ERROR <> 0 RETURN    

    SELECT @OSPMatSerl = OSPMatSerl FROM #TPDOSPPOItemMat


    SELECT @CurrDate = CONVERT(NCHAR(8), GETDATE(), 112)  
    /******************************************************************************************
     외주처 재고 가져오는 로직
    *******************************************************************************************/
    
    --외주처재고를 가져오기 위해 외주처 가져옴
    SELECT @CustSeq = A.CustSeq,
           @FactUnit = A.FactUnit
      FROM _TPDOSPPO AS A 
                JOIN #TPDOSPPOItemMat AS B  ON A.OSPPOSeq = B.OSPPOSeq
     WHERE A.CompanySeq = @CompanySeq 

    --해당 위탁거래처에 대한 창고코드 구하기  
    SELECT @WHSeq = WHSeq   
      FROM _TDAWH   
     WHERE CompanySeq = @CompanySeq  
       AND CommissionCustSeq = @CustSeq   
       AND FactUnit = @FactUnit --문학문20140404:창고등록에서 사업장별로 생산외주창고를 등록하도록 수정하게 되어서, 외주처재고 가져올때도 사업장을 체크   


    CREATE TABLE #GetInOutItem
    (ItemSeq INT)

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
    
    INSERT INTO #GetInOutItem
    SELECT DISTINCT H.ItemSeq 
      FROM _TPDOSPPOItemMat AS H  
                JOIN #TPDOSPPOItemMat AS T               ON H.OSPPOSeq = T.OSPPOSeq   
                                                        AND (@OSPMatSerl IS NULL OR H.OSPMatSerl = T.OSPMatSerl) 
    WHERE H.CompanySeq = @CompanySeq 

  --  SELECT * FROM #GetInOutItem

    EXEC _SLGGetInOutStock    
        @CompanySeq    = @CompanySeq,       -- 법인코드    
        @BizUnit       = 0,     -- 사업부문    
        @FactUnit      = @FactUnit,       -- 생산사업장    
        @DateFr        = @CurrDate, -- 조회기간Fr    
        @DateTo        = @CurrDate, -- 조회기간To    
        @WHSeq         = @WHSeq,       -- 창고지정    
        @SMWHKind      = 0,       -- 창고구분별 조회    
        @CustSeq       = 0,       -- 수탁거래처    
        @IsSubDisplay  = '', -- 기능창고 조회    
        @IsUnitQry     = '0', -- 단위별 조회    
        @QryType       = 'S'  -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고    

    /*************************************************************************************************************/

    
    SELECT  
        K.WorkOrderNo  AS WorkOrderNo   ,
        D.ItemNo       AS AssyItemNo    , -- 외주품번
        D.ItemName     AS AssyItemName  , -- 외주품명
        D.Spec         AS AssySpec      , -- 외주규격
        E.UnitName     AS AssyUnitName  , -- 외주단위
        J.ItemNo       AS MatItemNo     , -- 자재번호
        J.ItemName     AS MatItemName   , -- 자재명
        J.Spec         AS MatSpec       , -- 자재규격
        N.UnitName     AS MatUnitName   , -- 자재단위
        H.QtyPerOne    AS Qty     , -- 개당소요량
        H.Qty          AS ReqQty        , -- 불출요청수량
        ISNULL(G.STDStockQty, 0)     AS StockQty      , -- 외주처재고
        H.Remark       AS Remark        , -- 비고
        H.StdUnitSeq   AS StdUnitSeq    , -- 기준단위코드
        L.UnitName     AS StdUnitName   , -- 기준단위
        H.StdUnitQty   AS StdUnitQty    , -- 기준단위수량
        H.ItemSeq      AS MatItemSeq    , -- 자재내부코드
        H.UnitSeq      AS UnitSeq       , -- 단위
        H.IsSale        ,
        H.Price         ,

        K.WorkOrderSeq AS WorkOrderSeq  ,
        K.WorkOrderSerl AS WorkOrderSerl, 
        A.OSPAssySeq   AS AssySeq       ,
        A.OSPPOSeq     AS OSPPOSeq      ,
        A.OSPPOSerl    AS OSPPOSerl     ,
        H.OSPMatSerl   AS OSPMatSerl    ,
        A.OSPPOSeq     AS FromSeq      ,
        A.OSPPOSerl    AS FromSerl     
        --,P.DelvReqSeq     AS FromSeq
        --,P.DelvReqSerl    AS FromSerl
        ,O.OSPMatSerl                AS FromSubSerl
        ,P.DelvReqSeq     AS Memo4
        ,P.DelvReqSerl    AS Memo5 
        
    FROM _TPDOSPPOItemMat                               AS H
                     JOIN #TPDOSPPOItemMat              AS T               ON H.OSPPOSeq = T.OSPPOSeq 
                                                                          AND (@OSPMatSerl IS NULL OR H.OSPMatSerl = T.OSPMatSerl)
                     JOIN _TPDOSPPOItem                 AS A  WITH(NOLOCK) ON H.CompanySeq = A.CompanySeq
                                                                          AND H.OSPPOSeq = A.OSPPOSeq
                                                                          AND H.OSPPOSerl = A.OSPPOSerl
                     JOIN _TPDOSPPO                     AS M  WITH(NOLOCK) ON A.CompanySeq  = M.CompanySeq
                                                                          AND A.OSPPOSeq    = M.OSPPOSeq
          LEFT OUTER JOIN _TPDSFCWorkOrder              AS K  WITH(NOLOCK) ON A.CompanySeq  = K.CompanySeq
                                                                          AND A.WorkOrderSeq= K.WorkOrderSeq  
                                                                          AND A.WorkOrderSerl = K.WorkOrderSerl
          LEFT OUTER JOIN _TDAItem                      AS D  WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq
                                                                          AND A.OSPAssySeq  = D.ItemSeq  
          LEFT OUTER JOIN _TDAUnit                      AS E  WITH(NOLOCK) ON D.CompanySeq  = E.CompanySeq
                                                                          AND D.UnitSeq     = E.UnitSeq
          LEFT OUTER JOIN _TDAItem                      AS J  WITH(NOLOCK) ON H.CompanySeq  = J.CompanySeq
                                                                          AND H.ItemSeq  = J.ItemSeq  
          LEFT OUTER JOIN _TDAUnit                      AS L  WITH(NOLOCK) ON H.CompanySeq  = L.CompanySeq
                                                                          AND H.StdUnitSeq     = L.UnitSeq
		  LEFT OUTER JOIN _TDAUnit		                AS N WITH(NOLOCK) ON H.CompanySeq     = N.CompanySeq 
											                				 AND H.UnitSeq        = N.UnitSeq
        LEFT OUTER JOIN #GetInOutStock                AS G               ON H.ItemSeq     = G.ItemSeq
                                                                          --AND H.StdUnitSeq  = G.UnitSeq     -- H.UnitSeq => H.StdUnitSeq  로 가져오도록 수정 2014.02.12 김용현
          LEFT OUTER JOIN KPXLS_TSLDelvRequest          AS O WITH(NOLOCK)ON O.CompanySeq            = A.CompanySeq
                                                                        AND O.DVReqSeq              = A.OSPPOSeq
                                                                        AND O.DVReqSerl             = A.OSPPOSerl
                                                                        AND ISNULL(O.FromPgmSeq,0)  IN(1036,1028455)
          LEFT OUTER JOIN KPXLS_TSLDelvRequestItem      AS P WITH(NOLOCK)ON @CompanySeq             = P.CompanySeq
                                                                        AND T.DelvReqSeq            = P.DelvReqSeq
                                                                        AND T.DelvReqSerl           = P.DelvReqSerl
                                                                        
    WHERE A.CompanySeq  = @CompanySeq
    ORDER BY T.IDX_NO
    
RETURN
GO


