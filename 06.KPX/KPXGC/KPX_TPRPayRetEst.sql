if object_id('KPX_TPRPayRetEst') is null
begin 
CREATE TABLE KPX_TPRPayRetEst
(
    CompanySeq		INT 	 NOT NULL, 
    YY		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    RetEstAmt		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPRPayRetEst on KPX_TPRPayRetEst(CompanySeq,YY,EmpSeq) 
end 


if object_id('KPX_TPRPayRetEstLog') is null
begin 
CREATE TABLE KPX_TPRPayRetEstLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    YY		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    RetEstAmt		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 

