  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockListQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockListQuerySub  
GO  
  
-- v2015.10.22  
  
-- 월생산계획조회-Sub조회 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockListQuerySub  
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
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlanSeq   INT)    
    
    -- 최종조회   
    SELECT A.PlanSeq, 
           A.PlanSerl, 
           A.ItemSeq, 
           CASE WHEN B.ItemEngSName <> '' THEN B.ItemEngSName ELSE B.ItemName END AS ItemName, 
           B.ItemNo, 
           A.BaseQty / 1000 AS BaseQty, 
           A.ProdPlanQty / 1000 AS ProdPlanQty, 
           A.SalesPlanQty / 1000 AS SalesPlanQty, 
           A.SelfQty / 1000 AS SelfQty, 
           A.LastQty / 1000 AS LastQty, 
           C.PlanNo, 
           CASE WHEN E.MngValSeq IN ( 1010168007, 1010168010 ) 
                THEN E.MngValSeq 
                ELSE (
                        CASE WHEN D.AssetSeq = 18 -- PPG제품 
                             THEN 1010168001
                             WHEN D.AssetSeq = 20 -- PPG반제품 
                             THEN 1010168002 
                             END 
                     ) 
                END AS GubunSeq 
      FROM KPXCM_TPDSFCMonthProdPlanStockItem           AS A 
      LEFT OUTER JOIN _TDAItem                          AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN KPXCM_TPDSFCMonthProdPlanStock    AS C ON ( C.CompanySeq = @CompanySeq AND C.PlanSeq = A.PlanSeq ) 
      LEFT OUTER JOIN _TDAItemAsset                     AS D ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = B.AssetSeq ) 
      LEFT OUTER JOIN _TDAItemUserDefine                 AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq AND E.MngSerl = 1000003 ) 
      LEFT OUTER JOIN _TDAUMinor                        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MngValSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlanSeq = @PlanSeq 
     ORDER BY GubunSeq, ItemName 
    
    RETURN 