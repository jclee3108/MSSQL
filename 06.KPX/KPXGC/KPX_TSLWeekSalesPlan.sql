if object_id('KPX_TSLWeekSalesPlan') is null

begin 
CREATE TABLE KPX_TSLWeekSalesPlan
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    WeekSeq		INT 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    DVPlaceSeq  INT     NOT NULL, 
    UMPackingType		INT 	 NULL, 
    Qty		DECIMAL(19,5) 	 NULL, 
    SDate		NCHAR(8) 	 NULL, 
    EDate		NCHAR(8) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TSLWeekSalesPlan on KPX_TSLWeekSalesPlan(CompanySeq,BizUnit,WeekSeq,PlanRev,CustSeq,ItemSeq,DVPlaceSeq,PlanDate) 
end 

if object_id('KPX_TSLWeekSalesPlanLog') is null

begin 
CREATE TABLE KPX_TSLWeekSalesPlanLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    WeekSeq		INT 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    DVPlaceSeq  INT     NOT NULL, 
    PlanDate		NCHAR(8) 	 NOT NULL, 
    UMPackingType		INT 	 NULL, 
    Qty		DECIMAL(19,5) 	 NULL, 
    SDate		NCHAR(8) 	 NULL, 
    EDate		NCHAR(8) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


