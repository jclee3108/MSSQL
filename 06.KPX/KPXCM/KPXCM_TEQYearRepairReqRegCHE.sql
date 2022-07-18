if object_id('KPXCM_TEQYearRepairReqRegCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReqRegCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    RepairSeq		INT 	 NOT NULL, 
    ReqDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQYearRepairReqRegCHE on KPXCM_TEQYearRepairReqRegCHE(CompanySeq,ReqSeq) 
end 

if object_id('KPXCM_TEQYearRepairReqRegCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReqRegCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    RepairSeq		INT 	 NOT NULL, 
    ReqDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 
