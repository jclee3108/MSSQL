     
IF OBJECT_ID('mnpt_SPJTWorkPlanExtraDlgQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTWorkPlanExtraDlgQuery      
GO      
      
-- v2017.09.12
      
-- 할증구분Dlg-조회 by 이재천  
CREATE PROC mnpt_SPJTWorkPlanExtraDlgQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @PJTSeq             INT, 
            @ExtraGroupSeq      NVARCHAR(500), 
            @ShipSeq            INT, 
            @ShipSerl           INT, 
            @WorkDate           NCHAR(8) 
      
    SELECT @PJTSeq          = ISNULL( PJTSeq, 0 ), 
           @ExtraGroupSeq   = ISNULL( ExtraGroupSeq, '' ), 
           @ShipSeq         = ISNULL( ShipSeq, 0 ), 
           @ShipSerl        = ISNULL( ShipSerl, 0 ), 
           @WorkDate        = ISNULL( WorkDate, '')
      FROM #BIZ_IN_DataBlock1    
    
    ------------------------------------------------
    -- 할증구분코드 테이블로 만들기, Srt
    ------------------------------------------------
    CREATE TABLE #CheckExtraSeq 
    (
        UMExtraType     INT 
    )

    INSERT INTO #CheckExtraSeq (UMExtraType)
    SELECT Code
      FROM _FCOMXmlToSeq(0, '<XmlString><Code>' + REPLACE(@ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>')
    ------------------------------------------------
    -- 할증구분코드 테이블로 만들기, End 
    ------------------------------------------------
    
    SELECT Z.UMExtraType, MAX(ExtraRate) AS ExtraRate, MAX(UnionExtraRate) AS UnionExtraRate
      INTO #ExtraRate
      FROM ( 
            -- 계약할증율
            SELECT A.TitleSeq AS UMExtraType, MAX(CONVERT(DECIMAL(19,5),A.Value)) AS ExtraRate, 0 AS UnionExtraRate
              FROM mnpt_TPJTProjectDeliveryValue AS A 
             WHERE A.CompanySeq = @CompanySeq
               AND A.PJTSeq = @PJTSeq
               AND CONVERT(INT,A.Value) > 0 
             GROUP BY A.TitleSeq
    
            UNION ALL 
            -- 노조할증율
            SELECT B.TitleSeq AS UMExtraType, 0 AS ExtraRate, B.Value AS UnionExtraRate
              FROM mnpt_TPJTUnionExtra                  AS A 
              LEFT OUTER JOIN mnpt_TPJTUnionExtraValue  AS B ON ( B.CompanySeq = @CompanySeq AND B.StdSeq = A.StdSeq ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.StdDate <= @WorkDate 
               AND B.Value > 0 
           ) AS Z 
     GROUP BY Z.UMExtraType 
    
    
    -- 최종조회 
    SELECT B.MinorName AS UMExtraTypeName, 
           A.UMExtraType   AS UMExtraType, 
           A.ExtraRate AS ExtraRate, 
           CASE WHEN C.UMExtraType IS NULL THEN '0' ELSE '1' END Sel, 
           CASE WHEN D.MinorSeq IS NULL THEN '1' ELSE '0' END IsDIS, 
           E.Value AS ExtraWeight, 
           G.MinorName AS UMApplyTonName, 
           A.UnionExtraRate AS UnionExtraRate
      FROM #ExtraRate                       AS A 
      LEFT OUTER JOIN _TDAUMinor            AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMExtraType ) 
      LEFT OUTER JOIN #CheckExtraSeq        AS C ON ( C.UMExtraType = A.UMExtraType ) 
      LEFT OUTER JOIN (
                        SELECT A.MinorSeq
                          FROM _TDAUMinorValue AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.Serl IN ( 1000004, 1000005 ) 
                           AND A.MajorSeq = 1015782 
                           AND A.ValueText = '1' 
                      ) AS D ON ( D.MinorSeq = A.UMExtraType ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetailValue  AS E ON ( E.CompanySeq = @CompanySeq 
                                                      AND E.ShipSeq = @ShipSeq 
                                                      AND E.ShipSerl = @ShipSerl 
                                                      AND E.TitleSeq = A.UMExtraType 
                                                        ) 
      LEFT OUTER JOIN mnpt_TPJTShipDetail       AS F ON ( F.CompanySeq = @CompanySeq AND F.ShipSeq = E.ShipSeq AND F.ShipSerl = E.ShipSerl ) 
      LEFT OUTER JOIN _TDAUMinor                AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMApplyTon ) 
        
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

        , PJTSeq INT, ExtraGroupSeq NVARCHAR(500), ShipSeq INT, ShipSerl INT, WorkDate CHAR(8)
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

        , PJTSeq INT, UMExtraTypeName NVARCHAR(200), UMExtraType INT, ExtraRate DECIMAL(19, 5), ExtraGroupSeq NVARCHAR(500), Sel CHAR(1), IsDIS CHAR(1), ExtraWeight DECIMAL(19, 5), UMApplyTonName NVARCHAR(200), UnionExtraRate DECIMAL(19, 5), ShipSeq INT, ShipSerl INT, WorkDate CHAR(8)
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, PJTSeq, ExtraGroupSeq, ShipSeq, ShipSerl, WorkDate) 
SELECT N'A', 1, 1, 1, 0, NULL, NULL, N'1', N'', N'156', N'', N'2', N'2782', N'20170919'
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

SET @ServiceSeq     = 13820011
--SET @MethodSeq      = 1
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820010
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTWorkPlanExtraDlgQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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