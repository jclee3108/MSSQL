if object_id('KPX_THRWorkEmpDaily') is null
begin 
CREATE TABLE KPX_THRWorkEmpDaily
(
    CompanySeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    WorkDate		NCHAR(8) 	 NOT NULL, 
    UMWorkCenterSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THRWorkEmpDaily on KPX_THRWorkEmpDaily(CompanySeq,Serl) 
end 


if object_id('KPX_THRWorkEmpDailyLog') is null
begin 
CREATE TABLE KPX_THRWorkEmpDailyLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    WorkDate		NCHAR(8) 	 NOT NULL, 
    UMWorkCenterSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
 )
 end 
 
 
 