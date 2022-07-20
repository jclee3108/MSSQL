if object_id('mnpt_TPJTShipMaster') is null
begin 
    CREATE TABLE mnpt_TPJTShipMaster
    (
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NULL, 
        EnShipName		NVARCHAR(200) 	 NULL, 
        ShipName		NVARCHAR(200) 	 NULL, 
        LINECode		NVARCHAR(20) 	 NULL, 
        EnLINEName		NVARCHAR(200) 	 NULL, 
        LINEName		NVARCHAR(200) 	 NULL, 
        NationCode		NVARCHAR(20) 	 NULL, 
        NationName		NVARCHAR(200) 	 NULL, 
        CodeLetters		NVARCHAR(20) 	 NULL, 
        TotalTON		DECIMAL(19,5) 	 NULL, 
        LoadTON		DECIMAL(19,5) 	 NULL, 
        LOA		DECIMAL(19,5) 	 NULL, 
        Breadth		DECIMAL(19,5) 	 NULL, 
        DRAFT		DECIMAL(19,5) 	 NULL, 
        BULKCNTR		NVARCHAR(10) 	 NULL, 
        IsImagine		NCHAR(1) 	 NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        FirstUserSeq		INT 	 NULL, 
        FirstDateTime		DATETIME 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL, 
    CONSTRAINT PKmnpt_TPJTShipMaster PRIMARY KEY CLUSTERED (CompanySeq ASC, ShipSeq ASC)

    )
end 


if object_id('mnpt_TPJTShipMasterLog') is null
begin 
    CREATE TABLE mnpt_TPJTShipMasterLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ShipSeq		INT 	 NOT NULL, 
        IFShipCode		NVARCHAR(20) 	 NULL, 
        EnShipName		NVARCHAR(200) 	 NULL, 
        ShipName		NVARCHAR(200) 	 NULL, 
        LINECode		NVARCHAR(20) 	 NULL, 
        EnLINEName		NVARCHAR(200) 	 NULL, 
        LINEName		NVARCHAR(200) 	 NULL, 
        NationCode		NVARCHAR(20) 	 NULL, 
        NationName		NVARCHAR(200) 	 NULL, 
        CodeLetters		NVARCHAR(20) 	 NULL, 
        TotalTON		DECIMAL(19,5) 	 NULL, 
        LoadTON		DECIMAL(19,5) 	 NULL, 
        LOA		DECIMAL(19,5) 	 NULL, 
        Breadth		DECIMAL(19,5) 	 NULL, 
        DRAFT		DECIMAL(19,5) 	 NULL, 
        BULKCNTR		NVARCHAR(10) 	 NULL, 
        IsImagine		NCHAR(1) 	 NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        FirstUserSeq		INT 	 NULL, 
        FirstDateTime		DATETIME 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        PgmSeq		INT 	 NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTShipMasterLog ON mnpt_TPJTShipMasterLog (LogSeq)
end 



