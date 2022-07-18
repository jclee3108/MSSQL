  
IF OBJECT_ID('DTI_SPJTPublicSIMonthlyGPListQuery') IS NOT NULL   
    DROP PROC DTI_SPJTPublicSIMonthlyGPListQuery  
GO  
  
-- v2014.04.09  
  
-- 공공SI사업 월별 손익현황_DTI-조회 by 이재천   
CREATE PROC DTI_SPJTPublicSIMonthlyGPListQuery  
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
            @CostYMFr   NCHAR(6), 
            @CostYMTo   NCHAR(6), 
            @AmtUnit    DECIMAL(19,5) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CostYMFr = ISNULL(CostYMFr, ''), 
           @AmtUnit  = ISNULL(AmtUnit, 1), 
           @CostYMTo = ISNULL(CostYMTo,'') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            CostYMFr  NCHAR(6), 
            AmtUnit   DECIMAL(19,5), 
            CostYMTo  NCHAR(6) 
           )
    
    IF @AmtUnit = 0 
    BEGIN
        SELECT @AmtUnit = 1 
    END 
    
    CREATE TABLE #TEMP 
    (
        SMCostType      INT, 
        SMCostTypeSub   INT, 
        SMItemType      INT, 
        PlanAmt         DECIMAL(19,5), 
        ResultAmt       DECIMAL(19,5), 
        CostYM          NCHAR(6), 
        Sort            INT
    )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    -- 공공SI사업경영계획
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT A.SMCostType, A.SMCostType, A.SMItemType, CASE WHEN ISNULL(SUM(B.Value),0) = 0 THEN SUM(A.Amt) ELSE SUM(B.Value) END, 0, A.CostYM, 1
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostType, C.MinorSeq AS SMItemType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMInor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000419001,1000419002,1000419003,1000419004,1000419011 ) 
                   ) AS C ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000418001 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B ON ( B.PlanYM = A.CostYM AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType ) 
     GROUP BY A.SMCostType, A.SMItemType, A.CostYM 
     
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT A.SMCostType, A.SMCostType, A.SMItemType, CASE WHEN ISNULL(SUM(B.Value),0) = 0 THEN SUM(A.Amt) ELSE SUM(B.Value) END, 0, A.CostYM, 1
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostType, C.MinorSeq AS SMItemType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMInor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000419001,1000419002,1000419003,1000419004,1000419008,1000419012 ) 
                   ) AS C ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000418002 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B ON ( B.PlanYM = A.CostYM AND B.SMCostType = A.SMCostType AND B.SMItemType = A.SMItemType ) 
     GROUP BY A.SMCostType, A.SMItemType, A.CostYM 
    
    -- 공공SI사업경영실적
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostType, SMItemType, 0, SUM(ResultAmt), ResultYM, 1
      FROM DTI_TPJTPublicSIProfitResult 
     WHERE ResultYM BETWEEN @CostYMFr AND @CostYMTo 
       AND SMCostType IN ( 1000418001, 1000418002 ) 
     GROUP BY SMCostType, SMItemType, ResultYM
    
    -- 계 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostType, 1000419091, SUM(PlanAmt), SUM(ResultAmt), CostYM, 1
      FROM #TEMP AS A 
     WHERE SMCostType IN ( 1000418001, 1000418002 ) 
     GROUP BY SMCostType, CostYM 
    
    -- 프로젝트매출이익 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT 1000418003, 1000418003, 1000418003, 
           SUM(CASE WHEN SMCostType = 1000418001 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418002 THEN PlanAmt ELSE 0 END), 
           SUM(CASE WHEN SMCostType = 1000418001 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418002 THEN ResultAmt ELSE 0 END), 
           CostYM, 
           1
      FROM #TEMP 
     WHERE SMItemType = 1000419091 
     GROUP BY CostYM 
    
    -- 프로젝트사내대체 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT A.SMCostType, A.SMCostType, A.SMCostType, CASE WHEN ISNULL(SUM(B.ResultAmt),0) = 0 THEN SUM(A.Amt) ELSE SUM(B.ResultAmt) END, 0, A.CostYM, 1 
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000418009 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSIProfitResult AS B ON ( B.ResultYM = A.CostYM AND B.SMCostType = A.SMCostType ) 
     GROUP BY A.SMCostType, A.CostYM 
    
    
    -- % (프로젝트매출이익)
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT 1000418004, 1000418004, 1000418004, 
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418001 THEN PlanAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418001 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418002 THEN PlanAmt ELSE 0 END)) / 
                SUM(CASE WHEN SMCostType = 1000418001 THEN PlanAmt ELSE 0 END) * 100 
           END, 
           
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418001 THEN ResultAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418001 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418002 THEN ResultAmt ELSE 0 END)) / 
                SUM(CASE WHEN SMCostType = 1000418001 THEN ResultAmt ELSE 0 END) * 100 
           END, 
           CostYM, 
           1
    
      FROM #TEMP 
     WHERE SMItemType = 1000419091 
     GROUP BY CostYM 
    
    -- 영업매출계획 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT A.SMCostType, A.SMCostType, A.SMCostType, CASE WHEN ISNULL(SUM(B.Value),0) = 0 THEN SUM(A.Amt) ELSE SUM(B.Value) END, 0, A.CostYM, 1
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq IN ( 1000418005, 1000418006 ) 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B ON ( B.PlanYM = A.CostYM AND B.SMCostType = A.SMCostType ) 
     GROUP BY A.SMCostType, A.CostYM 
    
    -- 영업매출실적 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostType, SMCostType, 
           0, 
           SUM(ResultAmt), 
           ResultYM, 
           1
      FROM DTI_TPJTPublicSIProfitResult 
     WHERE ResultYM BETWEEN @CostYMFr AND @CostYMTo 
       AND SMCostType IN ( 1000418005, 1000418006 ) 
     GROUP BY ResultYM, SMCostType 
    
    -- 영업매출이익
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT 1000418007, 1000418007, 1000418007, 
           SUM(CASE WHEN SMCostType = 1000418005 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418006 THEN PlanAmt ELSE 0 END), 
           SUM(CASE WHEN SMCostType = 1000418005 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418006 THEN ResultAmt ELSE 0 END), 
           CostYM, 
           1
      FROM #TEMP 
     WHERE CostYM BETWEEN @CostYMFr AND @CostYMTo 
       AND SMCostType IN ( 1000418005, 1000418006 ) 
     GROUP BY CostYM  
    
    -- % (영업매출이익)
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT 1000418011, 1000418011, 1000418011, 
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418005 THEN PlanAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418005 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418006 THEN PlanAmt ELSE 0 END)) /
                SUM(CASE WHEN SMCostType = 1000418005 THEN PlanAmt ELSE 0 END) * 100
           END, 
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418005 THEN ResultAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418005 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418006 THEN ResultAmt ELSE 0 END)) / 
                SUM(CASE WHEN SMCostType = 1000418005 THEN ResultAmt ELSE 0 END) * 100 
           END, 
           CostYM, 
           1
      FROM #TEMP 
     WHERE SMCostType IN ( 1000418005, 1000418006 ) 
     GROUP BY CostYM 
    
    -- 사내대체이익계획
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT A.SMCostType, A.SMCostType, A.SMCostType, CASE WHEN ISNULL(SUM(B.Value),0) = 0 THEN SUM(A.Amt) ELSE SUM(B.Value) END, 0, A.CostYM, 1
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq  = 1000418008 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B ON ( B.PlanYM = A.CostYM AND B.SMCostType = A.SMCostType ) 
     GROUP BY A.SMCostType, A.CostYM 
    
    -- 사내대체이익실적
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT SMCostType, SMCostType, SMCostType, SUM(ResultAmt), 0, ResultYM, 1 
      FROM DTI_TPJTPublicSIProfitResult 
     WHERE ResultYM BETWEEN @CostYMFr AND @CostYMTo 
       AND SMCostType = 1000418008
     GROUP BY ResultYM, SMCostType 
    
    -- 매출이익합계 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1000418010, 1000418010, 1000418010, 
           SUM(CASE WHEN SMCostType = 1000418003 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418007 THEN PlanAmt ELSE 0 END), 
           SUM(CASE WHEN SMCostType = 1000418003 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418007 THEN ResultAmt ELSE 0 END), 
           CostYM, 
           1 
      FROM #TEMP 
     WHERE SMCostType IN ( 1000418003, 1000418007 ) 
     GROUP BY CostYM 
    
    -- % (매출이익합계) 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1000418011, 1000418011, 1000418011, 
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418003 THEN PlanAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418003 THEN PlanAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418007 THEN PlanAmt ELSE 0 END)) / 
                SUM(CASE WHEN SMCostType = 1000418003 THEN PlanAmt ELSE 0 END)
           END, 
           CASE WHEN SUM(CASE WHEN SMCostType = 1000418003 THEN ResultAmt ELSE 0 END) = 0 THEN 0 
           ELSE (SUM(CASE WHEN SMCostType = 1000418003 THEN ResultAmt ELSE 0 END) - SUM(CASE WHEN SMCostType = 1000418007 THEN ResultAmt ELSE 0 END)) / 
                SUM(CASE WHEN SMCostType = 1000418003 THEN ResultAmt ELSE 0 END)
           END, 
           CostYM, 
           1
      FROM #TEMP 
     WHERE SMCostType IN ( 1000418003, 1000418007 ) 
     GROUP BY CostYM 
    
    -- 투입비율 계획
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1999999999, 1999999999, A.SMItemType, CASE WHEN ISNULL(AVG(B.Value),0) = 0 THEN AVG(A.Amt) ELSE AVG(B.Value) END, 0, A.CostYM, 1
      FROM (SELECT B.CostYM, A.MinorSeq AS SMItemType, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000419009 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSISalesPlan AS B ON ( B.PlanYM = A.CostYM AND B.SMItemType = A.SMItemType ) 
     GROUP BY A.SMItemType, A.CostYM 
    
    -- 투입비율 실적 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1999999999, 1999999999, SMItemType, 0, AVG(ResultAmt), ResultYM, 1 
      FROM DTI_TPJTPublicSIProfitResult 
     WHERE ResultYM BETWEEN @CostYMFr AND @CostYMTo 
       AND SMItemType = 1000419009 
     GROUP BY ResultYM, SMItemType 
    
    -- 미투입비율 계획
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1999999999, 1999999999, 1000419010, CASE WHEN AVG(PlanAmt) = 0 THEN 0 ELSE 100 - AVG(PlanAmt) END, 0, CostYM, 1 
      FROM #TEMP 
     WHERE SMItemType = 1000419009 
       AND PlanAmt <> 0 
    GROUP BY CostYM, SMCostType, SMItemType 
    
    -- 미투입비율 실적
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1999999999, 1999999999, 1000419010, 0, CASE WHEN AVG(ResultAmt)  = 0 THEN 0 ELSE 100 - AVG(ResultAmt)  END , CostYM, 1 
      FROM #TEMP 
     WHERE SMItemType = 1000419009 
       AND ResultAmt <> 0 
    GROUP BY CostYM, SMCostType, SMItemType 
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------
    
    -- 간접비 SI 개발팀
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, 
           CASE WHEN SUM(ISNULL(B.PlanCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.PlanCost) END, 
           CASE WHEN SUM(ISNULL(B.ResultCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.ResultCost) END, 
           CostYM, 
           2
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostLClass, C.MinorSeq AS SMCostMClass, D.MinorSeq AS SMCostSClass, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000426001, 1000426002 ) 
                   ) AS C ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000427001, 1000427002 ) 
                   ) AS D ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000425001 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSIProfitCostResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                          AND B.ResultYM = A.CostYM 
                                                                          AND B.SMCostLClass = A.SMCostLClass 
                                                                          AND B.SMCostMClass = A.SMCostMClass 
                                                                          AND B.SMCostSClass = A.SMCostSClass 
                                                                            )
     GROUP BY A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, A.CostYM 
            
    -- 계 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostTypeSub, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425001
       AND SMCostTypeSub IN ( 1000426001, 1000426002 ) 
     GROUP BY SMCostType, SMCostTypeSub, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, SMItemType, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425001 
       AND SMItemType IN ( 1000427001, 1000427002 ) 
     GROUP BY SMCostType, SMItemType, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425001 
     GROUP BY SMCostType, CostYM 
    
    -- 판매비 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, 
           CASE WHEN SUM(ISNULL(B.PlanCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.PlanCost) END, 
           CASE WHEN SUM(ISNULL(B.ResultCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.ResultCost) END, 
           CostYM, 
           2 
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostLClass, C.MinorSeq AS SMCostMClass, D.MinorSeq AS SMCostSClass, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000426003, 1000426004 ) 
                   ) AS C ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000427001, 1000427002 ) 
                   ) AS D ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000425002 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSIProfitCostResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                          AND B.ResultYM = A.CostYM 
                                                                          AND B.SMCostLClass = A.SMCostLClass 
                                                                          AND B.SMCostMClass = A.SMCostMClass 
                                                                          AND B.SMCostSClass = A.SMCostSClass 
                                                                            )
     GROUP BY A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, A.CostYM 
    
    -- 계 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostTypeSub, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425002
       AND SMCostTypeSub IN ( 1000426003, 1000426004 ) 
     GROUP BY SMCostType, SMCostTypeSub, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, SMItemType, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425002 
       AND SMItemType IN ( 1000427001, 1000427002 ) 
     GROUP BY SMCostType, SMItemType, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425002 
     GROUP BY SMCostType, CostYM 
    
    -- 일반비 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, 
           CASE WHEN SUM(ISNULL(B.PlanCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.PlanCost) END, 
           CASE WHEN SUM(ISNULL(B.ResultCost,0)) = 0 THEN SUM(A.Amt) ELSE SUM(B.ResultCost) END, 
           CostYM, 
           2 
      FROM (SELECT B.CostYM, A.MinorSeq AS SMCostLClass, C.MinorSeq AS SMCostMClass, D.MinorSeq AS SMCostSClass, CONVERT(DECIMAL(19,5),0) AS Amt 
              FROM _TDASMinor AS A 
              JOIN (SELECT DISTINCT LEFT(Solar,6) AS CostYM
                      FROM _TCOMCalendar AS A 
                     WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
                   ) AS B ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000426005, 1000426006 ) 
                   ) AS C ON ( 1 = 1 ) 
              JOIN (SELECT MinorSeq 
                      FROM _TDASMInor AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.MinorSeq IN ( 1000427001, 1000427002 ) 
                   ) AS D ON ( 1 = 1 ) 
             WHERE CompanySeq = @CompanySeq 
               AND A.MinorSeq = 1000425003 
           ) AS A 
      LEFT OUTER JOIN DTI_TPJTPublicSIProfitCostResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                          AND B.ResultYM = A.CostYM 
                                                                          AND B.SMCostLClass = A.SMCostLClass 
                                                                          AND B.SMCostMClass = A.SMCostMClass 
                                                                          AND B.SMCostSClass = A.SMCostSClass 
                                                                            )
     GROUP BY A.SMCostLClass, A.SMCostMClass, A.SMCostSClass, A.CostYM 
    
    -- 계 
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, SMCostTypeSub, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425003
       AND SMCostTypeSub IN ( 1000426005, 1000426006 ) 
     GROUP BY SMCostType, SMCostTypeSub, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, SMItemType, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425003 
       AND SMItemType IN ( 1000427001, 1000427002 ) 
     GROUP BY SMCostType, SMItemType, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT SMCostType, 1999999999, 1999999999, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP AS A 
     WHERE SMCostType = 1000425003 
     GROUP BY SMCostType, CostYM 
    
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort)
    SELECT 1000425004, 1000425004, 1000425004, SUM(PlanAmt), SUM(ResultAmt), CostYM, 2 
      FROM #TEMP 
     WHERE SMCostTypeSub = 1999999999 
       AND SMItemType = 1999999999 
     GROUP BY CostYM 
     
    INSERT INTO #TEMP (SMCostType, SMCostTypeSub, SMItemType, PlanAmt, ResultAmt, CostYM, Sort) 
    SELECT 1000425005, 1000425005, 1000425005, A.PlanAmt + B.PlanAmt - C.PlanAmt, A.ResultAmt + B.ResultAmt - C.ResultAmt, A.CostYM, 2 
      FROM (SELECT CostYM, SUM(PlanAmt) AS PlanAmt, SUM(ResultAmt) AS ResultAmt
              FROM #TEMP 
             WHERE SMCostType = 1000418003
             GROUP BY CostYM 
            ) AS A 
      LEFT OUTER JOIN (SELECT CostYM, SUM(PlanAmt) AS PlanAmt, SUM(ResultAmt) AS ResultAmt
                         FROM #TEMP 
                        WHERE SMCostType = 1000418007
                       GROUP BY CostYM 
                      ) AS B ON ( B.CostYM = A.CostYM ) 
      LEFT OUTER JOIN (SELECT CostYM, SUM(PlanAmt) AS PlanAmt, SUM(ResultAmt) AS ResultAmt
                         FROM #TEMP 
                        WHERE SMCostType = 1000425004
                       GROUP BY CostYM 
                      ) AS C ON ( C.CostYm = A.CostYM ) 
