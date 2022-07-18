
if object_id('KPX_TDAItemClass') is null 
begin 
CREATE TABLE KPX_TDAItemClass 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    UMajorItemClass int NOT NULL,   
    UMItemClass int NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,   
    PgmSeq int NULL   
) 
create unique clustered index idx_KPX_TDAItemClass on KPX_TDAItemClass(CompanySeq,ItemSeq,UMajorItemClass) 
end 

if object_id('KPX_TDAItemClassLog') is null
begin
CREATE TABLE KPX_TDAItemClassLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,   
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    ItemSeq int NULL   ,    
    UMajorItemClass int NULL   ,    
    UMItemClass int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    LogPgmSeq int NULL   ,    
    PgmSeq int NULL   
) 
end 