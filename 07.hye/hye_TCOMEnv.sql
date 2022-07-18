

if OBJECT_ID('hye_TCOMEnv') is null 
begin 
    CREATE TABLE hye_TCOMEnv 
    (   
        CompanySeq int NOT NULL,    
        EnvSeq int NOT NULL,    
        EnvName nvarchar(100) NOT NULL,    
        Description nvarchar(500) NOT NULL,    
        ModuleSeq int NOT NULL,    
        SMControlType int NOT NULL,    
        CodeHelpSeq int NOT NULL,    
        MinorSeq int NULL   ,    
        SMUseType int NOT NULL,    
        QuerySort int NOT NULL,    
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL,    
        DecLength int NOT NULL,    
        AddCheckScript nvarchar(100) NULL   ,    
        AddSaveScript nvarchar(100) NULL   
    ) 

    CREATE UNIQUE CLUSTERED INDEX PKhye_TCOMEnv on hye_TCOMEnv(CompanySeq, EnvSeq)
end 


if OBJECT_ID('hye_TCOMEnvLog') is null 
begin 
    CREATE TABLE hye_TCOMEnvLog 
    (   
        LogSeq int identity NOT NULL,   
        LogUserSeq int NOT NULL,  
        LogDateTime datetime NOT NULL,  
        LogType nchar(1) NOT NULL,  
        LogPgmSeq int NULL   ,   
        CompanySeq int NOT NULL,  
        EnvSeq int NOT NULL,   
        EnvName nvarchar(100) NOT NULL,   
        Description nvarchar(500) NOT NULL, 
        ModuleSeq int NOT NULL,   
        SMControlType int NOT NULL,  
        CodeHelpSeq int NOT NULL,   
        MinorSeq int NOT NULL,   
        SMUseType int NOT NULL,  
        QuerySort int NOT NULL,   
        LastUserSeq int NOT NULL,  
        LastDateTime datetime NOT NULL,   
        DecLength int NOT NULL,  
        AddCheckScript nvarchar(100) NOT NULL,    
        AddSaveScript nvarchar(100) NOT NULL
    ) 
    CREATE UNIQUE CLUSTERED INDEX IDXTemphye_TCOMEnvLog on hye_TCOMEnvlog(LogSeq)
END 



--drop table hye_TCOMEnvLog 