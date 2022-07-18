if object_id('KPX_TACDailyExpPlanItem') is null
begin 

CREATE TABLE KPX_TACDailyExpPlanItem
(
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    UMExpPlanSeq		INT 	 NOT NULL, 
    UMBankSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)

create unique clustered index idx_KPX_TACDailyExpPlanItem on KPX_TACDailyExpPlanItem(CompanySeq,BaseDate,Serl) 
end 

if object_id('KPX_TACDailyExpPlanItemLog') is null
begin 
CREATE TABLE KPX_TACDailyExpPlanItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    UMExpPlanSeq		INT 	 NOT NULL, 
    UMBankSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 