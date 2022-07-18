
IF OBJECT_ID('KPXGC_SPDSFCWorkReport_POP') IS NOT NULL 
    DROP PROC KPXGC_SPDSFCWorkReport_POP
GO 

-- 2016.11.28 

-- 수불반영관련 문제가 발생하여 전체적으로 수정 by이재천 
/*************************************************************************************************************    
 설  명 - POP생산실적 생성
 작성일 - 20151120
 작성자 - 천혜연   
*************************************************************************************************************/    
CREATE PROC KPXGC_SPDSFCWorkReport_POP
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
			@WhSeq				INT,
			@UserSeq			INT,
			@ProcTypeSeq		INT,
			@StdYM				NCHAR(6),
			@DateFr             NVARCHAR(8),
			@DateTo             NVARCHAR(8), 
            @CurrDATETIME       DATETIME
    
    SELECT @CurrDATETIME    = GETDATE()      

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
    

	INSERT INTO #KPX_TPDSFCWorkReport_POP
    (
        Seq				, WorkingTag		, CRTDATETIME		, PROCYN			, PROCDATETIME	    , 
        ErrorMessage	, COMPANYSEQ		, FactUnit		    , IFWorkReportSeq	, WorkStartDate 	, 
        WorkEndDate		, EmpSeq			, DeptSeq			, WorkReportSeq	    , WorkOrderNo		, 
        WorkOrderSeq	, WorkOrderSerl	    , WorkCenterSeq	    , GoodItemSeq		, ProcRev			, 
        AssyItemSeq		, ProcSeq			, UnitSeq			, RealLotNo		    , Qty				, 
        OKQty		    , BadQty			, WhSeq			    , WorkTimeGroup	    , WorkStartTime	    , 
        WorkEndTime		, WorkMin			, Remark			

    )
	SELECT TOP 1 
           A.Seq,               A.WorkingTag,		A.RegDateTime,      A.ProcYN,           A.ProcDateTime,     
           A.ErrorMessage,      A.CompanySeq,       B.FactUnit,		    A.IFWorkReportSeq,  A.WorkStartDate,    

           A.WorkEndDate,       F.EmpSeq,           (CASE WHEN ISNULL(A.DeptSeq, 0) = 0 THEN F.DeptSeq ELSE A.DeptSeq END) AS DeptSeq, 
           A.WorkReportSeq,     W.WorkOrderNo,      
           
           W.WorkOrderSeq,      W.WorkOrderSerl,    W.WorkCenterSeq,    A.GoodItemSeq,      '00',   
           A.AssyItemSeq,       A.ProcSeq,          A.ProdUnitSeq,      A.RealLotNo,        ISNULL(A.ProdQty,0),    
           ISNULL(A.OKQty,0),   ISNULL(A.BadQty,0), B.ProdInWhSeq,	    A.WorkTimeGroup,    A.WorkStartTime, 
           A.WorkEndTime,       (A.WorkMin/60.0),   '[POP 생산실적]'
			
	  FROM KPX_TPDSFCWorkReport_POP                 AS A
                 JOIN _TPDBaseWorkCenter            AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq ) 
      LEFT OUTER JOIN _fnadmEmpOrd(@CompanySeq, '') AS F ON ( F.EmpSeq = A.RegEmpSeq ) 
                 JOIN _TPDSFCWorkOrder AS W ON W.CompanySeq = @CompanySeq AND W.WorkOrderSeq = A.WorkOrderSeq AND W.WorkOrderSerl = A.WorkOrderSerl  
     WHERE A.CompanySeq = @CompanySeq 
       AND ISNULL(A.ProcYn, '0') = '0' 
       AND A.IsPacking = '0' 

       AND A.WorkStartDate > @LGstartEnv+'00' --물류시작월 이후만 처리 
       --AND (@WorkDate = '' OR A.WorkStartDate = @WorkDate)
     ORDER BY A.Seq 

    -- WHERE A.CompanySeq = @CompanySeq
    --   AND ISNULL(A.PROCYN, '0') <> '1' 
	   --AND A.WorkStartDate > @LGstartEnv+'00' --물류시작월 이후만 처리 
	   --AND A.IsPacking ='0' 
	   --AND LEFT(A.WorkEndDate, 6)  > @StdYM 
	   --AND (@WorkDate = '' OR A.WorkStartDate = @WorkDate)
	   --AND (@popseq = 0 or A.Seq = @popSeq) 
	   --AND NOT EXISTS (SELECT ClosingYM FROM _TCOMClosingYM WHERE CompanySeq = @CompanySeq AND ClosingSeq  = 69 AND ClosingYM = LEFT(A.WorkEndDate, 6) AND IsClose = '1' AND UnitSeq = 1)

	   --select * from #KPX_TPDSFCWorkReport_POP where IFWOrkReportSeq = '2015120200008'
    
    --select * from #KPX_TPDSFCWorkReport_POP 
    --return 
    
    UPDATE A    
       SET ProcYN = '5' --처리시작    
      FROM KPX_TPDSFCWorkReport_POP AS A    
     WHERE A.CompanySeq = @CompanySeq
       And ISNULL(A.ProcYN ,'0') = '0'    
       AND A.Seq IN (SELECT Seq FROM #KPX_TPDSFCWorkReport_POP)    
    

	
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
     WHERE A.WorkingTag IN ( 'U', 'D' ) 

	 --UPDATE #KPX_TPDSFCWorkReport_POP SET WorkingTag = 'A' WHERE WorkReportSeq
	 
     --select *from #KPX_TPDSFCWorkReport_POP 
     --return 
	  

	IF NOT EXISTS (SELECT 1 FROM #KPX_TPDSFCWorkReport_POP) -- 처리할 데이터가 없다면 종료한다.                    
    BEGIN     
	                              
        RETURN                    
    END
    
	          
    SELECT DISTINCT         
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
		   0					AS WorkerQty    , 
           D.BizUnit            AS BizUnit 
	

      INTO #TempMES      
      FROM #KPX_TPDSFCWorkReport_POP AS A      
      JOIN _TPDSFCWorkOrder  AS B ON A.WorkOrderNo  = B.WorkOrderNo 
                                 AND A.WorkOrderSerl = B.WorkOrderSerl     
                                 AND A.CompanySeq     = B.CompanySeq      
      JOIN _TPDBaseProcess   AS C ON C.CompanySeq     = @CompanySeq      
                                 AND C.ProcSeq        = B.ProcSeq      
      LEFT OUTER JOIN _TDAFactUnit  AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = B.FactUnit ) 
   
     WHERE (1 = 1)     
       AND A.WorkOrderSerl <> 0      
       AND A.CompanySeq = @CompanySeq 
     ORDER BY Seq
    
    
    ALTER TABLE #TempMES ADD Result NVARCHAR(250)
    
--================================================================================================================================================================
	 
	--생산실적 처리할 데이터가 없으면 종료
	IF NOT EXISTS ( SELECT 1 FROM #TempMES )
	BEGIN 
        RETURN    
	END
    
    -- 수불마감 
    UPDATE A
       SET Status = 1234, 
           Result = '월 수불마감으로 인해 처리 할 수 없습니다.'
      FROM #TempMES AS A 
     WHERE EXISTS (
                   SELECT 1 
                     FROM _TCOMClosingYM AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.ClosingSeq  = 69
                      AND Z.ClosingYM = LEFT(A.WorkCondition2, 6) 
                      AND Z.UnitSeq = A.BizUnit 
                      AND Z.IsClose = '1' 
                  )
    
	IF EXISTS ( SELECT 1 FROM #TempMES WHERE Status <> 0 )
	BEGIN 
        UPDATE A
           SET ErrorMessage = B.Result, 
               ProcYn = '2' 
          FROM KPX_TPDSFCWorkReport_POP AS A 
          JOIN #TempMES                 AS B ON ( B.Seq = A.Seq ) 
         WHERE A.CompanySeq = @CompanySeq 
        
        RETURN    
	END
    
    
    --=================================================================================        
    -- 트랜젝션 시작 부분        
    --=================================================================================        
    SET LOCK_TIMEOUT -1        
    BEGIN TRAN 
    BEGIN TRY       

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
        RAISERROR('Error during ''EXEC _SPDSFCWorkReportCheck''', 15, 1)        
          
    END    
	
	IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE Status <> 0)
    BEGIN 
	     --오류시 오류처리        
	     UPDATE A      
		    SET ProcYN = '2',      
		        ErrorMessage = '''EXEC _SPDSFCWorkReportCheck Error'''      
	       FROM KPX_TPDSFCWorkReport_POP    AS A      
		     JOIN #TempMES                  AS B ON B.Seq = A.Seq      
		     JOIN #TPDSFCWorkReport         AS D ON D.DataSeq = B.DataSeq      
	      WHERE D.Status <> 0  
	        and A.CompanySeq = @CompanySeq     
    END 
    
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

        TRUNCATE TABLE #TPDSFCWorkReport          
        
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
    
    
    --11 
        --select * from #TempMES 
        --select * from _TPDSFCWorkReport where companyseq = 1 and workreportseq = 30621 
        --select * from _TPDSFCGoodIn where companyseq = 1 and workreportseq = 30621 
        --select * from _TLGinoutDaily where companyseq = 1 and inoutseq = 30621
        --return 

        IF @@ERROR <> 0             
        BEGIN        
            RAISERROR('Error during ''EXEC KPXGC_SPDSFCWorkReportSave_POP''', 15, 1)        
        END   

        --select * from #TempMES 
        --select * From _TPDSFCWorkReport where companyseq = 1 and workreportseq = 30619 
        --select * From _TPDSFCGoodIn where companyseq = 1 and workreportseq = 30619 
        --return 
        -----------------------------------------            
        -- 에러걸렸을 경우, 체크내역 담기         
        -----------------------------------------          
        IF EXISTS (SELECT 1 FROM #TPDSFCWorkReport WHERE Status <> 0)        
        BEGIN       
            UPDATE #TempMES        
               SET Status = C.Status        
                  ,Result = C.Result        
                  ,WorkReportSeq = 0         
             FROM #TempMES          AS A      
             JOIN #TPDSFCWorkReport AS C ON A.WorkReportSeq = C.WorkReportSeq      
            WHERE A.Status = 0      
              AND C.Status <> 0        
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
        
		EXEC _SComSourceDailyBatch 'D', @CompanySeq, 1     

        IF @@ERROR <> 0             
        BEGIN        
            RAISERROR('Error during ''EXEC _SComSourceDailyBatch''', 15, 1)        
        END  

        -- 진행연결(작업지시 => 생산실적)      
        EXEC _SComSourceDailyBatch 'A', @CompanySeq, 1      

        IF @@ERROR <> 0             
        BEGIN        
            RAISERROR('Error during ''EXEC _SComSourceDailyBatch''', 15, 1)        
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

    --select * from #TempMES 
    --return 


    /*------------------------------------------------------------------------------------------------------------------------------        
        수불 Batch Save        
    ------------------------------------------------------------------------------------------------------------------------------*/          

    ------------------------------            
    -- 입출고 SAVE TempData생성            
    ------------------------------            
    SELECT A.WorkingTag,            
           A.IDX_NO,            
           A.DataSeq,            
           A.Status,            
           A.Selected,            
           'DataBlock1'    AS TABLE_NAME,            
           A.WorkReportSeq AS InOutSeq,            
           130             AS InOutType            
      INTO #TMP_InOutDailyBatch_Xml        
      FROM #TPDSFCWorkReport AS A            
     WHERE NOT EXISTS (SELECT 1 FROM #TempMES WHERE WorkReportSeq = A.WorkReportSeq AND Status <> 0)         


    ------------------------------            
    -- 입출고 SAVE Xml생성            
    ------------------------------            
    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(            
                                                SELECT *             
                                                  FROM #TMP_InOutDailyBatch_Xml            
                                                   FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS            
                                            ))            
    IF OBJECT_ID('tempdb..#TLGInOutDailyBatch') IS NOT NULL      
    BEGIN      
        DROP TABLE #TLGInOutDailyBatch      
    END    
    
    CREATE TABLE #TLGInOutDailyBatch (WorkingTag NCHAR(1) NULL)              
    EXEC _SCAOpenXmlToTemp '<ROOT></ROOT>', 2, @CompanySeq, 2619, 'DataBlock1', '#TLGInOutDailyBatch'       
    
    ------------------------------            
    -- 입출고 SAVE SP            
    ------------------------------            
    INSERT INTO #TLGInOutDailyBatch        
    EXEC KPX_SLGInOutDailyBatch_POP             
         @xmlDocument  = @XmlData,            
         @xmlFlags     = 2,            
         @ServiceSeq   = 2619,            
         @WorkingTag   = '',            
         @CompanySeq   = @CompanySeq,             
         @LanguageSeq  = 1,            
         @UserSeq      = @UserSeq,    
         @PgmSeq       = 1015            
  
    IF @@ERROR <> 0             
    BEGIN        
        RAISERROR('Error during ''EXEC KPX_SLGInOutDailyBatch_POP''', 15, 1)        
    END    

    -----------------------------------------            
    -- 에러걸렸을 경우, 체크내역 담기         
    -----------------------------------------          
    IF EXISTS (SELECT 1 FROM #TLGInOutDailyBatch WHERE Status <> 0)        
     BEGIN        
        UPDATE #TMP_TPDSFCWorkReport        
           SET   Status = B.Status        
                ,Result = B.Result        
          FROM #TmpMES              AS A        
          JOIN #TLGInOutDailyBatch  AS B ON A.WorkReportSeq = B.InOutSeq        
        WHERE A.Status = 0        
          AND B.Status <> 0       
                
     END        

    --------------------------------------------------------------------------------------------------------------------------------------------------         
    -- 최종 반영내역  UPDATE        
    --------------------------------------------------------------------------------------------------------------------------------------------------         
    UPDATE A        
       SET   ProcYn = CASE WHEN B.Status = 0 THEN '1' ELSE '2' END        
            ,ProcDateTime = @CurrDATETIME        
            ,ErrorMessage = ISNULL(B.Result,'') 
            ,WorkReportSeq    = CASE WHEN B.Status = 0 THEN B.WorkReportSeq ELSE 0 END      
      FROM KPX_TPDSFCWorkReport_POP AS A        
      JOIN #TempMES                 AS B ON A.Seq = B.Seq       
                                        AND A.WorkOrderSeq = B.WorkOrderSeq    
                                        AND A.WorkOrderSerl = B.WorkOrderSerl     
     WHERE A.CompanySeq = @CompanySeq 
         

    
    END TRY       
        
         
    BEGIN CATCH        
    --select 1    
        SELECT ERROR_NUMBER()    AS ErrorNumber,        
               ERROR_SEVERITY()  AS ErrorSeverity,        
               ERROR_STATE()     AS ErrorState,        
               ERROR_PROCEDURE() AS ErrorProcedure,        
               ERROR_LINE()      AS ErrorLine,        
               ERROR_MESSAGE()   AS ErrorMessage;        
        
        IF @@TRANCOUNT > 0        
            ROLLBACK TRANSACTION;        
        
    END CATCH        
        
    IF @@TRANCOUNT > 0        
        COMMIT TRANSACTION;        
                
    
    select * from #TPDSFCWorkReport 

    RETURN     
GO
--begin tran 
--exec KPXGC_SPDSFCWorkReport_POP 1 
--rollback 


--delete From KPX_TPDSFCWorkReport_POP where companyseq = 1 and workorderseq = 310394



--delete from KPX_TPDSFCWorkReportExcept_POP where reportseq in ( 27130,27162 )