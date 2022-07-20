if object_id('mnpt_TPJTEERentToolContractItem') is null
begin 
    CREATE TABLE mnpt_TPJTEERentToolContractItem
    (
        CompanySeq		INT 	 NOT NULL, 
        ContractSeq		INT 	 NOT NULL, 
        ContractSerl		INT 	 NOT NULL, 
        UMRentKind		INT 	 NOT NULL, 
        RentToolSeq		INT 	 NOT NULL, 
        TextRentToolName    NVARCHAR(200) NOT NULL, 
        UMRentType		INT 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        Price		DECIMAL(19,5) 	 NOT NULL, 
        Amt		DECIMAL(19,5) 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEERentToolContractItem PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC, ContractSerl ASC)

    )
end 

if object_id('mnpt_TPJTEERentToolContractItemLog') is null
begin 
    CREATE TABLE mnpt_TPJTEERentToolContractItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ContractSeq		INT 	 NOT NULL, 
        ContractSerl		INT 	 NOT NULL, 
        UMRentKind		INT 	 NOT NULL, 
        RentToolSeq		INT 	 NOT NULL, 
        TextRentToolName    NVARCHAR(200) NOT NULL, 
        UMRentType		INT 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        Price		DECIMAL(19,5) 	 NOT NULL, 
        Amt		DECIMAL(19,5) 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEERentToolContractItemLog ON mnpt_TPJTEERentToolContractItemLog (LogSeq)
end 


