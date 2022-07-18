
if object_id('KPXLS_TQCCOAPrint') is null
begin 
CREATE TABLE KPXLS_TQCCOAPrint 
(   
    CompanySeq int NOT NULL,    
    COASeq int NOT NULL,    
    CustSeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    LotNo nvarchar(100) NOT NULL,    
    QCType int NOT NULL,    
    ShipDate nchar(8) NULL   ,    
    COADate nchar(8) NOT NULL,    
    COANo nvarchar(100) NOT NULL,    
    COACount decimal(19,5) NOT NULL,    
    IsPrint nchar(1) NULL   ,    
    QCSeq int NOT NULL,    
    KindSeq int NOT NULL,  
    CasNo       nvarchar(200) not null, 
    TestEmpName nvarchar(200) not null, 
    OriWeight   decimal(19,5) not null, 
    TotWeight   decimal(19,5) not null, 
    CreateDate  nchar(8) not null, 
    ReTestDate  nchar(8) not null, 
    TestResultDate  nchar(8) not null, 
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    Remark nvarchar(100) NULL   ,    
    LifeCycle decimal(19,5) NULL   ,    
    QCDate nchar(8) NULL   ,    
    CustEngName nvarchar(100) NULL   ,    
    DVPlaceSeq int NULL   ,    
    CustItemName nvarchar(100) NULL   
) 

CREATE UNIQUE CLUSTERED INDEX idx_KPXLS_TQCCOAPrint on KPXLS_TQCCOAPrint(CompanySeq, COASeq)
end 


if object_id('KPXLS_TQCCOAPrintLog') is null
begin 
CREATE TABLE KPXLS_TQCCOAPrintLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    LogPgmSeq int NULL   ,    
    CompanySeq int NOT NULL,    
    COASeq int NOT NULL,    
    CustSeq int NOT NULL,    
    ItemSeq int NOT NULL,    
    LotNo nvarchar(100) NOT NULL,    
    QCType int NOT NULL,    
    ShipDate nchar(8) NULL   ,    
    COADate nchar(8) NOT NULL,    
    COANo nvarchar(100) NOT NULL,    
    COACount decimal(19,5) NOT NULL,    
    IsPrint nchar(1) NULL   ,    
    QCSeq int NOT NULL,    
    KindSeq int NOT NULL,    
    CasNo       nvarchar(200) not null, 
    TestEmpName nvarchar(200) not null, 
    OriWeight   decimal(19,5) not null, 
    TotWeight   decimal(19,5) not null, 
    CreateDate  nchar(8) not null, 
    ReTestDate  nchar(8) not null, 
    TestResultDate  nchar(8) not null, 
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,    
    Remark nvarchar(100) NULL   ,    
    SMSourceType int NULL   ,    
    LifeCycle decimal(19,5) NULL   ,    
    QCDate nchar(8) NULL   ,    
    CustEngName nvarchar(100) NULL   ,    
    DVPlaceSeq int NULL   ,    
    CustItemName nvarchar(100) NULL   
) 
end 


