if object_id('mnpt_TPJTUnionWagePriceValue') is null
begin 
    CREATE TABLE mnpt_TPJTUnionWagePriceValue
    (
        CompanySeq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        TitleSeq		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTUnionWagePriceValue PRIMARY KEY CLUSTERED (CompanySeq ASC, StdSeq ASC, StdSerl ASC, TitleSeq ASC)

    )
end 


if object_id('mnpt_TPJTUnionWagePriceValueLog') is null
begin 
    CREATE TABLE mnpt_TPJTUnionWagePriceValueLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        TitleSeq		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTUnionWagePriceValueLog ON mnpt_TPJTUnionWagePriceValueLog (LogSeq)
end 