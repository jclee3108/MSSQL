
if object_id('KPX_THRWelCode') is null 
begin 
CREATE TABLE KPX_THRWelCode
(
    CompanySeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    WelCodeName		NVARCHAR(100) 	 NOT NULL, 
    SMRegType		INT 	 NULL, 
    YearLimite		DECIMAL(19,5) 	 NULL, 
    WelFareKind		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_THRWelCode on KPX_THRWelCode(CompanySeq,WelCodeSeq) 
end 

if object_id('KPX_THRWelCodeLog') is null 
begin 
CREATE TABLE KPX_THRWelCodeLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    WelCodeName		NVARCHAR(100) 	 NOT NULL, 
    SMRegType		INT 	 NULL, 
    YearLimite		DECIMAL(19,5) 	 NULL, 
    WelFareKind		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 