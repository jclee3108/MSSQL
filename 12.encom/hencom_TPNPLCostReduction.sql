
if object_id('hencom_TPNPLCostReduction') is null

begin 
    CREATE TABLE hencom_TPNPLCostReduction
    (
        CompanySeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        PlanSeq		INT 	 NOT NULL, 
        PlanSerl		INT 	 NOT NULL, 
        Month01		DECIMAL(19,5) 	 NULL, 
        Month02		DECIMAL(19,5) 	 NULL, 
        Month03		DECIMAL(19,5) 	 NULL, 
        Month04		DECIMAL(19,5) 	 NULL, 
        Month05		DECIMAL(19,5) 	 NULL, 
        Month06		DECIMAL(19,5) 	 NULL, 
        Month07		DECIMAL(19,5) 	 NULL, 
        Month08		DECIMAL(19,5) 	 NULL, 
        Month09		DECIMAL(19,5) 	 NULL, 
        Month10		DECIMAL(19,5) 	 NULL, 
        Month11		DECIMAL(19,5) 	 NULL, 
        Month12		DECIMAL(19,5) 	 NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TPNPLCostReduction PRIMARY KEY CLUSTERED (CompanySeq ASC, DeptSeq ASC, PlanSeq ASC, PlanSerl ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TPNPLCostReduction ON hencom_TPNPLCostReduction(CompanySeq, DeptSeq, PlanSeq, PlanSerl)
end

if object_id('hencom_TPNPLCostReductionLog') is null
begin
    CREATE TABLE hencom_TPNPLCostReductionLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        PlanSeq		INT 	 NOT NULL, 
        PlanSerl		INT 	 NOT NULL, 
        Month01		DECIMAL(19,5) 	 NULL, 
        Month02		DECIMAL(19,5) 	 NULL, 
        Month03		DECIMAL(19,5) 	 NULL, 
        Month04		DECIMAL(19,5) 	 NULL, 
        Month05		DECIMAL(19,5) 	 NULL, 
        Month06		DECIMAL(19,5) 	 NULL, 
        Month07		DECIMAL(19,5) 	 NULL, 
        Month08		DECIMAL(19,5) 	 NULL, 
        Month09		DECIMAL(19,5) 	 NULL, 
        Month10		DECIMAL(19,5) 	 NULL, 
        Month11		DECIMAL(19,5) 	 NULL, 
        Month12		DECIMAL(19,5) 	 NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TPNPLCostReductionLog ON hencom_TPNPLCostReductionLog (LogSeq)
end 



