if object_id('KPX_TPDMRPMonth') is null
begin 
CREATE TABLE KPX_TPDMRPMonth
(
    CompanySeq		INT 	 NOT NULL, 
    MRPMonthSeq		INT 	 NOT NULL, 
    ProdPlanYM		NCHAR(6) 	 NOT NULL, 
    MRPNo		NVARCHAR(100) 	 NOT NULL, 
    SMInOutTypePur		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    PlanTime		NCHAR(4) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TPDMRPMonth on KPX_TPDMRPMonth(CompanySeq,MRPMonthSeq) 
end 

if object_id('KPX_TPDMRPMonthLog') is null
begin 
CREATE TABLE KPX_TPDMRPMonthLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    MRPMonthSeq		INT 	 NOT NULL, 
    ProdPlanYM		NCHAR(6) 	 NOT NULL, 
    MRPNo		NVARCHAR(100) 	 NOT NULL, 
    SMInOutTypePur		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    PlanTime		NCHAR(4) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


