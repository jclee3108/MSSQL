if object_id('KPX_TQCQAAnalysisType') is null 
begin 
CREATE TABLE KPX_TQCQAAnalysisType
(
    CompanySeq		INT 	 NOT NULL, 
    QAAnalysisType		INT 	 NOT NULL, 
    QAAnalysisTypeNo		NVARCHAR(100) 	 NOT NULL, 
    QAAnalysisTypeName		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL, 
)
create unique clustered index idx_KPX_TQCQAAnalysisType on KPX_TQCQAAnalysisType(CompanySeq,QAAnalysisType) 
end 


if object_id('KPX_TQCQAAnalysisTypeLog') is null 
begin

CREATE TABLE KPX_TQCQAAnalysisTypeLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    QAAnalysisType		INT 	 NOT NULL, 
    QAAnalysisTypeNo		NVARCHAR(100) 	 NOT NULL, 
    QAAnalysisTypeName		NVARCHAR(100) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsUse		NCHAR(1) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 