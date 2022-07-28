if OBJECT_ID('_TPDAnalysisItem') is null
begin
CREATE TABLE _TPDAnalysisItem 
(   
    CompanySeq int NOT NULL,    
    AnalysisItemSeq int NOT NULL,    
    ItemCode int NULL   ,    
    SampleLocSeq int NULL   ,    
    ApplyDate nchar(8) NULL   ,   
    EndDate nchar(8) NULL   ,    
    StandVal decimal(19,5) NULL   ,    
    MaxVal decimal(19,5) NULL   ,    
    MinVal decimal(19,5) NULL   ,    
    Unit int NULL   ,    
    ItemType int NULL   ,    
    Spec nvarchar(100) NULL   ,    
    LactamTrend nchar(1) NULL   ,    
    LactamMaxVal decimal(19,5) NULL   ,    
    LactamMinVal decimal(19,5) NULL   ,    
    Serl int NULL   ,    
    LastDateTime datetime NULL   ,    
    LastUserSeq int NULL   ,    
    IsOIS_IF nchar(1) NULL   
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TPDAnalysisItem on _TPDAnalysisItem(CompanySeq, AnalysisItemSeq)
end 


if OBJECT_ID('_TPDAnalysisItemLog') is null 
begin
CREATE TABLE _TPDAnalysisItemLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    AnalysisItemSeq int NOT NULL,    
    ItemCode int NULL   ,    
    SampleLocSeq int NULL   ,    
    ApplyDate nchar(8) NULL   ,    
    EndDate nchar(8) NULL   ,    
    StandVal decimal(19,5) NULL   ,    
    MaxVal decimal(19,5) NULL   ,    
    MinVal decimal(19,5) NULL   ,    
    Unit int NULL   ,    
    ItemType int NULL   ,    
    Spec nvarchar(100) NULL   ,    
    LactamTrend nchar(1) NULL   ,    
    LactamMaxVal decimal(19,5) NULL   ,    
    LactamMinVal decimal(19,5) NULL   ,    
    Serl int NULL   ,    
    LastDateTime datetime NULL   ,    
    LastUserSeq int NULL   ,    
    IsOIS_IF nchar(1) NULL   
) 
end 

