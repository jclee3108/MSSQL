IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDSFCWorkStart' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDSFCWorkStart
        (
            CompanySeq		INT 	 NOT NULL, 
            WorkOrderSeq		INT 	 NOT NULL, 
            WorkOrderSerl		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WorkReportSeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            StartTime		NCHAR(12) 	 NOT NULL, 
            EndTime		NCHAR(12) 	 NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKYW_TPDSFCWorkStart PRIMARY KEY CLUSTERED (CompanySeq ASC, WorkOrderSeq ASC, WorkOrderSerl ASC, Serl ASC, EmpSeq ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDSFCWorkStartLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDSFCWorkStartLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            WorkOrderSeq		INT 	 NOT NULL, 
            WorkOrderSerl		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WorkReportSeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            StartTime		NCHAR(12) 	 NOT NULL, 
            EndTime		NCHAR(12) 	 NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL
        )

        CREATE UNIQUE  INDEX IDXTempYW_TPDSFCWorkStartLog ON YW_TPDSFCWorkStartLog (LogSeq)
    END