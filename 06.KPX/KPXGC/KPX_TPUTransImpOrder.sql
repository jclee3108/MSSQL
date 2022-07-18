if object_id('KPX_TPUTransImpOrder') is null 
begin
CREATE TABLE KPX_TPUTransImpOrder
(
    CompanySeq		INT 	 NOT NULL, 
    TransImpSeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    OrderDate		NCHAR(8) 	 NOT NULL, 
    TransImpNo		NVARCHAR(100) 	 NOT NULL, 
    SMImpKind		INT 	 NOT NULL, 
    TransDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CustSeq     INT      NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    UMCountry		INT 	 NOT NULL, 
    UMPrice		INT 	 NOT NULL, 
    UMTrans		INT 	 NOT NULL, 
    UMCont		INT 	 NOT NULL, 
    ContQty		DECIMAL(19,5) 	 NOT NULL, 
    UMPort		INT 	 NOT NULL, 
    UMPayGet		INT 	 NOT NULL, 
    UMPayment1		INT 	 NOT NULL, 
    UMPriceTerms		INT 	 NOT NULL, 
    CarNo		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPUTransImpOrder on KPX_TPUTransImpOrder(CompanySeq,TransImpSeq) 
end 

if object_id('KPX_TPUTransImpOrderLog') is null 
begin 
CREATE TABLE KPX_TPUTransImpOrderLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    TransImpSeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    OrderDate		NCHAR(8) 	 NOT NULL, 
    TransImpNo		NVARCHAR(100) 	 NOT NULL, 
    SMImpKind		INT 	 NOT NULL, 
    TransDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CustSeq     INT      NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    UMCountry		INT 	 NOT NULL, 
    UMPrice		INT 	 NOT NULL, 
    UMTrans		INT 	 NOT NULL, 
    UMCont		INT 	 NOT NULL, 
    ContQty		DECIMAL(19,5) 	 NOT NULL, 
    UMPort		INT 	 NOT NULL, 
    UMPayGet		INT 	 NOT NULL, 
    UMPayment1		INT 	 NOT NULL, 
    UMPriceTerms		INT 	 NOT NULL, 
    CarNo		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 

