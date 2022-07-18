IF OBJECT_ID('KPX_TPDSFCProdPackReport') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackReport
(
    CompanySeq		INT 	 NOT NULL, 
    PackReportSeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PackDate		NCHAR(8) 	 NOT NULL, 
    ReportNo		NVARCHAR(100) 	 NOT NULL, 
    OutWHSeq		INT 	 NOT NULL, 
    InWHSeq		INT 	 NOT NULL, 
    UMProgType		INT 	 NOT NULL, 
    DrumOutWHSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TPDSFCProdPackReport on KPX_TPDSFCProdPackReport(CompanySeq,PackReportSeq) 
end 


IF OBJECT_ID('KPX_TPDSFCProdPackReportLog') is null 
begin 
CREATE TABLE KPX_TPDSFCProdPackReportLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackReportSeq		INT 	 NOT NULL, 
    FactUnit		INT 	 NOT NULL, 
    PackDate		NCHAR(8) 	 NOT NULL, 
    ReportNo		NVARCHAR(100) 	 NOT NULL, 
    OutWHSeq		INT 	 NOT NULL, 
    InWHSeq		INT 	 NOT NULL, 
    UMProgType		INT 	 NOT NULL, 
    DrumOutWHSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 