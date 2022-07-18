if object_id('KPX_TPDItemWCStd') is null 
begin 
CREATE TABLE KPX_TPDItemWCStd
(
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    WorkCenterSeq		INT 	 NOT NULL, 
    ProcSeq		INT 	 NOT NULL, 
    StdProdTime		INT 	 NULL, 
    WCCapacity		DECIMAL(19,5) 	 NULL, 
    Gravity		DECIMAL(19,5) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
)
create unique clustered index idx_KPX_TPDItemWCStd on KPX_TPDItemWCStd(CompanySeq,ItemSeq,WorkCenterSeq,ProcSeq) 
end 


if object_id('KPX_TPDItemWCStdLog') is null 
begin 
CREATE TABLE KPX_TPDItemWCStdLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    WorkCenterSeq		INT 	 NOT NULL, 
    ProcSeq		INT 	 NOT NULL, 
    StdProdTime		INT 	 NULL, 
    WCCapacity		DECIMAL(19,5) 	 NULL, 
    Gravity		DECIMAL(19,5) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 