IF OBJECT_ID('hencom_SPNCostOfTransportVarSubContQueryNew_AllDept') IS NOT NULL 
    DROP PROC hencom_SPNCostOfTransportVarSubContQueryNew_AllDept 
GO 
-- v2017.05.24
  
-- 사업계획운송비변수등록_hencom-도급비조회 by 이재천
CREATE PROC hencom_SPNCostOfTransportVarSubContQueryNew_AllDept  
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
    
    /*0나누기 에러 경고 처리*/          
    SET ANSI_WARNINGS OFF          
    SET ARITHIGNORE ON          
    SET ARITHABORT OFF

    DECLARE @docHandle  INT, 
            @PlanSeq    INT          
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                     
    
    SELECT @PlanSeq = ISNULL(PlanSeq,0) 
    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags) 
    WITH ( 
            PlanSeq    INT
         )
         
    CREATE TABLE #Result        
    (    
        DeptSeq     INT, 
        Gubun       INT, 
        ColumnA     NVARCHAR(100), 
        ColumnB     NVARCHAR(100), 
        ColumnC     NVARCHAR(100), 
        Sales       DECIMAL(19,5),
        Mth1        DECIMAL(19,5),
        Mth2        DECIMAL(19,5),
        Mth3        DECIMAL(19,5),
        Mth4        DECIMAL(19,5),
        Mth5        DECIMAL(19,5),
        Mth6        DECIMAL(19,5),
        Mth7        DECIMAL(19,5),
        Mth8        DECIMAL(19,5),
        Mth9        DECIMAL(19,5),
        Mth10       DECIMAL(19,5),
        Mth11       DECIMAL(19,5),
        Mth12       DECIMAL(19,5),
        Total       DECIMAL(19,5)
    )
    --전년도 차수중에 확정차수   
    DECLARE @Year NCHAR(4), 
            @PrevCfmPlanSeq INT, 
            @PrevYear NCHAR(4)  
        
    SELECT @Year = PlanYear 
      FROM hencom_TPNPlan    
     WHERE CompanySeq = @CompanySeq    
       AND PlanSeq = @PlanSeq    
  
    SELECT @PrevYear = CONVERT(INT,@Year)-1    
      
    ----전년도 차수중에 확정차수    
    -- SELECT @PrevCfmPlanSeq = PlanSeq     
    -- FROM hencom_TPNPlan WITH(NOLOCK)     
    -- WHERE CompanySeq = @CompanySeq     
    -- AND PlanYear = @PrevYear     
    -- AND IsCfm = '1'     
    




    --생산사업소찾기     
    SELECT A.DeptSeq, A.ProdDeptSeq, B.SlipUnit
      INTO #hencom_TDADeptAdd 
      FROM hencom_TDADeptAdd AS A WITH(NOLOCK)       
      JOIN _TDADept          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsUseReport = '1' 


    INSERT INTO #Result (DeptSeq, Gubun,ColumnA,ColumnB,ColumnC)        
    SELECT A.DeptSeq, B.*
      FROM #hencom_TDADeptAdd AS A 
      JOIN ( 
            SELECT 1 AS Gubun, '도급비' AS ColumnA, '운송비' AS ColumnB, '자차' AS ColumnC
            UNION         
            SELECT 2,'도급비','운송비','용차'        
            UNION         
            SELECT 3,'도급비','유류비','자차'        
            UNION         
            SELECT 4,'도급비','유류비','용차'        
            UNION         
            SELECT 5,'도급비','시간외 운반비','시간외 운반비'        
            UNION         
            SELECT 6,'도급비','회수수 운반비','회수수 운반비'        
            UNION         
            SELECT 7,'도급비','식대','식대'        
            UNION         
            SELECT 8,'도급비','기타','산재'        
            UNION         
            SELECT 9,'도급비','기타','기타'        
            UNION         
            SELECT 10,'도급비','기타','소계'        
            UNION         
            SELECT 11,'도급비','총     계','총     계'         
            UNION         
            SELECT 12,'도급단가(원/㎥)','도급단가(원/㎥)','도급단가(원/㎥)'         
            UNION         
            SELECT 13,'자차단가달성율','자차단가달성율','자차단가달성율'    
          ) AS B ON ( 1 = 1 ) 
     ORDER BY A.DeptSeq, B.Gubun
    
    
    ----------------------------------------------------------------------------
    -- 운송비(자차,용차) 
    ----------------------------------------------------------------------------
    -- 운송단가사업계획 - 월단가 (자차)
    SELECT DISTINCT 
           A.DeptSeq, 
           A.PlanSeq, 
           A.UMDistanceDegree, 
           Price01 AS SelfPrice01,
           Price02 AS SelfPrice02,
           Price03 AS SelfPrice03,
           Price04 AS SelfPrice04,
           Price05 AS SelfPrice05,
           Price06 AS SelfPrice06,
           Price07 AS SelfPrice07,
           Price08 AS SelfPrice08,
           Price09 AS SelfPrice09,
           Price10 AS SelfPrice10,
           Price11 AS SelfPrice11,
           Price12 AS SelfPrice12
      INTO #SelfPrice 
      FROM hencom_TPNPriceOfTransport   AS A 
      JOIN #hencom_TDADeptAdd           AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlanSeq = @PlanSeq
       AND A.UMPriceKind = 1014163001
    
    
    -- 운송단가사업계획 - 월단가 (용차)
    SELECT DISTINCT 
           A.DeptSeq, 
           A.PlanSeq, 
           A.UMDistanceDegree, 
           Price01 AS LentPrice01,
           Price02 AS LentPrice02,
           Price03 AS LentPrice03,
           Price04 AS LentPrice04,
           Price05 AS LentPrice05,
           Price06 AS LentPrice06,
           Price07 AS LentPrice07,
           Price08 AS LentPrice08,
           Price09 AS LentPrice09,
           Price10 AS LentPrice10,
           Price11 AS LentPrice11,
           Price12 AS LentPrice12
      INTO #LentPrice 
      FROM hencom_TPNPriceOfTransport   AS A 
      JOIN #hencom_TDADeptAdd           AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlanSeq = @PlanSeq
       AND A.UMPriceKind = 1014163002
    
    
    -- 판매계획(수량)
    SELECT A.PJTRegSeq ,    
           A.DeptSeq, 
           B.BPYm ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '01' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth1 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '02' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth2 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '03' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth3 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '04' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth4 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '05' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth5 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '06' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth6 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '07' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth7 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '08' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth8 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '09' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth9 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '10' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth10 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '11' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth11 ,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '12' THEN ISNULL(B.SalesQty,0) ELSE 0 END  ) AS Mth12 , 
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '01' THEN ISNULL(D.SelfPrice01,0) ELSE 0 END  ) AS SelfPrice01,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '02' THEN ISNULL(D.SelfPrice02,0) ELSE 0 END  ) AS SelfPrice02,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '03' THEN ISNULL(D.SelfPrice03,0) ELSE 0 END  ) AS SelfPrice03,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '04' THEN ISNULL(D.SelfPrice04,0) ELSE 0 END  ) AS SelfPrice04,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '05' THEN ISNULL(D.SelfPrice05,0) ELSE 0 END  ) AS SelfPrice05,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '06' THEN ISNULL(D.SelfPrice06,0) ELSE 0 END  ) AS SelfPrice06,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '07' THEN ISNULL(D.SelfPrice07,0) ELSE 0 END  ) AS SelfPrice07,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '08' THEN ISNULL(D.SelfPrice08,0) ELSE 0 END  ) AS SelfPrice08,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '09' THEN ISNULL(D.SelfPrice09,0) ELSE 0 END  ) AS SelfPrice09,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '10' THEN ISNULL(D.SelfPrice10,0) ELSE 0 END  ) AS SelfPrice10,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '11' THEN ISNULL(D.SelfPrice11,0) ELSE 0 END  ) AS SelfPrice11,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '12' THEN ISNULL(D.SelfPrice12,0) ELSE 0 END  ) AS SelfPrice12, 
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '01' THEN ISNULL(E.LentPrice01,0) ELSE 0 END  ) AS LentPrice01,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '02' THEN ISNULL(E.LentPrice02,0) ELSE 0 END  ) AS LentPrice02,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '03' THEN ISNULL(E.LentPrice03,0) ELSE 0 END  ) AS LentPrice03,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '04' THEN ISNULL(E.LentPrice04,0) ELSE 0 END  ) AS LentPrice04,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '05' THEN ISNULL(E.LentPrice05,0) ELSE 0 END  ) AS LentPrice05,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '06' THEN ISNULL(E.LentPrice06,0) ELSE 0 END  ) AS LentPrice06,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '07' THEN ISNULL(E.LentPrice07,0) ELSE 0 END  ) AS LentPrice07,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '08' THEN ISNULL(E.LentPrice08,0) ELSE 0 END  ) AS LentPrice08,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '09' THEN ISNULL(E.LentPrice09,0) ELSE 0 END  ) AS LentPrice09,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '10' THEN ISNULL(E.LentPrice10,0) ELSE 0 END  ) AS LentPrice10,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '11' THEN ISNULL(E.LentPrice11,0) ELSE 0 END  ) AS LentPrice11,    
           SUM( CASE WHEN RIGHT(B.BPYm,2) = '12' THEN ISNULL(E.LentPrice12,0) ELSE 0 END  ) AS LentPrice12
      INTO #PlanBaseData 
      FROM hencom_TPNPSalesPlan         AS A 
      JOIN #hencom_TDADeptAdd           AS Q ON ( Q.DeptSeq = A.DeptSeq ) 
      JOIN hencom_TPNPSalesPlanD        AS B ON ( B.CompanySeq = @CompanySeq AND B.PSalesRegSeq = A.PSalesRegSeq ) 
      JOIN hencom_TPNPJT                AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTRegSeq = A.PJTRegSeq ) 
      JOIN #SelfPrice                   AS D ON ( D.DeptSeq = A.DeptSeq AND D.UMDistanceDegree = C.UMDistanceDegree ) 
      JOIN #LentPrice                   AS E ON ( E.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanSeq = @PlanSeq 
       AND ISNULL(A.ItemSeq,0) <> 0
     GROUP BY A.PJTRegSeq, A.DeptSeq, B.BPYm 
    
    
    --select * From #PlanBaseData 
    --return 
    -- 현장, 월별로 나열하기
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth1) AS Qty, 
           MAX(SelfPrice01) AS SelfPrice, 
           MAX(LentPrice01) AS LentPrice
      INTO #QtyPrice
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth2), 
           MAX(SelfPrice02), 
           MAX(LentPrice02)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth3), 
           MAX(SelfPrice03), 
           MAX(LentPrice03)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth4), 
           MAX(SelfPrice04), 
           MAX(LentPrice04)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth5), 
           MAX(SelfPrice05), 
           MAX(LentPrice05) 
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth6), 
           MAX(SelfPrice06), 
           MAX(LentPrice06)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth7), 
           MAX(SelfPrice07), 
           MAX(LentPrice07)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth8), 
           MAX(SelfPrice08), 
           MAX(LentPrice08)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth9), 
           MAX(SelfPrice09), 
           MAX(LentPrice09)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth10), 
           MAX(SelfPrice10), 
           MAX(LentPrice10)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth11), 
           MAX(SelfPrice11), 
           MAX(LentPrice11)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    UNION ALL 
    
    SELECT PJTRegSeq, 
           DeptSeq, 
           BPYm, 
           SUM(Mth12), 
           MAX(SelfPrice12), 
           MAX(LentPrice12)
      FROM #PlanBaseData
     GROUP BY PJTRegSeq, DeptSeq, BPYm
    



    -- 운송비변수등록사업계획화면의 정보
    SELECT A.PJTRegSeq, 
           A.DeptSeq, 
           A.BPYm, 
           A.Qty, 
           A.SelfPrice, 
           A.LentPrice, 
           B.SelfUseRate, 
           B.LentUseRate, 
           B.WaterUseRate, 
           B.MinPreserveRate, 
           B.LentRotation, 
           
           -- 자차 : 판매량 * 자차단가 * ( 1 + 물차사용율 + 소량보존율 ) * 자차비율 
           A.Qty * A.SelfPrice * ( 1 + B.WaterUseRate + B.MinPreserveRate ) * B.SelfUseRate AS SelfAmt, 
           -- 용차 : ( 판매량 * 용차단가 * ( 1 + 물차사용율 + 소량보존율 ) * 용차비율 ) / ( 용차평균회전수 * 6 ) 
           ( A.Qty * A.LentPrice * ( 1 + B.WaterUseRate + B.MinPreserveRate ) * B.LentUseRate ) / ( LentRotation * 6 ) AS LentAmt
      INTO #CarAmt 
      FROM #QtyPrice AS A 
      JOIN (
            SELECT Z.DeptSeq, 
                   Z.PlanSeq, 
                   Z.BpYm, 
                   (100 - Z.LentUseRate) / 100 AS SelfUseRate, 
                   Z.LentUseRate / 100 AS LentUseRate,
                   Z.WaterUseRate / 100 AS WaterUseRate, 
                   Z.MinPreserveRate / 100 AS MinPreserveRate, 
                   Z.LentRotation 
              FROM hencom_TPNCostOfTransportVar AS Z
              WHERE Z.CompanySeq = @CompanySeq  
                AND Z.PlanSeq = @PlanSeq 
           ) AS B ON ( B.DeptSeq = A.DeptSeq AND B.BPYm = A.BPYm ) 
     WHERE A.Qty <> 0 
    






    -- 월별 금액 집계 
    SELECT DeptSeq, RIGHT(BPYm,2) AS YM, SUM(SelfAmt) AS SelfAmt, SUM(LentAmt) AS LentAmt
      INTO #SumCarAmt 
      FROM #CarAmt 
     GROUP BY DeptSeq, BPYm
    


    -- 세로 데이터 가로로 변경 
    SELECT DeptSeq, 
           B.[01] AS SelfAmt01, B.[02] AS SelfAmt02, B.[03] AS SelfAmt03, B.[04] AS SelfAmt04, B.[05] AS SelfAmt05, B.[06] AS SelfAmt06, 
           B.[07] AS SelfAmt07, B.[08] AS SelfAmt08, B.[09] AS SelfAmt09, B.[10] AS SelfAmt10, B.[11] AS SelfAmt11, B.[12] AS SelfAmt12
      INTO #SelfAmt 
      FROM ( SELECT * FROM #SumCarAmt ) AS A 
      PIVOT (MAX(SelfAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 

    SELECT DeptSeq, 
           B.[01] AS LentAmt01, B.[02] AS LentAmt02, B.[03] AS LentAmt03, B.[04] AS LentAmt04, B.[05] AS LentAmt05, B.[06] AS LentAmt06, 
           B.[07] AS LentAmt07, B.[08] AS LentAmt08, B.[09] AS LentAmt09, B.[10] AS LentAmt10, B.[11] AS LentAmt11, B.[12] AS LentAmt12
      INTO #LentAmt
      FROM ( SELECT * FROM #SumCarAmt ) AS A 
      PIVOT (MAX(LentAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    

    -- 결과테이블에 반영 
    UPDATE A
       SET Mth1    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt01,0) ELSE ISNULL(C.LentAmt01,0) END,  
           Mth2    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt02,0) ELSE ISNULL(C.LentAmt02,0) END,  
           Mth3    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt03,0) ELSE ISNULL(C.LentAmt03,0) END,    
           Mth4    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt04,0) ELSE ISNULL(C.LentAmt04,0) END,    
           Mth5    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt05,0) ELSE ISNULL(C.LentAmt05,0) END,    
           Mth6    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt06,0) ELSE ISNULL(C.LentAmt06,0) END,    
           Mth7    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt07,0) ELSE ISNULL(C.LentAmt07,0) END,    
           Mth8    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt08,0) ELSE ISNULL(C.LentAmt08,0) END,    
           Mth9    = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt09,0) ELSE ISNULL(C.LentAmt09,0) END,    
           Mth10   = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt10,0) ELSE ISNULL(C.LentAmt10,0) END,    
           Mth11   = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt11,0) ELSE ISNULL(C.LentAmt11,0) END,    
           Mth12   = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt12,0) ELSE ISNULL(C.LentAmt12,0) END, 
           
           Total   = CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt01,0) ELSE ISNULL(C.LentAmt01,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt02,0) ELSE ISNULL(C.LentAmt02,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt03,0) ELSE ISNULL(C.LentAmt03,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt04,0) ELSE ISNULL(C.LentAmt04,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt05,0) ELSE ISNULL(C.LentAmt05,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt06,0) ELSE ISNULL(C.LentAmt06,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt07,0) ELSE ISNULL(C.LentAmt07,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt08,0) ELSE ISNULL(C.LentAmt08,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt09,0) ELSE ISNULL(C.LentAmt09,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt10,0) ELSE ISNULL(C.LentAmt10,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt11,0) ELSE ISNULL(C.LentAmt11,0) END +
                     CASE WHEN A.Gubun = 1 THEN ISNULL(B.SelfAmt12,0) ELSE ISNULL(C.LentAmt12,0) END
      FROM #Result AS A 
      LEFT OUTER JOIN #SelfAmt AS B ON ( B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #LentAmt AS C ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun IN ( 1 , 2 ) 
    ----------------------------------------------------------------------------
    -- 운송비(자차,용차), END 
    ----------------------------------------------------------------------------

  
    ----------------------------------------------------------------------------
    -- 유류비(자차,용차)
    ----------------------------------------------------------------------------
    
    -- 평균운반거리(자차)
    SELECT A.DeptSeq, 
           A.BPYm, 
           SUM(A.Qty * ( B.ShuttleDistance / 2 )) / SUM(Qty) AS SelfAvgKm
      INTO #TotalKm
      FROM #QtyPrice        AS A 
      JOIN hencom_TPNPJT    AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTRegSeq = A.PJTRegSeq ) 
     WHERE A.Qty <> 0 
     GROUP BY A.DeptSeq, A.BPYm
    
    DECLARE @StdYear NCHAR(4) 
    SELECT @StdYear = PlanYear 
      FROM hencom_TPNPlan    
     WHERE CompanySeq = @CompanySeq    
       AND PlanSeq = @PlanSeq    
    

    
    -- 사업소별 월담기
    SELECT A.DeptSeq, B.BPYm 
      INTO #DeptBPYM
      FROM #hencom_TDADeptAdd AS A 
      JOIN (
            SELECT @StdYear + '01' AS BPYm
            UNION  
            SELECT @StdYear + '02' AS BPYm
            UNION  
            SELECT @StdYear + '03' AS BPYm
            UNION  
            SELECT @StdYear + '04' AS BPYm
            UNION  
            SELECT @StdYear + '05' AS BPYm
            UNION  
            SELECT @StdYear + '06' AS BPYm
            UNION  
            SELECT @StdYear + '07' AS BPYm
            UNION  
            SELECT @StdYear + '08' AS BPYm
            UNION  
            SELECT @StdYear + '09' AS BPYm
            UNION  
            SELECT @StdYear + '10' AS BPYm
            UNION  
            SELECT @StdYear + '11' AS BPYm
            UNION  
            SELECT @StdYear + '12' AS BPYm
          ) AS B ON ( 1 = 1 ) 
     ORDER BY DeptSeq, BPYm 


    -- 경유 단가 
    SELECT A.DeptSeq, 
           A.BPYm, 
           CASE WHEN RIGHT(A.BPYm,2) = '01' THEN B.Price01 
                WHEN RIGHT(A.BPYm,2) = '02' THEN B.Price02
                WHEN RIGHT(A.BPYm,2) = '03' THEN B.Price03
                WHEN RIGHT(A.BPYm,2) = '04' THEN B.Price04
                WHEN RIGHT(A.BPYm,2) = '05' THEN B.Price05
                WHEN RIGHT(A.BPYm,2) = '06' THEN B.Price06
                WHEN RIGHT(A.BPYm,2) = '07' THEN B.Price07
                WHEN RIGHT(A.BPYm,2) = '08' THEN B.Price08
                WHEN RIGHT(A.BPYm,2) = '09' THEN B.Price09
                WHEN RIGHT(A.BPYm,2) = '10' THEN B.Price10
                WHEN RIGHT(A.BPYm,2) = '11' THEN B.Price11
                WHEN RIGHT(A.BPYm,2) = '12' THEN B.Price12
                END AS OilPrice
      INTO #OilPirce
      FROM #DeptBPYM AS A 
      JOIN ( 
            SELECT Z.*
              FROM hencom_TPNOilPrice AS Z 
              JOIN #hencom_TDADeptAdd AS Y ON ( Y.DeptSeq = Z.DeptSeq ) 
              JOIN ( SELECT DeptSeq, MAX(OilPriceRegSeq) AS OilPriceRegSeq
                       FROM hencom_TPNOilPrice 
                      WHERE CompanySeq = @CompanySeq 
                        AND PlanSeq = @PlanSeq 
                        AND UMOilKind = 20031002
                      GROUP BY DeptSeq
                   ) AS Q ON ( Q.OilPriceRegSeq = Z.OilPriceRegSeq ) -- 2건이 등록되어도 한건만 나오도록 적용 
             WHERE Z.CompanySeq = @CompanySeq  
               AND Z.PlanSeq = @PlanSeq 
               AND Z.UMOilKind = 20031002 
           ) AS B ON ( B.DeptSeq = A.DeptSeq ) 
    


    --select * from #QtyPrice
    --select * from #TotalKm 


    --return 


    SELECT A.PJTRegSeq, 
           A.DeptSeq, 
           A.BPYm, 
           A.Qty, 
           B.SelfAvgKm, 
           C.WaterUseRate, 
           C.MinPreserveRate, 
           D.OilPrice, 
           C.OilAid, 
           C.OwnMilege,  
           C.LentMilege, 
           C.SelfUseRate, 
           C.LentUseRate,
           C.LentAvgAmt AS LentAvgAmt,
           -- 자차 : ( ( 출하수량 * 평균운반거리(자차) ) * 2 * ( 1 + 물차사용율 + 소량보전율 ) ) / 6 * ( 경유단가 - 유가보조 ) * 연비(자차) * ( 1 - 용차사용율 )  
           ( ( A.Qty * B.SelfAvgKm ) * 2 * ( 1 + C.WaterUseRate + C.MinPreserveRate ) ) / 6 * ( D.OilPrice - C.OilAid ) * C.OwnMilege * C.SelfUseRate AS SelfOilAmt, 
           -- 용차 : ( ( 출하수량 * 평균운반거리(용차) ) * 2 * ( 1 + 물차사용율 + 소량보전율 ) ) / 6 * 용차사용율 * 경유단가 * 용차연비
           ( ( A.Qty * C.LentAvgAmt ) * 2 * ( 1 + C.WaterUseRate + C.MinPreserveRate ) ) / 6 * C.LentUseRate * D.OilPrice * C.LentMilege AS LentOilAmt
      INTO #OilAmt
      FROM #QtyPrice    AS A 
      JOIN #TotalKm     AS B ON ( B.DeptSeq = A.DeptSeq AND B.BPYm = A.BPYm ) 
      JOIN (
            SELECT Z.PlanSeq, 
                   Z.DeptSeq, 
                   Z.BpYm, 
                   (100 - Z.LentUseRate) / 100 AS SelfUseRate, 
                   Z.LentUseRate / 100 AS LentUseRate,
                   Z.WaterUseRate / 100 AS WaterUseRate, 
                   Z.MinPreserveRate / 100 AS MinPreserveRate, 
                   Z.LentRotation, 
                   Z.OilAid, 
                   Z.OwnMilege, 
                   Z.LentMilege, 
                   ISNULL(Z.LentAvgAmt,0) AS LentAvgAmt
              FROM hencom_TPNCostOfTransportVar AS Z
              WHERE Z.CompanySeq = @CompanySeq  
                AND Z.PlanSeq = @PlanSeq 
           ) AS C ON ( C.DeptSeq = A.DeptSeq AND C.BPYm = A.BPYm ) 
      JOIN #OilPirce AS D ON ( D.DeptSeq = A.DeptSeq AND D.BPYm = A.BPYm ) 
     WHERE A.Qty <> 0 
     ORDER BY DeptSeq, PJTRegSeq, BPYm 
    
    -- 월별 금액 집계 
    SELECT DeptSeq, RIGHT(BPYm,2) AS YM, SUM(SelfOilAmt) AS SelfAmt, SUM(LentOilAmt) AS LentAmt
      INTO #SumOilAmt 
      FROM #OilAmt 
     GROUP BY DeptSeq, BPYm
     ORDER BY DeptSeq, BPYm


    -- 세로 데이터 가로로 변경 
    SELECT DeptSeq, 
           B.[01] AS SelfOilAmt01, B.[02] AS SelfOilAmt02, B.[03] AS SelfOilAmt03, B.[04] AS SelfOilAmt04, B.[05] AS SelfOilAmt05, B.[06] AS SelfOilAmt06, 
           B.[07] AS SelfOilAmt07, B.[08] AS SelfOilAmt08, B.[09] AS SelfOilAmt09, B.[10] AS SelfOilAmt10, B.[11] AS SelfOilAmt11, B.[12] AS SelfOilAmt12
      INTO #SelfOilAmt
      FROM ( SELECT * FROM #SumOilAmt ) AS A 
      PIVOT (MAX(SelfAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    
    SELECT DeptSeq, 
           B.[01] AS LentOilAmt01, B.[02] AS LentOilAmt02, B.[03] AS LentOilAmt03, B.[04] AS LentOilAmt04, B.[05] AS LentOilAmt05, B.[06] AS LentOilAmt06, 
           B.[07] AS LentOilAmt07, B.[08] AS LentOilAmt08, B.[09] AS LentOilAmt09, B.[10] AS LentOilAmt10, B.[11] AS LentOilAmt11, B.[12] AS LentOilAmt12
      INTO #LentOilAmt
      FROM ( SELECT * FROM #SumOilAmt ) AS A 
      PIVOT (MAX(LentAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    
    
    -- 결과테이블에 반영 
    UPDATE A
       SET Mth1    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt01,0) ELSE ISNULL(C.LentOilAmt01,0) END,  
           Mth2    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt02,0) ELSE ISNULL(C.LentOilAmt02,0) END,  
           Mth3    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt03,0) ELSE ISNULL(C.LentOilAmt03,0) END,    
           Mth4    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt04,0) ELSE ISNULL(C.LentOilAmt04,0) END,    
           Mth5    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt05,0) ELSE ISNULL(C.LentOilAmt05,0) END,    
           Mth6    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt06,0) ELSE ISNULL(C.LentOilAmt06,0) END,    
           Mth7    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt07,0) ELSE ISNULL(C.LentOilAmt07,0) END,    
           Mth8    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt08,0) ELSE ISNULL(C.LentOilAmt08,0) END,    
           Mth9    = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt09,0) ELSE ISNULL(C.LentOilAmt09,0) END,    
           Mth10   = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt10,0) ELSE ISNULL(C.LentOilAmt10,0) END,    
           Mth11   = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt11,0) ELSE ISNULL(C.LentOilAmt11,0) END,    
           Mth12   = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt12,0) ELSE ISNULL(C.LentOilAmt12,0) END, 
                                                                                           
           Total   = CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt01,0) ELSE ISNULL(C.LentOilAmt01,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt02,0) ELSE ISNULL(C.LentOilAmt02,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt03,0) ELSE ISNULL(C.LentOilAmt03,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt04,0) ELSE ISNULL(C.LentOilAmt04,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt05,0) ELSE ISNULL(C.LentOilAmt05,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt06,0) ELSE ISNULL(C.LentOilAmt06,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt07,0) ELSE ISNULL(C.LentOilAmt07,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt08,0) ELSE ISNULL(C.LentOilAmt08,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt09,0) ELSE ISNULL(C.LentOilAmt09,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt10,0) ELSE ISNULL(C.LentOilAmt10,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt11,0) ELSE ISNULL(C.LentOilAmt11,0) END +
                     CASE WHEN A.Gubun = 3 THEN ISNULL(B.SelfOilAmt12,0) ELSE ISNULL(C.LentOilAmt12,0) END
      FROM #Result AS A 
      LEFT OUTER JOIN #SelfOilAmt AS B ON ( B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #LentOilAmt AS C ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun IN ( 3 , 4 ) 
    ----------------------------------------------------------------------------
    -- 유류비(자차,용차), END 
    ----------------------------------------------------------------------------


    ----------------------------------------------------------------------------
    -- 시간외 운반비
    ----------------------------------------------------------------------------
        SELECT A.DeptSeq, 
               A.BPYm, 
               CASE WHEN RIGHT(A.BPYm,2) = '01' THEN B.Price01 
                    WHEN RIGHT(A.BPYm,2) = '02' THEN B.Price02
                    WHEN RIGHT(A.BPYm,2) = '03' THEN B.Price03
                    WHEN RIGHT(A.BPYm,2) = '04' THEN B.Price04
                    WHEN RIGHT(A.BPYm,2) = '05' THEN B.Price05
                    WHEN RIGHT(A.BPYm,2) = '06' THEN B.Price06
                    WHEN RIGHT(A.BPYm,2) = '07' THEN B.Price07
                    WHEN RIGHT(A.BPYm,2) = '08' THEN B.Price08
                    WHEN RIGHT(A.BPYm,2) = '09' THEN B.Price09
                    WHEN RIGHT(A.BPYm,2) = '10' THEN B.Price10
                    WHEN RIGHT(A.BPYm,2) = '11' THEN B.Price11
                    WHEN RIGHT(A.BPYm,2) = '12' THEN B.Price12
                    END AS AddTimePirce1, 
               CASE WHEN RIGHT(A.BPYm,2) = '01' THEN C.Price01 
                    WHEN RIGHT(A.BPYm,2) = '02' THEN C.Price02
                    WHEN RIGHT(A.BPYm,2) = '03' THEN C.Price03
                    WHEN RIGHT(A.BPYm,2) = '04' THEN C.Price04
                    WHEN RIGHT(A.BPYm,2) = '05' THEN C.Price05
                    WHEN RIGHT(A.BPYm,2) = '06' THEN C.Price06
                    WHEN RIGHT(A.BPYm,2) = '07' THEN C.Price07
                    WHEN RIGHT(A.BPYm,2) = '08' THEN C.Price08
                    WHEN RIGHT(A.BPYm,2) = '09' THEN C.Price09
                    WHEN RIGHT(A.BPYm,2) = '10' THEN C.Price10
                    WHEN RIGHT(A.BPYm,2) = '11' THEN C.Price11
                    WHEN RIGHT(A.BPYm,2) = '12' THEN C.Price12
                    END AS AddTimePirce2
      INTO #AddTimePrice
      FROM #DeptBPYM AS A 
      JOIN ( 
            SELECT Z.*
              FROM hencom_TPNPriceOfTransport AS Z 
              JOIN ( SELECT DeptSeq, MAX(POTRegSeq) AS POTRegSeq
                       FROM hencom_TPNPriceOfTransport 
                      WHERE CompanySeq = @CompanySeq 
                        AND PlanSeq = @PlanSeq 
                        AND UMPriceKind = 1014163003
                      GROUP BY DeptSeq
                   ) AS Q ON ( Q.POTRegSeq = Z.POTRegSeq ) -- 2건이 등록되어도 한건만 나오도록 적용 
             WHERE Z.CompanySeq = @CompanySeq  
               AND Z.PlanSeq = @PlanSeq 
               AND Z.UMPriceKind = 1014163003 
           ) AS B ON ( B.DeptSeq = A.DeptSeq ) 
      JOIN ( 
            SELECT Z.*
              FROM hencom_TPNPriceOfTransport AS Z 
              JOIN ( SELECT DeptSeq, MAX(POTRegSeq) AS POTRegSeq
                       FROM hencom_TPNPriceOfTransport 
                      WHERE CompanySeq = @CompanySeq 
                        AND PlanSeq = @PlanSeq 
                        AND UMPriceKind = 1014163004
                      GROUP BY DeptSeq
                   ) AS Q ON ( Q.POTRegSeq = Z.POTRegSeq ) -- 2건이 등록되어도 한건만 나오도록 적용 
             WHERE Z.CompanySeq = @CompanySeq  
               AND Z.PlanSeq = @PlanSeq 
               AND Z.UMPriceKind = 1014163004 
           ) AS C ON ( C.DeptSeq = A.DeptSeq ) 
    



    --hencom_TPNPriceOfTransport
    --select *from _TDAUMinor where majorseq = 1014163
    --select * from #AddTimePrice 
    
    SELECT A.DeptSeq, 
           A.PJTRegSeq, 
           A.BPYm,
           A.Qty, 
           B.AddTimePirce1, 
           B.AddTimePirce2, 
           C.OwnOTRate, 
           C.OwnOTMNRate, 
           -- 시간외 운반비 : 판매량 * ( (자차시간외사용율 * 시간외단가) + (자차시간외사용율(심야) * 시간외단가(심야)) ) / 6 
           A.Qty * ( ( C.OwnOTRate * AddTimePirce1 ) + ( C.OwnOTMNRate * B.AddTimePirce2 ) ) / 6 AS OTAmt
      INTO #OTAmt
      FROM #QtyPrice        AS A 
      JOIN #AddTimePrice    AS B ON ( B.DeptSeq = A.DeptSeq AND B.BPYm = A.BPYm ) 
      JOIN (
            SELECT Z.DeptSeq, 
                   Z.PlanSeq, 
                   Z.BpYm, 
                   Z.OwnOTRate / 100 AS OwnOTRate, 
                   Z.OwnOTMNRate / 100 AS OwnOTMNRate
              FROM hencom_TPNCostOfTransportVar AS Z
              WHERE Z.CompanySeq = @CompanySeq  
                AND Z.PlanSeq = @PlanSeq 
           ) AS C ON ( C.DeptSeq = A.DeptSeq AND C.BPYm = A.BPYm ) 
     WHERE A.Qty <> 0 
     ORDER BY A.DeptSeq, A.BPYm 
    



    -- 월별 금액 집계 
    SELECT DeptSeq, RIGHT(BPYm,2) AS YM, SUM(OTAmt) AS OTAmt 
      INTO #SumOTAmt 
      FROM #OTAmt 
     GROUP BY DeptSeq, BPYm
    
    SELECT DeptSeq, 
           B.[01] AS OTAmt01, B.[02] AS OTAmt02, B.[03] AS OTAmt03, B.[04] AS OTAmt04, B.[05] AS OTAmt05, B.[06] AS OTAmt06, 
           B.[07] AS OTAmt07, B.[08] AS OTAmt08, B.[09] AS OTAmt09, B.[10] AS OTAmt10, B.[11] AS OTAmt11, B.[12] AS OTAmt12
      INTO #OT
      FROM ( SELECT * FROM #SumOTAmt ) AS A 
      PIVOT (MAX(OtAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    
    
    --select * from #OT 
    -- 결과테이블에 반영 
    UPDATE A
       SET Mth1    = ISNULL(B.OTAmt01,0),  
           Mth2    = ISNULL(B.OTAmt02,0),  
           Mth3    = ISNULL(B.OTAmt03,0),    
           Mth4    = ISNULL(B.OTAmt04,0),    
           Mth5    = ISNULL(B.OTAmt05,0),    
           Mth6    = ISNULL(B.OTAmt06,0),    
           Mth7    = ISNULL(B.OTAmt07,0),    
           Mth8    = ISNULL(B.OTAmt08,0),    
           Mth9    = ISNULL(B.OTAmt09,0),    
           Mth10   = ISNULL(B.OTAmt10,0),    
           Mth11   = ISNULL(B.OTAmt11,0),    
           Mth12   = ISNULL(B.OTAmt12,0), 
                                                                                           
           Total   = ISNULL(B.OTAmt01,0) +
                     ISNULL(B.OTAmt02,0) +
                     ISNULL(B.OTAmt03,0) +
                     ISNULL(B.OTAmt04,0) +
                     ISNULL(B.OTAmt05,0) +
                     ISNULL(B.OTAmt06,0) +
                     ISNULL(B.OTAmt07,0) +
                     ISNULL(B.OTAmt08,0) +
                     ISNULL(B.OTAmt09,0) +
                     ISNULL(B.OTAmt10,0) +
                     ISNULL(B.OTAmt11,0) +
                     ISNULL(B.OTAmt12,0)
      FROM #Result AS A 
      LEFT OUTER JOIN #OT AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun = 5 
    ----------------------------------------------------------------------------
    -- 시간외 운반비, END 
    ----------------------------------------------------------------------------




    ----------------------------------------------------------------------------
    -- 회수수 운반비
    ----------------------------------------------------------------------------
        SELECT A.DeptSeq, 
               A.BPYm, 
               CASE WHEN RIGHT(A.BPYm,2) = '01' THEN B.Price01 
                    WHEN RIGHT(A.BPYm,2) = '02' THEN B.Price02
                    WHEN RIGHT(A.BPYm,2) = '03' THEN B.Price03
                    WHEN RIGHT(A.BPYm,2) = '04' THEN B.Price04
                    WHEN RIGHT(A.BPYm,2) = '05' THEN B.Price05
                    WHEN RIGHT(A.BPYm,2) = '06' THEN B.Price06
                    WHEN RIGHT(A.BPYm,2) = '07' THEN B.Price07
                    WHEN RIGHT(A.BPYm,2) = '08' THEN B.Price08
                    WHEN RIGHT(A.BPYm,2) = '09' THEN B.Price09
                    WHEN RIGHT(A.BPYm,2) = '10' THEN B.Price10
                    WHEN RIGHT(A.BPYm,2) = '11' THEN B.Price11
                    WHEN RIGHT(A.BPYm,2) = '12' THEN B.Price12
                    END AS ReturnPrice
      INTO #ReturnPrice
      FROM #DeptBPYM AS A 
      JOIN ( 
            SELECT Z.*
              FROM hencom_TPNPriceOfTransport AS Z 
              JOIN ( SELECT DeptSeq, MAX(POTRegSeq) AS POTRegSeq
                       FROM hencom_TPNPriceOfTransport 
                      WHERE CompanySeq = @CompanySeq 
                        AND PlanSeq = @PlanSeq 
                        AND UMPriceKind = 1014163005
                      GROUP BY DeptSeq
                   ) AS Q ON ( Q.POTRegSeq = Z.POTRegSeq ) -- 2건이 등록되어도 한건만 나오도록 적용 
             WHERE Z.CompanySeq = @CompanySeq  
               AND Z.PlanSeq = @PlanSeq 
               AND Z.UMPriceKind = 1014163005 
           ) AS B ON ( B.DeptSeq = A.DeptSeq ) 
    



    --hencom_TPNPriceOfTransport
    --select *from _TDAUMinor where majorseq = 1014163
    --select * from #AddTimePrice 
    SELECT A.DeptSeq, 
           A.PJTRegSeq, 
           A.BPYm,
           A.Qty, 
           B.ReturnPrice, 
           C.OwnReturnRate, 
           -- 회수수 운반비 : 판매량 * 자차회수수 사용율 * 단가 /6
           (A.Qty * C.OwnReturnRate * B.ReturnPrice) / 6 AS ReturnAmt
      INTO #ReturnAmt
      FROM #QtyPrice        AS A 
      JOIN #ReturnPrice    AS B ON ( B.DeptSeq = A.DeptSeq AND B.BPYm = A.BPYm ) 
      JOIN (
            SELECT Z.DeptSeq, 
                   Z.PlanSeq, 
                   Z.BpYm, 
                   Z.OwnReturnRate / 100 AS OwnReturnRate
              FROM hencom_TPNCostOfTransportVar AS Z
              WHERE Z.CompanySeq = @CompanySeq  
                AND Z.PlanSeq = @PlanSeq 
           ) AS C ON ( C.DeptSeq = A.DeptSeq AND C.BPYm = A.BPYm ) 
     WHERE A.Qty <> 0
    
    -- 월별 금액 집계 
    SELECT DeptSeq, RIGHT(BPYm,2) AS YM, SUM(ReturnAmt) AS ReturnAmt 
      INTO #SumReturnAmt 
      FROM #ReturnAmt 
     GROUP BY DeptSeq, BPYm 
    
    SELECT DeptSeq, 
           B.[01] AS ReturnAmt01, B.[02] AS ReturnAmt02, B.[03] AS ReturnAmt03, B.[04] AS ReturnAmt04, B.[05] AS ReturnAmt05, B.[06] AS ReturnAmt06, 
           B.[07] AS ReturnAmt07, B.[08] AS ReturnAmt08, B.[09] AS ReturnAmt09, B.[10] AS ReturnAmt10, B.[11] AS ReturnAmt11, B.[12] AS ReturnAmt12
      INTO #Return
      FROM ( SELECT * FROM #SumReturnAmt ) AS A 
      PIVOT (MAX(ReturnAmt)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    



    
    --select * from #OT 
    -- 결과테이블에 반영 
    UPDATE A
       SET Mth1    = ISNULL(B.ReturnAmt01,0),  
           Mth2    = ISNULL(B.ReturnAmt02,0),  
           Mth3    = ISNULL(B.ReturnAmt03,0),    
           Mth4    = ISNULL(B.ReturnAmt04,0),    
           Mth5    = ISNULL(B.ReturnAmt05,0),    
           Mth6    = ISNULL(B.ReturnAmt06,0),    
           Mth7    = ISNULL(B.ReturnAmt07,0),    
           Mth8    = ISNULL(B.ReturnAmt08,0),    
           Mth9    = ISNULL(B.ReturnAmt09,0),    
           Mth10   = ISNULL(B.ReturnAmt10,0),    
           Mth11   = ISNULL(B.ReturnAmt11,0),    
           Mth12   = ISNULL(B.ReturnAmt12,0), 
                                      
           Total   = ISNULL(B.ReturnAmt01,0) +
                     ISNULL(B.ReturnAmt02,0) +
                     ISNULL(B.ReturnAmt03,0) +
                     ISNULL(B.ReturnAmt04,0) +
                     ISNULL(B.ReturnAmt05,0) +
                     ISNULL(B.ReturnAmt06,0) +
                     ISNULL(B.ReturnAmt07,0) +
                     ISNULL(B.ReturnAmt08,0) +
                     ISNULL(B.ReturnAmt09,0) +
                     ISNULL(B.ReturnAmt10,0) +
                     ISNULL(B.ReturnAmt11,0) +
                     ISNULL(B.ReturnAmt12,0)
      FROM #Result AS A 
      LEFT OUTER JOIN #Return AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun = 6 
    ----------------------------------------------------------------------------
    -- 회수수 운반비,END
    ----------------------------------------------------------------------------


    ----------------------------------------------------------------------------
    -- 식대, 기타(산재,기타,소계)
    ----------------------------------------------------------------------------
    SELECT DeptSeq, RIGHT(A.BPYm,2) AS YM, SUM(A.PayforMeal) AS PayforMeal, SUM(A.IndusAccidInsur) AS IndusAccidInsur, SUM(A.EtcCost) AS EtcCost
      INTO #SumEtc 
      FROM hencom_TPNCostOfTransportVar AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PlanSeq = @PlanSeq 
     GROUP BY DeptSeq, RIGHT(A.BPYm,2) 
    

    SELECT DeptSeq, 
           B.[01] AS PayforMeal01, B.[02] AS PayforMeal02, B.[03] AS PayforMeal03, B.[04] AS PayforMeal04, B.[05] AS PayforMeal05, B.[06] AS PayforMeal06, 
           B.[07] AS PayforMeal07, B.[08] AS PayforMeal08, B.[09] AS PayforMeal09, B.[10] AS PayforMeal10, B.[11] AS PayforMeal11, B.[12] AS PayforMeal12
      INTO #PayforMeal
      FROM ( SELECT * FROM #SumEtc ) AS A 
      PIVOT (MAX(PayforMeal)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    

    SELECT DeptSeq, 
           B.[01] AS IndusAccidInsur01, B.[02] AS IndusAccidInsur02, B.[03] AS IndusAccidInsur03, B.[04] AS IndusAccidInsur04, B.[05] AS IndusAccidInsur05, B.[06] AS IndusAccidInsur06, 
           B.[07] AS IndusAccidInsur07, B.[08] AS IndusAccidInsur08, B.[09] AS IndusAccidInsur09, B.[10] AS IndusAccidInsur10, B.[11] AS IndusAccidInsur11, B.[12] AS IndusAccidInsur12
      INTO #IndusAccidInsur
      FROM ( SELECT * FROM #SumEtc ) AS A 
      PIVOT (MAX(IndusAccidInsur)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    

    SELECT DeptSeq, 
           B.[01] AS EtcCost01, B.[02] AS EtcCost02, B.[03] AS EtcCost03, B.[04] AS EtcCost04, B.[05] AS EtcCost05, B.[06] AS EtcCost06, 
           B.[07] AS EtcCost07, B.[08] AS EtcCost08, B.[09] AS EtcCost09, B.[10] AS EtcCost10, B.[11] AS EtcCost11, B.[12] AS EtcCost12
      INTO #EtcCost
      FROM ( SELECT * FROM #SumEtc ) AS A 
      PIVOT (MAX(EtcCost)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    

    -- 결과테이블에 반영 
    UPDATE A
       SET Mth1    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal01,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur01,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost01,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur01,0) + ISNULL(D.EtcCost01,0) 
                          END,
           Mth2    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal02,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur02,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost02,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur02,0) + ISNULL(D.EtcCost02,0) 
                          END,  
           Mth3    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal03,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur03,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost03,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur03,0) + ISNULL(D.EtcCost03,0) 
                          END,  
           Mth4    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal04,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur04,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost04,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur04,0) + ISNULL(D.EtcCost04,0) 
                          END,  
           Mth5    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal05,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur05,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost05,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur05,0) + ISNULL(D.EtcCost05,0) 
                          END,  
           Mth6    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal06,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur06,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost06,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur06,0) + ISNULL(D.EtcCost06,0) 
                          END,  
           Mth7    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal07,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur07,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost07,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur07,0) + ISNULL(D.EtcCost07,0) 
                          END,  
           Mth8    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal08,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur08,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost08,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur08,0) + ISNULL(D.EtcCost08,0) 
                          END,  
           Mth9    = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal09,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur09,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost09,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur09,0) + ISNULL(D.EtcCost09,0) 
                          END,  
           Mth10   = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal10,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur10,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost10,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur10,0) + ISNULL(D.EtcCost10,0) 
                          END,  
           Mth11   = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal11,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur11,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost11,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur11,0) + ISNULL(D.EtcCost11,0) 
                          END,  
           Mth12   = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal12,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur12,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost12,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur12,0) + ISNULL(D.EtcCost12,0) 
                          END,  
                                                                                           
           Total   = CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal01,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur01,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost01,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur01,0) + ISNULL(D.EtcCost01,0)
                          END +
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal02,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur02,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost02,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur02,0) + ISNULL(D.EtcCost02,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal03,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur03,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost03,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur03,0) + ISNULL(D.EtcCost03,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal04,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur04,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost04,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur04,0) + ISNULL(D.EtcCost04,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal05,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur05,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost05,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur05,0) + ISNULL(D.EtcCost05,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal06,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur06,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost06,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur06,0) + ISNULL(D.EtcCost06,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal07,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur07,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost07,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur07,0) + ISNULL(D.EtcCost07,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal08,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur08,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost08,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur08,0) + ISNULL(D.EtcCost08,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal09,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur09,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost09,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur09,0) + ISNULL(D.EtcCost09,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal10,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur10,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost10,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur10,0) + ISNULL(D.EtcCost10,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal11,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur11,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost11,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur11,0) + ISNULL(D.EtcCost11,0)
                          END +  
                     CASE WHEN A.Gubun = 7 THEN ISNULL(B.PayforMeal12,0) 
                          WHEN A.Gubun = 8 THEN ISNULL(C.IndusAccidInsur12,0) 
                          WHEN A.Gubun = 9 THEN ISNULL(D.EtcCost12,0) 
                          WHEN A.Gubun = 10 THEN ISNULL(C.IndusAccidInsur12,0) + ISNULL(D.EtcCost12,0)
                          END   
      FROM #Result AS A 
      LEFT OUTER JOIN #PayforMeal       AS B ON ( B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #IndusAccidInsur  AS C ON ( C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #EtcCost          AS D ON ( D.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun IN ( 7 , 8, 9, 10 ) 
    ----------------------------------------------------------------------------
    -- 식대, 기타(산재,기타,소계), END 
    ----------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------
    -- 총계
    ----------------------------------------------------------------------------
    UPDATE A
       SET Mth1  = B.Mth1 ,
           Mth2  = B.Mth2 ,
           Mth3  = B.Mth3 ,
           Mth4  = B.Mth4 ,
           Mth5  = B.Mth5 ,
           Mth6  = B.Mth6 ,
           Mth7  = B.Mth7 ,
           Mth8  = B.Mth8 ,
           Mth9  = B.Mth9 ,
           Mth10 = B.Mth10,
           Mth11 = B.Mth11,
           Mth12 = B.Mth12, 
           Total = B.Total
      FROM #Result AS A 
      JOIN ( 
            SELECT DeptSeq, 
                   11 AS Gubun,
                   SUM(ROUND(Mth1,0)) AS Mth1, 
                   SUM(ROUND(Mth2,0)) AS Mth2, 
                   SUM(ROUND(Mth3,0)) AS Mth3, 
                   SUM(ROUND(Mth4,0)) AS Mth4, 
                   SUM(ROUND(Mth5,0)) AS Mth5, 
                   SUM(ROUND(Mth6,0)) AS Mth6, 
                   SUM(ROUND(Mth7,0)) AS Mth7, 
                   SUM(ROUND(Mth8,0)) AS Mth8, 
                   SUM(ROUND(Mth9,0)) AS Mth9, 
                   SUM(ROUND(Mth10,0)) AS Mth10, 
                   SUM(ROUND(Mth11,0)) AS Mth11, 
                   SUM(ROUND(Mth12,0)) AS Mth12, 
                   SUM(ROUND(Total,0)) AS Total
              FROM #Result 
             WHERE Gubun BETWEEN 1 AND 9 
             GROUP BY DeptSeq 
           ) AS B ON ( B.DeptSeq = A.DeptSeq AND B.Gubun = A.Gubun ) 
     WHERE A.Gubun = 11 
    ----------------------------------------------------------------------------
    -- 총계, END 
    ----------------------------------------------------------------------------

    ----------------------------------------------------------------------------
    -- 도급단가
    ----------------------------------------------------------------------------
    SELECT DeptSeq, RIGHT(A.BPYm,2) AS YM, SUM(A.Qty) AS Qty 
      INTO #SumQty
      FROM #QtyPrice AS A 
     GROUP BY DeptSeq, RIGHT(A.BPYm,2)
    
    -- 세로 데이터 가로로 변경 
    SELECT DeptSeq, 
           B.[01] AS Qty01, B.[02] AS Qty02, B.[03] AS Qty03, B.[04] AS Qty04, B.[05] AS Qty05, B.[06] AS Qty06, 
           B.[07] AS Qty07, B.[08] AS Qty08, B.[09] AS Qty09, B.[10] AS Qty10, B.[11] AS Qty11, B.[12] AS Qty12
      INTO #SumQty_Row 
      FROM ( SELECT * FROM #SumQty ) AS A 
      PIVOT (MAX(Qty)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12])) AS B 
    
    UPDATE A
       SET Mth1  = C.Mth1  / NULLIF(B.Qty01,0), 
           Mth2  = C.Mth2  / NULLIF(B.Qty02,0), 
           Mth3  = C.Mth3  / NULLIF(B.Qty03,0), 
           Mth4  = C.Mth4  / NULLIF(B.Qty04,0), 
           Mth5  = C.Mth5  / NULLIF(B.Qty05,0), 
           Mth6  = C.Mth6  / NULLIF(B.Qty06,0), 
           Mth7  = C.Mth7  / NULLIF(B.Qty07,0), 
           Mth8  = C.Mth8  / NULLIF(B.Qty08,0), 
           Mth9  = C.Mth9  / NULLIF(B.Qty09,0), 
           Mth10 = C.Mth10 / NULLIF(B.Qty10,0), 
           Mth11 = C.Mth11 / NULLIF(B.Qty11,0), 
           Mth12 = C.Mth12 / NULLIF(B.Qty12,0), 
           Total = C.Total / NULLIF(ISNULL(B.Qty01,0) + 
                                    ISNULL(B.Qty02,0) + 
                                    ISNULL(B.Qty03,0) + 
                                    ISNULL(B.Qty04,0) + 
                                    ISNULL(B.Qty05,0) + 
                                    ISNULL(B.Qty06,0) + 
                                    ISNULL(B.Qty07,0) + 
                                    ISNULL(B.Qty08,0) + 
                                    ISNULL(B.Qty09,0) + 
                                    ISNULL(B.Qty10,0) + 
                                    ISNULL(B.Qty11,0) + 
                                    ISNULL(B.Qty12,0),0)
      FROM #Result      AS A 
      JOIN #SumQty_Row  AS B ON ( B.DeptSeq = A.DeptSeq )
      JOIN (
            SELECT *
              FROM #Result
             WHERE Gubun = 11
           ) AS C ON ( C.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun = 12 
    ----------------------------------------------------------------------------
    -- 도급단가, END 
    ----------------------------------------------------------------------------
    
    ----------------------------------------------------------------------------
    -- 자차단가달성율
    ----------------------------------------------------------------------------
    SELECT A.DeptSeq, 
           SUM(A.Mth1) AS Mth1, 
           SUM(A.Mth2) AS Mth2, 
           SUM(A.Mth3) AS Mth3, 
           SUM(A.Mth4) AS Mth4, 
           SUM(A.Mth5) AS Mth5, 
           SUM(A.Mth6) AS Mth6, 
           SUM(A.Mth7) AS Mth7, 
           SUM(A.Mth8) AS Mth8, 
           SUM(A.Mth9) AS Mth9, 
           SUM(A.Mth10) AS Mth10, 
           SUM(A.Mth11) AS Mth11, 
           SUM(A.Mth12) AS Mth12, 
           SUM(A.Total) AS Total 
      INTO #SelfTotalAmt
      FROM #Result AS A 
     WHERE Gubun IN ( 1, 3, 5, 6, 7, 8, 9 ) -- 운송비(자차), 유류비(자차), 시간외운반비, 회수수 운반비, 식대, 산재, 기타
     GROUP BY A.DeptSeq 
    
    SELECT Z.*, 
           Z.Qty01 + Z.Qty02 + Z.Qty03 + Z.Qty04 + Z.Qty05 + Z.Qty06 + 
           Z.Qty07 + Z.Qty08 + Z.Qty09 + Z.Qty10 + Z.Qty11 + Z.Qty12 AS TotalQty
      INTO #TotalQty
      FROM #SumQty_Row AS Z 


    -- 월별 용차사용율
    SELECT DeptSeq, RIGHT(BPYm,2) AS YM, MAX(LentUseRate) / 100 AS LentUseRate 
      INTO #LentUseRate
      FROM hencom_TPNCostOfTransportVar 
     WHERE CompanySeq = @CompanySeq 
       AND PlanSeq = @PlanSeq 
     GROUP BY DeptSeq, RIGHT(BPYm,2)
    
    UNION ALL -- 용차 사용율 평균
    
    SELECT DeptSeq, 13 AS YM, (SUM(LentUseRate)/12) / 100 AS LentUseRate 
      FROM hencom_TPNCostOfTransportVar 
     WHERE CompanySeq = @CompanySeq 
       AND PlanSeq = @PlanSeq 
     GROUP BY DeptSeq
    

    --select * from #LentUseRate 
    --return 
    
    --select * From #LentUseRate 
    --return 
    -- 세로 데이터 가로로 변경 
    SELECT DeptSeq, 
           B.[01] AS LentUseRate01, B.[02] AS LentUseRate02, B.[03] AS LentUseRate03, B.[04] AS LentUseRate04, B.[05] AS LentUseRate05, B.[06] AS LentUseRate06, 
           B.[07] AS LentUseRate07, B.[08] AS LentUseRate08, B.[09] AS LentUseRate09, B.[10] AS LentUseRate10, B.[11] AS LentUseRate11, B.[12] AS LentUseRate12, 
           B.[13] AS LentUseRate13
      INTO #LentUseRate_Row 
      FROM ( SELECT * FROM #LentUseRate ) AS A 
      PIVOT (MAX(LentUseRate)  FOR YM IN ( [01], [02], [03], [04], [05], [06], [07], [08], [09], [10], [11], [12], [13])) AS B 
    
    SELECT A.DeptSeq, 
           SUM(A.Mth1) AS Mth1, 
           SUM(A.Mth2) AS Mth2, 
           SUM(A.Mth3) AS Mth3, 
           SUM(A.Mth4) AS Mth4, 
           SUM(A.Mth5) AS Mth5, 
           SUM(A.Mth6) AS Mth6, 
           SUM(A.Mth7) AS Mth7, 
           SUM(A.Mth8) AS Mth8, 
           SUM(A.Mth9) AS Mth9, 
           SUM(A.Mth10) AS Mth10, 
           SUM(A.Mth11) AS Mth11, 
           SUM(A.Mth12) AS Mth12, 
           SUM(A.Total) AS Total 
      INTO #TotalAmt
      FROM #Result AS A 
     WHERE Gubun BETWEEN 1 AND 9   
     GROUP BY DeptSeq 
    
    UPDATE A
       SET Mth1  = (B.Mth1  / C.Qty01 / ( 1 - D.LentUseRate01 )) / ( E.Mth1  / C.Qty01 ) * 100, 
           Mth2  = (B.Mth2  / C.Qty02 / ( 1 - D.LentUseRate02 )) / ( E.Mth2  / C.Qty02 ) * 100, 
           Mth3  = (B.Mth3  / C.Qty03 / ( 1 - D.LentUseRate03 )) / ( E.Mth3  / C.Qty03 ) * 100, 
           Mth4  = (B.Mth4  / C.Qty04 / ( 1 - D.LentUseRate04 )) / ( E.Mth4  / C.Qty04 ) * 100, 
           Mth5  = (B.Mth5  / C.Qty05 / ( 1 - D.LentUseRate05 )) / ( E.Mth5  / C.Qty05 ) * 100, 
           Mth6  = (B.Mth6  / C.Qty06 / ( 1 - D.LentUseRate06 )) / ( E.Mth6  / C.Qty06 ) * 100, 
           Mth7  = (B.Mth7  / C.Qty07 / ( 1 - D.LentUseRate07 )) / ( E.Mth7  / C.Qty07 ) * 100, 
           Mth8  = (B.Mth8  / C.Qty08 / ( 1 - D.LentUseRate08 )) / ( E.Mth8  / C.Qty08 ) * 100, 
           Mth9  = (B.Mth9  / C.Qty09 / ( 1 - D.LentUseRate09 )) / ( E.Mth9  / C.Qty09 ) * 100, 
           Mth10 = (B.Mth10 / C.Qty10 / ( 1 - D.LentUseRate10 )) / ( E.Mth10 / C.Qty10 ) * 100, 
           Mth11 = (B.Mth11 / C.Qty11 / ( 1 - D.LentUseRate11 )) / ( E.Mth11 / C.Qty11 ) * 100, 
           Mth12 = (B.Mth12 / C.Qty12 / ( 1 - D.LentUseRate12 )) / ( E.Mth12 / C.Qty12 ) * 100, 
           Total = (B.Total / C.TotalQty / ( 1 - D.LentUseRate13 )) / ( E.Total / C.TotalQty ) * 100
      FROM #Result          AS A 
      JOIN #SelfTotalAmt    AS B ON ( B.DeptSeq = A.DeptSeq ) 
      JOIN #TotalQty        AS C ON ( C.DeptSeq = A.DeptSeq ) 
      JOIN #LentUseRate_Row AS D ON ( D.DeptSeq = A.DeptSeq ) 
      JOIN #TotalAmt        AS E ON ( E.DeptSeq = A.DeptSeq )
     WHERE A.Gubun = 13
    ----------------------------------------------------------------------------
    -- 자차단가달성율, END 
    ----------------------------------------------------------------------------
    

    ----------------------------------------------------------------------------
    -- 실적
    ----------------------------------------------------------------------------
    -- 운반비
    SELECT A.DeptSeq, 
           ISNULL(B.ValueText,'0') AS IsCarGubun, --1 자차, 0 용차
           SUM(ISNULL(A.Amt,0)  + ISNULL(A.AddPayAmt,0) - ISNULL(A.DeductionAmt,0)) AS Amt ,
           SUM(ISNULL(A.OTAmt,0)) AS OTAmt
      INTO #TMP_hencom_TPUSubContrCalc
      FROM hencom_TPUSubContrCalc       AS A
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.MajorSeq = 8030 
                                              AND B.MinorSeq = A.UMCarClass 
                                              AND B.Serl = 1000001
                                                )
     WHERE A.CompanySeq = @CompanySeq
       AND LEFT(A.WorkDate,4) = @StdYear 
       AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.
     GROUP BY A.DeptSeq, ISNULL(ValueText,'0')
    


    UPDATE A
       SET Sales = CASE WHEN A.Gubun = 1 THEN ISNULL(B.Amt,0) ELSE ISNULL(C.Amt,0) END 
      FROM #Result AS A 
      LEFT OUTER JOIN #TMP_hencom_TPUSubContrCalc AS B ON ( B.DeptSeq = A.DeptSeq AND B.IsCarGubun = '1' ) 
      LEFT OUTER JOIN #TMP_hencom_TPUSubContrCalc AS C ON ( B.DeptSeq = A.DeptSeq AND C.IsCarGubun = '0' ) 
     WHERE Gubun IN ( 1, 2 ) 

    --유류비
    SELECT A.DeptSeq, 
           ISNULL(C.ValueText,'0') AS IsCarGubun, --1 자차, 0 용차
           SUM(ISNULL(A.RefTotAmt,0)) AS Amt 
      INTO #TMP_hencom_TPUFuelCalc
      FROM hencom_TPUFuelCalc AS A
      LEFT OUTER JOIN hencom_TPUSubContrCar AS B ON ( B.CompanySeq = @CompanySeq AND B.SubContrCarSeq = A.SubContrCarSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS C ON ( C.CompanySeq = @CompanySeq 
                                                  AND C.MajorSeq = 8030 
                                                  AND C.MinorSeq = B.UMCarClass 
                                                  AND C.Serl = 1000001
                                                    )
     WHERE A.CompanySeq = @CompanySeq
       AND ISNULL(A.SlipSeq,0) <> 0 --전표처리된 건만.
       AND LEFT(A.FuelCalcYM,4) = @StdYear
     GROUP BY A.DeptSeq, ISNULL(ValueText,'0')  
    
    UPDATE A
       SET Sales = CASE WHEN A.Gubun = 3 THEN ISNULL(B.Amt,0) ELSE ISNULL(C.Amt,0) END 
      FROM #Result AS A 
      LEFT OUTER JOIN #TMP_hencom_TPUFuelCalc AS B ON ( B.DeptSeq = A.DeptSeq AND B.IsCarGubun = '1' ) 
      LEFT OUTER JOIN #TMP_hencom_TPUFuelCalc AS C ON ( C.DeptSeq = A.DeptSeq AND C.IsCarGubun = '0' ) 
     WHERE Gubun IN ( 3, 4 ) 
       
    -- 시간외운반비: 자차에만 OT금액 포함한다.
    UPDATE A
       SET Sales = ISNULL(B.OTAmt,0)
      FROM #Result AS A 
      LEFT OUTER JOIN #TMP_hencom_TPUSubContrCalc AS B ON ( B.IsCarGubun = '1' ) 
     WHERE Gubun = 5 
    
    --select *from _TDADept 
    -- 식대 
    SELECT D.DeptSeq, SUM(A.DrAmt) AS Amt
      INTO #SalesEatAmt
      FROM _TACSlipRow  AS A 
      JOIN _TACSlip     AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipMstSeq = A.SlipMstSeq ) 
      JOIN _TDAAccount  AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.AccSeq ) 
      JOIN #hencom_TDADeptAdd AS D ON ( D.SlipUnit = A.SlipUnit ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND C.AccNo = '59050104' -- 도급비(제)_식대
       AND LEFT(B.AccDate,4) = @StdYear 
       AND ISNULL(B.IsSet,'0') = '1'
     GROUP BY D.DeptSeq 
    
    UPDATE A
       SET Sales = B.Amt
      FROM #Result      AS A 
      JOIN #SalesEatAmt AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE Gubun = 7 
    
    
    -- 기타 
    SELECT D.DeptSeq, SUM(A.DrAmt) AS Amt
      INTO #SalesEtcAmt
      FROM _TACSlipRow  AS A 
      JOIN _TACSlip     AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipMstSeq = A.SlipMstSeq ) 
      JOIN _TDAAccount  AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.AccSeq )
      JOIN #hencom_TDADeptAdd AS D ON ( D.SlipUnit = A.SlipUnit ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND C.AccNo = '59050199' -- 도급비(제)_기타
       AND LEFT(B.AccDate,4) = @StdYear 
       AND ISNULL(B.IsSet,'0') = '1'
     GROUP BY D.DeptSeq 
    
    UPDATE A
       SET Sales = B.Amt
      FROM #Result      AS A 
      JOIN #SalesEtcAmt AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE Gubun = 9 
    
    -- 총계
    UPDATE A
       SET Sales = B.Sales
      FROM #Result AS A 
      JOIN ( 
            SELECT DeptSeq, SUM(ISNULL(Sales,0)) AS Sales
              FROM #Result 
             WHERE Gubun BETWEEN 1 AND 9 
             GROUP BY DeptSeq 
           ) AS B ON ( B.DeptSeq = A.DeptSeq ) 
     WHERE Gubun = 11 
    
    -- 도급단가 
    UPDATE A
       SET Sales = ISNULL(B.Sales,0) / NULLIF(C.SalesQty,0)
      FROM #Result AS A 
      JOIN #Result AS B ON ( B.DeptSeq = A.DeptSeq AND B.Gubun = 11 ) 
      JOIN ( 
            SELECT DeptSeq, SUM(ISNULL(Qty,0)) AS SalesQty
              FROM hencom_VInvoiceReplaceItem 
             WHERE CompanySeq = @CompanySeq
               AND LEFT(WorkDate,4) = @StdYear
             GROUP BY DeptSeq
           ) AS C ON ( C.DeptSeq = A.DepTSeq ) 
     WHERE A.Gubun = 12 
    
    
    ------------------
    -- 자차단가달성율
    ------------------
    -- 전체금액
    SELECT DeptSeq, SUM(ISNULL(A.Sales,0)) AS Amt
      INTO #SalesSelfTotalAmt
      FROM #Result AS A 
     WHERE Gubun IN ( 1, 3, 5, 6, 7, 8, 9 ) -- 운송비(자차), 유류비(자차), 시간외운반비, 회수수 운반비, 식대, 산재, 기타
     GROUP BY DeptSeq 
    
    -- 판매출하량
    SELECT DeptSeq, SUM(ISNULL(Qty,0)) AS Qty
      INTO #SalesTotalQty
      FROM hencom_VInvoiceReplaceItem 
     WHERE CompanySeq = @CompanySeq
       AND LEFT(WorkDate,4) = @StdYear
     GROUP BY DeptSeq 
    
    -- 실적 자차사용율
    SELECT A.DeptSeq, 
           SUM(CASE WHEN ISNULL(D.IsSelf,'0') = '1' THEN A.Qty ELSE 0 END) AS SelfQty, 
           SUM(CASE WHEN ISNULL(D.IsSelf,'0') = '0' THEN A.Qty ELSE 0 END) AS LentQty, 
           SUM(CASE WHEN ISNULL(D.IsSelf,'0') = '1' THEN A.Qty ELSE 0 END) / SUM(A.Qty) AS SelfUseRate
      INTO #SalesSelfUseRate
      FROM hencom_VInvoiceReplaceItem       AS A 
      JOIN hencom_TIFProdWorkReportCloseSum AS B ON ( B.CompanySeq = @CompanySeq AND B.SumMesKey = A.SumMesKey ) 
      JOIN hencom_TIFProdWorkReportClose    AS C ON ( C.CompanySeq = @CompanySeq AND C.SumMesKey = B.SumMesKey ) 
      JOIN ( 
            SELECT MinorSeq, ValueText AS IsSelf
              FROM _TDAUMinorValue 
             WHERE Majorseq = 8030 
               AND Serl = 1000001
          ) AS D ON ( D.MinorSeq = C.UMCarClass ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.WorkDate,4) = @StdYear
     GROUP BY A.DeptSeq 
    
    
    SELECT DeptSeq, SUM(ISNULL(A.Sales,0)) AS Amt
      INTO #SalesTotalAmt
      FROM #Result AS A 
     WHERE Gubun BETWEEN 1 AND 9   
     GROUP BY DeptSeq 
    
    UPDATE A
       SET Sales  = (B.Amt  / C.Qty / D.SelfUseRate) / ( E.Amt  / C.Qty ) * 100
      FROM #Result              AS A 
      JOIN #SalesSelfTotalAmt   AS B ON ( B.DeptSeq = A.DeptSeq ) 
      JOIN #SalesTotalQty       AS C ON ( C.DeptSeq = A.DeptSeq ) 
      JOIN #SalesSelfUseRate    AS D ON ( D.DeptSeq = A.DeptSeq ) 
      JOIN #SalesTotalAmt       AS E ON ( E.DeptSeq = A.DeptSeq ) 
     WHERE A.Gubun = 13
    ----------------------------------------------------------------------------
    -- 실적, END 
    ----------------------------------------------------------------------------
    
    SELECT * FROM #Result 
    --*/

    RETURN
go


--exec hencom_SPNCostOfTransportVarSubContQueryNew_AllDept
--@xmlDocument='<ROOT>  
--      <DataBlock2>  
--     <WorkingTag>A</WorkingTag>  
--     <IDX_NO>1</IDX_NO>  
--     <Status>0</Status>  
--     <DataSeq>1</DataSeq>  
--     <Selected>1</Selected>  
--     <TABLE_NAME>DataBlock2</TABLE_NAME>  
--    <IsChangedMst>1</IsChangedMst>  
--    <PlanSeq>3</PlanSeq>  
--     </DataBlock2>  
--   </ROOT>' ,
--@xmlFlags=2,@ServiceSeq=1510143,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031995  