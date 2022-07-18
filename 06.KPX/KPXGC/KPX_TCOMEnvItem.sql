if object_id('KPX_TCOMEnvItem') is null 
begin 
CREATE TABLE KPX_TCOMEnvItem 
(   
    CompanySeq int NOT NULL,    
    EnvSeq int NOT NULL,    
    EnvSerl int NOT NULL,    
    EnvValue nvarchar(100) NULL   ,    
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   
) 
CREATE UNIQUE CLUSTERED INDEX PKKPX_TCOMEnvItem on KPX_TCOMEnvItem(CompanySeq, EnvSeq, EnvSerl)
end 

if object_id('KPX_TCOMEnvItemLog') is null 
begin
CREATE TABLE KPX_TCOMEnvItemLog 
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
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   
) 

end 

