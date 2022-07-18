if object_id('KPX_THRWelMediItem') is null 
begin 
CREATE TABLE KPX_THRWelMediItem
(
    CompanySeq		INT 	 NOT NULL, 
    WelMediSeq		INT 	 NOT NULL, 
    WelMediSerl		INT 	 NOT NULL, 
    FamilyName		NVARCHAR(100) NOT NULL, 
    UMRelSeq		INT 	 NOT NULL, 
    MedicalName		NVARCHAR(100) 	 NOT NULL, 
    BegDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    MediAmt		DECIMAL(19,5) 	 NULL, 
    NonPayAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THRWelMediItem on KPX_THRWelMediItem(CompanySeq,WelMediSeq,WelMediSerl) 
end 

if object_id('KPX_THRWelMediItemLog') is null 
begin 
CREATE TABLE KPX_THRWelMediItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WelMediSeq		INT 	 NOT NULL, 
    WelMediSerl		INT 	 NOT NULL, 
    FamilyName		NVARCHAR(100) 	 NOT NULL, 
    UMRelSeq		INT 	 NOT NULL, 
    MedicalName		NVARCHAR(100) 	 NOT NULL, 
    BegDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    MediAmt		DECIMAL(19,5) 	 NULL, 
    NonPayAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 

