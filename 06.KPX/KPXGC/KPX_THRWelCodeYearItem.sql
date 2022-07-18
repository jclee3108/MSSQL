
if object_id('KPX_THRWelCodeYearItem') is null 
begin 
CREATE TABLE KPX_THRWelCodeYearItem
(
    CompanySeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    WelCodeSerl		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NULL, 
    RegName		NVARCHAR(100) 	 NULL, 
    RegSeq      INT NULL, 
    DateFr		NCHAR(8) 	 NULL, 
    DateTo		NCHAR(8) 	 NULL, 
    EmpAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_THRWelCodeYearItem on KPX_THRWelCodeYearItem(CompanySeq,WelCodeSeq,WelCodeSerl) 
end 

if object_id('KPX_THRWelCodeYearItemLog') is null 
begin 
CREATE TABLE KPX_THRWelCodeYearItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    WelCodeSeq		INT 	 NOT NULL, 
    WelCodeSerl		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NULL, 
    RegName		NVARCHAR(100) 	 NULL, 
    RegSeq      INT NULL, 
    DateFr		NCHAR(8) 	 NULL, 
    DateTo		NCHAR(8) 	 NULL, 
    EmpAmt		DECIMAL(19,5) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 
