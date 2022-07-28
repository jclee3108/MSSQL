if OBJECT_ID('_TPDTestReportItemDetail') is null
begin 
CREATE TABLE _TPDTestReportItemDetail 
(   
    CompanySeq int NOT NULL,    
    Seq int NOT NULL,    
    Serl int NOT NULL,    
    Method nvarchar(100) NOT NULL,    
    ApplyFrDate nchar(8) NOT NULL,    
    ApplyToDate nchar(8) NOT NULL,    
    LastYn nchar(1) NOT NULL,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
CREATE UNIQUE INDEX IDXTemp_TPDTestReportItemDetail on _TPDTestReportItemDetail(CompanySeq, Seq, Serl)
end 

if OBJECT_ID('_TPDTestReportItemDetailLog') is null
begin 
CREATE TABLE _TPDTestReportItemDetailLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    Seq int NOT NULL,    
    Serl int NOT NULL,    
    Method nvarchar(100) NOT NULL,    
    ApplyFrDate nchar(8) NOT NULL,    
    ApplyToDate nchar(8) NOT NULL,    
    LastYn nchar(1) NOT NULL,    
    LastUserSeq int NULL   ,    LastDateTime datetime NULL   
) 

end 