if OBJECT_ID('_TPDTestReportD') is null 
begin 
CREATE TABLE _TPDTestReportD 
(   
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    TestReportSerl int NOT NULL,    
    FactUnit int NULL   ,    
    SectionSeq int NULL   ,    
    SampleLocSeq int NULL   ,    
    ItemCode int NULL   ,    
    Unit int NULL   ,    
    ResultVal nvarchar(100) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

CREATE UNIQUE CLUSTERED INDEX IDXTemp_TPDTestReportD on _TPDTestReportD(CompanySeq, TestReportSeq, TestReportSerl)
end 

if OBJECT_ID('_TPDTestReportDLog') is null
begin 
CREATE TABLE _TPDTestReportDLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    TestReportSerl int NOT NULL,    
    FactUnit int NULL   ,    
    SectionSeq int NULL   ,    
    SampleLocSeq int NULL   ,    
    ItemCode int NULL   ,    
    Unit int NULL   ,    
    ResultVal nvarchar(100) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 
