     
IF OBJECT_ID('mnpt_SPJTEECNTRReportListQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEECNTRReportListQuery      
GO      
      
-- v2017.11.07 
      
-- 화면명-조회 by 이재천  
CREATE PROC mnpt_SPJTEECNTRReportListQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @WorkDateFr  NCHAR(8),   
            @WorkDateTo  NCHAR(8),   
            @InDateFr    NCHAR(8),   
            @InDateTo    NCHAR(8),   
            @IFItemCode  NVARCHAR(100),   
            @IFShipCode  NVARCHAR(10),   
            @ShipYear    NVARCHAR(4),   
            @SerlNo      NVARCHAR(100),   
            @PJTNo       NVARCHAR(100),   
            @DLS         NVARCHAR(100),   
            @PJTName     NVARCHAR(100),   
            @BizUnit     INT, 
            @PJTTypeSeq  INT, 
            @IFStatus    INT, 
            @CustSeq     INT, 
            @ShipSeq     INT, 
            @ItemSeq     INT, 
            @ShipSerlNo  NVARCHAR(50)

    SELECT @WorkDateFr  = ISNULL( WorkDateFr  , '' ),   
           @WorkDateTo  = ISNULL( WorkDateTo  , '' ),   
           @InDateFr    = ISNULL( InDateFr    , '' ),   
           @InDateTo    = ISNULL( InDateTo    , '' ),   
           @IFItemCode  = ISNULL( IFItemCode  , '' ),   
           @IFShipCode  = ISNULL( IFShipCode  , '' ),   
           @ShipYear    = ISNULL( ShipYear    , '' ),   
           @SerlNo      = ISNULL( SerlNo      , '' ),   
           @PJTNo       = ISNULL( PJTNo       , '' ),   
           @DLS         = ISNULL( DLS         , '' ),   
           @PJTName     = ISNULL( PJTName     , '' ),   
           @BizUnit     = ISNULL( BizUnit     , 0 ),   
           @PJTTypeSeq  = ISNULL( PJTTypeSeq  , 0 ),   
           @IFStatus    = ISNULL( IFStatus    , 0 ),   
           @CustSeq     = ISNULL( CustSeq     , 0 ),   
           @ShipSeq     = ISNULL( ShipSeq     , 0 ),   
           @ItemSeq     = ISNULL( ItemSeq     , 0 ), 
           @ShipSerlNo  = ISNULL( IFShipCode, '' ) + ISNULL( ShipYear, '' ) + ISNULL( SerlNo, '' )
      FROM #BIZ_IN_DataBlock1    
    
    IF @InDateTo = '' SELECT @InDateTo = '99991231' 
    IF @WorkDateTo = '' SELECT @WorkDateTo = '99991231'
    
    
    SELECT A.CNTRReportSeq, 
           A.ShipSeq, 
           A.ShipSerl, 
           B.PJTSeq,
           LEFT(A.WorkSrtDateTime,8) AS WorkSrtDate, 
           RIGHT(A.WorkSrtDateTime,4) AS WorkSrtTime,
           LEFT(A.WorkEndDateTime,8) AS WorkEndDate, 
           RIGHT(A.WorkEndDateTime,4) AS WorkEndTime, 
           A.IFShipCode + '-' + A.ShipYear + '-' + RIGHT('00' + CONVERT(NVARCHAR(10),A.SerlNo),3) AS ShipSerlNo, 
           C.EnShipName, 
           LEFT(D.InDateTime,8) AS InDate, 
           LEFT(D.OutDateTime,8) AS OutDate, 
           D.DiffApproachTime, 
           CASE WHEN B.Cnt = 1 THEN H.BizUnitName ELSE '' END AS BizUnitName, 
           CASE WHEN B.Cnt = 1 THEN G.ContractName ELSE '' END AS ContractName, -- 계약명 
           CASE WHEN B.Cnt = 1 THEN G.ContractNo ELSE '' END AS ContractNo, -- 계약번호 
           CASE WHEN B.Cnt = 1 THEN I.PJTTypeName ELSE '' END AS PJTTypeName, -- 화태
           CASE WHEN B.Cnt = 1 THEN J.CustName ELSE '' END AS CustName, -- 거래처
           CASE WHEN B.Cnt = 1 THEN E.PJTName ELSE '' END AS PJTName, -- 프로젝트명
           CASE WHEN B.Cnt = 1 THEN E.PJTNo ELSE '' END AS PJTNo, -- 프로젝트번호
           B.IsCfm AS IsShipCfm, 
           A.IFItemCode, 
           A.DLS, 
           A.ItemSeq, 
           K.ItemName, 
           A.Qty, 
           L.UserName AS IFUserName, 
           CONVERT(NVARCHAR(16),A.FirstDateTime,120) AS IFDateTime, 
           M.ErrMessage AS IFResult, 
           CASE WHEN B.Cnt = 1 THEN '정상' 
                WHEN B.Cnt > 1 THEN '본선계획중복'
                ELSE '본선계획없음'
                END AS IFStatusName, 
           CASE WHEN B.Cnt = 1 THEN 1 
                WHEN B.Cnt > 1 THEN 2
                ELSE 3
                END AS IFStatus, 
           N.IsInvoice
      FROM mnpt_TPJTEECNTRReport AS A 
      OUTER APPLY (
                    SELECT MAX(Z.PJTSeq) AS PJTSeq, MIN(ISNULL(Z.IsCfm,'0')) AS IsCfm, COUNT(1) AS Cnt 
                      FROM mnpt_TPJTShipWorkPlanFinish AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.ShipSeq = A.ShipSeq 
                       AND Z.ShipSerl = A.ShipSerl 
                     GROUP BY Z.ShipSeq, Z.ShipSerl 
                  ) AS B 
      LEFT OUTER JOIN mnpt_TPJTShipMaster           AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail           AS D ON ( D.CompanySeq = @CompanySeq AND D.ShipSeq = A.ShipSeq AND D.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TPJTProject                  AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = B.PJTSeq ) 
      LEFT OUTER JOIN mnpt_TPJTProject              AS F ON ( F.CompanySeq = @CompanySeq AND F.PJTSeq = E.PJTSeq ) 
      LEFT OUTER JOIN mnpt_TPJTContract             AS G ON ( G.CompanySeq = @CompanySeq AND G.ContractSeq = F.ContractSeq ) 
      LEFT OUTER JOIN _TDABizUnit                   AS H ON ( H.CompanySeq = @CompanySeq AND H.BizUnit = G.BizUnit ) 
      LEFT OUTER JOIN _TPJTType                     AS I ON ( I.CompanySeq = @CompanySeq AND I.PJTTypeSeq = E.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust                      AS J ON ( J.CompanySeq = @CompanySeq AND J.CustSeq = G.CustSeq ) 
      LEFT OUTER JOIN _TDAItem                      AS K ON ( K.CompanySeq = @CompanySeq AND K.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TCAUser                      AS L ON ( L.CompanySeq = @CompanySeq AND L.UserSeq = A.FirstUserSeq ) 
      LEFT OUTER JOIN mnpt_TPJTEECNTRReport_IF      AS M ON ( M.CompanySeq = @CompanySeq AND M.CNTRReportSeq = A.CNTRReportSeq ) 
      OUTER APPLY (
                   SELECT Z.PJTSeq, Z.ShipSeq, Z.ShipSerl , '1' AS IsInvoice
                     FROM mnpt_TPJTLinkInvoiceItem AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.ShipSeq = A.ShipSeq 
                      AND Z.ShipSerl = A.ShipSerl 
                      AND Z.PJTSeq = B.PJTSeq 
                    GROUP BY Z.PJTSeq, Z.ShipSeq, Z.ShipSerl 
                  ) AS N
     WHERE A.CompanySeq = @CompanySeq 
       AND ( LEFT(A.WorkSrtDateTime,8) BETWEEN @WorkDateFr AND @WorkDateTo ) 
       AND ( ISNULL(LEFT(D.InDateTime,8),'') BETWEEN @InDateFr AND @InDateTo ) 
       AND ( @IFItemCode = '' OR A.IFItemCode LIKE @IFItemCode + '%' ) 
       AND ( LTRIM(RTRIM(@ShipSerlNo)) = '' OR A.IFShipCode + A.ShipYear + RIGHT('00' + CONVERT(NVARCHAR(10),A.SerlNo),3) LIKE LTRIM(RTRIM(@ShipSerlNo)) + '%' ) 
       AND ( @PJTNo = '' OR CASE WHEN B.Cnt = 1 THEN E.PJTNo ELSE '' END LIKE @PJTNo + '%' ) 
       AND ( @DLS = '' OR A.DLS LIKE @DLS + '%' ) 
       AND ( @PJTName = '' OR CASE WHEN B.Cnt = 1 THEN E.PJTName ELSE '' END LIKE @PJTName + '%' ) 
       AND ( @BizUnit = 0 OR CASE WHEN B.Cnt = 1 THEN G.BizUnit ELSE 0 END = @BizUnit ) 
       AND ( @PJTTypeSeq = 0 OR CASE WHEN B.Cnt = 1 THEN E.PJTTypeSeq ELSE 0 END = @PJTTypeSeq ) 
       AND ( @CustSeq = 0 OR CASE WHEN B.Cnt = 1 THEN G.CustSeq ELSE 0 END = @CustSeq ) 
       AND ( @ShipSeq = 0 OR A.ShipSeq = @ShipSeq ) 
       AND ( @ItemSeq = 0 OR A.ItemSeq = @ItemSeq ) 
       AND ( @IFStatus = 0 OR CASE WHEN B.Cnt = 1 THEN 1 
                                   WHEN B.Cnt > 1 THEN 2
                                   ELSE 3
                                   END = @IFStatus ) 
     ORDER BY A.WorkSrtDateTime DESC 

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

        , WorkDateFr CHAR(8), WorkDateTo CHAR(8), InDateFr CHAR(8), InDateTo CHAR(8), IFShipCode NVARCHAR(100), ShipYear CHAR(4), SerlNo NVARCHAR(100), PJTNo NVARCHAR(100), DLS NVARCHAR(100), PJTName NVARCHAR(100), BizUnit INT, PJTTypeSeq INT, IFStatus INT, CustSeq INT, ShipSeq INT, ItemSeq INT, IFItemCode NVARCHAR(100)
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

        , WorkDateFr CHAR(8), WorkDateTo CHAR(8), BizUnitName NVARCHAR(100), PJTTypeName NVARCHAR(100), IFStatusName NVARCHAR(100), InDateFr CHAR(8), InDateTo CHAR(8), CustName NVARCHAR(100), IFShipCode NVARCHAR(100), ShipYear CHAR(4), SerlNo NVARCHAR(100), PJTNo NVARCHAR(100), DLS NVARCHAR(100), EnShipName NVARCHAR(100), PJTName NVARCHAR(100), ItemName NVARCHAR(100), IFOutDateFr CHAR(8), IFOutDateTo CHAR(8), IFWorkDateFr CHAR(8), IFWorkDateTo CHAR(8), BizUnit INT, PJTTypeSeq INT, IFStatus INT, CustSeq INT, ShipSeq INT, ItemSeq INT, WorkSrtDate CHAR(8), WorkSrtTime CHAR(4), WorkEndDate CHAR(8), WorkEndTime CHAR(4), ShipSerlNo NVARCHAR(100), InDate CHAR(8), OutDate CHAR(8), DiffApproachTime DECIMAL(19, 5), IsShipCfm CHAR(1), IFItemCode NVARCHAR(100), Qty DECIMAL(19, 5), UnitName NVARCHAR(100), IFUserName NVARCHAR(100), IFDateTime NVARCHAR(100), IFResult NVARCHAR(2000), IsInvoice CHAR(1), CNTRReportSeq INT, ShipSerl INT, PJTSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, WorkDateFr, WorkDateTo, InDateFr, InDateTo, IFShipCode, ShipYear, SerlNo, PJTNo, DLS, PJTName, BizUnit, PJTTypeSeq, IFStatus, CustSeq, ShipSeq, ItemSeq, IFItemCode) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'20171001', N'20171107', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N''
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

SET @ServiceSeq     = 13820045
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820049
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTEECNTRReportListQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 