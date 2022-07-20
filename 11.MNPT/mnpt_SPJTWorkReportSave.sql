  
IF OBJECT_ID('mnpt_SPJTWorkReportSave') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportSave  
GO  
    
-- v2017.09.25
  
-- 작업실적입력-SS1저장 by 이재천
CREATE PROC mnpt_SPJTWorkReportSave
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    --------------------------------------------------
    -- 할증구분코드에서 공유,휴일 만들어주기
    --------------------------------------------------
    -- 토요, 일요(공휴), 공휴구분
    SELECT CASE WHEN DATENAME(WEEKDAY, A.WorkDate) = '토요일' THEN B.MinorSeq ELSE C.MinorSeq END AS UMExtraSeq
        INTO #StaHoliDay
        FROM #BIZ_OUT_DataBlock1 AS A 
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000001 
                            AND Z.ValueText = '1' 
                        ) AS B ON ( 1 = 1 ) 
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000002 
                            AND Z.ValueText = '1' 
                        ) AS C ON ( 1 = 1 ) 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
        AND DATENAME(WEEKDAY, A.WorkDate) IN ( '토요일', '일요일' ) 
    UNION ALL 
    -- 공휴구분
    SELECT C.MinorSeq AS UMExtraSeq 
        FROM #BIZ_OUT_DataBlock1 AS A 
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
        LEFT OUTER JOIN (
                        SELECT MAX(MinorSeq) AS MinorSeq
                            FROM _TDAUMinorValue AS Z
                            WHERE Z.CompanySeq = @CompanySeq
                            AND Z.MajorSeq = 1015782
                            AND Z.Serl = 1000002 
                            AND Z.ValueText = '1' 
                        ) AS C ON ( 1 = 1 ) 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
        AND H.Solar IS NOT NULL 
        
    DECLARE @SatHoilUMExtraSeq NVARCHAR(100) 

    SELECT @SatHoilUMExtraSeq = MAX(UMExtraSeq)
        FROM #StaHoliDay 
        WHERE UMExtraSeq IS NOT NULL


    -- 기존 공휴, 토욜 지우고 다시 만들어주기 
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkReportSeq     INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkReportSeq, ExtraGroupSeq ) 
    SELECT WorkReportSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM #BIZ_OUT_DataBlock1 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkReportSeq     INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkReportSeq     INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @CntSub         INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkReportSeq    INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @CntSub = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @WorkReportSeq   = WorkReportSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @CntSub 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkReportSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkReportSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        DELETE A 
          FROM #CheckExtraSeq AS A 
          JOIN ( 
                SELECT A.MinorSeq 
                  FROM _TDAUMinor                   AS A 
                  LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
                 WHERE A.CompanySeq = @CompanySeq 
                   AND A.MajorSeq = 1015782
                   AND ( B.ValueText = '1' OR C.ValueText = '1' ) 
               ) AS B ON ( B.MInorSeq = A.UMExtraType ) 
        
        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + CONVERT(NVARCHAR(100),UMExtraType)
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkReportSeq, MultiExtraName ) 
        SELECT @WorkReportSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @CntSub >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @CntSub = @CntSub + 1 
        END 
    END 

    UPDATE A
       SET ExtraGroupSeq = B.MultiExtraName 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN #GroupExtraName      AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.WorkingTag IN ( 'A', 'U' ) 
       AND A.Status = 0 
    
    
    UPDATE A
        SET ExtraGroupSeq = CASE WHEN LEN(@SatHoilUMExtraSeq) = 10
                                THEN (CASE WHEN ISNULL(ExtraGroupSeq,'') = '' THEN @SatHoilUMExtraSeq ELSE ExtraGroupSeq + ',' + @SatHoilUMExtraSeq END)
                                ELSE ExtraGroupSeq
                                END 
               
        FROM #BIZ_OUT_DataBlock1 AS A 
        WHERE A.WorkingTag IN ( 'U', 'A' ) 
        AND A.Status = 0 
    --------------------------------------------------
    -- 할증구분코드에서 공유,휴일 만들어주기, End  
    --------------------------------------------------
    

    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkReport')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTWorkReport'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'WorkReportSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    --------------------------------------------------------------
    -- 실작업시간계산  
    --------------------------------------------------------------
    DECLARE @EnvTime NCHAR(4) 

    SELECT @EnvTime = REPLACE(A.EnvValue,':','')
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 5
    


    create table #MainTime
    (
        WorkReportSeq     INT, 
        WorkSrtTime     NCHAR(12), 
        WorkEndTime     NCHAR(12)
    )

    create table #ResultTime
    (
        WorkReportSeq     INT, 
        WorkSrtTime     NCHAR(12), 
        WorkEndTime     NCHAR(12)
    )


    INSERT INTO #MainTime (WorkReportSeq, WorkSrtTime, WorkEndTime)
    SELECT A.WorkReportSeq, 
           CASE WHEN REPLACE(A.WorkSrtTime,':','') < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkSrtTime,':',''), 
           CASE WHEN REPLACE(A.WorkEndTime,':','') <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + REPLACE(A.WorkEndTime,':','')
      FROM #BIZ_OUT_DataBlock1 AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''


    SELECT ROW_NUMBER() OVER(Order BY A.MinorSeq) AS IDX_NO, 
           CASE WHEN B.ValueText < @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + B.ValueText AS SrtTime, 
           CASE WHEN C.ValueText <= @EnvTime THEN CONVERT(NCHAR(8),DATEADD(DAY,1,GETDATE()),112) ELSE CONVERT(NCHAR(8),GETDATE(),112) END + C.ValueText AS EndTime
      INTO #UMinorTime
      from _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015905
    

    CREATE TABLE #WorkSrtTime
    (
        WorkReportSeq     INT, 
        WorkSrtTime     NCHAR(12)
    )

    DECLARE @Cnt            INT

    SELECT @Cnt = 1 

    WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #UMinorTime),0) + 1 ) 
    BEGIN 
        
        INSERT INTO #ResultTime 
        SELECT A.WorkReportSeq, 
               
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
          LEFT OUTER JOIN #WorkSrtTime  AS C ON ( C.WorkReportSeq = A.WorkReportSeq ) 
        
        TRUNCATE TABLE #WorkSrtTime 
        INSERT INTO #WorkSrtTime ( WorkReportSeq, WorkSrtTime)
        SELECT A.WorkReportSeq, 
               CASE WHEN A.WorkSrtTime > CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                    THEN A.WorkSrtTime 
                    ELSE CASE WHEN A.WorkEndTime > B.SrtTime THEN B.EndTime ELSE A.WorkEndTime END 
                    END
          FROM #MainTime                AS A 
          LEFT OUTER JOIN #UMinorTime   AS B ON ( B.IDX_NO = @Cnt ) 
        
        SELECT @Cnt = @Cnt + 1 

    END 
    
    SELECT WorkReportSeq, 
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
        GROUP BY WorkReportSeq 

    UPDATE A
       SET RealWorkTime = B.RealWorkTime
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN #RealWorkTime        AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 
       AND A.WorkSrtTime <> '' 
       AND A.WorkEndTime <> ''
    --------------------------------------------------------------
    -- 실작업시간계산, END 
    --------------------------------------------------------------

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkReport    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN 
        

        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, Srt
        --------------------------------------------------------------
        SELECT A.WorkingTag, 
               A.Status, 
               A.WorkReportSeq, 
               B.WorkReportSerl
          INTO #ItemLog 
          FROM #BIZ_OUT_DataBlock1      AS A 
          JOIN mnpt_TPJTWorkReportItem    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq )
         WHERE A.Status = 0 
           AND A.WorkingTag = 'D' 

        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkReportItem')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTWorkReportItem'    , -- 테이블명        
                      '#ItemLog'    , -- 임시 테이블명        
                      'WorkReportSeq,WorkReportSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        --------------------------------------------------------------
        -- 마스터 삭제시 디테일 로그남기기, End
        --------------------------------------------------------------
        
        DELETE B   
          FROM #BIZ_OUT_DataBlock1      AS A   
          JOIN mnpt_TPJTWorkReportItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.PJTSeq         = A.PJTSeq          , 
               B.UMLoadType     = A.UMLoadType      , 
               B.TodayQty       = A.TodayQty        ,  
               B.TodayMTWeight  = A.TodayMTWeight   ,  
               B.TodayCBMWeight = A.TodayCBMWeight  ,  
               B.UMWorkTeam     = A.UMWorkTeam      ,
               B.ExtraGroupSeq  = A.ExtraGroupSeq   ,  
               B.WorkSrtTime    = A.WorkSrtTime     ,  
               B.WorkEndTime    = A.WorkEndTime     ,  
               B.RealWorkTime   = A.RealWorkTime    , 
               B.EmpSeq         = A.EmpSeq          ,  
               B.DRemark        = A.DRemark         ,  
               B.LastUserSeq    = @UserSeq          ,  
               B.LastDateTime   = GETDATE()         ,
               B.PgmSeq         = @PgmSeq
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkReport    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  

        UPDATE B   
           SET B.PJTSeq         = A.PJTSeq          
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkPlanSeq = B.WorkPlanSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
        UPDATE B   
           SET B.UMWeather      = A.UMWeather     ,  
               B.MRemark        = A.MRemark       , 
               B.ManRemark      = A.ManRemark      
          FROM #BIZ_OUT_DataBlock1  AS A   
          JOIN mnpt_TPJTWorkReport    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkDate = B.WorkDate )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTWorkReport  
        (   
            CompanySeq, WorkReportSeq, WorkDate, UMWeather, MRemark, 
            IsCfm, PJTSeq, ShipSeq, ShipSerl, UMWorkType, 
            TodayQty, TodayMTWeight, TodayCBMWeight, UMWorkTeam, ExtraGroupSeq, 
            WorkSrtTime, WorkEndTime, RealWorkTime, EmpSeq, DRemark, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq, 
            WorkPlanSeq, ManRemark, UMLoadType
        )   
        SELECT @CompanySeq, WorkReportSeq, WorkDate, UMWeather, MRemark, 
               '0', PJTSeq, ShipSeq, ShipSerl, UMWorkType, 
               TodayQty, TodayMTWeight, TodayCBMWeight, UMWorkTeam, ExtraGroupSeq, 
               REPLACE(WorkSrtTime,':',''), REPLACE(WorkEndTime,':',''), RealWorkTime, EmpSeq, DRemark, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq, 
               WorkPlanSeq, ManRemark, UMLoadType 
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    
    -- 처리결과반영 
    UPDATE A
       SET UMWorkDivision = CASE WHEN A.ShipSeq = 0 OR A.ShipSeq IS NULL THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815002) 
                                 ELSE (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815001) 
                                 END, -- 작업구분 
           
           SumQty = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(KK.SumQty,0) END,           -- 전일누적 수량
           SumMTWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(KK.SumMTWeight,0) END, -- 전일누적 MT
           SumCBMWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE  ISNULL(KK.SumCBMWeight,0) END, -- 전일누적 CBM

           EtcQty = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END, -- 잔여수량
           EtcMTWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END, -- 잔여MT
           EtcCBMWeight = CASE WHEN A.ShipSerl = 0 THEN 0 ELSE ISNULL(A.GoodsCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END, -- 잔여CBM
           UMBisWorkTypeCnt = ISNULL(M.UMBisWorkTypeCnt,0) -- 업무구분Cnt
      FROM #BIZ_OUT_DataBlock1 AS A 
      OUTER APPLY ( -- 전일 누계
                    SELECT PJTSeq, 
                           UMWorkType, 
                           SUM(TodayQty) AS SumQty, 
                           SUM(TodayMTWeight) AS SumMTWeight, 
                           SUM(TodayCBMWeight) AS SumCBMWeight
                      FROM mnpt_TPJTWorkReport 
                     WHERE CompanySeq = @CompanySeq 
                       AND WorkDate < A.WorkDate  
                       AND PJTSeq = A.PJTSeq 
                       AND UMWorkType = A.UMWorkType
                    GROUP BY PJTSeq, UMWorkType 
                  ) AS K 
      LEFT OUTER JOIN (
                        SELECT Z.WorkReportSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkReportItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkReportSeq 
                      ) AS M ON ( M.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
      OUTER APPLY ( -- 전일 누계
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS SumQty, 
                               SUM(Z.TodayMTWeight) AS SumMTWeight, 
                               SUM(Z.TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkReport AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                          LEFT OUTER JOIN _TDAUMinor      AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = Z.UMWorkType ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkDate < A.WorkDate
                           AND Z.PJTSeq = A.PJTSeq
                           AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END
                           AND Z.ShipSeq = A.ShipSeq
                           AND Z.ShipSerl = A.ShipSerl
                         GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                  ) AS KK
      OUTER APPLY ( -- 금일 작업
                    SELECT Z.PJTSeq, 
                           Z.ShipSeq, 
                           Z.ShipSerl, 
                           CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                           SUM(Z.TodayQty) AS TodayQty, 
                           SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                           SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                      FROM mnpt_TPJTWorkReport AS Z 
                      LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkDate = A.WorkDate 
                       AND Z.PJTSeq = A.PJTSeq 
                       AND CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl
                     GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                  ) AS W
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A', 'U' ) 



    RETURN  
