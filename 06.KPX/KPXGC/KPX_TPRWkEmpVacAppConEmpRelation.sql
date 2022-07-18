if object_id('KPX_TPRWkEmpVacAppConEmpRelation') is null
begin 
CREATE TABLE KPX_TPRWkEmpVacAppConEmpRelation
(
    CompanySeq		INT 	 NOT NULL, 
    VacEmpSeq		INT 	 NOT NULL, 
    VacSeq		INT 	 NOT NULL, 
    ConEmpSeq		INT 	 NOT NULL, 
    ConSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TPRWkEmpVacAppConEmpRelation on KPX_TPRWkEmpVacAppConEmpRelation(CompanySeq,VacEmpSeq,VacSeq,ConEmpSeq,ConSeq) 
end 


if object_id('KPX_TPRWkEmpVacAppConEmpRelationLog') is null
begin 
CREATE TABLE KPX_TPRWkEmpVacAppConEmpRelationLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    VacEmpSeq		INT 	 NOT NULL, 
    VacSeq		INT 	 NOT NULL, 
    ConEmpSeq		INT 	 NOT NULL, 
    ConSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 