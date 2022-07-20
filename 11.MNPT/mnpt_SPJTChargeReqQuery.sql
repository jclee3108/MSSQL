IF OBJECT_ID('mnpt_SPJTChargeReqQuery') IS NOT NULL
    DROP PROC mnpt_SPJTChargeReqQuery
GO 
/************************************************************
 설  명		- 청구대상조회(생성)_mnpt
 작성일		- 2017년 9월 08일  
 작성자		- 방혁
 수정사항	- 
 ************************************************************/
 CREATE PROC mnpt_SPJTChargeReqQuery  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
	DECLARE @ChargeDate			NCHAR(6),
			@UMContractType		INT,
			@IFShipCode			NVARCHAR(100),
			@ShipYear			NVARCHAR(100),
			@ShipSerl			NVARCHAR(100),
			@BizUnit			INT,
			@UMChargeType		INT,
			@ShipSeq			INT,
			@PJTName			NVARCHAR(100),
			@PJTTypeName		NVARCHAR(100),
			@CustName			NVARCHAR(100),
			@SMExpKind			INT,
			@UMExampleKind		INT,
			@UMChargeCreate		INT,
			@UMChargeComplete	INT,
			@PJTNo				NVARCHAR(100),
			@ContractName		NVARCHAR(100),
			@ContractNo			NVARCHAR(100),
			@OutFrDate			NCHAR(8),
			@OutToDate			NCHAR(8),
			@ChargeFrDate		NCHAR(6),
			@ChargeToDate		NCHAR(6)
	SELECT @ChargeDate			= ISNULL(ChargeDate, ''),
		   @UMContractType		= ISNULL(UMContractType, 0),
		   @IFShipCode			= ISNULL(IFShipCode, ''),
		   @ShipYear			= ISNULL(ShipYear, ''),
		   @ShipSerl			= ISNULL(ShipSerl, ''),
		   @BizUnit				= ISNULL(BizUnit, 0),
		   @UMChargeType		= ISNULL(UMChargeType, 0),
		   @ShipSeq				= ISNULL(ShipSeq, 0),
		   @PJTName				= ISNULL(PJTName, ''),
		   @PJTTypeName			= ISNULL(PJTTypeName, ''),
		   @CustName			= ISNULL(CustName, ''),
		   @SMExpKind			= ISNULL(SMExpKind, 0),
		   @UMExampleKind		= ISNULL(UMExampleKind, 0),
		   @UMChargeCreate		= ISNULL(UMChargeCreate, 0),
		   @UMChargeComplete	= ISNULL(UMChargeComplete, 0),
		   @PJTNo				= ISNULL(PJTNo, 0),
		   @ContractName		= ISNULL(ContractName, 0),
		   @ContractNo			= ISNULL(ContractNo	, 0),
		   @OutFrDate			= ISNULL(OutFrDate, ''),
		   @OutToDate			= ISNULL(OutToDate, ''),
		   @ChargeFrDate		= ISNULL(ChargeFrDate, ''),
		   @ChargeToDate		= ISNULL(ChargeToDate, '')
	  FROM #BIZ_IN_DataBlock1	
	  

	CREATE TABLE #tmpContract (
		BizUnitName				NVARCHAR(100),
		ContractName			NVARCHAR(100),
		ContractNo				NVARCHAR(100),
		UMContractTypeName		NVARCHAR(100),
		UMContractKindName		NVARCHAR(100),
		PJTTypeName				NVARCHAR(100),
		PJTNo					NVARCHAR(100),
		PJTName					NVARCHAR(100),
		CustName				NVARCHAR(100),
		UMChargeTypeName		NVARCHAR(100),
		SMExpKindName			NVARCHAR(100),
		ContractFrDate			NCHAR(8),
		ContractToDate			NCHAR(8),
		IsFakeContract			NCHAR(1),
		IsContractSideFee		NCHAR(1),
		IsContractLoadFee		NCHAR(1),
		IsContractStorageFee	NCHAR(1),
		ContractFrDateYM		NCHAR(6),
		ContractToDateYM		NCHAR(6),
		ContractSeq				INT,
		PJTSeq					INT,
		UMWorkType				INT,
		IsShip					NCHAR(1),
		ChargeDate				NCHAR(8)
	)
	/*
		조회조건중 라디오버튼 주석
		계약적용일기준보기(종료제외) : 청구대상월에 걸리는 계약데이터 조회 (계약종료제외)
		계약전부보기(종료제외):모든 계약을 보여주되, 청구대상월 Fr ~ To에 해당하는 데이터만 월별로 뿌려주기
		작업기준보기: 작업실적을 기준으로 청구대상월에 걸리는 작업이있는 계약데이터보여주기.
	*/

	--계약건 청구월별로 담기..
	DECLARE @ChargeFrDate2	NCHAR(6)
	SELECT @ChargeFrDate2 = @ChargeFrDate
	WHILE(@ChargeFrDate2 <= @ChargeToDate)
	BEGIN
		INSERT INTO #tmpContract (
			BizUnitName,			ContractName,				ContractNo,					UMContractTypeName,
			UMContractKindName,		PJTTypeName,				PJTNo,						PJTName,
			CustName,				UMChargeTypeName,			SMExpKindName,				ContractFrDate,
			ContractToDate,			IsFakeContract,				IsContractSideFee,			IsContractLoadFee,
			IsContractStorageFee,	ContractFrDateYM,			ContractToDateYM,			ContractSeq,
			PJTSeq,					UMWorkType,					IsShip,
			ChargeDate
		)
		SELECT
			D.BizUnitName,			A.ContractName,				A.ContractNo,				E.MinorName,
			F.MinorName,			G.PJTTypeName,				C.PJTNo,					C.PJTName,
			H.CustName,				J.MinorName,				I.MinorName,				A.ContractFrDate,
			A.ContractToDate,		A.IsFakeContract,			'0',						'0',
			'0',					LEFT(A.ContractFrDate, 6),	LEFT(A.ContractToDate, 6),	A.ContractSeq,
			C.PJTSeq,				0,							CASE WHEN ISNULL(K.ValueText, 0) = 0 THEN '0' ELSE '1' END,
			@ChargeFrDate2
		  FROM mnpt_TPJTContract AS A WITH(NOLOCK)		
			   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ContractSeq	= A.ContractSeq
			   INNER JOIN _TPJTProject AS C WITH(NOLOCK)
					   ON C.CompanySeq	= B.CompanySeq
					  AND C.PJTseq		= B.PJTSeq
			   LEFT  JOIN _TDABizUnit AS D WITH(NOLOCK)
					   ON D.CompanySeq	= A.CompanySeq
					  AND D.BizUnit		= A.BizUnit
			   LEFT  JOIN _TDAUMinor AS E WITH(NOLOCK)
					   ON E.CompanySeq	= A.CompanySeq
					  AND E.Minorseq	= A.UMContractType
			   LEFT  JOIN _TDAUMinor AS F WITH(NOLOCK)
					   ON F.CompanySeq	= A.CompanySeq
					  AND F.Minorseq	= A.UMContractKind
			   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
					   ON G.CompanySeq	= C.CompanySeq
					  AND G.PJTTypeSeq	= C.PJTTypeSeq
			   LEFT  JOIN _TDACust AS H WITH(NOLOCK)
					   ON H.CompanySeq	= A.CompanySeq
					  AND H.CustSeq		= A.CustSeq
			   LEFT  JOIN _TDASMinor AS I WITH(NOLOCK)
					   ON I.CompanySeq	= A.CompanySeq
					  AND I.MinorSeq	= A.SMExpKind
			   LEFT  JOIN _TDAUMinor AS J WITH(NOLOCK)
					   ON J.CompanySeq	= A.CompanySeq
					  AND J.Minorseq	= A.UMChargeType
			   LEFT  JOIN _TDAUMinorValue AS K WITH(NOLOCK)
					   ON K.CompanySeq	= A.CompanySeq
					  AND K.MinorSeq	= A.UMChargeType
					  AND K.Serl		= 1000001
					  AND K.ValueText	= '1'
			   LEFT  JOIN _TDAUMinorValue AS L WITH(NOLOCK)
					   ON L.CompanySeq	= A.CompanySeq
					  AND L.MinorSeq	= A.UMContractKind
					  AND L.Serl		= 1000002
					  AND L.MajorSeq	= 1015778
		 WHERE A.CompanySeq					= @CompanySeq
		   AND B.SourcePJTSeq				= 0
		   AND A.IsStop						= '0'
		   AND A.IsComplete					= '0'
		   AND ISNULL(L.ValueText, '0')		= '0'
		   AND (@BizUnit		= 0 OR A.BizUnit		= @BizUnit)
		   AND (@UMContractType	= 0 OR A.UMContractType	= @UMContractType)
		   AND (@UMChargeType	= 0 OR A.UMChargeType	= @UMChargeType)
		   AND (@SMExpKind		= 0 OR A.SMExpKind		= @SMExpKind)
		   AND @ChargeFrDate2 BETWEEN CASE WHEN @UMExampleKind = 1015856001 THEN LEFT(A.ContractFrDate, 6)
										   ELSE @ChargeFrDate2
										   END
								  AND CASE WHEN @UMExampleKind = 1015856001 THEN LEFT(A.ContractToDate, 6)
										   ELSE @ChargeFrDate2
										   END

		SELECT @ChargeFrDate2 = CONVERT(NCHAR(6),DATEADD(MM, +1, CONVERT(DATETIME, @ChargeFrDate2 + '01')) , 112)
	END
	--제주연안엑셀업로드맵핑에 등록되어있는 프로젝트는 안나오게 수정.
	DELETE #tmpContract
	  FROM #tmpContract AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM mnpt_TPJTEEExcelUploadMapping
					 WHERE PJTSeq	= A.PJTSeq
				)
	--화태에 매출대상아님이 등록된 프로젝트는 안보이게 수정.
	DELETE #tmpContract
	  FROM #tmpContract AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM _TPJTProject AS Z WITH(NOLOCK)
						   LEFT  JOIN _TPJTType AS Y WITH(NOLOCK)
								   ON Y.CompanySeq	= Z.CompanySeq
								  AND Y.PJTTypeSeq	= Z.PJTTypeSeq
					 WHERE Z.CompanySeq			= @CompanySeq
					   AND Z.PJTSeq				= A.PJTSeq
					   AND Y.SMSalesRecognize = 7002005
				)
	
	----계약적용일기준보기(종료제외) 체크시 청구대상에 포함되지 않는 프로젝트 삭제
	--보류, 청구대상월이 생기면서 청구대상월 조건을 안걸고 계약전부보기를 하면
	--각각의 계약건별로 청구월별로 모든 데이터를 담아야 하기때문에 테이블 FullScan을 들어가야함..
	--IF @UMExampleKind	= 1015856001
	--BEGIN
	--	DELETE #tmpContract
	--	  FROM #tmpContract
	--	 WHERE (ContractFrDateYM > @ChargeDate OR ContractToDateYM < @ChargeDate)
	--END
	DECLARE @EnvSideFee			INT,
			@EnvLoadFee			INT,
			@EnvStorageFee		INT
	--접안료 품목중분류
	SELECT @EnvSideFee	= EnvValue
	  FROM mnpt_TCOMEnv 
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 7
	--하역료 품목중분류
	SELECT @EnvLoadFee	= EnvValue
	  FROM mnpt_TCOMEnv 
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 8
	--보관료 품목중분류
	SELECT @EnvStorageFee	= EnvValue
	  FROM mnpt_TCOMEnv			
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 9
	--계약의 접안료, 하역료, 보관료 여부 Insert
	CREATE TABLE #tmpItemLClass(
		ContractSeq				INT,
		IsContractSideFee		NCHAR(1),
		IsContractLoadFee		NCHAR(1),
		IsContractStorageFee	NCHAR(1)
	)
	INSERT INTO #tmpItemLClass (
		ContractSeq,
		IsContractSideFee,
		IsContractLoadFee,
		IsContractStorageFee
	)
	SELECT
		A.ContractSeq,
		CASE WHEN ISNULL(D.IsContractSideFee, 0) = 0 THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(E.IsContractLoadFee, 0) = 0 THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(F.IsContractStorageFee, 0) = 0 THEN '0' ELSE '1' END
	  FROM mnpt_TPJTContract AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.ContractSeq	= A.ContractSeq
		   INNER JOIN _TPJTProject AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.PJTSeq		= B.PJTSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractSideFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS D 
				   ON D.ContractSeq	= A.ContractSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractLoadFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS E 
				   ON E.ContractSeq	= A.ContractSeq
		   LEFT  JOIN (
						SELECT E.ContractSeq, COUNT(1) AS IsContractStorageFee
						  FROM _TPJTProjectDelivery AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
								LEFT  JOIN mnpt_TPJTProject AS D WITH(NOLOCK)
									    ON D.CompanySeq	= A.CompanySeq
									   AND D.PJTSeq		= A.PJTSeq
							    LEFT  JOIN mnpt_TPJTContract AS E WITH(NOLOCK)
										ON E.CompanySeq		= D.CompanySeq
									   AND E.ContractSeq	= D.ContractSeq
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND D.SourcePJTSeq		= 0
						  GROUP BY E.ContractSeq
					) AS F 
				   ON F.ContractSeq	= A.ContractSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND B.SourcePJTSeq	= 0				--SourcePJTSeq = 0 : 원천프로젝트.
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE ContractSeq	= A.ContractSeq
				)
	 GROUP BY A.ContractSeq,
			  CASE WHEN ISNULL(D.IsContractSideFee, 0) = 0 THEN '0' ELSE '1' END,
			  CASE WHEN ISNULL(E.IsContractLoadFee, 0) = 0 THEN '0' ELSE '1' END,
			  CASE WHEN ISNULL(F.IsContractStorageFee, 0) = 0 THEN '0' ELSE '1' END

	--계약의 접안료, 하역료, 보관료 여부 Update
	UPDATE #tmpContract
	   SET IsContractSideFee	= ISNULL(B.IsContractSideFee, '0'),
		   IsContractLoadFee	= ISNULL(B.IsContractLoadFee, '0'),
		   IsContractStorageFee	= ISNULL(B.IsContractStorageFee, '0')
	  FROM #tmpContract AS A
		   LEFT  JOIN #tmpItemLClass AS B
				   ON B.ContractSeq		= A.ContractSeq


	--/************************************************************************
	--계약입력의 청구항목-작업항목 맵핑에서 청구항목의 중분류가 환경설정(추가개발용)_mnpt의
	--하역료 청구항목 중분류이면서, 청구금액산출대상에 체크가되어있으면서, 가장첫번째로 등록된
	--작업항목가져오기..
	--************************************************************************/
	CREATE TABLE #tmpWorktype(
		PJTSeq			INT,
		UMWorkType		INT
	)
	INSERT INTO #tmpWorktype
	SELECT A.PJTSeq, A.UMWorkType
	  FROM mnpt_TPJTProjectMapping AS A WITH(NOLOCK)
		   INNER JOIN (
						SELECT PJTSeq, MIN(MappingSerl) AS MappingSerl
						  FROM mnpt_TPJTProjectMapping AS A WITH(NOLOCK)
							   INNER JOIN _TDAItemClass AS B WITH(NOLOCK)
									   ON B.CompanySeq		= A.CompanySeq
									  AND B.ItemSeq			= A.ItemSeq
									  AND B.UMajorItemClass	IN (2001, 2004)
							   INNER JOIN _VDAItemClass AS C 
								       ON C.CompanySeq		= B.CompanySeq
									  AND C.ItemClassSSeq	= B.UMItemClass
						  WHERE A.CompanySeq	= @CompanySeq
						    AND C.ItemClassMSeq	= @EnvLoadFee
							AND A.IsAmt			= '1'
						  GROUP BY PJTSeq
					) AS B
				  ON B.PJTSeq		= A.PJTSeq
				 AND B.MappingSerl	= A.MappingSerl
	 WHERE A.CompanySeq	= @CompanySeq
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE PJTseq	= A.PJTseq
				)
	--프로젝트별 청구항목의 대표 작업항목 Mapping 업데이트.
	UPDATE #tmpContract
	   SET UMWorkType	= B.UMWorkType
	  FROM #tmpContract AS A
		   INNER JOIN #tmpWorktype AS B
				   ON B.PJTseq	= A.PJTSeq
	--작업실적 대상 구하기.
	CREATE TABLE #tmpShipDetail (
		ContractSeq		INT,
		PJTSeq			INT,
		WorkReportSeq	INT,
		ShipSeq			INT,
		ShipSerl		INT,
		IsShip			NCHAR(1),		
		WorkDateYM		NCHAR(6)
	)	
	INSERT INTO #tmpShipDetail (
		ContractSeq,		PJTSeq,			WorkReportSeq,
		ShipSeq,			ShipSerl,		IsShip,
		WorkDateYM
	)
	SELECT
		C.ContractSeq,		A.PJTSeq,		A.WorkReportSeq,
		A.ShipSeq,			A.ShipSerl,		CASE WHEN A.ShipSeq <> 0 THEN '1' ELSE '0' END,
		LEFT(A.WorkDate, 6)
	  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN mnpt_TPJTContract AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.ContractSeq	= B.ContractSeq
	 WHERE A.CompanySeq		= @CompanySeq
	   AND B.SourcePJTSeq	= 0
	   AND A.IsCfm			= '1'
	   AND EXISTS (
					SELECT 1
					  FROM #tmpContract
					 WHERE PJTSeq	= A.PJTSeq
				)

	CREATE TABLE #tmpShipResult (
		ContractSeq			INT,
		PJTSeq				NVARCHAR(100),
		WorkReportSeq		NVARCHAR(500),
		ShipSeq				INT,
		ShipSerl			INT,
		IsShip				NCHAR(1),
		IFShipCode			NVARCHAR(100),
		ShipYear			NVARCHAR(100),
		ShipSerl2			NVARCHAR(100),
		FullShipName		NVARCHAR(100),
		EnShipName			NVARCHAR(100),
		ShipCnt				INT,
		InDateTime			NCHAR(8),
		OutDateTime			NCHAR(8),
		ApproachDateTime	INT,
		WorkDate			INT,
		WorkQty				DECIMAL(19, 5),
		TodayMTWeight		DECIMAL(19, 5),
		TodayCBMWeight		DECIMAL(19, 5),
		WorkCnt				INT,
		PJTName				NVARCHAR(100),
		PJTNo				NVARCHAR(100),
		PJTTypeName			NVARCHAR(100),
		ChargeDate			NCHAR(6)		--모선항차가있는건은 출항월. 없는건은 청구대상월.
	)

	--모선항차가 존재하는 실적은, 모선항차건별로 보여주되, 모든 실적데이터는 월에 상관없이 Sum데이터
	--IsShip = '1' : 모선항차가 존재하는 실적.
	IF EXISTS (SELECT 1 FROM #tmpShipDetail WHERE IsShip = '1' )
	BEGIN
		INSERT INTO #tmpShipResult (
			ContractSeq,
			PJTSeq,			
			WorkReportSeq,		
			ShipSeq,			
			ShipSerl,
			IsShip,		
			IFShipCode,
			ShipYear,
			ShipSerl2,
			FullShipName,		
			EnShipName,			
			ShipCnt,
			InDateTime,		
			OutDateTime,		
			ApproachDateTime,
			WorkDate,
			WorkQty,
			TodayMTWeight,
			TodayCBMWeight,
			WorkCnt,
			PJTName,
			PJTNo,
			PJTTypeName,
			ChargeDate
		)
		SELECT  
			C.ContractSeq,
		    C.PJTSeq					AS PJTSeq,
		    CASE WHEN C.WorkReportSeq IS NULL OR LEN(C.WorkReportSeq) = 0 THEN '' 
				 ELSE  SUBSTRING(C.WorkReportSeq, 1,  LEN(C.WorkReportSeq) -1 ) END		AS WorkReportSeq,
			A.ShipSeq,
			A.ShipSerl,
			C.IsShip,
		    A.IFShipCode, 
		    LEFT(A.ShipSerlNo, 4),
		    RIGHT(A.ShipSerlNo, 3),
			
			A.IFShipCode + '-' + LEFT(A.ShipSerlNo, 4) + '-' + RIGHT(A.ShipSerlNo, 3)  AS FullShipName,	--모선항차
			B.EnShipName,										--모선명
			1,													--모선항차횟수(모선항차일경우는 무조건 1이다, 모선별로 1건씩 보여주기 때문에)
			LEFT(A.InDateTime, 8)		AS InDateTime,			--입항일
			LEFT(A.OutDateTime, 8)		AS OutDateTime,			--출항일
			A.DiffApproachTime			AS DiffApproachTime,	--작업시간
			C.WorkDatecnt				AS WorkDatecnt,			--작업일수
			C.WorkQty					AS WorkQty,				--수량
			C.TodayMTWeight				AS TodayMTWeight,		--작업량(MT)
			C.TodayCBMWeight			AS TodayCBMWeight,		--작업량(CBM)
			C.WorkCnt					AS WorkCnt,				--작업항목수
			C.PJTName					AS PJTName,
			C.PJTNo						AS PJTNo,
			C.PJTTypeName				AS PJTTypeName,
			LEFT(A.OutDateTime, 6)
		  FROM  (
							SELECT A.ContractSeq, 
								   A.ShipSeq, 
								   A.ShipSerl,
								   A.IsShip,
								   B.WorkDatecnt,
								   C.WorkQty,
								   C.TodayMTWeight,
								   C.TodayCBMWeight,
								   D.WorkCnt,
								   E.WorkReportSeq,
								   F.PJTSeq,
								   F.PJTName,
								   F.PJTNo,
								   G.PJTTypeName
							  FROM #tmpShipDetail AS A
								   --모선항차별로 작업일수 구하기
								   --같은날에 여러건의 작업이 있어도 해당 작업일은 1로 쳐야하기 때문에 Union으로 중복을 제거하고
								   --Count한다.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, COUNT(1) AS WorkDateCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq
											) AS B 
										   ON B.ContractSeq		= A.ContractSeq
										  AND B.ShipSeq			= A.ShipSeq
										  AND B.ShipSerl		= A.ShipSerl
										  AND B.PJTSeq			= A.PJTSeq
								  LEFT  JOIN (
												--계약입력의 청구항목 -작업항목 매핑에 매핑된 작업의 수량가져오기.
												SELECT B.ContractSeq,
													   A.ShipSeq,
													   A.ShipSerl,
													   A.PJTSeq,
													   SUM(A.TodayQty)			AS WorkQty,
													   SUM(A.TodayMTWeight)		AS TodayMTWeight,
													   SUM(A.TodayCBMWeight)	AS TodayCBMWeight
												  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
													   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
															   ON B.CompanySeq	= A.CompanySeq
															  AND B.PJTSeq		= A.PJTSeq
													   INNER JOIN #tmpWorktype AS C
															   ON C.PJTSeq		= A.PJTSeq
															  AND C.UMWorkType	= A.UMWorkType
												 WHERE A.CompanySeq	= @CompanySeq
												   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																SELECT 1
																  FROM #tmpShipDetail 
																  WHERE WorkReportSeq	= A.WorkReportSeq
																   AND IsShip			= '1'
															)
												 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq
											) AS C 
										   ON C.ContractSeq	= A.ContractSeq
										  AND C.ShipSeq		= A.ShipSeq
										  AND C.ShipSerl	= A.ShipSerl
										  AND C.PJTSEq		= A.PJTSeq
								   --모선항차별로 작업항목수 구하기
								   --다른날에 여러건의 작업이 있어도 해당 작업항목은 1로 가져가야하기 때문에 Union으로 중복을 제거하고
								   --Count한다.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, COUNT(1) AS WorkCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '1'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.UMWorkType
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSEq
											) AS D 
										   ON D.ContractSeq	= A.ContractSeq
										  AND D.ShipSeq		= A.ShipSeq
										  AND D.ShipSerl	= A.ShipSerl
										  AND D.PJTSeq		= A.PJTSeq
								   --하나의 모선청구건에 어떤 작업실적내부코드가 걸려있는지 ','로 구분하여 보여주기.
								   LEFT  JOIN (
												SELECT ContractSeq, ShipSeq, ShipSerl, PJTSeq,
														(
															SELECT CONVERT(NVARCHAR(100), WorkReportSeq) + ','
															  FROM #tmpShipDetail
															 WHERE ShipSeq		= A.ShipSeq
															   AND ShipSerl		= A.ShipSerl
															   AND ContractSeq	= A.ContractSeq
															   AND PJTSeq		= A.PJTSeq
															 ORDER BY WorkReportSeq for xml path('')
															) AS WorkReportSeq
												  FROM #tmpShipDetail AS A
												 WHERE A.IsSHip	= '1'
												 GROUP BY ContractSeq, ShipSeq, ShipSerl, PJTSeq
											) AS E
										   ON E.ContractSeq	= A.ContractSeq
										  AND E.ShipSeq		= A.ShipSeq
										  AND E.ShipSerl	= A.ShipSerl
										  AND E.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
										   ON F.CompanySeq	= @CompanySeq
										  AND F.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
										   ON G.CompanySeq	= F.CompanySeq
										  AND G.PJTTypeSeq	= F.PJTTypeSeq
							 WHERE IsShip	= '1'	--모선청구일경우
							 GROUP BY A.ContractSeq,	A.ShipSeq,				A.ShipSerl,			B.WorkDatecnt, 
									  C.WorkQty,		C.TodayMTWeight,		C.TodayCBMWeight,	D.WorkCnt,	 
									  E.WorkReportSeq,	F.PJTSeq,				F.PJTName,			G.PJTTypeName,	
									  A.IsShip,			F.PJTNo
						) AS C 
			   LEFT  JOIN MNPT_TPJTShipDetail AS A WITH(NOLOCK)
					   ON A.ShipSeq		= C.ShipSeq
					  AND A.ShipSerl	= C.ShipSerl
			   LEFT  JOIN MNPT_TPJTShipMaster AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ShipSeq		= A.ShipSeq
	     WHERE EXISTS (
						SELECT 1
						  FROM #tmpShipDetail
						 WHERE ShipSeq	= C.ShipSeq
						   AND ShipSerl	= C.ShipSerl
						   AND IsShip	= '1'
					)
		   AND LEFT(A.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	END
	--모선이 없는건은 해당 청구월에 맞는 데이터만 집계해서 보여주기.
	--IsShip = '0' : 모선항차가 없는 실적..
	IF EXISTS (SELECT 1 FROM #tmpShipDetail WHERE IsShip = '0')
	BEGIN
		INSERT INTO #tmpShipResult (
			ContractSeq,
			PJTSeq,			
			WorkReportSeq,		
			ShipSeq,			
			ShipSerl,
			IsShip,		
			IFShipCode,
			ShipYear,
			ShipSerl2,
			FullShipName,		
			EnShipName,			
			ShipCnt,
			InDateTime,		
			OutDateTime,		
			ApproachDateTime,
			WorkDate,
			WorkQty,
			TodayMTWeight,
			TodayCBMWeight,
			WorkCnt,
			PJTName,
			PJTNo,
			PJTTypeName,
			ChargeDate
		)
		SELECT  
			C.ContractSeq,
		    C.PJTSeq		AS PJTSeq,
		    CASE WHEN C.WorkReportSeq IS NULL OR LEN(C.WorkReportSeq) = 0 THEN '' 
				 ELSE  SUBSTRING(C.WorkReportSeq, 1,  LEN(C.WorkReportSeq) -1 ) END		AS WorkReportSeq,
			0,
			0,
			C.IsShip,
		    '', 
		    '',
		    '',
			
			''  AS FullShipName,	--모선항차
			'',													--모선명
			1,													--모선항차횟수(모선항차일경우는 무조건 1이다, 모선별로 1건씩 보여주기 때문에)
			''							AS InDateTime,			--입항일
			''							AS OutDateTime,			--출항일
			0							AS DiffApproachTime,	--작업시간
			C.WorkDatecnt				AS WorkDatecnt,			--작업일수
			C.WorkQty					AS WorkQty,				--수량
			C.TodayMTWeight				AS TodayMTWeight,		--작업량(MT)
			C.TodayCBMWeight			AS TodayCBMWeight,		--작업량(CBM)
			C.WorkCnt					AS WorkCnt,				--작업항목수
			C.PJTName					AS PJTName,
			C.PJTNo						AS PJTNo,
			C.PJTTypeName				AS PJTTypeName,
			C.WorkDateYM
		  FROM  (
							SELECT A.ContractSeq, 
								   A.ShipSeq, 
								   A.ShipSerl,
								   A.IsShip,
								   B.WorkDatecnt,
								   C.WorkQty,
								   C.TodayMTWeight,
								   C.TodayCBMWeight,
								   D.WorkCnt,
								   E.WorkReportSeq,
								   F.PJTSeq,
								   F.PJTName,
								   F.PJTNo,
								   G.PJTTypeName,
								   A.WorkDateYM
							  FROM #tmpShipDetail AS A
								   --모선항차별로 작업일수 구하기
								   --같은날에 여러건의 작업이 있어도 해당 작업일은 1로 쳐야하기 때문에 Union으로 중복을 제거하고
								   --Count한다.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM, COUNT(1) AS WorkDateCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.WorkDate
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.WorkDate
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.WorkDate
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM
											) AS B 
										   ON B.ContractSeq		= A.ContractSeq
										  AND B.ShipSeq			= A.ShipSeq
										  AND B.ShipSerl		= A.ShipSerl
										  AND B.PJTSeq			= A.PJTSeq
										  AND B.WorkDateYM		= A.WorkDateYM
								  LEFT  JOIN (
												--계약입력의 청구항목 -작업항목 매핑에 매핑된 작업의 수량가져오기.
												SELECT B.ContractSeq,
													   A.ShipSeq,
													   A.ShipSerl,
													   A.PJTSeq,
													   LEFT(A.WorkDate, 6)		AS WorkDateYM,
													   SUM(A.TodayQty)			AS WorkQty,
													   SUM(A.TodayMTWeight)		AS TodayMTWeight,
													   SUM(A.TodayCBMWeight)	AS TodayCBMWeight
												  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
													   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
															   ON B.CompanySeq	= A.CompanySeq
															  AND B.PJTSeq		= A.PJTSeq
													   INNER JOIN #tmpWorktype AS C
															   ON C.PJTSeq		= A.PJTSeq
															  AND C.UMWorkType	= A.UMWorkType
												 WHERE A.CompanySeq	= @CompanySeq
												   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																SELECT 1
																  FROM #tmpShipDetail 
																  WHERE WorkReportSeq	= A.WorkReportSeq
																   AND IsShip			= '0'
															)
												 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6)
											) AS C 
										   ON C.ContractSeq	= A.ContractSeq
										  AND C.ShipSeq		= A.ShipSeq
										  AND C.ShipSerl	= A.ShipSerl
										  AND C.PJTSeq		= A.PJTSeq
										 AND C.WorkDateYM	= A.WorkDateYM
								   --모선항차별로 작업항목수 구하기
								   --다른날에 여러건의 작업이 있어도 해당 작업항목은 1로 가져가야하기 때문에 Union으로 중복을 제거하고
								   --Count한다.
								   LEFT  JOIN (
												SELECT S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM, COUNT(1) AS WorkCnt
												  FROM (
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.UMWorkType
															 UNION 
															SELECT B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6) AS WorkDateYM, A.UMWorkType
															  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
																   INNER JOIN mnpt_TPJTProject AS B WITH(NOLOCK)
																		   ON B.CompanySeq	= A.CompanySeq
																		  AND B.PJTSeq		= A.PJTSeq
															 WHERE A.CompanySeq = @CompanySeq
															   AND EXISTS (						--해당 조건을 안걸면 다른월에 있는 데이터도 가져온다.
																			SELECT 1
																			  FROM #tmpShipDetail 
																			 WHERE WorkReportSeq	= A.WorkReportSeq
																			   AND IsShip			= '0'
																		)
															 GROUP BY B.ContractSeq, A.ShipSeq, A.ShipSerl, A.PJTSeq, LEFT(A.WorkDate, 6), A.UMWorkType
														) AS S
												 GROUP BY S.ContractSeq, S.ShipSeq, S.ShipSerl, S.PJTSeq, S.WorkDateYM
											) AS D 
										   ON D.ContractSeq	= A.ContractSeq
										  AND D.ShipSeq		= A.ShipSeq
										  AND D.ShipSerl	= A.ShipSerl
										  AND D.PJTSeq		= A.PJTSeq
										  AND D.WorkDateYM	= A.WorkDateYM
								   --하나의 모선청구건에 어떤 작업실적내부코드가 걸려있는지 ','로 구분하여 보여주기.
								   LEFT  JOIN (
												SELECT ContractSeq, ShipSeq, ShipSerl, PJTSeq, WorkDateYM,
														(
															SELECT CONVERT(NVARCHAR(100), WorkReportSeq) + ','
															  FROM #tmpShipDetail
															 WHERE ShipSeq		= A.ShipSeq
															   AND ShipSerl		= A.ShipSerl
															   AND ContractSeq	= A.ContractSeq
															   AND WorkDateYM	= A.WorkDateYM
															   AND PJTSeq		= A.PJTSeq
															 ORDER BY WorkReportSeq for xml path('')
															) AS WorkReportSeq
												  FROM #tmpShipDetail AS A
												 WHERE A.IsSHip	= '0'
												 GROUP BY ContractSeq, ShipSeq, ShipSerl, WorkDateYM, PJTSeq
											) AS E
										   ON E.ContractSeq	= A.ContractSeq
										  AND E.ShipSeq		= A.ShipSeq
										  AND E.ShipSerl	= A.ShipSerl
										  AND E.WorkDateYM	= A.WorkDateYM
										  AND E.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
										   ON F.CompanySeq	= @CompanySeq
										  AND F.PJTSeq		= A.PJTSeq
								   LEFT  JOIN _TPJTType AS G WITH(NOLOCK)
										   ON G.companySeq	= F.CompanySeq
										  AND G.PJTTypeSeq	= F.PJTTypeSeq
							 WHERE IsShip	= '0'	--모선청구일경우
							 GROUP BY A.ContractSeq,	A.ShipSeq,				A.ShipSerl,			B.WorkDatecnt, 
									  C.WorkQty,		C.TodayMTWeight,		C.TodayCBMWeight,	D.WorkCnt,	 
									  E.WorkReportSeq,	F.PJTSeq,				F.PJTName,			G.PJTTypeName,	
									  A.IsShip,			F.PJTNo,				A.WorkDateYM
						) AS C 
			   LEFT  JOIN MNPT_TPJTShipDetail AS A WITH(NOLOCK)
					   ON A.ShipSeq		= C.ShipSeq
					  AND A.ShipSerl	= C.ShipSerl
			   LEFT  JOIN MNPT_TPJTShipMaster AS B WITH(NOLOCK)
					   ON B.CompanySeq	= A.CompanySeq
					  AND B.ShipSeq		= A.ShipSeq
	     WHERE EXISTS (
						SELECT 1
						  FROM #tmpShipDetail
						 WHERE ShipSeq	= C.ShipSeq
						   AND ShipSerl	= C.ShipSerl
						   AND IsShip	= '0'
					)
		   AND C.WorkDateYM	BETWEEN @ChargeFrDate AND @ChargeToDate
	END
	--같은 청구대상월에 모선항차가 있는게 존재하면 모선항차 없는 실적은 삭제하기,
	--모선항차가있는 데이터로 청구생성할거니깐..
	DELETE #tmpShipResult
	  FROM #tmpShipResult AS A
	 WHERE ShipSeq	= 0
	   AND EXISTS (
					SELECT 1
					  FROM #tmpShipResult
					 WHERE ContractSeq	= A.ContractSeq
					   AND PJTseq		= A.PJTSeq
					   AND ChargeDate	= A.ChargeDate
					   ANd ShipSeq		<> 0
				)

	--실적이 존재하지 않는 계약은 계약의 프로젝트, 프로젝트번호, 화태를 보여주고
	--실적이 존재하는 계약은 실적구할때 담은 프로젝트, 프로젝트번호, 화태를 보여준다.
	--실적으로 진행될시 여러개의 프로젝트가 하나의 모선청구 또는 월청구로 담길수있기때문에.
	SELECT ISNULL(A.BizUnitName, '')			AS BizUnitName,
		   A.ContractSeq						AS ContractSeq,
		   A.ContractName						AS ContractName,
		   A.ContractNo							AS ContractNo,
		   A.PJTName							AS PJTName,
		   A.PJTNo								AS PJTNo,
		   ISNULL(A.CustName, '')				AS CustName,
		   ISNULL(A.PJTTypeName, '')			AS PJTTypeName,
		   ISNULL(A.UMContractTypeName, '')		AS UMContractTypeName,
		   ISNULL(A.UMContractKindName, '')		AS UMContractKindName,
		   ISNULL(A.UMChargeTypeName, '')		AS UMChargeTypeName,
		   ISNULL(A.ContractFrDate, '')			AS ContractFrDate,
		   ISNULL(A.ContractToDate, '')			AS ContractToDate,
		   ISNULL(A.IsFakeContract, '0')		AS IsFakeContract,
		   ISNULL(A.IsContractSideFee, '0')		AS IsContractSideFee,
		   ISNULL(A.IsContractLoadFee ,'0')		AS IsContractLoadFee,
		   ISNULL(A.IsContractStorageFee, '')	AS IsContractStorageFee,
		   A.PJTSeq								AS PJTSeq,
		   ''									AS WorkReportSeq,
		   0									AS ShipSeq,
		   0									AS ShipSerl,
		   A.IsShip								AS IsShip,
		   ''									AS IFShipCode,
		   ''									AS ShipYear,
		   ''									AS ShipSerl2,
		   ''									AS FullShipName,
		   ''									AS EnShipName,
		   0									AS ShipCnt,
		   ''									AS InDateTime,
		   ''									AS OutDateTime,
		   0									AS ApproachDateTime,
		   ''									AS WorkDate,
		   0									AS WorkQty,
		   0									AS TodayMTWeight,
		   0									AS TodayCBMWeight,
		   0									AS WorkCnt,
		   ChargeDate							AS ChargeDate,
		   '0'									AS IsCNT,
		   '0'									AS IsDock
	  INTO #tmpResult2
	  FROM #tmpContract AS A
	 WHERE NOT EXISTS (
						SELECT 1
						  FROM #tmpShipResult
						 WHERE ContractSeq	= A.ContractSeq
						   AND ChargeDate	= A.ChargeDate
						   AND PJTSeq		= A.PJTSeq
					)
	UNION ALL
	SELECT DISTINCT 
	       ISNULL(B.BizUnitName, '')			AS BizUnitName,
		   B.ContractSeq						AS ContractSeq,
		   B.ContractName						AS ContractName,
		   B.ContractNo							AS ContractNo,
		   A.PJTName							AS PJTName,
		   A.PJTNo								AS PJTNo,
		   ISNULL(B.CustName, '')				AS CustName,
		   ISNULL(A.PJTTypeName, '')			AS PJTTypeName,
		   ISNULL(B.UMContractTypeName, '')		AS UMContractTypeName,
		   ISNULL(B.UMContractKindName, '')		AS UMContractKindName,
		   ISNULL(B.UMChargeTypeName, '')		AS UMChargeTypeName,
		   ISNULL(B.ContractFrDate, '')			AS ContractFrDate,
		   ISNULL(B.ContractToDate, '')			AS ContractToDate,
		   ISNULL(B.IsFakeContract, '')			AS IsFakeContract,
		   ISNULL(B.IsContractSideFee, '0')		AS IsContractSideFee,
		   ISNULL(B.IsContractLoadFee, '0')		AS IsContractLoadFee,
		   ISNULL(B.IsContractStorageFee, '0')	AS IsContractStorageFee,
		   ISNULL(A.PJTSeq, '')					AS PJTSeq,
		   ISNULL(A.WorkReportSeq, '')			AS WorkReportSeq,
		   ISNULL(A.ShipSeq, 0)					AS ShipSeq,
		   ISNULL(A.ShipSerl, 0)				AS ShipSerl,
		   ISNULL(A.IsShip, '')					AS IsShip,
		   ISNULL(A.IFShipCode, '')				AS IFShipCode,
		   ISNULL(A.ShipYear, '')				AS ShipYear,
		   ISNULL(A.ShipSerl2, 0)				AS ShipSerl2,
		   ISNULL(A.FullShipName, '')			AS FullShipName,
		   ISNULL(A.EnShipName, '')				AS EnShipName,
		   ISNULL(A.ShipCnt, 0)					AS ShipCnt,
		   ISNULL(A.InDateTime, '')				AS InDateTime,
		   ISNULL(A.OutDateTime, '')			AS OutDateTime,
		   ISNULL(A.ApproachDateTime, 0)		AS ApproachDateTime,
		   ISNULL(A.WorkDate, 0)				AS WorkDate,
		   ISNULL(A.WorkQty, 0)					AS WorkQty,
		   ISNULL(A.TodayMTWeight, 0)			AS TodayMTWeight,
		   ISNULL(A.TodayCBMWeight, 0)			AS TodayCBMWeight,
		   ISNULL(A.WorkCnt, 0)					AS WorkCnt,
		   A.ChargeDate							AS ChargeDate,
		   '0'									AS IsCNT,
		   '0'									AS IsDock
	  FROM #tmpShipResult AS A
		   INNER JOIN #tmpContract AS B
				   ON B.ContractSeq	= A.ContractSeq
	ORDER BY ContractNo, ContractName, PJTNo, PJTName, ChargeDate
	--컨테이녀 연동 추가 2017.11.08
	CREATE TABLE #tmpCNTItem (
		ItemSeq	INT
	)
	INSERT INTO #tmpCNTItem
	SELECT DISTINCT ValueSeq
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MajorSeq		= 1016233
	   AND Serl			= 1000003
	--해당 프로젝트에 컨테이너 연동품목 (사용자정의코드 운영정보하태-청구항목맵핑_mnpt) 에 매핑되어있는 청구항목이 존재한다면 컨테이너 여부에 체크
	UPDATE #tmpResult2
	   SET IsCNT	= '1'
	  FROM #tmpResult2 AS A
	 WHERE EXISTS (
					SELECT 1
					  FROM _TPJTProject AS Z WITH(NOLOCK)
						   INNER JOIN _TPJTProjectDelivery AS Y WITH(NOLOCK)
								   ON Y.CompanySeq	= Z.CompanySeq
								  AND Y.PJTSeq		= Z.PJTSeq
						   INNER JOIN #tmpCNTItem AS X WITH(NOLOCK)
								   ON X.ItemSeq		= Y.ItemSeq
					 WHERE Z.CompanySeq	= @CompanySeq
					   AND Z.PJTSeq		= A.PJTSeq
				)

	--실적이 존재하는 모선항차와, 실적이 존재하지 않는 컨테이너항차가 따로 존재한다면
	--본선완료 데이터를 읽어서 청구데이터를 생성해준다..
	INSERT INTO #tmpResult2 (
		BizUnitName,			ContractSeq,				ContractName,			ContractNo,					PJTName,
		PJTNo,					CustName,					PJTTypeName,			UMcontractTypeName,			UMContractKindName,
		UMChargeTypeName,		ContractFrDate,				ContractToDate,			IsFakeContract,				IsContractSideFee,
		IsContractLoadFee,		IsContractStorageFee,		PJTSeq,					WorkReportSeq,				ShipSeq,
		ShipSerl,				IsShip,						IFShipcode,				ShipYear,					ShipSerl2,
		FullShipName,			
		EnShipName,				ShipCnt,					InDateTime,				OutDateTime,
		ApproachDateTime,		WorkDate,					WorkQty,				TodayMTWeight,				TodayCBMWeight,
		WorkCnt,				ChargeDate,					IsCNT,					IsDock
	)

	SELECT
		A.BizUnitName,			A.ContractSeq,				A.ContractName,			A.ContractNo,				A.PJTName,
		A.PJTNo,				A.CustName,					A.PJTTypeName,			A.UMcontractTypeName,		A.UMContractKindName,
		A.UMChargeTypeName,		A.ContractFrDate,			A.ContractToDate,		A.IsFakeContract,			A.IsContractSideFee,
		A.IsContractLoadFee,	A.IsContractStorageFee,		A.PJTSeq,				-1,							C.ShipSeq,
		C.ShipSerl,				A.IsShip,					D.IFShipCode,			LEFT(D.ShipSerlNo, 4),		RIGHT(D.ShipSerlNo, 3),
		D.IFShipCode + '-' + LEFT(D.ShipSerlNo, 4) + '-' + RIGHT(D.ShipSerlNo, 3),
		E.EnShipName,			1,							LEFT(D.InDateTime, 8),	LEFT(D.OutDateTime, 8),
		D.DiffApproachTime,		0,							C.Qty,					0,							0,
		0,						LEFT(D.OutDateTime, 6),		'1',					'0'
	  FROM #tmpResult2 AS A
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS B
				   ON B.CompanySeq	= @CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN (
						SELECT Z.ShipSeq, Z.ShipSerl, SUM(Z.Qty) AS Qty
						  FROM mnpt_TPJTEECNTRReport AS Z
							   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS Y
									   ON Y.CompanySeq	= Z.CompanySeq
									  AND Y.ShipSeq		= Z.ShipSeq
									  AND Y.ShipSerl	= Z.ShipSerl
							   INNER JOIN (
												SELECT ShipSeq, ShipSerl, LEFT(OutDAteTime, 6) AS OutDate
												  FROM mnpt_TPJTShipDetail
												 GROUP BY ShipSeq, ShipSerl, LEFT(OutDAteTime, 6)
											) AS T 
									   ON T.ShipSeq		= Y.ShipSeq
									  AND T.ShipSerl	= Y.ShipSerl
							   INNER JOIN #tmpResult2 AS X
									   ON X.PJTSeq		= Y.PJTSeq
									  AND X.ChargeDate	= T.OutDate
							   INNER JOIN _TPJTProjectDelivery AS U 
									   ON U.CompanySeq	= @CompanySeq
									  AND U.ItemSeq		= Z.ItemSeq
						 WHERE Z.CompanySeq	= @CompanySeq
						 GROUP BY Z.ShipSeq,  Z.ShipSerl
					) AS C
				   ON C.ShipSeq		= B.ShipSeq
				  AND C.ShipSerl	= B.ShipSerl
		   INNER JOIN mnpt_TPJTShipDetail AS D
				   ON D.CompanySeq	= @CompanySeq
				  AND D.ShipSeq		= C.ShipSeq
				  AND D.ShipSerl	= C.ShipSerl
				  AND LEFT(D.OutDateTime, 6)	= A.ChargeDate
		   INNER JOIN mnpt_TPJTShipMaster AS E
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
	  WHERE A.IsCNT			= '1'
	    AND A.ShipSeq		<> 0
		AND A.WorkReportSeq = ''
	    AND (A.ShipSeq	<> C.ShipSeq or A.ShipSerl <> c.ShipSerl)
		AND LEFT(D.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	--작업실적이 없고 컨테이너청구항목이 존재하는 프로젝트는.
	--컨테이너실적에 있는 항차데이터 및 수량을 보여준다.
	UPDATE #tmpResult2
	   SET ShipSeq			= C.ShipSeq,
	       ShipSerl			= C.ShipSerl,
		   IFShipCode		= D.IFShipCode,
		   ShipYear			= LEFT(D.ShipSerlNo, 4),
		   ShipSerl2		= RIGHT(D.ShipSerlNo, 3),
		   FullShipName		= D.IFShipCode + '-' + LEFT(D.ShipSerlNo, 4) + '-' + RIGHT(D.ShipSerlNo, 3),
		   EnShipName		= E.EnShipName,
		   ShipCnt			= 1,
		   InDateTime		= LEFT(D.InDateTime, 8),
		   OutDateTime		= LEFT(D.OutDateTime, 8),
		   ApproachDateTime	= D.DiffApproachTime,
		   WorkQty			= C.Qty,
		   WorkReportSeq	= -1
	  FROM #tmpResult2 AS A
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS B
				   ON B.CompanySeq	= @CompanySeq
				  AND B.PJTSeq		= A.PJTSeq
		   INNER JOIN (
						SELECT Z.ShipSeq, Z.ShipSerl, SUM(Z.Qty) AS Qty
						  FROM mnpt_TPJTEECNTRReport AS Z
							   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS Y
									   ON Y.CompanySeq	= Z.CompanySeq
									  AND Y.ShipSeq		= Z.ShipSeq
									  AND Y.ShipSerl	= Z.ShipSerl
							   INNER JOIN (
												SELECT ShipSeq, ShipSerl, LEFT(OutDAteTime, 6) AS OutDate
												  FROM mnpt_TPJTShipDetail
												 GROUP BY ShipSeq, ShipSerl, LEFT(OutDAteTime, 6)
											) AS T 
									   ON T.ShipSeq		= Y.ShipSeq
									  AND T.ShipSerl	= Y.ShipSerl
							   INNER JOIN #tmpResult2 AS X
									   ON X.PJTSeq		= Y.PJTSeq
									  AND X.ChargeDate	= T.OutDate
							   INNER JOIN _TPJTProjectDelivery AS U 
									   ON U.CompanySeq	= @CompanySeq
									  AND U.ItemSeq		= Z.ItemSeq
						 WHERE Z.CompanySeq	= @CompanySeq
						 GROUP BY Z.ShipSeq,  Z.ShipSerl
					) AS C
				   ON C.ShipSeq		= B.ShipSeq
				  AND C.ShipSerl	= B.ShipSerl
		   INNER JOIN mnpt_TPJTShipDetail AS D
				   ON D.CompanySeq				= @CompanySeq
				  AND D.ShipSeq					= C.ShipSeq
				  AND D.ShipSerl				= C.ShipSerl
				  AND LEFT(D.OutDateTime, 6)	= A.ChargeDate
		   INNER JOIN mnpt_TPJTShipMaster AS E
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
	  WHERE A.IsCNT		= '1'
	    AND A.ShipSeq	= 0
		AND LEFT(D.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate
	--접안료 프로젝트는 별도로 보여주기.
	INSERT INTO #tmpResult2 (
		BizUnitName,			ContractSeq,				ContractName,			ContractNo,					PJTName,
		PJTNo,					CustName,					PJTTypeName,			UMcontractTypeName,			UMContractKindName,
		UMChargeTypeName,		ContractFrDate,				ContractToDate,			IsFakeContract,				IsContractSideFee,
		IsContractLoadFee,		IsContractStorageFee,		PJTSeq,					WorkReportSeq,				ShipSeq,
		ShipSerl,				IsShip,						IFShipcode,				ShipYear,					ShipSerl2,
		FullShipName,			
		EnShipName,				ShipCnt,					InDateTime,				OutDateTime,
		ApproachDateTime,		WorkDate,					WorkQty,				TodayMTWeight,				TodayCBMWeight,
		WorkCnt,				ChargeDate,					IsCNT,					IsDock
	)
	SELECT 
		DISTINCT 
		G.BizUnitName,			A.ContractSeq,				A.ContractName,			A.ContractNo,				I.PJTNAme,
		I.PJTNo,				H.CustName,					J.PJTTypeName,			K.MinorName,				L.MinorName,
		M.MinorName,			A.ContractFrDate,			A.ContractToDate,		A.IsFakeContract,			'1',
		'0',					'0',						C.PJTSeq,				'',							D.shipSeq,
		D.ShipSerl,				'0',						E.IFShipCode,			LEFT(E.ShipSerlNo, 4),		RIGHT(E.ShipSerlNo, 3),
		E.IFShipCode + '-' + LEFT(E.ShipSerlNo, 4) + '-' + RIGHT(E.ShipSerlNo, 3),	
		F.EnShipName,			1,							LEFT(E.InDateTime, 8),	LEFT(E.OutDateTime, 8),
		E.DiffApproachTime,		0,							0,						0,							0,							
		0,						LEFT(E.OutDateTime, 6),		'0',					'1'	
	  FROM mnpt_TPJTContract AS A WITH(NOLOCK)
		   LEFT  JOIN _TDAUMinorValue AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.MinorSeq	= A.UMContractKind
				  AND B.Serl		= 1000002
				  AND B.MajorSeq	= 1015778
		   LEFT  JOIN mnpt_TPJTProject AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  AND C.ContractSeq	= A.ContractSeq
		   INNER JOIN mnpt_TPJTShipWorkPlanFinish AS D WITH(NOLOCK)
				   ON D.CompanySeq	= C.CompanySeq
				  AND D.DockPJTSeq	= C.PJTSeq
		   INNER JOIN mnpt_TPJTShipDetail AS E WITH(NOLOCK)
				   ON E.CompanySeq	= D.CompanySeq
				  AND E.ShipSeq		= D.ShipSeq
				  AND E.ShipSerl	= D.ShipSerl
		   INNER JOIN mnpt_TPJTShipMaster AS F WITH(NOLOCK)
				   ON F.CompanySeq	= E.CompanySeq
				  AND F.ShipSeq		= E.ShipSeq
		   LEFT  JOIN _TDABizUnit AS G WITH(NOLOCK)
				   ON G.CompanySeq	= A.CompanySeq
				  AND G.BizUnit		= A.BizUnit
		   LEFT  JOIN _TDACust AS H WITH(NOLOCK)
				   ON H.CompanySeq	= A.CompanySeq
				  AND H.CustSeq		= A.CustSeq
		   LEFT  JOIN _TPJTProject AS I WITH(NOLOCK)
				   ON I.CompanySeq	= C.CompanySeq
				  AND I.PJTSeq		= C.PJTSeq
		   LEFT  JOIN _TPJTType AS J WITH(NOLOCK)
				   ON J.CompanySeq	= I.CompanySeq
				  AND J.PJTTypeSeq	= I.PJTTypeSeq
		   LEFT  JOIN _TDAUMinor AS K WITH(NOLOCK)
				   ON K.CompanySeq	= A.CompanySeq
				  AND K.MinorSeq	= A.UMContractType
		   LEFT  JOIN _TDAUMinor AS L WITH(NOLOCK)
				   ON L.CompanySeq	= A.CompanySeq
				  AND L.MinorSeq	= A.UMContractKind
		   LEFT  JOIN _TDAUMinor AS M WITH(NOLOCK)
				   ON M.CompanySeq	= A.CompanySEq
				  AND M.MinorSeq	= A.UMChargeType
	 WHERE A.CompanySeq	= @CompanySeq
	   AND B.ValueText	= '1'
	   AND LEFT(E.OutDateTime, 6) BETWEEN @ChargeFrDate AND @ChargeToDate


	--작업기준보기 체크시 작업이 없는 계약삭제
	IF @UMExampleKind = 1015856003
	BEGIN
	  DELETE #tmpResult2
		FROM #tmpResult2
	   WHERE WorkReportSeq = ''
	 END

	SELECT A.*,
		   ISNULL(B.InvoiceSeq, 0)  AS InvoiceSeq
	  INTO #tmpResult3
	  FROM #tmpResult2 AS A 
		   LEFT  JOIN (
						SELECT InvoiceSeq, 
							   ContractSeq, 
							   OldShipSeq		AS ShipSeq,		--OldShipSeq로 변경. 청구입력에서 항차가 신규입력 및 수정가능하기때문 2017.11.08 
							   OldShipSerl		AS ShipSerl,	--OldShipSerl로 변경. 청구입력에서 항차가 신규입력 및 수정가능하기때문 2017.11.08 
							   PJTSeq,
							   CASE WHEN OldShipSeq = 0 THEN ChargeDate ELSE '' END AS ChargeDate
						  FROM mnpt_TPJTLinkInvoiceItem
						 WHERE CompanySeq	= @CompanySeq
						 GROUP BY InvoiceSeq, ContractSeq, OldShipSeq, OldShipSerl, PJTSeq,
								  CASE WHEN OldShipSeq = 0 THEN ChargeDate ELSE '' END 
					) AS B 
				   ON B.ContractSeq	= A.ContractSeq
				  AND B.ShipSeq		= A.ShipSeq
				  AND B.ShipSerl	= A.ShipSerl
				  AND B.PJTSeq		= A.PJTSeq
				  ANd B.ChargeDate	= CASE WHEN A.ShipSeq = 0 THEN A.ChargeDate ELSE B.ChargeDate END
     WHERE (@IFShipCode			= '' OR A.IFShipCode	LIKE @IFShipCode	+ '%')
	   AND (@ShipYear			= '' OR A.ShipYear		LIKE @ShipYear		+ '%')
	   AND (@ShipSerl			= '' OR A.ShipSerl2		LIKE @ShipSerl		+ '%')
	   AND (@ShipSeq			= 0  OR A.ShipSeq		= @ShipSeq)
	   AND (@CustName			= '' OR A.CustName		LIKE @CustName		+ '%')
	   AND (@PJTName			= '' OR A.PJTName		LIKE @PJTName		+ '%')
	   AND (@PJTTypeName		= '' OR A.PJTTypeName	LIKE @PJTTypeName	+ '%')
	   AND (@PJTNo				= '' OR A.PJTNo			LIKE @PJTNo			+ '%')
	   AND (@ContractName		= '' OR A.ContractName	LIKE @ContractName	+ '%')
	   AND (@ContractNo			= '' OR A.ContractNo	LIKE @ContractNo	+ '%')

	--청구 or 수기의 접안료, 하역료, 보관료 여부 Insert
	CREATE TABLE #tmpItemLClass2(
		InvoiceSeq				INT,
		InvoiceNo				NVARCHAR(100),	--청구번호
		IsContractSideFee		NCHAR(1),	--접안료(청구)
		IsContractLoadFee		NCHAR(1),	--하역료(청구)
		IsContractStorageFee	NCHAR(1),	--보관료(청구)
		IsDirectSideFee			NCHAR(1),	--접안료(수기)
		IsDirectLoadFee			NCHAR(1),	--하역료(수기)
		IsDirectStorageFee		NCHAR(1),	--보관료(수기)
		IsChargeComplete		NCHAR(1),	--청구완료
		IsDirect				NCHAR(1)	--수기입력
		
	)
	/*
	청구생성으로된 품목대분류와, 청구입력화면에서 입력한 품목대분류의 비교는 링크테이블(mnpt_TPJTLinkInvoiceItem)의 PgmSeq로 구분한다
	청구생성으로 생성된 청구는 PgmSeq = 13820012이고 , 청구입력에서 수기로입력한 청구는 PgmSeq = 13820018이다
	*/
	INSERT INTO #tmpItemLClass2 (
		InvoiceSeq,
		InvoiceNo,
		IsContractSideFee,
		IsContractLoadFee,
		IsContractStorageFee,
		IsDirectSideFee,
		IsDirectLoadFee,
		IsDirectStorageFee,
		IsChargeComplete,
		IsDirect
	)
	SELECT
		A.InvoiceSeq,
		A.InvoiceNo,
		CASE WHEN ISNULL(B.IsContractSideFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(C.IsContractLoadFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(D.IsContractStorageFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(E.IsContractSideFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(F.IsContractLoadFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(G.IsContractStorageFee, 0) = 0		THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(Z.IsComplete, 0) <> ISNULL(Z.IsCnt, 0)	THEN '0' ELSE '1' END,
		CASE WHEN ISNULL(Y.IsComplete, 0) = 0				THEN '0' ELSE '1' END
	  FROM _TSLInvoice AS A WITH(NOLOCK)
		   LEFT  JOIN mnpt_TSLInvoice AS Y WITH(NOLOCK)
				   ON Y.CompanySeq	= A.CompanySeq
				  AND Y.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT InvoiceSeq, 
							   SUM(CONVERT(INT, IsComplete))	AS IsComplete,
							   COUNT(1)							AS IsCnt
						  FROM mnpt_TSLInvoiceItem
						 WHERE CompanySeq	= @CompanySeq
						 GROUP BY InvoiceSeq
						) AS Z 
				   ON Z.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractSideFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS B 
				   ON B.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractLoadFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS C 
				   ON C.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractStorageFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND A.PgmSeq			= 13820012
						  GROUP BY A.InvoiceSeq
					) AS D 
				   ON D.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractSideFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvSideFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS E 
				   ON E.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractLoadFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvLoadFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS F 
				   ON F.InvoiceSeq	= A.InvoiceSeq
		   LEFT  JOIN (
						SELECT A.InvoiceSeq, COUNT(1) AS IsContractStorageFee
						  FROM mnpt_TPJTLinkInvoiceItem AS A WITH(NOLOCK)
								LEFT  JOIN _TDAItemClass AS B WITH(NOLOCK)
										ON B.CompanySeq	= A.CompanySeq
									   AND B.ItemSeq	= A.ItemSeq
									   AND B.UMajorItemClass	IN (2001, 2004)
								LEFT  JOIN _VDAitemClass AS C
										ON C.CompanySeq		= B.CompanySeq
									   AND C.ItemClassSSeq	= B.UMItemClass
					      WHERE A.CompanySeq		= @CompanySeq
						    AND C.ItemClassMSeq		= @EnvStorageFee
							AND A.PgmSeq			= 13820018
						  GROUP BY A.InvoiceSeq
					) AS G 
				   ON G.InvoiceSeq	= A.InvoiceSeq
		
	 WHERE A.CompanySeq	= @CompanySeq
	   AND EXISTS (
					SELECT 1
					  FROM #tmpResult3
					 WHERE InvoiceSeq	= A.InvoiceSeq
				)

	   SELECT A.*,
			  B.InvoiceNo,
			  CASE WHEN A.InvoiceSeq <> 0				THEN '1' ELSE '0' END IsChargeCreate,
			  CASE WHEN B.IsContractSideFee <> 0		THEN '1' ELSE '0' END IsChargeSideFee,
			  CASE WHEN B.IsContractLoadFee <> 0		THEN '1' ELSE '0' END IsChargeLoadFee,
			  CASE WHEN B.IsContractStorageFee <> 0		THEN '1' ELSE '0' END IsChargeStorageFee,
			  CASE WHEN B.IsDirectSideFee <> 0			THEN '1' ELSE '0' END IsDirectSideFee,
			  CASE WHEN B.IsDirectLoadFee <> 0			THEN '1' ELSE '0' END IsDirectLoadFee,
			  CASE WHEN B.IsDirectStorageFee <> 0		THEN '1' ELSE '0' END IsDirectStorageFee,
			  CASE WHEN B.IsChargeComplete <> 0			THEN '1' ELSE '0' END IsChargeComplete,
			  ISNULL(B.IsChargeComplete, '0')	AS IsChargeComplete,
			  ISNULL(B.IsDirect, '0')			AS IsDirect,
			  CASE WHEN A.IsShip = '0' AND A.IsDock = '0' THEN '0'
				   ELSE ( CASE WHEN ISNULL(C.IsCfm, '0') = '0' THEN '0' ELSE '1' END )
				   END AS IsComplete
	     FROM #tmpResult3 AS A
			  LEFT JOIN (
							SELECT InvoiceSeq, 
								   InvoiceNo,
								   IsContractSideFee, 
								   IsContractLoadFee, 
								   IsContractStorageFee,
								   IsDirectSideFee,
								   IsDirectLoadFee,
								   IsDirectStorageFee,
								   IsChargeComplete,
								   IsDirect
							  FROM #tmpItemLClass2
							 GROUP BY InvoiceSeq, 
									  InvoiceNo,
									  IsContractSideFee, 
									  IsContractLoadFee, 
									  IsContractStorageFee,
									  IsDirectSideFee,
									  IsDirectLoadFee,
									  IsDirectStorageFee,
									  IsChargeComplete,
									  IsDirect
						) AS B
					  ON B.Invoiceseq	= A.InvoiceSeq
			  LEFT  JOIN mnpt_TPJTShipWorkPlanFinish  AS C WITH(NOLOCK)
					  ON C.CompanySeq	= @CompanySeq
					 AND C.ShipSeq		= A.ShipSeq
					 AND C.ShipSerl		= A.ShipSerl
					 AND A.PJTSeq		= CASE WHEN A.IsDock = '1' THEN C.DockPJTSeq ELSE C.PJTSeq END
		WHERE (@UMChargeCreate = 1015860001 OR (@UMChargeCreate = 1015860002 AND A.Invoiceseq = 0)			--청구생성
											OR (@UMChargeCreate = 1015860003 AND A.InvoiceSeq <> 0)
				)
		  AND  (@UMChargeComplete = 1015861001 OR (@UMChargeComplete = 1015861002 AND ISNULL(B.IsChargeComplete, '0') = '0')	--청구완료
											OR (@UMChargeComplete = 1015861003 AND ISNULL(B.IsChargeComplete, '0') <> '0')
				)
		ORDER BY A.BizUnitName, A.ContractNo, A.ChargeDate, A.PJTNo
