if object_id('KPX_TQCQASpec') is null 
begin 
CREATE TABLE KPX_TQCQASpec
(
    CompanySeq		INT 	 NOT NULL, 
    Serl            INT      NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    TestItemSeq		INT 	 NOT NULL, 
    QAAnalysisType		INT 	 NOT NULL, 
    SMInputType		INT 	 NULL, 
    LowerLimit		NVARCHAR(100) 	 NULL, 
    UpperLimit		NVARCHAR(100) 	 NULL, 
    QCUnit		INT 	 NOT NULL, 
    SDate		NCHAR(8) 	 NOT NULL, 
    EDate		NCHAR(8) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    IsProd		NCHAR(1) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TQCQASpec on KPX_TQCQASpec(CompanySeq,Serl) 
end 

if object_id('KPX_TQCQASpecLog') is null
begin 
CREATE TABLE KPX_TQCQASpecLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Serl            INT NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    TestItemSeq		INT 	 NOT NULL, 
    QAAnalysisType		INT 	 NOT NULL, 
    SMInputType		INT 	 NULL, 
    LowerLimit		NVARCHAR(100) 	 NULL, 
    UpperLimit		NVARCHAR(100) 	 NULL, 
    QCUnit		INT 	 NOT NULL, 
    SDate		NCHAR(8) 	 NOT NULL, 
    EDate		NCHAR(8) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    RegEmpSeq		INT 	 NOT NULL, 
    RegDateTime		DATETIME 	 NOT NULL, 
    IsProd		NCHAR(1) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 




