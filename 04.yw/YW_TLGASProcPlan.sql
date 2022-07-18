IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TLGASProcPlan' AND xtype = 'U' )

    BEGIN
        CREATE TABLE YW_TLGASProcPlan
        (
            CompanySeq		INT 	 NOT NULL, 
            ASRegSeq		INT 	 NOT NULL, 
            UMLastDecision		INT 	 NOT NULL, 
            UMLotMagnitude		INT 	 NOT NULL, 
            UMBadMagnitude		INT 	 NOT NULL, 
            UMMkind		INT 	 NOT NULL, 
            UMMtype		INT 	 NOT NULL, 
            UMIsEnd		INT 	 NOT NULL, 
            UMProbleSubItem		INT 	 NOT NULL, 
            UMProbleSemiItem		INT 	 NOT NULL, 
            UMBadType		INT 	 NOT NULL, 
            UMBadLKind		INT 	 NOT NULL, 
            UMBadMKind		INT 	 NOT NULL, 
            UMResponsType		INT 	 NOT NULL, 
            ResponsProc		NVARCHAR(100) 	 NOT NULL, 
            ResponsDept		NVARCHAR(100) 	 NOT NULL, 
            ProcDept		INT 	 NOT NULL, 
            ProbleCause		NVARCHAR(200) 	 NOT NULL, 
            ImsiProc		NVARCHAR(200) 	 NOT NULL, 
            ImsiEmp		INT 	 NOT NULL, 
            ImsiDate		NVARCHAR(200) 	 NOT NULL, 
            RootProc		NVARCHAR(200) 	 NOT NULL, 
            RootEmp		INT 	 NOT NULL, 
            RootDate		NVARCHAR(200) 	 NOT NULL, 
            EndDate		NCHAR(8) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKYW_TLGASProcPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, ASRegSeq ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'YW_TLGASProcPlanLog' AND xtype = 'U' )

    BEGIN
        CREATE TABLE YW_TLGASProcPlanLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ASRegSeq		INT 	 NOT NULL, 
            UMLastDecision		INT 	 NOT NULL, 
            UMLotMagnitude		INT 	 NOT NULL, 
            UMBadMagnitude		INT 	 NOT NULL, 
            UMMkind		INT 	 NOT NULL, 
            UMMtype		INT 	 NOT NULL, 
            UMIsEnd		INT 	 NOT NULL, 
            UMProbleSubItem		INT 	 NOT NULL, 
            UMProbleSemiItem		INT 	 NOT NULL, 
            UMBadType		INT 	 NOT NULL, 
            UMBadLKind		INT 	 NOT NULL, 
            UMBadMKind		INT 	 NOT NULL, 
            UMResponsType		INT 	 NOT NULL, 
            ResponsProc		NVARCHAR(100) 	 NOT NULL, 
            ResponsDept		NVARCHAR(100) 	 NOT NULL, 
            ProcDept		INT 	 NOT NULL, 
            ProbleCause		NVARCHAR(200) 	 NOT NULL, 
            ImsiProc		NVARCHAR(200) 	 NOT NULL, 
            ImsiEmp		INT 	 NOT NULL, 
            ImsiDate		NVARCHAR(200) 	 NOT NULL, 
            RootProc		NVARCHAR(200) 	 NOT NULL, 
            RootEmp		INT 	 NOT NULL, 
            RootDate		NVARCHAR(200) 	 NOT NULL, 
            EndDate		NCHAR(8) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE  INDEX IDXTempYW_TLGASProcPlanLog ON YW_TLGASProcPlanLog (LogSeq)
    END