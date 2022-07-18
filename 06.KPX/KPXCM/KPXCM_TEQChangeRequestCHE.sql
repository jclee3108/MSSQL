if object_id('KPXCM_TEQChangeRequestCHE') is null

begin 
CREATE TABLE KPXCM_TEQChangeRequestCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    ChangeRequestNo		NVARCHAR(100) 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    Title		NVARCHAR(200) 	 NOT NULL, 
    UMPlantType		INT 	 NOT NULL, 
    UMChangeType		INT 	 NOT NULL, 
    UMChangeReson1		INT 	 NOT NULL, 
    UMChangeReson2		INT 	 NOT NULL, 
    Purpose		NVARCHAR(200) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    Effect		NVARCHAR(200) 	 NOT NULL, 
    IsPID		NCHAR(1) 	 NOT NULL, 
    IsPFD		NCHAR(1) 	 NOT NULL, 
    IsLayOut		NCHAR(1) 	 NOT NULL, 
    IsProposal		NCHAR(1) 	 NOT NULL, 
    IsReport		NCHAR(1) 	 NOT NULL, 
    IsMinutes		NCHAR(1) 	 NOT NULL, 
    IsReview		NCHAR(1) 	 NOT NULL, 
    IsOpinion		NCHAR(1) 	 NOT NULL, 
    IsDange		NCHAR(1) 	 NOT NULL, 
    Etc		NVARCHAR(200) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
create unique clustered index idx_KPXCM_TEQChangeRequestCHE on KPXCM_TEQChangeRequestCHE(CompanySeq,ChangeRequestSeq) 
end 


if object_id('KPXCM_TEQChangeRequestCHELog') is null

begin 
CREATE TABLE KPXCM_TEQChangeRequestCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    ChangeRequestNo		NVARCHAR(100) 	 NOT NULL, 
    BaseDate		NCHAR(8) 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    Title		NVARCHAR(200) 	 NOT NULL, 
    UMPlantType		INT 	 NOT NULL, 
    UMChangeType		INT 	 NOT NULL, 
    UMChangeReson1		INT 	 NOT NULL, 
    UMChangeReson2		INT 	 NOT NULL, 
    Purpose		NVARCHAR(200) 	 NOT NULL, 
    Remark		NVARCHAR(200) 	 NOT NULL, 
    Effect		NVARCHAR(200) 	 NOT NULL, 
    IsPID		NCHAR(1) 	 NOT NULL, 
    IsPFD		NCHAR(1) 	 NOT NULL, 
    IsLayOut		NCHAR(1) 	 NOT NULL, 
    IsProposal		NCHAR(1) 	 NOT NULL, 
    IsReport		NCHAR(1) 	 NOT NULL, 
    IsMinutes		NCHAR(1) 	 NOT NULL, 
    IsReview		NCHAR(1) 	 NOT NULL, 
    IsOpinion		NCHAR(1) 	 NOT NULL, 
    IsDange		NCHAR(1) 	 NOT NULL, 
    Etc		NVARCHAR(200) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 
