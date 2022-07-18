if object_id('KPXCM_TEQRegInspectChg') is null
begin 

    CREATE TABLE KPXCM_TEQRegInspectChg
    (
        CompanySeq		INT 	 NOT NULL, 
        RegInspectSeq		INT 	 NOT NULL, 
        QCPlanDate          NCHAR(8) NOT NULL, 
        ReplaceDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(200) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index idx_KPXCM_TEQRegInspectChg on KPXCM_TEQRegInspectChg(CompanySeq,RegInspectSeq,QCPlanDate) 
end 


if object_id('KPXCM_TEQRegInspectChgLog') is null
begin 
    CREATE TABLE KPXCM_TEQRegInspectChgLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        RegInspectSeq		INT 	 NOT NULL, 
        QCPlanDate          NCHAR(8) NOT NULL, 
        ReplaceDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(200) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
end 




