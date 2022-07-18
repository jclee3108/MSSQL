if object_id('KPX_TACEvalProfitItemMaster') is null
begin 
CREATE TABLE KPX_TACEvalProfitItemMaster
(
    CompanySeq		INT 	 NOT NULL, 
    EvalProfitSeq		INT 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    FundNo      NVARCHAR(100) NOT NULL, 
    SrtDate		NCHAR(8) 	 NULL, 
    DurDate		NCHAR(8) 	 NULL, 
    ActAmt		DECIMAL(19,5) 	 NULL, 
    PrevAmt		DECIMAL(19,5) 	 NULL, 
    InvestAmt		DECIMAL(19,5) 	 NULL, 
    TestAmt		DECIMAL(19,5) 	 NULL, 
    AddAmt		DECIMAL(19,5) 	 NULL, 
    DiffActDate		INT 	 NULL, 
    TagetAdd		DECIMAL(19,5) 	 NULL, 
    StdAdd		DECIMAL(19,5) 	 NULL, 
    Risk		NVARCHAR(100) 	 NULL, 
    TrustLevel		NVARCHAR(100) 	 NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    Remark3		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TACEvalProfitItemMaster on KPX_TACEvalProfitItemMaster(CompanySeq,EvalProfitSeq) 
end 

if object_id('KPX_TACEvalProfitItemMasterLog') is null
begin 
CREATE TABLE KPX_TACEvalProfitItemMasterLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    EvalProfitSeq		INT 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    UMHelpCom		INT 	 NOT NULL, 
    FundSeq		INT 	 NOT NULL, 
    FundNo      NVARCHAR(100) NOT NULL, 
    SrtDate		NCHAR(8) 	 NULL, 
    DurDate		NCHAR(8) 	 NULL, 
    ActAmt		DECIMAL(19,5) 	 NULL, 
    PrevAmt		DECIMAL(19,5) 	 NULL, 
    InvestAmt		DECIMAL(19,5) 	 NULL, 
    TestAmt		DECIMAL(19,5) 	 NULL, 
    AddAmt		DECIMAL(19,5) 	 NULL, 
    DiffActDate		INT 	 NULL, 
    TagetAdd		DECIMAL(19,5) 	 NULL, 
    StdAdd		DECIMAL(19,5) 	 NULL, 
    Risk		NVARCHAR(100) 	 NULL, 
    TrustLevel		NVARCHAR(100) 	 NULL, 
    Remark1		NVARCHAR(1000) 	 NULL, 
    Remark2		NVARCHAR(1000) 	 NULL, 
    Remark3		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


