
if object_id('KPX_TDAItemFile') is null 
begin 
CREATE TABLE KPX_TDAItemFile 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    FileSeq int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 

create unique clustered index idx_KPX_TDAItemFile on KPX_TDAItemFile(CompanySeq,ItemSeq) 
end 

if object_id('KPX_TDAItemFileLog') is null 
begin
CREATE TABLE KPX_TDAItemFileLog 
(  
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,  
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,   
    ItemSeq int NULL   ,  
    FileSeq int NULL   ,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,  
    LogPgmSeq int NULL  
) 

end 