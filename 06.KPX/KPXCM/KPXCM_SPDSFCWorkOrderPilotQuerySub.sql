  
IF OBJECT_ID('KPXCM_SPDSFCWorkOrderPilotQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkOrderPilotQuerySub  
GO  
  
-- v2016.03.02  
  
-- 긴급작업지시입력-Item조회 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkOrderPilotQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PilotSeq   INT 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PilotSeq   = ISNULL( PilotSeq, 0 )
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PilotSeq   INT)    
      
    -- 최종조회   
    SELECT A.PilotSeq, 
           A.ProdPlanSeq, 
           A.WorkOrderSeq, 
           A.WorkCenterSeq, 
           D.WorkCenterName, 
           A.ItemSeq, 
           E.ItemEngSName AS ItemName, 
           A.LotNo, 
           A.SrtDate, 
           A.EndDate, 
           A.SrtHour, 
           A.EndHour, 
           A.Duration, 
           A.DurHour, 
           A.PatternSeq AS WorkCond6, 
           A.Remark, 
           A.SubItemSeq, 
           F.ItemEngSName AS SubItemName, 
           A.AfterWorkSeq, 
           G.MinorName AS AfterWorkName, 
           A.IsCfm, 
           B.WorkOrderNo, 
           C.ProdPlanNo, 
           A.ProdQty, 
           A.PatternSeq 
      FROM KPXCM_TPDSFCWorkOrderPilot       AS A 
      LEFT OUTER JOIN _TPDSFCWorkOrder      AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan  AS C ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = A.ProdPlanSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter    AS D ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq ) 
      LEFT OUTER JOIN _TDAItem              AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem              AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.SubItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.AfterWorkSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PilotSeq = @PilotSeq 
      
    RETURN  
    go
exec KPXCM_SPDSFCWorkOrderPilotQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <PilotSeq>1</PilotSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035544,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029271