if object_id('KPX_TEQChangeRiskRstCHE') is null
begin
CREATE TABLE KPX_TEQChangeRiskRstCHE
(
    CompanySeq		INT 	 NOT NULL, 
    RiskRstSeq		INT 	 NOT NULL, 
    RiskRstDate		NCHAR(8) 	 NOT NULL, 
    UMMaterialChange		INT 	 NULL, 
    UMFlashPoint		INT 	 NULL, 
    UMPPM		INT 	 NULL, 
    UMMg		INT 	 NULL, 
    UMHeat		INT 	 NULL, 
    UMDriveUp		INT 	 NULL, 
    UMDriveDown		INT 	 NULL, 
    UMDrivePress		INT 	 NULL, 
    IsProdUp		NCHAR(1) 	 NULL, 
    IsChangeProd		NCHAR(1) 	 NULL, 
    IsFlare		NCHAR(1) 	 NULL, 
    UMChangeLevel		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TEQChangeRiskRstCHE on KPX_TEQChangeRiskRstCHE(CompanySeq,RiskRstSeq) 
end 

if object_id('KPX_TEQChangeRiskRstCHELog') is null 
begin 
CREATE TABLE KPX_TEQChangeRiskRstCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    RiskRstSeq		INT 	 NOT NULL, 
    RiskRstDate		NCHAR(8) 	 NOT NULL, 
    UMMaterialChange		INT 	 NULL, 
    UMFlashPoint		INT 	 NULL, 
    UMPPM		INT 	 NULL, 
    UMMg		INT 	 NULL, 
    UMHeat		INT 	 NULL, 
    UMDriveUp		INT 	 NULL, 
    UMDriveDown		INT 	 NULL, 
    UMDrivePress		INT 	 NULL, 
    IsProdUp		NCHAR(1) 	 NULL, 
    IsChangeProd		NCHAR(1) 	 NULL, 
    IsFlare		NCHAR(1) 	 NULL, 
    UMChangeLevel		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 