if OBJECT_ID('_TGACompHouseCostMaster') is null 
begin 
CREATE TABLE _TGACompHouseCostMaster 
(   
    CompanySeq int NOT NULL,    
    CostSeq int NOT NULL,    
    HouseClass int NOT NULL,    
    CostType int NOT NULL,    
    CalcType int NOT NULL,    
    PackageAmt decimal(19,5) NULL   ,    
    ApplyFrDate nchar(6) NOT NULL,    
    ApplyToDate nchar(6) NOT NULL,    
    FreeApplyYn nchar(1) NULL   ,    
    CalcPointType int NULL   ,    
    AmtCalcType int NULL   ,    
    OrderNo int NULL   ,    
    Remark nvarchar(500) NULL   ,    
    LastDateTime datetime NOT NULL,    
    LastUserSeq int NOT NULL
) 

CREATE UNIQUE INDEX IDXTemp_TGACompHouseCostMaster on _TGACompHouseCostMaster(CompanySeq, CostSeq)

end 

if OBJECT_ID('_TGACompHouseCostMasterLog') is null 
begin 
CREATE TABLE _TGACompHouseCostMasterLog 
(   
    LogSeq int IDENTITY(1,1) NOT NULL, 
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    CostSeq int NOT NULL,    
    HouseClass int NOT NULL,    
    CostType int NOT NULL,    
    CalcType int NOT NULL,    
    PackageAmt decimal(19,5) NULL   ,    
    ApplyFrDate nchar(6) NOT NULL,    
    ApplyToDate nchar(6) NOT NULL,    
    FreeApplyYn nchar(1) NULL   ,    
    CalcPointType int NULL   ,    
    AmtCalcType int NULL   ,    
    OrderNo int NULL   ,    
    Remark nvarchar(500) NULL   ,    
    LastDateTime datetime NOT NULL,    
    LastUserSeq int NOT NULL
) 
end
