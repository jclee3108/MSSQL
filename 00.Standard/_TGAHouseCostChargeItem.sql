
if OBJECT_ID('_TGAHouseCostChargeItem') is null 
begin 
CREATE TABLE _TGAHouseCostChargeItem 
(   
    CompanySeq int NOT NULL,   
    CalcYm nchar(6) NOT NULL,   
    HouseSeq int NOT NULL,  
    CostType int NOT NULL,    
    HouseClass int NULL   ,    
    CfmYn nchar(1) NULL   ,   
    ChargeAmt decimal(19,5) NULL   ,  
    LastDateTime datetime NOT NULL,   
    LastUserSeq int NOT NULL
) 
CREATE UNIQUE INDEX IDXTemp_TGAHouseCostChargeItem on _TGAHouseCostChargeItem(CompanySeq, CalcYm, HouseSeq, CostType)
end 

if OBJECT_ID('_TGAHouseCostChargeItemLog') is null 
begin 
CREATE TABLE _TGAHouseCostChargeItemLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    CalcYm nchar(6) NOT NULL,   
    HouseSeq int NOT NULL,   
    CostType int NOT NULL,   
    HouseClass int NULL   ,   
    CfmYn nchar(1) NULL   ,    
    ChargeAmt decimal(19,5) NULL   ,   
    LastDateTime datetime NOT NULL,   
    LastUserSeq int NOT NULL
) 
end 


