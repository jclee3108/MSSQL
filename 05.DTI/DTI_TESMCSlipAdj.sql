IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMCSlipAdj' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TESMCSlipAdj
        (
            CompanySeq		INT 	 NOT NULL, 
            CostUnit		INT 	 NOT NULL, 
            CostYM		NCHAR(6) 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            AccSeq		INT 	 NOT NULL, 
            UMCostType		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            DrAmt		DECIMAL(19,5) 	 NOT NULL, 
            CrAmt		DECIMAL(19,5) 	 NOT NULL, 
            Summary		NVARCHAR(1000) 	 NOT NULL, 
            OrgSlipSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL, 
        CONSTRAINT PKDTI_TESMCSlipAdj PRIMARY KEY CLUSTERED (CompanySeq ASC, CostUnit ASC, CostYM ASC, Serl ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMCSlipAdjLog' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TESMCSlipAdjLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            CostUnit		INT 	 NOT NULL, 
            CostYM		NCHAR(6) 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            AccSeq		INT 	 NOT NULL, 
            UMCostType		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            DrAmt		DECIMAL(19,5) 	 NOT NULL, 
            CrAmt		DECIMAL(19,5) 	 NOT NULL, 
            Summary		NVARCHAR(1000) 	 NOT NULL, 
            OrgSlipSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL
        )
        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TESMCSlipAdjLog ON DTI_TESMCSlipAdjLog (LogSeq)
    END