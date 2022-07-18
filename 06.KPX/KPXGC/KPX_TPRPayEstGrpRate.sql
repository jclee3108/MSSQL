if object_id('KPX_TPRPayEstGrpRate') is null
begin 
CREATE TABLE KPX_TPRPayEstGrpRate
(
    CompanySeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    UMPayType		INT 	 NOT NULL, 
    UMPgSeq		INT 	 NOT NULL, 
    EstRate		DECIMAL(19,5) 	 NULL, 
    AddRate		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPRPayEstGrpRate on KPX_TPRPayEstGrpRate(CompanySeq,YY,UMPayType,UMPgSeq) 
end 

if object_id('KPX_TPRPayEstGrpRateLog') is null
begin 
CREATE TABLE KPX_TPRPayEstGrpRateLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    YY		NCHAR(4) 	 NOT NULL, 
    UMPayType		INT 	 NOT NULL, 
    UMPgSeq		INT 	 NOT NULL, 
    EstRate		DECIMAL(19,5) 	 NULL, 
    AddRate		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 