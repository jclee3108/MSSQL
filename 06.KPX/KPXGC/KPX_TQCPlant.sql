if object_id('KPX_TQCPlant') is null
begin 
CREATE TABLE KPX_TQCPlant
(
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    PlantName		NVARCHAR(100) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TQCPlant on KPX_TQCPlant(CompanySeq,PlantSeq) 
end 

if object_id('KPX_TQCPlantLog') is null 
begin 
CREATE TABLE KPX_TQCPlantLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    PlantName		NVARCHAR(100) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 