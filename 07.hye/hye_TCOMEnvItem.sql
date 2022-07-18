

IF OBJECT_ID('hye_TCOMEnvItem') IS NULL
begin 
    CREATE TABLE hye_TCOMEnvItem 
    ( 
        CompanySeq int NOT NULL,   
        EnvSeq int NOT NULL,   
        EnvSerl int NOT NULL,  
        EnvValue nvarchar(100) NULL   , 
        LastUserSeq int NOT NULL,   
        LastDateTime datetime NOT NULL
    ) 
    CREATE UNIQUE CLUSTERED INDEX PKhye_TCOMEnvItem on hye_TCOMEnvItem(CompanySeq, EnvSeq, EnvSerl)
end 
    
IF OBJECT_ID('hye_TCOMEnvItemLog') IS NULL
begin 
    CREATE TABLE hye_TCOMEnvItemLog 
    (   
        LogSeq int identity NOT NULL,    
        LogUserSeq int NOT NULL,    
        LogDateTime datetime NOT NULL,    
        LogType nchar(1) NOT NULL,    
        LogPgmSeq int NULL   ,    
        CompanySeq int NOT NULL,    
        EnvSeq int NOT NULL,    
        EnvSerl int NOT NULL,    
        EnvValue nvarchar(100) NULL   ,    
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL
    ) 
    CREATE UNIQUE CLUSTERED INDEX IDXTemphye_TCOMEnvItemLog on hye_TCOMEnvItemlog(LogSeq)
end 


