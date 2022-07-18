

if OBJECT_ID('KPX_TQCCOAPrint') is null
begin 

CREATE TABLE KPX_TQCCOAPrint
(
    CompanySeq		INT 	 NOT NULL, 
    COASeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    ShipDate		NCHAR(8) 	 NULL, 
    COADate		NCHAR(8) 	 NOT NULL, 
    COANo		NVARCHAR(100) 	 NOT NULL, 
    COACount		DECIMAL(19,5) 	 NOT NULL, 
    IsPrint		NCHAR(1) 	 NULL, 
    QCSeq		INT 	 NOT NULL, 
    KindSeq     INT     NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TQCCOAPrint on KPX_TQCCOAPrint(CompanySeq,COASeq) 
end 


if OBJECT_ID('KPX_TQCCOAPrintLog') is null
begin
CREATE TABLE KPX_TQCCOAPrintLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    COASeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    ShipDate		NCHAR(8) 	 NULL, 
    COADate		NCHAR(8) 	 NOT NULL, 
    COANo		NVARCHAR(100) 	 NOT NULL, 
    COACount		DECIMAL(19,5) 	 NOT NULL, 
    IsPrint		NCHAR(1) 	 NULL, 
    QCSeq		INT 	 NOT NULL, 
    KindSeq     INT     NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 

