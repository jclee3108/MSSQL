IF OBJECT_ID('KPXCM_SPDSFCMonthMatUsePlanScenarioQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthMatUsePlanScenarioQuery   
GO  
  
-- v2016.05.26 
  
-- 원부원료 사용계획서(생산계획시나리오)-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthMatUsePlanScenarioQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @FactUnit   INT,  
            @PlanYM     NCHAR(6), 
            @ItemName   NVARCHAR(100), 
            @ItemNo     NVARCHAR(100), 
            @PlanRevSeq INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit    = ISNULL( FactUnit, 0 ),  
           @PlanYM      = ISNULL( PlanYM, '' ),  
           @ItemName    = ISNULL( ItemName, '' ),  
           @ItemNo      = ISNULL( ItemNo, '' ), 
           @PlanRevSeq  = ISNULL( PlanRevSeq, 0 )
           
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit   INT,  
            PlanYM     NCHAR(6), 
            ItemName   NVARCHAR(100),
            ItemNo     NVARCHAR(100), 
            PlanRevSeq INT 
           )    
    
    -- 최종조회   
    SELECT CASE WHEN ISNULL(B.ItemEngSName,'') <> '' THEN B.ItemEngSName ELSE B.ItemName END AS ItemName, 
           B.ItemNo, 
           A.ItemSeq, 
           A.FactUnit, 
           C.FactUnitName, 
           A.PlanYM, 
           A.PlanRev, 
           CASE WHEN @WorkingTag <> 'P' THEN A.StockQty ELSE A.StockQty / 1000 END AS StockQty, 
           CASE WHEN @WorkingTag <> 'P' THEN A.ProdQtyM ELSE A.ProdQtyM / 1000 END AS ProdQtyM, 
           CASE WHEN @WorkingTag <> 'P' THEN A.RepalceQtyM ELSE A.RepalceQtyM / 1000 END AS RepalceQtyM, 
           CASE WHEN @WorkingTag <> 'P' THEN D.SumStockQty ELSE D.SumStockQty / 1000 END AS SumStockQty, 
           CASE WHEN @WorkingTag <> 'P' THEN D.SumProdQtyM ELSE D.SumProdQtyM / 1000 END AS SumProdQtyM, 
           CASE WHEN @WorkingTag <> 'P' THEN D.SumRepalceQtyM ELSE D.SumRepalceQtyM / 1000 END AS SumRepalceQtyM,                 
           SUBSTRING(A.PlanYM,1,4) + '-' + SUBSTRING(A.PlanYM,5,2) AS RptM,
           SUBSTRING(CONVERT(NCHAR(6),DATEADD(MONTH,1,A.PlanYm + '01'),112),1,4) + '-' + SUBSTRING(CONVERT(NCHAR(6),DATEADD(MONTH,1,A.PlanYm + '01'),112),5,2) AS RptM1,
           SUBSTRING(CONVERT(NCHAR(6),DATEADD(MONTH,2,A.PlanYm + '01'),112),1,4) + '-' + SUBSTRING(CONVERT(NCHAR(6),DATEADD(MONTH,2,A.PlanYm + '01'),112),5,2) AS RptM2
      FROM KPXCM_TPDSFCMonthMatUsePlanScenario     AS A 
      LEFT OUTER JOIN _TDAItem                  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAFactUnit              AS C ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN ( 
                        SELECT SUM(Z.StockQty) AS SumStockQty, 
                               SUM(Z.ProdQtyM) AS SumProdQtyM, 
                               SUM(Z.RepalceQtyM) AS SumRepalceQtyM, 
                               Z.FactUnit, 
                               Z.PlanYM 
                          FROM KPXCM_TPDSFCMonthMatUsePlanScenario AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.FactUnit, Z.PlanYM 
                      ) AS D ON ( D.FactUnit = A.FactUnit AND D.PlanYM = A.PlanYM ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @FactUnit = 0 OR A.FactUnit = @FactUnit )   
       AND ( @PlanYM = A.PlanYM ) 
       AND ( @ItemName = '' OR CASE WHEN ISNULL(B.ItemEngSName,'') <> '' THEN B.ItemEngSName ELSE B.ItemName END LIKE @ItemName + '%' ) 
       AND ( @ItemNo = '' OR B.ItemNo LIKE @ItemNo + '%' ) 
       AND ( CONVERT(INT,A.PlanRev) = @PlanRevSeq ) 
     ORDER BY CASE WHEN ISNULL(B.ItemEngSName,'') <> '' THEN B.ItemEngSName ELSE B.ItemName END
    
      
    RETURN  
Go
exec KPXCM_SPDSFCMonthMatUsePlanStockQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FactUnit>1</FactUnit>
    <PlanYM>201606</PlanYM>
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032977,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030477