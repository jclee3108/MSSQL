if object_id('hncom_TAdjWithHoldList') is null

begin 
    CREATE TABLE hncom_TAdjWithHoldList
    (
        CompanySeq		INT 	 NOT NULL, 
        AdjSeq          INT NOT NULL, 
        BizSeq		INT 	 NOT NULL, 
        StdYM		NCHAR(6) 	 NOT NULL, 
        EndDateFr		NCHAR(8) 	 NOT NULL, 
        EndDateTo		NCHAR(8) 	 NOT NULL, 
        EndDate         NCHAR(8) NOT NULL,
        UMTypeSeq		INT 	 NOT NULL, 
        EmpName		NVARCHAR(200) 	 NOT NULL, 
        EmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        TotAmt		DECIMAL(19,5) 	 NOT NULL, 
        TaxEmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        TaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        TaxShortageAmt		DECIMAL(19,5) 	 NOT NULL, 
        IncomeTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        ResidentTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        RuralTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        IsSum           NCHAR(1)        NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhncom_TAdjWithHoldList PRIMARY KEY CLUSTERED (CompanySeq ASC, AdjSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphncom_TAdjWithHoldList ON hncom_TAdjWithHoldList(CompanySeq, AdjSeq)
end 

if object_id('hncom_TAdjWithHoldListLog') is null

begin 
    CREATE TABLE hncom_TAdjWithHoldListLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        AdjSeq          INT NOT NULL,
        BizSeq		INT 	 NOT NULL, 
        StdYM		NCHAR(6) 	 NOT NULL, 
        EndDateFr		NCHAR(8) 	 NOT NULL, 
        EndDateTo		NCHAR(8) 	 NOT NULL, 
        EndDate         NCHAR(8) NOT NULL,
        UMTypeSeq		INT 	 NOT NULL, 
        EmpName		NVARCHAR(200) 	 NOT NULL, 
        EmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        TotAmt		DECIMAL(19,5) 	 NOT NULL, 
        TaxEmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        TaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        TaxShortageAmt		DECIMAL(19,5) 	 NOT NULL, 
        IncomeTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        ResidentTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        RuralTaxAmt		DECIMAL(19,5) 	 NOT NULL, 
        IsSum           NCHAR(1)        NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphncom_TAdjWithHoldListLog ON hncom_TAdjWithHoldListLog (LogSeq)
end 