if object_id('KPX_THREduRstWithCost') is null 
begin 
CREATE TABLE KPX_THREduRstWithCost
(
    CompanySeq		INT 	 NOT NULL, 
    RstSeq		INT 	 NOT NULL, 
    IsEI		NCHAR(1) 	 NULL, 
    SMComplate		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THREduRstWithCost on KPX_THREduRstWithCost(CompanySeq,RstSeq) 
end 


if object_id('KPX_THREduRstWithCostLog') is null 
begin 
CREATE TABLE KPX_THREduRstWithCostLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    RstSeq		INT 	 NOT NULL, 
    IsEI		NCHAR(1) 	 NULL, 
    SMComplate		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 