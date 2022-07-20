     
IF OBJECT_ID('mnpt_SPJTShipDetailIFListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTShipDetailIFListQuery      
GO      
      
-- v2017.09.07
      
-- 모선항차조회-조회 by 이재천  
CREATE PROC mnpt_SPJTShipDetailIFListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS     
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      
    DECLARE @IFShipCode     NVARCHAR(200),   
            @EnShipName     NVARCHAR(200),   
            @BizUnit        INT, 
            @ShipSerlNo     NVARCHAR(100),   
            @ShipName       NVARCHAR(100),   
            @UMBulkCntr     INT, 
            @FrSerlYear     NCHAR(4), 
            @ToSerlYear     NCHAR(4), 
            @FrSerlNo       NCHAR(3), 
            @ToSerlNo       NCHAR(3), 
            @FrInPlanDate   NCHAR(8), 
            @ToInPlanDate   NCHAR(8), 
            @FrInDate       NCHAR(8), 
            @ToInDate       NCHAR(8), 
            @IsNotOutDate   NCHAR(1) 
      
    SELECT @IFShipCode    = ISNULL( IFShipCode      , '' ),   
           @EnShipName    = ISNULL( EnShipName      , '' ),   
           @BizUnit       = ISNULL( BizUnit         , 0 ),   
           @ShipSerlNo    = ISNULL( ShipSerlNo      , '' ),   
           @ShipName      = ISNULL( ShipName        , '' ),   
           @UMBulkCntr    = ISNULL( UMBulkCntr      , 0 ),   
           @FrSerlYear    = ISNULL( FrSerlYear      , '' ),   
           @ToSerlYear    = ISNULL( ToSerlYear      , '' ),   
           @FrSerlNo      = ISNULL( FrSerlNo        , '' ),   
           @ToSerlNo      = ISNULL( ToSerlNo        , '' ),   
           @FrInPlanDate  = ISNULL( FrInPlanDate    , '' ),   
           @ToInPlanDate  = ISNULL( ToInPlanDate    , '' ),   
           @FrInDate      = ISNULL( FrInDate        , '' ),   
           @ToInDate      = ISNULL( ToInDate        , '' ),   
           @IsNotOutDate  = ISNULL( IsNotOutDate    , '0' )
      FROM #BIZ_IN_DataBlock1    
             
    IF @ToSerlYear = '' SELECT @ToSerlYear = '9999'
    IF @ToSerlNo = '' SELECT @ToSerlNo = '999'
    IF @ToInPlanDate = '' SELECT @ToInPlanDate = '99991231'
    IF @ToInDate = '' SELECT @ToInDate = '99991231'


    ------------------------------------------------------------------------
    -- Title 
    ------------------------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        TitleName   NVARCHAR(100), 
        TitleSeq   INT
    )
    INSERT INTO #Title (TitleName, TitleSeq) 
    SELECT A.MinorName + '중량'  AS TitleName, 
           A.MinorSeq   AS TitleSeq 
      FROM _TDAUMinor       AS A 
      JOIN _TDAUMinorValue  AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000005 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015782 
       AND B.ValueText = '1'
    
    SELECT * FROM #Title 
    ------------------------------------------------------------------------
    -- Fix
    ------------------------------------------------------------------------
    SELECT ROW_NUMBER() OVER(ORDER BY A.InPlanDateTime,A.ShipSerl) - 1 AS RowIdx, 
           A.ShipSeq           -- 모선내부코드 
          ,A.ShipSerl          -- 모선항차순번 
          ,STUFF(A.ShipSerlNo,5,0,'-') AS ShipSerlNo       -- 항차 
          ,B.IFShipCode        -- 모선코드 
          ,B.EnShipName        -- 모선명(영문) 
          ,B.ShipName          -- 모선명(한글) 
          ,B.TotalTON          -- GRT(TON) 
          ,B.LOA               -- LOA 
          ,B.DRAFT             -- DRAFT 
          ,B.LINECode          -- LINE 
          ,STUFF(STUFF(LEFT(A.InPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InPlanDateTime,4),3,0,':')   AS InPlanDateTime  -- 입항예정일시
          ,STUFF(STUFF(LEFT(A.OutPlanDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutPlanDateTime,4),3,0,':') AS OutPlanDateTime -- 출항예정일시
          ,STUFF(STUFF(LEFT(A.InDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.InDateTime,4),3,0,':') AS InDateTime                -- 입항일시 
          ,STUFF(STUFF(LEFT(A.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ApproachDateTime,4),3,0,':') AS ApproachDateTime -- 접안일시
          ,STUFF(STUFF(LEFT(A.WorkSrtDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkSrtDateTime,4),3,0,':') AS WorkSrtDateTime -- 하역개시일시
          ,STUFF(STUFF(LEFT(A.WorkEndDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.WorkEndDateTime,4),3,0,':') AS WorkEndDateTime -- 하역종료일시
          ,STUFF(STUFF(LEFT(A.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutDateTime,4),3,0,':') AS OutDateTime                -- 출항일시 
          -- 접안시간(시간단위로 올림) : (입항일시[DATETIME 타입(분으로 계산)] - 접안일시[DATETIME 타입(분으로 계산)]) / 60. 
          ,A.DiffApproachTime -- 접안시간

          ,A.BERTH             -- 선석 
          ,A.BRIDGE            -- BRIDGE 
          ,A.FROM_BIT + '~' + A.TO_BIT AS BIT   -- BIT 
          ,A.PORT              -- 전출항PORT
          ,A.TRADECode         -- 항로 
          ,CASE WHEN EXISTS (SELECT 1 FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MajorSeq = 1015793 AND MinorName = A.TRADECode) 
                THEN '내항선'
                WHEN ISNULL(A.TRADECode,'') = '' 
                THEN '' 
                ELSE '외항선' 
                END AS TRADETypeName 
          ,F.MinorName AS BULKCNTR -- 벌크컨테이너구분
          ,I.BizUnitName AS BizUnitName 
          ,A.AgentName          -- 대리점 
          ,CASE WHEN A.FirstUserSeq = 1 THEN '' ELSE D.UserName END AS FirstUserName -- 입력자
          ,CONVERT(NVARCHAr(200),A.FirstDateTime,120) AS FirstDateTime -- 입력시간
          ,A.UMApplyTon
          ,J.MinorName AS UMApplyTonName 
          ,ISNULL(K.ChangeCnt,0) AS ChangeCnt
      INTO #FixCol
      FROM mnpt_TPJTShipDetail               AS A   
      LEFT OUTER JOIN mnpt_TPJTShipMaster    AS B ON ( B.CompanySeq = @CompanySeq AND B.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TCAUser              AS D ON ( D.CompanySeq = @CompanySeq AND D.UserSeq = A.FirstUserSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.Majorseq = 1015786 AND E.Serl = 1000001 AND E.ValueText = A.BULKCNTR ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS G ON ( G.CompanySeq = @CompanySeq AND G.Majorseq = 1015794 AND G.Serl = 1000001 AND G.ValueText = A.BizUnitCode ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDABizUnit           AS I ON ( I.CompanySeq = @CompanySeq AND I.BizUnit = H.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMApplyTon ) 
      LEFT OUTER JOIN (
                  SELECT ShipSeq, ShipSerl, COUNT(1) AS ChangeCnt
                      FROM mnpt_TPJTShipDetailChange 
                      WHERE CompanySeq = @CompanySeq
                      GROUP BY ShipSeq, ShipSerl 
                  ) AS K ON ( K.ShipSeq = A.ShipSeq AND K.ShipSerl = A.ShipSerl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @IFShipCode = '' OR A.IFShipCode LIKE @IFShipCode + '%' ) -- 모선 
       AND ( @EnShipName = '' OR B.EnShipName LIKE @EnShipName + '%' ) -- 모선명(영문) 
       AND ( @ShipName = '' OR B.ShipName LIKE @ShipName + '%' ) -- 모선명(한글) 
       AND ( @BizUnit = 0 OR H.ValueSeq = @BizUnit ) -- 사업부문 
       AND ( @ShipSerlNo = '' OR A.ShipSerlNo LIKE @ShipSerlNo + '%' )  -- 항차 
       AND ( @UMBulkCntr = 0 OR E.MinorSeq = @UMBulkCntr ) -- 화물구분 
       --AND ( LEFT(ISNULL(A.ShipSerlNo,''),4) BETWEEN @FrSerlYear AND @ToSerlYear ) -- 항차년도 
       AND ( A.ShipSerlNo BETWEEN @FrSerlYear + @FrSerlNo AND @ToSerlYear + @ToSerlNo ) 
       AND ( LEFT(ISNULL(A.InPlanDateTime,''),8) BETWEEN @FrInPlanDate AND @ToInPlanDate ) -- 입항예정일 
       AND ( LEFT(ISNULL(A.InDateTime,''),8) BETWEEN @FrInDate AND @ToInDate ) -- 입항일 
       AND ( @IsNotOutDate = '0' 
             OR (@IsNotOutDate = '1' AND ISNULL(A.InDateTime,'') <> '' AND ISNULL(A.OutDateTime,'') = '') 
            ) -- 잡안중 모선 
     ORDER BY A.InPlanDateTime, A.ShipSerl
    
    SELECT * FROM #FixCol 

    ------------------------------------------------------------------------
    -- Value 
    ------------------------------------------------------------------------
    CREATE TABLE #Value
    (
        Value      DECIMAL(19, 5), 
        ShipSeq    INT, 
        ShipSerl   INT, 
        TitleSeq   INT
    )
    INSERT INTO #Value ( Value, ShipSeq, ShipSerl, TitleSeq ) 
    SELECT A.Value, 
           A.ShipSeq, 
           A.ShipSerl, 
           A.TitleSeq
      FROM mnpt_TPJTShipDetailValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #FixCol WHERE ShipSeq = A.ShipSeq AND ShipSerl = A.ShipSerl ) 
    
    
    ------------------------------------------------------------------------
    -- 최종조회 
    ------------------------------------------------------------------------
    SELECT B.RowIdx, A.ColIdx, C.Value AS Result	
      FROM #Value AS C	
      JOIN #Title AS A ON ( A.TitleSeq = C.TitleSeq ) 	
      JOIN #FixCol AS B ON ( B.ShipSeq = C.ShipSeq AND B.ShipSerl = C.ShipSerl ) 	
     ORDER BY A.ColIdx, B.RowIdx	


    RETURN   
      
      go
begin tran   
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_IN_DataBlock2 INT        , @CONST_#BIZ_IN_DataBlock3 INT        , @CONST_#BIZ_IN_DataBlock4 INT        , @CONST_#BIZ_OUT_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock2 INT        , @CONST_#BIZ_OUT_DataBlock3 INT        , @CONST_#BIZ_OUT_DataBlock4 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_IN_DataBlock2 = 0        , @CONST_#BIZ_IN_DataBlock3 = 0        , @CONST_#BIZ_IN_DataBlock4 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock2 = 0        , @CONST_#BIZ_OUT_DataBlock3 = 0        , @CONST_#BIZ_OUT_DataBlock4 = 0
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

        , FrIFDate CHAR(8), ToIFDate CHAR(8), FrSerlYear CHAR(4), ToSerlYear CHAR(4), FrInPlanDate CHAR(8), ToInPlanDate CHAR(8), FrInDate CHAR(8), ToInDate CHAR(8), IsNotOutDate CHAR(8), BizUnit INT, UMBulkCntr INT, FrSerlNo CHAR(3), ToSerlNo CHAR(3), IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200)
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

        , FrIFDate CHAR(8), ToIFDate CHAR(8), FrSerlYear CHAR(4), ToSerlYear CHAR(4), FrInPlanDate CHAR(8), ToInPlanDate CHAR(8), FrInDate CHAR(8), ToInDate CHAR(8), IsNotOutDate CHAR(8), BizUnit INT, UMBulkCntr INT, FrSerlNo CHAR(3), ToSerlNo CHAR(3), IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200)
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

        , TitleName NVARCHAR(200), TitleSeq INT
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

        , TitleName NVARCHAR(200), TitleSeq INT
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

        , IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), TotalTON DECIMAL(19, 5), LOA DECIMAL(19, 5), DRAFT DECIMAL(19, 5), LINECode NVARCHAR(200), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), InDateTime NVARCHAR(200), ApproachDateTime NVARCHAR(200), WorkSrtDateTime NVARCHAR(200), WorkEndDateTime NVARCHAR(200), OutDateTime NVARCHAR(200), DiffApproachTime INT, BERTH NVARCHAR(200), BRIDGE NVARCHAR(200), BIT NVARCHAR(200), PORT NVARCHAR(200), TRADECode NVARCHAR(200), TRADETypeName NVARCHAR(200), BULKCNTR NVARCHAR(200), BizUnitName NVARCHAR(200), FirstUserName NVARCHAR(200), FirstDateTime NVARCHAR(200), ShipSeq INT, ShipSerl INT, AgentName NVARCHAR(200), TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100), UMApplyTonName NVARCHAR(200)
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

        , IFShipCode NVARCHAR(200), ShipSerlNo NVARCHAR(200), EnShipName NVARCHAR(200), ShipName NVARCHAR(200), TotalTON DECIMAL(19, 5), LOA DECIMAL(19, 5), DRAFT DECIMAL(19, 5), LINECode NVARCHAR(200), InPlanDateTime NVARCHAR(200), OutPlanDateTime NVARCHAR(200), InDateTime NVARCHAR(200), ApproachDateTime NVARCHAR(200), WorkSrtDateTime NVARCHAR(200), WorkEndDateTime NVARCHAR(200), OutDateTime NVARCHAR(200), DiffApproachTime INT, BERTH NVARCHAR(200), BRIDGE NVARCHAR(200), BIT NVARCHAR(200), PORT NVARCHAR(200), TRADECode NVARCHAR(200), TRADETypeName NVARCHAR(200), BULKCNTR NVARCHAR(200), BizUnitName NVARCHAR(200), FirstUserName NVARCHAR(200), FirstDateTime NVARCHAR(200), ShipSeq INT, ShipSerl INT, AgentName NVARCHAR(200), TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5), UMApplyTon NVARCHAR(100), UMApplyTonName NVARCHAR(200)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock3 = 1

END

IF @CONST_#BIZ_IN_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_IN_DataBlock4 = 1

END

IF @CONST_#BIZ_OUT_DataBlock4 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock4
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

        , RowIdx INT, ColIdx INT, Value DECIMAL(19, 5)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock4 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, FrIFDate, ToIFDate, FrSerlYear, ToSerlYear, FrInPlanDate, ToInPlanDate, FrInDate, ToInDate, IsNotOutDate, BizUnit, UMBulkCntr, FrSerlNo, ToSerlNo, IFShipCode, ShipSerlNo, EnShipName, ShipName) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'0', N'', N'20170901', N'20170915', N'', N'', N'', N'', N'', N'', N'0', N'', N'', N'', N'', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820003
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820004
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTShipDetailIFListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4rollback 