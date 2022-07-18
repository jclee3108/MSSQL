if object_id('KPX_TPDMRPDailyItem') is null
begin 
CREATE TABLE KPX_TPDMRPDailyItem
(
    CompanySeq		INT 	 NOT NULL, 
    MRPDailySeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    MRPDate		NCHAR(8) 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    CalcType		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPDMRPDailyItem on KPX_TPDMRPDailyItem(CompanySeq,MRPDailySeq,Serl) 
end 

if object_id('KPX_TPDMRPDailytItemLog') is null
begin 
CREATE TABLE KPX_TPDMRPDailytItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    MRPDailySeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    MRPDate		NCHAR(8) 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    CalcType		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 

