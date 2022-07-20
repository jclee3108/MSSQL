     
IF OBJECT_ID('mnpt_SPREEWkEmpOTTimeDetailListPrint') IS NOT NULL       
    DROP PROC mnpt_SPREEWkEmpOTTimeDetailListPrint      
GO      
      
-- v2018.01.24  
      
-- 초과근로현황-디테일출력 by 이재천  
CREATE PROC mnpt_SPREEWkEmpOTTimeDetailListPrint      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @WkDateFr       NCHAR(8), 
            @WkDateTo       NCHAR(8), 
            @StdYM          NCHAR(6), 
            @HolidayIN      NCHAR(1) 
    
    select @WkDateFr = WkDateFr, 
           @WkDateTo = WkDateTo, 
           @StdYM    = StdYM, 
           @HolidayIN = HolidayIN
      FROM #BIZ_IN_DataBlock1 
    
    --select * from _TDAEmp where empseq = 16

    
    CREATE TABLE #mnpt_TPREEWkEmptemp 
    (
		WkDate				NCHAR(8),
		Day					NVARCHAR(100),
		HolidayKindName		NVARCHAR(100),
		BegTime				NCHAR(4),
		EndTime				NCHAR(4),
		WkOT				NCHAR(100),--DECIMAL(19,2),
		WkDay2				NCHAR(100),--DECIMAL(19,2),
		WkHoliday2			NCHAR(100),--DECIMAL(19,2),
		EmpEx2				NCHAR(100),--DECIMAL(19,2),
		EmpHoliday2			NCHAR(100),--DECIMAL(19,2),
		EmpNight2			NCHAR(100),--DECIMAL(19,2),
		BreakFast2			DECIMAL(19,5),
		Lunch2				DECIMAL(19,5),
		Dinner2				DECIMAL(19,5),
		NightMeal2			DECIMAL(19,5),
		EarlyWork2			DECIMAL(19,5),
		NightWork2			DECIMAL(19,5),
		Seq2				INT, 
        Sort                INT 
	  )
	INSERT INTO #mnpt_TPREEWkEmptemp
	--휴일승인테이블
	SELECT A.RepWkDate AS WkDate,
		   DATENAME(dw, A.RepWkDate) AS Day,
		   (SELECT HolidayName FROM _TCOMCalendarHolidayPRWkUnit WHERE CompanySeq = @CompanySeq AND SMHolidayType = 1051003 AND Solar = A.RepWkDate) AS HolidayKindName,
		   A.StartTime AS BegTime,
		   A.EndTime AS EndTime,
		   CONVERT(NVARCHAR(5),0.0) AS WkOT,
		   CONVERT(NVARCHAR(5),0.0) AS WkDay2,
		   CONVERT(NCHAR(5),CONVERT(DECIMAL(19,2),SUM(CASE WHEN B.WkItemSeq = 40 THEN D.DtCnt ELSE 0 END))) AS WkHoliday2,
		   --CONVERT(NVARCHAR(5),0.0) AS WkHoliday2,
		   CONVERT(NVARCHAR(5),0.0) AS EmpEx2,
		   CONVERT(NCHAR(5),CONVERT(DECIMAL(19,2),SUM(CASE WHEN B.WkItemSeq = 40 THEN D.DtCnt ELSE 0 END))) AS EmpHoliday2,
		   CONVERT(NVARCHAR(5),0.0) AS EmpNight2,
		   0 AS BreakFast2,
		   0 AS Lunch2,
		   0 AS Dinner2,
		   0 AS NightMeal2,
		   0 AS EarlyWork2,
		   0 AS NightWork2,
		   D.EmpSeq AS Seq2, 
           1 AS Sort 
	 --INTO #mnpt_TPREEWkEmpRepWk
	 FROM mnpt_TPREEWkEmpRepWk AS A WITH(NOLOCK)
                     JOIN #BIZ_IN_DataBlock1         AS Q ON ( Q.Seq = A.EmpSeq ) 
          LEFT OUTER JOIN _TPRWkItem AS B WITH(NOLOCK) 
                       ON (A.CompanySeq = B.CompanySeq
                      AND A.WkItemSeq  = B.WkItemSeq)
          LEFT OUTER JOIN _TPRWkEmpRepWk_Confirm AS C WITH(NOLOCK)
                       ON (A.CompanySeq = C.CompanySeq
                      AND A.EmpSeq     = C.CfmSeq
                      AND A.RepWkSeq   = C.CfmSerl) 
		  LEFT OUTER JOIN _TPRWkEmpDd AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
		  			  AND A.EmpSeq = D.EmpSeq
		  			  AND A.RepWkDate = D.WkDate
		  			  AND A.WkItemSeq = D.WkItemSeq
		  --LEFT OUTER JOIN _fnAdmEmpOrdRetResidIdEmp(@CompanySeq, '', ISNULL(Q.Seq,0)) AS E ON A.EmpSeq = E.EmpSeq
		  --LEFT OUTER JOIN _TPRBasEmpAmt AS G ON A.CompanySeq = G.CompanySeq
				--	  AND A.EmpSeq = G.EmpSeq
				--	  AND G.ItemSeq = (SELECT EnvValue FROM MNPT_TCOMENV WHERE CompanySeq = @CompanySeq AND EnvSeq = 37)
				--	  AND A.RepWkDate BETWEEN BegDate AND EndDate

	WHERE A.CompanySeq = @CompanySeq
      --AND ((A.EmpSeq = @Seq))
      --AND EXISTS (SELECT 1 FROM #Temp WHERE Seq = A.EmpSeq)
      AND (A.RepWkDate BETWEEN @WkDateFr AND @WkDateTo)
      AND ISNULL(C.CfmCode,0) = 1
      AND @HolidayIN = 1
    GROUP BY A.RepWkDate, D.EmpSeq, A.StartTime , A.EndTime

    --return 

	DECLARE @BreakFastAmt	DECIMAL(19, 5),	--조식식대
			@LunchAmt		DECIMAL(19, 5),	--중식식대
			@DinnerAmt		DECIMAL(19, 5),	--석식식대
			@NightMealAmt	DECIMAL(19, 5),	--야식식대
			@EarlyWorkAmt	DECIMAL(19, 5),	--조출교통비
			@NightWorkAmt	DECIMAL(19, 5)	--심야교통비
    
	--조식식대
	SELECT @BreakFastAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596001
	   AND Serl			= 1000001

	--중식식대
	SELECT @LunchAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596002
	   AND Serl			= 1000001

	--석식식대
	SELECT @DinnerAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596003
	   AND Serl			= 1000001

	--야식식대
	SELECT @NightMealAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596004
	   AND Serl			= 1000001

	--조출교통비
	SELECT @EarlyWorkAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596005
	   AND Serl			= 1000001

	--심야교통비
	SELECT @NightWorkAmt	= ISNULL(ValueText, 0)
	  FROM _TDAUMinorValue WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND MinorSeq		= 1016596006
	   AND Serl			= 1000001


	INSERT INTO #mnpt_TPREEWkEmptemp
	SELECT B.WKDate																	AS WkDate,					--작업일
		   DATENAME(DW, B.WKDate)													AS Day,						--요일
		   ISNULL(C.HolidayName, '')												AS HolidayKindName,			--공휴구분
		   A.CloseStratDTCnt														AS BegTime,					--마감출근시간
		   A.CloseEndDTCnt															AS EndTime,					--마감퇴근시간
		   CONVERT(DECIMAL(19, 2), ISNULL(WkOT,	0)			)						AS WkOT,					--기본OT	(기본OT시간)
		   CONVERT(DECIMAL(19, 2), ISNULL(WkDay2,	0)		)						AS WkDay2,					--평일(평일연장근로시간, 평일야간근로시간)	
		   CONVERT(DECIMAL(19, 2), ISNULL(WkHoliday2,	0)	)						AS WkHoliday2,				--휴일(휴일근로시간)
		   CONVERT(DECIMAL(19, 2), ISNULL(EmpEx2,	0)		)						AS EmpEx2,					--연장(연장근로시간)	
		   CONVERT(DECIMAL(19, 2), ISNULL(EmpHoliday2,	0)	)						AS EmpHoliday2,				--휴일(휴일근로시간)	
		   CONVERT(DECIMAL(19, 2), ISNULL(EmpNight2	,	0)	)						AS EmpNight2,				--야간(야간근로시간)	
		   A.IsCfmBreakFast * @BreakFastAmt											AS BreakFast2,				--조식식대
		   A.IsCfmLunch		* @LunchAmt												AS Lunch2,					--중식식대
		   A.IsCfmDinner	* @DinnerAmt											AS Dinner2,					--석식식대
		   A.IsCfmNightMeal	* @NightMealAmt											AS NightMeal2,				--야식식대
		   A.IsCfmEarlyWork * @EarlyWorkAmt											AS EarlyWork2,				--조출교통비
		   A.IsCfmNightWork	* @NightWorkAmt											AS NightWork2,				--심야교통비
		   A.EmpSeq																	AS Seq2, 
           2 AS Sort 
	  --INTO #mnpt_TPREEWkEmpOTTimeApp
	  FROM mnpt_TPREEWkEmpOTTimeApp AS A
		   INNER JOIN (
						SELECT Z.EmpSeq,
							   Z.AppSeq,
							   Z.WKDate,
							   SUM(CASE WHEN Z.WKItemSeq = 48			AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS WkOT,			--기본OT	(기본OT시간)
							   SUM(CASE WHEN Z.WKItemSeq IN (22, 23)	AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS WkDay2,		--평일(평일연장근로시간, 평일야간근로시간)	
							   SUM(CASE WHEN Z.WKItemSeq = 40			AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS WkHoliday2,	--휴일(휴일근로시간)
							   SUM(CASE WHEN Z.WKItemSeq = 37			AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS EmpEx2,		--연장(연장근로시간)	
							   SUM(CASE WHEN Z.WKItemSeq = 40			AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS EmpHoliday2,	--휴일(휴일근로시간)	
							   SUM(CASE WHEN Z.WKItemSeq = 38			AND ISNULL(Z.DTCnt, 0) > 0 THEN DTCnt ELSE 0 END) AS EmpNight2		--야간(야간근로시간)	
						  FROM _TPRWkEmpOTTimeDtl AS Z WITH(NOLOCK)
						 WHERE Z.CompanySeq	= @CompanySeq	
						   AND Z.WKDate		BETWEEN  @WkDateFr AND @WkDateTo  
						   --AND Z.EmpSeq		= @Seq
                           AND EXISTS (SELECT 1 FROM #BIZ_IN_DataBlock1 WHERE Seq = Z.EmpSeq)
						 GROUP BY Z.EmpSeq, Z.AppSeq, Z.WKDate
					) AS B
				   ON B.EmpSeq	= A.EmpSeq
			 	  AND B.AppSeq	= A.AppSeq
		   LEFT  JOIN _TCOMCalendarHolidayPRWkUnit AS C WITH(NOLOCK)
				   ON C.CompanySeq		= @CompanySeq
				  AND C.Solar			= B.WkDate
				  AND C.SMHolidayType	= 1051003	--휴일
				  AND C.Unit			= 1			--근태작업군 하드코딩



	INSERT INTO #mnpt_TPREEWkEmptemp (
		WkDate			,
		Day				,
		HolidayKindName	,
		BegTime			,
		EndTime			,
		WkOT			,
		WkDay2			,
		WkHoliday2		,
		EmpEx2			,
		EmpHoliday2		,
		EmpNight2		,
		BreakFast2		,
		Lunch2			,
		Dinner2			,
		NightMeal2		,
		EarlyWork2		,
		NightWork2		,
		Seq2			, 
        Sort 
	)
	SELECT	
		'',
		'',
		A.TitleName,
		'',
		'',
		0,
		CONVERT(DECIMAL(19, 2), ISNULL(WorkTime1,	0)			),
		CONVERT(DECIMAL(19, 2), ISNULL(WorkTime2,	0)			),
		CONVERT(DECIMAL(19, 2), ISNULL(WorkTime3,	0)			),
		CONVERT(DECIMAL(19, 2), ISNULL(WorkTime4,	0)			),
		CONVERT(DECIMAL(19, 2), ISNULL(WorkTime5,	0)			),
		0,
		0,
		0,
		0,
		0,
		0,
		A.EmpSeq, 
        3 AS Sort 
	  FROM mnpt_TPREEWkEmpOTTSum AS A WITH(NOLOCK)
	 WHERE A.CompanySeq	= @CompanySeq
	   AND EXISTS (SELECT 1 FROM #BIZ_IN_DataBlock1 WHERE Seq = A.EmpSeq ) 
	   AND A.StdYM		= @StdYM

	--select @StdYM return


	--select * from mnpt_TPREEWkEmpOTTSum  order by TitleName desc




    -----------------------------------------------master 

	CREATE TABLE #Result (
		Seq				INT,
		EmpName			NVARCHAR(100),
		EmpID			NVARCHAR(100),
		DeptName		NVARCHAR(100),
		UMJoName		NVARCHAR(100),
		WkDay			NVARCHAR(5), --DECIMAL(19, 2),
		WkHoliday		NVARCHAR(5), --DECIMAL(19, 2),
		EmpEx			NVARCHAR(5), --DECIMAL(19, 2),
		EmpHoliday		NVARCHAR(5), --DECIMAL(19, 2),
		EmpNight		NVARCHAR(5), --DECIMAL(19, 2),
		ExNorDay		NVARCHAR(5), --DECIMAL(19, 2),
		ExNorHoliday	NVARCHAR(5), --DECIMAL(19, 2),
		ExNorEx			NVARCHAR(5), --DECIMAL(19, 2),
		ExTimeHoliday	NVARCHAR(5), --DECIMAL(19, 2),
		ExTimeNight		NVARCHAR(5), --DECIMAL(19, 2),
		ExTimeMoney		DECIMAL(19, 5),
		ExNorDMoney		DECIMAL(19, 5),
		ExNorHMoney		DECIMAL(19, 5),
		ExTimeEMoney	DECIMAL(19, 5),
		ExTimeHMoney	DECIMAL(19, 5),
		ExTimeNMoney	DECIMAL(19, 5),
		ExSum			DECIMAL(19, 5),
		BreakFast		DECIMAL(19, 5),
		Lunch			DECIMAL(19, 5),
		Dinner			DECIMAL(19, 5),
		NightMeal		DECIMAL(19, 5),
		EarlyWork		DECIMAL(19, 5),
		NightWork		DECIMAL(19, 5),
		BenefitSum		DECIMAL(19, 5)
	)


	INSERT INTO #Result
	--휴일승인테이블
   SELECT  A.EmpSeq AS Seq,
		   E.EmpName AS EmpName,
		   E.EmpID AS EmpID,
		   E.DeptName AS DeptName,
		   E.UMJoName AS UMJoName,
		   CONVERT(NVARCHAR(5),0.0) AS WkDay,
		   CONVERT(NCHAR(5),CONVERT(DECIMAL(19,2),SUM(CASE WHEN B.WkItemSeq = 37 THEN D.DtCnt ELSE 0 END))) AS WkHoliday,
		   --CONVERT(NVARCHAR(5),0.0) AS WkHoliday,
		   CONVERT(NVARCHAR(5),0.0) AS EmpEx,
		   CONVERT(NCHAR(5),CONVERT(DECIMAL(19,2),SUM(CASE WHEN B.WkItemSeq = 37 THEN D.DtCnt ELSE 0 END))) AS EmpHoliday,
		   --SUM(CASE WHEN F.WkItemSName = '휴일' THEN D.DtCnt ELSE 0 END) AS EmpHoliday,
		   CONVERT(NVARCHAR(5),0.0) AS EmpNight,
		   CONVERT(NVARCHAR(5),0.0) AS ExNorDay,
		   CONVERT(NVARCHAR(5),0.0) AS ExNorHoliday,
		   --CONVERT(NCHAR(5),CONVERT(DECIMAL(19,2),SUM(CASE WHEN B.WkItemSName = '초과평일' THEN D.DtCnt ELSE 0 END))) AS ExNorHoliday,
		   --SUM(CASE WHEN F.WkItemSName = '초과휴일' THEN D.DtCnt ELSE 0 END) AS ExNorHoliday,
		   CONVERT(NVARCHAR(5),0.0) AS ExNorEx,
		   CONVERT(NVARCHAR(5),0.0) AS ExTimeHoliday,
		   CONVERT(NVARCHAR(5),0.0) AS ExTimeNight,
		   --(SELECT SUM(D.DtCnt) WHERE C.WkItemSeq = 33) AS WkDay,
		   0 AS ExTimeMoney,
		   0 AS ExNorDMoney,
		   A.WkMoney AS ExNorHMoney,
		   --SUM(CASE WHEN B.WkItemSName = '초과휴일' THEN D.DtCnt * G.Amt ELSE 0 END) AS ExNorHMoney,
		   0 AS ExTimeEMoney,
		   0 AS ExTimeHMoney,
		   0 AS ExTimeNMoney,
		   0 AS ExSum,
		   0 AS BreakFast,
		   0 AS Lunch,
		   0 AS Dinner,
		   0 AS NightMeal,
		   0 AS EarlyWork,
		   0 AS NightWork,
		   0 AS BenefitSum
     FROM mnpt_TPREEWkEmpRepWk AS A WITH(NOLOCK)
                     JOIN #BIZ_IN_DataBlock1         AS Q ON ( Q.Seq = A.EmpSeq ) 
          LEFT OUTER JOIN _TPRWkItem AS B WITH(NOLOCK) 
                          ON (A.CompanySeq = B.CompanySeq
                          AND A.WkItemSeq  = B.WkItemSeq)
          LEFT OUTER JOIN _TPRWkEmpRepWk_Confirm AS C WITH(NOLOCK)
                          ON (A.CompanySeq = C.CompanySeq
                          AND A.EmpSeq     = C.CfmSeq
                          AND A.RepWkSeq   = C.CfmSerl) 
	  LEFT OUTER JOIN _TPRWkEmpDd AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq
												   AND A.EmpSeq = D.EmpSeq
												   AND A.RepWkDate = D.WkDate
												   AND A.WkItemSeq = D.WkItemSeq
		  LEFT OUTER JOIN _fnAdmEmpOrdRetResidIdEmp(@CompanySeq, '', 0) AS E ON A.EmpSeq = E.EmpSeq
	  LEFT OUTER JOIN _TPRBasEmpAmt AS G ON A.CompanySeq = G.CompanySeq
										AND A.EmpSeq = G.EmpSeq
										AND G.ItemSeq = (SELECT EnvValue FROM MNPT_TCOMENV WHERE CompanySeq = @CompanySeq AND EnvSeq = 37)
										AND A.RepWkDate BETWEEN BegDate AND EndDate
    WHERE A.CompanySeq = @CompanySeq
	  AND (A.RepWkDate BETWEEN @WkDateFr AND @WkDateTo)
	  AND ISNULL(C.CfmCode,0) = 1
	  AND @HolidayIN = 1
	 GROUP BY A.EmpSeq,
		      E.EmpName,
		      E.EmpID,
		      E.DeptName,
		      E.UMJoName,
			  A.WkMoney
    
    
	DECLARE @ItemSeq INT

	--<근태>초과근로수당용 시급 급여항목
	SELECT @ItemSeq = EnvValue
	  FROM mnpt_TCOMEnv WITH(NOLOCK)
	 WHERE CompanySeq	= @CompanySeq
	   AND EnvSeq		= 37
    
	SELECT Z.EmpSeq			AS EmpSeq,
		   B.EmpName		AS EmpName,
		   B.EmpID			AS EmpID,
		   B.DeptName		AS DeptName,
		   B.UMJoName		AS UMJoName,
		   D.Amt	,
		   E.IsCfmBreakFast * @BreakFastAmt		AS BreakFast,
		   E.IsCfmLunch		* @LunchAmt			AS Lunch,
		   E.IsCfmDinner	* @DinnerAmt		AS Dinner,
		   E.IsCfmNightMeal	* @NightMealAmt		AS NightMeal,
		   E.IsCfmEarlyWork	* @EarlyWorkAmt		AS EarlyWork,
		   E.IsCfmNightWork	* @NightWorkAmt		AS NightWork,
		   CONVERT(DECIMAL(19, 2), 0)			AS BenefitSum,
		   CONVERT(DECIMAL(19, 2), 0)			AS WkDay,			--작업시간 - 평일OT시간		
		   CONVERT(DECIMAL(19, 2), 0)			AS WkHoliday,		--작업시간 - 휴일근로시간
		   CONVERT(DECIMAL(19, 2), 0)			AS EmpEx,			--근로내용구분 - 연장근로시간
		   CONVERT(DECIMAL(19, 2), 0)			AS EmpHoliday,		--근로내용구분 - 휴일근로시간
		   CONVERT(DECIMAL(19, 2), 0)			AS EmpNight,		--근로내용구분 - 야간근로시간
		   CONVERT(DECIMAL(19, 2), 0)			AS ExNorDay,		--초과시간 - 기본근로시간 - 초과평일시간
		   CONVERT(DECIMAL(19, 2), 0)			AS ExNorHoliday,	--초과시간 - 기본근로시간 - 초과휴일시간
		   CONVERT(DECIMAL(19, 2), 0)			AS ExNorEx,			--초과시간 - 시간외근로시간 - 초과연장시간
		   CONVERT(DECIMAL(19, 2), 0)			AS ExTimeHoliday,	--초과시간 - 시간외근로시간 - 초과휴일시간
		   CONVERT(DECIMAL(19, 2), 0)			AS ExTimeNight,		--초과시간 - 시간외근로시간 - 초과야간시간
		   CONVERT(DECIMAL(19, 5), 0)			AS ExNorDMoney,		--기본수당 - 초과평일시간 * 시급
		   CONVERT(DECIMAL(19, 5), 0)			AS ExNorHMoney,		--기본수당 - 초과휴일시간 * 시급
		   CONVERT(DECIMAL(19, 5), 0)			AS ExTimeEMoney,	--시간외근로수당 - 초과연장시간 * 시급 * 0.5
		   CONVERT(DECIMAL(19, 5), 0)			AS ExTimeHMoney,	--시간외근로수당 - 초과휴일시간 * 시급 * 0.5
		   CONVERT(DECIMAL(19, 5), 0)			AS ExTimeNMoney,	--시간외근로수당 - 초과야간시간 * 시급 * 0.5
		   CONVERT(DECIMAL(19, 5), 0)			AS ExSum,
		   A.StdYM								AS StdYM
	  INTO #tmpResult
	  FROM (
				SELECT EmpSeq
				  FROM _TPRWkEmpOTTimeDtl
				 WHERE CompanySeq	= @CompanySeq
				   AND WkDate		BETWEEN @WkDateFr AND @WkDateTo
				 GROUP BY EmpSeq
			) AS Z 
		   LEFT  JOIN mnpt_TPREEWkEmpOTTSum AS A WITH(NOLOCK)
				   ON Z.EmpSeq	= A.EmpSeq
				  AND A.StdYM	= @StdYM
                 JOIN #BIZ_IN_DataBlock1         AS Q ON ( Q.Seq = A.EmpSeq ) 
		     LEFT  JOIN _fnAdmEmpOrdRetResidIdEmp(@CompanySeq, '', 0) AS B 
				   ON B.EmpSeq = Z.EmpSeq
		   LEFT  JOIN _TPRBasEmpAmt AS D WITH(NOLOCK)
				   ON D.CompanySeq	= @CompanySeq
				  AND D.EmpSeq		= Z.EmpSeq
				  AND D.ItemSeq		= @ItemSeq
				  AND @WkDateTo BETWEEN D.BegDate AND D.EndDate
		   LEFT  JOIN (
						SELECT EmpSeq ,
							   SUM(CASE WHEN IsCfmBreakFast = '1' THEN 1 ELSE 0 END)		AS  IsCfmBreakFast,
							   SUM(CASE WHEN IsCfmLunch = '1' THEN 1 ELSE 0 END)			AS  IsCfmLunch,
							   SUM(CASE WHEN IsCfmDinner = '1' THEN 1 ELSE 0 END)			AS  IsCfmDinner,
							   SUM(CASE WHEN IsCfmNightMeal = '1' THEN 1 ELSE 0 END)		AS  IsCfmNightMeal,
							   SUM(CASE WHEN IsCfmEarlyWork = '1' THEN 1 ELSE 0 END)		AS  IsCfmEarlyWork,
							   SUM(CASE WHEN IsCfmNightWork = '1' THEN 1 ELSE 0 END)		AS  IsCfmNightWork
						  FROM mnpt_TPREEWkEmpOTTimeApp AS Z
						 WHERE Z.CompanySeq		= @CompanySeq
						   AND Z.IsClose		= '1'
						   AND EXISTS (
										SELECT 1
										  FROM _TPRWkEmpOTTimeDtl
										 WHERE CompanySeq	= @CompanySeq
										   AND WkDate		BETWEEN @WkDateFr AND @WkDateTo
										   AND AppSeq		= Z.AppSeq
										   AND EmpSeq		= Z.EmpSeq 
										   
									)
						 GROUP BY EmpSeq
					) AS E
				   ON E.EmpSeq	= Z.EmpSeq
	 GROUP BY 
		Z.EmpSeq	,	
		B.EmpName	,
		B.EmpID	,	
		B.DeptName	,
		B.UMJoName	,
		D.Amt		,
	    E.IsCfmBreakFast,
	    E.IsCfmLunch,
	    E.IsCfmDinner,
	    E.IsCfmNightMeal,
	    E.IsCfmEarlyWork,
	    E.IsCfmNightWork,
		A.StdYM

        --select * from #tmpResult
        --return 

	UPDATE #tmpResult
	   SET WkDay			= CONVERT(DECIMAL(19,2),ISNULL(B.WorkTime1, 0)),		--작업시간 - 평일OT시간		
		   WkHoliday		= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime2, 0)),		--작업시간 - 휴일근로시간
		   EmpEx			= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime3, 0)),		--근로내용구분 - 연장근로시간
		   EmpHoliday		= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime4, 0)),		--근로내용구분 - 휴일근로시간	
		   EmpNight			= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime5, 0)),		--근로내용구분 - 야간근로시간	
		   ExNorDay			= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime1, 0)),		--초과시간 - 기본근로시간 - 초과평일시간
		   ExNorHoliday		= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime2, 0)),		--초과시간 - 기본근로시간 - 초과휴일시간
		   ExNorEx			= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime3, 0)),		--초과시간 - 시간외근로시간 - 초과연장시간
		   ExTimeHoliday	= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime4, 0)),		--초과시간 - 시간외근로시간 - 초과휴일시간
		   ExTimeNight		= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime5, 0)),		--초과시간 - 시간외근로시간 - 초과야간시간
		   ExNorDMoney		= ROUND(ISNULL(D.WorkTime1, 0) * A.Amt, -1),			--기본수당 - 초과평일시간 * 시급
		   ExNorHMoney		= ROUND(ISNULL(D.WorkTime2, 0) * A.Amt, -1),			--기본수당 - 초과휴일시간 * 시급
		   ExTimeEMoney		= ROUND(ISNULL(D.WorkTime3, 0) * A.Amt * 0.5, -1),		--시간외근로수당 - 초과연장시간 * 시급 * 0.5
		   ExTimeHMoney		= ROUND(ISNULL(D.WorkTime4, 0) * A.Amt * 0.5, -1),		--시간외근로수당 - 초과휴일시간 * 시급 * 0.5
		   ExTimeNMoney		= ROUND(ISNULL(D.WorkTime5, 0) * A.Amt * 0.5, -1)		--시간외근로수당 - 초과야간시간 * 시급 * 0.5
	  FROM #tmpResult AS A
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime1) AS WorkTime1	--평일계 + 기본OT
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	<> '3. 초과시간'
						 GROUP BY EmpSeq
					) AS B
				   ON B.EmpSeq	= A.EmpSeq
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime2) AS WorkTime2,	--휴일 계
							   SUM(WorkTime3) AS WorkTime3,	--연장 계
							   SUM(WorkTime4) AS WorkTime4,	--휴일2 계
							   SUM(WorkTime5) AS WorkTime5	--야간 계
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	= '2. 계'
						 GROUP BY A.EmpSeq
					) AS C
				   ON C.EmpSeq	= A.EmpSeq
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime1) AS WorkTime1,	--평일 초과
							   SUM(WorkTime2) AS WorkTime2,	--휴일 초과
							   SUM(WorkTime3) AS WorkTime3,	--연장 초과
							   SUM(WorkTime4) AS WorkTime4,	--휴일2 초과
							   SUM(WorkTime5) AS WorkTime5	--야간 초과
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	= '3. 초과시간'
						 GROUP BY A.EmpSeq
					) AS D
				   ON C.EmpSeq	= A.EmpSeq
	UPDATE #tmpResult
	   SET WkDay			= CONVERT(DECIMAL(19,2),ISNULL(B.WorkTime1, 0)),		--작업시간 - 평일OT시간		
		   WkHoliday		= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime2, 0)),		--작업시간 - 휴일근로시간
		   EmpEx			= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime3, 0)),		--근로내용구분 - 연장근로시간
		   EmpHoliday		= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime4, 0)),		--근로내용구분 - 휴일근로시간	
		   EmpNight			= CONVERT(DECIMAL(19,2),ISNULL(C.WorkTime5, 0)),		--근로내용구분 - 야간근로시간	
		   ExNorDay			= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime1, 0)),		--초과시간 - 기본근로시간 - 초과평일시간
		   ExNorHoliday		= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime2, 0)),		--초과시간 - 기본근로시간 - 초과휴일시간
		   ExNorEx			= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime3, 0)),		--초과시간 - 시간외근로시간 - 초과연장시간
		   ExTimeHoliday	= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime4, 0)),		--초과시간 - 시간외근로시간 - 초과휴일시간
		   ExTimeNight		= CONVERT(DECIMAL(19,2),ISNULL(D.WorkTime5, 0)),		--초과시간 - 시간외근로시간 - 초과야간시간
		   ExNorDMoney		= ROUND(ISNULL(D.WorkTime1, 0) * A.Amt, -1),			--기본수당 - 초과평일시간 * 시급
		   ExNorHMoney		= ROUND(ISNULL(D.WorkTime2, 0) * A.Amt, -1),			--기본수당 - 초과휴일시간 * 시급
		   ExTimeEMoney		= ROUND(ISNULL(D.WorkTime3, 0) * A.Amt * 0.5, -1),		--시간외근로수당 - 초과연장시간 * 시급 * 0.5
		   ExTimeHMoney		= ROUND(ISNULL(D.WorkTime4, 0) * A.Amt * 0.5, -1),		--시간외근로수당 - 초과휴일시간 * 시급 * 0.5
		   ExTimeNMoney		= ROUND(ISNULL(D.WorkTime5, 0) * A.Amt * 0.5, -1)		--시간외근로수당 - 초과야간시간 * 시급 * 0.5
	  FROM #tmpResult AS A
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime1) AS WorkTime1	--평일계 + 기본OT
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	<> '3. 초과시간'
						 GROUP BY EmpSeq
					) AS B
				   ON B.EmpSeq	= A.EmpSeq
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime2) AS WorkTime2,	--휴일 계
							   SUM(WorkTime3) AS WorkTime3,	--연장 계
							   SUM(WorkTime4) AS WorkTime4,	--휴일2 계
							   SUM(WorkTime5) AS WorkTime5	--야간 계
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	= '2. 계'
						 GROUP BY A.EmpSeq
					) AS C
				   ON C.EmpSeq	= A.EmpSeq
		   LEFT   JOIN (
						SELECT EmpSeq, 
							   SUM(WorkTime1) AS WorkTime1,	--평일 초과
							   SUM(WorkTime2) AS WorkTime2,	--휴일 초과
							   SUM(WorkTime3) AS WorkTime3,	--연장 초과
							   SUM(WorkTime4) AS WorkTime4,	--휴일2 초과
							   SUM(WorkTime5) AS WorkTime5	--야간 초과
						  FROM mnpt_TPREEWkEmpOTTSum    AS A WITH(NOLOCK)
                          JOIN #BIZ_IN_DataBlock1       AS Q ON ( Q.Seq = A.EmpSeq ) 
						 WHERE A.CompanySeq	= @CompanySeq
						   AND A.StdYM		= @StdYM
						   --AND (@EmpSeq		= 0 OR A.EmpSeq = @EmpSeq)
						   AND A.TitleName	= '3. 초과시간'
						 GROUP BY A.EmpSeq
					) AS D
				   ON D.EmpSeq	= A.EmpSeq
				
				

	--수당 & 복지수당 Sum값 업데이트.
	UPDATE #tmpResult  
	   SET BenefitSum	= BreakFast + Lunch + Dinner + NightMeal + EarlyWork + NightWork,
		   ExSum		= ExNorDMoney + ExNorHMoney + ExTimeEMoney + ExTimeHMoney + ExTimeNMoney


	INSERT INTO #Result (
		Seq				,
		EmpName			,
		EmpID			,
		DeptName		,
		UMJoName		,
		WkDay			,
		WkHoliday		,
		EmpEx			,
		EmpHoliday		,
		EmpNight		,
		ExNorDay		,
		ExNorHoliday	,
		ExNorEx			,
		ExTimeHoliday	,
		ExTimeNight		,
		ExTimeMoney		,
		ExNorDMoney		,
		ExNorHMoney		,
		ExTimeEMoney	,
		ExTimeHMoney	,
		ExTimeNMoney	,
		ExSum			,
		BreakFast		,
		Lunch			,
		Dinner			,
		NightMeal		,
		EarlyWork		,
		NightWork		,
		BenefitSum		
	)
	SELECT
		EmpSeq			,
		EmpName			,
		EmpID			,
		DeptName		,
		UMJoName		,
		WkDay			,
		WkHoliday		,
		EmpEx			,
		EmpHoliday		,
		EmpNight		,
		ExNorDay		,
		ExNorHoliday	,
		ExNorEx			,
		ExTimeHoliday	,
		ExTimeNight		,
		Amt		,
		ExNorDMoney		,
		ExNorHMoney		,
		ExTimeEMoney	,
		ExTimeHMoney	,
		ExTimeNMoney	,
		ExSum			,
		BreakFast		,
		Lunch			,
		Dinner			,
		NightMeal		,
		EarlyWork		,
		NightWork		,
		BenefitSum		
	  FROM #tmpResult

      --select * From #Result
      --return 


    -- 최종조회 
    SELECT  B.Seq 
           ,B.EmpName			
           ,B.EmpID			
           ,B.DeptName		
           ,B.UMJoName		
           ,B.WkDay			
           ,B.WkHoliday		
           ,B.EmpEx			
           ,B.EmpHoliday		
           ,B.EmpNight		
           ,B.ExNorDay		
           ,B.ExNorHoliday	
           ,B.ExNorEx			
           ,B.ExTimeHoliday	
           ,B.ExTimeNight		
           ,B.ExTimeMoney		
           ,B.ExNorDMoney		
           ,B.ExNorHMoney		
           ,B.ExTimeEMoney	
           ,B.ExTimeHMoney	
           ,B.ExTimeNMoney	
           ,B.ExSum			
           ,B.BreakFast		
           ,B.Lunch			
           ,B.Dinner			
           ,B.NightMeal		
           ,B.EarlyWork		
           ,B.NightWork		
           ,B.BenefitSum		
           ,A.WkDate			
           ,A.Day				
           ,A.HolidayKindName	
           ,A.BegTime			
           ,A.EndTime			
           ,A.WkOT			
           ,A.WkDay2			
           ,A.WkHoliday2		
           ,A.EmpEx2			
           ,A.EmpHoliday2		
           ,A.EmpNight2		
           ,A.BreakFast2		
           ,A.Lunch2			
           ,A.Dinner2			
           ,A.NightMeal2		
           ,A.EarlyWork2		
           ,A.NightWork2		
           ,A.Seq2			
           ,A.Sort       
      FROM #mnpt_TPREEWkEmptemp AS A 
      LEFT OUTER JOIN #Result   AS B ON ( B.Seq = A.Seq2 ) 
     ORDER BY A.Seq2, A.Sort, A.WkDate
    
    RETURN     

go
