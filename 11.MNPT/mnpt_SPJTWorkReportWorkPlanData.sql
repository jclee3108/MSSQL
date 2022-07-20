     
IF OBJECT_ID('mnpt_SPJTWorkReportWorkPlanData') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportWorkPlanData  
GO  
    
-- v2017.09.25
  
-- 작업실적입력-작업계획가져오기 by 이재천
CREATE PROC mnpt_SPJTWorkReportWorkPlanData      
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
    
    --------------------------------------------------
    -- 작업계획 - 할증구분코드를 할증구분명칭으로 바꿔주기, Srt
    --------------------------------------------------
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkPlanSeq   INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkPlanSeq, ExtraGroupSeq ) 
    SELECT WorkPlanSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkPlan 
     WHERE CompanySeq = @CompanySeq 
       AND WorkDate = @WorkDate 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkPlanSeq   INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkPlanSeq   INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkPlanSeq  INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq   = ExtraGroupSeq, 
               @WorkPlanSeq     = WorkPlanSeq
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
    -- 작업계획 - 할증구분코드를 할증구분명칭으로 바꿔주기, End  
    --------------------------------------------------
    
    --------------------------------------------------
    -- 작업실적 - 할증구분코드를 할증구분명칭으로 바꿔주기, Srt
    --------------------------------------------------
    CREATE TABLE #ReportExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkReportSeq   INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ReportExtraSeq ( WorkReportSeq, ExtraGroupSeq ) 
    SELECT WorkReportSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkReport
     WHERE CompanySeq = @CompanySeq 
       AND WorkDate = @WorkDate 
    
    CREATE TABLE #ReportCheckExtraSeq
    (
        WorkReportSeq   INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #ReportGroupExtraName
    (
        WorkReportSeq   INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @WorkReportSeq  INT
    
    SELECT @Cnt = 1 , @ExtraGroupSeq = '' , @ExtraGroupName = ''

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq   = ExtraGroupSeq, 
               @WorkReportSeq   = WorkReportSeq
          FROM #ReportExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #ReportCheckExtraSeq 

        INSERT INTO #ReportCheckExtraSeq ( WorkReportSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkReportSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #ReportCheckExtraSeq 
        
        INSERT INTO #ReportGroupExtraName ( WorkReportSeq, MultiExtraName ) 
        SELECT @WorkReportSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #ReportExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    --------------------------------------------------
    -- 작업실적 - 할증구분코드를 할증구분명칭으로 바꿔주기, End  
    --------------------------------------------------
    
    --------------------------------------------------
    -- 작업실적 최종조회 
    --------------------------------------------------
    SELECT A.WorkReportSeq, 
           A.WorkPlanSeq,
           A.IsCfm,  
           A.PJTSeq,        -- 프로젝트코드
           P.PJTName,       -- 프로젝트명
           P.PJTNo,         -- 프로젝트번호 
           C.PJTTypeName,   -- PJTTypeName
           D.CustName,      -- 거래처 
           CASE WHEN E.UMCustKindName IS NULL OR LEN(E.UMCustKindName) = 0 THEN '' 
           	ELSE  SUBSTRING(E.UMCustKindName, 1,  LEN(E.UMCustKindName) -1 ) END   AS UMCustKindName, -- 거래처종류
           F.CustName			AS AGCustName,  -- 실화주 
           B.BizUnitName,   -- 사업부문
           A.ShipSeq, 
           A.ShipSerl, 
           G.IFShipCode + '-' + LEFT(ShipSerlNo,4) + '-' + RIGHT(ShipSerlNo,3) AS ShipSerlNo, -- 모선항차 
           H.EnShipName,    -- 모선 
           H.LOA,           -- LOA
           
           CASE WHEN A.ShipSeq = 0 OR A.ShipSeq IS NULL THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815002) 
                ELSE (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815001) 
                END AS UMWorkDivision, --작업구분
           
           A.UMWorkType,    -- 작업항목코드 
           I.MinorName AS UMWorkTypeName, -- 작업항목
           R.PlanQty AS GoodsQty, 
           R.PlanMTWeight AS GoodsMTWeight, 
           R.PlanCBMWeight AS GoodsCBMWeight,

           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumQty END AS SumQty, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumMTWeight END AS SumMTWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumCBMWeight END AS SumCBMWeight, 

           A.UMWorkTeam, 
           Q.MinorName AS UMWorkTeamName, 
           A.TodayQty, 
           A.TodayMTWeight, 
           A.TodayCBMWeight, 

           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(R.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(R.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(R.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight, -- 잔여CBM
           
           A.ExtraGroupSeq, 
           O.MultiExtraName, -- 할증구분 

           A.WorkSrtTime, -- 작업시작시간 
           A.WorkEndTime, -- 작업종료시간 
           A.RealWorkTime, -- 실작업시간 
           A.EmpSeq, 
           L.EmpName,    -- 총괄포맨 
           ISNULL(M.UMBisWorkTypeCnt,0) AS UMBisWorkTypeCnt, -- 업무구분Cnt
           G.AgentName, -- 대리점 
           A.DRemark, 
           A.MRemark, 
           A.ManRemark,
           A.UMWeather, 
           N.MinorName AS UMWeatherName, -- 날씨 
           A.UMLoadType, -- 하역방식코드 
           S.MinorName AS UMLoadTypeName -- 하역방식 
      FROM mnpt_TPJTWorkReport      AS A 
      LEFT OUTER JOIN _TPJTProject  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN ( -- 거래처종류 가로로 나열
                        SELECT CustSeq,
								(
                                    SELECT Y.Minorname + ','
                                      FROM _TDACustKind         AS Z 
                                      LEFT OUTER JOIN _TDAUMinor AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMCustKind ) 
                                     WHERE Z.CompanySeq	= @CompanySeq
                                       AND Z.CustSeq = Q.CustSeq
                                     ORDER BY CustSeq for xml path('')
                                ) AS UMCustKindName
                          FROM _TDACust AS Q
                         WHERE CompanySeq = @CompanySeq
                         GROUP BY CustSeq
                      ) AS E ON ( E.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = P.AGCustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkType )
      LEFT OUTER JOIN mnpt_TPJTProject      AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = P.PJTSeq ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT PJTSeq, 
                               UMWorkType, 
                               SUM(TodayQty) AS SumQty, 
                               SUM(TodayMTWeight) AS SumMTWeight, 
                               SUM(TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkReport
                         WHERE CompanySeq = @CompanySeq 
                           AND WorkDate < @WorkDate 
                        GROUP BY PJTSeq, UMWorkType 
                      ) AS K ON ( K.PJTSeq = A.PJTSeq AND K.UMWorkType = A.UMWorkType ) 
      LEFT OUTER JOIN _TDAEmp           AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkPlanItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkPlanSeq 
                      ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN #ReportGroupExtraName AS O ON ( O.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = A.UMWorkTeam ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS RR ON ( RR.CompanySeq = @CompanySeq AND RR.MinorSeq = A.UMWorkType AND RR.Serl = 1000001 ) 
      LEFT OUTER JOIN ( -- 전일 누계
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS SumQty, 
                               SUM(Z.TodayMTWeight) AS SumMTWeight, 
                               SUM(Z.TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkReport AS Z 
                          LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WorkDate < @WorkDate 
                        GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS KK ON ( KK.PJTSeq = A.PJTSeq 
                               AND KK.ShipSeq = A.ShipSeq 
                               AND KK.ShipSerl = A.ShipSerl 
                               AND KK.UMWorkType = CASE WHEN ISNULL(RR.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                 ) 
      LEFT OUTER JOIN ( -- 금일 작업
                        SELECT Z.PJTSeq, 
                               Z.ShipSeq, 
                               Z.ShipSerl, 
                               CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END AS UMWorkType, 
                               SUM(Z.TodayQty) AS TodayQty, 
                               SUM(Z.TodayMTWeight) AS TodayMTWeight, 
                               SUM(Z.TodayCBMWeight) AS TodayCBMWeight
                            FROM mnpt_TPJTWorkReport AS Z 
                            LEFT OUTER JOIN _TDAUMinorValue AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMWorkType AND Y.Serl = 1000001 ) 
                           WHERE Z.CompanySeq = @CompanySeq
                             AND Z.WorkDate = @WorkDate
                           GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, CASE WHEN ISNULL(Y.ValueText,'0') = '1' THEN 999 ELSE Z.UMWorkType END
                      ) AS W ON ( W.PJTSeq = A.PJTSeq 
                              AND W.ShipSeq = A.ShipSeq 
                              AND W.ShipSerl = A.ShipSerl 
                              AND W.UMWorkType = CASE WHEN ISNULL(RR.ValueText,'0') = '1' THEN 999 ELSE A.UMWorkType END 
                                ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish AS R ON ( R.CompanySeq = @CompanySeq AND R.PJTSeq = A.PJTSeq AND R.ShipSeq = R.ShipSeq AND R.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAUMinor                  AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = A.UMLoadType ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
       
    UNION ALL 
    
    --------------------------------------------------
    -- 작업계획 최종조회 
    --------------------------------------------------
    SELECT 0 AS WorkPalnSeq, 
           A.WorkPlanSeq,
           '0' AS IsCfm,  
           A.PJTSeq,        -- 프로젝트코드
           P.PJTName,       -- 프로젝트명
           P.PJTNo,         -- 프로젝트번호 
           C.PJTTypeName,   -- PJTTypeName
           D.CustName,      -- 거래처 
           CASE WHEN E.UMCustKindName IS NULL OR LEN(E.UMCustKindName) = 0 THEN '' 
           	ELSE  SUBSTRING(E.UMCustKindName, 1,  LEN(E.UMCustKindName) -1 ) END   AS UMCustKindName, -- 거래처종류
           F.CustName			AS AGCustName,  -- 실화주 
           B.BizUnitName,   -- 사업부문
           A.ShipSeq, 
           A.ShipSerl, 
           G.IFShipCode + '-' + LEFT(ShipSerlNo,4) + '-' + RIGHT(ShipSerlNo,3) AS ShipSerlNo, -- 모선항차 
           H.EnShipName,    -- 모선 
           H.LOA,           -- LOA
           
           CASE WHEN A.ShipSeq = 0 OR A.ShipSeq IS NULL THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815002) 
                ELSE (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815001) 
                END AS UMWorkDivision, --작업구분
           
           A.UMWorkType,    -- 작업항목코드 
           I.MinorName AS UMWorkTypeName, -- 작업항목
           R.PlanQty AS GoodsQty, 
           R.PlanMTWeight AS GoodsMTWeight, 
           R.PlanCBMWeight AS GoodsCBMWeight,
           0 AS SumQty, 
           0 AS SumMTWeight, 
           0 AS SumCBMWeight, 

           A.UMWorkTeam, 
           Q.MinorName AS UMWorkTeamName, 
           A.TodayQty, 
           A.TodayMTWeight, 
           A.TodayCBMWeight, 
           --ISNULL(J.GoodsQty,0) - (ISNULL(K.SumQty,0) + ISNULL(W.TodayQty,0)) AS EtcQty, -- 잔여수량
           --ISNULL(J.GoodsMTWeight,0) - (ISNULL(K.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) AS EtcMTWeight, -- 잔여MT
           --ISNULL(J.GoodsCBMWeight,0) - (ISNULL(K.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) AS EtcCBMWeight, -- 잔여CBM

           0 AS EtcQty, -- 잔여수량
           0 AS EtcMTWeight, -- 잔여MT
           0 AS EtcCBMWeight, -- 잔여CBM
           
           A.ExtraGroupSeq, 
           O.MultiExtraName, -- 할증구분 

           A.WorkSrtTime, -- 작업시작시간 
           A.WorkEndTime, -- 작업종료시간 
           A.RealWorkTime, -- 실작업시간 
           A.EmpSeq, 
           L.EmpName,    -- 총괄포맨 
           0 AS UMBisWorkTypeCnt, -- 업무구분Cnt
           G.AgentName, -- 대리점 
           A.DRemark, 
           A.MRemark, 
           A.ManRemark, 
           A.UMWeather, 
           N.MinorName AS UMWeatherName, -- 날씨 
           A.UMLoadType, -- 하역방식코드 
           S.MinorName AS UMLoadTypeName -- 하역방식 
      FROM mnpt_TPJTWorkPlan      AS A 
      LEFT OUTER JOIN _TPJTProject  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN ( -- 거래처종류 가로로 나열
                        SELECT CustSeq,
								(
                                    SELECT Y.Minorname + ','
                                      FROM _TDACustKind         AS Z 
                                      LEFT OUTER JOIN _TDAUMinor AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMCustKind ) 
                                     WHERE Z.CompanySeq	= @CompanySeq
                                       AND Z.CustSeq = Q.CustSeq
                                     ORDER BY CustSeq for xml path('')
                                ) AS UMCustKindName
                          FROM _TDACust AS Q
                         WHERE CompanySeq = @CompanySeq
                         GROUP BY CustSeq
                      ) AS E ON ( E.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN _TDACust      AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = P.AGCustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS G ON ( G.CompanySeq = @CompanySeq AND G.ShipSeq = A.ShipSeq AND G.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = G.ShipSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkType )
      LEFT OUTER JOIN mnpt_TPJTProject      AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = P.PJTSeq ) 
      --LEFT OUTER JOIN ( -- 전일 누계
      --                  SELECT PJTSeq, 
      --                         UMWorkType, 
      --                         SUM(TodayQty) AS SumQty, 
      --                         SUM(TodayMTWeight) AS SumMTWeight, 
      --                         SUM(TodayCBMWeight) AS SumCBMWeight
      --                    FROM mnpt_TPJTWorkPlan 
      --                   WHERE CompanySeq = @CompanySeq 
      --                     AND WorkDate < @WorkDate 
      --                  GROUP BY PJTSeq, UMWorkType 
      --                ) AS K ON ( K.PJTSeq = A.PJTSeq AND K.UMWorkType = A.UMWorkType ) 
      LEFT OUTER JOIN _TDAEmp           AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      --LEFT OUTER JOIN (
      --                  SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
      --                    FROM mnpt_TPJTWorkPlanItem AS Z 
      --                   WHERE Z.CompanySeq = @CompanySeq 
      --                   GROUP BY Z.WorkPlanSeq 
      --                ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN #GroupExtraName   AS O ON ( O.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = A.UMWorkTeam ) 
      LEFT OUTER JOIN ( -- 금일 작업
                        SELECT A.PJTSeq, 
                               A.UMWorkType, 
                               SUM(A.TodayQty) AS TodayQty, 
                               SUM(A.TodayMTWeight) AS TodayMTWeight, 
                               SUM(A.TodayCBMWeight) AS TodayCBMWeight
                          FROM mnpt_TPJTWorkPlan AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.WorkDate = @WorkDate
                         GROUP BY A.PJTSeq, A.UMWorkType
                      ) AS W ON ( W.PJTSeq = A.PJTSeq AND W.UMWorkType = A.UMWorkType ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish AS R ON ( R.CompanySeq = @CompanySeq AND R.PJTSeq = A.PJTSeq AND R.ShipSeq = R.ShipSeq AND R.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAUMinor                  AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = A.UMLoadType ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
       AND NOT EXISTS (SELECT 1 FROM mnpt_TPJTWorkReport WHERE CompanySeq = A.CompanySeq AND WorkPlanSeq = A.WorkPlanSeq ) 
       AND A.IsCfm = '1' 
     ORDER BY PJTName, WorkSrtTime

    RETURN     
 

 go
 begin tran 
 DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END

IF @CONST_#BIZ_IN_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock3
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

        , IsDUnionDay CHAR(1), IsDUnionHalf CHAR(1), IsDUnionMonth CHAR(1), IsDDailyDay CHAR(1), IsDDailyHalf CHAR(1), IsDDailyMonth CHAR(1), IsDOSDay CHAR(1), IsDOSHalf CHAR(1), IsDOSMonth CHAR(1), IsDEtcDay CHAR(1), IsDEtcHalf CHAR(1), IsDEtcMonth CHAR(1), IsNDUnionDailyDay CHAR(1), IsNDUnionDailyHalf CHAR(1), IsNDUnionDailyMonth CHAR(1), IsNDUnionSignalDay CHAR(1), IsNDUnionSignalHalf CHAR(1), IsNDUnionSignalMonth CHAR(1), IsNDUnionEtcDay CHAR(1), IsNDUnionEtcHalf CHAR(1), IsNDUnionEtcMonth CHAR(1), IsNDDailyDay CHAR(1), IsNDDailyHalf CHAR(1), IsNDDailyMonth CHAR(1), IsNDOSDay CHAR(1), IsNDOSHalf CHAR(1), IsNDOSMonth CHAR(1), IsNDEtcDay CHAR(1), IsNDEtcHalf CHAR(1), IsNDEtcMonth CHAR(1)
    )
    
    SET @CONST_#BIZ_IN_DataBlock3 = 1

END

IF @CONST_#BIZ_OUT_DataBlock3 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock3
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

        , IsDUnionDay CHAR(1), IsDUnionHalf CHAR(1), IsDUnionMonth CHAR(1), IsDDailyDay CHAR(1), IsDDailyHalf CHAR(1), IsDDailyMonth CHAR(1), IsDOSDay CHAR(1), IsDOSHalf CHAR(1), IsDOSMonth CHAR(1), IsDEtcDay CHAR(1), IsDEtcHalf CHAR(1), IsDEtcMonth CHAR(1), IsNDUnionDailyDay CHAR(1), IsNDUnionDailyHalf CHAR(1), IsNDUnionDailyMonth CHAR(1), IsNDUnionSignalDay CHAR(1), IsNDUnionSignalHalf CHAR(1), IsNDUnionSignalMonth CHAR(1), IsNDUnionEtcDay CHAR(1), IsNDUnionEtcHalf CHAR(1), IsNDUnionEtcMonth CHAR(1), IsNDDailyDay CHAR(1), IsNDDailyHalf CHAR(1), IsNDDailyMonth CHAR(1), IsNDOSDay CHAR(1), IsNDOSHalf CHAR(1), IsNDOSMonth CHAR(1), IsNDEtcDay CHAR(1), IsNDEtcHalf CHAR(1), IsNDEtcMonth CHAR(1)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkDate) 
SELECT N'U', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'20171030'
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

SET @ServiceSeq     = 13820024
--SET @MethodSeq      = 6
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820019
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportWorkPlanData            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3rollback 