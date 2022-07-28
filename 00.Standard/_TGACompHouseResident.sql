if OBJECT_ID('_TGACompHouseResident') is null 
begin 
CREATE TABLE _TGACompHouseResident 
(   
    CompanySeq int NOT NULL,    
    HouseSeq int NOT NULL,    
    ResidentSeq int NOT NULL, 
    EmpSeq int NOT NULL,    
    EnterDate nchar(8) NOT NULL, 
    LeavingDate nchar(8) NOT NULL,
    LeavingReason nvarchar(100) NULL   ,  
    FinalUseYn nchar(1) NULL   ,   
    TmpUseYn nchar(1) NULL   , 
    Remark nvarchar(500) NULL   ,  
    LastDateTime datetime NOT NULL,   
    LastUserSeq int NOT NULL
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TGACompHouseResident on _TGACompHouseResident(CompanySeq, HouseSeq, ResidentSeq)
end 

if OBJECT_ID('_TGACompHouseResidentLog') is null 
begin 
CREATE TABLE _TGACompHouseResidentLog 
(  
 LogSeq int identity NOT NULL,
    LogUserSeq int NOT NULL,   
    LogDateTime datetime NOT NULL,   
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,   
    HouseSeq int NOT NULL,  
    ResidentSeq int NOT NULL,    
    EmpSeq int NOT NULL,    
    EnterDate nchar(8) NOT NULL,  
    LeavingDate nchar(8) NOT NULL, 
    LeavingReason nvarchar(100) NULL   ,    
    FinalUseYn nchar(1) NULL   ,   
    TmpUseYn nchar(1) NULL   ,  
    Remark nvarchar(500) NULL   ,  
    LastDateTime datetime NOT NULL,   
    LastUserSeq int NOT NULL
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TGACompHouseResidentLog on _TGACompHouseResidentLog(LogSeq)
end 
