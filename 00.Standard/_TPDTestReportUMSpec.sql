if OBJECT_ID('_TPDTestReportUMSpec') is null 
begin 
CREATE TABLE _TPDTestReportUMSpec 
(   
    CompanySeq int NULL   ,    
    TestReportSeq int NULL   ,    
    UMSpec int NULL   ,    
    UMSpecValue nvarchar(100) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

CREATE UNIQUE INDEX IDXTemp_TPDTestReportUMSpec on _TPDTestReportUMSpec(CompanySeq, TestReportSeq, UMSpec)
end 

if OBJECT_ID('_TPDTestReportUMSpecLog') is null 
begin 
CREATE TABLE _TPDTestReportUMSpecLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NULL   ,    
    LogDateTime datetime NULL   ,    
    LogType nchar(1) NULL   ,    
    CompanySeq int NULL   ,    
    TestReportSeq int NULL   ,    
    UMSpec int NULL   ,    
    UMSpecValue nvarchar(100) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 

