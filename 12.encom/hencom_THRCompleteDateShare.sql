
if object_id('hencom_THRCompleteDateShare') is null
begin 
    CREATE TABLE hencom_THRCompleteDateShare
    (
        CompanySeq		INT 	 NOT NULL, 
        CompleteSeq		INT 	 NOT NULL, 
        ShareSerl		INT 	 NOT NULL, 
        EmpDeptType		INT 	 NOT NULL, 
        EmpDeptSeq		INT 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhencom_THRCompleteDateShare PRIMARY KEY CLUSTERED (CompanySeq ASC, CompleteSeq ASC, ShareSerl ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphencom_THRCompleteDateShare ON hencom_THRCompleteDateShare(CompanySeq, CompleteSeq, ShareSerl)
end 


if object_id('hencom_THRCompleteDateShareLog') is null
begin 
    CREATE TABLE hencom_THRCompleteDateShareLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        CompleteSeq		INT 	 NOT NULL, 
        ShareSerl		INT 	 NOT NULL, 
        EmpDeptType		INT 	 NOT NULL, 
        EmpDeptSeq		INT 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE  INDEX IDXTemphencom_THRCompleteDateShareLog ON hencom_THRCompleteDateShareLog (LogSeq)
end 