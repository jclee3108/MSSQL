if object_id('KPXCM_TEQChangeFinalReport') is null

begin 


CREATE TABLE KPXCM_TEQChangeFinalReport
(
    CompanySeq		INT 	 NOT NULL, 
    FinalReportSeq		INT 	 NOT NULL, 
    FinalReportDate		NCHAR(8) 	 NOT NULL, 
    ResultDateFr		NCHAR(8) 	 NOT NULL, 
    ResultDateTo		NCHAR(8) 	 NOT NULL, 
    FinalReportDeptSeq		INT 	 NOT NULL, 
    FinalReportEmpSeq		INT 	 NOT NULL, 
    ResultRemark		NVARCHAR(200) 	 NULL, 
    IsPID		NCHAR(1) 	 NULL, 
    IsPFD		NCHAR(1) 	 NULL, 
    IsLayOut		NCHAR(1) 	 NULL, 
    IsProposal		NCHAR(1) 	 NULL, 
    IsReport		NCHAR(1) 	 NULL, 
    IsMinutes		NCHAR(1) 	 NULL, 
    IsReview		NCHAR(1) 	 NULL, 
    IsOpinion		NCHAR(1) 	 NULL, 
    IsDange		NCHAR(1) 	 NULL, 
    IsMSDS		NCHAR(1) 	 NULL, 
    IsCheckList		NCHAR(1) 	 NULL, 
    IsResultCheck		NCHAR(1) 	 NULL, 
    IsEduJoin		NCHAR(1) 	 NULL, 
    IsSkillReport		NCHAR(1) 	 NULL, 
    Etc		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQChangeFinalReport on KPXCM_TEQChangeFinalReport(CompanySeq,FinalReportSeq) 
end 


if object_id('KPXCM_TEQChangeFinalReportLog') is null

begin 
CREATE TABLE KPXCM_TEQChangeFinalReportLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    FinalReportSeq		INT 	 NOT NULL, 
    FinalReportDate		NCHAR(8) 	 NOT NULL, 
    ResultDateFr		NCHAR(8) 	 NOT NULL, 
    ResultDateTo		NCHAR(8) 	 NOT NULL, 
    FinalReportDeptSeq		INT 	 NOT NULL, 
    FinalReportEmpSeq		INT 	 NOT NULL, 
    ResultRemark		NVARCHAR(200) 	 NULL, 
    IsPID		NCHAR(1) 	 NULL, 
    IsPFD		NCHAR(1) 	 NULL, 
    IsLayOut		NCHAR(1) 	 NULL, 
    IsProposal		NCHAR(1) 	 NULL, 
    IsReport		NCHAR(1) 	 NULL, 
    IsMinutes		NCHAR(1) 	 NULL, 
    IsReview		NCHAR(1) 	 NULL, 
    IsOpinion		NCHAR(1) 	 NULL, 
    IsDange		NCHAR(1) 	 NULL, 
    IsMSDS		NCHAR(1) 	 NULL, 
    IsCheckList		NCHAR(1) 	 NULL, 
    IsResultCheck		NCHAR(1) 	 NULL, 
    IsEduJoin		NCHAR(1) 	 NULL, 
    IsSkillReport		NCHAR(1) 	 NULL, 
    Etc		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    ChangeRequestSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


--drop table KPXCM_TEQChangeFinalReportLog