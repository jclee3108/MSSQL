if object_id('KPXLS_TQCRequestItemAdd_PUR') is null

begin 
--drop table KPXLS_TQCRequestItemAdd_PUR
CREATE TABLE KPXLS_TQCRequestItemAdd_PUR
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    SMTestResult		INT 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXLS_TQCRequestItemAdd_PUR on KPXLS_TQCRequestItemAdd_PUR(CompanySeq,ReqSeq,ReqSerl) 
end 

if object_id('KPXLS_TQCRequestItemAdd_PURLog') is null

begin 
CREATE TABLE KPXLS_TQCRequestItemAdd_PURLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    SMTestResult		INT 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 

