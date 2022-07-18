if object_id('KPXCM_TPDBOMBatchItem') is null
begin     
    CREATE TABLE KPXCM_TPDBOMBatchItem 
    (   
        CompanySeq int NOT NULL,   
        BatchSeq int NOT NULL,   
        Serl int NOT NULL,   
        ItemSeq int NOT NULL,  
        InputUnitSeq int NOT NULL, 
        NeedQtyNumerator decimal(19,5) NOT NULL,
        NeedQtyDenominator decimal(19,5) NOT NULL,   
        Remark nvarchar(500) NOT NULL,   
        LastUserSeq int NOT NULL,    
        LastDateTime datetime NOT NULL,  
        ProcSeq int NULL   ,  
        Overage decimal(19,5) NULL   , 
        AvgContent decimal(19,5) NULL   ,  
        SMDelvType int NULL   ,    
        SortOrder int NULL   ,   
        DateFr nchar(8) NULL   ,   
        DateTo nchar(8) NULL  
    ) 
    CREATE UNIQUE CLUSTERED INDEX TPK_KPXCM_TPDBOMBatchItem on KPXCM_TPDBOMBatchItem(CompanySeq, BatchSeq, Serl)
end 
    
if object_id('KPXCM_TPDBOMBatchItemLog') is null
begin 
    CREATE TABLE KPXCM_TPDBOMBatchItemLog 
    ( 
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,  
    LogDateTime datetime NOT NULL,  
    LogType nchar(1) NOT NULL,  
    CompanySeq int NOT NULL,   
    BatchSeq int NOT NULL,  
    Serl int NOT NULL,   
    ItemSeq int NOT NULL,  
    InputUnitSeq int NOT NULL,   
    NeedQtyNumerator decimal(19,5) NOT NULL, 
    NeedQtyDenominator decimal(19,5) NOT NULL,   
    Remark nvarchar(500) NOT NULL,   
    LastUserSeq int NOT NULL,   
    LastDateTime datetime NOT NULL,   
    ProcSeq int NULL   ,   
    Overage decimal(19,5) NULL   ,    
    AvgContent decimal(19,5) NULL   ,    
    SMDelvType int NULL   ,   
    LogPgmSeq int NULL   
    ) 
    
    CREATE UNIQUE CLUSTERED INDEX TPK_KPXCM_TPDBOMBatchItemLog on KPXCM_TPDBOMBatchItemLog(LogSeq)
end 
