IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TCOMEnvContractEmp' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TCOMEnvContractEmp
        (
            CompanySeq		INT 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TCOMEnvContractEmp PRIMARY KEY CLUSTERED (CompanySeq ASC, DeptSeq ASC, EmpSeq ASC)
        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TCOMEnvContractEmpLog' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TCOMEnvContractEmpLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TCOMEnvContractEmpLog ON DTI_TCOMEnvContractEmpLog (LogSeq) 
    END 