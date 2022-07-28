
if OBJECT_ID('_TGAHouseCostCalcInfo') is null 
begin 

CREATE TABLE _TGAHouseCostCalcInfo 
(   
    CompanySeq int NOT NULL,    
    CalcYm nchar(6) NOT NULL,    
    HouseSeq int NOT NULL,    
    CheckQty decimal(19,5) NULL   ,    
    UseQty decimal(19,5) NULL   ,    
    WaterCost decimal(19,5) NULL   ,    
    GeneralCost decimal(19,5) NULL   ,    
    LastDateTime datetime NOT NULL,    
    LastUserSeq int NOT NULL,    
    EmpSeq int NULL   ,    
    DeptSeq int NULL   
) 
CREATE UNIQUE INDEX IDXTemp_TGAHouseCostCalcInfo on _TGAHouseCostCalcInfo(CompanySeq, CalcYm, HouseSeq)
end 


if OBJECT_ID('_TGAHouseCostCalcInfoLog') is null 
begin 
CREATE TABLE _TGAHouseCostCalcInfoLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    CalcYm nchar(6) NOT NULL,    
    HouseSeq int NOT NULL,    
    CheckQty decimal(19,5) NULL   ,    
    UseQty decimal(19,5) NULL   ,    
    WaterCost decimal(19,5) NULL   ,    
    GeneralCost decimal(19,5) NULL   ,    
    LastDateTime datetime NOT NULL,    
    LastUserSeq int NOT NULL,    
    EmpSeq int NULL   ,    
    DeptSeq int NULL   
) 
CREATE UNIQUE INDEX IDXTemp_TGAHouseCostCalcInfoLog on _TGAHouseCostCalcInfoLog(LogSeq)
end 