     
IF OBJECT_ID('mnpt_SPJTWorkReportQuery') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportQuery  
GO  
    
-- v2018.02.01
  
-- 작업실적입력-SS1조회 by 이재천
CREATE PROC mnpt_SPJTWorkReportQuery      
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
        WorkReportSeq   INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkReportSeq, ExtraGroupSeq ) 
    SELECT WorkReportSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkReport 
     WHERE CompanySeq = @CompanySeq 
       AND WorkDate = @WorKDate 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkReportSeq   INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkReportSeq   INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkReportSeq  INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq   = ExtraGroupSeq, 
               @WorkReportSeq   = WorkReportSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkReportSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkReportSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkReportSeq, MultiExtraName ) 
        SELECT @WorkReportSeq, STUFF(@ExtraGroupName,1,1,'')


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
    SELECT A.WorkReportSeq,
           A.IsCfm,  
           A.PJTSeq,        -- 프로젝트코드
           --A.PJTSeq AS PJTSeqOld, 
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
           A.WorkPlanSeq, 
           SS.IsCfmDetail, 
           A.UMLoadType, 
           RR.MinorName AS UMLoadTypeName
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
                               ShipSeq, 
                               ShipSerl, 
                               SUM(TodayQty) AS SumQty, 
                               SUM(TodayMTWeight) AS SumMTWeight, 
                               SUM(TodayCBMWeight) AS SumCBMWeight
                          FROM mnpt_TPJTWorkReport 
                         WHERE CompanySeq = @CompanySeq 
                           AND WorkDate < @WorkDate 
                        GROUP BY PJTSeq, UMWorkType, ShipSeq, ShipSerl 
                      ) AS K ON ( K.PJTSeq = A.PJTSeq AND K.UMWorkType = A.UMWorkType AND K.ShipSeq = A.ShipSeq AND K.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAEmp           AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.WorkReportSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkReportItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkReportSeq 
                      ) AS M ON ( M.WorkReportSeq = A.WorkReportSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMWeather ) 
      LEFT OUTER JOIN #GroupExtraName   AS O ON ( O.WorkReportSeq = A.WorkReportSeq ) 
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
                          FROM mnpt_TPJTWorkReport AS Z 
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
                            FROM mnpt_TPJTWorkReport AS Z 
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
      LEFT OUTER JOIN (SELECT MAX(ISNULL(Z.IsCfm,'0')) AS IsCfmDetail 
                         FROM mnpt_TPJTWorkReportItem   AS Z 
                         JOIN mnpt_TPJTWorkReport       AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.WorkReportSeq = Z.WorkReportSeq ) 
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Y.WorkDate = @WorkDate 
                      ) AS SS ON ( 1 = 1 ) 
      LEFT OUTER JOIN _TDAUMinor                  AS RR ON ( RR.CompanySeq = @CompanySeq AND RR.MinorSeq = A.UMLoadType ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.WorkDate = @WorkDate   
     ORDER BY P.PJTName, A.WorkSrtTime
    
    RETURN     
 


 go

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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000), IsCfmDetail CHAR(1)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), SubWorkPlanSeq INT, IsCfmDetail CHAR(1), WorkDate CHAR(8)
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

        , UMBisWorkTypeName NVARCHAR(200), UMBisWorkType INT, SelfToolName NVARCHAR(200), SelfToolSeq INT, RentToolName NVARCHAR(200), RentToolSeq INT, ToolWorkTime DECIMAL(19, 5), DriverEmpName1 NVARCHAR(200), DriverEmpSeq1 INT, DriverEmpName2 NVARCHAR(200), DriverEmpSeq2 INT, DriverEmpName3 NVARCHAR(200), DriverEmpSeq3 INT, DUnionDay DECIMAL(19, 5), DUnionHalf DECIMAL(19, 5), DUnionMonth DECIMAL(19, 5), DDailyDay DECIMAL(19, 5), DDailyHalf DECIMAL(19, 5), DDailyMonth DECIMAL(19, 5), DOSDay DECIMAL(19, 5), DOSHalf DECIMAL(19, 5), DOSMonth DECIMAL(19, 5), DEtcDay DECIMAL(19, 5), DEtcHalf DECIMAL(19, 5), DEtcMonth DECIMAL(19, 5), NDEmpName NVARCHAR(200), NDEmpSeq INT, NDUnionUnloadGang DECIMAL(19, 5), NDUnionUnloadMan DECIMAL(19, 5), NDUnionDailyDay DECIMAL(19, 5), NDUnionDailyHalf DECIMAL(19, 5), NDUnionDailyMonth DECIMAL(19, 5), NDUnionSignalDay DECIMAL(19, 5), NDUnionSignalHalf DECIMAL(19, 5), NDUnionSignalMonth DECIMAL(19, 5), NDUnionEtcDay DECIMAL(19, 5), NDUnionEtcHalf DECIMAL(19, 5), NDUnionEtcMonth DECIMAL(19, 5), NDDailyDay DECIMAL(19, 5), NDDailyHalf DECIMAL(19, 5), NDDailyMonth DECIMAL(19, 5), NDOSDay DECIMAL(19, 5), NDOSHalf DECIMAL(19, 5), NDOSMonth DECIMAL(19, 5), NDEtcDay DECIMAL(19, 5), NDEtcHalf DECIMAL(19, 5), NDEtcMonth DECIMAL(19, 5), DRemark NVARCHAR(2000), WorkReportSeq INT, WorkReportSerl INT, IsMain CHAR(1), WorkPlanSeq NVARCHAR(100), WorkPlanSerl NVARCHAR(100), SubWorkPlanSeq INT, IsCfmDetail CHAR(1), WorkDate CHAR(8)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock2 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkDate) 
SELECT N'U', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20171102'
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
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820019
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkReportQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2rollback 