if object_id('KPXCM_TEQTaskOrderCHE') is null

begin 

CREATE TABLE KPXCM_TEQTaskOrderCHE
(
    CompanySeq		INT 	 NOT NULL, 
    TaskOrderSeq		INT 	 NOT NULL, 
    TaskOrderDate		NCHAR(8) 	 NOT NULL, 
    TaskOrderDeptSeq		INT 	 NOT NULL, 
    TaskOrderEmpSeq		INT 	 NOT NULL, 
    IsPID		NCHAR(1) 	 NOT NULL, 
    IsPFD		NCHAR(1) 	 NOT NULL, 
    IsLayOut		NCHAR(1) 	 NOT NULL, 
    IsProposal		NCHAR(1) 	 NOT NULL, 
    IsReport		NCHAR(1) 	 NOT NULL, 
    IsMinutes		NCHAR(1) 	 NOT NULL, 
    IsReview		NCHAR(1) 	 NOT NULL, 
    IsOpinion		NCHAR(1) 	 NOT NULL, 
    IsDange		NCHAR(1) 	 NOT NULL, 
    IsMSDS		NCHAR(1) 	 NOT NULL, 
    Etc		NVARCHAR(200) 	 NOT NULL, 
    ChangePlan		NVARCHAR(200) 	 NOT NULL, 
    TaskOrder		NVARCHAR(200) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 

)
create unique clustered index idx_KPXCM_TEQTaskOrderCHE on KPXCM_TEQTaskOrderCHE(CompanySeq,TaskOrderSeq) 
end 



if object_id('KPXCM_TEQTaskOrderCHELog') is null

begin 

CREATE TABLE KPXCM_TEQTaskOrderCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    TaskOrderSeq		INT 	 NOT NULL, 
    TaskOrderDate		NCHAR(8) 	 NOT NULL, 
    TaskOrderDeptSeq		INT 	 NOT NULL, 
    TaskOrderEmpSeq		INT 	 NOT NULL, 
    IsPID		NCHAR(1) 	 NOT NULL, 
    IsPFD		NCHAR(1) 	 NOT NULL, 
    IsLayOut		NCHAR(1) 	 NOT NULL, 
    IsProposal		NCHAR(1) 	 NOT NULL, 
    IsReport		NCHAR(1) 	 NOT NULL, 
    IsMinutes		NCHAR(1) 	 NOT NULL, 
    IsReview		NCHAR(1) 	 NOT NULL, 
    IsOpinion		NCHAR(1) 	 NOT NULL, 
    IsDange		NCHAR(1) 	 NOT NULL, 
    IsMSDS		NCHAR(1) 	 NOT NULL, 
    Etc		NVARCHAR(200) 	 NOT NULL, 
    ChangePlan		NVARCHAR(200) 	 NOT NULL, 
    TaskOrder		NVARCHAR(200) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 