  
IF OBJECT_ID('mnpt_SPJTWorkReportIsListCfm') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportIsListCfm  
GO  
    
-- v2018.02.05
  
-- 작업실적입력-항목별승인 by 이재천
CREATE PROC mnpt_SPJTWorkReportIsListCfm
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- 체크1, 본선작업완료건은 승인취소 할 수 없습니다.
    UPDATE A
       SET Result        = '본선작업완료건은 승인취소 할 수 없습니다.', 
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1 AS A 
      JOIN mnpt_TPJTWorkReport AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.Status = 0 
       AND B.IsCfm = '1' 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTShipWorkPlanFinish 
                    WHERE CompanySeq = @CompanySeq 
                      AND ShipSeq = B.ShipSeq 
                      AND ShipSerl = B.ShipSerl 
                      AND PJTSeq = B.PJTSeq 
                      AND IsCfm = '1'
                  )
    -- 체크1, End
    
    --체크2, 청구생성이 되어 승인 취소 할 수 없습니다. 
    UPDATE A
       SET Result        = '청구생성이 되어 승인 취소 할 수 없습니다.', 
           MessageType   = 1234,      
           Status        = 1234      
      FROM #BIZ_OUT_DataBlock1          AS A 
      JOIN mnpt_TPJTWorkReport      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
      JOIN mnpt_TPJTProjectMapping  AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTSeq = B.PJTSeq AND C.UMWorkType = B.UMWorkType ) 
     WHERE ( B.ShipSeq = 0 OR B.ShipSerl = 0 ) 
       AND B.IsCfm = '1' 
       AND EXISTS (SELECT 1 
                     FROM mnpt_TPJTLinkInvoiceItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.ItemSeq = C.ItemSeq 
                      AND Z.PJTSeq = B.PJTSeq 
                      AND Z.ChargeDate = LEFT(B.WorkDate,6) 
                  )
    -- 체크2, End
    
    UPDATE A
       SET IsCfm = B.IsCfm 
      FROM mnpt_TPJTWorkReport  AS A 
      JOIN #BIZ_OUT_DataBlock1  AS B ON ( B.WorkReportSeq = A.WorkReportSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND B.Status = 0 

    UPDATE A
       SET IsCfm = B.IsCfm
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TPJTWorkReport  AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkReportSeq = A.WorkReportSeq ) 
    
    RETURN  
 
GO

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

        , WorkReportSeq INT, IsCfm NVARCHAR(100)
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

        , PJTName NVARCHAR(200), PJTSeq INT, PJTTypeName NVARCHAR(200), CustName NVARCHAR(200), UMCustKindName NVARCHAR(200), AGCustName NVARCHAR(200), IFShipCode NVARCHAR(100), ShipSeq INT, ShipSerlNo NVARCHAR(100), ShipSerl INT, LOA DECIMAL(19, 5), UMWorkDivision NVARCHAR(200), UMWorkTypeName NVARCHAR(200), UMWorkType INT, GoodsQty DECIMAL(19, 5), GoodsMTWeight DECIMAL(19, 5), GoodsCBMWeight DECIMAL(19, 5), SumQty DECIMAL(19, 5), SumMTWeight DECIMAL(19, 5), SumCBMWeight DECIMAL(19, 5), TodayQty DECIMAL(19, 5), TodayMTWeight DECIMAL(19, 5), TodayCBMWeight DECIMAL(19, 5), EtcQty DECIMAL(19, 5), EtcMTWeight DECIMAL(19, 5), EtcCBMWeight DECIMAL(19, 5), MultiExtraName NVARCHAR(500), WorkSrtTime NVARCHAR(10), WorkEndTime NVARCHAR(10), RealWorkTime DECIMAL(19, 5), EmpName NVARCHAR(200), EmpSeq INT, UMBisWorkTypeCnt INT, BizUnitName NVARCHAR(200), PJTNo NVARCHAR(200), AgentName NVARCHAR(200), DRemark NVARCHAR(2000), WorkReportSeq INT, ExtraGroupSeq NVARCHAR(500), WorkDate NVARCHAR(100), UMWeatherName NVARCHAR(100), UMWeather NVARCHAR(100), MRemark NVARCHAR(2000), IsCfm NVARCHAR(100), Confirm NVARCHAR(100), NightQty DECIMAL(19, 5), NightMTWeight DECIMAL(19, 5), NightCBMWeight DECIMAL(19, 5), EnShipName NVARCHAR(200), WorkPlanSeq INT, UMWorkTeamName NVARCHAR(200), UMWorkTeam INT, ManRemark NVARCHAR(2000), IsCfmDetail CHAR(1), UMLoadType INT, UMLoadTypeName NVARCHAR(100), SourceWorkReportSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkReportSeq, IsCfm) 
SELECT N'U', 2, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', N'511', N'0'



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
--SET @MethodSeq      = 11
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820019
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkReportSeq, IsCfm)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, WorkReportSeq, IsCfm      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SPJTWorkReportIsListCfm            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0 
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : EndCOMMIT TRANSET @UseTransaction = N'0'GOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
        , CASE
            WHEN Status = 0 OR Status IS NULL THEN
                -- 정상인건 중에
                CASE
                    WHEN @HasError = N'1' THEN
                        -- 오류가 발생된 건이면
                        CASE
                            WHEN @UseTransaction = N'1' THEN
                                999999  -- 트랜잭션인 경우
                            ELSE
                                999998  -- 트랜잭션이 아닌 경우
                        END
                    ELSE
                        -- 오류가 발생되지 않은 건이면
                        0
                END
            ELSE
                Status
        END AS Status
        , Result, ROW_IDX, IsChangedMst, WorkReportSeq, IsCfm  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
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