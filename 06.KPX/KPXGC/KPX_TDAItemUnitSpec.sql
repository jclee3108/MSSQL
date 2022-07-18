if object_id('KPX_TDAItemUnitSpec') is null 
begin 
CREATE TABLE KPX_TDAItemUnitSpec 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    UnitSeq int NOT NULL,    
    UMSpecCode int NOT NULL,    
    SpecUnit nvarchar(20) NOT NULL,    
    Value decimal(19,5) NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
create unique clustered index idx_KPX_TDAItemUnitSpec on KPX_TDAItemUnitSpec(CompanySeq,ItemSeq,UnitSeq,UMSpecCode) 
end 

if object_id('KPX_TDAItemUnitSpeclog') is null
begin
CREATE TABLE KPX_TDAItemUnitSpeclog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,   
    LogDateTime datetime NOT NULL, 
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,  
    ItemSeq int NOT NULL,  
    UnitSeq int NOT NULL,  
    UMSpecCode int NULL   , 
    SpecUnit nvarchar(20) NOT NULL,  
    Value decimal(19,5) NULL   ,   
    LastUserSeq int NULL   ,  
    LastDateTime datetime NULL   ,   
    LogPgmSeq int NULL   
) 
end 