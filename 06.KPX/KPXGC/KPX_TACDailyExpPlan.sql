if object_id('KPX_TACDailyExpPlan') is null
begin 
CREATE TABLE KPX_TACDailyExpPlan
(
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    BegExRate		DECIMAL(19,5) 	 NOT NULL, 
    ExRateSpread		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TACDailyExpPlan on KPX_TACDailyExpPlan(CompanySeq,BaseDate) 
end 


if object_id('KPX_TACDailyExpPlanLog') is null
begin 
CREATE TABLE KPX_TACDailyExpPlanLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    BegExRate		DECIMAL(19,5) 	 NOT NULL, 
    ExRateSpread		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 