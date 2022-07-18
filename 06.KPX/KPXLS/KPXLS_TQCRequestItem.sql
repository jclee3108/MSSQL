
if object_id('KPXLS_TQCRequestItem') is null

begin 
CREATE TABLE KPXLS_TQCRequestItem
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq          INT 	 NOT NULL, 
    ReqSerl         INT      NOT NULL, 
    SourceSeq       INT      NOT NULL, 
    SourceSerl      INT      NOT NULL, 
    Remark          NVARCHAR(500)   NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
create unique clustered index idx_KPXLS_TQCRequestItem on KPXLS_TQCRequestItem(CompanySeq,ReqSeq,ReqSerl) 
end 


if object_id('KPXLS_TQCRequestItemLog') is null
begin 
CREATE TABLE KPXLS_TQCRequestItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq          INT 	 NOT NULL, 
    ReqSerl         INT      NOT NULL, 
    SourceSeq       INT      NOT NULL, 
    SourceSerl      INT      NOT NULL, 
    Remark          NVARCHAR(500)   NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
end