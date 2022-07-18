if object_id('KPX_TPDSFCProdPackReportItem') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackReportItem
(
    CompanySeq		INT 	 NOT NULL, 
    PackReportSeq		INT 	 NOT NULL, 
    PackReportSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    OutLotNo		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    SubUnitSeq		INT 	 NOT NULL, 
    SubQty		DECIMAL(19,5) 	 NOT NULL, 
    HambaQty		DECIMAL(19,5) 	 NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TPDSFCProdPackReportItem on KPX_TPDSFCProdPackReportItem(CompanySeq,PackReportSeq,PackReportSerl) 
end 


if object_id('KPX_TPDSFCProdPackReportItemLog') is null
begin 
CREATE TABLE KPX_TPDSFCProdPackReportItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackReportSeq		INT 	 NOT NULL, 
    PackReportSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    OutLotNo		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    SubUnitSeq		INT 	 NOT NULL, 
    SubQty		DECIMAL(19,5) 	 NOT NULL, 
    HambaQty		DECIMAL(19,5) 	 NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 