if object_id('KPXLS_TQCRequestAdd_PUR') is null

begin 
--drop table KPXLS_TQCRequestAdd_PUR
CREATE TABLE KPXLS_TQCRequestAdd_PUR
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    Storage		NVARCHAR(200) 	 NOT NULL, 
    CarNo		NVARCHAR(200) 	 NOT NULL, 
    CreateCustName		NVARCHAR(200) 	 NOT NULL, 
    QCReqList		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL

)
create unique clustered index idx_KPXLS_TQCRequestAdd_PUR on KPXLS_TQCRequestAdd_PUR(CompanySeq,ReqSeq) 
end 

if object_id('KPXLS_TQCRequestAdd_PURLog') is null

begin 
CREATE TABLE KPXLS_TQCRequestAdd_PURLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    Storage		NVARCHAR(200) 	 NOT NULL, 
    CarNo		NVARCHAR(200) 	 NOT NULL, 
    CreateCustName		NVARCHAR(200) 	 NOT NULL, 
    QCReqList		NVARCHAR(200) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 

