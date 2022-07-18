  
IF OBJECT_ID('KPX_SESMCGetResourceValueSum') IS NOT NULL   
    DROP PROC KPX_SESMCGetResourceValueSum  
GO  
  
-- v2015.02.23 
  
-- 배부기준 by이재천 
CREATE PROC KPX_SESMCGetResourceValueSum  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'   
    IF @@ERROR <> 0 RETURN    
    
    DELETE B 
     FROM #Temp AS A 
     JOIN _TESMGDriverSum AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq AND B.AccUnit = A.CostUnit ) 
    WHERE B.DriverSeq IN ( 2113, 2114, 2115 ) 
    
    CREATE TABLE #BaseQty 
    (
        CostKeySeq      INT, 
        CCtrSeq         INT, 
        ItemSeq         INT, 
        WorkOrderSeq    INT, 
        ProcSeq         INT, 
        AssySeq         INT, 
        DriverSeq       INT, 
        BizUnit         INT, 
        SMCostDiv       INT, 
        CustSeq         INT, 
        DataSource      INT, 
        FactUnit        INT, 
        AccUnit         INT, 
        DriverValue     DECIMAL(19,5) 
    ) 
    
    CREATE TABLE #BaseTime 
    (
        CostKeySeq      INT, 
        CCtrSeq         INT, 
        ItemSeq         INT, 
        WorkOrderSeq    INT, 
        ProcSeq         INT, 
        AssySeq         INT, 
        DriverSeq       INT, 
        BizUnit         INT, 
        SMCostDiv       INT, 
        CustSeq         INT, 
        DataSource      INT, 
        FactUnit        INT, 
        AccUnit         INT, 
        DriverValue     DECIMAL(19,5) 
    ) 
    
    INSERT INTO #BaseQty 
    (
        CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
        AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
        DataSource      ,FactUnit         ,AccUnit          ,DriverValue      
    ) 
    SELECT A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, 0, A.BizUnit, A.SMCostDiv, A.CustSeq, 
           A.DataSource, A.FactUnit, A.AccUnit, SUM(CASE WHEN C.SMAssetGrp = 6008005 THEN 0 ELSE A.DriverValue END) AS DriverValue 
      FROM _TESMGDriverSum AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.AssySeq ) 
      LEFT OUTER JOIN _TDAItemAsset AS C ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = B.AssetSeq ) 
     WHERE A.DriverSeq = 103 
       AND A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Temp WHERE CostUnit = A.AccUnit) 
     GROUP BY A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, A.BizUnit, A.SMCostDiv, A.CustSeq, 
           A.DataSource, A.FactUnit, A.AccUnit
    
    INSERT INTO #BaseTime 
    (
        CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
        AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
        DataSource      ,FactUnit         ,AccUnit          ,DriverValue      
    ) 
    SELECT A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, 0, A.BizUnit, A.SMCostDiv, A.CustSeq, 
           A.DataSource, A.FactUnit, A.AccUnit, SUM(DriverValue) AS DriverValue 
      FROM _TESMGDriverSum          AS A 
     WHERE A.DriverSeq = 10
       AND A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #Temp WHERE CostUnit = A.AccUnit) 
     GROUP BY A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, A.BizUnit, A.SMCostDiv, A.CustSeq, 
           A.DataSource, A.FactUnit, A.AccUnit
    
    CREATE TABLE #AllData
    (
        CostKeySeq      INT, 
        CCtrSeq         INT, 
        ItemSeq         INT, 
        WorkOrderSeq    INT, 
        ProcSeq         INT, 
        AssySeq         INT, 
        DriverSeq       INT, 
        BizUnit         INT, 
        SMCostDiv       INT, 
        CustSeq         INT, 
        DataSource      INT, 
        FactUnit        INT, 
        AccUnit         INT 
    )
    
    INSERT INTO #AllData 
    (
        CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
        AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
        DataSource      ,FactUnit         ,AccUnit          
    ) 
    SELECT CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
           AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
           DataSource      ,FactUnit         ,AccUnit 
      FROM #BaseQty
    
    UNION  
    
    SELECT CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
           AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
           DataSource      ,FactUnit         ,AccUnit 
      FROM #BaseTime  
    
    
    
    INSERT INTO _TESMGDriverSum 
    (
        CompanySeq ,    CostKeySeq ,    CCtrSeq ,   ItemSeq ,   WorkOrderSeq ,
        ProcSeq ,       AssySeq ,       DriverSeq , BizUnit ,   SMCostDiv ,
        CustSeq ,       DataSource ,    FactUnit ,  AccUnit ,   DriverValue
    ) 
    SELECT @CompanySeq     ,A.CostKeySeq       ,A.CCtrSeq          ,A.ItemSeq          ,A.WorkOrderSeq     ,
           A.ProcSeq       ,A.AssySeq          ,2113               ,A.BizUnit          ,A.SMCostDiv        ,
           A.CustSeq       ,A.DataSource       ,A.FactUnit         ,A.AccUnit          , 
           CASE WHEN ISNULL(B.DriverValue,0) = 0 THEN 0 ELSE ISNULL(C.DriverValue,0) / ISNULL(B.DriverValue,0) END * 0.5 * 100 + 
           CASE WHEN ISNULL(D.DriverValue,0) = 0 THEN 0 ELSE ISNULL(E.DriverValue,0) / ISNULL(D.DriverValue,0) END * 0.5 * 100 AS DriverValue 
      FROM #AllData AS A 
      LEFT OUTER JOIN ( SELECT Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit , SUM(DriverValue) AS DriverValue
                          FROM #BaseTime AS Z 
                         GROUP BY Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit 
                      ) AS B ON ( B.CostKeySeq = A.CostKeySeq 
                              AND B.FactUnit = A.FactUnit 
                              AND B.BizUnit = A.BizUnit 
                              AND B.AccUnit = A.AccUnit 
                                 )
      LEFT OUTER JOIN #BaseTime AS C ON ( C.CostKeySeq = A.CostKeySeq
                                      AND C.CCtrSeq = A.CCtrSeq 
                                      AND C.ItemSeq = A.ItemSeq 
                                      AND C.WorkOrderSeq = A.WorkOrderSeq
                                      AND C.ProcSeq = A.ProcSeq
                                      AND C.AssySeq = A.AssySeq
                                      AND C.DriverSeq = A.DriverSeq
                                      AND C.BizUnit = A.BizUnit
                                      AND C.SMCostDiv = A.SMCostDiv
                                      AND C.CustSeq = A.CustSeq
                                      AND C.DataSource = A.DataSource
                                      AND C.FactUnit = A.FactUnit
                                      AND C.AccUnit = A.AccUnit
                                         )
      LEFT OUTER JOIN ( SELECT Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit , SUM(DriverValue) AS DriverValue
                          FROM #BaseQty AS Z 
                         GROUP BY Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit 
                      ) AS D ON ( D.CostKeySeq = A.CostKeySeq 
                              AND D.FactUnit = A.FactUnit 
                              AND D.BizUnit = A.BizUnit 
                              AND D.AccUnit = A.AccUnit 
                                 )
      LEFT OUTER JOIN #BaseQty AS E ON ( E.CostKeySeq = A.CostKeySeq
                                     AND E.CCtrSeq = A.CCtrSeq 
                                     AND E.ItemSeq = A.ItemSeq 
                                     AND E.WorkOrderSeq = A.WorkOrderSeq
                                     AND E.ProcSeq = A.ProcSeq
                                     AND E.AssySeq = A.AssySeq
                                     AND E.DriverSeq = A.DriverSeq
                                     AND E.BizUnit = A.BizUnit
                                     AND E.SMCostDiv = A.SMCostDiv
                                     AND E.CustSeq = A.CustSeq
                                     AND E.DataSource = A.DataSource
                                     AND E.FactUnit = A.FactUnit
                                     AND E.AccUnit = A.AccUnit
                                        )
    
    UNION ALL 

    SELECT @CompanySeq, A.CostKeySeq      ,A.CCtrSeq          ,A.ItemSeq          ,A.WorkOrderSeq     ,A.ProcSeq          ,
           A.AssySeq         ,2114               ,A.BizUnit          ,A.SMCostDiv        ,A.CustSeq          ,
           A.DataSource      ,A.FactUnit         ,A.AccUnit          , 
           CASE WHEN ISNULL(B.DriverValue,0) = 0 THEN 0 ELSE ISNULL(C.DriverValue,0) / ISNULL(B.DriverValue,0) END * 0.5 * 100 AS DriverValue 
      FROM #AllData AS A 
      LEFT OUTER JOIN ( SELECT Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit , SUM(DriverValue) AS DriverValue
                          FROM #BaseTime AS Z 
                         GROUP BY Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit 
                      ) AS B ON ( B.CostKeySeq = A.CostKeySeq 
                              AND B.FactUnit = A.FactUnit 
                              AND B.BizUnit = A.BizUnit 
                              AND B.AccUnit = A.AccUnit 
                                 )
      LEFT OUTER JOIN #BaseTime AS C ON ( C.CostKeySeq = A.CostKeySeq
                                      AND C.CCtrSeq = A.CCtrSeq 
                                      AND C.ItemSeq = A.ItemSeq 
                                      AND C.WorkOrderSeq = A.WorkOrderSeq
                                      AND C.ProcSeq = A.ProcSeq
                                      AND C.AssySeq = A.AssySeq
                                      AND C.DriverSeq = A.DriverSeq
                                      AND C.BizUnit = A.BizUnit
                                      AND C.SMCostDiv = A.SMCostDiv
                                      AND C.CustSeq = A.CustSeq
                                      AND C.DataSource = A.DataSource
                                      AND C.FactUnit = A.FactUnit
                                      AND C.AccUnit = A.AccUnit
                                         )
    
    UNION ALL 
    
    SELECT @CompanySeq, A.CostKeySeq    ,A.CCtrSeq          ,A.ItemSeq          ,A.WorkOrderSeq     ,A.ProcSeq          ,
           A.AssySeq       ,2115               ,A.BizUnit          ,A.SMCostDiv        ,A.CustSeq          ,
           A.DataSource    ,A.FactUnit         ,A.AccUnit          ,
           CASE WHEN ISNULL(D.DriverValue,0) = 0 THEN 0 ELSE ISNULL(E.DriverValue,0) / ISNULL(D.DriverValue,0) END * 0.5 * 100 AS DriverValue 
      FROM #AllData AS A 
      LEFT OUTER JOIN ( SELECT Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit , SUM(DriverValue) AS DriverValue
                          FROM #BaseQty AS Z 
                         GROUP BY Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit 
                      ) AS D ON ( D.CostKeySeq = A.CostKeySeq 
                              AND D.FactUnit = A.FactUnit 
                              AND D.BizUnit = A.BizUnit 
                              AND D.AccUnit = A.AccUnit 
                                 )
      LEFT OUTER JOIN #BaseQty AS E ON ( E.CostKeySeq = A.CostKeySeq
                                     AND E.CCtrSeq = A.CCtrSeq 
                                     AND E.ItemSeq = A.ItemSeq 
                                     AND E.WorkOrderSeq = A.WorkOrderSeq
                                     AND E.ProcSeq = A.ProcSeq
                                     AND E.AssySeq = A.AssySeq
                                     AND E.DriverSeq = A.DriverSeq
                                     AND E.BizUnit = A.BizUnit
                                     AND E.SMCostDiv = A.SMCostDiv
                                     AND E.CustSeq = A.CustSeq
                                     AND E.DataSource = A.DataSource
                                     AND E.FactUnit = A.FactUnit
                                     AND E.AccUnit = A.AccUnit
                                        )
    
    UNION ALL 
    
    SELECT @CompanySeq, A.CostKeySeq    ,A.CCtrSeq          ,A.ItemSeq          ,A.WorkOrderSeq     ,A.ProcSeq          ,
           A.AssySeq       ,2116               ,A.BizUnit          ,A.SMCostDiv        ,A.CustSeq          ,
           A.DataSource    ,A.FactUnit         ,A.AccUnit          ,
           ISNULL(E.DriverValue,0)
           --CASE WHEN ISNULL(D.DriverValue,0) = 0 THEN 0 ELSE ISNULL(E.DriverValue,0) / ISNULL(D.DriverValue,0) END * 0.5 * 100 AS DriverValue 
      FROM #AllData AS A 
      --LEFT OUTER JOIN ( SELECT Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit , SUM(DriverValue) AS DriverValue
      --                    FROM #BaseQty AS Z 
      --                   GROUP BY Z.CostKeySeq, Z.FactUnit, Z.AccUnit, Z.BizUnit 
      --                ) AS D ON ( D.CostKeySeq = A.CostKeySeq 
      --                        AND D.FactUnit = A.FactUnit 
      --                        AND D.BizUnit = A.BizUnit 
      --                        AND D.AccUnit = A.AccUnit 
      --                           )
      LEFT OUTER JOIN #BaseQty AS E ON ( E.CostKeySeq = A.CostKeySeq
                                     AND E.CCtrSeq = A.CCtrSeq 
                                     AND E.ItemSeq = A.ItemSeq 
                                     AND E.WorkOrderSeq = A.WorkOrderSeq
                                     AND E.ProcSeq = A.ProcSeq
                                     AND E.AssySeq = A.AssySeq
                                     AND E.DriverSeq = A.DriverSeq
                                     AND E.BizUnit = A.BizUnit
                                     AND E.SMCostDiv = A.SMCostDiv
                                     AND E.CustSeq = A.CustSeq
                                     AND E.DataSource = A.DataSource
                                     AND E.FactUnit = A.FactUnit
                                     AND E.AccUnit = A.AccUnit
                                        )
    
    SELECT * FROM #Temp 
    
    RETURN  
GO 
begin tran 
exec KPX_SESMCGetResourceValueSum @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>P</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <CostUnit>1</CostUnit>
    <RptUnit>0</RptUnit>
    <CostYM>201501</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <CostMngAmdSeq>0</CostMngAmdSeq>
    <CostKeySeq>49</CostKeySeq>
    <WorkSeq>15</WorkSeq>
    <StartTime>2015-02-23T20:28:28.623</StartTime>
    <EndTime>2015-02-23T20:28:28.863</EndTime>
    <UserName>영림원</UserName>
    <PlanYear xml:space="preserve">    </PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1028091,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3600
rollback 