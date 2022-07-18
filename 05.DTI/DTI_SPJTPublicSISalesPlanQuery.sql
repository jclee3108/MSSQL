  
IF OBJECT_ID('DTI_SPJTPublicSISalesPlanQuery') IS NOT NULL   
    DROP PROC DTI_SPJTPublicSISalesPlanQuery  
GO  
  
-- v2014.04.07  
  
-- 공공SI사업경영계획_DTI-조회 by 이재천   
CREATE PROC DTI_SPJTPublicSISalesPlanQuery  
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
            @PlanYear   NVARCHAR(4) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @PlanYear   = ISNULL( PlanYear, '' ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlanYear   NCHAR(4))    
    
    CREATE TABLE #Title
    (
        ColIdx      INT IDENTITY(0,1), 
        Title       NVARCHAR(100), 
        TitleSeq    INT
    )
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT '1월', @PlanYear + '01'
    UNION ALL 
    SELECT '2월', @PlanYear + '02'
    UNION ALL 
    SELECT '3월', @PlanYear + '03'
    UNION ALL 
    SELECT '4월', @PlanYear + '04'
    UNION ALL 
    SELECT '5월', @PlanYear + '05'
    UNION ALL 
    SELECT '6월', @PlanYear + '06'
    UNION ALL 
    SELECT '7월', @PlanYear + '07'
    UNION ALL 
    SELECT '8월', @PlanYear + '08'
    UNION ALL 
    SELECT '9월', @PlanYear + '09' 
    UNION ALL 
    SELECT '10월', @PlanYear + '10'
    UNION ALL 
    SELECT '11월', @PlanYear + '11'
    UNION ALL 
    SELECT '12월', @PlanYear + '12' 
    UNION ALL 
    SELECT '합계', 201413
    
    SELECT * FROM #Title 
    
    CREATE TABLE #FixCol 
    (
        RowIdx          INT IDENTITY(0,1), 
        SMCostType      INT, 
        SMItemType      INT, 
        SMCostTypeName  NVARCHAR(100), 
        SMItemTypeName  NVARCHAR(100), 
    )
    
    CREATE TABLE #SMinorInfo 
    (
        SMCostType  INT, 
        SMItemType  INT, 
        Sort        INT
    )
    
    INSERT INTO #SMInorInfo( SMCostType, SMItemType, Sort ) 
    SELECT 1000418001, 1000419001, 1 
    UNION ALL 
    SELECT 1000418001, 1000419002, 1
    UNION ALL 
    SELECT 1000418001, 1000419003, 1 
    UNION ALL 
    SELECT 1000418001, 1000419004, 1 
    UNION ALL 
    SELECT 1000418001, 1000419011, 1 
    UNION ALL 
    SELECT 1000418001, 99, 2
    UNION ALL 
    SELECT 1000418002, 1000419001, 1
    UNION ALL 
    SELECT 1000418002, 1000419002, 1
    UNION ALL 
    SELECT 1000418002, 1000419003, 1
    UNION ALL 
    SELECT 1000418002, 1000419004, 1
    UNION ALL 
    SELECT 1000418002, 1000419008, 1
    UNION ALL 
    SELECT 1000418002, 1000419012, 1 
    UNION ALL 
    SELECT 1000418002, 99, 2 
    UNION ALL 
    SELECT 1000418003, 0, 3
    UNION ALL 
    SELECT 1000418004, 0, 3 
    UNION ALL 
    SELECT 1000418005, 0, 3
    UNION ALL 
    SELECT 1000418006, 0, 3 
    UNION ALL 
    SELECT 1000418007, 0, 3 
    UNION ALL 
    SELECT 1000418008, 0, 3 
    UNION ALL 
    SELECT 1999999999, 1000419009, 3 
    UNION ALL 
    SELECT 1999999999, 1000419010, 3 
    
    -- 기초데이터 넣기 
    CREATE TABLE #TEMP 
    (
        PlanYM          NCHAR(6), 
        SMCostType      INT, 
        SMItemType      INT, 
        Value           DECIMAL(19,5), 
        Sort            INT 
    )
    INSERT INTO #TEMP ( PlanYM, SMCostType, SMItemType, Value, Sort ) 
    SELECT A.PlanYM, A.SMCostType, A.SMItemType, ISNULL(B.Value,0), A.Sort 
    --CASE WHEN A.SMItemType = 99 THEN C.SumValue 
    --                                                                   ELSE ISNULL(B.Value,0) 
                                                                       
    --                                                                   END , A.Sort 
      FROM (SELECT B.TitleSeq AS PlanYM, A.SMCostType, SMItemType, A.Sort
              FROM #SMinorInfo AS A 
              LEFT OUTER JOIN #Title AS B ON ( 1 = 1 )
           )  AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType AND B.PlanYM = A.PlanYM ) 
    
    -- 계 
    UPDATE A
       SET Value = B.SumValue
      FROM #TEMP AS A   
      LEFT OUTER JOIN (SELECT A.PlanYM, A.SMCostType, SUM(ISNULL(A.Value,0)) AS SumValue
                         FROM DTI_TPJTPublicSISalesPlan AS A 
                        WHERE A.CompanySeq = @CompanySeq 
                          AND (LEFT(A.PlanYM,4) = @PlanYear) 
                          AND A.SMCostType IN ( 1000418001, 1000418002 )  
                        GROUP BY A.SMCostType, A.PlanYM
                      ) AS B ON ( B.SMCostType = A.SMCostType AND B.PlanYM = A.PlanYM ) --  AND A.SMItemType = 99 ) -- A.smitemtype = 99 ) --AND C.PlanYM = B.PlanYM) 
     WHERE A.SMItemType = 99 
    
    -- 프로젝트 매출이익(GP1=A-B), % 구하기
    UPDATE A 
       SET Value = CASE WHEN A.SMCostType = 1000418003 THEN B.Amt WHEN A.SMCostType = 1000418004 THEN B.Rate END
     FROM #TEMP AS A 
     LEFT OUTER JOIN (SELECT A.PlanYM, A.Value - B.Value AS Amt, CASE WHEN ISNULL(A.Value,0) = 0 THEN 0 ELSE (A.Value-B.Value) / A.Value * 100 END AS Rate 
                        FROM (SELECT PlanYM, Value 
                                FROM #TEMP 
                                WHERE SMItemType = 99 
                                  AND SMCostType = 1000418001
                             ) AS A 
                        LEFT OUTER JOIN (SELECT PlanYM, Value 
                                           FROM #TEMP 
                                          WHERE SMItemType = 99 
                                            AND SMCostType = 1000418002
                              ) AS B ON ( B.PlanYm = A.PlanYM )
                     ) AS B ON ( B.PlanYM = A.PlanYM ) 
     WHERE A.SMCostType IN ( 1000418003, 1000418004 ) 
    
    -- 영업 매출이익GP2=A2-B2
    UPDATE A 
       SET Value = B.Amt
      FROM #TEMP AS A 
     LEFT OUTER JOIN (SELECT A.PlanYM, A.Value - B.Value AS Amt 
                        FROM (SELECT PlanYM, Value 
                                FROM #TEMP 
                                WHERE SMCostType = 1000418005
                             ) AS A 
                        LEFT OUTER JOIN (SELECT PlanYM, Value 
                                           FROM #TEMP 
                                          WHERE SMCostType = 1000418006
                              ) AS B ON ( B.PlanYm = A.PlanYM )
                     ) AS B ON ( B.PlanYM = A.PlanYM ) 
     WHERE A.SMCostType = 1000418007 
    
    -- 미투입비율 구하기 
    UPDATE A 
       SET Value = B.Rate
    
      FROM #TEMP AS A 
      LEFT OUTER JOIN (SELECT PlanYM, CASE WHEN ISNULL(Value,0) = 0 THEN 0 ELSE 100 - Value END AS Rate 
                         FROM #TEMP 
                         WHERE SMItemType = 1000419009 
                      ) AS B ON ( B.PlanYM = A.PlanYM )  
     WHERE A.SMItemType = 1000419010
    
    -- 합계
    SELECT 201413 AS PlanYM, SMCostType, SMItemType, SUM(Value) AS Value, CASE WHEN SMItemType = 99 THEN 2 WHEN SMItemType = 0 THEN 3 ELSE 1 END AS Sort
      INTO #TEMP_SUB
      FROM #TEMP AS A 
     WHERE LEFT(A.PlanYM,4) = @PlanYear 
       AND PlanYM <> 201413 
     GROUP BY SMCostType, SMItemType
     ORDER BY SMCostType, Sort, SMItemType 
    
    -- 고정값
    INSERT INTO #FixCol( SMCostType, SMItemType, SMCostTypeName, SMItemTypeName ) 
    SELECT A.SMCostType, A.SMItemType, B.MinorName, CASE WHEN A.SMItemType = 99 THEN '계' ELSE C.MinorName END
      FROM (SELECT DISTINCT SMCostType, SMItemType, Sort
              FROM #TEMP
           ) AS A 
      LEFT OUTER JOIN _TDASMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMCostType ) 
      LEFT OUTER JOIN _TDASMinor    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMItemType ) 
     ORDER BY A.SMCostType, RIGHT(A.SMItemType,2), A.Sort
    
    SELECT * FROM #FixCol 
    
    -- 가변값
    CREATE TABLE #Value 
    (
        PlanYM      NCHAR(6), 
        SMCostType  INT, 
        SMItemType  INT, 
        Results     DECIMAL(19,5), 
    )
    INSERT INTO #Value( PlanYM, SMCostType, SMItemType, Results ) 
    SELECT A.PlanYM, A.SMCostType, A.SMItemType, A.Value 
      FROM #TEMP AS A 
    
    -- 합계금액 UPDATE 
    UPDATE A 
       SET Results = CASE WHEN B.SMCostType = 1000418004 THEN ((SELECT Value FROM #TEMP_SUB WHERE SMItemType = 99 AND SMcostType = 1000418001) - 
                                                               (SELECT Value FROM #TEMP_SUB WHERE SMItemType = 99 AND SMcostType = 1000418002))
                                                              /(SELECT Value FROM #TEMP_SUB WHERE SMItemType = 99 AND SMcostType = 1000418001) * 100 
                          WHEN B.SMItemType = 1000419009 THEN (CASE WHEN (SELECT COUNT(1) FROM #Value WHERE SMItemType = 1000419009 AND Results <> 0 AND PlanYM <> 201413) = 0 THEN 0 
                                                                    ELSE B.Value / (SELECT COUNT(1) FROM #Value WHERE SMItemType = 1000419009 AND Results <> 0 AND PlanYM <> 201413) 
                                                                    END)
                          WHEN B.SMItemType = 1000419010 THEN (CASE WHEN (SELECT COUNT(1) FROM #Value WHERE SMItemType = 1000419010 AND Results <> 0 AND PlanYM <> 201413) = 0 THEN 0 
                                                                    ELSE B.Value / (SELECT COUNT(1) FROM #Value WHERE SMItemType = 1000419010 AND Results <> 0 AND PlanYM <> 201413) 
                                                                    END)
                          ELSE  B.Value END 
      FROM #Value AS A 
      LEFT OUTER JOIN #TEMP_SUB AS B ON ( B.PlanYM = A.PlanYM AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType ) 
     WHERE A.PlanYM = 201413 
    
    SELECT B.RowIdx, A.ColIdx, C.Results
      FROM #Value AS C 
      JOIN #Title AS A ON ( A.TitleSeq = C.PlanYM ) 
      JOIN #FixCol AS B ON ( B.SMCostType = C.SMCostType AND B.SMItemType = C.SMItemType ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
GO
exec DTI_SPJTPublicSISalesPlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYear>2014</PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022071,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018561