if object_id('KPX_TPRWKEmpOTGroupAppEmp') is null
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupAppEmp
(
    CompanySeq		INT 	 NOT NULL, 
    GroupAppSeq		INT 	 NOT NULL, 
    AppSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPX_TPRWKEmpOTGroupAppEmp on KPX_TPRWKEmpOTGroupAppEmp(CompanySeq,GroupAppSeq,AppSeq,EmpSeq) 
end 

if object_id('KPX_TPRWKEmpOTGroupAppEmpLog') is null
begin 
CREATE TABLE KPX_TPRWKEmpOTGroupAppEmpLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    GroupAppSeq		INT 	 NOT NULL, 
    AppSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 