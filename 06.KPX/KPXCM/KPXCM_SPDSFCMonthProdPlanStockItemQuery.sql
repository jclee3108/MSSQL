  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockItemQuery') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockItemQuery  
GO  
  
-- v2015.10.20  
  
-- 월생산계획-조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockItemQuery  
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
            @PlanSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanSeq   = ISNULL( PlanSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (PlanSeq   INT)    
    
    -- 최종조회   
    SELECT A.PlanSeq, 
           A.PlanSerl, 
           A.ItemSeq, 
           CASE WHEN C.ItemEngSName <> '' THEN C.ItemEngSName ELSE C.ItemName END AS ItemName, 
           C.ItemNo, 
           CASE WHEN @WorkingTag = 'P' THEN A.BaseQty / 1000 ELSE A.BaseQty END AS BaseQty, 
           CASE WHEN @WorkingTag = 'P' THEN A.ProdPlanQty / 1000 ELSE A.ProdPlanQty END AS ProdPlanQty, 
           CASE WHEN @WorkingTag = 'P' THEN A.SalesPlanQty / 1000 ELSE A.SalesPlanQty END AS SalesPlanQty,  
           CASE WHEN @WorkingTag = 'P' THEN A.SelfQty / 1000 ELSE A.SelfQty END AS SelfQty, 
           CASE WHEN @WorkingTag = 'P' THEN A.LastQty / 1000 ELSE A.LastQty END AS LastQty, 
           CASE WHEN E.MngValSeq IN ( 1010168007, 1010168010 ) 
                THEN E.MngValSeq 
                ELSE (
                        CASE WHEN D.AssetSeq = 18 -- PPG제품 
                             THEN 1010168001
                             WHEN D.AssetSeq = 20 -- PPG반제품 
                             THEN 1010168002 
                             END 
                     ) 
                END AS GubunSeq, 
           CASE WHEN @WorkingTag = 'P' THEN G.SumBaseQty1 / 1000 ELSE G.SumBaseQty1 END AS SumBaseQty1, 
           CASE WHEN @WorkingTag = 'P' THEN G.SumProdPlanQty1 / 1000 ELSE G.SumProdPlanQty1 END AS SumProdPlanQty1 , 
           CASE WHEN @WorkingTag = 'P' THEN G.SumSalesPlanQty1 / 1000 ELSE G.SumSalesPlanQty1 END AS SumSalesPlanQty1 , 
           CASE WHEN @WorkingTag = 'P' THEN G.SumSelfQty1 / 1000 ELSE G.SumSelfQty1 END AS SumSelfQty1, 
           CASE WHEN @WorkingTag = 'P' THEN G.SumLastQty1 / 1000 ELSE G.SumLastQty1 END AS SumLastQty1, 
           CASE WHEN @WorkingTag = 'P' THEN H.SumBaseQty2 / 1000 ELSE H.SumBaseQty2 END AS SumBaseQty2, 
           CASE WHEN @WorkingTag = 'P' THEN H.SumProdPlanQty2 / 1000 ELSE H.SumProdPlanQty2 END AS SumProdPlanQty2, 
           CASE WHEN @WorkingTag = 'P' THEN H.SumSalesPlanQty2 / 1000 ELSE H.SumSalesPlanQty2 END AS SumSalesPlanQty2, 
           CASE WHEN @WorkingTag = 'P' THEN H.SumSelfQty2 / 1000 ELSE H.SumSelfQty2 END AS SumSelfQty2, 
           CASE WHEN @WorkingTag = 'P' THEN H.SumLastQty2 / 1000 ELSE H.SumLastQty2 END AS SumLastQty2

      FROM KPXCM_TPDSFCMonthProdPlanStockItem   AS A 
      LEFT OUTER JOIN _TDAItem                  AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset             AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN _TDAItemUserDefine         AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = C.ItemSeq AND E.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinor                AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MngValSeq ) 
      OUTER APPLY ( SELECT SUM(Z.BaseQty) AS SumBaseQty1, SUM(Z.ProdPlanQty) AS SumProdPlanQty1, SUM(Z.SalesPlanQty) AS SumSalesPlanQty1, 
                           SUM(Z.SelfQty) AS SumSelfQty1, SUM(LastQty) AS SumLastQty1 
                      FROM KPXCM_TPDSFCMonthProdPlanStockItem AS Z 
                      LEFT OUTER JOIN _TDAItem                AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.PlanSeq = @PlanSeq
                       AND Y.AssetSeq = 18 
                  ) AS G 
      OUTER APPLY ( SELECT SUM(Z.BaseQty) AS SumBaseQty2, SUM(Z.ProdPlanQty) AS SumProdPlanQty2, SUM(Z.SalesPlanQty) AS SumSalesPlanQty2, 
                           SUM(Z.SelfQty) AS SumSelfQty2, SUM(LastQty) AS SumLastQty2 
                      FROM KPXCM_TPDSFCMonthProdPlanStockItem AS Z 
                      LEFT OUTER JOIN _TDAItem                AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ItemSeq = Z.ItemSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.PlanSeq = @PlanSeq
                       AND Y.AssetSeq = 20
                  ) AS H 
      LEFT OUTER JOIN KPXCM_TPDSFCMonthProdPlanStock AS I ON ( I.CompanySeq = @CompanySeq AND I.PlanSeq = A.PlanSeq AND I.PlanYMSub = A.PlanYMSub ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlanSeq = @PlanSeq 
       AND A.PlanYMSub = I.PlanYM
     ORDER BY GubunSeq, ItemName
    
    RETURN  
GO
exec KPXCM_SPDSFCMonthProdPlanStockItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanSeq>17</PlanSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'P',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069