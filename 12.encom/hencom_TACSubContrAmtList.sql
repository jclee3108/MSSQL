if object_id('hencom_TACSubContrAmtList') is null
begin 

    CREATE TABLE hencom_TACSubContrAmtList
    (
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        SubContrAmt1		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt2		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt3		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt4		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt5		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt6		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt1		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt2		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt3		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt4		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt5		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt6		DECIMAL(19,5) 	 NOT NULL, 
        ThisMonthAmt		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACSubContrAmtList PRIMARY KEY CLUSTERED (CompanySeq ASC, StdDate ASC, SlipUnit ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACSubContrAmtList ON hencom_TACSubContrAmtList(CompanySeq, StdDate, SlipUnit)
end 

if object_id('hencom_TACSubContrAmtListLog') is null
begin 

    CREATE TABLE hencom_TACSubContrAmtListLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        SubContrAmt1		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt2		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt3		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt4		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt5		DECIMAL(19,5) 	 NOT NULL, 
        SubContrAmt6		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt1		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt2		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt3		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt4		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt5		DECIMAL(19,5) 	 NOT NULL, 
        DeductAmt6		DECIMAL(19,5) 	 NOT NULL, 
        ThisMonthAmt		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACSubContrAmtListLog ON hencom_TACSubContrAmtListLog (LogSeq)
end 