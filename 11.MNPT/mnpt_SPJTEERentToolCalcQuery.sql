     
IF OBJECT_ID('mnpt_SPJTEERentToolCalcQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolCalcQuery      
GO      
      
-- v2017.12.06
      
-- 외부장비임차정산-조회 by 이재천  
CREATE PROC mnpt_SPJTEERentToolCalcQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

    DECLARE @StdYM      NCHAR(6), 
            @BizUnit    INT, 
            @DeptSeq    INT 
      
    SELECT @StdYM   = ISNULL( StdYM, '' ), 
           @BizUnit = ISNULL( BizUnit, 0 ), 
           @DeptSeq = ISNULL( DeptSeq, 0 )
      FROM #BIZ_IN_DataBlock1    
    
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
       AND ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       --AND ( @StdYM BETWEEN LEFT(A.RentSrtDate,6) AND LEFT(A.RentEndDate,6) ) 
    
    ------------------------------------------------------------------------
    -- 일대 or 계약이 없는 건, Srt
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
           A.RentToolSeq, 
           I.EquipmentSName AS RentToolName, 
           B.WorkDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq, 
           A.WorkReportSeq, 
           A.WorkReportSerl, 
           C.ContractSeq, 
           C.ContractSerl, 
           C.PJTSeq AS ContractPJTSeq 
      INTO #Daily 
      FROM mnpt_TPJTWorkReportItem          AS A 
                 JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject          AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = B.PJTSeq ) 
      LEFT OUTER JOIN #Contract             AS C ON ( C.RentToolSeq = A.RentToolSeq 
                                                  AND B.WorkDate BETWEEN C.RentSrtDate AND C.RentEndDate 
                                                  AND C.UMRentType <> 1016305003 -- 월대 제외
                                                    ) 
      --OUTER APPLY ( 
      --              SELECT Z.RentCustSeq, Z.UMRentType, Z.UMRentKind, Z.RentSrtDate, Z.RentEndDate, Z.EmpSeq, Z.DeptSeq 
      --                FROM #Contract AS Z 
      --               WHERE Z.BizUnit = J.PJTSeq 
      --                 AND Z.RentToolSeq = A.RentToolSeq 
      --                 AND B.WorkDate BETWEEN Z.RentSrtDate AND Z.RentEndDate 
      --                 AND Z.UMRentType <> 1016305003 
      --            ) AS C 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMRentKind ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.UMRentType ) 
      LEFT OUTER JOIN _TDABizUnit           AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = C.BizUnit ) 
      LEFT OUTER JOIN _TDAAccUnit           AS G ON ( G.CompanySeq = @CompanySeq AND G.AccUnit = F.AccUnit ) 
      LEFT OUTER JOIN _TDACust              AS H ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = C.RentCustSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment     AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.RentToolSeq <> 0 AND A.RentToolSeq IS NOT NULL) -- 임차장비만 보기 
       AND LEFT(B.WorkDate,6) = @StdYM 
       AND A.IsCfm = '1' 
       --AND NOT EXISTS (SELECT 1 FROM #Contract WHERE BizUnit = J.BizUnit AND UMRentType = 1016305003 AND RentToolSeq = A.RentToolSeq)
       --AND C.RentToolSeq IS NULL
    

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
     GROUP BY RentToolSeq, WorkDate

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
    ------------------------------------------------------------------------
    -- 일대 or 계약이 없는 건, End
    ------------------------------------------------------------------------
    
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
           A.RentToolSeq, 
           I.EquipmentSName AS RentToolName, 
           LEFT(B.WorkDate,6) + '01' AS WorkDateSub, 
           B.WorKDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq, 
           A.WorkReportSeq, 
           A.WorkReportSerl, 
           C.ContractSeq, 
           C.ContractSerl, 
           C.PJTSeq AS ContractPJTSeq 
      INTO #Monthliy
      FROM mnpt_TPJTWorkReportItem          AS A 
                 JOIN mnpt_TPJTWorkReport   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject          AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = B.PJTSeq ) 
      LEFT OUTER JOIN #Contract             AS C ON ( C.RentToolSeq = A.RentToolSeq 
                                                  AND B.WorkDate BETWEEN C.RentSrtDate AND C.RentEndDate 
                                                    ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMRentKind ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.UMRentType ) 
      LEFT OUTER JOIN _TDABizUnit           AS F ON ( F.CompanySeq = @CompanySeq AND F.BizUnit = C.BizUnit ) 
      LEFT OUTER JOIN _TDAAccUnit           AS G ON ( G.CompanySeq = @CompanySeq AND G.AccUnit = F.AccUnit ) 
      LEFT OUTER JOIN _TDACust              AS H ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = C.RentCustSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment     AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
      --LEFT OUTER JOIN _TPJTProject          AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = B.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (A.RentToolSeq <> 0 AND A.RentToolSeq IS NOT NULL) -- 임차장비만 보기 
       AND LEFT(B.WorkDate,6) = @StdYM 
       AND A.IsCfm = '1' 
       --AND EXISTS (SELECT 1 FROM #Contract WHERE BizUnit = J.BizUnit AND UMRentType = C.UMRentType AND RentToolSeq = A.RentToolSeq)
       AND C.UMRentType = 1016305003 
    


    DELETE A
      FROM #Daily AS A 
     WHERE EXISTS (SELECT 1 FROM #Monthliy WHERE WorkReportSeq = A.WorkReportSeq AND WorkReportSerl = A.WorkReportSerl) 



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
    ------------------------------------------------------------------------
    -- 월대, End 
    ------------------------------------------------------------------------

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
           CASE WHEN A.BizUnit IS NULL THEN '0' ELSE '1' END AS IsContract, 
           A.ContractSeq, 
           A.ContractSerl, 
           A.ContractPJTSeq 
      FROM #Daily AS A 
      LEFT OUTER JOIN #WorkPJTName  AS B ON ( B.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #DayCnt       AS C ON ( C.RentToolSeq = A.RentToolSeq AND C.WorkDate = A.WorkDate ) 
      LEFT OUTER JOIN #NightCnt     AS D ON ( D.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #HolidayCnt   AS E ON ( E.RentToolSeq = A.RentToolSeq ) 
    
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
           CASE WHEN A.BizUnit IS NULL THEN '0' ELSE '1' END AS IsContract, 
           A.ContractSeq, 
           A.ContractSerl, 
           A.ContractPJTSeq
      FROM #Monthliy AS A 
      LEFT OUTER JOIN #WorkPJTName  AS B ON ( B.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #DayCnt       AS C ON ( C.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #NightCnt     AS D ON ( D.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #HolidayCnt   AS E ON ( E.RentToolSeq = A.RentToolSeq ) 


    ------------------------------------------------------------------------
    -- 운전원, Srt
    ------------------------------------------------------------------------
    INSERT INTO #Result 
    (
        BizUnitName    , BizUnit        , AccUnitName    , AccUnit        , RentCustName   , 
        RentCustSeq    , UMRentTypeName , UMRentType     , UMRentKindName , UMRentKind     , 
        RentToolSeq    , RentToolName   , WorkDate       , PJTNames       , RentSrtDate    , 
        RentEndDate    , WorkDateCnt    , NightCnt       , HolidayCnt     , WorkDateSub    , 
        EmpSeq         , DeptSeq        , IsContract     , ContractSeq    , ContractSerl   , 
        PJTSeq 
    )
    SELECT B.BizUnitName  , A.BizUnit       , C.AccUnitName  , B.AccUnit      , D.CustName      ,
           A.RentCustSeq  , E.MinorName     , A.UMRentType   , F.MinorName    , A.UMRentKind    , 
           
           CASE WHEN A.UMRentKind = 1016351002 THEN A.RentToolSeq ELSE 0 END, 
           CASE WHEN A.UMRentKind = 1016351002 THEN I.EquipmentSName ELSE A.TextRentToolName END, 
           ''             , ''             , A.RentSrtDate   , 

           A.RentEndDate  , 0               , 0              , 0              , @StdYM + '01'   , 
           A.EmpSeq       , A.DeptSeq       , '1' , A.ContractSeq, A.ContractSerl, 
           A.PJTSeq 
      FROM #Contract                    AS A 
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDAAccUnit       AS C ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDACust          AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.RentCustSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMRentKind ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
     WHERE @StdYM BETWEEN LEFT(A.RentSrtDate,6) AND LEFT(A.RentEndDate,6) 
       AND A.UMRentKind IN ( 1016351002, 1016351003 ) 
    
    ------------------------------------------------------------------------
    -- 운전원, End 
    ------------------------------------------------------------------------
    
    --select * from #Result 
    --return 

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
    
    --select * from #Acc 
    --return 

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
    

    --select * From #Contract 
    --return 
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
    
    --select * from #Result 
    --select * From #EquipmentSeqCCtr 
    --select * from #Result 
    --return 

    --select * 
    --  From _TDACCtrDept

    --  --select * from sysobjects where name like '[_]T%Dept%CCtr%'
    --  select * From _THROrgDeptCCtr 

    SELECT DISTINCT 
           A.BizUnitName    , A.BizUnit        , A.AccUnitName    , A.AccUnit        , A.RentCustName   , 
           A.RentCustSeq    , A.UMRentTypeName , A.UMRentType     , A.UMRentKindName , A.UMRentKind     , 
           A.RentToolSeq    , A.RentToolName   , A.WorkDate       , A.PJTNames       , A.RentSrtDate    , 
           A.RentEndDate    , A.WorkDateCnt    , A.NightCnt       , A.HolidayCnt     , A.WorkDateSub    , 
           A.EmpSeq         , A.DeptSeq        , A.IsContract     , A.ContractSeq    , A.ContractSerl   , 
           M.EmpName, 
           N.DeptName, 
           B.CalcSeq,
           B.Qty, 
           B.Price, 
           B.Amt, 
           B.AddListName, 
           B.AddQty, 
           B.AddPrice, 
           B.AddAmt, 
           B.RentAmt, 
           B.RentVAT, 
           B.Remark, 
           B.SlipSeq, 
           C.SlipID, 
           CASE WHEN B.CompanySeq IS NULL THEN '0' ELSE '1' END AS IsCalc, 
           CASE WHEN B.SlipSeq IS NULL OR B.SlipSeq = 0 THEN '0' ELSE '1' END AS IsSlip, 
           B.RentAmt + B.RentVAT AS TotalAmt, 
           
           D.AccSeq, 
           D.AccName, 

           E.AccSeq AS VATAccSeq, 
           E.AccName AS VATAccName ,
           F.AccSeq AS OppAccSeq, 
           F.AccName AS OppAccName, 
           
           --CASE WHEN A.UMRentKind = 1016351001 THEN I.CCtrSeq ELSE L.CCtrSeq END AS CCtrSeq, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN J.CCtrName ELSE L.CCtrName END AS CCtrName, 

           CASE WHEN O.CCtrSeq IS NOT NULL THEN O.CCtrSeq 
                WHEN I.CCtrSeq IS NOT NULL THEN I.CCtrSeq 
                ELSE P.CCtrSeq 
                END AS CCtrSeq, 
           J.CCtrName, 
           J.UMCostType, 
           K.MinorName AS UMCostTypeName, 

           --CASE WHEN A.UMRentKind = 1016351001 THEN J.UMCostType ELSE L.UMCostType END AS UMCostType, 
           --CASE WHEN A.UMRentKind = 1016351001 THEN K.MinorName ELSE L.UMCostTypeName END AS UMCostTypeName, 
           CASE WHEN A.BizUnit IS NULL THEN 2 ELSE 1 END AS Sort, 
           I.CarModel, 
           CASE WHEN A.UMRentType = 1016305003 THEN RIGHT(@StdYM,2) + '월 ' + '01일 ~ ' + RIGHT(CONVERT(NVARCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,+1,@StdYM + '01')),112),2) + '일'
                ELSE CASE WHEN A.WorkDate <> '' THEN STUFF(RIGHT(A.WorkDate,4),3,0,'월 ') + '일' ELSE A.WorkDate END 
                END AS RptDate

      FROM #Result                              AS A 
      LEFT OUTER JOIN mnpt_TPJTEERentToolCalc   AS B ON ( B.CompanySeq = @CompanySeq 
                                                      AND B.BizUnit = A.BizUnit 
                                                      AND B.RentCustSeq = A.RentCustSeq 
                                                      AND B.UMRentType = A.UMRentType 
                                                      AND B.UMRentKind = A.UMRentKind 
                                                      AND B.RentToolSeq = A.RentToolSeq 
                                                      AND B.WorkDate = A.WorkDateSub 
                                                      AND B.ContractSeq = A.ContractSeq 
                                                      AND B.ContractSerl = A.ContractSerl 
                                                        )
      LEFT OUTER JOIN _TACSlipRow               AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipSeq = B.SlipSeq ) 
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
      LEFT OUTER JOIN #EquipmentSeqCCtr AS I ON ( I.EquipmentSeq = A.RentToolSeq AND I.BizUnit = A.BizUnit ) 
      --OUTER APPLY ( 
      --                SELECT TOP 1 II.CCtrSeq, JJ.CCtrName, KK.MinorName AS UMCostTypeName, JJ.UMCostType 
      --                  FROM #Result AS Z 
      --                  LEFT OUTER JOIN #EquipmentSeqCCtr AS II ON ( II.EquipmentSeq = Z.RentToolSeq AND II.BizUnit = Z.BizUnit ) 
      --                  LEFT OUTER JOIN _TDACCtr          AS JJ ON ( JJ.CompanySeq = @CompanySeq AND JJ.CCtrSeq = II.CCtrSeq ) 
      --                  LEFT OUTER JOIN _TDAUMinor        AS KK ON ( KK.CompanySeq = @CompanySeq AND KK.MinorSeq = JJ.UMCostType ) 
      --                 WHERE Z.UMRentKind = 1016351001 -- 장비
      --                   AND Z.BizUnit = A.BizUnit 
      --                   AND Z.RentCustSeq = A.RentCustSeq 
      --                   AND Z.UMRentType = Z.UMRentType 
      --                 ORDER BY Z.UMRentKind, Z.UMRentType, Z.WorkDate 
      --            ) AS L
      LEFT OUTER JOIN _TDAEmp           AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #PJTCCtr          AS O ON ( O.PJTSeq = A.PJTSeq AND O.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _THROrgDeptCCtr   AS P ON ( P.CompanySeq = @CompanySeq AND P.DeptSeq = A.DeptSeq AND @StdYM BETWEEN P.BegYm AND P.EndYM )

      LEFT OUTER JOIN _TDACCtr          AS J ON ( J.CompanySeq = @CompanySeq 
                                              AND J.CCtrSeq = CASE WHEN O.CCtrSeq IS NOT NULL THEN O.CCtrSeq 
                                                                   WHEN I.CCtrSeq IS NOT NULL THEN I.CCtrSeq 
                                                                   ELSE P.CCtrSeq 
                                                                   END
                                                ) 
      LEFT OUTER JOIN _TDAUMinor        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = J.UMCostType ) 

     WHERE ( @BizUnit = 0 OR A.BizUnit = @BizUnit ) 
       AND ( B.CompanySeq IS NULL OR (B.CompanySeq IS NOT NULL AND B.StdYM = @StdYM) )
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
     ORDER BY Sort, BizUnitName, A.UMRentKind, A.UMRentType, A.WorkDate 
    
    RETURN     
go
