if object_id('KPXCM_TEQYearRepairRltManHourCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairRltManHourCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultSerl		INT 	 NOT NULL, 
    ResultSubSerl		INT 	 NOT NULL, 
    DivSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    WorkOperSerl		INT 	 NOT NULL, 
    ManHour		DECIMAL(19,5) 	 NOT NULL, 
    OTManHour		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TEQYearRepairRltManHourCHE on KPXCM_TEQYearRepairRltManHourCHE(CompanySeq,ResultSeq,ResultSerl,ResultSubSerl) 
end 

if object_id('KPXCM_TEQYearRepairRltManHourCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairRltManHourCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ResultSeq		INT 	 NOT NULL, 
    ResultSerl		INT 	 NOT NULL, 
    ResultSubSerl		INT 	 NOT NULL, 
    DivSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    WorkOperSerl		INT 	 NOT NULL, 
    ManHour		DECIMAL(19,5) 	 NOT NULL, 
    OTManHour		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 