IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTPublicSISalesPlan' AND xtype = 'U' )
begin
    CREATE TABLE DTI_TPJTPublicSISalesPlan
    (
        CompanySeq		INT 	 NOT NULL, 
        PlanYM		NCHAR(6) 	 NOT NULL, 
        SMCostType		INT 	 NOT NULL, 
        SMItemType		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index IDX_DTI_TPJTPublicSISalesPlan on DTI_TPJTPublicSISalesPlan(CompanySeq, PlanYM, SMCostType, SMItemType)
end 

IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TPJTPublicSISalesPlanLog' AND xtype = 'U' )
begin

    CREATE TABLE DTI_TPJTPublicSISalesPlanLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        PlanYM		NCHAR(6) 	 NOT NULL, 
        SMCostType		INT 	 NOT NULL, 
        SMItemType		INT 	 NOT NULL, 
        Value		DECIMAL(19,5) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
end
