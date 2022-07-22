IF OBJECT_ID('hencom_TPNPLMatItemConvfactor') IS NULL 
begin 

    CREATE TABLE hencom_TPNPLMatItemConvfactor
    (
        CompanySeq		INT 	 NOT NULL, 
        CFSeq		INT 	 NOT NULL, 
        StdYear		NCHAR(4) 	 NULL, 
        DeptSeq		INT 	 NULL, 
        ItemSeq		INT 	 NULL, 
        ConvFactor		DECIMAL(19,5) 	 NULL, 
        Remark      NVARCHAR(2000) NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL, 
    CONSTRAINT TPKhencom_TPNPLMatItemConvfactor PRIMARY KEY CLUSTERED (CompanySeq ASC, CFSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TPNPLMatItemConvfactor ON hencom_TPNPLMatItemConvfactor(CompanySeq, CFSeq)
end 



IF OBJECT_ID('hencom_TPNPLMatItemConvfactorLog') IS NULL 
begin 
    CREATE TABLE hencom_TPNPLMatItemConvfactorLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CFSeq		INT 	 NOT NULL, 
        StdYear		NCHAR(4) 	 NULL, 
        DeptSeq		INT 	 NULL, 
        ItemSeq		INT 	 NULL, 
        ConvFactor		DECIMAL(19,5) 	 NULL, 
        Remark      NVARCHAR(2000) NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TPNPLMatItemConvfactorLog ON hencom_TPNPLMatItemConvfactorLog (LogSeq)
end 