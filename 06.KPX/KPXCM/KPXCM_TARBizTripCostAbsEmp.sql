if object_id('KPXCM_TARBizTripCostAbsEmp') is null
begin 
CREATE TABLE KPXCM_TARBizTripCostAbsEmp
(
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    AbsDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    WkItemSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TARBizTripCostAbsEmp on KPXCM_TARBizTripCostAbsEmp(CompanySeq,BizTripSeq,AbsDate,EmpSeq,WkItemSeq) 
end 

if object_id('KPXCM_TARBizTripCostAbsEmpLog') is null
begin 
CREATE TABLE KPXCM_TARBizTripCostAbsEmpLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    AbsDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    WkItemSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 