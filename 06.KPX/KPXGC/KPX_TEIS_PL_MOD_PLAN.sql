if object_id('KPX_TEIS_PL_MOD_PLAN') is null 
begin 
CREATE TABLE KPX_TEIS_PL_MOD_PLAN
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    AccSeq		INT 	 NOT NULL, 
    ModAmt		DECIMAL(19,5) 	 NULL, 
    EstAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TEIS_PL_MOD_PLAN on KPX_TEIS_PL_MOD_PLAN(CompanySeq,BizUnit,PlanYM,AccSeq) 
end 

if object_id('KPX_TEIS_PL_MOD_PLANLog') is null 
begin 
CREATE TABLE KPX_TEIS_PL_MOD_PLANLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    AccSeq		INT 	 NOT NULL, 
    ModAmt		DECIMAL(19,5) 	 NULL, 
    EstAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 
