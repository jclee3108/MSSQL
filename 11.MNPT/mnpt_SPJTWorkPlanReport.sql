     
IF OBJECT_ID('mnpt_SPJTWorkPlanReport') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanReport
GO  
    
-- v2017.10.31
  
-- 작업계획서(출력물)-SS1조회 by 이재천
CREATE PROC mnpt_SPJTWorkPlanReport      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @WorkDate   NCHAR(8)
      
    SELECT @WorkDate = ISNULL( WorkDate    , '' )
      FROM #BIZ_IN_DataBlock1 
    
    /*********************************************************************************
    -- DataBlock1 (Master)
    **********************************************************************************/
    
    SELECT DISTINCT 
           A.WorkDate, 
           A.UMWeather, 
           B.MinorName AS UMWeatherName, 
           A.MRemark, 
           A.ManRemark
      FROM mnpt_TPJTWorkPlan        AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMWeather ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkDate = @WorKDate 
    
    /*********************************************************************************
    -- DataBlock2(본선작업) , DataBlock3(본선외작업)
    **********************************************************************************/

    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, Srt
    --------------------------------------------------
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkPlanSeq     INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkPlanSeq, ExtraGroupSeq ) 
    SELECT WorkPlanSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkPlan 
     WHERE CompanySeq = @CompanySeq 
       AND WorkDate = @WorkDate 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkPlanSeq     INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkPlanSeq     INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkPlanSeq    INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @WorkPlanSeq   = WorkPlanSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkPlanSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkPlanSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkPlanSeq, MultiExtraName ) 
        SELECT @WorkPlanSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, End  
    --------------------------------------------------
    
    --------------------------------------------------
    -- 최종조회 
    --------------------------------------------------
    SELECT A.WorkPlanSeq,
           (CASE WHEN ISNULL(P.PJTName,'') = '' THEN '　' ELSE ISNULL(P.PJTName,'') END) AS PJTName,       -- 프로젝트명
           (CASE WHEN ISNULL(P.PJTNo,'') = '' THEN '　' ELSE ISNULL(P.PJTNo,'') END) AS PJTNo,         -- 프로젝트번호 
           (CASE WHEN ISNULL(C.PJTTypeName,'') = '' THEN '　' ELSE ISNULL(C.PJTTypeName,'') END) AS PJTTypeName,   -- PJTTypeName
           (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END) AS CustName,      -- 거래처 
           CASE WHEN NOT EXISTS (SELECT 1 FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND CustSeq = D.CustSeq AND UMCustKind = 1004002) 
                THEN (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END)
                ELSE '　' 
                END AS CustName1, 
           CASE WHEN EXISTS (SELECT 1 FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND CustSeq = D.CustSeq AND UMCustKind = 1004002) 
                THEN (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END)
                ELSE '　' 
                END AS CustName2, 
           (CASE WHEN ISNULL(B.BizUnitName,'') = '' THEN '　' ELSE ISNULL(B.BizUnitName,'') END) AS BizUnitName,   -- 사업부문
           (CASE WHEN ISNULL(H.EnShipName,'') = '' THEN '　' ELSE ISNULL(H.EnShipName,'') END) AS EnShipName,   -- 모선 
           (CASE WHEN ISNULL(I.MinorName,'') = '' THEN '　' ELSE ISNULL(I.MinorName,'') END) AS UMWorkTypeName, -- 작업항목
           ISNULL(S.PlanQty,0) AS GoodsQty, 
           ISNULL(S.PlanMTWeight,0) AS GoodsMTWeight, 
           ISNULL(S.PlanCBMWeight,0) AS GoodsCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumQty,0) END AS SumQty, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumMTWeight,0) END AS SumMTWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumCBMWeight,0) END AS SumCBMWeight, 
           --A.UMWorkTeam, 
           (CASE WHEN ISNULL(Q.MinorName,'') = '' THEN '　' ELSE ISNULL(Q.MinorName,'') END) AS UMWorkTeamName, 
           ISNULL(A.TodayQty,0) AS TodayQty, 
           ISNULL(A.TodayMTWeight,0) AS TodayMTWeight, 
           ISNULL(A.TodayCBMWeight,0) AS TodayCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight, -- 잔여CBM
           --A.ExtraGroupSeq, 
           (CASE WHEN ISNULL(O.MultiExtraName,'') = '' THEN '　' ELSE ISNULL(O.MultiExtraName,'') END) AS MultiExtraName, -- 할증구분 
           STUFF(A.WorkSrtTime,3,0,':') AS WorkSrtTime, -- 작업시작시간 
           STUFF(A.WorkEndTime,3,0,':') AS WorkEndTime, -- 작업종료시간 
           ISNULL(A.RealWorkTime,0) AS RealWorkTime, -- 실작업시간 
           --A.EmpSeq, 
           (CASE WHEN ISNULL(L.EmpName,'') = '' THEN '　' ELSE ISNULL(L.EmpName,'') END) AS EmpName    -- 총괄포맨 
      INTO #MasterShip
      FROM mnpt_TPJTWorkPlan        AS A 
      LEFT OUTER JOIN _TPJTProject  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkType )
      LEFT OUTER JOIN mnpt_TPJTProject      AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = P.PJTSeq ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT PJTSeq, 
                               ShipSeq, 
                               ShipSerl, 
                               UMWorkType, 
                               SUM(TodayQty) AS SumQty, 
                               SUM(TodayMTWeight) AS SumMTWeight, 
                               SUM(TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkPlan 
                         WHERE CompanySeq = @CompanySeq 
                           AND WorkDate < @WorkDate 
                        GROUP BY PJTSeq, ShipSeq, ShipSerl, UMWorkType 
                      ) AS K ON ( K.PJTSeq = A.PJTSeq AND K.ShipSeq = A.ShipSeq AND K.ShipSerl = A.ShipSerl AND K.UMWorkType = A.UMWorkType ) 
      LEFT OUTER JOIN _TDAEmp           AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkPlanItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkPlanSeq 
                      ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      --LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN #GroupExtraName   AS O ON ( O.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = A.UMWorkTeam ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS SumQty, 
                               SUM(Z.TodayMTWeight) AS SumMTWeight, 
                               SUM(Z.TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkPlan AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkDate < @WorkDate 
                        GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS KK ON ( KK.PJTSeq = A.PJTSeq 
                               AND KK.ShipSeq = A.ShipSeq 
                               AND KK.ShipSerl = A.ShipSerl 
                               AND KK.UMWorkType = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                 ) 
      LEFT OUTER JOIN ( -- 금일 작업
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS TodayQty, 
                               SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                               SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                            FROM mnpt_TPJTWorkPlan AS Z 
                            LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                           WHERE Z.CompanySeq = @CompanySeq
                             AND Z.WorkDate = @WorkDate
                           GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS W ON ( W.PJTSeq = A.PJTSeq 
                              AND W.ShipSeq = A.ShipSeq 
                              AND W.ShipSerl = A.ShipSerl 
                              AND W.UMWorkType = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
       AND ( A.ShipSeq <> 0 AND A.ShipSeq IS NOT NULL ) 
     ORDER BY P.PJTName, A.WorkSrtTime


    SELECT A.WorkPlanSeq,
           (CASE WHEN ISNULL(P.PJTName,'') = '' THEN '　' ELSE ISNULL(P.PJTName,'') END) AS PJTName,       -- 프로젝트명
           (CASE WHEN ISNULL(P.PJTNo,'') = '' THEN '　' ELSE ISNULL(P.PJTNo,'') END) AS PJTNo,         -- 프로젝트번호 
           (CASE WHEN ISNULL(C.PJTTypeName,'') = '' THEN '　' ELSE ISNULL(C.PJTTypeName,'') END) AS PJTTypeName,   -- PJTTypeName
           (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END) AS CustName,      -- 거래처 
           CASE WHEN NOT EXISTS (SELECT 1 FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND CustSeq = D.CustSeq AND UMCustKind = 1004002) 
                THEN (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END)
                ELSE '　' 
                END AS CustName1, 
           CASE WHEN EXISTS (SELECT 1 FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND CustSeq = D.CustSeq AND UMCustKind = 1004002) 
                THEN (CASE WHEN ISNULL(D.CustName,'') = '' THEN '　' ELSE ISNULL(D.CustName,'') END)
                ELSE '　' 
                END AS CustName2, 
           (CASE WHEN ISNULL(B.BizUnitName,'') = '' THEN '　' ELSE ISNULL(B.BizUnitName,'') END) AS BizUnitName,   -- 사업부문
           (CASE WHEN ISNULL(H.EnShipName,'') = '' THEN '　' ELSE ISNULL(H.EnShipName,'') END) AS EnShipName,   -- 모선 
           (CASE WHEN ISNULL(I.MinorName,'') = '' THEN '　' ELSE ISNULL(I.MinorName,'') END) AS UMWorkTypeName, -- 작업항목
           ISNULL(S.PlanQty,0) AS GoodsQty, 
           ISNULL(S.PlanMTWeight,0) AS GoodsMTWeight, 
           ISNULL(S.PlanCBMWeight,0) AS GoodsCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumQty,0) END AS SumQty, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumMTWeight,0) END AS SumMTWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(K.SumCBMWeight,0) END AS SumCBMWeight, 
           --A.UMWorkTeam, 
           (CASE WHEN ISNULL(Q.MinorName,'') = '' THEN '　' ELSE ISNULL(Q.MinorName,'') END) AS UMWorkTeamName, 
           ISNULL(A.TodayQty,0) AS TodayQty, 
           ISNULL(A.TodayMTWeight,0) AS TodayMTWeight, 
           ISNULL(A.TodayCBMWeight,0) AS TodayCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight, -- 잔여CBM
           --A.ExtraGroupSeq, 
           (CASE WHEN ISNULL(O.MultiExtraName,'') = '' THEN '　' ELSE ISNULL(O.MultiExtraName,'') END) AS MultiExtraName, -- 할증구분 
           STUFF(A.WorkSrtTime,3,0,':') AS WorkSrtTime, -- 작업시작시간 
           STUFF(A.WorkEndTime,3,0,':') AS WorkEndTime, -- 작업종료시간 
           ISNULL(A.RealWorkTime,0) AS RealWorkTime, -- 실작업시간 
           --A.EmpSeq, 
           (CASE WHEN ISNULL(L.EmpName,'') = '' THEN '　' ELSE ISNULL(L.EmpName,'') END) AS EmpName    -- 총괄포맨 
      INTO #MasterNoShip
      FROM mnpt_TPJTWorkPlan        AS A 
      LEFT OUTER JOIN _TPJTProject  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkType )
      LEFT OUTER JOIN mnpt_TPJTProject      AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = P.PJTSeq ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT PJTSeq, 
                               ShipSeq, 
                               ShipSerl, 
                               UMWorkType, 
                               SUM(TodayQty) AS SumQty, 
                               SUM(TodayMTWeight) AS SumMTWeight, 
                               SUM(TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkPlan 
                         WHERE CompanySeq = @CompanySeq 
                           AND WorkDate < @WorkDate 
                        GROUP BY PJTSeq, ShipSeq, ShipSerl, UMWorkType 
                      ) AS K ON ( K.PJTSeq = A.PJTSeq AND K.ShipSeq = A.ShipSeq AND K.ShipSerl = A.ShipSerl AND K.UMWorkType = A.UMWorkType ) 
      LEFT OUTER JOIN _TDAEmp           AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkPlanItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkPlanSeq 
                      ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      --LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN #GroupExtraName   AS O ON ( O.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = A.UMWorkTeam ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMWorkType AND R.Serl = 1000001 ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS SumQty, 
                               SUM(Z.TodayMTWeight) AS SumMTWeight, 
                               SUM(Z.TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkPlan AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkDate < @WorkDate 
                        GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS KK ON ( KK.PJTSeq = A.PJTSeq 
                               AND KK.ShipSeq = A.ShipSeq 
                               AND KK.ShipSerl = A.ShipSerl 
                               AND KK.UMWorkType = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                 ) 
      LEFT OUTER JOIN ( -- 금일 작업
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS TodayQty, 
                               SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                               SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                            FROM mnpt_TPJTWorkPlan AS Z 
                            LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                           WHERE Z.CompanySeq = @CompanySeq
                             AND Z.WorkDate = @WorkDate
                           GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS W ON ( W.PJTSeq = A.PJTSeq 
                              AND W.ShipSeq = A.ShipSeq 
                              AND W.ShipSerl = A.ShipSerl 
                              AND W.UMWorkType = CASE WHEN ISNULL(R.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
       AND ( A.ShipSeq = 0 OR A.ShipSeq IS NULL ) 
     ORDER BY P.PJTName, A.WorkSrtTime
    
    
    
    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           A.UMBisWorkType, 
           A.SelfToolSeq, 
           A.RentToolSeq, 
           A.ToolWorkTime, 
           0 AS DirverEmpSeq, 
           A.DUnionDay + A.DUnionHalf + A.DUnionMonth AS DUnion, 
           A.DDailyDay + A.DDailyHalf + A.DDailyMonth AS DDaily, 
           A.DOSDay + A.DOSHalf + A.DOSMonth AS DOS, 
           A.DEtcDay + A.DEtcHalf + A.DEtcMonth AS DEtc, 
           A.NDEmpSeq, 
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDailyDay + A.NDUnionDailyHalf + A.NDUnionDailyMonth AS NDUnionDaily, 
           A.NDUnionSignalDay + A.NDUnionSignalHalf + A.NDUnionSignalMonth AS NDUnionSignal, 
           A.NDUnionEtcDay + A.NDUnionEtcHalf + A.NDUnionEtcMonth AS NDUnionEtc, 
           A.NDDailyDay + A.NDDailyHalf + A.NDDailyMonth AS NDDaily, 
           A.NDOSDay + A.NDOSHalf + A.NDOSMonth AS NDOS, 
           A.NDEtcDay + A.NDEtcHalf + A.NDEtcMonth AS NDEtc, 
           A.DRemark, 
           1 AS Sort

      INTO #mnpt_TPJTWorkPlanItem
      FROM mnpt_TPJTWorkPlanItem    AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DriverEmpSeq1 = 0 AND A.DriverEmpSeq2 = 0 AND A.DriverEmpSeq3 = 0 
    UNION ALL 
    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           A.UMBisWorkType, 
           A.SelfToolSeq, 
           A.RentToolSeq, 
           A.ToolWorkTime, 
           A.DriverEmpSeq1 AS DirverEmpSeq, 
           A.DUnionDay + A.DUnionHalf + A.DUnionMonth AS DUnion, 
           A.DDailyDay + A.DDailyHalf + A.DDailyMonth AS DDaily, 
           A.DOSDay + A.DOSHalf + A.DOSMonth AS DOS, 
           A.DEtcDay + A.DEtcHalf + A.DEtcMonth AS DEtc, 
           A.NDEmpSeq, 
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDailyDay + A.NDUnionDailyHalf + A.NDUnionDailyMonth AS NDUnionDaily, 
           A.NDUnionSignalDay + A.NDUnionSignalHalf + A.NDUnionSignalMonth AS NDUnionSignal, 
           A.NDUnionEtcDay + A.NDUnionEtcHalf + A.NDUnionEtcMonth AS NDUnionEtc, 
           A.NDDailyDay + A.NDDailyHalf + A.NDDailyMonth AS NDDaily, 
           A.NDOSDay + A.NDOSHalf + A.NDOSMonth AS NDOS, 
           A.NDEtcDay + A.NDEtcHalf + A.NDEtcMonth AS NDEtc, 
           A.DRemark, 
           2 AS Sort
      FROM mnpt_TPJTWorkPlanItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DriverEmpSeq1 <> 0 
    UNION ALL 
    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           A.UMBisWorkType, 
           A.SelfToolSeq, 
           A.RentToolSeq, 
           A.ToolWorkTime, 
           A.DriverEmpSeq2 AS DirverEmpSeq, 
           A.DUnionDay + A.DUnionHalf + A.DUnionMonth AS DUnion, 
           A.DDailyDay + A.DDailyHalf + A.DDailyMonth AS DDaily, 
           A.DOSDay + A.DOSHalf + A.DOSMonth AS DOS, 
           A.DEtcDay + A.DEtcHalf + A.DEtcMonth AS DEtc, 
           A.NDEmpSeq, 
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDailyDay + A.NDUnionDailyHalf + A.NDUnionDailyMonth AS NDUnionDaily, 
           A.NDUnionSignalDay + A.NDUnionSignalHalf + A.NDUnionSignalMonth AS NDUnionSignal, 
           A.NDUnionEtcDay + A.NDUnionEtcHalf + A.NDUnionEtcMonth AS NDUnionEtc, 
           A.NDDailyDay + A.NDDailyHalf + A.NDDailyMonth AS NDDaily, 
           A.NDOSDay + A.NDOSHalf + A.NDOSMonth AS NDOS, 
           A.NDEtcDay + A.NDEtcHalf + A.NDEtcMonth AS NDEtc, 
           A.DRemark, 
           3 AS Sort
      FROM mnpt_TPJTWorkPlanItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DriverEmpSeq2 <> 0 
    UNION ALL 
    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           A.UMBisWorkType, 
           A.SelfToolSeq, 
           A.RentToolSeq, 
           A.ToolWorkTime, 
           A.DriverEmpSeq3 AS DirverEmpSeq, 
           A.DUnionDay + A.DUnionHalf + A.DUnionMonth AS DUnion, 
           A.DDailyDay + A.DDailyHalf + A.DDailyMonth AS DDaily, 
           A.DOSDay + A.DOSHalf + A.DOSMonth AS DOS, 
           A.DEtcDay + A.DEtcHalf + A.DEtcMonth AS DEtc, 
           A.NDEmpSeq, 
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDailyDay + A.NDUnionDailyHalf + A.NDUnionDailyMonth AS NDUnionDaily, 
           A.NDUnionSignalDay + A.NDUnionSignalHalf + A.NDUnionSignalMonth AS NDUnionSignal, 
           A.NDUnionEtcDay + A.NDUnionEtcHalf + A.NDUnionEtcMonth AS NDUnionEtc, 
           A.NDDailyDay + A.NDDailyHalf + A.NDDailyMonth AS NDDaily, 
           A.NDOSDay + A.NDOSHalf + A.NDOSMonth AS NDOS, 
           A.NDEtcDay + A.NDEtcHalf + A.NDEtcMonth AS NDEtc, 
           A.DRemark, 
           4 AS Sort
      FROM mnpt_TPJTWorkPlanItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DriverEmpSeq3 <> 0 
    

    --select * from #mnpt_TPJTWorkPlanItem where workplanseq = 284 

    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           (CASE WHEN ISNULL(B.MinorName ,'') = '' THEN '　' ELSE ISNULL(B.MinorName ,'') END) AS UMBisWorkTypeName, 
           (CASE WHEN ISNULL(C.EquipmentSName ,'') = '' THEN '　' ELSE ISNULL(C.EquipmentSName ,'') END) AS SelfToolName, 
           (CASE WHEN ISNULL(D.EquipmentSName  ,'') = '' THEN '　' ELSE ISNULL(D.EquipmentSName  ,'') END) AS RentToolName, 
           A.ToolWorkTime, 
           (CASE WHEN ISNULL(E.EmpName ,'') = '' THEN '　' ELSE ISNULL(E.EmpName ,'') END) AS DirverEmpName, 
           A.DUnion, 
           A.DDaily, 
           A.DOS, 
           A.DEtc,  
           (CASE WHEN ISNULL(F.EmpName ,'') = '' THEN '　' ELSE ISNULL(F.EmpName ,'') END) AS NDEmpName, 
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDaily, 
           A.NDUnionSignal, 
           A.NDUnionEtc, 
           A.NDDaily, 
           A.NDOS, 
           A.NDEtc, 
           (CASE WHEN ISNULL(A.DRemark ,'') = '' THEN '　' ELSE ISNULL(A.DRemark ,'') END) AS DRemark 
      INTO #Detail 
      FROM #mnpt_TPJTWorkPlanItem       AS A 
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMBisWorkType ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS C ON ( C.CompanySeq = @CompanySeq AND C.EquipmentSeq = A.SelfToolSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS D ON ( D.CompanySeq = @CompanySeq AND D.EquipmentSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.DirverEmpSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.NDEmpSeq ) 
     ORDER BY WorkPlanSeq, WorkPlanSerl, Sort
    
    -- DataBlock2
    SELECT * 
      FROM #MasterShip          AS A 
      LEFT OUTER JOIN #Detail   AS B ON ( B.WorkPlanSeq = A.WorkPlanSeq ) 
    -- DataBlock3 
    SELECT * 
      FROM #MasterNoShip        AS A 
      LEFT OUTER JOIN #Detail   AS B ON ( B.WorkPlanSeq = A.WorkPlanSeq ) 
    
    
    /*********************************************************************************
    -- DataBlock4(안전교육)
    **********************************************************************************/
    
    SELECT MinorName AS ListName_4
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016105
    
    /*********************************************************************************
    -- DataBlock5(본선접안 전/후 APRON 시설물점검)
    **********************************************************************************/
    
    SELECT MinorName AS ListName_5
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016104
    
    /*********************************************************************************
    -- DataBlock6(3대 다발 재해예방/화제예방/시설물 안전점검사항)
    **********************************************************************************/
    
    CREATE TABLE #List1 
    ( 
        IDX_NO          INT IDENTITY, 
        ListKindName    NVARCHAR(200), 
        ListName        NVARCHAR(200) 
    )
    INSERT INTO #List1 ( ListKindName, ListName ) 
    SELECT C.MinorName AS ListKindName, A.MinorName AS ListName 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016107
     ORDER BY A.MinorSort
    
    CREATE TABLE #List2 
    ( 
        IDX_NO          INT IDENTITY, 
        ListKindName    NVARCHAR(200), 
        ListName        NVARCHAR(200) 
    )
    INSERT INTO #List2 ( ListKindName, ListName ) 
    SELECT C.MinorName AS ListKindName, A.MinorName AS ListName 
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016109
     ORDER BY A.MinorSort
    
    SELECT ISNULL(B.ListKindName,'') AS ListKindName1_6, 
           ISNULL(B.ListName,'') AS ListName1_6, 
           ISNULL(C.ListKindName,'') AS ListKindName2_6, 
           ISNULL(C.ListName,'') AS ListName2_6 
      FROM ( 
            SELECT IDX_NO
              FROM #List1 
            UNION
            SELECT IDX_NO 
              FROM #List2 
           ) AS A 
      LEFT OUTER JOIN #List1 AS B ON ( B.IDX_NO = A.IDX_NO ) 
      LEFT OUTER JOIN #List2 AS C ON ( C.IDX_NO = A.IDX_NO ) 
    
    /*********************************************************************************
    -- DataBlock7(하역장비 정검 및 운전자 확인)
    **********************************************************************************/
    
    CREATE TABLE #DataBlock7_1 
    (
        IDX_NO      INT IDENTITY, 
        MinorSeq    INT, 
        ListName    NVARCHAR(100), 
        
    )
    DECLARE @ListCnt INT 

    SELECT @ListCnt = COUNT(1) 
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016110
    
    SELECT @ListCnt = CEILING(CONVERT(DECIMAL(19,5),@ListCnt) / 2)

    SET ROWCOUNT @ListCnt 

    INSERT INTO #DataBlock7_1 ( MinorSeq, ListName ) 
    SELECT A.MinorSeq, MinorName AS ListName
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016110
     ORDER BY A.MinorSeq 
    
    SET ROWCOUNT 0

    CREATE TABLE #DataBlock7_2 
    (
        IDX_NO      INT IDENTITY, 
        MinorSeq    INT, 
        ListName    NVARCHAR(100) 
    )

    INSERT INTO #DataBlock7_2 ( MinorSeq, ListName ) 
    SELECT A.MinorSeq, A.MinorName AS ListName
      FROM _TDAUMinor AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016110
       AND NOT EXISTS (SELECT 1 FROM #DataBlock7_1 WHERE MinorSeq = A.MinorSeq ) 
    
    SELECT A.ListName AS ListName1_7, 
           B.ListName AS ListName2_7
      FROM #DataBlock7_1                AS A 
      LEFT OUTER JOIN #DataBlock7_2     AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    /*********************************************************************************
    -- DataBlock8(하역장비 정검 및 운전자 확인)
    **********************************************************************************/
    SELECT REPLACE(C.MinorName, ',', NCHAR(13)) AS ListKindName_8, 
           REPLACE(D.ValueText, ',', NCHAR(13)) AS InPutToolName_8,
           A.MinorName AS ListName_8
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1016112
     ORDER BY A.MinorSort
    

    RETURN 
GO

begin tran 

DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0
IF @CONST_#BIZ_IN_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , WorkDate NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_IN_DataBlock1 = 1

END

IF @CONST_#BIZ_OUT_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkPlanSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), SourceWorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000), IsShipCharge CHAR(1)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END

IF @CONST_#BIZ_IN_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock2
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT, IsMain CHAR(1)
    )
    
    SET @CONST_#BIZ_IN_DataBlock2 = 1

END

IF @CONST_#BIZ_OUT_DataBlock2 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock2
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkPlanSeq INT, WorkPlanSerl INT, IsMain CHAR(1)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkDate) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'20171029'
IF @@ERROR <> 0 RETURN


DECLARE @HasError           NCHAR(1)
        , @UseTransaction   NCHAR(1)
        -- 내부 SP용 파라메터
        , @ServiceSeq       INT
        , @MethodSeq        INT
        , @WorkingTag       NVARCHAR(10)
        , @CompanySeq       INT
        , @LanguageSeq      INT
        , @UserSeq          INT
        , @PgmSeq           INT
        , @IsTransaction    BIT

SET @HasError = N'0'
SET @UseTransaction = N'0'

BEGIN TRY

SET @ServiceSeq     = 13820013
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820008
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkPlanReport            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndGOTO_END:
END TRY
BEGIN CATCH
-- SQL 오류인 경우는 여기서 처리가 된다
    IF @UseTransaction = N'1'
        ROLLBACK TRAN
    
    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
            , @ERROR_SEVERITY   INT
            , @ERROR_STATE      INT
            , @ERROR_PROCEDURE  NVARCHAR(128)

    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
            , @ERROR_STATE      = ERROR_STATE() 
            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

    RETURN
END CATCH

-- SQL 오류를 제외한 체크로직으로 발생된 오류는 여기서 처리
IF @HasError = N'1' AND @UseTransaction = N'1'
    ROLLBACK TRAN
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2
rollback     
 