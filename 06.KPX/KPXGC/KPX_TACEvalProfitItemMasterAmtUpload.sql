if object_id('KPX_TACEvalProfitItemMasterAmtUpload') is null 
begin 
CREATE TABLE KPX_TACEvalProfitItemMasterAmtUpload
(
    CompanySeq		INT 	 NOT NULL, 
    Seq		INT 	 NOT NULL, 
    UMHelpComName		NVARCHAR(100) 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    FundCode		NVARCHAR(100) 	 NOT NULL, 
    TestAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
)
create unique clustered index idx_KPX_TACEvalProfitItemMasterAmtUpload on KPX_TACEvalProfitItemMasterAmtUpload(CompanySeq,Seq) 


end 


if object_id('KPX_TACEvalProfitItemMasterAmtUploadLog') is null 
begin 
CREATE TABLE KPX_TACEvalProfitItemMasterAmtUploadLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Seq		INT 	 NOT NULL, 
    UMHelpComName		NVARCHAR(100) 	 NOT NULL, 
    StdDate		NCHAR(8) 	 NOT NULL, 
    FundCode		NVARCHAR(100) 	 NOT NULL, 
    TestAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


