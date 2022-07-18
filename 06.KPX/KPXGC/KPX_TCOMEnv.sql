IF OBJECT_ID('KPX_TCOMEnv') IS NULL 
begin 
CREATE TABLE KPX_TCOMEnv 
(   
    CompanySeq int NULL   ,    
    EnvSeq int NULL   ,    
    EnvName nvarchar(100) NULL   ,    
    Description nvarchar(500) NULL   ,    
    ModuleSeq int NULL   ,    
    SMControlType int NULL   ,    
    CodeHelpSeq int NULL   ,    
    MinorSeq int NULL   ,    
    SMUseType int NULL   ,    
    QuerySort int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    DecLength int NULL   ,    
    AddCheckScript nvarchar(100) NULL   ,    
    AddSaveScript nvarchar(100) NULL   
) 
CREATE UNIQUE CLUSTERED INDEX idx_KPX_TCOMEnv on KPX_TCOMEnv(CompanySeq, EnvSeq)
end 

if object_id('KPX_TCOMEnvLog') is null 
begin 
CREATE TABLE KPX_TCOMEnvLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    LogPgmSeq int NULL   ,    
    CompanySeq int NULL   ,    
    EnvSeq int NULL   ,    
    EnvName nvarchar(100) NULL   ,    
    Description nvarchar(500) NULL   ,    
    ModuleSeq int NULL   ,    
    SMControlType int NULL   ,    
    CodeHelpSeq int NULL   ,    
    MinorSeq int NULL   ,    
    SMUseType int NULL   ,    
    QuerySort int NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    DecLength int NULL   ,    
    AddCheckScript nvarchar(100) NULL   ,    
    AddSaveScript nvarchar(100) NULL   
) 
end 