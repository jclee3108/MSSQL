IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMBGPCostAdjStd' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TESMBGPCostAdjStd
        (
            CompanySeq		INT 	 NOT NULL, 
            CostYM		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            SMAccType		INT 	 NOT NULL, 
            AdjCCtrSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL, 
        CONSTRAINT PKDTI_TESMBGPCostAdjStd PRIMARY KEY CLUSTERED (CompanySeq ASC, CostYM ASC, CCtrSeq ASC, SMAccType ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMBGPCostAdjStdLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TESMBGPCostAdjStdLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            CostYM		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            SMAccType		INT 	 NOT NULL, 
            AdjCCtrSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
            PgmSeq		INT 	 NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TESMBGPCostAdjStdLog ON DTI_TESMBGPCostAdjStdLog (LogSeq)
    END