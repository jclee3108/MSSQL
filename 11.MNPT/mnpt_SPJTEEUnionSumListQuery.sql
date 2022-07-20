     
IF OBJECT_ID('mnpt_SPJTEEUnionSumListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEEUnionSumListQuery      
GO      
      
-- v2018.01.18 
      
-- 노임집계표-조회 by 이재천  
CREATE PROC mnpt_SPJTEEUnionSumListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     
    DECLARE @FrStdYM    NCHAR(6), 
            @ToStdYM    NCHAR(6), 
            @BizUnit    INT
      
    SELECT @FrStdYM = ISNULL( FrStdYM, '' ),   
           @ToStdYM = ISNULL( ToStdYM, '' ), 
           @BizUnit = ISNULL( BizUnit, 0 )
      FROM #BIZ_IN_DataBlock1    
    

    CREATE TABLE #Result 
    (
        IDX_NO              INT IDENTITY, 
        StdYM               NCHAR(6), 
        --OutDate             NCHAR(8), 
        ItemClassMSeq       INT, 
        UMLoadType          INT, 
        --PJTTypeKindName     NVARCHAR(200),
        Qty                 DECIMAL(19,5),
        MTQty               DECIMAL(19,5),
        RTQty               DECIMAL(19,5),
        SumAmt              DECIMAL(19,5),
        GangAmt             DECIMAL(19,5),
        GangExtraAmt        DECIMAL(19,5),
        GangSumAmt          DECIMAL(19,5),
        RetireAmt           DECIMAL(19,5),
        ModernAmt           DECIMAL(19,5),
        TraingAmt           DECIMAL(19,5),
        WelfareAmt          DECIMAL(19,5),
        MedicalAmt          DECIMAL(19,5),
        NationalAmt         DECIMAL(19,5),
        SafetyAmt           DECIMAL(19,5),
        SocietyAmt          DECIMAL(19,5),
        UtilityAmt          DECIMAL(19,5),
        UDDSumAmt           DECIMAL(19,5),
        UnionSumAmt         DECIMAL(19,5),
        DailyWageAmt        DECIMAL(19,5),
        RentToolAmt         DECIMAL(19,5),
        RentSumAmt          DECIMAL(19,5), 
        IsExists            NCHAR(1) 
    ) 
    
    
    -- 조회연월 구하기 
    SELECT DISTINCT LEFT(Solar,6) AS StdYM 
      INTO #TCOMCalendar 
      FROM _TCOMCalendar 
     WHERE LEFT(Solar,6) BETWEEN @FrStdYM AND @ToStdYM 
     ORDER BY StdYM
    
    -- 화태중분류, 하역방식 모두구하기 
    INSERT INTO #Result ( StdYM, ItemClassMSeq, UMLoadType ) 
    SELECT DISTINCT 
           C.StdYM, 
           A.MinorSeq AS ItemClassMSeq, 
           CASE WHEN A.MinorSeq <> 2002001 THEN D.MinorSeq ELSE 0 END AS UMLoadType 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 2001 ) 
      LEFT OUTER JOIN #TCOMCalendar     AS C ON ( 1 = 1 ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1015935 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 2002 

       AND B.ValueSeq = 2003001 
     ORDER BY StdYM, ItemCLassMSeq, UMLoadType 
    
    -- 비노임 
    INSERT INTO #Result ( StdYM, ItemClassMSeq, UMLoadType ) 
    SELECT DISTINCT 
           A.StdYM, 
           9999990 AS ItemClassMSeq, 
           0 AS UMLoadType 
      FROM #TCOMCalendar AS A 
    
    SELECT C.ItemClassMSeq, 
           A.UMLoadType, 
           LEFT(A.OutDate,6) AS StdYM, 
           SUM(A.Qty) AS Qty, 
           SUM(A.MTQty) AS MTQty, 
           SUM(A.GangAmt) AS GangAmt, 
           SUM(A.GangExtraAmt) AS GangExtraAmt, 
           SUM(A.GangSumAmt) AS GangSumAmt, 
           SUM(A.RetireAmt) AS RetireAmt, 
           SUM(A.ModernAmt) AS ModernAmt, 
           SUM(A.TraingAmt) AS TraingAmt, 
           SUM(A.WelfareAmt) AS WelfareAmt, 
           SUM(A.MedicalAmt) AS MedicalAmt, 
           SUM(A.NationalAmt) AS NationalAmt, 
           SUM(A.SafetyAmt) AS SafetyAmt, 
           SUM(A.SocietyAmt) AS SocietyAmt, 
           SUM(A.UtilityAmt) AS UtilityAmt, 
           SUM(A.UDDSumAmt) AS UDDSumAmt, 
           SUM(A.SumAmt) AS SumAmt
      INTO #mnpt_TPJTUnionPaySum 
      FROM mnpt_TPJTUnionPaySum     AS A 
      LEFT OUTER JOIN _TPJTType     AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
      LEFT OUTER JOIN _VDAItemClass AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemClassSSeq = B.ItemClassSeq ) 
      LEFT OUTER JOIN _TPJTProject  AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.OutDate,6) BETWEEN @FrStdYM AND @ToStdYM 
       AND ( @BizUnit = 0 OR D.BizUnit = @BizUnit ) 
     GROUP BY ItemClassMSeq, UMLoadType, LEFT(OutDate,6)
    

    UPDATE A
       SET Qty            = B.Qty          ,
           MTQty          = B.MTQty        ,
           SumAmt         = B.SumAmt       ,
           GangAmt        = B.GangAmt      ,
           GangExtraAmt   = B.GangExtraAmt ,
           GangSumAmt     = B.GangSumAmt   ,
           RetireAmt      = B.RetireAmt    ,
           ModernAmt      = B.ModernAmt    ,
           TraingAmt      = B.TraingAmt    ,
           WelfareAmt     = B.WelfareAmt   ,
           MedicalAmt     = B.MedicalAmt   ,
           NationalAmt    = B.NationalAmt  ,
           SafetyAmt      = B.SafetyAmt    ,
           SocietyAmt     = B.SocietyAmt   ,
           UtilityAmt     = B.UtilityAmt   ,
           UDDSumAmt      = B.UDDSumAmt    , 
           IsExists       = '1' 

      FROM #Result                  AS A 
      JOIN #mnpt_TPJTUnionPaySum    AS B ON ( B.ItemClassMSeq = A.ItemClassMSeq AND B.UMLoadType = A.UMLoadType AND B.StdYM = A.StdYM ) 
    
    ----------------------------------------------------------------------------------------
    -- 소급
    ----------------------------------------------------------------------------------------
    SELECT C.ItemClassMSeq, 
           LEFT(A.RetroDate,6) AS StdYM, 
           SUM(A.Qty) AS Qty, 
           SUM(A.MTQty) AS MTQty, 
           SUM(A.GangAmt) AS GangAmt, 
           SUM(A.GangExtraAmt) AS GangExtraAmt, 
           SUM(A.GangSumAmt) AS GangSumAmt, 
           SUM(A.RetireAmt) AS RetireAmt, 
           SUM(A.ModernAmt) AS ModernAmt, 
           SUM(A.TraingAmt) AS TraingAmt, 
           SUM(A.WelfareAmt) AS WelfareAmt, 
           SUM(A.MedicalAmt) AS MedicalAmt, 
           SUM(A.NationalAmt) AS NationalAmt, 
           SUM(A.SafetyAmt) AS SafetyAmt, 
           SUM(A.SocietyAmt) AS SocietyAmt, 
           SUM(A.UtilityAmt) AS UtilityAmt, 
           SUM(A.UDDSumAmt) AS UDDSumAmt, 
           SUM(A.SumAmt) AS SumAmt
      INTO #mnpt_TPJTUnionPaySumAdd
      FROM mnpt_TPJTUnionPaySum     AS A 
      LEFT OUTER JOIN _TPJTType     AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
      LEFT OUTER JOIN _VDAItemClass AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemClassSSeq = B.ItemClassSeq ) 
      LEFT OUTER JOIN _TPJTProject  AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.RetroDate,6) BETWEEN @FrStdYM AND @ToStdYM 
       AND ( @BizUnit = 0 OR D.BizUnit = @BizUnit ) 
     GROUP BY C.ItemClassMSeq, LEFT(A.RetroDate,6)
    
    
    UPDATE Z
       SET Qty          = ISNULL(Z.Qty         ,0) + ISNULL(Q.Qty         ,0), 
           MTQty        = ISNULL(Z.MTQty       ,0) + ISNULL(Q.MTQty       ,0), 
           GangAmt      = ISNULL(Z.GangAmt     ,0) + ISNULL(Q.GangAmt     ,0), 
           GangExtraAmt = ISNULL(Z.GangExtraAmt,0) + ISNULL(Q.GangExtraAmt,0), 
           GangSumAmt   = ISNULL(Z.GangSumAmt  ,0) + ISNULL(Q.GangSumAmt  ,0), 
           RetireAmt    = ISNULL(Z.RetireAmt   ,0) + ISNULL(Q.RetireAmt   ,0), 
           ModernAmt    = ISNULL(Z.ModernAmt   ,0) + ISNULL(Q.ModernAmt   ,0), 
           TraingAmt    = ISNULL(Z.TraingAmt   ,0) + ISNULL(Q.TraingAmt   ,0), 
           WelfareAmt   = ISNULL(Z.WelfareAmt  ,0) + ISNULL(Q.WelfareAmt  ,0), 
           MedicalAmt   = ISNULL(Z.MedicalAmt  ,0) + ISNULL(Q.MedicalAmt  ,0), 
           NationalAmt  = ISNULL(Z.NationalAmt ,0) + ISNULL(Q.NationalAmt ,0), 
           SafetyAmt    = ISNULL(Z.SafetyAmt   ,0) + ISNULL(Q.SafetyAmt   ,0), 
           SocietyAmt   = ISNULL(Z.SocietyAmt  ,0) + ISNULL(Q.SocietyAmt  ,0), 
           UtilityAmt   = ISNULL(Z.UtilityAmt  ,0) + ISNULL(Q.UtilityAmt  ,0), 
           UDDSumAmt    = ISNULL(Z.UDDSumAmt   ,0) + ISNULL(Q.UDDSumAmt   ,0), 
           SumAmt       = ISNULL(Z.SumAmt      ,0) + ISNULL(Q.SumAmt      ,0), 
           IsExists = '1' 
      FROM #Result AS Z 
      JOIN ( 
            SELECT A.StdYM, A.ItemClassMSeq, MIN(A.IDX_NO) AS Min_IDX_NO
              FROM #Result      AS A 
              JOIN #mnpt_TPJTUnionPaySumAdd  AS B ON ( B.StdYM = A.StdYM AND B.ItemClassMSeq = A.ItemClassMSeq ) 
             WHERE A.IsExists = '1' 
             GROUP BY A.StdYM, A.ItemClassMSeq 
           ) AS Y ON ( Y.StdYM = Z.StdYM AND Y.ItemClassMSeq = Z.ItemClassMSeq AND Y.Min_IDX_NO = Z.IDX_NO ) 
      JOIN #mnpt_TPJTUnionPaySumAdd  AS Q ON ( Q.StdYM = Z.StdYM AND Q.ItemClassMSeq = Z.ItemClassMSeq ) 
    ----------------------------------------------------------------------------------------
    -- 소급, End 
    ----------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------
    -- 컨테이너 
    ----------------------------------------------------------------------------------------
    SELECT A.MinorSeq AS UMWorkType, B.ValueText AS RTCalc
      INTO #CNTRWorkType
      FROM _TDAUMinorValue              AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000003 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015816
       AND A.Serl = 1000002
    
    
    SELECT 2002001 AS ItemClassMSeq, 
           LEFT(B.OutDateTime,6) AS StdYM, 
           SUM(A.Qty * CONVERT(INT,C.MngValText)) AS Qty, 
           SUM(A.Qty * (CONVERT(INT,C.MngValText) * 8) )  AS RTWeight, 
           MAX(I.GangAmt)       AS GangAmt, 
           MAX(I.GangExtraAmt)  AS GangExtraAmt, 
           MAX(I.GangSumAmt)    AS GangSumAmt, 
           MAX(I.RetireAmt)     AS RetireAmt, 
           MAX(I.ModernAmt)     AS ModernAmt, 
           MAX(I.TraingAmt)     AS TraingAmt, 
           MAX(I.WelfareAmt)    AS WelfareAmt, 
           MAX(I.MedicalAmt)    AS MedicalAmt, 
           MAX(I.NationalAmt)   AS NationalAmt, 
           MAX(I.SafetyAmt)     AS SafetyAmt, 
           MAX(I.SocietyAmt)    AS SocietyAmt, 
           MAX(I.UtilityAmt)    AS UtilityAmt, 
           MAX(I.UDDSumAmt)     AS UDDSumAmt, 
           MAX(I.SumAmt)        AS SumAmt
      INTO #CNTRReport
      FROM mnpt_TPJTEECNTRReport            AS A 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAItemUserDefine     AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq AND C.MngSerl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS G ON ( G.CompanySeq = @CompanySeq AND G.Majorseq = 1015794 AND G.Serl = 1000001 AND G.ValueText = B.BizUnitCode ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000002 ) 
      LEFT OUTER JOIN (
                        SELECT ItemClassMSeq, 
                               SUM(GangAmt)       AS GangAmt, 
                               SUM(GangExtraAmt)  AS GangExtraAmt, 
                               SUM(GangSumAmt)    AS GangSumAmt, 
                               SUM(RetireAmt)     AS RetireAmt, 
                               SUM(ModernAmt)     AS ModernAmt, 
                               SUM(TraingAmt)     AS TraingAmt, 
                               SUM(WelfareAmt)    AS WelfareAmt, 
                               SUM(MedicalAmt)    AS MedicalAmt, 
                               SUM(NationalAmt)   AS NationalAmt, 
                               SUM(SafetyAmt)     AS SafetyAmt, 
                               SUM(SocietyAmt)    AS SocietyAmt, 
                               SUM(UtilityAmt)    AS UtilityAmt, 
                               SUM(UDDSumAmt)     AS UDDSumAmt, 
                               SUM(SumAmt)        AS SumAmt
                          FROM #mnpt_TPJTUnionPaySum 
                         WHERE ItemClassMSeq = 2002001 
                         GROUP BY ItemClassMSeq
                      ) AS I ON ( 1 = 1 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(B.OutDateTime,6) BETWEEN @FrStdYM AND @ToStdYM 
       AND ( @BizUnit = 0 OR H.ValueSeq = @BizUnit ) 
     GROUP BY LEFT(B.OutDateTime,6)
    
    UPDATE A
       SET Qty          = B.Qty, 
           RTQty        = B.RTWeight, 
           GangAmt      = B.GangAmt     , 
           GangExtraAmt = B.GangExtraAmt, 
           GangSumAmt   = B.GangSumAmt  , 
           RetireAmt    = B.RetireAmt   , 
           ModernAmt    = B.ModernAmt   , 
           TraingAmt    = B.TraingAmt   , 
           WelfareAmt   = B.WelfareAmt  , 
           MedicalAmt   = B.MedicalAmt  , 
           NationalAmt  = B.NationalAmt , 
           SafetyAmt    = B.SafetyAmt   , 
           SocietyAmt   = B.SocietyAmt  , 
           UtilityAmt   = B.UtilityAmt  , 
           UDDSumAmt    = B.UDDSumAmt   , 
           SumAmt       = B.SumAmt      , 
           IsExists = '1' 
      FROM #Result      AS A 
      JOIN #CNTRReport  AS B ON ( B.StdYM = A.StdYM AND B.ItemClassMSeq = A.ItemClassMSeq ) 
    ----------------------------------------------------------------------------------------
    -- 컨테이너, End 
    ----------------------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------------------
    -- 비노임
    ----------------------------------------------------------------------------------------
    CREATE TABLE #UnionWorkReportSeq ( WorkReportSeq INT )

    INSERT INTO #UnionWorkReportSeq ( WorkReportSeq ) 
    -- 노조노임 
    SELECT A.WorkReportSeq 
      FROM mnpt_TPJTWorkReport      AS A 
      LEFT OUTER JOIN _TPJTProject  AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WorkDate,6) BETWEEN @FrStdYM AND @ToStdYM
       AND ( @BizUnit = 0 OR B.BizUnit = @BizUnit ) 
       AND EXISTS (
                    SELECT 1
                    FROM mnpt_TPJTWorkReportItem        --Gang이 0보다 큰것
                    WHERE CompanySeq	= @CompanySeq 
                    AND NDUnionUnloadGang > 0 
                    AND IsCfm		= '1'    
                    AND WorkReportSeq = A.WorkReportSeq
                  )
    UNION 
    -- 노조일일용
	SELECT DISTINCT A.WorkReportSeq 
	  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTWorkReportItem AS B WITH(NOLOCK)
				   ON B.CompanySeq		= A.CompanySeq
				  AND B.WorkReportSeq	= A.WorkReportSeq
      LEFT OUTER JOIN _TPJTProject  AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq	= @CompanySeq
	   AND B.IsCfm		= '1'
       AND LEFT(A.WorkDate,6) BETWEEN @FrStdYM AND @ToStdYM
       AND ( @BizUnit = 0 OR C.BizUnit = @BizUnit ) 
	   AND (DUnionDay			> 0	OR		--운전원 - 노조 - 일대
	   		DUnionHalf			> 0	OR		--운전원 - 노조 - 반일
	   		DUnionMonth			> 0	OR		--운전원 - 노조 - 월대
	   		NDUnionDailyDay		> 0	OR		--운전원외 - 노조 - 일용 - 일대
	   		NDUnionDailyHalf	> 0 OR		--운전원외 - 노조 - 일용 - 반일
	   		NDUnionSignalDay	> 0	OR		--운전원외 - 노조 - 신호수 - 일대
	   		NDUnionSignalHalf	> 0	OR		--운전원외 - 노조 - 신호수 - 반일
	   		NDUnionEtcDay		> 0	OR		--운전원외 - 노조 - 기타 - 일대
	   		NDUnionEtcHalf		> 0	OR		--운전원외 - 노조 - 기타 - 반일
	   		NDUnionEtcMonth		> 0	)		--운전원외 - 노조 - 기타 - 월대
    UNION 
    -- 일용임금
	SELECT DISTINCT 
           A.WorkReportSeq 
	  FROM mnpt_TPJTWorkReport AS A WITH(NOLOCK)
		   INNER JOIN mnpt_TPJTWorkReportItem AS B WITH(NOLOCK)
				   ON B.CompanySeq		= A.CompanySeq
				  AND B.WorkReportSeq	= A.WorkReportSeq
      LEFT OUTER JOIN _TPJTProject  AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq	= @CompanySeq
       AND LEFT(A.WorkDate,6) BETWEEN @FrStdYM AND @ToStdYM
       AND ( @BizUnit = 0 OR C.BizUnit = @BizUnit ) 
	   AND (DDailyDay			> 0	OR		--운전원 - 일용 - 일대
	   		DDailyHalf			> 0	OR		--운전원 - 일용 - 반일
	   		NDDailyDay			> 0	OR		--운전원외 - 일용 - 일대
	   		NDDailyHalf			> 0	 )		--운전원외 - 일용 - 반일
	   AND B.IsCfm		= '1'
    
    --return 
    
    SELECT LEFT(A.WorkDate,6) AS StdYM, SUM(A.TodayQty) AS Qty, SUM(A.TodayMTWeight) AS MTQty
      INTO #Etc
      FROM mnpt_TPJTWorkReport      AS A 
      LEFT OUTER JOIN _TPJTProject  AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WorkDate,6) BETWEEN @FrStdYM AND @ToStdYM
       AND ( @BizUnit = 0 OR C.BizUnit = @BizUnit ) 
       AND NOT EXISTS (SELECT 1 FROM #UnionWorkReportSeq AS Z WHERE Z.WorkReportSeq = A.WorkReportSeq) 
       AND NOT EXISTS (SELECT 1 FROM #CNTRWorkType WHERE UMWorkType = A.UMWorkType)
     GROUP BY LEFT(A.WorkDate,6)

    
    UPDATE A
       SET Qty = B.Qty, 
           MTQty = B.MTQty, 
           IsExists = '1' 
      FROM #Result      AS A 
      JOIN #Etc  AS B ON ( B.StdYM = A.StdYM ) 
     WHERE ItemClassMSeq = 9999990
    ----------------------------------------------------------------------------------------
    -- 비노임, End 
    ----------------------------------------------------------------------------------------
    --return 
    ----------------------------------------------------------------------------------------
    -- 일용임금
    ----------------------------------------------------------------------------------------
    SELECT C.ItemClassMSeq, 
           1015935001 AS UMLoadType, 
           LEFT(A.WorkDate,6) AS StdYM, 
           SUM(A.SumAmt) AS SumAmt
      INTO #mnpt_TPJTEEDailyWage 
      FROM mnpt_TPJTEEDailyWage     AS A 
      LEFT OUTER JOIN _TPJTType     AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
      LEFT OUTER JOIN _VDAItemClass AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemClassSSeq = B.ItemClassSeq ) 
      --LEFT OUTER JOIN 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WorkDate,6) BETWEEN @FrStdYM AND @ToStdYM 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
     GROUP BY C.ItemClassMSeq, LEFT(WorkDate,6)
    

    

    UPDATE A
       SET DailyWageAmt = B.SumAmt, 
           IsExists = '1' 
      FROM #Result      AS A 
      JOIN #mnpt_TPJTEEDailyWage  AS B ON ( B.StdYM = A.StdYM AND B.ItemClassMSeq = A.ItemClassMSeq AND B.UMLoadType = A.UMLoadType ) 
    ----------------------------------------------------------------------------------------
    -- 일용임금, End 
    ----------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------
    -- 외부장비
    ----------------------------------------------------------------------------------------
    SELECT A.StdYM, 
           (CASE WHEN A.RentToolSeq <> 0 THEN B.ItemClassMSeq ELSE F.ItemClassMSeq END) AS ItemClassMSeq, 
           (CASE WHEN A.RentToolSeq <> 0 THEN B.UMLoadType ELSE 0 END) AS UMLoadType, 
           SUM(A.Amt) AS Amt
      INTO #RentToolAmt 
      FROM mnpt_TPJTEERentToolCalc          AS A 
      OUTER APPLY ( SELECT TOP 1 S.ItemClassMSeq, Y.UMLoadType
                      FROM mnpt_TPJTWorkReportItem          AS Z 
                      LEFT OUTER JOIN mnpt_TPJTWorkReport   AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WorkReportSeq = Z.WorkReportSeq ) 
                      LEFT OUTER JOIN _TPJTProject          AS R ON ( R.CompanySeq = @CompanySeq AND R.PJTSeq = Y.PJTSeq ) 
                      LEFT OUTER JOIN _TPJTType             AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.PJTTypeSeq = R.PJTTypeSeq ) 
                      LEFT OUTER JOIN _VDAItemClass         AS S ON ( S.CompanySeq = @CompanySeq AND S.ItemClassSSeq = Q.ItemClassSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND ISNULL(Z.RentToolSeq,0) = Z.RentToolSeq 
                  ) AS B 
      LEFT OUTER JOIN mnpt_TPJTEERentToolContractItem   AS C ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = A.ContractSeq AND C.COntractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TPJTProject                      AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTSeq = C.PJTSeq ) 
      LEFT OUTER JOIN _TPJTType                         AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTTypeSeq = D.PJTTypeSeq ) 
      LEFT OUTER JOIN _VDAItemClass                     AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemClassSSeq = E.ItemClassSeq ) 
                      --mnpt_TPJTWorkReportItem   AS B ON 
     WHERE A.CompanySeq = @CompanySeq 
       AND ISNULL((CASE WHEN A.RentToolSeq <> 0 THEN B.ItemClassMSeq ELSE F.ItemClassMSeq END),0) <> 0 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
     GROUP BY A.StdYM, (CASE WHEN A.RentToolSeq <> 0 THEN B.ItemClassMSeq ELSE F.ItemClassMSeq END), (CASE WHEN A.RentToolSeq <> 0 THEN B.UMLoadType ELSE 0 END)

     --select * From #RentToolAmt return 
    UPDATE A
       SET RentToolAmt = B.Amt, 
           IsExists = '1' 
      FROM #Result      AS A 
      JOIN #RentToolAmt  AS B ON ( B.StdYM = A.StdYM AND B.ItemClassMSeq = A.ItemClassMSeq AND B.UMLoadType = A.UMLoadType AND B.UMLoadType <> 0 ) 

    UPDATE Z
       SET RentToolAmt = Q.Amt, 
           IsExists = '1' 
      FROM #Result AS Z 
      JOIN ( 
            SELECT A.StdYM, A.ItemClassMSeq, MIN(A.IDX_NO) AS Min_IDX_NO
              FROM #Result      AS A 
              JOIN #RentToolAmt  AS B ON ( B.StdYM = A.StdYM AND B.ItemClassMSeq = A.ItemClassMSeq AND B.UMLoadType = 0 ) 
             GROUP BY A.StdYM, A.ItemClassMSeq 
           ) AS Y ON ( Y.StdYM = Z.StdYM AND Y.ItemClassMSeq = Z.ItemClassMSeq AND Y.Min_IDX_NO = Z.IDX_NO ) 
      JOIN #RentToolAmt  AS Q ON ( Q.StdYM = Z.StdYM AND Q.ItemClassMSeq = Z.ItemClassMSeq AND Q.UMLoadType = 0 ) 
    ----------------------------------------------------------------------------------------
    -- 외부장비, End 
    ----------------------------------------------------------------------------------------
    
    --select * from #Result 
    --return 

    SELECT StdYM        , 
           ItemClassMSeq, 
           CASE WHEN ItemClassMSeq = 9999990 THEN '비노임' 
                ELSE ISNULL(B.MinorName,'') + CASE WHEN ISNULL(C.MinorName,'') <> '' AND ISNULL(B.MinorName,'') <> '' 
                                                   THEN ' - ' + ISNULL(C.MinorName,'') 
                                                   ELSE '' 
                                                   END 
                END AS PJTTypeKindName,
           UMLoadType   , 
           Qty          ,
           MTQty        ,
           RTQty        ,
           ISNULL(GangSumAmt,0) + ISNULL(UtilityAmt,0) + ISNULL(UDDSumAmt,0) AS SumAmt  ,
           GangAmt      ,
           GangExtraAmt ,
           GangSumAmt   ,
           RetireAmt    ,
           ModernAmt    ,
           TraingAmt    ,
           WelfareAmt   ,
           MedicalAmt   ,
           NationalAmt  ,
           SafetyAmt    ,
           SocietyAmt   ,
           UtilityAmt   ,
           UDDSumAmt    ,
           ISNULL(GangSumAmt,0) + ISNULL(UtilityAmt,0) AS UnionSumAmt  ,
           DailyWageAmt ,
           RentToolAmt  ,
           ISNULL(DailyWageAmt,0) + ISNULL(RentToolAmt,0) AS RentSumAmt, 
           1 AS Sort 
      FROM #Result AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ItemClassMSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMLoadType ) 
     WHERE IsExists = '1'
    UNION ALL 
    SELECT StdYM, 
           9999999, 
           '계', 
           0,          
           SUM(Qty         ) AS Qty         ,        
           SUM(MTQty       ) AS MTQty       ,        
           SUM(RTQty       ) AS RTQty       ,        
           SUM(SumAmt      ) AS SumAmt      ,        
           SUM(GangAmt     ) AS GangAmt     ,        
           SUM(GangExtraAmt) AS GangExtraAmt,        
           SUM(GangSumAmt  ) AS GangSumAmt  ,        
           SUM(RetireAmt   ) AS RetireAmt   ,        
           SUM(ModernAmt   ) AS ModernAmt   ,        
           SUM(TraingAmt   ) AS TraingAmt   ,        
           SUM(WelfareAmt  ) AS WelfareAmt  ,        
           SUM(MedicalAmt  ) AS MedicalAmt  ,        
           SUM(NationalAmt ) AS NationalAmt ,        
           SUM(SafetyAmt   ) AS SafetyAmt   ,        
           SUM(SocietyAmt  ) AS SocietyAmt  ,        
           SUM(UtilityAmt  ) AS UtilityAmt  ,        
           SUM(UDDSumAmt   ) AS UDDSumAmt   ,        
           SUM(UnionSumAmt ) AS UnionSumAmt ,        
           SUM(DailyWageAmt) AS DailyWageAmt,        
           SUM(RentToolAmt ) AS RentToolAmt ,        
           SUM(RentSumAmt  ) AS RentSumAmt  , 
           2 AS Sort 
      FROM #Result AS A 
     WHERE IsExists = '1'
     GROUP BY StdYM 
     ORDER BY StdYM, Sort, ItemClassMSeq 

    RETURN 
