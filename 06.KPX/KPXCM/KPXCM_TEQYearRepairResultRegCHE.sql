if object_id('KPXCM_TEQYearRepairResultRegCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairResultRegCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQYearRepairResultRegCHE on KPXCM_TEQYearRepairResultRegCHE(CompanySeq,ResultSeq) 
end 



if object_id('KPXCM_TEQYearRepairResultRegCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairResultRegCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 
