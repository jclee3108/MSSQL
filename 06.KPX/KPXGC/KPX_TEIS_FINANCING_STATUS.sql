if object_id('KPX_TEIS_FINANCING_STATUS') is null 
begin 
CREATE TABLE KPX_TEIS_FINANCING_STATUS
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMSupply		INT 	 NOT NULL, 
    ResultUpAmt		DECIMAL(19,5) 	 NULL, 
    ResultDownAmt		DECIMAL(19,5) 	 NULL, 
    PlanUpAmt		DECIMAL(19,5) 	 NULL, 
    PlanDownAmt		DECIMAL(19,5) 	 NULL, 
    AmtRate		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TEIS_FINANCING_STATUS on KPX_TEIS_FINANCING_STATUS(CompanySeq,BizUnit,PlanYM,UMSupply) 
end 



if object_id('KPX_TEIS_FINANCING_STATUSLog') is null 
begin 
CREATE TABLE KPX_TEIS_FINANCING_STATUSLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMSupply		INT 	 NOT NULL, 
    ResultUpAmt		DECIMAL(19,5) 	 NULL, 
    ResultDownAmt		DECIMAL(19,5) 	 NULL, 
    PlanUpAmt		DECIMAL(19,5) 	 NULL, 
    PlanDownAmt		DECIMAL(19,5) 	 NULL, 
    AmtRate		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 