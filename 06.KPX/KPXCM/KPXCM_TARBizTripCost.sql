if object_id('KPXCM_TARBizTripCost') is null

begin 
CREATE TABLE KPXCM_TARBizTripCost
(
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripNo		NVARCHAR(50) 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    TripEmpSeq		INT 	 NOT NULL, 
    TripDeptSeq		INT 	 NOT NULL, 
    TripCCtrSeq		INT 	 NOT NULL, 
    CostSeq		INT 	 NOT NULL, 
    RemValSeq		INT 	 NOT NULL, 
    TripPlace		NVARCHAR(200) 	 NOT NULL, 
    TripCust		NVARCHAR(200) 	 NOT NULL, 
    TripFrDate		NCHAR(8) 	 NOT NULL, 
    TripToDate		NCHAR(8) 	 NOT NULL, 
    Purpose		NVARCHAR(500) 	 NOT NULL, 
    Contents		NVARCHAR(500) 	 NOT NULL, 
    TripPerson		NVARCHAR(200) 	 NOT NULL, 
    PayReqDate		NCHAR(8) 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    WkItemSeq   INT NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TARBizTripCost on KPXCM_TARBizTripCost(CompanySeq,BizTripSeq) 
end 


if object_id('KPXCM_TARBizTripCostLog') is null

begin 
CREATE TABLE KPXCM_TARBizTripCostLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    BizTripNo		NVARCHAR(50) 	 NOT NULL, 
    RegDate		NCHAR(8) 	 NOT NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    TripEmpSeq		INT 	 NOT NULL, 
    TripDeptSeq		INT 	 NOT NULL, 
    TripCCtrSeq		INT 	 NOT NULL, 
    CostSeq		INT 	 NOT NULL, 
    RemValSeq		INT 	 NOT NULL, 
    TripPlace		NVARCHAR(200) 	 NOT NULL, 
    TripCust		NVARCHAR(200) 	 NOT NULL, 
    TripFrDate		NCHAR(8) 	 NOT NULL, 
    TripToDate		NCHAR(8) 	 NOT NULL, 
    Purpose		NVARCHAR(500) 	 NOT NULL, 
    Contents		NVARCHAR(500) 	 NOT NULL, 
    TripPerson		NVARCHAR(200) 	 NOT NULL, 
    PayReqDate		NCHAR(8) 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    WkItemSeq   INT NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 


