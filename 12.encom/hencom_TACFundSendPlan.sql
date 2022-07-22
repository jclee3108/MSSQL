if object_id('hencom_TACFundSendPlan') is null
begin 

    CREATE TABLE hencom_TACFundSendPlan
    (
        CompanySeq		INT 	 NOT NULL, 
        StdDate		NCHAR(8) 	 NOT NULL, 
        SlipUnit		INT 	 NOT NULL, 
        InSendAmt		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt1		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt2		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt3		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt4		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt5		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt6		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt7		DECIMAL(19,5) 	 NOT NULL, 
        SendAmt8		DECIMAL(19,5) 	 NOT NULL, 
        AccSendAmt		DECIMAL(19,5) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_TACFundSendPlan PRIMARY KEY CLUSTERED (CompanySeq ASC, StdDate ASC, SlipUnit ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_TACFundSendPlan ON hencom_TACFundSendPlan(CompanySeq, StdDate, SlipUnit)
end 

if object_id('hencom_TACFundSendPlanLog') is null
begin 


CREATE TABLE hencom_TACFundSendPlanLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    SlipUnit		INT 	 NOT NULL, 
    InSendAmt		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt1		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt2		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt3		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt4		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt5		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt6		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt7		DECIMAL(19,5) 	 NOT NULL, 
    SendAmt8		DECIMAL(19,5) 	 NOT NULL, 
    AccSendAmt		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 