IF object_id('mnpt_TPJTEERentToolCalc') is null
begin 

    CREATE TABLE mnpt_TPJTEERentToolCalc
    (
        CompanySeq		INT 	 NOT NULL, 
        CalcSeq		INT 	 NOT NULL, 
        StdYM       NCHAR(6)    NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        RentCustSeq		INT 	 NOT NULL, 
        UMRentType		INT 	 NOT NULL, 
        UMRentKind		INT 	 NOT NULL, 
        RentToolSeq		INT 	 NOT NULL, 
        WorkDate		NCHAR(8) 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        Price		DECIMAL(19,5) 	 NOT NULL, 
        Amt		DECIMAL(19,5) 	 NOT NULL, 
        AddListName		NVARCHAR(200) 	 NOT NULL, 
        AddQty		DECIMAL(19,5) 	 NOT NULL, 
        AddPrice		DECIMAL(19,5) 	 NOT NULL, 
        AddAmt		DECIMAL(19,5) 	 NOT NULL, 
        RentAmt		DECIMAL(19,5) 	 NOT NULL, 
        RentVAT		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        ContractSeq INT NOT NULL, 
        ContractSerl    INT NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEERentToolCalc PRIMARY KEY CLUSTERED (CompanySeq ASC, CalcSeq ASC)

    )

end 

IF object_id('mnpt_TPJTEERentToolCalcLog') is null
begin 
    
    CREATE TABLE mnpt_TPJTEERentToolCalcLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CalcSeq		INT 	 NOT NULL, 
        StdYM       NCHAR(6)    NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        RentCustSeq		INT 	 NOT NULL, 
        UMRentType		INT 	 NOT NULL, 
        UMRentKind		INT 	 NOT NULL, 
        RentToolSeq		INT 	 NOT NULL, 
        WorkDate		NCHAR(8) 	 NOT NULL, 
        Qty		DECIMAL(19,5) 	 NOT NULL, 
        Price		DECIMAL(19,5) 	 NOT NULL, 
        Amt		DECIMAL(19,5) 	 NOT NULL, 
        AddListName		NVARCHAR(200) 	 NOT NULL, 
        AddQty		DECIMAL(19,5) 	 NOT NULL, 
        AddPrice		DECIMAL(19,5) 	 NOT NULL, 
        AddAmt		DECIMAL(19,5) 	 NOT NULL, 
        RentAmt		DECIMAL(19,5) 	 NOT NULL, 
        RentVAT		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        ContractSeq INT NOT NULL, 
        ContractSerl    INT NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEERentToolCalcLog ON mnpt_TPJTEERentToolCalcLog (LogSeq)
end 




