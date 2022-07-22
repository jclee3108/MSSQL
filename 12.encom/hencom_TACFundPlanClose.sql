if object_id('hencom_TACFundPlanClose') is null
begin 

    CREATE TABLE hencom_TACFundPlanClose
    (
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Check1		NCHAR(1) 	 NOT NULL, 
        Check2		NCHAR(1) 	 NOT NULL, 
        Check3		NCHAR(1) 	 NOT NULL, 
        Check4		NCHAR(1) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACFundPlanClose PRIMARY KEY CLUSTERED (CompanySeq ASC, StdDate ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACFundPlanClose ON hencom_TACFundPlanClose(CompanySeq, StdDate)
end 

if object_id('hencom_TACFundPlanCloseLog') is null
begin 
    CREATE TABLE hencom_TACFundPlanCloseLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Check1		NCHAR(1) 	 NOT NULL, 
        Check2		NCHAR(1) 	 NOT NULL, 
        Check3		NCHAR(1) 	 NOT NULL, 
        Check4		NCHAR(1) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACFundPlanCloseLog ON hencom_TACFundPlanCloseLog (LogSeq)
end 