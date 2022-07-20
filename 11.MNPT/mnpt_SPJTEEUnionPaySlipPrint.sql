IF OBJECT_ID('mnpt_SPJTEEUnionPaySlipPrint') IS NOT NULL 
    DROP PROC mnpt_SPJTEEUnionPaySlipPrint
GO 

-- v2018.01.15 

-- 노조전표(출력물) by이재천 
 CREATE PROC mnpt_SPJTEEUnionPaySlipPrint  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    
    ---------------------------------------------------------------------------------------------------------
    -- 하역 노임
    ---------------------------------------------------------------------------------------------------------
	SELECT ROW_NUMBER() OVER (ORDER BY UnionPaySeq) AS IDX_NO, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl, 
           --H.OutDateTime,
           H.IFShipCode + '-' + STUFF(H.ShipSerlNo,5,0,'-') AS ShipSerlNo, 
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTeam,
		   B.BizUnitName,
		   A.OutDate,
		   D.EnShipName,
		   E.PJTTypeName,
		   G.MinorName											AS UMLoadTypeName,
		   DATENAME(WEEKDAY, A.WorkDate)						AS WorkDay,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName,
		   A.UpTodayQty AS TodayQty,
		   A.UpTodayMTWeight,
           A.UpSaturday,
           A.UpHoliday,
           A.UpRain,
           A.UpDanger,
           A.UpNight, 
		   A.Saturday,
		   A.Holiday,
		   A.Rain,
		   A.Danger,
           A.Night, 
		   A.Price,
		   A.Amt,
		   A.IsSaturday,
		   A.IsHoliday,
		   A.IsRain,
		   A.IsDanger,
		   A.IsNight,
		   A.SumAmt, 
           CONVERT(DECIMAL(19,5),0) AS SaturdayRate, 
           CONVERT(DECIMAL(19,5),0) AS HolidayRate, 
           CONVERT(DECIMAL(19,5),0) AS RainRate, 
           CONVERT(DECIMAL(19,5),0) AS DangerRate, 
           CONVERT(DECIMAL(19,5),0) AS NightRate, 
           A.MealCnt, 
           A.MealPrice, 
           A.MealAmt 
      INTO #BaseData 
	  FROM mnpt_TPJTUnionPayDaily           AS A 
      LEFT OUTER JOIN _TDABizUnit           AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS D ON ( D.CompanySeq = @CompanySeq AND D.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TPJTType             AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTTypeSeq = A.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMLoadType ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = A.ShipSeq AND H.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq	= @CompanySeq	  
       AND EXISTS (SELECT 1 
                     FROM #BIZ_IN_DataBlock1 
                    WHERE PJTSeq = A.PJTSeq 
                      AND ShipSeq = A.ShipSeq 
                      AND ShipSerl = A.ShipSerl 
                      AND UMLoadType = A.UMLoadType 
                  )
	 ORDER BY BizUnitName, A.OutDate, WorkDate, UMWorkTEam
    

    CREATE TABLE #BaseData_DataNo 
    ( 
        DataNo      INT IDENTITY, 
        BizUnit     INT, 
        ShipSeq     INT, 
        ShipSerl    INT
    ) 
    INSERT INTO #BaseData_DataNo ( BizUnit, ShipSeq, ShipSerl ) 
    SELECT DISTINCT 
           BizUnit, 
           ShipSeq, 
           ShipSerl
      FROM #BaseData    
    
    --SELECT * FROM #BaseData_DataNo

    --return 
    
    --할증금액 계산
	CREATE TABLE #ExtraPrice 
    (
        PJTTypeSeq      INT,
        UMLoadType      INT,
        SrtDate         NCHAR(8),
        EndDate         NCHAR(8),
        TitleSeq        INT,
        Rate            DECIMAL(19, 5)
	)
    INSERT INTO #ExtraPrice 
    (
        PJTTypeSeq, UMLoadType, SrtDate, EndDate, TitleSeq, 
        Rate
	)
	SELECT PJTTypeSeq, UMLoadWaySeq, A.StdDate, '', C.TitleSeq, 
           C.Value
	  FROM mnpt_TPJTUnionExtra AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTUnionExtraItem AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND b.StdSeq		= A.StdSeq
		   INNER JOIN mnpt_TPJTUnionExtraValue AS C WITH(NOLOCK)
				   ON C.CompanySeq	= B.CompanySeq
				  AND C.StdSeq		= B.StdSeq
				  AND C.StdSerl		= B.StdSerl
	  WHERE A.CompanySeq	= @CompanySeq
    

	/*-----------------------------------------------------------------------------
	적용시작일 적용종료일 날짜계산
	------------------------------------------------------------------------------*/
	--시작, 종료일 재구성
	UPDATE #ExtraPrice
	   SET EndDate  = ( SELECT ISNULL(CONVERT(NCHAR(8), DATEADD(d, -1, MIN(SrtDate)), 112), '99991231')
						  FROM #ExtraPrice
						 WHERE PJTTypeSeq	= A.PJTTypeSeq
						   AND UMLoadType	= A.UMLoadType
						   AND SrtDate       > A.SrtDate   )
	  FROM #ExtraPrice AS A
    


    -- 할증율 구하기 
    UPDATE A
       SET SaturdayRate = CASE WHEN A.IsSaturday = '1' THEN (CONVERT(DECIMAL(19,5),B.Rate) / 100) ELSE 0 END, 
           HolidayRate  = CASE WHEN A.IsHoliday = '1' THEN (CONVERT(DECIMAL(19,5),C.Rate) / 100) ELSE 0 END, 
           RainRate     = CASE WHEN A.IsRain = '1' THEN (CONVERT(DECIMAL(19,5),D.Rate) / 100) ELSE 0 END, 
           DangerRate   = CASE WHEN A.IsDanger = '1' THEN CONVERT(DECIMAL(19,5),(F.Rate) / 100) ELSE 0 END, 
           NightRate    = CASE WHEN A.IsNight = '1' THEN (CONVERT(DECIMAL(19,5),E.Rate) / 100) ELSE 0 END 
      FROM #BaseData AS A 
      OUTER APPLY ( 
                    SELECT Z.Rate
                      FROM #ExtraPrice AS Z 
                     WHERE Z.TitleSeq = 1015782001
                       AND Z.PJTTypeSeq = A.PJTTypeSeq 
                       AND Z.UMLoadType = A.UMLoadType 
                       AND A.WorkDate BETWEEN Z.SrtDate AND Z.EndDate 
                  ) AS B 
      OUTER APPLY ( 
                    SELECT Z.Rate
                      FROM #ExtraPrice AS Z 
                     WHERE Z.TitleSeq = 1015782002
                       AND Z.PJTTypeSeq = A.PJTTypeSeq 
                       AND Z.UMLoadType = A.UMLoadType 
                       AND A.WorkDate BETWEEN Z.SrtDate AND Z.EndDate 
                  ) AS C 
      OUTER APPLY ( 
                    SELECT Z.Rate
                      FROM #ExtraPrice AS Z 
                     WHERE Z.TitleSeq = 1015782003
                       AND Z.PJTTypeSeq = A.PJTTypeSeq 
                       AND Z.UMLoadType = A.UMLoadType 
                       AND A.WorkDate BETWEEN Z.SrtDate AND Z.EndDate 
                  ) AS D 
      OUTER APPLY ( 
                    SELECT Z.Rate
                      FROM #ExtraPrice AS Z 
                     WHERE Z.TitleSeq = 1015782004
                       AND Z.PJTTypeSeq = A.PJTTypeSeq 
                       AND Z.UMLoadType = A.UMLoadType 
                       AND A.WorkDate BETWEEN Z.SrtDate AND Z.EndDate 
                  ) AS E 
      OUTER APPLY ( 
                    SELECT Z.Rate
                      FROM #ExtraPrice AS Z 
                     WHERE Z.TitleSeq = 1015782005
                       AND Z.PJTTypeSeq = A.PJTTypeSeq 
                       AND Z.UMLoadType = A.UMLoadType 
                       AND A.WorkDate BETWEEN Z.SrtDate AND Z.EndDate 
                  ) AS F 
    
    -- 할증별로 나오도록..
    SELECT A.*, 
           0 AS ExtraRate,
           0 AS UMExtraSeq 
      INTO #Result_DataBlock1
      FROM #BaseData AS A
     WHERE IsSaturday = '0' AND IsHoliday = '0' AND IsRain = '0' AND IsDanger = '0' AND IsNight = '0' 
    UNION ALL 
    SELECT A.*, 
           SaturdayRate AS ExtraRate, 
           1015782001 AS UMExtraSeq
      FROM #BaseData       AS A 
     WHERE IsSaturday = '1' 
    UNION ALL 
    SELECT A.*, 
           HolidayRate AS ExtraRate, 
           1015782002 AS UMExtraSeq
      FROM #BaseData       AS A 
     WHERE IsHoliday = '1' 
    UNION ALL 
    SELECT A.*, 
           RainRate AS ExtraRate, 
           1015782003 AS UMExtraSeq
      FROM #BaseData       AS A 
     WHERE IsRain = '1' 
    UNION ALL 
    SELECT A.*, 
           DangerRate AS ExtraRate, 
           1015782005 AS UMExtraSeq
      FROM #BaseData       AS A 
     WHERE IsDanger = '1' 
    UNION ALL 
    SELECT A.*, 
           NightRate AS ExtraRate, 
           1015782004 AS UMExtraSeq
      FROM #BaseData       AS A 
     WHERE IsNight = '1' 
    
    -- 할증단가에 기본단가가 합쳐지는 건은 1건만 
    SELECT IDX_NO, MIN(UMExtraSeq) AS MINUMExtraSeq 
      INTO #MINUMExtraSeqSub
      FROM #Result_DataBlock1 
     GROUP BY IDX_NO
    
    --select * From #Result_DataBlock1 
    --return 
    
    -- 하역 노임 
    SELECT '하역노임' AS KindName,
           A.ShipSeq, 
           A.ShipSerl, 
           A.BizUnitName,
           A.ShipSerlNo, 
           A.EnShipName, 
           A.OutDate AS OutDate,
           A.WorkDate, 
           A.UMWorkTypeName, 
           A.IDX_NO AS DataKindSeq, 
           CASE WHEN A.UMExtraSeq = 0 THEN A.UMWorkTeamName ELSE B.MinorName END AS UMWorkTeamName, 
           A.PJTTypeName, 
           CASE WHEN C.IDX_NO IS NOT NULL THEN A.TodayQty ELSE 0 END AS TodayQty, 
           A.UMExtraSeq, 
           CASE WHEN A.UMExtraSeq = 1015782001 THEN A.UpSaturday 
                WHEN A.UMExtraSeq = 1015782002 THEN A.UpHoliday 
                WHEN A.UMExtraSeq = 1015782003 THEN A.UpRain 
                WHEN A.UMExtraSeq = 1015782004 THEN A.UpNight
                WHEN A.UMExtraSeq = 1015782005 THEN A.UpDanger 
                ELSE 0
                END AS UpExtraWeight, 
           CASE WHEN C.IDX_NO IS NOT NULL THEN A.UpTodayMTWeight ELSE 0 END AS UpMTWeight,
           CASE WHEN C.IDX_NO IS NOT NULL THEN A.Price ELSE 0 END AS Price,
           A.Price * CASE WHEN A.ExtraRate = 0 THEN 0 ELSE A.ExtraRate END AS ExtraPrice, 
           A.SumAmt, 
           D.TotalSumAmt, 
           D.TotalTodayQty, 
           D.TotalUpMTWeight, 
           E.DataNo 

      INTO #DataBlock2_Print
      FROM #Result_DataBlock1       AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMExtraSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.ShipSeq, Z.ShipSerl, 
                               SUM(SumAmt) AS TotalSumAmt, 
                               SUM(CASE WHEN Y.IDX_NO IS NOT NULL THEN Z.TodayQty ELSE 0 END) AS TotalTodayQty, 
                               SUM(CASE WHEN Y.IDX_NO IS NOT NULL THEN Z.UpTodayMTWeight ELSE 0 END) AS TotalUpMTWeight
                          FROM #Result_DataBlock1           AS Z 
                          LEFT OUTER JOIN #MINUMExtraSeqSub AS Y ON ( Y.IDX_NO = Z.IDX_NO AND Y.MINUMExtraSeq = Z.UMExtraSeq )  
                         GROUP BY Z.ShipSeq, Z.ShipSerl 
                      ) AS D ON ( D.ShipSeq = A.ShipSeq AND D.ShipSerl = A.ShipSerl ) 
     LEFT OUTER JOIN #MINUMExtraSeqSub AS C ON ( C.IDX_NO = A.IDX_NO AND C.MINUMExtraSeq = A.UMExtraSeq ) 
     LEFT OUTER JOIN #BaseData_DataNo   AS E ON ( E.BizUnit = A.BizUnit AND E.ShipSeq = A.ShipSeq AND E.ShipSerl = A.ShipSerl ) 
     ORDER BY A.IDX_NO 
    ---------------------------------------------------------------------------------------------------------
    -- 하역 노임, End 
    ---------------------------------------------------------------------------------------------------------
    
 
    ---------------------------------------------------------------------------------------------------------
    -- 일용 노임
    ---------------------------------------------------------------------------------------------------------
    SELECT ROW_NUMBER() OVER (ORDER BY A.BizUnit, A.ShipSeq, A.ShipSerl, A.PJTSeq, A.WorkDate, A.UMWorkTeam) AS IDX_NO, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTEam,
		   B.BizUnitName,
		   A.OutDate,
		   C.IFShipCode + '-' + STUFF(C.ShipSerlNo, 5, 0, '-')	AS ShipSerlNo,
		   D.EnShipName,
		   E.PJTTypeName,
		   F.PJTName,
		   G.MinorName											AS UMLoadTypeName,
		   DATENAME(WEEKDAY, A.WorkDate)						AS WorkDay,
		   A.UMHolidayTypeName,
		   A.UMWeatherName,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName,
		   A.UDDToolName,
		   A.UDDUnionDay,
		   A.UDDPrice,
		   A.UDDNightTime,
		   A.UDDAmt,
		   A.UDDIsSaturday,
		   A.UDDIsSaturdayAmt,
		   A.UDDIsHoliday,
		   A.UDDIsHolidayAmt,
		   A.UDDIsRain,
		   A.UDDIsRainAmt,
		   A.UDDIsDanger,
		   A.UDDIsDangerAmt,
		   A.UDDIsNight,
		   A.UDDIsNightAmt,
		   A.UDDExtraAmt,
		   A.UDDSumAmt,
		   A.UDMUnionDay,
		   A.UDMPrice,
		   A.UDMAmt,
		   A.UDMExtraAmt,
		   A.UDMSumAmt,
		   A.UUDUnionDay,
		   A.UUDPrice,
		   A.UUDNighgTime,
		   A.UUDAmt,
		   A.UUDIsSaturday,
		   A.UUDIsSaturdayAmt,
		   A.UUDIsHoliday,
		   A.UUDIsHolidayAmt,
		   A.UUDIsRain,
		   A.UUDIsRainAmt,
		   A.UUDIsDanger,
		   A.UUDIsDangerAmt,
		   A.UUDIsNight,
		   A.UUDIsNightAmt,
		   A.UUDExtraAmt,
		   A.UUDSumAmt,
		   A.USDUnionDay,
		   A.USDPrice,
		   A.USDNighgTime,
		   A.USDAmt,
		   A.USDIsSaturday,
		   A.USDIsSaturdayAmt,
		   A.USDIsHoliday,
		   A.USDIsHolidayAmt,
		   A.USDIsRain,
		   A.USDIsRainAmt,
		   A.USDIsDanger,
		   A.USDIsDangerAmt,
		   A.USDIsNight,
		   A.USDIsNightAmt,
		   A.USDExtraAmt,
		   A.USDSumAmt,
		   A.UDDSumAmt + UUDSumAmt + A.USDSumAmt	AS MealExceptAmt,
		   A.MealCnt,
		   A.MealPrice,
		   A.MealAmt,
		   A.SumAmt,
		   A.ToolSeq,
		   A.Remark
      INTO #BaseData2
	  FROM mnpt_TPJTUnionPayDaily2 AS A
		   LEFT  JOIN _TDABizUnit AS B WITH(NOLOCK)
				   ON B.CompanySeq	= A.CompanySeq
				  AND B.BizUnit		= A.BizUnit
		   LEFT  JOIN mnpt_TPJTShipDetail AS C WITH(NOLOCK)
				   ON C.CompanySeq	= A.CompanySeq
				  AND C.ShipSeq		= A.ShipSeq
				  AND C.ShipSerl	= A.ShipSerl
		   LEFT  JOIN mnpt_TPJTShipMaster AS D WITH(NOLOCK)
				   ON D.CompanySeq	= A.CompanySeq
				  AND D.ShipSeq		= A.ShipSeq
		   LEFT  JOIN _TPJTType AS E WITH(NOLOCK)
				   ON E.CompanySeq	= A.CompanySeq
				  AND E.PJTTypeSeq	= A.PJTTypeSeq
		   LEFT  JOIN _TPJTProject AS F WITH(NOLOCK)
				   ON F.CompanySeq	= A.CompanySeq
				  AND F.PJTSeq		= A.PJTSeq
		   LEFT  JOIN _TDAUMinor AS G WITH(NOLOCK)
				   ON G.CompanySeq	= A.CompanySeq
				  AND G.MinorSeq	= A.UMLoadType
		   LEFT  JOIN mnpt_TPJTUnionPaySum AS H WITH(NOLOCK)
				   ON H.CompanySeq	= A.CompanySeq
				  AND H.PJTSeq		= A.PJTSeq
				  AND H.ShipSeq		= A.ShipSeq
				  AND H.ShipSerl	= A.ShipSerl
				  AND H.UMLoadType	= A.UMLoadType
				  AND H.IsUpdate	= '0'
				  AND H.SlipSeq		<> 0
     WHERE A.CompanySeq	= @CompanySeq	  
	   AND EXISTS (SELECT 1 
                     FROM #BIZ_IN_DataBlock1 
                    WHERE PJTSeq = A.PJTSeq 
                      AND ShipSeq = A.ShipSeq 
                      AND ShipSerl = A.ShipSerl 
                      AND UMLoadType = A.UMLoadType 
                  )
	 ORDER BY BizUnitName, A.OutDate, WorkDate, UMWorkTeam
    
    --select * From #BaseData2 
    --return 
    CREATE TABLE #BaseData_DataNo2 
    ( 
        DataNo      INT IDENTITY, 
        BizUnit     INT, 
        ShipSeq     INT, 
        ShipSerl    INT
    ) 
    INSERT INTO #BaseData_DataNo2 ( BizUnit, ShipSeq, ShipSerl ) 
    SELECT DISTINCT 
           BizUnit, 
           ShipSeq, 
           ShipSerl
      FROM #BaseData2  

    --운전원 노임단가입력 
	CREATE TABLE #tmpDPrice 
    ( 
        UMToolType	INT,
        PJTTypeSeq	INT,
        StartDate	NCHAR(8),
        EndDate		NCHAR(8),
        Price		DECIMAL(19, 5)
	)
    INSERT INTO #tmpDPrice 
    (
		UMToolType,		PJTTypeSeq,		StartDate,
		EndDate,		Price
	)
    SELECT B.UMToolType, C.PJTTypeSeq, A.StdDate,
           '',				UnDayPrice
      FROM mnpt_TPJTOperatorPriceMaster AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTOperatorPriceItem AS B WITH(NOLOCK)
				   ON B.Companyseq	= A.Companyseq
				  AND B.StdSeq		= A.StdSeq
		   INNER JOIN mnpt_TPJTOperatorPriceSubItem AS C WITH(NOLOCK)
				   ON C.Companyseq	= B.Companyseq
				  AND C.StdSeq		= B.StdSeq
				  AND C.StdSerl		= B.StdSerl
	 WHERE A.Companyseq	= @CompanySeq
	--/*-----------------------------------------------------------------------------
	--적용시작일 적용종료일 날짜계산
	--------------------------------------------------------------------------------*/
	--시작, 종료일 재구성
	UPDATE #tmpDPrice
	   SET EndDate  = ( SELECT ISNULL(CONVERT(NCHAR(8), DATEADD(d, -1, MIN(StartDate)), 112), '99991231')
						  FROM #tmpDPrice
						 WHERE UMToolType	= A.UMToolType
						   AND PJTTypeSeq	= A.PJTTypeSeq
						   AND StartDate	> A.StartDate   )
	  FROM #tmpDPrice AS A
    
	SELECT C.IFShipCode + '-' + STUFF(C.ShipSerlNo, 5, 0, '-')		AS FullShipName,
		   D.PJTName												AS PJTName,
		   A.WorkDate												AS WorkDate,
		   E.MinorName												AS UMWorkTeamName,
		   CASE WHEN ISNULL(G.MinorName, '') <> '' THEN ISNULL(G.MinorName, '')
			    WHEN ISNULL(I.MinorName, '') <> '' THEN ISNULL(I.MinorName, '') 
				ELSE ''
				END AS UDDToolName,
		   CASE WHEN ISNULL(G.Minorseq, '') <> '' THEN ISNULL(G.Minorseq, '')
			    WHEN ISNULL(I.Minorseq, '') <> '' THEN ISNULL(I.Minorseq, '') 
				ELSE ''
				END AS UDDToolSeq,
		   B.DUnionDay												AS UDDUnionDay,
		   0														AS UDDPrice,
		   CASE WHEN A.UMWorkTeam = 6017002 THEN A.RealWorkTime
				ELSE 0
				END													AS UDDNightTime,
		   0														AS UDDAmt,
		   J.PJTTypeSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.PJTSeq, 
           A.UMWorkTeam, 
           A.UMLoadType

	  INTO #UDDaily
	  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTWorkReportItem AS B WITH(NOLOCK)
				   ON B.CompanySeq		= A.CompanySeq
				  AND B.WorkReportSeq	= A.WorkReportSeq
		   LEFT  JOIN mnpt_TPJTShipDetail AS C WITH(NOLOCK)
				   ON C.CompanySeq		= A.CompanySeq
				  AND C.ShipSeq			= A.ShipSeq
				  AND C.ShipSerl		= A.ShipSerl
		   LEFT  JOIN _TPJTProject AS D WITH(NOLOCK)
				   ON D.CompanySeq		= A.CompanySeq
				  AND D.PJTseq			= A.PJTSeq
		   LEFT  JOIN _TDAUMinor AS E WITH(NOLOCK)
				   ON E.CompanySeq		= A.CompanySeq
				  AND E.MinorSeq		= A.UMWorkTeam
		   LEFT  JOIN mnpt_TPDEquipment AS F WITH(NOLOCK)
				   ON F.CompanySeq		= B.CompanySeq
				  AND F.EquipmentSeq	= B.SelfToolSeq
		   LEFT  JOIN _TDAUMinor AS G WITH(NOLOCK)
				   ON G.CompanySeq		= F.CompanySeq
				  AND G.MinorSeq		= F.UMToolType
		   LEFT  JOIN mnpt_TPDEquipment AS H WITH(NOLOCK)
				   ON H.CompanySeq		= B.CompanySeq
				  AND H.EquipmentSeq	= B.RentToolSeq
		   LEFT  JOIN _TDAUMinor AS I WITH(NOLOCK)
				   ON I.CompanySeq		= H.CompanySeq
				  AND I.MinorSeq		= H.UMToolType
		   LEFT  JOIN _TPJTProject AS J WITH(NOLOCK)
				   ON J.CompanySeq	= A.CompanySeq
				  AND J.PJTSeq		= A.PJTSeq
	 WHERE A.CompanySeq	= @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #BaseData2 
                    WHERE ShipSeq = A.ShipSeq 
                      AND ShipSerl = A.ShipSerl 
                      AND PJTSeq = A.PJTSeq 
                      AND WorkDate = A.WorkDate 
                      AND UMWorkTeam = A.UMWorkTeam 
                      AND UMLoadType = A.UMLoadType 
                  ) 
	   
	   AND B.DUnionDay	> 0	--운전원 - 노조 - 일대
	 ORDER BY B.WorkReportSeq, B.WorkReportSerl

	UPDATE #UDDaily
	   SET UDDPrice = ISNULL(B.Price, 0),
		   UDDAmt	= ISNULL(B.Price, 0) * ISNULL(A.UDDUnionDay, 0)
	  FROM #UDDaily AS A
		   LEFT  JOIN #tmpDPrice AS B
				   ON B.PJTTypeSeq	= A.PJTTypeSeq
				  AND B.UMToolType	= A.UDDToolSeq
				  AND A.WorkDate	BETWEEN B.StartDate AND B.EndDate
    
    -- 노조일용 할증율 
    SELECT A.ValueSeq AS UMExtraSeq, 
           B.ValueText AS UDDRate,
           C.ValueText AS UDMRate, 
           D.ValueText AS UDRate,
           E.ValueText AS USRate
      INTO #DailyRate
      FROM _TDAUMinorValue              AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000004 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.MinorSeq AND E.Serl = 1000005 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.MinorSeq AND F.Serl = 1000006 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.MinorSeq AND G.Serl = 1000006 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016040
       AND A.Serl = 1000001

    -- 노조운전
    SELECT A.IDX_NO, 
           '운전' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTEam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   A.PJTTypeName,
		   A.PJTName,
		   A.UMLoadTypeName, 
		   A.WorkDay, 
		   A.UMHolidayTypeName,
		   A.UMWeatherName,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName,
           A.UDDIsSaturday AS IsSaturday,
		   A.UDDIsHoliday AS IsHoliday,
		   A.UDDIsRain AS IsRain,
		   A.UDDIsDanger AS IsDanger,
		   A.UDDIsNight AS IsNight,
           B.UDDToolName AS UDDToolName,
		   B.UDDToolSeq AS UDDToolSeq,
		   B.UDDUnionDay AS ManCnt,
		   B.UDDPrice AS Price,
		   B.UDDNightTime AS NightTime,
		   A.UDDSumAmt AS SumAmt, 
           1 AS Sort 
      INTO #UDD
      FROM #BaseData2   AS A 
      JOIN #UDDaily     AS B ON ( B.ShipSeq = A.ShipSeq 
                              AND B.ShipSerl = A.ShipSerl 
                              AND B.PJTSeq = A.PJTSeq 
                              AND B.WorkDate = A.WorkDate 
                              AND B.UMWorkTeam = A.UMWorkTeam 
                              AND B.UMLoadType = A.UMLoadType 
                                )
     WHERE B.UDDUnionDay <> 0 
    
    -- 노조 운전 월대
    SELECT A.IDX_NO, 
           '운전(월대)' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTEam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   A.PJTTypeName,
		   A.PJTName,
		   A.UMLoadTypeName, 
		   A.WorkDay, 
		   A.UMHolidayTypeName,
		   A.UMWeatherName,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName, 
           '0' AS IsSaturday,
		   '0' AS IsHoliday,
		   '0' AS IsRain,
		   '0' AS IsDanger,
		   '0' AS IsNight,
           '' AS UDDToolName,
		   0 AS UDDToolSeq,
		   A.UDMUnionDay AS ManCnt,
		   A.UDMPrice AS Price,
		   0 AS NightTime,
		   A.UDMSumAmt AS SumAmt, 
           2 AS Sort 
      INTO #UDM 
      FROM #BaseData2   AS A 
     WHERE A.UDMUnionDay <> 0 

    -- 일용(노조일용)
    SELECT A.IDX_NO, 
           '일용' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTEam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   A.PJTTypeName,
		   A.PJTName,
		   A.UMLoadTypeName, 
		   A.WorkDay, 
		   A.UMHolidayTypeName,
		   A.UMWeatherName,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName, 
           A.UDDIsSaturday AS IsSaturday,
		   A.UUDIsHoliday AS IsHoliday,
		   A.UUDIsRain AS IsRain,
		   A.UUDIsDanger AS IsDanger,
		   A.UUDIsNight AS IsNight,
           '' AS UDDToolName,
		   0 AS UDDToolSeq,
		   A.UUDUnionDay AS ManCnt,
		   A.UUDPrice AS Price,
		   A.UUDNighgTime AS NightTime,
		   A.UUDSumAmt AS SumAmt, 
           3 AS Sort  
      INTO #UNDD 
      FROM #BaseData2   AS A 
     WHERE A.UUDUnionDay <> 0 

    -- 신호수
    SELECT A.IDX_NO, 
           '신호수' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   A.UMWorkTEam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   A.PJTTypeName,
		   A.PJTName,
		   A.UMLoadTypeName, 
		   A.WorkDay, 
		   A.UMHolidayTypeName,
		   A.UMWeatherName,
		   A.UMWorkTeamName,
		   A.UMWorkTypeName, 
           A.USDIsHoliday AS IsSaturday,
		   A.USDIsHoliday AS IsHoliday,
		   A.USDIsRain AS IsRain,
		   A.USDIsDanger AS IsDanger,
		   A.USDIsNight AS IsNight,
           '' AS UDDToolName,
		   0 AS UDDToolSeq,
		   A.USDUnionDay AS ManCnt,
		   A.USDPrice AS Price,
		   A.USDNighgTime AS NightTime,
		   A.USDSumAmt AS SumAmt, 
           4 AS Sort  
      INTO #US 
      FROM #BaseData2   AS A 
     WHERE A.USDUnionDay <> 0 
    
    
    -- 식대
    SELECT '식대' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq, 
		   A.UMLoadType,
		   A.WorkDate,
		   0 AS UMWorkTeam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   '' AS PJTTypeName,
		   '' AS PJTName,
		   '' AS UMLoadTypeName, 
		   '' AS WorkDay, 
		   '' AS UMHolidayTypeName,
		   '' AS UMWeatherName,
		   '' AS UMWorkTeamName,
		   '' AS UMWorkTypeName, 
           '0' AS IsSaturday,
		   '0' AS IsHoliday,
		   '0' AS IsRain,
		   '0' AS IsDanger,
		   '0' AS IsNight,
           '' AS UDDToolName,
		   0 AS UDDToolSeq,
		   A.MealCnt AS ManCnt,
		   A.MealPrice AS Price,
		   0 AS NightTime,
		   A.MealAmt AS Amt, 
           5 AS Sort  
      INTO #Meal 
      FROM #BaseData   AS A 
     WHERE A.MealCnt <> 0 
    UNION ALL 
    SELECT '식대' AS TypeName, 
           A.BizUnit,
		   A.ShipSeq,
		   A.ShipSerl,
		   A.PJTSeq,
		   A.PJTTypeSeq,
		   A.UMLoadType,
		   A.WorkDate,
		   0 AS UMWorkTeam,
		   A.BizUnitName,
		   A.OutDate,
		   A.ShipSerlNo,
		   A.EnShipName,
		   '' AS PJTTypeName,
		   '' AS PJTName,
		   '' AS UMLoadTypeName, 
		   '' AS WorkDay, 
		   '' AS UMHolidayTypeName,
		   '' AS UMWeatherName,
		   '' AS UMWorkTeamName,
		   '' AS UMWorkTypeName, 
           '0' AS IsSaturday,
		   '0' AS IsHoliday,
		   '0' AS IsRain,
		   '0' AS IsDanger,
		   '0' AS IsNight,
           '' AS UDDToolName,
		   0 AS UDDToolSeq,
		   A.MealCnt AS ManCnt,
		   A.MealPrice AS Price,
		   0 AS NightTime,
		   A.MealAmt AS Amt, 
           5 AS Sort  
      FROM #BaseData2   AS A 
     WHERE A.MealCnt <> 0 
    
    SELECT TypeName, BizUnit, ShipSeq, ShipSerl, PJTSeq, PJTTypeSeq, 
           UMLoadType, WorkDate, UMWorkTeam, BizUnitName, OutDate, 
           ShipSerlNo, EnShipName, Sort, SUM(ManCnt) AS ManCnt, Price, SUM(Amt) AS Amt 
      INTO #Result_Meal 
      FROM #Meal  
     GROUP BY TypeName, BizUnit, ShipSeq, ShipSerl, PJTSeq, PJTTypeSeq, 
              UMLoadType, WorkDate, UMWorkTeam, BizUnitName, OutDate, 
              ShipSerlNo, EnShipName, Sort, Price
                
    
    SELECT * INTO #RowData FROM #UDD 
    UNION ALL 
    SELECT * FROM #UDM 
    UNION ALL 
    SELECT * FROM #UNDD 
    UNION ALL 
    SELECT * FROM #US 
     ORDER BY Sort, IDX_NO 
    
    --select * from #RowData 
    --return 
    
    -- 할증별로 나오도록... 
    SELECT A.*, 
           0 AS ExtraRate,
           0 AS UMExtraSeq 
      INTO #Result_DataBlock2
      FROM #RowData AS A
     WHERE IsSaturday = '0' AND IsHoliday = '0' AND IsRain = '0' AND IsDanger = '0' AND IsNight = '0' 
    UNION ALL 
    SELECT A.*, 
           CASE WHEN A.Sort = 1 THEN ISNULL(UDDRate,0) 
                WHEN A.Sort = 2 THEN ISNULL(UDMRate,0)
                WHEN A.Sort = 3 THEN ISNULL(UDRate ,0)
                WHEN A.Sort = 4 THEN ISNULL(USRate ,0)
                END AS ExtraRate, 
           B.UMExtraSeq
      FROM #RowData       AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(UDDRate) AS UDDRate,
                               MAX(UDMRate) AS UDMRate, 
                               MAX(UDRate) AS UDRate,
                               MAX(USRate) AS USRate, 
                               UMExtraSeq
                          FROM #DailyRate   
                         WHERE UMExtraSeq = 1015782001 
                         GROUP BY UMExtraSeq 
                       ) AS B ON ( 1 = 1 ) 
     WHERE IsSaturday = '1' 
    UNION ALL 
    SELECT A.*, 
           CASE WHEN A.Sort = 1 THEN UDDRate 
                WHEN A.Sort = 2 THEN UDMRate
                WHEN A.Sort = 3 THEN UDRate 
                WHEN A.Sort = 4 THEN USRate 
                END AS ExtraRate, 
           B.UMExtraSeq
      FROM #RowData       AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(UDDRate) AS UDDRate,
                               MAX(UDMRate) AS UDMRate, 
                               MAX(UDRate) AS UDRate,
                               MAX(USRate) AS USRate, 
                               UMExtraSeq
                          FROM #DailyRate   
                         WHERE UMExtraSeq = 1015782002 
                         GROUP BY UMExtraSeq 
                       ) AS B ON ( 1 = 1 ) 
     WHERE IsHoliday = '1' 
    UNION ALL 
    SELECT A.*, 
           CASE WHEN A.Sort = 1 THEN UDDRate 
                WHEN A.Sort = 2 THEN UDMRate
                WHEN A.Sort = 3 THEN UDRate 
                WHEN A.Sort = 4 THEN USRate 
                END AS ExtraRate, 
           B.UMExtraSeq 
      FROM #RowData       AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(UDDRate) AS UDDRate,
                               MAX(UDMRate) AS UDMRate, 
                               MAX(UDRate) AS UDRate,
                               MAX(USRate) AS USRate, 
                               UMExtraSeq
                          FROM #DailyRate   
                         WHERE UMExtraSeq = 1015782003 
                         GROUP BY UMExtraSeq 
                       ) AS B ON ( 1 = 1 ) 
     WHERE IsRain = '1' 
    UNION ALL 
    SELECT A.*, 
           CASE WHEN A.Sort = 1 THEN UDDRate 
                WHEN A.Sort = 2 THEN UDMRate
                WHEN A.Sort = 3 THEN UDRate 
                WHEN A.Sort = 4 THEN USRate 
                END AS ExtraRate, 
           B.UMExtraSeq 
      FROM #RowData       AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(UDDRate) AS UDDRate,
                               MAX(UDMRate) AS UDMRate, 
                               MAX(UDRate) AS UDRate,
                               MAX(USRate) AS USRate, 
                               UMExtraSeq
                          FROM #DailyRate   
                         WHERE UMExtraSeq = 1015782005 
                         GROUP BY UMExtraSeq 
                       ) AS B ON ( 1 = 1 ) 
     WHERE IsDanger = '1' 
    UNION ALL 
    SELECT A.*, 
           CASE WHEN A.Sort = 1 THEN UDDRate 
                WHEN A.Sort = 2 THEN UDMRate
                WHEN A.Sort = 3 THEN UDRate 
                WHEN A.Sort = 4 THEN USRate 
                END AS ExtraRate, 
           B.UMExtraSeq 
      FROM #RowData       AS A 
      LEFT OUTER JOIN (
                        SELECT MAX(UDDRate) AS UDDRate,
                               MAX(UDMRate) AS UDMRate, 
                               MAX(UDRate) AS UDRate,
                               MAX(USRate) AS USRate, 
                               UMExtraSeq
                          FROM #DailyRate   
                         WHERE UMExtraSeq = 1015782004 
                         GROUP BY UMExtraSeq 
                       ) AS B ON ( 1 = 1 ) 
     WHERE IsNight = '1' 
     ORDER BY Sort 
    
    -- 할증단가에 기본단가가 합쳐지는 건은 1건만 
    SELECT TypeName, BizUnit, ShipSeq, ShipSerl, PJTSeq,
		   PJTTypeSeq, UMLoadType, WorkDate, UMWorkTeam, UMWorkTypeName, 
           UDDToolSeq, MIN(UMExtraSeq) AS MINUMExtraSeq 
      INTO #MINUMExtraSeq
      FROM #Result_DataBlock2 
     GROUP BY TypeName, BizUnit, ShipSeq, ShipSerl, PJTSeq,
		      PJTTypeSeq, UMLoadType, WorkDate, UMWorkTeam, UMWorkTypeName, 
              UDDToolSeq
    
    --select * from #Result_DataBlock2 
    --return 
    SELECT A.BizUnit, 
           A.PJTSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.EnShipName, 
           A.ShipSerlNo, 
           A.TypeName, 
           A.UDDToolSeq, 
           A.UDDToolName, 
           A.UMExtraSeq, 
           A.UMWorkTeam, 
           CASE WHEN A.UMExtraSeq = 0 THEN A.UMWorkTeamName ELSE B.MinorName END AS UMWorkTeamName, 
           CASE WHEN A.UMExtraSeq = 0 THEN '0' ELSE '1' END AS IsExtra, 
           MAX(A.NightTime) AS NightTime, 
           SUM(A.ManCnt) ManCnt, 
           A.WorkDate, 
           CASE WHEN A.UMWorkTeam = 6017002 AND A.NightTime <> 0 AND A.UMExtraSeq = 1015782004 THEN A.Price * ((CONVERT(DECIMAL(19,5),A.ExtraRate) / 100) + CASE WHEN C.TypeName IS NULL THEN 0 ELSE 1 END) / 8
                WHEN UMExtraSeq <> 0 THEN A.Price * ((CONVERT(DECIMAL(19,5),A.ExtraRate)) / 100 + 1) 
                ELSE A.Price 
                END AS Price, 
           A.SumAmt, 
           A.Sort, 
           A.IDX_NO, 
           A.OutDate, 
           A.BizUnitName
        INTO #Result_Select
        FROM #Result_DataBlock2         AS A 
        LEFT OUTER JOIN _TDAUMinor      AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMExtraSeq ) 
        LEFT OUTER JOIN #MINUMExtraSeq  AS C ON ( C.TypeName = A.TypeName 
                                              AND C.BizUnit = A.BizUnit 
                                              AND C.ShipSeq = A.ShipSeq 
                                              AND C.ShipSerl = A.ShipSerl 
                                              AND C.PJTSeq = A.PJTSeq 
                                              --AND C.PJTTypeSeq = A.PJTTypeSeq 
                                              AND C.UMLoadType = A.UMLoadType 
                                              AND C.WorkDate = A.WorkDate 
                                              AND C.UMWorkTeam = A.UMWorkTeam
                                              AND C.UMWorkTypeName = A.UMWorkTypeName 
                                              AND C.UDDToolSeq = A.UDDToolSeq
                                              AND C.MINUMExtraSeq = A.UMExtraSeq
                                                 ) 
     GROUP BY A.BizUnit, 
              A.PJTSeq, 
              A.ShipSeq, 
              A.ShipSerl, 
              A.EnShipName, 
              A.ShipSerlNo, 
              A.TypeName, 
              A.UDDToolSeq, 
              A.UDDToolName, 
              A.UMExtraSeq, 
              A.UMWorkTeam, 
              CASE WHEN A.UMExtraSeq = 0 THEN A.UMWorkTeamName ELSE B.MinorName END, 
              CASE WHEN A.UMExtraSeq = 0 THEN '0' ELSE '1' END, 
              A.WorkDate, 
              CASE WHEN A.UMWorkTeam = 6017002 AND A.NightTime <> 0 AND A.UMExtraSeq = 1015782004 THEN A.Price * ((CONVERT(DECIMAL(19,5),A.ExtraRate) / 100) + CASE WHEN C.TypeName IS NULL THEN 0 ELSE 1 END) / 8
                WHEN UMExtraSeq <> 0 THEN A.Price * ((CONVERT(DECIMAL(19,5),A.ExtraRate)) / 100 + 1)
                ELSE A.Price 
                END, 
              A.SumAmt, 
              A.Sort, 
              A.IDX_NO, 
              A.OutDate, 
              A.BizUnitName 
     ORDER BY Sort, IDX_NO
    
    --select *from #Result_Select 
    --return 
    -- 최종조회
    SELECT '일용노임' AS KindName,
           Z.BizUnit,
           Z.PJTSeq, 
           Z.ShipSeq, 
           Z.ShipSerl, 
           Z.EnShipName, 
           Z.ShipSerlNo, 
           Z.TypeName, 
           Z.UDDToolSeq, 
           Z.UDDToolName, 
           Z.UMExtraSeq, 
           Z.UMWorkTeam, 
           Z.UMWorkTeamName, 
           Z.IsExtra,
           Z.Sort, 
           Z.Price, 
           Z.NightTime, 
           Z.ManCnt, 
           Z.IDX_NO AS DataKindSeq, 
           Z.SumAmt, 
           --CASE WHEN Z.UMWorkTeam = 6017002 AND Z.NightTime <> 0 THEN Z.NightTime * Z.ManCnt * Z.Price ELSE Z.ManCnt * Z.Price END Amt,
           Y.Remark, 
           Z.OutDate, 
           Z.BizUnitName
      INTO #DataBlock3_Print 
      FROM (
            SELECT BizUnit,
                   PJTSeq, 
                   ShipSeq, 
                   ShipSerl, 
                   EnShipName, 
                   ShipSerlNo, 
                   TypeName, 
                   UDDToolSeq, 
                   UDDToolName, 
                   UMExtraSeq, 
                   UMWorkTeam, 
                   UMWorkTeamName, 
                   IsExtra,
                   Sort, 
                   Price, 
                   IDX_NO, 
                   OutDate,
                   BizUnitName, 
                   MAX(SumAmt) AS SumAmt, 
                   SUM(NightTime) AS NightTime, 
                   SUM(ManCnt) AS ManCnt
              FROM #Result_Select 
             GROUP BY PJTSeq, 
                      ShipSeq, 
                      ShipSerl, 
                      EnShipName, 
                      ShipSerlNo, 
                      TypeName, 
                      UDDToolSeq, 
                      UDDToolName, 
                      UMExtraSeq, 
                      UMWorkTeam, 
                      UMWorkTeamName, 
                      IsExtra,
                      Sort, 
                      Price, 
                      IDX_NO,
                      BizUnit, 
                      OutDate, 
                      BizUnitName
          ) AS Z 
     LEFT OUTER JOIN ( 
                        SELECT B.ShipSeq, B.ShipSerl, B.TypeName, B.UDDToolSeq, B.UMExtraSeq, B.Sort, B.Price, 
                               B.PJTSeq, 
           
                               replace ( 
                               replace ( 
                               replace ( 
                               (SELECT STUFF(RIGHT(A.WorkDate,4),3,0,'/') + ' ' + CONVERT(NVARCHAR(20),CONVERT(INT,A.ManCnt)) + '명' +
                                       CASE WHEN A.UMWorkTeam = 6017002 AND A.NightTime <> 0 THEN ' (' + CONVERT(NVARCHAR(20),CONVERT(INT,A.NightTime)) + '시간)' 
                                            ELSE '' 
                                            END 
                                       AS Remark
                                  FROM #Result_Select AS A 
                                 WHERE A.PJTSeq = B.PJTSeq 
                                   AND A.ShipSeq = B.ShipSeq 
                                   AND A.Shipserl = B.ShipSerl 
                                   AND A.TypeName = B.TypeName 
                                   AND A.UDDToolSeq = B.UDDToolSeq 
                                   AND A.UMExtraSeq = B.UMExtraSeq 
                                   AND A.Sort = B.Sort 
                                   AND A.Price = B.Price FOR XML AUTO, ELEMENTS
                               ),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
                          FROM (SELECT DISTINCT 
                                       ShipSeq, ShipSerl, TypeName, UDDToolSeq, UMExtraSeq, Sort, Price, 
                                       PJTSeq
                                  FROM #Result_Select 
                               )AS B  
                     ) AS Y ON ( Y.PJTSeq = Z.PJTSeq 
                             AND Y.ShipSeq = Z.ShipSeq 
                             AND Y.ShipSerl = Z.ShipSerl 
                             AND Y.TypeName = Z.TypeName 
                             AND Y.UDDToolSeq = Z.UDDToolSeq 
                             AND Y.UMExtraSeq = Z.UMExtraSeq 
                             AND Y.Sort = Z.Sort 
                             AND Y.Price = Z.Price 
                               )
    UNION ALL 
    -- 식대 
    SELECT '일용노임' AS KindName, 
           Z.BizUnit, 
           Z.PJTSeq, 
           Z.ShipSeq, 
           Z.ShipSerl, 
           Z.EnShipName, 
           Z.ShipSerlNo, 
           Z.TypeName, 
           0 AS UDDToolSeq, 
           '' AS UDDToolName, 
           0 AS UMExtraSeq, 
           0 AS UMWorkTeam, 
           '' AS UMworkTeamName, 
           '0' AS IsExtra, 
           Z.Sort, 
           Z.Price, 
           0 AS NightTime, 
           Z.ManCnt, 
           99999 AS DataKindSeq, 
           Z.ManCnt * Z.Price AS SumAmt, 
           Y.Remark, 
           Z.OutDate, 
           Z.BizUnitName
      FROM ( 
            SELECT BizUnit, 
                   PJTSeq, 
                   ShipSeq, 
                   ShipSerl, 
                   EnShipName, 
                   ShipSerlNo, 
                   TypeName, 
                   SUM(ManCnt) AS ManCnt, 
                   Price, 
                   Sort, 
                   OutDate, 
                   BizUnitName 
              FROM #Result_Meal 
             GROUP BY BizUnit, 
                      PJTSeq, 
                      ShipSeq, 
                      ShipSerl, 
                      EnShipName, 
                      ShipSerlNo, 
                      TypeName, 
                      Price, 
                      Sort, 
                      OutDate, 
                      BizUnitName 
           ) AS Z  
      LEFT OUTER JOIN ( 
                        SELECT B.ShipSeq, B.ShipSerl, B.TypeName, B.Sort, B.Price, B.PJTSeq, 
                               replace ( 
                               replace ( 
                               replace ( 
                               (SELECT STUFF(RIGHT(A.WorkDate,4),3,0,'/') + ' ' + CONVERT(NVARCHAR(20),CONVERT(INT,A.ManCnt)) + '명' AS Remark
                                  FROM #Result_Meal AS A 
                                 WHERE A.PJTSeq = B.PJTSeq 
                                   AND A.ShipSeq = B.ShipSeq 
                                   AND A.Shipserl = B.ShipSerl 
                                   AND A.TypeName = B.TypeName 
                                   AND A.Sort = B.Sort 
                                   AND A.Price = B.Price FOR XML AUTO, ELEMENTS
                               ),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
                          FROM (
                                SELECT DISTINCT 
                                       ShipSeq, ShipSerl, TypeName, Sort, Price, PJTSeq
                                  FROM #Result_Meal 
                               ) AS B  
                     ) AS Y ON ( Y.PJTSeq = Z.PJTSeq 
                             AND Y.ShipSeq = Z.ShipSeq 
                             AND Y.ShipSerl = Z.ShipSerl 
                             AND Y.TypeName = Z.TypeName 
                             AND Y.Sort = Z.Sort 
                             AND Y.Price = Z.Price 
                               )

        --   select 1, * From #BaseData 
        --select 2, * from #BaseData2 
        --select 3, * from #Result_Meal 
        --return 
    -- DataBlock1
    SELECT A.ShipSerlNo, A.EnShipName, A.OutDate 
      FROM #DataBlock2_Print AS A 
    UNION  
    SELECT A.ShipSerlNo, A.EnShipName, A.OutDate 
      FROM #DataBlock3_Print AS A 
    
    -- DataBlock2 
    SELECT * FROM #DataBlock2_Print 

    -- DataBlock3
    SELECT A.*, 
           B.SumAmt + C.SumMealAmt AS SumAmt -- 식대 추가(하역노임,일용노임)
      FROM #DataBlock3_Print AS A 
      LEFT OUTER JOIN (
                        SELECT ShipSeq, ShipSerl, SUM(SumAmt) - SUM(MealAmt) AS SumAmt -- 식대 제외 (일용노임)
                          FROM #BaseData2 
                         GROUP BY ShipSeq, ShipSerl 
                      ) AS B ON ( B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN (
                        SELECT ShipSeq, ShipSerl, SUM(Amt) AS SumMealAmt
                          FROM #Result_Meal 
                         GROUP BY ShipSeq, ShipSerl 
                      ) AS C ON ( C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
     ORDER BY A.Sort, A.DataKindSeq
        
 
    -- DataBlock4
    SELECT A.ShipSeq, A.ShipSerl, SUM(ISNULL(A.SumAmt,0)) + MAX(ISNULL(C.SumMealAmt,0)) AS DataBlock3Amt
      FROM (
            SELECT ShipSeq, ShipSerl, SUM(SumAmt) AS SumAmt 
              FROM #BaseData 
             GROUP BY ShipSeq, ShipSerl 
            UNION ALL 
            SELECT ShipSeq, ShipSerl, SUM(SumAmt) - SUM(MealAmt) AS SumAmt 
              FROM #BaseData2 
             GROUP BY ShipSeq, ShipSerl 

           ) AS A 
      LEFT OUTER JOIN (
                        SELECT ShipSeq, ShipSerl, SUM(Amt) AS SumMealAmt
                          FROM #Result_Meal 
                         GROUP BY ShipSeq, ShipSerl 
                      ) AS C ON ( C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
     GROUP BY A.ShipSeq, A.ShipSerl 
    
    -- DataBlock5 
    SELECT TOP 1 * 
      FROM ( 
            SELECT ShipSeq, ShipSerl, MAX(BizUnitName) AS BizUnitName, MAX(OutDate) AS OutDate 
              FROM #DataBlock2_Print 
             GROUP BY ShipSeq, ShipSerl 
            UNION 
            SELECT ShipSeq, ShipSerl, MAX(BizUnitName) AS BizUnitName, MAX(OutDate) AS OutDate 
              FROM #DataBlock3_Print 
             GROUP BY ShipSeq, ShipSerl 
           ) AS A 
    -----------------------------------------------------------------------------------------------------------
    -- 일용 노임, End 
    ---------------------------------------------------------------------------------------------------------
    RETURN 
