
IF OBJECT_ID('KPX_SCMPgmUseListQuerySub') IS NOT NULL 
    DROP PROC KPX_SCMPgmUseListQuerySub
GO 

-- v2015.02.24    
    
-- 프로그램사용내역현황-조회 by 이재천     
CREATE PROC KPX_SCMPgmUseListQuerySub    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,    
            -- 조회조건     
            @WorkDateFr  NCHAR(8),   
            @WorkDateTo  NCHAR(8),   
            @EmpSeq      INT,   
            @DeptSeq     INT,   
            @UMJdSeq     INT,   
            @UMJpSeq     INT,   
            @IsManager   NCHAR(1)   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @WorkDateFr  = ISNULL( WorkDateFr, '' ),    
           @WorkDateTo  = ISNULL( WorkDateTo, '' ),    
           @EmpSeq      = ISNULL( EmpSeq    , 0 ),    
           @DeptSeq     = ISNULL( DeptSeq   , 0 ),   
           @UMJdSeq     = ISNULL( UMJdSeq   , 0 ),   
           @UMJpSeq     = ISNULL( UMJpSeq   , 0 ),   
           @IsManager   = ISNULL( IsManager , '0')   
  
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
            WorkDateFr  NCHAR(8),  
            WorkDateTo  NCHAR(8),  
            EmpSeq      INT,   
            DeptSeq     INT,   
            UMJdSeq     INT,   
            UMJpSeq     INT,   
            IsManager   NCHAR(1)   
           )      
      
    DECLARE @DateCnt INT 
    
    SELECT @DateCnt = DATEDIFF(Day, @WorkDateFr, @WorkDateTo) + 1 
    
    CREATE TABLE #Result   
    (   
        EmpName     NVARCHAR(100),   
        EmpSeq      INT,   
        DeptName    NVARCHAR(100),   
        DeptSeq     INT,   
        UMJpName    NVARCHAR(100),   
        UMJpSeq     INT,   
        UMJdName    NVARCHAR(100),   
        UMJdSeq     INT,   
        WorkDate    NCHAR(8),   
        Caption     NVARCHAR(100),   
        PgmSeq      INT,   
        Cnt         INT,   
        RunningTime INT  
    )      
    
    INSERT INTO #Result   
    (  
        EmpName, EmpSeq, DeptName, DeptSeq, UMJpName,   
        UMJpSeq, UMJdName, UMJdSeq, WorkDate, Caption,   
        PgmSeq, Cnt, RunningTime  
    )  
    SELECT C.EmpName, C.EmpSeq, C.DeptName, C.DeptSeq, E.Remark AS UMJpName,   
           C.UMJpSeq, C.UMJdName, C.UMJdSeq, CONVERT(NCHAR(8),StartTime,112) AS WorkDate, D.Caption,   
           D.PgmSeq, COUNT(1) AS Cnt, SUM(DATEDIFF(mi, A.StartTime, GETDATE())) AS RunningTime   
      FROM _TCAUserLoginInfoPgm AS A   
      LEFT OUTER JOIN _TCAUser  AS B ON ( B.CompanySeq = A.CompanySeq AND B.UserSeq = A.UserSeq )   
      LEFT OUTER JOIN KPXERP.dbo._fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = B.EmpSeq )   
      LEFT OUTER JOIN _TCAPgm   AS D ON ( D.PgmSeq = A.PgmSeq )   
      LEFT OUTER JOIN _TDAUMinor AS E ON ( E.CompanySeq = @CompanySeq AND MinorSeq = C.UMJpSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND CONVERT(NCHAR(8),StartTime,112) BETWEEN @WorkDateFr AND @WorkDateTo   
       AND ( @EmpSeq = 0 OR C.EmpSeq = @EmpSeq )   
       AND ( @DeptSeq = 0 OR C.DeptSeq = @DeptSeq )   
       AND ( @UMJpSeq = 0 OR C.UMJpSeq = @UMJpSeq )   
       AND ( @UMJdSeq = 0 OR C.UMJdSeq = @UMJdSeq )   
       AND ISNULL(C.EmpSeq,0) <> 0   
     GROUP BY C.EmpName, C.EmpSeq, C.DeptName, C.DeptSeq, E.Remark,   
              C.UMJpSeq, C.UMJdName, C.UMJdSeq, CONVERT(NCHAR(8),StartTime,112),   
              D.Caption, D.PgmSeq  
      
    UNION ALL   
      
    SELECT C.EmpName, C.EmpSeq, C.DeptName, C.DeptSeq, E.Remark AS UMJpName,    
           C.UMJpSeq, C.UMJdName, C.UMJdSeq, CONVERT(NCHAR(8),StartTime,112) AS WorkDate, D.Caption,   
           D.PgmSeq, COUNT(1) AS Cnt, SUM(DATEDIFF(mi, A.StartTime, A.EndTime)) AS RunningTime   
      FROM _TCAUserLoginInfoPgmHistory AS A   
      LEFT OUTER JOIN _TCAUser  AS B ON ( B.CompanySeq = A.CompanySeq AND B.UserSeq = A.UserSeq )   
      LEFT OUTER JOIN KPXERP.dbo._fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = B.EmpSeq )   
      LEFT OUTER JOIN _TCAPgm   AS D ON ( D.PgmSeq = A.PgmSeq )  
      LEFT OUTER JOIN _TDAUMinor AS E ON ( E.CompanySeq = @CompanySeq AND MinorSeq = C.UMJpSeq )  
     WHERE EndTime IS NOT NULL    
       AND CONVERT(NCHAR(8),StartTime,112) BETWEEN @WorkDateFr AND @WorkDateTo   
         AND ( @EmpSeq = 0 OR C.EmpSeq = @EmpSeq )   
       AND ( @DeptSeq = 0 OR C.DeptSeq = @DeptSeq )   
       AND ( @UMJpSeq = 0 OR C.UMJpSeq = @UMJpSeq )   
       AND ( @UMJdSeq = 0 OR C.UMJdSeq = @UMJdSeq )   
       AND ISNULL(C.EmpSeq,0) <> 0   
     GROUP BY C.EmpName, C.EmpSeq, C.DeptName, C.DeptSeq, E.Remark,   
           C.UMJpSeq, C.UMJdName, C.UMJdSeq, CONVERT(NCHAR(8),StartTime,112),   
           D.Caption, D.PgmSeq  
      
      
    IF @IsManager = '1'   
    BEGIN  
        DELETE A  
          FROM #Result AS A   
         WHERE NOT EXISTS (SELECT 1 FROM KPXERP.dbo.KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND A.EmpSeq = EnvValue AND EnvSeq = 29)  
    END   
      
     SELECT EmpName, EmpSeq, DeptName, DeptSeq, UMJpName, 
            UMJpSeq, UMJdName, UMJdSeq, WorkDate, SUM(Cnt) AS Cnt, 
            SUM(RunningTime) AS RunningTime
       FROM #Result 
      GROUP BY EmpName, EmpSeq, DeptName, DeptSeq, UMJpName, 
               UMJpSeq, UMJdName, UMJdSeq, WorkDate
    
    --SELECT '' AS Name, EmpName, EmpSeq, DeptName, DeptSeq, UMJpName,   
    --       UMJpSeq, UMJdName, UMJdSeq, WorkDate, SUM(Cnt) AS Cnt, 
    --       SUM(RunningTime) AS RunningTime, 
    --       CASE WHEN ISNULL(@DateCnt,0) <= 0 THEN 0 ELSE SUM(RunningTime) / ISNULL(@DateCnt,0) END AS AvgRunningTime, 
    --       1 AS Sort 
    --  FROM #Result   
    -- GROUP BY EmpName, EmpSeq, DeptName, DeptSeq, UMJpName,   
    --          UMJpSeq, UMJdName, UMJdSeq, WorkDate 
    
    --UNION ALL 
    
    --SELECT '이름 계' AS Name, EmpName, EmpSeq, DeptName, DeptSeq, UMJpName,   
    --       UMJpSeq, UMJdName, UMJdSeq, '', SUM(Cnt) AS Cnt, 
    --       SUM(RunningTime) AS RunningTime, 
    --       CASE WHEN ISNULL(@DateCnt,0) <= 0 THEN 0 ELSE SUM(RunningTime) / ISNULL(@DateCnt,0) END, 
    --       2 AS Sort 
    --  FROM #Result   
    -- GROUP BY EmpName, EmpSeq, DeptName, DeptSeq, UMJpName,   
    --          UMJpSeq, UMJdName, UMJdSeq 
    
    --UNION ALL 
              
    --SELECT '부서 계', '', 9999999998, DeptName, DeptSeq, '',   
    --       0, '', 0, '', SUM(Cnt) AS Cnt, 
    --       SUM(RunningTime) AS RunningTime, 
    --       CASE WHEN ISNULL(@DateCnt,0) <= 0 THEN 0 ELSE SUM(RunningTime) / ISNULL(@DateCnt,0) END, 
    --       3 AS Sort 
    --  FROM #Result   
    -- GROUP BY DeptName, DeptSeq
    
    --UNION ALL 
              
    --SELECT '총 계', '', 9999999999, '', 9999999999, '',   
    --       0, '', 0, '', SUM(Cnt) AS Cnt, 
    --       SUM(RunningTime) AS RunningTime, 
    --       CASE WHEN ISNULL(@DateCnt,0) <= 0 THEN 0 ELSE SUM(RunningTime) / ISNULL(@DateCnt,0) END, 
    --       4 AS Sort 
    --  FROM #Result   
    -- ORDER BY DeptSeq, EmpSeq, Sort 
    
    RETURN    
      
      
      
  
  GO 
  exec KPX_SCMPgmUseListQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WorkDateFr>20150201</WorkDateFr>
    <WorkDateTo>20150227</WorkDateTo>
    <EmpSeq />
    <DeptSeq />
    <UMJdSeq />
    <UMJpSeq />
    <IsManager>0</IsManager>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1028098,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1023521