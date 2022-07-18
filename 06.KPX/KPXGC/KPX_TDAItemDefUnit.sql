if object_id('KPX_TDAItemDefUnit') is null 
begin 
CREATE TABLE KPX_TDAItemDefUnit 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    UMModuleSeq int NOT NULL,    
    STDUnitSeq int NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
create unique clustered index idx_KPX_TDAItemDefUnit on KPX_TDAItemDefUnit(CompanySeq,ItemSeq,UMModuleSeq) 
end



if object_id('KPX_TDAItemDefUnitLog') is null 
begin 
CREATE TABLE KPX_TDAItemDefUnitLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,   
    ItemSeq int NULL   , 
    UMModuleSeq int NULL   ,  
    STDUnitSeq int NULL   ,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,  
    LogPgmSeq int NULL   
) 
end 