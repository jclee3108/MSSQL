if object_id('KPX_TSLWeekSalesPlanRev') is null

begin 
CREATE TABLE KPX_TSLWeekSalesPlanRev
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    WeekSeq		INT 	 NOT NULL, 
    PlanRev		NCHAR(6) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TSLWeekSalesPlanRev on KPX_TSLWeekSalesPlanRev(CompanySeq,BizUnit,WeekSeq,PlanRev) 
end 


if object_id('KPX_TSLWeekSalesPlanRevLog') is null
begin 

CREATE TABLE KPX_TSLWeekSalesPlanRevLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    WeekSeq		INT 	 NOT NULL, 
    PlanRev		NCHAR(6) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 