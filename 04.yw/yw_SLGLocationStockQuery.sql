
IF OBJECT_ID('yw_SLGLocationStockQuery') IS NOT NULL
    DROP PROC yw_SLGLocationStockQuery
GO
    
-- 2013.08.29 

-- Location재고조회_yw by공민하,이재천
CREATE PROC yw_SLGLocationStockQuery
    @CompanySeq     INT  = 1,
    @WHSeq			INT	 = 0 
AS
    
	CREATE TABLE #GetInOutLot 
    (      
        LotNo       NVARCHAR(30),      
        ItemSeq     INT      
    ) 

	CREATE TABLE #GetInOutLotStock (      
        WHSeq           INT,            
        FunctionWHSeq   INT,            
        LotNo           NVARCHAR(30),          
        ItemSeq         INT,            
        UnitSeq         INT,            
        PrevQty         DECIMAL(19, 5),            
        InQty           DECIMAL(19, 5),            
        OutQty          DECIMAL(19, 5),            
        StockQty        DECIMAL(19, 5),            
        STDPrevQty      DECIMAL(19, 5),            
        STDInQty        DECIMAL(19, 5),            
        STDOutQty       DECIMAL(19, 5),            
        STDStockQty     DECIMAL(19, 5)            
    )
    
    DECLARE @GETDATE NVARCHAR(8) 
    SELECT @GETDATE = CONVERT(NVARCHAR(8),GETDATE(),112) 
    
    INSERT INTO #GetInOutLot(ItemSeq, LotNo)
    SELECT  A.ItemSeq, A.LotNo
      FROM _TLGLotStock AS A WITH(NOLOCK)     
     WHERE A.CompanySeq = @CompanySeq
     GROUP BY A.ItemSeq, A.LotNo
		 
	-- 창고재고 가져오기      
    EXEC _SLGGetInOutLotStock   @CompanySeq     = @CompanySeq,  -- 법인코드            
                                @BizUnit        = 1,			-- 사업부문            
                                @FactUnit       = 0,            -- 생산사업장            
                                @DateFr         = @GETDATE,     -- 조회기간Fr            
                                @DateTo         = @GETDATE,     -- 조회기간To            
                                @WHSeq          = @WHSeq,       -- 창고지정            
                                @SMWHKind       = 0,            -- 창고구분별 조회            
                                @CustSeq        = 0,            -- 수탁거래처            
                                @IsTrustCust    = '',           -- 수탁여부            
                                @IsSubDisplay   = '',           -- 기능창고 조회            
                                @IsUnitQry      = '',           -- 단위별 조회            
                                @QryType        = 'S'           -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고            
    
    
    DELETE FROM #GetInOutLotStock WHERE StockQty <= 0  -- 0 이상인 값만 가져오기위해 삭제
    
    -- 불출요청 기준으로 데이터 담기 (진행데이터포함)
    
    SELECT   ROW_NUMBER () OVER(ORDER BY A.OutReqSeq, A.OutReqItemSerl) AS IDX_NO,
            C.WorkCond1     AS LotNo,
            E.CustSeq       AS CustSeq,
            C.WorkOrderSeq,
            C.WorkOrderSerl, 
            A.OutReqSeq,
            A.OutReqItemSerl, 
            A.ItemSeq, 
            C.AssyItemSeq   AS UpperItemSeq, 
            A.Qty
      
      INTO #TPDMMOutReqItem
      FROM _TPDMMOutReqItem             AS A WITH(NOLOCK)
      JOIN #GetInOutLotStock            AS B ON ( A.ItemSeq = B.ItemSeq ) 
      JOIN _TPDSFCWorkOrder             AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND B.LotNo = RTRIM(C.WorkCond1) 
                                                           AND A.WorkOrderSeq = C.WorkOrderSeq AND A.WorkOrderSerl = C.WorkOrderSerl 
                                                             )
      LEFT OUTER JOIN _TPDOSPPOItem     AS D WITH(NOLOCK) ON ( C.CompanySeq = D.CompanySeq AND C.WorkOrderSeq = D.WorkOrderSeq AND C.WorkOrderSerl = D.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDOSPPO         AS E WITH(NOLOCK) ON ( D.CompanySeq = E.CompanySeq AND D.OSPPOSeq = E.OSPPOSeq )       
     WHERE A.CompanySeq = @CompanySeq
    
    -- DELETE, 1 거래처가 2개 이상 있을경우 삭제 (임시테이블)
    
    SELECT ItemSeq, LotNo
      INTO #TMP_DupItemSeq
      FROM #TPDMMOutReqItem
    GROUP BY ItemSeq, LotNo
    HAVING MIN(CustSeq) <> MAX(CustSeq)   
    
    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_DupItemSeq  AS B ON ( A.ItemSeq = B.ItemSeq AND A.LotNo = B.LotNo ) 
    
    -- END, 1 
    
    -- 자재불출요청 -> 자재불출 (진행)
    
    CREATE TABLE #TMP_ProgressTable 
                 (IDOrder   INT, 
                  TableName NVARCHAR(100)) 

    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
         SELECT 1, '_TPDMMOutItem' 

    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TPDMMOutReqItem', 
            @TempTableName = '#TPDMMOutReqItem', 
            @TempSeqColumnName = 'OutReqSeq', 
            @TempSerlColumnName = 'OutReqItemSerl', 
            @TempSubSerlColumnName = ''  
    
    -- 자재불출요청 -> 자재불출 (진행) END,
    
    -- DELETE, 2 하나의 작업시지에 2개 이상의 불출요청이 있는 경우 삭제 (임시테이블)
    
    SELECT ItemSeq, LotNo
      INTO #TMP_DupCount
      FROM #TPDMMOutReqItem
    GROUP BY ItemSeq, LotNo
    HAVING MIN(OutReqSeq) <> MAX(OutReqSeq)   
    
    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_DupCount    AS B ON ( A.ItemSeq = B.ItemSeq AND A.LotNo = B.LotNo ) 
    
    -- END, 2
    
    -- DELETE, 3 요청수량과 불출수량이 같을 경우 삭제 (임시테이블)
    
    SELECT A.IDX_NO, ISNULL(SUM(B.Qty),0) AS Qty, ISNULL(SUM(C.Qty),0) AS ReqQty
      INTO #TMP_SAMEReq
      FROM #TCOMProgressTracking    AS A
      JOIN _TPDMMOUtItem            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.Seq = B.MatOutSeq AND A.Serl = OutItemSerl ) 
      JOIN #TPDMMOutReqItem         AS C              ON ( C.IDX_NO = A.IDX_NO ) 
     GROUP BY A.IDX_NO 
     HAVING ISNULL(SUM(B.Qty),0) = ISNULL(SUM(C.Qty),0) 

    DELETE A
      FROM #TPDMMOutReqItem AS A
      JOIN #TMP_SAMEReq AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    -- END, 3
        
    -- 최종조회
    
    SELECT A.LotNo      AS LotNo, 
           C.ItemNo     AS ItemNo, 
           A.StockQty   AS StockQty, 
           C.ItemName   AS ItemName, 
           A.WHSeq      AS WHSeq, 
           A.ItemSeq    AS ItemSeq, 
           D.CustName   AS CustName, 
           B.CustSeq    AS CustSeq, 
           B.OutReqSeq  AS OutReqSeq, 
           B.OutReqItemSerl AS OutReqSerl, 
           B.UpperItemSeq   AS UpperItemSeq
           
      FROM #GetInOutLotStock AS A 
      LEFT OUTER JOIN #TPDMMOutReqItem AS B ON ( B.LotNo = A.LotNo AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem         AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDACust         AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = B.CustSeq ) 
    
GO
exec yw_SLGLocationStockQuery @CompanySeq = 1, @WHSeq = 1
