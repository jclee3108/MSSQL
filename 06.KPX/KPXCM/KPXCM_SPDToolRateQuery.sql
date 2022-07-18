  
IF OBJECT_ID('KPXCM_SPDToolRateQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDToolRateQuery  
GO  
  
-- v2016.04.28 
  
-- 연간설비가동율조회(우레탄)-조회 by 이재천   
CREATE PROC KPXCM_SPDToolRateQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT, 
            @StdYear    NCHAR(4), 
            @IsRemark   NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit    = ISNULL( FactUnit, 0 ),  
           @StdYear     = ISNULL( StdYear, '' ), 
           @IsRemark    = ISNULL( IsRemark, '0')
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit    INT,  
            StdYear     NCHAR(4), 
            IsRemark    NCHAR(1) 
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
        Remark          NVARCHAR(MAX)
    )
    
    INSERT INTO #Result( StdMonthSub, StdMonth ) 
    SELECT @StdYear + '01', '1월'
    UNION ALL 
    SELECT @StdYear + '02', '2월'
    UNION ALL 
    SELECT @StdYear + '03', '3월'
    UNION ALL 
    SELECT @StdYear + '04', '4월'
    UNION ALL 
    SELECT @StdYear + '05', '5월'
    UNION ALL 
    SELECT @StdYear + '06', '6월'
    UNION ALL 
    SELECT @StdYear + '07', '7월'
    UNION ALL 
    SELECT @StdYear + '08', '8월'
    UNION ALL 
    SELECT @StdYear + '09', '9월'
    UNION ALL 
    SELECT @StdYear + '10', '10월'
    UNION ALL 
    SELECT @StdYear + '11', '11월'
    UNION ALL 
    SELECT @StdYear + '12', '12월'
    
    --SELECT * FROM #Result
    
    
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
       AND LEFT(A.SrtDate,4) = @StdYear
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
       AND LEFT(A.SrtDate,4) = @StdYear
       AND LEFT(A.SrtDate,6) <> LEFT(A.EndDate,6) 
    
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
                         WHERE SYear = @StdYear 
                         GROUP BY LEFT(Solar,6) 
                        ) AS C ON ( A.StdMonthSub = C.StdYM ) 
               --JOIN #ShutDown AS D ON A.StdMonthSub = D.StdMonthSub -- bgkeum (ShutDown 등록한 건만 나오게 해달라는 요청) 주석하고 현업과 확인 
                        
    -- 실제가동일 계산 
    UPDATE A 
       SET RealWorkDate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * AllWorkDate END, 
           ToolRate = CASE WHEN AllWorkTime = 0 THEN 0 ELSE (RealWorkTime / AllWorkTime) * 100 END 
      FROM #Result AS A 
    
    -- 비고 #Temp
    CREATE TABLE #Remark
    (
        StdMonthSub     NCHAR(6), 
        Remark          NVARCHAR(MAX) 
    )
    IF @IsRemark = '1' 
    BEGIN 
        INSERT INTO #Remark ( StdMonthSub, Remark ) 
        SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark + ' : ' + A.Remark1 AS Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
        FROM #ShutDown AS B 
        GROUP BY B.StdMonthSub		
    END 
    ELSE
    BEGIN
        INSERT INTO #Remark ( StdMonthSub, Remark ) 
        SELECT B.StdMonthSub, REPLACE ( REPLACE ( REPLACE ( (SELECT A.Remark FROM #ShutDown AS A WHERE StdMonthSub = B.StdMonthSub  FOR XML AUTO, ELEMENTS),'</Remark></A><A><Remark>',', '), '<A><Remark>',''), '</Remark></A>', '') AS Remark 
        FROM #ShutDown AS B 
        GROUP BY B.StdMonthSub	
    END 
    
    -- 비고 Update 
    UPDATE A
       SET Remark = ISNULL(B.Remark,'')
      FROM #Result AS A 
      LEFT OUTER JOIN #Remark AS B ON ( B.StdMonthSub = A.StdMonthSub ) 
    

    -- 합계 
    INSERT INTO #Result 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999998, '계', SUM(AllWorkDate), SUM(RealWorkDate), SUM(AllWorkTime), 
           SUM(RealWorkTime), SUM(ShutDownTime), CASE WHEN SUM(AllWorkTime) = 0 THEN 0 ELSE (SUM(RealWorkTime) / SUM(AllWorkTime)) * 100 END, 
           '총 SHUT-DOWN시간 : '+ CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,SUM(ShutDownTime)) / 24) + '일)'
      FROM #Result
    
    -- 평균 
    INSERT INTO #Result 
    ( 
        StdMonthSub, StdMonth, AllWorkDate, RealWorkDate, AllWorkTime, 
        RealWorkTime, ShutDownTime, ToolRate, Remark 
    ) 
    SELECT 999999, '평균', AVG(AllWorkDate), AVG(RealWorkDate), AVG(AllWorkTime), 
           AVG(RealWorkTime), AVG(ShutDownTime), CASE WHEN AVG(AllWorkTime) = 0 THEN 0 ELSE (AVG(RealWorkTime) / AVG(AllWorkTime)) * 100 END, 
           '평균 SHUT-DOWN시간 : '+ CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime))) + 'HR (' + CONVERT(NVARCHAR(100),CONVERT(INT,AVG(ShutDownTime)) / 24) + '일)'
      FROM #Result
     WHERE StdMonthSub < 999998 -- bgkeum
      
    SELECT *, @StdYear AS StdYear 
      FROM #Result 
        
    RETURN  
    GO
exec KPXCM_SPDToolRateQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <StdYear>2016</StdYear>
    <IsRemark>1</IsRemark>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036660,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030027