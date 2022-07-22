if object_id('hencom_TACSendAmtList') is null

begin 
    CREATE TABLE hencom_TACSendAmtList
    (
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        Amt1		DECIMAL(19,5) 	 NOT NULL, 
        Amt2		DECIMAL(19,5) 	 NOT NULL, 
        Amt3		DECIMAL(19,5) 	 NOT NULL, 
        Amt4		DECIMAL(19,5) 	 NOT NULL, 
        Amt5		DECIMAL(19,5) 	 NOT NULL, 
        Amt6		DECIMAL(19,5) 	 NOT NULL, 
        Amt7		DECIMAL(19,5) 	 NOT NULL, 
        Amt8		DECIMAL(19,5) 	 NOT NULL, 
        Amt9		DECIMAL(19,5) 	 NOT NULL, 
        Amt10		DECIMAL(19,5) 	 NOT NULL, 
        Amt11		DECIMAL(19,5) 	 NOT NULL, 
        Amt12		DECIMAL(19,5) 	 NOT NULL, 
        Amt13		DECIMAL(19,5) 	 NOT NULL, 
        Amt14		DECIMAL(19,5) 	 NOT NULL, 
        Amt15		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACSendAmtList PRIMARY KEY CLUSTERED (CompanySeq ASC, StdDate ASC, SlipUnit ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACSendAmtList ON hencom_TACSendAmtList(CompanySeq, StdDate, SlipUnit)
end 

if object_id('hencom_TACSendAmtListLog') is null
begin 
    CREATE TABLE hencom_TACSendAmtListLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        Amt1		DECIMAL(19,5) 	 NOT NULL, 
        Amt2		DECIMAL(19,5) 	 NOT NULL, 
        Amt3		DECIMAL(19,5) 	 NOT NULL, 
        Amt4		DECIMAL(19,5) 	 NOT NULL, 
        Amt5		DECIMAL(19,5) 	 NOT NULL, 
        Amt6		DECIMAL(19,5) 	 NOT NULL, 
        Amt7		DECIMAL(19,5) 	 NOT NULL, 
        Amt8		DECIMAL(19,5) 	 NOT NULL, 
        Amt9		DECIMAL(19,5) 	 NOT NULL, 
        Amt10		DECIMAL(19,5) 	 NOT NULL, 
        Amt11		DECIMAL(19,5) 	 NOT NULL, 
        Amt12		DECIMAL(19,5) 	 NOT NULL, 
        Amt13		DECIMAL(19,5) 	 NOT NULL, 
        Amt14		DECIMAL(19,5) 	 NOT NULL, 
        Amt15		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACSendAmtListLog ON hencom_TACSendAmtListLog (LogSeq)
end 