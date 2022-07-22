if object_id('hencom_TSLDeposit') is null

begin 

    CREATE TABLE hencom_TSLDeposit
    (
        CompanySeq		INT 	 NOT NULL, 
        DepositSeq		INT 	 NOT NULL, 
        DepositNo		NVARCHAR(200) 	 NOT NULL, 
        DepositDate		NCHAR(8) 	 NOT NULL, 
        DepositAmt		DECIMAL(19,5) 	 NOT NULL, 
        InterestAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReturnDate		NCHAR(8) 	 NOT NULL, 
        DepositAccSeq		INT 	 NOT NULL, 
        InterestAccSeq		INT 	 NOT NULL, 
        TotAccSeq		INT 	 NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TSLDeposit PRIMARY KEY CLUSTERED (CompanySeq ASC, DepositSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TSLDeposit ON hencom_TSLDeposit(CompanySeq, DepositSeq)
end 


if object_id('hencom_TSLDepositLog') is null
begin 

    CREATE TABLE hencom_TSLDepositLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        DepositSeq		INT 	 NOT NULL, 
        DepositNo		NVARCHAR(200) 	 NOT NULL, 
        DepositDate		NCHAR(8) 	 NOT NULL, 
        DepositAmt		DECIMAL(19,5) 	 NOT NULL, 
        InterestAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReturnDate		NCHAR(8) 	 NOT NULL, 
        DepositAccSeq		INT 	 NOT NULL, 
        InterestAccSeq		INT 	 NOT NULL, 
        TotAccSeq		INT 	 NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TSLDepositLog ON hencom_TSLDepositLog (LogSeq)
end 