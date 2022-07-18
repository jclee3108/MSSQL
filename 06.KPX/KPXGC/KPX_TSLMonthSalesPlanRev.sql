
if object_id('KPX_TSLMonthSalesPlanRev') is null 
begin 
CREATE TABLE KPX_TSLMonthSalesPlanRev
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TSLMonthSalesPlanRev on KPX_TSLMonthSalesPlanRev(CompanySeq,BizUnit,PlanYM,PlanRev) 
end 



if object_id('KPX_TSLMonthSalesPlanRevLog') is null 
begin 
CREATE TABLE KPX_TSLMonthSalesPlanRevLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 