IF OBJECT_ID('test_KPXGC_SPDSFCWorkReportERPCrt_POP') IS NOT NULL 
    DROP PROC test_KPXGC_SPDSFCWorkReportERPCrt_POP
GO 


/*************************************************************************************************************    
 설  명 - POP생산실적 생성
 작성일 - 20151120
 작성자 - 천혜연   
*************************************************************************************************************/    
CREATE PROC test_KPXGC_SPDSFCWorkReportERPCrt_POP
	@CompanySeq     INT = 1 ,
	@WorkDate		NCHAR(8) = '',
	@popSeq         INT = 0
AS      
     

    DECLARE @CrtDate            DATETIME     ,      
            @FileName           NVARCHAR(100),      
            @CrtDateFile        NVARCHAR(14) ,      
            @MaxSerl            INT          ,      
            @Count              INT          ,        
            @Seq                INT          ,        
            @PreCrtDateCHAR     NVARCHAR(30) ,        
            @PreCrtDateCHAR2    NVARCHAR(30) ,        
            @PreCrtDateCHAR3    NVARCHAR(30) ,        
            @PreCrtDate         DATETIME     ,        
            @PreCrtDate2        DATETIME     ,        
            @PreCrtDate3        DATETIME     ,        
            @docHandle          INT          ,        
            @XmlData            NVARCHAR(MAX),        
            @GetDate            NVARCHAR(14) ,    
            @CloseDate          NVARCHAR(6)  ,    
            @Status             INT          ,    
            @Result             NVARCHAR(250),    
            @Level1DataBlock    NVARCHAR(100),    
            @Level2DataBlock    NVARCHAR(100),    
            @Sql1               NVARCHAR(MAX),    
            @Sql2               NVARCHAR(MAX),
            @EmpSeq             INT          ,
            @DeptSeq            INT           ,
			@StdDate			NCHAR(8),
			@WhSeq						INT,
			@UserSeq			INT,
			@ProcTypeSeq			INT,
			@StdYM				NCHAR(6),
			@DateFr NVARCHAR(8),
			@DateTo NVARCHAR(8)

    SELECT @StdDate =  CONVERT (NCHAR(8),GETDATE(),112)    
	SELECT @StdYM = LEFT(@StdDate, 6) 


	SELECT @DateFr = CONVERT(NCHAR(6), GETDATE(), 112) + '01', @DateTo = CONVERT(NCHAR(8), GETDATE(), 112)

	--SELECT @DateFr = LEFT(@DateFr, 6), @DateTo = LEFT(@DateTo, 6)


    SELECT @UserSeq = 1
	SELECT @ProcTypeSeq = 5
 
	    -- 물류시작월 가져오기
    DECLARE @LGstartEnv     NVARCHAR(10)
    EXEC dbo._SCOMEnv @CompanySeq,1006,1,0,@LGstartEnv OUTPUT  


	--SELECT @StdYM = MIN(ClosingYM) FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq = 69 AND IsClose <> '1' AND ClosingYM > @LGstartEnv
    SELECT @StdYM = MAX(ClosingYM) FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq = 69 AND IsClose = '1' AND UnitSeq = 1 AND ClosingYM > @LGstartEnv
	    
    SET @GetDate = REPLACE(REPLACE(REPLACE(CONVERT(NCHAR(20), GETDATE(), 120), '-', ''), ' ', ''), ':', '')        
    
    --업무별 MES대표담당자 지정 
    ----SELECT @EmpSeq = ValueSeq FROM _TDAUMinorValue AS A WITH(NOLOCK) WHERE CompanySeq = @CompanySeq  AND MinorSeq = 1010264002 AND Serl = 1000001
    SELECT @DeptSeq = 8 --생산팀
     

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


    CREATE TABLE #TLGInOutStock
    (  
        InOutType		INT NULL,			  
        InOutSeq		INT NULL, 
        InOutSerl		INT NULL,	   
        DataKind		INT DEFAULT 0,		 
        InOutDataSerl	INT DEFAULT 0,  
        InOutSubSerl	INT NULL,			  
        InOut			INT NULL, 
        InOutYM			NCHAR(6) NULL, 
        InOutDate		NCHAR(8) NULL,		 
        WHSeq			INT NULL,  
        FunctionWHSeq	INT NULL,			  
        ItemSeq			INT NULL, 
        UnitSeq			INT NULL,      
        Qty				DECIMAL(19,5) NULL, 
        StdQty			DECIMAL(19,5) NULL,  
        Amt				DECIMAL(19,5) NULL, 
        InOutKind		INT NULL, 
        InOutDetailKind INT NULL  
    )  


	CREATE TABLE #KPX_TPDSFCWorkReport_POP
	(	
		DataSeq				INT IDENTITY(1,1),
		Seq					INT,
		WorkingTag			NCHAR(1),
		CRTDATETIME			DATETIME,
		PROCYN				NCHAR(1),
		PROCDATETIME		DATETIME,
		ErrorMessage			NVARCHAR(200),
		COMPANYSEQ			INT,
		FactUnit			INT,
		IFWorkReportSeq	    NVARCHAR(30),
		WorkStartDate 		NCHAR(8),
		WorkEndDate			NCHAR(8),
		EmpSeq				INT,
		DeptSeq				INT,
		WorkReportSeq		INT,
		WorkOrderNo			NVARCHAR(30),
		WorkOrderSeq		INT,
		WorkOrderSerl		INT,
		WorkCenterSeq		INT,
		GoodItemSeq			INT,
		ProcRev				NCHAR(2),
		AssyItemSeq			INT,
		ProcSeq				INT,
		UnitSeq				INT,
		RealLotNo				NVARCHAR(30),
		Qty					DECIMAL(19,5),
		OKQty				DECIMAL(19,5),
		BadQty				DECIMAL(19,5),
		WhSeq				INT,
		WorkTimeGroup		INT,
		WorkStartTime			NCHAR(4),
		WorkEndTime			NCHAR(5),
		WorkMin			DECIMAL(19,5),
		Remark				NVARCHAR(200)		
	)

    --실적 정보 중 작업지시가 없는 것은 무시한다.      
    UPDATE A      
       SET ProcYN = '7',      
           ErrorMessage = '작업지시 정보가 없습니다.'      
      FROM KPX_TPDSFCWorkReport_POP AS A      
           LEFT OUTER JOIN _TPDSFCWorkOrder AS B ON B.CompanySeq = A.CompanySeq and B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkORderSerl      
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ProcYN = '0'      
       AND A.IsPacking = '0'      
       AND ISNULL(B.CompanySeq, 0) = 0
	   AND LEFT(A.WorkEndDate, 6)  > @StdYM 



    --실적 최초 데이터가 삭제인 정보는 무시한다.      
    UPDATE A       
       SET ProcYN = '8',      
           ErrorMessage = '실적 최초 데이터가 삭제인 정보는 무시한다.'      
      FROM KPX_TPDSFCWorkReport_POP AS A      
     WHERE Seq IN (      
                    SELECT A.Seq      
                      FROM KPX_TPDSFCWorkReport_POP AS A      
                     WHERE IsPacking = '0'      
                       AND WorkingTag = 'D'      
                       AND IFWorkReportSeq IN (SELECT IFWorkReportSeq      
                                                 FROM KPX_TPDSFCWorkReport_POP      
                                                WHERE CompanySeq = @CompanySeq  
                                                  and IsPacking = '0'      
                                                GROUP BY IFWorkReportSeq      
                                                HAVING COUNT(1) = 1)      
                    UNION ALL      
                    SELECT A.Seq      
                      FROM (SELECT IFWorkReportSeq, MIN(Seq) AS Seq      
                              FROM KPX_TPDSFCWorkReport_POP AS A      
                             WHERE A.CompanySeq = @CompanySeq  
                               AND A.IsPacking  = '0'      
                               AND A.WorkingTag = 'D'      
                             GROUP BY IFWorkReportSeq) AS A      
                            LEFT OUTER JOIN (SELECT IFWorkReportSeq, MIN(Seq) AS Seq      
                                               FROM KPX_TPDSFCWorkReport_POP AS A      
                                              WHERE A.CompanySeq = @CompanySeq  
                                                and IsPacking = '0'      
                                                AND WorkingTag = 'A'      
                                              GROUP BY IFWorkReportSeq) AS B ON B.IFWorkReportSeq = A.IFWorkReportSeq      
                     WHERE A.Seq < B.Seq      
                    )      
            And A.CompanySeq = @CompanySeq 


	--ERP 작업지시 삭제됐을때.. 에러 
	UPDATE A
	   SET ProcYn = '2', ErrorMessage = '업무 월마감이 완료되어 처리할 수 없습니다. '
	  FROM KPX_TPDSFCWorkReport_POP AS A
	WHERE A.CompanySeq = @CompanySeq 
      AND A.ProcYn  NOT IN  ('1' , '2')
	  AND (@WorkDate = '' OR A.WorkStartDate = @WorkDate)
	  AND A.WorkStartDate > @LGstartEnv+'00' --물류시작월 이후만 처리 
	  AND A.IsPacking = '0' 
	  AND LEFT(A.WorkEndDate, 6)  > @StdYM 
      AND EXISTS (SELECT ClosingYM FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq  = 69 AND ClosingYM = LEFT(A.WorkEndDate, 6) AND IsClose = '1' AND UnitSeq = 1)


	INSERT INTO #KPX_TPDSFCWorkReport_POP
	SELECT  A.Seq,			A.WorkingTag,		A.RegDateTime,			A.ProcYN,	A.ProcDateTime,	A.ErrorMessage,
			A.CompanySeq,	B.FactUnit,		    A.IFWorkReportSeq,		A.WorkStartDate,	A.WorkEndDate,	F.EmpSeq, (CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN F.DeptSeq ELSE A.DeptSeq END)     AS DeptSeq, 
			A.WorkReportSeq, W.WorkOrderNo, W.WorkOrderSeq,		W.WorkOrderSerl, W.WorkCenterSeq,
			A.GoodItemSeq,	'00', 	A.AssyItemSeq,  A.ProcSeq,		A.ProdUnitSeq,	A.RealLotNo, 
			ISNULL(A.ProdQty, 0), ISNULL(A.OKQty, 0), ISNULL(A.BadQty, 0), 
			B.ProdInWhSeq,	A.WorkTimeGroup, A.WorkStartTime, A.WorkEndTime, (A.WorkMin/60.0), '[POP 생산실적]'
			
	  FROM KPX_TPDSFCWorkReport_POP AS A
	       JOIN _TPDBaseWorkCenter      AS B ON A.CompanySeq = B.CompanySeq          
                                            AND A.WorkCenterSeq = B.WorkCenterSeq        
	       ----JOIN _TPDSFCWorkOrder AS B ON A.CompanySeq = B.CompanySeq
								----				AND A.WorkOrderSeqMES = B.WorkCond2
		   ----JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
					----					  AND A.GoodItemNo = I.ItemNo
		   ----JOIN _TDAItem AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq
					----					  AND A.ItemNo = J.ItemNo 
		   LEFT OUTER JOIN _fnadmEmpOrd(@CompanySeq, '') AS F ON A.RegEmpSeq = F.EmpSeq
		   JOIN _TPDSFCWorkOrder AS W ON W.CompanySeq = @CompanySeq AND W.WorkOrderSeq = A.WorkOrderSeq AND W.WorkOrderSerl = A.WorkOrderSerl  
     WHERE A.COMPANYSEQ = @CompanySeq
       AND ISNULL(A.PROCYN, '0') <> '1' 
	   AND A.WorkStartDate > @LGstartEnv+'00' --물류시작월 이후만 처리 
	   AND A.IsPacking ='0' 
	   AND LEFT(A.WorkEndDate, 6)  > @StdYM 
	   AND (@WorkDate = '' OR A.WorkStartDate = @WorkDate)
	   AND (@popseq = 0 or A.Seq = @popSeq) 
	   AND NOT EXISTS (SELECT ClosingYM FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq  = 69 AND ClosingYM = LEFT(A.WorkEndDate, 6) AND IsClose = '1' AND UnitSeq = 1)

	   --select * from #KPX_TPDSFCWorkReport_POP where IFWOrkReportSeq = '2015120200008'

	
	UPDATE A      
       SET WorkReportSeq = ISNULL((SELECT MAX(P.WorkReportSeq)       
                                     FROM KPX_TPDSFCWorkReport_POP AS P      
                                          JOIN _TPDSFCWorkReport AS R ON R.CompanySeq = P.CompanySeq       
                                                                     AND R.WorkOrderSeq = P.WorkOrderSeq      
                                                                     AND R.WorkOrderSerl = P.WorkOrderSerl      
                                                                     AND R.WorkReportSeq = P.WorkReportSeq      
                                    WHERE P.CompanySeq = A.CompanySeq       
                                      AND P.WorkOrderseq = A.WorkOrderSeq       
                                      AND P.WorkOrderSerl = A.WorkOrderSerl       
                                      AND P.IFWorkReportSeq = A.IFWorkReportSeq),0)      
                                          
      FROM #KPX_TPDSFCWorkReport_POP AS A      
     WHERE A.WorkingTag IN ('U', 'D'  ) 

	 --UPDATE #KPX_TPDSFCWorkReport_POP SET WorkingTag = 'A' WHERE WorkReportSeq
	 
	  

	IF NOT EXISTS (SELECT 1 FROM #KPX_TPDSFCWorkReport_POP) -- 처리할 데이터가 없다면 종료한다.                    
    BEGIN     
	                              
        RETURN                    
    END


    ---- CREATE TABLE #TLGInOutStock(      
    ----    InOutType int,      
    ----    InOutSeq int,      
    ----    InOutSerl int,      
    ----    DataKind int default 0,      
    ----    InOutDataSerl int default 0,      
    ----    InOutSubSerl int,      
    ----    InOut int,      
    ----    InOutYM nchar(6),      
    ----    InOutDate nchar(8),      
    ----    WHSeq int,      
    ----    FunctionWHSeq int,      
    ----    ItemSeq int,      
    ----    UnitSeq int,      
    ----    Qty decimal(19,5),      
    ----    StdQty decimal(19,5),      
    ----    Amt decimal(19,5),      
    ----    InOutKind int,      
    ----    InOutDetailKind int      
    ----)      


	     
    CREATE TABLE #TLGInOutLotStock(                  
        InOutType int,                  
        InOutSeq int,                  
        InOutSerl int,                  
        DataKind int default 0,                  
        InOutDataSerl int default 0,                  
        InOutSubSerl int,                  
        InOutLotSerl int,                  
        InOut int,                  
        InOutYM nchar(6),                  
        InOutDate nchar(8),                  
        WHSeq int,                  
        FunctionWHSeq int,      
        LotNo   NVARCHAR(30),                
        ItemSeq int,                  
        UnitSeq int,                  
        Qty decimal(19,5),                  
        StdQty decimal(19,5),                  
        InOutKind int,                  
        InOutDetailKind int ,                  
        Amt decimal(19,5)                 
    )  
	    

   
    --자재투입
	CREATE TABLE #TempMatinput
	(
	
		WorkingTag NCHAR(1),
		DataSeq		INT IDENTITY(1,1),		
		Status		INT,
		Selected	INT,
		TABLE_NAME	NVARCHAR(100),
		Seq         INT, 
		IFWorkReportSeq NVARCHAR(50),
		WorkReportSeq		INT,
		ItemSerl	INT,
		Qty			DECIMAL(19,5),
		InputDate	NCHAR(8),
		MatItemSeq	INT,
		MatUnitSeq	INT,
		StdUnitQty	DECIMAL(19,5),
		RealLotNo	NVARCHAR(50),
		SerialNoFrom	NVARCHAR(50),
		ProcSeq		INT,
		AssyYn		NCHAR(1),
		IsConsign	NVARCHAR(10),
		GoodItemSeq	INT,
		InputType	INT,
		IsPaid		NCHAR(1),
		IsPjt		NCHAR(1),
		PjtSeq		INT,
		WBSSeq		INT,
		LastUserSeq	INT,
		LastDateTime	DATETIME,
		Remark		NVARCHAR(100),
		ProdWRSeq	INT,
		SerialNo	NVARCHAR(10),
		TableType	NCHAR(1),
		WorkOrderSeq	INT,
		WorkOrderSerl	INT,
		WHSeq			INT
	)    
	  
		-- 재고반영 --      
		 CREATE TABLE #TLGInOutMonth       
		(        
			InOut           INT           ,        
			InOutYM         NCHAR(6)      ,        
			WHSeq           INT           ,        
			FunctionWHSeq   INT           ,        
			ItemSeq         INT           ,        
			UnitSeq         INT           ,        
			Qty             DECIMAL(19, 5),        
			StdQty          DECIMAL(19, 5),        
			ADD_DEL         INT        
		)        
        
		CREATE TABLE #TLGInOutMonthLot       
		(        
			InOut           INT           ,        
			InOutYM         NCHAR(6)      ,        
			WHSeq           INT           ,        
			FunctionWHSeq   INT           ,        
			LotNo           NVARCHAR(30)  ,        
			ItemSeq         INT           ,        
			UnitSeq         INT           ,        
			Qty             DECIMAL(19, 5),        
			StdQty          DECIMAL(19, 5),        
			ADD_DEL         INT        
		)        
        
		CREATE TABLE #TLGInOutMinusCheck       
		(        
			WHSeq           INT,        
			FunctionWHSeq   INT,        
			ItemSeq         INT        
		)        
        
        ----CREATE TABLE #TLGInOutDailyBatch (    

        ----    WorkingTag      NCHAR(1),    
        ----    InOutType       INT,    
        ----    InOutSeq        INT,    
        ----    MessageType     INT,    
        ----    Status          INT,    
        ----    Result          NVARCHAR(250)   
        ----) 

	          
    SELECT  DISTINCT         
           WorkingTag                  AS WorkingTag    ,  -- A : 신규추가, D : 삭제, U : UPDATE      
           IDENTITY(INT, 1, 1)  AS DataSeq       ,        
           0                    AS Status        ,        
           0                    AS Selected      ,        
           'DataBlock1'         AS TABLE_NAME    ,       
           Seq     AS Seq  ,    
		   A.IFWorkReportSeq    AS IFWorkReportSeq,
           A.WorkReportSeq      AS WorkReportSeq ,        
           B.WorkOrderSeq       AS WorkOrderSeq  ,        
           B.WorkOrderSerl      AS WorkOrderSerl ,        
           A.WorkCenterSeq      AS WorkCenterSeq ,        
           B.GoodItemSeq        AS GoodItemSeq   ,      
                   
           B.ProcRev            AS ProcRev       ,        
           B.AssyItemSeq        AS AssyItemSeq   ,        
           C.ProcSeq            AS ProcSeq       ,        
           B.ProdUnitSeq        AS ProdUnitSeq   ,        
           A.Qty          AS ProdQty       ,        
           A.OKQty          AS OKQty         ,        
           A.BadQty        AS BadQty        ,        
           A.Qty           AS StdUnitProdQty,        
           A.OKQty         AS StdUnitOKQty  ,        
           A.BadQty       AS StdUnitBadQty ,        
           A.WorkStartTime        AS WorkStartTime ,        
           A.WorkEndTime        AS WorkEndTime   ,        
           A.WorkMin AS WorkHour      ,    --ISNULL(A.WorkHour,0) AS WorkHour,        
           A.WorkMin                    AS ProcHour      ,        
           6041007 AS WorkType, ---  CASE WHEN A.WorkType = '1' THEN 6041003 ELSE 6041001 END              AS WorkType      ,    -- WorkType 이 1 인 경우 재작업    
           0                    AS ChainGoodsSeq ,        
           A.RealLotNo              AS RealLotNo     ,        
           ''                   AS SerialNoFrom  ,        
           0                    AS CCtrSeq       ,   
           A.EmpSeq                   AS EmpSeq        ,  
           A.DeptSeq,        
           A.WorkstartDate   AS WorkCondition1,        
           A.WorkEndDate     AS WorkCondition2,        
           ''					AS WorkCondition3,        
           A.WorkMin			AS WorkCondition4,        
           0          AS WorkCondition5,        
           0			AS WorkCondition6,        
           B.Remark				AS Remark        ,        
           B.IsProcQC           AS IsProcQC      ,        
           B.IsLastProc         AS IsLastProc    ,        
           '0'                  AS IsPjt         ,      
           0                    AS PJTSeq        ,        
           B.WBSSeq             AS WBSSeq        ,        
           A.WorkTimeGroup        AS WorkTimeGroup ,        
           B.ItemBomRev         AS ItemBomRev    ,        
           ''                   AS SubEtcInSeq   ,     
           0                    AS PreProdWRSeq  ,        
           0                    AS PreAssySeq    ,        
           0                    AS PreAssyQty    ,        
           ''                   AS PreLotNo      ,        
           0                    AS PreUnitSeq    ,        
           A.WorkEndDate           AS WorkDate      ,        
           B.FactUnit           AS FactUnit      ,        
           B.WorkOrderNo        AS WorkOrderNo   ,      
           ''					AS SerialNo     ,
		   0					AS WorkerQty
	

      INTO #TempMES      
      FROM #KPX_TPDSFCWorkReport_POP AS A      
        JOIN _TPDSFCWorkOrder  AS B ON A.WorkOrderNo  = B.WorkOrderNo 
                                   AND A.WorkOrderSerl = B.WorkOrderSerl     
                                   AND A.CompanySeq     = B.CompanySeq      
        JOIN _TPDBaseProcess   AS C ON C.CompanySeq     = @CompanySeq      
                                   AND C.ProcSeq        = B.ProcSeq      
   
     WHERE (1 = 1)     
       AND A.WorkOrderSerl <> 0      
       AND A.CompanySeq = @CompanySeq 
	   
    ------GROUP BY B.WorkOrderSeq    ,B.WorkOrderSerl,	A.WorkCenterSeq,	B.GoodItemSeq  	     
    ------        ,B.AssyItemSeq  	,C.ProcSeq      ,B.ProdUnitSeq  ,A.LotNo     ,B.Remark 
    ------        ,B.IsProcQC     	,B.IsLastProc   ,B.WBSSeq      ,B.ItemBomRev  ,A.WorkDate     
    ------        ,B.FactUnit     ,B.WorkOrderNo      ,B.ProcRev     ,A.DeptSeq, A.EmpSeq, A.CrtSeq
    ORDER BY Seq




    ALTER TABLE #TempMES ADD Result NVARCHAR(250)
	
	  

