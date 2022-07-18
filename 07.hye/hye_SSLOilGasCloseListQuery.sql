 
IF OBJECT_ID('hye_SSLOilGasCloseListQuery') IS NOT NULL   
    DROP PROC hye_SSLOilGasCloseListQuery  
GO  
  
-- v2017.01.10
  
-- POS주유소충전소마감현황_hye-조회 by이재천 
CREATE PROC hye_SSLOilGasCloseListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYM      NCHAR(6), 
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8), 
            @SlipKind   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM     = ISNULL( StdYM    , '' ),
           @DateFr    = ISNULL( DateFr   , '' ),
           @DateTo    = ISNULL( DateTo   , '' ),
           @SlipKind  = ISNULL( SlipKind , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              StdYM      NCHAR(6),
              DateFr     NCHAR(8),
              DateTo     NCHAR(8),
              SlipKind   INT
           )    
    
    
    ---------------------------------------------------------
    -- Title 
    ---------------------------------------------------------
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0,1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT
    )

    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT STUFF(STUFF(Solar,5,0,'-'),8,0,'-'), Solar
      FROM _TCOMCalendar 
     WHERE LEFT(Solar,6) = @StdYM 
    
    UNION ALL 

    SELECT '당월', @StdYM
    
    SELECT * FROM #Title 
    
    ---------------------------------------------------------
    -- Fix
    ---------------------------------------------------------
    CREATE TABLE #FixCol
    (
        RowIdx      INT IDENTITY(0,1), 
        BizUnitName NVARCHAR(100), 
        BizUnit     INT
    )
    INSERT INTO #FixCol ( BizUnitName, BizUnit ) 
    SELECT MinorName, B.ValueText
      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1013753

    SELECT * FROM #FixCol 

    ---------------------------------------------------------
    -- Value
    ---------------------------------------------------------
    
    SELECT B.BizUnit, BizUnitName, A.TitleSeq, A.Title
      INTO #Main
      FROM #Title               AS A 
      LEFT OUTER JOIN #FixCol   AS B ON ( 1 = 1 ) 
    

    SELECT A.TitleSeq AS StdDate, 
           A.BizUnit,
           CASE WHEN (CASE WHEN LEN(A.TitleSeq) = 6 THEN D.BizUnit ELSE C.BizUnit END) IS NOT NULL THEN '회계반영(마감)' 
                WHEN C.BizUnit IS NULL AND B.CompanySeq IS NOT NULL THEN '마감' 
                WHEN B.CompanySeq IS NULL AND O.CompanySeq IS NOT NULL THEN '제출'
                ELSE '미제출'
                END AS Value 
      INTO #Value 
      FROM #Main                                AS A 
      LEFT OUTER JOIN hye_TSLOilSalesIsCfm      AS O ON ( O.CompanySeq = @CompanySeq 
                                                      AND O.StdYMDate = A.TitleSeq 
                                                      AND O.BizUnit = A.BizUnit 
                                                      AND O.IsCfm = '1' 
                                                        ) 

      LEFT OUTER JOIN hye_TSLOilSalesIsClose    AS B ON ( B.CompanySeq = @CompanySeq 
                                                      AND B.StdYMDate = A.TitleSeq 
                                                      AND B.BizUnit = A.BizUnit 
                                                      AND B.IsClose = '1' 
                                                      AND B.io_type = CASE WHEN @SlipKind = 1013901001 THEN 'O' ELSE 'I' END 
                                                        ) 
      LEFT OUTER JOIN (
                        SELECT BizUnit, StdDate
                          FROM hye_TSLPOSSlipRelation 
                         WHERE CompanySeq = @CompanySeq 
                           AND ISNULL(SlipMstSeq,0) <> 0 
                           AND UMSlipKind = @SlipKind
                         GROUP BY BizUnit, StdDate
                      ) AS C ON ( C.BizUnit = A.BizUnit AND C.StdDate = A.TitleSeq )  

      LEFT OUTER JOIN (
                        SELECT BizUnit, StdYM
                          FROM hye_TSLPOSSlipMonthRelation 
                         WHERE CompanySeq = @CompanySeq 
                           AND ISNULL(SlipMstSeq,0) <> 0 
                           AND UMSlipKind = @SlipKind
                         GROUP BY BizUnit, StdYM
                      ) AS D ON ( D.BizUnit = A.BizUnit AND D.StdYM = A.TitleSeq )  
    

    SELECT B.RowIdx, A.ColIdx, C.Value AS Value
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.StdDate ) 
      JOIN #FixCol AS B ON ( B.BizUnit = C.BizUnit ) 
     ORDER BY A.ColIdx, B.RowIdx




    RETURN  
    GO
begin tran 
exec hye_SSLOilGasCloseListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201612</StdYM>
    <DateFr>20161201</DateFr>
    <DateTo>20161203</DateTo>
    <SlipKind>1013901002</SlipKind>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730179,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=77730064
rollback 