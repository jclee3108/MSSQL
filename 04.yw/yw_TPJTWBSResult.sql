if object_id('yw_TPJTWBSResult') is null 
begin
CREATE TABLE yw_TPJTWBSResult
(
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    UMWBSSeq		INT 	 NOT NULL, 
    TargetDate		NCHAR(8) 	 NULL, 
    BegDate		NCHAR(8) 	 NULL, 
    EndDate		NCHAR(8) 	 NULL, 
    ChgDate		NCHAR(8) 	 NULL, 
    Results		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_yw_TPJTWBSResult on yw_TPJTWBSResult(CompanySeq,PJTSeq,UMWBSSeq)
end

if object_id('yw_TPJTWBSResultLog') is null 
begin
CREATE TABLE yw_TPJTWBSResultLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    UMWBSSeq		INT 	 NOT NULL, 
    TargetDate		NCHAR(8) 	 NULL, 
    BegDate		NCHAR(8) 	 NULL, 
    EndDate		NCHAR(8) 	 NULL, 
    ChgDate		NCHAR(8) 	 NULL, 
    Results		NVARCHAR(100) 	 NULL, 
    FileSeq		INT 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end


