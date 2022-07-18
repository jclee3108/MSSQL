if object_id('KPX_TLGInOutDailyAdd') is null
begin 
CREATE TABLE KPX_TLGInOutDailyAdd
(
    CompanySeq		INT 	 NOT NULL, 
    InOutType		INT 	 NOT NULL, 
    InOutSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    Kind        INT     NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TLGInOutDailyAdd on KPX_TLGInOutDailyAdd(CompanySeq,InOutType,InOutSeq) 
end 


if object_id('KPX_TLGInOutDailyAddLog') is null
begin 
CREATE TABLE KPX_TLGInOutDailyAddLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    InOutType		INT 	 NOT NULL, 
    InOutSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    Kind        INT     NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


