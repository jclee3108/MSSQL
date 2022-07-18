if object_id('KPX_TQCPlantCycle') is null
begin
CREATE TABLE KPX_TQCPlantCycle
(
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    CycleSerl		INT 	 NOT NULL, 
    CycleTime		NVARCHAR(4) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TQCPlantCycle on KPX_TQCPlantCycle(CompanySeq,PlantSeq,CycleSerl) 
end 

if object_id('KPX_TQCPlantCycleLog') is null
begin 
CREATE TABLE KPX_TQCPlantCycleLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    CycleSerl		INT 	 NOT NULL, 
    CycleTime		NVARCHAR(4) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 