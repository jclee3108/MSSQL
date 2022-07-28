if OBJECT_ID('_TGACompHouseCostDeducAmt') is null 
begin 
CREATE TABLE _TGACompHouseCostDeducAmt 
(   
    CompanySeq int NULL   ,    
    EmpSeq int NULL   ,  
    HouseSeq int NULL   ,    
    CalcYm nchar(6) NULL   ,  
    IsPay nchar(1) NULL   ,  
    LastUserSeq int NULL   ,  
    LastDateTime datetime NULL   ,   
    Seq int NULL   
) 
CREATE UNIQUE INDEX IDXTemp_TGACompHouseCostDeducAmt on _TGACompHouseCostDeducAmt(CompanySeq, EmpSeq, HouseSeq, CalcYm)
end 


if OBJECT_ID('_TGACompHouseCostDeducAmtlog') is null 
begin 
CREATE TABLE _TGACompHouseCostDeducAmtlog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NULL   ,    
    LogDateTime datetime NULL   ,   
    LogType nchar(1) NULL   ,  
    CompanySeq int NULL   ,   
    EmpSeq int NULL   ,   
    HouseSeq int NULL   ,   
    CalcYm nchar(6) NULL   ,    
    IsPay nchar(1) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    Seq int NULL   
) 

end 