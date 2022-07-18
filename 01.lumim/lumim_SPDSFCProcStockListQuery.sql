  
IF OBJECT_ID('lumim_SPDSFCProcStockListQuery') IS NOT NULL   
    DROP PROC lumim_SPDSFCProcStockListQuery  
GO  
  
-- v2013.08.21  
  
-- 재공조회_lumim-조회 by 이재천   
CREATE PROC lumim_SPDSFCProcStockListQuery  
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
      
    -- 최종조회(공정별 대기수량)
    
	SELECT C.ProdPlanNo AS ProdPlanNo, 
           A.RealLotNo AS LotNo, 
           D.ProcNo,
           E.ProcNo AS ToProcNo,
           A.OKQty AS NextProcQty, 
           E.ProcSeq, 
           P.ProcName AS NextProcName 
      FROM _TPDSFCWorkReport AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TPDROUItemProcRev   AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND Z.ItemSeq = A.GoodItemSeq AND Z.ProcRev = A.ProcRev ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDMPSDailyProdPlan AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ProdPlanSeq = B.ProdPlanSeq ) 
      JOIN _TPDProcTypeItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ProcTypeSeq = Z.ProcTypeSeq AND D.ProcSeq = A.ProcSeq ) 
      LEFT OUTER JOIN _TPDProcTypeItem     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ProcNo = D.ToProcNo AND E.ProcTypeSeq = D.ProcTypeSeq ) 
      LEFT OUTER JOIN (SELECT MAX(X.ProcNo) AS ProcNo, Q.RealLotNo
                          FROM _TPDSFCWorkReport AS Q 
                          LEFT OUTER JOIN _TPDROUItemProcRev AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.ProcRev = Q.ProcRev AND Y.ItemSeq = Q.GoodItemSeq ) 
                          LEFT OUTER JOIN _TPDProcTypeItem   AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.ProcTypeSeq = Y.ProcTypeSeq AND X.ProcSeq = Q.ProcSeq )  
                         WHERE Q.CompanySeq = @CompanySeq 
                         GROUP BY Q.RealLotNo
                      ) AS Q ON ( Q.RealLotNo = A.RealLotNo AND Q.ProcNo = D.ProcNo ) 
      LEFT OUTER JOIN _TPDBaseProcess AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.ProcSeq = E.ProcSeq ) 
      JOIN _TDAItem AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.GoodItemSeq 
                                       AND F.AssetSeq = (SELECT EnvValue 
                                                           FROM lumim_TCOMEnv 
                                                          WHERE CompanySeq = @CompanySeq AND EnvSeq = 3 AND EnvSerl = 1 
                                                        ) 
                                         )
	 WHERE A.CompanySeq = @CompanySeq
       AND (@ProcSeq = 0 OR A.ProcSeq = @ProcSeq) 
       AND C.ProdPlanNo = @ProdPlanNo 
       AND Q.RealLotNo = A.RealLotNo 
       AND Q.ProcNo = D.ProcNo 
       AND D.ProcNo <> E.ProcNo 
    
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
       AND (@ProcSeq = 0 OR A.ProcSeq = @ProcSeq) 
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
       AND (@ProcSeq = 0 OR A.ProcSeq = @ProcSeq) 
       AND C.ProdPlanNo = @ProdPlanNo 
    
     GROUP BY D.RealLotNo 
    
    RETURN  

GO
exec lumim_SPDSFCProcStockListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ProdPlanNo>201308250003</ProdPlanNo>
    <ProcSeq>385</ProcSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017251,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014758