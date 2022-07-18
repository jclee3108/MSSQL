
if object_id('KPXCM_TPDSFCMonthProdPlanStockItem') is null 
begin 
    CREATE TABLE KPXCM_TPDSFCMonthProdPlanStockItem
    (
        CompanySeq		INT 	 NOT NULL, 
        PlanSeq		INT 	 NOT NULL, 
        PlanSerl		INT 	 NOT NULL, 
        PlanYMSub   NCHAR(6) NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        BaseQty		DECIMAL(19,5) 	 NOT NULL, 
        ProdPlanQty		DECIMAL(19,5) 	 NOT NULL, 
        SalesPlanQty		DECIMAL(19,5) 	 NOT NULL, 
        SelfQty		DECIMAL(19,5) 	 NOT NULL, 
        LastQty		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index idx_KPXCM_TPDSFCMonthProdPlanStockItem on KPXCM_TPDSFCMonthProdPlanStockItem(CompanySeq,PlanSeq,PlanSerl,PlanYMSub) 
end 


if object_id('KPXCM_TPDSFCMonthProdPlanStockItemLog') is null 
begin 
CREATE TABLE KPXCM_TPDSFCMonthProdPlanStockItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlanSeq		INT 	 NOT NULL, 
    PlanSerl		INT 	 NOT NULL, 
    PlanYMSub   NCHAR(6) NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    BaseQty		DECIMAL(19,5) 	 NOT NULL, 
    ProdPlanQty		DECIMAL(19,5) 	 NOT NULL, 
    SalesPlanQty		DECIMAL(19,5) 	 NOT NULL, 
    SelfQty		DECIMAL(19,5) 	 NOT NULL, 
    LastQty		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 

