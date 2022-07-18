if object_id('KPX_TPDMRPMonthItem') is null
begin 
CREATE TABLE KPX_TPDMRPMonthItem
(
    CompanySeq		INT 	 NOT NULL, 
    MRPMonthSeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    MRPMonth		NCHAR(6) 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    CalcType		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TPDMRPMonthItem on KPX_TPDMRPMonthItem(CompanySeq,MRPMonthSeq,Serl) 
end 

if object_id('KPX_TPDMRPMonthItemLog') is null
begin 
CREATE TABLE KPX_TPDMRPMonthItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    MRPMonthSeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    MRPMonth		NCHAR(6) 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    CalcType		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


