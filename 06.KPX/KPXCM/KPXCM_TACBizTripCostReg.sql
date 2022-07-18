if object_id('KPXCM_TACBizTripCostReg') is null

begin 
CREATE TABLE KPXCM_TACBizTripCostReg
(
    CompanySeq		INT 	 NOT NULL, 
    Seq		INT 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    CostDate		NCHAR(8) 	 NOT NULL, 
    CostAccSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    RemSeq		INT 	 NOT NULL, 
    RemValSeq		INT 	 NOT NULL, 
    UMCostType		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    OppAccSeq		INT 	 NOT NULL, 
    CashDate		NCHAR(8) 	 NOT NULL, 
    SlipSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPXCM_TACBizTripCostReg on KPXCM_TACBizTripCostReg(CompanySeq,Seq) 
end 



if object_id('KPXCM_TACBizTripCostRegLog') is null

begin 
CREATE TABLE KPXCM_TACBizTripCostRegLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Seq		INT 	 NOT NULL, 
    AccUnit		INT 	 NOT NULL, 
    CostDate		NCHAR(8) 	 NOT NULL, 
    CostAccSeq		INT 	 NOT NULL, 
    Amt		DECIMAL(19,5) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    RemSeq		INT 	 NOT NULL, 
    RemValSeq		INT 	 NOT NULL, 
    UMCostType		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    OppAccSeq		INT 	 NOT NULL, 
    CashDate		NCHAR(8) 	 NOT NULL, 
    SlipSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 