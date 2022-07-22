IF OBJECT_ID('hencom_SCOMFSQueryTermCmp_GAAPFS_IS_AllSlipUnitQuery') IS NOT NULL 
    DROP PROC hencom_SCOMFSQueryTermCmp_GAAPFS_IS_AllSlipUnitQuery
GO 

-- v2017.08.11

-- 전표관리단위별로 조회되도록 수정(다이나믹) by이재천
/************************************************************
설  명 - 제조원가명세서 조회
작성일 - 2008년 11월 11일
작성자 - 김일주
************************************************************/
CREATE PROC dbo.hencom_SCOMFSQueryTermCmp_GAAPFS_IS_AllSlipUnitQuery
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT = 0,
    @ServiceSeq     INT = 0,
    @WorkingTag     NVARCHAR(10) = '',
    @CompanySeq     INT = 0,
    @LanguageSeq    INT = 1,
    @UserSeq        INT = 0,
    @PgmSeq         INT = 0
AS
    -- 변수선언 부분
    DECLARE @docHandle          INT,
            @AccUnit            INT,
            @FrAccYM            NCHAR(8),
            @ToAccYM            NCHAR(8),
            @PrevFrAccYM        NCHAR(8),
            @PrevToAccYM        NCHAR(8),
            @FrAccDate          NCHAR(8),
            @ToAccDate          NCHAR(8),
            @PrevFrAccDate      NCHAR(8),
            @PrevToAccDate      NCHAR(8),            
            @LastStartDate      NCHAR(8),
            @LastEndDate        NCHAR(8),
            @argLanguageSeq     INT,
            @IsInit             NCHAR(1),
            @PrevIsInit         NCHAR(1),
            @IsUseUMCostType    NCHAR(1),
            @FSKindNo           NVARCHAR(20),
            @FSDomainSeq        INT,
            @FormatSeq          INT,
            @RptUnit            INT,
            @argString          NVARCHAR(4000),
            @FrSttlYM           NCHAR(6),
            @ToSttlYM           NCHAR(6),
            @PrevFrSttlYM       NCHAR(6),
            @PrevToSttlYM       NCHAR(6),
            @IsDisplayZero      NCHAR(1),
            @FTASeq             INT,
            @MultiAccUnit       NVARCHAR(MAX),
            @SlipUnit           INT
	CREATE TABLE #BSISLevel (LevelSeq INT, BS NVARCHAR(1), INS NVARCHAR(1))  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    IF @PgmSeq NOT IN (100477, 100483, 100484, 100485 )   -- 모바일 제외
    BEGIN
        SELECT @AccUnit             = ISNULL(AccUnit, 0),
               @FrAccYM             = REPLACE(ISNULL(RTRIM(FrAccYM), ''), '-', ''),
               @ToAccYM             = REPLACE(ISNULL(RTRIM(ToAccYM), ''), '-', ''),
               @PrevFrAccYM         = REPLACE(ISNULL(RTRIM(PrevFrAccYM), ''), '-', ''),
               @PrevToAccYM         = REPLACE(ISNULL(RTRIM(PrevToAccYM), ''), '-', ''),
               @FrAccDate           = ISNULL(RTRIM(FrAccDate), '' ), -- 시작회계일자
               @ToAccDate           = ISNULL(RTRIM(ToAccDate), '' ), -- 종료회계일자
               @argLanguageSeq      = ISNULL(LanguageSeq, 0),
               @FSDomainSeq         = ISNULL(FSDomainSeq   , 11 ),   -- 재무제표구조영역
               @FSKindNo            = ISNULL(FSKindNo      , '' ),   -- 재무제표종류코드
               @FormatSeq           = ISNULL(FormatSeq     ,  0 ),   -- 재무제표구조
               @RptUnit             = ISNULL(RptUnit       ,  0 ),   -- 보고결산단위
               @IsDisplayZero       = ISNULL(IsDisplayZero , '0'),   -- 0금액표시여부
               @IsInit              = ISNULL(IsInit        , '0'),   -- 당기기초           
               @PrevIsInit          = ISNULL(PrevIsInit    , '0'),   -- 전기기초     
               @FTASeq              = ISNULL(FTASeq        ,  0 ),   -- FTA협정
               @MultiAccUnit        = ISNULL(MultiAccUnit  ,  ''),   -- 멀티회계단위
               @SlipUnit            = ISNULL(SlipUnit      ,  0 )    -- 전표관리단위  2012.09.19 추가 by bgKeum
          FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
          WITH (AccUnit         INT,
                FrAccYM         NCHAR(8),
                ToAccYM         NCHAR(8),
                PrevFrAccYM     NCHAR(8),
                PrevToAccYM     NCHAR(8),
                FrAccDate       NCHAR(8),
                ToAccDate       NCHAR(8),
                LanguageSeq     INT,
                FSDomainSeq     INT,
                FSKindNo        NVARCHAR(20),
                FormatSeq       INT,
                RptUnit         INT,
                IsDisplayZero   NCHAR(1),
                IsInit          NCHAR(1),
                PrevIsInit      NCHAR(1),
                FTASeq          INT,
                MultiAccUnit    NVARCHAR(MAX),
                SlipUnit        INT
                )
    END
    ELSE
    BEGIN
        SELECT @AccUnit             = ISNULL(AccUnit, 0),  
               @FrAccYM             = REPLACE(ISNULL(RTRIM(FrAccYM), ''), '-', ''),  
               @ToAccYM             = REPLACE(ISNULL(RTRIM(ToAccYM), ''), '-', ''),  
               @PrevFrAccYM         = REPLACE(ISNULL(RTRIM(PrevFrAccYM), ''), '-', ''),  
               @PrevToAccYM         = REPLACE(ISNULL(RTRIM(PrevToAccYM), ''), '-', ''),  
               @FrAccDate           = ISNULL(RTRIM(FrAccDate), '' ), -- 시작회계일자  
               @ToAccDate           = ISNULL(RTRIM(ToAccDate), '' ), -- 종료회계일자  
               @argLanguageSeq      = ISNULL(LanguageSeq, 0),  
               @FSDomainSeq         = ISNULL(FSDomainSeq   , 11 ),   -- 재무제표구조영역  
               @FSKindNo            = ISNULL(FSKindNo      , '' ),   -- 재무제표종류코드  
               @FormatSeq           = ISNULL(FormatSeq     ,  0 ),   -- 재무제표구조  
               @RptUnit             = ISNULL(RptUnit       ,  0 ),   -- 보고결산단위  
               @IsDisplayZero       = ISNULL(IsDisplayZero , '0'),   -- 0금액표시여부  
               @IsInit              = ISNULL(IsInit        , '0'),   -- 당기기초             
               @PrevIsInit          = ISNULL(PrevIsInit    , '0'),   -- 전기기초       
               @FTASeq              = ISNULL(FTASeq        ,  0 ),   -- FTA협정  
               @MultiAccUnit        = ISNULL(MultiAccUnit  ,  ''),   -- 멀티회계단위  
               @SlipUnit            = ISNULL(SlipUnit      ,  0 )    -- 전표관리단위  2012.09.19 추가 by bgKeum  
          FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
          WITH (AccUnit         INT,  
                FrAccYM         NCHAR(8),  
                ToAccYM         NCHAR(8),  
                PrevFrAccYM     NCHAR(8),  
                PrevToAccYM     NCHAR(8),  
                FrAccDate       NCHAR(8),  
                ToAccDate       NCHAR(8),  
                LanguageSeq     INT,  
                FSDomainSeq     INT,  
                FSKindNo        NVARCHAR(20),  
                FormatSeq       INT,  
                RptUnit         INT,  
                IsDisplayZero   NCHAR(1),  
                IsInit          NCHAR(1),  
                PrevIsInit      NCHAR(1),  
                FTASeq          INT,  
                MultiAccUnit    NVARCHAR(MAX),  
                SlipUnit        INT  
                )
    END
	INSERT #BSISLevel 
	SELECT ISNULL(DisplayLevel,0),
           ISNULL(BSItem,''),
           ISNULL(ISItem,'')
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (    DisplayLevel INT     ,
                BSItem       NCHAR(1),
                ISItem       NCHAR(1))   
    
    IF @RptUnit > 0
    BEGIN
        SELECT @FSDomainSeq = FSDomainSeq
		FROM   _TCRRptUnit
        WHERE  CompanySeq = @CompanySeq 
        AND    RptUnit = @RptUnit
	END
	
	IF LEN(RTRIM(LTRIM(@FrAccYM))) = 8 AND @FrAccDate = '' AND @ToAccDate = ''  --일자별일때
	BEGIN
		SELECT @FrAccDate = @FrAccYM		
		SELECT @ToAccDate = @ToAccYM
		SELECT @FrAccYM = LEFT(@FrAccYM, 6)
		SELECT @ToAccYM = LEFT(@ToAccYM, 6)
		
		SELECT @PrevFrAccDate = @PrevFrAccYM		
		SELECT @PrevToAccDate = @PrevToAccYM
		SELECT @PrevFrAccYM = LEFT(@PrevFrAccYM, 6)
		SELECT @PrevToAccYM = LEFT(@PrevToAccYM, 6)				
	END 	
    -- ISNULL 처리가 되지 않아 전기금액을 못 가져와서 추가함  dhkim3
	SELECT @PrevFrAccDate = ISNULL(@PrevFrAccDate, '')
	SELECT @PrevToAccDate = ISNULL(@PrevToAccDate, '')
    
    IF @FormatSeq = 0 
    BEGIN
        -- 재무제표구조마스터 선택
        SELECT TOP 1 @FormatSeq   = A.FormatSeq,           -- 재무제표구조코드
                     @IsUseUMCostType = B.IsUseUMCostType  -- 비용구분 사용여부
          FROM _TCOMFSForm AS A WITH (NOLOCK)
          JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq  
          JOIN _TCOMFSKind AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.FSKindSeq = C.FSKindSeq  
         WHERE A.CompanySeq   = @CompanySeq
           AND C.FSKindNo     = @FSKindNo                  -- 재무제표종류코드
           AND A.FSDomainSeq  = @FSDomainSeq               -- 재무제표구조영역
           AND A.IsDefault    = '1' 
           AND @ToAccYM BETWEEN A.FrYM AND A.ToYM          -- 기간내에 하나만 존재
    END

    -- 비용구분 사용여부를 읽어온다.  
    SELECT  @IsUseUMCostType = B.IsUseUMCostType  
      FROM _TCOMFSForm AS A WITH (NOLOCK)  
      JOIN _TCOMFSDomainFSKind AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSDomainSeq = B.FSDomainSeq AND A.FSKindSeq = B.FSKindSeq  
     WHERE A.CompanySeq   = @CompanySeq  
       AND A.FormatSeq    = @FormatSeq  
    
    CREATE TABLE #tmpFinancialStatement
    (
        RowNum      INT IDENTITY(0, 1)
    )
    ALTER TABLE #tmpFinancialStatement ADD ThisTermItemAmt       DECIMAL(19, 5)  -- 당기항목금액
    ALTER TABLE #tmpFinancialStatement ADD ThisTermAmt           DECIMAL(19, 5)  -- 당기금액
    ALTER TABLE #tmpFinancialStatement ADD PrevTermItemAmt       DECIMAL(19, 5)  -- 전기항목금액
    ALTER TABLE #tmpFinancialStatement ADD PrevTermAmt           DECIMAL(19, 5)  -- 전기금액
    ALTER TABLE #tmpFinancialStatement ADD PrevChildAmt          DECIMAL(19, 5)  -- 하위금액
    ALTER TABLE #tmpFinancialStatement ADD ThisChildAmt          DECIMAL(19, 5)  -- 하위금액
    ALTER TABLE #tmpFinancialStatement ADD ThisReplaceFormula    NVARCHAR(1000)   -- 당기금액
    ALTER TABLE #tmpFinancialStatement ADD PrevReplaceFormula    NVARCHAR(1000)   -- 당기금액

    CREATE TABLE #Result 
    (
        SlipUnit            INT, 
        RowNum              INT, 
        FSItemNamePrt       NVARCHAR(1000), 
        ThisTermItemAmt     DECIMAL(19,5), 
        SMItemForeColorCode INT, 
        SMItemBackColorCode INT, 
        FSItemSort          INT, 
        FSItemSeq           INT 
    )
    
    -- 재무제표 기본 초기 형태 생성
    EXEC _SCOMFSFormInit @CompanySeq, @FormatSeq, @argLanguageSeq, '#tmpFinancialStatement'
    IF @@ERROR <> 0  RETURN
    
    -- while를 위해서 담아두기 
    SELECT * 
      INTO #tmpFinancialStatement_Sub
      FROM #tmpFinancialStatement
    
    DECLARE @cFSItemTypeSeq INT,
            @cFSItemSeq     INT,
            @cUMCostType    INT
    SELECT @cFSItemTypeSeq = A.FSItemTypeSeq, 
           @cFSItemSeq     = A.FSItemSeq, 
           @cUMCostType    = A.UMCostType
    FROM   _TCOMFSFormTree AS A WITH(NOLOCK)
    JOIN   _TDAAccount AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.FSItemTypeSeq = 2 AND A.FSItemSeq = B.AccSeq     
    WHERE  A.CompanySeq  = @CompanySeq
    AND    A.FormatSeq   = 2
    AND    B.SMAccKind   = 4018003 -- 자본
    AND    A.FSItemLevel = 1  



    SELECT Z.ValueSeq AS SlipUnit, Y.MinorSort 
      INTO #UseSlipUnit
      FROM _TDAUMinorValue  AS Z WITH(NOLOCK) 
      JOIN _TDAUMinor       AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.MinorSeq ) 
     WHERE Z.CompanySeq = @CompanySeq  
       AND Z.MajorSeq = 1015303 
       AND Z.Serl = 1000001 
       AND Y.IsUse = '1' 


    -- 전체 전표관리단위 담기, Srt
    CREATE TABLE #SlipUnit 
    (
        IDX_NO      INT IDENTITY , 
        SlipUnit    INT 
    )

    INSERT INTO #SlipUnit ( SlipUnit ) 
    SELECT A.SlipUnit 
      FROM _TACSlipUnit AS A 
      JOIN #UseSlipUnit AS B ON ( B.SlipUnit = A.SlipUnit ) 
     ORDER BY SlipUnit 
    -- 전체 전표관리단위 담기, End 
    
    
    DECLARE @Cnt INT
    SELECT @Cnt = 1 


    WHILE ( @Cnt <= (SELECT MAX(IDX_NO) FROM #SlipUnit) ) 
    BEGIN 
       
        
        TRUNCATE TABLE #tmpFinancialStatement 

        INSERT INTO #tmpFinancialStatement
        (
            ThisTermItemAmt, ThisTermAmt, PrevTermItemAmt, PrevTermAmt, 
            PrevChildAmt, ThisChildAmt, ThisReplaceFormula, PrevReplaceFormula, FSItemTypeSeq, 
            FSItemSeq, UMCostType, FormatSerl, FSItemName, ParentType, 
            ParentSeq, ParentUMCostType, FSItemLevel, FSItemSort, FSItemNo, 
            SMDrOrCr, SMAccKind, Number, strNumber, SMAmtPosOpt, 
            strAmtPosOpt, SMDisplayItemOpt, strDisplayItemOpt, SMNumType, strNumType, 
            SMItemForeColorCode, strItemForeColorCode, SMItemBackColorCode, strItemBackColorCode, IsSubtraction, 
            IsGarbage, ChildCnt, FSItemNamePrt, FSItemTypeName, UMCostTypeName, 
            IsSlip, DrAmt, CrAmt, IniDrAmt, IniCrAmt, 
            MonthDrAmt, MonthCrAmt, DrBalAmt, CrBalAmt, DrCumulativeAmt, 
            CrCumulativeAmt, OpeningBalAmt, ClosingBalAmt, TermItemAmt, TermAmt, 
            ChildAmt, ReplaceFormula, IsSetAmt
        )
        SELECT ThisTermItemAmt, ThisTermAmt, PrevTermItemAmt, PrevTermAmt, 
               PrevChildAmt, ThisChildAmt, ThisReplaceFormula, PrevReplaceFormula, FSItemTypeSeq, 
               FSItemSeq, UMCostType, FormatSerl, FSItemName, ParentType, 
               ParentSeq, ParentUMCostType, FSItemLevel, FSItemSort, FSItemNo, 
               SMDrOrCr, SMAccKind, Number, strNumber, SMAmtPosOpt, 
               strAmtPosOpt, SMDisplayItemOpt, strDisplayItemOpt, SMNumType, strNumType, 
               SMItemForeColorCode, strItemForeColorCode, SMItemBackColorCode, strItemBackColorCode, IsSubtraction, 
               IsGarbage, ChildCnt, FSItemNamePrt, FSItemTypeName, UMCostTypeName, 
               IsSlip, DrAmt, CrAmt, IniDrAmt, IniCrAmt, 
               MonthDrAmt, MonthCrAmt, DrBalAmt, CrBalAmt, DrCumulativeAmt, 
               CrCumulativeAmt, OpeningBalAmt, ClosingBalAmt, TermItemAmt, TermAmt, 
               ChildAmt, ReplaceFormula, IsSetAmt
          FROM #tmpFinancialStatement_Sub

        SELECT @SlipUnit = SlipUnit 
          FROM #SlipUnit 
         WHERE IDX_NO = @Cnt 
        
        --원장에 의한 재무제표 기본 금액 생성
        EXEC _SCOMFSFormMakeRawData @CompanySeq, @FormatSeq, @IsUseUMCostType, @AccUnit, @FrAccYM, @ToAccYM, @FrAccDate, @ToAccDate, @argString, '#tmpFinancialStatement','1', @IsInit, '0', @SlipUnit
        IF @@ERROR <> 0  RETURN
    
        -- 재무제표 설정에 의한 계산
        EXEC _SCOMFSFormCalc @CompanySeq, @FormatSeq, '#tmpFinancialStatement', @IsUseUMCostType
        IF @@ERROR <> 0  RETURN
        
        UPDATE A
           SET ThisTermItemAmt = CASE WHEN A.ParentType = 0 THEN TermAmt ELSE A.TermItemAmt END 
          FROM #tmpFinancialStatement AS A
    

        -- 표시양식 적용
        EXEC _SCOMFSFormApplyStyle @CompanySeq, @FormatSeq, '#tmpFinancialStatement', '0', '1'
        IF @@ERROR <> 0  RETURN
    

        -- 전표관리단위별로 담아두기
        INSERT INTO #Result 
        ( 
            SlipUnit, RowNum, FSItemNamePrt, ThisTermItemAmt, SMItemForeColorCode, 
            SMItemBackColorCode, FSItemSort, FSItemSeq
        ) 
        SELECT @SlipUnit AS SlipUnit, 
               A.RowNum, 
               A.FSItemNamePrt,
               A.ThisTermItemAmt,     -- 당기항목금액
               A.SMItemForeColorCode,
               A.SMItemBackColorCode, 
               A.FSItemSort, 
               A.FSItemSeq
          FROM #tmpFinancialStatement AS A 
          LEFT OUTER JOIN #BSISLevel AS B ON A.FSItemLevel = B.LevelSeq 
         WHERE  B.BS = '1'
         ORDER BY A.FSItemSort   
        
        SELECT @Cnt = @Cnt + 1 
    
    END 
    

    -- 0금액 보임여부, Srt
    SELECT DISTINCT FSItemSeq
      INTO #IsNotZero
      FROM #Result 
     WHERE ThisTermItemAmt <> 0 
       OR SMItemBackColorCode IS NOT NULL 
    
    IF @IsDisplayZero = '0' 
    BEGIN 
        DELETE A 
          FROM #Result  AS A 
          LEFT OUTER JOIN #IsNotZero  AS B ON ( B.FSItemSeq = A.FSItemSeq ) 
         WHERE B.FSItemSeq IS NULL 
    END 
    -- 0금액 보임여부, End 

    -- Title 
    CREATE TABLE #Title	
    ( 
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT 
    ) 
    
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT B.SlipUnitName, A.SlipUnit 
      FROM (
            SELECT DISTINCT SlipUnit 
              FROM #Result
           ) AS A 
      JOIN _TACSlipUnit AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipUnit = A.SlipUnit ) 
      JOIN #UseSlipUnit AS C ON ( C.SlipUnit = A.SlipUnit ) 
     ORDER BY C.MinorSort 
    
    SELECT * FROM #Title 
    
    -- Fix 
    CREATE TABLE #FixCol 
    ( 
        RowIdx              INT IDENTITY(0, 1), 
        RowNum              INT, 
        FSItemNamePrt       NVARCHAR(100), 
        ThisTermItemAmt     DECIMAL(19,5), 
        SMItemForeColorCode INT, 
        SMItemBackColorCode INT 
    ) 
    
    INSERT INTO #FixCol ( RowNum, FSItemNamePrt, ThisTermItemAmt, SMItemForeColorCode, SMItemBackColorCode ) 
    SELECT RowNum, FSItemNamePrt, SUM(ThisTermItemAmt), MAX(SMItemForeColorCode), MAX(SMItemBackColorCode)
      FROM #Result 
     GROUP BY RowNum, FSItemNamePrt, FSItemSort
     ORDER BY FSItemSort 
    
    SELECT * FROM #FixCol 
    
    -- Value 
    CREATE TABLE #Value	
    ( 
        SlipUnit        INT, 
        RowNum          INT, 
        ThisTermItemAmt DECIMAL(19, 5) 
    ) 
    
    INSERT INTO #Value ( SlipUnit, RowNum, ThisTermItemAmt ) 
    SELECT SlipUnit, RowNum, ThisTermItemAmt 
      FROM #Result 
    
    -- 결과값 조회 
    SELECT B.RowIdx, A.ColIdx, C.ThisTermItemAmt AS Value 
      FROM #Value   AS C 
      JOIN #Title   AS A ON ( A.TitleSeq = C.SlipUnit ) 
      JOIN #FixCol  AS B ON ( B.RowNum = C.RowNum ) 
     ORDER BY A.ColIdx, B.RowIdx 
    
    RETURN
    /**********************************************************************************************************/
    
go 
--begin tran 
--exec hencom_SCOMFSQueryTermCmp_GAAPFS_IS_AllSlipUnitQuery @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag />
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <DisplayLevel>1</DisplayLevel>
--    <BSItem>1</BSItem>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <AccUnit />
--    <FrAccYM>201701</FrAccYM>
--    <ToAccYM>201701</ToAccYM>
--    <PrevFrAccYM>201601</PrevFrAccYM>
--    <PrevToAccYM>201608</PrevToAccYM>
--    <FSKindNo>IS</FSKindNo>
--    <LanguageSeq />
--    <FSDomainSeq>11</FSDomainSeq>
--    <RptUnit />
--    <IsDisplayZero>0</IsDisplayZero>
--    <IsInit>0</IsInit>
--    <PrevIsInit>0</PrevIsInit>
--    <FTASeq />
--    <SlipUnit />
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <DisplayLevel>2</DisplayLevel>
--    <BSItem>0</BSItem>
--    <AccUnit />
--    <FrAccYM>201701</FrAccYM>
--    <ToAccYM>201701</ToAccYM>
--    <PrevFrAccYM>201601</PrevFrAccYM>
--    <PrevToAccYM>201608</PrevToAccYM>
--    <FSKindNo>IS</FSKindNo>
--    <LanguageSeq />
--    <FSDomainSeq>11</FSDomainSeq>
--    <RptUnit />
--    <IsDisplayZero>0</IsDisplayZero>
--    <IsInit>0</IsInit>
--    <PrevIsInit>0</PrevIsInit>
--    <FTASeq />
--    <SlipUnit />
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <DisplayLevel>3</DisplayLevel>
--    <BSItem>0</BSItem>
--    <AccUnit />
--    <FrAccYM>201701</FrAccYM>
--    <ToAccYM>201701</ToAccYM>
--    <PrevFrAccYM>201601</PrevFrAccYM>
--    <PrevToAccYM>201608</PrevToAccYM>
--    <FSKindNo>IS</FSKindNo>
--    <LanguageSeq />
--    <FSDomainSeq>11</FSDomainSeq>
--    <RptUnit />
--    <IsDisplayZero>0</IsDisplayZero>
--    <IsInit>0</IsInit>
--    <PrevIsInit>0</PrevIsInit>
--    <FTASeq />
--    <SlipUnit />
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag>U</WorkingTag>
--    <IDX_NO>4</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <DisplayLevel>4</DisplayLevel>
--    <BSItem>0</BSItem>
--    <AccUnit />
--    <FrAccYM>201701</FrAccYM>
--    <ToAccYM>201701</ToAccYM>
--    <PrevFrAccYM>201601</PrevFrAccYM>
--    <PrevToAccYM>201608</PrevToAccYM>
--    <FSKindNo>IS</FSKindNo>
--    <LanguageSeq />
--    <FSDomainSeq>11</FSDomainSeq>
--    <RptUnit />
--    <IsDisplayZero>0</IsDisplayZero>
--    <IsInit>0</IsInit>
--    <PrevIsInit>0</PrevIsInit>
--    <FTASeq />
--    <SlipUnit />
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1512371,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033723
--rollback 