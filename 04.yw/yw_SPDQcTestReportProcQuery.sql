
IF OBJECT_ID('yw_SPDQcTestReportProcQuery') IS NOT NULL
    DROP PROC yw_SPDQcTestReportProcQuery
GO 
 
-- v2013.07.18
  
-- 공정검사입력_YW(조회) by이재천  
CREATE PROC yw_SPDQcTestReportProcQuery    
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
            @QcSeq      INT    
        
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
    
    SELECT @QCSeq = ISNULL( QCSeq, 0 ) 
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
      WITH ( QCSeq   INT ) 
    
    CREATE TABLE #Temp 
    (
        IDX_NO        INT IDENTITY, 
        WorkOrderSeq  INT, 
        WorkOrderSerl INT
    )
    
    INSERT INTO #Temp(WorkOrderSeq, WorkOrderSerl) 
         SELECT A.WorkOrderSeq, A.WorkOrderSerl 
           FROM _TPDSFCWorkOrder AS A WITH(NOLOCK) 
    
    CREATE TABLE #TMP_SourceTable 
            (IDOrder   INT, 
             TableName NVARCHAR(100)) 
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
         SELECT 1, '_TSLOrderItem' 
    
    CREATE TABLE #TCOMSourceTracking 
            (IDX_NO  INT, 
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
    
    EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPDSFCWorkOrder', 
             @TempTableName = '#Temp', 
             @TempSeqColumnName = 'WorkOrderSeq', 
             @TempSerlColumnName = 'WorkOrderSerl', 
             @TempSubSerlColumnName = '' 
     
     SELECT A.IDX_NO, A.WorkOrderSeq, A.WorkOrderSerl, B.Seq, B.Serl 
       INTO #Temp2 
       FROM #Temp AS A 
       LEFT OUTER JOIN #TCOMSourceTracking AS B ON ( A.IDX_NO = B.IDX_NO ) 
    
    -- 최종조회(Control)    
    SELECT X.QCDate, 
           H.Dummy1 AS OrderItemNo, 
           B.ItemNo AS AssyItemNo, 
           B.ItemName AS AssyItemName, 
           E.MinorName AS WorkStationName, 
           C.WorkCenterName, 
           F.ProcName, 
           A.OrderQty, 
           X.ProdQty, 
           A.AssyItemSeq, 
           D.WorkStationSeq, 
           A.WorkCenterSeq, 
           A.ProcSeq, 
           X.SourceSeq AS WorkOrderSeq, 
           X.SourceSerl AS WorkOrderSerl, 
           X.QCSeq 
    
      FROM YW_TPDQCTestReport            AS X WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.WorkOrderSeq = X.SourceSeq AND A.WorkOrderSerl = X.SourceSerl ) 
      LEFT OUTER JOIN _TDAItem           AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.AssyItemSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND A.WorkOrderDate BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAUMinor         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.WorkStationSeq ) 
      LEFT OUTER JOIN _TPDBaseProcess    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ProcSeq = A.ProcSeq ) 
      LEFT OUTER JOIN #Temp2             AS G              ON ( G.WorkOrderSeq = A.WorkOrderSeq AND G.WorkOrderSerl = A.WorkOrderSerl )  
      LEFT OUTER JOIN _TSLOrderItem      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.OrderSeq = G.Seq AND H.OrderSerl = G.Serl ) 
     
     WHERE X.CompanySeq = @CompanySeq 
       AND X.QCSeq = @QCSeq 
    
    -- 최종조회(Sheet)     
    SELECT ISNULL(A.MinorName,'') AS UMQCTitleName, 
           X.UMQCTitleSeq, 
           D.TestingCond, 
           D.LowerLimit, 
           D.UpperLimit, 
           ISNULL(G.TagetLevel,'') AS TargetLevel, 
           ISNULL(F.MinorName,'') AS SMInputTypeName, 
           ISNULL(H.MinorName,'') AS SMTestResultName, 
           E.InPutType AS SMInputTypeSeq, 
           X.SMTestResult, 
           X.TestValue, 
           X.QCQty, 
           X.QCSeq, 
           X.Serl, 
           X.UMQCTitleSeq AS UMQCTitleSeqOld 
             
      FROM YW_TPDQCTestReportSub         AS X WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAUMinor         AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.MinorSeq = X.UMQCTitleSeq ) 
      LEFT OUTER JOIN YW_TPDQCTestReport AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.QCSeq = X.QCSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = B.SourceSeq AND C.WorkOrderSerl = B.SourceSerl ) 
      LEFT OUTER JOIN _TPDQAProcQcTitle  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ProcSeq = C.ProcSeq AND D.UMQcTitleSeq = X.UMQcTitleSeq ) 
      LEFT OUTER JOIN _TPDQAQcTitleSub   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UMQCTitleSeq = X.UMQcTitleSeq ) 
      LEFT OUTER JOIN _TDASMinor         AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.InputType ) 
      LEFT OUTER JOIN _TPDQAItemQcTitle  AS G WITH(NOLOCK) ON ( G.Companyseq = @CompanySeq AND G.UMQCTitleSeq = X.UMQCTitleSeq AND G.ItemSeq = C.AssyItemSeq ) 
      LEFT OUTER JOIN _TDASMinor         AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = X.SMTestResult ) 
    
     WHERE X.CompanySeq = @CompanySeq 
       AND X.QCSeq = @QCSeq 
       AND X.Serl = 1 
     ORDER BY UMQCTitleName 
    
    RETURN    
