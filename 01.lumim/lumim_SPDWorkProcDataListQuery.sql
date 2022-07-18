  
IF OBJECT_ID('lumim_SPDWorkProcDataListQuery') IS NOT NULL   
    DROP PROC lumim_SPDWorkProcDataListQuery  
GO  
  
-- v2013.08.21 
  
-- 자재관리정보조회_lumim(조회) by이재천   
CREATE PROC lumim_SPDWorkProcDataListQuery  
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
            @WorkOrderDateFr NVARCHAR(8), 
            @WorkOrderDateTo NVARCHAR(8), 
            @ProdPlanNo      NVARCHAR(200), 
            @LotNo           NVARCHAR(30), 
            @ItemName        NVARCHAR(200), 
            @ItemNo          NVARCHAR(100), 
            @Spec            NVARCHAR(100)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @WorkOrderDateFr = ISNULL(WorkOrderDateFr, '' ), 
           @WorkOrderDateTo = ISNULL(WorkOrderDateTo, '' ), 
           @ProdPlanNo      = ISNULL(ProdPlanNo     , '' ), 
           @LotNo           = ISNULL(LotNo          , '' ), 
           @ItemName        = ISNULL(ItemName       , '' ), 
           @ItemNo          = ISNULL(ItemNo         , '' ), 
           @Spec            = ISNULL(Spec           , '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            WorkOrderDateFr NVARCHAR(8), 
            WorkOrderDateTo NVARCHAR(8), 
            ProdPlanNo      NVARCHAR(200),
            LotNo           NVARCHAR(30), 
            ItemName        NVARCHAR(200),
            ItemNo          NVARCHAR(100),
            Spec            NVARCHAR(100)
           )    
      
    IF @WorkOrderDateTo = '' SELECT @WorkOrderDateTo = '99991231'
    
    
    CREATE TABLE #TEMP 
    (
     EnvSeq         INT, 
     ProcSeq        INT,
     ProdPlanSeq    INT,
     RealLotNo      NVARCHAR(100), 
     ProdQty        DECIMAL(19,5), 
     WorkReportSeq  INT,
     GoodItemSeq    INT, 
     ProdPlanNo     NVARCHAR(100), 
     WorkOrderDate  NVARCHAR(8), 
     ItemSeq        INT,
     ItemName       NVARCHAR(100), 
     ItemNo         NVARCHAR(100), 
     Spec           NVARCHAR(100)
    )
    
    INSERT INTO #TEMP (
                       EnvSeq, ProcSeq, ProdPlanSeq, RealLotNo, ProdQty, 
                       WorkReportSeq, GoodItemSeq, ProdPlanNo, WorkOrderDate, ItemSeq, 
                       ItemName, ItemNo, Spec
                      )
    SELECT D.EnvSeq, A.ProcSeq, C.ProdPlanSeq, A.RealLotNo, A.ProdQty, 
           A.WorkReportSeq, A.GoodItemSeq, C.ProdPlanNo, B.WorkOrderDate, A.GoodItemSeq, 
           E.ItemName, E.ItemNo, E.Spec  
      FROM _TPDSFCWorkReport AS A
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq ) 
      LEFT OUTER JOIN lumim_TCOMEnv AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EnvValue = A.ProcSeq AND D.EnvSeq IN (4,5,7) AND EnvSerl = 1 ) 
      LEFT OUTER JOIN _TDAItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq 
       AND B.WorkOrderDate BETWEEN @WorkOrderDateFr AND @WorkOrderDateTo 
       AND (@ProdPlanNo = '' OR C.ProdPlanNo LIKE @ProdPlanNo + '%')
       AND (@LotNo = '' OR A.RealLotNo LIKE @LotNo + '%') 
       AND (@ItemName = '' OR E.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR E.ItemNo LIKE @ItemNo + '%') 
       AND (@Spec = '' OR E.Spec LIKE @Spec + '%') 
    
    SELECT Z.ItemSeq, 
           Z.ItemName, 
           Z.ItemNo, 
           Z.Spec, 
           X.ChipWave, 
           X.ChipPower, 
           X.LFinfo, 
           Z.ProdPlanNo, 
           Z.ProdQty AS Qty, 
           Z.RealLotNo AS LotNo, 
           X.OvenNo AS ChipOvenNo, -- Chip Oven호기
           W.OvenNo AS ZenerOvenNo,  -- Oven투입시간(CH)
           Q.OvenNo AS DPOvenNo, -- Zener Oven호기 
           X.OvenNoRegTime AS OvenCHTime, -- Oven투입시간(ZD) 
           W.OvenNoRegTime AS OvenZDTime, -- DP Oven호기 
           Q.OvenNoRegTime AS OvenDPTime, -- Oven투입시간(DP)
           REPLACE(REPLACE(REPLACE((SELECT SPName 
                                      FROM lumim_TPDSFCWorkReportSp AS R 
                                     WHERE R.WorkReportSeq = Z.WorkReportSeq FOR XML AUTO, ELEMENTS
                                   ), '</SPName></R><R><SPName>', ','
                                  ), '<R><SPName>', ''
                          ), '</SPName></R>', ''
                  ) AS SPName -- SP명(ChipSheet) 
    
      FROM #TEMP AS Z
      LEFT OUTER JOIN lumim_TPDSFCWorkReportProc AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.WorkReportSeq = Z.WorkReportSeq ) 
      LEFT OUTER JOIN #TEMP AS Y ON ( Y.ProdPlanSeq = Z.ProdPlanSeq AND Y.RealLotNo = Z.RealLotNo AND Y.EnvSeq = 5) 
      LEFT OUTER JOIN lumim_TPDSFCWorkReportProc AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.WorkReportSeq = Y.WorkReportSeq ) 
      LEFT OUTER JOIN #TEMP AS V ON ( V.ProdPlanSeq = Z.ProdPlanSeq AND V.RealLotNo = Z.RealLotNo AND V.EnvSeq = 7 ) 
      LEFT OUTER JOIN lumim_TPDSFCWorkReportProc AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.WorkReportSeq = V.WorkReportSeq ) 
    
     WHERE Z.EnvSeq = 4 
     
     ORDER BY Z.RealLotNo
    
    RETURN  
GO
exec lumim_SPDWorkProcDataListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkOrderDateFr>20130801</WorkOrderDateFr>
    <WorkOrderDateTo>20130821</WorkOrderDateTo>
    <ProdPlanNo />
    <LotNo />
    <ItemName>test_반제품6(이재천)</ItemName>
    <ItemNo />
    <Spec />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017214,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014730