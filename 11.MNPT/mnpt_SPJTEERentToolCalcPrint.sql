     
IF OBJECT_ID('mnpt_SPJTEERentToolCalcPrint') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolCalcPrint      
GO      
      
-- v2017.12.14
      
-- 외부장비임차정산-출력 by 이재천  
CREATE PROC mnpt_SPJTEERentToolCalcPrint      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    
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
           A.RentToolSeq, 
           F.EquipmentSName AS RentToolName, 
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
           F.CarModel, 
           CASE WHEN A.UMRentType = 1016305003 THEN RIGHT(A.StdYM,2) + '월 ' + '01일 ~ ' + RIGHT(CONVERT(NVARCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,+1,A.StdYM + '01')),112),2) + '일'
                ELSE CASE WHEN A.WorkDate <> '' THEN STUFF(RIGHT(A.WorkDate,4),3,0,'월 ') + '일' ELSE A.WorkDate END 
                END AS RptDate
      INTO #Main_Data
      FROM mnpt_TPJTEERentToolCalc      AS A 
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RentCustSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSEq = A.UMRentKind ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS F ON ( F.CompanySeq = @CompanySeq AND F.EquipmentSeq = A.RentToolSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #BIZ_IN_DataBlock1 WHERE CalcSeq = A.CalcSeq) 
     --ORDER BY BizUnitName, A.UMRentKind, A.UMRentType, A.WorkDate 


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
        IsContract      NCHAR(1)
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
           B.UMRentType, 
           B.Qty, 
           B.Price, 
           B.Amt, 
           A.EmpSeq, 
           A.DeptSeq 
      INTO #Contract
      FROM mnpt_TPJTEERentToolContract      AS A 
      JOIN mnpt_TPJTEERentToolContractItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #Main_Data 
                    WHERE BizUnit = A.BizUnit 
                      AND RentCustSeq = A.RentCustSeq 
                      AND WorkDate BETWEEN A.RentSrtDate AND A.RentEndDate 
                      AND UMRentKind = B.UMRentKind 
                      AND RentToolSeq = B.RentToolSeq 
                      AND UMRentType = B.UMRentType 
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
           A.RentToolSeq, 
           I.EquipmentSName AS RentToolName, 
           B.WorkDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq 
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
           WHERE BizUnit = C.BizUnit 
               AND RentCustSeq = C.RentCustSeq 
               AND WorkDate = B.WorkDate 
               AND UMRentKind = C.UMRentKind 
               AND RentToolSeq = A.RentToolSeq 
               AND UMRentType = C.UMRentType 
           )
    
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
        EmpSeq         , DeptSeq        , IsContract
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
           '0' AS IsContract
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
           A.RentToolSeq, 
           I.EquipmentSName AS RentToolName, 
           LEFT(B.WorkDate,6) + '01' AS WorkDateSub, 
           B.WorKDate, 
           C.RentSrtDate, 
           C.RentEndDate, 
           C.EmpSeq, 
           C.DeptSeq 
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
       AND C.UMRentType = 1016305003 
              AND EXISTS (SELECT 1 
               FROM #Main_Data 
           WHERE BizUnit = C.BizUnit 
               AND RentCustSeq = C.RentCustSeq 
               AND LEFT(WorkDate,6) = LEFT(B.WorkDate,6)
               AND UMRentKind = C.UMRentKind 
               AND RentToolSeq = A.RentToolSeq 
               AND UMRentType = C.UMRentType 
           )
       
    
    
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
        EmpSeq         , DeptSeq        , IsContract
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
           '1' AS IsContract
      FROM #Monthliy AS A 
      LEFT OUTER JOIN #WorkPJTName  AS B ON ( B.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #DayCnt       AS C ON ( C.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #NightCnt     AS D ON ( D.RentToolSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN #HolidayCnt   AS E ON ( E.RentToolSeq = A.RentToolSeq ) 
    ------------------------------------------------------------------------
    -- 월대, End 
    ------------------------------------------------------------------------
    /*
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
    */

   SELECT DISTINCT 
          A.CalcSeq, 
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
          A.WorkDate AS WorkDateSub, 
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
          A.CarModel, 
          A.RptDate
          --D.AccSeq, 
          --D.AccName, 
          --E.AccSeq AS VATAccSeq, 
          --E.AccName AS VATAccName ,
          --F.AccSeq AS OppAccSeq, 
          --F.AccName AS OppAccName, 
          --CASE WHEN A.UMRentKind = 1016351001 THEN I.CCtrSeq ELSE L.CCtrSeq END AS CCtrSeq, 
          --CASE WHEN A.UMRentKind = 1016351001 THEN J.CCtrName ELSE L.CCtrName END AS CCtrName, 
          --CASE WHEN A.UMRentKind = 1016351001 THEN J.UMCostType ELSE L.UMCostType END AS UMCostType, 
          --CASE WHEN A.UMRentKind = 1016351001 THEN K.MinorName ELSE L.UMCostTypeName END AS UMCostTypeName
      FROM #Main_Data AS A 
      LEFT OUTER JOIN #Result AS B ON ( B.BizUnit = A.BizUnit 
                                    AND B.RentCustSeq = A.RentCustSeq 
                                    AND B.UMRentType = A.UMRentType
                                    AND B.UMRentKind = A.UMRentKind 
                                    AND B.RentToolSeq = A.RentToolSeq 
                                    AND B.WorkDateSub = A.WorkDate 
                                      ) 
      --LEFT OUTER JOIN mnpt_TPDEquipment AS I ON ( I.CompanySeq = @CompanySeq AND I.EquipmentSeq = A.RentToolSeq ) 
      --LEFT OUTER JOIN _TDACCtr          AS J ON ( J.CompanySeq = @CompanySeq AND J.CCtrSeq = I.CCtrSeq ) 
      --LEFT OUTER JOIN _TDAUMinor        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = J.UMCostType ) 
      OUTER APPLY ( 
                      SELECT TOP 1 II.CCtrSeq, JJ.CCtrName, KK.MinorName AS UMCostTypeName, JJ.UMCostType 
                        FROM #Result AS Z 
                        LEFT OUTER JOIN mnpt_TPDEquipment AS II ON ( II.CompanySeq = @CompanySeq AND II.EquipmentSeq = Z.RentToolSeq ) 
                        LEFT OUTER JOIN _TDACCtr          AS JJ ON ( JJ.CompanySeq = @CompanySeq AND JJ.CCtrSeq = II.CCtrSeq ) 
                        LEFT OUTER JOIN _TDAUMinor        AS KK ON ( KK.CompanySeq = @CompanySeq AND KK.MinorSeq = JJ.UMCostType ) 
                       WHERE Z.UMRentKind = 1016351001 -- 장비
                         AND Z.BizUnit = A.BizUnit 
                         AND Z.RentCustSeq = A.RentCustSeq 
                         AND Z.UMRentType = Z.UMRentType 
                       ORDER BY Z.UMRentKind, Z.UMRentType, Z.WorkDate 
                  ) AS L
      LEFT OUTER JOIN _TDAEmp           AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = B.DeptSeq ) 
      /*
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
    */
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

        , CalcSeq INT
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

        , StdYM CHAR(6), BizUnitName NVARCHAR(200), BizUnit INT, Sel CHAR(1), AccUnitName NVARCHAR(200), RentCustName NVARCHAR(200), UMRentTypeName NVARCHAR(200), UMRentKindName NVARCHAR(200), RentToolName NVARCHAR(200), WorkDate CHAR(8), AccUnit INT, RentCustSeq INT, UMRentType INT, UMRentKind INT, RentToolSeq INT, Qty DECIMAL(19, 5), Price DECIMAL(19, 5), Amt DECIMAL(19, 5), AddListName NVARCHAR(200), AddQty DECIMAL(19, 5), AddPrice DECIMAL(19, 5), AddAmt DECIMAL(19, 5), RentAmt DECIMAL(19, 5), RentVAT DECIMAL(19, 5), TotalAmt DECIMAL(19, 5), Remark NVARCHAR(2000), PJTNames NVARCHAR(200), RentSrtDate CHAR(8), RentEndDate CHAR(8), WorkDateCnt INT, NightCnt INT, HolidayCnt INT, AccName NVARCHAR(100), VATAccName NVARCHAR(200), OppAccName NVARCHAR(200), CCtrName NVARCHAR(200), UMCostTypeName NVARCHAR(200), IsCalc CHAR(1), SlipID NVARCHAR(100), IsSlip CHAR(1), AccSeq INT, VATAccSeq INT, OppAccSeq INT, CCtrSeq INT, UMCostType INT, SlipSeq INT, CalcSeq INT, WorkDateSub CHAR(8), EmpSeq INT, EmpName NVARCHAR(200), DeptName NVARCHAR(200), DeptSeq INT, CarModel NVARCHAR(100), RptDate NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, CalcSeq) 
SELECT N'', 1, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'1'
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

SET @ServiceSeq     = 13820070
--SET @MethodSeq      = 5
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820060
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEERentToolCalcPrint            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 