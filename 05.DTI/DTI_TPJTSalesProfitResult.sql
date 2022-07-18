IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesProfitResult' AND xtype = 'U' )
begin

CREATE TABLE DTI_TPJTSalesProfitResult
(
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    SMCostType		INT 	 NOT NULL, 
    SMItemType		INT 	 NOT NULL, 
    ResultYM		NCHAR(6) 	 NOT NULL, 
    FcstAmt		DECIMAL(19,5) 	 NOT NULL, 
    ResultAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL, 
CONSTRAINT PKDTI_TPJTSalesProfitResult PRIMARY KEY CLUSTERED (CompanySeq ASC, PJTSeq ASC, SMCostType ASC, SMItemType ASC, ResultYM ASC)

)
end


IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesProfitResultLog' AND xtype = 'U' )
begin

CREATE TABLE DTI_TPJTSalesProfitResultLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    SMCostType		INT 	 NOT NULL, 
    SMItemType		INT 	 NOT NULL, 
    ResultYM		NCHAR(6) 	 NOT NULL, 
    FcstAmt		DECIMAL(19,5) 	 NOT NULL, 
    ResultAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TPJTSalesProfitResultLog ON DTI_TPJTSalesProfitResultLog (LogSeq)
end


IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesProfitPlan' AND xtype = 'U' )
begin

CREATE TABLE DTI_TPJTSalesProfitPlan
(
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    SMCostType		INT 	 NOT NULL, 
    SMItemType		INT 	 NOT NULL, 
    Rev		INT 	 NOT NULL, 
    PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
    RevRemark		NVARCHAR(1000) 	 NOT NULL, 
    RevDate		NCHAR(8) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL, 
CONSTRAINT PKDTI_TPJTSalesProfitPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, PJTSeq ASC, SMCostType ASC, SMItemType ASC, Rev ASC)

)
end


IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTSalesProfitPlanLog' AND xtype = 'U' )
begin 

CREATE TABLE DTI_TPJTSalesProfitPlanLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    SMCostType		INT 	 NOT NULL, 
    SMItemType		INT 	 NOT NULL, 
    Rev		INT 	 NOT NULL, 
    PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
    RevRemark		NVARCHAR(1000) 	 NOT NULL, 
    RevDate		NCHAR(8) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TPJTSalesProfitPlanLog ON DTI_TPJTSalesProfitPlanLog (LogSeq)
end 