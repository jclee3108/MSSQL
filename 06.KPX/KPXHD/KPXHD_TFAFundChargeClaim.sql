if object_id('KPXHD_TFAFundChargeClaim') is null

begin 

CREATE TABLE KPXHD_TFAFundChargeClaim
(
    CompanySeq		INT 	 NOT NULL, 
    FundChargeSeq		INT 	 NOT NULL, 
    StdYM		NCHAR(6) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    TotExcessProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    TotAdviceAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastYMClaimAmt		DECIMAL(19,5) 	 NOT NULL, 
    StdYMClaimAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXHD_TFAFundChargeClaim on KPXHD_TFAFundChargeClaim(CompanySeq,FundChargeSeq) 
end 


if object_id('KPXHD_TFAFundChargeClaimLog') is null
begin 
CREATE TABLE KPXHD_TFAFundChargeClaimLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FundChargeSeq		INT 	 NOT NULL, 
    StdYM		NCHAR(6) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    TotExcessProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    TotAdviceAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastYMClaimAmt		DECIMAL(19,5) 	 NOT NULL, 
    StdYMClaimAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 
