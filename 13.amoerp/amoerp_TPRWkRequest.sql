IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'amoerp_TPRWkRequest' AND xtype = 'U' )
    BEGIN
        CREATE TABLE amoerp_TPRWkRequest
        (
            CompanySeq		INT 	 NOT NULL, 
            ReqSeq		INT 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WkItemSeq		INT 	 NOT NULL, 
            ReqDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            STime		NCHAR(4) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            ETime		NCHAR(4) 	 NOT NULL, 
            Remark		NVARCHAR(200) 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKamoerp_TPRWkRequest PRIMARY KEY CLUSTERED (CompanySeq ASC, ReqSeq ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'amoerp_TPRWkRequestLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE amoerp_TPRWkRequestLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ReqSeq		INT 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WkItemSeq		INT 	 NOT NULL, 
            ReqDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            STime		NCHAR(4) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            ETime		NCHAR(4) 	 NOT NULL, 
            Remark		NVARCHAR(200) 	 NOT NULL, 
            LastUserSeq		INT 	 NULL, 
            LastDateTime		DATETIME 	 NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempamoerp_TPRWkRequestLog ON amoerp_TPRWkRequestLog (LogSeq)
    END
