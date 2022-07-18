IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMDEmpCCtrRatio' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TESMDEmpCCtrRatio
        (
        CompanySeq		INT 	 NOT NULL, 
        CostYM		NCHAR(6) 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        CCtrSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        EmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        PayAmt		DECIMAL(19,5) 	 NOT NULL, 
        TotPayAmt		DECIMAL(19,5) 	 NOT NULL, 
        BonusAmt		DECIMAL(19,5) 	 NOT NULL, 
        TotBonusAmt		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(1000) 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL, 
        CONSTRAINT PKDTI_TESMDEmpCCtrRatio PRIMARY KEY CLUSTERED (CompanySeq ASC, CostYM ASC, EmpSeq ASC, CCtrSeq ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TESMDEmpCCtrRatioLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TESMDEmpCCtrRatioLog
        (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CostYM		NCHAR(6) 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        CCtrSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        EmpCnt		DECIMAL(19,5) 	 NOT NULL, 
        PayAmt		DECIMAL(19,5) 	 NOT NULL, 
        TotPayAmt		DECIMAL(19,5) 	 NOT NULL, 
        BonusAmt		DECIMAL(19,5) 	 NOT NULL, 
        TotBonusAmt		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(1000) 	 NULL, 
        LastUserSeq		INT 	 NULL, 
        LastDateTime		DATETIME 	 NULL
        )
        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TESMDEmpCCtrRatioLog ON DTI_TESMDEmpCCtrRatioLog (LogSeq)
    END