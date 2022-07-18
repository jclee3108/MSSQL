IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDWorkCenterEmp' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDWorkCenterEmp
        (
            CompanySeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKYW_TPDWorkCenterEmp PRIMARY KEY CLUSTERED (CompanySeq ASC, WorkCenterSeq ASC, EmpSeq ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPDWorkCenterEmpLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPDWorkCenterEmpLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            WorkCenterSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL
        )

        CREATE UNIQUE  INDEX IDXTempYW_TPDWorkCenterEmpLog ON YW_TPDWorkCenterEmpLog (LogSeq)
    END