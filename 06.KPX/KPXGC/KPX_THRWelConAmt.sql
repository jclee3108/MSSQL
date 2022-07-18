if object_id('KPX_THRWelConAmt') is null 
begin 
CREATE TABLE KPX_THRWelConAmt
(
    CompanySeq		INT 	 NOT NULL, 
    SMConMutual		INT 	 NOT NULL, 
    ConSeq		INT 	 NOT NULL, 
    WkItemSeq		INT 	 NOT NULL, 
    Numerator		DECIMAL(19,5) 	 NOT NULL, 
    Denominator		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_THRWelConAmt on KPX_THRWelConAmt(CompanySeq,SMConMutual,ConSeq,WkItemSeq) 
end 

if object_id('KPX_THRWelConAmtLog') is null 
begin 
CREATE TABLE KPX_THRWelConAmtLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    SMConMutual		INT 	 NOT NULL, 
    ConSeq		INT 	 NOT NULL, 
    WkItemSeq		INT 	 NOT NULL, 
    Numerator		DECIMAL(19,5) 	 NOT NULL, 
    Denominator		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 