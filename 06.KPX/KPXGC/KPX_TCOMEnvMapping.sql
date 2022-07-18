if object_id('KPX_TCOMEnvMapping') is null 
begin 
CREATE TABLE KPX_TCOMEnvMapping 
(   
    CompanySeq int NOT NULL,    
    TableName nvarchar(100) NOT NULL,    
    Field nvarchar(100) NOT NULL,    
    TableTask nvarchar(100) NULL   ,    
    Remark nvarchar(500) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
CREATE UNIQUE CLUSTERED INDEX PKKPX_TCOMEnvMapping on KPX_TCOMEnvMapping(CompanySeq, TableName, Field)
end 

if object_id('KPX_TCOMEnvMappingLog') is null
begin
CREATE TABLE KPX_TCOMEnvMappingLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    LogPgmSeq int NULL   ,    
    CompanySeq int NOT NULL,    
    TableName nvarchar(100) NOT NULL,  
    Field nvarchar(100) NOT NULL,   
    TableTask nvarchar(100) NULL   ,   
    Remark nvarchar(500) NULL   ,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   
) 
end 