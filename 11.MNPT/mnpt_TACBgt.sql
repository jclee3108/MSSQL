if object_id('mnpt_TACBgt') is null
begin 

    CREATE TABLE mnpt_TACBgt
    (
        CompanySeq		INT 	 NOT NULL, 
        ChgSeq		INT 	 NOT NULL, 
        BgtYM		NCHAR(6) 	 NOT NULL, 
        AccUnit		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        CCtrSeq		INT 	 NOT NULL, 
        AccSeq		INT 	 NOT NULL, 
        IniOrAmd		NCHAR(1) 	 NOT NULL, 
        SMBgtChangeKind		INT 	 NOT NULL, 
        SMBgtChangeSource		INT 	 NOT NULL, 
        BgtSeq		INT 	 NOT NULL, 
        UMCostType		INT 	 NOT NULL, 
        BgtAmt		DECIMAL(19,5) 	 NOT NULL, 
        ChgBgtDesc		NVARCHAR(400) 	 NOT NULL, 
        UMChgType		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TACBgt PRIMARY KEY CLUSTERED (CompanySeq ASC, ChgSeq ASC)

    )
end 

if object_id('mnpt_TACBgtLog') is null
begin 
    CREATE TABLE mnpt_TACBgtLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        ChgSeq		INT 	 NOT NULL, 
        BgtYM		NCHAR(6) 	 NOT NULL, 
        AccUnit		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        CCtrSeq		INT 	 NOT NULL, 
        AccSeq		INT 	 NOT NULL, 
        IniOrAmd		NCHAR(1) 	 NOT NULL, 
        SMBgtChangeKind		INT 	 NOT NULL, 
        SMBgtChangeSource		INT 	 NOT NULL, 
        BgtSeq		INT 	 NOT NULL, 
        UMCostType		INT 	 NOT NULL, 
        BgtAmt		DECIMAL(19,5) 	 NOT NULL, 
        ChgBgtDesc		NVARCHAR(400) 	 NOT NULL, 
        UMChgType		INT 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TACBgtLog ON mnpt_TACBgtLog (LogSeq)
end 


