if object_id('mnpt_TPJTEECNTRReport') is null
begin 
    CREATE TABLE mnpt_TPJTEECNTRReport
    (
        CompanySeq		INT 	 NOT NULL, 
        CNTRReportSeq		INT 	 NOT NULL, 
        LINE		NVARCHAR(10) 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NOT NULL, 
        ShipYear		NVARCHAR(4) 	 NOT NULL, 
        SerlNo		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        IFItemCode		NVARCHAR(100) 	 NOT NULL, 
        DLS		NVARCHAR(10) 	 NOT NULL, 
        WorkSrtDateTime		NVARCHAR(12) 	 NOT NULL, 
        VLCD		NVARCHAR(10) 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        WorkEndDateTime		NVARCHAR(12) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEECNTRReport PRIMARY KEY CLUSTERED (CompanySeq ASC, CNTRReportSeq ASC)

    )
end 


if object_id('mnpt_TPJTEECNTRReportLog') is null
begin 
    CREATE TABLE mnpt_TPJTEECNTRReportLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CNTRReportSeq		INT 	 NOT NULL, 
        LINE		NVARCHAR(10) 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NOT NULL, 
        ShipYear		NVARCHAR(4) 	 NOT NULL, 
        SerlNo		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        ShipSerl		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        IFItemCode		NVARCHAR(100) 	 NOT NULL, 
        DLS		NVARCHAR(10) 	 NOT NULL, 
        WorkSrtDateTime		NVARCHAR(12) 	 NOT NULL, 
        VLCD		NVARCHAR(10) 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        WorkEndDateTime		NVARCHAR(12) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEECNTRReportLog ON mnpt_TPJTEECNTRReportLog (LogSeq)
end 