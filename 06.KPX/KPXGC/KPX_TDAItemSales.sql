
if object_id('KPX_TDAItemSales') is null 
begin 
CREATE TABLE KPX_TDAItemSales 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    IsVat nchar(1) NOT NULL,    
    SMVatKind int NOT NULL,   
    SMVatType int NOT NULL,   
    IsOption nchar(1) NOT NULL, 
    IsSet nchar(1) NOT NULL,    
    LastUserSeq int NULL   ,  
    LastDateTime datetime NULL   ,  
    Guaranty decimal(19,5) NULL   ,  
    HSCode nvarchar(20) NULL   ,  
    PgmSeq int NULL   
) 
create unique clustered index idx_KPX_TDAItemSales on KPX_TDAItemSales(CompanySeq,ItemSeq) 
end 


if object_id('KPX_TDAItemSalesLog') is null 
begin 
CREATE TABLE KPX_TDAItemSalesLog 
(
    LogSeq int identity NOT NULL,
    LogUserSeq int NOT NULL,
    LogDateTime datetime NOT NULL,
    LogType nchar(1) NOT NULL,
    CompanySeq int NOT NULL,
    ItemSeq int NOT NULL,
    IsVat nchar(1) NOT NULL,
    SMVatKind int NOT NULL,  
    SMVatType int NOT NULL,    
    IsOption nchar(1) NOT NULL,   
    IsSet nchar(1) NOT NULL, 
    LastUserSeq int NULL   ,  
    LastDateTime datetime NULL   ,  
    Guaranty decimal(19,5) NULL   ,    
    HSCode nvarchar(20) NULL   ,   
    LogPgmSeq int NULL   ,  
    PgmSeq int NULL   
) 
end 


