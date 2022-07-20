if object_id('mnpt_TACEEBgtAdj') is null
begin 

    CREATE TABLE mnpt_TACEEBgtAdj
    (
        CompanySeq		INT 	 NOT NULL, 
        AdjSeq		INT 	 NOT NULL, 
        StdYear     NCHAR(4) NOT NULL, 
        AccUnit     INT NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        CCtrSeq     INT NOT NULL, 
        AccSeq		INT 	 NOT NULL, 
        UMCostType		INT 	 NOT NULL, 
        Month01		DECIMAL(19,5) 	 NOT NULL, 
        Month02		DECIMAL(19,5) 	 NOT NULL, 
        Month03		DECIMAL(19,5) 	 NOT NULL, 
        Month04		DECIMAL(19,5) 	 NOT NULL, 
        Month05		DECIMAL(19,5) 	 NOT NULL, 
        Month06		DECIMAL(19,5) 	 NOT NULL, 
        Month07		DECIMAL(19,5) 	 NOT NULL, 
        Month08		DECIMAL(19,5) 	 NOT NULL, 
        Month09		DECIMAL(19,5) 	 NOT NULL, 
        Month10		DECIMAL(19,5) 	 NOT NULL, 
        Month11		DECIMAL(19,5) 	 NOT NULL, 
        Month12		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TACEEBgtAdj PRIMARY KEY CLUSTERED (CompanySeq ASC, AdjSeq ASC)

    )
end 

if object_id('mnpt_TACEEBgtAdjLog') is null
begin 
    CREATE TABLE mnpt_TACEEBgtAdjLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        AdjSeq		INT 	 NOT NULL, 
        StdYear     NCHAR(4) NOT NULL, 
        AccUnit     INT NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        CCtrSeq     INT NOT NULL, 
        AccSeq		INT 	 NOT NULL, 
        UMCostType		INT 	 NOT NULL, 
        Month01		DECIMAL(19,5) 	 NOT NULL, 
        Month02		DECIMAL(19,5) 	 NOT NULL, 
        Month03		DECIMAL(19,5) 	 NOT NULL, 
        Month04		DECIMAL(19,5) 	 NOT NULL, 
        Month05		DECIMAL(19,5) 	 NOT NULL, 
        Month06		DECIMAL(19,5) 	 NOT NULL, 
        Month07		DECIMAL(19,5) 	 NOT NULL, 
        Month08		DECIMAL(19,5) 	 NOT NULL, 
        Month09		DECIMAL(19,5) 	 NOT NULL, 
        Month10		DECIMAL(19,5) 	 NOT NULL, 
        Month11		DECIMAL(19,5) 	 NOT NULL, 
        Month12		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TACEEBgtAdjLog ON mnpt_TACEEBgtAdjLog (LogSeq)
end 


