if object_id('KPXCM_TQCTestResultMonitoring') is null

begin 
--drop table DTI_TCOMEnvAdmin
CREATE TABLE KPXCM_TQCTestResultMonitoring
(
    CompanySeq		INT     NOT NULL, 
    QCSeq           INT     NOT NULL, 
    UserSeq         INT     NOT NULL, 
    LastUserSeq     INT     NULL, 
    LastDateTime    DATETIME NULL, 
    PgmSeq		INT 	 NULL 
)
create unique clustered index idx_KPXCM_TQCTestResultMonitoring on KPXCM_TQCTestResultMonitoring(CompanySeq,QcSeq,UserSeq) 
end 


if object_id('KPXCM_TQCTestResultMonitoringLog') is null
begin 
--drop table DTI_TCOMEnvAdminLog
CREATE TABLE KPXCM_TQCTestResultMonitoringLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT     NOT NULL, 
    QCSeq           INT     NOT NULL, 
    UserSeq         INT     NOT NULL, 
    LastUserSeq     INT     NULL, 
    LastDateTime    DATETIME NULL, 
    PgmSeq		INT 	 NULL 
)
end

