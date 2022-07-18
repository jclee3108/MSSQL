if object_id('KPX_TPDMRPDaily') is null
begin 
CREATE TABLE KPX_TPDMRPDaily
(
    CompanySeq		INT 	 NOT NULL, 
    MRPDailySeq		INT 	 NOT NULL, 
    DateFr		NCHAR(8) 	 NOT NULL, 
    DateTo		NCHAR(8) 	 NOT NULL, 
    MRPNo		NVARCHAR(100) 	 NOT NULL, 
    SMInOutTypePur		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    PlanTime		NCHAR(4) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPDMRPDaily on KPX_TPDMRPDaily(CompanySeq,MRPDailySeq) 
end 

if object_id('KPX_TPDMRPDailyLog') is null
begin 
CREATE TABLE KPX_TPDMRPDailyLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    MRPDailySeq		INT 	 NOT NULL, 
    DateFr		NCHAR(8) 	 NOT NULL, 
    DateTo		NCHAR(8) 	 NOT NULL, 
    MRPNo		NVARCHAR(100) 	 NOT NULL, 
    SMInOutTypePur		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    PlanTime		NCHAR(4) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


