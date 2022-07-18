    
IF OBJECT_ID('KPX_SPDWorkReportMonthDailyListQuery') IS NOT NULL   
    DROP PROC KPX_SPDWorkReportMonthDailyListQuery  
GO 

-- v2016.01.26 
  
-- 생산월보조회(자재)-조회 by 이재천 
CREATE PROC KPX_SPDWorkReportMonthDailyListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @FactUnit       INT,                     
            @StdYMFr        NCHAR(6),                     
            @StdYMTo        NCHAR(6), 
            @ItemName       NVARCHAR(200), 
            @AssetSeq       INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FactUnit       = ISNULL( FactUnit  , 0 ), 
           @StdYMFr        = ISNULL( StdYMFr   , '' ), 
           @StdYMTo        = ISNULL( StdYMTo   , '' ), 
           @ItemName       = ISNULL( ItemName  , '' ), 
           @AssetSeq       = ISNULL( AssetSeq  , 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,          
            StdYMFr        NCHAR(6),           
            StdYMTo        NCHAR(6),       
            ItemName       NVARCHAR(200), 
            AssetSeq       INT 
           )    
    
    CREATE TABLE #TPDSFCWorkReport        
    ( 
        StdYM           NCHAR(6), 
        WorkReportSeq   INT, 
        AssyItemSeq     INT, 
        AssyItemName    NVARCHAR(255), 
        OKQty           DECIMAL(19,5), 
        Gubun           INT, 
        Sort            INT 
    )        
    
    INSERT INTO #TPDSFCWorkReport        
    SELECT LEFT(A.WorkDate,6), A.WorkReportSeq, A.AssyItemSeq, C.ItemName, SUM(STDUnitOKQty) AS OKQty, E.MngValSeq, 1        
      FROM _TPDSFCWorkReport        AS A With(Nolock)        
                 JOIN _TDAItem            AS C With(nolock) On A.CompanySeq = C.CompanySeq And A.AssyItemSeq = C.ItemSeq        
                 JOIN _TDAItemAsset       AS D With(nolock) On C.CompanySeq = D.CompanySeq And C.AssetSeq = D.AssetSeq  And D.SMAssetGrp NOT IN ( 6008005)        
      LEFT OUTER JOIN _TDAItemUserDefine AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND A.AssyItemSeq = E.ItemSeq AND E.MngSerl = 1000003        
     WHERE A.CompanySeq = @CompanySeq         
       AND ( LEFT(A.WorkDate,6) BETWEEN @StdYMFr AND @StdYMTo ) 
       AND ( @FactUnit = 0 OR A.FactUnit = @FactUnit ) 
     GROUP BY LEFT(A.WorkDate,6), A.WorkReportSeq, A.AssyItemSeq, C.ItemName, E.MngValSeq        
    
    CREATE TABLE #TPDSFCWorkReportMat        
    ( 
        StdYM           NCHAR(6), 
        AssyItemSeq     INT, 
        ItemCnt         INT, 
        MatItemSeq      INT, 
        MatItemName     NVARCHAR(250), 
        MatItemSName    NVARCHAR(100), 
        NeedQty         DECIMAL(19,5), 
        Gubun           INT, 
        Sort            INT 
    )        
    SELECT A.StdYM, 
           A.AssyItemSeq, 
           B.MatItemSeq, 
           C.ItemName, 
           CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END AS ItemSName, 
           SUM(STDUnitQty) AS NeedQty        
      INTO #TPDSFCWorkReportMatSub        
      FROM #TPDSFCWorkReport    AS A With(Nolock)        
      JOIN _TPDSFCMatinput      AS B With(nolock) On @CompanySeq = B.CompanySeq  and A.WorkReportSeq = B.WorkReportSeq        
      JOIN _TDAItem             AS C With(nolock) ON C.CompanySeq = B.CompanySeq And C.ItemSeq = B.MatItemSeq        
     GROUP BY A.StdYM, A.AssyItemSeq,B.MatItemSeq,C.ItemName , CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END         
    
    
    INSERT INTO #TPDSFCWorkReportMat  -- 1레벨에 대해서 제공품일 경우 해당 제공품의 투입 자재로 변경 처리        
    SELECT F.StdYM
          ,F.AssyItemSeq        
          ,ROW_NUMBER() OVER(PARTITION BY F.AssyItemSeq ORDER BY F.MatItemSeq ) as ItemCnt        
          ,F.MatItemSeq        
          ,F.ItemName        
          ,F.ItemSName        
          ,Sum(F.NeedQty) AS NeedQty        
          ,E.MngValSeq        
          ,1         
      FROM ( SELECT A.StdYM
                   ,A.AssyItemSeq        
                   ,B.MatItemSeq        
                   ,C.ItemName        
                   ,CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END AS ItemSName        
                   ,SUM(B.STDUnitQty) AS NeedQty        
              FROM #TPDSFCWorkReportMatSub AS A  With(Nolock)        
                  Join _TPDSFCWorkReport   AS A1 With(Nolock) ON @CompanySeq = A1.CompanySeq And A1.AssyItemSeq = A.MatItemSeq AND LEFT(A1.WorkDate,6) = A.StdYM
                  Join _TPDSFCMatinput     AS B  With(nolock) On A1.CompanySeq = B.CompanySeq  and A1.WorkReportSeq = B.WorkReportSeq         
                  Join _TDAItem            AS C  With(nolock) ON C.CompanySeq = B.CompanySeq And C.ItemSeq = B.MatItemSeq        
                  Join _TDAItem            AS C1 With(nolock) ON C1.CompanySeq = @CompanySeq And C1.ItemSeq = A.MatItemSeq        
                  Join _TDAItemAsset       AS D  With(nolock) ON C1.CompanySeq = D.CompanySeq And C1.AssetSeq = D.AssetSeq And D.SMAssetGrp IN ( 6008005)        
             WHERE A1.CompanySeq = @CompanySeq         
               AND ( LEFT(A1.WorkDate,6) BETWEEN @StdYMFr AND @StdYMTo ) 
               And (@FactUnit = 0 or A1.FactUnit = @FactUnit)        
             GROUP BY A.StdYM, A.AssyItemSeq,B.MatItemSeq,C.ItemName , CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END         
            
            UNION ALL        
            
            SELECT A.StdYM
                  ,A.AssyItemSeq        
                  ,A.MatItemSeq        
                  ,A.ItemName        
                  ,A.ItemSName        
                  ,sum(A.NeedQty) AS NeedQty        
              FROM #TPDSFCWorkReportMatSub AS A With(Nolock)        
                  Join _TDAItem            AS C With(nolock) ON C.CompanySeq = @CompanySeq  And C.ItemSeq = A.MatItemSeq        
                  Join _TDAItemAsset       AS D With(nolock) ON C.CompanySeq = D.CompanySeq And C.AssetSeq = D.AssetSeq And D.SMAssetGrp NOT IN ( 6008005)        
             GROUP BY A.StdYM, A.AssyItemSeq,A.MatItemSeq,A.ItemName , A.ItemSName        
           )  AS  F        
      LEFT OUTER JOIN _TDAItemUserDefine AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND F.AssyItemSeq = E.ItemSeq AND E.MngSerl = 1000003      
     Group by F.StdYM, F.AssyItemSeq, F.MatItemSeq, F.ItemName, F.ItemSName, E.MngValSeq        
    
    
    --AM사업부는 공정이3단계라서 한번더 태움. 20150805        
    IF @FactUnit = 0 OR @FactUnit = 5         
    BEGIN        
        INSERT INTO #TPDSFCWorkReportMat  -- 1레벨에 대해서 제공품일 경우 해당 제공품의 투입 자재로 변경 처리        
        SELECT F.StdYM
              ,F.AssyItemSeq        
              ,ItemCnt + ROW_NUMBER() OVER(PARTITION BY F.AssyItemSeq ORDER BY F.MatItemSeq ) as ItemCnt        
              ,F.MatItemSeq        
              ,F.ItemName        
              ,F.ItemSName        
              ,Sum(F.NeedQty) AS NeedQty        
              ,E.MngValSeq        
              ,1         
          from ( select A.StdYM 
                       ,A.AssyItemSeq        
                       ,B.MatItemSeq        
                       ,C.ItemName        
                       ,CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END AS ItemSName        
                       ,sum(B.STDUnitQty) AS NeedQty        
                       ,MAX(ItemCnt) AS ItemCnt        
                   from #TPDSFCWorkReportMat AS A  With(Nolock)        
                        Join _TPDSFCWorkReport   AS A1 With(Nolock) ON @CompanySeq = A1.CompanySeq And A1.AssyItemSeq = A.MatItemSeq AND LEFT(A1.WorkDate,6) = A.StdYM
                        Join _TPDSFCMatinput     AS B  With(nolock) On A1.CompanySeq = B.CompanySeq  and A1.WorkReportSeq = B.WorkReportSeq         
                        Join _TDAItem            AS C  With(nolock) ON C.CompanySeq = B.CompanySeq And C.ItemSeq = B.MatItemSeq        
                        Join _TDAItem            AS C1 With(nolock) ON C1.CompanySeq = @CompanySeq And C1.ItemSeq = A.MatItemSeq        
                        Join _TDAItemAsset       AS D  With(nolock) ON C1.CompanySeq = D.CompanySeq And C1.AssetSeq = D.AssetSeq And D.SMAssetGrp IN ( 6008005)        
                   Where A1.CompanySeq = @CompanySeq         
                     AND ( LEFT(A1.WorkDate,6) BETWEEN @StdYMFr AND @StdYMTo )    
                     And (@FactUnit = 0 or A1.FactUnit = @FactUnit)        
                   group by A.StdYM, A.AssyItemSeq,B.MatItemSeq,C.ItemName , CASE WHEN ISNULL(C.ItemSName, '') = '' THEN '( ) ' + C.ItemName ELSE '(' + ISNULL(C.ItemSName, '') + ')' END         
               )  AS  F        
          LEFT OUTER JOIN _TDAItemUserDefine AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq AND F.AssyItemSeq = E.ItemSeq AND E.MngSerl = 1000003        
         --where F.MatItemSeq = 16 
         Group by F.StdYM, F.AssyItemSeq, F.MatItemSeq, F.ItemName, F.ItemSName, E.MngValSeq, ItemCnt        
    END        
    
    CREATE TABLE #BaseData 
    (
        ItemName        NVARCHAR(200), 
        ItemSeq         INT, 
        StdYM           NCHAR(8), 
        NeedQty         DECIMAL(19,5), 
        AssetName       NVARCHAr(100), 
        AssetSeq        INT 
        
    )
    INSERT INTO #BaseData ( ItemName, ItemSeq, StdYM, NeedQty, AssetName, AssetSeq ) 
    SELECT X.MatItemName, X.MatItemSeq, X.StdYM , SUM(X.NeedQty) AS NeedQty, CASE WHEN F.ItemSeq IS NULL THEN '제품' ELSE '원료' END, CASE WHEN F.ItemSeq IS NULL THEN 2 ELSE 1 END
      FROM #TPDSFCWorkReportMat AS X      
      LEFT OUTER JOIN _TDAItem AS E ON E.CompanySeq = @CompanySeq AND X.MatItemSeq = E.ItemSeq     
      LEFT OUTER JOIN (
                        SELECT A.ItemSeq 
                          FROM _TDAItem                 AS A 
                          LEFT OUTER JOIN _TDAItemAsset AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.AssetSeq = C.AssetSeq ) 
                          LEFT OUTER JOIN _TDASMinor    AS J WITH(NOLOCK) ON ( C.CompanySeq = J.CompanySeq AND J.MajorSeq = 6008 AND C.SMAssetGrp = J.MinorSeq ) 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND J.MinorValue = 1 
                      ) AS F ON ( F.ItemSeq = X.MatItemSeq ) 
     WHERE E.AssetSeq <> 19  
       AND ( @ItemName = '' OR X.MatItemName LIKE @ItemName + '%' ) 
       AND ( @AssetSeq = 0 OR CASE WHEN F.ItemSeq IS NULL THEN 2 ELSE 1 END = @AssetSeq ) 
     GROUP BY MatItemName, X.MatItemSeq, X.StdYM, F.ItemSeq 
    
    

    
    -- Title 
    CREATE TABLE #Title
    (
     ColIdx     INT IDENTITY(0, 1), 
     Title      NVARCHAR(100), 
     TitleSeq   INT
    )
    INSERT INTO #Title ( TitleSeq, Title )
    SELECT DISTINCT 
           LEFT(Solar,6) AS TitleSeq, 
           LEFT(Solar,4) + '-' + SUBSTRING(Solar,5,2) AS Title
      FROM _TCOMCalendar 
     WHERE LEFT(Solar,6) BETWEEN @StdYMFr AND @StdYMTo 
      
    SELECT * FROM #Title 
    -- Title, END 
    
    -- Fix 
    CREATE TABLE #FixCol
    (
     RowIdx     INT IDENTITY(0, 1), 
     ItemName   NVARCHAR(100), 
     ItemSeq    INT, 
     AssetSeq   INT, 
     AssetName  NVARCHAR(100), 
     SumNeedQty DECIMAL(19,5), 
     AVGNeedQty DECIMAL(19,5)
    )
    
    SELECT ItemName, ItemSeq, SUM(Cnt) AS Cnt 
      INTO #Cnt 
      FROM (
            SELECT ItemName, ItemSeq, 1 AS Cnt 
              FROM #BaseData 
           ) AS A 
     GROUP BY ItemName, ItemSeq 
    
    INSERT INTO #FixCol ( ItemName, ItemSeq, AssetName, AssetSeq, SumNeedQty, AVGNeedQty ) 
    SELECT A.ItemName, A.ItemSeq, A.AssetName, A.AssetSeq, SUM(NeedQty) AS SumNeedQty, SUM(NeedQty) / NULLIF(MAX(B.Cnt),0) AS AVGNeedQty
      FROM #BaseData        AS A
      LEFT OUTER JOIN #Cnt  AS B ON ( B.ItemSeq = A.ItemSeq ) 
     GROUP BY A.ItemName, A.ItemSeq,A.AssetName, A.AssetSeq
     ORDER BY A.ItemName
      
    SELECT * FROM #FixCol 
    -- Fix, END 
    
    -- Value 
    CREATE TABLE #Value
    (
     ItemSeq        INT, 
     StdYM          NCHAR(6), 
     NeedQty        DECIMAL(19, 5) 
    )
    INSERT INTO #Value ( ItemSeq, StdYM, NeedQty ) 
    SELECT ItemSeq, StdYM, NeedQty 
      FROM #BaseData 
      
    SELECT B.RowIdx, A.ColIdx, C.NeedQty AS Value
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.StdYM ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq ) 
     ORDER BY A.ColIdx, B.RowIdx
    -- Value, END 
    
    RETURN        
go
begin tran
exec KPX_SPDWorkReportMonthDailyListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>0</FactUnit>
    <StdYMFr>201501</StdYMFr>
    <StdYMTo>201503</StdYMTo>
    <ItemName></ItemName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034442,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028525
rollback 