if OBJECT_ID('_TGACompHouseMaster') is null 
begin 
CREATE TABLE _TGACompHouseMaster 
(   
    CompanySeq int NOT NULL,    
    HouseSeq int NOT NULL,    
    HouseClass int NOT NULL,    
    DongName nvarchar(4) NOT NULL,    
    DongSerl int NOT NULL,    
    HoName nvarchar(30) NOT NULL,    
    PrivateSize decimal(19,5) NULL   ,    
    RegisterySize decimal(19,5) NULL   ,    
    PurchaseDate nchar(8) NOT NULL,    OwnerType int NULL   ,    
    HouseType int NULL   ,    
    UseYn nchar(1) NULL   ,    
    UseType int NOT NULL,    
    Remark nvarchar(500) NULL   ,    
    LastDateTime datetime NOT NULL,    
    LastUserSeq int NOT NULL
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TGACompHouseMaster on _TGACompHouseMaster(CompanySeq, HouseSeq)
end 

if OBJECT_ID('_TGACompHouseMasterLog') is null 
begin 
CREATE TABLE _TGACompHouseMasterLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,  
    HouseSeq int NOT NULL, 
    HouseClass int NOT NULL, 
    DongName nvarchar(4) NOT NULL,  
    DongSerl int NOT NULL,   
    HoName nvarchar(30) NOT NULL,  
    PrivateSize decimal(19,5) NULL   ,
    RegisterySize decimal(19,5) NULL   , 
    PurchaseDate nchar(8) NOT NULL,  
    OwnerType int NULL   ,   
    HouseType int NULL   ,
    UseYn nchar(1) NULL   , 
    UseType int NOT NULL,   
    Remark nvarchar(500) NULL   ,  
    LastDateTime datetime NOT NULL,  
    LastUserSeq int NOT NULL
) 
CREATE UNIQUE CLUSTERED INDEX IDXTemp_TGACompHouseMasterLog on _TGACompHouseMasterLog(LogSeq)
end 


