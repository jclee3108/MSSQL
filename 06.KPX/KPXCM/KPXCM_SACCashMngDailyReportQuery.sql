  
IF OBJECT_ID('KPXCM_SACCashMngDailyReportQuery') IS NOT NULL   
    DROP PROC KPXCM_SACCashMngDailyReportQuery  
GO  
  
-- v2016.06.08  
  
-- 자금실적조회(일별)-조회 by 이재천   
CREATE PROC KPXCM_SACCashMngDailyReportQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @AccUnit    INT, 
            @StdYM      NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @AccUnit = ISNULL( AccUnit, 0 ),  
           @StdYM   = ISNULL( StdYM, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AccUnit    INT, 
            StdYM      NCHAR(6)     
           )    
    
    -- 기본 데이터 
    CREATE TABLE #BaseData 
    (
        UMKindSeq       INT, 
        StdDate         NCHAR(8), 
        Amt             DECIMAL(19,5), 
        InOutKind       INT -- 1 수입, 2 지출 
    )
    -- 수입 
    INSERT INTO #BaseData ( UMKindSeq, StdDate, Amt, InOutKind ) 
    SELECT A.MinorSeq, B.StdDate, SUM(ISNULL(B.DomAmt,0)), 1 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN KPX_TACCashInMng  AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.UMCashInKindSeq = A.MinorSeq 
                                              AND B.AccUnit = @AccUnit 
                                              AND LEFT(B.StdDate,6) = @StdYM 
                                              AND ISNULL(B.UMCashInKindSeq,0) <> 0  
                                                ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND A.MajorSeq = 1012906 
     GROUP BY A.MinorSeq, B.StdDate
     
    -- 지출 
    INSERT INTO #BaseData ( UMKindSeq, StdDate, Amt, InOutKind ) 
    SELECT A.MinorSeq, B.StdDate, SUM(ISNULL(B.DomAmt,0)), 2  
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN KPX_TACCashOutMng AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.UMCashOutKindSeq = A.MinorSeq 
                                              AND B.AccUnit = @AccUnit 
                                              AND LEFT(B.StdDate,6) = @StdYM 
                                              AND ISNULL(B.UMCashOutKindSeq,0) <> 0  
                                                ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND A.MajorSeq = 1012907 
     GROUP BY A.MinorSeq, B.StdDate
    
    -- Title 
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT
    )
    
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT CONVERT(NVARCHAR(10),CONVERT(INT,SUBSTRING(Solar,5,2))) + '/' + CONVERT(NVARCHAR(10),CONVERT(INT,RIGHT(Solar,2))) AS Title, 
           Solar AS TitleSeq 
      FROM _TCOMCalendar 
     WHERE LEFT(Solar,6) = @StdYM
     ORDER BY Solar 
    
    SELECT * FROM #Title 
    
    -- Fix 
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        KindSeq     INT, 
        KindName    NVARCHAR(100), 
        KindSeq2    INT, 
        KindName2   NVARCHAR(100), 
        SumAmt      DECIMAL(19,5), 
        MinorSort   INT 
    )
    
    INSERT INTO #FixCol ( KindSeq, KindName, KindSeq2, KindName2, SumAmt, MinorSort ) 
    SELECT A.InOutKind AS KindSeq, 
           CASE WHEN A.InOutKind = 1 THEN '수입' ELSE '지출' END, 
           A.UMKindSeq AS KindSeq2, 
           MAX(B.MinorName), 
           SUM(A.Amt), 
           MAX(B.MinorSort)
      FROM #BaseData                AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMKindSeq ) 
     GROUP BY A.InOutKind, A.UMKindSeq 
    
    UNION ALL 
    
    SELECT A.InOutKind, 
           CASE WHEN A.InOutKind = 1 THEN '수입' ELSE '지출' END, 
           CASE WHEN A.InOutKind = 1 THEN 1012906998 ELSE 1012907998 END, 
           '계', 
           SUM(A.Amt), 
           98
      FROM #BaseData                AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMKindSeq ) 
     GROUP BY A.InOutKind
    
    UNION ALL 
    
    SELECT 3, 
           '', 
           1012907999, 
           '과 부 족', 
           SUM(CASE WHEN A.InOutKind = 2 THEN A.Amt * (-1) ELSE A.Amt END), 
           99
      FROM #BaseData                AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMKindSeq ) 
     ORDER BY KindSeq, KindSeq2 
    
    SELECT * FROM #FixCol 
    
    -- Value 
    CREATE TABLE #Value 
    (
        StdDate     NCHAR(8), 
        Amt         DECIMAL(19,5), 
        KindSeq     INT, 
        KindSeq2    INT
    )
    
    
    INSERT INTO #Value ( StdDate, Amt, KindSeq, KindSeq2 ) 
    SELECT StdDate, SUM(Amt), InOutKind, UMKindSeq
      FROM #BaseData 
     GROUP BY StdDate, InOutKind, UMKindSeq
    
    UNION ALL 
    
    SELECT StdDate, 
           SUM(Amt), 
           InOutKind, 
           CASE WHEN InOutKind = 1 THEN 1012906998 ELSE 1012907998 END
           
      FROM #BaseData 
     GROUP BY StdDate, InOutKind 
     
    UNION ALL 
    
    SELECT StdDate, 
           SUM(CASE WHEN InOutKind = 2 THEN Amt * (-1) ELSE Amt END), 
           3, 
           1012907999
      FROM #BaseData 
     GROUP BY StdDate
    
    SELECT B.RowIdx, A.ColIdx, C.Amt AS Value
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.StdDate ) 
      JOIN #FixCol AS B ON ( B.KindSeq2 = C.KindSeq2 AND B.KindSeq = C.KindSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
    GO
exec KPXCM_SACCashMngDailyReportQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccUnit>1</AccUnit>
    <StdYM>201605</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036947,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030279