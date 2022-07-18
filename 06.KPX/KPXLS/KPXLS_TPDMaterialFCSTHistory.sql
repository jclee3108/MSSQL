

if object_id('KPXLS_TPDMaterialFCSTHistory') is null
begin 
CREATE TABLE KPXLS_TPDMaterialFCSTHistory 
(   
    CompanySeq int NOT NULL,    
    FactUnit int NOT NULL,    
    GoodItemSeq int NOT NULL,    
    MatItemSeq int NOT NULL,   
    StdDate nvarchar(8) NOT NULL,   
    ResultValue decimal(19,5) NOT NULL, 
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   
) 
CREATE UNIQUE CLUSTERED INDEX PKKPXLS_TPDMaterialFCSTHistory on KPXLS_TPDMaterialFCSTHistory(CompanySeq, FactUnit, GoodItemSeq, MatItemSeq, StdDate)
end 



if object_id('KPXLS_TPDMaterialFCSTHistoryLog') is null
begin
CREATE TABLE KPXLS_TPDMaterialFCSTHistoryLog 
(   
    LogSeq int NOT NULL,   
    LogUserSeq int NOT NULL,   
    LogDateTime datetime NOT NULL, 
    LogType nchar(1) NOT NULL,    
    LogPgmSeq int NULL   ,    
    CompanySeq int NOT NULL,   
    FactUnit int NOT NULL,  
    GoodItemSeq int NOT NULL, 
    MatItemSeq int NOT NULL,   
    StdDate nvarchar(8) NOT NULL,   
    ResultValue decimal(19,5) NOT NULL,  
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL  
) 
CREATE UNIQUE CLUSTERED INDEX IDXTempKPXLS_TPDMaterialFCSTHistoryLog on KPXLS_TPDMaterialFCSTHistoryLog(LogSeq)
end 