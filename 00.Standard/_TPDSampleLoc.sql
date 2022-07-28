if OBJECT_ID('_TPDSampleLoc') is null 

begin
CREATE TABLE _TPDSampleLoc 
(   
    CompanySeq int NOT NULL,    
    SampleLocSeq int NOT NULL,    
    SampleLoc nvarchar(10) NULL   ,    
    FactUnit int NULL   ,    
    SectionSeq int NULL   ,    
    ApplyDate nchar(8) NULL   ,    
    MatDiv int NULL   ,    
    Serl int NULL   ,    
    Remark nvarchar(100) NULL   ,    
    EndDate nchar(8) NULL   ,    
    Time01 nchar(1) NULL   ,    
    Time03 nchar(1) NULL   ,    
    Time05 nchar(1) NULL   ,    
    Time07 nchar(1) NULL   ,    
    Time09 nchar(1) NULL   ,    
    Time11 nchar(1) NULL   ,    
    Time13 nchar(1) NULL   ,    
    Time15 nchar(1) NULL   ,    
    Time17 nchar(1) NULL   ,    
    Time19 nchar(1) NULL   ,    
    Time21 nchar(1) NULL   ,    
    Time23 nchar(1) NULL   ,    
    LastDateTime datetime NULL   ,    
    LastUserSeq int NULL   ,    
    AllDay nchar(1) NULL   ,    
    IsMon nchar(1) NULL   ,    
    IsTue nchar(1) NULL   ,    
    IsWed nchar(1) NULL   ,    
    IsThu nchar(1) NULL   ,    
    IsFri nchar(1) NULL   ,    
    IsSat nchar(1) NULL   ,    
    IsSun nchar(1) NULL   
) 

CREATE UNIQUE CLUSTERED INDEX idx_TPDSampleLoc on _TPDSampleLoc(CompanySeq, SampleLocSeq)
end 


if OBJECT_ID('_TPDSampleLocLog') is null 
begin
CREATE TABLE _TPDSampleLocLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    SampleLocSeq int NOT NULL,    
    SampleLoc nvarchar(10) NULL   ,    
    FactUnit int NULL   ,    
    SectionSeq int NULL   ,    
    ApplyDate nchar(8) NULL   ,    
    MatDiv int NULL   ,    
    Serl int NULL   ,    
    Remark nvarchar(100) NULL   ,    
    EndDate nchar(8) NULL   ,    
    Time01 nchar(1) NULL   ,    
    Time03 nchar(1) NULL   ,    
    Time05 nchar(1) NULL   ,    
    Time07 nchar(1) NULL   ,    
    Time09 nchar(1) NULL   ,    
    Time11 nchar(1) NULL   ,    
    Time13 nchar(1) NULL   ,    
    Time15 nchar(1) NULL   ,    
    Time17 nchar(1) NULL   ,    
    Time19 nchar(1) NULL   ,    
    Time21 nchar(1) NULL   ,    
    Time23 nchar(1) NULL   ,    
    LastDateTime datetime NULL   ,    
    LastUserSeq int NULL   ,    
    AllDay nchar(1) NULL   ,    
    IsMon nchar(1) NULL   ,    
    IsTue nchar(1) NULL   ,    
    IsWed nchar(1) NULL   ,    
    IsThu nchar(1) NULL   ,    
    IsFri nchar(1) NULL   ,    
    IsSat nchar(1) NULL   ,    
    IsSun nchar(1) NULL   
) 
end