--================================================================================================================================================================
	 
	--생산실적 처리할 데이터가 없으면 종료
	IF NOT EXISTS ( SELECT 1 FROM #TempMES )
	BEGIN 
		--ROLLBACK TRAN    
        RETURN    
	END


	
    -- 데이터 마감 Check --    
    SELECT A.WorkingTag               ,    
           A.DataSeq                  ,    
           A.Selected                 ,    
           A.Status                   ,    
           A.Result                   ,    
           'DataBlock2'  AS TABLE_NAME,    
           A.GoodItemSeq AS ItemSeq   ,    
           A.WorkDate    AS Date      ,    
           2894          AS ServiceSeq,    
           2             AS MethodSeq ,    
           A.DeptSeq     AS DeptSeq   ,    
           A.FactUnit    AS FactUnit  ,    
           CASE WHEN A.WorkingTag = 'A' THEN A.WorkDate ELSE B.WorkDate END  AS DateOld   ,    
           CASE WHEN A.WorkingTag = 'A' THEN A.DeptSeq  ELSE B.DeptSeq  END  AS DeptSeqOld,    
           CASE WHEN A.WorkingTag = 'A' THEN A.FactUnit ELSE B.FactUnit END  AS FactUnitOld    
      INTO #CloseCheck    
      FROM #TempMES AS A    
        LEFT OUTER JOIN _TPDSFCWorkReport AS B ON B.CompanySeq = @CompanySeq    
                                              AND A.WorkReportSeq = B.WorkReportSeq    
        
    SET @XmlData = CONVERT(NVARCHAR(MAX),      
                (   SELECT DataSeq AS IDX_NO, *      
                      FROM #CloseCheck      
                    FOR XML RAW('DataBlock2'), ROOT('ROOT'), ELEMENTS)  )    
    -- 마감정보 생성              
    CREATE TABLE #TCOMCloseCheck (WorkingTag NCHAR(1) NULL)                
    EXEC dbo._SCAOpenXmlToTemp @XmlData, 2, @CompanySeq, 2639, 'DataBlock2', '#TCOMCloseCheck'    
    
    SELECT IDENTITY(INT, 1, 1) AS Seq,    
           A.*           , C.CompanySeq              , C.ClosingSeq     , C.SMTermUnit      , C.SMUnitSeq      ,    
           C.SMDtlUnitSeq, C.RptUnit AS RptUnitDefine, 0 AS UnitSeqOld  , 0 AS DtlUnitSeqOld, C.Level1DataBlock, C.Level2DataBlock,    
           (CASE WHEN F.MinorValue = '1' THEN 1 ELSE 2 END ) AS IsMaterial -- 자재여부    
      INTO #Temp    
      FROM #TCOMCloseCheck AS A    
                   JOIN _TCOMClosingDefineService AS B WITH(NOLOCK) ON B.CompanySeq   = @CompanySeq    
                                                                   AND A.ServiceSeq   = B.ServiceSeq    
                                                                   AND A.MethodSeq    = B.MethodSeq    
                   JOIN _TCOMClosingDefine        AS C WITH(NOLOCK) ON C.CompanySeq   = @CompanySeq    
                                                                   AND B.ClosingSeq   = C.ClosingSeq    
                                                                   AND C.IsUseClosing = '1' -- 마감체크사용하는 건들만    
        LEFT OUTER JOIN _TDAItem                  AS D WITH(NOLOCK) ON D.CompanySeq   = @CompanySeq    
                                                                   AND A.ItemSeq      = D.ItemSeq            
        LEFT OUTER JOIN _TDAItemAsset             AS E WITH(NOLOCK) ON E.CompanySeq   = @CompanySeq    
                                                                   AND D.AssetSeq     = E.AssetSeq           
        LEFT OUTER JOIN _TDASMinor                AS F WITH(NOLOCK) ON F.CompanySeq   = @CompanySeq    
                                                                     AND  E.SMAssetGrp   = F.MinorSeq    
        
    SELECT @Level1DataBlock = Level1DataBlock,    
           @Level2DataBlock = Level2DataBlock    
      FROM _TCOMClosingDefine    
     WHERE CompanySeq = @CompanySeq    
       AND ClosingSeq = 69    
        

    IF ISNULL(@Level1DataBlock, '') <> ''    
    BEGIN    
        SELECT @Sql1 = 'UPDATE #Temp SET UnitSeq = ISNULL('+ @Level1DataBlock +',0), UnitSeqOld = ISNULL('+ @Level1DataBlock +'Old,0)'    
            
        EXEC (@Sql1)    
    END    
        
    IF ISNULL(@Level2DataBlock, '') <> ''    
    BEGIN    
        SELECT @Sql2 = 'UPDATE #Temp SET DtlUnitSeq = ISNULL('+ @Level2DataBlock +',0), DtlUnitSeqOld = ISNULL('+ @Level2DataBlock +'Old,0)'    
            
        EXEC (@Sql2)    
    END    
        
    SELECT @Result = Message FROM _TCAMessageLanguage WHERE MessageSeq = 2 AND LanguageSeq = 1    
        
    SELECT @Result = REPLACE(@Result, '@1', '수불')    
        

    -- 일마감 체크 --    
    UPDATE C    
       SET C.Result = REPLACE(@Result, '@2' , CASE WHEN B.DtlUnitSeq = '1' THEN '(자재)' ELSE '(제/상품)' END),    
           C.Status = 1    
      FROM #Temp AS A    
        JOIN _TCOMClosingDate    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                  AND A.ClosingSeq = B.ClosingSeq    
        JOIN #TCOMCloseCheck     AS C              ON A.IDX_NO     = C.IDX_NO    
     WHERE (1 = 1)    
       AND ( B.ClosingDate = A.Date OR ( A.WorkingTag <> 'A' AND B.ClosingDate = A.DateOld ) )     
       AND ( ISNULL( A.SMUnitSeq, 0 ) > 0     
         AND ( B.UnitSeq = (CASE A.Level1DataBlock     
          WHEN 'BizUnit' THEN (CASE ISNULL( A.UnitSeq, '' )     
                WHEN '' THEN (SELECT BizUnit FROM _TDAFactUnit WITH (NOLOCK) WHERE ( CompanySeq = @CompanySeq AND FactUnit = A.FactUnit ))     
                ELSE A.UnitSeq END)    
          ELSE A.UnitSeq END ) -- CASE     
      OR ( A.WorkingTag <> 'A' AND B.UnitSeq = (CASE A.Level1DataBlock     
                  WHEN 'BizUnit' THEN (CASE ISNULL( A.UnitSeqOld, '' )     
                        WHEN '' THEN (SELECT BizUnit FROM _TDAFactUnit WITH (NOLOCK) WHERE ( CompanySeq = @CompanySeq AND FactUnit = A.FactUnitOld ))     
                        ELSE A.UnitSeqOld END)    
                  ELSE A.UnitSeqOld END) ) ) -- CASE, OR, AND     
        ) -- AND     
       AND ( B.DtlUnitSeq = A.IsMaterial )--OR ( A.WorkingTag <> 'A' AND B.DtlUnitSeq = A.IsMaterialOld ) )    
       AND B.IsClose = '1'    
       AND A.SMTermUnit = 1046001    
        
    -- 월마감 체크 --    
    UPDATE C    
       SET C.Result = REPLACE(@Result, '@2' , CASE WHEN B.DtlUnitSeq = '1' THEN '(자재)' ELSE '(제/상품)' END),    
           C.Status = 1    
      FROM #Temp    AS A     
        JOIN _TCOMClosingYM  AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ClosingSeq = B.ClosingSeq )    
        JOIN #TCOMCloseCheck AS C              ON ( A.IDX_NO = C.IDX_NO )    
     WHERE (1 = 1)    
       AND ( B.ClosingYM = ISNULL( A.DateYM, LEFT( A.Date, 6 ) ) OR ( A.WorkingTag <> 'A' AND B.ClosingYM = ISNULL( A.DateYMOld, LEFT( A.DateOld, 6 ) ) ) ) --    
       AND ( ISNULL( A.SMUnitSeq, 0 ) > 0     
         AND ( B.UnitSeq = (CASE A.Level1DataBlock     
          WHEN 'BizUnit' THEN (CASE ISNULL( A.UnitSeq, '' )     
                  WHEN '' THEN (SELECT BizUnit FROM _TDAFactUnit WITH (NOLOCK) WHERE ( CompanySeq = @CompanySeq AND FactUnit = A.FactUnit ))     
                ELSE A.UnitSeq END)    
          ELSE A.UnitSeq END ) -- CASE     
      OR ( A.WorkingTag <> 'A' AND B.UnitSeq = (CASE A.Level1DataBlock     
                  WHEN 'BizUnit' THEN (CASE ISNULL( A.UnitSeqOld, '' )     
                      WHEN '' THEN (SELECT BizUnit FROM _TDAFactUnit WITH (NOLOCK) WHERE ( CompanySeq = @CompanySeq AND FactUnit = A.FactUnitOld ))     
                        ELSE A.UnitSeqOld END)    
                  ELSE A.UnitSeqOld END) ) ) -- CASE, OR, AND     
        ) -- AND     
       AND ( B.DtlUnitSeq = A.IsMaterial )--OR ( A.WorkingTag <> 'A' AND B.DtlUnitSeq = A.IsMaterialOld ) )    
       AND B.IsClose = '1'     
       AND A.SMTermUnit = 1046002    
        
    UPDATE A    
       SET A.Status = B.Status,    
          A.Result = B.Result    
      FROM #TempMES AS A    
        JOIN #TCOMCloseCheck AS B ON A.DataSeq = B.DataSeq    
        
 

        
         
    --CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)      
    --EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock1', '#TPDSFCWorkReport'      
      
   
        
    ------------------------------          
    -- Temp테이블 데이터 XMl로 생성          
    ------------------------------          
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(          
                                                SELECT DataSeq - 1 AS IDX_NO, *           
                                                  FROM #TempMES          
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS          
                                            ))          
          
    ------------------------------          
    -- 생산실적Temp테이블 생성          
    ------------------------------          
    CREATE TABLE #TPDSFCWorkReport (WorkingTag NCHAR(1) NULL)              
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock1', '#TPDSFCWorkReport'              
          

		
	
		  
	DELETE _TCOMCreateSeqMax where TableName = '_TPDSFCWorkReport'
	DELETE _TCOMCreateSeqMax where TableName = '_TPDSFCGoodIn'


    ------------------------------          
    -- 생산실적 Check SP : 사업부별로 생산입고 방식이 달라 사이트용으로 별도 작성함.        
    ------------------------------          
    INSERT INTO #TPDSFCWorkReport          
    EXEC _SPDSFCWorkReportCheck          
         @xmlDocument  = @XmlData,          
         @xmlFlags     = 2,          
         @ServiceSeq   = 2909,          
         @WorkingTag   = '',          
         @CompanySeq   = @CompanySeq,          
         @LanguageSeq  = 1,          
         @UserSeq      = 1,--@UserSeq,          
         @PgmSeq       = 1015          
             
    IF @@ERROR <> 0           
    BEGIN          
        --ROLLBACK TRAN          
        RETURN            
    END          

	
	


	----UPDATE A
	----  SET WorkCondition1	= B.PassYN,
	----	  WorkCondition4	= B.RejectQty,
	----	  WorkCondition3	= B.InDate
	----  FROM #TPDSFCWorkReport AS A
	----	   JOIN #TempMES AS B ON A.DataSeq = B.DataSeq

	----select * from #TPDSFCWorkReport

	BEGIN TRAN											  
														            
    IF EXISTS (SELECT 1 FROM #TempMES WHERE Status = 0)    
    BEGIN    
            ------------------------------          
            -- 생산실적입력 SAVE SP XML 생성          
            ------------------------------          
            SELECT @XmlData = CONVERT(NVARCHAR(MAX),(          
                                                        SELECT *           
                                                          FROM #TPDSFCWorkReport          
                                                           FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS          
                                                    ))          

            DELETE #TPDSFCWorkReport          
        -- 생산실적 입력 --     
		

        INSERT INTO #TPDSFCWorkReport      
        EXEC KPXGC_SPDSFCWorkReportSave_POP      
             @xmlDocument = @XmlData   ,      
             @xmlFlags    = 2          ,      
             @ServiceSeq  = 2909       ,      
             @WorkingTag  = ''         ,      
             @CompanySeq  = @CompanySeq,      
             @LanguageSeq = 1          ,      
             @UserSeq     = 1          ,      
             @PgmSeq      = 1015      
              
        IF @@ERROR <> 0      
        BEGIN      
            ROLLBACK TRAN         
            RETURN      
        END    
		

      -- 진행 --       
    CREATE TABLE #SComSourceDailyBatch       
    (        
        ToTableName     NVARCHAR(100) ,        
        ToSeq           INT           ,        
        ToSerl          INT           ,        
        ToSubSerl       INT           ,        
        FromTableName   NVARCHAR(100) ,        
        FromSeq         INT           ,        
        FromSerl        INT           ,        
        FromSubSerl     INT           ,        
        ToQty           DECIMAL(19, 5),        
        ToStdQty        DECIMAL(19, 5),        
        ToAmt           DECIMAL(19, 5),        
        ToVAT           DECIMAL(19, 5),        
        FromQty         DECIMAL(19, 5),        
        FromSTDQty      DECIMAL(19, 5),        
        FromAmt         DECIMAL(19, 5),        
        FromVAT         DECIMAL(19, 5)        
    ) 

        TRUNCATE TABLE #SComSourceDailyBatch    
            
        -- 진행연결(작업지시 => 생산실적) 데이터 생성      
        INSERT INTO #SComSourceDailyBatch      
        SELECT '_TPDSFCWorkReport', A.WorkReportSeq, 0, 0,      
               '_TPDSFCWorkOrder', B.WorkOrderSeq, B.WorkOrderSerl, 0,      
               A.ProdQty, A.ProdQty, 0, 0,      
               B.OrderQty, B.StdUnitQty, 0, 0      
          FROM #TPDSFCWorkReport AS A      
            JOIN _TPDSFCWorkOrder AS B ON A.WorkOrderSeq  = B.WorkOrderSeq      
                                      AND A.WorkOrderSerl = B.WorkOrderSerl      
                               AND B.CompanySeq    = @CompanySeq      
         WHERE A.Status = 0    
           AND A.WorkingTag IN ('A','U')    
              
        IF @@ERROR <> 0      
        BEGIN      
            ROLLBACK TRAN        
            RETURN      
        END      
          
		EXEC _SComSourceDailyBatch 'D', @CompanySeq, 1     
        -- 진행연결(작업지시 => 생산실적)      
        EXEC _SComSourceDailyBatch 'A', @CompanySeq, 1      
        IF @@ERROR <> 0      
        BEGIN      
            ROLLBACK TRAN        
            RETURN      
        END      
    
	

        UPDATE #TempMES
          SET WorkReportSeq = CASE WHEN ISNULL(B.Result, '') <> '' THEN 0 ELSE B.WorkReportSeq END
         FROM #TempMES AS A 
         JOIN #TPDSFCWorkReport AS B ON A.DataSeq = B.DataSeq
		 WHERE A.WorkingTag = 'A'
              
        -- 생산 지시후 생산실적 데이터 반영 --      
        UPDATE KPX_TPDSFCWorkReport_POP      
           SET WorkReportSeq = CASE WHEN ISNULL(C.Result, '') <> '' THEN C.WorkReportSeq ELSE C.WorkReportSeq END,      
               PROCYN        = CASE WHEN ISNULL(C.Result, '') <> '' THEN '2' ELSE '1' END,
			   PROCDATETIME  = GETDATE(),
               ErrorMessage    = CASE WHEN ISNULL(C.Result, '') <> '' THEN C.Result ELSE '' END			      
          FROM KPX_TPDSFCWorkReport_POP AS A      
            JOIN #TempMES          AS B ON A.Seq = B.Seq      
            JOIN #TPDSFCWorkReport AS C ON B.DataSeq = C.DataSeq                  
        IF @@ERROR <> 0      
        BEGIN      
            ROLLBACK TRAN       

            RETURN      
        END
    
	
	
		--------------------------------------------------------------------------------------------------------------------------
		--최종공정일때 LOTNo Master에 등록해준다.
		--------------------------------------------------------------------------------------------------------------------------
		INSERT INTO _TLGLotMaster (
				CompanySeq,                                 LotNo,                                      ItemSeq,
				SourceLotNo,                                UnitSeq,                                    Qty,
				CreateDate,                                 CreateTime,                                 ValiDate,
				ValidTime,                                  RegDate,                                    RegUserSeq,
				CustSeq,                                    Remark,                                     OriLotNo,
				OriItemSeq,                                 InNo,                                       SupplyCustSeq,
				PgmSeqModifying,                            LastUserSeq,                                LastDateTime,
				PgmSeq
			)
		SELECT @CompanySeq,                              A.RealLotNo,                                A.GoodItemSeq,
				A.RealLotNo,                              A.ProdUnitSeq,                              SUM(A.OKQty),
				'',                               '', '',
				'', '', 1,
				0, 'POP생산실적', '',
				0, '', 0, 
				1015, 1, GETDATE(),
				0
				FROM #TPDSFCWorkReport AS A           
				JOIN _TPDSFCWorkOrder   AS B ON B.CompanySeq    = @CompanySeq      
										AND A.WorkOrderSeq  = B.WorkOrderSeq      
										AND A.WorkOrderSerl = B.WorkOrderSerl        
				JOIN _TPDProcTypeItem   AS F ON B.CompanySeq    = F.CompanySeq
										AND B.ProcSeq       = F.ProcSeq 
										AND F.IsLastProc = '1'     --최종공정 투입내역
				LEFT OUTER JOIN _TLGLotMaster AS L ON L.CompanySeq = @CompanySeq 
												AND A.GoodItemSeq = L.ItemSeq 
												AND A.RealLotNo = L.LotNo 
			WHERE (1=1)   
			AND A.WorkingTag = 'A'          
			AND A.Status = 0
			AND ISNULL(L.LotNo, '') = ''
			GROUP BY A.RealLotNo, A.GoodItemSeq, A.ProdUnitSeq
			------------------------------------------------------------------------------------------------------------------------


    END    
 


    DELETE _TCOMCreateSeqMax where TableName = '_TPDSFCWorkReport'
	DELETE _TCOMCreateSeqMax where TableName = '_TPDSFCGoodIn'
	DELETE _TCOMCreateSeqMax where TableName = '_TPDQCTestReport'

 ------   --수정건은 삭제하고 다시 인서트
	------IF EXISTS (Select 1 From #TPDSFCWorkReport WHERE WorkingTag IN ('U', 'D') )
	------BEGIN
	------	DELETE _TPDSFCMatinput 
	------	 FROM _TPDSFCMatinput AS A JOIN #TPDSFCWorkReport AS B ON A.WorkReportSeq = B.WorkReportSeq
	------	 WHERE B.WorkingTag IN ('U', 'D')

	------	DELETE _TPDSFCMatinput
	------	 FROM _TPDSFCMatinput AS A JOIN #KPX_TPDSFCWorkReport_POP AS B ON A.WorkReportSeq = B.WorkReportSeq
	------	 WHERE B.WorkingTag IN ('U', 'D')
		
	------END


    -- 투입 자재 내역을 IFR_TPDSFCMatinput_MDA 테이블에서 가져온다 --  
	INSERT INTO #TempMatinput  (WorkingTag, Status, Selected, TABLE_NAME, Seq, IFWorkReportSeq, WorkReportSeq, ItemSerl, Qty, InputDate,
						      MatItemSeq, MatUnitSeq, StdUnitQty, RealLotNo, SerialNoFrom, ProcSeq, AssyYn, IsConsign, GoodItemSeq, InputType, 
							  IsPaid, IsPjt, PjtSeq, WBSSeq, Remark, ProdWRSeq,SerialNo,  TableType, WorkOrderSeq,WorkOrderSerl,  WHSeq)
    SELECT A.WorkingTag       AS WorkingTag  ,      
           0                    AS Status      ,      
           0                    AS Selected    ,      
           'DataBlock2'         AS TABLE_NAME  ,
		   A.Seq				AS Seq,
           A.IFWorkReportSeq    AS IFWorkReportSeq,    
		   B.WorkReportSeq		AS WorkReportSeq,  
           CASE WHEN A.WorkingTag = 'A' THEN 0
                 WHEN A.WorkingTag <> 'A' THEN
                        (SELECT TOP 1 ItemSerl
                           FROM KPX_TPDSFCWorkREportExcept_POP
                          WHERE IFWorkReportSeq = A.IFWorkReportSeq
                            AND POPKey = A.POPKey
                            AND ProcYN <> '8'
                            AND Seq < A.Seq
                          ORDER BY Seq DESC) END                          AS ItemSerl,  
           A.Qty                AS Qty         ,      
           M.WorkDate           AS InputDate   ,      
           I.ItemSeq            AS MatItemSeq  ,    
           A.UnitSeq		    AS MatUnitSeq  ,      
           0                    AS StdUnitQty  ,      
           CASE WHEN S.IsLotMng = '1' and ISNULL(A.ItemLotNo ,'') = '' THEN I.ItemNo
                 WHEN S.IsLotMng = '1' and ISNULL(A.ItemLotNo ,'') <> '' THEN ISNULL(A.ItemLotNo,'')
                 WHEN S.IsLotMng = '0' THEN ''
                 ELSE '' END                AS RealLotNo,    
           ''                   AS SerialNoFrom,      
           C.ProcSeq            AS ProcSeq     ,      
           CASE WHEN D.GoodItemSeq = D.AssyItemSeq THEN '0'      
                WHEN D.IsLastProc  = '1'           THEN '0'      
                ELSE '1' END    AS AssyYn      ,      
           ''                   AS IsConsign   ,      
           B.GoodItemSeq        AS GoodItemSeq ,      
           6042002              AS InputType   ,      
           ''                   AS IsPaid      ,      
           '0'                  AS IsPjt       ,      
           0                    AS PjtSeq      ,      
           0                    AS WBSSeq      ,      
           ----1                    AS LastUserSeq ,      
           ----GETDATE()            AS LastDateTime,      
           '연동생성 투입건(투입연동)'                AS Remark      ,      
           0                    AS ProdWRSeq   ,      
           ''           AS SerialNo    ,      
           --A.WorkReportSeqMes   AS WorkReportSeqMes,      
           --A.ItemSerlMes        AS ItemSerlMes ,      
           '1'                  AS TableType,
           B.WorkOrderSeq       AS WorkOrderNo,
           B.WorkOrderSerl      AS WorkOrderSerl,
		   A.WHSeq              AS WHSeq
	
	 FROM KPX_TPDSFCWorkReportExcept_POP	  AS A  
        JOIN KPX_TPDSFCWorkReport_POP AS B ON B.IFWorkReportSeq = A.IFWorkReportSeq
                                          AND B.Seq = A.ReportSeq
        JOIN _TPDSFCWorkOrder  AS D WITH(NOLOCK) ON B.WorkOrderSeq  = D.WorkOrderSeq      
                                                AND B.WorkOrderSerl = D.WorkOrderSerl      
                                                AND B.CompanySeq    = D.CompanySeq      
        JOIN _TPDBaseProcess   AS C WITH(NOLOCK) ON C.CompanySeq    = @CompanySeq      
                                                AND C.ProcSeq       = B.ProcSeq 
        JOIN #TempMES          AS M ON  A.IFWorkReportSeq = M.IFWorkReportSeq
        JOIN _TDAItem          AS I WITH(NOLOCK) ON I.CompanySeq    = @CompanySeq
                                                AND A.ItemSeq        = I.ItemSeq    
		LEFT OUTER JOIN _TDAItemStock AS S ON S.CompanySeq = @CompanySeq
                                          AND S.ItemSeq = A.ItemSeq
     WHERE A.ProcYN  = '0'
       AND A.CompanySeq = @CompanySeq   
	   AND A.IFWorkReportSeq IN (SELECT IFWorkReportSeq FROM #TempMES)


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

    ---- 창고재고 가져오기	 
    --EXEC _SLGGetInOutStock @CompanySeq   = @CompanySeq,   -- 법인코드      
    --                            @BizUnit      = 0,      -- 사업부문      
    --                            @FactUnit     = 0,     -- 생산사업장     
    --                            @DateFr       = @DateFr,       -- 조회기간Fr     
    --                            @DateTo       = @DateTo,       -- 조회기간To     
    --                            @WHSeq        = 0,        -- 창고지정      
    --                            @SMWHKind     = 0,     -- 창고구분별 조회
    --                            @CustSeq      = 0,      -- 수탁거래처     
    --                            @IsTrustCust  = '',  -- 수탁여부      
    --                            @IsSubDisplay = 0, -- 기능창고 조회 
    --                            @IsUnitQry    = 0,    -- 단위별 조회   
    --                            @QryType      = 'S'       -- 'S': 1007 실재고, 'B':1008 자산포함, 'A':1011 가용재고



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


	/**************************************************************************************************************************************************/

 

	--SELECT ISNULL(B.STDStockQty,0) , A.ProdQty, *
	/* 1.마이너스 재고이면 삭제함. */
	DELETE #TempMatinput
	  FROM #TempMatinput  
    WHERE WorkReportSeq IN (SELECT WorkReportSeq 
							  FROM #TempMatinput AS A LEFT OUTER JOIN #GetInOutStock AS B ON A.MatItemSeq = B.ItemSeq AND A.WHSeq = B.WHSeq
							 WHERE ISNULL(B.STDStockQty,0) - A.Qty < 0 
							)
			

/*
    INSERT INTO #TempMatinput      
        (         
            WorkingTag  , Status     , Selected    , TABLE_NAME       , WorkReportSeq ,      
            ItemSerl    , Qty        , InputDate   , MatItemSeq       , MatUnitSeq    ,      
            StdUnitQty  , RealLotNo  , SerialNoFrom, ProcSeq          ,      
            AssyYn      , IsConsign  , GoodItemSeq , InputType        , IsPaid        ,      
            IsPjt       , PjtSeq     , WBSSeq      , LastUserSeq      , LastDateTime  ,      
            Remark      , ProdWRSeq  , SerialNo    , TableType        , WorkOrderSeq   , WorkOrderSerl, WHSeq
        )      
    SELECT 'A' , 0          , 0           , 'DataBlock2'     , A.WorkReportSeq ,      
           0            , A.OKQty * (C.NeedQtyNumerator / C.NeedQtyDenominator), A.WorkDate      , C.MatItemSeq     , C.UnitSeq       ,      
           0            , ''         , ''          , A.ProcSeq        ,      
           CASE WHEN B.GoodItemSeq = B.AssyItemSeq THEN '0'      
                  WHEN B.IsLastProc  = '1'           THEN '0'      
                ELSE '1' END    AS AssyYn      , '', B.GoodItemSeq    , 6042002 , ''    ,      
           '0'          , 0          , 0           , 1                , GETDATE()       ,      
           '연동생성 투입건(투입연동)'        , 0          , E.SerialNo  , '2'              , 0               , 0 
     FROM #TPDSFCWorkReport AS A      
        JOIN _TPDSFCWorkOrder   AS B ON B.CompanySeq    = @CompanySeq      
                                    AND A.WorkOrderSeq  = B.WorkOrderSeq      
                                    AND A.WorkOrderSerl = B.WorkOrderSerl 
		JOIN _TPDROUItemProcMat AS C ON B.CompanySeq    = C.CompanySeq      
                                    AND B.GoodItemSeq   = C.ItemSeq      
                                    AND B.ProcRev       = C.ProcRev      
                                    AND B.ItemBomRev    = C.BomRev      
                                    AND B.ProcSeq       = C.ProcSeq   									     
        ----JOIN _TPDBOM AS C ON B.CompanySeq    = C.CompanySeq      
        ----                            AND B.GoodItemSeq   = C.ItemSeq      
        ----                            --AND B.ProcRev       = C.ProcRev      
        ----                            AND B.ItemBomRev    = C.ItemBomRev      
        ----                            --AND B.ProcSeq       = C.ProcSeq      
        JOIN _TDAItem           AS D ON C.CompanySeq    = D.CompanySeq      
                                    AND C.MatItemSeq    = D.ItemSeq      		
        JOIN #TempMES           AS E ON A.DataSeq       = E.DataSeq    ---- AND M.WorkReportSeq = E.WorkReportSeq         
        JOIN _TPDProcTypeItem   AS F ON B.CompanySeq    = F.CompanySeq
                                    AND A.ProcSeq       = F.ProcSeq 
                                    AND F.IsLastProc = '1'     --최종공정 투입내역
      WHERE (1=1)   
       AND A.WorkingTag = 'A'          
       AND A.Status = 0     
	   AND C.MatItemSeq NOT IN (SELECT K.MatItemSeq FROM #TempMatinput AS K WHERE A.WorkReportSeq = K.WorkReportSeq)
    
	*/
	
	
	 
    --품목별환산단위등록에 없는 단위면, 품목의 기준단위를 사용함.    
    IF NOT EXISTS (SELECT 1 
                     FROM #TempMatinput    AS A
                       JOIN _TDAItemUnit AS B ON B.ItemSeq    = A.MatItemSeq      
                                             AND B.UnitSeq    = A.MatUnitSeq      
                                             AND B.CompanySeq = @CompanySeq       
                   )
     BEGIN
         UPDATE A
           SET MatUnitSeq = B.UnitSeq 
          FROM #TempMatinput AS A
             JOIN _TDAItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq
                                            AND A.MatItemSeq    = B.ItemSeq 
     END    
     
     
     
                   
    -- 기준단위 수량 적용 --      
    UPDATE A      
       SET StdUnitQty = A.Qty * (CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum / ConvDen END)      
      FROM #TempMatinput AS A      
        JOIN _TDAItemUnit AS B ON B.ItemSeq    = A.MatItemSeq      
                              AND B.UnitSeq    = A.MatUnitSeq      
                              AND B.CompanySeq = @CompanySeq      
          
    -- 자재투입내부순번(ItemSerl) 생성 --      
    SELECT WorkReportSeq, DataSeq, ROW_NUMBER() OVER(PARTITION BY WorkReportSeq ORDER BY WorkReportSeq) as ItemSerl      
      INTO #TempMatInput_Serl      
      FROM #TempMatinput   
	 WHERE WorkingTag = 'A'     
      
    IF EXISTS (SELECT 1 FROM #TempMatInput_Serl)      
    BEGIN      
        SELECT @Count = COUNT(*) FROM #TempMatInput_Serl      
              
        SELECT @Seq = MAX(A.ItemSerl)      
          FROM _TPDSFCMatinput AS A      
            JOIN #TempMatInput_Serl AS B ON A.WorkReportSeq = B.WorkReportSeq      
           WHERE A.CompanySeq = @CompanySeq  
		       
        SELECT @Seq = ISNULL(@Seq, 0)      
      
        -- #TempMatinput 테이블에 ItemSerl UpDate(WorkingTag A인것만) --      
        UPDATE A      
           SET A.ItemSerl = @Seq + B.ItemSerl --@Seq + B.DataSeq      
          FROM #TempMatinput AS A       
            JOIN #TempMatInput_Serl AS B ON A.DataSeq = B.DataSeq      
        WHERE WorkingTag = 'A'

        IF @@ERROR <> 0      
        BEGIN      
            ROLLBACK TRAN          
            RETURN      
        END      
    END      
 
      
    -- 생산실적키가 없는 건은 삭제해준다 --      
    DELETE #TempMatinput      
      FROM #TempMatinput      
     WHERE ISNULL(WorkReportSeq, 0) = 0
	 

    CREATE TABLE #TPDSFCMatinput (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2909, 'DataBlock2', '#TPDSFCMatinput'      
      
    SET @XmlData = CONVERT(NVARCHAR(MAX),      
                    (   SELECT DataSeq - 1 AS IDX_NO, *      
                          FROM #TempMatinput      
                        FOR XML RAW('DataBlock2'), ROOT('ROOT'), ELEMENTS) )      
      


	
     ----자재투입내역 반영 --        
    INSERT INTO #TPDSFCMatinput      
    EXEC KPXGC_SPDSFCWorkReportMatSave      
         @XmlDocument = @XmlData   ,      
         @XmlFlags     = 2         ,      
         @ServiceSeq  = 2909       ,      
           @WorkingTag  = ''         ,      
         @CompanySeq  = @CompanySeq,      
         @LanguageSeq = 1          ,      
         @UserSeq     = 1          ,      
         @PgmSeq      = 1015      
          
    IF @@ERROR <> 0    
    BEGIN      
        ROLLBACK TRAN        
        RETURN      
    END


    -- MES에서 실적이 월변경하여 수정이 발생할 경우 기존 수불데이터 강제로 삭제 2016.11.02 by이재천 
    IF EXISTS ( SELECT 1 FROM #TempMES WHERE WorkingTag = 'U' ) 
    BEGIN 
        
        SELECT B.WorkingTag, A.GoodInSeq, A.WorkReportSeq  
          INTO #DelSeq 
          FROM _TPDSFCGoodIn AS A 
          JOIN #TempMES      AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
         WHERE A.CompanySeq = @CompanySeq 


        DELETE A 
          FROM _TLGInOutDaily AS A 
          JOIN #DelSeq        AS B ON ( B.GoodInSeq = A.InOutSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 140 
           AND B.WorkingTag = 'U' 

        DELETE A 
          FROM _TLGInOutDailyItem AS A 
          JOIN #DelSeq        AS B ON ( B.GoodInSeq = A.InOutSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 140 
           AND B.WorkingTag = 'U' 

        DELETE A 
          FROM _TLGInoutStock AS A 
          JOIN #DelSeq        AS B ON ( B.GoodInSeq = A.InOutSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 140 
           AND B.WorkingTag = 'U' 

        DELETE A 
          FROM _TLGInoutLotStock AS A 
          JOIN #DelSeq        AS B ON ( B.GoodInSeq = A.InOutSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.InOutType = 140 
           AND B.WorkingTag = 'U' 
    END 
    -- MES에서 실적이 월변경하여 수정이 발생할 경우 기존 수불데이터 강제로 삭제, END 2016.11.02 by이재천 



 ----   IF EXISTS (Select 1 From #TempMatinput WHERE ISNULL(MatItemSeq,0) <> 0 AND WorkingTag = 'A' ) 
	----BEGIN 
	----	INSERT INTO _TPDSFCMatinput (    
	----		CompanySeq,         WorkReportSeq,      ItemSerl,           InputDate,              MatItemSeq,    
	----		MatUnitSeq,         Qty,                StdUnitQty,         RealLotNo,              SerialNoFrom,    
	----		ProcSeq,            AssyYn,             IsConsign,          GoodItemSeq,    
	----		InputType,          IsPaid,             IsPjt,              PjtSeq,                 WBSSeq,    
	----		LastUserSeq,        LastDateTime,       Remark,             ProdWRSeq    
	----	)    

	----	SELECT    
	----		@CompanySeq,       A.WorkReportSeq,    A.ItemSerl,  A.InputDate,            A.MatItemSeq,    
	----		A.MatUnitSeq,          A.Qty,        A.Qty, --ROUND(A.InPutQty*(CASE WHEN ConvDen = 0 THEN 0 ELSE ConvNum/ConvDen END),2) ,          
	----		A.RealLotNo      ,'',    
	----		0,          '0',                '',                 0,    
	----		6042002,            '',                 '0',                0,                      0,    
	----		@UserSeq,                  GETDATE(),          '',              0    
	----		FROM #TempMatinput AS A  
	----		WHERE ISNULL(A.MatItemSeq,0) <> 0
	----		 AND WorkingTag = 'A'
	----END	
	
	  	 -- 생산실적 및 재고반영 수불발생  
	 SELECT DISTINCT   
		 WorkingTag            AS WorkingTag,   
		 IDENTITY(INT, 1, 1)       AS DataSeq,  
		 0           AS Status,  
		 'DataBlock1'         AS TABLE_NAME,  
		 LEFT(WorkDate, 6) AS InOutYM  ,
		 130           AS SMInOutType   
	   INTO #TLGInOUtDailyTemp  
	   FROM #TPDSFCWorkReport AS A  
	  WHERE Status = 0

	INSERT INTO #TLGInOUtDailyTemp (WorkingTag, Status, TABLE_NAME, InOutYM, SMInOutType)
	SELECT DISTINCT   
		 WorkingTag            AS WorkingTag,   
		 0           AS Status,  
		 'DataBlock1'         AS TABLE_NAME,  
		 LEFT(WorkDate, 6) AS InOutYM  ,
		 140           AS SMInOutType   
	   FROM #TPDSFCWorkReport AS A  
	  WHERE Status = 0

	SELECT @XmlData = CONVERT(NVARCHAR(MAX),(          
				SELECT DataSeq - 1 AS IDX_NO, *           
				  FROM #TLGInOUtDailyTemp      
				FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS          
				))      

    CREATE TABLE #TLGStockReSum (WorkingTag NCHAR(1) NULL)      
    EXEC dbo._SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 5248, 'DataBlock1', '#TLGStockReSum' 


	INSERT INTO #TLGStockReSum  
	 EXEC _SLGReInOutStockSum  
	   @xmlDocument  = @XmlData,          
	   @xmlFlags     = 2,          
	   @ServiceSeq   = 5248,          
	   @WorkingTag   = '',          
	   @CompanySeq   = @CompanySeq,          
	   @LanguageSeq  = 1,          
	   @UserSeq      = 1,          
	   @PgmSeq       = 1  

	IF @@ERROR <> 0           
	 BEGIN          
			ROLLBACK TRAN   
			RETURN       
	 END   


	---------- --생산 실적의 자재투입 데이터 반영      
	UPDATE KPX_TPDSFCWorkReportExcept_POP	      
       SET ItemSerl       = CASE WHEN ISNULL(C.Result, '') <> '' THEN 0 ELSE C.ItemSerl END,      
           ProcYn        = CASE WHEN (ISNULL(C.Result, '') <> '' OR ISNULL(C.ItemSerl, 0) = 0)  THEN '0' ELSE '1' END,
           WorkReportSeq = CASE WHEN ISNULL(C.Result, '') <> '' THEN 0 ELSE B.WorkReportSeq END,
           ErrorMessage    = CASE WHEN ISNULL(C.Result, '') <> '' THEN C.Result ELSE '' END,
		   ProcDateTime = GETDATE()
      FROM KPX_TPDSFCWorkReportExcept_POP AS A      
        JOIN #TempMatinput     AS B ON A.IFWorkReportSeq = B.IFWorkReportSeq And A.Seq = B.Seq     
        JOIN #TPDSFCMatinput AS C ON B.DataSeq = C.DataSeq 
     WHERE B.TableType = '1'      
	  AND A.ProcYN  = '0'
	 AND ISNULL(A.WorkReportSeq, 0) = 0 
          
    IF @@ERROR <> 0      
    BEGIN      
        ROLLBACK TRAN        
        RETURN      
    END      

	 ----SELECT C.ItemSerl, *
	 ----FROM KPX_TPDSFCWorkReportExcept_POP AS A      
  ----      JOIN #TempMatinput     AS B ON A.IFWorkReportSeq = B.IFWorkReportSeq And A.Seq = B.Seq     
  ----      JOIN #TPDSFCMatinput AS C ON B.DataSeq = C.DataSeq 
  ----   WHERE B.TableType = '1'      
	 ---- AND A.ProcYN  = '0'
	 ----AND ISNULL(A.WorkReportSeq, 0) = 0 


    ---------------------------------------------------------------------------------------
	-- 실행결과 표시 
	---------------------------------------------------------------------------------------
	DECLARE @TOTCnt INT, @OKCnt INT
	 
	SELECT @TOTCnt = COUNT(1) FROM #TempMES
	SELECT @OKCnt  = COUNT(1) FROM #TempMES WHERE WorkReportSeq <> 0

  COMMIT TRAN     

  --rollback tran 

	----SELECT * FROM KPX_TPDSFCWorkReport_POP WHERE Seq IN (15636,15638,15639,15640,15641,15643,15644)
	----SELECT * FROM KPX_TPDSFCWorkReportExcept_POP WHERE IFWorkReportSeq IN (SELECT IFWorkReportSeq FROM KPX_TPDSFCWorkReport_POP WHERE Seq IN (15636,15638,15639,15640,15641,15643,15644))

 ---- rollback tran
	     
      RETURN     


GO


select * from _TDASMinor where majorseq = 8042 and companyseq = 1 