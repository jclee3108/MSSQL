IF OBJECT_ID('hye_TCOMEnvMapping') is null 
begin 
    CREATE TABLE hye_TCOMEnvMapping 
    (   
        CompanySeq int NOT NULL,    
        TableName nvarchar(100) NOT NULL,    
        TableTask nvarchar(100) NOT NULL,    
        Field nvarchar(100) NOT NULL,    
        Remark nvarchar(500) NOT NULL,    
        LastDateTime datetime NOT NULL,    
        LastUserSeq int NOT NULL
    ) 
end 