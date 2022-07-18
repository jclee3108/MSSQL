  
IF OBJECT_ID('KPXCM_SEQMonthRegInspectPlanQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQMonthRegInspectPlanQuery  
GO  
  
-- v2016.04.21  
  
-- 월별정기검사계획조회-조회 by 이재천   
CREATE PROC KPXCM_SEQMonthRegInspectPlanQuery  
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
            @PlanYear   NCHAR(4), 
            @UMQCSeq    INT 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYear    = ISNULL( PlanYear, '' ),  
           @UMQCSeq     = ISNULL( UMQCSeq, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PlanYear   NCHAR(4),
            UMQCSeq    INT       
           )    
    
    -- 기본데이터 
    SELECT CASE WHEN ISNULL(J.ReplaceDate,'') = '' THEN CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) 
                ELSE J.ReplaceDate 
                END  AS QCPlanDate,
           A.ToolSeq, 
           H.ToolNo, 
           A.UMQCSeq, 
           C.MinorName AS UMQCName
      INTO #BaseData 
      FROM KPXCM_TEQRegInspect      AS A    
      LEFT OUTER JOIN _TDAUMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMQCSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCCycle )   
      LEFT OUTER JOIN _TPDTool      AS H ON ( H.CompanySeq = @CompanySeq AND H.ToolSeq = A.ToolSeq )   
      OUTER APPLY (  
                    SELECT MAX(QCResultDate) AS QCDate   
                      FROM KPXCM_TEQRegInspectRst AS Z   
                     WHERE Z.CompanySeq = @CompanySeq   
                       AND Z.RegInspectSeq = A.RegInspectSeq   
                     GROUP BY Z.RegInspectSeq  
                  ) K   
      LEFT OUTER JOIN KPXCM_TEQRegInspectChg AS J ON ( J.CompanySeq = @CompanySeq 
                                                   AND J.RegInspectSeq = A.RegInspectSeq 
                                                   AND J.QCPlanDate = CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) 
                                                     )   
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @UMQCSeq = 0 OR A.UMQCSeq = @UMQCSeq ) 
       AND LEFT(CASE WHEN ISNULL(J.ReplaceDate,'') = '' THEN CONVERT(NCHAR(8),DATEADD(DAY,CONVERT(INT,F.Remark),ISNULL(K.QCDate,A.LastQCDate)),112) 
                     ELSE J.ReplaceDate 
                     END,4) = @PlanYear 
    
    -- Title 
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY(0, 1), 
        TitleName   NVARCHAR(100), 
        TitleSeq    INT, 
        TitleName2  NVARCHAR(100), 
        TitleSeq2   INT
    )
    INSERT INTO #Title ( TitleName, TitleSeq, TitleName2, TitleSeq2 ) 
    SELECT A.TitleName, A.TitleSeq, B.TitleName2, B.TitleSeq2
      FROM (SELECT '만기일자' AS TitleName, 100 AS TitleSeq) AS A 
      JOIN (
            SELECT '1월' AS TitleName2, @PlanYear + '01' AS TitleSeq2 
            UNION ALL 
            SELECT '2월' AS TitleName2, @PlanYear + '02' AS TitleSeq2 
            UNION ALL 
            SELECT '3월' AS TitleName2, @PlanYear + '03' AS TitleSeq2 
            UNION ALL 
            SELECT '4월' AS TitleName2, @PlanYear + '04' AS TitleSeq2 
            UNION ALL 
            SELECT '5월' AS TitleName2, @PlanYear + '05' AS TitleSeq2 
            UNION ALL 
            SELECT '6월' AS TitleName2, @PlanYear + '06' AS TitleSeq2 
            UNION ALL 
            SELECT '7월' AS TitleName2, @PlanYear + '07' AS TitleSeq2 
            UNION ALL 
            SELECT '8월' AS TitleName2, @PlanYear + '08' AS TitleSeq2 
            UNION ALL 
            SELECT '9월' AS TitleName2, @PlanYear + '09' AS TitleSeq2 
            UNION ALL 
            SELECT '10월' AS TitleName2, @PlanYear + '10' AS TitleSeq2 
            UNION ALL 
            SELECT '11월' AS TitleName2, @PlanYear + '11' AS TitleSeq2 
            UNION ALL 
            SELECT '12월' AS TitleName2, @PlanYear + '12' AS TitleSeq2 
           ) AS B ON ( 1 = 1 ) 
    
    SELECT * FROM #Title 
    
    -- Fix 
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0, 1), 
        UMQCName    NVARCHAR(100), 
        UMQCSeq     INT
    )
    
    -- 검사명중 가장많은 Count 구하기 
    SELECT A.UMQCSeq, MAX(A.Cnt) AS Cnt, IDENTITY(INT,1,1) AS IDX_NO
      INTO #MaxCnt 
      FROM ( 
            SELECT COUNT(1) AS Cnt, UMQCSeq, LEFT(QCPlanDate,6) AS QCPalnDateYM
              FROM #BaseData 
             GROUP BY UMQCSeq, LEFT(QCPlanDate,6) 
           ) AS A 
     GROUP BY UMQCSeq 
    
    DECLARE @Cnt            INT, 
            @WhileUMQCSeq   INT, 
            @MaxCnt         INT 
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) -- 검사설비가 가장 많은 기준으로 Fix 담기 
    BEGIN
        
        SELECT @WhileUMQCSeq = UMQCSeq, 
               @MaxCnt = Cnt 
          FROM #MaxCnt 
         WHERE IDX_NO = @Cnt 
        
        SELECT @MaxCnt = ISNULL(@MaxCnt,0)
        
        SET ROWCOUNT @MaxCnt
        
        INSERT INTO #FixCol ( UMQCName, UMQCSeq ) 
        SELECT UMQCName, UMQCSeq 
          FROM #BaseData 
         WHERE UMQCSeq = @WhileUMQCSeq
    
        SET ROWCOUNT 0 
        
        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #MaxCnt) ,0) OR NOT EXISTS (SELECT 1 FROM #MaxCnt) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
        
    END 
    
    SELECT * FROM #FixCol 
    
    -- Value 
    CREATE TABLE #Value 
    (
        IDX_NO      INT, 
        ToolNo      NVARCHAR(100), 
        QCPlanYM    NCHAR(6), 
        UMQCSeq     INT 
    ) 
    INSERT INTO #Value ( IDX_NO, ToolNo, QCPlanYM, UMQCSeq ) 
    SELECT ROW_NUMBER() OVER ( PARTITION BY A.UMQCSeq,LEFT(A.QCPlanDate,6) ORDER BY A.UMQCSeq, LEFT(A.QCPlanDate,6) ) + B.MinRowIdx, 
           A.ToolNo, LEFT(A.QCPlanDate,6), A.UMQCSeq  
      FROM #BaseData AS A 
      JOIN (
            SELECT UMQCSeq, MIN(RowIdx) - 1 AS MinRowIdx
              FROM #FixCol 
             GROUP BY UMQCSeq 
           ) AS B ON ( B.UMQCSeq = A.UMQCSeq ) 
     ORDER BY A.UMQCSeq, A.ToolNo
    
    -- 최종조회 
    SELECT B.RowIdx, A.ColIdx, C.ToolNo AS Value
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq2 = QCPlanYM ) 
      JOIN #FixCol AS B ON ( B.UMQCSeq = C.UMQCSeq AND B.RowIdx = C.IDX_NO ) 
     ORDER BY A.ColIdx, B.RowIdx

    
    RETURN  
GO 

EXEC KPXCM_SEQMonthRegInspectPlanQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYear>2016</PlanYear>
    <UMQCSeq />
    <UMQCName />
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1036603, @WorkingTag = N'', @CompanySeq = 2, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1029997