------------------------------------------------------------------------------------------------------------------------------------------------
    
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT, 
        Title2     NVARCHAR(100), 
        TitleSeq2  INT
    )
    
    INSERT INTO #Title (Title, TitleSeq, Title2, TitleSeq2) 
    SELECT A.Title, A.TitleSeq, B.Title2, B.TitleSeq2 
      FROM (SELECT DISTINCT STUFF(LEFT(Solar,6),5,0,'-') AS Title, LEFT(Solar,6) AS TitleSeq 
              FROM _TCOMCalendar AS A 
             WHERE LEFT(Solar,6) BETWEEN @CostYMFr AND @CostYMTo 
           ) AS A 
      JOIN (SELECT '계획' AS Title2, 100 AS TitleSeq2 
            UNION ALL 
            SELECT '실적', 200 
            UNION ALL 
            SELECT '계획비', 300
            ) AS B ON ( 1 = 1 ) 
     ORDER BY TitleSeq, TitleSeq2 
    
    SELECT * FROM #Title 
    
    -- 고정부 
    
    CREATE TABLE #FixCol
    (
        RowIdx              INT IDENTITY(0, 1), 
        SMCostType          INT, 
        SMCostTypeName      NVARCHAR(100), 
        SMCostTypeSub       INT, 
        SMCostTypeNameSub   NVARCHAR(100), 
        SMItemType          INT, 
        SMItemTypeName      NVARCHAR(100), 
        SumPlanAmt          DECIMAL(19,5), 
        SumResultAmt        DECIMAL(19,5) 
    )
    
    INSERT INTO #FixCol ( 
                            SMCostType         ,SMCostTypeName     ,SMCostTypeSub      ,SMCostTypeNameSub  ,SMItemType         ,
                            SMItemTypeName     ,SumPlanAmt         ,SumResultAmt       
                        )    
    SELECT A.SMCostType, MAX(B.MinorName), A.SMCostTypeSub,  MAX(D.MinorName), A.SMItemType, 
           CASE WHEN A.SMItemType IN ( 1000419091, 1999999999 ) THEN '계' ELSE MAX(C.MinorName) END, 
           
           CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418004 AND PlanAmt <> 0) 
                WHEN SMItemType = 1000418011 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418011 AND PlanAmt <> 0) 
                WHEN SMItemType = 1000419009 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419009 AND PlanAmt <> 0) 
                WHEN SMItemType = 1000419010 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419010 AND PlanAmt <> 0) 
                ELSE SUM(PlanAmt) / @AmtUnit
                END, 
           CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418004 AND ResultAmt <> 0) 
                WHEN SMItemType = 1000418011 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418011 AND ResultAmt <> 0) 
                WHEN SMItemType = 1000419009 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419009 AND ResultAmt <> 0) 
                WHEN SMItemType = 1000419010 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419010 AND ResultAmt <> 0) 
                ELSE SUM(ResultAmt) / @AmtUnit
                END 
           
           --CASE WHEN SMItemType IN ( 1000419009, 1000419010 ) THEN AVG(PlanAmt) ELSE SUM(PlanAmt) / @AmtUnit END, 
           --CASE WHEN SMItemType IN ( 1000419009, 1000419010 ) THEN AVG(ResultAmt) ELSE SUM(ResultAmt) / @AmtUnit END 
      FROM #TEMP AS A 
      LEFT OUTER JOIN _TDASMinor        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMCostType ) 
      LEFT OUTER JOIN _TDASMinor        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMItemType ) 
      LEFT OUTER JOIN _TDASMinor        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMCostTypeSub ) 
     GROUP BY A.Sort, A.SMCostType, A.SMCostTypeSub, A.SMItemType 
     ORDER BY A.Sort, A.SMCostType, A.SMCostTypeSub, A.SMItemType 
    
    SELECT * FROM #FixCol 
    
    CREATE TABLE #Value
    (
        CostYM          NCHAR(6), 
        TitleSeq2       INT, 
        SMCostType      INT, 
        SMCostTypeSub   INT, 
        SMItemType      INT, 
        Results         DECIMAL(19, 5) 
    )
    INSERT INTO #Value ( CostYM, TitleSeq2, SMCostType, SMCostTypeSub, SMItemType, Results ) 
    SELECT CostYM, 100, SMCostType, SMCostTypeSub, SMItemType, 
           CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418004 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000418011 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418011 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000419009 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419009 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000419010 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419010 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                ELSE SUM(PlanAmt) / @AmtUnit
                END
      FROM #TEMP AS A 
     GROUP BY CostYM, SMCostType, SMCostTypeSub, SMItemType 
    UNION ALL 
    SELECT CostYM, 200, SMCostType, SMCostTypeSub, SMItemType, 
           CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418004 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000418011 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418011 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000419009 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419009 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                WHEN SMItemType = 1000419010 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419010 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                ELSE SUM(ResultAmt) / @AmtUnit
                END 
      FROM #TEMP AS A 
     GROUP BY CostYM, SMCostType, SMCostTypeSub, SMItemType 
    UNION ALL 
    SELECT CostYM, 300, SMCostType, SMCostTypeSub, SMItemType, 
           CASE WHEN (CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418004 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                           WHEN SMItemType = 1000418011 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418011 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                           WHEN SMItemType = 1000419009 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419009 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                           WHEN SMItemType = 1000419010 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419010 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                           ELSE SUM(ResultAmt) / @AmtUnit
                           END 
                     ) = 0 THEN 0 
                ELSE ((CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418004 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000418011 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000418011 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000419009 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419009 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000419010 THEN (SELECT AVG(PlanAmt) From #TEMP where SMItemType = 1000419010 AND PlanAmt <> 0 AND CostYM = A.CostYM ) 
                            ELSE SUM(PlanAmt) / @AmtUnit
                            END
                      ) / 
                      (CASE WHEN SMItemType = 1000418004 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418004 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000418011 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000418011 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000419009 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419009 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                            WHEN SMItemType = 1000419010 THEN (SELECT AVG(ResultAmt) From #TEMP where SMItemType = 1000419010 AND ResultAmt <> 0 AND CostYM = A.CostYM ) 
                            ELSE SUM(ResultAmt) / @AmtUnit
                            END 
                      )
                     )
                END * 100 
      FROM #TEMP AS A 
     GROUP BY CostYM, SMCostType, SMCostTypeSub, SMItemType 
    
    SELECT B.RowIdx, A.ColIdx, Results 
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.CostYM AND A.TitleSeq2 = C.TitleSeq2 ) 
      JOIN #FixCol AS B ON ( B.SMCostType = C.SMCostType AND B.SMCostTypeSub = C.SMCostTypeSub AND B.SMItemType = C.SMItemType ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    RETURN  
GO
exec DTI_SPJTPublicSIMonthlyGPListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CostYMFr>201301</CostYMFr>
    <CostYMTo>201303</CostYMTo>
    <AmtUnit>0</AmtUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1022139,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018607