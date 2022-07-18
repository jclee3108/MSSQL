IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPUProdSalesTotalInfo' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPUProdSalesTotalInfo
        (
            CompanySeq		INT 	 NOT NULL, 
            OSPPOSeq		INT 	 NOT NULL, 
            OSPPOSerl		INT 	 NOT NULL, 
            InfoDate		NCHAR(8) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKYW_TPUProdSalesTotalInfo PRIMARY KEY CLUSTERED (CompanySeq ASC, OSPPOSeq ASC, OSPPOSerl ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TPUProdSalesTotalInfoLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE YW_TPUProdSalesTotalInfoLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            OSPPOSeq		INT 	 NOT NULL, 
            OSPPOSerl		INT 	 NOT NULL, 
            InfoDate		NCHAR(8) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )
        CREATE UNIQUE CLUSTERED INDEX IDXTempYW_TPUProdSalesTotalInfoLog ON YW_TPUProdSalesTotalInfoLog (LogSeq)
    END
