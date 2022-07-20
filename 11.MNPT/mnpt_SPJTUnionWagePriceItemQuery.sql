     
IF OBJECT_ID('mnpt_SPJTUnionWagePriceItemQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTUnionWagePriceItemQuery 
GO      
      
-- v2017.09.28
      
-- 노조노임단가입력-SS2조회 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StdSeq     INT 
      
    SELECT @StdSeq   = ISNULL( StdSeq, 0 )
      FROM #BIZ_IN_DataBlock1    
    
    -- Title 
    CREATE TABLE #Title
    (
         ColIdx     INT IDENTITY(0, 1), 
         TitleName1 NVARCHAR(200), 
         TitleSeq1  INT, 
         TitleName2 NVARCHAR(200), 
         TitleSeq2  INT, 
         TitleName3 NVARCHAR(200), 
         TitleSeq3  INT 
    )
    INSERT INTO #Title ( TitleName1, TitleSeq1, TitleName2, TitleSeq2, TitleName3, TitleSeq3 )

    SELECT CASE WHEN B.ValueText = '1' THEN '공과금' ELSE '노임' END AS TitleName1, 
           CASE WHEN B.ValueText = '1' THEN 2 ELSE 1 END AS TitleSeq1, 
           A.MinorName AS TitleName2, 
           A.MinorSeq AS TitleSeq2, 
           E.MinorName AS TitleName3, 
           100 + ROW_NUMBER() OVER(ORDER BY A.MinorSeq) AS TitleSeq3
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000001 )        
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 )        
      LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000004 )        
      LEFT OUTER JOIN _TDAUMinor        AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015942
       AND ( B.ValueText = '1' OR C.ValueText = '1' ) 
     ORDER BY A.MinorSort

    SELECT * FROM #Title

    
    -- Fix 
    CREATE TABLE #FixCol
    (
         RowIdx         INT IDENTITY(0, 1), 
         StdSeq         INT, 
         StdSerl        INT, 
         PJTTypeSeq     INT, 
         PJTTypeName    NVARCHAR(200), 
         UMLoadWaySeq   INT, 
         UMLoadWayName  NVARCHAR(200) 
    )
    INSERT INTO #FixCol ( StdSeq, StdSerl, PJTTypeSeq, PJTTypeName, UMLoadWaySeq, UMLoadWayName ) 
    SELECT A.StdSeq, 
           A.StdSerl, 
           A.PJTTypeSeq, 
           B.PJTTypeName, 
           A.UMLoadWaySeq, 
           C.MinorName
      FROM mnpt_TPJTUnionWagePriceItem  AS A 
      LEFT OUTER JOIN _TPJTType         AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMLoadWaySeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @StdSeq 
    
    SELECT * FROM #FixCol 
    
    -- Value
    CREATE TABLE #Value
    (
         
         StdSeq     INT, 
         StdSerl    INT, 
         TitleSeq   INT, 
         Value      DECIMAL(19, 5) 
    )
    
    INSERT INTO #Value (StdSeq, StdSerl, TitleSeq, Value)
    SELECT A.StdSeq, A.StdSerl, A.TitleSeq, A.Value
      FROM mnpt_TPJTUnionWagePriceValue AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.StdSeq = @StdSeq 

    
    SELECT B.RowIdx, A.ColIdx, C.Value 
      FROM #Value   AS C
      JOIN #Title   AS A ON ( A.TitleSeq2 = C.TitleSeq ) 
      JOIN #FixCol  AS B ON ( B.StdSeq = C.StdSeq AND B.StdSerl = C.StdSerl ) 
     ORDER BY A.ColIdx, B.RowIdx


    
    RETURN     
Go


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

        , StdSeq INT
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

        , StdDate CHAR(8), Remark NVARCHAR(200), StdSeq INT, FrStdDate CHAR(8), ToStdDate CHAR(8)
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

        , TitleName1 NVARCHAR(200), TitleSeq1 INT, TitleName2 NVARCHAR(200), TitleSeq2 INT, TitleName3 NVARCHAR(200), TitleSeq3 INT
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

        , TitleName1 NVARCHAR(200), TitleSeq1 INT, TitleName2 NVARCHAR(200), TitleSeq2 INT, TitleName3 NVARCHAR(200), TitleSeq3 INT
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

        , PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UMLoadWayName NVARCHAR(200), UMLoadWaySeq INT, StdSeq INT, StdSerl INT, TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5)
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

        , PJTTypeName NVARCHAR(200), PJTTypeSeq INT, UMLoadWayName NVARCHAR(200), UMLoadWaySeq INT, StdSeq INT, StdSerl INT, TITLE_IDX0_SEQ INT, Value DECIMAL(19, 5)
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
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdSeq) 
SELECT N'', 1, 1, 1, 0, NULL, NULL, NULL, N'DataBlock1', N'7'
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

SET @ServiceSeq     = 13820028
--SET @MethodSeq      = 3
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820023
SET @IsTransaction  = 0
-- ExecuteOrder : 1 : StartEXEC    mnpt_SPJTUnionWagePriceItemQuery            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
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
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1DROP TABLE #BIZ_IN_DataBlock2DROP TABLE #BIZ_OUT_DataBlock2DROP TABLE #BIZ_IN_DataBlock3DROP TABLE #BIZ_OUT_DataBlock3DROP TABLE #BIZ_IN_DataBlock4DROP TABLE #BIZ_OUT_DataBlock4rollback 