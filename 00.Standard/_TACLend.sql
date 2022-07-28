IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLend' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLend
        (
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            SMKoOrFor		NCHAR(1) 	 NULL, 
            SMLendType		INT 	 NOT NULL, 
            UMLendKind		INT 	 NOT NULL, 
            LendNo		NVARCHAR(50) 	 NOT NULL, 
            AccSeq		INT 	 NOT NULL, 
            LendDate		NCHAR(8) 	 NOT NULL, 
            ExpireDate		NCHAR(8) 	 NOT NULL, 
            Amt		DECIMAL(19,5) 	 NOT NULL, 
            ForAmt		DECIMAL(19,5) 	 NULL, 
            CurrSeq		INT 	 NULL, 
            ExRateDate		NCHAR(8) 	 NULL, 
            ExRate		DECIMAL(19,5) 	 NULL, 
            CustSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            SlipSeq		INT 	 NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PK_TACLend PRIMARY KEY CLUSTERED (CompanySeq ASC, LendSeq ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            SMKoOrFor		NCHAR(1) 	 NULL, 
            SMLendType		INT 	 NOT NULL, 
            UMLendKind		INT 	 NOT NULL, 
            LendNo		NVARCHAR(50) 	 NOT NULL, 
            AccSeq		INT 	 NOT NULL, 
            LendDate		NCHAR(8) 	 NOT NULL, 
            ExpireDate		NCHAR(8) 	 NOT NULL, 
            Amt		DECIMAL(19,5) 	 NOT NULL, 
            ForAmt		DECIMAL(19,5) 	 NULL, 
            CurrSeq		INT 	 NULL, 
            ExRateDate		NCHAR(8) 	 NULL, 
            ExRate		DECIMAL(19,5) 	 NULL, 
            CustSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            SlipSeq		INT 	 NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTemp_TACLendLog ON _TACLendLog (LogSeq)
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendInterestOpt' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE _TACLendInterestOpt
        (
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            ChgDate		NCHAR(8) 	 NULL, 
            SMCalcMethod		INT 	 NOT NULL, 
            SMInterestPayWay	INT 	 NOT NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            InterestRate		DECIMAL(19,5) 	 NOT NULL, 
            InterestTerm		INT 	 NOT NULL, 
            DayQty		INT 	 NOT NULL, 
            PayCnt		INT 	 NOT NULL, 
            SMRateType		INT 	 NOT NULL, 
            Spread		DECIMAL(19,5) 	 NOT NULL, 
            IntDayCountType INT NOT NULL,
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PK_TACLendInterestOpt PRIMARY KEY CLUSTERED (CompanySeq ASC, LendSeq ASC, Serl ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendInterestOptLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendInterestOptLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            ChgDate		NCHAR(8) 	 NULL, 
            SMCalcMethod		INT 	 NOT NULL, 
            SMInterestPayWay	INT	 NOT NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            InterestRate		DECIMAL(19,5) 	 NOT NULL, 
            InterestTerm		INT 	 NOT NULL, 
            DayQty		INT 	 NOT NULL, 
            PayCnt		INT 	 NOT NULL, 
            SMRateType		INT 	 NOT NULL, 
            Spread		DECIMAL(19,5) 	 NOT NULL, 
            IntDayCountType  INT   NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTemp_TACLendInterestOptLog ON _TACLendInterestOptLog (LogSeq)
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendPlan' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE _TACLendPlan
        (
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            PayCnt		INT 	 NOT NULL, 
            PayDate		NCHAR(8) 	 NOT NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            TotAmt		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt		DECIMAL(19,5) 	 NOT NULL, 
            PayIntAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PK_TACLendPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, LendSeq ASC, Serl ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendPlanLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendPlanLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            PayCnt		INT 	 NOT NULL, 
            PayDate		NCHAR(8) 	 NOT NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            TotAmt		DECIMAL(19,5) 	 NOT NULL, 
            PayAmt		DECIMAL(19,5) 	 NOT NULL, 
            PayIntAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTemp_TACLendPlanLog ON _TACLendPlanLog (LogSeq)
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendSurety' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendSurety
        (
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            SuretyName		NVARCHAR(100) 	 NOT NULL, 
            SuretyAmt		DECIMAL(19,5) 	 NOT NULL, 
            SuretyDate		NCHAR(8) 	 NOT NULL, 
            ExpireDate		NCHAR(8) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PK_TACLendSurety PRIMARY KEY CLUSTERED (CompanySeq ASC, LendSeq ASC, Serl ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendSuretyLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendSuretyLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            SuretyName		NVARCHAR(100) 	 NOT NULL, 
            SuretyAmt		DECIMAL(19,5) 	 NOT NULL, 
            SuretyDate		NCHAR(8) 	 NOT NULL, 
            ExpireDate		NCHAR(8) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTemp_TACLendSuretyLog ON _TACLendSuretyLog (LogSeq)
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendRePayOpt' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendRePayOpt
        (
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            ChgDate		NCHAR(8) 	 NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            RepayCnt		INT 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            SMRepayType		INT 	 NOT NULL, 
            RepayTerm		INT 	 NOT NULL, 
            DeferYear		INT 	 NOT NULL, 
            DeferMonth		INT 	 NOT NULL, 
            OddTime		INT 	 NOT NULL, 
            OddUnitAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PK_TACLendRePayOpt PRIMARY KEY CLUSTERED (CompanySeq ASC, LendSeq ASC, Serl ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = '_TACLendRePayOptLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE _TACLendRePayOptLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            LendSeq		INT 	 NOT NULL, 
            Serl		INT 	 NOT NULL, 
            ChgDate		NCHAR(8) 	 NULL, 
            FrDate		NCHAR(8) 	 NOT NULL, 
            RepayCnt		INT 	 NOT NULL, 
            ToDate		NCHAR(8) 	 NOT NULL, 
            SMRepayType		INT 	 NOT NULL, 
            RepayTerm		INT 	 NOT NULL, 
            DeferYear		INT 	 NOT NULL, 
            DeferMonth		INT 	 NOT NULL, 
            OddTime		INT 	 NOT NULL, 
            OddUnitAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
            PgmSeq		INT 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTemp_TACLendRePayOptLog ON _TACLendRePayOptLog (LogSeq)
    END