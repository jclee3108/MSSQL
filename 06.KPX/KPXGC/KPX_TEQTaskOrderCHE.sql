if object_id('KPX_TEQTaskOrderCHE') is null
begin 
CREATE TABLE KPX_TEQTaskOrderCHE
(
    CompanySeq		INT 	 NOT NULL, 
    TaskOrderSeq		INT 	 NOT NULL, 
    TaskOrderDate		NCHAR(8) 	 NOT NULL, 
    ISPID		NCHAR(1) 	 NULL, 
    IsInstrument		NCHAR(1) 	 NULL, 
    IsField		NCHAR(1) 	 NULL, 
    IsPlot		NCHAR(1) 	 NULL, 
    IsDange		NCHAR(1) 	 NULL, 
    IsConce		NCHAR(1) 	 NULL, 
    IsISO		NCHAR(1) 	 NULL, 
    IsEquip		NCHAR(1) 	 NULL, 
    Etc		NVARCHAR(2000) 	 NULL, 
    IsTaskOrder		NCHAR(1) 	 NULL, 
    ChangePlan		NVARCHAR(200) 	 NULL, 
    TaskOrder		NVARCHAR(200) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TEQTaskOrderCHE on KPX_TEQTaskOrderCHE(CompanySeq,TaskOrderSeq) 
end 

if object_id('KPX_TEQTaskOrderCHELog') is null
begin 
CREATE TABLE KPX_TEQTaskOrderCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    TaskOrderSeq		INT 	 NOT NULL, 
    TaskOrderDate		NCHAR(8) 	 NOT NULL, 
    ISPID		NCHAR(1) 	 NULL, 
    IsInstrument		NCHAR(1) 	 NULL, 
    IsField		NCHAR(1) 	 NULL, 
    IsPlot		NCHAR(1) 	 NULL, 
    IsDange		NCHAR(1) 	 NULL, 
    IsConce		NCHAR(1) 	 NULL, 
    IsISO		NCHAR(1) 	 NULL, 
    IsEquip		NCHAR(1) 	 NULL, 
    Etc		NVARCHAR(2000) 	 NULL, 
    IsTaskOrder		NCHAR(1) 	 NULL, 
    ChangePlan		NVARCHAR(200) 	 NULL, 
    TaskOrder		NVARCHAR(200) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 