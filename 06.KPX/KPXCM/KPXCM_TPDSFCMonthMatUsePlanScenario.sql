if object_id('KPXCM_TPDSFCMonthMatUsePlanScenario') is null
begin 
    CREATE TABLE KPXCM_TPDSFCMonthMatUsePlanScenario
    (
        CompanySeq		INT 	 NOT NULL, 
        FactUnit		INT 	 NOT NULL, 
        PlanYM		NCHAR(6) 	 NOT NULL, 
        PlanRev     NCHAR(2)        NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        StockQty		DECIMAL(19,5) 	 NOT NULL, 
        ProdQtyM		DECIMAL(19,5) 	 NOT NULL, 
        RepalceQtyM		DECIMAL(19,5) 	 NOT NULL, 
        --ProdQtyM1		DECIMAL(19,5) 	 NOT NULL, 
        --RepalceQtyM1		DECIMAL(19,5) 	 NOT NULL, 
        --ProdQtyM2		DECIMAL(19,5) 	 NOT NULL, 
        --RepalceQtyM2		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL

    )
    create unique clustered index idx_KPXCM_TPDSFCMonthMatUsePlanStock on KPXCM_TPDSFCMonthMatUsePlanScenario(CompanySeq,FactUnit,PlanYM,PlanRev,ItemSeq) 
end 

if object_id('KPXCM_TPDSFCMonthMatUsePlanScenarioLog') is null
begin 
CREATE TABLE KPXCM_TPDSFCMonthMatUsePlanScenarioLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev     NCHAR(2)        NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    StockQty		DECIMAL(19,5) 	 NOT NULL, 
    ProdQtyM		DECIMAL(19,5) 	 NOT NULL, 
    RepalceQtyM		DECIMAL(19,5) 	 NOT NULL, 
    --ProdQtyM1		DECIMAL(19,5) 	 NOT NULL, 
    --RepalceQtyM1		DECIMAL(19,5) 	 NOT NULL, 
    --ProdQtyM2		DECIMAL(19,5) 	 NOT NULL, 
    --RepalceQtyM2		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

end 

