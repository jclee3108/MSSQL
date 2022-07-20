if object_id('mnpt_TARCostAccSub') is null
begin 

    CREATE TABLE mnpt_TARCostAccSub
    (
        CompanySeq		INT 	 NOT NULL, 
        SMKindSeq		INT 	 NOT NULL, 
        CostSeq		INT 	 NOT NULL, 
        CostSClassSeq		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TARCostAccSub PRIMARY KEY CLUSTERED (CompanySeq ASC, SMKindSeq ASC, CostSeq ASC)

    )
end 


if object_id('mnpt_TARCostAccSubLog') is null
begin 
    CREATE TABLE mnpt_TARCostAccSubLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        SMKindSeq		INT 	 NOT NULL, 
        CostSeq		INT 	 NOT NULL, 
        CostSClassSeq		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TARCostAccSubLog ON mnpt_TARCostAccSubLog (LogSeq)
end 