IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMng_Confirm' AND xtype = 'U' )
begin 
CREATE TABLE DTI_TSLContractMng_Confirm
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
    CfmReason		NVARCHAR(1000) 	 NULL, 
    LastDateTime		DATETIME 	 NULL, 
CONSTRAINT PKDTI_TSLContractMng_Confirm PRIMARY KEY CLUSTERED (CompanySeq ASC, CfmSeq ASC, CfmSerl ASC, CfmSubSerl ASC)
)
end

IF not EXISTS (SELECT * FROM Sysobjects where Name = 'DTI_TSLContractMng_ConfirmLog' AND xtype = 'U' )
begin
CREATE TABLE DTI_TSLContractMng_ConfirmLog
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
    CfmReason		NVARCHAR(1000) 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
CREATE UNIQUE CLUSTERED INDEX IDXTempDTI_TSLContractMng_ConfirmLog ON DTI_TSLContractMng_ConfirmLog (LogSeq)
end
