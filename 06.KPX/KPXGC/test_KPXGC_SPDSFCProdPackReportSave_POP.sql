IF OBJECT_ID('test_KPXGC_SPDSFCProdPackReportSave_POP') IS NOT NULL 
    DROP PROC test_KPXGC_SPDSFCProdPackReportSave_POP
GO 

-- v2016.10.05
      
-- POP 연동 생산실적입력(Lot대체, 이동처리) by이재천     
      
/*********************************************************************************************************  
  
-- Relation Table의 DataKind   
  
1 - 포장실적 전함바 Lot 대체(공정)
2 - 포장실적 생산수량 저장탱크로 이동 (공정)
3 - 포장실적 일반 Lot을 전함바 Lot로 대체 (공정)  
4 - 포장실적 Lot대체 (탱크)   
5 - 포장실적 생산수량 저장탱크로 이동(탱크)
6 - 용기 기타출고 

*********************************************************************************************************/  
 CREATE PROC test_KPXGC_SPDSFCProdPackReportSave_POP
    @CompanySeq INT ,
	@WorkDate   NVARCHAR(8) = '',
	@IFPOPSeq		INT = 0
    
AS       
    DECLARE @StdYM NCHAR(6),
			@DateFr NVARCHAR(8),
			@DateTo NVARCHAR(8)

	-- 물류시작월 가져오기
    DECLARE @LGstartEnv     NVARCHAR(10)
    EXEC dbo._SCOMEnv @CompanySeq,1006,1,0,@LGstartEnv OUTPUT  

	--SELECT @StdYM = MIN(ClosingYM) FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq = 69 AND IsClose <> '1' AND ClosingYM > @LGstartEnv
	SELECT @StdYM = MAX(ClosingYM) FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq = 69 AND IsClose = '1' AND UnitSeq IN (1,3) AND ClosingYM > @LGstartEnv

	SELECT @DateFr = CONVERT(NCHAR(6), GETDATE(), 112) + '01', @DateTo = CONVERT(NCHAR(8), GETDATE(), 112)

	SELECT @DateFr = LEFT(@DateFr, 6), @DateTo = LEFT(@DateTo, 6) 
	

    -- 대상품목 
    CREATE TABLE #GetInOutItem
    ( 
        ItemSeq INT, 
        ItemClassSSeq INT, ItemClassSName NVARCHAR(200), -- 품목소분류
        ItemClassMSeq INT, ItemClassMName NVARCHAR(200), -- 품목중분류
        ItemClassLSeq INT, ItemClassLName NVARCHAR(200)  -- 품목대분류
    )


    -- 입출고
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

    -- 상세입출고내역 
    --CREATE TABLE #TLGInOutStock  
    --(  
    --    InOutType INT,  
    --    InOutSeq  INT,  
    --    InOutSerl INT,  
    --    DataKind  INT,  
    --    InOutSubSerl  INT,
    --    InOut INT,  
    --    InOutDate NCHAR(8),  
    --    WHSeq INT,  
    --    FunctionWHSeq INT,  
    --    ItemSeq INT,  
    --    UnitSeq INT,  
    --    Qty DECIMAL(19,5),  
    --    StdQty DECIMAL(19,5),
    --    InOutKind INT,
    --    InOutDetailKind INT 
    --)  


    CREATE TABLE #TLGInOutStock (
        InOutType           INT,
        InOutSeq            INT,
        InOutSerl           INT,
        DataKind            INT DEFAULT 0,
        InOutDataSerl       INT DEFAULT 0,
        InOutSubSerl        INT,
        InOut               INT,
        InOutYM             NCHAR(6),
        InOutDate           NCHAR(8),
        WHSeq               INT,
        FunctionWHSeq       INT,
        ItemSeq             INT,
        UnitSeq             INT,
        Qty                 DECIMAL(19, 5),
        StdQty              DECIMAL(19, 5),
        Amt                 DECIMAL(19, 5),
        InOutKind           INT,
        InOutDetailKind     INT
    )

	CREATE TABLE #GetInOutLot    
    (      
        LotNo         NVARCHAR(30),    
        ItemSeq       INT  
    )      

    CREATE TABLE #GetInOutLotStock      
    (      
        WHSeq           INT,      
        FunctionWHSeq   INT,      
        LotNo           NVARCHAR(30),    
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


    CREATE TABLE #BaseData       
    (      
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )      
    
    -- 기초 데이터 
    INSERT INTO #BaseData 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )        
    SELECT TOP 10 A.Seq, A.WorkingTag, C.FactUnit, A.IsPacking, A.WorkOrderSeq, 
           A.WorkOrderSerl, ISNULL(E.SourceSeq,0), ISNULL(E.SourceSerl,0), A.GoodItemSeq, A.SubQty * E.PackingQty, --ISNULL(A.ProdQty,0) - (ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0)) - ISNULL(D.UseQty,0), 
           A.RealLotNo, ISNULL(A.HambaQty,0) + ISNULL(A.DrainQty,0), A.WorkStartDate, ISNULL(A.ProdQty,0), ISNULL(D.UseQty,0), 
           CASE WHEN ISNULL(E.OutWHSeq,0) = 0 THEN ISNULL(F.OutWHSeq, 0) ELSE ISNULL(E.OutWHSeq,0) END, 
		   CASE WHEN ISNULL(E.InWHSeq,0) = 0 THEN ISNULL(F.InWHSeq,0) ELSE ISNULL(E.InWHSeq,0) END, E.SubItemSeq, A.SubQty, 
		   CASE WHEN ISNULL(E.SubOutWHSeq,0) = 0 THEN ISNULL(F.SubOutWHSeq,0) ELSE ISNULL(E.SubOutWHSeq,0) END, 
           F.UMProgType 
      FROM KPX_TPDSFCWorkReport_POP AS A       
      OUTER APPLY ( SELECT Z.FactUnit , Z.SourceSeq, Z.SourceSerl   
                     FROM KPX_TPDSFCWorkOrder_POP AS Z     
                    WHERE Z.CompanySeq = @CompanySeq     
                      AND Z.WorkOrderSeq = A.WorkOrderSeq     
                      AND Z.WorkorderSerl = A.WorkOrderSerl     
                      AND Z.IsPacking = A.IsPacking     
                      AND Z.Serl = (     
                                    SELECT MAX(Serl) AS Serl     
                                      FROM KPX_TPDSFCWorkOrder_POP AS Y    
                                     WHERE Y.companyseq = @CompanySeq      
                                       AND Y.WorkOrderSeq = Z.WorkOrderSeq    
                                       AND Y.WorkOrderSerl = Z.WorkOrderSerl    
                                   )    
                 ) AS C   
      OUTER APPLY (  
                    SELECT SUM(UseQty) AS UseQty 
                      FROM KPX_TPDPackingHanbaInPut_POP AS Z   
                     WHERE Z.CompanySeq = @CompanySeq   
                       AND Z.WorkOrderSeq = A.WorkOrderSeq   
                       AND Z.WorkOrderSerl = A.WorkOrderSerl   
                 ) AS D 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS E ON ( E.CompanySeq = @CompanySeq AND E.PackOrderSeq = A.WorkOrderSeq AND E.PackOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder       AS F ON ( F.CompanySeq = @CompanySeq AND F.PackOrderSeq = E.PackOrderSeq ) 
	  
     WHERE A.ProcYn = '0'         
       AND A.IsPacking = '1'         
       AND ISNULL(C.FactUnit,0) <> 0       
       AND ISNULL(A.WorkStartDate,'') <> '' 
	   AND (@IFPOPSeq = 0 OR A.Seq = @IFPOPSeq)
	   ----and A.WorkOrderSeq= 1599 
	   --AND A.WorkingTag = 'A'
	   ----and A.IFWorkReportSeq = '2015090100012' 
	   AND (@WorkDate = '' OR A.WorkStartDate LIKE @WorkDate + '%' )
	  AND LEFT(A.WorkStartDate, 6)  > @StdYM
	  AND NOT EXISTS (SELECT ClosingYM FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq  = 69 AND ClosingYM = LEFT(A.WorkStartDate, 6) AND IsClose = '1' AND UnitSeq IN (1, 3)) 
     ORDER BY A.Seq


	/* 마이너스 재고체크 */
    TRUNCATE TABLE #GetInOutItem
	TRUNCATE TABLE #GetInOutStock
	TRUNCATE TABLE #TLGInOutStock

	-- 대상품목 담기 
    INSERT INTO #GetInOutItem
    ( 
        ItemSeq, 
        ItemClassSSeq, ItemClassSName, -- 품목소분류
        ItemClassMSeq, ItemClassMName, -- 품목중분류
        ItemClassLSeq, ItemClassLName  -- 품목대분류
    )

    SELECT DISTINCT A.ItemSeq,
           C.MinorSeq AS ItemClassSSeq, C.MinorName AS ItemClassSName, -- '품목소분류' 
	       E.MinorSeq AS ItemClassMSeq, E.MinorName AS ItemClassMName, -- '품목중분류' 
	       G.MinorSeq AS ItemClassLSeq, G.MinorName AS ItemClassLName  -- '품목대분류' 		  
      FROM _TDAItem                     AS A WITH (NOLOCK)
      JOIN _TDAItemSales                AS H WITH (NOLOCK) ON A.CompanySeq = H.CompanySeq AND A.ItemSeq = H.ItemSeq 
      JOIN _TDAItemAsset                AS I WITH (NOLOCK) ON A.CompanySeq = I.CompanySeq AND A.AssetSeq = I.AssetSeq -- 품목자산분류       
      -- 소분류 
      LEFT OUTER JOIN _TDAItemClass	    AS B WITH(NOLOCK) ON ( A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) AND A.CompanySeq = B.CompanySeq )
      LEFT OUTER JOIN _TDAUMinor		AS C WITH(NOLOCK) ON ( B.UMItemClass = C.MinorSeq AND B.CompanySeq = C.CompanySeq AND C.IsUse = '1' )
      LEFT OUTER JOIN _TDAUMinorValue	AS D WITH(NOLOCK) ON ( C.MinorSeq = D.MinorSeq AND D.Serl in (1001,2001) AND C.MajorSeq = D.MajorSeq AND C.CompanySeq = D.CompanySeq )
      -- 중분류 
      LEFT OUTER JOIN _TDAUMinor		AS E WITH(NOLOCK) ON ( D.ValueSeq = E.MinorSeq AND D.CompanySeq = E.CompanySeq AND E.IsUse = '1' )
      LEFT OUTER JOIN _TDAUMinorValue	AS F WITH(NOLOCK) ON ( E.MinorSeq = F.MinorSeq AND F.Serl = 2001 AND E.MajorSeq = F.MajorSeq AND E.CompanySeq = F.CompanySeq )
      -- 대분류 
      LEFT OUTER JOIN _TDAUMinor		AS G WITH(NOLOCK) ON ( F.ValueSeq = G.MinorSeq AND F.CompanySeq = G.CompanySeq AND G.IsUse = '1' )
	  LEFT OUTER JOIN _TDAItemAsset		AS J WITH(NOLOCK) ON ( J.CompanySeq = A.CompanySeq AND J.AssetSeq = A.AssetSeq)
	  LEFT OUTER JOIN _TDASMinor		AS K WITH(NOLOCK) ON ( K.CompanySeq = J.CompanySeq AND K.MinorSeq = J.SMAssetGrp)
     WHERE A.CompanySeq = @CompanySeq
       AND I.IsQty <> '1' -- 재고수량 관리 

    -- 창고재고 가져오기	 
    EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드
                           @BizUnit      = 0,	  -- 사업부문
						   @FactUnit     = 0,     -- 생산사업장
                           @DateFr       = @DateFr,       -- 조회기간Fr
                           @DateTo       = @DateTo,       -- 조회기간To
                           @WHSeq        = 0,			  -- 창고지정
                           @SMWHKind     = 0,			  -- 창고구분 
                           @CustSeq      = 0,			  -- 수탁거래처
                           @IsTrustCust  = '',			  -- 수탁여부
                           @IsSubDisplay = 0,			 -- 기능창고 조회
                           @IsUnitQry    = 0,    -- 단위별 조회
                           @QryType      = 'S',      -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고
                           @MngDeptSeq   =  0,
                           @IsUseDetail  = '1'


    SELECT A.CompanySeq,
           A.ItemSeq,
           G.ItemClassSSeq,
           G.ItemClassSName,
           G.ItemClassMSeq,
           G.ItemClassMName,
           G.ItemClassLSeq,
           G.ItemClassLName
      INTO #TEMP_TDAItem
      FROM _TDAItem AS A WITH(NOLOCK)
           JOIN _TDAItemSales AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ItemSeq =A.ItemSeq
           JOIN _TDAItemStock AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.ItemSeq =A.ItemSeq
           JOIN _TDAItemAsset AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq AND D.AssetSeq =A.AssetSeq
           LEFT OUTER JOIN _TDAItemClass AS F WITH(NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.ItemSeq = A.ItemSeq AND F.UMajorItemClass IN (2001, 2004) 
           LEFT OUTER JOIN _VDAItemClass AS G WITH(NOLOCK) ON G.CompanySeq = A.CompanySeq AND G.ItemClassSSeq = F.UMItemClass
     WHERE A.CompanySeq = 1
       AND C.IsLotMng = '1'
       AND D.IsQty <> '1'  

	
	TRUNCATE TABLE #GetInOutLot 
	TRUNCATE TABLE #GetInOutLotStock

    INSERT INTO #GetInOutLot
    SELECT DISTINCT
           B.LotNo,
           A.ItemSeq
      FROM #TEMP_TDAItem AS A
           JOIN _TLGLotStock AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.ItemSeq = A.ItemSeq

	SELECT @DateFr = CONVERT(NCHAR(6), GETDATE(), 112) + '01', @DateTo = CONVERT(NCHAR(8), GETDATE(), 112)

-- 창고재고 가져오기      
    EXEC _SLGGetInOutLotStock   @CompanySeq   = @CompanySeq,   -- 법인코드      
                                @BizUnit      = 0,      -- 사업부문      
                                @FactUnit     = 0,     -- 생산사업장     
                                @DateFr       = @DateFr,       -- 조회기간Fr     
                                @DateTo       = @DateTo,       -- 조회기간To     
                                @WHSeq        = 0,        -- 창고지정      
                                @SMWHKind     = 0,     -- 창고구분별 조회
                                @CustSeq      = 0,      -- 수탁거래처     
                                @IsTrustCust  = '',  -- 수탁여부      
                                @IsSubDisplay = 0, -- 기능창고 조회 
                                @IsUnitQry    = 0,    -- 단위별 조회   
                                @QryType      = 'S'       -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고      


	/**************************************************************************************************************************************************/

	----SELECT * FROM #GetInOutStock
 ----   SELECT * FROM #BaseData
	
	CREATE TABLE #TMP_Minus
	(
		Seq INT,
		ErrMsg NVARCHAR(200)
	)

	--SELECT ISNULL(B.STDStockQty,0) , A.ProdQty, *
	/* 1.포장실적 이동처리 (저장창고 -> 일반창고 이동) 시 마이너스 재고이면 삭제함. */

	INSERT INTO #TMP_Minus
	SELECT A.Seq, '완성품의 창고재고가 부족하여 처리할 수 없습니다.'
	FROM #BaseData AS A 
	LEFT OUTER JOIN #GetInOutStock AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq 
	JOIN _TDAItem   AS C ON C.CompanySeq = @CompanySeq AND A.GoodItemSeq = C.ItemSeq
	JOIN _TDAItemStock AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND C.ItemSeq =D.ItemSeq
    WHERE ISNULL(B.STDStockQty,0) - A.ProdQty < 0 
	AND D.IsLotMng <> '1'

	INSERT INTO #TMP_Minus
	SELECT A.Seq, '용기품목의 창고재고가 부족하여 처리할 수 없습니다.'
	  FROM #BaseData AS A 
	  LEFT OUTER JOIN #GetInOutStock AS B ON A.SubItemSeq = B.ItemSeq AND A.SubOutWHSeq = B.WHSeq 
	  JOIN _TDAItem   AS C ON C.CompanySeq = @CompanySeq AND A.SubItemSeq = C.ItemSeq
	JOIN _TDAItemStock AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND C.ItemSeq =D.ItemSeq
    WHERE ISNULL(B.STDStockQty,0) - A.SubQty < 0 
	AND D.IsLotMng <> '1'
	AND C.AssetSeq NOT IN (11)

	DECLARE @IsLotMinus NCHAR(1)

	SELECT @IsLotMinus = EnvValue FROM _TCOMEnv WHERE CompanySeq = 1 AND EnvSeq = 8043

	IF @IsLotMinus = '1' 
		BEGIN
		INSERT INTO #TMP_Minus
		SELECT A.Seq, '완성품의 전함바 대표LOT (H0000000) 재고가 부족하여 처리할 수 없습니다.'
		  FROM #BaseData AS A 
		  LEFT OUTER JOIN #GetInOutLotStock AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq AND B.LotNo = 'H0000000' --A.RealLotNo = B.LotNo
		 			 JOIN #TEMP_TDAItem AS C ON A.GoodItemSeq = C.ItemSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.BeforHambaQty < 0
		  AND A.UMProgType = 1010345001 
		  AND Seq NOT IN (SELECT Seq FROM #TMP_Minus)


		INSERT INTO #TMP_Minus
		SELECT A.Seq, '완성품의 LOT 재고가 부족하여 처리할 수 없습니다.'
		  FROM #BaseData AS A 
		  LEFT OUTER JOIN #GetInOutLotStock AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq AND A.RealLotNo = B.LotNo
		 			 JOIN #TEMP_TDAItem AS C ON A.GoodItemSeq = C.ItemSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.ProdQty < 0
		  AND A.UMProgType = 1010345001 
		  AND Seq NOT IN (SELECT Seq FROM #TMP_Minus)

		INSERT INTO #TMP_Minus
		SELECT A.Seq, '완성품의 LOT재고가 부족하여 처리할 수 없습니다.'
		  FROM #BaseData AS A 
		  LEFT OUTER JOIN (SELECT ItemSeq, WHSeq, SUM(STDStockQty) AS STDStockQty FROM #GetInOutLotStock GROUP BY ItemSeq, WHSeq) AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq --AND A.RealLotNo = B.LotNo
		 			 JOIN #TEMP_TDAItem AS C ON A.GoodItemSeq = C.ItemSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.ProdQty < 0
		  AND A.UMProgType <> 1010345001 
		  AND Seq NOT IN (SELECT Seq FROM #TMP_Minus)
	END

	  /*
	INSERT INTO #TMP_Minus
	SELECT A.Seq, '용기품목의 LOT재고가 부족하여 처리할 수 없습니다.'
	  FROM #BaseData AS A LEFT OUTER JOIN #GetInOutLotStock AS B ON A.SubItemSeq = B.ItemSeq AND A.SubOutWHSeq = B.WHSeq AND A.RealLotNo = B.LotNo
						  JOIN #TEMP_TDAItem AS C ON A.SubItemSeq = C.ItemSeq 
    WHERE ISNULL(B.STDStockQty,0) - A.HambaDrainQty < 0
	 AND Seq NOT IN (SELECT Seq FROM #TMP_Minus)
	 */


	 SELECT * FROM #TMP_Minus
	/*
		DELETE #BaseData
		  FROM #BaseData AS A LEFT OUTER JOIN #GetInOutStock AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.ProdQty < 0 

		--SELECT ISNULL(B.STDStockQty,0) , A.SubQty, *
		/* 2. 용기기타출고 시 마이너스 재고면 삭제 */
		DELETE #BaseData
		  FROM #BaseData AS A LEFT OUTER JOIN #GetInOutStock AS B ON A.SubItemSeq = B.ItemSeq AND A.SubOutWHSeq = B.WHSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.SubQty < 0 


	
		DELETE #BaseData
		  FROM #BaseData AS A LEFT OUTER JOIN #GetInOutLotStock AS B ON A.GoodItemSeq = B.ItemSeq AND A.OutWHSeq = B.WHSeq AND A.RealLotNo = B.LotNo
								JOIN #TEMP_TDAItem AS C ON A.GoodItemSeq = C.ItemSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.ProdQty < 0

		DELETE #BaseData
		  FROM #BaseData AS A LEFT OUTER JOIN #GetInOutLotStock AS B ON A.SubItemSeq = B.ItemSeq AND A.SubOutWHSeq = B.WHSeq AND A.RealLotNo = B.LotNo
							  JOIN #TEMP_TDAItem AS C ON A.SubItemSeq = C.ItemSeq 
		WHERE ISNULL(B.STDStockQty,0) - A.HambaDrainQty < 0
	*/

/*
	DELETE #BaseData
	  FROM #BaseData  
    WHERE Seq IN (SELECT Seq FROM #TMP_Minus )
	*/


	UPDATE KPX_TPDSFCWorkReport_POP
	  SET ErrorMessage = B.ErrMsg,
		  ProcYN = '2'
	 FROM KPX_TPDSFCWorkReport_POP AS A JOIN #TMP_Minus AS B ON A.Seq = B.Seq 
	 WHERE A.ProcYn <> '1'         
       AND A.IsPacking = '1'   


	--DROP TABLE #GetInOutLot 
	--DROP TABLE #GetInOutLotStock


	IF NOT EXiSTS (SELECT 1 FROM #BaseData) 
	BEGIN 
		RETURN
	END
    
	/* 포장LOTNO이 없으면 Lot마스터 생성 */
	IF EXISTS (SELECT 1 
				FROM #BaseData AS A 
			    LEFT OUTER JOIN _TLGLotMaster AS B ON B.CompanySeq = @CompanySeq AND A.GoodItemSeq = B.ItemSeq AND A.RealLotNo = B.LotNo 
			   WHERE B.LotNo IS NULL ) 
	BEGIN 
		INSERT INTO _TLGLotMaster (	 CompanySeq
									,LotNo
									,SourceLotNo
									,CreateDate
									,CreateTime
									,ValiDate
									,ValidTime
									,CustSeq
									,Remark
									,OriLotNo
									,OriItemSeq
									,RegDate
									,ItemSeq
									,UnitSeq
									,Qty
									,RegUserSeq
									,LastUserSeq
									,LastDateTime
									)
		SELECT DISTINCT @CompanySeq , A.RealLotNo
						,''
						,CONVERT(NVARCHAR(8),GETDATE(),112)
						,''
						,''
						,''
						,0
						,'POP포장실적'
						,''
						,0
						,CONVERT(NVARCHAR(8),GETDATE(),112)
						,A.GoodItemSeq
						,B.UnitSeq
						,A.ProdQty
						,1
						,1
						,GETDATE()
		 FROM #BaseData AS A 
		 JOIN _TDAItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq AND A.GoodItemSeq = B.ItemSeq 
		 LEFT OUTER JOIN _TLGLotMaster AS C ON C.CompanySeq = @CompanySeq AND A.GoodItemSeq = C.ItemSeq AND A.RealLotNo = C.LotNo 
		WHERE C.LotNo IS NULL
	END

 

    -- 원천구분 - 공정 
    CREATE TABLE #TypeOne
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )
    INSERT INTO #TypeOne 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )    
    SELECT Seq, WorkingTag, A.FactUnit, IsPacking, A.WorkOrderSeq, 
           A.WorkOrderSerl, SourceSeq, SourceSerl, A.GoodItemSeq, A.ProdQty, 
           A.RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
           OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
           UMProgType 
      FROM #BaseData AS A
	  --LEFT OUTER JOIN _TPDSFCWorkReport	 AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq AND A.SourceSeq = R.WorkOrderSeq AND A.SourceSerl = R.WorkOrderSerl
     WHERE UMProgType = 1010345001 
     -- AND ISNULL(R.WorkReportSeq, 0) <> 0

    -- 원천구분 - 탱크 
    CREATE TABLE #TypeTwo
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50) 
    )
    INSERT INTO #TypeTwo 
    (        
        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
        UMProgType 
    )    
    SELECT Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
           WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
           RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
           OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
           UMProgType 
      FROM #BaseData 
     WHERE UMProgType = 1010345002 
    
    


    
    IF EXISTS (SELECT 1 FROM #TypeOne) 
    BEGIN 
        /*******************************************************************************************************
        -- 공정 
        *******************************************************************************************************/
        ---------------------------------------------------------------------------------
        -- 전함바 Lot 대체 (함바 Lot -> 출하Lot) - 저장탱크 
        ---------------------------------------------------------------------------------
        DECLARE @Count      INT, 
                @Seq        INT, 
                @BizUnit    INT, 
                @Date       NCHAR(8), 
                @MaxNo      NVARCHAR(50), 
                @Cnt        INT 
        
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
            
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag IN ( 'A', 'U' )    
        
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 1 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )  
         WHERE A.WorkingTag = 'D' 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        --BEGIN TRAN 
        
        -- 수정, 삭제 시 삭제 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '포장실적 전함바 Lot 대체', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 전함바 Lot 대체', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.BeforHambaQty, A.BeforHambaQty, 0, 0, 
               0, 8023042, 0, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, 'H0000000', NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        


        DELETE A 
          FROM KPX_TPDSFCProdPackReportRelation AS A 
          JOIN #TypeOne                         AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 310 
           AND B.WorkingTag IN ( 'U', 'D' ) 

        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 1, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'A', 'U' ) 

        ---------------------------------------------------------------------------------
        -- 전함바 Lot 대체 (함바 Lot -> 출하Lot) - 저장탱크, END 
        ---------------------------------------------------------------------------------
        

        ---------------------------------------------------------------------------------
        -- 생산수량 이동처리 (저장탱크 -> 일반창고) 
        ---------------------------------------------------------------------------------
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag IN ( 'A', 'U' )    
        
        --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 2 
                                                      AND B.InOutType = 80 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )        
         WHERE A.WorkingTag = 'D' 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END      
        
        -- 수정, 삭제 시 삭제 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 80, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.InWHSeq, 
               0, '0', '1', 0, 0, 
               '', 0, '포장실적 생산수량 저장탱크로 이동', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 80, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 생산수량 저장탱크로 이동', NULL, NULL, A.InWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023008, 8012001, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, NULL, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 

        DELETE A 
          FROM KPX_TPDSFCProdPackReportRelation AS A 
          JOIN #TypeOne                         AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 80 
           AND B.WorkingTag IN ( 'U', 'D' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 2, 80, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'A', 'U' ) 
        ---------------------------------------------------------------------------------
        -- 생산수량 이동처리 (저장탱크 -> 일반창고), END  
        ---------------------------------------------------------------------------------
        
        ---------------------------------------------------------------------------------
        -- 함바 수량 Lot대체 (출하 Lot -> 함바 Lot) - 저장탱크 
        ---------------------------------------------------------------------------------
        SELECT @Count = (SELECT COUNT(1) FROM #TypeOne) 
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeOne AS A 
         WHERE WorkingTag IN ( 'A', 'U' )  
        
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq
          FROM #TypeOne AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 3 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )      
         WHERE A.WorkingTag = 'D' 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeOne WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeOne AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeOne              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeOne)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        
        -- 수정, 삭제 시 삭제 
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeOne AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '포장실적 일반 Lot을 전함바 Lot로 대체', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
		----select '#TypeOne', * from #TypeOne

        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 일반 Lot을 전함바 Lot로 대체', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.BeforHambaQty + A.RealProdQty - A.ProdQty, A.BeforHambaQty + A.RealProdQty - A.ProdQty , /* 전함바 + 생산수량 - 포장단위수량 -> 잔여LOT수량 *//*A.HambaDrainQty, A.HambaDrainQty, */ 0, 0, 
               0, 8023042, 0, 'H0000000', '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, A.RealLotNo, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeOne AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        DELETE A 
          FROM KPX_TPDSFCProdPackReportRelation AS A 
          JOIN #TypeOne                         AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 310 
           AND B.WorkingTag IN ( 'U', 'D' ) 
		
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 3, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeOne AS A 
         WHERE A.WorkingTag IN ( 'A', 'U' ) 
        ---------------------------------------------------------------------------------
        -- 함바 수량 Lot대체 (출하 Lot -> 함바 Lot) - 저장탱크, END 
        --------------------------------------------------------------------------------- 
        
        --IF @@ERROR <> 0 
        --BEGIN
        --    ROLLBACK 
        --END 
        
        
    END 
    
    
    CREATE TABLE #TypeTwo_Result
    (
        IDX_NO          INT IDENTITY, 
        Seq             INT,     
        WorkingTag      NCHAR(1),   
        FactUnit        INT,       
        IsPacking       NCHAR(1), 
        WorkOrderSeq    INT, 
        WorkOrderSerl   INT, 
        SourceSeq       INT, 
        SourceSerl      INT, 
        GoodItemSeq     INT,       
        ProdQty         DECIMAL(19,5),       
        RealLotNo       NVARCHAR(100), 
        HambaDrainQty   DECIMAL(19,5), 
        WorkEndDate     NCHAR(8), 
        RealProdQty     DECIMAL(19,5), 
        BeforHambaQty   DECIMAL(19,5), 
        OutWHSeq        INT, 
        InWHSeq         INT, 
        SubItemSeq      INT, 
        SubQty          DECIMAL(19,5), 
        SubOutWHSeq     INT, 
        UMProgType      INT, 
        InOutSeq        INT, 
        InOutNo         NVARCHAR(50), 
        LotNo           NVARCHAR(50) 
    )
    
    ----select * from #TypeTwo

    IF EXISTS (SELECT 1 FROM #TypeTwo)
    BEGIN
        /*******************************************************************************************************
        -- 탱크  
        *******************************************************************************************************/
        DECLARE @WHSeq      INT, 
                @FactUnit   INT, 
                @IFSeq      INT, 
                @LotNo      NVARCHAR(50)     
                 
        SELECT @DateFr = CONVERT(NCHAR(8),GETDATE(),112)     
        
        --CREATE TABLE #GetInOutLot            
        --(              
        --    LotNo         NVARCHAR(30),            
        --    ItemSeq       INT        
        --)      
        --CREATE TABLE #GetInOutLotStock              
        --(              
        --    WHSeq           INT,              
        --    FunctionWHSeq   INT,              
        --    LotNo           NVARCHAR(30),            
        --    ItemSeq         INT,              
        --    UnitSeq         INT,              
        --    PrevQty         DECIMAL(19,5),              
        --    InQty           DECIMAL(19,5),              
        --    OutQty          DECIMAL(19,5),              
        --    StockQty        DECIMAL(19,5),              
        --    STDPrevQty      DECIMAL(19,5),              
        --    STDInQty        DECIMAL(19,5),              
        --    STDOutQty       DECIMAL(19,5),              
        --    STDStockQty     DECIMAL(19,5)              
        --)  
        
        CREATE TABLE #GetInOutLotStock_Sub      
        (         
            IDX_NO          INT IDENTITY,       
            RegDate         NCHAR(8),       
            WHSeq           INT,              
            FunctionWHSeq   INT,              
            LotNo           NVARCHAR(30),            
            ItemSeq         INT,              
            UnitSeq         INT,              
            PrevQty         DECIMAL(19,5),              
            InQty           DECIMAL(19,5),              
            OutQty          DECIMAL(19,5),              
            StockQty        DECIMAL(19,5),              
            STDPrevQty      DECIMAL(19,5),              
            STDInQty        DECIMAL(19,5),              
            STDOutQty       DECIMAL(19,5),              
            STDStockQty     DECIMAL(19,5), 
            Seq             INT 
        ) 
		
		
		----select * from #TypeTwo
		
		      
        
        SELECT @Cnt  = 1 
        WHILE ( 1 = 1 ) 
        BEGIN
            
            TRUNCATE TABLE #GetInOutLot      
            INSERT INTO #GetInOutLot ( LotNo, ItemSeq )         
            SELECT DISTINCT B.LotNo, A.GoodItemSeq        
              FROM #TypeTwo     AS A         
              JOIN _TLGLotStock AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq )      
             WHERE A.IDX_NO = @Cnt 
            

            SELECT @BizUnit = C.BizUnit, 
                   @WHSeq = A.OutWHSeq, 
                   @FactUnit = A.FactUnit, 
                   @IFSeq = A.Seq 
              FROM #TypeTwo AS A 
              ----LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl ) 
              LEFT OUTER JOIN _TDAWH AS C ON ( C.CompanySeq = @CompanySeq AND C.WHSeq = A.OutWHSeq ) 
             WHERE A.IDX_NO = @Cnt 
            

            TRUNCATE TABLE #GetInOutLotStock 
            -- 창고재고 가져오기              
            EXEC _SLGGetInOutLotStock @CompanySeq   = @CompanySeq,   -- 법인코드              
                                      @BizUnit      = @BizUnit,      -- 사업부문              
                                      @FactUnit     = @FactUnit,     -- 생산사업장              
                                      @DateFr       = @DateFr,       -- 조회기간Fr              
                                      @DateTo       = @DateFr,       -- 조회기간To              
                                      @WHSeq        = @WHSeq,        -- 창고지정              
                                      @SMWHKind     = 0,     -- 창고구분별 조회              
                                      @CustSeq      = 0,      -- 수탁거래처              
                                      @IsTrustCust  = '0',  -- 수탁여부              
                                      @IsSubDisplay = '0', -- 기능창고 조회              
                                      @IsUnitQry    = '0',    -- 단위별 조회              
                                      @QryType      = 'S'       -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고  
            
			----select 111111111
			----select * from #GetInOutLotStock

            TRUNCATE TABLE #GetInOutLotStock_Sub 
            
            INSERT INTO #GetInOutLotStock_Sub       
            SELECT B.RegDate, A.*, @IFSeq 
              FROM #GetInOutLotStock AS A         
              LEFT OUTER JOIN _TLGLotMaster AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.LotNo = A.LotNo    ) --AND B.LotNo = A.LotNo         
             WHERE A.STDStockQty > 0       
             ORDER BY B.RegDate DESC      
            
			----select 111111111
			----select * from #GetInOutLotStock
			----select * from #GetInOutLotStock_Sub
    
	
            IF (SELECT ProdQty FROM #TypeTwo WHERE Seq = @IFSeq) > (SELECT ISNULL(SUM(STDStockQty),0) FROM  #GetInOutLotStock_Sub)
            BEGIN
                
                UPDATE A 
                   SET ProcYn = '2', 
                       ErrorMessage = '재고가 부족하여 처리 할 수 없습니다.(탱크)' 
                  FROM KPX_TPDSFCWorkReport_POP AS A 
                 WHERE Seq = @IFSeq 
                
            END 
            ELSE 
            BEGIN
                DECLARE @StockCnt   INT, 
                        @ProdQty    DECIMAL(19,5), 
                        @StockQty   DECIMAL(19,5) 
                
                SELECT @ProdQty = ProdQty 
                  FROM #TypeTwo 
                 WHERE IDX_NO = @Cnt 
                
                SELECT @StockCnt = 1 
                --select @OriQty 
                --SELECT * from #TypeTwo
                --return 
                WHILE ( 1 = 1 ) 
                BEGIN
                    
                    SELECT @StockQty = STDStockQty, 
                           @LotNo = LotNo  
                      FROM #GetInOutLotStock_Sub 
                     WHERE IDX_NO = @StockCnt 
                    
                    --SELECT @StockQty = 6000
                    --select @StockQty , @ProdQty
                    
                    INSERT INTO #TypeTwo_Result 
                    (        
                        Seq, WorkingTag, FactUnit, IsPacking, WorkOrderSeq, 
                        WorkOrderSerl, SourceSeq, SourceSerl, GoodItemSeq, ProdQty, 
                        RealLotNo, HambaDrainQty, WorkEndDate, RealProdQty, BeforHambaQty, 
                        OutWHSeq, InWHSeq, SubItemSeq, SubQty, SubOutWHSeq, 
                        UMProgType, LotNo 
                    )    
                    SELECT A.Seq, A.WorkingTag, A.FactUnit, A.IsPacking, A.WorkOrderSeq, 
                           A.WorkOrderSerl, A.SourceSeq, A.SourceSerl, A.GoodItemSeq, CASE WHEN @StockQty >= @ProdQty THEN @ProdQty ELSE @StockQty END, 
                           A.RealLotNo, A.HambaDrainQty, A.WorkEndDate, CASE WHEN @StockQty >= @ProdQty THEN @ProdQty ELSE @StockQty END, A.BeforHambaQty, 
                           A.OutWHSeq, A.InWHSeq, A.SubItemSeq, A.SubQty, A.SubOutWHSeq, 
                           A.UMProgType, @LotNo 
                      FROM #TypeTwo AS A 
                     WHERE Seq = @IFSeq 
                    
                    IF @StockCnt >= (SELECT MAX(IDX_NO) FROM #GetInOutLotStock_Sub)
                       OR @StockQty >= @ProdQty 
                    BEGIN 
                        BREAK
                    END 
                    ELSE
                    BEGIN
                        SELECT @StockCnt = @StockCnt + 1 
                        SELECT @ProdQty = @ProdQty - @StockQty 
                    END 
                
                
                END 
            
            END 
            

            IF @Cnt >= (SELECT MAX(IDX_NO) FROM #TypeTwo)
            BEGIN 
                BREAK 
            END 
            ELSE
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        
        END 
    
      

        SELECT @Count = (SELECT COUNT(1) FROM #TypeTwo_Result)
        ---------------------------------------------------------------------------------
        -- 저장탱크 Lot 대체 - 선입선출 (탱크) 
        ---------------------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM #TypeTwo_Result WHERE WorkingTag IN ( 'A','U' ))
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
		
		select'222222',  * from #TypeTwo_Result
		
		     
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeTwo_Result AS A 
         WHERE WorkingTag IN ( 'A','U' )
        
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq
          FROM #TypeTwo_Result AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 4 
                                                      AND B.InOutType = 310 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )      
         WHERE A.WorkingTag = 'D' 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeTwo_Result WHERE WorkingTag IN ( 'A','U' ))       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeTwo_Result AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeTwo_Result              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeTwo_Result)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END       
        
        
        -- 수정, 삭제 시 삭제 
        DELETE B 
          FROM #TypeTwo_Result AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeTwo_Result AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 310 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        

		SELECT '11111111111111', @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '포장실적 Lot대체 (탱크)', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeTwo_Result AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 

        
        -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 310, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, 0, 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.OutWHSeq, 
               0, '', '', 0, 0, 
               '', 0, '포장실적 Lot대체 (탱크)', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeTwo_Result AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 310, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 Lot대체 (탱크)', NULL, NULL, A.OutWHSeq, A.OutWHSeq, 
               --B.UnitSeq, A.HambaDrainQty, A.HambaDrainQty, 0, 0, 
			   B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023042, 0, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, A.LotNo, NULL, 
               NULL, NULL, NULL, 1021351
          FROM #TypeTwo_Result AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        

        DELETE A 
          FROM KPX_TPDSFCProdPackReportRelation AS A 
          JOIN #TypeTwo_Result                  AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 310 
           AND B.WorkingTag IN ( 'U', 'D' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 4, 310, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeTwo_Result AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        

        SELECT @Count = (SELECT COUNT(1) FROM #TypeTwo)
        ---------------------------------------------------------------------------------
        -- 생산수량 이동처리 (저장탱크 -> 일반창고) (탱크)
        ---------------------------------------------------------------------------------
        IF EXISTS (SELECT 1 FROM #TypeTwo WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
            -- 키값생성코드부분 시작                
            EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
        END          
        
                 
        -- Temp Talbe 에 생성된 키값 UPDATE       
        UPDATE A               
           SET InOutSeq = @Seq + IDX_NO         
          FROM #TypeTwo AS A 
         WHERE WorkingTag IN ( 'A', 'U' ) 
        
        --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
        -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
        UPDATE A       
           SET InOutSeq = B.InOutSeq
          FROM #TypeTwo AS A       
          JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                      AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                      AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                      AND B.DataKind = 5 
                                                      AND B.InOutType = 80 
                                                      --AND B.InOutSeq = A.InOutSeq 
                                                      --AND B.InOutSerl = 1 
                                                        )        
          --LEFT OUTER JOIN _TLGInOutDaily        AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutType = B.InOutType AND C.InOutSeq = B.InOutSeq ) 
         WHERE A.WorkingTag = 'D' 
        
                  
        SELECT @Cnt = 1         
        
        IF EXISTS (SELECT 1 FROM #TypeTwo WHERE WorkingTag IN ( 'A', 'U' ))       
        BEGIN       
            WHILE ( 1 = 1 )          
            BEGIN 
                
                SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                       @Date = WorkEndDate
                  FROM #TypeTwo AS A 
                 WHERE IDX_NO = @Cnt 
                
                exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                        
                UPDATE #TypeTwo              
                   SET InOutNo = @MaxNo         
                  WHERE IDX_NO = @Cnt        
                        
                IF @Cnt = (SELECT MAX(IDX_NO) FROM #TypeTwo)         
                BEGIN         
                    BREAK         
                END         
                ELSE         
                BEGIN        
                    SELECT @Cnt = @Cnt + 1         
                END         
            END         
        END      
        
        -- 수정, 삭제 시 삭제 
        DELETE B 
          FROM #TypeTwo AS A 
          JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        DELETE B 
          FROM #TypeTwo AS A 
          JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 80 ) 
         WHERE A.WorkingTag IN ( 'D', 'U' ) 
        
        
        -- 신규, 수정 시 입력 
        INSERT INTO _TLGInOutDaily 
        (
            CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
            FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
            WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
            DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
            CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
            LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
        )
        
        SELECT @CompanySeq, 80, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
               0, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 0, 0, A.WorkEndDate, 
               0, 0, 0, A.OutWHSeq, A.InWHSeq, 
               0, '0', '1', 0, 0, 
               '', 0, '포장실적 생산수량 저장탱크로 이동(탱크)', '', '0', 
               1, GETDATE(), 0, 1021351, 0 
          FROM #TypeTwo AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        
        
        INSERT INTO _TLGInOutDailyItem 
        (
            CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
            InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
            UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
            EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
            IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
            LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
            ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
        ) 
        
        SELECT @CompanySeq, 80, A.InOutSeq, 1, A.GoodItemSeq, 
               '포장실적 생산수량 저장탱크로 이동(탱크)', NULL, NULL, A.InWHSeq, A.OutWHSeq, 
               B.UnitSeq, A.ProdQty, A.ProdQty, 0, 0, 
               0, 8023008, 8012001, A.RealLotNo, '', 
               NULL, NULL, NULL, NULL, 0, 
               1, GETDATE(), NULL, NULL, NULL, 
               NULL, NULL, NULL, 1021351

          FROM #TypeTwo AS A 
          LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.GoodItemSeq ) 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        


        DELETE A 
          FROM KPX_TPDSFCProdPackReportRelation AS A 
          JOIN #TypeTwo_Result                  AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 80 
           AND B.WorkingTag IN ( 'U', 'D' ) 
        
        INSERT INTO KPX_TPDSFCProdPackReportRelation 
        (
            CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
            InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
        )
        SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 5, 80, 
               A.InOutSeq, 1, 1, GETDATE() 
          FROM #TypeTwo AS A 
         WHERE A.WorkingTag IN ( 'U','A' ) 
        ---------------------------------------------------------------------------------
        -- 생산수량 이동처리 (저장탱크 -> 일반창고), END  
        ---------------------------------------------------------------------------------
    END 
    
    --select * from #BaseData
    
    SELECT @Count = (SELECT COUNT(1) FROM #BaseData)
    ---------------------------------------------------------------------------------
    -- 용기 기타출고 
    ---------------------------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM #BaseData WHERE WorkingTag IN ( 'A','U' ))       
    BEGIN       
        DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = '_TLGInOutDaily'       
        -- 키값생성코드부분 시작                
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TLGInOutDaily', 'InOutSeq', @Count              
    END          
    
             
    -- Temp Talbe 에 생성된 키값 UPDATE       
    UPDATE A               
       SET InOutSeq = @Seq + IDX_NO         
      FROM #BaseData AS A 
     WHERE WorkingTag IN ( 'U', 'A' ) 
    
    --select * From _TDASMinor where majorseq = 8042 and companyseq = 1 
    -- 삭제, 수정  일 경우 연결 연결 테이블 InOutSeq,Serl 로 업데이트       
    UPDATE A       
       SET InOutSeq = B.InOutSeq
      FROM #BaseData AS A       
      JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq       
                                                  AND B.WorkOrderSeq = A.WorkOrderSeq       
                                                  AND B.WorkOrderSerl = A.WorkOrderSerl       
                                                  AND B.DataKind = 6  
                                                  AND B.InOutType = 31 
                                                  --AND B.InOutSeq = A.InOutSeq 
                                                  --AND B.InOutSerl = 1 
                                                    )
     WHERE A.WorkingTag = 'D' 
    
              
    SELECT @Cnt = 1         
    
    IF EXISTS (SELECT 1 FROM #BaseData WHERE WorkingTag IN ( 'A', 'U' ))       
    BEGIN       
        WHILE ( 1 = 1 )          
        BEGIN 
            
            SELECT @BizUnit = (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), 
                   @Date = WorkEndDate
              FROM #BaseData AS A 
             WHERE IDX_NO = @Cnt 
            
            exec dbo._SCOMCreateNo 'LG', '_TLGInOutDaily', @CompanySeq, @BizUnit, @Date, @MaxNo OUTPUT         
                    
            UPDATE #BaseData              
               SET InOutNo = @MaxNo         
              WHERE IDX_NO = @Cnt        
                    
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #BaseData)         
            BEGIN         
                BREAK         
            END         
            ELSE         
            BEGIN        
                SELECT @Cnt = @Cnt + 1         
            END         
        END         
    END      
    
    -- 수정, 삭제 시 삭제 
    DELETE B 
      FROM #BaseData AS A 
      JOIN _TLGInOutDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutType = 31 ) 
     WHERE A.WorkingTag IN ( 'D', 'U' ) 
    
    DELETE B 
      FROM #BaseData AS A 
      JOIN _TLGInOutDailyItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InOutSeq = A.InOutSeq AND B.InOutSerl = 1 AND B.InOutType = 31 ) 
     WHERE A.WorkingTag IN ( 'D', 'U' ) 
    
    ----select '#BaseData', * from #BaseData

    -- 신규, 수정 시 입력 
    INSERT INTO _TLGInOutDaily 
    (
        CompanySeq, InOutType, InOutSeq, BizUnit, InOutNo, 
        FactUnit, ReqBizUnit, DeptSeq, EmpSeq, InOutDate, 
        WCSeq, ProcSeq, CustSeq, OutWHSeq, InWHSeq, 
        DVPlaceSeq, IsTrans, IsCompleted, CompleteDeptSeq, CompleteEmpSeq, 
        CompleteDate, InOutDetailType, Remark, Memo, IsBatch, 
        LastUserSeq, LastDateTime, UseDeptSeq, PgmSeq, FileSeq
    )
    
    SELECT @CompanySeq, 31, A.InOutSeq, (SELECT TOP 1 BizUnit FROM _TDAFactUnit WHERE FactUnit = A.FactUnit), A.InOutNo, 
           0, 0, 0, 0, A.WorkEndDate, 
           0, 0, 0, A.SubOutWHSeq, 0, 
           0, '', '', 0, 0, 
           '', 0, '용기 기타출고', '', '0', 
           1, GETDATE(), 0, 1021351, 0 
      FROM #BaseData AS A 
     WHERE A.WorkingTag IN ( 'U','A' ) 
    
    
    INSERT INTO _TLGInOutDailyItem 
    (
        CompanySeq, InOutType, InOutSeq, InOutSerl, ItemSeq, 
        InOutRemark, CCtrSeq, DVPlaceSeq, InWHSeq, OutWHSeq, 
        UnitSeq, Qty, STDQty, Amt, EtcOutAmt, 
        EtcOutVAT, InOutKind, InOutDetailKind, LotNo, SerialNo, 
        IsStockSales, OriUnitSeq, OriItemSeq, OriQty, OriSTDQty, 
        LastUserSeq, LastDateTime, PJTSeq, OriLotNo, ProgFromSeq, 
        ProgFromSerl, ProgFromSubSerl, ProgFromTableSeq, PgmSeq
    ) 
    
    SELECT @CompanySeq, 31, A.InOutSeq, 1, A.SubItemSeq, 
           '용기 기타출고', NULL, NULL, 0, A.SubOutWHSeq, 
           B.UnitSeq, A.SubQty, A.SubQty, 0, 0, 
           0, 8023003, 8025007, '', '', 
           '', 0, 0, 0, 0, 
           1, GETDATE(), NULL, NULL, NULL, 
           NULL, NULL, NULL, 1021351
      FROM #BaseData AS A 
      LEFT OUTER JOIN _TDAItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.SubItemSeq ) 
     WHERE A.WorkingTag IN ( 'U','A' ) 
    

    DELETE A 
        FROM KPX_TPDSFCProdPackReportRelation AS A 
        JOIN #TypeTwo_Result                  AS B ON ( B.WorkOrderSeq = A.WorkorderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
        WHERE A.CompanySeq = @CompanySeq 
        AND A.InOutType = 31 
        AND B.WorkingTag IN ( 'U', 'D' ) 

	--용기 기타출고 
    INSERT INTO KPX_TPDSFCProdPackReportRelation 
    (
        CompanySeq, WorkOrderSeq, WorkOrderSerl, DataKind, InOutType, 
        InOutSeq, InOutSerl, LastUserSeq, LastDateTime 
    )
    SELECT @CompanySeq, A.WorkOrderSeq, A.WorkOrderSerl, 6, 31, 
           A.InOutSeq, 1, 1, GETDATE() 
      FROM #BaseData AS A 
     WHERE A.WorkingTag IN ( 'U', 'A' ) 
    ---------------------------------------------------------------------------------
    -- 용기 기타출고, END 
    ---------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------------------------------------------------
    -- 연결 테이블 삭제 
    ------------------------------------------------------------------------------------------------------------------------
    DELETE B 
      FROM #BaseData AS A 
      JOIN KPX_TPDSFCProdPackReportRelation AS B ON ( B.CompanySeq = @CompanySeq 
                                                  AND B.WorkOrderSeq = A.WorkOrderSeq 
                                                  AND B.WorkOrderSerl = A.WorkOrderSerl 
                                                    ) 
     WHERE A.WorkingTag = 'D' 
    ------------------------------------------------------------------------------------------------------------------------
    -- 연결 테이블 삭제, END  
    ------------------------------------------------------------------------------------------------------------------------    
    
    --select * from #BaseData
    ------------------------------------------------------------------------------------------------------------------------    
    -- 포장실적 
    ------------------------------------------------------------------------------------------------------------------------    
    CREATE TABLE #KPX_TPDSFCProdPackReport         
    (        
        IDX_NO              INT IDENTITY,         
        CompanySeq          INT,         
        PackReportSeq       INT,         
        FactUnit            INT,         
        PackDate            NCHAR(8),         
        ReportNo            NVARCHAR(100),         
        OutWHSeq            INT,         
        InWHSeq             INT,         
        UMProgType          INT,         
        DrumOutWHSeq        INT,         
        Remark              NVARCHAR(100),         
        LastUserSeq         INT        
    )         
            
    CREATE TABLE #KPX_TPDSFCProdPackReportItem         
    (        
        IDX_NO              INT IDENTITY,         
        CompanySeq          INT,         
        PackReportSeq       INT,         
        PackReportSerl      INT,         
        ItemSeq             INT,         
        UnitSeq             INT,         
        Qty                 DECIMAL(19,5),         
        LotNo               NVARCHAR(100),         
        OutLotNo            NVARCHAR(100),         
        Remark              NVARCHAR(100),         
        SubItemSeq          INT,         
        SubUnitSeq          INT,         
        SubQty              DECIMAL(19,5),         
        HambaQty            DECIMAL(19,5),         
        PackOrderSeq        INT,         
        PackOrderSerl       INT,         
        LastUserSeq         INT         
    )      
    CREATE TABLE #KPX_TPDSFCProdPackReportLog       
    (      
        IDX_NO          INT IDENTITY,       
        WorkingTag      NCHAR(1),       
        Status          INT,       
        PackReportSeq   INT      
    )     
    CREATE TABLE #KPX_TPDSFCProdPackReportItemLog       
    (      
        IDX_NO          INT IDENTITY,       
        WorkingTag      NCHAR(1),       
        Status          INT,       
        PackReportSeq   INT,      
        PackReportSerl   INT      
    ) 
    DECLARE @TableColumns NVARCHAR(MAX), 
            @ReportNo     NVARCHAR(50) 
    
    -- 포장 실적 삭제시 로그         
    INSERT INTO #KPX_TPDSFCProdPackReportLog ( WorkingTag, Status, PackReportSeq )         
    SELECT A.WorkingTag, 0, C.PackReportSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
      JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )         
            
    -- 마스터 로그           
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReport')            
                  
    EXEC _SCOMLog @CompanySeq   ,                
                  1      ,                
                  'KPX_TPDSFCProdPackReport'    , -- 테이블명                
                  '#KPX_TPDSFCProdPackReportLog'    , -- 임시 테이블명                
                  'PackReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )                
                  @TableColumns , '', 1  -- 테이블 모든 필드명           
            
                
    INSERT INTO #KPX_TPDSFCProdPackReportItemLog ( WorkingTag, Status, PackReportSeq, PackReportSerl )         
    SELECT A.WorkingTag, 0, B.PackReportSeq, B.PackReportSerl        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
                
    -- 디테일 로그           
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackReportItem')            
                  
    EXEC _SCOMLog @CompanySeq   ,                
                  1      ,                
                  'KPX_TPDSFCProdPackReportItem'    , -- 테이블명                
                  '#KPX_TPDSFCProdPackReportItemLog'    , -- 임시 테이블명                
                  'PackReportSeq,PackReportSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )                
                  @TableColumns , '', 1  -- 테이블 모든 필드명           
    
    DELETE C         
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
      JOIN KPX_TPDSFCProdPackReport     AS C ON ( C.CompanySeq = @CompanySeq AND C.PackReportSeq = B.PackReportSeq )         
     WHERE A.WorkingTag IN ( 'U', 'D' )   
                 
                
    DELETE B        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackReportItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
     WHERE A.WorkingTag IN ( 'U', 'D' )   
    
    -- 마스터 데이터 #Temp
    INSERT INTO #KPX_TPDSFCProdPackReport         
    (        
        CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
        OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
        LastUserSeq         
    )        
    SELECT @CompanySeq, 0, A.FactUnit, WorkEndDate, '',         
           C.OutWHSeq, C.InWHSeq, B.UMProgType, C.SubOutWHSeq, B.Remark,         
           B.LastUserSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackOrder AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq )         
	  JOIN KPX_TPDSFCProdPackOrderItem AS C ON ( C.CompanySeq = @CompanySeq AND C.PackOrderSeq = A.WorkOrderSeq AND C.PackOrderSerl = A.WorkOrderSerl )         
     WHERE A.WorkingTag IN ( 'U', 'A' )   
    
    -- 디테일 데이터 #Temp
    INSERT INTO #KPX_TPDSFCProdPackReportItem         
    (        
        CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
        Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
        SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
        LastUserSeq         
    )        
    SELECT @CompanySeq, 0, 0, A.GoodItemSeq, B.UnitSeq,         
           A.RealProdQty, B.LotNo, B.OutLotNo, B.Remark, B.SubItemSeq,         
           B.SubUnitSeq, ISNULL(A.SubQty,0), A.HambaDrainQty, A.WorkOrderSeq, A.WorkOrderSerl,         
           B.LastUserSeq        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.WorkOrderSeq AND B.PackOrderSerl = A.WorkOrderSerl )         
     WHERE A.WorkingTag IN ( 'U', 'A' )   
    
    SELECT @Count = (SELECT COUNT(1) FROM #BaseData)
    
    SELECT @Seq = 0         
    -- 키값생성코드부분 시작    

	DELETE FROM _TCOMCreateSeqMax WHERE CompanySeq = @CompanySeq AND TableName = 'KPX_TPDSFCProdPackReport'      
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_TPDSFCProdPackReport', 'PackReportSeq', @Count
    
            
    UPDATE A         
       SET PackReportSeq = @Seq + IDX_NO      
      FROM #KPX_TPDSFCProdPackReport AS A         

    UPDATE A         
       SET PackReportSeq = @Seq + IDX_NO,         
           PackReportSerl = 1     
      FROM #KPX_TPDSFCProdPackReportItem AS A          
    
    
    SELECT @Cnt = 1 
    
    -- 번호 채번 
    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @Date = PackDate 
          FROM #KPX_TPDSFCProdPackReport  
        
        EXEC dbo._SCOMCreateNo 'PD', 'KPX_TPDSFCProdPackReport', @CompanySeq, 0, @Date, @ReportNo OUTPUT 
        
        UPDATE A 
           SET ReportNo = @ReportNo 
          FROM #KPX_TPDSFCProdPackReport AS A 
         WHERE IDX_NO = @Cnt 
        
        
        
        IF @Cnt >= (SELECT ISNULL(MAX(IDX_NO),0) FROM #BaseData)
        BEGIN
            BREAK 
        END 
        ELSE 
        BEGIN 
            SELECT @Cnt = @Cnt + 1 
        END 
    
    END 
                
    INSERT INTO KPX_TPDSFCProdPackReport         
    (        
        CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
        OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
        LastUserSeq, LastDateTime         
    )        
    SELECT CompanySeq, PackReportSeq, FactUnit, PackDate, ReportNo,         
           OutWHSeq, InWHSeq, UMProgType, DrumOutWHSeq, Remark,         
           LastUserSeq, GETDATE()         
      FROM #KPX_TPDSFCProdPackReport         
              
    INSERT INTO KPX_TPDSFCProdPackReportItem         
    (        
        CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
        Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
        SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
        LastUserSeq, LastDateTime        
    )        
    SELECT CompanySeq, PackReportSeq, PackReportSerl, ItemSeq, UnitSeq,         
             Qty, LotNo, OutLotNo, Remark, SubItemSeq,         
           SubUnitSeq, SubQty, HambaQty, PackOrderSeq, PackOrderSerl,         
           LastUserSeq, GETDATE()        
      FROM #KPX_TPDSFCProdPackReportItem       
    ------------------------------------------------------------------------------------------------------------------------    
    -- 포장실적, END 
    ------------------------------------------------------------------------------------------------------------------------    
    

    -- MES에서 실적 월변경시 재고재집계 오류남
    -- 수정삭제시 해당건의 InOutStock, InOutLotStock 삭제 조치 2016.10.05 by이재천 
    SELECT A.InOutType, A.InOutSeq, A.InOutSerl 
      INTO #DeleteStock
      FROM KPX_TPDSFCProdPackReportRelation AS A 
      JOIN #BaseData                        AS B ON ( B.WorkorderSeq = A.WOrkorderSeq AND B.WorkOrderSerl = A.WorkorderSerl ) 
     WHERE A.CompanySEq = @CompanySeq 
       AND B.WorkingTag IN ( 'U', 'D' ) 
    
    DELETE A 
      FROM _TLGInOutStock AS A 
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #DeleteStock WHERE InOutType = A.InOutType AND InOutSeq = A.InOutSeq AND InOutSerl = A.InOutSerl ) 

    DELETE A 
      FROM _TLGInOutLotStock AS A 
     WHERE CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #DeleteStock WHERE InOutType = A.InOutType AND InOutSeq = A.InOutSeq AND InOutSerl = A.InOutSerl ) 
    -- MES월변경 오류관련 END 


    --select GETDATE() 
    CREATE TABLE #TLGStockReSumCheck (WorkingTag NCHAR(1) NULL)
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 7583, 'DataBlock1', '#TLGStockReSumCheck'
    
     CREATE TABLE #TLGStockReSum (WorkingTag NCHAR(1) NULL)      
     ExEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 5248, 'DataBlock1', '#TLGStockReSum'     

    -- 재고재집계 
    DECLARE @XmlData NVARCHAR(MAX) 
    
    CREATE TABLE #Date 
    (
        IDX_NO      INT IDENTITY, 
        StdYM       NCHAR(6) 
    )
    
    INSERT INTO #Date (StdYM) 
    SELECT DISTINCT LEFT(WorkEndDate,6) AS StdYM 
      FROM #BaseData
     ORDER BY LEFT(WorkEndDate,6)
    
    
    SELECT @XmlData = CONVERT(NVARCHAR(MAX), ( SELECT 'U' AS WorkingTag,         
                                                      A.IDX_NO AS IDX_NO, 
                                                      A.IDX_NO AS DataSeq,         
                                                      1 AS Selected,         
                                                      0 AS Status,         
                                                      A.StdYM AS InOutYM, 
                                                      0 AS UserSeq, 
                                                      0 AS SMInOutType
                                                 FROM #Date AS A 
                                                FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS           
                                                 ))         

    

    INSERT INTO #TLGStockReSumCheck 
    EXEC _SLGReInOutStockCheck 
         @xmlDocument  = @XmlData,           
         @xmlFlags     = 2,           
         @ServiceSeq   = 7583,           
         @WorkingTag   = '',           
         @CompanySeq   = @CompanySeq,           
         @LanguageSeq  = 1,           
         @UserSeq      = 1,           
         @PgmSeq       = 1021351    
    
--select * from #TLGStockReSumCheck 

--return 
    
    INSERT INTO #TLGStockReSum 
    EXEC _SLGReInOutStockSum 
         @xmlDocument  = @XmlData,           
         @xmlFlags     = 2,           
         @ServiceSeq   = 5248,           
         @WorkingTag   = '',           
         @CompanySeq   = @CompanySeq,           
         @LanguageSeq  = 1,           
         @UserSeq      = 1,           
         @PgmSeq       = 1021351    
    
--    --select LEFT(WorkEndDate,6), SubItemSeq from #BaseData
--    --select GETDATE()  
    
    
--    return 

    /*
        
    exec _SLGReInOutStockCheck @xmlDocument=N'<ROOT>
      <DataBlock1>
        <WorkingTag>U</WorkingTag>
        <IDX_NO>12</IDX_NO>
        <DataSeq>1</DataSeq>
        <Status>0</Status>
        <Selected>0</Selected>
        <InOutYM>201512</InOutYM>
        <SMInOutType>0</SMInOutType>
        <UserSeq>50322</UserSeq>
        <TABLE_NAME>DataBlock1</TABLE_NAME>
      </DataBlock1>
    </ROOT>',@xmlFlags=2,@ServiceSeq=7583,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5956


    exec _SLGReInOutStockSum @xmlDocument=N'<ROOT>
      <DataBlock1>
        <WorkingTag>U</WorkingTag>
        <IDX_NO>11</IDX_NO>
        <DataSeq>1</DataSeq>
        <Selected>0</Selected>
        <Status>0</Status>
        <InOutYM>201511</InOutYM>
        <SMInOutType>0</SMInOutType>
        <UserSeq>0</UserSeq>
      </DataBlock1>
    </ROOT>',@xmlFlags=2,@ServiceSeq=5248,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=0,@PgmSeq=5956
    */

    
    UPDATE B        
       SET B.ProcYn = '1', ProcDateTime = GetDate(), ErrorMessage = ''        
      FROM #BaseData AS A         
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
    
    SELECT B.*
      FROM #BaseData AS A 
      JOIN KPX_TPDSFCWorkReport_POP AS B ON ( B.CompanySeq = @CompanySeq AND B.Seq = A.Seq ) 
    
    
    RETURN 



GO


