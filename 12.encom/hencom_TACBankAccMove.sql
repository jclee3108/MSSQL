if object_id('hencom_TACBankAccMove') is null
begin 

    CREATE TABLE hencom_TACBankAccMove
    (
        CompanySeq		INT 	 NOT NULL, 
        MoveSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NULL, 
        OutBankAccSeq		INT 	 NULL, 
        OutAmt		DECIMAL(19,5) 	 NULL, 
        InBankAccSeq		INT 	 NULL, 
        InAmt		DECIMAL(19,5) 	 NULL, 
        AddAmt		DECIMAL(19,5) 	 NULL, 
        DrAccSeq		INT 	 NULL, 
        CrAccSeq		INT 	 NULL, 
        AddAccSeq		INT 	 NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        SlipSeq     INT         NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACBankAccMove PRIMARY KEY CLUSTERED (CompanySeq ASC, MoveSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACBankAccMove ON hencom_TACBankAccMove(CompanySeq, MoveSeq)
end 

if object_id('hencom_TACBankAccMoveLog') is null
begin 

    CREATE TABLE hencom_TACBankAccMoveLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        MoveSeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NULL, 
        OutBankAccSeq		INT 	 NULL, 
        OutAmt		DECIMAL(19,5) 	 NULL, 
        InBankAccSeq		INT 	 NULL, 
        InAmt		DECIMAL(19,5) 	 NULL, 
        AddAmt		DECIMAL(19,5) 	 NULL, 
        DrAccSeq		INT 	 NULL, 
        CrAccSeq		INT 	 NULL, 
        AddAccSeq		INT 	 NULL, 
        Remark		NVARCHAR(2000) 	 NULL, 
        SlipSeq     INT         NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACBankAccMoveLog ON hencom_TACBankAccMoveLog (LogSeq)
end 



