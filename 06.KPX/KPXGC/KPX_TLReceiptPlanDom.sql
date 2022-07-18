IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'KPX_TLReceiptPlanDom' AND xtype = 'U' )
    BEGIN
        CREATE TABLE KPX_TLReceiptPlanDom
        (
        CompanySeq		INT 	 NOT NULL, 
        PlanYM		NCHAR(6) 	 NOT NULL, 
        PlanType		NCHAR(1) 	 NOT NULL, 
        Serl		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        CustSeq		INT 	 NOT NULL, 
        CurrSeq		INT 	 NULL, 
        SMInType		INT 	 NULL, 
        PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt1		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt2		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt3		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt4		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt5		DECIMAL(19,5) 	 NOT NULL, 
        LongBondAmt		DECIMAL(19,5) 	 NOT NULL, 
        BadBondAmt		DECIMAL(19,5) 	 NOT NULL, 
        PlanDomAmt		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt1		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt2		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt3		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt4		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt5		DECIMAL(19,5) 	 NULL, 
        LongBondDomAmt		DECIMAL(19,5) 	 NULL, 
        BadBondDomAmt		DECIMAL(19,5) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
        CONSTRAINT PKKPX_TLReceiptPlanDom PRIMARY KEY CLUSTERED (CompanySeq ASC, PlanYM ASC, PlanType ASC, Serl ASC)
        )
    END

IF NOT EXISTS (SELECT * FROM Sysobjects where Name = 'KPX_TLReceiptPlanDomLog' AND xtype = 'U' )
    BEGIN
        CREATE TABLE KPX_TLReceiptPlanDomLog
        (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        PlanYM		NCHAR(6) 	 NOT NULL, 
        PlanType		NCHAR(1) 	 NOT NULL, 
        Serl		INT 	 NOT NULL, 
        BizUnit		INT 	 NOT NULL, 
        CustSeq		INT 	 NOT NULL, 
        CurrSeq		INT 	 NULL, 
        SMInType		INT 	 NULL, 
        PlanAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt1		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt2		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt3		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt4		DECIMAL(19,5) 	 NOT NULL, 
        ReceiptAmt5		DECIMAL(19,5) 	 NOT NULL, 
        LongBondAmt		DECIMAL(19,5) 	 NOT NULL, 
        BadBondAmt		DECIMAL(19,5) 	 NOT NULL, 
        PlanDomAmt		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt1		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt2		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt3		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt4		DECIMAL(19,5) 	 NULL, 
        ReceiptDomAmt5		DECIMAL(19,5) 	 NULL, 
        LongBondDomAmt		DECIMAL(19,5) 	 NULL, 
        BadBondDomAmt		DECIMAL(19,5) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
        )
        CREATE UNIQUE CLUSTERED INDEX IDXTempKPX_TLReceiptPlanDomLog ON KPX_TLReceiptPlanDomLog (LogSeq)
    END