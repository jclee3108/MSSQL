
if object_id('KPX_TDAItemUnit') is null 
begin 
CREATE TABLE KPX_TDAItemUnit 
(   
    CompanySeq int NOT NULL,  
    ItemSeq int NOT NULL,  
    UnitSeq int NOT NULL,   
    BarCode nvarchar(100) NULL   , 
    ConvNum decimal(19,5) NULL   ,   
    ConvDen decimal(19,5) NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,   
    TransConvQty decimal(19,5) NULL   
) 
create unique clustered index idx_KPX_TDAItemUnit on KPX_TDAItemUnit(CompanySeq,ItemSeq,UnitSeq) 
end 


if object_id('KPX_TDAItemUnitLog') is null 
begin 
CREATE TABLE KPX_TDAItemUnitLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    ItemSeq int NULL   ,    
    UnitSeq int NULL   ,    
    BarCode nvarchar(100) NULL   ,    
    ConvNum decimal(19,5) NULL   ,    
    ConvDen decimal(19,5) NULL   ,    
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,    
    TransConvQty decimal(19,5) NULL   ,    
    LogPgmSeq int NULL   
) 
end 