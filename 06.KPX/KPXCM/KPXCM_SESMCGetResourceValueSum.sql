IF OBJECT_ID('KPXCM_SESMCGetResourceValueSum') IS NOT NULL 
    DROP PROC KPXCM_SESMCGetResourceValueSum
GO 

-- v2016.05.23 
  
-- 배부기준 by이재천 
CREATE PROC dbo.KPXCM_SESMCGetResourceValueSum
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    

	DECLARE @CostKeySeq INT,
			@CostUnit   INT,
			@SMCostDiv	INT,
			@DriverWeight   INT,
			@CostYM     NCHAR(6),
            @CostCalcUnit   INT
    
    CREATE TABLE #Temp (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'   
    IF @@ERROR <> 0 RETURN    
    
    SELECT @CostYM = CostYM FROM #Temp WHERE ISNULL(CostYM,'') <> ''
    
--1111	KPX_드럼포장실적
--1112	KPX_수출비용    
    
    DELETE B 
     FROM #Temp AS A 
     JOIN _TESMGDriverSum AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq AND B.AccUnit = A.CostUnit ) 
    WHERE B.DriverSeq IN ( 2113, 2114, 2115 , 2119, 1111, 1112 ) 
    
	SELECT @CostKeySeq = CostKeySeq, @CostUnit = CostUnit, @SMCostDiv = SMCostDiv FROM #Temp


     
     -- 환경설정에서 '가중치배부기준' 가져오기      (공정/제품/공정품)의 생산량에 가중치를 준 배부기준을 사용합니다.
     EXEC dbo._SCOMEnv @CompanySeq,5908,0  /*@UserSeq*/,@@PROCID,@DriverWeight OUTPUT    
     
     -- 환경설정에서 '원가계산단위' 가져오기      (공정/제품/공정품)의 생산량에 가중치를 준 배부기준을 사용합니다.
     EXEC dbo._SCOMEnv @CompanySeq,5524,0  /*@UserSeq*/,@@PROCID,@CostCalcUnit OUTPUT    


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
       AND A.CostKeySeq = @CostKeySeq -- 2016.05.23 by bgKeum 추가
       AND EXISTS (SELECT 1 FROM #Temp WHERE CostUnit = A.AccUnit) 
     GROUP BY A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, A.BizUnit, A.SMCostDiv, A.CustSeq, 
           A.DataSource, A.FactUnit, A.AccUnit
    
    
    --시간에도 가중치 계산 하기 위해 추가
   
    INSERT INTO #BaseTime 
    (
        CostKeySeq      ,CCtrSeq          ,ItemSeq          ,WorkOrderSeq     ,ProcSeq          ,
        AssySeq         ,DriverSeq        ,BizUnit          ,SMCostDiv        ,CustSeq          ,
        DataSource      ,FactUnit         ,AccUnit          ,DriverValue      
    ) 
    SELECT A.CostKeySeq, A.CCtrSeq, A.ItemSeq , A.WorkOrderSeq, A.ProcSeq, 
           A.AssySeq, 0, A.BizUnit, A.SMCostDiv, A.CustSeq, 

           A.DataSource, A.FactUnit, A.AccUnit, 
           --SUM(DriverValue) AS DriverValue 
           SUM(ROUND(A.DriverValue* ISNULL(C.Weight,1),5))
      FROM _TESMGDriverSum          AS A 
            LEFT OUTER JOIN _TESMDDriverWeight AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq 
                                                                AND A.CostKeySeq = C.CostKeySeq 
                                                             -- 2016.05.23 by bgKeum CostUnit Join 추가
                                                                AND C.CostUnit = (CASE @CostCalcUnit WHEN 5502003 THEN A.BizUnit
                                                                                                     WHEN 5502001 THEN A.FactUnit
                                                                                                     WHEN 5502002 THEN A.AccUnit END)
                                                                AND ((@DriverWeight = 5541001 AND A.ProcSeq = C.ProcSeq)
                                                                  OR (@DriverWeight = 5541002 AND A.ItemSeq = C.ItemSeq)
                                                                  --OR (@DriverWeight = 5541003 AND A.ITemSeq = C.ITemSeq AND A.AssyITemSeq = C.AssyItemSeq)
                                                                  --OR (@DriverWeight = 5541004 AND A.ProcSeq = C.ProcSeq AND D.ProcTypeSeq = C.ProcTypeSeq)
                                                                    )       
     WHERE A.DriverSeq = 10
       AND A.CompanySeq = @CompanySeq 
       AND A.CostKeySeq = @CostKeySeq -- 2016.05.23 by bgKeum 추가
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


--SELECT * FROM _TESMBDriver WHERE CompanySeq = 2

    --시간 * 가중치 를 2121 로 insert한다. #BaseTime 에 가중치 곱한 값이 있다.
    INSERT INTO _TESMGDriverSum 
    (
        CompanySeq ,    CostKeySeq ,    CCtrSeq ,   ItemSeq ,   WorkOrderSeq ,
        ProcSeq ,       AssySeq ,       DriverSeq , BizUnit ,   SMCostDiv ,
        CustSeq ,       DataSource ,    FactUnit ,  AccUnit ,   DriverValue
    ) 
    SELECT @CompanySeq, A.CostKeySeq      ,A.CCtrSeq          ,A.ItemSeq          ,A.WorkOrderSeq     ,A.ProcSeq          ,
           A.AssySeq         ,2121               ,A.BizUnit          ,A.SMCostDiv        ,A.CustSeq          ,
           A.DataSource      ,A.FactUnit         ,A.AccUnit          , 
           ISNULL(C.DriverValue,0) AS DriverValue 
      FROM #AllData AS A 
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
        
    
--1111	KPX_드럼포장실적
--1112	KPX_수출비용
    
    
    
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
    


	    INSERT INTO _TESMGDriverSum 
		(
			CompanySeq ,    CostKeySeq ,    CCtrSeq ,   ItemSeq ,   WorkOrderSeq ,
			ProcSeq ,       AssySeq ,       DriverSeq , BizUnit ,   SMCostDiv ,
			CustSeq ,       DataSource ,    FactUnit ,  AccUnit ,   DriverValue
		)

		SELECT @CompanySeq, @CostKeySeq, A.CCtrSeq, A.ItemSeq, 0,
			   A.ProcSeq,  A.AssyItemSeq, 2119, A.BizUnit, 5507001,
			   0,	0, A.FactUnit, A.AccUnit, SUM(ISNULL(B.SteamHour, 0))	
		  FROM _TESMGWorkReport AS A WITH(NOLOCK) 
				LEFT OUTER JOIN KPX_TPDSFCWorkReportAdd AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.WorkReportSeq = B.WorkReportSeq
		WHERE A.CostKeySeq = @CostKeySeq   
          AND A.CompanySeq = @CompanySeq    
		  AND A.FactUnit = 5
		GROUP BY  A.CCtrSeq, A.ItemSeq,
			   A.ProcSeq,  A.AssyItemSeq, A.BizUnit, A.FactUnit, A.AccUnit


    --당월 생산입고가 있는 품목이 대상임
    CREATE TABLE #ItemList
    (
        ItemSeq     INT
    )
    
    INSERT INTO #ItemList(ItemSeq)
    SELECT A.GoodItemSeq
      FROM _TPDSFCGoodIn AS A WITH(NOLOCK)
            LEFT OUTER JOIN _TDAFactUnit    AS C WITH(NOLOCK) ON C.CompanySeq   = @CompanySeq AND A.FactUnit    = C.FactUnit
            LEFT OUTER JOIN _TDABizUnit     AS D WITH(NOLOCK) ON D.CompanySeq   = @CompanySeq AND C.BizUnit = D.BizUnit
     WHERE A.CompanySeq   = @CompanySeq
       AND LEFT(A.InDate,6) = @CostYM
       AND ISNULL(D.AccUnit,0) = @CostUnit
  
    
--1111	KPX_드럼포장실적
	    INSERT INTO _TESMGDriverSum 
		(
			CompanySeq ,    CostKeySeq ,    CCtrSeq ,   ItemSeq ,   WorkOrderSeq ,
			ProcSeq ,       AssySeq ,       DriverSeq , BizUnit ,   SMCostDiv ,
			CustSeq ,       DataSource ,    FactUnit ,  AccUnit ,   DriverValue
		)

	   SELECT @CompanySeq, @CostKeySeq, 0, 	B.ItemSeq, 0,
	          0, 0, 1111, C.BizUnit, 5507001,
	          0, 0, A.FactUnit, D.AccUnit, SUM(B.SubQty)
       FROM KPX_TPDSFCProdPackReport AS A  
       LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackReportSeq = A.PackReportSeq ) 
            LEFT OUTER JOIN _TDAFactUnit    AS C WITH(NOLOCK) ON C.CompanySeq   = @CompanySeq AND A.FactUnit    = C.FactUnit
            LEFT OUTER JOIN _TDABizUnit     AS D WITH(NOLOCK) ON D.CompanySeq   = @CompanySeq AND C.BizUnit = D.BizUnit
      WHERE A.CompanySeq    = @CompanySeq
        AND LEFT(ISNULL(A.PackDate,''),6) = @CostYM
        AND ISNULL(D.AccUnit,0) = @CostUnit
        AND B.ItemSeq IN (SELECT ItemSeq FROM #ItemList)
      GROUP BY B.ItemSeq, C.BizUnit, A.FactUnit, D.AccUnit

--1112	KPX_수출비용    
	    INSERT INTO _TESMGDriverSum 
		(
			CompanySeq ,    CostKeySeq ,    CCtrSeq ,   ItemSeq ,   WorkOrderSeq ,
			ProcSeq ,       AssySeq ,       DriverSeq , BizUnit ,   SMCostDiv ,
			CustSeq ,       DataSource ,    FactUnit ,  AccUnit ,   DriverValue
		)
	   SELECT @CompanySeq, @CostKeySeq, 0, 	B.ItemSeq, 0,
	          0, 0, 1112, A.BizUnit, 5507001,
	          0, 0, E.FactUnit, D.AccUnit, SUM(ISNULL(B.Qty,0)*ISNULL(C.ExpAmtUSD,0) )
       FROM _TSLOrder AS A WITH(NOLOCK)
            LEFT OUTER JOIN _TSLOrderItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                           AND A.OrderSeq   = B.OrderSeq
            LEFT OUTER JOIN KPX_TSLOrderItemAdd AS C WITH(NOLOCK) ON A.CompanySeq   = C.CompanySeq
                                                                 AND A.OrderSeq     = C.OrderSeq
                                                                 AND B.OrderSerl    = C.OrderSerl
            LEFT OUTER JOIN _TDABizUnit     AS D WITH(NOLOCK) ON D.CompanySeq   = @CompanySeq AND A.BizUnit = D.BizUnit  
            LEFT OUTER JOIN _TDAFactUnit    AS E WITH(NOLOCK) ON E.CompanySeq   = @CompanySeq AND D.BizUnit    = E.BizUnit                                                                           
      WHERE A.CompanySeq    = @CompanySeq
        AND LEFT(ISNULL(A.OrderDate,''),6) = @CostYM
        AND ISNULL(D.AccUnit,0) = @CostUnit
      GROUP BY B.ItemSeq, A.BizUnit, E.FactUnit, D.AccUnit

    SELECT * FROM #Temp 
    
    RETURN

GO

--SELECT * FROM _TESMDCostKey WHERE CompanySeq = 2
begin tran
exec KPXCM_SESMCGetResourceValueSum @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>P</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <CostUnit>1</CostUnit>
    <RptUnit>0</RptUnit>
    <CostYM>201605</CostYM>
    <SMCostMng>5512001</SMCostMng>
    <CostMngAmdSeq>0</CostMngAmdSeq>
    <CostKeySeq>29</CostKeySeq>
    <WorkSeq>15</WorkSeq>
    <StartTime>2015-09-24T14:28:17.843</StartTime>
    <EndTime>2015-09-24T14:28:18.713</EndTime>
    <UserName>영림원</UserName>
    <PlanYear xml:space="preserve">    </PlanYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1028091,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=3600
rollback
