
if object_id ('KPX_TSLMonthSalesPlan') is null 
begin 
CREATE TABLE KPX_TSLMonthSalesPlan
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    DVPlaceSeq		INT 	 NULL, 
    CurrSeq		INT 	 NULL, 
    Price		DECIMAL(19,5) 	 NULL, 
    PlanQty		DECIMAL(19,5) 	 NULL, 
    PlanCurAmt		DECIMAL(19,5) 	 NULL, 
    PlanKorAmt		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    EmpSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TSLMonthSalesPlan on KPX_TSLMonthSalesPlan(CompanySeq,BizUnit,PlanYM,PlanRev,CustSeq,ItemSeq) 
end 

if object_id('KPX_TSLMonthSalesPlanLog') is null 
begin 
CREATE TABLE KPX_TSLMonthSalesPlanLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    PlanRev		NCHAR(2) 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    DVPlaceSeq		INT 	 NULL, 
    CurrSeq		INT 	 NULL, 
    Price		DECIMAL(19,5) 	 NULL, 
    PlanQty		DECIMAL(19,5) 	 NULL, 
    PlanCurAmt		DECIMAL(19,5) 	 NULL, 
    PlanKorAmt		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    EmpSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 