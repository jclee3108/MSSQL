if object_id('mnpt_TPJTOperatorPriceItem') is null
begin 
    CREATE TABLE mnpt_TPJTOperatorPriceItem
    (
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        UMToolType		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTOperatorPriceItem PRIMARY KEY CLUSTERED (Companyseq ASC, StdSeq ASC, StdSerl ASC)

    )
end 

if object_id('mnpt_TPJTOperatorPriceItemLog') is null
begin 
    CREATE TABLE mnpt_TPJTOperatorPriceItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        UMToolType		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTOperatorPriceItemLog ON mnpt_TPJTOperatorPriceItemLog (LogSeq)
end 