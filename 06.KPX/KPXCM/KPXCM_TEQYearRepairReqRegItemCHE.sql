
if object_id('KPXCM_TEQYearRepairReqRegItemCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReqRegItemCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    WONo            NVARCHAR(100) NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    WorkOperSeq		INT 	 NOT NULL, 
    WorkGubn		INT 	 NOT NULL, 
    WorkContents		NVARCHAR(200) 	 NOT NULL, 
    ProgType		INT 	 NOT NULL,     
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TEQYearRepairReqRegItemCHE on KPXCM_TEQYearRepairReqRegItemCHE(CompanySeq,ReqSeq,ReqSerl) 
end 

if object_id('KPXCM_TEQYearRepairReqRegItemCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReqRegItemCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    WONo            NVARCHAR(100) NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    WorkOperSeq		INT 	 NOT NULL, 
    WorkGubn		INT 	 NOT NULL, 
    WorkContents		NVARCHAR(200) 	 NOT NULL, 
    ProgType		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 


