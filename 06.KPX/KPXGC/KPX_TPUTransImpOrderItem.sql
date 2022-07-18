
if object_id('KPX_TPUTransImpOrderItem') is null 
begin 
CREATE TABLE KPX_TPUTransImpOrderItem
(
    CompanySeq		INT 	 NOT NULL, 
    TransImpSeq		INT 	 NOT NULL, 
    TransImpSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NULL, 
    Price		DECIMAL(19,5) 	 NULL, 
    CurAmt		DECIMAL(19,5) 	 NULL, 
    DomAmt		DECIMAL(19,5) 	 NULL, 
    MakerSeq		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    STDUnitSeq		INT 	 NULL, 
    STDQty		DECIMAL(19,5) 	 NULL, 
    LotNo		NVARCHAR(100) 	 NULL, 
    UMPacking		INT 	 NULL, 
    TransDate		NCHAR(8) 	 NOT NULL, 
    BLSeq		INT 	 NOT NULL, 
    BLSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TPUTransImpOrderItem on KPX_TPUTransImpOrderItem(CompanySeq,TransImpSeq,TransImpSerl) 
end 

if object_id('KPX_TPUTransImpOrderItemLog') is null 
begin 
CREATE TABLE KPX_TPUTransImpOrderItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    TransImpSeq		INT 	 NOT NULL, 
    TransImpSerl		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NULL, 
    Price		DECIMAL(19,5) 	 NULL, 
    CurAmt		DECIMAL(19,5) 	 NULL, 
    DomAmt		DECIMAL(19,5) 	 NULL, 
    MakerSeq		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    STDUnitSeq		INT 	 NULL, 
    STDQty		DECIMAL(19,5) 	 NULL, 
    LotNo		NVARCHAR(100) 	 NULL, 
    UMPacking		INT 	 NULL, 
    TransDate		NCHAR(8) 	 NOT NULL, 
    BLSeq		INT 	 NOT NULL, 
    BLSerl		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 