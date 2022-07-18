  
IF OBJECT_ID('lumim_SPDSFCProcStockListSubQuery') IS NOT NULL   
    DROP PROC lumim_SPDSFCProcStockListSubQuery  
GO  
  
-- v2013.09.11 
  
-- 재공조회_lumim-조회 by 이재천   
CREATE PROC lumim_SPDSFCProcStockListSubQuery  
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
            @ProcSeq    INT,  
            @ProdPlanNo NVARCHAR(100)  
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ProcSeq    = ISNULL(ProcSeq, 0), 
           @ProdPlanNo = ISNULL(ProdPlanNo, '')
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags ) 
      
      WITH (
            ProcSeq     INT, 
            ProdPlanNo  NVARCHAR(100)
           )    
    
    -- 최종조회(전체진행정보)
    
	SELECT ISNULL(SUM(D.OKQty),0) EndQty, 
	       ISNULL(MAX(C.ProdQty),0) AS PlanQty, 
	       C.ProdPlanNo,
	       CAST((ISNULL(SUM(D.OKQty),0) / ISNULL(MAX(C.ProdQty),0)) * 100 AS DECIMAL(19,2)) AS ProgressPercent 
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkReport    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkReportSeq = A.WorkReportSeq AND D.IsLastProc = '1') 
      JOIN _TDAItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq 
                                       AND E.AssetSeq = (SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1 
                                                        ) 
                                         )
     WHERE A.CompanySeq = @CompanySeq
       AND C.ProdPlanNo = @ProdPlanNo 
     
     GROUP BY C.ProdPlanNo
    
    -- 최종조회(LotNo별 완료수량)
    
    SELECT MAX(C.ProdPlanNo) AS ProdPlanNo, 
           ISNULL(SUM(D.OKQty),0) AS EndQty, 
           D.RealLotNo AS LotNo      
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq ) 
      JOIN _TPDSFCWorkReport AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkReportSeq = A.WorkReportSeq AND D.IsLastProc = '1' ) 
      JOIN _TDAItem          AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.GoodItemSeq 
                                                AND E.AssetSeq = (SELECT EnvValue 
                                                                    FROM lumim_TCOMEnv 
                                                                   WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1 
                                                                 ) 
                                                  )
     WHERE A.CompanySeq = @CompanySeq 
       AND C.ProdPlanNo = @ProdPlanNo 
    
     GROUP BY D.RealLotNo 
    
    RETURN  

GO
exec lumim_SPDSFCProcStockListSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ProdPlanNo />
    <ProcSeq></ProcSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017251,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014758