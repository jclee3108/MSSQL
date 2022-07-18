if object_id('KPX_TPDSFCProdPackOrderItem') is null

begin 
CREATE TABLE KPX_TPDSFCProdPackOrderItem
(
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    OrderQty		DECIMAL(19,5) 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    UMDMMarking		INT 	 NOT NULL, 
    OutLotNo		NVARCHAR(100) 	 NOT NULL, 
    PackOnDate		NCHAR(8) 	 NOT NULL, 
    PackReOnDate		NCHAR(8) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    SubUnitSeq		INT 	 NOT NULL, 
    SubQty		DECIMAL(19,5) 	 NOT NULL, 
    NonMarking		NVARCHAR(200) 	 NULL, 
    PopInfo		NVARCHAR(200) 	 NULL, 
    IsStop		NCHAR(1) 	 NULL, 
    WorkCenterSeq int   null, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TPDSFCProdPackOrderItem on KPX_TPDSFCProdPackOrderItem(CompanySeq,PackOrderSeq,PackOrderSerl) 
end 

if object_id('KPX_TPDSFCProdPackOrderItemLog') is null

begin 

CREATE TABLE KPX_TPDSFCProdPackOrderItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    OrderQty		DECIMAL(19,5) 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    UMDMMarking		INT 	 NOT NULL, 
    OutLotNo		NVARCHAR(100) 	 NOT NULL, 
    PackOnDate		NCHAR(8) 	 NOT NULL, 
    PackReOnDate		NCHAR(8) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    SubItemSeq		INT 	 NOT NULL, 
    SubUnitSeq		INT 	 NOT NULL, 
    SubQty		DECIMAL(19,5) 	 NOT NULL, 
    NonMarking		NVARCHAR(200) 	 NULL, 
    PopInfo		NVARCHAR(200) 	 NULL, 
    IsStop		NCHAR(1) 	 NULL, 
    WorkCenterSeq int   null, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 




