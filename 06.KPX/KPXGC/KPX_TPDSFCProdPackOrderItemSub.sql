if object_id('KPX_TPDSFCProdPackOrderItemSub') is null

begin 
CREATE TABLE KPX_TPDSFCProdPackOrderItemSub
(
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    PackOrderSubSerl		INT 	 NOT NULL, 
    InDate		NCHAR(8) 	 NOT NULL, 
    InQty		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL, 
)
create unique clustered index idx_KPX_TPDSFCProdPackOrderItemSub on KPX_TPDSFCProdPackOrderItemSub(CompanySeq,PackOrderSeq,PackOrderSerl,PackOrderSubSerl) 
end 


if object_id('KPX_TPDSFCProdPackOrderItemSubLog') is null

begin 
CREATE TABLE KPX_TPDSFCProdPackOrderItemSubLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    PackOrderSubSerl		INT 	 NOT NULL, 
    InDate		NCHAR(8) 	 NOT NULL, 
    InQty		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 