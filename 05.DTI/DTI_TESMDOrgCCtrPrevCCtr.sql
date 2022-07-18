if object_id('DTI_TESMDOrgCCtrPrevCCtr') is null 
begin
CREATE TABLE DTI_TESMDOrgCCtrPrevCCtr
(
    CompanySeq		INT 	 NOT NULL, 
    CostYM		NCHAR(6) 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    PrevCCtrSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_DTI_TESMDOrgCCtrPrevCCtr on DTI_TESMDOrgCCtrPrevCCtr(CompanySeq,CostYM,CCtrSeq,PrevCCtrSeq)
end 

if object_id('DTI_TESMDOrgCCtrPrevCCtrLog') is null 
begin
CREATE TABLE DTI_TESMDOrgCCtrPrevCCtrLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    CostYM		NCHAR(6) 	 NOT NULL, 
    CCtrSeq		INT 	 NOT NULL, 
    PrevCCtrSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end