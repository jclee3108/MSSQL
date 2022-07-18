if object_id('KPX_TEQChangeCmmReviewEmpCHE') is null
begin 

CREATE TABLE KPX_TEQChangeCmmReviewEmpCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ReviewSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL

)
create unique clustered index idx_KPX_TEQChangeCmmReviewEmpCHE on KPX_TEQChangeCmmReviewEmpCHE(CompanySeq,ReviewSeq,EmpSeq) 
end 


if object_id('KPX_TEQChangeCmmReviewEmpCHELog') is null
begin 
CREATE TABLE KPX_TEQChangeCmmReviewEmpCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReviewSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 
