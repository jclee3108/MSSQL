     
IF OBJECT_ID('mnpt_SPJTWorkPlanItemQuery') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanItemQuery  
GO  
    
-- v2017.09.14
  
-- 작업계획입력-SS2조회 by 이재천
CREATE PROC mnpt_SPJTWorkPlanItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @WorkPlanSeq        INT, 
            @SourceWorkPlanSeq  INT, 
            @WorkDate           NCHAR(8), 
            @PJTTypeSeq         INT, 
            @StdSeq             INT, 
            @ExStdSeq           INT 
      
    SELECT @WorkPlanSeq = ISNULL( WorkPlanSeq, 0 ), 
           @SourceWorkPlanSeq = ISNULL( SourceWorkPlanSeq, 0 )
      FROM #BIZ_IN_DataBlock1 
    
    ------------------------------------------------------------------------
    -- 일대, 반일, 월대 HID 처리  ( 1 - 보임,  0 - 숨김 ) 
    ------------------------------------------------------------------------
    SELECT @WorkDate = A.WorkDate, 
           @PJTTypeSeq = B.PJTTypeSeq 
      FROM mnpt_TPJTWorkPlan    AS A 
      JOIN _TPJTProject         AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkPlanSeq = @WorkPlanSeq 
    
    -- 운전원노임단가 
    SELECT @StdSeq = Z.StdSeq 
      FROM mnpt_TPJTOperatorPriceMaster AS Z 
      JOIN ( 
            SELECT MAX(StdDate) AS StdDate 
             FROM mnpt_TPJTOperatorPriceMaster AS A 
            WHERE A.CompanySeq = @CompanySeq 
              AND A.StdDate <= @WorkDate 
           ) AS Y ON ( Y.StdDate = Z.StdDate ) 
    

    SELECT CASE WHEN MAX(A.UnDayPrice     )  > 0 THEN '1' ELSE '0' END IsDUnionDay,  
           CASE WHEN MAX(A.UnHalfPrice    )  > 0 THEN '1' ELSE '0' END IsDUnionHalf,  
           CASE WHEN MAX(A.UnMonthPrice   )  > 0 THEN '1' ELSE '0' END IsDUnionMonth, 
           CASE WHEN MAX(A.DailyDayPrice  )  > 0 THEN '1' ELSE '0' END IsDDailyDay, 
           CASE WHEN MAX(A.DailyHalfPrice )  > 0 THEN '1' ELSE '0' END IsDDailyHalf, 
           CASE WHEN MAX(A.DailyMonthPrice)  > 0 THEN '1' ELSE '0' END IsDDailyMonth, 
           CASE WHEN MAX(A.OSDayPrice     )  > 0 THEN '1' ELSE '0' END IsDOSDay, 
           CASE WHEN MAX(A.OSHalfPrice    )  > 0 THEN '1' ELSE '0' END IsDOSHalf, 
           CASE WHEN MAX(A.OSMonthPrice   )  > 0 THEN '1' ELSE '0' END IsDOSMonth, 
           CASE WHEN MAX(A.EtcDayPrice    )  > 0 THEN '1' ELSE '0' END IsDEtcDay, 
           CASE WHEN MAX(A.EtcHalfPrice   )  > 0 THEN '1' ELSE '0' END IsDEtcHalf, 
           CASE WHEN MAX(A.EtcMonthPrice  )  > 0 THEN '1' ELSE '0' END IsDEtcMonth 
      INTO #IsDPrice
      FROM mnpt_TPJTOperatorPriceSubItem AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @StdSeq 
       AND A.PJTTypeSeq = @PJTTypeSeq 
       
    -- 운전원노임단가 
    SELECT @ExStdSeq = Z.StdSeq 
      FROM mnpt_TPJTOperatorEXPriceMaster AS Z 
      JOIN ( 
            SELECT MAX(StdDate) AS StdDate 
             FROM mnpt_TPJTOperatorEXPriceMaster AS A 
            WHERE A.CompanySeq = @CompanySeq 
              AND A.StdDate <= @WorkDate 
           ) AS Y ON ( Y.StdDate = Z.StdDate ) 
    
    SELECT CASE WHEN A.UnDailyDayPrice      > 0 THEN '1' ELSE '0' END IsNDUnionDailyDay,  
           CASE WHEN A.UnDailyHalfPrice     > 0 THEN '1' ELSE '0' END IsNDUnionDailyHalf,  
           CASE WHEN A.UnDailyMonthPrice    > 0 THEN '1' ELSE '0' END IsNDUnionDailyMonth,  
           CASE WHEN A.UnSignalDayPrice     > 0 THEN '1' ELSE '0' END IsNDUnionSignalDay,  
           CASE WHEN A.UnSignalHalfPrice    > 0 THEN '1' ELSE '0' END IsNDUnionSignalHalf,  
           CASE WHEN A.UnSignalMonthPrice   > 0 THEN '1' ELSE '0' END IsNDUnionSignalMonth,  
           CASE WHEN A.UnEtcDayPrice        > 0 THEN '1' ELSE '0' END IsNDUnionEtcDay,  
           CASE WHEN A.UnEtcHalfPrice       > 0 THEN '1' ELSE '0' END IsNDUnionEtcHalf,  
           CASE WHEN A.UnEtcMonthPrice      > 0 THEN '1' ELSE '0' END IsNDUnionEtcMonth,  
           CASE WHEN A.DailyDayPrice        > 0 THEN '1' ELSE '0' END IsNDDailyDay,  
           CASE WHEN A.DailyHalfPrice       > 0 THEN '1' ELSE '0' END IsNDDailyHalf,  
           CASE WHEN A.DailyMonthPrice      > 0 THEN '1' ELSE '0' END IsNDDailyMonth,  
           CASE WHEN A.OSDayPrice           > 0 THEN '1' ELSE '0' END IsNDOSDay,  
           CASE WHEN A.OSHalfPrice          > 0 THEN '1' ELSE '0' END IsNDOSHalf,  
           CASE WHEN A.OSMonthPrice         > 0 THEN '1' ELSE '0' END IsNDOSMonth,  
           CASE WHEN A.EtcDayPrice          > 0 THEN '1' ELSE '0' END IsNDEtcDay,  
           CASE WHEN A.EtcHalfPrice         > 0 THEN '1' ELSE '0' END IsNDEtcHalf,  
           CASE WHEN A.EtcMonthPrice        > 0 THEN '1' ELSE '0' END IsNDEtcMonth
      INTO #IsNDPrice
      FROM mnpt_TPJTOperatorEXPriceItem AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @ExStdSeq 
       AND A.PJTTypeSeq = @PJTTypeSeq 
    ------------------------------------------------------------------------
    -- 일대, 반일, 월대 HID 처리  ( 1 - 보임,  0 - 숨김 ), END 
    ------------------------------------------------------------------------


    SELECT A.WorkPlanSeq, 
           A.WorkPlanSerl, 
           A.UMBisWorkType,                     -- 업무구분코드
           B.MinorName AS UMBisWorkTypeName,    -- 업무구분 
           A.SelfToolSeq,                       -- 자가장비코드 
           C.EquipmentSName AS SelfToolName,    -- 자가장비 
           A.RentToolSeq,                       -- 임차장비코드 
           D.EquipmentSName AS RentToolName,    -- 임차장비 
           A.ToolWorkTime,                      -- 운행시간 
           A.DriverEmpSeq1,                     -- 운전원당사1코드
           E.EmpName AS DriverEmpName1,         -- 운전원당사1
           A.DriverEmpSeq2,                     -- 운전원당사2코드
           F.EmpName AS DriverEmpName2,         -- 운전원당사2
           A.DriverEmpSeq3,                     -- 운전원당사3코드
           G.EmpName AS DriverEmpName3,         -- 운전원당사3
           A.DUnionDay, 
           A.DUnionHalf, 
           A.DUnionMonth, 
           A.DDailyDay, 
           A.DDailyHalf, 
           A.DDailyMonth, 
           A.DOSDay, 
           A.DOSHalf, 
           A.DOSMonth, 
           A.DEtcDay, 
           A.DEtcHalf, 
           A.DEtcMonth, 
           A.NDEmpSeq,                          -- 운전원외당사코드 
           H.EmpName AS NDEmpName,              -- 운전원외당사
           A.NDUnionUnloadGang, 
           A.NDUnionUnloadMan, 
           A.NDUnionDailyDay, 
           A.NDUnionDailyHalf, 
           A.NDUnionDailyMonth, 
           A.NDUnionSignalDay, 
           A.NDUnionSignalHalf, 
           A.NDUnionSignalMonth, 
           A.NDUnionEtcDay, 
           A.NDUnionEtcHalf, 
           A.NDUnionEtcMonth, 
           A.NDDailyDay, 
           A.NDDailyHalf, 
           A.NDDailyMonth, 
           A.NDOSDay, 
           A.NDOSHalf, 
           A.NDOSMonth, 
           A.NDEtcDay, 
           A.NDEtcHalf, 
           A.NDEtcMonth, 
           A.DRemark, 
           '1' AS IsMain
      INTO #mnpt_TPJTWorkPlanItem  
      FROM mnpt_TPJTWorkPlanItem        AS A 
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMBisWorkType ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS C ON ( C.CompanySeq = @CompanySeq AND C.EquipmentSeq = A.SelfToolSeq ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS D ON ( D.CompanySeq = @CompanySeq AND D.EquipmentSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.DriverEmpSeq1 ) 
      LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.DriverEmpSeq2 ) 
      LEFT OUTER JOIN _TDAEmp           AS G ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.DriverEmpSeq3 ) 
      LEFT OUTER JOIN _TDAEmp           AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.NDEmpSeq ) 
      LEFT OUTER JOIN #IsDPrice         AS I ON ( 1 = 1 ) 
      LEFT OUTER JOIN #IsNDPrice        AS J ON ( 1 = 1 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkPlanSeq = @WorkPlanSeq 
    

    IF EXISTS (SELECT 1 FROm #mnpt_TPJTWorkPlanItem)
    BEGIN 
        SELECT * FROM #mnpt_TPJTWorkPlanItem
    END 
    ELSE 
    BEGIN 

        SELECT 
               --A.WorkPlanSeq, 
               --A.WorkPlanSerl, 
               A.UMBisWorkType,                     -- 업무구분코드
               B.MinorName AS UMBisWorkTypeName,    -- 업무구분 
               A.SelfToolSeq,                       -- 자가장비코드 
               C.EquipmentSName AS SelfToolName,    -- 자가장비 
               A.RentToolSeq,                       -- 임차장비코드 
               D.EquipmentSName AS RentToolName,    -- 임차장비 
               A.ToolWorkTime,                      -- 운행시간 
               A.DriverEmpSeq1,                     -- 운전원당사1코드
               E.EmpName AS DriverEmpName1,         -- 운전원당사1
               A.DriverEmpSeq2,                     -- 운전원당사2코드
               F.EmpName AS DriverEmpName2,         -- 운전원당사2
               A.DriverEmpSeq3,                     -- 운전원당사3코드
               G.EmpName AS DriverEmpName3,         -- 운전원당사3
               --A.DUnionDay, 
               --A.DUnionHalf, 
               --A.DUnionMonth, 
               --A.DDailyDay, 
               --A.DDailyHalf, 
               --A.DDailyMonth, 
               --A.DOSDay, 
               --A.DOSHalf, 
               --A.DOSMonth, 
               --A.DEtcDay, 
               --A.DEtcHalf, 
               --A.DEtcMonth, 
               A.NDEmpSeq,                          -- 운전원외당사코드 
               H.EmpName AS NDEmpName,              -- 운전원외당사
               --A.NDUnionUnloadGang, 
               --A.NDUnionUnloadMan, 
               --A.NDUnionDailyDay, 
               --A.NDUnionDailyHalf, 
               --A.NDUnionDailyMonth, 
               --A.NDUnionSignalDay, 
               --A.NDUnionSignalHalf, 
               --A.NDUnionSignalMonth, 
               --A.NDUnionEtcDay, 
               --A.NDUnionEtcHalf, 
               --A.NDUnionEtcMonth, 
               --A.NDDailyDay, 
               --A.NDDailyHalf, 
               --A.NDDailyMonth, 
               --A.NDOSDay, 
               --A.NDOSHalf, 
               --A.NDOSMonth, 
               --A.NDEtcDay, 
               --A.NDEtcHalf, 
               --A.NDEtcMonth, 
               --A.DRemark, 
               '0' AS IsMain
          FROM mnpt_TPJTWorkPlanItem        AS A 
          LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMBisWorkType ) 
          LEFT OUTER JOIN mnpt_TPDEquipment AS C ON ( C.CompanySeq = @CompanySeq AND C.EquipmentSeq = A.SelfToolSeq ) 
          LEFT OUTER JOIN mnpt_TPDEquipment AS D ON ( D.CompanySeq = @CompanySeq AND D.EquipmentSeq = A.RentToolSeq ) 
          LEFT OUTER JOIN _TDAEmp           AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.DriverEmpSeq1 ) 
          LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = @CompanySeq AND F.EmpSeq = A.DriverEmpSeq2 ) 
          LEFT OUTER JOIN _TDAEmp           AS G ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.DriverEmpSeq3 ) 
          LEFT OUTER JOIN _TDAEmp           AS H ON ( H.CompanySeq = @CompanySeq AND H.EmpSeq = A.NDEmpSeq ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.WorkPlanSeq = @SourceWorkPlanSeq 
           AND ISNULL(@WorkPlanSeq,0) <> 0 

    END 

    ------------------------------------------------------------------------
    -- 일대, 반일, 월대 HID 처리  ( 1 - 보임,  0 - 숨김 ) 
    ------------------------------------------------------------------------
    SELECT * 
      FROM #IsDPrice                AS A  
      LEFT OUTER JOIN #IsNDPrice    AS B ON ( 1 = 1 )

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

        , WorkPlanSeq INT, SourceWorkPlanSeq INT
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkPlanSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(100), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), SourceWorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT
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
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkPlanSeq, SourceWorkPlanSeq) 
SELECT N'', 1, 1, 1, 0, NULL, NULL, NULL, N'DataBlock1', N'112', N'0'
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
--SET @MethodSeq      = 3
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820008
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkPlanItemQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3rollback 