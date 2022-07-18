if object_id('KPX_TACFundDailyPlanOut') is null
begin 

CREATE TABLE KPX_TACFundDailyPlanOut
(
    CompanySeq		INT 	 NOT NULL, 
    PlanOutSeq		INT 	 NOT NULL, 
    FundDate		NCHAR(8) 	 NOT NULL, 
    Sort		INT 	 NOT NULL, 
    Summary		NVARCHAR(1000) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    SlipSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TACFundDailyPlanOut on KPX_TACFundDailyPlanOut(CompanySeq,PlanOutSeq) 
end 


if object_id('KPX_TACFundDailyPlanOutLog') is null
begin 
CREATE TABLE KPX_TACFundDailyPlanOutLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlanOutSeq		INT 	 NOT NULL, 
    FundDate		NCHAR(8) 	 NOT NULL, 
    Sort		INT 	 NOT NULL, 
    Summary		NVARCHAR(1000) 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    SlipSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 