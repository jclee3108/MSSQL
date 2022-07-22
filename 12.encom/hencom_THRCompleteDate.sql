
if object_id('hencom_THRCompleteDate') is null
begin 
    CREATE TABLE hencom_THRCompleteDate
    (
        CompanySeq		INT 	 NOT NULL, 
        CompleteSeq		INT 	 NOT NULL, 
        UMCompleteType		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        ManagementAmt		DECIMAL(19,5) 	 NOT NULL, 
        AlarmDay		INT 	 NOT NULL, 
        SrtDate		NCHAR(8) 	 NOT NULL, 
        EndDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_THRCompleteDate PRIMARY KEY CLUSTERED (CompanySeq ASC, CompleteSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_THRCompleteDate ON hencom_THRCompleteDate(CompanySeq, CompleteSeq)
end 



if object_id('hencom_THRCompleteDateLog') is null
begin 
    CREATE TABLE hencom_THRCompleteDateLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CompleteSeq		INT 	 NOT NULL, 
        UMCompleteType		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        ManagementAmt		DECIMAL(19,5) 	 NOT NULL, 
        AlarmDay		INT 	 NOT NULL, 
        SrtDate		NCHAR(8) 	 NOT NULL, 
        EndDate		NCHAR(8) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_THRCompleteDateLog ON hencom_THRCompleteDateLog (LogSeq)
end 