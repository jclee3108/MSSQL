if object_id('KPX_TQCQAQualityAssuranceSpec') is null 
begin 
CREATE TABLE KPX_TQCQAQualityAssuranceSpec
(
    CompanySeq		INT 	 NOT NULL, 
    Serl            INT      NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
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
create unique clustered index idx_KPX_TQCQAQualityAssuranceSpec on KPX_TQCQAQualityAssuranceSpec(CompanySeq,Serl) 
end 

if object_id('KPX_TQCQAQualityAssuranceSpecLog') is null
begin 
CREATE TABLE KPX_TQCQAQualityAssuranceSpecLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    Serl            INT NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
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

