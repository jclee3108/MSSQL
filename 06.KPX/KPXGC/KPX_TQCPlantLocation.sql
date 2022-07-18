if object_id('KPX_TQCPlantLocation') is null
begin 
CREATE TABLE KPX_TQCPlantLocation
(
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    LocationSeq		INT 	 NOT NULL, 
    LocationName		NVARCHAR(100) 	 NOT NULL, 
    Sort		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TQCPlantLocation on KPX_TQCPlantLocation(CompanySeq,PlantSeq,LocationSeq) 
end 

if object_id('KPX_TQCPlantLocationLog') is null
begin 
CREATE TABLE KPX_TQCPlantLocationLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PlantSeq		INT 	 NOT NULL, 
    LocationSeq		INT 	 NOT NULL, 
    LocationName		NVARCHAR(100) 	 NOT NULL, 
    Sort		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 