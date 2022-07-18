
IF OBJECT_ID('DTI_SESMCPlanDepartListQuery') IS NOT NULL 
    DROP PROC DTI_SESMCPlanDepartListQuery
GO 

-- v2014.03.11 

-- 계획조회(부문)_DTI(조회) by 이재천 
CREATE PROC DTI_SESMCPlanDepartListQuery  
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
            @CostYear   NCHAR(4), 
            @IsAdj      NCHAR(1), 
            @CostYM     NCHAR(6), 
            @Cnt        INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @AmtUnit     = AmtUnit  ,
           @CCtrSeq     = CCtrSeq  ,
           @CostYear    = CostYear   ,
           @IsAdj       = IsAdj    
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            AmtUnit     DECIMAL(19,5), 
            CCtrSeq     INT , 
            CostYear    NCHAR(4), 
            IsAdj       NCHAR(1) 
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
        AND LEFT(CostYM,4) = @CostYear 
    --select * from _TDASMinor where companyseq =1 and majorseq = 5512--001
    --select @cctrSeq  
    --select * from _TDACCtr where CompanySeq = 1 and CCtrSeq = 70
    
    -- 활동센터 가져오기 (원가년월 별로 조회조건 활동센터의 하위 활동센터를 모두 가져온다.)
    CREATE TABLE #CCtr 
    (
        CostYM      INT,
        CCtrSeq     INT 
    )
    
    SELECT @Cnt = 1
    
    WHILE ( @Cnt < 13 )
    BEGIN
        SELECT @CostYM = @CostYear + RIGHT('00'+CAST(@Cnt AS NVARCHAR),2)
        
        INSERT INTO #CCtr ( CostYM, CCtrSeq )
        SELECT @CostYM, CCtrSeq
          FROM DTI_fnOrgCCtr ( @CompanySeq, @CostYM, @CCtrSeq ) 
         WHERE LEN(OrgCd) <= 9 
        
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
        --BGColor     INT 
    )
    --select * from DTI_TESMCProfitResult where companyseq = 1 and cctrseq = 66 and costkeyseq = 85
    INSERT INTO #TEMP ( 
                        Serl, SMGPItem, AccSeq, AccName, 
                        Amt, 
                        CCtrSeq, AccSort1, AccSort2, Kind, CostYM--, BGColor
                      )
    SELECT CASE WHEN B.CostYM BETWEEN @CostYear + '01' AND @CostYear + '03' THEN 1
                WHEN B.CostYM BETWEEN @CostYear + '04' AND @CostYear + '06' THEN 2
                WHEN B.CostYM BETWEEN @CostYear + '07' AND @CostYear + '09' THEN 3
                WHEN B.CostYM BETWEEN @CostYear + '10' AND @CostYear + '12' THEN 4 END,
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
      LEFT OUTER JOIN DTI_TPNCostItem AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.STDYear = @CostYear AND I.AccSeq = A.AccSeq AND I.SMGPItem = A.SMGPItem ) 
     WHERE A.CompanySeq = @CompanySeq 
     GROUP BY CASE WHEN B.CostYM BETWEEN @CostYear + '01' AND @CostYear + '03' THEN 1
                   WHEN B.CostYM BETWEEN @CostYear + '04' AND @CostYear + '06' THEN 2
                   WHEN B.CostYM BETWEEN @CostYear + '07' AND @CostYear + '09' THEN 3
                   WHEN B.CostYM BETWEEN @CostYear + '10' AND @CostYear + '12' THEN 4 END,
              A.SMGPItem, A.AccSeq, A.CCtrSeq--, E.BGColor
     ORDER BY MIN(I.Sort)

    -- 직접/공통/지원 구분에 따라 계정과목 집계 
    INSERT INTO #TEMP (Serl, SMGPItem, CCtrSeq, AccSeq, AccName, 
                       Amt, AccSort1, Kind, CostYM)--, BGColor)    
    SELECT A.Serl, A.SMGPItem, A.CCtrSeq, -1, MAX(B.CostName2),
           SUM(A.Amt)/@AmtUnit, MIN(B.Sort), 2, MAX(A.CostYM)--, A.BGColor
      FROM #TEMP AS A    
      JOIN DTI_TPNCostItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                            AND B.STDYear    = @CostYear
                                            AND A.AccSeq     = B.AccSeq    
                                            AND A.SMGPItem   = B.SMGPItem 
     WHERE A.SMGPItem IN (1000398016, 1000398017, 1000398018)    
       --AND ISNULL(A.IsAdj, '0') = '0'    
     GROUP BY A.Serl, A.SMGPItem, A.CCtrSeq, B.CostName2--, A.BGColor
    
    DELETE FROM #TEMP WHERE AccSeq > 0
    
    --select * from #TEMP
    --return 
    CREATE TABLE #TMP_Result 
    (
        Serl        INT, --NCHAR(6),
        SMGPItem    INT,
        AccSeq      INT, 
        AccName     NVARCHAR(100), 
        Amt         DECIMAL(19,5), 
        CCtrSeq     INT, 
        AccSort1    INT,        -- 비용 손익요약항목 정렬순서  
        AccSort2    INT        -- 비용 계정과목 정렬순서  
        --BGColor     INT
    )
    
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
    UNION ALL 
    SELECT CASE WHEN A.CostYM BETWEEN @CostYear + '01' AND @CostYear + '06' THEN 5
                WHEN A.CostYM BETWEEN @CostYear + '06' AND @CostYear + '12' THEN 6 END, 
           A.SMGPItem, 
           A.AccSeq, 
           SUM(A.Amt), 
           A.CCtrSeq, 
           MIN(A.AccSort1), 
           MIN(A.AccSort2), 
           A.AccName
      FROM #TEMP AS A 
     GROUP BY CASE WHEN A.CostYM BETWEEN @CostYear + '01' AND @CostYear + '06' THEN 5
                WHEN A.CostYM BETWEEN @CostYear + '06' AND @CostYear + '12' THEN 6 END, 
              A.SMGPItem, A.AccSeq, A.CCtrSeq, A.AccName
    UNION ALL 
    SELECT 7,
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
        TitleSeq    INT, 
        Title2      NVARCHAR(200), 
        TitleSeq2   INT
    )
    
    INSERT INTO #Title ( Title, TitleSeq, Title2, TitleSeq2 ) 
    SELECT DISTINCT B.CCtrName AS Title, B.CCtrSeq AS TitleSeq, D.Title2, D.TitleSeq2
      FROM #CCtr    AS A 
      JOIN (SELECT 'Q1' AS Title2, 1 AS TitleSeq2 
            UNION ALL 
            SELECT 'Q2', 2
            UNION ALL
            SELECT 'Q3', 3
            UNION ALL
            SELECT 'Q4', 4
            UNION ALL
            SELECT 'H1', 5
            UNION ALL
            SELECT 'H2', 6
            UNION ALL 
            SELECT '년도계', 7 
           ) AS D ON ( 1 = 1 ) 
      JOIN #TMP_Result         AS C ON ( C.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDACCtr AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CCtrSeq = A.CCtrSeq )  
     ORDER BY B.CCtrSeq, D.TitleSeq2 
    
    SELECT * FROM #Title -- ORDER BY TitleSeq, TitleSeq2 
    --select * from #TMP_Result 
    --return 
    -- 고정
    
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
        CCtrSeq         INT, 
        TitleSeq2       INT, 
        AccSeq          INT, 
        AccName    NVARCHAR(100) 
    )
    
    INSERT INTO #Value (SMGPItem, CCtrSeq, TitleSeq2, Amt, AccSeq, AccName)
    SELECT A.SMGPItem, A.CCtrSeq, A.Serl, A.Amt, A.AccSeq, A.AccName
      FROM #TMP_Result AS A 
    
    SELECT B.RowIdx, A.ColIdx, C.Amt AS Results 
      FROM #Value AS C 
      JOIN #Title AS A ON ( A.TitleSeq = C.CCtrSeq AND A.TitleSeq2 = C.TitleSeq2 ) 
      JOIN #FixCol AS B ON ( ISNULL(B.AccName, '') = ISNULL(C.AccName, '') AND B.SMGPItem = C.SMGPItem ) 
     ORDER BY A.ColIdx, B.RowIdx 
     
    --UNION ALL 
    --SELECT B.RowIDX, C.ColIDX, SUM(A.Amt)
    --  FROM #Value AS A  
    --  JOIN #FixCol AS B ON B.SMGPItem = A.SMGPItem AND ISNULL(B.AccSeq, 0) = ISNULL(A.AccSeq, 0) AND ISNULL(B.SMGPItemName, '') = ISNULL(A.AccName, '')  
    --  JOIN #Title  AS C ON A.CCtrSeq  = C.TitleSeq  
    -- WHERE ISNULL(A.AccSeq, 0) <> 0  
    --   --AND ISNULL(A.IsAdj, '0') = '0'  
    -- GROUP BY B.RowIDX, C.ColIDX  
     
    
    RETURN
GO
exec DTI_SESMCPlanDepartListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <CostYear>2013</CostYear>
    <CCtrSeq>57</CCtrSeq>
    <AmtUnit>0</AmtUnit>
    <IsAdj>0</IsAdj>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021588,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018155
