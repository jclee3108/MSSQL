if object_id('KPX_TLGInOutReqAdd') is null
begin 
CREATE TABLE KPX_TLGInOutReqAdd
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    Kind		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TLGInOutReqAdd on KPX_TLGInOutReqAdd(CompanySeq,ReqSeq) 
end 


if object_id('KPX_TLGInOutReqAddLog') is null
begin 
CREATE TABLE KPX_TLGInOutReqAddLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    Kind		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 




