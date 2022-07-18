if object_id('KPXCM_TEQChangeRequestCHE_Confirm') is null

begin 
CREATE TABLE KPXCM_TEQChangeRequestCHE_Confirm
(
    CompanySeq		INT 	 NOT NULL, 
    CfmSeq		INT 	 NOT NULL, 
    CfmSerl		INT 	 NOT NULL, 
    CfmSubSerl		INT 	 NOT NULL, 
    CfmSecuSeq		INT 	 NOT NULL, 
    IsAuto		NCHAR(1) 	 NOT NULL, 
    CfmCode		INT 	 NOT NULL, 
    CfmDate		NCHAR(8) 	 NOT NULL, 
    CfmEmpSeq		INT 	 NOT NULL, 
    UMCfmReason		INT 	 NOT NULL, 
    CfmReason		NVARCHAR(500) 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 

)
create unique clustered index idx_KPXCM_TEQChangeRequestCHE_Confirm on KPXCM_TEQChangeRequestCHE_Confirm(CompanySeq,CfmSeq,CfmSerl,CfmSubSerl) 
end 


if object_id('KPXCM_TEQChangeRequestCHE_ConfirmLog') is null

begin 
CREATE TABLE KPXCM_TEQChangeRequestCHE_ConfirmLog
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
    CfmSecuSeq		INT 	 NOT NULL, 
    IsAuto		NCHAR(1) 	 NOT NULL, 
    CfmCode		INT 	 NOT NULL, 
    CfmDate		NCHAR(8) 	 NOT NULL, 
    CfmEmpSeq		INT 	 NOT NULL, 
    UMCfmReason		INT 	 NOT NULL, 
    CfmReason		NVARCHAR(500) 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 