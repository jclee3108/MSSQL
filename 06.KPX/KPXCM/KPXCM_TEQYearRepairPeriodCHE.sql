if object_id('KPXCM_TEQYearRepairPeriodCHE') is null 
begin 
    CREATE TABLE KPXCM_TEQYearRepairPeriodCHE 
    (   
        CompanySeq int NOT NULL,    
        RepairSeq  INT NOT NULL, 
        RepairYear nchar(4) NOT NULL, 
        FactUnit INT NOT NULL , 
        Amd int NOT NULL,    
        EmpSeq int not null, 
        DeptSeq int not null, 
        RepairName nvarchar(100) NULL   ,    
        RepairFrDate nchar(8) NOT NULL,    
        RepairToDate nchar(8) NOT NULL,    
        ReceiptFrDate nchar(8) NOT NULL,    
        ReceiptToDate nchar(8) NOT NULL,    
        RepairCfmYn nchar(1) NOT NULL,   
        ReceiptCfmyn nchar(1) NOT NULL,   
        Remark nvarchar(12) NULL   ,    
        LastDateTime datetime NOT NULL,    
        LastUserSeq int NOT NULL
    ) 
    create unique clustered index idx_KPXCM_TEQYearRepairPeriodCHE on KPXCM_TEQYearRepairPeriodCHE(CompanySeq,RepairSeq)
end 


if object_id('KPXCM_TEQYearRepairPeriodCHELog') is null 
begin 
    CREATE TABLE KPXCM_TEQYearRepairPeriodCHELog 
    (   
        LogSeq int identity NOT NULL,   
        LogUserSeq int NOT NULL,  
        LogDateTime datetime NOT NULL,  
        LogType nchar(1) NOT NULL,    
        LogPgmSeq   INT NULL, 
        CompanySeq int NOT NULL,   
        RepairSeq  INT NOT NULL, 
        RepairYear nchar(4) NOT NULL,  
        FactUnit INT NOT NULL , 
        Amd int NOT NULL,   
        EmpSeq int not null, 
        DeptSeq int not null, 
        RepairName nvarchar(100) NULL   , 
        RepairFrDate nchar(8) NOT NULL,   
        RepairToDate nchar(8) NOT NULL,   
        ReceiptFrDate nchar(8) NOT NULL,  
        ReceiptToDate nchar(8) NOT NULL,  
        RepairCfmYn nchar(1) NOT NULL,   
        ReceiptCfmyn nchar(1) NOT NULL,    
        Remark nvarchar(12) NULL   ,   
        LastDateTime datetime NOT NULL,   
        LastUserSeq int NOT NULL
    ) 
end 


