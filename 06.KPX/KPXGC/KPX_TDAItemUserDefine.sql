
if object_id('KPX_TDAItemUserDefine') is null
begin 
CREATE TABLE KPX_TDAItemUserDefine 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    MngSerl int NOT NULL,    
    MngValSeq int NULL   ,    
    MngValText nvarchar(200) NULL   ,    
    LastUserSeq int NOT NULL,    
    LastDateTime datetime NOT NULL,    
    PgmSeq int NULL   
) 
create unique clustered index idx_KPX_TDAItemUserDefine on KPX_TDAItemUserDefine(CompanySeq,ItemSeq,MngSerl) 
end 


if object_id('KPX_TDAItemUserDefineLog') is null 
begin 
CREATE TABLE KPX_TDAItemUserDefineLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    MngSerl int NOT NULL,    
    MngValSeq int NULL   ,    
    MngValText nvarchar(200) NULL   ,    
    LastUserSeq int NOT NULL,    
    LastDateTime datetime NOT NULL,    
    LogPgmSeq int NULL   ,    
    PgmSeq int NULL   
 ) 
end 