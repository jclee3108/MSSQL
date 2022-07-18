if object_id('KPX_TPDSFCProdPackOrder') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackOrder
(
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PackDate		NCHAR(8) 	 NOT NULL, 
    OrderNo		NVARCHAR(100) 	 NOT NULL, 
    OutWHSeq		INT 	 NOT NULL, 
    InWHSeq		INT 	 NOT NULL, 
    UMProgType		INT 	 NOT NULL, 
    SubOutWHSeq     INT      NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TPDSFCProdPackOrder on KPX_TPDSFCProdPackOrder(CompanySeq,PackOrderSeq) 
end 

if object_id('KPX_TPDSFCProdPackOrderLog') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackOrderLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PackDate		NCHAR(8) 	 NOT NULL, 
    OrderNo		NVARCHAR(100) 	 NOT NULL, 
    OutWHSeq		INT 	 NOT NULL, 
    InWHSeq		INT 	 NOT NULL, 
    UMProgType		INT 	 NOT NULL, 
    SubOutWHSeq     INT      NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


