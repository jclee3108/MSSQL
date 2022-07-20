if object_id('mnpt_TPJTEERentToolContract') is null
begin 

    CREATE TABLE mnpt_TPJTEERentToolContract
    (
        CompanySeq		INT 	 NOT NULL, 
        ContractSeq		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        ContractDate		NCHAR(8) 	 NOT NULL, 
        ContractNo		NVARCHAR(200) 	 NOT NULL, 
        RentCustSeq		INT 	 NOT NULL, 
        RentSrtDate		NCHAR(8) 	 NOT NULL, 
        RentEndDate		NCHAR(8) 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEERentToolContract PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC)

    )
end 

if object_id('mnpt_TPJTEERentToolContractLog') is null
begin 

    CREATE TABLE mnpt_TPJTEERentToolContractLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ContractSeq		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        ContractDate		NCHAR(8) 	 NOT NULL, 
        ContractNo		NVARCHAR(200) 	 NOT NULL, 
        RentCustSeq		INT 	 NOT NULL, 
        RentSrtDate		NCHAR(8) 	 NOT NULL, 
        RentEndDate		NCHAR(8) 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEERentToolContractLog ON mnpt_TPJTEERentToolContractLog (LogSeq)
end 