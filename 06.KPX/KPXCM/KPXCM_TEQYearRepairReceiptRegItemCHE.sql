
if object_id('KPXCM_TEQYearRepairReceiptRegItemCHE') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReceiptRegItemCHE
(
    CompanySeq		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegSerl		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    ProgType		INT 	 NOT NULL, 
    RtnReason		NVARCHAR(500) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		datetime 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
)
create unique clustered index idx_KPXCM_TEQYearRepairReceiptRegItemCHE on KPXCM_TEQYearRepairReceiptRegItemCHE(CompanySeq,ReceiptRegSeq,ReceiptRegSerl) 
end 


if object_id('KPXCM_TEQYearRepairReceiptRegItemCHELog') is null
begin 
CREATE TABLE KPXCM_TEQYearRepairReceiptRegItemCHELog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptRegSeq		INT 	 NOT NULL, 
    ReceiptRegSerl		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqSerl		INT 	 NOT NULL, 
    ProgType		INT 	 NOT NULL, 
    RtnReason		NVARCHAR(500) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		datetime 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end 


