IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'amoerp_TPRWkRequest_Confirm' AND xtype = 'U' )
    BEGIN
        CREATE TABLE amoerp_TPRWkRequest_Confirm
        (
            CompanySeq		INT 	 NOT NULL, 
            CfmSeq		INT 	 NOT NULL, 
            CfmSerl		INT 	 NOT NULL, 
            CfmSubSerl		INT 	 NOT NULL, 
            CfmSecuSeq		INT 	 NULL, 
            IsAuto		NCHAR(1) 	 NULL, 
            CfmCode		INT 	 NULL, 
            CfmDate		NCHAR(8) 	 NULL, 
            CfmEmpSeq		INT 	 NULL, 
            UMCfmReason		INT 	 NULL, 
            CfmReason		NVARCHAR(500) 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKamoerp_TPRWkRequest_Confirm PRIMARY KEY CLUSTERED (CompanySeq ASC, CfmSeq ASC, CfmSerl ASC, CfmSubSerl ASC)
        )

    END
    
IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'amoerp_TPRWkRequest_ConfirmLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE amoerp_TPRWkRequest_ConfirmLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            CfmSeq		INT 	 NOT NULL, 
            CfmSerl		INT 	 NOT NULL, 
            CfmSubSerl		INT 	 NOT NULL, 
            CfmSecuSeq		INT 	 NULL, 
            IsAuto		NCHAR(1) 	 NULL, 
            CfmCode		INT 	 NULL, 
            CfmDate		NCHAR(8) 	 NULL, 
            CfmEmpSeq		INT 	 NULL, 
            UMCfmReason		INT 	 NULL, 
            CfmReason		NVARCHAR(500) 	 NULL, 
            LastDateTime		DATETIME 	 NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempamoerp_TPRWkRequest_ConfirmLog ON amoerp_TPRWkRequest_ConfirmLog (LogSeq)
    END
