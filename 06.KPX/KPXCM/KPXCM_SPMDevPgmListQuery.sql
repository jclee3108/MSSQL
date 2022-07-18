  
IF OBJECT_ID('KPXCM_SPMDevPgmListQuery') IS NOT NULL   
    DROP PROC KPXCM_SPMDevPgmListQuery  
GO  
  
-- v2015.09.17  
  
-- (관리)프로그램개발현황_KPXCM-리스트조회 by 이재천   
CREATE PROC KPXCM_SPMDevPgmListQuery  
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
            @IsModule   NCHAR(1),
            @StdDate    NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @IsModule    = ISNULL( IsModule  , '0' ), 
           @StdDate     = ISNULL( StdDate   , '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            IsModule   NCHAR(1),
            StdDate    NCHAR(8)
           )    
    
    -- 기초데이터 
    CREATE TABLE #BaseData 
    (
        DevOrder    NVARCHAR(100), 
        PlanDate    NCHAR(8), 
        Cnt         INT, 
        SMIsFinSeq  INT 
    )
    INSERT INTO #BaseData ( DevOrder, PlanDate, Cnt, SMIsFinSeq ) 
    SELECT ISNULL(Y.DevOrder,''), Z.Solar, ISNULL(Y.Cnt ,0), ISNULL(Y.SMIsFinSeq,0) 
      FROM _TCOMCalendar AS Z 
      LEFT OUTER JOIN ( 
                        SELECT (CASE WHEN @IsModule = '1' THEN A.Module ELSE DevOrder END) AS DevOrder, A.PlanDate, COUNT(1) AS Cnt, A.SMIsFinSeq  
                          FROM KPX_TPMDevPgm AS A 
                         WHERE A.CompanySeq = @CompanySeq  
                         GROUP BY (CASE WHEN @IsModule = '1' THEN A.Module ELSE DevOrder END), A.PlanDate, A.SMIsFinSeq
                       ) AS Y ON ( Y.PlanDate = Z.Solar ) 
     WHERE Z.Solar BETWEEN CONVERT(NCHAR(8),DATEADD(DAY, -1, @StdDate),112) AND CONVERT(NCHAR(8),DATEADD(DAY, 10, @StdDate),112) 
     
    -- 합계행 추가 
    INSERT INTO #BaseData
    SELECT '합계', A.PlanDate, A.Cnt, A.SMIsFinSeq 
      FROM #BaseData AS A 
    
    
    CREATE TABLE #Result 
    (
        DevOrder    NVARCHAR(100), 
        PlanCnt     DECIMAL(19,5), 
        ResultCnt   DECIMAL(19,5), 
        RltRate     DECIMAL(19,5), 
        TotDevPgm   DECIMAL(19,5), 
        LimitDate   NCHAR(8), 
        DevPgmCnt01 DECIMAL(19,5), 
        DevPgmCnt02 DECIMAL(19,5), 
        DevPgmCnt03 DECIMAL(19,5), 
        DevPgmCnt04 DECIMAL(19,5), 
        DevPgmCnt05 DECIMAL(19,5), 
        DevPgmCnt06 DECIMAL(19,5), 
        DevPgmCnt07 DECIMAL(19,5), 
        DevPgmCnt08 DECIMAL(19,5), 
        DevPgmCnt09 DECIMAL(19,5), 
        DevPgmCnt10 DECIMAL(19,5), 
        DevPgmCnt11 DECIMAL(19,5), 
        DevPgmCnt12 DECIMAL(19,5) 
    )
    
    INSERT INTO #Result ( DevOrder, LimitDate ) 
    SELECT DevOrder, CASE WHEN DevOrder = '합계' THEN '' ELSE MAX(PlanDate) END AS LimitDate 
      FROM #BaseData AS A 
     WHERE A.DevOrder <> ''
     GROUP BY DevOrder 
    

                        
    -- 집계데이터 Count 
    SELECT A.DevOrder, 
           MAX(C.PlanCnt) AS PlanCnt, 
           MAX(B.FinCnt) AS ResultCnt, 
           MAX(D.Cnt) AS TotDevPgm, 
           ROUND((MAX(CONVERT(DECIMAL(19,5),B.FinCnt)) / MAX(CONVERT(DECIMAL(19,5),C.PlanCnt))) * 100,2) AS RltRate -- 달성율 
      INTO #Temp 
      FROM #Result AS A 
      LEFT OUTER JOIN (
                        SELECT Z.DevOrder, SUM(Cnt) AS FinCnt 
                          FROM #BaseData AS Z 
                         WHERE SMIsFinSeq = 1070001 
                        GROUP BY Z.DevOrder
                      ) AS B ON ( B.DevOrder = A.DevOrder ) 
      LEFT OUTER JOIN (
                        SELECT Z.DevOrder, SUM(Cnt) AS PlanCnt 
                          FROM #BaseData AS Z 
                        GROUP BY Z.DevOrder
                      ) AS C ON ( C.DevOrder = A.DevOrder ) 
      LEFT OUTER JOIN (
                        SELECT (CASE WHEN @IsModule = '1' THEN Z.Module ELSE Z.DevOrder END) AS DevOrder, COUNT(1) AS Cnt
                          FROM KPX_TPMDevPgm AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY (CASE WHEN @IsModule = '1' THEN Z.Module ELSE Z.DevOrder END) 
                        
                        UNION ALL 
                        
                        SELECT '합계', COUNT(1) Cnt 
                          FROM KPX_TPMDevPgm AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                      ) AS D ON ( D.DevOrder = A.DevOrder ) 
     WHERE A.DevOrder <> ''
     GROUP BY A.DevOrder 
    
    UPDATE A 
       SET PlanCnt = B.PlanCnt,  
           ResultCnt = B.ResultCnt, 
           RltRate = B.RltRate, 
           TotDevPgm = B.TotDevPgm 
      FROM #Result  AS A  
      JOIN #Temp    AS B ON ( B.DevOrder = A.DevOrder ) 
    
 
    -- 일자별 계획 Count
    UPDATE A 
       SET DevPgmCnt01 = ISNULL(B.Cnt01,0), 
           DevPgmCnt02 = ISNULL(C.Cnt02,0),  
           DevPgmCnt03 = ISNULL(D.Cnt03,0),  
           DevPgmCnt04 = ISNULL(E.Cnt04,0),  
           DevPgmCnt05 = ISNULL(F.Cnt05,0),  
           DevPgmCnt06 = ISNULL(G.Cnt06,0),  
           DevPgmCnt07 = ISNULL(H.Cnt07,0),  
           DevPgmCnt08 = ISNULL(I.Cnt08,0),  
           DevPgmCnt09 = ISNULL(J.Cnt09,0),  
           DevPgmCnt10 = ISNULL(K.Cnt10,0), 
           DevPgmCnt11 = ISNULL(L.Cnt11,0), 
           DevpgmCnt12 = ISNULL(M.Cnt12,0)  
    
      FROM #Result AS A 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt01
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, -1, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS B 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt02
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = @StdDate 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS C 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt03
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 1, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS D
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt04
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 2, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS E
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt05
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 3, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS F 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt06
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 4, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS G 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt07
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 5, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS H 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt08
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 6, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS I 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt09
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 7, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS J 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt10
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 8, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS K 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt11
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 9, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS L 
      OUTER APPLY ( 
                    SELECT SUM(Cnt) AS Cnt12
                      FROM #BaseData AS Z 
                     WHERE Z.PlanDate = CONVERT(NCHAR(8),DATEADD(DAY, 10, @StdDate),112) 
                       AND Z.DevOrder = A.DevOrder 
                  ) AS M 
                  
     
    SELECT * FROM #Result
    
    
    RETURN 
go
exec KPXCM_SPMDevPgmListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdDate>20150901</StdDate>
    <DevOrder />
    <Module />
    <PgmName />
    <FrPlanDate />
    <ToPlanDate />
    <PgmClass />
    <Consultant />
    <DevName />
    <FrFinDate />
    <ToFinDate />
    <SMIsFinSeq />
    <Remark1 />
    <Remark2 />
    <IsModule>0</IsModule>
    <Remark3 />
    <Remark4 />
    <Remark5 />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032115,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026590