
IF OBJECT_ID('KPX_SSLWeekSalesPlanTitleQuery') IS NOT NULL 
    DROP PROC KPX_SSLWeekSalesPlanTitleQuery
GO 

-- v2014.11.17 

-- 주간판매계획입력(타이틀조회) by이재천    
CREATE PROC KPX_SSLWeekSalesPlanTitleQuery                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 

AS        

    DECLARE @docHandle  INT,
            @FromDate   NCHAR(8), 
            @ToDate     NCHAR(8) 
 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @FromDate = ISNULL(FromDate, ''), 
           @ToDate   = ISNULL(ToDate, '') 
    
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (FromDate   NCHAR(8),
            ToDate     NCHAR(8))
    
    DECLARE @EnvValue4 INT, 
            @EnvValue5 INT, 
            @DayKind   INT, 
            @SDate     NCHAR(8), 
            @Cnt       INT 
    
    SELECT @EnvValue4 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 4 AND EnvSerl = 1 ),1025001)
    SELECT @EnvValue5 = ISNULL(( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = 1 AND EnvSeq = 5 AND EnvSerl = 1 ),0)
    
    SELECT @DayKind = CASE WHEN A.MinorValue = 7 THEN 0 ELSE A.MinorValue END 
      FROM _TDASMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND MinorSeq = @EnvValue4 
    
    SELECT @SDate = A.Solar
      FROM _TCOMCalendar AS A
     WHERE A.Solar BETWEEN @FromDate AND @ToDate 
       AND A.SWeek0 = @DayKind 
    
    
    CREATE TABLE #TEMP 
    (
        ColIdx      INT IDENTITY, 
        Title       NVARCHAR(100), 
        TitleSeq    INT
    ) 
    
    SELECT @Cnt = 0 
    
    WHILE( 1 = 1 ) 
    BEGIN
        INSERT INTO #TEMP (Title, TitleSeq)
        SELECT STUFF(RIGHT(Solar,4),3,0,'월 ') + '일', CONVERT(INT,Solar) 
          FROM _TCOMCalendar
         WHERE Solar = CONVERT(NCHAR(8),DATEADD(DAY,@Cnt,@SDate),112)
        
        IF @Cnt = @EnvValue5 - 1 
        BEGIN
            BREAK
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
        
    END 
    
    SELECT * FROM #TEMP
    
    
    
GO 
exec KPX_SSLWeekSalesPlanTitleQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FromDate>20140630</FromDate>
    <ToDate>20140706</ToDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025887,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021321