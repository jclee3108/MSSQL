if object_id('KPX_TACDailyExpPlanExRate') is null
begin 

CREATE TABLE KPX_TACDailyExpPlanExRate
(
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    UMBankSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    ListExRate		DECIMAL(19,5) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL

)
create unique clustered index idx_KPX_TACDailyExpPlanExRate on KPX_TACDailyExpPlanExRate(CompanySeq,BaseDate,Serl) 
end 

if object_id('KPX_TACDailyExpPlanExRateLog') is null
begin 
CREATE TABLE KPX_TACDailyExpPlanExRateLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    UMBankSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    ListExRate		DECIMAL(19,5) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 