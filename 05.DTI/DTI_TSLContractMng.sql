IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMng' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TSLContractMng
        (
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            RevRemark		NVARCHAR(1000) 	 NOT NULL, 
            ContractMngNo		NVARCHAR(50) 	 NOT NULL, 
            ContractNo		NVARCHAR(50) 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            ContractDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            CustSeq		INT 	 NOT NULL, 
            BKCustSeq		INT 	 NOT NULL, 
            EndUserSeq		INT 	 NOT NULL, 
            UMContractKind		INT 	 NOT NULL, 
            UMSalesCond         INT  NOT NULL, 
            ContractEndDate		NCHAR(8) 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WHSeq       INT      NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            FileSeq		INT 	 NOT NULL, 
            IsCfm		NCHAR(1) 	 NOT NULL, 
            CfmDate		NCHAR(8) 	 NOT NULL, 
            CfmEmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TSLContractMng PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC)

        )
END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            RevRemark		NVARCHAR(1000) 	 NOT NULL, 
            ContractMngNo		NVARCHAR(50) 	 NOT NULL, 
            ContractNo		NVARCHAR(50) 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            ContractDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            CustSeq		INT 	 NOT NULL, 
            BKCustSeq		INT 	 NOT NULL, 
            EndUserSeq		INT 	 NOT NULL, 
            UMContractKind		INT 	 NOT NULL, 
            UMSalesCond         INT  NOT NULL,
            ContractEndDate		NCHAR(8) 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WHSeq       INT      NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            FileSeq		INT 	 NOT NULL, 
            IsCfm		NCHAR(1) 	 NOT NULL, 
            CfmDate		NCHAR(8) 	 NOT NULL, 
            CfmEmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLContractMngLog ON DTI_TSLContractMngLog (LogSeq)
END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngItem' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngItem
        (
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractSerl		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            IsStock		NCHAR(1) 	 NOT NULL, 
            PurYM		NCHAR(6) 	 NOT NULL, 
            PurPrice		DECIMAL(19,5) 	 NOT NULL, 
            PurAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesYM		NCHAR(6) 	 NOT NULL, 
            SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TSLContractMngItem PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC, ContractSerl ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngItemLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngItemLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractSerl		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            IsStock		NCHAR(1) 	 NOT NULL, 
            PurYM		NCHAR(6) 	 NOT NULL, 
            PurPrice		DECIMAL(19,5) 	 NOT NULL, 
            PurAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesYM		NCHAR(6) 	 NOT NULL, 
            SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLContractMngItemLog ON DTI_TSLContractMngItemLog (LogSeq)
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngRev' AND xtype = 'U' )
    BEGIN 
        CREATE TABLE DTI_TSLContractMngRev
        (
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            RevRemark		NVARCHAR(1000) 	 NOT NULL, 
            ContractMngNo		NVARCHAR(50) 	 NOT NULL, 
            ContractNo		NVARCHAR(50) 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            ContractDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            CustSeq		INT 	 NOT NULL, 
            BKCustSeq		INT 	 NOT NULL, 
            EndUserSeq		INT 	 NOT NULL, 
            UMContractKind		INT 	 NOT NULL, 
            UMSalesCond         INT  NOT NULL,
            ContractEndDate		NCHAR(8) 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WHSeq       INT      NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            FileSeq		INT 	 NOT NULL, 
            IsCfm		NCHAR(1) 	 NOT NULL, 
            CfmDate		NCHAR(8) 	 NOT NULL, 
            CfmEmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TSLContractMngRev PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC, ContractRev ASC)

        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngRevLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngRevLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            RevRemark		NVARCHAR(1000) 	 NOT NULL, 
            ContractMngNo		NVARCHAR(50) 	 NOT NULL, 
            ContractNo		NVARCHAR(50) 	 NOT NULL, 
            BizUnit		INT 	 NOT NULL, 
            ContractDate		NCHAR(8) 	 NOT NULL, 
            SDate		NCHAR(8) 	 NOT NULL, 
            EDate		NCHAR(8) 	 NOT NULL, 
            CustSeq		INT 	 NOT NULL, 
            BKCustSeq		INT 	 NOT NULL, 
            EndUserSeq		INT 	 NOT NULL, 
            UMContractKind		INT 	 NOT NULL, 
            UMSalesCond         INT  NOT NULL,
            ContractEndDate		NCHAR(8) 	 NOT NULL, 
            DeptSeq		INT 	 NOT NULL, 
            EmpSeq		INT 	 NOT NULL, 
            WHSeq       INT      NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            FileSeq		INT 	 NOT NULL, 
            IsCfm		NCHAR(1) 	 NOT NULL, 
            CfmDate		NCHAR(8) 	 NOT NULL, 
            CfmEmpSeq		INT 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLContractMngRevLog ON DTI_TSLContractMngRevLog (LogSeq)
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngItemRev' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngItemRev
        (
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractSerl		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            IsStock		NCHAR(1) 	 NOT NULL, 
            PurYM		NCHAR(6) 	 NOT NULL, 
            PurPrice		DECIMAL(19,5) 	 NOT NULL, 
            PurAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesYM		NCHAR(6) 	 NOT NULL, 
            SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL, 
        CONSTRAINT PKDTI_TSLContractMngItemRev PRIMARY KEY CLUSTERED (CompanySeq ASC, ContractSeq ASC, ContractSerl ASC, ContractRev ASC)

        )
    END


IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMngItemRevLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE DTI_TSLContractMngItemRevLog
        (
            LogSeq		INT IDENTITY(1,1) NOT NULL, 
            LogUserSeq		INT NOT NULL, 
            LogDateTime		DATETIME NOT NULL, 
            LogType		NCHAR(1) NOT NULL, 
            LogPgmSeq		INT NULL, 
            CompanySeq		INT 	 NOT NULL, 
            ContractSeq		INT 	 NOT NULL, 
            ContractSerl		INT 	 NOT NULL, 
            ContractRev		INT 	 NOT NULL, 
            ItemSeq		INT 	 NOT NULL, 
            Qty		DECIMAL(19,5) 	 NOT NULL, 
            IsStock		NCHAR(1) 	 NOT NULL, 
            PurYM		NCHAR(6) 	 NOT NULL, 
            PurPrice		DECIMAL(19,5) 	 NOT NULL, 
            PurAmt		DECIMAL(19,5) 	 NOT NULL, 
            SalesYM		NCHAR(6) 	 NOT NULL, 
            SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
            SalesAmt		DECIMAL(19,5) 	 NOT NULL, 
            Remark		NVARCHAR(1000) 	 NOT NULL, 
            LastUserSeq		INT 	 NOT NULL, 
            LastDateTime		DATETIME 	 NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLContractMngItemRevLog ON DTI_TSLContractMngItemRevLog (LogSeq)
    END