go
begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
IF @CONST_#BIZ_IN_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , FrStdYM CHAR(6), ToStdYM CHAR(6), BizUnit INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock1 = 1

END

IF @CONST_#BIZ_OUT_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , FrStdYM CHAR(6), ToStdYM CHAR(6), StdYM CHAR(6), PJTTypeKindName NVARCHAR(200), Qty DECIMAL(19, 5), MTQty DECIMAL(19, 5), RTQty DECIMAL(19, 5), SumAmt DECIMAL(19, 5), GangAmt DECIMAL(19, 5), GangExtraAmt DECIMAL(19, 5), GangSumAmt DECIMAL(19, 5), RetireAmt DECIMAL(19, 5), ModernAmt DECIMAL(19, 5), TraingAmt DECIMAL(19, 5), WelfareAmt DECIMAL(19, 5), MedicalAmt DECIMAL(19, 5), NationalAmt DECIMAL(19, 5), SafetyAmt DECIMAL(19, 5), SocietyAmt DECIMAL(19, 5), UtilityAmt DECIMAL(19, 5), UDDSumAmt DECIMAL(19, 5), UnionSumAmt DECIMAL(19, 5), DailyWageAmt DECIMAL(19, 5), RentToolAmt DECIMAL(19, 5), RentSumAmt DECIMAL(19, 5), ItemClassMSeq INT, BizUnit INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, FrStdYM, ToStdYM, BizUnit) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'201712', N'201712', N''
IF @@ERROR <> 0 RETURN


DECLARE @HasError           NCHAR(1)
        , @UseTransaction   NCHAR(1)
        -- 내부 SP용 파라메터
        , @ServiceSeq       INT
        , @MethodSeq        INT
        , @WorkingTag       NVARCHAR(10)
        , @CompanySeq       INT
        , @LanguageSeq      INT
        , @UserSeq          INT
        , @PgmSeq           INT
        , @IsTransaction    BIT

SET @HasError = N'0'
SET @UseTransaction = N'0'

BEGIN TRY

SET @ServiceSeq     = 13820075
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820077
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEEUnionSumListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:
END TRY
BEGIN CATCH
-- SQL 오류인 경우는 여기서 처리가 된다
    IF @UseTransaction = N'1'
        ROLLBACK TRAN
    
    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
            , @ERROR_SEVERITY   INT
            , @ERROR_STATE      INT
            , @ERROR_PROCEDURE  NVARCHAR(128)

    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
            , @ERROR_STATE      = ERROR_STATE() 
            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

    RETURN
END CATCH

-- SQL 오류를 제외한 체크로직으로 발생된 오류는 여기서 처리
IF @HasError = N'1' AND @UseTransaction = N'1'
    ROLLBACK TRAN
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 