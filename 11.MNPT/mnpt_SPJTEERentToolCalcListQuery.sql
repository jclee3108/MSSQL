     
IF OBJECT_ID('mnpt_SPJTEERentToolCalcListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolCalcListQuery      
GO      
      
-- v2018.04.04
      
-- 외부장비임차정산조회-조회 by 이재천  
CREATE PROC mnpt_SPJTEERentToolCalcListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

    DECLARE @FrCalcYM       NCHAR(6), 
            @ToCalcYM       NCHAR(6), 
            @BizUnit        INT, 
            @UMRentType     INT, 
            @UMToolType     INT, 
            @PJTName        NVARCHAR(200), 
            @SlipExistsSeq  INT, 
            @EmpSeq         INT,
            @DeptSeq        INT,
            @RentToolSeq    INT,
            @UMRentKind     INT,
            @FrWorkDate     NCHAR(8), 
            @ToWorkDate     NCHAR(8), 
            @RentCustSeq    INT

      
    SELECT @FrCalcYM       = ISNULL( FrCalcYM, '' ), 
           @ToCalcYM       = ISNULL( ToCalcYM, '' ), 
           @BizUnit        = ISNULL( BizUnit, 0 ), 
           @UMRentType     = ISNULL( UMRentType    , 0 ), 
           @UMToolType     = ISNULL( UMToolType    , 0 ), 
           @PJTName        = ISNULL( PJTName       , '' ), 
           @SlipExistsSeq  = ISNULL( SlipExistsSeq , 0 ), 
           @EmpSeq         = ISNULL( EmpSeq        , 0 ), 
           @DeptSeq        = ISNULL( DeptSeq       , 0 ), 
           @RentToolSeq    = ISNULL( RentToolSeq   , 0 ), 
           @UMRentKind     = ISNULL( UMRentKind    , 0 ), 
           @FrWorkDate     = ISNULL( FrWorkDate    , '' ), 
           @ToWorkDate     = ISNULL( ToWorkDate    , '' ), 
           @RentCustSeq    = ISNULL( RentCustSeq   , 0 )
      FROM #BIZ_IN_DataBlock1    
    
    IF @ToCalcYM = '' SELECT @ToCalcYM = '999912'
    IF @ToWorkDate = '' SELECT @ToWorkDate = '99991231'
   
    --   select * From #Result 
    --return 

    SELECT A.CalcSeq, 
           A.StdYM AS CalcYM, 
           A.BizUnit, 
           B.BizUnitName, 
           A.RentCustSeq,
           C.CustName AS RentCustName, 
           A.UMRentType, 
           D.MinorName AS UMRentTypeName, 
           A.UMRentKind, 
           E.MinorName AS UMRentKindName, 
           --A.RentToolSeq, 
           --F.EquipmentSName AS RentToolName, 
           CASE WHEN A.UMRentKind = 1016351003 THEN 0 ELSE A.RentToolSeq END AS RentToolSeq,  
           CASE WHEN A.UMRentKind = 1016351003 THEN G.TextRentToolName  ELSE F.EquipmentSName END AS RentToolName,  
           A.WorkDate, 
           A.Qty, 
           A.Price, 
           A.Amt, 
           A.AddListName, 
           A.AddQty, 
           A.AddPrice,
           A.AddAmt, 
           A.RentAmt, 
           A.RentVAT, 
           A.RentAmt + A.RentVAT AS TotalAmt, 
           A.Remark, 
           A.SlipSeq, 
           CASE WHEN A.SlipSeq = 0 OR A.SlipSeq IS NULL THEN 2 ELSE 1 END AS SlipExistsSeq, 
           A.ContractSeq, 
           A.ContractSerl, 
           G.PJTSeq, 
           H.DeptSeq, 
           H.EmpSeq
      INTO #Main_Data
      FROM mnpt_TPJTEERentToolCalc      AS A 
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RentCustSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSEq = A.UMRentKind ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS F ON ( F.CompanySeq = @CompanySeq AND F.EquipmentSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN mnpt_TPJTEERentToolContractItem AS G ON ( G.CompanySeq = @CompanySEq AND G.ContractSeq = A.ContractSeq AND G.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN mnpt_TPJTEERentToolContract     AS H ON ( H.CompanySeq = @CompanySeq AND H.ContractSeq = G.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( A.StdYM BETWEEN @FrCalcYM AND @ToCalcYM ) 
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( @UMRentType = 0 OR A.UMRentType = @UMRentType ) 
       AND ( @UMToolType = 0 OR F.UMToolType = @UMToolType ) 
       AND ( @SlipExistsSeq = 0 OR CASE WHEN A.SlipSeq = 0 OR A.SlipSeq IS NULL THEN 2 ELSE 1 END = @SlipExistsSeq ) 
       AND ( @RentToolSeq = 0 OR A.RentToolSeq = @RentToolSeq ) 
       AND ( @UMRentKind = 0 OR A.UMRentKind = @UMRentKind ) 
       AND ( @RentCustSeq = 0 OR A.RentCustSeq = @RentCustSeq ) 

    --select * from #Main_Data 
    --return 

     -- 결과테이블     
    CREATE TABLE #Result 
    ( 
        BizUnitName     NVARCHAR(200), 
        BizUnit         INT, 
        AccUnitName     NVARCHAR(200), 
        AccUnit         INT, 
        RentCustName    NVARCHAR(200), 
        RentCustSeq     INT, 
        UMRentTypeName  NVARCHAR(200), 
        UMRentType      INT, 
        UMRentKindName  NVARCHAR(200), 
        UMRentKind      INT, 
        RentToolSeq     INT, 
        RentToolName    NVARCHAR(200), 
        WorkDate        NCHAR(8),
        WorkDateSub     NCHAR(8), 
        PJTNames        NVARCHAR(500), 
        RentSrtDate     NCHAR(8), 
        RentEndDate     NCHAR(8), 
        WorkDateCnt     INT, 
        NightCnt        INT, 
        HolidayCnt      INT, 
        EmpSeq          INT, 
        DeptSeq         INT, 
        IsContract      NCHAR(1), 
        ContractSeq     INT, 
        ContractSerl    INT, 
        PJTSeq          INT 
    ) 

    ------------------------------------------------------------------------
    -- 외부장비임차계약
    ------------------------------------------------------------------------
    SELECT A.BizUnit, 
           A.RentCustSeq , 
           A.RentSrtDate, 
           A.RentEndDate, 
           B.UMRentKind, 
           B.RentToolSeq, 
           B.TextRentToolName, 
           B.UMRentType, 
           B.Qty, 
           B.Price, 
           B.Amt, 
           A.EmpSeq, 
           A.DeptSeq, 
           A.ContractSeq, 
           B.ContractSerl, 
           B.PJTSeq 
      INTO #Contract
      FROM mnpt_TPJTEERentToolContract      AS A 
      JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #Main_Data 
                    WHERE ContractSeq = A.ContractSeq
                      AND ContractSerl = B.ContractSerl 
                  )

    ------------------------------------------------------------------------
    -- 일대,
    ------------------------------------------------------------------------
    SELECT DISTINCT 
           B.UMWorkTeam, 
           B.PJTSeq, 
           F.BizUnitName, 
           C.BizUnit, 
           G.AccUnitName, 
           F.AccUnit, 
           H.CustName AS RentCustName, 
           C.RentCustSeq, 
           E.MinorName AS UMRentTypeName, 
           C.UMRentType, 
           D.MinorName AS UMRentKindName, 
           C.UMRentKind, 
           CASE WHEN C.UMRentKind = 1016351003 THEN 0 ELSE A.RentToolSeq END AS RentToolSeq,  
           CASE WHEN C.UMRentKind = 1016351003 THEN C.TextRentToolName  ELSE I.EquipmentSName END AS RentToolName,  
           B.WorkDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq, 
           C.ContractSeq, 
           C.ContractSerl, 
           C.PJTSeq AS ContractPJTSeq 
      INTO #Daily 
      FROM mnpt_TPJTWorkReportItem          AS A 
                 JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject          AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = B.PJTSeq ) 
                 JOIN #Contract             AS C ON ( C.BizUnit = J.BizUnit 
                                                  AND C.RentToolSeq = A.RentToolSeq 
                                                  AND B.WorkDate BETWEEN C.RentSrtDate AND C.RentEndDate 
                                                  AND C.UMRentType <> 1016305003 
                                                    ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMRentKind ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.UMRentType ) 
      LEFT OUTER JOIN _TDABizUnit           AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = C.BizUnit ) 
      LEFT OUTER JOIN _TDAAccUnit           AS G ON ( G.CompanySeq = @CompanySeq AND G.AccUnit = F.AccUnit ) 
      LEFT OUTER JOIN _TDACust              AS H ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = C.RentCustSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment     AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.RentToolSeq <> 0 AND A.RentToolSeq IS NOT NULL) -- 임차장비만 보기 
       AND A.IsCfm = '1' 
       AND EXISTS (SELECT 1 
                     FROM #Main_Data 
                     WHERE ContractSeq = C.ContractSeq 
                       AND ContractSerl = C.ContractSerl 
                  )
       AND ( @PJTName = '' OR J.PJTName LIKE @PJTName + '%' ) 

       --AND ( B.WorkDate BETWEEN @FrWorkDate AND @ToWorkDate ) 
    
    -- 작업프로젝트
    SELECT A.RentToolSeq, MAX(B.PJTName) + CASE WHEN SUM(A.Cnt) > 1 THEN ' 외 ' + CONVERT(NVARCHAR(100),SUM(A.Cnt) - 1) + '건' ELSE '' END AS WorkPJTName
      INTO #WorkPJTName
      FROM ( 
            SELECT DISTINCT RentToolSeq, PJTSeq, 1 AS Cnt 
              FROM #Daily 
           ) AS A 
      LEFT OUTER JOIN _TPJTProject AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     GROUP BY RentToolSeq 

    -- 작업일수 
    SELECT RentToolSeq, WorkDate, SUM(Cnt) AS DayCnt 
      INTO #DayCnt 
      FROM ( 
            SELECT DISTINCT RentToolSeq, WorkDate , 1 AS Cnt 
              FROM #Daily 
           ) AS A 
     GROUP BY RentToolSeq, WorKDate 

    -- 야간일수 
    SELECT RentToolSeq, SUM(Cnt) AS NightCnt 
      INTO #NightCnt 
      FROM ( 
            SELECT DISTINCT RentToolSeq, UMWorkTeam, 1 AS Cnt 
              FROM #Daily 
             WHERE UMWorkTeam = 6017002 -- 야간
           ) AS A 
     GROUP BY RentToolSeq 

    -- 휴일일수 
    SELECT RentToolSeq, SUM(Cnt) AS HolidayCnt
      INTO #HolidayCnt
      FROM ( 
            SELECT DISTINCT RentToolSeq, WorkDate, 1 AS Cnt 
              FROM #Daily AS A 
            WHERE DATENAME(WEEKDAY, A.WorkDate) IN ( '토요일', '일요일' ) 
    
            UNION
    
            SELECT DISTINCT RentToolSeq, WorkDate, 1 AS Cnt 
              FROM #Daily AS A 
              LEFT OUTER JOIN (
		    	                SELECT Z.Solar
		    		                FROM _TCOMCalendarHolidayPRWkUnit AS Z
		    			            LEFT OUTER JOIN _TDAUMinorValue   AS Y ON Z.CompanySeq = @CompanySeq
		    					                                        AND Y.ValueSeq = Z.DayTypeSeq
		    					                                        AND Y.MajorSeq = 1015916
		    					                                        AND Y.Serl = 1000001 
		    		                WHERE Z.CompanySeq	= @CompanySeq 
                                        AND Y.CompanySeq IS NOT NULL 
		    		                GROUP BY Z.Solar
		    	              ) AS H ON ( H.Solar = A.WorkDate ) 
             WHERE H.Solar IS NOT NULL 
           ) AS A 
     GROUP BY A.RentToolSeq
    
    INSERT INTO #Result 
    (
        BizUnitName    , BizUnit        , AccUnitName    , AccUnit        , RentCustName   , 
        RentCustSeq    , UMRentTypeName , UMRentType     , UMRentKindName , UMRentKind     , 
        RentToolSeq    , RentToolName   , WorkDate       , PJTNames       , RentSrtDate    , 
        RentEndDate    , WorkDateCnt    , NightCnt       , HolidayCnt     , WorkDateSub    , 
        EmpSeq         , DeptSeq        , IsContract     , ContractSeq    , ContractSerl   ,
        PJTSeq 
    )
    SELECT A.BizUnitName, 
           A.BizUnit, 
           A.AccUnitName, 
           A.AccUnit, 
           A.RentCustName, 
           A.RentCustSeq, 
           A.UMRentTypeName, 
           A.UMRentType, 
           A.UMRentKindName, 
           A.UMRentKind, 
           A.RentToolSeq, 
           A.RentToolName, 
           A.WorkDate,
           B.WorkPJTName AS PJTNames, 
           A.RentSrtDate AS RentSrtDate, 
           A.RentEndDate AS RentEndDate, 
           ISNULL(C.DayCnt,0) AS WorkDateCnt, 
           ISNULL(D.NightCnt,0) AS NightCnt, 
           ISNULL(E.HolidayCnt,0) AS HolidayCnt, 
           A.WorkDate, 
           A.EmpSeq, 
           A.DeptSeq, 
           '0' AS IsContract, 
           A.ContractSeq, 
           A.ContractSerl, 
           A.ContractPJTSeq
      FROM #Daily AS A 
      LEFT OUTER JOIN #WorkPJTName  AS B ON ( B.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #DayCnt       AS C ON ( C.RentToolSeq = A.RentToolSeq AND C.WorkDate = A.WorkDate ) 
      LEFT OUTER JOIN #NightCnt     AS D ON ( D.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #HolidayCnt   AS E ON ( E.RentToolSeq = A.RentToolSeq ) 
    ------------------------------------------------------------------------
    -- 일대 or 계약이 없는 건, End 
    ------------------------------------------------------------------------
    
    --select * from #Main_Data 
    --return 
    ------------------------------------------------------------------------
    -- 월대, Srt 
    ------------------------------------------------------------------------
    SELECT DISTINCT 
           B.UMWorkTeam, 
           B.PJTSeq, 
           F.BizUnitName, 
           C.BizUnit, 
           G.AccUnitName, 
           F.AccUnit, 
           H.CustName AS RentCustName, 
           C.RentCustSeq, 
           E.MinorName AS UMRentTypeName, 
           C.UMRentType, 
           D.MinorName AS UMRentKindName, 
           C.UMRentKind, 
           CASE WHEN C.UMRentKind = 1016351003 THEN 0 ELSE A.RentToolSeq END AS RentToolSeq,  
           CASE WHEN C.UMRentKind = 1016351003 THEN C.TextRentToolName  ELSE I.EquipmentSName END AS RentToolName,  
           LEFT(B.WorkDate,6) + '01' AS WorkDateSub, 
           B.WorKDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq, 
           C.ContractSeq, 
           C.ContractSerl, 
           C.PJTSeq AS ContractPJTSeq 
      INTO #Monthliy
      FROM mnpt_TPJTWorkReportItem          AS A 
                 JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject          AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = B.PJTSeq ) 
                 JOIN #Contract             AS C ON ( C.BizUnit = J.BizUnit 
                                                  AND C.RentToolSeq = A.RentToolSeq 
                                                  AND B.WorkDate BETWEEN C.RentSrtDate AND C.RentEndDate 
                                                    ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMRentKind ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.UMRentType ) 
      LEFT OUTER JOIN _TDABizUnit           AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = C.BizUnit ) 
      LEFT OUTER JOIN _TDAAccUnit           AS G ON ( G.CompanySeq = @CompanySeq AND G.AccUnit = F.AccUnit ) 
      LEFT OUTER JOIN _TDACust              AS H ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = C.RentCustSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment     AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.RentToolSeq <> 0 AND A.RentToolSeq IS NOT NULL) -- 임차장비만 보기 
       AND A.IsCfm = '1' 
       AND C.UMRentType IN ( 1016305002, 1016305003 ) 
       AND EXISTS (SELECT 1 
                    FROM #Main_Data 
                   WHERE ContractSeq = C.ContractSeq 
                     AND ContractSerl = C.ContractSerl 
                  ) 
       AND ( @PJTName = '' OR J.PJTName LIKE @PJTName + '%' ) 
    
    --select * From #Daily 
    --return 
    
    -- 작업프로젝트
    SELECT A.RentToolSeq, MAX(B.PJTName) + CASE WHEN SUM(A.Cnt) > 1 THEN ' 외 ' + CONVERT(NVARCHAR(100),SUM(A.Cnt) - 1) + '건' ELSE '' END AS WorkPJTName
      INTO #WorkPJTName2
      FROM ( 
            SELECT DISTINCT RentToolSeq, PJTSeq, 1 AS Cnt 
              FROM #Monthliy 
           ) AS A 
      LEFT OUTER JOIN _TPJTProject AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     GROUP BY RentToolSeq 

    -- 작업일수 
    SELECT RentToolSeq, SUM(Cnt) AS DayCnt 
      INTO #DayCnt2
      FROM ( 
            SELECT DISTINCT RentToolSeq, WorkDate , 1 AS Cnt 
              FROM #Monthliy 
           ) AS A 
     GROUP BY RentToolSeq 

    -- 야간일수 
    SELECT RentToolSeq, SUM(Cnt) AS NightCnt 
      INTO #NightCnt2
      FROM ( 
            SELECT DISTINCT RentToolSeq, UMWorkTeam, 1 AS Cnt 
              FROM #Monthliy 
             WHERE UMWorkTeam = 6017002 -- 야간
           ) AS A 
     GROUP BY RentToolSeq 

    -- 휴일일수 
    SELECT RentToolSeq, SUM(Cnt) AS HolidayCnt
      INTO #HolidayCnt2
      FROM ( 
            SELECT DISTINCT RentToolSeq, WorkDate, 1 AS Cnt 
              FROM #Monthliy AS A 
            WHERE DATENAME(WEEKDAY, A.WorkDate) IN ( '토요일', '일요일' ) 
    
            UNION
    
            SELECT DISTINCT RentToolSeq, WorkDate, 1 AS Cnt 
              FROM #Monthliy AS A 
              LEFT OUTER JOIN (
		    	                SELECT Z.Solar
		    		                FROM _TCOMCalendarHolidayPRWkUnit AS Z
		    			            LEFT OUTER JOIN _TDAUMinorValue   AS Y ON Z.CompanySeq = @CompanySeq
		    					                                        AND Y.ValueSeq = Z.DayTypeSeq
		    					                                        AND Y.MajorSeq = 1015916
		    					                                        AND Y.Serl = 1000001 
		    		                WHERE Z.CompanySeq	= @CompanySeq 
                                        AND Y.CompanySeq IS NOT NULL 
		    		                GROUP BY Z.Solar
		    	              ) AS H ON ( H.Solar = A.WorkDate ) 
             WHERE H.Solar IS NOT NULL 
           ) AS A 
     GROUP BY A.RentToolSeq
    
    INSERT INTO #Result 
    (
        BizUnitName    , BizUnit        , AccUnitName    , AccUnit        , RentCustName   , 
        RentCustSeq    , UMRentTypeName , UMRentType     , UMRentKindName , UMRentKind     , 
        RentToolSeq    , RentToolName   , WorkDate       , PJTNames       , RentSrtDate    , 
        RentEndDate    , WorkDateCnt    , NightCnt       , HolidayCnt     , WorkDateSub    , 
        EmpSeq         , DeptSeq        , IsContract     , ContractSeq    , ContractSerl   , 
        PJTSeq 
    )
    SELECT DISTINCT 
           A.BizUnitName, 
           A.BizUnit, 
           A.AccUnitName, 
           A.AccUnit, 
           A.RentCustName, 
           A.RentCustSeq, 
           A.UMRentTypeName, 
           A.UMRentType, 
           A.UMRentKindName, 
           A.UMRentKind, 
           A.RentToolSeq, 
           A.RentToolName, 
           '' AS WorkDate,
           B.WorkPJTName AS PJTNames, 
           A.RentSrtDate AS RentSrtDate, 
           A.RentEndDate AS RentEndDate, 
           ISNULL(C.DayCnt,0) AS WorkDateCnt, 
           ISNULL(D.NightCnt,0) AS NightCnt, 
           ISNULL(E.HolidayCnt,0) AS HolidayCnt, 
           A.WorkDateSub, 
           A.EmpSeq, 
           A.DeptSeq, 
           '1' AS IsContract, 
           A.ContractSeq, 
           A.ContractSerl, 
           A.ContractPJTSeq 
      FROM #Monthliy AS A 
      LEFT OUTER JOIN #WorkPJTName  AS B ON ( B.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #DayCnt       AS C ON ( C.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #NightCnt     AS D ON ( D.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #HolidayCnt   AS E ON ( E.RentToolSeq = A.RentToolSeq ) 
    ------------------------------------------------------------------------
    -- 월대, End 
    ------------------------------------------------------------------------
    --select * from _TCAPgm where caption like '%외부장비%'
   
    -- 자동전표환경설정 계정과목가져오기 
    SELECT DISTINCT 
           C.AccSeq,
           D.AccName,
           C.RowSort, 
           C.IsAnti, 
           D.SMAccType
      INTO #Acc
      FROM _TACSlipKind             AS A 
      JOIN _TACSlipAutoEnv          AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipKindNo = A.SlipKindNo ) 
      JOIN _TACSlipAutoEnvRow       AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipAutoEnvSeq = B.SlipAutoEnvSeq ) 
      JOIN _TDAAccount              AS D ON ( D.CompanySeq = @CompanySeq AND D.AccSeq = C.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.PgmSeq     = 13820060
     ORDER BY C.RowSort
    

    DECLARE @EnvValue1  INT 
    SELECT @EnvValue1 = (SELECT EnvValue FROM mnpt_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 1)

    SELECT BizUnit,
           EquipmentSeq, 
           CCtrSeq, 
           CarModel
      INTO #EquipmentSeqCCtr
      FROM mnpt_TPDEquipment AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizUnit = @EnvValue1
    UNION ALL 
    SELECT @EnvValue1 AS BizUnit,
           EquipmentSeq, 
           CopyCCtrSeq AS CCtrSeq, 
           CarModel
      FROM mnpt_TPDEquipment AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CopyCCtrSeq <> 0 
    UNION ALL 
    SELECT A.BizUnit,
           EquipmentSeq, 
           CCtrSeq, 
           CarModel
      FROM mnpt_TPDEquipment AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.CopyCCtrSeq <> 0 
    

    SELECT A.BizUnit, 
           A.PJTSeq, 
           A.CCtrSeq
      INTO #PJTCCtr
      FROM _TPJTProject     AS A 
      JOIN mnpt_TPJTProject AS B ON ( B.CompanySeq = A.CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Contract WHERE PJTSeq = A.PJTSeq ) 
       AND A.BizUnit = @EnvValue1 
    UNION ALL 
    SELECT @EnvValue1 AS BizUnit,
           A.PJTSeq, 
           B.CopyCCtrSeq AS CCtrSeq 
      FROM _TPJTProject     AS A 
      JOIN mnpt_TPJTProject AS B ON ( B.CompanySeq = A.CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.CopyCCtrSeq <> 0 
       AND EXISTS (SELECT 1 FROM #Contract WHERE PJTSeq = A.PJTSeq ) 
    UNION ALL 
    SELECT A.BizUnit AS BizUnit,
           A.PJTSeq, 
           A.CCtrSeq
      FROM _TPJTProject     AS A 
      JOIN mnpt_TPJTProject AS B ON ( B.CompanySeq = A.CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.CopyCCtrSeq <> 0 
       AND EXISTS (SELECT 1 FROM #Contract WHERE PJTSeq = A.PJTSeq ) 


    SELECT A.CalcSeq, 
           A.CalcYM, 
           A.BizUnit, 
           A.BizUnitName, 
           A.RentCustSeq,
           A.RentCustName, 
           A.UMRentType, 
           A.UMRentTypeName, 
           A.UMRentKind, 
           A.UMRentKindName, 
           A.RentToolSeq, 
           A.RentToolName, 
           CASE WHEN A.UMRentType <> 1016305003 AND A.UMRentKind = 1016351001 THEN A.WorkDate ELSE '' END WorkDate, 
           --A.WorkDate, 
           A.Qty, 
           A.Price, 
           A.Amt, 
           A.AddListName, 
           A.AddQty, 
           A.AddAmt, 
           A.AddPrice,
           A.RentAmt, 
           A.RentVAT, 
           A.TotalAmt, 
           A.Remark, 
           A.SlipSeq, 
           A.SlipExistsSeq, 
           B.PJTNames, 
           B.RentSrtDate, 
           B.RentEndDate, 
           B.EmpSeq, 
           B.DeptSeq, 
           M.EmpName, 
           N.DeptName, 
           B.WorkDateCnt, 
           B.HolidayCnt, 
           B.NightCnt, 
           D.AccSeq, 
           D.AccName, 
           E.AccSeq AS VATAccSeq, 
           E.AccName AS VATAccName ,
           F.AccSeq AS OppAccSeq, 
           F.AccName AS OppAccName, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN I.CCtrSeq ELSE L.CCtrSeq END AS CCtrSeq, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN J.CCtrName ELSE L.CCtrName END AS CCtrName, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN J.UMCostType ELSE L.UMCostType END AS UMCostType, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN K.MinorName ELSE L.UMCostTypeName END AS UMCostTypeName, 
           CASE WHEN O.CCtrSeq IS NOT NULL THEN O.CCtrSeq 
                WHEN I.CCtrSeq IS NOT NULL THEN I.CCtrSeq 
                ELSE P.CCtrSeq 
                END AS CCtrSeq, 
           J.CCtrName, 
           J.UMCostType, 
           K.MinorName AS UMCostTypeName, 
           A.ContractSeq, 
           A.ContractSerl 
      FROM #Main_Data AS A 
      LEFT OUTER JOIN #Result AS B ON ( B.BizUnit = A.BizUnit 
                                    AND B.RentCustSeq = A.RentCustSeq 
                                    AND B.UMRentType = A.UMRentType
                                    AND B.UMRentKind = A.UMRentKind 
                                    AND B.RentToolSeq = A.RentToolSeq 
                                    AND B.WorkDateSub = A.WorkDate 
                                    AND B.ContractSeq = A.ContractSeq
                                    AND B.ContractSerl = A.ContractSerl 
                                      ) 
      LEFT OUTER JOIN ( -- 임차계정
                        SELECT TOP 1 AccSeq, AccName
                          FROM #Acc AS Z 
                         WHERE IsAnti = '0'
                        ORDER BY RowSort
                      ) AS D ON ( 1 = 1 ) 
      LEFT OUTER JOIN ( -- 부가세계정
                        SELECT TOP 1 AccSeq, AccName
                          FROM #Acc AS Z 
                         WHERE IsAnti = '0'
                           AND SMAccType = 4002009
                        ORDER BY RowSort
                      ) AS E ON ( 1 = 1 ) 
      LEFT OUTER JOIN ( -- 상대계정
                        SELECT TOP 1 AccSeq, AccName
                          FROM #Acc AS Z 
                         WHERE IsAnti = '1'
                        ORDER BY RowSort
                      ) AS F ON ( 1 = 1 ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
      --LEFT OUTER JOIN _TDACCtr          AS J ON ( J.CompanySeq = @CompanySeq AND J.CCtrSeq = I.CCtrSeq ) 
      --LEFT OUTER JOIN _TDAUMinor        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = J.UMCostType ) 
      --OUTER APPLY ( 
      --                SELECT TOP 1 II.CCtrSeq, JJ.CCtrName, KK.MinorName AS UMCostTypeName, JJ.UMCostType 
      --                  FROM #Result AS Z 
      --                  LEFT OUTER JOIN mnpt_TPDEquipment AS II ON ( II.CompanySeq = @CompanySeq AND II.EquipmentSeq = Z.RentToolSeq ) 
      --                  LEFT OUTER JOIN _TDACCtr          AS JJ ON ( JJ.CompanySeq = @CompanySeq AND JJ.CCtrSeq = II.CCtrSeq ) 
      --                  LEFT OUTER JOIN _TDAUMinor        AS KK ON ( KK.CompanySeq = @CompanySeq AND KK.MinorSeq = JJ.UMCostType ) 
      --                 WHERE Z.UMRentKind = 1016351001 -- 장비
      --                   AND Z.BizUnit = A.BizUnit 
      --                   AND Z.RentCustSeq = A.RentCustSeq 
      --                   AND Z.UMRentType = Z.UMRentType 
      --                 ORDER BY Z.UMRentKind, Z.UMRentType, Z.WorkDate 
      --            ) AS L
      LEFT OUTER JOIN _TDAEmp           AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN #PJTCCtr          AS O ON ( O.PJTSeq = A.PJTSeq AND O.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _THROrgDeptCCtr   AS P ON ( P.CompanySeq = @CompanySeq AND P.DeptSeq = A.DeptSeq AND A.CalcYM BETWEEN P.BegYm AND P.EndYM )

      LEFT OUTER JOIN _TDACCtr          AS J ON ( J.CompanySeq = @CompanySeq 
                                              AND J.CCtrSeq = CASE WHEN O.CCtrSeq IS NOT NULL THEN O.CCtrSeq 
                                                                   WHEN I.CCtrSeq IS NOT NULL THEN I.CCtrSeq 
                                                                   ELSE P.CCtrSeq 
                                                                   END
                                                ) 
      LEFT OUTER JOIN _TDAUMinor        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = J.UMCostType ) 
     WHERE ( @EmpSeq = 0 OR ISNULL(B.EmpSeq,A.EmpSeq) = @EmpSeq ) 
       AND ( @DeptSeq = 0 OR ISNULL(B.DeptSeq,A.DeptSeq) = @DeptSeq ) 
       AND ( CASE WHEN A.UMRentType <> 1016305003 AND A.UMRentKind = 1016351001 THEN A.WorkDate ELSE '' END BETWEEN @FrWorkDate AND @ToWorkDate ) 
     ORDER BY A.BizUnitName, A.CalcYM, A.RentCustName, A.UMRentType, A.UMRentKind, A.RentToolName, A.WorkDate 
        
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

        , BizUnit NVARCHAR(100), RentCustSeq NVARCHAR(100), UMRentType NVARCHAR(100), UMRentKind NVARCHAR(100), RentToolSeq NVARCHAR(100), EmpSeq NVARCHAR(100), DeptSeq NVARCHAR(100), PJTName NVARCHAR(100), FrCalcYM NVARCHAR(100), ToCalcYM NVARCHAR(100), FrWorkDate NVARCHAR(100), ToWorkDate NVARCHAR(100), UMToolType NVARCHAR(100), SlipExistsSeq NVARCHAR(100)
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

        , BizUnit NVARCHAR(100), RentCustSeq NVARCHAR(100), UMRentType NVARCHAR(100), UMRentKind NVARCHAR(100), RentToolSeq NVARCHAR(100), EmpSeq NVARCHAR(100), DeptSeq NVARCHAR(100), PJTName NVARCHAR(100), SlipExistsName NVARCHAR(100), FrCalcYM NVARCHAR(100), ToCalcYM NVARCHAR(100), FrWorkDate NVARCHAR(100), ToWorkDate NVARCHAR(100), UMToolType NVARCHAR(100), SlipExistsSeq NVARCHAR(100), BizUnitName NVARCHAR(100), CalcYM NVARCHAR(100), RentCustName NVARCHAR(100), UMRentTypeName NVARCHAR(100), UMRentKindName NVARCHAR(100), UMToolTypeName NVARCHAR(100), RentToolName NVARCHAR(100), WorkDate NVARCHAR(100), Qty NVARCHAR(100), Price NVARCHAR(100), Amt NVARCHAR(100), AddListName NVARCHAR(100), AddQty NVARCHAR(100), AddPrice NVARCHAR(100), AddAmt NVARCHAR(100), RentAmt NVARCHAR(100), RentVAT NVARCHAR(100), TotalAmt NVARCHAR(100), Remark NVARCHAR(100), PJTNames NVARCHAR(100), RentSrtDate NVARCHAR(100), RentEndDate NVARCHAR(100), EmpName NVARCHAR(100), DeptName NVARCHAR(100), WorkDateCnt NVARCHAR(100), NightCnt NVARCHAR(100), HolidayCnt NVARCHAR(100), AccName NVARCHAR(100), VATAccName NVARCHAR(100), OppAccName NVARCHAR(100), CCtrName NVARCHAR(100), UMCostTypeName NVARCHAR(100), SlipID NVARCHAR(100), SlipSeq NVARCHAR(100), CalcSeq NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, BizUnit, RentCustSeq, UMRentType, UMRentKind, RentToolSeq, EmpSeq, DeptSeq, PJTName, FrCalcYM, ToCalcYM, FrWorkDate, ToWorkDate, UMToolType, SlipExistsSeq) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'200101', N'201712', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820084
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820087
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEERentToolCalcListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1
rollback 
