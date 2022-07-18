
IF OBJECT_ID('yw_SPDQcTestReportProcJumpQuery') IS NOT NULL 
    DROP PROC yw_SPDQcTestReportProcJumpQuery 
GO 

-- v2013.07.18 
  
-- 공정검사입력_yw(점프조회) by이재천 
CREATE PROC yw_SPDQcTestReportProcJumpQuery 
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
            @WorkOrderSeq  INT, 
            @WorkOrderSerl INT, 
            @Present       NCHAR(8) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument 
            
    SELECT @WorkOrderSeq  = ISNULL( WorkOrderSeq , 0 ), 
           @WorkOrderSerl = ISNULL( WorkOrderSerl, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
    
      WITH ( 
            WorkOrderSeq   INT, 
            WorkOrderSerl  INT 
           ) 
    
    SELECT @Present = CONVERT(NCHAR(8),GETDATE(),112)
    
    CREATE TABLE #Temp 
    (
     IDX_NO        INT IDENTITY, 
     WorkOrderSeq  INT, 
     WorkOrderSerl INT 
    ) 
    
    INSERT INTO #Temp(WorkOrderSeq, WorkOrderSerl) 
         SELECT A.WorkOrderSeq, A.WorkOrderSerl 
           FROM _TPDSFCWorkOrder AS A WITH(NOLOCK) 
          WHERE WorkOrderSeq = @WorkOrderSeq 
            AND WorkOrderSerl = @WorkOrderSerl 
    
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
    SELECT H.Dummy1 AS OrderItemNo, 
           B.ItemNo AS AssyItemNo, 
           B.ItemName AS AssyItemName, 
           E.MinorName AS WorkStationName, 
           C.WorkCenterName, 
           F.ProcName, 
           A.OrderQty, 
           A.AssyItemSeq, 
           D.WorkStationSeq, 
           A.WorkCenterSeq, 
           A.ProcSeq,  
           A.WorkOrderSeq, 
           A.WorkOrderSerl 
    
      FROM _TPDSFCWorkOrder              AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAItem           AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.AssyItemSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN yw_TPDWorkStation  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq AND @Present BETWEEN D.BegDate AND D.EndDate ) 
      LEFT OUTER JOIN _TDAUMinor         AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.WorkStationSeq ) 
      LEFT OUTER JOIN _TPDBaseProcess    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ProcSeq = A.ProcSeq )  
      LEFT OUTER JOIN #Temp2             AS G              ON ( G.WorkOrderSeq = A.WorkOrderSeq AND G.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TSLOrderItem      AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.OrderSeq = G.Seq AND H.OrderSerl = G.Serl ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WorkOrderSeq = @WorkOrderSeq 
       AND A.WorkOrderSerl = @WorkOrderSerl 
    
    -- 최종조회(Sheet) 
    SELECT A.ProcSeq, 
           ISNULL(F.MinorName,'') AS UMQCTitleName, 
           A.UMQCTitleSeq, 
           A.TestingCond, 
           A.LowerLimit, 
           A.UpperLimit, 
           ISNULL(G.TagetLevel,'') AS TargetLevel, 
           ISNULL(D.MinorName,'') AS SMInputTypeName, 
           B.InPutType AS SMInputTypeSeq 
    
      FROM _TPDSFCWorkOrder AS Z 
      LEFT OUTER JOIN _TPDQAProcQcTitle AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ProcSeq = Z.ProcSeq ) 
      LEFT OUTER JOIN _TPDQAQcTitleSub  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.UMQCTitleSeq = A.UMQcTitleSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.ProcSeq ) 
      LEFT OUTER JOIN _TDASMinor        AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.InPutType ) 
      LEFT OUTER JOIN _TDAUMinor        AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMQCUnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMQCTitleSeq ) 
      LEFT OUTER JOIN _TPDQAItemQcTitle AS G WITH(NOLOCK) ON ( G.Companyseq = @CompanySeq AND G.UMQCTitleSeq = B.UMQCTitleSeq AND G.ItemSeq = Z.AssyItemSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND Z.WorkOrderSeq = @WorkOrderSeq 
       AND Z.WorkOrderSerl = @WorkOrderSerl 
       AND B.IsProcQc = '1' 
       AND B.IsBadAdd = '1' 
     ORDER BY UMQCTitleName 
    
    RETURN  
GO