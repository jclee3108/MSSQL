if object_id('mnpt_TPJTOperatorPriceMaster') is null
begin 

    CREATE TABLE mnpt_TPJTOperatorPriceMaster
    (
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTOperatorPriceMaster PRIMARY KEY CLUSTERED (Companyseq ASC, StdSeq ASC)

    )
end 


if object_id('mnpt_TPJTOperatorPriceMasterLog') is null
begin 

    CREATE TABLE mnpt_TPJTOperatorPriceMasterLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTOperatorPriceMasterLog ON mnpt_TPJTOperatorPriceMasterLog (LogSeq)
end 