if object_id('KPX_THRWelMediEmp') is null 
begin 
CREATE TABLE KPX_THRWelMediEmp
(
    CompanySeq		INT 	 NOT NULL, 
    WelMediEmpSeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    RegSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CompanyAmt		INT 	 NOT NULL, 
    ItemSeq		INT 	 NULL, 
    PbYM		NCHAR(6) 	 NULL, 
    PbSeq		INT 	 NULL, 
    WelMediSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THRWelMediEmp on KPX_THRWelMediEmp(CompanySeq,WelMediEmpSeq) 
end 

if object_id('KPX_THRWelMediEmpLog') is null 
begin 

CREATE TABLE KPX_THRWelMediEmpLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WelMediEmpSeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    RegSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    CompanyAmt		INT 	 NOT NULL, 
    ItemSeq		INT 	 NULL, 
    PbYM		NCHAR(6) 	 NULL, 
    PbSeq		INT 	 NULL, 
    WelMediSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 