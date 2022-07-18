
if object_id('KPX_TEQCheckReport') is null 
begin 
CREATE TABLE KPX_TEQCheckReport
(
    CompanySeq		INT 	 NOT NULL, 
    Seq         INT NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    CheckDate		NCHAR(8) 	 NOT NULL, 
    UMCheckTerm     INT NOT NULL, 
    CheckReport		NVARCHAR(100) NULL, 
    Remark		NVARCHAR(100) 	 NULL, 
    Files1		INT 	 NULL, 
    Files2		INT 	 NULL, 
    Files3		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TEQCheckReport on KPX_TEQCheckReport(CompanySeq,Seq) 
end 


if object_id('KPX_TEQCheckReportLog') is null 
begin 
CREATE TABLE KPX_TEQCheckReportLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Seq         INT NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    CheckDate		NCHAR(8) 	 NOT NULL, 
    UMCheckTerm     INT NOT NULL, 
    CheckReport		NVARCHAR(100) 	 NULL, 
    Remark		NVARCHAR(100) 	 NULL, 
    Files1		INT 	 NULL, 
    Files2		INT 	 NULL, 
    Files3		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 


