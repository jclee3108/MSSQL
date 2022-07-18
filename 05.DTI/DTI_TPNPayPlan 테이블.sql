IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPNPayPlan' AND xtype = 'U' )

    BEGIN
        CREATE TABLE DTI_TPNPayPlan
        (
            CompanySeq		INT 	 NOT NULL, 
            AccUnit			INT 	 NOT NULL,
            PlanYear	NCHAR(4) 	 NOT NULL,  
            Serl		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            DeptSeq     INT      NOT NULL,
            PayAmt1		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt2		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt3		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt4		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt5		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt6		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt7		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt8		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt9		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt10		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt11		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt12		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TPNPayPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, AccUnit ASC, PlanYear ASC, Serl ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPNPayPlanLog' AND xtype = 'U' )

    BEGIN
        CREATE TABLE DTI_TPNPayPlanLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            AccUnit		    INT 	 NOT NULL, 
            PlanYear		NCHAR(4) 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            CCtrSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            DeptSeq     INT      NOT NULL,
            PayAmt1		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt2		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt3		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt4		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt5		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt6		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt7		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt8		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt9		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt10		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt11		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt12		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE  INDEX IDXTempDTI_TPNPayPlanLog ON DTI_TPNPayPlanLog (LogSeq)
    END