
if object_id('KPX_TACComCostDivSlip') is null 
begin 
CREATE TABLE KPX_TACComCostDivSlip
(
    CompanySeq		INT 	 NOT NULL, 
    CostYM		NCHAR(6) 	 NOT NULL, 
    SMCostMng		INT 	 NOT NULL, 
    SendCCtrSeq		INT 	 NOT NULL, 
    RevCCtrSeq		INT 	 NOT NULL, 
    CostAccSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    SlipMstSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TACComCostDivSlip on KPX_TACComCostDivSlip(CompanySeq,CostYM,SMCostMng,SendCCtrSeq,RevCCtrSeq,CostAccSeq) 
end 


if object_id('KPX_TACComCostDivSlipLog') is null 
begin 
CREATE TABLE KPX_TACComCostDivSlipLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    CostYM		NCHAR(6) 	 NOT NULL, 
    SMCostMng		INT 	 NOT NULL, 
    SendCCtrSeq		INT 	 NOT NULL, 
    RevCCtrSeq		INT 	 NOT NULL, 
    CostAccSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    SlipMstSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 
