
IF OBJECT_ID('yw_SPDSFCProdBadListQuery') IS NOT NULL
    DROP PROC yw_SPDSFCProdBadListQuery
GO 
    
-- v2013.08.02 

-- 불량실적조회_YW(조회) by이재천
CREATE PROC yw_SPDSFCProdBadListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle   INT,  
            -- 조회조건   
            @WorkCenterSeq  INT,
            @DeptSeq        INT,
            @QueryDateTo    NCHAR(10), 
            @WorkStationSeq INT,
            @QueryDateFr    NCHAR(10),
            @QueryKind      INT, 
            @Present        NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @WorkCenterSeq  = WorkCenterSeq, 
           @DeptSeq        = DeptSeq, 
           @QueryDateTo    = QueryDateTo, 
           @WorkStationSeq = WorkStationSeq, 
           @QueryDateFr    = QueryDateFr, 
           @QueryKind      = QueryKind 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (WorkCenterSeq   INT,
            DeptSeq         INT,
            QueryDateTo     NCHAR(10),
            WorkStationSeq  INT,
            QueryDateFr     NCHAR(10),
            QueryKind       INT )
    
    IF @QueryDateTo = ''
    BEGIN
        SELECT @QueryDateTo = '99991231'
    END
    
    SELECT @Present = CONVERT(NCHAR(8),GETDATE(),112) -- 현재날짜(워크스테이션 조회하기위한 조건)
    
    -- 실적건별 조회조건 --------------------------------------------------------------------------------------------
    
    IF @QueryKind = 1008318001
    BEGIN
    
    -- 헤더부
    CREATE TABLE #Title
    (
     ColIdx     INT IDENTITY(0, 1), 
     Title      NVARCHAR(10), 
     Title2     NVARCHAR(10),
     TitleSeq   INT, 
     TitleSeq2  INT
    ) 
    
    INSERT INTO #Title(Title, TitleSeq, Title2, TitleSeq2)
    SELECT D.MinorName , D.MinorSeq, F.Name, F.Seq 
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      JOIN _TDAUMinor         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMQcTitleSeq AND D.MajorSeq = 1008328 ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN E.BegDate AND E.EndDate ) 
      LEFT OUTER JOIN ( SELECT '수량' AS Name, 1 AS Seq
                        UNION ALL
                        SELECT '비중' AS Name, 2 AS Seq 
                      ) AS F ON (1=1)
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR E.WorkStationSeq = @WorkStationSeq)
     GROUP BY D.MinorSeq,  F.Seq, F.Name, D.MinorName
     ORDER BY D.MinorSeq
    
    SELECT Title, TitleSeq, Title2, TitleSeq2, ColIdx FROM #Title ORDER BY ColIdx
    
    -- 고정행
    CREATE TABLE #FixCol
    (
     RowIdx          INT IDENTITY(0,1),
     RealLotNO       NVARCHAR(200),
     WorkCenterName  NVARCHAR(200), 
     WorkCenterSeq   INT,
     WorkOrderNo     NVARCHAR(200),
     BadQty          DECIMAL(19,5),
     ProdQty         DECIMAL(19,5),
     WorkDate        NVARCHAR(10),
     WorkOrderSeq    INT, 
     BadPercent      DECIMAL(19,2), 
     WorkStationSeq  INT, 
     ItemName        NVARCHAR(200),
     ItemNo          NVARCHAR(100),
     ItemSeq         INT, 
     OKQty           DECIMAL(19,5), 
     WorkStationName NVARCHAR(200),
     WorkReportSeq   INT
    )
    INSERT INTO #FixCol(
                        RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
                        ProdQty   , WorkDate       , WorkOrderSeq  , BadPercent  , WorkStationSeq ,
                        ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName, WorkReportSeq 
                       )
    SELECT A.RealLotNo , B.WorkCenterName , A.WorkCenterSeq , C.WorkOrderNo , A.BadQty , 
           A.ProdQty   , A.WorkDate       , A.WorkOrderSeq  , ISNULL(A.BadQty * 100 / NULLIF(A.ProdQty,0), 0) , D.WorkStationSeq , 
           E.ItemName  , E.ItemNo         , A.GoodItemSeq AS ItemSeq , A.OKQty , F.MinorName, A.WorkReportSeq
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAItem           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor         AS F WITH(NOLOCK) ON ( F.CompanySEq = @CompanySeq AND F.MinorSeq = D.WorkStationSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq) 
     ORDER BY A.WorkDate, C.WorkOrderNo
    
    SELECT RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
           ProdQty   , WorkDate       , WorkOrderSeq  , CAST(ROUND(BadPercent,2) AS NVARCHAR(22))+'%' AS BadPercent, WorkStationSeq ,
           ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName , WorkReportSeq
      FROM #FixCol
     ORDER BY WorkDate, WorkOrderNo
    
    -- 가변행
    CREATE TABLE #Value
    (
     BadKindQty     DECIMAL(19,0),
     BadKindPercent DECIMAL(19,2),
     WorkOrderSeq   INT,  
     UMQcTitleSeq   INT,
     WorkReportSeq  INT
    )
    
    INSERT INTO #Value(BadKindQty, BadKindPercent, WorkOrderSeq, UMQcTitleSeq, WorkReportSeq)
    SELECT ISNULL(SUM(C.QCQty),0),ISNULL((SUM(C.QCQty) * 100) / NULLIF(SUM(A.ProdQty),0),0), A.WorkOrderSeq, C.UMQcTitleSeq, A.WorkReportSeq
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq)
       AND ISNULL(A.BadQty,0) <> 0 
     GROUP BY A.WorkReportSeq, A.WorkOrderSeq,C.UMQcTitleSeq
     ORDER BY WorkOrderSeq
    
    SELECT C.WorkReportSeq,B.RowIdx, A.ColIdx,CASE WHEN A.TitleSeq2 = 1 THEN CAST(ISNULL(C.BadKindQty,0) AS NVARCHAR(22)) ELSE CAST(ROUND(ISNULL(C.BadKindPercent,0),2) AS NVARCHAR(22))+'%' END AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.UMQcTitleSeq )
      JOIN #FixCol AS B ON ( B.WorkReportSeq = C.WorkReportSeq ) 
     ORDER BY B.RowIdx, A.ColIdx
    
    END
    
    -- LOT별 조회조건 --------------------------------------------------------------------------------------------
    
    IF @QueryKind = 1008318002
    BEGIN
    
    -- 헤더부
    CREATE TABLE #Title2
    (
     ColIdx     INT IDENTITY(0, 1), 
     Title      NVARCHAR(10), 
     Title2     NVARCHAR(10),
     TitleSeq   INT, 
     TitleSeq2  INT
    ) 
    
    INSERT INTO #Title2(Title, TitleSeq, Title2, TitleSeq2)
    SELECT D.MinorName , D.MinorSeq, F.Name, F.Seq 
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      JOIN _TDAUMinor         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMQcTitleSeq AND D.MajorSeq = 1008328 ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN E.BegDate AND E.EndDate ) 
      LEFT OUTER JOIN ( SELECT '수량' AS Name, 1 AS Seq
                        UNION ALL
                        SELECT '비중' AS Name, 2 AS Seq 
                      ) AS F ON (1=1)
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR E.WorkStationSeq = @WorkStationSeq)
     GROUP BY D.MinorSeq,  F.Seq, F.Name, D.MinorName
     ORDER BY D.MinorSeq
    
    SELECT Title, TitleSeq, Title2,TitleSeq2, ColIdx FROM #Title2
    
    -- 고정행
    CREATE TABLE #FixCol2
    (
     RowIdx          INT IDENTITY(0,1),
     RealLotNO       NVARCHAR(200),
     WorkCenterName  NVARCHAR(200), 
     WorkCenterSeq   INT,
     WorkOrderNo     NVARCHAR(200),
     BadQty          DECIMAL(19,5),
     ProdQty         DECIMAL(19,5),
     WorkDate        NVARCHAR(10),
     WorkOrderSeq    INT, 
     BadPercent      DECIMAL(19,2), 
     WorkStationSeq  INT, 
     ItemName        NVARCHAR(200),
     ItemNo          NVARCHAR(100),
     ItemSeq         INT, 
     OKQty           DECIMAL(19,5), 
     WorkStationName NVARCHAR(200)
    )
    INSERT INTO #FixCol2(
                         RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
                         ProdQty   , WorkDate       , WorkOrderSeq  , BadPercent  , WorkStationSeq ,
                         ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName 
                        )
    SELECT A.RealLotNo    , '' , '' , ''           , SUM(A.BadQty) , 
           SUM(A.ProdQty) , '' , '' , ISNULL(SUM(A.BadQty) * 100 / NULLIF(SUM(A.ProdQty),0), 0) , '' , 
           ''             , '' , '' , SUM(A.OKQty) , ''
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAItem           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor         AS F WITH(NOLOCK) ON ( F.CompanySEq = @CompanySeq AND F.MinorSeq = D.WorkStationSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq)
     GROUP BY A.RealLotNo
     ORDER BY A.RealLotNo
    
    SELECT RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
           ProdQty   , WorkDate       , WorkOrderSeq  , CAST(ROUND(BadPercent,2) AS NVARCHAR(22))+'%' AS BadPercent, WorkStationSeq ,
           ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName 
      FROM #FixCol2
    
    -- 가변행
    CREATE TABLE #Value2
    (
     BadKindQty     DECIMAL(19,0),
     BadKindPercent DECIMAL(19,2), 
     UMQcTitleSeq   INT,
     RealLotNo      NVARCHAR(100)
    )
    
    INSERT INTO #Value2(BadKindQty, BadKindPercent, UMQcTitleSeq, RealLotNo)
    SELECT SUM(C.QCQty), ISNULL((SUM(C.QCQty) * 100) / NULLIF(SUM(A.ProdQty),0),0),  C.UMQcTitleSeq, A.RealLotNo
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq)
     GROUP BY A.RealLotNo, C.UMQcTitleSeq 
    
    SELECT B.RowIdx, A.ColIdx,CASE WHEN A.TitleSeq2 = 1 THEN CAST(C.BadKindQty AS NVARCHAR(22)) ELSE CAST(ROUND(C.BadKindPercent,2) AS NVARCHAR(22))+'%' END AS Result
      FROM #Value2 AS C
      JOIN #Title2 AS A ON ( A.TitleSeq = C.UMQcTitleSeq )
      JOIN #FixCol2 AS B ON ( B.RealLotNo = C.RealLotNo ) 
     ORDER BY B.RowIdx, A.ColIdx
    
    END
    
    -- 품목별 조회조건 --------------------------------------------------------------------------------------------
    
    IF @QueryKind = 1008318003
    BEGIN
    
    -- 헤더부
    CREATE TABLE #Title3
    (
     ColIdx     INT IDENTITY(0, 1), 
     Title      NVARCHAR(10), 
     Title2     NVARCHAR(10),
     TitleSeq   INT, 
     TitleSeq2  INT
    ) 
    
    INSERT INTO #Title3(Title, TitleSeq, Title2, TitleSeq2)
    SELECT D.MinorName , D.MinorSeq, F.Name, F.Seq 
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      JOIN _TDAUMinor         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.UMQcTitleSeq AND D.MajorSeq = 1008328 ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN E.BegDate AND E.EndDate ) 
      LEFT OUTER JOIN ( SELECT '수량' AS Name, 1 AS Seq
                        UNION ALL
                        SELECT '비중' AS Name, 2 AS Seq 
                      ) AS F ON (1=1)
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR E.WorkStationSeq = @WorkStationSeq)
     GROUP BY D.MinorSeq,  F.Seq, F.Name, D.MinorName
     ORDER BY D.MinorSeq
    
    SELECT Title, TitleSeq, Title2,TitleSeq2, ColIdx FROM #Title3
    
    -- 고정행
    CREATE TABLE #FixCol3
    (
     RowIdx          INT IDENTITY(0,1),
     RealLotNO       NVARCHAR(200),
     WorkCenterName  NVARCHAR(200), 
     WorkCenterSeq   INT,
     WorkOrderNo     NVARCHAR(200),
     BadQty          DECIMAL(19,5),
     ProdQty         DECIMAL(19,5),
     WorkDate        NVARCHAR(10),
     WorkOrderSeq    INT, 
     BadPercent      DECIMAL(19,2), 
     WorkStationSeq  INT, 
     ItemName        NVARCHAR(200),
     ItemNo          NVARCHAR(100),
     ItemSeq         INT, 
     OKQty           DECIMAL(19,5), 
     WorkStationName NVARCHAR(200)
    )
    INSERT INTO #FixCol3(
                         RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
                         ProdQty   , WorkDate       , WorkOrderSeq  , BadPercent  , WorkStationSeq ,
                         ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName 
                        ) 
                       
    SELECT ''             , ''       , ''                       , ''           , SUM(A.BadQty) , 
           SUM(A.ProdQty) , ''       , ''                       , ISNULL(SUM(A.BadQty) * 100 / NULLIF(SUM(A.ProdQty),0), 0) , '' , 
           E.ItemName     , E.ItemNo , A.GoodItemSeq AS ItemSeq , SUM(A.OKQty) , ''
    
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAItem           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor         AS F WITH(NOLOCK) ON ( F.CompanySEq = @CompanySeq AND F.MinorSeq = D.WorkStationSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq)
     GROUP BY A.GoodItemSeq, E.ItemName, E.ItemNo
     ORDER BY A.GoodItemSeq
     
    SELECT RealLotNO , WorkCenterName , WorkCenterSeq , WorkOrderNo , BadQty         , 
           ProdQty   , WorkDate       , WorkOrderSeq  , CAST(ROUND(BadPercent,2) AS NVARCHAR(22))+'%' AS BadPercent, WorkStationSeq ,
           ItemName  , ItemNo         , ItemSeq       , OKQty       , WorkStationName 
      FROM #FixCol3
    
    -- 가변행
    CREATE TABLE #Value3
    (
     BadKindQty     DECIMAL(19,0),
     BadKindPercent DECIMAL(19,2),
     UMQcTitleSeq   INT,
     ItemSeq        INT
    )

    INSERT INTO #Value3(BadKindQty, BadKindPercent, UMQcTitleSeq, ItemSeq)
    SELECT SUM(C.QCQty), ISNULL((SUM(C.QCQty) * 100) / NULLIF(SUM(A.ProdQty),0),0), C.UMQcTitleSeq, A.GoodItemSeq
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.SourceSeq = A.WorkReportSeq AND SourceType = 3 ) 
      LEFT OUTER JOIN YW_TPDQCTestReportSub  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.QCSeq = B.QCSeq ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR D.WorkStationSeq = @WorkStationSeq)
     GROUP BY A.GoodItemSeq, C.UMQcTitleSeq
     ORDER BY A.GoodItemSeq
    
    SELECT B.RowIdx, A.ColIdx,CASE WHEN A.TitleSeq2 = 1 THEN CAST(C.BadKindQty AS NVARCHAR(22)) ELSE CAST(ROUND(C.BadKindPercent,2) AS NVARCHAR(22))+'%' END AS Result
      FROM #Value3 AS C
      JOIN #Title3 AS A ON ( A.TitleSeq = C.UMQcTitleSeq )
      JOIN #FixCol3 AS B ON ( B.ItemSeq = C.ItemSeq ) 
     ORDER BY B.RowIdx, A.ColIdx
    
    END
    
    RETURN
GO
exec yw_SPDSFCProdBadListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QueryDateFr>20130726</QueryDateFr>
    <QueryDateTo>20130726</QueryDateTo>
    <DeptSeq />
    <QueryKind>1008318003</QueryKind>
    <WorkCenterSeq>100040</WorkCenterSeq>
    <WorkStationSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016813,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014344