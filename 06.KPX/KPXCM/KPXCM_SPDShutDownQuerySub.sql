  
IF OBJECT_ID('KPXCM_SPDShutDownQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDShutDownQuerySub  
GO  
  
-- v2016.04.22 
  
-- SHUT-DOWN일정등록(우레탄)-Item조회 by 이재천   
CREATE PROC KPXCM_SPDShutDownQuerySub  
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
            @SrtDate    NCHAR(8), 
            @SrtTime    NVARCHAR(5), 
            @EndDate    NCHAR(8), 
            @EndTime    NVARCHAR(5)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SrtDate    = ISNULL( SrtDate, '' ),  
           @SrtTime    = ISNULL( SrtTime, '' ),  
           @EndDate    = ISNULL( EndDate, '' ),  
           @EndTime    = ISNULL( EndTime, '' )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            SrtDate    NCHAR(8), 
            SrtTime    NVARCHAR(5),       
            EndDate    NCHAR(8),       
            EndTime    NVARCHAR(5)      
           ) 
    
    CREATE TABLE #Result 
    (
        SrtDateTime     NCHAR(12), 
        EndDateTime     NCHAR(12), 
        ShiftTeamSeq    INT, 
        ShiftTeamName   NVARCHAR(100)
    )
    
    DECLARE @SrtDateTime NCHAR(12), 
            @EndDateTime NCHAR(12) 
    
    SELECT @SrtDateTime = @SrtDate + REPLACE(@SrtTime,':',''), 
           @EndDateTime = @EndDate + REPLACE(@EndTime,':','') 
    
    IF @SrtDate = '' OR @SrtTime = '' OR @EndDate = '' OR @EndTime = '' 
    BEGIN
    
        SELECT @SrtDateTime = '201601010000'
        SELECT @EndDateTime = '201601010000'
    END 
    
    WHILE ( 1 = 1 ) 
    BEGIN
        
        INSERT INTO #Result ( SrtDateTime, EndDateTime, ShiftTeamName, ShiftTeamSeq ) 
        SELECT CASE WHEN SMInType = 3109002 THEN LEFT(@SrtDateTime,8) 
                    WHEN SMInType = 3109003 THEN CONVERT(NCHAR(8),DATEADD(DAY,1,LEFT(@SrtDateTime,8)),112) 
                    END + InTime AS SrtDateTime,
               
               CASE WHEN SMOutType = 3109002 THEN LEFT(@SrtDateTime,8) 
                    WHEN SMOutType = 3109003 THEN CONVERT(NCHAR(8),DATEADD(DAY,1,LEFT(@SrtDateTime,8)),112) 
                    END + OutTime AS EndDateTime, 
               ShiftTeamName, ShiftTeamSeq
          FROM _TPRWkShiftTeam  AS A 
         WHERE A.CompanySeq = @CompanySeq  
           AND ShiftTeamSeq IN ( 1, 2, 3 ) -- KPX케미칼 
           --AND ShiftTeamSeq IN ( 23, 24, 25 ) -- SITE 개발서버 

        
        SELECT @SrtDateTime = CONVERT(NCHAR(8),DATEADD(DAY,1,LEFT(@SrtDateTime,8)),112) + RIGHT(@SrtDateTime,4) -- 1일씩 더해서 당일,익일 처리 
        
        IF @SrtDateTime >= @EndDateTime  -- 시작일을 1일 더했을 때 종료일보다 크면 종료 
        BEGIN
            BREAK 
        END 
    
    END 
    
    -- 최종조회 
    SELECT LEFT(SrtDateTime,8) AS WorkDate, 
           STUFF(RIGHT(SrtDateTime,4),3,0,':') AS WorkTime, 
           ShiftTeamName AS WorkTeam 
      FROM #Result 
     WHERE SrtDateTime < @EndDateTime  

      
    RETURN  
go

EXEC KPXCM_SPDShutDownQuerySub @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <SrtDate>20160401</SrtDate>
    <SrtTime>07:00</SrtTime>
    <EndDate>20160402</EndDate>
    <EndTime>23:00</EndTime>
    <EndTimeSeq>1012820003</EndTimeSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1036643, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1030021
