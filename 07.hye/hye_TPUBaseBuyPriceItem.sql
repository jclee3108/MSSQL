if object_id('hye_TPUBaseBuyPriceItem') is null 
begin 

    CREATE TABLE hye_TPUBaseBuyPriceItem
    (
        CompanySeq		INT 	 NOT NULL, 
        PriceSeq		INT 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        UnitSeq		INT 	 NOT NULL, 
        CurrSeq		INT 	 NOT NULL, 
        UMDVGroupSeq		INT 	 NOT NULL, 
        SrtDate		NCHAR(8) 	 NOT NULL, 
        EndDate		NCHAR(8) 	 NOT NULL, 
        YSSPrice		DECIMAL(19,5) 	 NOT NULL, 
        DelvPrice		DECIMAL(19,5) 	 NOT NULL, 
        StdPrice		DECIMAL(19,5) 	 NOT NULL, 
        SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
        ChgPrice		DECIMAL(19,5) 	 NOT NULL, 
        IsChg		NCHAR(1) 	 NOT NULL, 
        Summary		NVARCHAR(500) 	 NOT NULL, 
        Remark		NVARCHAR(500) 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT TPKhye_TPUBaseBuyPriceItem PRIMARY KEY CLUSTERED (CompanySeq ASC, PriceSeq ASC)

    )

    CREATE UNIQUE  INDEX IDXTemphye_TPUBaseBuyPriceItem ON hye_TPUBaseBuyPriceItem(CompanySeq, PriceSeq)
end 

if object_id('hye_TPUBaseBuyPriceItemLog') is null 
begin 
CREATE TABLE hye_TPUBaseBuyPriceItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PriceSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    UMDVGroupSeq		INT 	 NOT NULL, 
    SrtDate		NCHAR(8) 	 NOT NULL, 
    EndDate		NCHAR(8) 	 NOT NULL, 
    YSSPrice		DECIMAL(19,5) 	 NOT NULL, 
    DelvPrice		DECIMAL(19,5) 	 NOT NULL, 
    StdPrice		DECIMAL(19,5) 	 NOT NULL, 
    SalesPrice		DECIMAL(19,5) 	 NOT NULL, 
    ChgPrice		DECIMAL(19,5) 	 NOT NULL, 
    IsChg		NCHAR(1) 	 NOT NULL, 
    Summary		NVARCHAR(500) 	 NOT NULL, 
    Remark		NVARCHAR(500) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)

CREATE UNIQUE  INDEX IDXTemphye_TPUBaseBuyPriceItemLog ON hye_TPUBaseBuyPriceItemLog (LogSeq)
end 


