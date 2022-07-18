if object_id('KPX_TSLDelvItemPrice') is null
begin 
CREATE TABLE KPX_TSLDelvItemPrice
(
    CompanySeq		INT 	 NOT NULL, 
    DVItemPriceSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    DVPlaceSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    SDate		NCHAR(8) 	 NOT NULL, 
    EDate		NCHAR(8) 	 NOT NULL, 
    DrumPrice		DECIMAL(19,5) 	 NULL, 
    TankPrice		DECIMAL(19,5) 	 NULL, 
    BoxPrice		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL 
)
create unique clustered index idx_KPX_TSLDelvItemPrice on KPX_TSLDelvItemPrice(CompanySeq,DVItemPriceSeq) 
create index idx_KPX_TSLDelvItemPriceSub on KPX_TSLDelvItemPrice(CompanySeq,CustSeq,DVPlaceSeq,ItemSeq) 
end 



if object_id('KPX_TSLDelvItemPriceLog') is null 
begin  

CREATE TABLE KPX_TSLDelvItemPriceLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    DVItemPriceSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    DVPlaceSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    SDate		NCHAR(8) 	 NOT NULL, 
    EDate		NCHAR(8) 	 NOT NULL, 
    DrumPrice		DECIMAL(19,5) 	 NULL, 
    TankPrice		DECIMAL(19,5) 	 NULL, 
    BoxPrice		DECIMAL(19,5) 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 
