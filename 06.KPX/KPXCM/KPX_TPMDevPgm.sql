if object_id('KPX_TPMDevPgm') is null 
begin 
CREATE TABLE KPX_TPMDevPgm
(
    CompanySeq  int not null, 
    DevSeq      int not null, 
    DevOrder    nvarchar(100) not null, 
    Module      nvarchar(100) not null, 
    PgmName     nvarchar(100) not null, 
    PgmClass    nvarchar(100) not null, 
    Consultant  nvarchar(100) not null, 
    DevName     nvarchar(100) not null, 
    PlanDate    nchar(8) not null, 
    FinDate     nchar(8) not null, 
    SMIsFinSeq  int, 
    Remark1     nvarchar(500) not null, 
    Remark2     nvarchar(500) not null,  
    Remark3     nvarchar(500) not null,  
    Remark4     nvarchar(500) not null, 
    Remark5     nvarchar(500) not null, 
    LastUserSeq int not null, 
    LastDateTime    datetime not null 
)
create unique clustered index idx_KPX_TPMDevPgm on KPX_TPMDevPgm(CompanySeq,DevSeq) 
end 


if object_id('KPX_TPMDevPgmLog') is null 
begin 
CREATE TABLE KPX_TPMDevPgmLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq  int not null, 
    DevSeq      int not null, 
    DevOrder    nvarchar(100) not null, 
    Module      nvarchar(100) not null, 
    PgmName     nvarchar(100) not null, 
    PgmClass    nvarchar(100) not null, 
    Consultant  nvarchar(100) not null, 
    DevName     nvarchar(100) not null, 
    PlanDate    nchar(8) not null, 
    FinDate     nchar(8) not null, 
    SMIsFinSeq  int, 
    Remark1     nvarchar(500) not null, 
    Remark2     nvarchar(500) not null,  
    Remark3     nvarchar(500) not null,  
    Remark4     nvarchar(500) not null, 
    Remark5     nvarchar(500) not null, 
    LastUserSeq int not null, 
    LastDateTime    datetime not null 
)
end 
