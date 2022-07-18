if object_id('KPX_TEIS_DEBT_STATUS') is null 
begin 
CREATE TABLE KPX_TEIS_DEBT_STATUS
(
    CompanySeq		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMDEBTItem		INT 	 NOT NULL, 
    ActPlusAmt		DECIMAL(19,5) 	 NULL, 
    ActMinusAmt		DECIMAL(19,5) 	 NULL, 
    PlanRestAmt		DECIMAL(19,5) 	 NULL, 
    PlanPlusAmt		DECIMAL(19,5) 	 NULL, 
    PlanMinusAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TEIS_DEBT_STATUS on KPX_TEIS_DEBT_STATUS(CompanySeq,PlanYM,UMDEBTItem) 
end 


if object_id('KPX_TEIS_DEBT_STATUSLog') is null 
begin 
CREATE TABLE KPX_TEIS_DEBT_STATUSLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMDEBTItem		INT 	 NOT NULL, 
    ActPlusAmt		DECIMAL(19,5) 	 NULL, 
    ActMinusAmt		DECIMAL(19,5) 	 NULL, 
    PlanRestAmt		DECIMAL(19,5) 	 NULL, 
    PlanPlusAmt		DECIMAL(19,5) 	 NULL, 
    PlanMinusAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 