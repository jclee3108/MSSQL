if OBJECT_ID('_TPDTestExpReport') is null 
begin
CREATE TABLE _TPDTestExpReport 
(   
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    UMSpec int NOT NULL,    
    UMSpecValue nvarchar(300) NULL   ,    
    AnalysisDate nchar(8) NULL   ,    
    RgstDate nchar(8) NULL   ,    
    RgstEmpSeq int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

CREATE UNIQUE CLUSTERED INDEX IDXTemp_TPDTestExpReport on _TPDTestExpReport(CompanySeq, TestReportSeq, UMSpec)
end 

if OBJECT_ID('_TPDTestExpReportLog') is null 
begin
CREATE TABLE _TPDTestExpReportLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    UMSpec int NOT NULL,    
    UMSpecValue nvarchar(300) NULL   ,    
    AnalysisDate nchar(8) NULL   ,    
    RgstDate nchar(8) NULL   ,    
    RgstEmpSeq int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 


