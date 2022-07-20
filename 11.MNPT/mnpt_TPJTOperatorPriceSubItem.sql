if object_id('mnpt_TPJTOperatorPriceSubItem') is null
begin 
    CREATE TABLE mnpt_TPJTOperatorPriceSubItem
    (
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        StdSubSerl		INT 	 NOT NULL, 
        PJTTypeSeq		INT 	 NOT NULL, 
        UnDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        UnHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        UnMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTOperatorPriceSubItem PRIMARY KEY CLUSTERED (Companyseq ASC, StdSeq ASC, StdSerl ASC, StdSubSerl ASC)

    )
end 

if object_id('mnpt_TPJTOperatorPriceSubItemLog') is null
begin 
    CREATE TABLE mnpt_TPJTOperatorPriceSubItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        Companyseq		INT 	 NOT NULL, 
        StdSeq		INT 	 NOT NULL, 
        StdSerl		INT 	 NOT NULL, 
        StdSubSerl		INT 	 NOT NULL, 
        PJTTypeSeq		INT 	 NOT NULL, 
        UnDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        UnHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        UnMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        DailyMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        OSMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcDayPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcHalfPrice		DECIMAL(19,5) 	 NOT NULL, 
        EtcMonthPrice		DECIMAL(19,5) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTOperatorPriceSubItemLog ON mnpt_TPJTOperatorPriceSubItemLog (LogSeq)
end 




