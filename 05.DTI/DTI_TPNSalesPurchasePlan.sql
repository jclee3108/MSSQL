IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPNSalesPurchasePlan' AND xtype = 'U' )
begin 
    CREATE TABLE DTI_TPNSalesPurchasePlan
    (
        CompanySeq		INT 	 NOT NULL, 
        CostKeySeq		INT 	 NOT NULL, 
        Serl		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        PlanType		INT 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index IDX_DTI_TPNSalesPurchasePlan on DTI_TPNSalesPurchasePlan(CompanySeq, CostKeySeq, Serl)
end

IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPNSalesPurchasePlanLog' AND xtype = 'U' )
begin

    CREATE TABLE DTI_TPNSalesPurchasePlanLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CostKeySeq		INT 	 NOT NULL, 
        Serl		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        PlanType		INT 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TPJTPublicSISalesPlanLog ON DTI_TPJTPublicSISalesPlanLog (LogSeq)
end


