if object_id('KPXCM_TPDSFCMonthProdPlanScenario') is null 
begin 
    CREATE TABLE KPXCM_TPDSFCMonthProdPlanScenario
    (
        CompanySeq		INT 	 NOT NULL, 
        PlanSeq		INT 	 NOT NULL, 
        PlanYMSub nchar(6) not null, 
        PlanYM      nchar(6) not null, 
        PlanRev		NCHAR(2) 	 NOT NULL, 
        PlanNo      NVARCHAR(200) NOT NULL, 
        FactUnit		INT 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        IsStockCfm  NCHAR(1) NULL, 
        RptProdSalesQty1    decimal(19,5) not null, 
        RptProdSalesQty2 decimal(19,5) not null, 
        RptSelfQty1 decimal(19,5) not null, 
        RptSelfQty2 decimal(19,5) not null, 
        RptSalesQty1 decimal(19,5) not null, 
        RptSalesQty2 decimal(19,5) not null,  
        IsCfm nchar(1) not null, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL 
    )
    create unique clustered index idx_KPXCM_TPDSFCMonthProdPlanScenario on KPXCM_TPDSFCMonthProdPlanScenario(CompanySeq,PlanSeq,PlanYMSub) 
end 

if object_id('KPXCM_TPDSFCMonthProdPlanScenarioLog') is null 
begin 
CREATE TABLE KPXCM_TPDSFCMonthProdPlanScenarioLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlanSeq		INT 	 NOT NULL, 
    PlanYMSub nchar(6) not null, 
    PlanYM      nchar(6) not null, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    PlanNo      NVARCHAR(200) NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    IsStockCfm  NCHAR(1) NULL, 
    RptProdSalesQty1    decimal(19,5) not null, 
    RptProdSalesQty2 decimal(19,5) not null, 
    RptSelfQty1 decimal(19,5) not null, 
    RptSelfQty2 decimal(19,5) not null, 
    RptSalesQty1 decimal(19,5) not null, 
    RptSalesQty2 decimal(19,5) not null,  
    IsCfm nchar(1) not null, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
end 



