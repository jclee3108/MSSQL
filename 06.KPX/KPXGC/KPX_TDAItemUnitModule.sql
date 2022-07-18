
if object_id('KPX_TDAItemUnitModule') is null 
begin 
CREATE TABLE KPX_TDAItemUnitModule 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    UnitSeq int NOT NULL,    
    UMModuleSeq int NOT NULL,    
    IsUsed nchar(1) NOT NULL,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
create unique clustered index idx_KPX_TDAItemUnitModule on KPX_TDAItemUnitModule(CompanySeq,ItemSeq,UnitSeq,UMModuleSeq) 
end 

if object_id('KPX_TDAItemUnitModuleLog') is null 
begin 
CREATE TABLE KPX_TDAItemUnitModuleLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    UnitSeq int NOT NULL,    
    UMModuleSeq int NOT NULL,    
    IsUsed nchar(1) NOT NULL,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    LogPgmSeq int NULL   
) 


end 