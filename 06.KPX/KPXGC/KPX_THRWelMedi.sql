
if object_id('KPX_THRWelMedi') is null
begin 
CREATE TABLE KPX_THRWelMedi
(
    CompanySeq		INT 	 NOT NULL, 
    WelMediSeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    RegSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    ComAmt		DECIMAL(19,5) 	 NULL, 
    SlipSeq     INT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THRWelMedi on KPX_THRWelMedi(CompanySeq,WelMediSeq) 
end 

if object_id('KPX_THRWelMediLog') is null 
begin 
CREATE TABLE KPX_THRWelMediLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WelMediSeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    RegSeq		INT 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    ComAmt		DECIMAL(19,5) 	 NULL, 
    SlipSeq     INT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 

