if object_id('KPXCM_TSLExpExpenseDesc') is null

begin 
    CREATE TABLE KPXCM_TSLExpExpenseDesc
    (
        CompanySeq		INT 	 NOT NULL, 
        ExpenseSeq		INT 	 NOT NULL, 
        ExpenseSerl		INT 	 NOT NULL, 
        ItemRemark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index idx_KPXCM_TSLExpExpenseDesc on KPXCM_TSLExpExpenseDesc(CompanySeq,ExpenseSeq,ExpenseSerl) 
end 


if object_id('KPXCM_TSLExpExpenseDescLog') is null
begin 
    CREATE TABLE KPXCM_TSLExpExpenseDescLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ExpenseSeq		INT 	 NOT NULL, 
        ExpenseSerl		INT 	 NOT NULL, 
        ItemRemark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
end 