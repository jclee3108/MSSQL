  
IF OBJECT_ID('KPXCM_SSFCWorkReportTimeClac') IS NOT NULL   
    DROP PROC KPXCM_SSFCWorkReportTimeClac  
GO  
  
-- v2015.09.22  
  
-- 생산실적입력-시간계산 by 이재천 
CREATE PROC KPXCM_SSFCWorkReportTimeClac  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @WorkCondition1 NCHAR(8),  
            @WorkCondition2 NCHAR(8),  
            @WorkStartTime  NVARCHAR(10), 
            @WorkEndTime    NVARCHAR(10) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT  @WorkCondition1 = ISNULL( WorkCondition1, '' ),  
            @WorkCondition2 = ISNULL( WorkCondition2, '' ),  
            @WorkStartTime  = ISNULL( WorkStartTime, '' ),  
            @WorkEndTime    = ISNULL( WorkEndTime, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkCondition1 NCHAR(8),
            WorkCondition2 NCHAR(8),
            WorkStartTime  NVARCHAR(10), 
            WorkEndTime    NVARCHAR(10) 
           )   
    
    DECLARE @StartTime DATETIME, 
            @EndTime   DATETIME
    
    -- 날짜, 시간 빈값 체크 
    IF ISDATE(@WorkCondition1) = 0 OR ISDATE(@WorkCondition2) = 0 OR @WorkStartTime = '' OR @WorkEndTime = '' 
    BEGIN
        SELECT 0 AS WorkHour 
        RETURN
    END 

    
    SELECT @WorkStartTime = REPLACE(@WorkStartTime,':',''), 
           @WorkEndTime = REPLACE(@WorkEndTime,':','') 
    
    
    SELECT @StartTime = CONVERT(DATETIME,LEFT(@WorkCondition1,4) + '-' +  -- 년도 
                                         SUBSTRING(@WorkCondition1,5,2) + '-' + -- 월 
                                         SUBSTRING(@WorkCondition1,7,2) + ' ' + -- 일 
                                         LEFT(@WorkStartTime,2) + ':' + RIGHT(@WorkStartTime,2) + ':00.000') -- 시간 
                                         
    SELECT @EndTime = CONVERT(DATETIME,LEFT(@WorkCondition2,4) + '-' +  -- 년도 
                                       SUBSTRING(@WorkCondition2,5,2) + '-' + -- 월 
                                       SUBSTRING(@WorkCondition2,7,2) + ' ' + -- 일 
                                       LEFT(@WorkEndTime,2) + ':' + RIGHT(@WorkEndTime,2) + ':00.000') -- 시간 
                  
    -- (종료시간 - 시작시간) 
    SELECT DATEDIFF(Mi, @StartTime, @EndTime) AS WorkHour 
    
    RETURN  
GO 
exec KPXCM_SSFCWorkReportTimeClac @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WorkCondition1>20150901</WorkCondition1>
    <WorkCondition2>20150905</WorkCondition2>
    <WorkStartTime>0919</WorkStartTime>
    <WorkEndTime>0930</WorkEndTime>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032227,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=5987