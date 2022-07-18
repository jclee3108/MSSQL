
if object_id('KPX_TDAUMajorMaster') is null 
begin 
CREATE TABLE KPX_TDAUMajorMaster
(
    CompanySeq		INT 	 NOT NULL, 
    UMajorSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TDAUMajorMaster on KPX_TDAUMajorMaster(CompanySeq,UMajorSeq) 
end 

if object_id('KPX_TDAUMajorMasterLog') is null 
begin 
CREATE TABLE KPX_TDAUMajorMasterLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    UMajorSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 
