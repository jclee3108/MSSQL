IF OBJECT_ID('hencom_SPSLRealTimeDHListSS2Query') IS NOT NULL 
    DROP PROC hencom_SPSLRealTimeDHListSS2Query
GO 

-- v2018.05.25 

-- 날짜 기간으로 조회 될 수 있도록 반영 by이재천 
/************************************************************
 설  명 - 데이터-대한 실시간출하현황 : SS2조회
 작성일 - 20161028
 작성자 - 이종민
************************************************************/
CREATE PROC hencom_SPSLRealTimeDHListSS2Query                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle  INT,
		    @DeptSeq    INT ,
            @WorkDateFr NCHAR(8), 
            @WorkDateTo NCHAR(8) 
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq    = ISNULL(DeptSeq,0)    ,
            @WorkDateFr = ISNULL(WorkDateFr,''), 
            @WorkDateTo = ISNULL(WorkDateTo,'') 
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
	  WITH (DeptSeq     INT ,
            WorkDateFr  NCHAR(8), 
            WorkDateTo  NCHAR(8) )
	
	-- 송장 자료 임시테이블 생성
	-- 송장 자료 임시테이블 생성
	CREATE TABLE #TMPMesViewData
	(
		HC01PGBN	NVARCHAR(3),	-- 사업소코드(자체)
		CODEERP		DECIMAL(10),	-- 사업소코드(ERP)
		TRADE		NVARCHAR(100),	-- 사업소명
		HC01DATE	NCHAR(10),		-- 
		HC01SEQ		NVARCHAR(3),	-- 예정번호
		HC01TRNM	NVARCHAR(200),	-- 거래처명
		HC01SPNM	NVARCHAR(200),	-- 현장명
		HC01YQTY	DECIMAL(19,5),  -- 예정별 예정수량
		HC02SPECNAME   NVARCHAR(200), -- 규격명
		HC02SEQ		NVARCHAR(10),	-- 송장순번
		HC02TIME	NVARCHAR(10),	-- 송장시간
		HC02QTY		DECIMAL(19,5),  -- 차량적제량
		HC02ADDQTY	DECIMAL(19,5),  -- 송장별 누계량
		HC02CNT		DECIMAL(19,5),  -- 예정별차량카운트
		HC02ADDCNT	DECIMAL(19,5),  -- 예정별차량누계카운트
		HC02CRCD	NVARCHAR(10),	-- 차량코드
		HC02CRNO	NVARCHAR(10)	-- 차량번호
	)
	INSERT INTO #TMPMesViewData
	EXEC daehan_SMESDataOpenQuery @CompanySeq,@WorkDateFr, @WorkDateTo

    -- 웅촌 중복데이터로 인해 통합기준으로만...
    DELETE FROM #TMPMesViewData WHERE HC01PGBN = 'BID'

	INSERT INTO #TMPMesViewData
	EXEC daehan_SMESDataOpenQuery_Oracle @CompanySeq,@WorkDateFr, @WorkDateTo

    
	
	SELECT	TRADE AS DeptName
	,		CODEERP AS DeptSeq
	,		REPLACE(HC01DATE,'-','') AS WorkDate 
	,		HC01SEQ AS EstSeq
	,		HC01TRNM AS CustName
	,		HC01SPNM AS PjtName
	,       HC02SPECNAME AS SpecName
	,		SUM(isNull(HC01YQTY, 0)) AS PlanQty
	,		SUM(isNull(HC02QTY, 0)) AS OutQty
	,		SUM(isNull(HC01YQTY, 0)) - SUM(isNull(HC02QTY, 0)) AS RemainQty
	,		(CASE WHEN SUM(isNull(HC01YQTY, 0)) = 0 THEN 0 ELSE ROUND(SUM(isNull(HC02QTY, 0)) / SUM(isNull(HC01YQTY, 0)) * 100, 0) END) AS ProgRate
	FROM	(
		SELECT	TRADE
		,		CODEERP
		,		HC01DATE
		,		HC01SEQ
		,		HC01TRNM
		,		HC01SPNM
		,		MAX(HC01YQTY) AS HC01YQTY
		,       HC02SPECNAME
		,		SUM(HC02QTY) AS HC02QTY
		FROM	#TMPMesViewData
		GROUP BY TRADE
		,		CODEERP
		,		HC01DATE
		,		HC01SEQ
		,		HC01TRNM
		,		HC01SPNM
		,       HC02SPECNAME
		--,		HC01YQTY
	) AS A
	WHERE	CODEERP = @DeptSeq
	GROUP BY TRADE
	,		CODEERP
	,		HC01DATE
	,		HC01SEQ
	,		HC01TRNM
	,		HC01SPNM
	,       HC02SPECNAME
	--,		HC01YQTY
RETURN
go
