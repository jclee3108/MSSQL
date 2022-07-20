if object_id('mnpt_TPJTUnionWagePriceItem') is null
begin 
CREATE TABLE mnpt_TPJTUnionWagePriceItem
(
    CompanySeq		INT 	 NOT NULL, 
    StdSeq		INT 	 NOT NULL, 
    StdSerl		INT 	 NOT NULL, 
    PJTTypeSeq		INT 	 NOT NULL, 
    UMLoadWaySeq		INT 	 NOT NULL, 
    FirstUserSeq		INT 	 NOT NULL, 
    FirstDateTime		DATETIME 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL, 
CONSTRAINT PKmnpt_TPJTUnionWagePriceItem PRIMARY KEY CLUSTERED (CompanySeq ASC, StdSeq ASC, StdSerl ASC)

)
end 


if object_id('mnpt_TPJTUnionWagePriceItemLog') is null
begin 
    CREATE TABLE mnpt_TPJTUnionWagePriceItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        PJTTypeSeq		INT 	 NOT NULL, 
        UMLoadWaySeq		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTUnionWagePriceItemLog ON mnpt_TPJTUnionWagePriceItemLog (LogSeq)
end 