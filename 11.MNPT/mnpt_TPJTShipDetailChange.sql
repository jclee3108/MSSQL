if object_id('mnpt_TPJTShipDetailChange') is null
begin 
    CREATE TABLE mnpt_TPJTShipDetailChange
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        ShipSubSerl		INT 	 NOT NULL, 
        ApproachDate		NCHAR(8) 	 NULL, 
        ApproachTime		NCHAR(4) 	 NULL, 
        ChangeDate		NCHAR(8) 	 NULL, 
        ChangeTime		NCHAR(4) 	 NULL, 
        DiffApproachTime		DECIMAL(19,5) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTShipDetailChange PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC, ShipSerl ASC, ShipSubSerl ASC)

    )
end 


if object_id('mnpt_TPJTShipDetailChangeLog') is null
begin
    CREATE TABLE mnpt_TPJTShipDetailChangeLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        ShipSubSerl		INT 	 NOT NULL, 
        ApproachDate		NCHAR(8) 	 NULL, 
        ApproachTime		NCHAR(4) 	 NULL, 
        ChangeDate		NCHAR(8) 	 NULL, 
        ChangeTime		NCHAR(4) 	 NULL, 
        DiffApproachTime		DECIMAL(19,5) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTShipDetailChangeLog ON mnpt_TPJTShipDetailChangeLog (LogSeq)
end 