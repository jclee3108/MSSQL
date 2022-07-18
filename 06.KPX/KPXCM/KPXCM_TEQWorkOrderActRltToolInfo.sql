if object_id('KPXCM_TEQWorkOrderActRltToolInfo') is null
begin 
CREATE TABLE KPXCM_TEQWorkOrderActRltToolInfo
(
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    ProtectKind		INT 	 NOT NULL, 
    WorkReason		INT 	 NOT NULL, 
    PreProtect		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQWorkOrderActRltToolInfo on KPXCM_TEQWorkOrderActRltToolInfo(CompanySeq,ReceiptSeq,WOReqSeq,WOReqSerl) 
end 

if object_id('KPXCM_TEQWorkOrderActRltToolInfoLog') is null
begin 
CREATE TABLE KPXCM_TEQWorkOrderActRltToolInfoLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    WOReqSeq		INT 	 NOT NULL, 
    WOReqSerl		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    ProtectKind		INT 	 NOT NULL, 
    WorkReason		INT 	 NOT NULL, 
    PreProtect		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    FileSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 