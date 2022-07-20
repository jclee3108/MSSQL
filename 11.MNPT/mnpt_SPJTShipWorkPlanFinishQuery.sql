IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SPJTShipWorkPlanFinishQuery'))
DROP PROCEDURE dbo.mnpt_SPJTShipWorkPlanFinishQuery
GO       
-- v2018.01.10
  
-- 본선작업계획완료입력-조회 by 이재천
CREATE PROC mnpt_SPJTShipWorkPlanFinishQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @IFShipCode      NVARCHAR(100),   
            @SerlYear        NCHAR(4),   
            @SerlNo          NVARCHAR(100),   
            @PJTNo           NVARCHAR(200),   
            @ContractName    NVARCHAR(200),   
            @PJTName         NVARCHAR(200),   
            @DockPJTName     NVARCHAR(200),   
            @FrWorkDate      NCHAR(8), 
            @ToWorkDate      NCHAR(8), 
            @FrContractDate  NCHAR(8), 
            @ToContractDate  NCHAR(8), 
            @BizUnit         INT, 
            @CustSeq         INT, 
            @ShipSeq         INT, 
            @PJTTypeSeq      INT, 
            @FinishType      INT, 
            @ShipSerlNo      NVARCHAR(200),
            @InDateFr        NCHAR(8), 
            @InDateTo        NCHAR(8), 
            @ApproachDateFr  NCHAR(8), 
            @ApproachDateTo  NCHAR(8), 
            @OutDateFr       NCHAR(8), 
            @OutDateTo       NCHAR(8), 
            @OldInDateTo     NCHAR(8), 
            @OldApproachDateTo  NCHAR(8), 
            @OldOutDateTo    NCHAR(8) 


    
    SELECT @IFShipCode        = ISNULL( IFShipCode      , '' ),   
           @SerlYear          = ISNULL( SerlYear        , '' ),   
           @SerlNo            = ISNULL( SerlNo          , '' ),   
           @PJTNo             = ISNULL( PJTNo           , '' ),   
           @ContractName      = ISNULL( ContractName    , '' ),   
           @PJTName           = ISNULL( PJTName         , '' ),   
           @DockPJTName       = ISNULL( DockPJTName     , '' ),   
           @FrWorkDate        = ISNULL( FrWorkDate      , '' ),   
           @ToWorkDate        = ISNULL( ToWorkDate      , '' ),   
           @FrContractDate    = ISNULL( FrContractDate  , '' ),   
           @ToContractDate    = ISNULL( ToContractDate  , '' ),   
           @BizUnit           = ISNULL( BizUnit         , 0 ),   
           @CustSeq           = ISNULL( CustSeq         , 0 ),   
           @ShipSeq           = ISNULL( ShipSeq         , 0 ),   
           @PJTTypeSeq        = ISNULL( PJTTypeSeq      , 0 ),   
           @FinishType        = ISNULL( FinishType      , 0 ), 
           @InDateFr          = ISNULL( InDateFr        , ''), 
           @InDateTo          = ISNULL( InDateTo        , ''),   
           @ApproachDateFr    = ISNULL( ApproachDateFr  , ''),
           @ApproachDateTo    = ISNULL( ApproachDateTo  , ''),
           @OutDateFr         = ISNULL( OutDateFr       , ''),
           @OutDateTo         = ISNULL( OutDateTo       , ''),
           @OldInDateTo       = ISNULL( InDateTo        , ''),   
           @OldApproachDateTo = ISNULL( ApproachDateTo  , ''),
           @OldOutDateTo      = ISNULL( OutDateTo       , '')
      FROM #BIZ_IN_DataBlock1    
    


    IF @ToWorkDate = '' SELECT @ToWorkDate = '99991231'
    IF @ToContractDate = '' SELECT @ToContractDate = '99991231' 
    IF @InDateTo = '' SELECT @InDateTo = '99991231'
    IF @ApproachDateTo = '' SELECT @ApproachDateTo = '99991231'
    IF @OutDateTo = '' SELECT @OutDateTo = '99991231'

    SELECT @ShipSerlNo = @IFShipCode + @SerlYear + @SerlNo 

    SELECT @ShipSerlNo = LTRIM(RTRIM(@ShipSerlNo))

    -- 등록된 모선정보
    SELECT A.ShipPlanFinishSeq, -- 내부코드 
           A.ShipSeq, 
           A.ShipSerl, 
           H.IFShipCode + '-' + LEFT(H.ShipSerlNo,4) + '-' + RIGHT(H.ShipSerlNo,3) AS ShipSerlNo, 
           I.EnShipName, 
           B.PJTName,
           B.PJTNo,
           A.PJTSeq, 
           A.DockPJTSeq, 
           K.PJTName AS DockPJTName, 
		   A.DockCustSeq,
		   L.CustName	AS DockCustName,
           E.BizUnitName,       -- 사업부문  
           D.ContractName,      -- 계약명 
		  D.ContractNo,        -- 계약번호 
           F.PJTTypeName,       -- 화태 
           G.CustName,           -- 거래처
           A.PlanQty, 
           A.PlanMTWeight, 
           A.PlanCBMWeight, 
           H.DiffApproachTime, 
           J.ChangeCnt, 
           STUFF(STUFF(LEFT(H.InPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(H.InPlanDateTime,4),3,0,':')   AS InPlanDateTime, -- 입항예정일시
           STUFF(STUFF(LEFT(H.OutPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(H.OutPlanDateTime,4),3,0,':') AS OutPlanDateTime, -- 출항예정일시
           A.IsCfm, 
           LEFT(H.InDateTime,8) AS InDate, 
           RIGHT(H.InDateTime,4) AS InTime, 
           LEFT(H.ApproachDateTime,8) AS ApproachDate, 
           RIGHT(H.ApproachDateTime,4) AS ApproachTime, 
           LEFT(H.OutDateTime,8) AS OutDate, 
           RIGHT(H.OutDateTime,4) AS OutTime,
           CASE WHEN EXISTS (SELECT 1 FROM mnpt_TPJTWorkPlan WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq AND ShipSeq = A.ShipSeq ANd ShipSerl = A.ShipSerl) 
                THEN '1' 
                ELSE '0' 
                END AS IsPlanExists
      INTO #mnpt_TPJTShipWorkPlanFinish
      FROM mnpt_TPJTShipWorkPlanFinish      AS A 
      LEFT OUTER JOIN _TPJTProject          AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN mnpt_TPJTProject      AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = B.PJTSeq ) 
      LEFT OUTER JOIN mnpt_TPJTContract     AS D ON ( D.CompanySeq = @CompanySeq AND D.ContractSeq = C.ContractSeq ) 
      LEFT OUTER JOIN _TDABizUnit           AS E ON ( E.CompanySeq = @CompanySeq AND E.BizUnit = D.BizUnit ) 
      LEFT OUTER JOIN _TPJTType             AS F ON ( F.CompanySeq = @CompanySeq AND F.PJTTypeSeq = B.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust              AS G ON ( G.CompanySeq = @CompanySeq AND G.CustSeq = D.CustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = A.ShipSeq AND H.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS I ON ( I.CompanySeq = @CompanySeq AND I.ShipSeq = H.ShipSeq ) 
      LEFT OUTER JOIN (
                        SELECT ShipSeq, ShipSerl, COUNT(1) AS ChangeCnt
                          FROM mnpt_TPJTShipDetailChange 
                         WHERE CompanySeq = @CompanySeq
                         GROUP BY ShipSeq, ShipSerl 
                      ) AS J ON ( J.ShipSeq = A.ShipSeq AND J.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TPJTProject          AS K ON ( K.CompanySeq = @CompanySeq AND K.PJTSeq = A.DockPJTSeq ) 
	  LEFT OUTER JOIN _TDACust				AS L ON ( L.CompanySeq	= A.CompanySeq AND L.CustSeq = A.DockCustSeq)
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @ShipSerlNo = '' OR H.IFShipCode + H.ShipSerlNo LIKE @ShipSerlNo +'%' ) 
       AND ( @BizUnit = 0 OR D.BizUnit = @BizUnit ) 
       AND ( @CustSeq = 0 OR D.CustSeq = @CustSeq ) 
       AND ( @PJTNo = '' OR B.PJTNo LIKE @PJTNo + '%' ) 
       AND ( @ShipSeq = 0 OR A.ShipSeq = @ShipSeq ) 
       AND ( @ContractName = '' OR D.ContractName LIKE @ContractName + '%' ) 
       AND ( @PJTTypeSeq = 0 OR B.PJTTypeSeq = @PJTTypeSeq ) 
       AND ( @PJTName = '' OR B.PJTName LIKE @PJTName + '%' ) 
       AND ( (ISNULL(D.ContractFrDate,'') BETWEEN @FrContractDate AND @ToContractDate) OR (ISNULL(D.ContractToDate,'') BETWEEN @FrContractDate AND @ToContractDate) ) 
       AND ( @FinishType = 0 OR A.IsCfm = CASE WHEN @FinishType = 1 THEN '1' ELSE '0' END ) 
       AND ( @DockPJTName = '' OR K.PJTName LIKE @DockPJTName + '%' ) 
       AND ( (@InDateFr = '' AND @OldInDateTo = '' AND ISNULL(LEFT(H.InDateTime,8),'') = '') OR (ISNULL(LEFT(H.InDateTime,8),'') BETWEEN @InDateFr AND @InDateTo) ) 
       AND ( (@ApproachDateFr = '' AND @OldApproachDateTo = '' AND ISNULL(LEFT(H.ApproachDateTime,8),'') = '') OR (ISNULL(LEFT(H.ApproachDateTime,8),'') BETWEEN @ApproachDateFr AND @ApproachDateTo) ) 
       AND ( (@OutDateFr = '' AND @OldOutDateTo = '' AND ISNULL(LEFT(H.OutDateTime,8),'') = '') OR (ISNULL(LEFT(H.OutDateTime,8),'') BETWEEN @OutDateFr AND @OutDateTo) ) 
    
    SELECT A.PJTSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.TodayQty, 
           A.TodayMTWeight, 
           A.TodayCBMWeight, 
           CASE WHEN A.IsCfm = '1' AND ISNULL(C.IsCfm,'1') = '1' THEN '1' ELSE '0' END AS IsCfm, -- Master,Detail 모두 승인되었을 경우 승인으로 본다.
           A.UMWorkType, 
           A.WorkDate, 
           A.WorkDate + CASE WHEN A.WorkSrtTime = '' THEN '0000' ELSE A.WorkSrtTime END AS WorkSrtDateTime,
           A.WorkDate + CASE WHEN A.WorkEndTime = '' THEN '0000' ELSE A.WorkEndTime END AS WorkEndDateTime
      INTO #mnpt_TPJTWorkReport
      FROM mnpt_TPJTWorkReport          AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMWorkType AND B.Serl = 1000001 ) 
      OUTER APPLY ( SELECT Z.WorkReportSeq, MIN(ISNULL(IsCfm,'0')) AS IsCfm 
                      FROM mnpt_TPJTWorkReportItem AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkReportSeq = A.WorkReportSEq 
                     GROUP BY Z.WorkReportSeq 
                  ) AS C 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.ValueText = '1' 
       AND EXISTS ( 
                    SELECT 1 
                      FROM mnpt_TPJTWorkReport          AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WorkDate BETWEEN @FrWorkDate AND @ToWorkDate 
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl 
                       AND Z.PJTSeq = A.PJTSeq 
                  ) 
    
    -- 작업실적 데이터
    SELECT A.PJTSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           Count(1) AS Cnt, 
           MIN(B.MinorName) + CASE WHEN COUNT(1) > 1 THEN ' 외 ' + CONVERT(NVARCHAR(10),COUNT(1) - 1) ELSE '' END AS UMWorkTypeName, 
           SUM(A.TodayQty) AS ResultQty, 
           SUM(A.TodayMTWeight) AS ResultMTWeight, 
           SUM(A.TodayCBMWeight) AS ResultCBMWeight, 
           MIN(ISNULL(A.IsCfm, '0')) AS IsReportCfm, -- 작업실적승인 
           MAX(C.WorkDayCnt) AS WorkDayCnt,  -- 작업일수 
           LEFT(MIN(A.WorkSrtDateTime),8) AS WorkSrtDate, -- 하역개시일
           RIGHT(MIN(A.WorkSrtDateTime),4) AS WorkSrtTime, -- 하역개시시각
           LEFT(MAX(A.WorkEndDateTime),8) AS WorkEndDate, -- 하역개시일
           RIGHT(MAX(A.WorkEndDateTime),4) AS WorkEndTime -- 하역개시시각
      INTO #Report
      FROM #mnpt_TPJTWorkReport          AS A 
      LEFT OUTER JOIN _TDAUMinor         AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMWorkType ) 
      LEFT OUTER JOIN ( -- 작업일수 
                        SELECT Y.PJTSeq, Y.ShipSeq, Y.ShipSerl, COUNT(1) AS WorkDayCnt
                          FROM ( 
                                SELECT DISTINCT Z.PJTSeq, Z.ShipSeq, Z.ShipSerl, Z.WorkDate
                                  FROM #mnpt_TPJTWorkReport AS Z 
                                ) AS Y 
                         GROUP BY Y.PJTSeq, Y.ShipSeq, Y.ShipSerl
                      ) AS C ON ( C.PJTSeq = A.PJTSeq AND C.ShipSeq = A.ShipSeq AND C.ShipSerl = A.ShipSerl ) 
     GROUP BY A.PJTSeq, A.ShipSeq, A.ShipSerl 
    
    SELECT A.ShipPlanFinishSeq, -- 내부코드 
           A.ShipSeq, 
           A.ShipSerl, 
           A.ShipSerlNo, 
           A.EnShipName, 
           A.PJTName,
           A.PJTNo,
           A.PJTSeq, 
           A.DockPJTSeq, 
           A.DockPJTName, 
		   A.DockCustSeq,
		   A.DockCustName,
           A.BizUnitName,       -- 사업부문  
           A.ContractName,      -- 계약명 
           A.ContractNo,        -- 계약번호 
           A.PJTTypeName,       -- 화태 
           A.CustName,           -- 거래처
           A.PlanQty, 
           A.PlanMTWeight, 
           A.PlanCBMWeight, 
           A.DiffApproachTime, 
           A.ChangeCnt, 
           A.InPlanDateTime, -- 입항예정일시
           A.OutPlanDateTime, -- 출항예정일시
           A.IsCfm, 
           A.InDate, 
           A.InTime, 
           A.ApproachDate, 
           A.ApproachTime, 
           A.OutDate, 
           A.OutTime,
           A.IsPlanExists,
           A.PJTSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           B.Cnt, 
           B.UMWorkTypeName, 
           B.ResultQty, 
           B.ResultMTWeight, 
           B.ResultCBMWeight, 
           B.IsReportCfm AS IsReportCfm, -- 작업실적승인 
           B.WorkDayCnt,  -- 작업일수 
           B.WorkSrtDate, -- 하역개시일
           B.WorkSrtTime, -- 하역개시시각
           B.WorkEndDate, -- 하역개시일
           B.WorkEndTime -- 하역개시시각
      FROM #mnpt_TPJTShipWorkPlanFinish AS A 
      LEFT OUTER JOIN #Report           AS B ON ( B.PJTSeq = A.PJTSeq AND B.ShipSeq = A.ShipSeq AND B.ShipSerl = A.ShipSerl ) 
     WHERE IsPlanExists = '0' OR B.ShipSeq IS NOT NULL 
    RETURN     
go

begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
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

        , IFShipCode NVARCHAR(100), SerlYear CHAR(4), SerlNo NVARCHAR(100), PJTNo NVARCHAR(200), ContractName NVARCHAR(200), PJTName NVARCHAR(200), FrWorkDate CHAR(8), ToWorkDate CHAR(8), FrContractDate CHAR(8), ToContractDate CHAR(8), BizUnit INT, CustSeq INT, ShipSeq INT, PJTTypeSeq INT, FinishType INT, DockPJTName NVARCHAR(200), InDateFr CHAR(8), InDateTo CHAR(8), ApproachDateFr CHAR(8), ApproachDateTo CHAR(8), OutDateFr CHAR(8), OutDateTo CHAR(8)
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

        , IFShipCode NVARCHAR(100), SerlYear CHAR(4), SerlNo NVARCHAR(100), BizUnitName NVARCHAR(200), CustName NVARCHAR(200), PJTNo NVARCHAR(200), EnShipName NVARCHAR(200), ContractName NVARCHAR(200), PJTTypeName NVARCHAR(200), PJTName NVARCHAR(200), FrWorkDate CHAR(8), ToWorkDate CHAR(8), FrContractDate CHAR(8), ToContractDate CHAR(8), BizUnit INT, CustSeq INT, ShipSeq INT, PJTTypeSeq INT, ShipSerlNo NVARCHAR(200), ShipSerl INT, PJTSeq INT, PlanQty DECIMAL(19, 5), PlanMTWeight DECIMAL(19, 5), PlanCBMWeight DECIMAL(19, 5), WorkDayCnt INT, UMWorkTypeName NVARCHAR(200), ResultQty DECIMAL(19, 5), ResultMTWeight DECIMAL(19, 5), ResultCBMWeight DECIMAL(19, 5), IsReportCfm CHAR(1), IsCfm CHAR(1), InDate CHAR(8), InTime NVARCHAR(5), ApproachDate CHAR(8), ApproachTime NVARCHAR(5), WorkSrtDate CHAR(8), WorkSrtTime NVARCHAR(5), WorkEndDate CHAR(8), WorkEndTime NVARCHAR(5), OutDate CHAR(8), OutTime NVARCHAR(5), ChangeCnt INT, DiffApproachTime DECIMAL(19, 5), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), ShipPlanFinishSeq INT, FinishTypeName NVARCHAR(200), FinishType INT, IsPlanExists CHAR(1), DockPJTName NVARCHAR(200), DockPJTSeq INT, DockCustSeq INT, DockCustName NVARCHAR(100), InDateFr CHAR(8), InDateTo CHAR(8), ApproachDateFr CHAR(8), ApproachDateTo CHAR(8), OutDateFr CHAR(8), OutDateTo CHAR(8)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, IFShipCode, SerlYear, SerlNo, PJTNo, ContractName, PJTName, FrWorkDate, ToWorkDate, FrContractDate, ToContractDate, BizUnit, CustSeq, ShipSeq, PJTTypeSeq, FinishType, DockPJTName, InDateFr, InDateTo, ApproachDateFr, ApproachDateTo, OutDateFr, OutDateTo) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'ILCB', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820029
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 1
SET @PgmSeq         = 13820024
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipWorkPlanFinishQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 