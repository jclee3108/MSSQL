    
IF OBJECT_ID('mnpt_SPDEEMonthlyToolFuelListQuery') IS NOT NULL       
    DROP PROC mnpt_SPDEEMonthlyToolFuelListQuery      
GO      
      
-- v2018.01.18 
      
-- 월별주유가동현황-조회 by 이재천  
CREATE PROC mnpt_SPDEEMonthlyToolFuelListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     
    DECLARE @StdYear    NCHAR(4), 
            @StdDay     INT 
      
    SELECT @StdYear = ISNULL( StdYear    , '' )
      FROM #BIZ_IN_DataBlock1    
    
    
    SELECT @StdDay = '26'

    ----------------------------------------------------------------------------------
    -- 장비구분별 급유금액 구하기, Srt
    ----------------------------------------------------------------------------------
    -- 장비구분별 단가 * 수량 (급유금액)
    SELECT CASE WHEN RIGHT(A.FuelDate,2) >= @StdDay THEN CONVERT(nchar(6),DATEADD(Month,1,A.FuelDate),112) ELSE LEFT(A.FuelDate,6) END AS FuelYM, 
           C.UMToolType, 
           SUM(B.FuelQty * A.DieselPrice) AS FuelAmt 
      INTO #DataBlock2_Base
      FROM mnpt_TPDEEFuelMaster AS A 
      JOIN mnpt_TPDEEFuelitem   AS B ON ( B.CompanySeq = @CompanySeq AND B.FuelSeq = A.FuelSeq ) 
      JOIN mnpt_TPDEquipment    AS C ON ( C.CompanySeq = @CompanySeq AND C.EquipmentSeq = B.EquipmentSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(CASE WHEN RIGHT(A.FuelDate,2) >= @StdDay THEN CONVERT(nchar(6),DATEADD(Month,1,A.FuelDate),112) ELSE LEFT(A.FuelDate,6) END,4) = @StdYear 
     GROUP BY CASE WHEN RIGHT(A.FuelDate,2) >= @StdDay THEN CONVERT(nchar(6),DATEADD(Month,1,A.FuelDate),112) ELSE LEFT(A.FuelDate,6) END, C.UMToolType
    
    --select * from #DataBlock2_Base 
    --return 
    CREATE TABLE #DataBlock2_KindName
    ( 
        KindName1   NVARCHAR(200), 
        KindName2   NVARCHAR(200), 
        KindSeq2    INT
    )

    INSERT INTO #DataBlock2_KindName ( KindName1, KindName2, KindSeq2 ) 
    SELECT DISTINCT 
           '장비별' AS KindName1, 
           B.MinorName AS KindName2, 
           A.UMtoolType AS KindSeq2
      FROM #DataBlock2_Base AS A 
      LEFT OUTER JOIN _TDAUMinor AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMToolType ) 
    
    -- 등록된 데이터 Count
    SELECT UMToolType, Count(1) AS Cnt 
      INTO #DataBlock2_UMToolType_Cnt
      FROM ( 
            SELECT DISTINCT UMToolType, FuelYM
              FROM #DataBlock2_Base 
           ) AS A 
     GROUP BY UMToolType 
    
    -- DataBlock2 최종 담기 
    SELECT A.KindName1, 
           A.KindName2, 
           A.KindSeq2, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '01' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt01, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '02' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt02, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '03' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt03, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '04' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt04, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '05' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt05, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '06' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt06, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '07' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt07, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '08' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt08, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '09' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt09, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '10' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt10, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '11' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt11, 
           SUM(CASE WHEN RIGHT(B.FuelYM,2) = '12' THEN ROUND(B.FuelAmt,0) ELSE 0 END) AS Amt12, 
           SUM(ROUND(B.FuelAmt,0)) AS SumAmt, 
           SUM(ROUND(B.FuelAmt,0)) / MAX(C.Cnt) AS AvgAmt 
      INTO #DataBlock2_Result
      FROM #DataBlock2_KindName           AS A 
      LEFT OUTER JOIN #DataBlock2_Base  AS B ON ( B.UMToolType = A.KindSeq2 ) 
      LEFT OUTER JOIN #DataBlock2_UMToolType_Cnt    AS C ON ( C.UMToolType = A.KindSeq2 ) 
     GROUP BY A.KindName1, A.KindName2, A.KindSeq2
    ----------------------------------------------------------------------------------
    -- 장비구분별 급유금액 구하기, End 
    ----------------------------------------------------------------------------------
    
    --select * from #DataBlock2_Result 
    --return 
    ----------------------------------------------------------------------------------
    -- 화태중분류별 금액, 단가, 물량 구하기, Srt
    ----------------------------------------------------------------------------------
    CREATE TABLE #DataBlock1_Result 
    ( 
        IDX_NO          INT IDENTITY, 
        KindName1       NVARCHAR(200), 
        KindName2       NVARCHAR(200), 
        KindSeq2        INT, 
        Amt01           DECIMAL(19,5),
        MTWeight01      DECIMAL(19,5),
        Price01         DECIMAL(19,5),
        Amt02           DECIMAL(19,5),
        MTWeight02      DECIMAL(19,5),
        Price02         DECIMAL(19,5),
        Amt03           DECIMAL(19,5),
        MTWeight03      DECIMAL(19,5),
        Price03         DECIMAL(19,5),
        Amt04           DECIMAL(19,5),
        MTWeight04      DECIMAL(19,5),
        Price04         DECIMAL(19,5),
        Amt05           DECIMAL(19,5),
        MTWeight05      DECIMAL(19,5),
        Price05         DECIMAL(19,5),
        Amt06           DECIMAL(19,5),
        MTWeight06      DECIMAL(19,5),
        Price06         DECIMAL(19,5),
        Amt07           DECIMAL(19,5),
        MTWeight07      DECIMAL(19,5),
        Price07         DECIMAL(19,5),
        Amt08           DECIMAL(19,5),
        MTWeight08      DECIMAL(19,5),
        Price08         DECIMAL(19,5),
        Amt09           DECIMAL(19,5),
        MTWeight09      DECIMAL(19,5),
        Price09         DECIMAL(19,5),
        Amt10           DECIMAL(19,5),
        MTWeight10      DECIMAL(19,5),
        Price10         DECIMAL(19,5),
        Amt11           DECIMAL(19,5),
        MTWeight11      DECIMAL(19,5),
        Price11         DECIMAL(19,5),
        Amt12           DECIMAL(19,5),
        MTWeight12      DECIMAL(19,5),
        Price12         DECIMAL(19,5),
        SumAmt          DECIMAL(19,5),
        SumMTWeight     DECIMAL(19,5),
        SumPrice        DECIMAL(19,5),
        AvgAmt          DECIMAL(19,5),
    )

    CREATE TABLE #DataBlock1_Title
    ( 
        KindName1       NVARCHAR(200), 
        KindName2       NVARCHAR(200), 
        KindSeq2        INT, 
        Sort            INT 
    )
    
    SELECT A.WorkReportSeq, 
           --LEFT(A.WorkDate,6) AS WorkYM, 
           CASE WHEN RIGHT(A.WorkDate,2) >= @StdDay THEN CONVERT(NCHAR(6),DATEADD(Month,1,A.WorkDate),112) ELSE LEFT(A.WorkDate,6) END AS WorkYM, 
           A.WorkDate, 
           F.ItemClassMSeq, 
           F.ItemClassMName, 
           A.TodayMTWeight AS MTWeight, 
           CASE WHEN ISNULL(B.SelfToolSeq,0) <> 0 THEN ISNULL(B.SelfToolSeq,0) ELSE ISNULL(B.RentToolSeq,0) END AS ToolSeq, 
           G.UMToolType, 
           CASE WHEN ISNULL(B.ToolWorkTime,0) = 0 THEN ISNULL(A.RealWorkTime,0) ELSE ISNULL(B.ToolWorkTime,0) END WorkTime 
      INTO #DataBlock1_Base
      FROM mnpt_TPJTWorkReport                  AS A 
      LEFT OUTER JOIN mnpt_TPJTWorkReportItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject              AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TPJTType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.PJTTypeSeq = C.PJTTypeSeq ) 
      LEFT OUTER JOIN _VDAItemClass             AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemClassSSeq = D.ItemClassSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment         AS G ON ( G.CompanySeq = @CompanySeq 
                                                      AND G.EquipmentSeq = CASE WHEN ISNULL(B.SelfToolSeq,0) <> 0 THEN ISNULL(B.SelfToolSeq,0) ELSE ISNULL(B.RentToolSeq,0) END 
                                                        ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND LEFT(CASE WHEN RIGHT(A.WorkDate,2) >= @StdDay THEN CONVERT(NCHAR(6),DATEADD(Month,1,A.WorkDate),112) ELSE LEFT(A.WorkDate,6) END,4) = @StdYear 
    
    --select * from #DataBlock1_Base where umtooltype <> 0 and  workdate = '20171201' 
    --return 
    -- 배부기준 1 : 월 장비 주유금액을 화태별 작업시간(작업실적)으로 배부 
    SELECT A.WorkYM, A.ItemClassMSeq, A.UMToolType, SUM(A.WorkTime) AS WorkTime, SUM(B.MTWeight) AS MTWeight 
      INTO #DataBlock1_Split1
      FROM #DataBlock1_Base AS A 
      LEFT OUTER JOIN (
                        SELECT Z.WorkYM, Z.WorkReportSeq, Z.ItemClassMSeq, MAX(Z.MTWeight) AS MTWeight 
                          FROM #DataBlock1_Base AS Z 
                         WHERE ISNULL(Z.UMToolType,0) <> 0 
                         GROUP BY Z.WorkYM, Z.WorkReportSeq, Z.ItemClassMSeq
                      ) AS B ON ( B.ItemClassMSeq = A.ItemClassMSeq AND B.WorkYM = A.WorkYM ) 
     WHERE ISNULL(A.UMToolType,0) <> 0 
     GROUP BY A.WorkYM, A.ItemClassMSeq, A.UMToolType

    SELECT A.WorkYM, 
           A.ItemClassMSeq, 
           --A.UMToolType, 
           SUM(A.WorkTime / B.SumWorkTime * C.FuelAmt) AS Amt  
      INTO #DataBlock1_Split1_Amt 
      FROM #DataBlock1_Split1 AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.WorkYM, Z.UMToolType, SUM(WorkTime) AS SumWorkTime
                          FROM #DataBlock1_Split1 AS Z 
                         GROUP BY Z.WorkYM, Z.UMToolType 
                      ) AS B ON ( B.WorkYM = A.WorkYM AND B.UMToolType = A.UMToolType ) 
     LEFT OUTER JOIN #DataBlock2_Base AS C ON ( C.FuelYM = A.WorkYM AND C.UMToolType = A.UMToolType ) 
     GROUP BY A.WorkYM, A.ItemClassMSeq
    
    

    -- 배부기준 2 : 투입시간이 없는장비는 사용자정의코드(주유현황용 장비- 화태중분류 연결)로 연결된 화태중분류의 물량비율로 배부 
    SELECT A.WorkYM, A.ItemClassMSeq, SUM(A.MTWeight) AS MTWeight 
      INTO #DataBlock1_Split2
      FROM (
            SELECT Z.WorkYM, Z.WorkReportSeq, Z.ItemClassMSeq, MAX(Z.MTWeight) AS MTWeight 
              FROM #DataBlock1_Base AS Z 
             GROUP BY Z.WorkYM, Z.WorkReportSeq, Z.ItemClassMSeq
           ) AS A 
     GROUP BY A.WorkYM, A.ItemClassMSeq
     
    
    SELECT B.ValueSeq AS UMToolType, C.ValueSeq AS ItemClassMSeq
      INTO #Split2Mapping
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016782 
    
    SELECT A.FuelYM, A.FuelAmt, A.UMToolType, B.ItemClassMSeq 
      INTO #Split2Amt
      FROM #DataBlock2_Base             AS A 
      LEFT OUTER JOIN #Split2Mapping    AS B ON ( B.UMToolType = A.UMToolType ) 
     WHERE NOT EXISTS (SELECT 1 FROM #DataBlock1_Split1 WHERE WorkYM = A.FuelYM AND UMToolType = A.UMToolType) 
    
    
    SELECT A.WorkYM, 
           A.ItemClassMSeq, 
           C.UMToolType, 
           A.MTWeight / B.MTWeight * C.FuelAmt AS Amt 
      INTO #DataBlock1_Split2_Amt 
      FROM #DataBlock1_Split2 AS A 
      LEFT OUTER JOIN (
                        SELECT WorkYM, SUM(MTWeight) AS MTWeight
                          FROM #DataBlock1_Split2 AS Z 
                         WHERE EXISTS (SELECT 1 FROM #Split2Mapping WHERE ItemClassMSeq = Z.ItemClassMSeq) 
                         GROUP BY WorkYM
                      ) AS B ON ( B.WorkYM = A.WorkYM ) 
                 JOIN #Split2Amt AS C ON ( C.FuelYM = A.WorkYM AND C.ItemClassMSeq = A.ItemClassMSeq ) 
     WHERE EXISTS (SELECT 1 FROM #Split2Mapping WHERE ItemClassMSeq = A.ItemClassMSeq) 
    
   
    -- 배부기준 3 : 화태 물량비율로 배부 
    SELECT WorkReportSeq, WorkYM, ItemClassMSeq, MAX(MTWeight) AS MTWeight
      INTO #DataBlock1_Split3
      FROM #DataBlock1_Base 
     GROUP BY WorkReportSeq, WorkYM, ItemClassMSeq 
    
    SELECT A.FuelYM, SUM(A.FuelAmt) AS FuelAmt 
      INTO #Split3Amt
      FROM #DataBlock2_Base             AS A 
     WHERE NOT EXISTS (SELECT 1 FROM #DataBlock1_Split1 WHERE FuelYM = A.FuelYM AND UMToolType = A.UMToolType) 
       AND NOT EXISTS (SELECT 1 FROM #DataBlock1_Split2_Amt WHERE FuelYM = A.FuelYM AND UMToolType = A.UMToolType )
     GROUP BY A.FuelYM
    
    SELECT A.WorkYM, 
           A.ItemClassMSeq, 
           SUM(A.MTWeight / B.MTWeight * C.FuelAmt) AS Amt 
      INTO #DataBlock1_Split3_Amt 
      FROM #DataBlock1_Split3 AS A 
      LEFT OUTER JOIN (
                        SELECT WorkYM, SUM(MTWeight) AS MTWeight
                          FROM #DataBlock1_Split3 
                         GROUP BY WorkYM
                      ) AS B ON ( B.WorkYM = A.WorkYM ) 
                 JOIN #Split3Amt AS C ON ( C.FuelYM = A.WorkYM ) 
     GROUP BY A.WorkYM, A.ItemClassMSeq
    
    

    INSERT INTO #DataBlock1_Title ( KindName1, KindName2, KindSeq2, Sort ) 
    SELECT DISTINCT 
           '화태별' AS KindName1, 
           B.MinorName AS KindName2, 
           A.ItemClassMSeq AS KindSeq2, 
           1 AS Sort 
      FROM #DataBlock1_Split1_Amt   AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ItemClassMSeq ) 
    UNION  
    SELECT DISTINCT 
           '화태별' AS KindName1, 
           B.MinorName AS KindName2, 
           A.ItemClassMSeq AS KindSeq2, 
           1 AS Sort
      FROM #DataBlock1_Split2_Amt   AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ItemClassMSeq ) 
    UNION 
    SELECT DISTINCT 
           '화태별' AS KindName1, 
           B.MinorName AS KindName2, 
           A.ItemClassMSeq AS KindSeq2, 
           1 AS Sort
      FROM #DataBlock1_Split3_Amt   AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ItemClassMSeq ) 
    UNION 
    SELECT DISTINCT 
           '화태별' AS KindName1, 
           '기타' AS KindName2, 
           999999999 AS KindSeq2, 
           2 AS Sort 
    
    
    -- 데이터 숫자 (평균을 구하기 위함)
    DECLARE @DataCnt INT 
    
    SELECT @DataCnt = Count(1) 
      FROM ( 
            select WorkYM
              From #DataBlock1_Split1_Amt 
            UNION 
            select WorkYM
              From #DataBlock1_Split2_Amt 
            UNION 
            select WorkYM 
              From #DataBlock1_Split3_Amt  
           ) AS A 
    

    INSERT INTO #DataBlock1_Result
    (
        KindName1, KindName2, KindSeq2, MTWeight01, MTWeight02, 
        MTWeight03, MTWeight04, MTWeight05, MTWeight06, MTWeight07, 
        MTWeight08, MTWeight09, MTWeight10, MTWeight11, MTWeight12,
        SumMTWeight, Amt01, Amt02, Amt03, Amt04, 
        Amt05, Amt06, Amt07, Amt08, Amt09, 
        Amt10, Amt11, Amt12
    )
    SELECT Q.KindName1, 
           Q.KindName2, 
           Q.KindSeq2, 

           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '01' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight01, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '02' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight02, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '03' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight03, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '04' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight04, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '05' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight05, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '06' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight06, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '07' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight07, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '08' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight08, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '09' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight09, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '10' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight10, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '11' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight11, 
           SUM(CASE WHEN RIGHT(Z.WorkYM,2) = '12' THEN ISNULL(Z.MTWeight,0) ELSE 0 END) AS MTWeight12, 
           SUM(ISNULL(Z.MTWeight,0)) AS SumMTWeight, 

           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '01' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '01' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '01' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt01, 
                                                                            
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '02' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '02' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '02' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt02, 
                                                                            
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '03' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '03' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '03' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt03, 
                                                                            
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '04' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '04' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '04' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt04, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '05' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '05' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '05' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt05, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '06' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '06' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) + 
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '06' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt06, 
           
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '07' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '07' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '07' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt07, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '08' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '08' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '08' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt08, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '09' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '09' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '09' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt09, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '10' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '10' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '10' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt10, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '11' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '11' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '11' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt11, 
                                                              
           SUM(CASE WHEN RIGHT(Y.WorkYM,2) = '12' THEN ISNULL(ROUND(Y.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(R.WorkYM,2) = '12' THEN ISNULL(ROUND(R.Amt,0),0) ELSE 0 END) +
           SUM(CASE WHEN RIGHT(E.WorkYM,2) = '12' THEN ISNULL(ROUND(E.Amt,0),0) ELSE 0 END) AS Amt12  
           

           --SUM(ISNULL(Y.Amt,0)) +
           --SUM(ISNULL(R.Amt,0)) +
           --SUM(ISNULL(E.Amt,0)) AS SumAmt
            

           --( SUM(ISNULL(Y.Amt,0)) +
           --SUM(ISNULL(R.Amt,0)) +
           --SUM(ISNULL(E.Amt,0)) ) / @DataCnt AS AvgAmt 
      FROM #DataBlock1_Title AS Q
      LEFT OUTER JOIN ( 
                        SELECT WorkYM, ItemClassMSeq, SUM(MTWeight) AS MTWeight 
                          FROM ( 
                                SELECT WorkYM, 
                                       WorkReportSeq, 
                                       ItemClassMSeq, 
                                       MAX(MTWeight) AS MTWeight 
                                  FROM #DataBlock1_Base AS A 
                                 GROUP BY WorkYM, WorkReportSeq, ItemClassMSeq
                               ) AS B 
                         GROUP BY WorkYM, ItemClassMSeq
                      ) AS Z ON ( Z.ItemClassMSeq = Q.KindSeq2 ) 
      LEFT OUTER JOIN #DataBlock1_Split1_Amt AS Y ON ( Y.ItemClassMSeq = Q.KindSeq2 AND Y.WorkYM = Z.WorkYM ) 
      LEFT OUTER JOIN #DataBlock1_Split2_Amt AS R ON ( R.ItemClassMSeq = Q.KindSeq2 AND R.WorkYM = Z.WorkYM ) 
      LEFT OUTER JOIN #DataBlock1_Split3_Amt AS E ON ( E.ItemClassMSeq = Q.KindSeq2 AND E.WorkYM = Z.WorkYM ) 
     GROUP BY Q.KindName1, Q.KindName2, Q.KindSeq2, Q.Sort 
     ORDER BY Q.Sort 
    
    -- 단수 마지막 값에 보정
    SELECT B.Amt01 - A.Amt01 AS DiffAmt01, 
           B.Amt02 - A.Amt02 AS DiffAmt02, 
           B.Amt03 - A.Amt03 AS DiffAmt03, 
           B.Amt04 - A.Amt04 AS DiffAmt04, 
           B.Amt05 - A.Amt05 AS DiffAmt05, 
           B.Amt06 - A.Amt06 AS DiffAmt06, 
           B.Amt07 - A.Amt07 AS DiffAmt07, 
           B.Amt08 - A.Amt08 AS DiffAmt08, 
           B.Amt09 - A.Amt09 AS DiffAmt09, 
           B.Amt10 - A.Amt10 AS DiffAmt10, 
           B.Amt11 - A.Amt11 AS DiffAmt11, 
           B.Amt12 - A.Amt12 AS DiffAmt12
      INTO #DiffAmt 
      FROM ( 
            SELECT SUM(Amt01) AS Amt01,
                   SUM(Amt02) AS Amt02,
                   SUM(Amt03) AS Amt03,
                   SUM(Amt04) AS Amt04,
                   SUM(Amt05) AS Amt05,
                   SUM(Amt06) AS Amt06,
                   SUM(Amt07) AS Amt07,
                   SUM(Amt08) AS Amt08,
                   SUM(Amt09) AS Amt09,
                   SUM(Amt10) AS Amt10,
                   SUM(Amt11) AS Amt11,
                   SUM(Amt12) AS Amt12
              FROM #DataBlock1_Result 
          ) AS A 
      LEFT OUTER JOIN ( 
                        SELECT SUM(Amt01) AS Amt01, 
                               SUM(Amt02) AS Amt02, 
                               SUM(Amt03) AS Amt03, 
                               SUM(Amt04) AS Amt04, 
                               SUM(Amt05) AS Amt05, 
                               SUM(Amt06) AS Amt06, 
                               SUM(Amt07) AS Amt07, 
                               SUM(Amt08) AS Amt08, 
                               SUM(Amt09) AS Amt09, 
                               SUM(Amt10) AS Amt10, 
                               SUM(Amt11) AS Amt11, 
                               SUM(Amt12) AS Amt12
                          FROM #DataBlock2_Result 
                      ) AS B ON ( 1 = 1 ) 
    
    
    UPDATE A
       SET Amt01 = A.Amt01 + B.DiffAmt01, 
           Amt02 = A.Amt02 + B.DiffAmt02, 
           Amt03 = A.Amt03 + B.DiffAmt03, 
           Amt04 = A.Amt04 + B.DiffAmt04, 
           Amt05 = A.Amt05 + B.DiffAmt05, 
           Amt06 = A.Amt06 + B.DiffAmt06, 
           Amt07 = A.Amt07 + B.DiffAmt07, 
           Amt08 = A.Amt08 + B.DiffAmt08, 
           Amt09 = A.Amt09 + B.DiffAmt09, 
           Amt10 = A.Amt10 + B.DiffAmt10, 
           Amt11 = A.Amt11 + B.DiffAmt11, 
           Amt12 = A.Amt12 + B.DiffAmt12
      FROM #DataBlock1_Result AS A 
      JOIN #DiffAmt           AS B ON ( 1 = 1 ) 
      JOIN ( 
            SELECT MAX(IDX_NO) AS IDX_NO 
              FROM #DataBlock1_Result 
           ) AS C ON ( C.IDX_NO = A.IDX_NO ) 
    
    ----------------------------------------------------------------------------------
    -- 화태중분류별 금액, 단가, 물량 구하기, End 
    ----------------------------------------------------------------------------------
    
    -- DataBlock1
    SELECT KindName1, 
           KindName2, 
           KindSeq2, 
           NULLIF(MTWeight01,0) AS MTWeight01, 
           NULLIF(MTWeight02,0) AS MTWeight02, 
           NULLIF(MTWeight03,0) AS MTWeight03, 
           NULLIF(MTWeight04,0) AS MTWeight04, 
           NULLIF(MTWeight05,0) AS MTWeight05, 
           NULLIF(MTWeight06,0) AS MTWeight06, 
           NULLIF(MTWeight07,0) AS MTWeight07, 
           NULLIF(MTWeight08,0) AS MTWeight08, 
           NULLIF(MTWeight09,0) AS MTWeight09, 
           NULLIF(MTWeight10,0) AS MTWeight10, 
           NULLIF(MTWeight11,0) AS MTWeight11, 
           NULLIF(MTWeight12,0) AS MTWeight12,
           NULLIF(SumMTWeight,0) AS SumMTWeight, 
           NULLIF(Amt01,0) AS Amt01, 
           NULLIF(Amt02,0) AS Amt02, 
           NULLIF(Amt03,0) AS Amt03, 
           NULLIF(Amt04,0) AS Amt04, 
           NULLIF(Amt05,0) AS Amt05, 
           NULLIF(Amt06,0) AS Amt06, 
           NULLIF(Amt07,0) AS Amt07, 
           NULLIF(Amt08,0) AS Amt08, 
           NULLIF(Amt09,0) AS Amt09, 
           NULLIF(Amt10,0) AS Amt10, 
           NULLIF(Amt11,0) AS Amt11, 
           NULLIF(Amt12,0) AS Amt12, 
           
           NULLIF( (Amt01 + Amt02 + Amt03 + Amt04 + Amt05 + Amt06 + 
                    Amt07 + Amt08 + Amt09 + Amt10 + Amt11 + Amt12) ,0) AS SumAmt, 

           NULLIF(Amt01,0) / NULLIF(MTWeight01,0) AS Price01, 
           NULLIF(Amt02,0) / NULLIF(MTWeight02,0) AS Price02, 
           NULLIF(Amt03,0) / NULLIF(MTWeight03,0) AS Price03, 
           NULLIF(Amt04,0) / NULLIF(MTWeight04,0) AS Price04, 
           NULLIF(Amt05,0) / NULLIF(MTWeight05,0) AS Price05, 
           NULLIF(Amt06,0) / NULLIF(MTWeight06,0) AS Price06, 
           NULLIF(Amt07,0) / NULLIF(MTWeight07,0) AS Price07, 
           NULLIF(Amt08,0) / NULLIF(MTWeight08,0) AS Price08, 
           NULLIF(Amt09,0) / NULLIF(MTWeight09,0) AS Price09, 
           NULLIF(Amt10,0) / NULLIF(MTWeight10,0) AS Price10, 
           NULLIF(Amt11,0) / NULLIF(MTWeight11,0) AS Price11, 
           NULLIF(Amt12,0) / NULLIF(MTWeight12,0) AS Price12, 
           NULLIF(( Amt01 + Amt02 + Amt03 + Amt04 + Amt05 + Amt06 + 
                    Amt07 + Amt08 + Amt09 + Amt10 + Amt11 + Amt12 ),0) / NULLIF(SumMTWeight,0) AS SumPrice, 

           NULLIF(( Amt01 + Amt02 + Amt03 + Amt04 + Amt05 + Amt06 + 
                    Amt07 + Amt08 + Amt09 + Amt10 + Amt11 + Amt12 ),0) / NULLIF(@DataCnt,0) AS AvgAmt
      FROM #DataBlock1_Result 
    
    -- DataBlock2
    SELECT KindName1,
           KindName2,
           KindSeq2, 
           NULLIF(A.Amt01,     0) AS Amt01,    
           NULLIF(A.Amt02,     0) AS Amt02,    
           NULLIF(A.Amt03,     0) AS Amt03,    
           NULLIF(A.Amt04,     0) AS Amt04,    
           NULLIF(A.Amt05,     0) AS Amt05,    
           NULLIF(A.Amt06,     0) AS Amt06,    
           NULLIF(A.Amt07,     0) AS Amt07,    
           NULLIF(A.Amt08,     0) AS Amt08,    
           NULLIF(A.Amt09,     0) AS Amt09,    
           NULLIF(A.Amt10,     0) AS Amt10,    
           NULLIF(A.Amt11,     0) AS Amt11,    
           NULLIF(A.Amt12,     0) AS Amt12,    
           NULLIF(A.SumAmt,    0) AS SumAmt,   
           NULLIF(A.AvgAmt,    0) AS AvgAmt    
      FROM #DataBlock2_Result AS A 
    
    RETURN     

GO
