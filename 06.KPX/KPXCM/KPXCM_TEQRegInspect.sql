

if object_id('KPXCM_TEQRegInspect') is null
begin 
    CREATE TABLE KPXCM_TEQRegInspect
    (
        CompanySeq		INT 	 NOT NULL, 
        RegInspectSeq		INT 	 NOT NULL, 
        ToolSeq		INT 	 NOT NULL, 
        UMQCSeq		INT 	 NOT NULL, 
        UMQCCompany		INT 	 NULL, 
        UMLicense		INT 	 NULL, 
        EmpSeq		INT 	 NULL, 
        UMQCCycle		INT 	 NOT NULL, 
        LastQCDate		NCHAR(8) 	 NOT NULL, 
        Spec		NVARCHAR(100) 	 NULL, 
        QCNo		NVARCHAR(100) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL 
    )
    create unique clustered index idx_KPXCM_TEQRegInspect on KPXCM_TEQRegInspect(CompanySeq,RegInspectSeq) 
end 


if object_id('KPXCM_TEQRegInspectLog') is null
begin 
    CREATE TABLE KPXCM_TEQRegInspectLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        RegInspectSeq		INT 	 NOT NULL, 
        ToolSeq		INT 	 NOT NULL, 
        UMQCSeq		INT 	 NOT NULL, 
        UMQCCompany		INT 	 NULL, 
        UMLicense		INT 	 NULL, 
        EmpSeq		INT 	 NULL, 
        UMQCCycle		INT 	 NOT NULL, 
        LastQCDate		NCHAR(8) 	 NOT NULL, 
        Spec		NVARCHAR(100) 	 NULL, 
        QCNo		NVARCHAR(100) 	 NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
end 
