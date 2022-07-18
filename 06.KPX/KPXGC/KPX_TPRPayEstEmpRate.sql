if object_id('KPX_TPRPayEstEmpRate') is null
begin 
CREATE TABLE KPX_TPRPayEstEmpRate
(
    CompanySeq		INT 	 NOT NULL, 
    YY		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    EstRate		DECIMAL(19,5) 	 NOT NULL, 
    AddRate		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPRPayEstEmpRate on KPX_TPRPayEstEmpRate(CompanySeq,YY,EmpSeq) 
end 


if object_id('KPX_TPRPayEstEmpRateLog') is null
begin 
CREATE TABLE KPX_TPRPayEstEmpRateLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    YY		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    EstRate		DECIMAL(19,5) 	 NOT NULL, 
    AddRate		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 