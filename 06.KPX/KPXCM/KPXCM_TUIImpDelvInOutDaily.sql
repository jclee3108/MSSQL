if object_id('KPXCM_TUIImpDelvInOutDaily') is null

begin 
CREATE TABLE KPXCM_TUIImpDelvInOutDaily
(
    CompanySeq		INT 	 NOT NULL, 
    DelvSeq         INT      NOT NULL, 
    DelvSerl        INT      NOT NULL, 
    InOutSeq        INT      NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPXCM_TUIImpDelvInOutDaily on KPXCM_TUIImpDelvInOutDaily(CompanySeq,DelvSeq,DelvSerl,InOutSeq) 
end 


if object_id('KPXCM_TUIImpDelvInOutDailyLog') is null
begin 
CREATE TABLE KPXCM_TUIImpDelvInOutDailyLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    DelvSeq         INT      NOT NULL, 
    DelvSerl        INT      NOT NULL, 
    InOutSeq        INT      NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end