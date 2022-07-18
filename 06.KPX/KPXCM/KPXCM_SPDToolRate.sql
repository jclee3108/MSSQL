  
IF OBJECT_ID('KPXCM_SPDToolRate') IS NOT NULL   
    DROP PROC KPXCM_SPDToolRate  
GO  
  
-- v2016.05.19  
  
-- 연간설비가동율-공통 조회 by 이재천   
CREATE PROC KPXCM_SPDToolRate  
    @CompanySeq     INT = 2, 
    @FactUnit       INT = 3,                -- 생산사업장 
    @StdYearFr      NCHAR(4),               -- From연도
    @StdYearTo      NCHAR(4),               -- To연도 
    @SMPlanType     INT = 1080002,          -- 계획/실제 구분 (1080001 : 계획, 1080002 : 실제)
    @StdYM          NCHAR(6) = NULL,        -- 조회기준월(생략가능)
    @StyleKind      NCHAR(1) = 'M',         -- 집계 기준 ( Y : 연도, M : 월 ) 
    @PgmSeq         INT = 0,                -- 특별한 경우를 Case 만들기위해 필요 
    @IsRemark       NCHAR(1) = '0'          -- 사유포함여부 
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    
    --------------결과 테이블-----------------------------------
    /*
    CREATE TABLE #Result_Main  
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark1         NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)  
    )
    */
    --------------결과 테이블-----------------------------------
    
    IF ISNULL(@StdYM,'') = '' SELECT @StdYM = '999912'
    
    CREATE TABLE #Result_Main  
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark          NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)
    )
    
    CREATE TABLE #Result 
    (
        StdMonthSub     NCHAR(6), 
        StdMonth        NVARCHAR(20), 
        AllWorkDate     DECIMAL(19,5), 
        RealWorkDate    DECIMAL(19,5), 
        AllWorkTime     DECIMAL(19,5), 
        RealWorkTime    DECIMAL(19,5), 
        ShutDownTime    DECIMAL(19,5), 
        ToolRate        DECIMAL(19,5), 
        Remark          NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX), 
        StdYear         NCHAR(4)  
    )
    
    INSERT INTO #Result( StdMonthSub, StdMonth ) 
    SELECT CONVERT(NCHAR(4),A.StdYear) + B.StdMonthSub, StdMonth 
      FROM ( 
            SELECT DISTINCT SYear AS StdYear 
              FROM _TCOMCalendar AS A 
             WHERE SYear BETWEEN @StdYearFr AND @StdYearTo
           ) AS A 
      JOIN ( 
            SELECT '01' AS StdMonthSub , '1월' AS StdMonth 
            UNION ALL 
            SELECT '02', '2월'
            UNION ALL 
            SELECT '03', '3월'
            UNION ALL 
            SELECT '04', '4월'
            UNION ALL 
            SELECT '05', '5월'
            UNION ALL 
            SELECT '06', '6월'
            UNION ALL 
            SELECT '07', '7월'
            UNION ALL 
            SELECT '08', '8월'
            UNION ALL 
            SELECT '09', '9월'
            UNION ALL 
            SELECT '10', '10월'
            UNION ALL 
            SELECT '11', '11월'
            UNION ALL 
            SELECT '12', '12월'
           ) AS B ON  ( 1 = 1 ) 
    
    CREATE TABLE #ShutDown 
    (
        SrtDateTime     DATETIME, 
        EndDateTime     DATETIME, 
        HourDiff        INT, 
        AllHour         INT,  
        AllDay          INT, 
        StdMonthSub     NCHAR(6), 
        Remark          NVARCHAR(MAX), 
        Remark1         NVARCHAR(MAX) 
    )
    -- 월이 겹친경우 나눠서 넣어주기 
    INSERT INTO #ShutDown ( SrtDateTime, EndDateTime, HourDiff, Remark, Remark1 )
    SELECT LEFT(A.SrtDate,4) + '-' + SUBSTRING(A.SrtDate,5,2) + '-' + RIGHT(A.SrtDate,2) + ' ' + B.MinorName + ':00.000', 
           CASE WHEN LEFT(A.SrtDate,6) = LEFT(A.EndDate,6) 
                THEN LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + RIGHT(A.EndDate,2) + ' ' + C.MinorName + ':00.000'
                ELSE LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + '01' + ' ' + '00:00:00.000'
                END, 
           0, 
           SUBSTRING(A.SrtDate,5,2) + '/' + RIGHT(A.SrtDate,2) + ' ' + B.MinorName + ' ~ ' + 
           CASE WHEN LEFT(A.SrtDate,6) = LEFT(A.EndDate,6) 
                THEN SUBSTRING(A.EndDate,5,2) + '/' + RIGHT(A.EndDate,2) + ' ' + C.MinorName 
                ELSE SUBSTRING(A.EndDate,5,2) + '/' + '01' + ' ' + '00:00'
                END AS Remark, 
           A.Remark 
      FROM KPXCM_TPDShutDown        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SrtTimeSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSEq = A.EndTimeSeq ) 
     WHERE A.FactUnit = @FactUnit 
       AND LEFT(A.SrtDate,4) BETWEEN @StdYearFr AND @StdYearTo
       AND ( @SMPlanType = 0 OR A.SMPlanType = @SMPlanType) -- 계획/실제 추가 20160518 jhpark 
    UNION ALL 
    SELECT LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + '01' + ' ' + '00:00:00.000', 
           LEFT(A.EndDate,4) + '-' + SUBSTRING(A.EndDate,5,2) + '-' + RIGHT(A.EndDate,2) + ' ' + C.MinorName + ':00.000', 
           0, 
           SUBSTRING(A.EndDate,5,2) + '/' + '01' + ' ' + '00:00' + ' ~ ' + 
           SUBSTRING(A.EndDate,5,2) + '/' + RIGHT(A.EndDate,2) + ' ' + C.MinorName AS Remark, 
           A.Remark 
      FROM KPXCM_TPDShutDown        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SrtTimeSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSEq = A.EndTimeSeq ) 
     WHERE A.FactUnit = @FactUnit 
       AND LEFT(A.SrtDate,4) BETWEEN @StdYearFr AND @StdYearTo
       AND LEFT(A.SrtDate,6) <> LEFT(A.EndDate,6) 
       AND ( @SMPlanType = 0 OR A.SMPlanType = @SMPlanType) -- 계획/실제 추가 20160518 jhpark 
    
    
    --select * from #ShutDown Order by SrtDateTime 
    --return 

    -- ShutDown 시간기준  
    UPDATE A 
       SET HourDiff = DATEDIFF(Hour, SrtDateTime, EndDateTime), 
           StdMonthSub = CONVERT(NCHAR(6),SrtDateTime,112), 
           Remark = Remark + '('+ CONVERT(NVARCHAR(100),DATEDIFF(Hour, SrtDateTime, EndDateTime)) +'HR)'
      FROM #ShutDown AS A 
    
    
    -- 해당월의 전체 시간 
    UPDATE A 
       SET AllWorkTime = (ISNULL(C.AllDay,0) * 24), -- 전체시간 
           ShutDownTime = ISNULL(B.HourDiff,0), -- Shutdown 시간 -- bgkeum
           RealWorkTime = (ISNULL(C.AllDay,0) * 24) - ISNULL(B.HourDiff,0), -- 실제가동시간  -- bgkeum
           AllWorkDate = ISNULL(C.AllDay,0) -- 전체일수 
      FROM #Result AS A 
      LEFT OUTER JOIN (
                        SELECT StdMonthSub, SUM(HourDiff) AS HourDiff, MAX(AllHour) AS AllHour, MAX(AllDay) AS AllDay 
                          FROM #ShutDown 
                         GROUP BY StdMonthSub
                      ) AS B ON ( B.StdMonthSub = A.StdMonthSub ) 
      LEFT OUTER JOIN (
                        SELECT MAX(CONVERT(INT,RIGHT(Solar,2))) AS AllDay, LEFT(Solar,6) AS StdYM
                          FROM _TCOMCalendar 
                         WHERE SYear BETWEEN @StdYearFr AND @StdYearTo 
                         GROUP BY LEFT(Solar,6) 
                        ) AS C ON ( A.StdMonthSub = C.StdYM ) 
     WHERE A.StdMonthSub <= @StdYM 
    
    -- 실제가동일 계산 
    UPDATE A 
       SET RealWorkDate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * AllWorkDate END, 
           ToolRate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * 100 END 
      FROM #Result AS A 
     WHERE A.StdMonthSub <= @StdYM  
    
    
    
    -- 비고 #Temp
    CREATE TABLE #Remark
    (
        StdMonthSub     NCHAR(6), 
        Remark1         NVARCHAR(MAX), 
        Remark2         NVARCHAR(MAX) 
    )
    
    IF @PgmSeq = 1030027 -- 연간설비가동율조회(우레탄)
    BEGIN      
        IF @IsRemark = '1' -- 사유포함여부 
        BEGIN 
            INSERT INTO #Remark ( StdMonthSub, Remark1 ) 
            SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark + ' : ' + A.Remark1 AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
            FROM #ShutDown AS B 
            GROUP BY B.StdMonthSub		
        END 
        ELSE
        BEGIN
            INSERT INTO #Remark ( StdMonthSub, Remark1 ) 
            SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
            FROM #ShutDown AS B 
            GROUP BY B.StdMonthSub	
        END
        
    END 
    ELSE
    BEGIN 
        INSERT INTO #Remark ( StdMonthSub, Remark1, Remark2  ) 
        SELECT B.StdMonthSub, 
               REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',NCHAR(13)), '<A><Remark>',''), '</Remark></A>', '') AS Remark1,  
               REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark1 AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',NCHAR(13)), '<A><Remark>',''), '</Remark></A>', '') AS Remark2 
        FROM #ShutDown AS B 
        GROUP BY B.StdMonthSub		
    END 
    

    -- 비고 Update 
    UPDATE A
       SET Remark = ISNULL(B.Remark1,''),
           Remark2 = ISNULL(B.Remark2,'')
      FROM #Result AS A 
      LEFT OUTER JOIN #Remark AS B ON ( B.StdMonthSub = A.StdMonthSub ) 
     WHERE A.StdMonthSub <= @StdYM  
    
    
    IF @StyleKind = 'M' -- 월별 집계 
    BEGIN 
        INSERT INTO #Result_Main
        SELECT * 
          FROM #Result
    END 
    ELSE -- 연도 집계 
    BEGIN 
        INSERT INTO #Result_Main 
        ( 
            StdMonthSub, AllWorkDate, AllWorkTime, RealWorkTime, ShutDownTime, 
            RealWorkDate, ToolRate, Remark, Remark2, StdMonth
        ) 
        SELECT LEFT(StdMonthSub,4), 
               SUM(AllWorkDate), 
               SUM(AllWorkTime), 
               SUM(AllWorkTime) - SUM(ShutDownTime), 
               SUM(ShutDownTime), 
               
               CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE ((SUM(AllWorkTime) - SUM(ShutDownTime)) / SUM(AllWorkTime)) * SUM(AllWorkDate) END, 
               CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE ((SUM(AllWorkTime) - SUM(ShutDownTime)) / SUM(AllWorkTime)) * 100 END,
               '', '', ''
          FROM #Result 
         GROUP BY LEFT(StdMonthSub,4) 
    END 
    
    -- 합계 
    INSERT INTO #Result_Main 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999998, '계', SUM(AllWorkDate), SUM(RealWorkDate), SUM(AllWorkTime), 
           SUM(RealWorkTime), SUM(ShutDownTime), CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE (SUM(RealWorkTime) / SUM(AllWorkTime)) * 100 END, 
           '총 SHUT-DOWN시간 : '+ CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime)) / 24) + '일)'
      FROM #Result_Main
    
    -- 평균 
    INSERT INTO #Result_Main 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999999, '평균', AVG(AllWorkDate), AVG(RealWorkDate), AVG(AllWorkTime), 
           AVG(RealWorkTime), AVG(ShutDownTime), CASE WHEN AVG(AllWorkTime) = 0 THEN 0 ELSE (AVG(RealWorkTime) / AVG(AllWorkTime)) * 100 END, 
           '평균 SHUT-DOWN시간 : '+ CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime)) / 24) + '일)'
      FROM #Result_Main
     WHERE StdMonthSub < 999998 
    
    IF @PgmSeq = 1030027 -- 연간설비가동율조회(우레탄) 출력물 
    BEGIN 
        UPDATE A 
           SET StdYear = LEFT(StdMonthSub,4)
          FROM #Result_Main AS A 
    END 
    
    SELECT *
      FROM #Result_Main 
    
    RETURN  
    GO
begin tran 

exec KPXCM_SPDToolRate @CompanySeq = 1             
                      ,@FactUnit   = 1              -- 생산사업장 
                      ,@StdYearFr  = '2015'         -- From연도
                      ,@StdYearTo  = '2016'         -- To연도 
                      ,@SMPlanType  = 1080002       -- 계획/실제 구분 (1080001 : 계획, 1080002 : 실제) -> 생략가능 기본 : 실제(1080002)
                      ,@StdYM       = '201605'      -- 조회기준월 -> 생략가능 기본 : 현재월 
                      ,@StyleKind   = 'M'           -- 집계 기준 ( Y : 연도, M : 월 ) -> 생략가능 기본 : 략 
                      --,@PgmSeq      = 1030027       -- 특별한 경우를 Case 만들기위해 필요  
                      --,@IsRemark    = '1'           -- 사유포함여부 
rollback 