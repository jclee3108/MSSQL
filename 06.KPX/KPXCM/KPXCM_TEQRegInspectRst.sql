if object_id('KPXCM_TEQRegInspectRst') is null
begin 
CREATE TABLE KPXCM_TEQRegInspectRst
(
    CompanySeq		INT 	 NOT NULL, 
    RegInspectSeq		INT 	 NOT NULL, 
    QCDate		NCHAR(8) 	 NOT NULL, 
    QCResultDate NCHAR(8) 	 NOT NULL,  
    Remark		NVARCHAR(200) 	 NOT NULL, 
    FileSeq     INT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_KPXCM_TEQRegInspectRst on KPXCM_TEQRegInspectRst(CompanySeq,RegInspectSeq,QCDate) 
end 


if object_id('KPXCM_TEQRegInspectRstLog') is null
begin 
CREATE TABLE KPXCM_TEQRegInspectRstLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    RegInspectSeq		INT 	 NOT NULL, 
    QCDate		NCHAR(8) 	 NOT NULL, 
    QCResultDate NCHAR(8) 	 NOT NULL,  
    Remark		NVARCHAR(200) 	 NOT NULL, 
    FileSeq     INT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 


