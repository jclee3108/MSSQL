if object_id('_TDAUMToolKindTree') is null 
begin 
    CREATE TABLE _TDAUMToolKindTree 
    (   
        CompanySeq int NOT NULL,    
        UMToolKind int NOT NULL,    
        UpperUMToolKind int NOT NULL,    
        Sort int NULL   ,    
        Level int NULL   ,    
        NodeImg int NULL   ,    
        GongjongSeq int NOT NULL,    
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL
    ) 
    CREATE UNIQUE INDEX IDXTemp_TDAUMToolKindTree on _TDAUMToolKindTree(CompanySeq, UMToolKind, UpperUMToolKind)
end 

if object_id('_TDAUMToolKindTreeLog') is null 
begin 
    CREATE TABLE _TDAUMToolKindTreeLog 
    (   
        LogSeq int identity NOT NULL,    
        LogUserSeq int NOT NULL,    
        LogDateTime datetime NOT NULL,    
        LogType nchar(1) NOT NULL,    
        CompanySeq int NOT NULL,    
        UMToolKind int NOT NULL,    
        UpperUMToolKind int NOT NULL,    
        Sort int NULL   ,    
        Level int NULL   ,    
        NodeImg int NULL   ,    
        GongjongSeq int NOT NULL,    
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL
    ) 
end 