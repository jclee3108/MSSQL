
if object_id('KPX_TDAItemRemark') is null 
begin 
CREATE TABLE KPX_TDAItemRemark 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    ItemRemark nvarchar(1000) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
create unique clustered index idx_KPX_TDAItemRemark on KPX_TDAItemRemark(CompanySeq,ItemSeq) 
end 


if object_id('KPX_TDAItemRemarkLog') is null 
begin
CREATE TABLE KPX_TDAItemRemarkLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,   
    CompanySeq int NULL   ,  
    ItemSeq int NOT NULL,    
    ItemRemark nvarchar(1000) NULL   ,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,  
    LogPgmSeq int NULL   
) 


end 