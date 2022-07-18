if object_id('yw_TPJTToolResult') is null 
begin
CREATE TABLE yw_TPJTToolResult
(
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    Results		NVARCHAR(100) 	  NULL, 
    RevResults		NVARCHAR(100) 	  NULL, 
    RevDate		NCHAR(8) 	  NULL, 
    RevEndDate		NCHAR(8) 	  NULL, 
    TestRegDate		NCHAR(8) 	  NULL, 
    TestEndDate		NCHAR(8) 	  NULL, 
    LastUserSeq		INT 	  NULL, 
    LastDateTime		DATETIME 	  NULL
)
create unique clustered index idx_yw_TPJTToolResult on yw_TPJTToolResult(CompanySeq,PJTSeq,ToolSeq,Serl)
end


if object_id('yw_TPJTToolResultLog') is null 
begin
CREATE TABLE yw_TPJTToolResultLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PJTSeq		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    Serl		INT 	 NOT NULL, 
    Results		NVARCHAR(100) 	  NULL, 
    RevResults		NVARCHAR(100) 	  NULL, 
    RevDate		NCHAR(8) 	  NULL, 
    RevEndDate		NCHAR(8) 	  NULL, 
    TestRegDate		NCHAR(8) 	  NULL, 
    TestEndDate		NCHAR(8) 	  NULL, 
    LastUserSeq		INT 	  NULL, 
    LastDateTime		DATETIME 	  NULL
)
end


--drop table yw_TPJTToolResult 
--drop table yw_TPJTToolResultLog
