if OBJECT_ID('KPX_TACResultProfitItemMaster') is null
begin 
CREATE TABLE KPX_TACResultProfitItemMaster
(
    CompanySeq		INT 	 NOT NULL, 
    ResultProfitSeq		INT 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    CancelDate		NCHAR(8) 	 NULL, 
    CancelAmt		DECIMAL(19,5) 	 NULL, 
    CancelResultAmt		DECIMAL(19,5) 	 NULL, 
    AllCancelDate		NCHAR(8) NULL, 
    AllCancelAmt		DECIMAL(19,5) 	 NULL, 
    AllCancelResultAmt		DECIMAL(19,5) 	 NULL, 
    SplitDate		NCHAR(8) 	 NULL, 
    SliptAmt		DECIMAL(19,5) 	 NULL, 
    ResultReDate    NCHAR(8) NULL, 
    ResultReAmt     DECIMAL(19,5) NULL, 

    ResultAmt		DECIMAL(19,5) 	 NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    Remark3		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TACResultProfitItemMaster on KPX_TACResultProfitItemMaster(CompanySeq,ResultProfitSeq) 
end 

if object_id('KPX_TACResultProfitItemMasterLog') is null
begin 
CREATE TABLE KPX_TACResultProfitItemMasterLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ResultProfitSeq		INT 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    CancelDate		NCHAR(8) 	 NULL, 
    CancelAmt		DECIMAL(19,5) 	 NULL, 
    CancelResultAmt		DECIMAL(19,5) 	 NULL, 
    AllCancelDate		NCHAR(8) NULL, 
    AllCancelAmt		DECIMAL(19,5) 	 NULL, 
    AllCancelResultAmt		DECIMAL(19,5) 	 NULL, 
    SplitDate		NCHAR(8) 	 NULL, 
    SliptAmt		DECIMAL(19,5) 	 NULL, 
    ResultReDate    NCHAR(8) NULL, 
    ResultReAmt     DECIMAL(19,5) NULL, 
    ResultAmt		DECIMAL(19,5) 	 NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    Remark3		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 





