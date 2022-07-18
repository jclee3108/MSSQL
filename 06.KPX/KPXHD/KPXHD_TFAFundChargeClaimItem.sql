if object_id('KPXHD_TFAFundChargeClaimItem') is null

begin 

CREATE TABLE KPXHD_TFAFundChargeClaimItem
(
    CompanySeq		INT 	 NOT NULL, 
    FundChargeSeq		INT 	 NOT NULL, 
    FundChargeSerl		INT 	 NOT NULL, 
    FundCode		NVARCHAR(200) 	 NOT NULL, 
    FundName		NVARCHAR(200) 	 NOT NULL, 
    ActAmt		DECIMAL(19,5) 	 NOT NULL, 
    CancelDate		NCHAR(8) 	 NOT NULL, 
    ProfitRate		DECIMAL(19,5) 	 NOT NULL, 
    ProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    SrtDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    FromToDate		INT 	 NOT NULL, 
    StdProfitRate		DECIMAL(19,5) 	 NOT NULL, 
    ExcessProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    AdviceAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXHD_TFAFundChargeClaimItem on KPXHD_TFAFundChargeClaimItem(CompanySeq,FundChargeSeq,FundChargeSerl) 
end 

if object_id('KPXHD_TFAFundChargeClaimItemLog') is null

begin 
CREATE TABLE KPXHD_TFAFundChargeClaimItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FundChargeSeq		INT 	 NOT NULL, 
    FundChargeSerl		INT 	 NOT NULL, 
    FundCode		NVARCHAR(200) 	 NOT NULL, 
    FundName		NVARCHAR(200) 	 NOT NULL, 
    ActAmt		DECIMAL(19,5) 	 NOT NULL, 
    CancelDate		NCHAR(8) 	 NOT NULL, 
    ProfitRate		DECIMAL(19,5) 	 NOT NULL, 
    ProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    SrtDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    FromToDate		INT 	 NOT NULL, 
    StdProfitRate		DECIMAL(19,5) 	 NOT NULL, 
    ExcessProfitAmt		DECIMAL(19,5) 	 NOT NULL, 
    AdviceAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

end 