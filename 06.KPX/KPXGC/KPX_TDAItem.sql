if object_id('KPX_TDAItem') is null
begin
CREATE TABLE KPX_TDAItem 
(   
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    ItemName nvarchar(200) NOT NULL,    
    TrunName nvarchar(200) NOT NULL,    
    ItemNo nvarchar(100) NOT NULL,    
    AssetSeq int NOT NULL,    
    SMStatus int NOT NULL,    
    ItemSName nvarchar(100) NOT NULL,    
    ItemEngName nvarchar(200) NOT NULL,    
    ItemEngSName nvarchar(100) NOT NULL,    
    Spec nvarchar(100) NOT NULL,    
    SMABC int NOT NULL,    
    UnitSeq int NOT NULL,    
    DeptSeq int NOT NULL,    
    EmpSeq int NOT NULL,    
    ModelSeq int NOT NULL,    
    SMInOutKind int NOT NULL,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    IsInherit nchar(1) NULL   ,    
    RegUserSeq int NULL   ,    
    RegDateTime datetime NULL   ,    
    LaunchDate nchar(8) NULL   ,    
    PgmSeq int NULL   
) 
create unique clustered index idx_KPX_TDAItem on KPX_TDAItem(CompanySeq,ItemSeq) 
end 

if object_id('KPX_TDAItemLog') is null 
begin 
CREATE TABLE KPX_TDAItemLog 
(   
    LogSeq int identity NOT NULL,   
    LogUserSeq int NOT NULL,   
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    ItemName nvarchar(200) NOT NULL,    
    TrunName nvarchar(200) NOT NULL,    
    ItemNo nvarchar(100) NOT NULL,    
    AssetSeq int NOT NULL,    
    SMStatus int NOT NULL,    
    ItemSName nvarchar(100) NOT NULL,   
    ItemEngName nvarchar(200) NOT NULL,    
    ItemEngSName nvarchar(100) NOT NULL,    
    Spec nvarchar(100) NOT NULL,    
    SMABC int NOT NULL,    
    UnitSeq int NOT NULL,    
    DeptSeq int NOT NULL,    
    EmpSeq int NOT NULL,    
    ModelSeq int NOT NULL,    
    SMInOutKind int NOT NULL,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,    
    IsInherit nchar(1) NULL   ,    
    RegUserSeq int NULL   ,    
    RegDateTime datetime NULL   ,    
    LaunchDate nchar(8) NULL   ,    
    LogPgmSeq int NULL   ,    
    PgmSeq int NULL   
) 
end 