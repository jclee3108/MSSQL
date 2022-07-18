
IF OBJECT_ID('yw_SPDSFCProdBadListQuery') IS NOT NULL
    DROP PROC yw_SPDSFCProdBadListQuery
GO 
    
-- v2013.08.14 

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
    
    CREATE TABLE #FixColTemp 
    (
     WorkReportSeq  INT,
     ItemSeq        INT,
     RealLotNo      NVARCHAR(100), 
     OKQty          DECIMAL(19,5), 
     BadQty         DECIMAL(19,5), 
     ProdQty        DECIMAL(19,5), 
     BadPercent     DECIMAL(19,2)
    )
    
    INSERT INTO #FixColTemp (WorkReportSeq, ItemSeq, RealLotNo, OKQty, BadQty, ProdQty, BadPercent)
    SELECT A.WorkReportSeq, A.GoodItemSeq, A.RealLotNo, A.OKQty, A.BadQty, A.ProdQty, ISNULL((ISNULL(A.BadQty,0) * 100) / NULLIF(A.ProdQty,0),0)
      FROM _TPDSFCWorkReport AS A 
      LEFT OUTER JOIN yw_TPDWorkStation AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN B.BegDate AND B.EndDate ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WorkDate BETWEEN @QueryDateFr AND @QueryDateTo
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)
       AND (@WorkCenterSeq = 0 OR A.WorkCenterSeq = @WorkCenterSeq)
       AND (@WorkStationSeq = 0 OR B.WorkStationSeq = @WorkStationSeq) 
    
    CREATE TABLE #FixCol
    (
        RowIdx          INT IDENTITY(0,1),
        WorkReportSeq   INT, 
        ItemSeq         INT, 
        RealLotNO       NVARCHAR(200),
        OKQty           DECIMAL(19,5), 
        BadQty          DECIMAL(19,5),
        ProdQty         DECIMAL(19,5), 
        BadPercent      NVARCHAR(100),  
        WorkCenterName  NVARCHAR(200), 
        WorkCenterSeq   INT,
        WorkOrderNo     NVARCHAR(200),
        WorkDate        NVARCHAR(10),
        WorkOrderSeq    INT, 
        WorkStationSeq  INT, 
        ItemName        NVARCHAR(200),
        ItemNo          NVARCHAR(100),
        WorkStationName NVARCHAR(200) 
        
    )
    
    INSERT INTO #FixCol (
                         WorkReportSeq  , ItemSeq        , RealLotNO      , OKQty          , BadQty         ,
                         ProdQty        , BadPercent     , WorkCenterName , WorkCenterSeq  , WorkOrderNo    ,
                         WorkDate       , WorkOrderSeq   , WorkStationSeq , ItemName       , ItemNo         ,
                         WorkStationName
                        )
    
    SELECT CASE WHEN @QueryKind = 1008318001 THEN Z.WorkReportSeq ELSE 0 END AS WorkReportSeq, 
           CASE WHEN @QueryKind = 1008318002 THEN 0 ELSE Z.ItemSeq END AS ItemSeq, 
           CASE WHEN @QueryKind = 1008318003 THEN '' ELSE Z.RealLotNo END AS RealLotNo, 
           SUM(Z.OKQty) AS OKQty, 
           SUM(Z.BadQty) AS BadQty, 
           SUM(Z.ProdQty) AS ProdQty, 
           ISNULL(CAST(CAST(ROUND(SUM(Z.BadQty) * 100 / NULLIF(SUM(Z.ProdQty),0),2) AS DECIMAL(19,2)) AS NVARCHAR(22)),0.00)+'%' AS BadPercent, 
           CASE WHEN @QueryKind = 1008318001 THEN B.WorkCenterName ELSE '' END AS WorkCenterName, 
           CASE WHEN @QueryKind = 1008318001 THEN B.WorkCenterSeq ELSE 0 END AS WorkCenterSeq, 
           CASE WHEN @QueryKind = 1008318001 THEN C.WorkOrderNo ELSE '' END AS WorkOrderNo, 
           CASE WHEN @QueryKind = 1008318001 THEN A.WorkDate ELSE '' END AS WorkDate, 
           CASE WHEN @QueryKind = 1008318001 THEN C.WorkOrderSeq ELSE 0 END AS WorkOrderSeq, 
           CASE WHEN @QueryKind = 1008318001 THEN D.WorkStationSeq ELSE 0 END AS WorkStationSeq, 
           CASE WHEN @QueryKind = 1008318002 THEN '' ELSE E.ItemName END AS ItemName, 
           CASE WHEN @QueryKind = 1008318002 THEN '' ELSE E.ItemNo END AS ItemNo, 
           CASE WHEN @QueryKind = 1008318001 THEN F.MinorName ELSE '' END AS WorkStationName
      
      FROM #FixColTemp AS Z
      LEFT OUTER JOIN _TPDSFCWorkReport  AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.WorkReportSeq = Z.WorkReportSeq )
      LEFT OUTER JOIN _TPDBaseWorkCenter AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAItem           AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor         AS F WITH(NOLOCK) ON ( F.CompanySEq = @CompanySeq AND F.MinorSeq = D.WorkStationSeq )    
    
     GROUP BY CASE WHEN @QueryKind = 1008318001 THEN Z.WorkReportSeq ELSE 0 END, 
              CASE WHEN @QueryKind = 1008318002 THEN 0 ELSE Z.ItemSeq END, 
              CASE WHEN @QueryKind = 1008318003 THEN '' ELSE Z.RealLotNo END, 
              CASE WHEN @QueryKind = 1008318001 THEN B.WorkCenterName ELSE '' END, 
              CASE WHEN @QueryKind = 1008318001 THEN B.WorkCenterSeq ELSE 0 END, 
              CASE WHEN @QueryKind = 1008318001 THEN C.WorkOrderNo ELSE '' END, 
              CASE WHEN @QueryKind = 1008318001 THEN A.WorkDate ELSE '' END, 
              CASE WHEN @QueryKind = 1008318001 THEN C.WorkOrderSeq ELSE 0 END, 
              CASE WHEN @QueryKind = 1008318001 THEN D.WorkStationSeq ELSE 0 END, 
              CASE WHEN @QueryKind = 1008318002 THEN '' ELSE E.ItemName END, 
              CASE WHEN @QueryKind = 1008318002 THEN '' ELSE E.ItemNo END, 
              CASE WHEN @QueryKind = 1008318001 THEN F.MinorName ELSE '' END
    
    SELECT * FROM #FixCol
    
    -- 가변행

    CREATE TABLE #Value
    (
         BadKindQty     DECIMAL(19,0),
         BadKindPercent DECIMAL(19,2),
         UMQcTitleSeq   INT,
         WorkReportSeq  INT, 
         RealLotNo      NVARCHAR(100), 
         ItemSeq        INT
    )

    INSERT INTO #Value (BadKindQty, BadKindPercent, UMQcTitleSeq, WorkReportSeq, RealLotNo, ItemSeq)
    SELECT ISNULL(SUM(C.QCQty),0) AS BadKindQty, 
           ISNULL((SUM(C.QCQty) * 100) / NULLIF(SUM(A.ProdQty),0),0) AS BadKindPercent, 
           C.UMQcTitleSeq, 
           CASE WHEN @QueryKind = 1008318001 THEN A.WorkReportSeq ELSE 0 END AS WorkReportSeq, 
           CASE WHEN @QueryKind = 1008318003 THEN '' ELSE A.RealLotNo END AS RealLotNo, 
           CASE WHEN @QueryKind = 1008318002 THEN '' ELSE A.GoodItemSeq END AS ItemSeq 
           
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
     GROUP BY CASE WHEN @QueryKind = 1008318001 THEN A.WorkReportSeq ELSE 0 END, 
              CASE WHEN @QueryKind = 1008318003 THEN '' ELSE A.RealLotNo END, 
              CASE WHEN @QueryKind = 1008318002 THEN '' ELSE A.GoodItemSeq END, 
              C.UMQcTitleSeq 
    
    SELECT C.WorkReportSeq, 
           C.RealLotNo, 
           C.ItemSeq, 
           B.RowIdx, 
           A.ColIdx,
           CASE WHEN A.TitleSeq2 = 1 THEN CAST(ISNULL(C.BadKindQty,0) AS NVARCHAR(22)) ELSE CAST(ROUND(ISNULL(C.BadKindPercent,0),2) AS NVARCHAR(22))+'%' END AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.UMQcTitleSeq )
      JOIN #FixCol AS B ON ( B.WorkReportSeq = C.WorkReportSeq AND B.RealLotNo = C.RealLotNo AND B.ItemSeq = C.ItemSeq ) 
     ORDER BY B.RowIdx, A.ColIdx
    
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
    <QueryDateFr>20130701</QueryDateFr>
    <QueryDateTo>20130814</QueryDateTo>
    <DeptSeq />
    <QueryKind>1008318002</QueryKind>
    <WorkCenterSeq />
    <WorkStationSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016813,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014344