if object_id('KPX_TSETieDisasterTake') is null
begin 
CREATE TABLE KPX_TSETieDisasterTake
(
    CompanySeq		INT 	 NOT NULL, 
    YYMM		NCHAR(6) 	 NOT NULL, 
    DisasterCount		DECIMAL(19,5) 	 NULL, 
    NonWkCount		DECIMAL(19,5) 	 NULL, 
    MMWorkCount		DECIMAL(19,5) 	 NULL, 
    YYWorkSUM		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 

)
create unique clustered index idx_KPX_TSETieDisasterTake on KPX_TSETieDisasterTake(CompanySeq,YYMM) 
end 

if object_id('KPX_TSETieDisasterTakeLog') is null
begin 
CREATE TABLE KPX_TSETieDisasterTakeLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    YYMM		NCHAR(6) 	 NOT NULL, 
    DisasterCount		DECIMAL(19,5) 	 NULL, 
    NonWkCount		DECIMAL(19,5) 	 NULL, 
    MMWorkCount		DECIMAL(19,5) 	 NULL, 
    YYWorkSUM		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 