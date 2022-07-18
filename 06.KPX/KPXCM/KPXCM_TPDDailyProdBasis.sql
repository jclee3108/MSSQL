if object_id('KPXCM_TPDDailyProdBasis') is null
begin 

    CREATE TABLE KPXCM_TPDDailyProdBasis
    (
        CompanySeq		INT 	 NOT NULL, 
        UnitProcSeq		INT 	 NOT NULL, 
        UMItemKind		INT 	 NOT NULL, 
        UnitProcName		NVARCHAR(200) 	 NOT NULL, 
        Sort		INT 	 NOT NULL, 
        Remark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL

    )
    create unique clustered index idx_KPXCM_TPDDailyProdBasis on KPXCM_TPDDailyProdBasis(CompanySeq,UnitProcSeq) 
end 


if object_id('KPXCM_TPDDailyProdBasisLog') is null
begin 

CREATE TABLE KPXCM_TPDDailyProdBasisLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    UnitProcSeq		INT 	 NOT NULL, 
    UMItemKind		INT 	 NOT NULL, 
    UnitProcName		NVARCHAR(200) 	 NOT NULL, 
    Sort		INT 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

end 


