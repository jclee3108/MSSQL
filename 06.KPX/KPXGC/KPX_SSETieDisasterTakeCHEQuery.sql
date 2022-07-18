  
IF OBJECT_ID('KPX_SSETieDisasterTakeCHEQuery') IS NOT NULL   
    DROP PROC KPX_SSETieDisasterTakeCHEQuery  
GO  
  
-- v2014.12.26  
  
-- 무재해운동- 기초데이터 생성 조회 by 이재천   
CREATE PROC KPX_SSETieDisasterTakeCHEQuery  
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
            @YYMM       NCHAR(6) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @YYMM   = ISNULL( YYMM, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (YYMM   NCHAR(6))    
    
    
    CREATE TABLE #Log 
    (
        IDX_NO      INT, 
        Status      INT, 
        WorkingTag  NCHAR(1), 
        YYMM        NCHAR(6) 
    ) 
    INSERT INTO #Log 
    SELECT 1, 0, 'D', @YYMM 
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSETieDisasterTake')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSETieDisasterTake'    , -- 테이블명        
                  '#Log'    , -- 임시 테이블명        
                  'YYMM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
    DELETE A 
      FROM KPX_TSETieDisasterTake AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.YYMM = @YYMM 
    
    
    CREATE TABLE #BaseData 
    (
        WorkDate        NCHAr(8), 
        PlanEmpCnt      DECIMAL(19,5), 
        EmpCnt          DECIMAL(19,5), 
        WorkHour        DECIMAL(19,5), 
        OverHour        DECIMAL(19,5), 
        SumHour         DECIMAL(19,5) 
    ) 
    INSERT INTO #BaseData ( WorkDate, PlanEmpCnt, EmpCnt, WorkHour, OverHour, SumHour ) 
    SELECT Solar AS WorkDate, 
           ISNULL(B.Cnt,0) AS PlanEmpCnt, -- 총근로인원 
           ISNULL(C.Cnt,0) AS EmpCnt, -- 산정기준근로인원 
           ISNULL(C.Cnt,0) * 8 AS WorkHour, -- 근로시간 
           ISNULL(B.DTCnt,0) AS OverHour, -- 연장시간 
           (ISNULL(C.Cnt,0) * 8) + ISNULL(B.DTCnt,0) AS SumHour -- 총근로시간 
           
      FROM _TCOMCalendar AS A 
      OUTER APPLY ( SELECT WorkDate, 
                           COUNT(1) AS Cnt, 
                           SUM(O.DTCnt) AS DTCnt 
                      FROM KPX_THRWorkEmpDaily AS Z 
                      OUTER APPLY (SELECT Y.WkDate, Y.EmpSeq, SUM(Y.DTCnt) AS DTCnt 
                                     FROM _TPRWkEmpDd AS Y 
                                    WHERE Y.CompanySeq = @CompanySeq 
                                      AND Y.WkDate = Z.WorkDate 
                                      AND Y.EmpSeq = Z.EmpSeq 
                                      AND Y.WkItemSeq NOT IN ( SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 17 ) 
                                    GROUP BY Y.WkDate, Y.EmpSeq
                                  ) AS O
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.UMWorkCenterSeq = 1010550001 -- 대산 
                       AND Z.WorkDate = A.Solar 
                     GROUP BY WorkDate 
                   ) AS B 
      OUTER APPLY (SELECT WorkDate, Count(1) AS Cnt 
                     FROM KPX_THRWorkEmpDaily AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.UMWorkCenterSeq = 1010550001 -- 대산 
                      AND Z.WorkDate = A.Solar
                      AND Z.EmpSeq NOT IN ( SELECT EmpSeq 
                                              FROM _TPRWkAbsEmp AS O 
                                              JOIN _TPRWkItem   AS P ON ( P.CompanySeq = @CompanySeq AND P.SMDTCType = 3068001 AND P.WkItemSeq = O.WkItemSeq AND P.IsPaid = '0')
                                             WHERE O.CompanySeq = @CompanySEq 
                                               AND O.AbsDate = Z.WorkDate 
                                               AND O.EmpSeq = Z.EmpSeq 
                                          ) 
                    GROUP BY WorkDate 
                  ) AS C
     WHERE LEFT(A.Solar,4) = LEFT(@YYMM,4) 
     ORDER BY WorkDate 
    
    SELECT A.WorkDate, 
           A.PlanEmpCnt, 
           A.EmpCnt, 
           A.WorkHour, 
           A.OverHour, 
           A.SumHour, 
           
           B.YearWorkHour, 
           B.YearWorkHour2, 
           ISNULL((SELECT DisasterCount FROM KPX_TSETieDisasterTake WHERE CompanySeq = @CompanySeq AND YYMM = LEFT(YYMM,4) + '01'),0) AS DisasterCount, 
           ISNULL((SELECT NonWkCount FROM KPX_TSETieDisasterTake WHERE CompanySeq = @CompanySeq AND YYMM = LEFT(YYMM,4) + '01'),0) AS NonWkCount, 
           ISNULL((SELECT DisasterCount FROM KPX_TSETieDisasterTake WHERE CompanySeq = @CompanySeq AND YYMM = LEFT(YYMM,4) + '01'),0) * B.YearWorkHour * 1000000 AS Result1, 
           ISNULL((SELECT NonWkCount FROM KPX_TSETieDisasterTake WHERE CompanySeq = @CompanySeq AND YYMM = LEFT(YYMM,4) + '01'),0) * B.YearWorkHour2 * 1000 AS Result2 
      FROM #BaseData AS A 
      OUTER APPLY (SELECT LEFT(Z.WorkDate,4) AS WorkYear , SUM(SumHour) AS YearWorkHour, SUM(SumHour) AS YearWorkHour2
                     FROM #BaseData AS Z 
                    WHERE LEFT(Z.WorkDate,4) = LEFT(A.WorkDate,4) 
                      AND LEFT(Z.WorkDate,6) <= @YYMM 
                    GROUP BY LEFT(Z.WorkDate,4) 
                  ) AS B 
    
    
    RETURN  
GO 

exec KPX_SSETieDisasterTakeCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <YYMM>201411</YYMM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021464