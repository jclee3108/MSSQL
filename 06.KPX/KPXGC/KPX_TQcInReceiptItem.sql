if object_id('KPX_TQcInReceiptItem') is null
begin 
CREATE TABLE KPX_TQcInReceiptItem
(
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    IsInQC		NCHAR(1) 	 NULL, 
    IsAutoDelvIn		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL

)
create unique clustered index idx_KPX_TQcInReceiptItem on KPX_TQcInReceiptItem(CompanySeq,ItemSeq) 
end 

if object_id('KPX_TQcInReceiptItemLog') is null
begin 
CREATE TABLE KPX_TQcInReceiptItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    IsInQC		NCHAR(1) 	 NULL, 
    IsAutoDelvIn		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 