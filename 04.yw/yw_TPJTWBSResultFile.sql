if object_id('YW_TPJTWBSResultDWRFile') is not null 
begin
drop table YW_TPJTWBSResultDWRFile
end 
if object_id('YW_TPJTWBSResultRegFile') is not null 
begin
drop table YW_TPJTWBSResultRegFile
end 
if object_id('YW_TPJTWBSResultChgFile') is not null 
begin
drop table YW_TPJTWBSResultChgFile
end 
if object_id('YW_TPJTWBSResultEtcFile') is not null 
begin
drop table YW_TPJTWBSResultEtcFile
end 


if object_id('YW_TPJTWBSResultDWRFileLog') is not null 
begin
drop table YW_TPJTWBSResultDWRFileLog
end 
if object_id('YW_TPJTWBSResultRegFileLog') is not null 
begin
drop table YW_TPJTWBSResultRegFileLog
end 
if object_id('YW_TPJTWBSResultChgFileLog') is not null 
begin
drop table YW_TPJTWBSResultChgFileLog
end 
if object_id('YW_TPJTWBSResultEtcFileLog') is not null 
begin
drop table YW_TPJTWBSResultEtcFileLog
end 


if object_id('yw_TPJTWBSResultFile') is null
begin
CREATE TABLE yw_TPJTWBSResultFile
(
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    DWRFileSeq		INT 	 NOT NULL, 
    ChgFileSeq		INT 	 NOT NULL, 
    RegFileSeq		INT 	 NOT NULL, 
    EtcFileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_yw_TPJTWBSResultFile on yw_TPJTWBSResultFile(CompanySeq,PJTSeq) 
end 


if object_id('yw_TPJTWBSResultFileLog') is null 
begin 
CREATE TABLE yw_TPJTWBSResultFileLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    DWRFileSeq		INT 	 NOT NULL, 
    ChgFileSeq		INT 	 NOT NULL, 
    RegFileSeq		INT 	 NOT NULL, 
    EtcFileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end
