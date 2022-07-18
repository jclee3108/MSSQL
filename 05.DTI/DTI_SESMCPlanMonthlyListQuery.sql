  
IF OBJECT_ID('DTI_SESMCPlanMonthlyListQuery') IS NOT NULL   
    DROP PROC DTI_SESMCPlanMonthlyListQuery  
GO  
  
-- v2014.03.14  
  
-- 계획조회(사업팀_월별)_DTI(조회) by이재천   
CREATE PROC DTI_SESMCPlanMonthlyListQuery  
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
            @AmtUnit    DECIMAL(19,5),   
            @CCtrSeq    INT,   
            @PlanYear   NCHAR(4),   
            @IsAdj      NCHAR(1),   
            @CostYM     NCHAR(6),   
            @SMClass    INT, 
            @Cnt        INT   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @AmtUnit     = ISNULL(AmtUnit,0)  ,  
           @CCtrSeq     = ISNULL(CCtrSeq,0)  ,  
           @PlanYear    = ISNULL(PlanYear,'')   ,  
           @IsAdj       = ISNULL(IsAdj,'0'), 
           @SMClass     = ISNULL(SMClass, 0)
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AmtUnit    DECIMAL(19,5),
            CCtrSeq    INT,   
            PlanYear   NCHAR(4),   
            IsAdj      NCHAR(1),   
            CostYM     NCHAR(6),   
            SMClass    INT, 
            Cnt        INT   
           )    
    -- 금액단위가 0일 때, 1로 Update  
    IF @AmtUnit = 0 SELECT @AmtUnit = 1  
    
    -- 해당 원가년도의 CostKeySeq 가져오기  
    CREATE TABLE #CostKey   
    (   
        CostKeySeq  INT,   
        CostYM      NCHAR(6)   
    )  
      
    INSERT INTO #CostKey ( CostKeySeq, CostYM )  
    SELECT CostKeySeq, CostYM  
      FROM _TESMDCostKey  
     WHERE CompanySeq     = @CompanySeq  
        AND SMCostMng      = 5512002 
    
    -- 활동센터 가져오기 (원가년월 별로 조회조건 활동센터의 하위 활동센터를 모두 가져온다.)  
    CREATE TABLE #CCtr   
    (  
        CostYM      INT,  
        CCtrSeq     INT   
    )  
      
    SELECT @Cnt = 1  
      
    WHILE ( @Cnt < 13 )  
    BEGIN  
        SELECT @CostYM = @PlanYear + RIGHT('00'+CAST(@Cnt AS NVARCHAR),2)  
          
        INSERT INTO #CCtr ( CostYM, CCtrSeq )  
        SELECT @CostYM, CCtrSeq  
          FROM DTI_fnOrgCCtr ( @CompanySeq, @CostYM, @CCtrSeq )   
         WHERE LEN(OrgCd) <= 3 
    
        SELECT @Cnt = @Cnt + 1  
    END 
    
    -- 데이터 담기  
    CREATE TABLE #TEMP  
    (  
        Serl        INT, --NCHAR(6),  
        CostYM      NCHAR(6),   
        SMGPItem    INT,  
        AccSeq      INT,   
        Amt         DECIMAL(19,5),   
        AccName     NVARCHAR(100),   
        CCtrSeq     INT,   
        AccSort1    INT,        -- 비용 손익요약항목 정렬순서    
        AccSort2    INT,        -- 비용 계정과목 정렬순서    
        Kind        INT   
    )  
    INSERT INTO #TEMP (   
                        Serl, SMGPItem, AccSeq, AccName, Amt,   
                        CCtrSeq, AccSort1, AccSort2, Kind, CostYM--, BGColor  
                      )  
    SELECT CASE WHEN B.CostYM = @PlanYear + '01' THEN 1  
                WHEN B.CostYM = @PlanYear + '02' THEN 2  
                WHEN B.CostYM = @PlanYear + '03' THEN 3  
                WHEN B.CostYM = @PlanYear + '04' THEN 5  
                WHEN B.CostYM = @PlanYear + '05' THEN 6  
                WHEN B.CostYM = @PlanYear + '06' THEN 7  
                WHEN B.CostYM = @PlanYear + '07' THEN 10 
                WHEN B.CostYM = @PlanYear + '08' THEN 11 
                WHEN B.CostYM = @PlanYear + '09' THEN 12 
                WHEN B.CostYM = @PlanYear + '10' THEN 14 
                WHEN B.CostYM = @PlanYear + '11' THEN 15 
                WHEN B.CostYM = @PlanYear + '12' THEN 16 END, 
           A.SMGPItem, A.AccSeq, MAX(F.AccName),   
           SUM(ISNULL(A.Value,0))/@AmtUnit,   
           A.CCtrSeq, MIN(I.Sort), MIN(I.Sort), 1,   
           MAX(B.CostYM)  
      FROM DTI_TESMCProfitResult    AS A   
      JOIN #CostKey                 AS B ON ( B.CostKeyseq = A.CostKeySeq )  
      JOIN #CCtr                    AS C ON ( C.CostYM = B.CostYM AND C.CCtrSeq = A.CCtrSeq )   
      JOIN _TDASMinor               AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMGPItem )   
      OUTER APPLY (SELECT MinorSeq AS SMGPItem,    
                            MAX(CASE WHEN Serl = 1000002 THEN ValueText END) AS Caption, -- Caption    
                          MAX(CASE WHEN Serl = 1000004 THEN ValueText END) AS BGColor, -- 배경색    
                          MAX(CASE WHEN Serl = 1000006 THEN ValueText END) AS IsSum    -- '목'으로 보기    
                     FROM _TDASMinorValue     
                    WHERE CompanySeq = @CompanySeq    
                      AND MinorSeq   = A.SMGPItem    
                    GROUP BY MinorSeq  
                  ) AS E   
      LEFT OUTER JOIN _TDAAccount     AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.AccSeq = A.AccSeq )   
      LEFT OUTER JOIN DTI_TPNCostItem AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.STDYear = @PlanYear AND I.AccSeq = A.AccSeq AND I.SMGPItem = A.SMGPItem )   
     WHERE A.CompanySeq = @CompanySeq 
     GROUP BY CASE WHEN B.CostYM = @PlanYear + '01' THEN 1 
                   WHEN B.CostYM = @PlanYear + '02' THEN 2 
                   WHEN B.CostYM = @PlanYear + '03' THEN 3 
                   WHEN B.CostYM = @PlanYear + '04' THEN 5 
                   WHEN B.CostYM = @PlanYear + '05' THEN 6 
                   WHEN B.CostYM = @PlanYear + '06' THEN 7 
                   WHEN B.CostYM = @PlanYear + '07' THEN 10 
                   WHEN B.CostYM = @PlanYear + '08' THEN 11 
                   WHEN B.CostYM = @PlanYear + '09' THEN 12 
                   WHEN B.CostYM = @PlanYear + '10' THEN 14 
                   WHEN B.CostYM = @PlanYear + '11' THEN 15 
                   WHEN B.CostYM = @PlanYear + '12' THEN 16 END, 
              A.SMGPItem, A.AccSeq, A.CCtrSeq--, E.BGColor  
     ORDER BY MIN(I.Sort) 
    
    -- 직접/공통/지원 구분에 따라 계정과목 집계   
    INSERT INTO #TEMP (Serl, SMGPItem, CCtrSeq, AccSeq, AccName,   
                       Amt, AccSort1, Kind, CostYM) 
    SELECT A.Serl, A.SMGPItem, A.CCtrSeq, -1, MAX(B.CostName2),  
           SUM(A.Amt)/@AmtUnit, MIN(B.Sort), 2, MAX(A.CostYM) 
      FROM #TEMP AS A      
      JOIN DTI_TPNCostItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq      
                                            AND B.STDYear    = @PlanYear  
                                            AND A.AccSeq     = B.AccSeq      
                                            AND A.SMGPItem   = B.SMGPItem   
     WHERE A.SMGPItem IN (1000398016, 1000398017, 1000398018)      
       --AND ISNULL(A.IsAdj, '0') = '0'      
     GROUP BY A.Serl, A.SMGPItem, A.CCtrSeq, B.CostName2 
      
    DELETE FROM #TEMP WHERE AccSeq > 0  
    
    CREATE TABLE #TMP_Result   
    (  
        Serl        INT, 
        SMGPItem    INT,  
        AccSeq      INT,   
        AccName     NVARCHAR(100),   
        Amt         DECIMAL(19,5),   
        CCtrSeq     INT,   
        AccSort1    INT,        -- 비용 손익요약항목 정렬순서    
        AccSort2    INT        -- 비용 계정과목 정렬순서    
    ) 
    
    IF @SMClass = 1000413001 
    BEGIN 
        INSERT INTO #TMP_Result (Serl, SMGPItem, AccSeq, Amt, CCtrSeq, AccSort1, AccSort2, AccName)   
        SELECT Serl,   
               SMGPItem,   
               AccSeq,   
               SUM(Amt),   
               CCtrSeq,   
               MIN(AccSort1),   
               MIN(AccSort2),   
               AccName  
           FROM #TEMP   
         GROUP BY Serl, SMGPItem, AccSeq, CCtrSeq, AccName 
    END
    
    INSERT INTO #TMP_Result (Serl, SMGPItem, AccSeq, Amt, CCtrSeq, AccSort1, AccSort2, AccName)   
    SELECT CASE WHEN A.CostYM BETWEEN @PlanYear + '01' AND @PlanYear + '03' THEN 4
                WHEN A.CostYM BETWEEN @PlanYear + '04' AND @PlanYear + '06' THEN 8
                WHEN A.CostYM BETWEEN @PlanYear + '07' AND @PlanYear + '09' THEN 13
                WHEN A.CostYM BETWEEN @PlanYear + '10' AND @PlanYear + '12' THEN 17 END, 
           A.SMGPItem,   
           A.AccSeq,   
           SUM(A.Amt),   
           A.CCtrSeq,   
           MIN(A.AccSort1),   
           MIN(A.AccSort2),   
           A.AccName  
      FROM #TEMP AS A   
     GROUP BY CASE WHEN A.CostYM BETWEEN @PlanYear + '01' AND @PlanYear + '03' THEN 4
                   WHEN A.CostYM BETWEEN @PlanYear + '04' AND @PlanYear + '06' THEN 8
                   WHEN A.CostYM BETWEEN @PlanYear + '07' AND @PlanYear + '09' THEN 13
                   WHEN A.CostYM BETWEEN @PlanYear + '10' AND @PlanYear + '12' THEN 17 END, 
              A.SMGPItem, A.AccSeq, A.CCtrSeq, A.AccName  
    UNION ALL 
    SELECT CASE WHEN A.CostYM BETWEEN @PlanYear + '01' AND @PlanYear + '06' THEN 9
                WHEN A.CostYM BETWEEN @PlanYear + '07' AND @PlanYear + '12' THEN 18 END,  
           A.SMGPItem,   
           A.AccSeq,   
           SUM(A.Amt),   
           A.CCtrSeq,   
           MIN(A.AccSort1),   
           MIN(A.AccSort2),   
           A.AccName  
      FROM #TEMP AS A   
     GROUP BY CASE WHEN A.CostYM BETWEEN @PlanYear + '01' AND @PlanYear + '06' THEN 9
                   WHEN A.CostYM BETWEEN @PlanYear + '07' AND @PlanYear + '12' THEN 18 END,  
              A.SMGPItem, A.AccSeq, A.CCtrSeq, A.AccName 
    UNION ALL  
    SELECT 19,  
           A.SMGPItem,   
           A.AccSeq,   
           SUM(A.Amt),   
           A.CCtrSeq,   
           MIN(A.AccSort1),   
           MIN(A.AccSort2),   
           A.AccName   
      FROM #TEMP AS A   
     GROUP BY LEFT(A.CostYM,4), A.SMGPItem, A.AccSeq, A.CCtrSeq, A.AccName  
    
    -- 타이틀  
    CREATE TABLE #Title   
    (  
        ColIdx      INT IDENTITY(0,1),   
        Title       NVARCHAR(200),   
        TitleSeq    INT 
    )  
    
    CREATE TABLE #Title_Sub
    (
        Title       NVARCHAR(100), 
        TitleSeq    INT
    )
    
    IF @SMClass = 1000413001 
    BEGIN 
        INSERT INTO #Title_Sub (Title, TitleSeq)
        SELECT '1월', 1 
        UNION ALL 
        SELECT '2월', 2 
        UNION ALL 
        SELECT '3월', 3 
        UNION ALL 
        SELECT '4월', 5 
        UNION ALL 
        SELECT '5월', 6 
        UNION ALL 
        SELECT '6월', 7 
        UNION ALL 
        SELECT '7월', 10 
        UNION ALL 
        SELECT '8월', 11 
        UNION ALL 
        SELECT '9월', 12 
        UNION ALL 
        SELECT '10월', 14  
        UNION ALL 
        SELECT '11월', 15 
        UNION ALL 
        SELECT '12월', 16 
    END
    
    INSERT INTO #Title_Sub (Title, TitleSeq)
    SELECT '1Q', 4 
    UNION ALL 
    SELECT '2Q', 8 
    UNION ALL 
    SELECT '3Q', 13 
    UNION ALL 
    SELECT '4Q', 17 
    UNION ALL 
    SELECT '1H', 9 
    UNION ALL 
    SELECT '2H', 18 
    UNION ALL 
    SELECT '합계', 19 
    
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT DISTINCT A.Title, A.TitleSeq 
      FROM #Title_Sub AS A
     ORDER BY A.TitleSeq
    
    SELECT * FROM #Title
    
    -- 고정부
    CREATE TABLE #FixCol   
    (  
        RowIdx          INT IDENTITY(0,1),   
        SMGPItem        INT,   
        SMGPItemName    NVARCHAR(200),   
        Sort            INT,   
        AccSeq          INT,   
        BGColor         INT,   
        AccName         NVARCHAR(100),   
        Sort1           INT,   
        Sort2           INT   
    )  
    INSERT INTO #FixCol ( SMGPItem, SMGPItemName, Sort, AccSeq, BGColor, AccName, Sort1, Sort2 )   
    SELECT DISTINCT SMGPItem,   
           CASE WHEN A.AccSeq <> 0 THEN A.AccName ELSE C.ValueText END,   
           B.MinorSort,   
           A.AccSeq,   
           D.ValueText,   
           A.AccName,   
           ISNULL(A.AccSort1,0),   
           A.AccSort2  
      FROM #TMP_Result AS A   
      LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMGPItem )   
      LEFT OUTER JOIN _TDASMinorValue AS C ON C.CompanySeq = @CompanySeq    
                                          AND B.MinorSeq   = C.MinorSeq    
                                          AND C.Serl       = 1000002 -- Caption    
      LEFT OUTER JOIN _TDASMinorValue AS D ON D.CompanySeq = @CompanySeq    
                                          AND B.MinorSeq   = D.MinorSeq    
                                          AND D.Serl       = 1000004 -- 배경색    
                                          AND ISNULL(A.AccSeq, 0) = 0    
     ORDER BY B.MinorSort, A.AccSeq, ISNULL(A.AccSort1,0)   
      
    SELECT RowIdx,   
           CASE WHEN AccSeq < 0 THEN '  ' + SMGPItemName     
                WHEN AccSeq > 0 THEN '     ' + SMGPItemName    
                                ELSE SMGPItemName END AS SMGPItemName,    
           SMGPItem,   
           AccSeq,   
           Sort,   
           BGColor  
      FROM #FixCol   
     ORDER BY RowIdx 
    
    -- 가변   
    CREATE TABLE #Value   
    (  
        Amt             DECIMAL(19,5),   
        SMGPItem        INT,   
        TitleSeq        INT,   
        AccSeq          INT,   
        AccName         NVARCHAR(100)   
    )  
    
    INSERT INTO #Value (SMGPItem, TitleSeq, Amt, AccSeq, AccName)  
    SELECT A.SMGPItem, A.Serl, A.Amt, A.AccSeq, A.AccName  
      FROM #TMP_Result AS A   
      
    SELECT B.RowIdx, A.ColIdx, C.Amt AS Results   
      FROM #Value AS C   
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 
      JOIN #FixCol AS B ON ( ISNULL(B.AccName, '') = ISNULL(C.AccName, '') AND B.SMGPItem = C.SMGPItem )   
     ORDER BY A.ColIdx, B.RowIdx   
    
GO
exec DTI_SESMCPlanMonthlyListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanYear>2013</PlanYear>
    <CCtrSeq>66</CCtrSeq>
    <AmtUnit>1</AmtUnit>
    <SMClass>1000413001</SMClass>
    <IsAdj>0</IsAdj>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021679,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018227