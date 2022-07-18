IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLInterTransferPJT' AND xtype = 'U' )
begin 
    CREATE TABLE DTI_TSLInterTransferPJT
    (
        CompanySeq		INT 	 NOT NULL, 
        InputYM		NCHAR(6) 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        ResourceSeq		INT 	 NOT NULL, 
        StdYM		NVARCHAR(6) 	 NOT NULL, 
        ReceiptDeptSeq		INT 	 NOT NULL, 
        SendDeptSeq		INT 	 NOT NULL, 
        SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
        GPAmt		DECIMAL(19,5) 	 NOT NULL, 
        OwnershipGPAmt		DECIMAL(19,5) 	 NOT NULL, 
        PJTProcRate		DECIMAL(19,5) 	 NOT NULL, 
        PreInterBillingAmt		DECIMAL(19,5) 	 NOT NULL, 
        InterBillingAmt		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
    CONSTRAINT PKDTI_TSLInterTransferPJT PRIMARY KEY CLUSTERED (CompanySeq ASC, InputYM ASC, PJTSeq ASC, ResourceSeq ASC, StdYM ASC)
    )
end

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLInterTransferPJTLog' AND xtype = 'U' )
begin
    CREATE TABLE DTI_TSLInterTransferPJTLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        InputYM		NCHAR(6) 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        ResourceSeq		INT 	 NOT NULL, 
        StdYM		NVARCHAR(6) 	 NOT NULL, 
        ReceiptDeptSeq		INT 	 NOT NULL, 
        SendDeptSeq		INT 	 NOT NULL, 
        SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
        GPAmt		DECIMAL(19,5) 	 NOT NULL, 
        OwnershipGPAmt		DECIMAL(19,5) 	 NOT NULL, 
        PJTProcRate		DECIMAL(19,5) 	 NOT NULL, 
        PreInterBillingAmt		DECIMAL(19,5) 	 NOT NULL, 
        InterBillingAmt		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLInterTransferPJTLog ON DTI_TSLInterTransferPJTLog (LogSeq)
end