if object_id('KPXCM_TPDMonthProdPlanRev') is null

begin 
CREATE TABLE KPXCM_TPDMonthProdPlanRev
(
    CompanySeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    PlanRevName		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NULL 
)
create unique clustered index idx_KPXCM_TPDMonthProdPlanRev on KPXCM_TPDMonthProdPlanRev(CompanySeq,FactUnit,PlanYM,PlanRev) 
end 


if object_id('KPXCM_TPDMonthProdPlanRevLog') is null

begin 
CREATE TABLE KPXCM_TPDMonthProdPlanRevLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    PlanRevName		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NULL
)
end 