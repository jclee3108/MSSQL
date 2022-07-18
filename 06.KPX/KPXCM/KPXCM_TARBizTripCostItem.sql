if object_id('KPXCM_TARBizTripCostItem') is null

begin 
CREATE TABLE KPXCM_TARBizTripCostItem
(
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripSerl		INT 	 NOT NULL, 
    UMTripKind		INT 	 NOT NULL, 
    UMOilKind		INT 	 NOT NULL, 
    AllKm		DECIMAL(19,5) 	 NOT NULL, 
    Price		DECIMAL(19,5) 	 NOT NULL, 
    Mileage		DECIMAL(19,5) 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TARBizTripCostItem on KPXCM_TARBizTripCostItem(CompanySeq,BizTripSeq,BizTripSerl) 
end 



if object_id('KPXCM_TARBizTripCostItemLog') is null

begin 
CREATE TABLE KPXCM_TARBizTripCostItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripSerl		INT 	 NOT NULL, 
    UMTripKind		INT 	 NOT NULL, 
    UMOilKind		INT 	 NOT NULL, 
    AllKm		DECIMAL(19,5) 	 NOT NULL, 
    Price		DECIMAL(19,5) 	 NOT NULL, 
    Mileage		DECIMAL(19,5) 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 