if object_id('hencom_TACPaymentPricePlan') is null
begin 

    CREATE TABLE hencom_TACPaymentPricePlan
    (
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        MatAmt1		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt2		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt3		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt4		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt1		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt3		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt4		DECIMAL(19,5) 	 NOT NULL, 
        ReAmt1		DECIMAL(19,5) 	 NOT NULL, 
        ReAmt2		DECIMAL(19,5) 	 NOT NULL, 
        EtcAmt1		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACPaymentPricePlan PRIMARY KEY CLUSTERED (CompanySeq ASC, StdDate ASC, SlipUnit ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACPaymentPricePlan ON hencom_TACPaymentPricePlan(CompanySeq, StdDate, SlipUnit)
end 

if object_id('hencom_TACPaymentPricePlanLog') is null
begin 
    CREATE TABLE hencom_TACPaymentPricePlanLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        MatAmt1		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt2		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt3		DECIMAL(19,5) 	 NOT NULL, 
        MatAmt4		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt1		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt3		DECIMAL(19,5) 	 NOT NULL, 
        GoodsAmt4		DECIMAL(19,5) 	 NOT NULL, 
        ReAmt1		DECIMAL(19,5) 	 NOT NULL, 
        ReAmt2		DECIMAL(19,5) 	 NOT NULL, 
        EtcAmt1		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACPaymentPricePlanLog ON hencom_TACPaymentPricePlanLog (LogSeq)
end 