if OBJECT_ID('_TPDTestExpReportList') is null
begin 
CREATE TABLE _TPDTestExpReportList 
(   
    CompanySeq int NOT NULL,    
    TestReportSeq int NOT NULL,    
    TestReportSerl int NOT NULL,    
    FactUnit int NULL   ,    
    SectionSeq int NULL   ,    
    SampleLocSeq int NULL   ,    
    AnalysisItemSeq int NULL   ,    
    ItemCodeName nvarchar(300) NULL   ,    
    UnitName nvarchar(300) NULL   ,    
    Spec nvarchar(300) NULL   ,    
    ResultVal nvarchar(300) NULL   ,    
    Method nvarchar(300) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TPDTestExpReportList on _TPDTestExpReportList(CompanySeq, TestReportSeq, TestReportSerl)
end 


if OBJECT_ID('_TPDTestExpReportListLog') is null 
begin
CREATE TABLE _TPDTestExpReportListLog 
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
    AnalysisItemSeq int NULL   ,    
    ItemCodeName nvarchar(300) NULL   ,    
    UnitName nvarchar(300) NULL   ,    
    Spec nvarchar(300) NULL   ,    
    ResultVal nvarchar(300) NULL   ,    
    Method nvarchar(300) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 
