if object_id('KPX_TPRWKEmpOTGroupApp') is null
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupApp
(
    CompanySeq		INT 	 NOT NULL, 
    GroupAppSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    GroupAppNo		NVARCHAR(100) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TPRWKEmpOTGroupApp on KPX_TPRWKEmpOTGroupApp(CompanySeq,GroupAppSeq) 
end 

if object_id('KPX_TPRWKEmpOTGroupAppLog') is null
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupAppLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    GroupAppSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    GroupAppNo		NVARCHAR(100) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 