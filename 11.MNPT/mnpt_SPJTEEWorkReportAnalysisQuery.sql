     
IF OBJECT_ID('mnpt_SPJTEEWorkReportAnalysisQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEEWorkReportAnalysisQuery      
GO      
      
-- v2018.02.01
      
-- 하역생산성분석-조회 by 이재천  
CREATE PROC mnpt_SPJTEEWorkReportAnalysisQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @StdYear            NCHAR(4), 
            @UMWorkReportKind   INT,  
            @BizUnit            INT, 
            @UMAnalysisKind     INT, 
            @IsNotRORO          NCHAR(1), 
            @IsCrane            NCHAR(1), 
            @WorkTimeSeq        INT 
    
    SELECT @StdYear           = ISNULL( StdYear          , '' ),   
           @UMWorkReportKind  = ISNULL( UMWorkReportKind , 0 ),   
           @BizUnit           = ISNULL( BizUnit          , 0 ),   
           @UMAnalysisKind    = ISNULL( UMAnalysisKind   , 0 ),   
           @IsNotRORO         = ISNULL( IsNotRORO        , '0' ),   
           @IsCrane           = ISNULL( IsCrane          , '0' ), 
           @WorkTimeSeq       = ISNULL( WorkTimeSeq      , 0 ) 
      FROM #BIZ_IN_DataBlock1  
    
    
    -- 화태그룹-화태연결 
    SELECT A.ValueSeq AS UMPJTTypeGroupSeq, 
           C.ValueSeq AS PJTTypeSeq, 
           ISNULL(B.ValueText,'0') AS IsQty 
      INTO #PJTTypeGroup
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ValueSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016547
       AND A.Serl = 1000001
    

    -- 작업그룹-작업항목연결 
    SELECT A.ValueSeq AS UMWorkGroupSeq, 
           C.ValueSeq AS UMWorkType, 
           ISNULL(B.ValueText,'0') AS IsShip 
      INTO #WorkGroup
      FROM _TDAUMinorValue AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ValueSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016549
       AND A.Serl = 1000001
    

    -- 하역생산성종류
    SELECT DISTINCT 
           A.MinorSeq AS UMWorkReportKind, -- 하역생산성종류 
           B.ValueSeq AS UMPJTTypeGroupSeq, -- 화태그룹코드
           C.ValueSeq AS UMWorkGroupSeq, -- 작업그룹코드 
           D.PJTTypeSeq,  -- 화태코드 
           D.IsQty,       -- 수량기준 
           E.UMWorkType,  -- 작업항목 
           E.IsShip       -- 모선여부 
      INTO #UMWorkReportKind
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN #PJTTypeGroup     AS D ON ( D.UMPJTTypeGroupSeq = B.ValueSeq ) 
      LEFT OUTER JOIN #WorkGroup        AS E ON ( E.UMWorkGroupSeq = C.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016550 
       AND A.MinorSeq = @UMWorkReportKind -- 하역생산성종류 조회조건
    
    
    -- 작업실적 
    SELECT ISNULL(CASE WHEN B.SelfToolSeq = 0 THEN B.RentToolSeq ELSE B.SelfToolSeq END,0) AS ToolSeq, 
           A.WorkDate, 
           E.EquipmentSName AS ToolName, 
           A.ShipSeq, 
           A.ShipSerl,  
           F.IFShipCode + '-' + STUFF(F.ShipSerlNo,5,0,'-') AS ShipSerlNo, 
           C.CustSeq, 
           G.CustName, 
           A.PJTSeq, 
           C.PJTName, 
           A.TodayQty, 
           A.TodayMTWeight, 
           D.IsQty, 
           E.IsCrane, 
           A.WorkSrtTime, 
           A.WorkEndTime, 
           A.WorkReportSeq, 
           B.WorkReportSerl, 
           CONVERT(DECIMAL(19,5),0) AS RealWorkTime, 
           A.UMLoadType, 
           ISNULL(B.ToolWorkTime,0) AS ToolWorkTime
      INTO #KindData 
      FROM mnpt_TPJTWorkReport                  AS A 
      LEFT OUTER JOIN mnpt_TPJTWorkReportItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TPJTProject              AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN ( 
                        SELECT Z.PJTTypeSeq, MAX(Z.IsQty) AS IsQty 
                          FROM #UMWorkReportKind AS Z 
                         GROUP BY Z.PJTTypeSeq 
                      ) AS D ON ( D.PJTTypeSeq = C.PJTTypeSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment         AS E ON ( E.CompanySeq = @CompanySeq 
                                                      AND E.EquipmentSeq = CASE WHEN B.SelfToolSeq = 0 THEN B.RentToolSeq ELSE B.SelfToolSeq END 
                                                        ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail       AS F ON ( F.CompanySeq = @CompanySeq AND F.ShipSeq = A.ShipSeq AND F.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDACust                  AS G ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = C.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #UMWorkReportKind 
                    WHERE PJTTypeSeq = C.PJTTypeSeq 
                      AND UMWorkType = A.UMWorkType 
                      AND IsShip = CASE WHEN ISNULL(A.ShipSeq,0) = 0 OR ISNULL(A.ShipSerl,0) = 0 THEN '0' ELSE '1' END 
                  ) 
       AND A.IsCfm = '1' 
       AND ( B.IsCfm = '1' OR NOT EXISTS (SELECT 1 FROM mnpt_TPJTWorkReportItem WHERE CompanySeq = @CompanySeq AND WorkReportSeq = A.WorkReportSeq) ) 
       AND LEFT(A.WorkDate,4) = @StdYear 
       AND ISNULL(E.IsCrane,'0') = CASE WHEN @IsCrane = '1' THEN '1' ELSE ISNULL(E.IsCrane,'0') END  
       AND ( @BizUnit = 0 OR C.BizUnit = @BizUnit ) 
    
    
    --select ToolSeq, ToolWorkTime from #KindData 
    --return 
    -- 분석기준이 장비인 경우에는 장비가 있는 데이터만... 
    IF @UMAnalysisKind = 1016554001 OR @WorkTimeSeq = 2 
    BEGIN 
        DELETE FROM #KindData WHERE ToolSeq = 0
    END 
    
    -- 하역방식 RORO 제외
    IF @IsNotRORO = '1' 
    BEGIN 
        DELETE A 
          FROM #KindData                    AS A 
          LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMLoadType AND B.Serl = 1000001 ) 
         WHERE B.ValueSeq = 1016268002 
    END 
    
    IF @WorkTimeSeq = 1 
    BEGIN 
        --------------------------------------------------------------
        -- 실작업시간계산  
        --------------------------------------------------------------
        DECLARE @EnvTime NCHAR(4) 

        SELECT @EnvTime = REPLACE(A.EnvValue,':','')
          FROM mnpt_TCOMEnv AS A 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.EnvSeq = 5
    

        CREATE TABLE #MainTime
        (
            WorkReportSeq   INT, 
            WorkReportSerl  INT, 
            WorkSrtTime     NCHAR(12), 
            WorkEndTime     NCHAR(12)
        )

        CREATE TABLE #ResultTime
        (
            WorkReportSeq   INT, 
            WorkReportSerl  INT, 
            WorkSrtTime     NCHAR(12), 
            WorkEndTime     NCHAR(12)
        )


        INSERT INTO #MainTime (WorkReportSeq, WorkReportSerl, WorkSrtTime, WorkEndTime)
        SELECT A.WorkReportSeq, 
               A.WorkReportSerl, 
               CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':',''), 
               CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
          FROM #KindData AS A 
         WHERE A.WorkSrtTime <> '' 
           AND A.WorkEndTime <> ''
    
    
        -- 휴식 시간 
        SELECT ROW_NUMBER() OVER(Order BY A.MinorSeq) AS IDX_NO, 
               CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(B.ValueText,':','') AS SrtTime, 
               CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(C.ValueText,':','') AS EndTime
          INTO #UMinorTime
          FROM _TDAUMinor AS A 
          LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
          LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.MajorSeq = 1016552
    
    
        CREATE TABLE #WorkSrtTime
        (
            WorkReportSeq   INT, 
            WorkReportSerl  INT, 
            WorkSrtTime     NCHAR(12)
        )

        DECLARE @Cnt            INT

        SELECT @Cnt = 1 

        WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #UMinorTime),0) + 1 ) 
        BEGIN 
        
            INSERT INTO #ResultTime 
            SELECT A.WorkReportSeq, 
                   A.WorkReportSerl, 
               
                   CASE WHEN ISNULL(C.WorkSrtTime,A.WorkSrtTime) > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END OR C.WorkSrtTime = '' 
                        THEN '' 
                        ELSE ISNULL(C.WorkSrtTime,A.WorkSrtTime)
                        END, 
               
                   CASE WHEN ISNULL(C.WorkSrtTime,A.WorkSrtTime) > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END 
                        THEN '' 
                        ELSE CASE WHEN A.WorkEndTime > B.SrtTime THEN B.SrtTime ELSE A.WorkEndTime END 
                        END

              FROM #MainTime                AS A 
              LEFT OUTER JOIN #UMinorTime   AS B ON ( B.IDX_NO = @Cnt ) 
              LEFT OUTER JOIN #WorkSrtTime  AS C ON ( C.WorkReportSeq = A.WorkReportSeq AND C.WorkReportSerl = A.WorkReportSerl ) 
        
            TRUNCATE TABLE #WorkSrtTime 
            INSERT INTO #WorkSrtTime ( WorkReportSeq, WorkReportSerl, WorkSrtTime )
            SELECT A.WorkReportSeq, 
                   A.WorkReportSerl, 
                   CASE WHEN A.WorkSrtTime > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                        THEN A.WorkSrtTime 
                        ELSE CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                        END
              FROM #MainTime                AS A 
              LEFT OUTER JOIN #UMinorTime   AS B ON ( B.IDX_NO = @Cnt ) 
        
            SELECT @Cnt = @Cnt + 1 

        END 


        SELECT WorkReportSeq, 
               WorkReportSerl, 
                SUM(
                    CASE WHEN 
                            DATEDIFF( MI, 
                                        STUFF(STUFF(LEFT(WorkSrtTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                        STUFF(RIGHT(WorkSrtTime,4),3,0,':') + ':00.000', 
                                        STUFF(STUFF(LEFT(WorkEndTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                        STUFF(RIGHT(WorkEndTime,4),3,0,':') + ':00.000'
                                    ) < 0 
                        THEN 0 
                        ELSE 
                            DATEDIFF( MI, 
                                        STUFF(STUFF(LEFT(WorkSrtTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                        STUFF(RIGHT(WorkSrtTime,4),3,0,':') + ':00.000', 
                                        STUFF(STUFF(LEFT(WorkEndTime,8),5,0,'-'),8,0,'-') + ' ' +  
                                        STUFF(RIGHT(WorkEndTime,4),3,0,':') + ':00.000'
                                    )
                        END 
                    ) / 60. AS RealWorkTime 
          INTO #RealWorkTime
          FROM #ResultTime 
         WHERE WorkSrtTime <> '' 
         GROUP BY WorkReportSeq, WorkReportSerl
    

        UPDATE A
           SET RealWorkTime = B.RealWorkTime
          FROM #KindData        AS A 
          JOIN #RealWorkTime    AS B ON ( B.WorkReportSeq = A.WorkReportSeq AND B.WorkReportSerl = A.WorkReportSerl ) 
         WHERE A.WorkSrtTime <> '' 
           AND A.WorkEndTime <> ''
        --------------------------------------------------------------
        -- 실작업시간계산, END 
        --------------------------------------------------------------
    END 
    ELSE 
    BEGIN 
        UPDATE A 
           SET RealWorkTime = ToolWorkTime 
          FROM #KindData AS A 
    END 
    
    --select * from #KindData  where shipseq = 2 and shipserl = 2786
    --return 

    -- Case별로 데이터 담아오기 (장비, 모선, 거래처, 프로젝트)
    SELECT MAX(A.IsQty) AS IsQty, 
           MAX(A.WorkDate) AS WorkDate, 
           CASE WHEN MAX(IsQty) = '1' THEN MAX(TodayQty) ELSE MAX(TodayMTWeight) END AS Qty, 
           CASE WHEN @WorkTimeSeq = 1 THEN MAX(A.RealWorkTime) ELSE SUM(A.RealWorkTime) END AS RealWorkTime, 
           MAX(CASE WHEN @UMAnalysisKind = 1016554001 THEN ToolName 
                    WHEN @UMAnalysisKind = 1016554002 THEN ShipSerlNo 
                    WHEN @UMAnalysisKind = 1016554003 THEN CustName 
                    WHEN @UMAnalysisKind = 1016554004 THEN PJTName 
                    END) AS AnalysisName, 
           MAX(CASE WHEN @UMAnalysisKind = 1016554001 THEN ToolSeq 
                    WHEN @UMAnalysisKind = 1016554002 THEN ShipSeq 
                    WHEN @UMAnalysisKind = 1016554003 THEN CustSeq 
                    WHEN @UMAnalysisKind = 1016554004 THEN PJTSeq 
                    END) AS AnalysisSeq, 
           MAX(CASE WHEN @UMAnalysisKind = 1016554002 THEN ShipSerl
                    ELSE 0 
                    END) AS AnalysisSerl, 
           WorkReportSeq, 
           CASE WHEN @UMAnalysisKind = 1016554001 THEN WorkReportSerl 
                ELSE 0 END AS WorkReportSerl 

      INTO #Result
      FROM #KindData AS A 
     GROUP BY WorkReportSeq, 
              CASE WHEN @UMAnalysisKind = 1016554001 THEN WorkReportSerl 
                   ELSE 0 END 
    
    -- 월별 실적이 있는 월 Cnt
    SELECT LEFT(StdYM,4) AS StdYear, AnalysisSeq, AnalysisSerl, SUM(Cnt) AS Cnt 
      INTO #DataCnt 
      FROM (
            SELECT DISTINCT LEFT(WorkDate,6) AS StdYM, AnalysisSeq, AnalysisSerl, 1 AS Cnt 
              FROM #Result
           ) AS A 
     GROUP BY LEFT(StdYM,4), AnalysisSeq, AnalysisSerl
        
    CREATE TABLE #Result_Sum
    (
        UMAnalysisKindName  NVARCHAR(200), 
        AnalysisName        NVARCHAR(200), 
        AnalysisSeq         INT, 
        AnalysisSerl        INT, 
        Qty01               DECIMAL(19,5), 
        Qty02               DECIMAL(19,5), 
        Qty03               DECIMAL(19,5), 
        Qty04               DECIMAL(19,5), 
        Qty05               DECIMAL(19,5), 
        Qty06               DECIMAL(19,5), 
        Qty07               DECIMAL(19,5), 
        Qty08               DECIMAL(19,5), 
        Qty09               DECIMAL(19,5), 
        Qty10               DECIMAL(19,5), 
        Qty11               DECIMAL(19,5), 
        Qty12               DECIMAL(19,5), 
        
        Time01              DECIMAL(19,5), 
        Time02              DECIMAL(19,5), 
        Time03              DECIMAL(19,5), 
        Time04              DECIMAL(19,5), 
        Time05              DECIMAL(19,5), 
        Time06              DECIMAL(19,5), 
        Time07              DECIMAL(19,5), 
        Time08              DECIMAL(19,5), 
        Time09              DECIMAL(19,5), 
        Time10              DECIMAL(19,5), 
        Time11              DECIMAL(19,5), 
        Time12              DECIMAL(19,5), 
        
        Month01             DECIMAL(19,5), 
        Month02             DECIMAL(19,5), 
        Month03             DECIMAL(19,5), 
        Month04             DECIMAL(19,5), 
        Month05             DECIMAL(19,5), 
        Month06             DECIMAL(19,5), 
        Month07             DECIMAL(19,5), 
        Month08             DECIMAL(19,5), 
        Month09             DECIMAL(19,5), 
        Month10             DECIMAL(19,5), 
        Month11             DECIMAL(19,5), 
        Month12             DECIMAL(19,5), 
        MonthTot            DECIMAL(19,5), 
        MonthAvg            DECIMAL(19,5), 
        Sort                INT
    )

    -- 최종조회 
    INSERT INTO #Result_Sum 
    (
        UMAnalysisKindName  , AnalysisName      , AnalysisSeq       , AnalysisSerl      , Qty01     ,
        Qty02               , Qty03             , Qty04             , Qty05             , Qty06     ,
        Qty07               , Qty08             , Qty09             , Qty10             , Qty11     ,
        Qty12               , Time01            , Time02            , Time03            , Time04    , 
        Time05              , Time06            , Time07            , Time08            , Time09    , 
        Time10              , Time11            , Time12            , Month01           , Month02   , 
        Month03             , Month04           , Month05           , Month06           , Month07   , 
        Month08             , Month09           , Month10           , Month11           , Month12   , 
        MonthTot           , MonthAvg           , Sort               
    )
    SELECT (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @UMAnalysisKind) AS UMAnalysisKindName, 
           A.AnalysisName, 
           A.AnalysisSeq, 
           A.AnalysisSerl, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.Qty ELSE 0 END) AS Qty01, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.Qty ELSE 0 END) AS Qty02, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.Qty ELSE 0 END) AS Qty03, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.Qty ELSE 0 END) AS Qty04, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.Qty ELSE 0 END) AS Qty05, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.Qty ELSE 0 END) AS Qty06, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.Qty ELSE 0 END) AS Qty07, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.Qty ELSE 0 END) AS Qty08, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.Qty ELSE 0 END) AS Qty09, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.Qty ELSE 0 END) AS Qty10, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.Qty ELSE 0 END) AS Qty11, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.Qty ELSE 0 END) AS Qty12, 
           
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.RealWorkTime ELSE 0 END) AS Time01, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.RealWorkTime ELSE 0 END) AS Time02, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.RealWorkTime ELSE 0 END) AS Time03, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.RealWorkTime ELSE 0 END) AS Time04, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.RealWorkTime ELSE 0 END) AS Time05, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.RealWorkTime ELSE 0 END) AS Time06, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.RealWorkTime ELSE 0 END) AS Time07, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.RealWorkTime ELSE 0 END) AS Time08, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.RealWorkTime ELSE 0 END) AS Time09, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.RealWorkTime ELSE 0 END) AS Time10, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.RealWorkTime ELSE 0 END) AS Time11, 
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.RealWorkTime ELSE 0 END) AS Time12, 
           
           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.RealWorkTime ELSE 0 END),0) AS Month01, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.RealWorkTime ELSE 0 END),0) AS Month02, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.RealWorkTime ELSE 0 END),0) AS Month03, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.RealWorkTime ELSE 0 END),0) AS Month04, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.RealWorkTime ELSE 0 END),0) AS Month05, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.RealWorkTime ELSE 0 END),0) AS Month06, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.RealWorkTime ELSE 0 END),0) AS Month07, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.RealWorkTime ELSE 0 END),0) AS Month08, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.RealWorkTime ELSE 0 END),0) AS Month09, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.RealWorkTime ELSE 0 END),0) AS Month10, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.RealWorkTime ELSE 0 END),0) AS Month11, 

           SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.Qty ELSE 0 END) / 
           NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.RealWorkTime ELSE 0 END),0) AS Month12, 
                      
           SUM(A.Qty) / NULLIF(SUM(A.RealWorkTime),0) AS MonthTot, 
           SUM(A.Qty) / NULLIF(SUM(A.RealWorkTime),0) / NULLIF(MAX(B.Cnt),0) AS MonthAvg, 
           2 AS Sort
      FROM #Result              AS A 
      LEFT OUTER JOIN #DataCnt  AS B ON ( B.AnalysisSeq = A.AnalysisSeq AND B.AnalysisSerl = A.AnalysisSerl ) 
     GROUP BY A.AnalysisName, A.AnalysisSeq, A.AnalysisSerl 
    
    --select * From #Result 
    --return 
    IF EXISTS (SELECT 1 FROM #Result)
    BEGIN 
        INSERT INTO #Result_Sum 
        (
            UMAnalysisKindName  , AnalysisName      , AnalysisSeq       , AnalysisSerl      , Qty01     ,
            Qty02               , Qty03             , Qty04             , Qty05             , Qty06     ,
            Qty07               , Qty08             , Qty09             , Qty10             , Qty11     ,
            Qty12               , Time01            , Time02            , Time03            , Time04    , 
            Time05              , Time06            , Time07            , Time08            , Time09    , 
            Time10              , Time11            , Time12            , Month01           , Month02   , 
            Month03             , Month04           , Month05           , Month06           , Month07   , 
            Month08             , Month09           , Month10           , Month11           , Month12   , 
            MonthTot           , MonthAvg           , Sort               
        )
        SELECT '' AS UMAnalysisKindName, 
               CASE WHEN MAX(IsQty) = '1' THEN '수량' ELSE '물량' END AS AnalysisName, 
               0 AS AnalysisSeq, 
               0 AS AnalysisSerl, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.Qty ELSE 0 END) AS Qty01, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.Qty ELSE 0 END) AS Qty02, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.Qty ELSE 0 END) AS Qty03, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.Qty ELSE 0 END) AS Qty04, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.Qty ELSE 0 END) AS Qty05, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.Qty ELSE 0 END) AS Qty06, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.Qty ELSE 0 END) AS Qty07, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.Qty ELSE 0 END) AS Qty08, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.Qty ELSE 0 END) AS Qty09, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.Qty ELSE 0 END) AS Qty10, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.Qty ELSE 0 END) AS Qty11, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.Qty ELSE 0 END) AS Qty12, 
           
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.RealWorkTime ELSE 0 END) AS Time01, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.RealWorkTime ELSE 0 END) AS Time02, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.RealWorkTime ELSE 0 END) AS Time03, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.RealWorkTime ELSE 0 END) AS Time04, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.RealWorkTime ELSE 0 END) AS Time05, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.RealWorkTime ELSE 0 END) AS Time06, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.RealWorkTime ELSE 0 END) AS Time07, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.RealWorkTime ELSE 0 END) AS Time08, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.RealWorkTime ELSE 0 END) AS Time09, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.RealWorkTime ELSE 0 END) AS Time10, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.RealWorkTime ELSE 0 END) AS Time11, 
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.RealWorkTime ELSE 0 END) AS Time12, 
           
               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '01' THEN A.RealWorkTime ELSE 0 END),0) AS Month01, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '02' THEN A.RealWorkTime ELSE 0 END),0) AS Month02, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '03' THEN A.RealWorkTime ELSE 0 END),0) AS Month03, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '04' THEN A.RealWorkTime ELSE 0 END),0) AS Month04, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '05' THEN A.RealWorkTime ELSE 0 END),0) AS Month05, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '06' THEN A.RealWorkTime ELSE 0 END),0) AS Month06, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '07' THEN A.RealWorkTime ELSE 0 END),0) AS Month07, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '08' THEN A.RealWorkTime ELSE 0 END),0) AS Month08, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '09' THEN A.RealWorkTime ELSE 0 END),0) AS Month09, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '10' THEN A.RealWorkTime ELSE 0 END),0) AS Month10, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '11' THEN A.RealWorkTime ELSE 0 END),0) AS Month11, 

               SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.Qty ELSE 0 END) / 
               NULLIF(SUM(CASE WHEN LEFT(A.WorkDate,6) = @StdYear + '12' THEN A.RealWorkTime ELSE 0 END),0) AS Month12, 
                      
               SUM(A.Qty) / NULLIF(SUM(A.RealWorkTime),0) AS MonthTot, 
               SUM(A.Qty) / NULLIF(SUM(A.RealWorkTime),0) / NULLIF(MAX(B.Cnt),0) AS MonthAvg, 
               1 AS Sort 
          FROM #Result              AS A 
          LEFT OUTER JOIN #DataCnt  AS B ON ( B.AnalysisSeq = A.AnalysisSeq AND B.AnalysisSerl = A.AnalysisSerl ) 
    END 

    SELECT *
      FROM #Result_Sum
     ORDER BY Sort, AnalysisName 
    
    RETURN 
