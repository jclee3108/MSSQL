
if OBJECT_ID('_TPDTestReport')is null 
begin 
CREATE TABLE _TPDTestReport 
(   
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    NoticDate nchar(8) NULL   ,    
    AnalysisDate nchar(8) NULL   ,    
    ItemTakeDate nchar(8) NULL   ,    
    CustSeq int NULL   ,    
    ItemSeq int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

CREATE UNIQUE CLUSTERED INDEX IDXTemp_TPDTestReport on _TPDTestReport(CompanySeq, TestReportSeq)
end

if OBJECT_ID('_TPDTestReportLog')is null 
begin 
CREATE TABLE _TPDTestReportLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    NoticDate nchar(8) NULL   ,    
    AnalysisDate nchar(8) NULL   ,    
    ItemTakeDate nchar(8) NULL   ,    
    CustSeq int NULL   ,    
    ItemSeq int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 

