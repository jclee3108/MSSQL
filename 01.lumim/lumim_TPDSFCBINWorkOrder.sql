IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'lumim_TPDSFCBINWorkOrder' AND xtype = 'U' )
    BEGIN
        CREATE TABLE lumim_TPDSFCBINWorkOrder
        (
            CompanySeq		INT 	 NOT NULL, 
            BINWorkOrderSeq		INT 	 NOT NULL, 
            BINWorkOrderNo		NVARCHAR(100) 	 NOT NULL, 
            ProdPlanSeq		INT 	 NOT NULL, 
            THTool		NVARCHAR(50) 	 NOT NULL, 
            BINNo		NVARCHAR(5) 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKlumim_TPDSFCBINWorkOrder PRIMARY KEY CLUSTERED (CompanySeq ASC, BINWorkOrderSeq ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'lumim_TPDSFCBINWorkOrderLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE lumim_TPDSFCBINWorkOrderLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            BINWorkOrderSeq		INT 	 NOT NULL, 
            BINWorkOrderNo		NVARCHAR(100) 	 NOT NULL, 
            ProdPlanSeq		INT 	 NOT NULL, 
            THTool		NVARCHAR(50) 	 NOT NULL, 
            BINNo		NVARCHAR(5) 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE  INDEX IDXTemplumim_TPDSFCBINWorkOrderLog ON lumim_TPDSFCBINWorkOrderLog (LogSeq)
    END