
if object_id('KPXCM_TSEChemicalsListCHE') is null
begin
CREATE TABLE KPXCM_TSEChemicalsListCHE 
(   
    CompanySeq int NOT NULL,    
    ChmcSeq int NOT NULL,    
    ItemSeq int NOT NULL,   
    ToxicName nvarchar(400) NULL   ,
    MainPurpose nvarchar(400) NULL   , 
    Content nvarchar(400) NULL   ,   
    PrintName nvarchar(400) NULL   ,   
    Remark nvarchar(400) NULL   ,  
    LastDateTime datetime NULL   , 
    LastUserSeq int NULL   ,  
    Acronym nvarchar(100) NULL   ,
    CasNo nvarchar(100) NULL   ,  
    Molecular nvarchar(100) NULL   , 
    ExplosionBottom nvarchar(100) NULL   , 
    ExplosionTop nvarchar(100) NULL   ,   
    StdExpo nvarchar(100) NULL   ,   
    Toxic nvarchar(100) NULL   ,    
    FlashPoint nvarchar(100) NULL   ,    
    IgnitionPoint nvarchar(100) NULL   ,  
    Pressure nvarchar(100) NULL   ,  
    IsCaustic nvarchar(100) NULL   ,  
    IsStatus nvarchar(100) NULL   ,    
    UseDaily decimal(19,5) NULL   ,   
    State nvarchar(100) NULL   ,   
    PoisonKind nvarchar(100) NULL   ,  
    DangerKind nvarchar(100) NULL   ,   
    SafeKind nvarchar(100) NULL   ,  
    SaveKind nvarchar(100) NULL   , 
    GroupKind int NULL, 
    MakeCountry NVARCHAR(100) null, 
    CustSeq int null, 
    IsSave  nchar(1) null
) 
CREATE UNIQUE CLUSTERED INDEX IDXTempKPXCM_TSEChemicalsList on KPXCM_TSEChemicalsListCHE(CompanySeq, ChmcSeq)
end 


if object_id('KPXCM_TSEChemicalsListCHELog') is null
begin
CREATE TABLE KPXCM_TSEChemicalsListCHELog 
(   
    LogSeq int identity NOT NULL,   
    LogUserSeq int NOT NULL,   
    LogDateTime datetime NOT NULL,  
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,   
    ChmcSeq int NOT NULL,   
    ItemSeq int NOT NULL,  
    ToxicName nvarchar(400) NULL   , 
    MainPurpose nvarchar(400) NULL   ,   
    Content nvarchar(400) NULL   ,  
    PrintName nvarchar(400) NULL   ,   
    Remark nvarchar(400) NULL   ,    
    LastDateTime datetime NULL   ,  
    LastUserSeq int NULL   ,
    Acronym nvarchar(100) NULL   ,  
    CasNo nvarchar(100) NULL   ,   
    Molecular nvarchar(100) NULL   , 
    ExplosionBottom nvarchar(100) NULL   ,  
    ExplosionTop nvarchar(100) NULL   ,    
    StdExpo nvarchar(100) NULL   ,  
    Toxic nvarchar(100) NULL   ,  
    FlashPoint nvarchar(100) NULL   ,    
    IgnitionPoint nvarchar(100) NULL   ,   
    Pressure nvarchar(100) NULL   ,   
    IsCaustic nvarchar(100) NULL   ,  
    IsStatus nvarchar(100) NULL   ,    
    UseDaily decimal(19,5) NULL   ,  
    State nvarchar(100) NULL   ,   
    PoisonKind nvarchar(100) NULL   ,   
    DangerKind nvarchar(100) NULL   ,   
    SafeKind nvarchar(100) NULL   ,    
    SaveKind nvarchar(100) NULL   ,  
    GroupKind int NULL, 
    MakeCountry NVARCHAR(100) null, 
    CustSeq int null, 
    IsSave  nchar(1) null
) 
CREATE UNIQUE CLUSTERED INDEX IDXTempKPXCM_TSEChemicalsListLog on KPXCM_TSEChemicalsListCHELog(LogSeq)
end 



--if not exists (select 1 from syscolumns where id = object_id('_TSEChemicalsListCHE') and name = 'MakeCountry')
--begin
--    alter table _TSEChemicalsListCHE add MakeCountry nvarchar(100) null 
--    alter table _TSEChemicalsListCHELog add MakeCountry nvarchar(100) null 
--end 

--if not exists (select 1 from syscolumns where id = object_id('_TSEChemicalsListCHE') and name = 'CustSeq')
--begin
--    alter table _TSEChemicalsListCHE add CustSeq int null 
--    alter table _TSEChemicalsListCHELog add CustSeq int null 
--end 


--if not exists (select 1 from syscolumns where id = object_id('_TSEChemicalsListCHE') and name = 'IsSave')
--begin
--    alter table _TSEChemicalsListCHE add IsSave nchar(1) null 
--    alter table _TSEChemicalsListCHELog add IsSave nchar(1) null 
--end 
