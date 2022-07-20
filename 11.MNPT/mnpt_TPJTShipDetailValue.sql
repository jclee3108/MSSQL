if object_id('mnpt_TPJTShipDetailValue') is null
begin 
    CREATE TABLE mnpt_TPJTShipDetailValue
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        TitleSeq		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipDetailValue PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC, ShipSerl ASC, TitleSeq ASC)

    )
end 

if object_id('mnpt_TPJTShipDetailValueLog') is null
begin 
    CREATE TABLE mnpt_TPJTShipDetailValueLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        TitleSeq		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTShipDetailValueLog ON mnpt_TPJTShipDetailValueLog (LogSeq)
end 




