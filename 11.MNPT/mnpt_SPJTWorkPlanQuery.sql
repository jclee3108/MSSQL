     
IF OBJECT_ID('mnpt_SPJTWorkPlanQuery') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanQuery  
GO  
    
-- v2017.09.13
  
-- 작업계획입력-SS1조회 by 이재천
CREATE PROC mnpt_SPJTWorkPlanQuery      
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
           S.PlanQty AS GoodsQty, 
           S.PlanMTWeight AS GoodsMTWeight, 
           S.PlanCBMWeight AS GoodsCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumQty END AS SumQty, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumMTWeight END AS SumMTWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE K.SumCBMWeight END AS SumCBMWeight, 

           A.UMWorkTeam, 
           Q.MinorName AS UMWorkTeamName, 
           A.TodayQty, 
           A.TodayMTWeight, 
           A.TodayCBMWeight, 
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanQty,0) - (ISNULL(KK.SumQty,0) + ISNULL(W.TodayQty,0)) END AS EtcQty, -- 잔여수량
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanMTWeight,0) - (ISNULL(KK.SumMTWeight,0) + ISNULL(W.TodayMTWeight,0)) END AS EtcMTWeight, -- 잔여MT
           CASE WHEN ISNULL(A.ShipSerl,0) = 0 THEN 0 ELSE ISNULL(S.PlanCBMWeight,0) - (ISNULL(KK.SumCBMWeight,0) + ISNULL(W.TodayCBMWeight,0)) END AS EtcCBMWeight, -- 잔여CBM
           
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
           A.SourceWorkPlanSeq, 
           A.UMLoadType, 
           T.MinorName AS UMLoadTypeName
      FROM mnpt_TPJTWorkPlan        AS A 
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
      LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
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
      LEFT OUTER JOIN _TDAUMinor                    AS T ON ( T.CompanySeq = @CompanySeq AND T.MinorSeq = A.UMLoadType ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
     ORDER BY P.PJTName, A.WorkSrtTime
    
    RETURN     
 