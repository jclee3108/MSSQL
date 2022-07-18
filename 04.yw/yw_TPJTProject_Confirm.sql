if object_id('yw_TPJTProject_Confirm') is null
begin
CREATE TABLE yw_TPJTProject_Confirm
(
    CompanySeq		INT 	 NOT NULL, 
    CfmSeq		INT 	 NOT NULL, 
    CfmSerl		INT 	 NOT NULL, 
    CfmSubSerl		INT 	 NOT NULL, 
    CfmSecuSeq		INT 	 NULL, 
    IsAuto		NCHAR(1) 	 NULL, 
    CfmCode		INT 	 NULL, 
    CfmDate		NCHAR(8) 	 NULL, 
    CfmEmpSeq		INT 	 NULL, 
    UMCfmReason		INT 	 NULL, 
    CfmReason		NVARCHAR(500) 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_yw_TPJTProject_Confirm on yw_TPJTProject_Confirm (CompanySeq,CfmSeq,CfmSerl,CfmSubSerl)
end 

if object_id('yw_TPJTProject_ConfirmLog') is null 
begin 
CREATE TABLE yw_TPJTProject_ConfirmLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    CfmSeq		INT 	 NOT NULL, 
    CfmSerl		INT 	 NOT NULL, 
    CfmSubSerl		INT 	 NOT NULL, 
    CfmSecuSeq		INT 	 NULL, 
    IsAuto		NCHAR(1) 	 NULL, 
    CfmCode		INT 	 NULL, 
    CfmDate		NCHAR(8) 	 NULL, 
    CfmEmpSeq		INT 	 NULL, 
    UMCfmReason		INT 	 NULL, 
    CfmReason		NVARCHAR(500) 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 
