if object_id('mnpt_TPJTEECNTRReport_IF') is null
begin 
    CREATE TABLE mnpt_TPJTEECNTRReport_IF
    (
        CompanySeq		INT 	 NOT NULL, 
        CNTRReportSeq		INT 	 NOT NULL, 
        LINE		NVARCHAR(10) 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NOT NULL, 
        ShipYear		NVARCHAR(10) 	 NOT NULL, 
        SerlNo		NVARCHAR(4) 	 NOT NULL, 
        IFItemCode		INT 	 NOT NULL, 
        DLS		NVARCHAR(10) 	 NOT NULL, 
        WorkSrtDateTime		NVARCHAR(12) 	 NOT NULL, 
        VLCD		NVARCHAR(10) 	 NOT NULL, 
        LastWorkTime		NVARCHAR(14) 	 NOT NULL, 
        ErrMessage		NVARCHAR(200) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEECNTRReport_IF PRIMARY KEY CLUSTERED (CompanySeq ASC, CNTRReportSeq ASC)

    )
end 

if object_id('mnpt_TPJTEECNTRReport_IFLog') is null
begin 
    CREATE TABLE mnpt_TPJTEECNTRReport_IFLog
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
        ShipYear		NVARCHAR(10) 	 NOT NULL, 
        SerlNo		NVARCHAR(4) 	 NOT NULL, 
        IFItemCode		INT 	 NOT NULL, 
        DLS		NVARCHAR(10) 	 NOT NULL, 
        WorkSrtDateTime		NVARCHAR(12) 	 NOT NULL, 
        VLCD		NVARCHAR(10) 	 NOT NULL, 
        LastWorkTime		NVARCHAR(14) 	 NOT NULL, 
        ErrMessage		NVARCHAR(200) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEECNTRReport_IFLog ON mnpt_TPJTEECNTRReport_IFLog (LogSeq)
end 
