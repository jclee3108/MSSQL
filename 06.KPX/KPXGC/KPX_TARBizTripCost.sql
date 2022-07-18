
if object_id('KPX_TARBizTripCost') is null
begin 
CREATE TABLE KPX_TARBizTripCost
(
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripNo		NVARCHAR(20) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    SMTripKind		INT 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    TripFrDate		NCHAR(8) 	 NOT NULL, 
    TripToDate		NCHAR(8) 	 NOT NULL, 
    TermNight		DECIMAL(19,5) 	 NOT NULL, 
    TermDay		DECIMAL(19,5) 	 NOT NULL, 
    TripPlace		NVARCHAR(200) 	 NOT NULL, 
    Purpose		NVARCHAR(200) 	 NOT NULL, 
    TransCost		DECIMAL(19,5) 	 NOT NULL, 
    DailyCost		DECIMAL(19,5) 	 NOT NULL, 
    LodgeCost		DECIMAL(19,5) 	 NOT NULL, 
    EctCost		DECIMAL(19,5) 	 NOT NULL, 
    CardOutCost		DECIMAL(19,5) 	 NOT NULL, 
    CostSeq		INT 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    SlipUnit		INT 	  NULL, 
    SlipMstSeq		INT 	  NULL, 
    SlipSeq		INT 	  NULL, 
    LastUserSeq		INT 	  NULL, 
    LastDateTime		DATETIME 	  NULL 
)
create unique clustered index idx_KPX_TARBizTripCost on KPX_TARBizTripCost(CompanySeq,BizTripSeq) 
end 


if object_id('KPX_TARBizTripCostLog') is null
begin 
CREATE TABLE KPX_TARBizTripCostLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripNo		NVARCHAR(20) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    SMTripKind		INT 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    TripFrDate		NCHAR(8) 	 NOT NULL, 
    TripToDate		NCHAR(8) 	 NOT NULL, 
    TermNight		DECIMAL(19,5) 	 NOT NULL, 
    TermDay		DECIMAL(19,5) 	 NOT NULL, 
    TripPlace		NVARCHAR(200) 	 NOT NULL, 
    Purpose		NVARCHAR(200) 	 NOT NULL, 
    TransCost		DECIMAL(19,5) 	 NOT NULL, 
    DailyCost		DECIMAL(19,5) 	 NOT NULL, 
    LodgeCost		DECIMAL(19,5) 	 NOT NULL, 
    EctCost		DECIMAL(19,5) 	 NOT NULL, 
    CardOutCost		DECIMAL(19,5) 	 NOT NULL, 
    CostSeq		INT 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    SlipUnit		INT 	  NULL, 
    SlipMstSeq		INT 	  NULL, 
    SlipSeq		INT 	  NULL, 
    LastUserSeq		INT 	  NULL, 
    LastDateTime		DATETIME 	  NULL
)
end 

