if object_id('mnpt_TPJTUnionWagePrice') is null
begin 
    CREATE TABLE mnpt_TPJTUnionWagePrice
    (
        CompanySeq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTUnionWagePrice PRIMARY KEY CLUSTERED (CompanySeq ASC, StdSeq ASC)

    )
end 


if object_id('mnpt_TPJTUnionWagePriceLog') is null
begin 
    CREATE TABLE mnpt_TPJTUnionWagePriceLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTUnionWagePriceLog ON mnpt_TPJTUnionWagePriceLog (LogSeq)
end 