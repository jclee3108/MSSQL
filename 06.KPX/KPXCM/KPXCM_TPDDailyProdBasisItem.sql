if object_id('KPXCM_TPDDailyProdBasisItem') is null
begin 

    CREATE TABLE KPXCM_TPDDailyProdBasisItem
    (
        CompanySeq		INT 	 NOT NULL, 
        UnitProcSeq		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        ItemPrtName		NVARCHAR(200) 	 NOT NULL, 
        Sort		INT 	 NOT NULL, 
        ConvDen     DECIMAL(19,5) NOT NULL, 
        Remark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL

    )
    create unique clustered index idx_KPXCM_TPDDailyProdBasisItem on KPXCM_TPDDailyProdBasisItem(CompanySeq,UnitProcSeq,ItemSeq) 
end 

if object_id('KPXCM_TPDDailyProdBasisItemLog') is null
begin 
    CREATE TABLE KPXCM_TPDDailyProdBasisItemLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        UnitProcSeq		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        ItemPrtName		NVARCHAR(200) 	 NOT NULL, 
        Sort		INT 	 NOT NULL, 
        ConvDen     DECIMAL(19,5) NOT NULL, 
        Remark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
end 


