if object_id('KPXLS_TQCRequest') is null

begin 
CREATE TABLE KPXLS_TQCRequest
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq          INT 	 NOT NULL, 
    ReqNo           NVARCHAR(100) NOT NULL, 
    ReqDate         NCHAR(8) NOT NULL, 
    EmpSeq          INT      NOT NULL, 
    DeptSeq         INT      NOT NULL, 
    FromPgmSeq      INT 	 NOT NULL, 
    SMSourceType    INT      NOT NULL, 
    SourceSeq       INT      NOT NULL, 
    Remark          NVARCHAR(500)   NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
create unique clustered index idx_KPXLS_TQCRequest on KPXLS_TQCRequest(CompanySeq,ReqSeq) 
end 


if object_id('KPXLS_TQCRequestLog') is null
begin 
CREATE TABLE KPXLS_TQCRequestLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq          INT 	 NOT NULL, 
    ReqNo           NVARCHAR(100) NOT NULL, 
    ReqDate         NCHAR(8) NOT NULL, 
    EmpSeq          INT      NOT NULL, 
    DeptSeq         INT      NOT NULL, 
    FromPgmSeq      INT 	 NOT NULL, 
    SMSourceType    INT      NOT NULL, 
    SourceSeq       INT      NOT NULL, 
    Remark          NVARCHAR(500)   NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
end