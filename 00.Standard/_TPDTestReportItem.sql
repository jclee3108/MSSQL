if OBJECT_ID('_TPDTestReportItem') is null
begin 
CREATE TABLE _TPDTestReportItem 
(   
    CompanySeq int NOT NULL,    
    Seq int NOT NULL,    
    ItemSeq int NOT NULL,    
    ItemCode int NOT NULL,    
    Remark nvarchar(500) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

CREATE UNIQUE INDEX IDXTemp_TPDTestReportItem on _TPDTestReportItem(CompanySeq, Seq)
end 

if OBJECT_ID('_TPDTestReportItemLog') is null 
begin 
CREATE TABLE _TPDTestReportItemLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    Seq int NOT NULL,    
    ItemSeq int NOT NULL,    
    ItemCode int NOT NULL,    
    Remark nvarchar(500) NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
end 

