if object_id('KPXCM_TPDBOMBatch') is null 
begin 
    CREATE TABLE KPXCM_TPDBOMBatch 
    (   
        CompanySeq int NOT NULL,    
        FactUnit int NOT NULL,    
        BatchSeq int NOT NULL,    
        BatchNo nchar(12) NOT NULL,    
        BatchName nvarchar(100) NOT NULL,    
        ItemSeq int NOT NULL,    
        BatchSize decimal(19,5) NOT NULL,    
        ProdUnitSeq int NOT NULL,    
        IsUse nchar(1) NOT NULL,    
        DateFr nchar(8) NOT NULL,    
        DateTo nchar(8) NOT NULL,    
        Remark nvarchar(500) NOT NULL,    
        IsDefault nchar(1) NOT NULL,    
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL,    
        BOMRev nchar(2) NULL   ,    
        ProcTypeSeq int NULL   
    ) 
    CREATE UNIQUE CLUSTERED INDEX TPK_KPXCM_TPDBOMBatch on KPXCM_TPDBOMBatch(CompanySeq, FactUnit, BatchSeq)
end 

if object_id('KPXCM_TPDBOMBatchLog') is null 
begin 
    CREATE TABLE KPXCM_TPDBOMBatchLog 
    (   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,    
    FactUnit int NOT NULL,    
    BatchSeq int NOT NULL,   
    BatchNo nchar(12) NOT NULL,    
    BatchName nvarchar(100) NOT NULL,    
    ItemSeq int NOT NULL,    
    BatchSize decimal(19,5) NOT NULL,    
    ProdUnitSeq int NOT NULL,    
    IsUse nchar(1) NOT NULL,   
    DateFr nchar(8) NOT NULL,    
    DateTo nchar(8) NOT NULL,  
    Remark nvarchar(500) NOT NULL,    
    IsDefault nchar(1) NOT NULL,   
    LastUserSeq int NOT NULL,  
    LastDateTime datetime NOT NULL,    
    BOMRev nchar(2) NULL   ,  
    ProcTypeSeq int NULL   ,   
    LogPgmSeq int NULL   
    ) 
    CREATE UNIQUE CLUSTERED INDEX TPK_KPXCM_TPDBOMBatchLog on KPXCM_TPDBOMBatchLog(LogSeq)
end 