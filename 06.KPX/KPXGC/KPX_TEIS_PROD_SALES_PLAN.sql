if object_id('KPX_TEIS_PROD_SALES_PLAN') is null 
begin 
CREATE TABLE KPX_TEIS_PROD_SALES_PLAN
(
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMItemClassL		INT 	 NOT NULL, 
    ProdQty		DECIMAL(19,5) 	 NULL, 
    SalesQty		DECIMAL(19,5) 	 NULL, 
    SalesAmt		DECIMAL(19,5) 	 NULL, 
    SpendQty		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TEIS_PROD_SALES_PLAN on KPX_TEIS_PROD_SALES_PLAN(CompanySeq,BizUnit,PlanYM,UMItemClassL) 
end 


if object_id('KPX_TEIS_PROD_SALES_PLANLog') is null 
begin  
CREATE TABLE KPX_TEIS_PROD_SALES_PLANLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    PlanYM		NCHAR(6) 	 NOT NULL, 
    UMItemClassL		INT 	 NOT NULL, 
    ProdQty		DECIMAL(19,5) 	 NULL, 
    SalesQty		DECIMAL(19,5) 	 NULL, 
    SalesAmt		DECIMAL(19,5) 	 NULL, 
    SpendQty		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 