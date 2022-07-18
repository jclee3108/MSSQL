IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDSFCWorkLoss' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDSFCWorkLoss
        (
            CompanySeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            UMLossSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            StartTime		NCHAR(12) 	 NOT NULL, 
            EndTime		NCHAR(12) 	 NULL, 
            Remark		NVARCHAR(100) 	 NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKYW_TPDSFCWorkLoss PRIMARY KEY CLUSTERED (CompanySeq ASC, WorkCenterSeq ASC, UMLossSeq ASC, Serl ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDSFCWorkLossLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDSFCWorkLossLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            UMLossSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            StartTime		NCHAR(12) 	 NOT NULL, 
            EndTime		NCHAR(12) 	 NULL, 
            Remark		NVARCHAR(100) 	 NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL
        )
    CREATE UNIQUE  INDEX IDXTempYW_TPDSFCWorkLossLog ON YW_TPDSFCWorkLossLog (LogSeq)
    END
    
