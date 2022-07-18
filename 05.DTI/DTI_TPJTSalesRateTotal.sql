IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesRateTotal' AND xtype = 'U' )
    begin
        CREATE TABLE DTI_TPJTSalesRateTotal
        (
            CompanySeq		INT 	 NOT NULL, 
            PJTSeq		INT 	 NOT NULL, 
            ResultYM		NCHAR(6) 	 NOT NULL, 
            SMItemType		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesCost		DECIMAL(19,5) 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL, 
        CONSTRAINT PKDTI_TPJTSalesRateTotal PRIMARY KEY CLUSTERED (CompanySeq ASC, PJTSeq ASC, ResultYM ASC, SMItemType ASC, ItemSeq ASC, Serl ASC)

        )
    end


IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesRateTotalLog' AND xtype = 'U' )
    begin 

        CREATE TABLE DTI_TPJTSalesRateTotalLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            PJTSeq		INT 	 NOT NULL, 
            ResultYM		NCHAR(6) 	 NOT NULL, 
            SMItemType		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesCost		DECIMAL(19,5) 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TPJTSalesRateTotalLog ON DTI_TPJTSalesRateTotalLog (LogSeq)
end
